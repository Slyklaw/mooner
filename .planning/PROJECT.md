# MoonBit Compiler — Self-Hosting Completion

## What This Is

A MoonBit compiler implementation that compiles a simple language to x86_64 ELF executables. The compiler currently passes 8 of 13 test examples; 3 have critical codegen bugs causing incorrect output or segfaults, 1 has acceptable float precision degradation, and 1 is out of scope due to missing runtime support.

Goal: Fix the codegen bugs to make all 13 examples produce correct output (with 012 acknowledged as expected failure).

## Core Value

The compiler generates correct, executable output for all language features covered by the test suite. If everything else fails, the examples must pass.

## Requirements

### Validated

- ✓ COMP-01 — Function calls with arguments return correct values (Phase 2)

### Active

- **COMP-01**: Function calls with arguments return correct values (fix example 004)
- **COMP-02**: Control flow constructs (if, for, while) execute without crashes (fix example 009)
- **COMP-03**: Enum pattern matching discriminates variants correctly (fix example 011)
- **COMP-04**: Pattern matching on structured data (structs, nested patterns) works without crashes (fix example 013)
- **COMP-05**: All 13 examples pass verification against reference outputs (with 012 as expected failure)

### Out of Scope

- **Runtime library support** — Example 012 requires test framework runtime, explicitly out of scope
- **New language features** — Only bug fixes, no feature expansion
- **Float precision improvements** — Example 007's minor degradation is acceptable
- **Performance optimizations** — Correctness over speed

## Context

The compiler consists of:
- `lexer.mbt` - Tokenizer
- `parser.mbt` - Parser producing ASTs
- `codegen.mbt` - x86_64 code generator (primary bug location)
- `compiler.mbt` - Entry point, ELF emission
- `cmd/main/main.mbt` - CLI

Comprehensive codebase analysis exists in `.planning/codebase/`:
- Architecture, stack, conventions, concerns, integrations, testing, structure

Test suite: `examples/mbt_examples/001` through `013` with reference outputs. Current status: 8 passing, 3 failing (009, 011, 013), 1 acceptable (007), 1 out-of-scope (012).

## Constraints

- **Bug scope**: Only codegen fixes, no parser changes, no runtime additions
- **Validation**: Output must match official MoonBit compiler exactly (except 012, 007)
- **Testing**: After each fix, run full test suite to prevent regressions
- **Commit discipline**: Atomic commits with descriptive messages

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Focus exclusively on codegen bugs | Parser and lexer appear correct; failures trace to codegen | — Pending |
| Fix order: 004 → 009 → 011 → 013 | Dependency chain: function calls foundational; control flow next; enums before full pattern matching | — Pending |
| Allow temporary debug code in codegen | Needed for investigation; will be cleaned up | — Pending |
| Phase 2: Implement full System V ABI compliance | Parameter offset miscalculation and stack cleanup overrun caused function call failures | ✓ Fixed: 004 returns 42, all passing tests still pass |

---

*Last updated: 2026-03-11 after Phase 2 completion*
