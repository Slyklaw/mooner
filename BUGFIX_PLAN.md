# Compiler Bugfix Plan

**Target:** All 13 examples passing (excluding 012_runtime support)
**Created:** 2026-03-11
**Status:** Planning stage

---

## Overview

Current state: 7/13 passing, 4 critical codegen bugs (2 cause segfaults), 1 acceptable degradation, 1 out-of-scope.

**Compiler readiness:** The compiler can compile and run basic programs but fails on:
- Function calls with arguments
- Control flow constructs (loops, conditionals)
- Enum pattern matching
- General pattern matching

These are **codegen** issues, not parser issues. The parser likely produces correct ASTs; code generation emits incorrect machine code.

---

## Investigation Phase (Est. 2-4 hours)

### 1. Generate and Inspect Assembly

For each failing example, generate the assembly code to see what's being emitted:

```bash
# Build with assembly output
for i in 004 009 011 013; do
  echo "=== Example $i ==="
  moon run cmd/main examples/mbt_examples/${i}_*.mbt 2>/dev/null
  if [ -f "examples/mbt_examples/${i}_*.exe" ]; then
    # Extract assembly if possible (check compiler output format)
    # The codegen likely emits machine code directly, but we can inspect
    # any debug output or add tracing
  fi
done
```

**If codegen doesn't produce assembly:** Temporarily modify `codegen.mbt` to emit assembly listing for inspection (add debug flag).

### 2. Minimal Test Cases

Create minimal reproduction cases to isolate each bug:

- **004_function**: A single function that returns a constant
- **009_control**: A simple `if` or `for` loop with known values
- **011_enum**: Minimal enum with pattern match on one variant
- **013_pattern**: Simple struct + pattern match

Test these against known-good outputs.

### 3. Trace Codegen Execution

Add debug output to `codegen_expr` and instruction emission:
- Print AST node type being codegen'd
- Print emitted instructions
- Print register allocations

Compare traces for passing vs failing examples.

---

## Bug-Specific Investigation

### Bug A: 004_basic_function (Wrong Return Value)

**Symptom:** Function returning constant 42 instead outputs 80.

**Hypotheses:**
1. Function arguments are bashing the return value location
2. Stack frame layout is wrong (return value in wrong place)
3. Caller/callee saved registers not preserved correctly
4. Constant folding or propagation bug

**Investigation:**
- Add trace: `codegen_function_decl`, `codegen_expr` for return statement
- Check: Where is return value stored? (eax? stack?)
- Compare with codegen for literals in main scope (works in 003)

**Likely fix location:** `codegen.mbt` function calling convention or return value handling.

---

### Bug B: 009_basic_control_flows (Segfault)

**Symptom:** Program with `if`/`for` crashes immediately. Outputs "0" then segfault.

**Hypotheses:**
1. Jump/branch instruction encoding wrong
2. Label addresses computed incorrectly
3. Stack pointer corrupted in control flow blocks
4. Infinite loop detected and skipped? (parser has guard)

**Investigation:**
- Simplify to just `if true { println(1) }` — still crash?
- Simplify to `for i in 0..1 { println(i) }` — check loop setup
- Inspect emitted machine code for jump targets
- Check: Are relative offsets computed correctly?

**Likely fix location:** `emit_inst` match arms for jumps (Jcc, Jmp), label resolution in `codegen_block`.

---

### Bug C: 011_basic_enum (Wrong Enum Pattern)

**Symptom:** Matching on Color enum outputs wrong variant values:
- Expected: Red → Green → Blue → RGBA
- Got: Red → Red → ... (missing others)

**Hypotheses:**
1. Enum variant discriminant values wrong (all Red?)
2. Pattern matching doesn't extract variant correctly
3. Memory layout of enums incorrect (tag not set properly)

**Investigation:**
- Check how enum variants are constructed in codegen
- Check how pattern matching compares discriminants
- Minimal: `let x = Red; match x { Red => ... }` — does it work?

**Likely fix location:** `codegen_enum` or pattern matching codegen in `codegen_match`.

---

### Bug D: 013_pattern_matching (Segfault + Garbage)

**Symptom:** Complex pattern matching crashes. Earlier output shows wrong field values (x:0 vs x:10).

**Hypotheses:**
1. Pattern matching branches reference wrong variables
2. Struct field offsets computed incorrectly
3. Stack corruption from mismatched types in branches
4. Pattern guard evaluation crashes

**Investigation:**
- Isolate: Does `match x { Point(x, y) => println(x) }` work?
- Check: Are struct fields loaded from correct offsets?
- Does pattern matching with multiple branches corrupt memory?
- Compare with simpler pattern matching in 011 (partially works)

**Likely fix location:** `codegen_match`, `codegen_struct_pattern`, field access codegen.

---

## Fix Plan

After investigation identifies root causes, proceed with fixes in this order:

### 1. Fix Function Calls (004)

- Update argument-passing convention
- Ensure return value slot not clobbered
- Test with minimal example until 80 → 42

### 2. Fix Control Flow (009)

- Correct jump offset calculations
- Fix label resolution (absolute vs relative)
- Validate stack management in blocks
- Test with minimal if/for until no crash

### 3. Fix Enum Handling (011)

- Correct enum discriminant values
- Fix variant construction in codegen
- Verify pattern matching discriminates correctly
- Test minimal enum match

### 4. Fix Pattern Matching (013)

- Fix struct field offsets in patterns
- Ensure branch memory layout correct
- Validate nested pattern handling
- Test minimal case, then full example

---

## Validation

After each fix:
1. Re-run affected example individually
2. Re-run full test suite
3. Update this plan with what was fixed
4. Commit with descriptive message

---

## Acceptance

All 13 examples either:
- ✅ PASS (output matches reference)
- ⚠️ PASS* (minor float precision difference acceptable)
- ⏭️ EXPECTED FAIL (012 - runtime not in scope)

No segfaults. No wrong outputs.

---

## Rollout Strategy

**Approach:** One bug at a time, test after each fix.

1. Start with **004** (simplest, likely calling convention)
2. Then **009** (control flow foundational)
3. Then **011** (enum simpler than full pattern matching)
4. Finally **013** (may be resolved by earlier fixes)

If fixes interact (e.g., function calls fix also resolves pattern matching), validate all examples after each fix.

---

## Notes

- Do NOT add runtime support (012 out of scope)
- Float precision degredation (007) is acceptable
- Priorities: correctness > performance > elegance
- Temporary debug code OK in codegen during investigation
