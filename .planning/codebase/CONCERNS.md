# Codebase Concerns

**Analysis Date:** 2026-03-25

## Tech Debt

**Monolithic CodeGen:**
- Issue: `codegen.mbt` is 8,599 lines with a single function `codegen_expr` spanning approximately 5,946 lines (line 2305 to line 8251). The `CodeGen` struct has over 40 fields, indicating excessive state complexity.
- Files: `codegen.mbt`
- Impact: Extremely difficult to maintain, debug, or extend. Any change risks introducing subtle bugs due to tight coupling.
- Fix approach: Decompose `codegen_expr` into smaller functions handling each AST variant. Group related state fields into substructures (e.g., `VarInfo`, `StackTracker`).

**Duplicate and Unused Code:**
- Issue: `examples/double_ryu_nonjs.mbt` is a duplicate of `double_ryu_nonjs.mbt`. The first `padding` variable in `compiler.mbt` is shadowed and unused.
- Files: `examples/double_ryu_nonjs.mbt`, `compiler.mbt`
- Impact: Maintenance confusion; dead code increases cognitive load.
- Fix approach: Remove the duplicate file; eliminate the unused variable.

## Known Bugs

**ELF Header Padding Value:**
- Symptoms: The ELF header padding byte is set to `0x00B` (decimal 11) instead of `0x00`. This may produce malformed executables on some systems.
- Files: `compiler.mbt` (lines 26 and 103)
- Trigger: Every compilation.
- Workaround: Change `0x00B` to `0x00` in both occurrences.

**Stack Offset Calculation Uncertainty:**
- Symptoms: Comments in `codegen.mbt` (lines 6620-6640) reveal confusion about stack offset formulas for tuple variables. The current formula may produce incorrect offsets in complex scenarios.
- Files: `codegen.mbt`
- Trigger: Compilation of programs with tuple destructuring alongside other local variables.
- Workaround: None; requires careful verification and possible rewrite of stack offset logic.

## Security Considerations

**Arbitrary File Read/Write:**
- Risk: The compiler reads arbitrary source files and writes executable files at user-specified paths. If used in an untrusted environment (e.g., a web service), this could lead to path traversal or system compromise.
- Files: `compiler.mbt` (functions `compile_file`), `cmd/main/main.mbt`
- Current mitigation: None; the tool is intended as a local compiler.
- Recommendations: Add input validation, restrict output paths, consider sandboxing if used in a service.

**Lack of Input Validation:**
- Risk: The lexer/parser do not validate input length or content, potentially leading to denial-of-service (infinite loops, excessive memory allocation).
- Files: `lexer.mbt`, `parser.mbt`
- Current mitigation: None.
- Recommendations: Add bounds checks, limit recursion depth, and implement proper error reporting.

## Performance Bottlenecks

**Inefficient Map Lookups:**
- Problem: The `CodeGen` struct uses many separate `Map[String, ...]` fields for variable metadata. Each access is O(log n) and repeated frequently.
- Files: `codegen.mbt`
- Cause: Design choice; each variable attribute stored in a separate map.
- Improvement path: Combine variable metadata into a single struct per variable, stored in a map from name to struct.

**Array Concatenation in Hot Loops:**
- Problem: Code generation uses `array + element` concatenation (e.g., `converted_parts = converted_parts + [part]`) which creates new arrays each iteration.
- Files: `codegen.mbt` (lines 2368-2390)
- Cause: Convenience; MoonBit arrays are immutable.
- Improvement path: Use `Array::push` or pre-allocate with known size.

## Fragile Areas

**Stack Offset Management:**
- Files: `codegen.mbt` (lines 6600-6700)
- Why fragile: Manual stack pointer tracking with complex formulas; comments indicate the developer struggled to get it right.
- Safe modification: Extract stack offset calculation into a separate function with unit tests; verify with a variety of variable patterns.
- Test coverage: No unit tests for this area.

**String Concatenation Code Generation:**
- Files: `codegen.mbt` (lines 2334-2399)
- Why fragile: Handles multiple special cases (bool, float, ident) and builds nested `Binary` expressions. Easy to miss edge cases.
- Safe modification: Refactor into a dedicated function with clear logic; add snapshot tests for various concatenation patterns.
- Test coverage: No direct tests; only E2E tests via examples.

## Scaling Limits

**Single-Threaded Compilation:**
- Current capacity: Limited to the speed of a single CPU core.
- Limit: Large programs will compile slowly.
- Scaling path: Introduce parallel lexing/parsing (if language permits) or incremental compilation.

**Memory Usage:**
- Current capacity: Entire source code and AST held in memory.
- Limit: Very large source files (>100 MB) could exhaust memory.
- Scaling path: Implement streaming lexer/parser or memory-mapped files.

## Dependencies at Risk

**moonbitlang/x:**
- Risk: The `fs` module is used for file I/O. Its API may change.
- Impact: Breaks compilation if the module updates.
- Migration plan: Pin version (already pinned to 0.4.40) or abstract behind a trait.

**moonbitlang/async:**
- Risk: Listed as a dependency but not used in any source file (only in `moon.mod.json`).
- Impact: Unnecessary dependency increases build time and potential conflicts.
- Migration plan: Remove from `moon.mod.json` if not needed.

## Missing Critical Features

**Error Recovery and Reporting:**
- Problem: The compiler panics on invalid syntax; no error messages are produced.
- Blocks: Using the compiler as a language server or in an IDE.
- Priority: High (for usability).

**Optimization passes:**
- Problem: No dead code elimination, constant folding, or register allocation.
- Blocks: Producing efficient executables.
- Priority: Medium (for a production compiler).

## Test Coverage Gaps

**CodeGen Unit Tests:**
- What's not tested: Any code generation logic, especially stack offset calculation, instruction selection, and label resolution.
- Files: `codegen.mbt`
- Risk: Regressions in emitted x86_64 code go unnoticed until E2E tests fail.
- Priority: High

**Parser Error Cases:**
- What's not tested: Malformed input, edge cases in operator precedence, nested structures.
- Files: `parser.mbt`
- Risk: Parser crashes or produces incorrect AST.
- Priority: Medium

**E2E Test Coverage:**
- What's not tested: Examples 012 and above (pattern matching, arrays, etc.).
- Files: `run_e2e_tests.sh` only runs examples 001-011.
- Risk: New features may break untested examples.
- Priority: Medium

---

*Concerns audit: 2026-03-25*