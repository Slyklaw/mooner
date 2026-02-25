# Plan: Get Official MoonBit Examples Working

## Status Summary

| Example | Compile | Run | Priority Issues |
|---------|---------|-----|----------------|
| 001_hello | ✅ | ✅ | OUTPUT MATCHES official |
| 002_variable | ✅ | ✅ | OUTPUT MATCHES official |
| 003_basic_constants | ✅ | ✅ | OUTPUT MATCHES official |
| 004_basic_function | ✅ | ✅ | OUTPUT MATCHES official |
| 005_basic_array | ✅ | ✅ | **OUTPUT MATCHES official** |
| 006_basic_string | ✅ | ✅ | **OUTPUT MATCHES official** |
| 007_basic_tuple | ✅ | ❌ | **Segfault** |
| 008_basic_map | ✅ | ❌ | **Segfault** |
| 009_basic_control_flows | ✅ | ✅ | OUTPUT MATCHES official |
| 010_basic_struct | ✅ | ✅ | **OUTPUT MATCHES official** |
| 011_basic_enum | ✅ | ⚠️ | Simple enum variants work; enum constructors with data (RGB, RGBA) have stack corruption issues |
| 012_basic_test | ⚠️ | ❌ | Official compiler fails on this file |
| 013_pattern_matching | ✅ | ❌ | Compiles but segfaults at runtime (parser infinite loop fixed) |

## Recent Fixes

### 2025-02-25: Parser Infinite Loop Fixed
- **Issue**: Example 013 pattern matching caused infinite loop during parsing (timeout)
- **Root cause**: In `parser.mbt`, when the parser encountered RBrace (or similar tokens) at the start of an expression, it returned `(Unit, self)` without advancing the parser position, causing an infinite loop in the main parse loop
- **Fix**: Added check in `Parser::parse()` to detect when the parser position doesn't advance after parsing an expression, and skip the current token to prevent infinite loop
- **Result**: Example 013 now compiles (no timeout), but has a runtime segfault

### 2025-02-25: Simple Enum Pattern Matching Fixed
- **Issue**: Example 011 crashed on simple enum variants (Green, Blue) after printing "Red"
- **Root cause**: In `codegen.mbt`, the match expression code for Ident patterns (simple enums like Red, Green, Blue) incorrectly tried to treat non-zero discriminant values as pointers and dereference them
- **Fix**: Simplified the Ident pattern matching to directly compare the scrutinee value with the expected discriminant (no pointer dereference for simple enums)
- **Result**: Simple enum variants (without data) now work correctly

### 2024-02-24: Array Concatenation and Spread Syntax Fixed
- **Issue**: Array concatenation (`arr1 + arr2`) only returned the right array. Spread syntax (`[..arr]`) caused a partial match error in the type checker and was not implemented in codegen.
- **Fix**: Added `Spread` variant to `type_checker.mbt` to fix type checker errors. Rewrote array concatenation and ArrayLit allocation to support dynamically pushing spread array items onto the heap buffer using precise x86-64 assembly in `codegen.mbt`.
- **Result**: `[..arr]` syntax and `arr1 + arr2` produce correct exact array combinations matching the official compiler. Example 005 now passes.

### 2024-02-24: Unicode Escape Sequences Fixed
- **Issue**: Unicode escape sequences like `\u{1F407}` (rabbit emoji) showed as "?"
- **Root cause**: Lexer was parsing hex but just outputting "?" placeholder
- **Fix**: Added UTF-8 encoding in lexer - converts code point to proper 1-4 byte UTF-8 sequence
- **Result**: Example 006 now OUTPUTS MATCH official compiler

### 2024-02-24: Enum Constructor Implementation
- **Issue**: Enum variants with data (RGB(0, 0, 255)) not properly created
- **Fix**: 
  1. Added enum constructor detection in CallExpr handler
  2. Creates stack-allocated structure: [discriminant][arg0][arg1]...
  3. Returns pointer to structure
  4. Added pattern matching logic to detect direct discriminant (0) vs pointer
- **Result**: Simple enum variants work; variants with data creation works but pattern matching still has edge cases

