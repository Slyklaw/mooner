# Phase 2 Research: Tuple & Float Improvements

**Phase:** 2 - Tuple & Float Improvements
**Goal:** Float values in tuples print correctly, and float runtime conversion outputs full decimal representation.
**Requirements:** TUP-01, TUP-02, TUP-03, FLT-01, FLT-02
**Date:** 2026-03-10

---

## 1. Technical Background

### 1.1 MoonBit Compiler Architecture

This is a MoonBit compiler that generates x86_64 Linux executables. The code generator (`codegen.mbt`) translates AST nodes to x86_64 assembly instructions.

Key data structures in `CodeGen` for float handling:

```moonbit
pub struct CodeGen {
  var_is_float : Map[String, Bool]                    // Line 8 - per-variable float flag
  var_tuple_field_types : Map[String, Array[Bool]]    // Line 15 - tuple element types
  var_tuple_field_float_values : Map[String, Array[Double]]  // Line 18 - compile-time known floats
  var_float_values : Map[String, Double]              // Line 44 - individual float var values
}
```

### 1.2 Float Printing Mechanism

Float-to-string conversion happens via the Ryu algorithm:

- **Compile-time:** `ryu_to_string(f : Double) -> String` for known constants
- **Runtime:** Code generation that computes float values then converts (see lines 2966-3210)

The `println` function ultimately needs a string. For float variables/expressions, the compiler:
1. Looks up value in `var_float_values` if known at compile time
2. Otherwise emits runtime computation code

### 1.3 GuardExpr: Tuple Destructuring

The `GuardExpr` AST node (lines 7551-7719) handles guard expressions like:

```moonbit
guard tuple1 is (a, b, c)
```

It extracts tuple fields and binds them to pattern variables. The code path:
- Determine source tuple field types (Float or Int) via `is_float_expr`
- For each field: load from stack (3 scenarios: parameter, variable, literal)
- Push onto stack for the guard body
- Register variable in tracking maps (`var_offsets`, `var_is_float`, `var_is_bool`)

---

## 2. Problem Analysis

### 2.1 Primary Bug: Missing Float Value Propagation

**Location:** `codegen.mbt`, lines 7699-7710

When GuardExpr extracts a float field, it correctly:
- Sets `var_is_float[name] = is_float`
- Sets `var_offsets[name]` for stack location

But it **does NOT**:
- Store the actual float value in `var_float_values[name]`
- Copy `var_tuple_field_float_values` entries to the extracted variables

**Consequence:**

```moonbit
let t = (1.5, 2.5)  // var_tuple_field_float_values[t] = [1.5, 2.5]
guard t is (a, b)
println("a=\{}")  // Attempts to print 'a'
```

The println code path checks `var_float_values.get("a")` → returns `None` because GuardExpr never stored it. Fallback: prints `<float>` placeholder.

### 2.2 Float Runtime Conversion Gaps

**Location:** `codegen.mbt`, lines 3144-3167 (Binary operation float printing)

When `eval_to_float(Binary(op, left, right))` returns `None` (partial variables), code currently emits:

```moonbit
None => {
  let (g2, label) = g.add_string("<expr>")
  // ... emits placeholder
}
```

This is a placeholder for unimplemented runtime float computation + conversion. Should emit actual code that:
1. Evaluates left and right float expressions at runtime
2. Performs the arithmetic operation
3. Converts result to string using the Ryu runtime routine

### 2.3 Test Coverage Gaps

Existing test `examples/mbt_examples/test_guard_float.mbt` checks destructuring but doesn't verify that extracted floats print actual values (it uses string concatenation with `\{var}` which might go through different code path).

No tests for:
- Float variable in tuple (`let x=1.5; let t=(x,2.5); guard t is (a,b); println(a)`)
- Float expressions in println (`println(1.5 + 2.5)`)
- Edge values (0.0, negative, large, small)

---

## 3. Solution Approaches

### 3.1 Fix GuardExpr Float Propagation

**Approach:** After extracting each float field and before updating `var_float_values`:

1. If source tuple has `var_tuple_field_float_values` (tuple literal case):
   - Copy the corresponding float value to new variable's entry in `var_float_values`
2. If source is a tuple variable with tracked values:
   - Look up that variable's `var_tuple_field_float_values` and copy

**Code insertion point:** After line 7710 in GuardExpr, inside the `name_idx` loop, after updating `var_is_float`.

**Why this works:** The extracted variable will then have its float value in `var_float_values`, making it available to downstream println code that checks that map.

### 3.2 Complete Float Runtime Codegen

