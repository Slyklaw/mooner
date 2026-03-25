# Phase 3: Functions & Variables - Research

**Researched:** 2026-03-25
**Domain:** WebAssembly binary generation for functions and variables
**Confidence:** HIGH

## User Constraints (from CONTEXT.md)

### Locked Decisions
No specific implementation decisions were discussed due to auto-advance mode.
- Claude has full discretion on implementation details within the phase boundary.

### Claude's Discretion
- Function signature representation (WASM type section)
- Local variable allocation strategy (stack vs locals)
- Function call instruction selection (call vs call_indirect)
- Export mechanism (export section entries)
- Import section design (future WASI compatibility)
- Handling of recursion and stack overflow
- Error handling for undefined behavior

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| FUNC-01 | Function signatures (parameters, return types) | WASM type section encoding, function section |
| FUNC-02 | Function body with local variables | Local variable index allocation, get/set instructions |
| FUNC-03 | Function calls within same module | Call instruction, call stack management |
| FUNC-04 | Export functions to host | Export section entries with function indices |
| FUNC-05 | Import external functions | Import section entries with module/function names |
| VAR-01 | Local variables (get/set) | Local variable types, instruction encoding |
| VAR-02 | Global variables (optional) | Global section, mutable/immutable globals |
| VAR-03 | Variable scoping within functions | Function-level scope, shadowing rules |

## Summary

This phase requires implementing the WebAssembly binary generation for functions and variables. The existing codebase already compiles to x86_64; we need to adapt the code generation to produce WASM binary format. The core tasks are:

1. **WASM Binary Structure**: Extend the existing ELF header generation to produce WASM binary headers (magic number, version).
2. **Type Section**: Define function signatures (parameter and result types) using WASM value types (i32, i64, f32, f64).
3. **Function Section**: Map function indices to type indices.
4. **Memory Section**: Define linear memory (if needed for strings/data).
5. **Export Section**: Export functions by name with export kind `function`.
6. **Import Section**: Import external functions (for future WASI support).
7. **Code Section**: Function bodies with local variable declarations and instructions.
8. **Local Variable Allocation**: Assign indices to locals (parameters first, then locals).
9. **Instruction Generation**: Emit WASM instructions for get_local, set_local, call, etc.

**Primary recommendation**: Use the existing codegen.mbt as a foundation, but replace x86_64 instructions with WASM opcodes. The parser and lexer remain unchanged; only the code generation phase changes.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| WebAssembly Binary Format | 1.0 | Target binary format | Official W3C standard |
| WASM instruction set | 1.0 | Instruction encoding | Core of WebAssembly |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| None | - | - | - |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hand-rolled binary encoding | Use existing WASM libraries (e.g., wasm-encoder) | Introduces external dependency; our compiler is self-contained |
| Text format (WAT) generation | Direct binary generation | Text format easier for debugging but extra step |

**Installation:** No external libraries needed.

## Architecture Patterns

### Recommended Project Structure
```
src/
├── lexer.mbt        # Tokenizer (unchanged)
├── parser.mbt       # Parser (unchanged)
├── codegen.mbt      # Code generator (extend for WASM)
├── wasm.mbt         # WASM binary encoding helpers
└── compiler.mbt     # Entry point (adapt for WASM output)
```

### Pattern 1: Modular Code Generation
**What:** Separate x86_64 and WASM code generation into distinct modules.
**When to use:** When supporting multiple backends.
**Example:**
```moonbit
// codegen.mbt
fn generate_code(ast: AST, backend: Backend) -> Bytes {
  match backend {
    X86_64 => x86_codegen(ast)
    WASM => wasm_codegen(ast)
  }
}
```

### Anti-Patterns to Avoid
- **Mixing binary formats:** Keep ELF and WASM generation separate to avoid confusion.
- **Hardcoding offsets:** Use helper functions to compute section sizes and indices.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| WASM binary encoding | Custom binary writer | Existing patterns from codebase | Ensure correct encoding |
| Section sizing | Manual byte counting | Compute from content length | Avoid off-by-one errors |

**Key insight:** The existing codebase already handles binary output for ELF; we can reuse patterns for WASM sections.

## Common Pitfalls

### Pitfall 1: Incorrect Section Ordering
**What goes wrong:** WASM binary requires sections in a specific order (type, import, function, memory, export, start, element, code, data).
**Why it happens:** Not following spec.
**How to avoid:** Follow WASM specification ordering; create a section list and serialize in order.

