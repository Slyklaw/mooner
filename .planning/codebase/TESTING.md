# Testing Patterns

**Analysis Date:** 2026-03-11

## Test Framework

**Built-in MoonBit Test Runner:**
- Tests are part of MoonBit standard toolchain
- No external testing framework (Jest, Vitest, etc.)
- Run tests with: `moon test`
- Watch mode: Not configurable (run command repeatedly)
- Coverage: `moon coverage analyze > uncovered.log`

**Run Commands:**
```bash
moon test                     # Run all tests
moon test --update            # Update snapshot tests
moon coverage analyze > log   # Generate coverage report
```

## Test File Organization

**Two-Tier System:**

1. **Blackbox Tests (`*_test.mbt`):**
   - Test public API from outside the package
   - Located in same directory as source
   - Example: `mooner_test.mbt`

2. **Whitebox Tests (`*_wbtest.mbt`):**
   - Test internal implementation details
   - Have access to private functions/types
   - Example: `mooner_wbtest.mbt`

**Naming:**
- Blackbox: `package_name_test.mbt` (e.g., `lexer_test.mbt` would test lexer from outside)
- Whitebox: `package_name_wbtest.mbt` (e.g., `parser_wbtest.mbt` tests parser internals)
- Current codebase only has `mooner_test.mbt` and `mooner_wbtest.mbt` at root

**Location Pattern:**
- Co-located with source code (same directory)
- No separate `test/` directory

## Test Structure

**Test Block Syntax:**
```moonbit
///|
test "descriptive name" {
  // test body
  assert_eq(actual, expected)
}

///|
test {
  // anonymous test
  assert_true(condition)
}
```

**Example from `mooner_wbtest.mbt`:**
```moonbit
///|
test "lexer produces correct tokens for hello" {
  let input = "fn main { println(\"hello\") }"
  let tokens = tokenize(input)

  // Check we have the expected token types
  assert_true(tokens[0] is Token::Fn)
  assert_true(tokens[1] is Token::Ident(_))
}
```

**Arrangement:**
- Each `///|` block separates distinct tests
- Block comments with `///|` are optional but conventional
- Test blocks can be named or anonymous

## Assertion Patterns

**Available Assertions:**

- `assert_eq(actual, expected)` - equality comparison
- `assert_true(condition)` - boolean true
- `assert_false(condition)` - boolean false
- Pattern matching with `is`: `assert_true(value is Type::Variant)`
- `inspect(value)` for snapshot testing (see below)

**Pattern Matching Assertions:**
```moonbit
match tokens[0] {
  Token::String(s) => assert_eq(s, "hello world")
  _ => assert_true(false)
}
```

## Mocking

**No Mocking Framework:**
- MoonBit standard library does not include mocking
- Manual dependency injection used when needed
- Example: `lexer.mbt` is pure function `tokenize(input: String) -> Array[Token]`
- No need to mock file I/O in unit tests (lexer/parser/codegen are pure)

**Test isolation:**
- Tests are pure functions of input
- No shared mutable state between tests
- Each test creates fresh data structures

## Fixtures and Test Data

**Inline Fixtures:**
- Test data defined directly in test body
- Example: `let input = "fn main { println(1) }"`
- Small, focused fixtures

**External Test Files:**
- E2E tests use files in `examples/mbt_examples/` directory
- Files named `001_*.mbt`, `002_*.mbt`, etc.
- These are real MoonBit programs compiled by both compilers

**Example Fixtures from `mooner_test.mbt`:**
```moonbit
test "compile_file returns ok for valid input" {
  let input_path = "examples/mbt_examples/001_hello.mbt"
  let output_path = "/tmp/mooner_test_001.exe"
  let result = @mooner.compile_file(input_path, output_path)
  assert_true(match result { Ok(_) => true, Err(_) => false })
}
```

## Snapshot Testing

**Inspect Function:**
- `inspect(value)` records output for comparison
- First run creates snapshot file
- Subsequent runs compare to stored snapshot
- Update with `moon test --update`

**Example from `examples/mbt_examples/012_basic_test.mbt`:**
```moonbit
test {
  inspect(fib(5))
  inspect([1,2,3,4].map(fib))
}

test "fibonacci" {
  inspect(fib(5), content="5")
  inspect(fib(6), content="8")
}
```

**Use Cases:**
- Complex outputs where exact equality assertion is verbose
- Regression testing of compiler output
- Capturing full AST structure or generated code

## Coverage

**Coverage Tool:**
- `moon coverage analyze` generates coverage report
- Output redirected to file: `moon coverage analyze > uncovered.log`
- Shows which functions/lines are untested

