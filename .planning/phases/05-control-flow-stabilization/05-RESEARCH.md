# Phase 5 Research: Control Flow Stabilization

**Date:** 2026-03-26  
**Phase:** 5 — Control Flow Stabilization  
**Goal:** Eliminate segfaults in control flow constructs (if/else, loops) so WASM backend can correctly compile and execute 009_basic_control_flows example.

---

## Technical Context

The MoonBit compiler uses a code generation abstraction with backends. The WASM backend (`wasm_backend.mbt`) generates WASM binary code. Control flow constructs (if, for, while, block) compile to WASM `block`, `loop`, `br`, `br_if` instructions.

Key components:
- `CodeGen` struct in `codegen.mbt` (8,635 lines — monolithic)
- Label management: `define_label`, `pending_labels`, backpatching mechanism
- Instruction emission: `emit_inst` (1800+ line match statement)
- Jump instructions: `emit_jmp`, `emit_je`, `emit_jne`, etc.

WASM uses structured control flow with nested blocks. Labels must resolve to correct relative offsets after code generation.

---

## Root Cause Analysis

From CONCERNS.md Bug 1:

**Symptoms:** Program outputs "0" then segfaults on any `if` or `for` construct.

**Likely cause:** Incorrect jump offset calculation or label resolution in `emit_jmp` family of instructions.

**Why this happens:**
- WASM requires precise relative offsets for branch targets
- The label backpatching system (`define_label` + `pending_labels`) likely has bugs:
  - Labels may be defined at wrong positions (offset mis-calculation)
  - Pending jumps may not be patched correctly after label definition
  - Multiple passes may leave unresolved placeholders
- Alternatively, stack corruption from mismatched block nesting

---

## Specific Files to Modify

Based on CONCERNS.md and codebase structure:

1. **`codegen.mbt`** — Primary target
   - Functions to inspect/fix:
     - `define_label` — how labels register their position
     - `emit_jmp`, `emit_je`, `emit_jne`, `emit_jg`, etc. — jump emission with offset calculation
     - `pending_labels` resolution mechanism
     - `emit_block`, `emit_loop`, `emit_if` — block structure handling
   - Look for: incorrect offset arithmetic, forgetting to backpatch, wrong sign on relative jumps

2. **`wasm_backend.mbt`** (if separate) — WASM-specific emission
   - Check if jump helpers are implemented correctly
   - Verify WASM block/loop instruction encoding

3. **Tests to add/modify:**
   - Unit tests in `codegen_test.mbt` or `wasm_backend_test.mbt`
   - Regression test: ensure `examples/mbt_examples/009_basic_control_flows.mbt` compiles and runs correctly

---

## Test Strategy

**Verification tests (TEST-01):**
- Write a unit test that compiles a small MoonBit function with if/else and loops
- Target WASM backend
- Execute the WASM (via WASI or interpreter) and assert correct output
- Example scenarios:
  ```moonbit
  fn if_test(x: Int) -> Int {
    if x > 0 { 1 } else { 0 }
  }
  fn loop_test(n: Int) -> Int {
    var sum = 0
    var i = 0
    while i < n {
      sum = sum + i
      i = i + 1
    }
    sum
  }
  ```

**Regression tests (TEST-05):**
- Add the existing `009_basic_control_flows.mbt` example to CI
- Compile to WASM and run
- Assert output matches expected (should not segfault)
- Ensure test fails if segfault returns

---

## Validation Approach

1. **Manual verification:**
   ```
   moon run cmd/main examples/mbt_examples/009_basic_control_flows.mbt --target wasm
   chmod +x examples/mbt_examples/009_basic_control_flows.exe  # actually .wasm
   # Run with wasm-opt or wasm-interpreter if available, or compare output to official compiler
   ```

2. **Automated test:**
   - Add to existing blackbox test suite (`mooner_test.mbt` or dedicated `wasm_stability_test.mbt`)
   - Test should compile and execute, not just check non-zero output

3. **Comparison:**
   - Use official MoonBit compiler to compile same source to WASM and compare binary or output
   - Or have expected output snapshot

---

## Pitfalls to Avoid

1. **Offset direction confusion:** WASM uses relative offsets from current position. Remember: jump target = label_position - (current_position + jump_instruction_size). Easy to get sign wrong.

2. **Label scoping:** Nested blocks create label scopes. Ensure label resolution matches correct block depth. Don't allow jumps to labels in different blocks.

3. **Backpatch timing:** Define label before or after emitting jumps? Typical approach:
   - Emit jump with placeholder offset (0) and record pending label in a list
   - When label is defined, go back and fill in correct offset for all pending jumps
   - If order is reversed (label before jump), emit direct jump with computed offset

4. **Placeholder size:** If placeholder is 1 byte but actual offset needs 5 bytes (LEB128), buffer overflow or misalignment. Use a fixed-size placeholder (e.g., 4 bytes) or re-encode after all labels known (two-pass).

5. **WASI module boundaries:** If example uses I/O (println), ensure imports are declared correctly. Import mismatches can cause runtime traps that look like segfaults.

6. **Testing environment:** Running WASM in wrong environment (e.g., plain Linux binary instead of WASI) will crash. Ensure test runner uses `wasm-opt`/`wasm-run` or proper WASI host.

---

## Related Concerns from CONCERNS.md

- **Label Resolution** (p. 144): Two-pass backpatching is bug-prone. Verify that every pending label eventually gets resolved. Check for "label never defined" or "defined multiple times" bugs.

- **Control Flow Crash** (p. 33-39): Existing bug description. Fix approach: inspect `define_label` and pending label resolution; verify relative offset calculations.

---

## Implementation Checklist

- [ ] Understand current label handling in `codegen.mbt`
- [ ] Identify specific bug: wrong offset calculation or failed backpatch
- [ ] Fix offset math (watch sign and size)
- [ ] Ensure all jump types use same mechanism (consistent)
- [ ] Add unit test for basic if/else
- [ ] Add unit test for loops (while, for)
- [ ] Add regression test using 009 example
- [ ] Run full test suite to ensure no regressions in x86_64 backend
- [ ] Verify WASM validator passes (`wasm-validate` if available)

---

## Questions to Resolve During Planning

- Should we refactor label handling entirely or patch the bug?
- Do we need a two-pass approach for guaranteed correctness?
- How to test WASM execution in CI without external tools? (Maybe use Node.js runner or WASI SDK)
- Should we add debug assertions to catch unresolved labels?

---

*Research prepared based on CONCERNS.md analysis and codebase review.*
