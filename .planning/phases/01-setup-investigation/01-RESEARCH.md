# Phase 1 Research: Setup & Investigation

**Phase:** 1 — Setup & Investigation
**Goal:** Prepare codebase for debugging and establish baseline measurements
**Date:** 2026-03-11

---

## What This Phase Needs

Phase 1 is preparatory: it must produce the tools and baselines needed for subsequent bugfix phases. No code fixes happen here; instead, we build instrumentation, test harnesses, and record the "before" state.

### Four Success Criteria

1. **Debug tracing enabled/disabled via flag**
2. **Minimal reproduction cases for each failing example (004, 009, 011, 013)**
3. **Baseline test results recorded**
4. **Codegen instrumentation ready for selective use**

---

## Recommended Approach

### 1. Debug Tracing Architecture

**Approach: Conditional compilation via MoonBit build flags**

MoonBit supports conditional compilation using `@conditional` attribute or compile-time flags. Since the codebase is self-hosted, the easiest is to add a runtime flag that's checked at each trace point, but that adds overhead. Better: use a compile-time constant that branches are optimized away.

**Implementation in `codegen.mbt`:**

```moonbit
// At top of codegen.mbt
let debug_level : Int = 0 // Set via compiler flag or environment

fn trace_instruction(pos : Int, opcode : String, operands : Array[String]) : Unit = {
  if debug_level >= 1 {
    // Print to stderr or log file
    println("[$pos] $opcode $operands")
  }
}

fn trace_ast(node : String) : Unit = {
  if debug_level >= 2 {
    println("AST: $node")
  }
}
```

**To enable:** Pass `-DDEBUG_CODEGEN=1` to the MoonBit compiler when building `cmd/main`, or set an environment variable that the codegen reads at initialization.

**Flag design:**
- `--debug-codegen` CLI flag → sets `CodeGen.debug_level`
- Levels: 0=none, 1=instructions, 2=AST+instructions, 3=+register allocation

**Why runtime flag (not compile-time):** Easier to toggle without recompiling the compiler. The compiler is slow to compile; runtime flag allows quick iteration.

**Alternative (compile-time):** MoonBit's `#[iff(condition)]` attribute could eliminate branches entirely. But requires rebuilding compiler for each change. For this phase, runtime flag is sufficient; optimize later if needed.

### 2. What to Trace

**Instruction emissions (debug_level=1):**
- Position in code buffer (byte offset)
- Opcode mnemonic (MOV, ADD, CALL, JMP, etc.)
- Operands (registers, immediates, memory addresses)
- Result: assembly-like listing that can be fed to `ndisasm` or `objdump -D -b binary -m i386:x86-64`

**AST nodes (debug_level=2):**
- Which expression/statement is being codegen'd
- Type information if available
- Helps map failing AST nodes to emitted code

**Register allocation (debug_level=3):**
- Which virtual/physical register is assigned
- Spill/fill events
- Stack offsets for locals

**For initial bug diagnosis:** Level 1 (instructions) is most important. Level 2 helps identify which part of the source triggers problematic code. Level 3 likely overkill for these straightforward bugs.

### 3. Minimal Reproduction Harness

**Structure:** Create a directory `.planning/phases/01-setup-investigation/harness/` containing:

- `harness.sh` – script that iterates over failing examples, compiles with our compiler, runs, captures output
- `harness.mbt` – optional MoonBit program that can compile and run examples programmatically? Simpler: shell script.

**harness.sh content:**

```bash
#!/bin/bash
set -e

# Paths
COMPILER="moon run cmd/main"
REFERENCE="moon run"  # Official MoonBit to generate reference output
EXAMPLES_DIR="examples/mbt_examples"
OUTPUT_DIR=".planning/phases/01-setup-investigation/harness/outputs"
BASELINE_FILE=".planning/phases/01-setup-investigation/baseline_results.md"

mkdir -p "$OUTPUT_DIR"

echo "# Baseline Test Results" > "$BASELINE_FILE"
echo "Date: $(date)" >> "$BASELINE_FILE"
echo "" >> "$BASELINE_FILE"

# Examples to test (failing ones)
FAILING_EXAMPLES=(004 009 011 013)

for ex in "${FAILING_EXAMPLES[@]}"; do
  echo "=== Testing $ex ==="
  
  # Find the source file (pattern: ${ex}_*.mbt)
  src=$(ls "$EXAMPLES_DIR/${ex}"*.mbt | head -1)
  base=$(basename "$src" .mbt)
  
  # Compile with our compiler
  echo "Compiling with our compiler..."
  $COMPILER "$src" 2>/dev/null || true  # ignore errors, segfaults possible
  
  exe_path="${src%.mbt}.exe"
  if [ -f "$exe_path" ]; then
    chmod +x "$exe_path"
    "./$exe_path" > "$OUTPUT_DIR/${base}_our.txt" 2>&1 || true
    our_status=$?
  else
    echo "No executable produced"
    echo "OUR: compilation failed" > "$OUTPUT_DIR/${base}_our.txt"
    our_status=1
  fi
  
  # Compile with reference compiler
  echo "Compiling with reference..."
  $REFERENCE "$src" > /dev/null 2>&1 || true
  if [ -f "$exe_path" ]; then
    "./$exe_path" > "$OUTPUT_DIR/${base}_ref.txt" 2>&1 || true
    ref_status=$?
  else
    echo "No reference executable produced"
    echo "REF: compilation failed" > "$OUTPUT_DIR/${base}_ref.txt"
    ref_status=1
  fi
  
  # Record results
  echo "## $base" >> "$BASELINE_FILE"
  echo "- Our status: $our_status, output: $OUTPUT_DIR/${base}_our.txt" >> "$BASELINE_FILE"
  echo "- Ref status: $ref_status, output: $OUTPUT_DIR/${base}_ref.txt" >> "$BASELINE_FILE"
  
  # Diff if both succeeded
  if [ $our_status -eq 0 ] && [ $ref_status -eq 0 ]; then
    if diff -q "$OUTPUT_DIR/${base}_our.txt" "$OUTPUT_DIR/${base}_ref.txt" > /dev/null; then
      echo "- Match: YES" >> "$BASELINE_FILE"
    else
      echo "- Match: NO (see diffs)" >> "$BASELINE_FILE"
      diff -u "$OUTPUT_DIR/${base}_ref.txt" "$OUTPUT_DIR/${base}_our.txt" >> "$BASELINE_FILE" || true
    fi
  else
    echo "- Match: N/A (one or both failed)" >> "$BASELINE_FILE"
  fi
  
  echo "" >> "$BASELINE_FILE"
done

echo "Baseline recorded in $BASELINE_FILE"
```

