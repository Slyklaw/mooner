# Plan 1: Remove Unnecessary Code for Working Examples

## Goal
Simplify the compiler to only support features needed by the 8 working examples, making self-hosting easier.

## Working Examples (IDENTICAL to official MoonBit compiler)
- 001_hello.mbt - println strings
- 002_variable.mbt - let, variables
- 003_basic_constants.mbt - constants  
- 004_basic_function.mbt - functions with params/returns
- 006_basic_string.mbt - string operations
- 009_basic_control_flows.mbt - if/else, while/for loops
- 010_basic_struct.mbt - user-defined types
- 011_basic_enum.mbt - enums

## Features to KEEP (from working examples)

| Feature | Files Affected |
|---------|---------------|
| Integer/Boolean/Char literals | lexer.mbt, type_checker.mbt |
| String literals & operations | lexer.mbt, codegen.mbt |
| Arithmetic (+, -, *, /, %) | codegen.mbt |
| Comparison (==, !=, <, >, <=, >=) | codegen.mbt |
| Bitwise (&, \|, ^, <<, >>) | codegen.mbt |
| Unary (!, -) | codegen.mbt |
| Variables (let, assignment) | parser.mbt, codegen.mbt |
| Compound assignment (+=, etc) | parser.mbt, codegen.mbt |
| Functions (def, call, return) | parser.mbt, type_checker.mbt, codegen.mbt |
| If/else expressions | parser.mbt, codegen.mbt |
| While/for loops | parser.mbt, codegen.mbt |
| Break/continue | codegen.mbt |
| Match expressions (Int/Bool patterns) | parser.mbt, codegen.mbt |
| User-defined types (struct) | parser.mbt, type_checker.mbt, codegen.mbt |
| Enum definitions | parser.mbt, type_checker.mbt, codegen.mbt |
| println/print | codegen.mbt |
| Builtins: input, int_to_string, string_to_int, char_to_int, int_to_char | codegen.mbt |

## Features to REMOVE

| Feature | Rationale |
|---------|-----------|
| Float/Double support | Not needed for compiler, not in working examples |
| Array operations | Example 005 doesn't work identically |
| Tuple operations | Example 007 binary differs |
| Map operations | Example 008 binary differs |
| String concatenation | Not needed for self-hosting |
| String interpolation | Not implemented |
| Test syntax | Example 012 not supported |
| Advanced pattern matching | Example 013 differs |
| Field access (.) on complex types | Not needed for compiler |

## Implementation Steps

1. Run `moon build` to ensure current state compiles

2. Remove float parsing/emitting from lexer.mbt
   - Remove Float token variant or mark as unused
   - Remove float literal parsing

3. Remove float type from type_checker.mbt
   - Remove TFloat type variant if not used
   - Remove float-specific type checking

4. Remove float operations from codegen.mbt
   - Remove XMM register support
   - Remove float arithmetic instructions (addsd, subsd, mulsd, divsd)
   - Remove float comparison (ucomisd, cvtsi2sd, cvtsd2si)
   - Remove float literal handling in .rodata

5. Remove array literal/indexing code paths
   - Remove ArrayLit AST node handling in codegen
   - Remove array indexing

6. Remove tuple code paths
   - Remove Tuple/TupleGet AST handling
   - Remove tuple field access (.0, .1, etc.)

7. Remove map code paths
   - Remove MapLit AST handling

8. Remove string_concat and string operations beyond comparison
   - Keep string literals and comparison
   - Remove string concatenation runtime

9. Run tests to verify working examples still pass

## Verification

After each removal, run:
```bash
moon test
# Or manually verify working examples:
for i in 001 002 003 004 006 009 010 011; do
  moon run cmd/main examples/mbt_examples/${i}_*.mbt
  chmod +x examples/mbt_examples/${i}_*.exe
  moon run examples/mbt_examples/${i}_*.mbt > /tmp/moon_$i.txt
  ./examples/mbt_examples/${i}_*.exe > /tmp/our_$i.txt
  diff /tmp/moon_$i.txt /tmp/our_$i.txt && echo "$i: OK"
done
```
