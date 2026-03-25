# Architecture

**Analysis Date:** 2026-03-25

## Pattern Overview

**Overall:** Monolithic compiler pipeline with distinct phases (lexer, parser, code generator, ELF linker).

**Key Characteristics:**
- Simple single-pass compilation without separate linking or optimization phases.
- Each phase is implemented in a dedicated module (`lexer.mbt`, `parser.mbt`, `codegen.mbt`, `compiler.mbt`).
- The compiler generates x86_64 ELF executables directly, embedding the ELF header generation within `compiler.mbt`.
- No separate symbol table or type-checking passes; the language is dynamically typed (or type inference is implicit).
- The codebase is written entirely in MoonBit, making it self-hosted (the compiler compiles its own language).

## Layers

**Frontend (Lexer):**
- Purpose: Tokenizes source code into a stream of tokens.
- Location: `lexer.mbt`
- Contains: `Token` enum (80+ token types), `Lexer` struct with `tokenize` function.
- Depends on: Nothing external (pure transformation).
- Used by: Parser.

**Frontend (Parser):**
- Purpose: Parses token stream into an Abstract Syntax Tree (AST).
- Location: `parser.mbt`
- Contains: `AST` enum (40+ node types), `Parser` struct with `parse` function.
- Depends on: `Token` from lexer.
- Used by: Code generator.

**Backend (Code Generator):**
- Purpose: Traverses AST and emits x86_64 machine code bytes.
- Location: `codegen.mbt`
- Contains: `CodeGen` struct with extensive state for tracking variables, labels, loops, strings, floats, etc.
- Depends on: `AST` from parser.
- Used by: Compiler entry point.

**Linker (ELF Builder):**
- Purpose: Assembles generated machine code into a valid ELF executable with proper headers and padding.
- Location: `compiler.mbt` (function `compile_file`)
- Contains: ELF header constants, program header generation, padding logic.
- Depends on: Code generator's byte output, external file I/O (`@fs`).
- Used by: CLI entry point.

**CLI Entry Point:**
- Purpose: Parses command-line arguments and invokes the compilation pipeline.
- Location: `cmd/main/main.mbt`
- Contains: `main` function that reads args, calls `@mooner.compile_file`.
- Depends on: Compiler's public API.

## Data Flow

**Compilation Pipeline:**

1. **Source → Tokens:** `lexer.tokenize(source)` produces `Array[Token]`.
2. **Tokens → AST:** `parser.parse(tokens)` produces `AST`.
3. **AST → Machine Code:** `codegen.codegen(ast, debug_level)` produces `Array[Byte]`.
4. **Machine Code → ELF File:** `compiler.compile_file` combines ELF header, program header, padding, and code bytes, then writes to disk.

**State Management:**
- Lexer maintains position index.
- Parser maintains token array and position index.
- CodeGen maintains a complex state map (`CodeGen` struct) that tracks variable offsets, types, labels, string/float pools, etc.
- No persistent state between compilation runs; each invocation creates fresh structs.

## Key Abstractions

**Token (`lexer.mbt`):**
- Purpose: Represents lexical units of the source language.
- Examples: `Token::Fn`, `Token::Int(Int)`, `Token::Plus`.
- Pattern: Tagged union with variants for keywords, literals, operators.

**AST (`parser.mbt`):**
- Purpose: Represents syntactic structure of the program.
- Examples: `AST::Func`, `AST::LetBind`, `AST::Binary`.
- Pattern: Tagged union with recursive structure (AST nodes can contain other AST nodes).

**CodeGen (`codegen.mbt`):**
- Purpose: Stateful code emitter that translates AST into x86_64 instructions.
- Examples: `CodeGen` struct with fields for code buffer, label maps, variable offset maps.
- Pattern: Single-pass code generation with forward label references resolved via pending labels array.

## Entry Points

**CLI Entry Point:**
- Location: `cmd/main/main.mbt`
- Triggers: User runs `moon run cmd/main <input_file> [output_file] [--debug]`.
- Responsibilities: Parse args, call `@mooner.compile_file`.

**Compiler API Entry Point:**
- Location: `compiler.mbt`
- Triggers: Called by CLI or other MoonBit code.
- Responsibilities: Orchestrate tokenization, parsing, code generation, and ELF assembly.

**Public API Functions (exported from root package):**
- `tokenize(source: String) -> Array[Token]` (`lexer.mbt`)
- `parse(tokens: Array[Token]) -> AST` (`parser.mbt`)
- `codegen(ast: AST, debug_level: Int) -> Array[Byte]` (`codegen.mbt`)
- `compile_file(input_path: String, output_path: String, debug_level: Int) -> Result[Unit, String]` (`compiler.mbt`)

## Error Handling

**Strategy:** Result monad (`Result[T, E]`) for fallible operations; errors are `String` messages.

**Patterns:**
- `compile_file` returns `Result[Unit, String]` for file I/O errors.
- Lexer/parser/codegen currently assume valid input (no error recovery).
- External library calls (e.g., `@fs.read_file_to_string`) are wrapped in `catch` blocks that convert exceptions to `Err(...)`.

## Cross-Cutting Concerns

**Logging:** No logging framework; debug output via `println` when `debug_level > 0` (in codegen).
**Validation:** No explicit validation; malformed input may cause panics or incorrect output.
**Authentication:** Not applicable (offline compiler).

---

*Architecture analysis: 2026-03-25*