### Pitfall 2: Local Variable Index Confusion
**What goes wrong:** Parameters are locals starting at index 0, additional locals follow.
**Why it happens:** Mixing parameter indices with local indices.
**How to avoid:** Clearly separate parameter count and local count; locals start after parameters.

### Pitfall 3: Export Function Index Mismatch
**What goes wrong:** Export section references function index, but function indices are relative to the function section (not import count).
**Why it happens:** Ignoring imported functions.
**How to avoid:** Account for imported functions when mapping function indices.

### Pitfall 4: Missing Memory Section
**What goes wrong:** Linear memory required for strings/globals.
**Why it happens:** Assuming stack-only execution.
**How to avoid:** Include memory section with at least one page (64KB) if any data or globals.

## Code Examples

Verified patterns from official sources:

### WASM Binary Header
```
0x00, 0x61, 0x73, 0x6D,  // magic number "\0asm"
0x01, 0x00, 0x00, 0x00,  // version 1
```

### Type Section Entry
```
0x60,                     // form: function
0x02,                     // param count: 2
0x7F, 0x7F,               // params: i32, i32
0x01,                     // result count: 1
0x7F                      // result: i32
```

### Function Body Local Declaration
```
0x02,                     // local count: 2
0x01, 0x7F,               // 1 local of type i32
0x01, 0x7F,               // 1 local of type i32
...                       // instructions
```

### Export Entry
```
0x07,                     // name length
'e','x','p','o','r','t','1',  // export name
0x00,                     // export kind: function
0x00                      // function index (0-based)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| x86_64 binary generation | WebAssembly binary generation | Phase 3 | Cross-platform execution |

**Deprecated/outdated:**
- ELF-specific sections (will remain for x86 backend)

## Open Questions

1. **Memory model**: Should we implement linear memory now or defer to later phase?
   - What we know: Strings and globals may need memory.
   - What's unclear: Whether Phase 3 requires memory.
   - Recommendation: Include memory section but keep minimal (1 page). Future phases can expand.

2. **Import mechanism**: How detailed should import section be?
   - What we know: Future WASI support will need imports.
   - What's unclear: Exact import signatures.
   - Recommendation: Allow arbitrary imports but keep simple for now.

## Validation Architecture

> Skip this section entirely if workflow.nyquist_validation is false in .planning/config.json

### Test Framework
| Property | Value |
|----------|-------|
| Framework | MoonBit built-in test framework |
| Config file | none — see Wave 0 |
| Quick run command | `moon test` |
| Full suite command | `moon test` |
| Estimated runtime | ~2 seconds |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| FUNC-01 | Function signature parsing | unit | `moon test` | ✅ yes |
| FUNC-02 | Local variable allocation | unit | `moon test` | ✅ yes |
| FUNC-03 | Function calls | integration | `moon test` | ✅ yes |
| FUNC-04 | Export functions | integration | `moon test` | ✅ yes |
| FUNC-05 | Import functions | unit | `moon test` | ✅ yes |
| VAR-01 | Local variable get/set | unit | `moon test` | ✅ yes |
| VAR-02 | Global variables | unit | `moon test` | ✅ yes |
| VAR-03 | Variable scoping | unit | `moon test` | ✅ yes |

### Nyquist Sampling Rate
- **Minimum sample interval:** After every committed task → run: `moon test`
- **Full suite trigger:** Before merging final task of any plan wave
- **Phase-complete gate:** Full suite green before `/gsd-verify-work` runs
- **Estimated feedback latency per task:** ~1 second

### Wave 0 Gaps (must be created before implementation)
- [ ] `tests/test_wasm_functions.mbt` — covers FUNC-01, FUNC-02, FUNC-03, VAR-01
- [ ] `tests/test_wasm_exports.mbt` — covers FUNC-04, FUNC-05
- [ ] `tests/test_wasm_memory.mbt` — covers VAR-02, VAR-03

*(If no gaps: "None — existing test infrastructure covers all phase requirements")*

## Sources

### Primary (HIGH confidence)
- WebAssembly Binary Format Specification (W3C) — https://webassembly.github.io/spec/core/binary/
- MoonBit documentation — https://docs.moonbitlang.com

### Secondary (MEDIUM confidence)
- Existing codegen.mbt patterns from this project

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - WebAssembly spec is stable and well-documented
- Architecture: HIGH - Patterns derived from existing codebase
- Pitfalls: MEDIUM - Common WASM pitfalls known but need validation

**Research date:** 2026-03-25
**Valid until:** 2026-04-25