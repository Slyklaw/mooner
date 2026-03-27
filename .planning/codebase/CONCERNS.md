# Codebase Concerns

**Analysis Date:** 2026-03-26

## Tech Debt

**Large Monolithic Files:**
- `codegen.mbt` (8635 lines) is too large and lacks modularization
  - Contains 1800+ line match statement in `emit_inst`
  - Multiple concerns mixed: instruction emission, register allocation, label management
  - Needs refactoring into smaller, focused modules

**Code Duplication:**
- X86 register code lookup duplicated in `reg_code_lookup` and inline matches
- ModR/M encoding logic repeated across many instruction patterns
- String/char/float parsing duplicated between lexer and interpolation parser

**Manual Implementation Debt:**
- Hand-rolled integer parsing (`parse_int`, `parse_hex`, `parse_binary`) instead of using standard library
- Custom float parser (`parse_double`) is incomplete - skips exponent handling (line 312-315)
- Manual UTF-8 conversion (`unicode_to_utf8`) reimplements standard functionality
- Custom LEB128 encoding in WASM backend instead of reusable library

**Inconsistent Abstraction:**
- Some code uses functional style (immutable), other parts imperative (mutable vars)
- Error handling inconsistent: some functions return `Result`, others `Option`, many return default `Unit` on error
- Mix of enum-based type representation and string-based type names

## Known Bugs

**Critical - Segfaults:**

**Bug 1: Control Flow Crash (009_basic_control_flows)**
- **Files:** `codegen.mbt` (label handling, jump emission)
- **Symptoms:** Program outputs "0" then segfaults on any `if` or `for` construct
- **Trigger:** Any control flow structure
- **Likely cause:** Incorrect jump offset calculation or label resolution in `emit_jmp` family of instructions
- **Impact:** Makes entire control flow subsystem unusable
- **Fix approach:** Inspect label backpatching in `define_label` and pending label resolution; verify relative offset calculations

**Bug 2: Pattern Matching Crash (013_pattern_matching)**
- **Files:** `codegen.mbt` (pattern matching codegen), possibly `parser.mbt` (struct pattern parsing)
- **Symptoms:** Garbage output followed by segfault on complex pattern matches with structs
- **Trigger:** Struct patterns with field extraction, nested patterns
- **Likely cause:** Stack corruption from mismatched branch memory layout or incorrect struct field offsets
- **Impact:** Prevents use of pattern matching on structured data
- **Fix approach:** Verify memory layout of match arms, check struct field offset calculation, ensure stack alignment preserved

**Non-Critical - Wrong Output:**

**Bug 3: Function Return Value Corruption (004_basic_function)**
- **Files:** `codegen.mbt` (function call/return convention)
- **Symptoms:** Function `add(2, 40)` returns 80 instead of 42
- **Expected:** 42
- **Actual:** 80
- **Likely cause:** Caller/callee saved registers not preserved; return value location clobbered during call
- **Impact:** All function calls produce incorrect results
- **Fix approach:** Review calling convention implementation, ensure return value in correct register (rax) protected across calls

**Bug 4: Enum Pattern Matching Mismatch (011_basic_enum)**
- **Files:** `codegen.mbt` (enum construction), `parser.mbt` (enum variant parsing)
- **Symptoms:** Enum variants all appear to have same discriminant; only first variant works repeatedly
- **Expected:** Red, Green, Blue, RGB, RGBA all distinct
- **Actual:** Red appears twice, Green appears once, Blue and RGBA missing
- **Likely cause:** Enum discriminant assignment incorrect or pattern matching doesn't extract variant tag properly
- **Impact:** Enums unusable for sum types
- **Fix approach:** Check how enum discriminants are assigned in codegen, verify pattern matching comparison logic

**Float Parsing Issue:**
- **Files:** `lexer.mbt:294-318`
- **Issue:** `parse_double` doesn't actually parse exponent; comment says "Skip exponent for now - simplified"
- **Impact:** Scientific notation floats like `1.5e10` parsed incorrectly
- **Severity:** Medium (affects numeric literals with exponent)

## Security Considerations

**Integer Overflow Risks:**
- `parse_int` (lexer.mbt:280-291) multiplies result by 10 without overflow check
- `parse_hex`, `parse_binary` have same issue
- Could wrap around on large literals, leading to incorrect code generation

**Array Bounds:**
- Direct array indexing throughout (`arr[i]`) with no bounds checks
- MoonBit runtime may trap, but compiler could generate out-of-bounds accesses from AST traversal
- Files: `codegen.mbt`, `parser.mbt` - many loops assume valid indices

**String Concatenation:**
- Repeated `=` concatenation creates intermediate strings
- Potential memory exhaustion on very large string literals or interpolations
- No length validation before concatenation

**Unicode Handling:**
- `unicode_to_utf8` assumes valid code points (< 0x110000) without validation
- Could produce invalid UTF-8 for out-of-range values
- String interpolation doesn't validate escape sequences

## Performance Bottlenecks

**Codegen Performance:**
- `emit_inst` is a 1800+ line match statement - compiler will be slow on large programs
- Each instruction emission goes through giant match; could optimize with lookup tables or separate emit functions per instruction class
- String concatenation in codegen (e.g., `inst_to_string`) creates many temporary strings

**Parser Performance:**
- `parse_string_interpolation` and `parse_interpolation_expr` do repeated string splitting/trimming
- Could be optimized with direct character iteration instead of substring creation
- `read_while` creates new strings character-by-character (quadratic behavior possible)

**WASM Backend:**
- `encode_uleb128`, `encode_sleb128` use mutable arrays - could be optimized
- `encode_name_string` does UTF-16 detection heuristics on every string, expensive

