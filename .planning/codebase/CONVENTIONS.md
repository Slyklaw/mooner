# Coding Conventions

**Analysis Date:** 2026-03-11

## Naming Patterns

**Files:**
- Lowercase with underscores: `lexer.mbt`, `parser.mbt`, `codegen.mbt`, `compiler.mbt`
- Test files: `*_test.mbt` (blackbox/E2E), `*_wbtest.mbt` (whitebox/unit)

**Functions:**
- snake_case: `tokenize`, `parse_expr`, `read_escape_seq`
- Public functions: `pub fn name(...)`
- Private functions: `fn name(...)`
- Methods: `StructName::method_name(self : StructName) -> ReturnType`

**Types:**
- Structs: PascalCase: `Lexer`, `Parser`, `CodeGen`
- Enums: PascalCase: `Token`, `AST`, `X86Inst`, `X86Operand`
- Enum variants: PascalCase or ALL_CAPS for tokens: `Fn`, `Let`, `Eof`, `LParen`

**Variables:**
- snake_case: `input`, `tokens`, `current_parser`, `parser_pos`
- Mutable variables: `let mut var_name = value`
- Shadowing common: `let parser = self` (reassigning with updates)

**Constants:**
- Magic numbers inlined with comments: `0x1000`, `0x78`, `46` (with comment `// '.'`)

## Code Style

**Block Organization:**
- MoonBit block-style layout with `///|` separator between logical blocks
- Each block is independent and order-agnostic
- Example from `lexer.mbt`:
  ```moonbit
  ///|
  pub enum Token {
    Fn
    Let
    // ...
  } derive(Show)

  ///|
  pub struct Lexer {
    input : String
    pos : Int
  }
  ```

**Struct Initialization:**
- Record syntax: `{ field1: value1, field2: value2 }`
- Struct updates: `{ ..self, pos: self.pos + 1 }`
- Example: `{ ..self, pos: self.pos + 1, line: self.line + 1 }`

**Pattern Matching:**
- Heavy use of `match` expressions throughout
- Exhaustive pattern matching required
- Example pattern: `match char_at(lexer.input, lexer.pos) { Some(c) => ..., None => ... }`

**String Concatenation:**
- Uses `+` operator: `acc = acc + c.to_string()`
- Explicit conversions: `.to_string()`, `.to_int()`, `.to_double()`

**Array Operations:**
- Concatenation: `arr = arr + [element]`
- Length: `arr.length()`
- Empty array: `[]`

**Map Operations:**
- Creation: `Map::new()`
- Insert: `map = Map::insert(key, value, map)`

## Import Organization

**Import Syntax:**
- Package imports: `@package.module` (e.g., `@fs`, `@env`, `@lib`)
- Standard library imports: `import { "module" }` in `moon.pkg`
- Example from `compiler.mbt`: `@fs.read_file_to_string(input_path)`

**Import Locations:**
- `@` imports appear inline at usage site (not at file top)
- Package dependencies declared in `moon.pkg` and `moon.mod.json`

## Error Handling

**Result Type:**
- Functions that can fail return `Result[Unit, String]` or `Result[T, String]`
- Success: `Ok(())` or `Ok(value)`
- Failure: `Err("error message")`

**Try-Catch Pattern:**
```moonbit
try {
  @fs.read_file_to_string(path)
} catch {
  e => return Err("Failed to read: \{e}")
}
```

**Error Messages:**
- Descriptive, user-facing strings
- Include context: `"Failed to read input file: \{e}"`
- Compile errors are not thrown but returned

## Documentation

**Block Comments:**
- `///|` precedes each logical block (enum, struct, function)
- These are MoonBit's doc comment system

**Inline Comments:**
- Single-line: `// comment`
- Within functions to explain complex logic

**License Headers:**
- Some files (e.g., `double_ryu_nonjs.mbt`) include Apache 2.0 license header
- Standard copyright notice format

**Function Comments:**
- Each public function and struct typically has a `///|` comment above
- Private helper functions may have brief inline comments

## Function Design

**Method Syntax:**
- Type methods: `fn StructName::method(self : StructName) -> Return`
- Frequently use `self` parameter by value (not reference)
- Immutable by default; use `mut` when needed

**Parameter Style:**
- Named parameters with types: `input : String`, `output_path : String`
- Optional parameters: `optional_param : Type?` with `None` default

**Return Values:**
- Almost all functions have explicit return types
- Return last expression implicitly (no explicit `return` needed)
- Early returns: `return value` within branches

**Recursion:**
- Common for tree traversal (parser), string processing (lexer)
- Tail recursion not optimized but widely used

## Type System Conventions

**Option Types:**
- `Type?` for nullable/optional values
- Use `match` to extract: `match value { Some(v) => ..., None => ... }`

**Result Types:**
- `Result[T, String]` for fallible operations
- Propagate with `try { ... }`

**Enum Variants:**
- Token enum: PascalCase variants (`Fn`, `Let`, `Ident(String)`)
- AST enum: Variants carry payloads: `Func(String, Array[(String, AST?)], AST?, AST)`

## Logging

**Debug Output:**
- `println("message")` for simple output
- No formal logging framework
- E2E tests rely on stdout comparison

## Formatting

**Tool:**
- `moon fmt` is the code formatter (per AGENTS.md)
- No `.prettierrc` or `.eslintrc` present in repository

**Style Guide:**
- Consistent 2-space indentation (inferred from code)
- No trailing whitespace in repository files
- LF line endings (Linux environment)

## Module Structure

**Single-File Modules:**
- Each `.mbt` file is a module
- No nested directories in main package (all source at root)
- Dependencies in `.mooncakes/` (generated)

**Exports:**
- `pub` keyword marks public items
- Internal helpers are private (no `pub`)

## Special Patterns

**Lexer State:**
- Immutable state: `Lexer` struct returned as new value after each step
- Example: `lexer.advance()` returns new `Lexer`

**Parser Recursion:**
- Each parse function returns `(AST, Parser)` tuple
- Parser advanced token position is carried forward
- `skip(n)` advances without parsing

**Code Generation:**
- `CodeGen` struct accumulates state in maps (`var_offsets`, `labels`)
- Methods mutate `CodeGen` and return updated version
- Byte buffer: `Array[Byte]` appended with `emit_byte`

## Block Comment Conventions

The `///|` separator creates a visual block boundary. Code can be reordered within a file without affecting semantics (each block is independent). This is a MoonBit-specific convention.

---

*Conventions analysis: 2026-03-11*