**Make it executable:** `chmod +x harness.sh`

**Minimal reproduction cases:** In addition to running the full examples, also create tiny versions that isolate each bug:

- `harness/minimal/004_minimal.mbt` – just a function returning constant + call
- `harness/minimal/009_minimal.mbt` – simplest if statement, simplest for loop
- `harness/minimal/011_minimal.mbt` – enum with 2 variants, match on both
- `harness/minimal/013_minimal.mbt` – struct with 2 fields, match with destructuring

These will be used during debugging to test fixes in isolation.

### 4. Baseline Test Results

The `baseline_results.md` should contain:

- Date and time
- Compiler commit hash (if applicable)
- For each failing example:
  - Compilation success/failure
  - Runtime: success, segfault, or panic
  - Output comparison: identical, different, or N/A
  - If different: include unified diff (or reference file path)
  - Notes on observed symptoms (e.g., "004 returns 80 instead of 42", "009 segfaults after printing 0")

**Optional:** Create a `baseline.json` for machine parsing:

```json
{
  "date": "2026-03-11T...",
  "examples": {
    "004": {
      "compiled": true,
      "ran": true,
      "exit_code": 0,
      "match": false,
      "diff": "..."
    },
    ...
  }
}
```

### 5. Validation Strategy

Even Phase 1 must be verifiable before moving on. Validation for Phase 1:

- **Check 1:** Harness script runs without errors and produces outputs for all 4 failing examples.
- **Check 2:** `trace_instruction` function exists in codegen.mbt and can be called.
- **Check 3:** Setting `debug_level` via environment variable or compile-time constant actually affects output (test by running with 0 and 1, observe no prints vs prints).
- **Check 4:** Baseline file exists and contains entries for all 4 examples with clear status.
- **Check 5:** Minimal reproduction cases compile and run (even if they fail as expected).

If all these are true, Phase 1 is done.

---

## Risks & Pitfalls

- **Instrumentation overhead:** If debug prints are too verbose, they may slow compilation noticeably. Keep them simple and behind a flag.
- **Infinite loops in harness:** The harness must handle hangs (use timeout). Add `timeout 5` around executable runs.
- **Compiler self-hosting:** Since the compiler is written in MoonBit, changing `codegen.mbt` requires recompiling the compiler. That's okay; Phase 1 won't be iterated much.
- **Segfault handling:** Our harness must not crash if the generated executable segfaults. Use `|| true` to capture status.

---

## Deliverables Summary

Phase 1 should produce:

1. **Code changes:**
   - `codegen.mbt`: add debug tracing functions and a debug_level field in CodeGen struct
   - Possibly `compiler.mbt` or `main.mbt` to expose `--debug-codegen` flag

2. **Test infrastructure:**
   - `.planning/phases/01-setup-investigation/harness/harness.sh`
   - `.planning/phases/01-setup-investigation/harness/minimal/*.mbt` (minimal repros)
   - Possibly a `Makefile` or `justfile` for convenience

3. **Documentation:**
   - `.planning/phases/01-setup-investigation/01-RESEARCH.md` (this file)
   - `.planning/phases/01-setup-investigation/baseline_results.md` (generated by harness run)

After research, the planner will create 2-4 executable PLAN.md files that break this work into atomic tasks with clear verification criteria.

---

## Notes for Planner

- Research exists: project-level research in `.planning/research/` already covers debugging approaches; this phase needs **specific implementation** for this codebase.
- The codebase uses `moon` CLI; any automation should use `moon run cmd/main` to compile.
- No CONTEXT.md exists; user design decisions are in PROJECT.md (which we've read).
- The existing `BUGFIX_PLAN.md` already sketches investigation order; Phase 1 is aligned with that.
- Phase 1 is preparatory; it doesn't fix bugs. The deliverables are tools and baselines.

Good luck planning!
