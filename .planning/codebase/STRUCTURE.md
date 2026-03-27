# Codebase Structure

**Analysis Date:** 2026-03-26

## Directory Layout

```
[project-root]/
├── .mooncakes/              # Dependency package cache (generated, not committed)
│   └── moonbitlang/
│       ├── x/               # Standard library packages (fs, sys, crypto, etc.)
│       └── ...
├── .planning/               # Project planning documents
│   └── codebase/            # Codebase analysis documents (this directory)
├── cmd/                     # Command-line interface and entry points
│   └── main/
│       └── main.mbt         # CLI entry point
├── examples/                # Sample MoonBit source files for testing
│   ├── *.mbt
│   └── mbt_examples/
├── .gitignore               # Git ignore rules
├── AGENTS.md                # Agent instructions and project conventions
├── backend.mbt              # Backend trait and target abstraction
├── codegen.mbt              # x86_64 code generator (CodeGen, X86Inst, X86Operand)
├── compiler.mbt             # Compilation orchestration, ELF generation
├── double_ryu_nonjs.mbt     # Float-to-string algorithm (IEEE 754)
├── lexer.mbt                # Lexical analyzer (Token, Lexer)
├── parser.mbt               # Parser (AST, Parser)
├── wasm_backend.mbt         # WebAssembly backend implementation
├── moon.mod.json            # MoonBit module metadata
├── moon.pkg                 # Package dependencies (per-directory)
├── README.md                # Project documentation
└── [test files]             # mooner_test.mbt, mooner_wbtest.mbt
```

## Directory Purposes

**Root Directory:**
- Purpose: Contains all core compiler source files and project configuration
- Contains: `.mbt` source files for lexer, parser, codegen, compiler; backend implementations; configuration files
- Key files: `lexer.mbt`, `parser.mbt`, `codegen.mbt`, `compiler.mbt`, `backend.mbt`, `wasm_backend.mbt`

**`cmd/main/`:**
- Purpose: Command-line interface and executable entry point
- Contains: `main.mbt` - argument parsing, target selection, invocation of compiler
- Key files: `cmd/main/main.mbt`

**`examples/`:**
- Purpose: Sample MoonBit source files for manual testing and demonstration
- Contains: Various `.mbt` files showcasing language features
- Key files: Multiple test programs (e.g., `test_for_loop.mbt`, `test_for_in.mbt`, `debug_fn.mbt`)

**`.mooncakes/`:**
- Purpose: MoonBit package dependency cache (auto-generated)
- Contains: Downloaded dependencies from `moon.mod.json`
- Generated: Yes (by `moon fetch` or build)
- Committed: No (in `.gitignore`)

**`.planning/codebase/`:**
- Purpose: Architecture and codebase analysis documents for GSD tooling
- Contains: `ARCHITECTURE.md`, `STRUCTURE.md`, and other analysis docs
- Generated: Yes (by `gsd-map-codebase`)
- Committed: Yes (reviewed documentation)

## Key File Locations

**Entry Points:**
- `cmd/main/main.mbt`: CLI entry point (`fn main`)
- `compiler.mbt`: Library API (`compile_file`, `compile_file_target`)

**Configuration:**
- `moon.mod.json`: Module name, version, dependencies, repository, license
- `moon.pkg`: Per-package dependencies (top-level imports `moonbitlang/x/fs`)

**Core Compiler Logic:**
- `lexer.mbt`: Tokenization engine (1024 lines)
- `parser.mbt`: Parser and AST definitions (1724 lines)
- `codegen.mbt`: x86_64 code generator with instruction emission (1800+ lines)
- `compiler.mbt`: Compilation orchestration and ELF binary generation (203 lines)
- `backend.mbt`: Backend trait and target info abstractions
- `wasm_backend.mbt`: WebAssembly backend with WASM binary generation (1573 lines)

**Supporting:**
- `double_ryu_nonjs.mbt`: Float-to-string conversion for printing
- `AGENTS.md`: Project-specific agent guidelines

## Naming Conventions

**Files:**
- Pattern: `snake_case.mbt` for all source files
- Examples: `lexer.mbt`, `parser.mbt`, `codegen.mbt`, `wasm_backend.mbt`
- Entry point: `cmd/main/main.mbt`

**Types (structs, enums):**
- Pattern: `PascalCase`
- Examples: `Token`, `Lexer`, `AST`, `Parser`, `CodeGen`, `X86Inst`, `X86Operand`, `Backend`, `TargetInfo`

**Functions:**
- Pattern: `snake_case` with module prefix for associated functions
- Examples: `tokenize`, `parse`, `compile_file`, `Lexer::new`, `Parser::parse_expr`, `CodeGen::emit_byte`
- Associated function style: `Type::fn_name(params) -> Return`

**Variables:**
- Pattern: `snake_case` for locals and mutable vars
- Pattern: `camelCase` for struct fields (MoonBit convention)
- Examples: `input_path`, `output_path`, `debug_level`, `tokens`, `ast`

**Constants:**
- Pattern: `SCREAMING_SNAKE_CASE` for module-level constants
- Examples: None prominent, but literals like byte opcodes are inline

## Where to Add New Code

**New Language Feature (syntax/semantics):**
1. Extend `Token` enum in `lexer.mbt` if new token needed
2. Add lexer logic in `Lexer::next_token` to recognize new syntax
3. Extend `AST` enum in `parser.mbt` with new variant
4. Add parsing logic in appropriate `Parser::parse_*` function
5. Extend code generation in `codegen.mbt` (x86_64) and/or `wasm_backend.mbt` (WASM)

**New Backend Target:**
1. Create `new_backend.mbt` implementing `Backend` trait
2. Define target-specific struct and instruction set
3. Add to `Target` enum in `compiler.mbt`
4. Update `Target::from_string` and `compile_file_target` switch

**New CLI Option:**
1. Modify `cmd/main/main.mbt` argument parsing logic
2. Propagate flag to `compile_file_target` parameters

**Utility Functions:**
- Place in relevant module (e.g., string helpers in `lexer.mbt`, arithmetic helpers in `wasm_backend.mbt`)
- If generic across modules, consider new file like `utils.mbt`

**Tests:**
- Unit tests: `_test.mbt` suffix for blackbox tests
- Whitebox tests: `_wbtest.mbt` suffix
- Co-located with implementation or separate `tests/` directory? Current pattern: co-located
- Existing tests: `parser` has inline test blocks with `test "name" { ... }`

## Special Directories

**`/.mooncakes/`:**
- Purpose: MoonBit package manager cache
- Generated: Yes (automatic)
- Committed: No (listed in `.gitignore`)
- Contains: Downloaded dependencies (`moonbitlang/x`, `moonbitlang/async`, etc.)

**`/.planning/codebase/`:**
- Purpose: GSD tooling analysis documents
- Generated: Partially (by `gsd-map-codebase`)
- Committed: Yes (documentation)
- Contains: `ARCHITECTURE.md`, `STRUCTURE.md`, `CONVENTIONS.md`, `TESTING.md`, `CONCERNS.md`, `STACK.md`, `INTEGRATIONS.md`

**`/examples/`:**
- Purpose: Demonstration and manual testing
- Generated: No
- Committed: Yes
- Contains: User-facing example programs

**`/cmd/`:**
- Purpose: Executable entry points (can have multiple subcommands)
- Generated: No
- Committed: Yes
- Contains: CLI implementations; `main` is the default entry point

---

*Structure analysis: 2026-03-26*
