# Technology Stack

**Analysis Date:** 2026-03-11

## Languages

**Primary:**
- MoonBit - Custom language for writing the compiler itself

**Secondary:**
- Shell scripting (Bash) - E2E test orchestration in `run_e2e_tests.sh` and `test_examples.sh`

## Runtime

**Environment:**
- MoonBit runtime compiling to native x86_64 ELF executables
- Target architecture: x86-64 (AMD64)
- Output format: ELF executables with custom headers

**Package Manager:**
- MoonBit built-in package manager via `moon.mod.json` and `moon.pkg` files
- Lockfile: Not used (MoonBit uses version constraints in `moon.mod.json`)
- Dependencies managed through `moon.mod.json` "deps" section

## Frameworks

**Core:**
- `moonbitlang/core` - MoonBit standard library (imported implicitly)
- `moonbitlang/x` (0.4.40) - Experimental packages including filesystem (`fs`)
- `moonbitlang/async` (0.16.6) - Asynchronous programming library

**Testing:**
- MoonBit built-in testing framework:
  - Blackbox tests: `_test.mbt` files (e.g., `mooner_test.mbt`)
  - Whitebox tests: `_wbtest.mbt` files (e.g., `mooner_wbtest.mbt`)

**Build/Dev:**
- `moon build` - Builds the project
- `moon run` - Runs MoonBit programs
- `moon test` - Executes tests
- `moon fmt` - Formats code
- `moon info` - Updates/generates package interface files (`.mbti`)
- `moon ide` - Provides IDE integration (peek-def, outline, find-references)

## Key Dependencies

**Critical:**
- `moonbitlang/x/fs` - Filesystem operations for reading source files and writing ELF binaries (used in `compiler.mbt:7`, `compiler.mbt:113`)
- `moonbitlang/core/env` - Environment access for CLI argument parsing (used in `cmd/main/main.mbt:5`)

**Infrastructure:**
- `moonbitlang/async` - Future async capabilities (currently in deps but not actively used in compiler code)
- `moonbitlang/x` - Collection of experimental utilities

## Configuration

**Project Metadata:**
- `moon.mod.json` - Root project configuration with:
  - Name: `username/mooner`
  - Version: `0.1.0`
  - Dependencies: `moonbitlang/x:0.4.40`, `moonbitlang/async:0.16.6`
  - Imports: `moonbitlang/x`, `moonbitlang/core`

**Package Configuration:**
- `moon.pkg` - Root package dependencies (imports `moonbitlang/x/fs`)
- `cmd/main/moon.pkg` - CLI entry point package configuration
  - Imports: `moonbitlang/core/env`, `username/mooner` (@lib)
  - Options: `"is-main": true`

**Build Configuration:**
- No separate build config files (.buildozer, tsconfig, etc.)
- All configuration is in `moon.mod.json` and `moon.pkg`

## Generated Artifacts

- `.mbti` files - Generated interface files (e.g., `pkg.generated.mbti`)
- `_build/` directory - Build outputs
- `.mooncakes/` directory - Downloaded dependencies (package cache)

## Platform Requirements

**Development:**
- MoonBit toolchain installed
- Bash shell for running test scripts
- Linux/Unix environment (scripts use bash)

**Production:**
- Target: x86_64 Linux/Unix systems
- Output: Standalone ELF executables (no runtime dependency)
- Executables require `chmod +x` after generation

---

*Stack analysis: 2026-03-11*
