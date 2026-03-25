# MoonBit WASM Backend

## What This Is

A WebAssembly compilation target for the MoonBit compiler. Currently compiles MoonBit source code to x86_64 ELF executables; this project adds WASM output as an alternative backend.

## Core Value

Enable MoonBit programs to run in WebAssembly environments (browsers, WASI runtimes) while reusing the existing MoonBit compiler frontend.

## Requirements

### Validated

- ✓ MoonBit language compilation (lexer, parser, codegen) — existing
- ✓ x86_64 ELF executable generation — existing
- ✓ Command-line interface (`moon run cmd/main`) — existing
- ✓ File I/O (read source, write output) — existing
- ✓ Basic language features (functions, variables, arithmetic, control flow) — existing

### Active

- [ ] WebAssembly backend (WASM binary generation)
- [ ] Integration with existing frontend (reuse lexer/parser)
- [ ] Maintain compatibility with existing CLI
- [ ] WASM module structure (sections, exports, imports)
- [ ] Support for basic language features in WASM (functions, locals, control flow)

### Out of Scope

- Rewriting frontend — reuse existing lexer/parser
- Adding new language features — focus on WASM backend only
- Optimizing existing x86_64 backend — parallel work
- Advanced WASM features (SIMD, threads, bulk memory) — defer to future
- WASI integration — initial target is standalone WASM modules

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

---
*Last updated: 2026-03-25 after initialization*