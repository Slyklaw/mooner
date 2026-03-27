# Testing Patterns

**Analysis Date:** 2026-03-26

## Test Framework

MoonBit has built-in test support with two test types:

- **Blackbox tests** (`_test.mbt`): Integration/E2E tests that test the public API
- **Whitebox tests** (`_wbtest.mbt`): Unit tests that can access internal implementation details

**Test Runner:** `moon test`
- Runs all tests in the package
- Discovers `_test.mbt` and `_wbtest.mbt` files automatically

**Configuration:** No separate test config file; tests are compiled and run directly.

## Test File Organization

**Location:** Tests are co-located with the code they test.

**Naming:**
- Blackbox: `package_name_test.mbt`
- Whitebox: `package_name_wbtest.mbt`

**Examples:**
- `mooner_test.mbt` - blackbox tests in package root (52 lines)
- `mooner_wbtest.mbt` - whitebox tests in package root (121 lines)
- `wasm/label_test.mbt` - WASM backend tests (308 lines)
- `wasm/float_test.mbt` - WASM float instruction tests (167 lines)
- `examples/mbt_examples/012_basic_test.mbt` - example usage tests (38 lines)

## Test Syntax

**Basic test block:**
```moonbit
test "descriptive name" {
  // Test body
  assert_eq(actual, expected)
}
```

**From `mooner_test.mbt` (lines 12-23):**
```moonbit
test "compile_file returns ok for valid input" {
  let input_path = "examples/mbt_examples/001_hello.mbt"
  let output_path = "/tmp/mooner_test_001.exe"

  let result = @mooner.compile_file(input_path, output_path, 0)
  assert_true(
    match result {
      Ok(_) => true
      Err(_) => false
    },
  )
}
```

**Anonymous test (no name):** Not typical; name strongly encouraged.

## Assertion Functions

**`assert_eq[T](actual : T, expected : T)`**
- Asserts equality using `==` comparison
- Used for stable, deterministic results

**From `mooner_wbtest.mbt` (lines 26-27):**
```moonbit
test "lexer handles integers" {
  let tokens = tokenize("let x = 42")
  assert_true(tokens[1] is Token::Ident("x"))
  assert_true(tokens[3] is Token::Int(42))
}
```

**`assert_true(condition : Bool)`**
- Asserts that a boolean expression is true
- Useful for pattern matching checks

**From `mooner_wbtest.mbt` (lines 50-54):**
```moonbit
test "parser produces func AST" {
  let tokens = tokenize("fn main { 1 }")
  let ast = parse(tokens)

  assert_true(ast is AST::Func(_, _, _, _))
}
```

**`assert_false(condition : Bool)`**
- Asserts that a boolean expression is false

**From `examples/mbt_examples/012_basic_test.mbt` (line 10):**
```moonbit
test {
  assert_eq(1, 1 + 2)
  assert_false(1 == 2)
  assert_true([1,2,3] == [1,2,3])
}
```

## Snapshot Testing

**Purpose:** Record and verify output of complex or formatted data.

**Function:** `inspect(value)` or `inspect(value, content="expected")`

**From `examples/mbt_examples/012_basic_test.mbt` (lines 15-29):**
```moonbit
/// MoonBit supports snapshot testing.
/// 
/// Pass the value you want to test to the `inspect` function, and run the test with `moon test`.
/// If the output is as expected, you can store the result with `moon test --update`.
/// The next time you run the test, the stored result will be compared with the actual result.
test {
  inspect(fib(5))
  inspect([1,2,3,4].map(fib))
}

/// Add test name to make it more descriptive.
test "fibonacci" {
  inspect(fib(5), content="5")
  inspect(fib(6), content="8")
}
```

**Workflow:**
1. Write test with `inspect(value)`
2. Run `moon test` - snapshot is recorded if new
3. Future runs compare against stored snapshot
4. Use `moon test --update` to refresh snapshots after intentional changes

**Not used in compiler tests:** The `mooner_*.mbt` files use assert functions, not snapshot testing, because they test API behavior rather than output formatting.

## Test Structure Patterns

