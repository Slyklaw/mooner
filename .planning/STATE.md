# State: Mooner Compiler

## Project Reference

**Project Name:** Mooner  
**Core Value:** Compile standard MoonBit language to working x86_64 Linux executables that match official MoonBit compiler output.  
**Current Focus:** Phase 2 - Tuple & Float Improvements

## Current Position

| Attribute | Value |
|-----------|-------|
| **Phase** | 2 - Tuple & Float Improvements |
| **Status** | In Progress - float fixes implemented |
| **Progress** | [==--] 40% |

## Phase 1: Complete

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

### Active Issues (blocking v1)

1. **Map type (008_basic_map)** - ✓ FIXED - Working correctly
2. **Float tuple printing (007_basic_tuple)** - ✓ FIXED - Now prints floats correctly (2.1 vs official 2.099...)
3. **Float variable runtime conversion** - ✓ FIXED - Now prints full float value (2.1 not 3.0)
4. **String printing (006_basic_string)** - Minor diff: shows "Use <string>. Happy coding" extra line
5. **Enum pattern matching with data (011_basic_enum)** - Not implemented
6. **Pattern matching guards/destructuring (013_pattern_matching)** - Not supported
7. **Derive(Show) macro** - Not implemented

### Key Decisions

| Decision | Rationale | Status |
|----------|-----------|--------|
| Direct syscall code generation | Avoids runtime library dependency | Working |
| Stack-based local variables | Simpler code generation | Working |
| Parse single top-level function | Simplifies compilation model | Working |

## Session Continuity

### What's Ready

- Phase 1: Map Support requirements are clear
- Examples: 008_basic_map ready to test after implementation
- Codebase: lexer.mbt, parser.mbt, type_checker.mbt, codegen.mbt well-structured

### Next Steps

1. Phase 1: Map Support - COMPLETE ✓
2. Proceed to Phase 2: Fix float tuple printing and float runtime conversion

### Blockers

- None - Phase 1 is complete

---

*Last updated: 2026-03-09*
