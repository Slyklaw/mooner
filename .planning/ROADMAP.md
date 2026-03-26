# Roadmap: MoonBit WASM Backend

## Overview

Add WebAssembly compilation target to existing MoonBit-to-x86_64 compiler. Phases progress from foundation (binary encoding + architecture) through language features (arithmetic, control flow, functions) to CLI integration, delivering a working WASM backend while preserving existing x86_64 functionality.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation** - WASM binary encoding and codegen abstraction (completed 2026-03-26)
- [x] **Phase 2: Basic Language Features** - Arithmetic operations and control flow (completed 2026-03-25)
- [ ] **Phase 3: Functions & Variables** - Function calls, exports, and variable handling
- [ ] **Phase 4: CLI Integration** - Command-line interface and compatibility

## Phase Details

### Phase 1: Foundation
**Goal**: Establish WASM backend foundation with binary encoding and architecture to support multiple backends
**Depends on**: Nothing (first phase)
**Requirements**: WASM-01, WASM-02, WASM-03, WASM-04, ABST-01, ABST-02, ABST-03
**Success Criteria** (what must be TRUE):
  1. Compiler can generate a valid WASM binary file (passes wasm-validate) from a trivial program
  2. Existing x86_64 backend still works after abstraction refactoring
  3. New backend can be added by implementing a simple interface (observable via code structure)
**Plans**: 3 plans in 2 waves

Plans:
- [x] 01-01: Implement LEB128 encoding and WASM section writing utilities
- [x] 01-02: Refactor codegen to support multiple backends (strategy pattern)
- [ ] 01-03: Create minimal WASM backend that emits empty module

### Phase 2: Basic Language Features
**Goal**: Support basic arithmetic operations and control flow in WASM
**Depends on**: Phase 1
**Requirements**: ARIT-01, ARIT-02, ARIT-03, ARIT-04, CTRL-01, CTRL-02, CTRL-03, CTRL-04
**Success Criteria** (what must be TRUE):
  1. User can compile programs with arithmetic operations (i32, i64, f32, f64) and get correct results when executed
  2. User can compile programs with if/else conditionals and branching works as expected
  3. User can compile programs with loops (while/for) and they execute correctly
  4. User can compile programs with block labels and early returns from functions
**Plans**: TBD

Plans:
- [x] 02-01: Implement i32 and i64 arithmetic operations in WASM backend
- [x] 02-02: Implement f32 and f64 arithmetic operations in WASM backend
- [x] 02-03: Implement if/else and loop control flow in WASM backend
- [x] 02-04: Implement block labels, branching, and return statements

### Phase 3: Functions & Variables
**Goal**: Support functions and variables in WASM
**Depends on**: Phase 2
**Requirements**: FUNC-01, FUNC-02, FUNC-03, FUNC-04, FUNC-05, VAR-01, VAR-02, VAR-03
**Success Criteria** (what must be TRUE):
  1. User can define functions with parameters and return values, and call them
  2. User can use local variables with get/set operations within functions
  3. User can export functions to host environment (observable via wasm-objdump exports)
  4. User can import external functions (basic import mechanism)
**Plans**: TBD

Plans:
- [ ] 03-01: Implement function signatures and local variables
- [ ] 03-02: Implement function calls and exports
- [ ] 03-03: Implement global variables (if applicable)

### Phase 4: CLI Integration
**Goal**: Integrate WASM backend into existing CLI
**Depends on**: Phase 3
**Requirements**: CLI-01, CLI-02, CLI-03, CLI-04
**Success Criteria** (what must be TRUE):
  1. User can use `--target wasm` flag to compile to WASM
  2. Compiler auto-detects output format based on file extension (.wasm vs .exe)
  3. Existing x86_64 backend still works without breaking changes
  4. Output .wasm files have proper permissions (no chmod needed)
**Plans**: 3 plans in 1 wave

Plans:
- [x] 04-01-PLAN.md — Add --target flag and auto-detection
- [x] 04-02-PLAN.md — Wire WASM compilation to CLI
- [x] 04-03-PLAN.md — Verify backward compatibility and permissions

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 3/3 | Complete    | 2026-03-26 |
| 2. Basic Language Features | 4/4 | Complete    | 2026-03-25 |
| 3. Functions & Variables | 0/3 | Not started | - |
| 4. CLI Integration | 3/3 | Planned | - |

## Coverage

All 27 v1 requirements mapped to phases. No orphaned requirements.

| Phase | Requirements Count | Requirement IDs |
|-------|-------------------|-----------------|
| 1 | 7 | WASM-01 to WASM-04, ABST-01 to ABST-03 |
| 2 | 8 | ARIT-01 to ARIT-04, CTRL-01 to CTRL-04 |
| 3 | 8 | FUNC-01 to FUNC-05, VAR-01 to VAR-03 |
| 4 | 4 | CLI-01 to CLI-04 |

---
*Roadmap created: 2026-03-25*
*Depth: quick (4 phases)*
*Requirements: 27 total*