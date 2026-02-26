# Plan 011: Fix Enum Constructors with Data

## Summary

### What Works Now ✅

1. **Simple enum variants** (Red, Green, Blue without data)
2. **Enum constructors with data** (RGB(Int, Int, Int), RGBA(Int, Int, Int, Int))
3. **Pattern matching** on enum values stored in variables or passed to functions
4. **Field binding** in patterns (e.g., `RGB(r, g, b) => r + g + b`)
5. **Passing enum values** to and from functions
6. **Multiple enum variants** in the same enum type

### Root Causes Fixed

1. **Removed errant debug code** (lines 3610-3612) - was incorrectly executing a MOV to a RIP-relative address
2. **Changed threshold from 4096 to 256** - the original threshold was too large, causing enum variants with discriminant values >= 3 to be treated as direct discriminants instead of pointers

### Known Issues

1. **String interpolation bug** - Using `"\(var)"` or `"text: \{var}"` causes a segfault. This is a separate bug that blocks some enum test cases.
   - Workaround: Use separate print statements or print with concatenation

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

The 011 example test uses string interpolation in match bodies which triggers the string interpolation bug, causing a crash after the first two cases.
