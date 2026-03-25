# Phase 2: Basic Language Features - Context

**Gathered:** 2026-03-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Support basic arithmetic operations (i32, i64, f32, f64) and control flow (if/else, loops, branching, early returns) in the WebAssembly backend. This phase does not include function calls, variables, or advanced features.

</domain>

<decisions>
## Implementation Decisions

### Auto Mode
- No specific implementation decisions were discussed due to auto-advance mode.
- Claude has full discretion on implementation details within the phase boundary.

### Claude's Discretion
- Mapping of MoonBit arithmetic operators to WASM instructions (e.g., signed vs unsigned division)
- Exact representation of control flow structures (block types, label nesting)
- Error handling for unsupported constructs (e.g., division by zero)
- Optimization strategies (if any) for arithmetic and control flow
- Testing approach (unit tests, integration tests, example programs)

</decisions>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 02-basic-language-features*
*Context gathered: 2026-03-25*