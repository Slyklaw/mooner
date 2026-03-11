# Codebase Concerns

**Analysis Date:** 2026-03-11

## Tech Debt

### Massive Codegen File

**File:** `codegen.mbt` (~8,400 lines)

The codegen module is extremely large and violates single responsibility principle. It contains:
- 1,300+ lines of `emit_inst` match arms for x86 instruction generation
- Hundreds of helper functions for type checking and code generation
- Complex state management with 20+ fields in `CodeGen` struct

**Impact:** Difficult to maintain, test, or modify. High risk of introducing bugs when changing instruction generation.

**Fix approach:** Decompose into separate modules:
- Separate instruction emitters by category (arithmetic, logical, control flow, floating-point)
- Extract type inference helpers into dedicated module
- Reduce `CodeGen` struct field count by grouping related state

---

### Massive Parser with Complex Logic

**File:** `parser.mbt` (~1,700 lines)

Parser contains deeply nested parsing logic for multiple language constructs:
- `parse_struct_or_block` (around lines 279-426): Ambiguous detection between struct literals, map literals, and blocks
- `parse_for` (around lines 544-633): Complex C-style vs for-in loop detection
- `parse_string_interpolation` + `parse_interpolation_expr` (around lines 1241-1563): Manual expression parser within string interpolation

**Impact:** High cognitive load, hard to reason about correctness, prone to parsing edge cases.

**Fix approach:**
- Break parser into smaller focused functions
- Extract interpolation expression parser to separate module
- Simplify struct/map/block disambiguation with clearer token lookahead

---

### Duplicate Ryu Implementation

**Files:**
- `double_ryu_nonjs.mbt` (~730 lines)
- `examples/double_ryu_nonjs.mbt` (~730 lines)

Both files contain identical implementations of the Ryu float-to-string algorithm.

**Impact:** Maintenance burden, risk of divergence, code bloat.

**Fix approach:** Consolidate into single module in lib/ and import where needed. Remove duplicate from examples/.

---

### Silent Failures via Unit Returns

**Files:** `parser.mbt` extensive

Parser frequently returns `Unit` as fallback in error cases:
- EOF handling returns `(Unit, self.advance())`
- Error cases in `parse_let`, `parse_guard` return `(Unit, Unit)`
- Character parsing returns `'?'` on error

**Impact:** Parsing errors may silently succeed with wrong AST, causing confusing runtime failures.

**Fix approach:** Eliminate fallback Unit returns. Use Result types or propagate errors properly.

---

## Known Bugs

### Abrupt Termination on Error

**File:** `double_ryu_nonjs.mbt` around line 116

```moonbit
abort("IllegalArgumentException \{value}")
```

The `pow5Factor` function calls `abort` when encountering an impossible state.

**Symptoms:** Program crash with unhelpful error message.

**Fix:** Replace `abort` with proper error handling (Result or Option return).

---

### Incomplete Number Parsing - Scientific Notation

**File:** `lexer.mbt` lines 294-319

The `parse_double` function skips exponent parsing:

```moonbit
} else if (c == 101 || c == 'E') && i < s.length() - 1 {
  // 'e' or 'E'
  // Skip exponent for now - simplified
}
```

**Impact:** Float literals with scientific notation (e.g., `1.23e4`) won't parse correctly.

**Fix:** Implement full exponent parsing.

---

### Insufficient Unicode Escape Validation

**File:** `lexer.mbt` lines 620-642

Unicode escape `\u{XXXX}` parsing does not validate code point range:
- No check for `0 <= code <= 0x10FFFF`
- No check for surrogate code points (0xD800-0xDFFF)

**Impact:** Invalid Unicode sequences may produce malformed strings.

**Fix:** Add validation and emit error.

---

### Block Comment Unterminated

**File:** `lexer.mbt` lines 186-210

`skip_block_comment` terminates on EOF without error if comment is unclosed:

```moonbit
None => depth = 0
```

**Impact:** Unterminated block comments silently ignored, leaving content as code tokens.

**Fix:** Report error on EOF with `depth > 0`.

---

### String Interpolation Edge Cases

**Files:** `parser.mbt` lines 1241-1323, `lexer.mbt` lines 577-609

String interpolation parsing has issues:
- No validation that `}` closes properly
- If expression runs to EOF without `}`, malformed interpolation
- Returns `(acc, lexer)` on EOF without indicating incomplete interpolation

**Impact:** Malformed interpolation may produce incorrect AST.

**Fix:** Validate matching braces, report errors.

---

## Security Considerations

### No Bounds Checking on Array Accesses

**File:** `parser.mbt` throughout

Parser uses array indexing without bounds checks:

```moonbit
let variant_name = parts[1].to_string()
```

**Risk:** Index out of bounds if malformed AST reaches codegen.

**Mitigation:** MoonBit runtime may panic on OOB, but better to validate at parse time.

---

### Fixed-Size Buffers in Ryu

