# Mooner - MoonBit to x86_64 Compiler

## What This Is

A compiler written in MoonBit that compiles standard MoonBit language source files to x86_64 Linux ELF binaries. The compiler follows a classic pipeline: `Source Code → Lexer → Parser → Type Checker → Code Generator → ELF Binary`.

## Core Value

Compile standard MoonBit language to working x86_64 Linux executables that match official MoonBit compiler output.

## Requirements

### Validated

- ✓ fn main entry point
- ✓ Integer, float, boolean, char literals
- ✓ Variables (let bindings, mutable assignment, compound assignment)
- ✓ Arithmetic operators (+, -, *, /, %)
- ✓ Bitwise operators (&, |, ^, <<, >>)
- ✓ Comparison operators (==, !=, <, >, <=, >=)
- ✓ Unary operators (-, !)
- ✓ Print/println for strings, ints, floats, chars
- ✓ If/else expressions
- ✓ While/for loops with break/continue
- ✓ Match expressions (int, bool, wildcard patterns)
- ✓ Function definitions and calls
- ✓ Return statements
- ✓ Array literals, indexing, assignment, length(), push(), concatenation, spread
- ✓ Tuple literals and field access
- ✓ String operations (concat, get_char, comparison, length)
- ✓ Unicode escape sequences
- ✓ Struct definitions, construction, field access, mutation, functional update
- ✓ Enum definitions and constructors (simple variants)
- ✓ Test blocks (assert_eq, assert_true, assert_false, inspect)
- — Phase 1-5 features from plan.md

### Active

- [ ] Map type support (008_basic_map - segfaults)
- [ ] Float tuple printing (007_basic_tuple - shows `<tuple>`)
- [ ] Float variable runtime conversion (prints integer part only)
- [ ] Enum pattern matching with data constructors (011_basic_enum)
- [ ] Pattern matching guards and destructuring (013_pattern_matching)
- [ ] Derive(Show) macro

### Out of Scope

- Lambda/anonymous functions
- Generics/type parameters
- Closures
- Complex pattern matching (or patterns, ranges)
- Full optimization passes
- DWARF debug info

## Context

- Project started as educational compiler project
- Existing codebase: lexer.mbt, parser.mbt, type_checker.mbt, codegen.mbt, compiler.mbt
- Examples directory with 13 test cases (7 passing)
- Official MoonBit compiler available for output comparison
- No runtime library - generates syscalls directly

## Constraints

- **Target**: Linux x86_64 (64-bit)
- **ABI**: System V AMD64 ABI
- **Entry**: Single main function
- **Output**: Standalone ELF executable

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Direct syscall code generation | Avoids runtime library dependency | — Pending |
| Stack-based local variables | Simpler code generation | — Pending |
| Parse single top-level function | Simplifies compilation model | — Pending |

---
*Last updated: 2026-02-24 after project initialization*
