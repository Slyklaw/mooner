# Requirements: MoonBit Compiler

**Defined:** 2026-03-11
**Core Value:** The compiler generates correct, executable output for all language features covered by the test suite. If everything else fails, the examples must pass.
**Milestone:** v1.0 – Codegen bugfix to pass 13 examples

## v1 Requirements

### Code Generation

- [x] **COMP-01**: Function calls with arguments return correct values (fix example 004)
- [x] **COMP-02**: Control flow constructs (if, for, while) execute without crashes (fix example 009)
- [ ] **COMP-03**: Enum pattern matching discriminates variants correctly (fix example 011)
- [ ] **COMP-04**: Pattern matching on structured data (structs, nested patterns) works without crashes (fix example 013)
- [ ] **COMP-05**: All 13 examples pass verification against reference outputs (with 012 as expected failure, 007 float precision acceptable)

## v2 Requirements

(D deferred to future milestone – none in this scope)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Runtime library support | Example 012 requires test framework runtime – out of scope for codegen bugfix |
| New language features | Scope is bug fixes only; no feature expansion |
| Float precision improvements | Example 007's minor degradation is acceptable |
| Performance optimizations | Correctness over speed |
| Parser/lexer changes | Parser appears correct; failures are codegen issues |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| COMP-01 | Phase 2 | Complete |
| COMP-02 | Phase 3 | Complete |
| COMP-03 | Phase 4 | Pending |
| COMP-04 | Phase 5 | Pending |
| COMP-05 | Phase 6 | Pending |

**Coverage:**
- v1 requirements: 5 total
- Mapped to phases: 5
- Unmapped: 0 ✓

---
