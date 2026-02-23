# Plan: Get Official MoonBit Examples Working

## Status Summary

| Example | Compile | Run | Priority Issues |
|---------|---------|-----|-----------------|
| 001_hello | ✅ | ✅ | OUTPUT MATCHES official |
| 002_variable | ✅ | ✅ | OUTPUT MATCHES official |
| 003_basic_constants | ✅ | ✅ | OUTPUT MATCHES official |
| 004_basic_function | ✅ | ✅ | OUTPUT MATCHES official |
| 005_basic_array | ✅ | ⚠️ | `arr.length()`, `arr[i]`, `arr.push()`, `println(arr)` work; concat (+) returns right array; spread not implemented |
| 006_basic_string | ✅ | ⚠️ | get_char(), unwrap(), char equality, concat (+), escape sequences work; unicode shows '?'; interpolation not implemented |
| 007_basic_tuple | ✅ | ⚠️ | Int/float tuple field access works; printing shows `<tuple>`; destructuring broken |
| 008_basic_map | ✅ | ❌ | **Segfault** - maps unsupported |
| 009_basic_control_flows | ✅ | ✅ | OUTPUT MATCHES official |
| 010_basic_struct | ✅ | ⚠️ | Struct field access works; printing shows `<struct>` |
| 011_basic_enum | ✅ | ⚠️ | **FIXED**: Match expression works for int/wildcard; enum discriminants not implemented (all are 0) |
| 012_basic_test | ✅ | ❌ | Test blocks parse but not executed |
| 013_pattern_matching | ✅ | ⚠️ | **FIXED**: Basic match works for int/wildcard patterns |

## Recent Fixes

### 2024-02-22: Pattern Matching Implementation
- **Issue**: Match expressions were broken (just returned scrutinee value)
- **Root cause**: Parser expected `case` keyword but MoonBit uses `pattern => body` syntax
- **Fix**: Updated parser to handle MoonBit match syntax, implemented match codegen
- **Result**: Match now works for integer literals and wildcard patterns
- **Limitation**: Enum discriminants not implemented, destructuring not supported

### 2024-02-22: Struct Field Access Fixed
- **Issue**: Struct field access returned 0 for all fields
- **Root cause**: StructLit was incorrectly updating `next_offset` during field pushes, causing LetBind to calculate wrong offsets
- **Fix**: Removed `next_offset` update in StructLit, matching Tuple behavior
- **Result**: Struct field access now works correctly for both anonymous and named structs

### 2024-02-21: Float Truncation Bug Fixed
- **Issue**: Float values were being rounded instead of truncated when printing
  - 2.71 → printed as "3.0" (should be "2.0")
  - 5.5 → printed as "6.0" (should be "5.0")
- **Root cause**: Used `cvtsd2si` (round to nearest) instead of `cvttsd2si` (truncate toward zero)
- **Fix**: Changed opcode from `0x2D` to `0x2C`, renamed `Cvtsd2si` → `Cvttsd2si` in codegen.mbt
- **Result**: Float variables now work correctly with multiple floats

## Phase 1: Core Runtime (HIGH PRIORITY)

These are foundational issues blocking multiple examples.

### 1.1 Output System
- [x] Fix `println()` to output strings correctly (multiline `#|` strings now supported)
- [x] Fix `println()` to output integer values correctly
- [x] Fix `println()` to output boolean values (true/false, not 0/1)

### 1.2 Expressions & Arithmetic
- [x] Fix integer arithmetic (10 + 20 should = 30, not 0)
- [x] Fix boolean literals (false should print as "false")
- [x] Fix variable assignment and retrieval (`let mut` now parses correctly)

### 1.3 Function Calls
- [x] Fix function calls with arguments `add(2, 40)`
- [x] Fix function return values
- [x] Fix nested function calls
- [x] Fix multiple top-level function declarations

### 1.4 Control Flow - Conditionals
- [ ] Fix if/else to execute correct branch
- [ ] Implement if/else as expressions (return values)

## Phase 2: Data Types (HIGH-MEDIUM PRIORITY)

### 2.1 Number Literals
- [x] Support hex literals `0xFFFF`
- [x] Support binary literals `0b1001`
- [x] Support underscore separators `100_000_000`