**No Enforced Target:**
- No minimum coverage percentage enforced
- Coverage report used to identify gaps
- Manual verification of test completeness

## Test Types

**Unit Tests (Whitebox):**
- Location: `*_wbtest.mbt`
- Scope: Individual functions and internal logic
- Access: Can call private functions
- Example: `mooner_wbtest.mbt` tests `tokenize`, `parse` directly

**Integration Tests (Blackbox):**
- Location: `*_test.mbt`
- Scope: Public API end-to-end
- Access: Only public functions (`@mooner.compile_file`, etc.)
- Example: `mooner_test.mbt` compiles real files and checks success

**E2E Regression Tests:**
- Location: `run_e2e_tests.sh`, `test_examples.sh` (bash scripts)
- Scope: Compare compiler output with official MoonBit compiler
- Not run via `moon test` - separate shell scripts
- Reference output: `moon run example.mbt > expected.txt`
- Our output: `./example.exe > actual.txt`
- Compare with `diff`

**E2E Script Details:**

`run_e2e_tests.sh`:
```bash
for i in 001 002 003 ...; do
  moon run cmd/main "$file"    # Compile with our compiler
  moon run "$file" > moon.txt  # Official MoonBit output
  ./example.exe > our.txt      # Our compiler's output
  diff -q moon.txt our.txt     # Compare
done
```

`test_examples.sh`:
- Similar but simpler, tests subset of examples

## Test Data Patterns

**Token Arrays:**
```moonbit
let tokens = tokenize("let x = 42")
assert_true(tokens[1] is Token::Ident("x"))
assert_true(tokens[3] is Token::Int(42))
```

**AST Patterns:**
```moonbit
let ast = parse(tokens)
match ast {
  AST::Func(name, params, ret_type, body) => /* ... */
  AST::LetBind(var_name, annot, value, body) => assert_eq(var_name, "x")
  _ => assert_true(false)
}
```

**Code Output:**
```moonbit
let code = codegen(ast)
assert_true(code.length() > 0)  // non-empty byte array
```

## Common Test Scenarios

**Lexer Tests (`mooner_wbtest.mbt`):**
- Keywords: `fn`, `let`, `if`, `else`, etc.
- Literals: integers, floats, strings, chars, booleans
- Operators: `+`, `-`, `*`, `/`, `==`, `!=`, etc.
- String interpolation markers

**Parser Tests (`mooner_wbtest.mbt`):**
- Function definitions
- Let bindings (simple and tuple destructuring)
- Arithmetic expressions
- Function calls
- If expressions
- Arrays and tuples

**Compiler Tests (`mooner_test.mbt`):**
- End-to-end compilation succeeds
- Tokenize returns non-empty array
- Parse produces AST of expected variant
- Codegen produces non-empty byte array

## Test Execution Strategy

**Development Workflow:**
1. Write/modify code
2. Run `moon test` to execute unit/whitebox tests
3. Run `bash run_e2e_tests.sh` to verify official compiler parity
4. If E2E tests fail, inspect diffs and debug

**CI/CD (Implied):**
- Likely runs `moon test` on commits
- E2E comparison is manual (bash scripts)
- No GitHub Actions workflow in `.github/` for tests (directory empty)

## Test Coverage Gaps

**Current State:**
- `mooner_wbtest.mbt`: 121 lines covering lexer and parser basics
- `mooner_test.mbt`: 52 lines covering compile pipeline
- Many parser features not tested: match, while, for, struct, enum, etc.
- Codegen completely untested in `_test.mbt` files
- No tests for `compiler.mbt` ELF header generation edge cases
- No tests for error handling/pathological inputs

**Recommended Additions:**
- AST-to-Bytecode round-trip tests
- Edge cases: empty programs, nested expressions, large numbers
- Negative tests: malformed input produces expected errors
- Codegen: verify specific instruction sequences for known programs

## Test File Header Conventions

**Whitebox Tests:**
```moonbit
// Whitebox tests run within the package scope.
// Use them to validate internal helpers or invariants.
// Keep them focused; public behavior belongs in `_test.mbt`.
```

**Blackbox Tests:**
```moonbit
// Blackbox tests - E2E compilation tests
// Run via: bash run_e2e_tests.sh
```

## Snapshot File Location

**Unknown:**
- `moon test --update` creates snapshot files
- Location not observed in repository (likely in `_build/` or hidden directory)
- Snapshots are managed by MoonBit toolchain, not committed to repo

---

*Testing analysis: 2026-03-11*
