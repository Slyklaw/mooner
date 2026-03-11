# Phase 2: Function Calls - Research Analysis

## Overview

The MoonBit compiler generates x86_64 machine code using a self-hosted code generator. Function calls must comply with the System V AMD64 ABI:
- First 6 integer arguments passed in registers: `rdi`, `rsi`, `rdx`, `rcx`, `r8`, `r9`
- Return value in `rax`
- Stack must be 16-byte aligned at call sites
- Callee-saved registers: `rbx`, `rbp`, `r12`–`r15`

The current failure (example 004 returning 80 instead of 42) indicates a bug in the function call/return sequence.

---

## Current Implementation

### Caller Side: `CodeGen::codegen_user_func_call2` (lines 2196–2265)

```moonbit
fn CodeGen::codegen_user_func_call2(
  self : CodeGen,
  func_name : String,
  args : Array[AST],
) -> CodeGen {
  let arg_regs = ["rdi", "rsi", "rdx", "rcx", "r8", "r9"]
  let mut g = self
  let num_args = args.length()
  let mut total_stack_usage = 0

  // Evaluate & push arguments in reverse order
  let mut i = num_args - 1
  while i >= 0 {
    g = g.codegen_expr(args[i])
    g = g.emit_inst(Push(Reg64("rax")))
    // track stack usage (including tuple elements)
    ...
    i = i - 1
  }

  // Pop first 6 arguments into registers
  let mut j = 0
  while j < num_args {
    if j < 6 {
      g = g.emit_inst(Pop(Reg64(arg_regs[j])))
    }
    j = j + 1
  }

  g = g.emit_inst(Call(func_name))

  // Cleanup: remove arguments from stack
  if total_stack_usage > 0 {
    g = g.emit_inst(Add(Reg64("rsp"), Imm32(total_stack_usage)))
  }
  g
}
```

**Observations:**
- Arguments are evaluated and pushed onto the stack in reverse order.
- The first six are then popped off into the correct registers.
- The `total_stack_usage` variable accumulates 8 bytes per argument (plus tuple element sizes).
- After the `call`, the code adds `total_stack_usage` to `rsp`.

### Callee Side: `CodeGen::codegen_func` (lines 8208–8325)

```moonbit
fn CodeGen::codegen_func(
  self : CodeGen,
  name : String,
  params : Array[(String, AST?)],
  body : AST,
) -> CodeGen {
  let arg_regs = ["rdi", "rsi", "rdx", "rcx", "r8", "r9"]
  let mut g = self
  g = g.define_label("{name}")

  // Prologue: save callee-saved registers and set up frame
  g = g.emit_inst(Push(Reg64("rbp")))
  g = g.emit_inst(Mov(Reg64("rbp"), Reg64("rsp")))
  g = g.emit_inst(Push(Reg64("rbx")))
  g = g.emit_inst(Push(Reg64("r12")))
  g = g.emit_inst(Push(Reg64("r13")))
  g = g.emit_inst(Push(Reg64("r14")))
  g = g.emit_inst(Push(Reg64("r15")))

  let saved_regs_size = 6 * 8   // rbp, rbx, r12, r13, r14, r15
  g = { ..g, var_offsets: Map::new(), next_offset: -saved_regs_size }

  // Push incoming register parameters onto the stack for easy addressing
  let mut i = 0
  while i < params.length() {
    if i < 6 {
      g = g.emit_inst(Push(Reg64(arg_regs[i])))
    }
    i = i + 1
  }

  // Record offsets for each parameter
  let mut j = 0
  while j < params.length() {
    let (param_name, param_type) = params[j]
    if j < 6 {
      let offset = -saved_regs_size - (j + 1) * 8   // <-- BUG
      g.var_offsets[param_name] = offset
    }
    ...
    j = j + 1
  }

  g = { ..g, next_offset: -saved_regs_size - params.length() * 8 - 8 }
  g = g.codegen_expr(body)

  // Epilogue: restore registers and return
  g = g.emit_inst(Mov(Reg64("r15"), StackBP64(-40)))
  g = g.emit_inst(Mov(Reg64("r14"), StackBP64(-32)))
  g = g.emit_inst(Mov(Reg64("r13"), StackBP64(-24)))
  g = g.emit_inst(Mov(Reg64("r12"), StackBP64(-16)))
  g = g.emit_inst(Mov(Reg64("rbx"), StackBP64(-8)))
  g = g.emit_inst(Mov(Reg64("rsp"), Reg64("rbp")))
  g = g.emit_inst(Pop(Reg64("rbp")))
  g = g.emit_inst(Ret)
  g
}
```

