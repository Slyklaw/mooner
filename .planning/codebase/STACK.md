# Technology Stack

**Analysis Date:** 2026-03-26

## Languages

**Primary:**
- MoonBit (0.1.0) - Systems programming language, this is a self-hosted compiler project

**Secondary:**
- None detected

## Runtime

**Environment:**
- Native: x86_64 Linux ELF executables
- WebAssembly (WASM) for browser/embedded targets

**Package Manager:**
- `moon` - MoonBit's built-in package manager and build tool
- Lockfile: Not applicable (MoonBit uses `moon.pkg` manifests)

## Frameworks

**Core:**
- MoonBit compiler framework (custom-built) - Compiler infrastructure including lexer, parser, codegen

**Build/Dev:**
- `moon build` - Build the compiler
- `moon run cmd/main` - Run the compiler on source files
- `moon test` - Run test suite (blackbox `_test.mbt` and whitebox `_wbtest.mbt`)
- `moon fmt` - Code formatter
- `moon info` - Generate package interface files (`.mbti`)

## Key Dependencies

**Standard Library:**
- `moonbitlang/x` (v0.4.40) - Core standard library including filesystem (`fs`), crypto, numeric types
  - Used for: `@fs.read_file_to_string()` in `compiler.mbt:60`
  - Import path: `moonbitlang/x/fs` in `moon.pkg`
- `moonbitlang/async` (v0.16.6) - Async runtime (declared but not actively used in compiler)
- `moonbitlang/core` - Core language primitives (implicit import)

**Internal Modules:**
- `username/mooner` (this package) - Library providing compiler backend interface
  - Exports: `compile_file_target`, AST types, `Backend` trait, code generation structs
  - See `pkg.generated.mbti` for full interface

**Build System:**
- MoonBit's native build system (via `moon` CLI)
- No external build tools (Make, CMake, etc.)

## Configuration

**Environment:**
- No `.env` file or environment variable configuration detected
- All configuration via command-line arguments

**Command-line Interface:**
```bash
moon run cmd/main <input_file> [output_file] [--target wasm|x86_64] [--debug]
```

Target selection (priority order):
1. `--target` flag: `--target wasm` or `--target x86_64`
2. Output file extension: `.wasm` → WASM, `.exe` → x86_64
3. Default: x86_64

**Build Configuration:**
- No `tsconfig.json`, `.eslintrc`, `.prettierrc` or similar JavaScript tooling configs
- MoonBit uses its own formatting (`moon fmt`) and language server (`moon ide`)

## Platform Requirements

**Development:**
- MoonBit toolchain installed (via `curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash`)
- Linux/macOS development environment
- `moon` CLI commands available

**Production:**
- x86_64 Linux for native executables (ELF format)
- WebAssembly runtime for `.wasm` outputs (browser, WASM runtime)
- No runtime dependencies - executables are standalone

## Architecture Notes

This is a **self-hosted compiler** project:
- Written in MoonBit itself
- Compiles MoonBit source to x86_64 ELF or WebAssembly
- Components: lexer (`lexer.mbt`), parser (`parser.mbt`), codegen (`codegen.mbt`), compiler (`compiler.mbt`), backends (`backend.mbt`, `wasm_backend.mbt`)
- Entry point: `cmd/main/main.mbt`
- No external services or APIs integrated

---

*Stack analysis: 2026-03-26*
