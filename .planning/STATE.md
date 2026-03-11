# STATE: Project Memory

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-11)

**Core value:** The compiler generates correct, executable output for all language features covered by the test suite. If everything else fails, the examples must pass.
**Current focus:** Phase 3 (Control Flow Fixes) in progress. Plans 01-03 complete - jump offset fixes, break/continue validation, and control flow correctness testing done.

## Current Position

- **Phase:** 3 (Control Flow Fixes)
- **Plan:** 03 complete (Control flow correctness testing: if/else, for, while, nested)
- **Status:** Ready for remaining plans (004-008 regression) or transition
- **Progress:** [████████░░] 78%

## Performance Metrics

- Commits: 13 (code commits: 5, planning commits: 4, test commits: 4)
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
| Phase 02-function-calls P01 | 1 min | 1 tasks | 1 files |
| Phase 02 P02 | 2 min | 1 tasks | 1 files |
| Phase 02-function-calls P03 | ~4 min | 2 tasks | 1 files |
- [Phase 02-function-calls]: None - followed plan as specified — Plan executed exactly; auto-advance allowed smooth verification
| Phase 01-setup-investigation P02 | 5min | 3 tasks | 3 files |
| Phase 02 Pfunction-calls | ~10 min | 6 tasks | 3 files |
- [Phase 02]: Phase 2 completed: Function call fixes verified and test suite passes (19/19)

### Blockers

None at this time.

### Todos

- [x] Phase 1: Setup & Investigation complete (debug tracing, harness, minimal repros)
- [x] Run `/gsd-plan-phase 2` to create detailed plans for Phase 2
- [x] Execute Phase 2: Fix function call return bug (004)
- [x] Verify fix with minimal repro and full test suite
- [x] Phase 3 Plan 01: Fix jump offset calculation and label namespace isolation
- [x] Phase 3 Plan 02: Break/continue validation and nested loop verification
- [x] Phase 3 Plan 03: Control flow correctness testing (if/else, for, while, nested)

## Recent Work

- **2026-03-11:** Phase 1 completed:
  - Added debug tracing infrastructure to codegen (debug_level, trace_instruction)
  - Built test harness (harness.sh) and captured baseline results for 004/009/011/013
  - Created minimal reproduction files for each bug
- **2026-03-11:** Phase 2 (Function Calls) completed:
  - Verified 004_basic_function returns 42 (confirming fixes)
  - Full test suite passes (19/19) with no regressions
  - Updated mooner_test.mbt to match current API
- **2026-03-11:** Phase 3 Plan 01 completed:
  - Fixed conditional jump instruction length (Je, Jne, Jg, etc.) from 5 to 6 bytes
  - Captured start_pos before emitting opcode bytes for all jump/call instructions
  - Fixed RIP-relative addressing: LEA instr_len=7, Movsd instr_len=8
  - Added func_counter and current_func_idx for label namespace isolation
  - Example 009 no longer segfaults; no regressions on passing examples
- **2026-03-11:** Phase 3 Plan 02 completed:
  - Added `abort("break not inside loop")` / `abort("continue not inside loop")` validation
  - Break/continue outside loops now produce compile-time errors instead of silent fallthrough
  - Created nested break test verifying innermost loop scoping works correctly
  - Used if/else to preserve CodeGen return type in match arms
- **2026-03-11:** Phase 3 Plan 03 completed:
  - Created 6 control flow test files (if/else, for loop ×2, while loop ×2, nested)
  - All test outputs match official MoonBit compiler (IDENTICAL diffs)
  - Discovered `print(int)` garbles output — use `println` instead
  - Discovered multiple for-loops in same function segfault — one loop per file
  - Example 008 (maps) confirmed pre-existing bug (undefined label at codegen line 8569)
  - No regressions: 001-007, 009-010 all still work
- Research phase synthesized architecture, stack, features, pitfalls
- Roadmap defined with 6 phases covering all v1 requirements

## Handoff Notes

Next action: Check for Phase 3 remaining plans (004-007) or transition. Control flow correctness verified — if/else, for-in, while, nested all produce correct output matching official compiler. Known remaining: 008 pre-existing bug, 009 while hang, 011 enum, 013 pattern matching.
