# Mooner Compiler Roadmap

## Project Context

**Core Value:** Compile standard MoonBit language to working x86_64 Linux executables that match official MoonBit compiler output.

**Depth:** Comprehensive  
**Total Phases:** 5  
**Total v1 Requirements:** 15

---

## Phases

- [x] **Phase 1: Map Support** - Implement map type with literal syntax, access, and update operations (4 requirements) ✓ COMPLETE
- [x] **Phase 2: Tuple & Float Improvements** - Fix float runtime conversion and tuple printing (5 requirements) ✓ COMPLETE
- [x] **Phase 3: Enum Pattern Matching** - Implement enum data constructors and field extraction (3 requirements) ✓ COMPLETE
- [x] **Phase 4: Pattern Matching Enhancements** - Implement guards, destructuring, and or patterns (3 requirements) ✓ COMPLETE
- [x] **Phase 5: Derive(Show) Macro** - Implement derive macro to generate toString for types (1 requirement) ✓ COMPLETE

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

**Status:** Complete (2026-03-09)

---

### Phase 2: Tuple & Float Improvements

**Goal:** Float values in tuples print correctly, and float runtime conversion outputs full decimal representation.

**Depends on:** Phase 1

**Requirements:** TUP-01, TUP-02, TUP-03, FLT-01, FLT-02

**Plans:** 2 plans

**Plan List:**
- [x] 02-01-PLAN.md — Fix GuardExpr float value propagation ✓
- [x] 02-02-PLAN.md — Verify float runtime conversion precision ✓

**Status:** Complete (2026-03-10)

---

### Phase 3: Enum Pattern Matching

**Goal:** Enum variants with data constructors match correctly and extract field values into local variables.

**Depends on:** Phase 2

**Requirements:** ENUM-01, ENUM-02, ENUM-03

**Success Criteria** (what must be TRUE):

1. Enum variants with data constructors match correctly (e.g., `RGB(r, g, b)` extracts red, green, blue values)
2. Pattern binding extracts data from enum variants into local variables
3. Nested enum pattern matching works correctly (e.g., matching inside Option::Some)

**Status:** Complete (2026-03-10)

---

### Phase 4: Pattern Matching Enhancements

**Goal:** Advanced pattern matching features including guards, destructuring, and or patterns.

**Depends on:** Phase 3

**Requirements:** PAT-01, PAT-02, PAT-03

**Success Criteria** (what must be TRUE):

1. Guard expressions work in match arms (syntax: `guard x is pattern { ... }`)
2. Destructuring patterns work for tuples and arrays (e.g., `let (a, b) = tuple`)
3. Or patterns work correctly (e.g., `1 | 2 | 3` matches any of these values)

**Status:** Complete (2026-03-10)

---

### Phase 5: Derive(Show) Macro

**Goal:** Users can add `derive(Show)` to type definitions to automatically generate toString methods.

**Depends on:** Phase 4

**Requirements:** TEST-01

**Success Criteria** (what must be TRUE):

1. User can write `derive(Show)` after type definition and compiler generates toString method
2. Types with derive(Show) can be printed using println and produce correct string output
3. derive(Show) works for structs with named fields
4. derive(Show) works for enums with variants

**Status:** Complete (2026-03-10)

---

## Progress Table

| Phase | Status | Completed |
|-------|--------|-----------|
| 1. Map Support | ✓ Complete | 2026-03-09 |
| 2. Tuple & Float Improvements | ✓ Complete | 2026-03-10 |
| 3. Enum Pattern Matching | ✓ Complete | 2026-03-10 |
| 4. Pattern Matching Enhancements | ✓ Complete | 2026-03-10 |
| 5. Derive(Show) Macro | ✓ Complete | 2026-03-10 |

---

## Coverage Map

| Requirement | Phase | Status |
|-------------|-------|--------|
| MAP-01 | Phase 1 | Complete |
| MAP-02 | Phase 1 | Complete |
| MAP-03 | Phase 1 | Complete |
| MAP-04 | Phase 1 | Complete |
| TUP-01 | Phase 2 | Complete |
| TUP-02 | Phase 2 | Complete |
| TUP-03 | Phase 2 | Complete |
| FLT-01 | Phase 2 | Complete |
| FLT-02 | Phase 2 | Complete |
| ENUM-01 | Phase 3 | Complete |
| ENUM-02 | Phase 3 | Complete |
| ENUM-03 | Phase 3 | Complete |
| PAT-01 | Phase 4 | Complete |
| PAT-02 | Phase 4 | Complete |
| PAT-03 | Phase 4 | Complete |
| TEST-01 | Phase 5 | Complete |

**Coverage:** 15/15 requirements mapped ✓

---

*Last updated: 2026-03-10*