**Given-When-Then:** Not formalized but commonly followed:
```moonbit
test "description" {
  // Given: setup
  let input = "fn main { 1 }"
  
  // When: exercise
  let tokens = tokenize(input)
  let ast = parse(tokens)
  
  // Then: verify
  assert_true(ast is AST::Func(_, _, _, _))
}
```

**From `mooner_wbtest.mbt` (lines 50-54):**
```moonbit
test "parser produces func AST" {
  let tokens = tokenize("fn main { 1 }")  // Given
  let ast = parse(tokens)                  // When
  assert_true(ast is AST::Func(_, _, _, _))  // Then
}
```

## Test Types

### Whitebox Tests (`_wbtest.mbt`)

**Access:** Internal functions and private implementation details.

**Use cases:**
- Test private helper functions
- Verify invariants within a module
- Test low-level parsing logic
- Validate specific code paths

**Example from `mooner_wbtest.mbt` (lines 6-13):**
```moonbit
test "lexer produces correct tokens for hello" {
  let input = "fn main { println(\"hello\") }"
  let tokens = tokenize(input)

  // Check we have the expected token types
  assert_true(tokens[0] is Token::Fn)
  assert_true(tokens[1] is Token::Ident(_))
}
```

**Scope:** Runs within the package scope; can access `tokenize`, `parse`, etc., even if not public.

### Blackbox Tests (`_test.mbt`)

**Access:** Only public API functions.

**Use cases:**
- End-to-end compilation tests
- API contract verification
- Integration testing

**Example from `mooner_test.mbt` (lines 46-52):**
```moonbit
test "codegen produces bytes" {
  let input = "fn main { println(1) }"
  let tokens = @mooner.tokenize(input)
  let ast = @mooner.parse(tokens)
  let code = @mooner.codegen(ast, 0)
  assert_true(code.length() > 0)
}
```

Note the `@mooner.` prefix to access package exports.

### E2E Tests (External)

**Location:** `run_e2e_tests.sh` script (not a MoonBit test file)

**Pattern:** Bash script compares compiler output with official MoonBit compiler.

**From `mooner_test.mbt` (lines 1-8):**
```moonbit
// Blackbox tests - E2E compilation tests
// Run via: bash run_e2e_tests.sh

// Note: Due to lack of subprocess support in MoonBit's standard library,
// E2E tests are run via a bash script that compares compiler output
// with the official MoonBit compiler.
```

**Workflow:** Script compiles example programs with both compilers and diffs outputs.

## Specific Test Patterns in This Codebase

### Lexer Tests

Test tokenization of various constructs:
```moonbit
test "lexer handles keywords" {
  let keywords = ["fn", "let", "if", "else", "while", "for", "match", "return"]
  let code = keywords.join(" ")
  let tokens = tokenize(code)

  assert_true(tokens[0] is Token::Fn)
  assert_true(tokens[1] is Token::Let)
  // ...
}
```

**Coverage:** Keywords, identifiers, integers, floats, strings, operators.

### Parser Tests

Test AST construction:
```moonbit
test "parser handles let binding" {
  let tokens = tokenize("let x = 1")
  let ast = parse(tokens)

  match ast {
    AST::LetBind(name, _, _, _) => assert_eq(name, "x")
    _ => assert_true(false)
  }
}
```

**Coverage:** Functions, if expressions, arrays, tuples, binary operators, function calls.

### WASM Backend Tests

Test instruction encoding:
```moonbit
test "f32.add generates correct byte sequence (0x92)" {
  let inst = emit_f32_add()
  let bytes = inst.to_bytes()
  assert_eq(bytes[0], 0x92)
}
```

**Pattern:** Test that specific instructions generate correct opcode bytes.

**Advanced pattern:** Labeled control flow (from `wasm/label_test.mbt`):
```moonbit
test "labeled break generates correct bytecode" {
  let mut bytes : Array[Byte] = []
  
  // outer loop (label 1)
  bytes = bytes + emit_loop(block_type_empty()).to_bytes()
  
  // inner loop (label 0)
  bytes = bytes + emit_loop(block_type_empty()).to_bytes()
  
  bytes = bytes + emit_br_if(1).to_bytes()
  bytes = bytes + emit_br(0).to_bytes()
  
  assert_eq(bytes[0], 0x03)  // outer loop
  assert_eq(bytes[2], 0x03)  // inner loop
}
```

