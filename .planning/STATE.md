# State: Mooner Compiler

## Project Reference

**Project Name:** Mooner  
**Core Value:** Compile standard MoonBit language to working x86_64 Linux executables that match official MoonBit compiler output.  
**Current Focus:** Phase 1 - Map Support

## Current Position

| Attribute | Value |
|-----------|-------|
| **Phase** | 1 - Map Support |
| **Plan** | Not started |
| **Status** | Ready to begin |
| **Progress** | [----------] 0% |

### Phase Context

- **Phase Goal:** Users can create maps with literal syntax, access values by key, update values, and use maps without crashes
- **Requirements in Phase:** 4 (MAP-01 to MAP-04)
- **Success Criteria:** 4

## Performance Metrics

| Metric | Value |
|--------|-------|
| Total v1 Requirements | 15 |
| Requirements Completed | 0 |
| Requirements Pending | 15 |
| Phases Completed | 0/4 |
| Examples Passing | 7/13 |
| Examples Blocked | 6 |

## Accumulated Context

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

1. **Map type (008_basic_map)** - Segfaults when used
2. **Float tuple printing (007_basic_tuple)** - Shows `<tuple>` for float tuples
3. **Float variable runtime conversion** - Prints integer part only
4. **Enum pattern matching with data (011_basic_enum)** - Incomplete
5. **Pattern matching guards/destructuring (013_pattern_matching)** - Not supported
6. **Derive(Show) macro** - Not implemented

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

1. Begin Phase 1 implementation: Map literal syntax in parser
2. Add Map type to type checker
3. Implement map code generation in codegen.mbt
4. Test with 008_basic_map example
5. Fix any segfaults

### Blockers

- None identified for Phase 1 start

---

*Last updated: 2026-02-24*
