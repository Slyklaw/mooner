---
phase: 03-functions-variables
verified: 2026-03-26T17:30:00Z
status: passed
score: 8/8 must-haves verified
re_verification: false
gaps: []
---

# Phase 3: Functions and Variables Verification Report

**Phase Goal:** Support functions and variables in WASM
**Verified:** 2026-03-26T17:30:00Z
**Status:** PASSED
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #   | Truth   | Status     | Evidence       |
| --- | ------- | ---------- | -------------- |
| 1   | Function signatures are represented as WASM type entries (param count, param types, result count, result types) | ✓ VERIFIED | `wasm/type.mbt` contains `TypeSectionWriter::add_func()` encoding form 0x60 with LEB128 counts |
| 2   | Local variables are allocated indices: parameters first (0..n-1), then locals (n..n+m-1) | ✓ VERIFIED | `wasm/local.mbt` contains `LocalAllocator::alloc_param()` then `alloc_local()` following exact spec |
| 3   | Local variable get/set instructions encode correct index | ✓ VERIFIED | `wasm/instruction.mbt` contains `GetLocal(Int)` and `SetLocal(Int)` variants with LEB128 (0x20, 0x21) |
| 4   | MoonBit function declarations map to WASM function signatures | ✓ VERIFIED | `wasm_backend.mbt` contains `WasmModuleBuilder::add_function_type()` tracking type indices |
| 5   | Function calls emit call instruction with correct function index | ✓ VERIFIED | `wasm/instruction.mbt` contains `Call(Int)` instruction (opcode 0x10) with LEB128 func_idx |
| 6   | Export section entries map function indices to export names | ✓ VERIFIED | `wasm/export.mbt` contains `ExportSectionWriter::add_func_export()` encoding name + kind + index |
| 7   | Import section entries define external function signatures | ✓ VERIFIED | `wasm/import.mbt` contains `ImportSectionWriter::add_func_import()` with module + field + type_idx |
| 8   | Global variables are allocated in WASM global section with mutability flag | ✓ VERIFIED | `wasm/global.mbt` contains `GlobalSectionWriter::add_global()` with `GlobalType` (content_type + mutability) |

**Score:** 8/8 truths verified

### Required Artifacts

| Artifact | Expected    | Status | Details |
| -------- | ----------- | ------ | ------- |
| `wasm/type.mbt` | TypeSectionWriter for function signatures | ✓ VERIFIED | Contains `add_func()`, `encode()`, uses LEB128 for counts |
| `wasm/local.mbt` | LocalAllocator for variable indices | ✓ VERIFIED | Contains `alloc_param()`, `alloc_local()`, `encode_locals()` |
| `wasm/instruction.mbt` | WASM instruction encoding | ✓ VERIFIED | Contains `Instruction` enum with all needed variants, helper functions |
| `wasm/export.mbt` | ExportSectionWriter | ✓ VERIFIED | Contains `add_func_export()`, `encode()`, UTF-8 names |
| `wasm/import.mbt` | ImportSectionWriter | ✓ VERIFIED | Contains `add_func_import()`, `encode()`, returns import_idx |
| `wasm/global.mbt` | GlobalSectionWriter | ✓ VERIFIED | Contains `add_global()`, `add_global_i32()`, mutability flag support |
| `wasm_backend.mbt` | WasmModuleBuilder | ✓ VERIFIED | Complete module generation with proper index handling |

### Key Link Verification

| From | To  | Via | Status | Details |
| ---- | --- | --- | ------ | ------- |
| TypeSectionWriter | LEB128 encoding | encode_uleb128 | ✓ WIRED | Both in wasm/ use same encoding |
| LocalAllocator | Code generation | wasm_backend.mbt | ✓ WIRED | Tracked for local variable indices |
| Instruction encoding | LEB128 | encode_uleb128 | ✓ WIRED | Used for all indices |
| ExportSection | SectionWriter | encode_with_header | ✓ WIRED | Proper section header added |
| ImportSection | SectionWriter | encode_with_header | ✓ WIRED | Proper section header added |
| Function indices | Import handling | import_idx first | ✓ WIRED | WasmModuleBuilder puts imports at indices 0..N-1 |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ---------- | ----------- | ------ | -------- |
| FUNC-01 | 03-01 | Generate function signatures | ✓ SATISFIED | TypeSectionWriter adds function types to type section |
| FUNC-02 | 03-01 | Emit function bodies with locals | ✓ SATISFIED | LocalAllocator tracks locals, encode_locals() generates declarations |
| FUNC-03 | 03-02 | Support function calls | ✓ SATISFIED | Call instruction (0x10) with func_idx via WasmModuleBuilder |
| FUNC-04 | 03-02 | Support function exports | ✓ SATISFIED | ExportSectionWriter adds func exports with names |
| FUNC-05 | 03-02 | Support function imports | ✓ SATISFIED | ImportSectionWriter adds func imports, import_idx returned |
| VAR-01 | 03-01 | Map local variables to WASM locals | ✓ SATISFIED | LocalAllocator assigns indices 0..param_count-1 then param_count.. |
| VAR-02 | 03-02 | Local variable get/set operations | ✓ SATISFIED | get_local(), set_local() helpers encode correct indices |
| VAR-03 | 03-03 | Support global variables | ✓ SATISFIED | GlobalSectionWriter with mutability flag and init expressions |

All 8 requirements mapped to phase plans are satisfied.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| wasm_backend.mbt | 1396 | `if self.exported_funcs.length() > 0 || true` | ℹ️ Info | Always true condition, but export section is needed |

No blockers found. The `|| true` pattern is a minor code smell but doesn't prevent goal achievement.

### Gaps Summary

No gaps found. All must-haves verified:
- All 8 observable truths verified against actual code
- All 7 required artifacts exist and are substantive (not stubs)
- All key links are wired correctly
- All 8 requirements (FUNC-01 through FUNC-05, VAR-01 through VAR-03) are satisfied

---

_Verified: 2026-03-26T17:30:00Z_
_Verifier: Claude (gsd-verifier)_