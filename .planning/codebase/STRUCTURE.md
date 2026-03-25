# Codebase Structure

**Analysis Date:** 2026-03-25

## Directory Layout

```
moonbit/mooner/
├── lexer.mbt                 # Tokenizer implementation (Token enum, Lexer struct)
├── parser.mbt                # Parser implementation (AST enum, Parser struct)
├── codegen.mbt               # x86_64 code generator (CodeGen struct)
├── compiler.mbt              # ELF header generation and compilation orchestration
├── double_ryu_nonjs.mbt      # Ryu float-to-string algorithm (for IEEE 754 doubles)
├── mooner_test.mbt           # Blackbox tests (E2E compilation tests)
├── mooner_wbtest.mbt         # Whitebox tests (internal unit tests)
├── moon.mod.json             # Module metadata (dependencies, version)
├── moon.pkg                  # Package dependencies (imports)
├── pkg.generated.mbti        # Generated interface file (do not edit)
├── cmd/
│   └── main/
│       ├── main.mbt          # CLI entry point
│       └── moon.pkg          # Subpackage dependencies
├── examples/                 # Example MoonBit source files and compiled outputs
│   ├── mbt_examples/         # Official MoonBit examples for verification
│   └── test_*.mbt            # Various test programs (each with .exe counterpart)
├── harness/
│   └── minimal/              # Minimal executable examples (with README)
├── .github/
│   └── workflows/            # CI configuration (copilot-setup-steps.yml)
├── .githooks/                # Git hooks (pre-commit)
├── .mooncakes/               # MoonBit package cache (external dependencies)
├── _build/                   # Build artifacts (generated)
└── *.py                      # Utility scripts (fix_all.py, add_jmp.py, etc.)
```

## Directory Purposes

**Root directory:**
- Purpose: Contains core compiler modules and package configuration.
- Contains: All main `.mbt` source files, `moon.mod.json`, `moon.pkg`.
- Key files: `lexer.mbt`, `parser.mbt`, `codegen.mbt`, `compiler.mbt`.

**`cmd/main/`:**
- Purpose: Command‑line interface entry point.
- Contains: `main.mbt` (CLI logic), `moon.pkg` (sub‑package config).
- Key files: `main.mbt` (invokes `@mooner.compile_file`).

**`examples/`:**
- Purpose: Test programs and their compiled outputs.
- Contains: `.mbt` source files and corresponding `.exe` executables.
- Key files: `mbt_examples/` (official examples for verification).

**`harness/minimal/`:**
- Purpose: Minimal working examples for reference.
- Contains: Small `.mbt` programs with pre‑compiled `.exe` files.
- Key files: `README.md` (description of minimal examples).

**`.github/workflows/`:**
- Purpose: Continuous integration configuration.
- Contains: `copilot-setup-steps.yml` (GitHub Actions workflow).

**`.githooks/`:**
- Purpose: Git hooks for code quality.
- Contains: `pre-commit` (formatting checks via `moon fmt`).

**`.mooncakes/`:**
- Purpose: External MoonBit package cache (managed by MoonBit toolchain).
- Contains: Dependencies (`moonbitlang/x`, `moonbitlang/core`).
- Generated: Yes (do not edit).
- Committed: No (should be in `.gitignore`).

## Key File Locations

**Entry Points:**
- `cmd/main/main.mbt`: CLI entry point (`main` function).
- `compiler.mbt`: Compilation API entry point (`compile_file` function).

**Configuration:**
- `moon.mod.json`: Module metadata (name, version, dependencies).
- `moon.pkg`: Package‑level imports.
- `cmd/main/moon.pkg`: Sub‑package imports.

**Core Logic:**
- `lexer.mbt`: Tokenization (token types and lexer).
- `parser.mbt`: Parsing (AST nodes and parser).
- `codegen.mbt`: x86_64 instruction generation.
- `compiler.mbt`: ELF header assembly and file output.
- `double_ryu_nonjs.mbt`: Float‑to‑string conversion (used for printing floats).

**Testing:**
- `mooner_test.mbt`: Blackbox integration tests (run via `moon test`).
- `mooner_wbtest.mbt`: Whitebox unit tests (internal package tests).
- `run_e2e_tests.sh`: End‑to‑end verification script (compares with official compiler).
- `test_examples.sh`: Batch verification of example outputs.

## Naming Conventions

**Files:**
- Core compiler modules: lowercase with underscores (`lexer.mbt`, `parser.mbt`, `codegen.mbt`).
- Entry point: `main.mbt` (inside `cmd/main/`).
- Test files: `_test.mbt` (blackbox) and `_wbtest.mbt` (whitebox).
- Generated interface: `pkg.generated.mbti`.

**Directories:**
- Lowercase, single‑word where possible (`cmd`, `examples`, `harness`).
- Multi‑word uses underscores (`moon.bit` → `.mooncakes`).

**Functions:**
- CamelCase for public functions (`compile_file`, `tokenize`, `parse`, `codegen`).
- Snake_case for internal helpers (e.g., `parse_expression` inside parser).

**Types:**
- PascalCase for enum/struct names (`Token`, `AST`, `CodeGen`, `Parser`).
- Enum variants: PascalCase (`Token::Fn`, `AST::Int`).

**Variables:**
- Snake_case (`input_path`, `output_path`, `debug_level`).
- Prefix `var_` for tracked variables in `CodeGen` (e.g., `var_offsets`, `var_types`).

## Where to Add New Code

**New Language Feature:**
- Lexer changes: Add new token variants to `Token` enum in `lexer.mbt`.
- Parser changes: Add new AST variants to `AST` enum in `parser.mbt` and parsing rules.
- Code generation: Extend `codegen.mbt` to emit instructions for new constructs.

**New Compiler Pass (e.g., optimization):**
- Create a new file (e.g., `optimize.mbt`) in the root directory.
- Import and use it in `compiler.mbt` between parsing and code generation.

**New CLI Subcommand:**
- Add a new subdirectory under `cmd/` (e.g., `cmd/interpret/`).
- Follow same pattern as `cmd/main/` with its own `moon.pkg`.

**Utility Functions:**
- Place in a new `util.mbt` file in the root directory.
- Export public functions for reuse across modules.

**Tests:**
- Blackbox tests: Add to `mooner_test.mbt` or create new `*_test.mbt` files.
- Whitebox tests: Add to `mooner_wbtest.mbt` or create new `*_wbtest.mbt` files.
- Example programs: Add `.mbt` files to `examples/` (and compile to `.exe`).

## Special Directories

**`.mooncakes/`:**
- Purpose: External MoonBit package cache (managed by MoonBit toolchain).
- Generated: Yes.
- Committed: No (should be in `.gitignore`).

**`_build/`:**
- Purpose: Build artifacts (compiled packages, etc.).
- Generated: Yes.
- Committed: No.

**`.git/`:**
- Purpose: Git repository metadata.
- Generated: Yes.
- Committed: Yes.

---

*Structure analysis: 2026-03-25*