**File:** `double_ryu_nonjs.mbt` line 533

```moonbit
let result = FixedArray::make(25, Byte::default())
```

Fixed 25-byte buffer. Hard-coded limit could be exceeded with extremely large exponents.

**Risk:** Potential buffer overflow.

**Fix:** Ensure buffer size is mathematically sufficient.

---

### Magic Numbers in ELF Header

**File:** `compiler.mbt` lines 24-98

Hard-coded ELF header bytes without symbolic constants or validation.

**Risk:** Typos could produce invalid ELF binaries.

**Fix:** Define named constants with comments.

---

### Padding Byte Value 0x00B

**File:** `compiler.mbt` lines 25, 102

```moonbit
let padding : Array[Byte] = Array::make(padding_len, 0x00B)
```

Uses non-standard padding value 0x0B instead of 0x00. Purpose unclear.

**Fix:** Document why 0x00B is used or change to 0x00.

---

## Performance Bottlenecks

### String Concatenation in Lexer

**File:** `lexer.mbt` lines 221, 241, 259, etc.

Repeated concatenation with `+` causes O(n²) complexity for long strings.

**Fix:** Use `StringBuilder` for linear-time construction.

---

### Linear Search for String Deduplication

**File:** `codegen.mbt` lines 1725-1748

`add_string` uses linear scan for duplicates, causing O(n²) for many string literals.

**Fix:** Use hash set (`Map[String, Int]`) for O(1) lookup.

---

### Repeated Map Lookups in Codegen

**File:** `codegen.mbt` `codegen_expr`

Multiple hash map lookups per variable reference.

**Impact:** Slower compilation for programs with many variables.

**Fix:** Cache variable metadata in unified structure.

---

## Fragile Areas

### Struct/Map/Block Disambiguation

**File:** `parser.mbt` lines 279-426 `parse_struct_or_block`

Three-way disambiguation based on first token after `{`. Context-sensitive and can cause mis-parsing.

**Fix:** Separate into dedicated functions with clearer grammar.

---

### String Interpolation Parser Limitations

**File:** `parser.mbt` lines 1262-1301, 1400-1562

`parse_interpolation_expr` only handles basic expressions. Will fail on function calls, nested parentheses, unary operators.

---

### Parser Infinite Loop Guard

**File:** `parser.mbt` lines 1609-1615

Skips tokens silently when parsing doesn't advance, hiding bugs.

**Fix:** Replace with proper error reporting.

---

### Codegen Type Tracking Maps

**File:** `codegen.mbt` struct `CodeGen` (lines 2-48)

Maintains 20+ separate maps for variable metadata. Easy to forget updates, causing inconsistencies.

**Fix:** Consolidate into single `VarInfo` struct.

---

## Missing Critical Features

### Error Reporting with Locations

**Files:** `parser.mbt`, `lexer.mbt`

No line/column information in error messages.

**Impact:** Users get no feedback on syntax errors.

---

### Debug Information

**Files:** `codegen.mbt`, `compiler.mbt`

No debug info in generated ELF binaries.

**Impact:** Impossible to debug with source-level info.

---

### Standard Library Dependency

**File:** `cmd/main/main.mbt` uses `println`

Requires external MoonBit runtime to link.

---

### Type Checking

**Files:** `parser.mbt`

No semantic analysis. Type errors caught too late.

---

## Test Coverage Gaps

### Untested Parser Edge Cases

- Malformed struct/map literals
- Unterminated strings
- Invalid for-loop syntax
- Tuple destructuring mismatches
- Guard expressions without `is`

---

### Untested Codegen Paths

- Floating-point instructions
- Shift operations with variable shift count
- Struct update syntax
- Map literal operations
- Array concatenation
- Complex string concatenation

---

### Integration Tests Missing

**File:** `mooner_test.mbt` tests API in isolation only.

Missing compile-and-run tests, regression tests, golden output tests vs reference compiler.

**Script:** `run_e2e_tests.sh` exists but may not be in CI.

---

## Additional Concerns

### Inconsistent Error Handling

Mixed patterns: Result types, Unit+print, silent Unit, abort.

**Fix:** Standardize on Result types.

---

### Lack of Logging

No logging framework. Debugging requires manual `println`.

**Fix:** Add debug logging with verbosity levels.

---

## Summary Priority Recommendations

1. **Add testing infrastructure** - E2E tests, property tests, coverage
2. **Eliminate silent failures** - Result errors with locations
3. **Refactor codegen** - Split file, consolidate metadata
4. **Remove duplicate code** - Consolidate Ryu
5. **Proper error reporting** - Line/column, diagnostics
6. **Fix critical bugs** - Exponent parsing, EOF handling
7. **Address security** - Bounds checks, Unicode validation
8. **Improve performance** - StringBuilder, hash dedup
9. **Add debug info** - DWARF or symbols
10. **Implement type checking** - Semantic analysis

---

*Concerns audit: 2026-03-11*