**Key Steps:**
1. Save `rbp` and set frame pointer.
2. Save callee-saved registers (`rbx`, `r12`–`r15`).
3. Push incoming register arguments onto the stack to create a stable stack frame.
4. Assign fixed offsets (relative to `rbp`) for each parameter.
5. Generate code for the function body.
6. Restore callee-saved registers, reset `rsp` to `rbp`, pop `rbp`, and `ret`.

---

## Root Cause Analysis

### 1. Parameter Offset Miscalculation (Critical)

**Location:** `codegen_func`, line 8253

```moonbit
let offset = -saved_regs_size - (j + 1) * 8
```

**What it does:**  
The code intends to compute the offset of parameter `j` (0-indexed) from `rbp`. After pushing callee-saved registers and then the parameters:
- The first parameter (`j = 0`) is stored at `rbp - 48` (since `saved_regs_size = 48`).
- The second parameter (`j = 1`) is stored at `rbp - 56`, and so on.

**The bug:** The formula uses `(j + 1)` instead of `j`. This shifts all offsets by an extra `-8` bytes:
- Expected offset for `j = 0`: `-48` → actual computed: `-56`
- Expected offset for `j = 1`: `-56` → actual: `-64`
- etc.

**Impact:** When the function body accesses its parameters, it loads from the wrong stack locations. For `add(2, 40)`:
- `x` is read from `rbp-56` (where `y` is stored) → gets `40`.
- `y` is read from `rbp-64` (uninitialized/stack garbage) → may also be `40` or another value, yielding `80` instead of `42`.

**Evidence:** The comment at line 8240–8242 explicitly states: *"Record offsets: first param at rbp-48, second at rbp-56, etc."* The code, however, implements `(j + 1)` instead of `j`, contradicting the comment.

### 2. Stack Cleanup Overrun (Secondary)

**Location:** `codegen_user_func_call2`, lines 2259–2262

The caller accumulates `total_stack_usage` for **all** arguments (including those passed in registers). After the `call`, it always adds this total to `rsp`.

**Problem:** For calls with ≤6 arguments, the caller already popped the register arguments off the stack. The net stack change from pushes/pops is zero. Adding `total_stack_usage` (which equals 8 × number of arguments) would move `rsp` too far upward, corrupting the stack.

**Correct behavior:** Only arguments that remain on the stack (those with index ≥ 6) should be cleaned. The cleanup amount should be `8 × max(num_args - 6, 0)`.

**Why it still crashes later:** This bug may not affect the immediate return value of `add` (since corruption occurs after the call), but it will break subsequent code, especially for functions with many arguments or when multiple calls are made. It must be fixed for full ABI compliance.

---

## Debugging Strategy

1. **Enable instruction tracing** (`--debug-codegen`) to view the generated assembly. Compare the output for `004_basic_function.mbt` with a known-correct reference (e.g., the official MoonBit compiler).

2. **Inspect the prologue of `add`**:
   - Look for `push rbp`, `mov rbp, rsp`, saves of `rbx`/`r12`–`r15`.
   - Verify that the first parameter is stored at `[rbp-48]` and the second at `[rbp-56]`. If you see `[rbp-56]` and `[rbp-64]`, the offset calculation is wrong.

