---
phase: 02-function-calls
plan: 02
subsystem: compiler
tags: [x86_64, stack, function-calls, codegen]

# Dependency graph
requires:
  - phase: 02-function-calls
    provides: Corrected parameter offset calculation in callee prologue (plan 02-01)
provides:
  - Stack cleanup logic that only counts args with index >= 6
  - Example 004_basic_function outputs 42 correctly
affects:
  - 02-function-calls-03 (remaining function call fixes may depend on correct stack management)

# Tech tracking
tech-stack:
  added: []
  patterns: [conditional-stack-cleanup, stack-args-only]

key-files:
  created: []
  modified:
    - codegen.mbt - Modified codegen_user_func_call2 to conditionally accumulate total_stack_usage only for i >= 6

key-decisions:
  - "Followed plan exactly: wrapped total_stack_usage accumulation in if i >= 6"

patterns-established:
  - "Stack cleanup: only arguments passed on stack (index >= 6) contribute to total_stack_usage"

requirements-completed: ["COMP-01"]

# Metrics
duration: 2 min
completed: 2026-03-11
---

# Phase 2: Function Call Fixes - Plan 2 Summary

**Fixed stack cleanup in caller to only accumulate for stack arguments (i >= 6), preventing over-cleaning when register arguments are used**

## Performance

- **Duration:** ~2 min (verification)
- **Started:** 2026-03-11T10:59:32Z
- **Completed:** 2026-03-11T11:01:01Z
- **Tasks:** 1/1
- **Files modified:** 1 (codegen.mbt - fix already present)

## Accomplishments

- Verified that `codegen_user_func_call2` correctly limits `total_stack_usage` accumulation to arguments with index >= 6
- Example 004 (`add(2, 40)`) returns `42` as expected
- Stack cleanup now matches actual stack occupancy, preventing corruption when register arguments are present

## Task Commits

The code fix was already applied in commit `8da162e` (fix(02-function-calls-02): fix stack cleanup to only count stack args (i >= 6)). This execution verified the fix is functional.

**Plan metadata:** Created via this execution (SUMMARY, state updates)

## Files Created/Modified

No new modifications in this execution; the required fix was already present in `codegen.mbt`:

- `codegen.mbt` (lines 2225-2246) - The `total_stack_usage` accumulation is wrapped in `if i >= 6 { ... }`, ensuring only stack-passed arguments contribute to the cleanup amount

## Decisions Made

None - followed the plan as specified. The existing code matched the required change exactly.

## Deviations from Plan

None - plan executed exactly as written. The task required a code modification that was already present; verification confirmed correctness.

**Total deviations:** 0 auto-fixed
**Impact on plan:** No scope changes; verification successful.

## Issues Encountered

None - verification passed immediately. The codebase already contained the correct fix.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Stack cleanup logic is now correct for calls with ≤6 register arguments and >6 stack arguments
- Ready for Plan 02-03 (final function call fix) to complete Phase 2
- No blockers identified

---

*Phase: 02-function-calls*
*Completed: 2026-03-11*
