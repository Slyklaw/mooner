# Coding Conventions

**Analysis Date:** 2026-03-25

## Naming Patterns

**Files:**
- Snake case with `.mbt` extension: `lexer.mbt`, `parser.mbt`, `codegen.mbt`, `double_ryu_nonjs.mbt`
- Test files follow MoonBit convention: `*_test.mbt` for blackbox tests, `*_wbtest.mbt` for whitebox tests
- Example files in `examples/` directory: `test_*.mbt` for test examples, `*.mbt` for sample programs

**Functions:**
- Snake case for all functions and methods: `char_at`, `is_whitespace`, `read_ident`, `parse_int`, `parse_double`
- Method names use `Type::method` syntax: `Lexer::new`, `Lexer::advance`, `Parser::parse_expr`
- Private functions (not exported) use snake case: `self_token_eq`, `has_dot`, `has_exp`

**Variables:**
- Snake case for local variables: `input_path`, `output_path`, `debug_level`
- Mutable variables prefixed with `mut`: `let mut lexer = self`, `let mut result = ""`

**Types:**
- PascalCase for type definitions: `Token` (enum), `Lexer` (struct), `AST` (enum)
- Enum variants use PascalCase: `Token::Fn`, `Token::Ident(String)`, `AST::Func(...)`
- Struct fields use snake case: `input`, `pos`, `line`, `column`

**Constants:**
- No explicit constant definitions observed; literals used directly

## Code Style

**Formatting:**
- Tool: `moon fmt` (MoonBit's standard formatter)
- Block separation: `///|` on its own line separates independent blocks
- Indentation: 2 spaces (default MoonBit formatting)
- Braces: same line for control structures (`if ... {`, `match ... {`)

**Linting:**
- No dedicated linting configuration found; rely on `moon fmt` and compiler warnings
- Compiler warnings: reserved keyword warnings (e.g., `method` is reserved)

## Import Organization

**Pattern:**
- No explicit import statements; dependencies declared in `moon.mod.json`
- External packages accessed via `@` prefix: `@fs.read_file_to_string`, `@env.args()`
- Standard library functions accessed directly: `println`, `Array::make`, `String::length`

**Path Aliases:**
- Not applicable; MoonBit uses package-based imports

## Error Handling

**Patterns:**
- `Result[T, E]` type for fallible operations: `fn compile_file(...) -> Result[Unit, String]`
- `catch` blocks for error handling: `catch { e => return Err("Failed to read input file: \{e}") }`
- `try/catch` for I/O operations: `try { @fs.write_bytes_to_file(...) } catch { e => Err(...) }`
- Pattern matching on `Result` in caller: `match @lib.compile_file(...) { Ok(_) => ..., Err(e) => ... }`

**Error Messages:**
- Descriptive strings with interpolation: `"Failed to read input file: \{e}"`

## Logging

**Framework:** `println` for standard output

**Patterns:**
- Diagnostic output via `println("Compiled to \{output_path}")`
- Error output via `println("Error: \{e}")`
- No structured logging framework

## Comments

**When to Comment:**
- Block separators: `///|` on its own line between logical sections
- Inline comments for complex logic: `// Header is 64 + 56 = 120 bytes (0x78)`
- TODO comments for future work: `/// TODO: ryu_to_logger[T:Logger](Double/Float, T) -> Unit`
- Unicode escape notes: `// Unicode escape: \u{XXXX}`

**JSDoc/TSDoc:**
- Not used; MoonBit uses its own documentation system

## Function Design

**Size:**
- Functions tend to be focused (20-50 lines typical)
- Large functions broken into helpers (e.g., `Lexer::read_number` calls `read_decimal_number`, `parse_hex`, `parse_binary`)

**Parameters:**
- Explicit type annotations required
- `self` parameter for methods: `fn Lexer::advance(self : Lexer) -> Lexer`
- Tuple returns for multiple values: `(String, Lexer)` from `read_ident`

**Return Values:**
- Explicit return types required
- Unit `()` for side-effect functions
- `Option[T]` for partial functions: `fn char_at(s : String, i : Int) -> Char?`

## Module Design

**Exports:**
- Public items marked with `pub`: `pub enum Token`, `pub struct Lexer`, `pub fn Lexer::new`
- Internal helpers are private by default

**Barrel Files:**
- Not used; each module is a single `.mbt` file
- Package entry point: `compiler.mbt` exports `compile_file`
- CLI entry point: `cmd/main/main.mbt`

---

*Convention analysis: 2026-03-25*