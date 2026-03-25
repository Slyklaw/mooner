# Technology Stack

**Analysis Date:** 2026-03-25

## Languages

**Primary:**
- MoonBit (latest) - The entire compiler is implemented in MoonBit. This includes lexer, parser, code generator, and ELF header generation.

**Secondary:**
- x86_64 Assembly (generated) - The compiler outputs x86_64 ELF executables. Assembly is generated programmatically, not written manually.

## Runtime

**Environment:**
- MoonBit runtime (self-hosted) - The compiler runs on the MoonBit platform and compiles MoonBit source code to native x86_64 ELF executables.

**Package Manager:**
- Moon (moon) - MoonBit's official package manager and build tool.
- Lockfile: Not present (dependencies resolved on each build).

## Frameworks

**Core:**
- None (compiler/tooling) - The project is a standalone compiler with no application framework.

**Testing:**
- Built-in MoonBit test framework - Uses `moon test` with blackbox (`_test.mbt`) and whitebox (`_wbtest.mbt`) test files.

**Build/Dev:**
- `moon build` - Standard MoonBit build command.
- `moon run cmd/main` - Run the compiler CLI.
- `moon fmt` - Code formatter.
- `moon info` - Generate package interface files (`.mbti`).
- `moon test` - Run tests.

## Key Dependencies

**Critical:**
- `moonbitlang/x` (0.4.40) - Extended standard library providing filesystem operations (`@fs.read_file_to_string`, `@fs.write_bytes_to_file`).
- `moonbitlang/async` (0.16.6) - Asynchronous programming support (imported but not heavily used in current code).
- `moonbitlang/core` - Core language standard library providing basic types, `@env.args()`, etc.

**Infrastructure:**
- Not applicable - This is a standalone compiler with no external infrastructure dependencies.

## Configuration

**Environment:**
- `moon.mod.json` - Module metadata, dependencies, and import configuration.
- `moon.pkg` - Per-package dependency declarations and build options.

**Build:**
- No separate build configuration files (build is driven by Moon tooling).

## Platform Requirements

**Development:**
- MoonBit toolchain installed (`moon` command available).
- Linux/x86_64 target platform (compiler generates x86_64 ELF binaries).

**Production:**
- Compiled executables are standalone x86_64 ELF binaries with no runtime dependencies.
- Output requires `chmod +x` to set executable permissions.

---

*Stack analysis: 2026-03-25*