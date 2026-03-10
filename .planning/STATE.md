# State: Mooner Compiler

## Project Reference

**Project Name:** Mooner  
**Core Value:** Compile standard MoonBit language to working x86_64 Linux executables that match official MoonBit compiler output.  
**Current Focus:** Phase 3 - Enum & Pattern Matching

## Current Position

| Attribute | Value |
|-----------|-------|
| **Phase** | 3 - Enum & Pattern Matching |
| **Status** | In Progress - user function returns fixed |
| **Progress** | [===-] 60% |

## Phase 1-2: Complete

### Completed Features (from PROJECT.md)

- fn main entry point
- Integer, float, boolean, char literals
- Variables (let bindings, mutable assignment, compound assignment)
- Arithmetic operators (+, -, *, /, %)
- Bitwise operators (&, |, ^, <<, >>)
- Comparison operators (==, !=, <, >, <=, >=)
- Unary operators (-, !)
- Print/println for strings, ints, floats, chars
- If/else expressions
- While/for loops with break/continue
- Match expressions (int, bool, wildcard patterns)
- Function definitions and calls
- Return statements
- Array literals, indexing, assignment, length(), push(), concatenation, spread
- Tuple literals and field access
- String operations (concat, get_char, comparison, length)
- Unicode escape sequences
- Struct definitions, construction, field access, mutation, functional update
- Enum definitions and constructors (simple variants)
- Test blocks (assert_eq, assert_true, assert_false, inspect)
- Map type support

## Phase 3: In Progress

### Fixed in Phase 3

1. **User function return values** - ✓ FIXED
   - Block handling now properly processes ReturnExpr
   - Functions with explicit return work: `fn f() -> Int { return 99 }`
   - Functions with expression body work: `fn f() -> Int { a + b }`

2. **Function call in println** - ✓ FIXED  
   - Added CallExpr handling in println argument processing
   - `println(add(2, 40))` now works correctly

### Remaining Issues

1. **Pattern matching guards/destructuring (013_pattern_matching)** - Not supported
2. **Derive(Show) macro** - Not implemented
3. **Enum field extraction** - Minor issue with RGB(r,g,b) field values
4. **Float precision** - Some float operations show precision differences

### Test Results

| Example | Status |
|---------|--------|
| 003_basic_constants | ✓ PASS |
| 004_basic_function | ✓ PASS |
| 005_basic_array | ✓ PASS |
| 008_basic_map | ✓ PASS |
| 009_basic_control_flows | ✓ PASS |
| 010_basic_struct | ✓ PASS |
| 006_basic_string | Minor diff |
| 007_basic_tuple | Float precision |
| 011_basic_enum | Field values |

## Key Decisions

| Decision | Rationale | Status |
|----------|-----------|--------|
| Direct syscall code generation | Avoids runtime library dependency | Working |
| Stack-based local variables | Simpler code generation | Working |
| Parse single top-level function | Simplifies compilation model | Working |

## Session Continuity

### What's Ready

- Phase 1-2: Complete ✓
- Phase 3: Core user function support working
- Examples: Most basic examples pass

### Next Steps

1. Fix remaining enum field extraction issue
2. Implement pattern matching guards/destructuring
3. Implement Derive(Show) macro

### Blockers

- None

---

*Last updated: 2026-03-09*
