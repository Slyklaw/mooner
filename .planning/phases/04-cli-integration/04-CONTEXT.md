# Phase 4: CLI Integration - Context

**Gathered:** 2026-03-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Integrate WASM backend into the existing CLI, adding --target flag, auto-detecting output format based on file extension, maintaining backward compatibility with x86_64 backend, and ensuring output files have proper permissions.

</domain>

<decisions>
## Implementation Decisions

### Auto Mode
- No specific implementation decisions were discussed due to auto-advance mode.
- Claude has full discretion on implementation details within the phase boundary.

### Claude's Discretion
- Flag parsing implementation (--target vs --format)
- Output file permission handling
- Auto-detection logic for .wasm vs .exe extensions
- Error handling for unsupported targets
- Backward compatibility approach

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

*Phase: 04-cli-integration*
*Context gathered: 2026-03-25*