**Approach:** Replace `<expr>` placeholder with code that:
- Ensures both operands are evaluated as floats (load to xmm registers)
- Emits SSE2 arithmetic instruction (addsd, subsd, mulsd, divsd)
- Calls runtime float-to-string conversion routine (to be implemented or linked)

**Status:** This is more complex. May require implementing a runtime float-to-string function that uses Ryu algorithm at runtime. Could be deferred to separate task if compile-time propagation fixes the immediate printing issues for tuple floats.

### 3.3 Segment Phase Solution

Given 5 requirements (TUP-01, TUP-02, TUP-03, FLT-01, FLT-02), split:

**Plan 1:** Fix GuardExpr float propagation (addresses TUP-01, TUP-02, TUP-03)
- Directly fixes tuple float printing
- Moderate complexity (20-30 lines of codegen changes)
- Can be tested immediately with test_guard_float.mbt

**Plan 2:** Enhance float printing infrastructure (addresses FLT-01, FLT-02)
- Review all ryu_to_string usage sites
- Add runtime pathway for float expressions with variables
- Comprehensive test suite for float printing
- Higher complexity, may span multiple files

---

## 4. Recommended Approach

### Phase Structure: 2 Plans, Wave 1 (parallel but independent)

#### Plan 02-01: GuardExpr Float Value Propagation

**Focus:** Single targeted fix in codegen.mbt GuardExpr case.

**Changes:**
1. After each field extraction, if `is_float`:
   - Extract value from `src_tuple_field_float_values` if available
   - Or from source tuple variable's stored values
   - Store in `g2.var_float_values[name]`
2. Update test_guard_float.mbt to use direct concatenation (forces float-to-string lookup)

**Verification:**
- `moon test` shows tuple floats printing as numbers, not `<float>`
- Manual: `println("a=" + a)` outputs "a=1.5"

#### Plan 02-02: Float Printing Comprehensive Validation

**Focus:** Audit and fix all float-to-string codegen paths.

**Changes:**
1. Audit 18 `ryu_to_string` call sites (grep result) for correctness
2. Ensure `var_float_values` is checked for ALL float variables, not just tuple fields
3. Fill in runtime code path for float expressions (if needed)
4. Add test_float_runtime.mbt with comprehensive scenarios:
   - Literals: `println(3.14)`
   - Variables: `let x=2.718; println(x)`
   - Expressions: `println(1.5+2.5)`, `println(1+2.5)`
   - Edge: 0.0, negative, nested
   - GuardExpr-extracted floats (reuse)

**Verification:**
- All test cases print full decimal representation
- Compare output with official MoonBit compiler (if accessible)

---

## 5. Implementation Checklist

### Plan 02-01 Tasks

**Task 1: codegen.mbt GuardExpr modification**
- [ ] Locate GuardExpr case (lines 7551-7719)
- [ ] Find the `name_idx` loop (lines 7620-7712)
- [ ] After updating `var_is_float` and `var_is_bool` (lines 7701-7710), add:
  ```moonbit
  if is_float {
    // Try to extract the value from source tuple's stored float values
    match src_tuple_field_float_values {
      Some(values) => {
        if name_idx < values.length() {
          let mut new_float_vals = g2.var_float_values
          new_float_vals[name] = values[name_idx]
          g2 = { ..g2, var_float_values: new_float_vals }
        }
      }
      None => {
        // Check if source is a tuple variable with stored values
        match expr {
          Ident(src_name) => {
            match g.var_tuple_field_float_values.get(src_name) {
              Some(src_values) => {
                if name_idx < src_values.length() {
                  let mut new_float_vals = g2.var_float_values
                  new_float_vals[name] = src_values[name_idx]
                  g2 = { ..g2, var_float_values: new_float_vals }
                }
              }
              None => ()
            }
          }
          _ => ()
        }
      }
    }
  }
  ```
- [ ] Ensure the code inserted before `name_idx = name_idx + 1`
- [ ] Verify proper map mutation pattern (MoonBit maps are immutable, so create new map and update struct)

**Task 2: test_guard_float.mbt enhancement**
- [ ] Change string interpolation to explicit concatenation to force float-to-string conversion:
  ```moonbit
  println("tuple1: a=" + a + ", b=" + b + ", c=" + c)
  ```
- [ ] Add test case with float variables inside tuple:
  ```moonbit
    let x = 1.5
    let y = 2.5
    let tuple2 = (x, y)
    guard tuple2 is (p, q)
    println("tuple2: p=" + p + ", q=" + q)
  ```
- [ ] Ensure tests would fail if float values are not propagated (placeholders would be visible)

