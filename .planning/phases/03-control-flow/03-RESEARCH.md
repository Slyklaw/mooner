<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Jump offset calculation: Use instruction-type aware offset: each pending label fixup stores the instruction length (5 bytes for jmp/call, 6 bytes for conditional jumps). Compute offset as `target_pos - (ref_pos + instruction_length)`.
- Label namespace isolation: Prefix labels with function-specific identifier (e.g., `.Lfn{func_idx}_{label_id}`) to avoid collisions across functions. Maintain a per-function label counter.
- Invalid break/continue handling: Emit compile-time error: "break/continue not inside loop" when such statements appear outside any loop context. Detection during codegen (not parser).
- For-in loop edge cases: Empty array: loop body is skipped entirely; condition check ensures zero iterations; registers restored correctly. No special code needed; rely on existing condition evaluation.
- Label resolution failure: During fixup pass, if a referenced label is not found, panic with a clear error: "undefined label: {label_name}". Fail fast to catch missing label definitions.

### Claude's Discretion
- Branch instruction alignment (padding) for performance (if needed).
- Exact wording of error messages.
- Handling of nested break/continue (resolving to innermost enclosing loop) — as long as it works correctly.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| COMP-02 | Control flow constructs (if, for, while) execute without crashes (fix example 009) | The fixes address root causes: incorrect jump offsets, label collisions, missing break/continue validation, and undefined label errors. Implementation follows x86_64 System V ABI relative jump encoding. |
</phase_requirements>

# Phase 3: Control Flow - Research

**Researched:** 2026-03-11
**Domain:** x86_64 assembly code generation, relative jump encoding, label management
**Confidence:** HIGH

## Summary

This phase resolves critical code generation bugs in control flow constructs that cause example 009 to segfault. The issues are in the label handling subsystem of `codegen.mbt`: pending label offsets are computed without instruction-type awareness, labels are globally scoped causing collisions, and break/continue statements lack proper error handling. The fix involves updating the `CodeGen` struct to track instruction lengths for each pending label, enforce function-specific label namespaces, add compile-time validation for break/continue, and make label resolution errors explicit. These changes are confined to the code generator and align with the existing architecture.

**Primary recommendation:** Modify the label emission and fixup logic to be instruction-aware; add per-function label isolation; add runtime checks for break/continue; and replace silent label resolution failures with clear panics.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| MoonBit compiler codebase | current | Code generation for x86_64 ELF | Existing architecture; modifications confined to codegen.mbt |

### Supporting
No external libraries required.

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Storing instruction length in pending_labels | Calculating length from opcode at fixup time | Requires reading code bytes at fixup; storing length is simpler and consistent with design |
| Global label counter with function prefix | Separate label maps per function | Simpler to implement single map with prefixed names |

## Architecture Patterns

### Recommended Project Structure
The code generator is a single module (`codegen.mbt`). Changes should be localized to label management and jump emission.

### Pattern 1: Pending fixup with metadata
Store additional metadata (instruction length) for each pending label to enable correct offset calculation regardless of instruction size.

### Pattern 2: Function-scoped label generation
Prefix all automatically generated labels with a function-unique identifier to avoid cross-function collisions.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Manual offset computation | Custom ad-hoc math | Formula `target - (start + length)` based on actual instruction size | Ensures correct relative jumps per x86_64 spec |
| Global label namespace | Unique labels via random strings | Deterministic function-prefixed labels | Reproducible, debuggable, collision-free |

## Common Pitfalls

### Pitfall 1: Assuming all jumps have same size
**What goes wrong:** Uniform offset formula ignores that conditional jumps are 6 bytes total vs 5 for unconditional jumps, leading to misaligned branch targets.
**Why it happens:** The current code adds 4 to reference position regardless of instruction size, but if reference position is the start of instruction, the next instruction address differs.
**How to avoid:** Explicitly store and use instruction length in fixup.

### Pitfall 2: Label name collisions across functions
**What goes wrong:** Multiple functions define `.L0`, `.L1` etc., causing jumps to target the wrong function's label.
**Why it happens:** Global label counter is shared across functions.
**How to avoid:** Prefix with function index.

### Pitfall 3: Silent undefined label references
**What goes wrong:** If a jump references an undefined label, the placeholder remains 0, causing crashes or misbehavior.
**Why it happens:** The fixup loop does nothing when label not found.
**How to avoid:** Panic with clear error message.

## Code Examples

### Correct offset computation
```c
// x86_64 relative jump: offset = target - (next_instruction)
// next_instruction = start_of_instruction + instruction_length
// where instruction_length = 5 (jmp) or 6 (conditional jmp)
uint32_t offset = (uint32_t)(target_address - (start_address + instr_len));
```

From System V ABI documentation: relative offsets are calculated from the address of the next instruction.

### Function-prefixed label generation
```moonbit
let label_name = ".Lfn" + func_idx.to_string() + "_" + self.label_counter.to_string()
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Uniform offset (+4) | Instruction-aware offset | This phase | Correct jump targets |
| Global `.L` labels | Function-prefixed `.Lfn_` labels | This phase | No collisions |
| Silent label missing | Panic with "undefined label" | This phase | Fail-fast debugging |

**Deprecated/outdated:**
- None within this phase.

## Open Questions

1. **Nested break/continue handling**
   - What we know: `loop_labels` stack tracks enclosing loops.
   - What's unclear: Whether current AST provides break/continue nodes and how they are lowered.
   - Recommendation: Ensure break jumps to end label, continue jumps to loop condition; resolve to innermost loop on stack.

## Validation Architecture

> Nyquist validation not enabled; section omitted.

## Sources

- System V ABI x86_64 supplement (https://refspecs.linuxbase.org/elf/abi/x86_64-/)
- x86_64 instruction encoding reference (https://www.felixcloutier.com/x86/)
- MoonBit compiler codebase (existing codegen.mbt)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - changes confined to codegen.mbt, no external dependencies.
- Architecture: HIGH - design matches x86 ABI and established compiler patterns.
- Pitfalls: HIGH - identified from code analysis and known failure mode.

**Researched:** 2026-03-11
**Valid until:** 30 days (stable domain)
