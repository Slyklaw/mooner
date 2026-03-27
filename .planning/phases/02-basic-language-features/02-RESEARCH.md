# Phase 2: Basic Language Features - Research

**Date:** 2026-03-25
**Phase:** 2
**Status:** Complete

## Summary

Research on implementing arithmetic operations and control flow in a WASM backend for MoonBit compiler.

## Arithmetic Operations

### i32/i64 arithmetic
- WASM instructions: i32.add, i32.sub, i32.mul, i32.div_s, i32.div_u, i32.rem_s, i32.rem_u
- Signed vs unsigned division/remainder: MoonBit's `/` and `%` operators need mapping based on type (signedness)
- i64 equivalents: i64.add, i64.sub, i64.mul, i64.div_s, i32.div_u, i64.rem_s, i64.rem_u

### f32/f64 arithmetic
- WASM instructions: f32.add, f32.sub, f32.mul, f32.div, f64.add, f64.sub, f64.mul, f64.div
- No remainder for floats (not needed)
- Rounding modes: default nearest, but may need to consider explicit rounding in future

### Implementation notes
- Binary operations: pop two operands, push result
- Type checking: ensure operand types match expected type (i32, i64, f32, f64)
- Overflow: WASM traps on integer overflow (signed) or wraps (unsigned) — match MoonBit semantics (likely wrap for unsigned, trap for signed? need verification)

## Control Flow

### If/Else
- WASM `if` instruction with block type (result type)
- Structure: `if (type) then ... else ... end`
- Condition: i32 value (0 false, non-zero true)
- Need to generate block type based on result type of branches (if any)

### Loops
- WASM `loop` instruction with label for branching
- `loop` creates a label that can be branched to with `br 0` (continue) or `br 1` (break) depending on nesting
- `br_if` for conditional branch
- While loops: condition check at start, branch to loop label if true, else break
- For loops: similar but with initialization and increment (handled at higher level)

### Block labels and branching
- `block` instruction creates a label without looping
- Branch instructions: `br`, `br_if`, `br_table`
- Label indices: relative to current frame (0 = innermost label)
- Early returns: `return` instruction (unwind to function start)

### Return statements
- `return` instruction pops all values and returns from function
- Must ensure correct number of values on stack

## Validation Architecture

### Test Strategy
- Unit tests for each arithmetic instruction (i32, i64, f32, f64)
- Integration tests with small MoonBit programs that exercise arithmetic and control flow
- Compare output with x86_64 backend to ensure semantic equivalence
- Use wasm-validate to verify generated binary correctness

### Edge Cases
- Division by zero (WASM traps, MoonBit may have defined behavior? Need to decide)
- Overflow/underflow (signed vs unsigned)
- Float NaN/Infinity handling (WASM follows IEEE 754)

## References
- WebAssembly specification: https://webassembly.github.io/spec/core/
- WASM instruction list: https://webassembly.github.io/spec/core/instructions.html
- MoonBit arithmetic semantics: (to be determined)

---
*Research completed: 2026-03-25*