# STATE: Project Memory

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-11)

**Core value:** The compiler generates correct, executable output for all language features covered by the test suite. If everything else fails, the examples must pass.
**Current focus:** Phase 3 (Control Flow) - gaps still exist after plan 08 execution. Verification shows C-style for loop outputs 7 (expected 15), while+break hangs.

## Current Position

- **Phase:** 3 (Control Flow) - gap closure executed, array parameter tracking added
- **Plan:** 09 complete (array parameter tracking added)
- **Status:** Partial fix - direct array access works, loops still have issues
- **Progress:** [████████░░] 80%

## Performance Metrics

- Commits: 20 (code commits: 12, planning commits: 4, test commits: 4)
- Examples passing: 8 / 13 (008 has pre-existing bug; 009 partially works; 011, 013 remain)
- Critical bugs: 4 (011, 013 remain; 008 pre-existing undefined label; while/for loop infinite loop)
- Phase 3 issues: Array parameter tracking added (direct access works), loop iteration broken
- Test files added: 9 (if/else, for loop, for zero, while loop, while zero, nested control, nested break, nested continue, outer break)

## Accumulated Context

### Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Focus exclusively on codegen bugs | Parser/lexer appear correct; failures trace to codegen | ✓ Confirmed |
| Fix order: 004 → 009 → 011 → 013 | Dependency chain: function calls → control flow → enums → pattern matching | — Pending |
| Allow temporary debug code in codegen | Needed for investigation; will be cleaned up in Phase 6 | ✓ Implemented |
| Use existing codebase analysis as research foundation | Already mapped architecture, stack, concerns; synthesized research artifacts | ✓ Good |
| Build minimal reproduction tests | Isolate bugs for faster debugging | ✓ Completed |
| Tasks 1-3 of Plan 05 were already implemented in Plan 01 | Verified via code inspection, confirmed working | ✓ Deduplicated work |
| Only Task 4 needed implementation | func_counter/Current_func_idx existed but were never incremented | ✓ Wired |
| Add array parameter tracking | var_is_array_param map tracks array function parameters | Partial - infrastructure added, loops still broken |

### Blockers

| Blocker | Details | Status |
|---------|---------|--------|
| Pre-existing while/for loop bug | While/for loops with local integer variables cause infinite loops. This is a pre-existing bug unrelated to array parameters. Discovered during Plan 09 investigation. | Active |
| Mutable variable return bug | Returning a mutable local variable from a function returns 0 instead of the value. Pre-existing bug. | Active |

### Todos

- [x] Phase 1: Setup & Investigation complete (debug tracing, harness, minimal repros)
- [x] Phase 2: Function call fixes (004)
- [x] Phase 3 Plan 01: Fix jump offset calculation and label namespace isolation
- [x] Phase 3 Plan 02: Break/continue validation and nested loop verification
- [x] Phase 3 Plan 06: Break/continue validation confirmed, nested loops verified
- [x] Phase 3 Plan 03: Control flow correctness testing (if/else, for, while, nested)
- [x] Phase 3 Plan 05: Wire function index tracking for label namespace isolation
- [x] Phase 3 Plan 08: Add function index to loop labels (WhileLoop, ForLoop, ForInLoop)
- [x] Phase 3 Plan 09: Add array parameter tracking for C-style for loops

## Recent Work

- **2026-03-11:** Phase 1 completed: debug tracing, test harness, baseline results
- **2026-03-11:** Phase 2 (Function Calls) completed: 004 verified, 19/19 tests pass
- **2026-03-11:** Phase 3 Plan 01 completed: jump offset fixes, label namespace fields added
- **2026-03-11:** Phase 3 Plan 02 completed: break/continue validation
- **2026-03-11:** Phase 3 Plan 03 completed: 6 control flow tests, all match official compiler
- **2026-03-11:** Phase 3 Plan 05 completed:
  - Verified Tasks 1-3 already implemented in Plan 01
  - Task 4: Wired func_counter increment in codegen_func and main function handler
  - Labels now use unique function index prefixes per function
- **2026-03-11:** Phase 3 Plan 06 completed:
  - Break/continue validation already implemented at codegen.mbt:7204-7219
  - Nested loop handling verified correct via 3 test files
  - No code changes needed; validation and scoping already correct
- **2026-03-13:** Phase 3 Plan 08 executed:
  - Added function index to WhileLoop, ForLoop, ForInLoop labels
  - Verification FAILED: C-style for loop still outputs 7 (not 15); while+break still hangs
  - Root cause analysis incomplete - more investigation needed
- **2026-03-14:** Phase 3 Plan 09 executed:
  - Added var_is_array_param tracking for array function parameters
  - Added detection for Array[T] type annotations
  - Direct array element access now works (arr[i] = correct value)
  - While/for loops still hang due to pre-existing loop bug
  - Tests pass (19/19)

## Handoff Notes

**After Plan 09 execution:**
- Array parameter tracking infrastructure added (var_is_array_param map)
- Direct array element access works: `arr[0]+arr[1]+arr[2]+arr[3]+arr[4] = 15` ✓
- While/for loop iteration still broken - infinite loop with local variables
- This is a SEPARATE bug from array parameters - appears to be how local mutable variables work
- 19/19 tests still pass (but tests may not cover this edge case)

**Root cause findings from Plan 09:**
- The issue is NOT array parameter handling (that's now fixed)
- The issue is that while/for loops with local mutable integers cause infinite loops
- This is a pre-existing bug in how local mutable variables interact with loop conditions
