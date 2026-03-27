# Architecture

**Analysis Date:** 2026-03-26

## Pattern Overview

**Overall:** Multi-pass compiler with trait-based backend abstraction

**Key Characteristics:**
- Classic compiler pipeline: Lexing → Parsing → Code Generation → Output
- Trait-based backend system supports multiple target architectures
- Stateful code generation with explicit instruction emission
- Direct binary output generation (ELF for x86_64, WASM binary format)

## Layers

**Lexer Layer:**
- Purpose: Tokenize source code into token stream
- Location: `lexer.mbt`
- Contains: `Token` enum, `Lexer` struct, lexing functions
- Depends on: Nothing (pure string processing)
- Used by: Parser

**Parser Layer:**
- Purpose: Build abstract syntax tree (AST) from token stream
- Location: `parser.mbt`
- Contains: `AST` enum, `Parser` struct, parsing functions for all language constructs
- Depends on: `Token` from lexer
- Used by: CodeGen, Backend implementations

**Code Generation Layer:**
- Purpose: Convert AST to machine code/bytecode
- Location: `codegen.mbt` (x86_64 specific), `wasm_backend.mbt` (WASM specific)
- Contains: `CodeGen` struct (x86_64), `X86Inst`/`X86Operand` enums, `WasmModuleBuilder` (WASM)
- Depends on: `AST` from parser
- Used by: Compiler orchestration

**Backend Abstraction:**
- Purpose: Provide unified interface for different target architectures
- Location: `backend.mbt` (trait definition), implementations in `codegen.mbt` and `wasm_backend.mbt`
- Contains: `Backend` trait, `TargetInfo` struct, `Endianness` enum
- Depends on: Nothing (interface only)
- Used by: Compiler orchestration

**Orchestration Layer:**
- Purpose: Coordinate compilation flow, handle I/O, select target
- Location: `compiler.mbt`, `cmd/main/main.mbt`
- Contains: `Target` enum, `compile_file`, `compile_file_target`, CLI argument parsing
- Depends on: All lower layers
- Used by: End user (via CLI)

## Data Flow

**Compilation Pipeline:**

1. **Input**: Source file read via `@fs.read_file_to_string(input_path)`
2. **Tokenization**: `tokenize(source)` → `Array[Token]`
3. **Parsing**: `parse(tokens)` → `AST`
4. **Target Selection**: Based on output extension (.exe vs .wasm) or `--target` flag
5. **Code Generation**:
   - x86_64: `X86_64Backend::new(debug_level)` → `Backend::generate_module(backend, ast)` → `Bytes`
   - WASM: `WasmBackend::new(debug_level)` → `Backend::generate_module(backend, ast)` → `Bytes`
6. **Output Formatting**:
   - x86_64: Build ELF header (64 bytes) + program header (56 bytes) + padding + code, write to file
   - WASM: Build WASM module (magic + version + sections), write to file directly

**State Management:**
- `CodeGen` struct maintains mutable code buffer, label table, variable offsets, and various metadata
- State is threaded through functional updates (immutable style with shadowing)
- `pending_labels` allows forward references for jumps/calls

## Key Abstractions

**Token System:**
- `Token` enum in `lexer.mbt` represents all lexical tokens (keywords, operators, literals, punctuation)
- `Token::Ident(String)`, `Token::Int(Int)`, `Token::Float(Double)`, `Token::String(String)` carry payloads
- `token_eq` function for token comparison (pattern matching on enum variants)

**AST Representation:**
- `AST` enum in `parser.mbt` with 40+ variants representing all language constructs
- Literal nodes: `Int`, `Float`, `String`, `Char`, `Bool`, `Unit`, `Ident`
- Expression nodes: `Binary`, `Unary`, `CallExpr`, `FieldExpr`, `IndexExpr`, `IfExpr`, `MatchExpr`, etc.
- Statement nodes: `Func`, `LetBind`, `LetTuple`, `WhileLoop`, `ForLoop`, `ReturnExpr`, etc.
- Type/struct nodes: `TypeDecl`, `EnumDef`, `StructLit`, `StructUpdate`
- Special: `Block(Array[AST])`, `TestBlock`

**Instruction Set Abstraction:**
- x86_64: `X86Inst` enum defines all supported instructions (Mov, Add, Sub, Jmp, etc.)
- WASM: `WasmArithInst` enum, `WasmBlockType`, section-based binary format
- Operands: `X86Operand` enum (Imm8/32/64, Reg64, Stack, Label, MemIndirect, etc.)

**Backend Trait:**
- `Backend` trait defines `generate_module(self, AST) -> Array[Byte]`
- `get_target_info(self) -> TargetInfo`
- `supports_feature(self, Feature) -> Bool`
- Implementations: `X86_64Backend` (in `codegen.mbt`), `WasmBackend` (in `wasm_backend.mbt`)

## Entry Points

**Public API:**
- `compiler.mbt`:
  - `compile_file(input_path, output_path, debug_level) -> Result[Unit, String]` (auto-detect target)
  - `compile_file_target(input_path, output_path, debug_level, target) -> Result[Unit, String]` (explicit target)
  - `Target` enum with `x86_64()`, `wasm()`, `default()`, `from_string(String) -> Target?`

**CLI:**
- `cmd/main/main.mbt`: `main` function
- Parses command-line arguments: input file, output file, `--target`, `--debug`
- Calls `@lib.compile_file_target` with appropriate parameters
- Entry configured in `moon.mod.json`

## Error Handling

**Strategy:** `Result[Unit, String]` return types for compilation operations

**Patterns:**
- File I/O wrapped in `try/catch` with user-friendly error messages
- Parser recovers from errors by skipping tokens (prevents infinite loops)
- Tokenization returns `Eof` to terminate loop
- Validation errors return `Err("message")` with context

**Examples:**
- `@fs.read_file_to_string(input_path) catch { e => return Err("Failed to read input file: \{e}") }`
- `@fs.write_bytes_to_file(output_path, result) catch { e => Err("Failed to write output file: \{e}") }`

## Cross-Cutting Concerns

**Logging/Tracing:**
- Debug output via `CodeGen::trace_instruction` when `debug_level >= 1`
- Uses syscall-based println for x86_64 backend
- CLI `--debug` and `--debug-codegen` flags

**Validation:**
- Target validation: `Target::from_string` returns `None` for unknown targets
- AST validation implicitly during code generation (missing handlers default to stubs)

**File I/O:**
- All file operations use `@fs` module from `moonbitlang/x/fs`
- Binary write: `@fs.write_bytes_to_file(path, bytes)`
- Text read: `@fs.read_file_to_string(path)`

**Formatting:**
- `moon fmt` used for consistent code style (per AGENTS.md)
- No runtime formatting; all code is pre-formatted

---

*Architecture analysis: 2026-03-26*
