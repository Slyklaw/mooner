# STATE: Project Memory

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-11)

**Core value:** The compiler generates correct, executable output for all language features covered by the test suite. If everything else fails, the examples must pass.
**Current focus:** Phase 1 complete. Next: Plan Phase 2 (Fix Function Calls).

## Current Position

- **Phase:** 2 (Function Call Fixes)
- **Plan:** None yet (requires planning)
- **Status:** Not started
- **Progress:** 0%

## Performance Metrics

- Commits: 5 (planning commits: 5)
- Examples passing: 7 / 13
- Critical bugs: 4 (004, 009, 011, 013)
- Regressions: 0 (target: 0)

## Accumulated Context

### Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Focus exclusively on codegen bugs | Parser/lexer appear correct; failures trace to codegen | ✓ Confirmed |
| Fix order: 004 → 009 → 011 → 013 | Dependency chain: function calls → control flow → enums → pattern matching | — Pending |
| Allow temporary debug code in codegen | Needed for investigation; will be cleaned up in Phase 6 | ✓ Implemented |
| Use existing codebase analysis as research foundation | Already mapped architecture, stack, concerns; synthesized research artifacts | ✓ Good |
| Build minimal reproduction tests | Isolate bugs for faster debugging | ✓ Completed |

### Blockers

None at this time.

### Todos

- [x] Phase 1: Setup & Investigation complete (debug tracing, harness, minimal repros)
- [ ] Run `/gsd-plan-phase 2` to create detailed plans for Phase 2
- [ ] Execute Phase 2: Fix function call return bug (004)
- [ ] Verify fix with minimal repro and full test suite

## Recent Work

- **2026-03-11:** Phase 1 completed:
  - Added debug tracing infrastructure to codegen (debug_level, trace_instruction)
  - Built test harness (harness.sh) and captured baseline results for 004/009/011/013
  - Created minimal reproduction files for each bug
- Research phase synthesized architecture, stack, features, pitfalls
- Roadmap defined with 6 phases covering all v1 requirements

## Handoff Notes

Next action: `/gsd-plan-phase 2` to break down Phase 2 into executable plans with tasks.