3. **Examine the call sequence** in `main`:
   - Ensure arguments are moved into `rdi` and `rsi` correctly.
   - Verify that after `call add`, `rsp` is *not* adjusted when `num_args <= 6` (no `add rsp, ...` should appear for this example).

4. **Run the minimal test** (`004_minimal.mbt`) with a debugger or by inserting a breakpoint to check the value in `rax` immediately after the `call`.

---

## Code Locations to Examine

- **`codegen.mbt:8208–8325`** – `CodeGen::codegen_func` (callee prologue, parameter pushing, offset assignment, epilogue)
- **`codegen.mbt:2196–2265`** – `CodeGen::codegen_user_func_call2` (caller argument handling)
- **`codegen.mbt:492–1815`** – `CodeGen::emit_inst` (instruction emission for `Call`, `Push`, `Pop`, `Mov`, `Add`, etc.)
- **`codegen.mbt:2268+`** – `CodeGen::codegen_expr` (expression code generation; look for `Ident` to see how variable loads use `var_offsets`)

---

## Validation Checklist

After fixing the two bugs, the following must hold:

- ✅ **Example 004** prints `42` (not `80` or any other value).
- ✅ Functions with 1–6 integer arguments return correct results.
- ✅ Functions with >6 arguments work correctly (stack arguments are passed and accessed properly).
- ✅ Callee-saved registers (`rbx`, `r12`–`r15`) retain their values across calls.
- ✅ Stack pointer (`rsp`) is 16-byte aligned immediately before any `call` instruction.
- ✅ No `add rsp, ...` appears for calls with ≤6 arguments; for >6 arguments the cleanup matches the number of stack arguments.
- ✅ All previously passing examples (001, 002, 003, 005–008, 010) continue to pass.
- ✅ The generated assembly matches the reference compiler's output for the same source.

---

## Potential Pitfalls & Additional Considerations

- **Stack alignment**: The current code does not explicitly align `rsp` before `call`. With the current prologue (pushes of fixed size), alignment may already hold, but adding/removing pushes for debugging or new features could break it. Consider adding explicit alignment if needed.
- **Tuple arguments**: Tuple arguments are passed as pointers; the code tracks tuple element types for later handling. Ensure that offset calculations for tuple fields (if any) are consistent.
- **Variadic functions**: Not in current scope, but the ABI requires special handling (e.g., `al` register for number of vector registers used). Avoid breaking variadic calls if they are added later.
- **Register usage**: The caller uses `rcx` as a temporary in the binary expression code; this is a caller-saved register per ABI, so it’s safe.
- **Syscall calling convention**: The code uses `syscall` with `rdi`=1, `rsi`=buf, `rdx`=len. That matches Linux x86_64.

---

## Recommended Fixes

### 1. Fix parameter offset in `codegen_func` (line 8253):

```moonbit
// Old (buggy):
let offset = -saved_regs_size - (j + 1) * 8

// Correct:
let offset = -saved_regs_size - j * 8
```

### 2. Fix stack cleanup in `codegen_user_func_call2`:
Track only the bytes for arguments that remain on the stack after popping the register arguments.

```moonbit
// Replace total_stack_usage logic:
let mut stack_args_bytes = 0
// ... after popping:
if num_args > 6 {
  stack_args_bytes = (num_args - 6) * 8   // plus any tuple element adjustments if needed
}
if stack_args_bytes > 0 {
  g = g.emit_inst(Add(Reg64("rsp"), Imm32(stack_args_bytes)))
}
```

(Note: Tuple arguments already have special handling; ensure that the cleanup correctly accounts for any stack space used by tuple elements that were not popped.)

---

By addressing these issues, the compiler will correctly implement the System V AMD64 ABI for function calls, resolving the immediate failure in example 004 and establishing a solid foundation for more complex calling scenarios.
