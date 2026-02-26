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
8. **No more segfault** from string interpolation (though int values don't convert to strings yet)

### Root Causes Fixed

1. **Removed errant debug code** (lines 3610-3612) - was incorrectly writing to a RIP-relative address
2. **Changed threshold from 4096 to 256** - distinguishes between direct discriminant values and pointers
3. **Fixed string + int bug** - the code was treating any string + any value as string concatenation, crashing when the second operand wasn't a string
   - Added `is_string_concat` to check if BOTH operands are strings
   - Added fallback for string + non-string (returns empty string for now)

### Known Limitations

1. **String + int concatenation** returns empty string instead of converting int to string
   - This affects string interpolation like `"value: \{x}"` - prints empty for the int part
   - Full int-to-string concatenation would require implementing proper int_to_string function

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
