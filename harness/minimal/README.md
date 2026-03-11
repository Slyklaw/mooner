# Minimal Reproduction Suite

These files isolate specific bugs for faster debugging. Each file tests exactly one language feature that is currently failing in the compiler.

## Bug Mapping

- `004_minimal.mbt` → Function call with 2 args returning sum
- `009_if_minimal.mbt` → Simple if/else branching
- `009_for_minimal.mbt` → Simple for loop (and while loop)
- `011_minimal.mbt` → Enum with 3 variants, pattern match
- `013_minimal.mbt` → Struct with fields, pattern match destructuring

## Usage

### Compile and run with our compiler:
```bash
moon run cmd/main harness/minimal/004_minimal.mbt
moon run cmd/main harness/minimal/009_if_minimal.mbt
moon run cmd/main harness/minimal/009_for_minimal.mbt
moon run cmd/main harness/minimal/011_minimal.mbt
moon run cmd/main harness/minimal/013_minimal.mbt
```

### Expected Outputs

- `004_minimal.mbt`: Should print `42`
- `009_if_minimal.mbt`: Should print `1\n0\n` (true branch then false branch)
- `009_for_minimal.mbt`: Should print `0\n1\n2\n0\n1\n` (for loop then while loop)
- `011_minimal.mbt`: Should print `Red\nGreen\nBlue\n` (one line per match)
- `013_minimal.mbt`: Should print `10\n40\n50\n` (one line per match)

### Current Status

These files may currently produce wrong output or crash - that's expected. They are designed to isolate the exact bug patterns so we can fix them systematically. Once fixed, each should produce the expected output shown above.

## Debugging Workflow

1. Run the minimal file with the compiler
2. Observe the output (correct or incorrect)
3. Use the minimal file to isolate the bug in the codebase
4. Fix the bug in the relevant module (lexer, parser, codegen)
5. Verify the fix by running the minimal file again
6. Test against the full test suite to ensure no regressions

These minimal reproductions are essential for efficient debugging and verification of each fix.