**Memory Usage:**
- CodeGen struct has 30+ Map fields for variable tracking - could be consolidated
- Parser creates many temporary AST nodes; no pooling or reuse

## Fragile Areas

**String Interpolation Parser:**
- `parse_string_interpolation` and `parse_interpolation_expr` (parser.mbt:1241-1563)
- Custom mini-parser for expressions inside strings
- Handles field access, binary ops, numeric literals - easily broken by new syntax
- No error recovery; malformed interpolation likely crashes or misparses

**Heredoc/Dedent Logic:**
- `Lexer::read_multiline_string` (lexer.mbt:486-574)
- Complex state: detecting end marker vs dedent prefix, manual line-by-line dedent
- Edge cases: empty heredocs, nested dedent markers, mixed tabs/spaces
- Currently uses `#|` as delimiter - unusual, may have edge cases

**Struct/Block/Map Disambiguation:**
- `Parser::parse_struct_or_block` (parser.mbt:279-426)
- Tries to distinguish `{ expr }` (block), `{ field: value }` (struct), `{ "key": value }` (map)
- Detection based on first token type and lookahead for colon
- Fragile: ambiguous cases like `{ x: }` or `{ "x": }` without value

**ELF Header Generation:**
- `compiler.mbt:88-177` hardcodes ELF structures with magic numbers
- Padding calculations delicate (0x1000 page alignment)
- Any change to codegen output size breaks offsets
- No validation that generated code fits expectations

**Label Resolution:**
- `CodeGen::define_label` and pending_labels mechanism
- Two-pass: emit placeholder, then backpatch
- Bug-prone: if label never defined, placeholder remains; if defined multiple times, overwrites
- Current bug: control flow crashes indicate label issues

**Float-to-String Ryu Algorithm:**
- `double_ryu_nonjs.mbt` - complex algorithm ported from JS
- 731 lines of intricate numeric conversion
- Easy to introduce off-by-one errors; lack of tests for edge cases (NaN, Inf, subnormals)

## Scaling Limits

**No Module System:**
- Single-file compilation only
- No import/export between files
- Limits program size and code reuse

**WASM Backend Incomplete:**
- `wasm_backend.mbt` generates empty module with only memory export
- No function code generation
- Not usable for real programs

**No Type Checking:**
- Parser builds AST without type validation
- Type errors only caught at runtime (if at all)
- Limits confidence in code correctness

**No Optimization:**
- Codegen emits naive, unoptimized code
- No register allocation (only uses rax/rsp/rbp)
- No dead code elimination, constant folding limited
- Performance will degrade rapidly on larger programs

**Test Infrastructure Limited:**
- Only 121 lines of whitebox tests in `mooner_wbtest.mbt`
- Tests cover basic lexer/parser features only
- No tests for codegen (beyond `mooner_test.mbt` which just checks non-zero output)
- No tests for enum, pattern matching, control flow
- E2E tests rely on bash script comparing to reference compiler

**Limited Example Coverage:**
- 78 examples but only 13 are officially tracked (`test_results.md`)
- No guarantee remaining examples work correctly
- Lack of regression tests for fixed bugs

## Dependencies at Risk

**MoonBit Standard Library:**
- Primary dependency: `@lib` (compiler's own lib)
- Package: `moon.pkg` shows no external dependencies
- **Risk:** Low - no third-party risk
- **Caveat:** Standard library may change API; compiler tightly coupled to current lib internals

**OS/Platform Assumptions:**
- ELF generation assumes Linux/x86_64
- No support for other OSes (Windows PE, macOS Mach-O)
- Syscall-based I/O assumes Linux syscall numbers
- **Risk:** Platform portability very low

## Missing Critical Features

**Error Reporting:**
- Lexer/parser errors not recovered; just return default values
- No line/column tracking on errors after first
- Error messages not descriptive ("Error: ..." only)
- No diagnostic severity levels (warning vs error)

**Module/Import System:**
- Cannot compile multi-file programs
- No namespace support
- Blocks code organization and reuse

**Type System:**
- No type checking pass
- AST has type annotations but they're not validated
- Type unsafety leads to runtime crashes (e.g., mismatched field access)

**Standard Library Support:**
- Only minimal `println` appears to work (via external runtime?)
- Many standard library functions missing
- BUGFIX_PLAN notes example 012 (basic_test) is out of scope due to missing test framework runtime

**Debug Information:**
- No DWARF or other debug info
- Hard to debug generated code
- No source mapping for errors

**Optimization:**
- No optimization passes
- Generated code is naive and likely inefficient
- Register allocation rudimentary (hardcoded rax usage)

## Test Coverage Gaps

**Missing Unit Tests:**
- No tests for lexer edge cases: unterminated strings, invalid escapes, overflow literals
- No parser error recovery tests
- No codegen correctness tests (only "produces bytes")
- No enum variant parsing/generation tests
- No pattern matching compilation tests

**No Negative Tests:**
- Tests only cover valid syntax
- No tests for syntax errors, type errors, semantic errors
- Unknown how compiler behaves on malformed input

**WASM Backend Untested:**
- Only test is `test_wasm.wasm` binary; no test assertions
- No validation that WASM output is correct
- No tests for WASM-specific features

**Integration Gaps:**
- Examples 004, 009, 011, 013 broken but not caught by automated tests (only manual comparison)
- No snapshot testing of ASTs or assembly output
- No property-based tests

**Coverage Unknown:**
- No code coverage measurement
- Cannot tell what percentage of codegen is exercised by tests
- Likely large portions untested (e.g., all floating-point code except one float test)

---

*Concerns audit: 2026-03-26*
