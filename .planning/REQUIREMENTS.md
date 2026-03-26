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

- [ ] **CTRL-01**: Support if/else conditional statements (WASM `if`/`else`/`end`)
- [ ] **CTRL-02**: Support loop constructs (WASM `loop`/`br`/`br_if`)
- [ ] **CTRL-03**: Support block labels and branching (WASM `block`, `br`, `br_table`)
- [ ] **CTRL-04**: Support early returns from functions (WASM `return`)

### Functions

- [ ] **FUNC-01**: Generate function signatures (parameter and result types)
- [ ] **FUNC-02**: Emit function bodies with local variables
- [ ] **FUNC-03**: Support function calls (direct calls within module)
- [ ] **FUNC-04**: Support function exports (make functions callable from host)
- [ ] **FUNC-05**: Support function imports (call external functions, e.g., WASI)

### Variables

- [ ] **VAR-01**: Map local variables to WASM locals (i32, i64, f32, f64)
- [ ] **VAR-02**: Support local variable get/set operations
- [ ] **VAR-03**: Support global variables (if applicable)

### CLI Integration

- [ ] **CLI-01**: Add `--target wasm` flag to compiler CLI
- [ ] **CLI-02**: Auto-detect output format based on file extension (.wasm vs .exe)
- [ ] **CLI-03**: Maintain compatibility with existing x86_64 backend (no breaking changes)
- [ ] **CLI-04**: Output `.wasm` files with proper permissions (no chmod needed)

### Code Generation Abstraction

- [x] **ABST-01**: Refactor code generation to support multiple backends (strategy pattern)
- [x] **ABST-02**: Define backend interface for instruction emission
- [x] **ABST-03**: Keep existing x86_64 backend functional after abstraction

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
| CTRL-01 | Phase 2 | Pending |
| CTRL-02 | Phase 2 | Pending |
| CTRL-03 | Phase 2 | Pending |
| CTRL-04 | Phase 2 | Pending |
| FUNC-01 | Phase 3 | Pending |
| FUNC-02 | Phase 3 | Pending |
| FUNC-03 | Phase 3 | Pending |
| FUNC-04 | Phase 3 | Pending |
| FUNC-05 | Phase 3 | Pending |
| VAR-01 | Phase 3 | Pending |
| VAR-02 | Phase 3 | Pending |
| VAR-03 | Phase 3 | Pending |
| CLI-01 | Phase 4 | Pending |
| CLI-02 | Phase 4 | Pending |
| CLI-03 | Phase 4 | Pending |
| CLI-04 | Phase 4 | Pending |
| ABST-01 | Phase 1 | Complete |
| ABST-02 | Phase 1 | Complete |
| ABST-03 | Phase 1 | Complete |

**Coverage:**
- v1 requirements: 27 total
- Mapped to phases: 27
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-25*
*Last updated: 2026-03-26 after Plan 01-02 completion*