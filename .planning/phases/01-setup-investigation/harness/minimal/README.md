# Minimal Reproduction Test Suite

## Purpose

These minimal test files isolate specific codegen bugs observed in the MoonBit compiler. Each file contains the smallest possible code that reproduces a particular failure, making it easier to:
- Understand the exact scope of each bug
- Test fixes quickly without running full examples
- Document expected vs actual behavior

## Files and Bug Mapping

| File | Bug ID | Description | Expected Output |
|------|--------|-------------|-----------------|
| `004_minimal.mbt` | 004 | Function call return value | `42` |
| `009_if_minimal.mbt` | 009 | If/else conditional branching | `1` |
| `009_for_minimal.mbt` | 009 | For loop iteration | `0`, `1`, `2` (each on new line) |
| `011_minimal.mbt` | 011 | Enum definition and pattern matching | `Red` |
| `013_minimal.mbt` | 013 | Struct pattern matching with destructuring | `10` |

## Usage

### Compile and run with our compiler:
```bash
moon run cmd/main minimal/<file>.mbt
# .exe will be created in the same directory as the source
./minimal/<file>.exe
```

### Compile and run with reference MoonBit compiler:
```bash
moon run minimal/<file>.mbt
```

### Compare outputs:
```bash
# Run both and compare
moon run cmd/main minimal/004_minimal.mbt && ./004_minimal.exe > our_output.txt
moon run minimal/004_minimal.mbt > ref_output.txt
diff -u ref_output.txt our_output.txt
```

## Current Status

All minimal files should compile successfully with our compiler (no syntax errors). However, runtime behavior may be incorrect:
- **004_minimal**: Outputs `80` instead of `42` (function return value bug)
- **009_if_minimal**: May crash or produce wrong output (branching bug)
- **009_for_minimal**: May crash or infinite loop (loop construct bug)
- **011_minimal**: May crash or print wrong variant (enum pattern matching bug)
- **013_minimal**: May crash or print wrong field value (struct pattern matching bug)

## Notes

- These files use `println` which is available in the test examples and should work in our compiler's runtime.
- The bugs are in the codegen phase, not parsing or type checking.
- Once a bug is fixed, re-run the minimal test to verify the fix produces the expected output.
- Use `--debug-codegen` flag with our compiler to trace instruction generation for debugging:
  ```bash
  moon run cmd/main minimal/013_minimal.mbt -- --debug-codegen 2>&1 | less
  ```