---
phase: 02-function-calls
plan: 01
subsystem: compiler
tags: [x86_64, stack, function-calls, codegen]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: debug infrastructure and minimal reproduction tests
provides:
  - Corrected parameter offset calculation in function prologue
  - Fixed example 004 (basic function call) returns correct result (42)
affects:
  - 02-function-calls-02 (stack cleanup fix will build on this correction)

# Tech tracking
tech-stack:
  added: []
  patterns: [stack-offset-calibration, callee-parameter-access]

key-files:
  created: []
  modified:
    - codegen.mbt - Fixed offset formula in codegen_func for parameter stack locations

key-decisions:
  - "Followed plan exactly: changed offset formula from -(j+1)*8 to -j*8"

patterns-established:
  - "Parameter offsets: first parameter at rbp-48 (when saved_regs_size=48)"

requirements-completed: ["COMP-01"]

# Metrics
duration: 1 min
completed: 2025-03-11
---

# Phase 2: Function Call Fixes - Plan 1 Summary

**Fixed parameter offset calculation in callee prologue, resolving example 004 returning 80 instead of 42**

## Performance

- **Duration:** ~1 min
- **Started:** 2026-03-11T10:47:22Z
- **Completed:** 2026-03-11T10:48:16Z
- **Tasks:** 1/1
- **Files modified:** 1

## Accomplishments

- Corrected the stack offset formula for function parameters in `codegen_func`
- First parameter now correctly located at `rbp-48` (instead of `rbp-56`)
- Example 004 (`add(2, 40)`) now returns `42` (previously returned `80`)

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix parameter offset calculation in codegen_func** - `4adaa50` (fix)

**Plan metadata:** Will be committed separately (docs: complete plan summary)

## Files Created/Modified

- `codegen.mbt` (line 8253) - Changed `let offset = -saved_regs_size - (j + 1) * 8` to `let offset = -saved_regs_size - j * 8` to correctly calculate stack location of parameters relative to rbp

## Decisions Made

None - followed the plan as specified. The fix was straightforward and applied exactly as described.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed
**Impact on plan:** No scope changes; fix applied cleanly.

## Issues Encountered

None - the single-line change resolved the bug as expected.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Parameter offset bug fixed; example 004 now passes
- Ready for Plan 02-02 (stack cleanup fix) to address remaining calling convention issues
- No blockers identified

---

*Phase: 02-function-calls*
*Completed: 2025-03-11*