### 2024-02-23: Float Variable Tracking Verified Working
- **Investigation**: Was investigating "float variable bug" where `let x = 3.14; println(x)` showed "3.0" instead of "3.14"
- **Finding**: Float variable tracking (`var_is_float`) IS working correctly! The issue is the **runtime float-to-string conversion** which only prints integer part + ".0" suffix
- **Test results**:
  - `println(3.14)` → "3.14" (literal, pre-computed at compile time)
  - `let x = 3.14; println(x)` → "3.0" (variable, runtime conversion)
  - `let y = 99.5; println(y)` → "99.0" (variable)
- **Root cause**: The runtime float conversion code explicitly prints "0" then "." (lines 2482-2490 in codegen.mbt) regardless of actual fractional part, then extracts and prints integer digits. Comment says "Just print integer part for now with '.0' suffix"
- **Conclusion**: Float variable storage/loading works. To fully fix, need to implement proper fractional part extraction in runtime float-to-string conversion

### 2024-02-23: Struct Field Assignment and Functional Update
- **Issue**: Struct field mutation (`point.x = 5`) and functional update (`{ ..point, x: 20 }`) not implemented
- **Fix**: Added FieldExpr assignment codegen, StructUpdate parsing and codegen
- **Result**: Mutable struct fields work correctly with aliasing; functional update syntax works

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
- [x] Fix if/else to execute correct branch
- [x] Implement if/else as expressions (return values)

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
- [x] Implement `array.push()` mutation
- [x] Implement array concatenation `arr1 + arr2`
- [x] Implement spread operator `[..arr1, 1000, ..arr2]`

### 2.3 Strings
- [x] Implement String concatenation `str1 + str2`
- [x] Implement `string.get_char(index)`
- [x] Implement escape sequences `\n`, `\t`, `\u{}`
- [x] Implement string interpolation `"\{lang}"`

### 2.4 Tuples
- [x] Implement Tuple type `(a, b, c)`
- [x] Implement tuple element access `tuple.0`

## Phase 3: Control Flow (MEDIUM PRIORITY)

### 3.1 Loops
- [x] Implement C-style for loop `for i=0; i<n; i=i+1`
- [x] Implement for-in loop `for x in arr` ✅
- [x] Implement while loop
- [x] Implement break statement
- [x] Implement continue statement

## Phase 4: Structured Data (MEDIUM-LOW PRIORITY)

### 4.1 Structs
- [x] Parse struct definitions
- [x] Implement struct construction `{ x: 3, y: 4 }`
- [x] Implement struct field access `point.x`
- [x] Implement mutable fields `mut x`
- [x] Implement functional update `{ ..point, x: 20 }`

### 4.2 Enums
- [x] Parse enum definitions
- [x] Implement simple enum constructors `Red`, `Green`, `Blue`
- [x] Implement enum constructors with data `RGB(Int, Int, Int)` (partial)

### 4.3 Pattern Matching
- [x] Implement basic match expressions
- [ ] Implement constructor patterns `RGB(r, g, b)` with data binding
- [x] Implement wildcard pattern `_`
- [ ] Implement guard expressions `guard x is pattern`

## Phase 5: Advanced Features (LOW PRIORITY)

### 5.1 Maps
- [ ] Implement Map type with literal `{"key": val}`
- [ ] Implement map access `map["key"]`
- [ ] Implement map update `map["key"] = val`
- [ ] Fix segfault in map operations

### 5.2 Testing
- [x] Parse `test {}` blocks
- [x] Execute test blocks (assert_eq, assert_true, assert_false, inspect work)

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
- [x] 005_basic_array working (OUTPUT MATCHES official) ✅
- [x] 006_basic_string working (OUTPUT MATCHES official)
- [x] 009_basic_control_flows working (OUTPUT MATCHES official)
- [x] 010_basic_struct working (OUTPUT MATCHES official)
- [ ] 007_basic_tuple working (segfault)
- [ ] 008_basic_map working (segfault)
- [ ] 011_basic_enum working (segfault)
- [ ] 012_basic_test (official compiler fails on file)
- [ ] 013_pattern_matching (timeout)

## Summary

**Working examples: 8/13** (001-006, 009-010)

**Most recent fixes:**
1. Example 005 (array) now outputs identically to official compiler
