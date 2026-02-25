---
phase: 01-map-support
verified: 2026-02-24T21:00:00Z
status: gaps_found
score: 0/4 must-haves verified
re_verification: true
  previous_status: gaps_found
  previous_score: 0/4
  gaps_closed: []
  gaps_remaining:
    - "User can create a map using literal syntax {\"key\": value} and compile without errors"
    - "User can access map value using key syntax map[\"key\"] and receive the correct value"
    - "User can update map value using assignment map[\"key\"] = new_value"
    - "Map operations (creation, access, update) don't cause segfaults at runtime"
  regressions: []

gaps:
  - truth: "User can create a map using literal syntax {\"key\": value} and compile without errors"
    status: failed
    reason: "MapLit codegen still returns 0 (null pointer) - no actual map allocation implemented"
    artifacts:
      - path: "codegen.mbt"
        issue: "Lines 3841-3847: MapLit returns 0 with comment 'Simplified implementation: return 0'"
      - path: "codegen.mbt"
        issue: "No map_new, map_insert runtime functions found in codebase"
    missing:
      - "map_new runtime function to allocate map structure"
      - "map_insert calls in MapLit handler to populate map entries"

  - truth: "User can access map value using key syntax map[\"key\"] and receive the correct value"
    status: failed
    reason: "IndexExpr for maps returns 0 unconditionally instead of calling map_get"
    artifacts:
      - path: "codegen.mbt"
        issue: "Lines 3868-3870: Map access returns 0 with comment 'For map access, just return 0'"
      - path: "codegen.mbt"
        issue: "No map_get function exists in codebase (grep found no matches)"
    missing:
      - "map_get runtime function for key lookup"
      - "IndexExpr handler to call map_get when is_map is true"

  - truth: "User can update map value using assignment map[\"key\"] = new_value"
    status: failed
    reason: "Assign handler treats all IndexExpr as array access, doesn't distinguish map vs array"
    artifacts:
      - path: "codegen.mbt"
        issue: "Lines 4540-4560: Assign handler only handles array element assignment, no map check"
      - path: "codegen.mbt"
        issue: "No is_map_expr call in Assign handler for IndexExpr target"
    missing:
      - "Check if target is TMap vs TArray in Assign handler"
      - "map_insert function call for map updates"

  - truth: "Map operations (creation, access, update) don't cause segfaults at runtime"
    status: failed
    reason: "Compilation hangs when trying to compile 008_basic_map.mbt - no executable produced"
    artifacts:
      - path: "cmd/main"
        issue: "Compilation timeout after 30 seconds, no output .exe file"
      - path: "examples/mbt_examples/008_basic_map.exe"
        issue: "File does not exist - compilation did not complete"
    missing:
      - "Working compilation that produces executable"
      - "Runtime test to verify no segfaults"
---

# Phase 1: Map Support Re-Verification Report

**Phase Goal:** Users can create maps with literal syntax, access values by key, update values, and use maps without crashes.
**Verified:** 2026-02-24
**Status:** gaps_found
**Re-verification:** Yes — after gap closure attempt

## Goal Achievement

### Observable Truths

| #   | Truth   | Status     | Evidence       |
| --- | ------- | ---------- | -------------- |
| 1   | User can create a map using literal syntax {"key": value} and compile without errors | ✗ FAILED | codegen.mbt:3841-3847 still returns 0 |
| 2   | User can access map value using key syntax map["key"] and receive the correct value | ✗ FAILED | codegen.mbt:3868-3870 returns 0, no map_get |
| 3   | User can update map value using assignment map["key"] = new_value | ✗ FAILED | codegen.mbt:4540-4560 doesn't check is_map |
| 4   | Map operations don't cause segfaults at runtime | ✗ FAILED | Compilation hangs, no exe produced |

**Score:** 0/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `codegen.mbt` | map_new function | ✗ MISSING | grep found no "map_new" in codebase |
| `codegen.mbt` | map_get function | ✗ MISSING | grep found no "map_get" in codebase |
| `codegen.mbt` | map_insert function | ✗ MISSING | grep found no "map_insert" in codebase |
| `codegen.mbt` | .Lmap_ runtime buffers | ✗ MISSING | grep found no ".Lmap_" in codebase |

### Key Link Verification

| From | To  | Via | Status | Details |
| ---- | --- | --- | ------ | ------- |
| codegen.mbt MapLit | runtime buffer | map allocation | ✗ NOT_WIRED | Returns 0, no allocation |
| codegen.mbt IndexExpr | map_get | runtime call | ✗ NOT_WIRED | Returns 0, no function call |
| codegen.mbt Assign | map_insert | type check + runtime | ✗ NOT_WIRED | No map check, no function call |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ---------- | ----------- | ------ | -------- |
| MAP-01 | 01-02-PLAN | User can create map with literal syntax | ✗ BLOCKED | Codegen still stubbed |
| MAP-02 | 01-02-PLAN | User can access map value via key | ✗ BLOCKED | Codegen returns 0 |
| MAP-03 | 01-02-PLAN | User can update map value | ✗ BLOCKED | No map-specific handling |
| MAP-04 | 01-02-PLAN | Map operations don't segfault | ✗ BLOCKED | Can't compile to test |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| codegen.mbt | 3843-3847 | MapLit returns 0, comment "Simplified implementation: return 0" | 🛑 Blocker | Map creation broken |
| codegen.mbt | 3868-3870 | Map index returns 0, comment "For map access, just return 0" | 🛑 Blocker | Map access broken |
| codegen.mbt | 4540-4560 | Assign handles IndexExpr but doesn't check map vs array | 🛑 Blocker | Map updates broken |
| .planning/REQUIREMENTS.md | 10-13 | Requirements marked [x] complete | ⚠️ Warning | Document claims completion but code is stubbed |

### Gaps Summary

The gap closure attempt did NOT close any gaps. The implementation remains stubbed:

1. **Map creation (MAP-01):** codegen.mbt still returns 0 for MapLit - no map_new implemented
2. **Map access (MAP-02):** IndexExpr for maps still returns 0 - no map_get implemented  
3. **Map update (MAP-03):** Assign handler still treats all IndexExpr as arrays - no map_insert, no is_map check
4. **Runtime safety (MAP-04):** Compilation still hangs when trying to compile map examples

**Root cause:** The plan (01-02-PLAN.md) was not executed. The summary (01-02-SUMMARY.md) shows only stubs were added, and it explicitly documents "patterns-established: - Map literal returns 0 (stub)". The gap closure attempted to add stubs but did not implement the actual runtime functions.

**CRITICAL ISSUE:** REQUIREMENTS.md incorrectly marks MAP-01 through MAP-04 as complete ([x]). This verification report contradicts that claim - the requirements are NOT satisfied.

---

_Verified: 2026-02-24_
_Verifier: Claude (gsd-verifier)_
