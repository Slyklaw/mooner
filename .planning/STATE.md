# STATE: Project Memory

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-11)

**Core value:** The compiler generates correct, executable output for all language features covered by the test suite. If everything else fails, the examples must pass.
**Current focus:** Phase 3 (Control Flow Fixes) in progress. Plans 01-03, 05 complete - jump offset fixes, break/continue validation, correctness testing, and function index wiring done.

## Current Position

- **Phase:** 3 (Control Flow Fixes)
- **Plan:** 05 complete (Label namespace isolation - function index tracking wired)
- **Status:** Ready for remaining plans (006-007) or transition
- **Progress:** [████████░░] 82%

## Performance Metrics

- Commits: 14 (code commits: 6, planning commits: 4, test commits: 4)
- Examples passing: 8 / 13 (008 has pre-existing bug; 009 partially works; 011, 013 remain)
- Critical bugs: 2 (011, 013 remain; 008 pre-existing undefined label)
- Regressions: 0 (target: 0)
- Test files added: 6 (if/else, for loop, for zero, while loop, while zero, nested control)

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

None at this time.

### Todos

- [x] Phase 1: Setup & Investigation complete (debug tracing, harness, minimal repros)
- [x] Phase 2: Function call fixes (004)
- [x] Phase 3 Plan 01: Fix jump offset calculation and label namespace isolation
- [x] Phase 3 Plan 02: Break/continue validation and nested loop verification
- [x] Phase 3 Plan 03: Control flow correctness testing (if/else, for, while, nested)
- [x] Phase 3 Plan 05: Wire function index tracking for label namespace isolation

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

## Handoff Notes

Next action: Check for Phase 3 remaining plans (006-007) or transition. Plan 05 complete. Example 009 still has for-loop output bug and while+break hang - these are separate from label namespace issues.
