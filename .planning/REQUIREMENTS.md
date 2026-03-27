# Requirements: MoonBit WASM Backend

**Defined:** 2026-03-25
**Core Value:** Enable MoonBit programs to run in WebAssembly environments (browsers, WASI runtimes) while reusing the existing MoonBit compiler frontend.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### WASM Binary

- [x] **WASM-01**: Generate valid WASM binary (correct magic number, version, section structure)
- [x] **WASM-02**: Implement LEB128 encoding for integers (required for WASM binary format)
- [ ] **WASM-03**: Write WASM sections (type, function, export, code, etc.)
- [ ] **WASM-04**: Validate generated binary passes WASM validation tools (e.g., `wasm-validate`)

### Arithmetic

- [ ] **ARIT-01**: Support i32 arithmetic operations (add, sub, mul, div, rem)
- [ ] **ARIT-02**: Support i64 arithmetic operations (add, sub, mul, div, rem)
- [ ] **ARIT-03**: Support f32 arithmetic operations (add, sub, mul, div)
- [ ] **ARIT-04**: Support f64 arithmetic operations (add, sub, mul, div)

### Control Flow

- [x] **CTRL-01**: Support if/else conditional statements (WASM `if`/`else`/`end`)
- [x] **CTRL-02**: Support loop constructs (WASM `loop`/`br`/`br_if`)
- [x] **CTRL-03**: Support block labels and branching (WASM `block`, `br`, `br_table`)
- [x] **CTRL-04**: Support early returns from functions (WASM `return`)

### Functions

- [x] **FUNC-01**: Generate function signatures (parameter and result types)
- [x] **FUNC-02**: Emit function bodies with local variables
- [ ] **FUNC-03**: Support function calls (direct calls within module)
- [ ] **FUNC-04**: Support function exports (make functions callable from host)
- [ ] **FUNC-05**: Support function imports (call external functions, e.g., WASI)

### Variables

- [x] **VAR-01**: Map local variables to WASM locals (i32, i64, f32, f64)
- [ ] **VAR-02**: Support local variable get/set operations
- [ ] **VAR-03**: Support global variables (if applicable)

### CLI Integration

- [x] **CLI-01**: Add `--target wasm` flag to compiler CLI
- [x] **CLI-02**: Auto-detect output format based on file extension (.wasm vs .exe)
- [x] **CLI-03**: Maintain compatibility with existing x86_64 backend (no breaking changes)
- [ ] **CLI-04**: Output `.wasm` files with proper permissions (no chmod needed)

### Code Generation Abstraction

- [x] **ABST-01**: Refactor code generation to support multiple backends (strategy pattern)
- [x] **ABST-02**: Define backend interface for instruction emission
- [x] **ABST-03**: Keep existing x86_64 backend functional after abstraction

## v1.1 Requirements

Stabilization milestone: fix critical bugs and add regression tests.

### Bug Fixes

- [ ] **BUGF-01**: Fix control flow crash — 009_basic_control_flows example runs without segfault
- [ ] **BUGF-02**: Fix pattern matching crash — 013_pattern_matching example runs without segfault
- [ ] **BUGF-03**: Fix return value corruption — 004_basic_function returns correct values (e.g., add(2,40)=42)
- [ ] **BUGF-04**: Fix enum pattern mismatch — 011_basic_enum produces correct discriminants and variants

### Testing

- [ ] **TEST-01**: Write unit test that reproduces and verifies BUGF-01 fix
- [ ] **TEST-02**: Write unit test that reproduces and verifies BUGF-02 fix
- [ ] **TEST-03**: Write unit test that reproduces and verifies BUGF-03 fix
- [ ] **TEST-04**: Write unit test that reproduces and verifies BUGF-04 fix
- [ ] **TEST-05**: Add regression test for 009_basic_control_flows to prevent future regressions
- [ ] **TEST-06**: Add regression test for 013_pattern_matching to prevent future regressions
- [ ] **TEST-07**: Add regression test for 004_basic_function to prevent future regressions
- [ ] **TEST-08**: Add regression test for 011_basic_enum to prevent future regressions

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Advanced WASM Features

- **ADVW-01**: Support WASM-GC (garbage collection) extensions
- **ADVW-02**: Support SIMD instructions (128-bit vector operations)
- **ADVW-03**: Support multi-threading (threads proposal)
- **ADVW-04**: Support bulk memory operations (memory.copy, memory.fill)

### Tooling

- **TOOL-01**: Generate debug information (DWARF) for WASM binaries
- **TOOL-02**: Support incremental compilation for faster builds
- **TOOL-03**: Provide WASM-specific optimization passes

### WASI Integration

- **WASI-01**: Full WASI preview 1 support (filesystem, environment, random)
- **WASI-02**: WASI preview 2 support (component model)
- **WASI-03**: Command-line argument passing via WASI

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Component Model support initially | Adds complexity; out of scope for MVP |
| SIMD instructions | Not needed for basic compilation |
| Multi-threading (threads proposal) | Advanced, rare use case |
| Debug information (DWARF) | Useful but not required for correctness |
| Rewrite existing x86_64 backend | Parallel work, not part of WASM backend |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| WASM-01 | Phase 1 | Pending |
| WASM-02 | Phase 1 | Pending |
| WASM-03 | Phase 1 | Pending |
| WASM-04 | Phase 1 | Pending |
| ARIT-01 | Phase 2 | Pending |
| ARIT-02 | Phase 2 | Pending |
| ARIT-03 | Phase 2 | Pending |
| ARIT-04 | Phase 2 | Pending |
| CTRL-01 | Phase 2 | Complete |
| CTRL-02 | Phase 2 | Complete |
| CTRL-03 | Phase 2 | Complete |
| CTRL-04 | Phase 2 | Complete |
| FUNC-01 | Phase 3 | Complete |
| FUNC-02 | Phase 3 | Complete |
| FUNC-03 | Phase 3 | Pending |
| FUNC-04 | Phase 3 | Pending |
| FUNC-05 | Phase 3 | Pending |
| VAR-01 | Phase 3 | Complete |
| VAR-02 | Phase 3 | Pending |
| VAR-03 | Phase 3 | Pending |
| CLI-01 | Phase 4 | Complete |
| CLI-02 | Phase 4 | Complete |
| CLI-03 | Phase 4 | Complete |
| CLI-04 | Phase 4 | Pending |
| ABST-01 | Phase 1 | Complete |
| ABST-02 | Phase 1 | Complete |
| ABST-03 | Phase 1 | Complete |
| BUGF-01 | Phase 5 | Pending |
| BUGF-02 | Phase 6 | Pending |
| BUGF-03 | Phase 7 | Pending |
| BUGF-04 | Phase 8 | Pending |
| TEST-01 | Phase 5 | Pending |
| TEST-02 | Phase 6 | Pending |
| TEST-03 | Phase 7 | Pending |
| TEST-04 | Phase 8 | Pending |
| TEST-05 | Phase 5 | Pending |
| TEST-06 | Phase 6 | Pending |
| TEST-07 | Phase 7 | Pending |
| TEST-08 | Phase 8 | Pending |

**Coverage:**
- v1 requirements: 27 total
- Mapped to phases: 27
- Unmapped: 0 ✓
- v1.1 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-25*
*Last updated: 2026-03-26 after v1.1 roadmap creation*
