# Phase 03: Control Flow - Context

**Gathered:** 2026-03-11  
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix jump offsets and label resolution so control flow constructs (if, for, while) execute without crashes and produce correct branching behavior. Example 009 currently segfaults due to incorrect branch target calculation and possibly label handling. The fix must be confined to codegen.

</domain>

<decisions>
## Implementation Decisions

### Jump offset calculation
- Use instruction-type aware offset: each pending label fixup stores the instruction length (5 bytes for jmp/call, 6 bytes for conditional jumps).
- Compute offset as `target_pos - (ref_pos + instruction_length)`.
- This corrects the bug where a uniform `target_pos - (ref_pos + 4)` causes misaligned branch targets.

### Label namespace isolation
- Prefix labels with function-specific identifier (e.g., `.Lfn{func_idx}_{label_id}`) to avoid collisions across functions.
- Maintain a per-function label counter.

### Invalid break/continue handling
- Emit compile-time error: "break/continue not inside loop" when such statements appear outside any loop context.
- Detection during codegen (not parser).

### For-in loop edge cases
- Empty array: loop body is skipped entirely; condition check ensures zero iterations; registers restored correctly.
- No special code needed; rely on existing condition evaluation.

### Label resolution failure
- During fixup pass, if a referenced label is not found, panic with a clear error: "undefined label: {label_name}".
- Fail fast to catch missing label definitions.

### Claude's Discretion
- Branch instruction alignment (padding) for performance (if needed).
- Exact wording of error messages.
- Handling of nested break/continue (resolving to innermost enclosing loop) — as long as it works correctly.

</decisions>

<specifics>
## Specific Ideas

- Follow System V ABI expectations for branch distances (relative offsets within range of signed 8/32 bits).
- No need to redesign label tracking; incremental adjustments to existing fixup logic.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 03-control-flow*  
*Context gathered: 2026-03-11*
