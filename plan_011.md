# Plan 011: Fix Enum Constructors with Data

## Summary

### Current Status

1. ✅ Simple enums (Red, Green) work when NOT mixed with enums with data
2. ✅ Passing enum values to functions works
3. ✅ Pattern matching with underscore works (`RGB(_) => ...`)
4. ❌ Pattern matching with enum constructors crashes or returns wrong value

### Root Causes Identified

1. **Missing pointer/direct discriminant check**: The CallExpr pattern matching code assumed all values are pointers, but simple enums store discriminants directly. Fixed by adding 4096 threshold check.

2. **Potential issue with enum buffer addressing**: The enum buffer is defined in the code section, and RipRel32 addressing may not be computing addresses correctly, resulting in pointer value 0.

### Debugging Notes

- Creating `RGB(10)` and returning it directly returns 0 instead of a valid pointer
- This suggests the enum buffer address computation is broken
- The issue is NOT in the pattern matching code itself, but in how the enum constructor stores/returns the buffer address

### Test Results

Working:
```moonbit
enum Color { Red, Green, RGB(Int) }
let c = RGB(10)
match c {
  _ => 999  // Returns 999 - underscore works
}
```

Not working:
```moonbit
enum Color { Red, RGB(Int) }
let c = RGB(10)
match c {
  RGB(_) => 111  // Should return 111, but returns 0
  Red => 0
}
```

## Next Steps

1. Debug the enum buffer address computation - verify RipRel32 is computing correct addresses
2. Consider storing enum buffer in a known location (e.g., at fixed address)
3. Once enum constructor returns correct pointer, field binding should work
