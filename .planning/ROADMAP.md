# Mooner Compiler Roadmap

## Project Context

**Core Value:** Compile standard MoonBit language to working x86_64 Linux executables that match official MoonBit compiler output.

**Depth:** Comprehensive  
**Total Phases:** 4  
**Total v1 Requirements:** 15

---

## Phases

- [x] **Phase 1: Map Support** - Implement map type with literal syntax, access, and update operations (4 requirements) ✓ COMPLETE
- [ ] **Phase 2: Tuple & Float Improvements** - Fix float runtime conversion and tuple printing (5 requirements)
- [ ] **Phase 3: Enum & Pattern Matching** - Implement advanced pattern matching with data constructors, guards, and destructuring (6 requirements)
- [ ] **Phase 4: Derive(Show) Macro** - Implement derive macro to generate toString for types (1 requirement)

---

## Phase Details

### Phase 1: Map Support

**Goal:** Users can create maps with literal syntax, access values by key, update values, and use maps without crashes.

**Depends on:** Nothing (first phase)

**Requirements:** MAP-01, MAP-02, MAP-03, MAP-04

**Success Criteria** (what must be TRUE):

1. User can create a map using literal syntax `{"key": value}` and compile without errors
2. User can access map value using key syntax `map["key"]` and receive the correct value
3. User can update map value using assignment `map["key"] = new_value`
4. Map operations (creation, access, update) don't cause segfaults at runtime

**Plans:** 2/2 plans (1 original + 1 gap closure)

**Plan list:**
- [x] 01-01-PLAN.md — Map literal syntax, access, and update implementation
- [ ] 01-02-PLAN.md — Gap closure: implement working map runtime

---

### Phase 2: Tuple & Float Improvements

**Goal:** Float values in tuples print correctly, and float runtime conversion outputs full decimal representation.

**Depends on:** Phase 1

**Requirements:** TUP-01, TUP-02, TUP-03, FLT-01, FLT-02

**Success Criteria** (what must be TRUE):

1. Float values inside tuples print their decimal representation (e.g., `(1, 2.5)` prints correctly, not `<tuple>`)
2. Mixed-type tuples with floats work correctly with println
3. Float tuple field access returns correct float value
4. Float variable runtime conversion prints full value (e.g., `let x = 3.14; println(x)` shows "3.14", not "3.0")
5. `println(float_expr)` outputs correct decimal representation for any float expression

**Plans:** TBD

---

### Phase 3: Enum & Pattern Matching

**Goal:** Advanced pattern matching works with enum data constructors, guards, and destructuring patterns.

**Depends on:** Phase 2

**Requirements:** ENUM-01, ENUM-02, ENUM-03, PAT-01, PAT-02, PAT-03

**Success Criteria** (what must be TRUE):

1. Enum variants with data constructors match correctly (e.g., `RGB(r, g, b)` extracts red, green, blue values)
2. Pattern binding extracts data from enum variants into local variables
3. Nested enum pattern matching works correctly (e.g., matching inside Option::Some)
4. Guard expressions work in match arms (syntax: `guard x is pattern { ... }`)
5. Destructuring patterns work for tuples and arrays (e.g., `let (a, b) = tuple`)
6. Or patterns work correctly (e.g., `1 | 2 | 3` matches any of these values)

**Plans:** TBD

---

### Phase 4: Derive(Show) Macro

**Goal:** Users can add `derive(Show)` to type definitions to automatically generate toString methods.

**Depends on:** Phase 3

**Requirements:** TEST-01

**Success Criteria** (what must be TRUE):

1. User can write `derive(Show)` after type definition and compiler generates toString method
2. Types with derive(Show) can be printed using println and produce correct string output
3. derive(Show) works for structs with named fields
4. derive(Show) works for enums with variants

**Plans:** TBD

---

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Map Support | 2/2 | ✓ Complete | 2026-03-09 |
| 2. Tuple & Float Improvements | 0/1 | Not started | - |
| 3. Enum & Pattern Matching | 0/1 | Not started | - |
| 4. Derive(Show) Macro | 0/1 | Not started | - |

---

## Coverage Map

| Requirement | Phase | Status |
|-------------|-------|--------|
| MAP-01 | Phase 1 | Pending |
| MAP-02 | Phase 1 | Pending |
| MAP-03 | Phase 1 | Pending |
| MAP-04 | Phase 1 | Pending |
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

**Coverage:** 15/15 requirements mapped ✓

---

*Last updated: 2026-02-24*