### 2.2 Arrays
- [x] Implement Array type with literal syntax `[1, 2, 3]`
- [x] Implement array indexing `arr[0]`
- [x] Implement `array.length()` method (reads from array header)
- [x] Implement string `length()` method (counts chars until null terminator)
- [x] Implement array element assignment `arr[i] = value`
- [x] Implement array printing in `println` (loop-based printing with comma separators)
- [x] Array layout: `[length][elem0][elem1]...` (length at offset 0, elements at offset 8)
- [ ] Implement `array.push()` mutation
- [ ] Implement array concatenation `arr1 + arr2`
- [ ] Implement spread operator `[..arr1, 1000, ..arr2]`

### 2.3 Strings
- [ ] Implement String concatenation `str1 + str2`
- [ ] Implement `string.get_char(index)`
- [ ] Implement escape sequences `\n`, `\t`, `\u{}`
- [ ] Implement string interpolation `"\{lang}"`

### 2.4 Tuples
- [ ] Implement Tuple type `(a, b, c)`
- [ ] Implement tuple element access `tuple.0`

## Phase 3: Control Flow (MEDIUM PRIORITY)

### 3.1 Loops
- [x] Implement C-style for loop `for i=0; i<n; i=i+1`
- [x] Implement for-in loop `for x in arr` ✅
- [x] Implement while loop
- [ ] Implement break statement
- [ ] Implement continue statement

## Phase 4: Structured Data (MEDIUM-LOW PRIORITY)

### 4.1 Structs
- [ ] Parse struct definitions
- [ ] Implement struct construction `{ x: 3, y: 4 }`
- [ ] Implement struct field access `point.x`
- [ ] Implement mutable fields `mut x`
- [ ] Implement functional update `{ ..point, x: 20 }`

### 4.2 Enums
- [ ] Parse enum definitions
- [ ] Implement simple enum constructors `Red`, `Green`, `Blue`
- [ ] Implement enum constructors with data `RGB(Int, Int, Int)`

### 4.3 Pattern Matching
- [ ] Implement basic match expressions
- [ ] Implement constructor patterns `RGB(r, g, b)`
- [ ] Implement wildcard pattern `_`
- [ ] Implement guard expressions `guard x is pattern`

## Phase 5: Advanced Features (LOW PRIORITY)

### 5.1 Maps
- [ ] Implement Map type with literal `{"key": val}`
- [ ] Implement map access `map["key"]`
- [ ] Implement map update `map["key"] = val`
- [ ] Fix segfault in map operations

### 5.2 Testing
- [ ] Parse `test {}` blocks
- [ ] Either execute or properly ignore test blocks

### 5.3 Derives
- [ ] Implement `derive(Show)` for auto toString

---

## Execution Order Recommendation

1. **Start with Phase 1** - Core runtime issues affect everything
   - Fix println → Fix arithmetic → Fix functions → Fix if/else

2. **Then Phase 2.1-2.2** - Number literals and Arrays are most common
   - Hex/binary literals → Array basics → Array methods

3. **Then Phase 3** - Control flow needed for many examples
   - For loops → While → Break/continue

4. **Then Phase 2.3-2.4** - Strings and Tuples
   - String concat → Interpolation → Tuples

5. **Finally Phases 4-5** - Advanced types
   - Structs → Enums → Pattern matching → Maps → Testing

---

## Progress Tracking

Update this section as tasks are completed:

- [x] 001_hello working (OUTPUT MATCHES official)
- [x] 002_variable working (OUTPUT MATCHES official)
- [x] 003_basic_constants working (OUTPUT MATCHES official)
- [x] 004_basic_function working (OUTPUT MATCHES official)
- [ ] 005_basic_array working (concat returns right array, spread not impl)
- [ ] 006_basic_string working (unicode/interpolation not impl)
- [ ] 007_basic_tuple working (mixed types/float in tuple broken)
- [ ] 008_basic_map working
- [x] 009_basic_control_flows working (OUTPUT MATCHES official)
- [ ] 010_basic_struct working
- [ ] 011_basic_enum working
- [ ] 012_basic_test working
- [ ] 013_pattern_matching working
