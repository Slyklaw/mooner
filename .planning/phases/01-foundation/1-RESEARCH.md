# Phase 1: Foundation - Research

**Researched:** 2026-03-25
**Domain:** WebAssembly binary encoding, compiler backend architecture
**Confidence:** MEDIUM (based on official spec and existing implementations)

## Summary

Phase 1 establishes the foundation for a WebAssembly backend in the MoonBit compiler. The key tasks are implementing LEB128 encoding utilities and creating a modular backend architecture that supports multiple targets (x86_64, WASM). The research confirms that WebAssembly uses LEB128 for all integer encodings, and the binary format is well-documented. The existing x86_64 backend can be refactored using a strategy pattern to allow new backends.

**Primary recommendation:** Implement LEB128 encoding as standalone utilities, refactor codegen to use a Backend interface, and create a minimal WASM backend that can emit a valid module with empty sections.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| WebAssembly spec | 3.0 (2026) | Binary format definition | Official standard |
| LEB128 | N/A | Variable-length integer encoding | Required by WASM spec |
| MoonBit compiler | existing | Current x86_64 backend | Must be preserved |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| wasm-validate | N/A | Validation of generated WASM | Testing phase |
| Node.js | >=18 | Scripting and testing | Development utilities |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hand-rolled LEB128 | Use existing LLVM implementation | Not available in this project |
| Direct binary writing | Use a WASM library | Adds dependency; we need low-level control |

**Installation:**
No external libraries needed. Use existing MoonBit standard library for byte arrays.

## Architecture Patterns

### Recommended Project Structure
```
src/
├── wasm/          # New WASM backend
├── x86_64/        # Existing backend (refactored)
└── codegen/       # Shared interface and utilities
```

### Pattern 1: Strategy Pattern for Backends
**What:** Define a `Backend` interface with methods for code generation. Each target implements this interface.
**When to use:** When multiple backends share the same high-level structure but differ in output.
**Example:**
```moonbit
// Source: design pattern from compiler textbooks
trait Backend {
  fn generate_module(self, ast: AST) -> ByteArray
}
```

### Anti-Patterns to Avoid
- **Monolithic codegen:** Keeping all backend logic in one file leads to tangled dependencies.
- **Assuming little-endian:** WebAssembly is little-endian; ensure byte order in encoding.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| LEB128 encoding | Custom bit manipulation | Follow spec pseudocode | Edge cases (sign extension, padding) are tricky |
| WASM validation | Manual binary checks | Use `wasm-validate` tool | Official validation catches spec compliance |

**Key insight:** The WASM binary format is simple but precise; deviations cause validation failures.

## Common Pitfalls

### Pitfall 1: Incorrect LEB128 sign extension
**What goes wrong:** Signed LEB128 requires sign extension when decoding; encoding must handle negative values correctly.
**Why it happens:** Misunderstanding two's complement representation.
**How to avoid:** Use the spec pseudocode; test with edge cases (zero, negative, large values).
**Warning signs:** Generated WASM fails validation with "malformed LEB128".

### Pitfall 2: Missing section order
**What goes wrong:** WASM sections must appear in a specific order (Type, Import, Function, etc.).
**Why it happens:** Assumption that order doesn't matter.
**How to avoid:** Follow spec ordering; implement a section writer that enforces order.
**Warning signs:** Validation error "unexpected section".

### Pitfall 3: Breaking existing x86_64 backend
**What goes wrong:** Refactoring for abstraction may introduce regressions.
**Why it happens:** Incomplete test coverage.
**How to avoid:** Run existing test suite after each refactoring step; keep changes minimal.
**Warning signs:** Existing tests fail.

## Code Examples

### LEB128 Encoding (unsigned)
```moonbit
// Source: WebAssembly spec binary/values.html
fn encode_uleb128(value: UInt) -> ByteArray {
  let mut bytes = ByteArray::new()
  let mut val = value
  while true {
    let byte = val & 0x7f
    val = val >> 7
    if val != 0 {
      bytes.push(byte | 0x80)
    } else {
      bytes.push(byte)
      break
    }
  }
  bytes
}
```

### WASM Module Header
```moonbit
// Source: WebAssembly spec binary/modules.html
fn write_module_header() -> ByteArray {
  let mut buf = ByteArray::new()
  // Magic number \0asm
  buf.push(0x00)
  buf.push(0x61)
  buf.push(0x73)
  buf.push(0x6d)
  // Version 1
  buf.push(0x01)
  buf.push(0x00)
  buf.push(0x00)
  buf.push(0x00)
  buf
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single backend (x86_64) | Multiple backend interface | Phase 1 | Enables WASM and future backends |
| Hand-written binary | Structured section writer | Phase 1 | Reduces errors, improves maintainability |

**Deprecated/outdated:**
- Direct byte manipulation without LEB128: Replaced by proper variable-length encoding.

## Open Questions

1. **How to handle debug information?**
   - What we know: WASM supports custom sections for debug info.
   - What's unclear: Whether Phase 1 should include debug info support.
   - Recommendation: Defer to later phase; focus on minimal valid module.

2. **What subset of WASM instructions to support initially?**
   - What we know: MoonBit's current x86_64 backend generates a limited set.
   - What's unclear: Mapping of MoonBit constructs to WASM instructions.
   - Recommendation: Start with empty module (no code), then add basic arithmetic.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| WASM-01 | Implement LEB128 encoding utilities | LEB128 spec and pseudocode provided |
| WASM-02 | Create WASM section writing utilities | Binary format spec, section ordering documented |
| WASM-03 | Minimal WASM backend that emits empty module | Module header example, section structure |
| WASM-04 | Validate generated WASM with wasm-validate | Validation tool identified |
| ABST-01 | Refactor codegen to support multiple backends | Strategy pattern example |
| ABST-02 | Define backend interface | Interface trait example |
| ABST-03 | Ensure existing x86_64 backend still works | Pitfall avoidance and testing strategy |

## Sources

### Primary (HIGH confidence)
- WebAssembly Specification - Binary Format (https://webassembly.github.io/spec/core/binary/values.html)
- WebAssembly Design - BinaryEncoding (https://github.com/WebAssembly/design/blob/ccbac15a287fa2af4a3db882d950db442011a7b1/BinaryEncoding.md)

### Secondary (MEDIUM confidence)
- Wikipedia - LEB128 (https://en.wikipedia.org/wiki/LEB128)
- Understanding Every Byte in a WASM Module (https://danielmangum.com/posts/every-byte-wasm-module/)

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - official spec is authoritative
- Architecture: MEDIUM - based on common compiler patterns
- Pitfalls: HIGH - well-documented in spec and community resources

**Research date:** 2026-03-25
**Valid until:** 2026-04-25 (30 days)