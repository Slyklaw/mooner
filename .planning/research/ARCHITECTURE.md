# Architecture Patterns

**Domain:** Compiler backend (WebAssembly)  
**Researched:** 2026-03-25  

## Recommended Architecture

Extend the existing monolithic pipeline with a strategy pattern for code generation.

```
Source → Lexer → Parser → AST → CodeGen (strategy) → Bytecode → Linker (format‑specific) → Output
```

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| Lexer (`lexer.mbt`) | Tokenize source code. | Parser. |
| Parser (`parser.mbt`) | Build AST from tokens. | CodeGen strategies. |
| CodeGen (abstract) | Define interface for emitting target‑specific bytes. | Concrete backends (x86_64, WASM). |
| x86_64 CodeGen (`codegen.mbt`) | Emit x86_64 machine code. | Linker (ELF builder). |
| WASM CodeGen (`wasm_codegen.mbt`) | Emit WASM binary sections. | WASM linker (binary encoder). |
| ELF Linker (`compiler.mbt`) | Assemble ELF executable. | Filesystem. |
| WASM Linker (`wasm_linker.mbt`) | Assemble WASM binary (type, function, code, data sections). | Filesystem. |
| CLI (`cmd/main/main.mbt`) | Parse arguments, select backend. | CodeGen strategies. |

### Data Flow

1. **Source → Tokens:** `lexer.tokenize(source)`.
2. **Tokens → AST:** `parser.parse(tokens)`.
3. **AST → Target Bytes:** `codegen.generate(ast, backend)` where `backend` is either `x86_64` or `wasm`.
4. **Target Bytes → Output File:** `linker.write(bytes, output_path)`.

## Patterns to Follow

### Pattern 1: Strategy Pattern for Backends
**What:** Define a `CodeGen` trait with methods like `emit_function`, `emit_instruction`, etc. Each backend implements the trait.
**When:** Adding multiple backends without duplicating frontend logic.
**Example:**
```moonbit
trait CodeGen {
  fn generate_function(self, func: Function) -> Array[Byte]
}
struct X86CodeGen { ... }
impl CodeGen for X86CodeGen { ... }
struct WasmCodeGen { ... }
impl CodeGen for WasmCodeGen { ... }
```

### Pattern 2: Section‑Based Binary Generation for WASM
**What:** Generate each WASM section (type, function, memory, export, code, data) separately, then concatenate with section IDs and lengths.
**When:** Building WASM binary directly.
**Example:** Write type section, then function section, etc., each preceded by a byte ID and LEB128 length.

## Anti‑Patterns to Avoid

### Anti‑Pattern 1: Monolithic CodeGen for Multiple Backends
**What:** Single codegen module with `if target == x86_64` branches.
**Why bad:** Becomes unmaintainable, violates single‑responsibility.
**Instead:** Separate backend modules behind a common interface.

### Anti‑Pattern 2: Directly Emitting WASM Text Format (WAT)
**What:** Generate WAT string and then convert to binary via external tool.
**Why bad:** Adds external dependency, slower, more complex.
**Instead:** Generate binary directly using byte arrays.

## Scalability Considerations

| Concern | At 100 programs | At 10K programs | At 1M programs |
|---------|-----------------|-----------------|----------------|
| Binary size | Irrelevant | Should be minimal (dead‑code elimination). | Critical; need optimization passes. |
| Compilation speed | Fine | May need incremental compilation. | Must cache IR, parallel backend. |

## Sources

- Existing architecture analysis (.planning/codebase/ARCHITECTURE.md).
- MoonBit textbook stack machine case study — simple backend example.
- WebAssembly binary format specification — section layout.

---
*Architecture research for: WebAssembly compiler backend*
*Researched: 2026-03-25*