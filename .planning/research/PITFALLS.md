# Domain Pitfalls

**Domain:** Compiler backend development (WebAssembly)  
**Researched:** 2026-03-25  

## Critical Pitfalls

### Pitfall 1: Premature Component Model Adoption
**What goes wrong:** Trying to target WASM Component Model (WIT) before implementing core WASM binary.  
**Why it happens:** Assuming component model is required for interoperability.  
**Consequences:** Adds unnecessary complexity, delays working backend.  
**Prevention:** Focus on core WASM binary format first; component model can be layered later.  
**Detection:** If design discussions center around WIT before binary encoding works.

### Pitfall 2: Over‑engineering the CodeGen Abstraction
**What goes wrong:** Creating a generic backend interface that is too abstract, making simple backends complex.  
**Why it happens:** Desire for future‑proofing with multiple backends.  
**Consequences:** Increased development time, harder to understand and maintain.  
**Prevention:** Start with a simple trait or interface that only abstracts instruction emission; refine later.  
**Detection:** When adding a new backend requires implementing many unnecessary methods.

## Moderate Pitfalls

### Pitfall 1: Ignoring WASM Validation
**What goes wrong:** Generating binary that passes runtime checks but is invalid per spec.  
**Prevention:** Use existing WASM validators (e.g., `wasm-validate`) during development.  
**Detection:** Runtime errors in WASM engines; use validation tools early.

### Pitfall 2: Hard‑coding Opcode Values
**What goes wrong:** Using magic numbers for WASM opcodes without documentation.  
**Prevention:** Define constants or an enum mapping mnemonic to byte value; reference spec.  
**Detection:** When opcode values change or need extension; becomes error‑prone.

## Minor Pitfalls

### Pitfall 1: Forgetting LEB128 Encoding for Integers
**What goes wrong:** Writing integers as raw bytes, causing malformed sections.  
**Prevention:** Implement and test LEB128 encoding early.  
**Detection:** WASM parsers reject the binary; debug with hex dump.

### Pitfall 2: Not Reusing Existing MoonBit Libraries
**What goes wrong:** Rewriting filesystem or buffer utilities that already exist in `moonbitlang/x`.  
**Prevention:** Check existing dependencies before implementing new utilities.  
**Detection:** Duplicate code; increased maintenance burden.

## Phase‑Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| WASM Binary Encoder | Incorrect section ordering | Follow spec order (type, function, memory, etc.). |
| CodeGen Abstraction | Leaking x86_64 specifics into abstraction | Define backend‑agnostic intermediate representation (IR). |
| Basic WASM Instructions | Missing control flow mapping | Study WASM branching semantics thoroughly. |
| Integration & Testing | Breaking existing x86_64 backend | Run both backend tests in CI. |

## Sources

- WebAssembly Binary Format specification — section order, validation rules.
- MoonBit textbook stack machine case study — practical encoding example.
- Existing compiler architecture analysis (.planning/codebase/ARCHITECTURE.md).
- Community experience (Rust `wasm-encoder` crate pitfalls, adapted to MoonBit).

---
*Pitfalls research for: WebAssembly compiler backend*
*Researched: 2026-03-25*