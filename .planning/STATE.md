# STATE: Project Memory

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-11)

**Core value:** The compiler generates correct, executable output for all language features covered by the test suite. If everything else fails, the examples must pass.
**Current focus:** Phase 3 (Control Flow) - gaps still exist after plan 08 execution. Verification shows C-style for loop outputs 7 (expected 15), while+break hangs.

## Current Position

- **Phase:** 3 (Control Flow) - gap closure executed but bugs persist
- **Plan:** 08 complete (loop label namespacing applied)
- **Status:** Verification failed - bugs remain
- **Progress:** [████████░░] 80%

## Performance Metrics

- Commits: 17 (code commits: 9, planning commits: 4, test commits: 4)
- Examples passing: 8 / 13 (008 has pre-existing bug; 009 partially works; 011, 013 remain)
- Critical bugs: 2 (011, 013 remain; 008 pre-existing undefined label)
- Phase 3 remaining bugs: 2 (C-style for loop outputs 7 not 15; while+break hangs)
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

### Blockers

| Blocker | Details | Status |
|---------|---------|--------|
| Phase 3 bugs persist | C-style for loop outputs 7 instead of 15; while+break hangs. Root cause not fully understood - label namespacing fix was insufficient. | Active |

### Todos

- [x] Phase 1: Setup & Investigation complete (debug tracing, harness, minimal repros)
- [x] Phase 2: Function call fixes (004)
- [x] Phase 3 Plan 01: Fix jump offset calculation and label namespace isolation
- [x] Phase 3 Plan 02: Break/continue validation and nested loop verification
- [x] Phase 3 Plan 06: Break/continue validation confirmed, nested loops verified
- [x] Phase 3 Plan 03: Control flow correctness testing (if/else, for, while, nested)
- [x] Phase 3 Plan 05: Wire function index tracking for label namespace isolation
- [x] Phase 3 Plan 08: Add function index to loop labels (WhileLoop, ForLoop, ForInLoop)

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

## Handoff Notes

Phase 3 gap closure (plan 08) was executed but verification shows bugs persist:
- C-style for loop with array param: outputs 7 instead of 15
- While+break: hangs infinitely
- for-in loop works correctly (outputs 15)

The root cause is NOT just label namespacing - needs deeper investigation. Recommend creating new gap closure plan to debug actual root cause.
