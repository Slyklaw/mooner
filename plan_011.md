# Plan: Fix Enum Constructors with Data (Example 011)

## Problem Analysis

When creating enum variants with data (e.g., `RGB(1, 2, 3)`), the current implementation:
1. Allocates space on the stack for the enum data
2. Stores discriminant at [rsp], args at [rsp+8], [rsp+16], etc.
3. Returns a pointer to this stack memory
4. **Does NOT restore rsp**, causing stack corruption
5. Even if we restored rsp, the data would become invalid after function returns

## Current Status (After Implementation)

- ✅ Simple enums (Red, Green, Blue) work
- ✅ Enum constructors with data work (RGB, RGBA) 
- ✅ Pattern matching works for basic cases
- ⚠️ Field binding in patterns not implemented (causes crash when accessing r, g, b)

## What Was Implemented

### 1. Global Enum Buffer
- Added 64KB static buffer `.Lenum_buf` in codegen
- Added `enum_buf_offset` field in CodeGen state to track next available offset

### 2. Constructor Uses Buffer
- Enum constructors with data now store data in static buffer instead of stack
- Returns pointer to buffer location
- Offset increments for each new enum

### 3. Pattern Matching
- CallExpr patterns (RGB(r,g,b)) work when fields aren't accessed
- Ident patterns (simple enums) work correctly

## Remaining Issue: Field Binding

When pattern matching with `RGB(r, g, b)`, the code should:
1. Load discriminant from enum buffer to check variant type
2. Load field values from buffer and bind to local variables (r, g, b)
3. Execute match body with bound variables

Currently, step 2 is not implemented - the binding is skipped. When the match body tries to use r, g, b, it accesses uninitialized stack memory causing the crash.

### Fix for Field Binding (Future Task)

```moonbit
// In CallExpr pattern matching:
// After matching discriminant, need to:
// 1. Load pointer to enum data from stack
// 2. For each binding (r, g, b):
//    - Calculate offset = 8 + bind_idx * 8
//    - Load value from [pointer + offset]
//    - Store in new local variable at current stack offset
```

This requires:
- Tracking the match body's local variable scope
- Allocating new stack slots for bound variables  
- Loading from enum buffer with correct offsets

## Test Results

Working:
```moonbit
enum Color { Red, Green, RGB(Int) }
let c = RGB(10)
match c {
  Red => println("Red")
  RGB(_) => println("RGB")  // Works!
}
```

Not working (field binding needed):
```moonbit
RGB(r, g, b) => println("\{r}, \{g}, \{b}")  // Crashes
```
