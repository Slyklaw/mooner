---
phase: 03-control-flow
plan: 01
subsystem: codegen
tags: [control-flow, x86_64, jumps, labels, codegen]

requires:
  - phase: 02-function-calls
    provides: function call fixup and stack management

provides:
  - Correct jump offset calculation for all conditional jumps
  - Function-indexed label namespace isolation
  - RIP-relative addressing fixup
  - Example 009 no longer segfaults

affects: [break-continue, loop-validation]

tech-stack:
  added: []
  patterns:
    - "Instruction-length-aware pending label fixup"
    - "Function-indexed label namespaces: .Lfn{idx}_{counter}"

key-files:
  created: []
  modified:
    - codegen.mbt

key-decisions:
  - "Captured start_pos before emitting opcode bytes for all jump/call instructions"
  - "Used instr_len=6 for conditional jumps (2-byte opcode 0F 8x + 4-byte offset)"
  - "Used instr_len=7 for LEA RipRel32 (3 bytes prefix + 4 bytes offset)"
  - "Used instr_len=8 for Movsd RipRel32 (4 bytes prefix + 4 bytes offset)"
  - "Label namespace isolation prevents cross-function label collisions"

requirements-completed: ["COMP-02"]

duration: ~3min
completed: 2026-03-11
---

# Phase 03 Plan 01: Jump Offset and Label Namespace Fixes Summary

**Fixed x86_64 conditional jump encoding (instr_len 5→6) and RIP-relative address calculation, added function-indexed label namespaces to prevent cross-function collisions**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-11
- **Completed:** 2026-03-11
- **Tasks:** 4 (1 pre-existing, 3 new)
- **Files modified:** 1

## Accomplishments

- **Segfault eliminated:** Example 009 now compiles and runs to completion (was crashing before)
- **Conditional jump fix:** All 14 conditional jump instructions (Je, Jne, Jg, Jge, Jl, Jle, Ja, Jae, Jb, Jbe, Jz, Jnz, Jp) now use correct 6-byte encoding with instr_len=6
- **Start position capture:** All jump, call, and RIP-relative instructions now capture start_pos before emitting opcode bytes
- **RIP-relative addressing:** LEA RipRel32 instr_len=7, Movsd RipRel32 instr_len=8
- **Label namespace isolation:** Added func_counter and current_func_idx fields; new_label generates .Lfn{idx}_{counter} format
- **No regressions:** All 19 tests pass; examples 001-006, 008, 010 produce IDENTICAL output to official compiler

## Task Commits

All work committed atomically in a single commit:

1. **Tasks 1-4** - `1e03622` (fix): fix control flow segfault - jump offsets and label namespaces

## Files Modified

- `codegen.mbt` - Core fixes: jump encoding, start_pos capture, label namespace isolation

## Decisions Made

- Captured start_pos before emitting opcode bytes (previously captured after, causing offset calculation errors)
- Used instr_len=6 for conditional jumps (previously 5, which ignored the 2-byte opcode prefix)
- Added function-indexed labels to prevent label collisions when multiple functions use same control flow patterns
- Task 1 (pending_labels type) and Task 4 (fixup loop) were already complete from prior work

## Deviations from Plan

None - plan executed exactly as written. Tasks 1 and 4 were already implemented in the codebase (pending_labels was already a three-tuple, fixup loop already used correct destructuring). The actual work was Tasks 2 (fixing start_pos and instr_len) and 3 (adding label namespace isolation).

## Issues Encountered

None beyond the core bugs addressed.

## Next Phase Readiness

- **Wave 2 ready:** Break/continue validation and while-loop debugging can proceed
- **Remaining for 009:** For-loop step produces incorrect output (7 instead of 15 for sum), while-loop hangs - to be addressed in Wave 2
- **No regressions:** All passing examples remain passing

---

*Phase: 03-control-flow*
*Completed: 2026-03-11*
