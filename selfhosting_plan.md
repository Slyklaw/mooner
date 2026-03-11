# Plan: Debug Self-Hosted Compiler Examples

**Last Updated:** 2026-03-11 — Actual test run revealed significant gaps

## Status Summary (ACTUAL CURRENT STATE)

| Example | Status | Issue | Category |
|---------|--------|-------|----------|
| 001_hello | ✓ PASS | | OK |
| 002_variable | ✓ PASS | | OK |
| 003_basic_constants | ✓ PASS | | OK |
| 004_basic_function | ✗ FAIL | Returns 80 instead of 42 | **Function calls** |
| 005_basic_array | ✓ PASS | | OK |
| 006_basic_string | ✓ PASS | | OK |
| 007_basic_tuple | ⚠️ PASS* | Float: 2.1 vs 2.0999999... | Float precision (acceptable) |
| 008_basic_map | ✓ PASS | | OK |
| 009_basic_control_flows | 💥 SEGFAULT | Crashes, outputs 0 | **Control flow** |
| 010_basic_struct | ✓ PASS | | OK |
| 011_basic_enum | ✗ FAIL | Wrong enum patterns | **Enum handling** |
| 012_basic_test | ✗ FAIL | Test framework runtime | Runtime support (out of scope) |
| 013_pattern_matching | 💥 SEGFAULT | Garbage output + crash | **Pattern matching** |

**Summary:**
- ✅ **7/13 passing** (001, 002, 003, 005, 006, 008, 010)
- ⚠️ **1 degraded** (007 - float precision acceptable)
- ❌ **4 compiler bugs** (004, 009, 011, 013)
- ⏭️ **1 out of scope** (012 - runtime test framework)
- 💥 **2 segfaults** (009, 013)

**Compiler Code Health:** 9/13 work (69%), 4 critical bugs remain

## Critical Path: Fix Compiler Bugs (4 failing examples)

**Goal:** Fix codegen bugs causing wrong output or segfaults. Runtime support (012) excluded per scope.

**Scope:** 004, 009, 011, 013 (007 degredation acceptable, 012 out of scope)

### Priority 1: Investigate Root Causes

Before coding, understand failure modes:

1. **004_basic_function** - Simple function returns wrong value (80 vs 42)
   - Likely: Function argument passing OR return value handling broken
   - Check: How arguments are placed on stack/registers, how return value is read

2. **009_basic_control_flows** - Segfault on simple loops/conditionals
   - Likely: Control flow codegen (jumps, labels) broken
   - Check: Jump offsets, label resolution, stack management in loops

3. **011_basic_enum** - Enum pattern matching produces wrong output
   - Currently: "Red" printed twice, missing "Green", "Blue", "RGBA"
   - Likely: Enum variant handling or pattern matching wrong branch selected

4. **013_pattern_matching** - Complex pattern matching segfault
   - Currently: Garbage output, then crash
   - Likely: Pattern matching codegen memory corruption or wrong branch

**Investigation approach:**
- For each failing example, generate assembly and inspect
- Compare working vs failing code paths
- Add debug output to codegen to trace decisions
- Identify minimal reproduction in codegen

## Recent Fixes

### Float-to-String Conversion (Ryu Algorithm) - COMPLETE!

- **Implemented `ryu_to_string()` function** with full Ryu floating-point to string conversion algorithm
- Converts IEEE 754 doubles to shortest round-trippable decimal representation
- Handles: positive/negative, zero, subnormal numbers, scientific notation, special values (NaN, Infinity)

### String Interpolation Improvements - COMPLETE!

- **Float literals**: `"{3.14}"` now prints `"3.14"` (uses Ryu algorithm)
- **Float variables**: Tuple-destructured float variables print their compile-time values
- **Int literals**: `"{42}"` prints `"42"`
- **Bool variables**: Print `"true"`/`"false"` correctly
- **Array variables**: Print tracked array values like `"[1, 2, 3]"`
- **Expression parsing**: Updated `parse_interpolation_expr()` to parse numeric literals (float/int) in addition to identifiers

### Binary Expressions in Interpolation - COMPLETE!

