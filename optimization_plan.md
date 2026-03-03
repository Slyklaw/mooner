# Optimization Phase

## Project Assessment

**Mooner** - Self-hosted MoonBit compiler targeting x86_64 ELF

### Current State
- 12/13 examples passing
- Phase 1 (Map Support) in progress  
- No test coverage
- Monolithic codebase (8880 lines in single file)
- Large CodeGen struct (28+ fields)

### Identified Issues

1. **Monolithic codebase** - All code in `compiler_combined.mbt`
2. **No test coverage** - Empty test files
3. **Large CodeGen struct** - 28+ fields tracking type info
4. **Dead code** - 5 commented-out features
5. **Feature gaps** - Map crashes, float tuple printing, test framework unsupported

---

## Planned Improvements

### Priority 1: Testing Infrastructure
Add tests to validate compiler behavior:
- Blackbox tests for each passing example
- Whitebox tests for internal helpers

### Priority 2: Modularization
Split monolithic file into packages:
- `lexer/` - Tokenization
- `parser/` - AST generation  
- `codegen/` - Code generation
- `runtime/` - Runtime functions

### Priority 3: Refactoring
- Extract type-tracking maps into separate `TypeInfo` struct
- Remove commented-out dead code

### Priority 4: Documentation
- Add module-level docs
- Document key algorithms

---

## Tasks

### Phase 1: Testing Infrastructure

- [ ] 1.1 Add blackbox test for 001_hello
- [ ] 1.2 Add blackbox test for 002_variable
- [ ] 1.3 Add blackbox test for 003_basic_constants
- [ ] 1.4 Add blackbox test for 004_basic_function
- [ ] 1.5 Add blackbox test for 005_basic_array
- [ ] 1.6 Add blackbox test for 006_basic_string
- [ ] 1.7 Add blackbox test for 007_basic_tuple
- [ ] 1.8 Add blackbox test for 008_basic_map
- [ ] 1.9 Add blackbox test for 009_basic_control_flows
- [ ] 1.10 Add blackbox test for 010_basic_struct
- [ ] 1.11 Add blackbox test for 011_basic_enum
- [ ] 1.12 Add whitebox tests for lexer tokenization
- [ ] 1.13 Add whitebox tests for parser AST generation

### Phase 2: Refactoring

- [ ] 2.1 Extract CodeGen type-tracking maps to TypeInfo struct
- [ ] 2.2 Remove commented-out dead code
- [ ] 2.3 Add module-level documentation

### Phase 3: Modularization

- [ ] 3.1 Create lexer package with proper exports
- [ ] 3.2 Create parser package with proper exports
- [ ] 3.3 Create codegen package with proper exports
- [ ] 3.4 Create runtime package for runtime functions

---

*Created: 2026-03-02*
