# Fix Plan: Examples 006 and 013

## Issue Summary

### Example 006 - String Interpolation
**Problem:** When a string variable is used in interpolation (`"Use \{lang}. Happy coding"`), it outputs `<string>` instead of the actual value.

**Root Cause:** In `codegen.mbt:3413-3420`, the string interpolation handling in println checks `var_is_string` but only prints a placeholder.

**Status:** ✅ FIXED! Output now matches official compiler.

---

### Example 013 - Pattern Matching

**Root Cause Found: Function Parameter Type Tracking Broken**

The fundamental issue is that **function parameters don't have their type information tracked**. In `codegen.mbt:7975`:
```moonbit
let (param_name, _) = params[j]  // Type info discarded!
```

This causes:
1. Tuple parameter access (`tuple.0`, `tuple.1`) fails - returns garbage
2. Guard statements fail because they can't determine parameter types
3. All pattern matching on function parameters fails

**Additional Issues:**
- Guard with Struct Patterns - Not implemented (falls through)
- Guard with Array Patterns - Not implemented (falls through)  
- Map Pattern Matching - Not implemented
- Match expression - Multiple bugs with case execution

---

## What's Been Fixed

### 006 - String Interpolation ✅
- Fixed by loading string from stack and calculating length dynamically
- Now prints actual string value instead of `<string>` placeholder

### 013 - Requires Core Type Tracking Fix

The fix requires tracking type information for function parameters, specifically:
1. Recording whether each parameter is a tuple
2. Recording tuple field types
3. Recording whether fields are floats, bools, arrays, etc.

This is a significant architectural change that affects many parts of the codegen.

---

## Current Status

| Example | Status | Notes |
|---------|--------|-------|
| 006 | ✅ FIXED | String interpolation works |
| 013 | ❌ BLOCKED | Requires function parameter type tracking |

---

## Path Forward for 013

To fix 013, need to:
1. **Track parameter types** in `codegen_function`:
   - Parse type annotations from params
   - If tuple type, parse field types
   - Record in var_is_tuple, var_tuple_field_types, etc.

2. **Implement missing guard patterns**:
   - Struct pattern handling
   - Array pattern handling

3. **Fix match expression issues**