## Test Data Setup

**Inline strings:** Test input is typically embedded as string literals.
```moonbit
let input = "fn main { println(1) }"
```

**Array construction:** Use array literals or `+` concatenation.
```moonbit
let mut bytes : Array[Byte] = []
bytes = bytes + emit_loop(...).to_bytes()
```

**No test fixtures:** No separate fixture files; all data inline.

## Mocking and Stubbing

**Not used:** This codebase does not use mocking frameworks. Tests use real functions with small inputs.

**Reason:** Compiler is mostly pure functions (tokenize, parse, codegen), so direct invocation is straightforward.

## Coverage Analysis

**Command:** `moon coverage analyze > uncovered.log`

**From AGENTS.md:**
```bash
moon coverage analyze > uncovered.log
```

**Purpose:** Generate report of which code paths are not covered by tests.

**Not automated:** Coverage analysis is manual; no CI pipeline currently configured.

**Output:** Writes human-readable report to file; not used to enforce coverage thresholds.

## Running Tests

**All tests:**
```bash
moon test
```

**Watch mode:** Not currently supported; must manually re-run.

**Coverage:** Combined with analysis:
```bash
moon test
moon coverage analyze > uncovered.log
```

**Update snapshots:**
```bash
moon test --update
```

**Single test:** Not supported; runs all tests in package.

## Test Dependencies

**Standard library only:** Tests use only `moonbit` stdlib.
- `Array`, `String`, `Int`, `Bool`
- `assert_eq`, `assert_true`, `assert_false`
- `inspect` for snapshot testing

**No external testing frameworks:** MoonBit's built-in test support is used directly.

## Integration with Package System

**Package-level tests:** Tests run per-package; each package's `.mbt` and `_test.mbt` files are compiled with that package.

**Dependencies:** Tests can access `pub` items from dependencies:
```moonbit
let tokens = @mooner.tokenize(input)  // Access from mooner package
```

**Internal access:** `_wbtest.mbt` files run in package scope; they can call private functions without `@` prefix.

## Known Limitations

1. **No subtests:** Each `test` block is atomic; cannot dynamically generate multiple assertions under one test name.
2. **No setup/teardown:** No before/after hooks; setup code must be in each test.
3. **No parameterized tests:** Must duplicate test code for multiple input variations.
4. **No test filtering:** `moon test` runs all tests; cannot select by name or pattern.
5. **No concurrent test execution:** Tests run sequentially.
6. **No E2E in stdlib:** Lack of subprocess means E2E tests require external bash scripts (see `run_e2e_tests.sh`).

## Test Quality Indicators

**Good patterns observed:**
- Descriptive test names: `"lexer handles integers"`, `"parser produces func AST"`
- Small, focused tests: Each tests one behavior
- Direct assertions: Clear pass/fail without complex logic in assertion
- Real inputs: Test with actual code snippets, not mocks

**Areas for improvement:**
- More edge cases: Error recovery, malformed syntax
- Property-based testing: Generate random inputs
- Fuzzing: Not currently used

## Adding New Tests

**For new lexer features:** Add to `mooner_wbtest.mbt`
```moonbit
test "lexer handles new feature" {
  let tokens = tokenize("new syntax")
  // assertions...
}
```

**For new parser features:** Add to `mooner_wbtest.mbt`
```moonbit
test "parser handles new construct" {
  let ast = parse(tokenize("new construct"))
  match ast {
    AST::NewVariant(...) => assert_true(true)
    _ => assert_true(false)
  }
}
```

**For public API changes:** Add to `mooner_test.mbt`
```moonbit
test "new public function works" {
  let result = @mooner.new_function(input)
  match result {
    Ok(_) => assert_true(true)
    Err(msg) => assert_true(false)
  }
}
```

**For WASM backend:** Add to `wasm/` directory, either new file or `wasm_backend_test.mbt` (not yet created).

## Test Commands Summary

```bash
moon test                      # Run all tests
moon test --update             # Update snapshots
moon coverage analyze > file   # Generate coverage report
bash run_e2e_tests.sh          # Run E2E comparison tests
bash test_examples.sh          # Run example program tests
```
