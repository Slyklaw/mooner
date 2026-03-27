# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-26)

**Core value:** Enable MoonBit programs to run in WebAssembly environments (browsers, WASI runtimes) while reusing the existing MoonBit compiler frontend.
**Current focus:** Not started (defining requirements)

## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: 2026-03-26 — Milestone v1.1 started

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table. Recent decisions affecting current work:

- [Phase 1]: Abstract code generation to support multiple backends
- [Phase 2]: Integrate arithmetic directly in wasm_backend.mbt for simplicity
- [Phase 02-04]: Used helper functions for BlockType to avoid MoonBit enum read-only issue
- [Phase 03-02]: Import indices come first (0 to N-1), then defined function indices for correct call targeting
- [ v1.0 Complete ]: Stabilize before new features — ✓ Good

### Pending Todos

From .planning/todos/pending/ — ideas captured during sessions

None yet.

### Blockers/Concerns

Issues that affect future work

None yet.
