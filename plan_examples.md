# Plan: Get Official MoonBit Examples Working

## Status Summary

| Example | Compile | Run | Priority Issues |
|---------|---------|-----|-----------------|
| 001_hello | ✅ | ✅ | **FIXED** - Multiline strings now work |
| 002_variable | ✅ | ✅ | **FIXED** - `let mut` parsing and boolean output work; OUTPUT MATCHES official |
| 003_basic_constants | ✅ | ✅ | **FIXED** - Hex/binary/underscore literals work; OUTPUT MATCHES official |
| 004_basic_function | ✅ | ✅ | **FIXED** - Multiple top-level functions and function calls work; OUTPUT MATCHES official |
| 005_basic_array | ✅ | ⚠️ | `arr.length()`, `arr[i]`, `arr.push()` work; concat returns left array (no crash); spread not impl; print shows `<array>` placeholder |
| 006_basic_string | ✅ | ⚠️ | get_char(), unwrap(), char equality, concat with +, escape sequences, char printing as char work; unicode shows '?'; interpolation literal |
| 007_basic_tuple | ✅ | ⚠️ | Tuples parse; field access works for arrays but not for values (mixed types issue) |
| 008_basic_map | ✅ | ❌ | **Segfault** - maps unsupported |
| 009_basic_control_flows | ✅ | ✅ | All loops work: fib/while/C-for/for-in ✅; OUTPUT MATCHES official |
| 010_basic_struct | ✅ | ⚠️ | Struct parsing works; field access works; Show derive not implemented |
| 011_basic_enum | ✅ | ❌ | Enums parse but constructors not implemented; match expression broken |
| 012_basic_test | ✅ | ❌ | Test blocks parse but not executed |
| 013_pattern_matching | ✅ | ❌ | Pattern matching broken (match expression has control flow bugs) |

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
- [x] Implement array element assignment `arr[i] = value`
- [x] Array layout: `[length][elem0][elem1]...` (length at offset 0, elements at offset 8)
- [ ] Implement `array.push()` mutation
- [ ] Implement array concatenation `arr1 + arr2`
- [ ] Implement spread operator `[..arr1, 1000, ..arr2]`
- [ ] Implement array printing in `println` (loop-based printing has register issues)

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

- [x] 001_hello working
- [x] 002_variable working
- [x] 003_basic_constants working
- [x] 004_basic_function working
- [ ] 005_basic_array working
- [ ] 006_basic_string working
- [ ] 007_basic_tuple working
- [ ] 008_basic_map working
- [x] 009_basic_control_flows working
- [ ] 010_basic_struct working
- [ ] 011_basic_enum working
- [ ] 012_basic_test working
- [ ] 013_pattern_matching working
