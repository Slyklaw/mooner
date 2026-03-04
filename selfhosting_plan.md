# Plan: Debug Self-Hosted Compiler Examples

## Status Summary

| Example | Status | Issue |
|---------|--------|-------|
| 001_hello | PASS | Fixed heredoc syntax - correctly handles #| start/end markers |
| 002_variable | PASS | |
| 003_basic_constants | PASS | |
| 004_basic_function | PASS | |
| 005_basic_array | PASS | Fixed array indexing off-by-one |
| 006_basic_string | PASS | Fixed string interpolation - properly handles `\{expr}` syntax |
| 007_basic_tuple | PASS | Float tuple printing now works! Fixed float literals using add_float (IEEE 754), bool printing, array printing, type annotation parsing, AND tuple destructuring with string interpolation using Ryu float-to-string conversion |
| 008_basic_map | PASS | Map creation, access, equality, update, and printing all work! |
| 009_basic_control_flows | PASS | |
| 010_basic_struct | PASS | |
| 011_basic_enum | PASS | Fixed by string interpolation fix in 006 |
| 012_basic_test | FAIL | Test framework not supported |
| 013_pattern_matching | PASS | Pattern matching works for basic cases |

**12 passed, 1 expected failure (012 - test framework not supported)**

## Debugging Order

### Phase 1: High Impact, Low Complexity

1. **005_basic_array** - Array indexing returns wrong value
   - Expected: `2`, Got: `1`
   - Likely off-by-one error in codegen or array access

### Phase 2: String Interpolation

2. **006_basic_string** - String interpolation
3. **011_basic_enum** - String interpolation in derive

### Phase 3: Float/Tuple

4. **007_basic_tuple** - Float tuple printing

### Phase 4: Advanced Features

5. **008_basic_map** - Map support
6. **012_basic_test** - Test framework
7. **013_pattern_matching** - Pattern matching

### Phase 5: Complex Issues

8. **001_hello** - Multiline string crash
   - FIXED: MoonBit heredoc uses #| for both start AND end markers
   - Fixed lexer to detect end marker (#| followed by newline) vs dedent prefix (#| followed by content)
   - Also handles backslash as literal in heredocs

## Recent Fixes

### Float-to-String Conversion (Ryu Algorithm) - COMPLETE!

- **Implemented `ryu_to_string()` function** with full Ryu floating-point to string conversion algorithm
- Converts IEEE 754 doubles to shortest round-trippable decimal representation
- Handles: positive/negative, zero, subnormal numbers, scientific notation, special values (NaN, Infinity)

### String Interpolation Improvements - COMPLETE!

- **Float literals**: `"{3.14}"` now prints `"3.14"` (uses Ryu algorithm)
- **Float variables**: Tuple-destructured float variables print their compile-time values
- **Int literals**: `"{42}"` prints `"42"`
- **Bool variables**: Print `"true"`/`"false"` correctly
- **Array variables**: Print tracked array values like `"[1, 2, 3]"`
- **Expression parsing**: Updated `parse_interpolation_expr()` to parse numeric literals (float/int) in addition to identifiers

### Binary Expressions in Interpolation - COMPLETE!

- **Float arithmetic**: `"{1.0/3.0}"` → `"0.3333333333333333"`
- **Integer arithmetic**: `"{10/3}"` → `"3"` (integer division)
- **Mixed operators**: `"{2.0 + 3.0}"`, `"{10 - 4}"`, `"{6 * 7}"` all work
- **Operator precedence**: `*`, `/` have higher precedence than `+`, `-`
- **Proper type handling**: Integer vs float arithmetic produces correct results

**Example:**
```moonbit
println("1.0/3.0: \{1.0/3.0}")  // Output: 1.0/3.0: 0.3333333333333333
println("10/3: \{10/3}")        // Output: 10/3: 3
```

### Example 007 - Fully Working!

Tuple destructuring with string interpolation now works:
```moonbit
let (a, b, c) = (3.14, false, [1,2,3])
println("{a}, {b}, {c}")  // Output: 3.14, false, [1, 2, 3]
```

### Previous Fixes

- 007_basic_tuple: Fixed float literals using `add_float` (IEEE 754 doubles), bool printing in tuples, array printing in tuples, and type annotation parsing for tuples
- 008_basic_map: Complete! Map creation, access, equality, update, and printing all work
- 005_basic_array: Fixed array indexing (off-by-one in codegen)
- 006_basic_string: Added unicode escape `\u{XXXX}` support in lexer
- 001_hello: Fixed heredoc syntax - uses #| for start/end, correctly detects end marker

## Verification Command

```bash
for i in 001 002 003 004 005 006 007 008 009 010 011 012 013; do
  file=$(ls examples/mbt_examples/${i}_*.mbt 2>/dev/null | head -1)
  if [ -n "$file" ]; then
    moon run cmd/main "$file" 2>/dev/null
    if [ -f "${file%.mbt}.exe" ]; then
      chmod +x "${file%.mbt}.exe"
      ./"${file%.mbt}.exe" > "/tmp/our_${i}.txt" 2>&1
      moon run "$file" > "/tmp/moon_${i}.txt" 2>&1
      if diff -q "/tmp/moon_${i}.txt" "/tmp/our_${i}.txt" > /dev/null 2>&1; then
        echo "$i: PASS"
      else
        echo "$i: FAIL"
      fi
    else
      echo "$i: COMPILE ERROR"
    fi
  fi
done
```

## Tasks

### Completed

- [x] 005_basic_array: Fix array indexing
- [x] 006_basic_string: Implement string interpolation - COMPLETE!
- [x] 007_basic_tuple: Fix float tuple printing - COMPLETE!
- [x] 007_basic_tuple: Float literals in string interpolation - COMPLETE!
- [x] 007_basic_tuple: Tuple destructuring with string interpolation - COMPLETE!
- [x] 008_basic_map: Add map support - COMPLETE!
- [x] 011_basic_enum: Fixed via string interpolation in 006
- [x] 013_pattern_matching: Complete pattern matching - COMPLETE!
- [x] 001_hello: Fixed heredoc syntax - COMPLETE!
- [x] **Binary expressions in interpolation**: `"{1.0/3.0}"`, `"{10 + 5}"`, etc. - COMPLETE!
  - Simple binary expressions with numeric literals now work
  - Proper integer vs float arithmetic (10/3 = 3, 10.0/3.0 = 3.333...)
  - Supports: +, -, *, / operators

### In Progress / Future

- [ ] 012_basic_test: Add test framework support (expected to fail)
- [ ] Chained binary expressions: `"{1.0 + 2.0 + 3.0}"` (currently shows `<expr>`)
- [ ] Binary expressions with variables: `"{x + 5}"` (currently shows `<expr>`)

---

*Created: 2026-03-01*
*Updated: 2026-03-03 - Binary expressions in interpolation now working! Added support for +, -, *, / with proper integer/float arithmetic*
