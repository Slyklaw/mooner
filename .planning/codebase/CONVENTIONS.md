# Coding Conventions

**Analysis Date:** 2026-03-26

## Block Structure

MoonBit code is organized in **block style**, with each logical block separated by the `///|` delimiter. The order of blocks is irrelevant, allowing flexible code organization.

**Example from `lexer.mbt` (lines 1-4):**
```moonbit
///|
/// Self-hosted MoonBit compiler - generates x86_64 ELF executables
pub enum Token {
  Fn
  Let
```

**Example from `parser.mbt` (lines 1-3):**
```moonbit
///|
pub enum AST {
  Unit
```

Each block typically contains:
- A documentation comment (optional, using `///`)
- The `///|` separator
- A single declaration or set of related declarations

## Naming Conventions

**Files:** snake_case with `.mbt` extension
- `lexer.mbt`, `parser.mbt`, `codegen.mbt`, `compiler.mbt`
- Test files: `mooner_test.mbt`, `mooner_wbtest.mbt`

**Types (enums, structs, traits):** PascalCase
- `Token`, `AST`, `Lexer`, `Parser`, `CodeGen`, `X86Inst`, `X86Operand`, `Target`

**Enum Variants:** PascalCase (mostly match language keywords)
- Keywords: `Fn`, `Let`, `Mut`, `If`, `Else`, `Match`, `Case`, `While`, `For`
- Literals: `True`, `False`, `Unit`, `Int`, `Float`, `String`, `Char`, `Bool`
- Operators: `Plus`, `Minus`, `Star`, `Slash`, `EqEq`, `BangEqual`, `Lt`, `Gt`
- Punctuation: `LParen`, `RParen`, `LBracket`, `RBracket`, `LBrace`, `RBrace`
- Special: `Ident`, `Eof`, `Underscore`

**Functions:** snake_case
- Public: `tokenize`, `parse`, `Lexer::new`, `Parser::parse`
- Private: `read_ident`, `is_whitespace`, `parse_binary`, `emit_byte`

**Variables and Struct Fields:** snake_case
- `input`, `pos`, `line`, `column`, `tokens`, `code`, `labels`
- `var_offsets`, `var_is_float`, `var_float_values`

**Constants:** Used sparingly; prefer module-level values
- `X86_64`, `Wasm` (enum variants) or module constants like `block_type_empty`

## Type System Patterns

**Option Types:** `Type?` for nullable values
```moonbit
fn char_at(s : String, i : Int) -> Char? {  // lexer.mbt:108
  if i < s.length() {
    let c = s[i]
    c.to_char()
  } else {
    None
  }
}
```

**Result Types:** `Result[T, String]` for error handling
```moonbit
pub fn compile_file(
  input_path : String,
  output_path : String,
  debug_level : Int,
) -> Result[Unit, String] {  // compiler.mbt:37
```

**Arrays:** `Array[Element]` for sequences
- Used extensively: `Array[Token]`, `Array[AST]`, `Array[Byte]`

**Maps:** `Map[Key, Value]` for associative data
- `Map[String, Int]`, `Map[String, Bool]` used in codegen for tracking variables

**Tuples:** `(Type1, Type2, ...)` for multiple return values
```moonbit
fn Lexer::read_ident(self : Lexer) -> (String, Lexer) {  // lexer.mbt:213
```

## Struct Definitions

**Struct initializer:** Record syntax with `{ ... }`
```moonbit
pub struct Lexer {
  input : String
  pos : Int
  line : Int
  column : Int
}

pub fn Lexer::new(input : String) -> Lexer {
  { input, pos: 0, line: 1, column: 1 }  // lexer.mbt:103-105
}
```

Note: Immutable by default; use `mut` for mutable bindings.

## Enum Definitions

**Simple enums:** No payload
```moonbit
pub enum Token {
  Fn
  Let
  Mut
  // ...
  Eof
} derive(Show)  // lexer.mbt:3-92
```

**Tagged enums:** With associated data
```moonbit
pub enum AST {
  Unit
  Int(Int)
  Float(Double)
  String(String)
  Char(Char)
  Bool(Bool)
  Ident(String)
  Block(Array[AST])
  Func(String, Array[(String, AST?)], AST?, AST)
  // ...
} derive(Show)  // parser.mbt:2-40
```

## Error Handling

**Pattern:** Return `Result[T, String]` for operations that can fail.

**Common patterns:**
1. **File I/O:** Use `@fs.read_file_to_string(path) catch { e => ... }`
```moonbit
let source = @fs.read_file_to_string(input_path) catch {
  e => return Err("Failed to read input file: \{e}")
}  // compiler.mbt:60-62
```

2. **Propagate errors with context:**
```moonbit
try {
  @fs.write_bytes_to_file(output_path, result)
  Ok(())
} catch {
  e => Err("Failed to write output file: \{e}")
}  // compiler.mbt:179-184
```

