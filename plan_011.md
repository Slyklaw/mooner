# Plan: Fix Enum Constructors with Data (Example 011)

## Current Status

- ✅ Simple enums (Red, Green, Blue) work
- ✅ Enum constructors with data work (RGB, RGBA) - stored in global buffer
- ✅ Pattern matching works with underscore patterns (RGB(_))
- ❌ Field binding not implemented (RGB(r, g, b) crashes)

## Implementation Details

### Global Enum Buffer
- 64KB static buffer `.Lenum_buf` 
- `enum_buf_offset` tracks next available offset
- Enum constructors store data in buffer instead of stack

### Pattern Matching
- Works with underscore patterns: `RGB(_)`, `RGBA(_)`

## Field Binding Complexity

Implementing `RGB(r, g, b)` requires:
1. Tracking bound variable names when matching
2. Loading field values from enum buffer when those variables are used

**Challenge:** MoonBit's nested match expressions and variable scoping make this complex.

## Workaround

Use underscore patterns:
```moonbit
RGB(_) => println("RGB")   // ✅ Works
```

Not:
```moonbit
RGB(r, g, b) => println("\{r}")  // ❌ Crashes
```

## Test Results

All examples 001-006, 009-010: IDENTICAL to official compiler
Example 011: Works with underscore patterns

Not working (field binding needed):
```moonbit
RGB(r, g, b) => println("\{r}, \{g}, \{b}")  // Crashes
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
