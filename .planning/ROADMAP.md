# Roadmap: MoonBit Compiler Bugfix

## Phases

- [x] **Phase 1: Setup & Investigation** - Instrument codegen, establish debug tracing, create minimal test cases (completed 2026-03-11)
- [x] **Phase 2: Function Calls** - Fix calling convention and return value handling (COMP-01)
- [x] **Phase 3: Control Flow** - Fix jump offsets and label resolution (COMP-02) (completed 2026-03-11)
- [ ] **Phase 4: Enums** - Fix enum discriminants and pattern matching (COMP-03)
- [ ] **Phase 5: Pattern Matching** - Fix struct patterns and branch layout (COMP-04)
- [ ] **Phase 6: Validation & Polish** - Ensure all examples pass, remove debug code (COMP-05)

## Phase Details

### Phase 1: Setup & Investigation
**Goal**: Prepare codebase for debugging and establish baseline measurements
**Depends on**: Nothing (first phase)
**Requirements**: (Preparatory – no direct requirement)
**Success Criteria** (what must be TRUE):
  1. Debug tracing can be enabled/disabled via flag (e.g., `--debug-codegen`)
  2. Minimal reproduction cases created for each failing example (004, 009, 011, 013) in a test harness
  3. Baseline test results recorded (current outputs, segfaults) in a results document
  4. Codegen instrumentation (prints of emitted instructions or AST nodes) ready for selective use

### Phase 2: Function Calls
**Goal**: Function calls with arguments return correct values; calling convention fully System V ABI compliant
**Depends on**: Phase 1
**Requirements**: COMP-01
**Success Criteria** (what must be TRUE):
  1. Example 004 (`add(2, 40)`) returns 42 (no more 80)
  2. Functions with 1-6 arguments (register args) produce correct results
  3. Functions with >6 arguments (stack args) work correctly
  4. Callee-saved registers (rbx, rbp, r12-r15) are preserved across calls
  5. No stack corruption observed in test suite; all passing examples still pass

### Phase 3: Control Flow
**Goal**: Control flow constructs (if, for, while) execute without crashes and produce correct branching behavior
**Depends on**: Phase 2
**Requirements**: COMP-02
**Success Criteria** (what must be TRUE):
  1. Example 009 runs to completion without segfault
  2. Conditional branches (if/else) produce expected outputs for both branches
  3. For loops iterate the correct number of times and exit cleanly
  4. While loops handle zero-iteration case and exit when condition becomes false
  5. Nested control flow (loops inside conditionals, etc.) works correctly
  6. No regressions in examples 001-008,010

## Plans Summary

**Plans:** 9 plans

Plans:
- [x] 03-01-PLAN.md — Fix jump offset calculation and label namespace
- [x] 03-02-PLAN.md — Break/continue validation and nested loop verification
- [x] 03-03-PLAN.md — Control flow correctness testing
- [x] 03-05-PLAN.md — Wire function index tracking for label namespace isolation
- [x] 03-06-PLAN.md — Add break/continue outside-loop validation and verify nested loops
- [x] 03-07-PLAN.md — Control flow comprehensive testing
- [x] 03-08-PLAN.md — Loop label namespacing for WhileLoop, ForLoop, ForInLoop
- [ ] 03-09-PLAN.md — Debug and fix array parameter access in C-style for loops (gap closure)

### Phase 4: Enums
**Goal**: Enum pattern matching discriminates variants correctly; each variant has unique discriminant
**Depends on**: Phase 3
**Requirements**: COMP-03
**Success Criteria** (what must be TRUE):
  1. Example 011 outputs: "Red", "Green", "Blue", "RGBA" in that order (no duplicates)
  2. Each enum variant gets a distinct tag (0,1,2,3) in generated code
  3. Pattern match on enums dispatches to the correct arm based on tag
  4. Enums with associated data (payloads) store and retrieve payloads correctly
  5. Exhaustive matches cover all variants; nonexhaustive matches produce compile error (if applicable)

### Phase 5: Pattern Matching
**Goal**: Pattern matching on structured data (structs, nested patterns) works without crashes or garbage values
**Depends on**: Phase 4
**Requirements**: COMP-04
**Success Criteria** (what must be TRUE):
  1. Example 013 runs to completion with correct output (field values match expected)
  2. Struct fields are bound to correct values in each match arm
  3. Multiple match arms coexist without corrupting each other's bindings
  4. Nested patterns (match inside match, patterns within patterns) execute correctly
  5. Guard conditions (if any) evaluate properly without side effects

### Phase 6: Validation & Polish
**Goal**: All 13 examples pass verification against reference; codebase clean and documented
**Depends on**: Phase 5
**Requirements**: COMP-05
**Success Criteria** (what must be TRUE):
  1. All examples 001-013 (except 012 as expected failure) produce output identical to reference compiler (007 within tolerance)
  2. No segfaults, no incorrect outputs, no hangs
  3. Temporary debug instrumentation removed or behind a compile-time/run-time flag
  4. Full test suite (`test_examples.sh`) passes consistently on every run
  5. Git commit history has clear, atomic commits for each bug fix

## Plans Summary

Each phase will have 2-4 executable plans (detailed during planning phase).

---

*Roadmap created: 2026-03-11*
*Last updated: 2026-03-13 - Phase 3 gap closure plan 09 added*