### Plan 02-02 Tasks

**Task 1: Code audit**
- [ ] `grep -n "ryu_to_string" codegen.mbt` → document all 18 locations
- [ ] For each, identify whether it's compile-time constant path or placeholder
- [ ] Check `var_float_values` usage: search for `var_float_values.get` to see lookup sites
- [ ] Verify that all float variable printing paths consult `var_float_values`
- [ ] Identify missing runtime pathway

**Task 2: Runtime code generation (if needed)**
- [ ] Determine if float expression codegen exists (likely in Binary case)
- [ ] If placeholder `<expr>` is still present, replace with:
  - Emit code to evaluate operands to xmm registers
  - Emit SSE arithmetic
  - Call runtime float-to-string (may need to implement)

**Task 3: Test suite**
- [ ] Create `examples/mbt_examples/test_float_runtime.mbt` with:
  - Simple literals (positive, negative, zero)
  - Float variables
  - Arithmetic expressions (int+float, float+float, mixed operations)
  - Nested expressions
  - GuardExpr-extracted floats
- [ ] Add expected output comments or assertions

---

## 6. Test Strategy

### 6.1 Unit Tests (examples/*.mbt)

**test_guard_float.mbt (updated):**
- Should print actual numbers for extracted float fields
- Failure mode: prints `<float>` or crashes

**test_float_runtime.mbt (new):**
- Each case prints to stdout
- Compare with expected decimal strings
- Use official compiler reference if available

### 6.2 Verification Commands

```bash
# Build
moon build

# Run tests
moon test

# Specific test
moon run examples/mbt_examples/test_guard_float.mbt

# Compare with official (if available)
moon run examples/mbt_examples/test_guard_float.mbt > /tmp/our_output.txt
# (compare with official compiler output)
diff expected.txt /tmp/our_output.txt
```

---

## 7. Risks and Edge Cases

### 7.1 Float Value Inheritance for Nested Tuples

GuardExpr for nested tuples (`guard ((1.1, 2.2), 3) is ((a,b),c)`) may need to recursively copy `var_tuple_field_float_values` for inner tuples. Current fix handles single-level only.

**Mitigation:** Test nested case; if fails, extend to copy nested tuple values.

### 7.2 Stack Layout and Offsets

The float extraction uses 8-byte slots and XMM registers. Must ensure:
- Alignment preserved
- No interference with integer values on same stack frame
- PushXmm/Pop balance correct

**Mitigation:** Existing code has worked for other float loading; follow same pattern.

### 7.3 Placeholder `<expr>` Still Present

If runtime float codegen is incomplete, some expressions may still emit `<expr>` strings.

**Mitigation:** Plan 02-02 can address remaining cases iteratively. Initial fix focuses on tuple float propagation which should cover most immediate failures.

### 7.4 Regressions

Changing GuardExpr could affect:
- Pattern matching for non-float tuples
- Guard conditions themselves (not just variable binding)
- Nested guards

**Mitigation:** Run all existing tests; check that enum pattern matching (Phase 3) still works after changes.

---

## 8. Dependencies and Constraints

- **Phase 1 (Map Support):** Complete, no direct impact on Phase 2
- **Files modified:** `codegen.mbt` (primary), test files in `examples/mbt_examples/`
- **No new dependencies:** Uses existing Ryu algorithm and x86_64 SSE2 instructions
- **Backward compatibility:** Changes only to codegen should not affect parser or type checker

---

## 9. Success Criteria Alignment

| Requirement | Plan | How satisfied |
|-------------|------|---------------|
| TUP-01 | 02-01 | Float tuple fields print correctly after guard extraction |
| TUP-02 | 02-01 | Mixed int-float tuples work with println |
| TUP-03 | 02-01 | Float tuple field access returns correct value (via printing) |
| FLT-01 | 02-02 | Float runtime conversion outputs full decimal |
| FLT-02 | 02-02 | Any float expression prints correctly |

All 5 requirements addressed.

---

## 10. Recommended Next Steps

1. **Execute Plan 02-01** (GuardExpr fix)
   - Implement code change
   - Update test
   - Verify tuple float printing works

2. **Execute Plan 02-02** (Float printing audit)
   - Review all float-to-string paths
   - Fill gaps in runtime codegen
   - Add comprehensive tests

3. **Validate against official compiler** (if possible)

4. **Proceed to Phase 3** (Enum Pattern Matching) once all success criteria met

---

**Research completed by:** GSD workflow (analysis based on codebase inspection)
**Confidence:** High (direct code analysis, clear bug identified)