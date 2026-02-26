# Plan 011: Fix Enum Constructors with Data

## Summary

### Current Status

1. ✅ Simple enums (Red, Green) work when NOT mixed with enums with data
2. ✅ Passing enum values to functions works
3. ✅ Pattern matching with underscore works (`RGB(_) => ...`)
4. ❌ Pattern matching with enum constructors crashes or returns wrong value
5. ❌ Field binding in patterns doesn't work in all cases

### Root Causes Identified

1. **Debug code left in**: There was errant debug code (lines 3610-3612) that was MOVing to a RIP-relative address incorrectly. This has been removed.

2. **Missing pointer/direct discriminant check**: The CallExpr pattern matching code assumed all values are pointers, but simple enums store discriminants directly. Fixed by adding 4096 threshold check.

3. **Pattern matching on function parameters**: There's an issue with matching on enum values that are passed as function parameters or returned from functions. The scrutinee evaluation and push appears to work, but the pattern matching doesn't match correctly in some cases.

### What Works

- `RGB(10)` constructor returns valid pointer (verified: 4204667)
- Direct matching on literal enums works: `match RGB(10) { RGB(n) => ... }`
- Passing enum directly to function works: `print_color(RGB(10))`
- Using underscore pattern works: `match c { _ => 100 }`

### What Doesn't Work

- Matching on enum returned from function: `let c = foo(); match c { ... }`
- Matching on enum stored in variable first, then passed to function
- Field binding in certain contexts

### Next Steps

1. Debug the function parameter/return value matching issue - likely related to how the scrutinee value is being loaded or compared
2. Test field binding (`RGB(r, g, b) => ...`) in contexts that work
3. Run full test suite to verify all enum functionality works
