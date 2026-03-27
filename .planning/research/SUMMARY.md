# Research Summary: MoonBit WASM Backend

**Domain:** Compiler backend development  
**Researched:** 2026-03-25  
**Overall confidence:** HIGH

## Executive Summary

The standard stack for building a WebAssembly compiler backend in MoonBit is to implement the WebAssembly binary format directly using MoonBit's byte manipulation primitives, without external dependencies. MoonBit's standard library provides sufficient tools (`Array[Byte]`, `Buffer`) for encoding WASM sections, opcodes, and LEB128 integers. The official MoonBit textbook demonstrates this approach with a stack machine compiler that generates WASM binary. The existing project already uses MoonBit 0.8.3 and the `moonbitlang/x` library for filesystem I/O, which is sufficient for reading source files and writing the compiled WASM output. No specialized WASM encoding libraries exist in the MoonBit ecosystem, making manual implementation the only viable option that adheres to the project's constraint of avoiding external dependencies.

## Key Findings

**Stack:** MoonBit (0.8.3) + manual WASM binary encoding + moonbitlang/x for I/O.  
**Architecture:** The existing compiler pipeline (lexer → parser → codegen) can be extended with a new code generation backend that emits WASM binary instead of x86_64 machine code.  
**Critical pitfall:** Attempting to use external libraries or component model tools prematurely; the MVP target should be core WASM binary.

## Implications for Roadmap

Based on research, suggested phase structure:

1. **Phase 1: WASM Binary Encoder** - Implement LEB128 encoding and section writing functions in MoonBit.
   - Addresses: Basic WASM binary generation.
   - Avoids: External dependencies.

2. **Phase 2: CodeGen Abstraction** - Refactor existing codegen to support multiple backends (x86_64 and WASM).
   - Addresses: Reuse frontend, maintain compatibility.
   - Avoids: Duplicating frontend logic.

3. **Phase 3: Basic WASM Instructions** - Map MoonBit language constructs to WASM MVP instructions (i32, control flow, functions).
   - Addresses: Core language features compilation.
   - Avoids: Advanced WASM features (SIMD, threads).

4. **Phase 4: Integration & Testing** - Integrate with CLI, test against MoonBit examples, compare output with official compiler.
   - Addresses: Compatibility and correctness.
   - Avoids: Regression in existing x86_64 backend.

**Phase ordering rationale:**
- Binary encoder must exist before code generation.
- Abstraction before adding new backend.
- Incremental feature addition ensures testability.

**Research flags for phases:**
- Phase 1: Standard patterns, unlikely to need research (binary format is well-documented).
- Phase 2: May need deeper research on abstraction patterns (strategy pattern, etc.).
- Phase 3: Requires mapping MoonBit types to WASM types; may need research on type system compatibility.
- Phase 4: Standard testing patterns.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Verified via official textbook and existing project dependencies. |
| Features | MEDIUM | Limited to MVP WASM features; advanced features deferred. |
| Architecture | HIGH | Existing architecture documented; extension points clear. |
| Pitfalls | MEDIUM | Common pitfalls identified (e.g., premature optimization). |

## Gaps to Address

- Detailed mapping of MoonBit types to WASM types (i32, i64, f32, f64).
- Handling of memory model (linear memory, stack vs heap).
- Error handling in WASM binary generation (validation).
- Performance considerations for large binary generation.

---
*Summary research for: MoonBit WASM Backend*
*Researched: 2026-03-25*