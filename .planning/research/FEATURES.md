# Features Research: MoonBit Compiler Bugfix

## Feature Categories

### Table Stakes (Must Have)

These are essential to make the test suite pass and achieve the core value. No v1 release without them.

#### 1. Function Call Correctness (COMP-01)

**What:** Function calls with multiple arguments return correct values. The current bug: `add(2, 40)` returns 80 instead of 42.

**Why table stake:** Without correct function calls, almost no program can work reliably. This is fundamental.

**Expected behavior:**
- Arguments passed in correct registers (rdi, rsi, rdx, rcx, r8, r9) and on stack for overflow
- Return value placed in rax (or appropriate register for size)
- Callee-saved registers (rbx, r12-r15, rbp) preserved
- Caller's stack frame not corrupted

**Complexity:** Moderate – requires careful alignment with System V ABI.

**Dependencies:** None (foundational).

#### 2. Control Flow Execution (COMP-02)

**What:** `if`, `for`, and `while` constructs execute without crashes. Current bug: simple programs segfault immediately upon entering control flow blocks.

**Why table stake:** Control flow is core to any non-trivial program. Without it, only straight-line code works.

**Expected behavior:**
- Conditional branches (je, jne, jl, jg, etc.) encode correct relative offsets
- Loops set up iteration variables correctly and exit when condition fails
- Stack pointer remains 16-byte aligned in function bodies
- Labels resolve to correct addresses

**Complexity:** Moderate – offset math and label handling can be tricky.

**Dependencies:** Requires function calls to be stable (functions often contain control flow).

#### 3. Enum Pattern Matching (COMP-03)

**What:** Matching on simple enum types discriminates variants correctly. Current bug: prints Red repeatedly instead of Red, Green, Blue, RGBA.

**Why table stake:** Enums are used in tests and real code. Wrong variant matching breaks program logic.

**Expected behavior:**
- Each enum variant has a unique discriminant (integer tag)
- Construction stores tag with payload (or tag in separate slot)
- Pattern matching compares tag and extracts payload only for matching variant
- No variant duplication

**Complexity:** Moderate – requires consistent layout and comparison.

**Dependencies:** Control flow (match arms are like conditional branches).

#### 4. General Pattern Matching (COMP-04)

**What:** Pattern matching on structured data (structs, nested patterns) works without crashes or garbage values.

**Why table stake:** Pattern matching is used for destructuring, variant handling, and complex data. Critical for expressiveness.

**Expected behavior:**
- Struct field offsets computed correctly in pattern context
- Variables bound in each branch refer to correct fields
- Multiple branches coexist without stack corruption
- Nested patterns (match inside match) work

**Complexity:** Higher – involves offsets, memory layout, multiple branch code generation.

**Dependencies:** Enums, control flow, function calls.

#### 5. Full Test Pass (COMP-05)

**What:** All 13 example programs produce output identical to the reference compiler (with 012 as expected failure and 007 allowing float precision degradation).

**Why table stake:** This is the acceptance criterion for the project.

**Expected behavior:**
- Example 001-013 (except 012) compile and run
- Output matches reference exactly (except 007)
- No segfaults, no incorrect outputs

**Complexity:** Low – this is a verification gate, not a feature.

**Dependencies:** All other table stakes.

### Differentiators (Not in v1 scope)

These would be valuable but are explicitly deferred:

- **Optimization passes:** Peephole optimizations, dead code elimination, constant folding improvements – would speed up generated code but not required for correctness.
- **Enhanced diagnostics:** Better error messages, source location tracking – helpful for users but not needed for bugfix milestone.
- **Debug info:** DWARF generation for gdb – nice to have but out of scope.

### Anti-Features (Deliberately NOT Building)

- **Runtime library expansion:** Example 012 needs a test framework runtime. Adding this would violate the "codegen bugs only" constraint.
- **New language constructs:** The scope is bug fixes, not feature additions. Adding new syntax or semantics would introduce new test failures.
- **Changing ABI:** Must match reference compiler; deviating would break compatibility.
- **Float precision improvements:** 007's minor degradation is acceptable; spending time on floating-point formatting would distract from core bugs.

---

## Feature Dependencies Graph

```
COMP-01 (Function Calls)
   └─┬─ COMP-02 (Control Flow) ───┐
      │                            │
      └─ COMP-03 (Enums) ─── COMP-04 (Pattern Matching)
                                     │
                                     └─ COMP-05 (Full Test Pass)
```

This suggests the fix order: function calls first, then control flow, then enums, then pattern matching, then full validation.

## Rationale for Scope

The core value is: *the compiler generates correct, executable output for all language features covered by the test suite.* That requires only bug fixes within `codegen.mbt`. Adding a runtime would expand the domain to "runtime support", which is a separate milestone. Therefore runtime-related examples (012) are out of scope.

The existing parser appears correct because the ASTs are being produced; the failures are all in code generation (wrong machine code). Thus, lexer and parser are not in scope for changes.
