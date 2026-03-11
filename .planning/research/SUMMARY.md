# Research Synthesis: MoonBit Compiler Bugfix

**Project:** MoonBit Compiler — Self-Hosting Completion  
**Milestone:** v1.0 (Bugfix to pass 13 examples)  
**Date:** 2026-03-11  
**Status:** Research complete (based on existing codebase analysis + targeted synthesis)

---

## Key Findings

### Stack
- **Language:** MoonBit (self-hosted)
- **Target:** x86_64 System V ABI (Linux ELF)
- **Codegen:** Direct machine code emission via `emit_inst`
- **Debugging:** Temporary prints, manual disassembly, diff against reference compiler
- **No external runtime** extensions – out of scope

### Table Stakes Features (All Required)

| Feature | Description | Complexity |
|---------|-------------|------------|
| **Function Call Correctness** | Arguments in correct registers; return in rax; callee-saved preserved | Moderate |
| **Control Flow Execution** | Jcc/Jmp relative offsets; label resolution; no segfaults | Moderate |
| **Enum Pattern Matching** | Unique discriminants; correct variant dispatch | Moderate |
| **General Pattern Matching** | Struct field offsets; branch variable binding; no corruption | Higher |
| **Full Test Pass** | All 13 examples match reference (012/007 special) | Validation gate |

### Architecture Insights

- **Single-pass code generation:** No optimization passes; immediate emission
- **Key bug zone:** `codegen.mbt` (all issues reside here)
- **Data flow:** Lexer → Parser → CodeGen → Machine Code → ELF wrapper
- **Calling convention:** Must be System V compliant (rdi/rsi/rdx/rcx/r8/r9, rax return, aligned stack)
- **Component coupling:** High within codegen; many maps must stay synchronized

### Critical Pitfalls

1. **Stack misalignment** – breaks calls, causes subtle bugs
2. **Return value overwrite** – arguments clobber result
3. **Relative jump miscalculation** – immediate segfaults
4. **Label address backpatching** – jumps to wrong targets
5. **Enum tag duplication** – pattern match stuck on first variant
6. **Pattern branch variable capture** – garbage in bindings
7. **Register clobbering across calls** – live values die
8. **Codegen state mutation** – cross-function contamination
9. **Regression from refactoring** – fix one, break another

---

## Implications for Roadmap

### Phase Structure (Recommended)

1. **Setup & Investigation** – Codegen instrumentation, debug tracing, minimal test cases
2. **Function Calls** – Fix calling convention, return handling, register preservation
3. **Control Flow** – Fix jump offsets, label resolution, stack alignment
4. **Enums** – Fix discriminants and pattern dispatch
5. **Pattern Matching** – Fix struct offsets, branch memory layout
6. **Validation & Polish** – Full test suite, remove debug code, final commit

### Order Justification

- **Functions first:** Many other constructs (control flow bodies, pattern match arms) contain function calls; if calls are broken, everything else is hard to test reliably.
- **Control flow second:** Loops/conditionals needed to iterate over test examples; also needed for more complex pattern matching codegen.
- **Enums before full pattern matching:** Enum patterns are simpler subset; fixes there may inform pattern matching infra.
- **Validation last:** Ensure all examples pass, no regressions.

### Scope Boundaries

- **In scope:** Changes to `codegen.mbt` only. No parser/lexer modifications.
- **Out of scope:** Runtime library (012), new features, performance work.
- **Acceptable:** Minor float precision deviation (007) – don't over-invest.

---

## Risk Assessment

- **High risk:** Control flow bugs cause immediate crashes, blocking progress; must be fixed early.
- **Medium risk:** Enum/pattern bugs may interact; careful isolation needed.
- **Mitigation:** After each fix, run full test suite. Commit atomic changes. Keep debug instrumentation until milestone complete.

---

## Next Steps

1. Confirm roadmap structure reflects these recommendations.
2. Start with Phase 1 (Setup) to add tracing and baseline measurements.
3. Proceed through fix phases in order, validating continuously.

---

*This synthesis combines existing `.planning/codebase/` analysis with focused research on compiler bug-fixing best practices. All recommendations are prescriptive and intended to feed directly into roadmap creation.*
