# Architecture Research: MoonBit Compiler Bugfix

## System Structure

The MoonBit compiler is a **single-pass code generator** that emits raw x86_64 machine code directly into a buffer, then wraps it in an ELF executable header. It is not a multi-pass optimizer;generation happens in one traversal of the AST.

### High-Level Pipeline

```
Source (.mbt) → Lexer → Tokens → Parser → AST → CodeGen → Machine Code Buffer + Relocations → ELF Wrapper → Executable (.exe)
```

### Component Deep Dive

#### 1. Lexer (`lexer.mbt`)

- Tokenizes input source into `Token` enum (identifiers, literals, keywords, operators)
- Handles string and numeric literals
- Tracks line/column for error reporting (though error handling minimal)
- Output: stream of tokens consumed by parser

**Stability:** Highly stable; no signs of errors. Tokenization appears correct since parsing succeeds.

#### 2. Parser (`parser.mbt`)

- Recursive descent parser (likely)
- Builds AST from tokens
- AST node types: expressions, statements, declarations, functions, modules
- No type checking (MoonBit likely uses Hindley-Milner inference later, but codegen may handle types directly)

**Stability:** Parser likely correct – ASTs are produced and passed to codegen. No parse errors reported on examples.

#### 3. Code Generator (`codegen.mbt`)

**This is where all bugs reside.**

- Maintains a `CodeGen` struct with:
  - Machine code buffer (growing vector of bytes)
  - Label table for forward/backward jumps
  - Symbol table for functions/variables (maybe)
  - Emit position counter

**Key functions:**
- `codegen_func(ast)` – generates code for a function, including prologue/epilogue
- `codegen_expr(expr)` – generates code for expressions, leaves result in rax/stack
- `codegen_stmt(stmt)` – generates control flow, local variable handling
- `codegen_match(expr, arms)` – generates pattern matching dispatch
- `emit_inst(opcode, operands...)` – writes bytes to buffer

**Calling convention:** System V AMD64 ABI (as used on Linux):
- Integer/pointer args: rdi, rsi, rdx, rcx, r8, r9
- Stack args pushed right-to-left (caller cleans)
- Return value in rax (or rdx:rax for 128-bit)
- Callee-saved: rbx, rbp, r12-r15
- Caller-saved: rax, rcx, rdx, rsi, rdi, r8-r11, xmm0-xmm15

**Bug zones:**
- Argument placement for function calls (`codegen_user_func_call2`)
- Return value handling (where callee stores result)
- Jump encoding: `Jcc` uses relative 8-bit or 32-bit displacements; need to compute `disp = target - next_ip`
- Enum layout: tag vs payload storage
- Pattern field offsets: struct layout alignment, packing

#### 4. Compiler (`compiler.mbt`)

- Entry point: reads file, invokes lexer+parser+codegen
- ELF header generation: creates 64-bit ELF with program headers
- Writes machine code into text segment
- Sets entry point to `_start` (or main)
- File permissions: not executable until `chmod +x`

**Stability:** Seems correct; it produces runnable executables (just wrong output/crashes).

#### 5. CLI (`cmd/main/main.mbt`)

- Thin wrapper: `moon run cmd/main <input> [output]`
- Calls compiler module
- Minimal argument handling

**Stability:** Fine.

## Data Flow

1. **Parse phase** produces AST with type information (maybe embedded in nodes).
2. **Codegen phase** walks AST; for each node:
   - Emits machine instructions into a byte buffer
   - Tracks current position (`codegen.pos`)
   - For expressions: result in rax (or xmm0 for floats) or on stack
   - For control flow: emit labels, resolve backpatching
3. **Relocation** likely minimal; all addresses are within code or known symbols (maybe functions external like `println`). The codegen likely emits `call` with placeholder and later patches.
4. **ELF emission**: Write ELF header + program headers + code buffer + any data sections.

## Build Order Implications for Bug Fixes

The codebase is a **single package** (no separate libraries). All changes will be in `codegen.mbt`. However, debugging may require temporary modifications to other files (e.g., adding debug prints in `compiler.mbt` to dump assembly). The fix order should be:

1. **Instrumentation:** Add debug output options to trace codegen per example.
2. **Function Calls:** Fix `codegen_user_func_call2` and return instruction handling.
3. **Control Flow:** Fix `codegen_block` and jump offset calculation in `emit_inst` for Jcc/Jmp.
4. **Enums:** Fix enum construction and match dispatch.
5. **Pattern Matching:** Fix struct pattern field access and branch layout.
6. **Validation:** Ensure full test pass, remove debug code.

## Component Interaction Risks

- **Tight coupling:** `codegen.mbt` is large (~8000 lines) with many helper functions; changes may have ripple effects.
- **Multiple maps:** The codegen uses many separate maps (instruction layouts, register usage, variable positions). Keeping them synchronized is critical.
- **No modular tests:** Each bug fix must be validated against full suite to catch regressions.

## Suggested Abstractions for Safety

- **Encapsulate jump calculation:** Function `jmp_rel(target_label) -> [bytes]` could centralize offset math.
- **Validate stack alignment:** After each function prologue, assert `rsp % 16 == 0`.
- **Add debug mode:** When enabled, emit assembly listing alongside machine code for easier inspection.
- **Isolate ABI logic:** Keep argument/return handling in well-named functions, not scattered.

---
