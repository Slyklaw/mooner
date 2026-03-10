# State: Mooner Compiler

## Project Reference

**Project Name:** Mooner  
**Core Value:** Compile standard MoonBit language to working x86_64 Linux executables that match official MoonBit compiler output.  
**Current Focus:** Phase 3 - Enum Pattern Matching

## Current Position

| Attribute | Value |
|-----------|-------|
| **Phase** | 3 - Enum Pattern Matching |
| **Status** | In progress - implementing enum data constructors |
| **Progress** | [==  ] 30% |

## Phase 1-2: Complete

### Completed Features (from PROJECT.md)

- fn main entry point
- Integer, float, boolean, char literals
- Variables (let bindings, mutable assignment, compound assignment)
- Arithmetic operators (+, -, *, /, %)
- Bitwise operators (&, |, ^, <<, >>)
- Comparison operators (==, !=, <, >, <=, >=)
- Unary operators (-, !)
- Print/println for strings, ints, floats, chars
- If/else expressions
- While/for loops with break/continue
- Match expressions (int, bool, wildcard patterns)
- Function definitions and calls
- Return statements
- Array literals, indexing, assignment, length(), push(), concatenation, spread
- Tuple literals and field access
- String operations (concat, get_char, comparison, length)
- Unicode escape sequences
- Struct definitions, construction, field access, mutation, functional update
- Enum definitions and constructors (simple variants)
- Test blocks (assert_eq, assert_true, assert_false, inspect)
- Map type support

## Phase 3: In Progress

### Fixed in Phase 3

1. **User function return values** - ✓ FIXED
   - Block handling now properly processes ReturnExpr
   - Functions with explicit return work: `fn f() -> Int { return 99 }`
   - Functions with expression body work: `fn f() -> Int { a + b }`

2. **Function call in println** - ✓ FIXED  
   - Added CallExpr handling in println argument processing
   - `println(add(2, 40))` now works correctly

3. **Enum field extraction in function** - ✓ FIXED
   - Match now extracts fields correctly when enum passed to function
   - `RGB(r,g,b)` pattern extracts correct values (0, 0, 255)
   - `println(r)` prints correct value when r is from enum pattern match

4. **LetBind after match with enum fields** - ✓ FIXED
   - Root cause: Functions didn't preserve callee-saved registers (r12-r15)
   - Match code uses r12 to hold enum pointer, which was being clobbered by function calls
   - Fixed by adding callee-saved register preservation to function prologue/epilogue
   - Also fixed match code to adjust next_offset when pushing scrutinee

5. **int_to_string null termination** - ✓ FIXED
   - Fixed int_to_string function to null-terminate for string concatenation
   - Used Dec/Inc pattern to properly position null terminator without overwriting digits

### Known Issues

1. **String interpolation with value 0 in println** - ✗ BUG
   - `println("RGB: \{r}, \{g}, \{b}")` where r=0, g=0 prints "RGB: , , 255"
   - `let s = "\{r}"; println(s)` works correctly (0 prints as "0")
   - Root cause: println uses inline int-to-string code (not int_to_string function)
   - Inline code doesn't null-terminate, causing string concatenation to read wrong data

2. **Pattern matching guards/destructuring (013_pattern_matching)** - Not supported
3. **Derive(Show) macro** - Not implemented
4. **Float precision** - Some float operations show precision differences

### Test Results

| Example | Status |
|---------|--------|
| 003_basic_constants | ✓ PASS |
| 004_basic_function | ✓ PASS |
| 005_basic_array | ✓ PASS |
| 008_basic_map | ✓ PASS |
| 009_basic_control_flows | ✓ PASS |
| 010_basic_struct | ✓ PASS |
| 011_basic_enum | ✓ Mostly (only 0 in println interp fails) |
| 006_basic_string | Minor diff |
| 007_basic_tuple | Float precision |

## Key Decisions

| Decision | Rationale | Status |
|----------|-----------|--------|
| Use global enum buffer | Simpler than per-function allocation | Working |
| Stack offsets -128+ for match bindings | Avoid collision with LetBind vars | Working |
| Match uses r12 register | Holds enum pointer for field extraction | Working (with callee-saved fix) |
| Preserve callee-saved registers | Required for r12 to survive function calls | Implemented |

## Summary of Today's Fixes

### Critical Bug Fix: Callee-Saved Register Preservation
**Problem:** Functions didn't preserve r12-r15, causing match enum pointer to be corrupted
**Solution:** Added push/pop of rbx, r12-r15 in function prologue/epilogue
**Impact:** Fixed LetBind after match, function calls in match bodies

### Match next_offset Fix
**Problem:** Match pushed scrutinee but didn't adjust next_offset
**Solution:** Decrement next_offset on push, increment on cleanup
**Impact:** Fixed stack offset calculations for LetBind inside match

### int_to_string Null Termination
**Problem:** int_to_string didn't null-terminate, breaking string concatenation
**Solution:** Added Dec/Mov/Inc pattern to null-terminate correctly
**Impact:** Fixed 0 in string interpolation when using let binding

## Next Steps

1. Complete Phase 3: Enum Pattern Matching
   - Implement enum data constructors (RGB(r, g, b))
   - Implement pattern binding for enum variants
   - Support nested enum pattern matching
2. Phase 4: Pattern Matching Enhancements
   - Implement guard expressions
   - Implement destructuring patterns
   - Implement or patterns
3. Phase 5: Derive(Show) Macro
