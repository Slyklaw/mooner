# Testing Patterns

**Analysis Date:** 2026-03-25

## Test Framework

**Runner:**
- MoonBit built-in test framework (`moon test`)
- Configuration: no separate config file; tests are defined in `*_test.mbt` and `*_wbtest.mbt` files

**Assertion Library:**
- Built-in assertions: `assert_true`, `assert_false`, `assert_eq`
- Snapshot testing via `inspect` function

**Run Commands:**
```bash
moon test                     # Run all tests
moon test --update            # Update snapshot test outputs
moon coverage analyze         # Analyze test coverage
```

## Test File Organization

**Location:**
- Blackbox tests: files ending in `_test.mbt` (e.g., `mooner_test.mbt`)
- Whitebox tests: files ending in `_wbtest.mbt` (e.g., `mooner_wbtest.mbt`)
- Example tests: `examples/mbt_examples/012_basic_test.mbt`

**Naming:**
- Blackbox test files: `<module>_test.mbt`
- Whitebox test files: `<module>_wbtest.mbt`
- Example test files: descriptive names like `012_basic_test.mbt`

**Structure:**
```
mooner_test.mbt          # Blackbox E2E compilation tests
mooner_wbtest.mbt        # Whitebox unit tests for lexer/parser
examples/mbt_examples/   # Example programs with integrated tests
```

## Test Structure

**Suite Organization:**
```moonbit
///|
test "description" {
  // test body
}
```

**Patterns:**
- Each test is a `test` block with optional string description
- Blocks separated by `///|` comment line
- Test blocks can be named: `test "compile_file returns ok for valid input" { ... }`
- Anonymous test blocks: `test { ... }`

**Setup/Teardown:**
- No explicit setup/teardown hooks; each test is independent
- Common setup via local function calls within test block

**Assertion Patterns:**
```moonbit
assert_true(condition)
assert_false(condition)
assert_eq(expected, actual)
```

**Snapshot Testing:**
```moonbit
inspect(value)                    # Snapshot with default formatting
inspect(value, content="5")       # Snapshot with explicit expected content
```

## Mocking

**Framework:** Not used

**Patterns:**
- No mocking framework detected in codebase
- Tests call internal functions directly (whitebox tests)
- External dependencies (file I/O) not mocked; tests use real files

**What to Mock:**
- N/A - mocking not practiced

**What NOT to Mock:**
- N/A

## Fixtures and Factories

**Test Data:**
- Test inputs are inline strings: `"fn main { println(1) }"`
- Example programs in `examples/` directory serve as integration test fixtures

**Location:**
- Test data embedded in test files
- Example programs in `examples/mbt_examples/`

## Coverage

**Requirements:** No explicit coverage threshold enforced

**View Coverage:**
```bash
moon coverage analyze > uncovered.log
```

**Coverage Output:**
- Lists uncovered lines per file with line numbers and snippets
- Warnings about reserved keywords
- Summary: total uncovered lines across files

## Test Types

**Unit Tests:**
- Whitebox tests (`*_wbtest.mbt`) test internal functions
- Example: lexer tokenization, parser AST construction
- Scope: single module internals

**Integration Tests:**
- Blackbox tests (`*_test.mbt`) test public API via `@mooner.compile_file`, `@mooner.tokenize`, etc.
- E2E tests via `run_e2e_tests.sh` compare output with official MoonBit compiler

**E2E Tests:**
- Script-based: `run_e2e_tests.sh` and `test_examples.sh`
- Compiles example programs, runs executables, diffs output against official compiler
- No MoonBit-native E2E test framework

## Common Patterns

**Async Testing:**
- Not used; no async code in compiler

**Error Testing:**
```moonbit
let result = @mooner.compile_file(input_path, output_path, 0)
assert_true(
  match result {
    Ok(_) => true
    Err(_) => false
  },
)
```

**Pattern Matching in Tests:**
```moonbit
match ast {
  AST::Func(_) => assert_true(true),
  _ => assert_true(false),
}
```

**Token Verification:**
```moonbit
assert_true(tokens[0] is Token::Fn)
assert_true(tokens[1] is Token::Ident(_))
```

**Snapshot Test Examples:**
```moonbit
test "fibonacci" {
  inspect(fib(5), content="5")
  inspect(fib(6), content="8")
}
```

---

*Testing analysis: 2026-03-25*