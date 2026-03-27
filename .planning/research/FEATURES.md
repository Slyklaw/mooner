# Feature Landscape

**Domain:** Compiler backend (WebAssembly)  
**Researched:** 2026-03-25  

## Table Stakes

Features users expect. Missing = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Generate valid WASM binary | Core requirement; without it, backend is useless. | Medium | Must pass WASM validation. |
| Support basic arithmetic (i32, i64, f32, f64) | Fundamental operations for any program. | Low | Direct mapping to WASM instructions. |
| Support control flow (if/else, loop, br) | Essential for conditional execution and iteration. | Medium | Need to handle label stacking. |
| Support function calls (import/export) | Programs rarely are single functions. | Medium | Handle call stack, return values. |
| Support local variables | Needed for any non‑trivial program. | Low | Map to WASM locals. |
| Maintain existing CLI compatibility | Users expect same command‑line interface. | Low | Add `--target wasm` flag or auto‑detect. |

## Differentiators

Features that set product apart. Not expected, but valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Generate minimal binary size | MoonBit's selling point for WebAssembly. | High | Requires dead code elimination, custom sections. |
| Support WASM‑GC (future) | Enables garbage‑collected languages. | High | Wait for MoonBit's own GC support. |
| Support WASI (future) | Allows system calls, file I/O. | Medium | Add import sections for WASI modules. |
| Incremental compilation | Faster development cycles. | High | Requires stable IR and caching. |

## Anti‑Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Component Model support initially | Adds complexity; out of scope for MVP. | Focus on core WASM binary; revisit later. |
| SIMD instructions | Not needed for basic compilation. | Implement only after core is stable. |
| Multi‑threading (threads proposal) | Advanced, rare use case. | Defer to future phase. |
| Debug information (DWARF) | Useful but not required for correctness. | Add after basic backend works. |

## Feature Dependencies

```
WASM Binary Generator → Basic arithmetic support
Basic arithmetic → Control flow support
Control flow → Function calls
Function calls → Local variables
All → CLI integration
```

## MVP Recommendation

Prioritize:
1. Generate valid WASM binary (section writing, LEB128).
2. Basic arithmetic and control flow mapping.
3. Function calls and local variables.
4. CLI integration.

Defer: WASI, SIMD, Component Model, debug info.

## Sources

- WebAssembly MVP specification — required features.
- Existing MoonBit compiler capabilities — what frontend already supports.
- MoonBit textbook example — demonstrated subset.

---
*Feature research for: WebAssembly compiler backend*
*Researched: 2026-03-25*