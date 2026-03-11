# Architecture

**Analysis Date:** 2026-03-11

## Pattern Overview

**Overall:** Classic multi-stage compiler with linear pipeline

**Key Characteristics:**
- Single-pass compilation from source to ELF binary
- Direct code generation (no intermediate IR)
- Functional style with immutable data structures
- Self-contained in ~1700 lines across 4 core files
- Block-style MoonBit code organization (///| separators)

## Layers

**Lexical Analysis:**
- Purpose: Tokenize source code into token stream
- Location: `lexer.mbt` (1024 lines)
- Contains: `Token` enum, `Lexer` struct, character/string/number parsing helpers
- Produces: `Array[Token]`
- No dependencies on other layers

**Syntax Analysis:**
- Purpose: Parse tokens into Abstract Syntax Tree (AST)
- Location: `parser.mbt` (1624 lines)
- Contains: `AST` enum (38 variants), `Parser` struct, recursive descent parser
- Produces: `AST` representing complete program
- Depends on: `Token` from lexer

**Code Generation:**
- Purpose: Transform AST into x86_64 machine code
- Location: `codegen.mbt` (1944+ lines)
- Contains: `CodeGen` struct, `X86Inst` enum (70+ instructions), `X86Operand` enum
- Produces: `Array[Byte]` containing machine code
- Depends on: `AST` from parser
- Key features: Variable offset tracking, label management, string/float literals

**Orchestration & Binary Packaging:**
- Purpose: Wire pipeline stages, add ELF headers, write output file
- Location: `compiler.mbt` (118 lines)
- Contains: `compile_file` function, ELF header construction, file I/O
- Depends on: `tokenize`, `parse`, `codegen` functions
- Produces: Complete ELF executable file

**Command-Line Interface:**
- Purpose: Argument handling and user interaction
- Location: `cmd/main/main.mbt` (24 lines)
- Contains: `main` function
- Depends on: `compile_file` from compiler

## Data Flow

**Compilation Pipeline:**

```
Source String
    ↓ (lexer.mbt: tokenize)
Array[Token]
    ↓ (parser.mbt: parse)
AST
    ↓ (codegen.mbt: codegen)
Array[Byte] (x86_64 machine code)
    ↓ (compiler.mbt: compile_file + ELF headers)
ELF Executable File
```

**Entry point flow:**
1. `main` (cmd/main/main.mbt) parses CLI args
2. Calls `compile_file` with input/output paths
3. `compile_file` reads source, calls `tokenize`, `parse`, `codegen`
4. Writes ELF file with headers + padded code

## Key Abstractions

**Token:**
- Enum representing all MoonBit language tokens (keywords, operators, literals)
- Defined in `lexer.mbt` lines 3-92
- Variants: `Fn`, `Let`, `Ident(String)`, `Int(Int)`, `Float(Double)`, etc.
- Includes operator tokens and punctuation

**AST:**
- Algebraic data type representing program structure
- Defined in `parser.mbt` lines 2-40
- 38 variants covering: literals, expressions, statements, declarations
- Key variants: `Func`, `LetBind`, `IfExpr`, `MatchExpr`, `Binary`, `CallExpr`, `TypeDecl`, `StructLit`, `EnumDef`

**X86Inst:**
- Enum of x86_64 instructions
- Defined in `parser.mbt` lines 1641-1703 (shared with parser)
- 70+ instruction variants: `Mov`, `Add`, `Sub`, `Cmp`, `Jmp`, `Je`, `Call`, `Ret`, etc.
- Separate categories: arithmetic, logic, control flow, floating-point, stack

**X86Operand:**
- Enum representing instruction operands
- Defined in `parser.mbt` lines 1706-1722
- Variants: `Imm8/32/64`, `Reg8/32/64`, `Xmm`, `Stack*`, `MemIndirect`, `RipRel32`, `Label`

**CodeGen:**
- Struct holding code generation state (lines 2-48 in codegen.mbt)
- Tracks: code buffer, symbol labels, variable offsets, type metadata, string/float literals
- Immutable functional style: each operation returns new CodeGen instance

## Entry Points

**Public API:**
- `tokenize(input: String) -> Array[Token]` (lexer.mbt:1007)
- `parse(tokens: Array[Token]) -> AST` (parser.mbt:1626)
- `codegen(ast: AST) -> Array[Byte]` (codegen.mbt - main entry)
- `compile_file(input_path: String, output_path: String) -> Result[Unit, String]` (compiler.mbt:2)

**CLI:**
- `main` function (cmd/main/main.mbt:4)
- Usage: `moon run cmd/main <input_file> [output_file]`

## Error Handling

**Strategy:** Fail-fast with descriptive error strings

- File I/O errors: caught and wrapped in `Err(String)` at `compile_file`
- Parsing errors: undefined behavior - parser returns `Unit` on unexpected tokens
- No panic/unwrapping on user code paths
- Errors propagate as `Result[Unit, String]` through compiler

## Cross-Cutting Concerns

**Binary Format:**
- ELF64 executable for Linux x86_64
- Entry point: 0x401000 (like GCC -nostdlib -s)
- Single PT_LOAD program header covering code
- No section headers (simplified)
- Code aligned to 0x1000 page boundary

**Memory Model:**
- Stack-based local variable allocation
- RBP-relative addressing for locals
- Caller-saved calling convention (not fully documented)
- No heap allocation (all data on stack or static)

**Floating-Point:**
- SSE2 instructions for FP operations (`movsd`, `addsd`, `subsd`, `mulsd`, `divsd`)
- Ryu algorithm for float-to-string conversion (`double_ryu_nonjs.mbt`)
- Runtime library calls for string concatenation and printing

---

*Architecture analysis: 2026-03-11*
