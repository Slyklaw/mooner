# Plan 1: Remove Unnecessary Code for Working Examples

## Goal
Simplify the compiler to only support features needed by the 8 working examples, AND make the compiler source compilable by itself (self-hosting).

## Updated Analysis

### Current Blocker: Parser Performance
Our parser hangs when compiling lexer.mbt due to complex nested `while` + `match` patterns in:
- `read_multiline_string()` - lines ~484-527
- `read_string()` - lines ~505-672 (string interpolation)

### Root Cause
Certain patterns in MoonBit source code cause our parser to take exponential time:
```moonbit
while not(done) {
  match expr {
    Some(x) => ...
    None => ...
  }
}
```
When these are deeply nested (e.g., 3+ levels), parsing becomes prohibitively slow.

### Solution
Simplify the lexer source to avoid these patterns, AND remove unused features to reduce codebase size.

## Working Examples (IDENTICAL to official MoonBit compiler)
- 001_hello.mbt - println strings
- 002_variable.mbt - let, variables
- 003_basic_constants.mbt - constants  
- 004_basic_function.mbt - functions with params/returns
- 006_basic_string.mbt - string operations
- 009_basic_control_flows.mbt - if/else, while/for loops
- 010_basic_struct.mbt - user-defined types
- 011_basic_enum.mbt - enums

## Features to KEEP

| Feature | Files Affected | Notes |
|---------|---------------|-------|
| Integer/Boolean/Char literals | lexer.mbt, type_checker.mbt | Essential |
| String literals | lexer.mbt, codegen.mbt | Essential |
| Arithmetic (+, -, *, /, %) | codegen.mbt | Essential |
| Comparison (==, !=, <, >, <=, >=) | codegen.mbt | Essential |
| Bitwise (&, \|, ^, <<, >>) | codegen.mbt | Essential |
| Unary (!, -) | codegen.mbt | Essential |
| Variables (let, assignment) | parser.mbt, codegen.mbt | Essential |
| Compound assignment (+=, etc) | parser.mbt, codegen.mbt | Essential |
| Functions (def, call, return) | parser.mbt, type_checker.mbt, codegen.mbt | Essential |
| If/else expressions | parser.mbt, codegen.mbt | Essential |
| While/for loops | parser.mbt, codegen.mbt | Essential |
| Break/continue | codegen.mbt | Essential |
| Match expressions (Int/Bool patterns) | parser.mbt, codegen.mbt | Essential |
| User-defined types (struct) | parser.mbt, type_checker.mbt, codegen.mbt | Essential |
| Enum definitions | parser.mbt, type_checker.mbt, codegen.mbt | Essential |
| println/print | codegen.mbt | Essential |
| Builtins: input, int_to_string, string_to_int, char_to_int, int_to_char | codegen.mbt | Essential |

## Features to REMOVE

### High Priority (causing parser issues)

| Feature | Action | Rationale |
|---------|--------|-----------|
| String interpolation | Remove | Complex nested patterns in lexer cause parser hang |
| Multiline strings (#\|) | Remove | Complex nested patterns in lexer cause parser hang |
| Float/Double | Remove | Not needed for compiler source |
| Array operations | Remove | Example 005 doesn't work identically |
| Tuple operations | Remove | Example 007 binary differs |
| Map operations | Remove | Example 008 binary differs |
| Test syntax | Remove | Not needed for self-hosting |
| Advanced pattern matching | Remove | Not needed for compiler source |

### Lower Priority (can keep for now)
- String comparison (needed for compiler)
- Basic field access on structs (needed for compiler)

## Implementation Steps

### Phase 1: Simplify lexer.mbt (CRITICAL)

1. **Remove string interpolation** from `read_string()`:
   - Remove the complex `parts`, `in_interpolation`, `current_expr` handling
   - Simple string parsing only

2. **Remove multiline string** support from `read_multiline_string()`:
   - Either remove entirely or make a no-op
   - The nested while+match pattern causes parser hang

3. **Remove Float token and parsing**:
   - Remove `Float(Double)` from Token enum
   - Remove float literal parsing

### Phase 2: Simplify parser.mbt

1. Keep as-is (it works for our use case)

### Phase 3: Simplify type_checker.mbt

1. Remove TFloat type if present
2. Remove float-specific type checking

### Phase 4: Simplify codegen.mbt

1. Remove XMM register support
2. Remove float arithmetic instructions
3. Remove float comparison
4. Remove array, tuple, map code generation

### Phase 5: Test Self-Hosting

After simplification, try compiling the compiler:
```bash
moon run cmd/main lexer.mbt
```

## Verification

After each phase:
```bash
# Test working examples
for i in 001 002 003 004 006 009 010 011; do
  moon run cmd/main examples/mbt_examples/${i}_*.mbt
  chmod +x examples/mbt_examples/${i}_*.exe
  moon run examples/mbt_examples/${i}_*.mbt > /tmp/moon_$i.txt
  ./examples/mbt_examples/${i}_*.exe > /tmp/our_$i.txt
  diff /tmp/moon_$i.txt /tmp/our_$i.txt && echo "$i: OK"
done

# Test self-hosting
moon run cmd/main lexer.mbt
```

## Success Criteria

1. ✅ All 8 working examples compile and produce identical output
2. ✅ Compiler source (lexer.mbt, etc.) compiles without hanging
3. ✅ Generated compiler can compile simple programs
