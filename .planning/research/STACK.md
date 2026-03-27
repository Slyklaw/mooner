# Technology Stack

**Project:** MoonBit WASM Backend  
**Researched:** 2026-03-25  
**Confidence:** HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| MoonBit | 0.8.3 (latest stable) | Primary implementation language | Self-hosted compiler; project already uses MoonBit. Strong type system and byte manipulation capabilities. |
| WebAssembly Binary Format | Core spec 1.0 (MVP) | Target output format | Standard for WASM; relatively simple section-based binary encoding. No external dependency needed. |
| LEB128 Encoding | (custom implementation) | Encode integers in WASM binary | Required for WASM binary format; can be implemented directly in MoonBit using bit operations. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| moonbitlang/x | 0.4.40 | Filesystem operations (`@fs.read_file_to_string`, `@fs.write_bytes_to_file`) | For reading source files and writing compiled WASM binary. |
| moonbitlang/async | 0.16.6 | Asynchronous support (imported but not required) | Only if async compilation is needed; otherwise optional. |
| moonbitlang/core | latest (bundled) | Core standard library (basic types, arrays, etc.) | Always; provides fundamental data structures like `Array[Byte]` and `Buffer`. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| moon | Build system and package manager | Run `moon build`, `moon test`, `moon run`. |
| moon fmt | Code formatter | Ensures consistent code style. |
| moon info | Generate interface files (`.mbti`) | Required for package exports. |
| moon test | Run blackbox/whitebox tests | Validate compiler correctness. |

## Installation

```bash
# Core toolchain (already installed for existing compiler)
# MoonBit toolchain via official installer
curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash

# Dependencies (already in moon.mod.json)
moon add moonbitlang/x@0.4.40
moon add moonbitlang/async@0.16.6
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Manual WASM binary encoding | External library (e.g., `wasm-encoder` in Rust via FFI) | If a MoonBit WASM encoder library emerges and is stable. Currently none exist. |
| Core WASM (MVP) | Component Model (WIT) | When targeting WASM component model for interoperability. Out of scope for initial backend. |
| Byte array manipulation | Stream-based writing | If large binary generation causes memory issues; but MoonBit's `Buffer` is efficient. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| External WASM encoding libraries | No mature MoonBit library exists; adding external dependencies violates project constraints. | Implement binary encoding directly using MoonBit's byte array primitives. |
| Component Model tools (wit-bindgen, wasm-tools) | Initial target is standalone WASM modules, not components. Adds complexity. | Focus on core WASM binary format; component support can be added later. |
| LLVM or other compiler frameworks | Overkill for a simple backend; increases dependencies and build complexity. | Direct binary generation aligns with existing x86_64 backend approach. |

## Stack Patterns by Variant

**If targeting WASI (WebAssembly System Interface):**
- Add `wasi` import sections manually (still binary encoding).
- Consider using `moonbitlang/wasi` package if available (currently not found).

**If optimizing for code size:**
- Implement custom section merging and dead code elimination.
- Use MoonBit's optimization flags (`moon build --release`).

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| moonbitlang/x@0.4.40 | MoonBit >=0.8.0 | Filesystem API stable. |
| moonbitlang/async@0.16.6 | MoonBit >=0.8.0 | Optional; can be omitted if not used. |

## Sources

- MoonBit official documentation (https://www.moonbitlang.com/docs/) — Language features and toolchain.
- WebAssembly Binary Format specification (https://webassembly.github.io/spec/core/binary.html) — Encoding details.
- MoonBit textbook case study: Stack Machine (https://moonbitlang.github.io/moonbit-textbook/stack-machine/) — Example of WASM binary generation in MoonBit (HIGH confidence).
- Existing project STACK.md (.planning/codebase/STACK.md) — Current dependency versions.

---
*Stack research for: WebAssembly compiler backend in MoonBit*
*Researched: 2026-03-25*