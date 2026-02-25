---
phase: 01-map-support
verified: 2026-02-24T20:30:00Z
status: gaps_found
score: 0/4 must-haves verified
re_verification: false

gaps:
  - truth: "User can create a map using literal syntax {\"key\": value} and compile without errors"
    status: partial
    reason: "Parser and type checker work, but code generation is stubbed to return 0"
    artifacts:
      - path: "codegen.mbt"
        issue: "MapLit returns 0 instead of allocating map structure"
      - path: "examples/mbt_examples/008_basic_map.exe"
        issue: "Compilation hangs, no executable produced"
    missing:
      - "Real map data structure allocation in codegen"
      - "Map runtime functions (map_new, map_insert, map_get)"

  - truth: "User can access map value using key syntax map[\"key\"] and receive the correct value"
    status: failed
    reason: "Codegen always returns 0 for map index access instead of looking up the key"
    artifacts:
      - path: "codegen.mbt"
        issue: "IndexExpr for maps returns 0 unconditionally (line ~3869)"
    missing:
      - "map_get function implementation for key lookup"

  - truth: "User can update map value using assignment map[\"key\"] = new_value"
    status: failed
    reason: "Assign with IndexExpr target doesn't check if target is a map vs array"
    artifacts:
      - path: "codegen.mbt"
        issue: "Assign handler treats all IndexExpr as array access (line ~4540)"
    missing:
      - "Check if target is TMap vs TArray"
      - "map_insert function call for map updates"

  - truth: "Map operations (creation, access, update) don't cause segfaults at runtime"
    status: failed
    reason: "Cannot verify - compilation hangs and no executable is produced"
    artifacts:
      - path: "compiler.mbt"
        issue: "Compilation appears to hang/take extremely long"
    missing:
      - "Working compilation that produces executable"
      - "Runtime test execution"
---

# Phase 1: Map Support Verification Report

**Phase Goal:** Users can create maps with literal syntax, access values by key, update values, and use maps without crashes.
**Verified:** 2026-02-24
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #   | Truth   | Status     | Evidence       |
| --- | ------- | ---------- | -------------- |
| 1   | User can create a map using literal syntax {"key": value} and compile without errors | ⚠️ PARTIAL | Parser accepts MapLit ✓, type checker infers TMap ✓, but codegen returns 0 ✗ |
| 2   | User can access map value using key syntax map["key"] and receive the correct value | ✗ FAILED | Codegen returns 0 unconditionally (line 3869: `g.emit_inst(Mov(Reg64("rax"), Imm32(0)))`) |
| 3   | User can update map value using assignment map["key"] = new_value | ✗ FAILED | Assign handler doesn't distinguish map vs array IndexExpr |
| 4   | Map operations don't cause segfaults at runtime | ✗ FAILED | Cannot verify - compilation hangs, no executable produced |

**Score:** 0/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `parser.mbt` | MapLit AST variant | ✓ VERIFIED | MapLit at line 28, parsing at line 377 |
| `type_checker.mbt` | TMap type | ✓ VERIFIED | TMap(Type, Type) at line 12, equality at line 51, MapLit handling at line 591 |
| `codegen.mbt` | Map operations | ✗ STUB | MapLit returns 0 (line 3846), IndexExpr returns 0 (line 3869) |
| `examples/mbt_examples/008_basic_map.exe` | Working compiled example | ✗ MISSING | File doesn't exist, compilation hangs |

### Key Link Verification

| From | To  | Via | Status | Details |
| ---- | --- | --- | ------ | ------- |
| parser.mbt | type_checker.mbt | MapLit AST node | ✓ WIRED | MapLit handled at type_checker.mbt:591 |
| type_checker.mbt | codegen.mbt | TMap type | ✓ WIRED | TMap handled in codegen (detects is_map) |
| codegen.mbt | runtime | syscalls for memory | ✗ NOT_WIRED | No map_hash, map_lookup, map_insert functions exist |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ---------- | ----------- | ------ | -------- |
| MAP-01 | Phase 1 | User can create map with literal syntax `{"key": value}` | ⚠️ PARTIAL | Parser/type checker OK, codegen returns 0 |
| MAP-02 | Phase 1 | User can access map value via key `map["key"]` | ✗ BLOCKED | Codegen always returns 0 |
| MAP-03 | Phase 1 | User can update map value `map["key"] = value` | ✗ BLOCKED | No map-specific assignment handling |
| MAP-04 | Phase 1 | Map operations don't segfault | ✗ BLOCKED | Can't compile/run to test |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| codegen.mbt | 3843-3847 | `MapLit` returns 0, comment says "simplified implementation: return 0" | 🛑 Blocker | Map creation broken |
| codegen.mbt | 3868-3870 | Map index returns 0, comment says "For map access, just return 0" | 🛑 Blocker | Map access always returns wrong value |
| codegen.mbt | 4540-4560 | Assign handles IndexExpr but doesn't distinguish map vs array | 🛑 Blocker | Map updates broken |
| compiler.mbt | all | Compilation appears to hang for map examples | 🛑 Blocker | Can't verify runtime behavior |

### Gaps Summary

The phase goal is NOT achieved. While parser and type checker correctly implement map syntax support, the code generation is completely stubbed:

1. **Map creation (MAP-01 partial):** `MapLit` codegen just returns 0 (null pointer), no actual map allocation
2. **Map access (MAP-02):** `IndexExpr` for maps returns 0 instead of looking up the key
3. **Map update (MAP-03):** `Assign` to `IndexExpr` treats all targets as arrays, not maps
4. **Runtime safety (MAP-04):** Cannot verify because compilation hangs

**Root cause:** Codegen has no actual map data structure implementation - no hash table, no bucket array, no map runtime functions.

---

_Verified: 2026-02-24_
_Verifier: Claude (gsd-verifier)_
