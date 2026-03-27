# MoonBit WASM Backend

## What This Is

A WebAssembly compilation target for the MoonBit compiler. Currently compiles MoonBit source code to x86_64 ELF executables; this project adds WASM output as an alternative backend.

## Core Value

Enable MoonBit programs to run in WebAssembly environments (browsers, WASI runtimes) while reusing the existing MoonBit compiler frontend.

## Current Milestone: v1.1 Stabilization

**Goal:** Fix critical bugs that make the WASM backend unstable

**Target features:**
- Fix control flow crash (009 example) — segfaults on if/for constructs
- Fix pattern matching crash (013 example) — segfaults on struct patterns
- Fix function return value corruption (004 example) — incorrect return values
- Fix enum pattern mismatch (011 example) — incorrect discriminant handling
- Add verification tests for each bug fix
- Add regression tests to prevent reoccurrence

**Excluded:**
- Float parsing exponent support (defer to v1.2)
- New language features or optimizations

## Requirements

### Validated

- ✓ MoonBit language compilation (lexer, parser, codegen) — existing
- ✓ x86_64 ELF executable generation — existing
- ✓ Command-line interface (`moon run cmd/main`) — existing
- ✓ File I/O (read source, write output) — existing
- ✓ Basic language features (functions, variables, arithmetic, control flow) — existing
- ✓ WebAssembly backend (WASM binary generation) — v1.0
- ✓ Integration with existing frontend (reuse lexer/parser) — v1.0
- ✓ Maintain compatibility with existing CLI — v1.0
- ✓ WASM module structure (sections, exports, imports) — v1.0
- ✓ Support for basic language features in WASM (functions, locals, control flow) — v1.0
- ✓ Code generation abstraction (strategy pattern) — v1.0

### Active

- [ ] Fix control flow crash (009 example) — segfaults on if/for
- [ ] Fix pattern matching crash (013 example) — segfaults on struct patterns
- [ ] Fix function return value corruption (004 example) — wrong return values
- [ ] Fix enum pattern mismatch (011 example) — incorrect discriminants
- [ ] Add verification tests for bug fixes
- [ ] Add regression tests to prevent reoccurrence

### Out of Scope

- Rewriting frontend — reuse existing lexer/parser
- Adding new language features — focus on stabilization first
- Optimizing existing x86_64 backend — parallel work
- Advanced WASM features (SIMD, threads, bulk memory) — defer to future
- WASI integration — initial target is standalone WASM modules
- Float parsing exponent support — deferred to v1.2
- Component Model support — adds complexity
- Debug information (DWARF) — useful but not required for correctness

## Context

**Project background:**
- Existing compiler is a MoonBit-to-x86_64 ELF compiler written in MoonBit
- Codebase includes `lexer.mbt`, `parser.mbt`, `codegen.mbt`, `compiler.mbt`, `cmd/main/main.mbt`
- Architecture is a simple pipeline: source → tokens → AST → x86_64 bytes → ELF file
- The compiler currently generates x86_64 machine code directly in `codegen.mbt`
- ELF header generation is in `compiler.mbt`

**Technical environment:**
- MoonBit language and toolchain (`moon build`, `moon run`, `moon test`)
- Target platform: WebAssembly (WASM) binary format
- No external dependencies required for WASM generation (pure byte manipulation)

**Known issues to address:**
- Current codegen is tightly coupled to x86_64 instruction set
- Need to abstract code generation to support multiple backends
- WASM has different memory model and execution semantics than x86_64

## Constraints

- **Tech stack**: Must implement in MoonBit (project is self-hosted)
- **Compatibility**: Must not break existing x86_64 backend
- **Architecture**: Should allow future backends (ARM, RISC-V) with similar abstraction
- **Dependencies**: Avoid external dependencies; keep compiler standalone

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Reuse existing frontend | Lexer/parser are mature and language-agnostic | — Pending |
| Abstract code generation | Enable multiple backends without duplication | — Pending |
| Start with basic WASM features | Validate approach before adding complexity | — Pending |
| Keep CLI compatible | Users shouldn't need new commands | — Pending |
| Stabilize before new features | Cannot add functionality on broken foundation | ✓ Good (v1.1 focused on bug fixes) |

---
*Last updated: 2026-03-26 after starting v1.1 stabilization milestone*