# Plan 011: Fix Enum Constructors with Data

## Summary

### What Works Now ✅

1. **Simple enum variants** (Red, Green, Blue without data)
2. **Enum constructors with data** (RGB(Int, Int, Int), RGBA(Int, Int, Int, Int))
3. **Pattern matching** on enum values stored in variables or passed to functions
4. **Field binding** in patterns (e.g., `RGB(r, g, b) => r + g + b`)
5. **Passing enum values** to and from functions
6. **Multiple enum variants** in the same enum type
7. **String + string concatenation** works
8. **No more segfault** from string interpolation
9. **String + int concatenation** now works correctly with proper int-to-string conversion

### Root Causes Fixed

1. **Removed errant debug code** (lines 3610-3612) - was incorrectly writing to a RIP-relative address
2. **Changed threshold from 4096 to 256** - distinguishes between direct discriminant values and pointers
3. **Fixed string + int bug** - the code was treating any string + any value as string concatenation, crashing when the second operand wasn't a string
   - Added `is_string_concat` to check if BOTH operands are strings
   - Added fallback that wraps non-string operand in `int_to_string()` call

### Test Results

Working:
```moonbit
enum Color { Red, Green, RGB(Int, Int, Int) }
let c = RGB(10, 20, 30)
match c {
  Red => 0
  Green => 1
  RGB(r, g, b) => r + g + b // Returns 60
}
```

The 011 example now runs with IDENTICAL output to official MoonBit compiler:
```
Red
Green
RGB: 0, 0, 255
Blue
RGBA: 255, 0, 0, 128
```

### Verified Examples

| Example | Status |
|---------|--------|
| 001_hello | IDENTICAL |
| 002_variable | IDENTICAL |
| 004_basic_function | IDENTICAL |
| 005_basic_array | IDENTICAL |
| 006_basic_string | IDENTICAL |
| 009_basic_control_flows | IDENTICAL |
| 010_basic_struct | IDENTICAL |
| **011_basic_enum** | **IDENTICAL** ✅ |

Pre-existing differences (not related to this fix):
- 007_basic_tuple - tuple display format differs
- 008_basic_map - map display format differs
