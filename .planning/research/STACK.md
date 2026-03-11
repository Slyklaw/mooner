# Research Summary: MoonBit Compiler Bugfix

## Domain Context

This is a **compiler code generation bugfix effort** for a MoonBit compiler that targets x86_64 Linux ELF executables. The compiler is implemented in MoonBit itself (self-hosting), with key components:

- `lexer.mbt` - Tokenizer
- `parser.mbt` - Parser producing ASTs
- `codegen.mbt` - x86_64 code generator (primary bug location)
- `compiler.mbt` - Entry point, ELF emission
- `cmd/main/main.mbt` - CLI

The codebase is mature enough to compile basic programs but has 4 critical codegen bugs preventing 13-example test suite from passing.

## Stack

**Language & Implementation:**
- **MoonBit** (self-hosted) – compiler written in the language it compiles
- **Target:** x86_64 System V ABI (Linux ELF)
- **Codegen:** Direct machine code emission via custom `emit_inst` functions

**Testing & Validation:**
- **Reference compiler:** Official MoonBit compiler output as ground truth
- **Test suite:** 13 example programs in `examples/mbt_examples/` with known outputs
- **Verification:** Diff output of our compiled executable vs reference output

**Debugging Tools:**
- Temporary debug prints in `codegen.mbt`
- Assembly/disassembly inspection (if needed)
- `moon test` and `moon build` for quick iteration
- Manual execution of generated `.exe` files

**What NOT to use:**
- External assembly generators (we emit raw opcodes)
- GDB (though could be useful for segfaults)
- New runtime libraries (out of scope)

## Features (Bug Fix Categories)

### Table Stakes (Must Fix)

1. **Function Call Convention (COMP-01)**
   - Proper argument passing in registers (rdi, rsi, rdx, rcx, r8, r9)
   - Stack handling for >6 arguments
   - Return value placement (rax for integers)
   - Callee/caller-saved register preservation

2. **Control Flow (COMP-02)**
   - Conditional branches (Jcc) with correct relative offsets
   - Loop constructs (`for`, `while`) with proper jump targets
   - Block scoping and stack management
   - Label resolution without corruption

3. **Enum Discriminants (COMP-03)**
   - Correct variant tag values in memory
   - Pattern matching discriminates based on tag
   - No variant duplication in match arms

4. **Pattern Matching (COMP-04)**
   - Struct field offsets in patterns
   - Branch memory layout without stack corruption
   - Nested pattern handling
   - Variable binding in patterns

5. **Complete Test Coverage (COMP-05)**
   - All 13 examples produce reference-accurate output
   - No segfaults
   - Acceptable float precision deviation (example 007)

### Differentiators (Out of Scope for v1)

- Runtime library expansion (example 012)
- Performance optimizations
- New language features
- Float precision improvements

### Anti-Features

- Adding runtime support (would violate bugfix-only scope)
- Parser changes (parser likely correct)
- Changing ABI (must match reference compiler)

## Architecture

### Components & Boundaries

```
┌─────────────────┐
│  cmd/main       │ CLI entry point
│  main.mbt       │
└────────┬────────┘
         │ invoke
┌────────▼────────┐
│  compiler.mbt   │ Orchestration, ELF header, file IO
│                 │ ⇩ parses source, runs lexer/parser
│                 │ ⇩ calls codegen, writes executable
└────────┬────────┘
         │ uses
┌────────▼───────────────────────────┐
│  lexer.mbt                         │
│  - Token enum                      │
│  - Lexer struct                    │
│  - lexing functions                │
└────────┬───────────────────────────┘
         │ produces tokens
┌────────▼───────────────────────────┐
│  parser.mbt                        │
│  - AST enum                        │
│  - Parser struct                   │
│  - expression/statement parsing   │
└────────┬───────────────────────────┘
         │ produces AST
┌────────▼───────────────────────────┐
│  codegen.mbt                       │
│  - CodeGen struct                  │
│  - x86_64 instruction types        │
│  - code generation functions       │
│  - emit_inst (machine code output)│
└───────────────────────────────────┘
```

### Data Flow

1. Source file → `lexer` → token stream
2. Token stream → `parser` → AST
3. AST → `codegen` → x86_64 machine code buffer + relocations
4. Machine code + ELF headers → `compiler` → `.exe` file

### Suggested Build Order (Bug Fix Phases)

1. **Setup & Investigation** – Understand codegen internals, add debug tracing
2. **Function Calls** – Fix calling convention and return handling
3. **Control Flow** – Fix jump offsets and label resolution
4. **Enums** – Fix discriminant storage and pattern matching
5. **Pattern Matching** – Fix struct patterns and nested matches
6. **Validation** – Full test suite, ensure no regressions

## Pitfalls

### Pitfall 1: Misinterpreting Stack Frame Layout

**Warning signs:** Return values appear corrupted; function arguments affect unrelated data; debug traces show inconsistent offsets.

**How to avoid:** Map out exactly where parameters and locals live relative to `rbp` (e.g., `rbp-48`, `rbp-56`). Verify with minimal examples: single-arg function returns constant.

**Phase addressing:** Phase 2 (Function Calls)

### Pitfall 2: Incorrect Relative Jump Offsets

**Warning signs:** Segfaults immediately on entering `if`/`for` blocks; program counter jumps to nonsense; output order wrong.

**How to avoid:** Compute `offset = target_label - current_position - instruction_size`. Test with single `jmp` to known label.

**Phase addressing:** Phase 3 (Control Flow)

### Pitfall 3: Enum Tag Confusion

**Warning signs:** Pattern match hits wrong variant; all variants appear equal; variant order messed up.

**How to avoid:** Ensure each enum variant gets a unique discriminant (0,1,2...). Check construction: the tag must be stored with the payload (or in a separate slot) consistently.

**Phase addressing:** Phase 4 (Enums)

### Pitfall 4: Pattern Branch Stack Corruption

**Warning signs:** Variables in one branch affect others; crashes when multiple match arms exist; garbage values for bound variables.

**How to avoid:** Ensure each branch has its own stack frame layout; field offsets computed correctly for struct patterns; no overlapping spill slots.

**Phase addressing:** Phase 5 (Pattern Matching)

### Pitfall 5: Fixing One Bug Breaking Another

**Warning signs:** After fix, previously passing examples start failing.

**How to avoid:** After each fix, run full test suite immediately. Commit frequently with atomic changes.

**Phase addressing:** All phases (continuous)

---
