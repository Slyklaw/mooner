# Requirements: Mooner Compiler

**Defined:** 2026-02-24
**Core Value:** Compile standard MoonBit language to working x86_64 Linux executables that match official MoonBit compiler output.

## v1 Requirements

### Map Support

- [x] **MAP-01**: User can create map with literal syntax `{"key": value}`
- [x] **MAP-02**: User can access map value via key `map["key"]`
- [x] **MAP-03**: User can update map value `map["key"] = value`
- [x] **MAP-04**: Map operations don't segfault

### Tuple Improvements

- [ ] **TUP-01**: Float values in tuples print correctly (not `<tuple>`)
- [ ] **TUP-02**: Mixed type tuples work with println
- [ ] **TUP-03**: Float tuple field access works correctly

### Float Runtime Conversion

- [ ] **FLT-01**: Float variable runtime conversion prints full value (not just integer part)
- [ ] **FLT-02**: `println(float_expr)` outputs correct decimal representation

### Enum Pattern Matching

- [ ] **ENUM-01**: Enum variants with data match correctly `RGB(r, g, b)`
- [ ] **ENUM-02**: Pattern binding extracts data from enum variants
- [ ] **ENUM-03**: Nested enum pattern matching works

### Pattern Matching Enhancements

- [ ] **PAT-01**: Guard expressions work in match `guard x is pattern`
- [ ] **PAT-02**: Destructuring patterns work for tuples and arrays
- [ ] **PAT-03**: Or patterns work `1 | 2 | 3`

### Testing & Derives

- [ ] **TEST-01**: `derive(Show)` generates toString for types

## v2 Requirements

### Advanced Features

- **[LAMBDA]**: Lambda/anonymous functions
- **[GENERICS]**: Generic type parameters
- **[CLOSURES]**: Closure capture and calling

### Optimizations

- **[OPT-01]**: Constant folding
- **[OPT-02]**: Dead code elimination
- **[OPT-03]**: Register allocation improvements

## Out of Scope

| Feature | Reason |
|---------|--------|
| DWARF debug info | Low priority for initial release |
| Complex optimizations | Focus on correctness first |
| Full pattern matching | Basic patterns sufficient for v1 |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| MAP-01 | Phase 1 | Complete |
| MAP-02 | Phase 1 | Complete |
| MAP-03 | Phase 1 | Complete |
| MAP-04 | Phase 1 | Complete |
| TUP-01 | Phase 2 | Pending |
| TUP-02 | Phase 2 | Pending |
| TUP-03 | Phase 2 | Pending |
| FLT-01 | Phase 2 | Pending |
| FLT-02 | Phase 2 | Pending |
| ENUM-01 | Phase 3 | Pending |
| ENUM-02 | Phase 3 | Pending |
| ENUM-03 | Phase 3 | Pending |
| PAT-01 | Phase 3 | Pending |
| PAT-02 | Phase 3 | Pending |
| PAT-03 | Phase 3 | Pending |
| TEST-01 | Phase 4 | Pending |

**Coverage:**
- v1 requirements: 15 total
- Mapped to phases: 15
- Unmapped: 0 ✓

---
*Requirements defined: 2026-02-24*
*Last updated: 2026-02-24 after initial definition*
