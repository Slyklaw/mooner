# Phase 2: Tuple & Float Improvements - Context

**Gathered:** 2026-02-25
**Status:** Ready for planning

<domain>
## Phase Boundary

CLI commands with correct float handling and representation in output. Official MoonBit compiler compatibility required.

</domain>

<decisions>
## Implementation Decisions

### Float Tuple Printing
 User chose `(1, 2.5)` format - print tuple fields comma-separated, showing actual float values in parentheses. Matches MoonBit's official format. Example: `println((1, 2.5))` prints `1, .5`. Not placeholder format.

### Float Variable Conversion
 User chose `Full Decimal` - should match official compiler. Example: `let x =3.14; println(x)` outputs `3.14`. Not truncated.

### Float Expressions
 User chose `Full Decimal` - example: `println(3.14 +x)` prints decimal representation.

### Claude's Discretion
- Scientific notation format for large/precise floats
 small floats
- - Fixed precision (e.g., `10` decimal places) for standard usage.
 - Error state behavior for invalid float expressions in println?

### Field Access
 Return raw float from tuple storage - no conversion needed.

### Error States
 What should happen if println fails on invalid float expression? Graceful error message? Silent failure?

### Specific Ideas
 None yet - to be determined from testing

## Deferred Ideas
None mentioned - discussion stayed within phase scope.

</deferred>
</domain>

<decisions>
 
</decisions>

<specifics>
## Specific Ideas
None identified yet - await context gathering

<deferred>
## Deferred Ideas
None - discussion stayed within phase scope.

</deferred>
</code>

---

*Phase: 02-tuple-float-improvements*
*Context gathered: 2026-02-25*