3. **Early returns:** Use `return` to exit early on error.

## Pattern Matching

**Match expressions:** Exhaustive pattern matching with `match`
```moonbit
match self.current() {
  Ident(name) => (name, self.advance())
  _ => ("", self)
}  // parser.mbt:98-101
```

**Destructuring:** Use pattern matching to unpack enums and tuples
```moonbit
match c {
  Some(c) => // handle Some
  None => // handle None
}  // lexer.mbt:124-128
```

**Guards:** Conditions in match arms using `if`
```moonbit
Some(c) if is_whitespace(c) => // whitespace handling
```

## Mutability

**Default:** All bindings are immutable.
```moonbit
let mut lexer = self  // mutable binding with `mut`
```

**Mutating structs:** Update syntax `{ ..struct, field: new_value }`
```moonbit
fn Lexer::advance(self : Lexer) -> Lexer {
  match self.current_char() {
    Some('\n') => { ..self, pos: self.pos + 1, line: self.line + 1, column: 1 }
    Some(_) => { ..self, pos: self.pos + 1, column: self.column + 1 }
    None => self
  }
}  // lexer.mbt:123-129
```

**Array mutation:** Use `array = array + [element]` (functional update)
```moonbit
tokens = tokens + [token]  // lexer.mbt:1014
stmts = stmts + [expr]     // parser.mbt:1613
```

## AST Types and Design

**AST node types:** Comprehensive representation of language constructs
- **Literals:** `Unit`, `Int`, `Float`, `String`, `Char`, `Bool`, `Ident`
- **Compound:** `Block`, `Tuple`, `ArrayLit`, `MapLit`, `StringConcat`
- **Control flow:** `IfExpr`, `MatchExpr`, `WhileLoop`, `ForLoop`, `ForInLoop`
- **Bindings:** `LetBind`, `LetTuple`, `Assign`, `AssignOp`
- **Expressions:** `Binary`, `Unary`, `CallExpr`, `IndexExpr`, `FieldExpr`, `Spread`
- **Functions:** `Func`, `ReturnExpr`, `Break`, `Continue`
- **Types:** `TypeDecl`, `EnumDef`, `StructLit`, `StructUpdate`
- **Advanced:** `GuardExpr`, `TestBlock`

**AST construction:** Hand-written recursive descent parser building AST nodes directly.

## Trait Usage

**`derive(Show)`:** Used on enums to enable printing for debugging.
```moonbit
pub enum Token { ... } derive(Show)  // lexer.mbt:92
```

No custom traits are defined in the core compiler files; the codebase relies on built-in traits and standard library functions.

## Code Layout and Indentation

**Indentation:** 2 spaces per level (observed in all source files)

**Block content:** Indented one level from the block header
```moonbit
pub fn Lexer::new(input : String) -> Lexer {
  { input, pos: 0, line: 1, column: 1 }  // 2-space indent
}
```

**Nested match arms:** Indented within the match block
```moonbit
match c {
  Some(c) =>
    if is_whitespace(c) {
      lexer = lexer.advance()
    } else {
      done = true
    }
  None => done = true
}  // lexer.mbt:158-167
```

## Comments

**File header:** Optional `///` comment at top of file
```moonbit
///|
/// Self-hosted MoonBit compiler - generates x86_64 ELF executables
```

**Block comments:** `///` before each block
- Describes purpose of the block
- Can be multi-line

**Inline comments:** `//` for short explanations
```moonbit
let has_dot = num_str.contains(".")  // Check if it's a float
```

## String Interpolation

**Syntax:** `\{expression}` inside strings
- Used in error messages: `"Failed to read file: \{e}"`
- Used in token parsing: `"\[name}[\{inner}]"`

## Access Modifiers

**`pub`:** Public declarations exported from the package
- `pub enum Token`, `pub struct Lexer`, `pub fn tokenize`

**No modifier:** Private to the package/module
- `fn char_at`, `fn is_whitespace`, `fn read_ident` are private helpers

## Derive Attributes

**`derive(Show)`:** Automatically generates `to_string` for debug printing.
Applied to `Token`, `AST`, `Operand`, `X86Inst`, `X86Operand`.

## Deprecated Code

**Handling:** Projects may include `deprecated.mbt` files per AGENTS.md, but this codebase does not currently use deprecated blocks.

## Code Style Summary

- **Immutable-first:** Use immutable bindings; mutate via shadowing or functional updates
- **Exhaustive matching:** Always handle all enum variants in match expressions
- **Explicit returns:** Use `return` for early exits; otherwise last expression returns
- **Error as strings:** Error messages are human-readable `String`s
- **Functional updates:** Arrays and structs updated with `+` and `{ .. }` syntax
- **Spaces over tabs:** 2-space indentation throughout
- **Self methods:** Use `self::method` syntax for struct methods
- **Option handling:** Prefer `match` over `unwrap`-style functions (MoonBit uses `?` option type)