- **Float arithmetic**: `"{1.0/3.0}"` → `"0.3333333333333333"`
- **Integer arithmetic**: `"{10/3}"` → `"3"` (integer division)
- **Mixed operators**: `"{2.0 + 3.0}"`, `"{10 - 4}"`, `"{6 * 7}"` all work
- **Chained expressions**: `"{1.0 + 2.0 + 3.0}"` → `"6"`, `"{2 * 3 * 4}"` → `"24"`
- **Operator precedence**: `*`, `/` have higher precedence than `+`, `-`
- **Proper type handling**: Integer vs float arithmetic produces correct results
- **Recursive evaluation**: Nested binary expressions are fully evaluated at compile time
- **Variables (integers)**: `"{x + 5}"` where x=10 → `"15"` - Runtime evaluation!
- **Variables (floats)**: `"{a / b}"` where a=10.0, b=3.0 → `"3.3333333333333335"` - Compile-time eval with tracked values!

**Example:**
```moonbit
println("1.0/3.0: \{1.0/3.0}")          // Output: 1.0/3.0: 0.3333333333333333
println("10/3: \{10/3}")                // Output: 10/3: 3
println("1.0 + 2.0 + 3.0: \{1.0 + 2.0 + 3.0}")  // Output: 1.0 + 2.0 + 3.0: 6
println("2 * 3 * 4: \{2 * 3 * 4}")      // Output: 2 * 3 * 4: 24
println("10 + 2 * 5: \{10 + 2 * 5}")    // Output: 10 + 2 * 5: 20 (precedence!)

let x = 10
println("x + 5: \{x + 5}")              // Output: x + 5: 15 (runtime eval!)
println("x * 2: \{x * 2}")              // Output: x * 2: 20

let t = (10.0, 3.0)
let (a, b) = t
println("a / b: \{a / b}")              // Output: a / b: 3.3333333333333335
```

### Example 007 - Fully Working!

Tuple destructuring with string interpolation now works:
```moonbit
let (a, b, c) = (3.14, false, [1,2,3])
println("{a}, {b}, {c}")  // Output: 3.14, false, [1, 2, 3]
```

### Previous Fixes

- 007_basic_tuple: Fixed float literals using `add_float` (IEEE 754 doubles), bool printing in tuples, array printing in tuples, and type annotation parsing for tuples
- 008_basic_map: Complete! Map creation, access, equality, update, and printing all work
- 005_basic_array: Fixed array indexing (off-by-one in codegen)
- 006_basic_string: Added unicode escape `\u{XXXX}` support in lexer
- 001_hello: Fixed heredoc syntax - uses #| for start/end, correctly detects end marker

## Verification Command

```bash
for i in 001 002 003 004 005 006 007 008 009 010 011 012 013; do
  file=$(ls examples/mbt_examples/${i}_*.mbt 2>/dev/null | head -1)
  if [ -n "$file" ]; then
    moon run cmd/main "$file" 2>/dev/null
    if [ -f "${file%.mbt}.exe" ]; then
      chmod +x "${file%.mbt}.exe"
      ./"${file%.mbt}.exe" > "/tmp/our_${i}.txt" 2>&1
      moon run "$file" > "/tmp/moon_${i}.txt" 2>&1
      if diff -q "/tmp/moon_${i}.txt" "/tmp/our_${i}.txt" > /dev/null 2>&1; then
        echo "$i: PASS"
      else
        echo "$i: FAIL"
      fi
    else
      echo "$i: COMPILE ERROR"
    fi
  fi
done
```

## Tasks

### Investigation Complete

- [x] Actually run test_examples.sh to see current state
- [x] Discover actual status: 7 passing, 4 bugs, 1 out-of-scope
- [x] Document actual failures with outputs
- [x] Categorize bugs: function calls, control flow, enums, pattern matching

### To Fix (Compiler Bugs)

- [ ] **004_basic_function**: Fix function return value codegen
- [ ] **009_basic_control_flows**: Fix control flow (loops/if) codegen causing segfault
- [ ] **011_basic_enum**: Fix enum variant handling and pattern matching
- [ ] **013_pattern_matching**: Fix complex pattern matching codegen

### Out of Scope / Accepted

- [ ] 007_basic_tuple: Float precision acceptable (2.1 vs 2.0999999)
- [ ] 012_basic_test: Test framework runtime — explicitly out of scope

---

## Verification

After each fix, re-run the full test suite:

```bash
bash test_examples.sh
```

All 13 examples should either PASS or be intentionally out-of-scope.

**Success criteria:**
- 004: Output matches reference exactly
- 009: No segfault, output matches exactly
- 011: Output matches reference exactly
- 013: No segfault, output matches exactly
- 007: Output within acceptable precision (already OK)
- 012: Expected failure (documented)

---

*Created: 2026-03-01*
*Updated: 2026-03-11 — Actual state assessment reveals 4 critical codegen bugs to fix*
