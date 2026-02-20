# Mooner Project - Feature Implementation Plan

## Project Overview

Mooner is a compiler written in MoonBit that compiles **standard MoonBit language** source files to **x86_64 Linux ELF binaries**. The compiler follows a classic pipeline: `Source Code → Lexer → Parser → Type Checker → Code Generator → ELF Binary`.

The compiler expects a MoonBit source file with a single `main` entry point:
```moonbit
fn main {
  println("Hello, World!")
}
```

This document outlines features that need to be implemented to make Mooner a complete and usable MoonBit compiler.

---

## Phase 1: Critical Bug Fixes & Core Stability

### 1.0 Parser Bug Fixes ✅ COMPLETED

**Location**: `parser.mbt:93-107`, `parser.mbt:178-204`

**Issues Fixed**:
1. **Ident handling in parse_literal** - `Ident` token was not handled, causing infinite loop when parsing function calls like `print("hi")`. Fixed by adding `Ident(name) => (Ident(name), self.advance())` to the match.

2. **Underscore handling in parse_primary** - `_` token (Underscore) wasn't handled, causing infinite loop with `let _ = 1`. Fixed by adding `Underscore => (Ident("_".to_string()), self.advance())`.

3. **Missing token handlers** - Equal, RParen, Comma, Semicolon weren't handled in parse_primary, causing infinite loops when parsing certain expressions.

4. **RIP-relative addressing** - FixedLea instruction displacement calculation in codegen (`ref_pos + 4` instead of `ref_pos + 7`).

5. **String label emission** - Fixed string labels being defined before exit code rather than inline with string data.

### 1.1 Fix println/print Function Implementation ✅ COMPLETED

**Location**: `codegen.mbt:760-810`

**Implementation**:
- ✅ Implemented actual string printing via Linux syscalls
- ✅ Handle the string argument properly 
- ✅ Support different types (Int, String)
- ✅ Implement `write` syscall (syscall #1) for stdout
- ✅ Handle string length calculation via string data emission

### 1.2 Fix Function Call Argument Handling ✅ PARTIALLY COMPLETE

**Location**: `codegen.mbt:805-856`

**Implementation**:
- ✅ Handle single argument in println/print (via sys_write)
- ⚠️ User-defined function calls not implemented (falls through to no-op)

### 1.3 Implement Proper Function Prologue/Epilogue ✅ COMPLETED

**Location**: `codegen.mbt:902-912`

**Implementation**:
- ✅ Basic prologue (push rbp, mov rbp, rsp)
- ✅ Basic epilogue (mov rsp, rbp, pop rbp, syscall)
- ✅ Stack allocation for local variables via LetBind

### 1.4 Variable Storage (LetBind) ✅ COMPLETED

**Location**: `codegen.mbt:882-903`

**Implementation**:
- ✅ Evaluate value expression
- ✅ Allocate stack slot using rbp-relative addressing (StackBP64)
- ✅ Store value to stack with proper push/pop of rbx as temp
- ✅ Track variable offsets in var_offsets map
- ✅ Load variable values when referenced via Ident

**New x86 Operand Added**:
- `StackBP64(Int)` - rbp-relative addressing for local variables

---

## Phase 2: Language Features

### 2.1 While Loop Code Generation ✅ COMPLETED (basic)

**Location**: `codegen.mbt:1019-1035`

**Implementation**:
- ✅ Generate loop header label
- ✅ Evaluate condition
- ✅ Emit conditional jump to loop exit
- ✅ Generate loop body code
- ✅ Emit unconditional jump back to loop header
- ✅ Define exit label

**Known Limitations**:
- Break/continue not implemented
- Return inside while loops doesn't clean up stack properly

### 2.2 For Loop Code Generation ✅ COMPLETED (basic)

**Location**: `codegen.mbt:1037-1069`, `parser.mbt:319-327`

**Implementation**:
- ✅ Handle init expression (variable initialization)
- ✅ Generate condition check
- ✅ Handle step expression
- ✅ Generate loop body with proper control flow
- ✅ Fixed parser bug - skip `)` after step before parsing body

**Known Limitations**:
- Break/continue not implemented
- Return inside for loops doesn't clean up stack properly

### 2.3 Match Expression Code Generation ✅ COMPLETED

**Location**: `codegen.mbt:1196-1261`, `lexer.mbt:640-647`

**Implementation**:
- ✅ Generate code to evaluate the matched expression
- ✅ Create labels for each case and end
- ✅ Emit comparison and jumps for each pattern
- ✅ Handle wildcard (`_`) case
- ✅ Implemented pattern matching for:
  - Integer literals
  - Boolean values
  - Variable binding (Ident)
- ✅ Fixed lexer to recognize `=>` as Arrow token

### 2.4 Break/Continue Statement Support ✅ COMPLETED

**Location**: `codegen.mbt:1159-1177`, `codegen.mbt:77-88`

**Implementation**:
- ✅ Track loop labels (start and end) using loop_labels stack
- ✅ Emit proper jump instructions
- ✅ Handle nested loops correctly (use a label stack)
- ✅ Break jumps to loop end, Continue jumps to condition/step check

### 2.5 Return Statement Implementation

**Location**: `codegen.mbt:779-782`

**Issue**: Return expressions are partially implemented but need improvement.

**Implementation**:
- Move return value to rax before jumping
- Properly handle functions with non-unit return types
- Clean up stack frame before returning

### 2.6 Array Operations ✅ COMPLETED

**Location**: `codegen.mbt:1165-1225`, `codegen.mbt:357-434`

**Implementation**:
- ✅ Array literal code generation using stack allocation
- ✅ Array indexing with computed address calculation
- ✅ Array element assignment
- ✅ Added MemIndirect operand for register-indirect addressing
- ✅ Fixed IMUL instruction encoding

### 2.7 Tuple Operations ✅ COMPLETED

**Location**: `codegen.mbt:1220-1245`, `codegen.mbt:1246-1276`, `parser.mbt:491-504`

**Implementation**:
- ✅ Tuple literal code generation using stack allocation
- ✅ Tuple field access (e.g., `t.0`, `t.1`)
- ✅ Updated parser to accept numeric field names after `.`

### 2.8 Field Expression (Struct/Record Access)

**Location**: `codegen.mbt` (missing implementation)

**Issue**: Field expressions like `obj.field` are not implemented.

**Implementation**:
- Generate code to evaluate the object expression
- Calculate field offset based on field name and struct layout
- Load/store the field value

---

## Phase 3: Operators & Expressions

### 3.1 Division and Modulo Operators ✅ COMPLETED

**Location**: `codegen.mbt:819-845`

**Implementation**:
- ✅ Implement `idiv` instruction for signed division
- ✅ Sign-extend rax to rdx:rax using `cqo`
- ✅ Handle remainder for modulo operation (stored in rdx)
- ✅ Fixed Idiv instruction encoding (modrm reg=7 for idiv extension)

### 3.2 Bitwise Operators ✅ COMPLETED

**Location**: `codegen.mbt:867-905`, `codegen.mbt:570-610`

**Implementation**:
- ✅ Implement `and`, `or`, `xor` instructions
- ✅ Implement shift operations (shl, sar for variable count in cl)
- ✅ Right shift uses arithmetic shift (sar) for signed semantics
- ✅ Added variable shift encodings (D3 /4, /5, /7 with cl register)

### 3.3 Compound Assignment Operators ✅ COMPLETED

**Location**: `codegen.mbt:1893-2010`, `parser.mbt:28`, `parser.mbt:678-696`, `lexer.mbt:584-590`

**Implementation**:
- ✅ Added AssignOp AST variant in parser
- ✅ Parse compound assignment tokens (+=, -=, *=, /=, %=, &=, |=, ^=, <<=, >>=)
- ✅ Fixed lexer to recognize += and -= (was missing)
- ✅ Generate code for compound operations (load, operate, store)
- ✅ Support for variable and array element compound assignment

### 3.4 Float/Double Support ✅ COMPLETED

**Location**: `codegen.mbt`, `lexer.mbt`, `type_checker.mbt`

**Implementation**:
- ✅ Added XMM register support in X86Operand
- ✅ Added float instructions (Movsd, Addsd, Subsd, Mulsd, Divsd, Ucomisd, Cvtsi2sd, Cvtsd2si)
- ✅ Float literal storage in .rodata section (8-byte IEEE 754 doubles)
- ✅ Float printing in println/print (compile-time conversion for literals, placeholder for expressions)
- ✅ Fixed lexer to parse float literals with decimal point
- ✅ Float arithmetic operations (+, -, *, /)
- ✅ Float comparison operators (==, !=, <, >, <=, >=)
- ✅ Float variables with proper stack storage and loading
- ⚠️ Runtime float-to-string conversion not implemented (prints `<float>` for expressions)

### 3.5 String Operations ✅ COMPLETED

**Location**: `codegen.mbt:1490-1512`, `codegen.mbt:1354-1362`, `codegen.mbt:1994-2045`

**Implementation**:
- ✅ Store string literals in .rodata section with proper null-termination
- ✅ Generate correct pointer to string data using RIP-relative LEA
- ✅ String comparison (==, !=) with runtime character-by-character comparison
- ✅ String concatenation via `string_concat(s1, s2)` builtin
- ✅ Runtime string length calculation for string variables

**Added**:
- `var_is_string` field in CodeGen struct to track string variables
- `is_string_expr()` function to detect string expressions (literals, variables, string_concat, input)
- `Movzx` x86 instruction for zero-extending 8-bit to 64-bit values
- `.Lstrcat_buf` 512-byte buffer for string concatenation results

### 3.6 Char Type Support ✅ COMPLETED

**Location**: `codegen.mbt:1088-1091`, `codegen.mbt:1348-1354`

**Implementation**:
- ✅ Char literals compiled as 8-bit integer ASCII codes
- ✅ Char printing in println/print
- ✅ char_to_int builtin (identity operation)
- ✅ int_to_char builtin (identity operation)

---

## Phase 4: Type System Enhancements

### 4.1 User-Defined Types ✅ COMPLETED

**Location**: `type_checker.mbt`, `codegen.mbt`, `parser.mbt`

**Implementation**:
- ✅ Parse `type` declarations with field definitions
- ✅ Added TypeDecl and StructLit AST nodes  
- ✅ Added TStruct type in type checker
- ✅ Code generation for struct literal
- ✅ Code generation for struct field access (both numeric and named)
- ✅ Added var_types tracking for struct variables
- ✅ Fixed Sub instruction encoding for all registers
- ✅ Fixed Tuple/StructLit stack offset calculation

### 4.2 Type Annotations in Code Generation

**Location**: `codegen.mbt`

**Issue**: Type annotations exist in AST but aren't used during code generation.

**Implementation**:
- Use type information to generate more efficient code
- Different code paths for known types vs unknown
- Size calculations based on types

### 4.3 Function Type Support

**Location**: `type_checker.mbt:164-190`

**Issue**: Functions are typed but closures aren't supported.

**Implementation** (Future):
- Support first-class functions
- Implement closure creation and calling
- Capture free variables

---

## Phase 5: Standard Library

### 5.1 Implement Missing Built-in Functions

**Location**: `type_checker.mbt:113-125`, `codegen.mbt:760-830`

**Current Status**:
- ✅ `println` - IMPLEMENTED (string, int literal, float literal, char literal)
- ✅ `print` - IMPLEMENTED (string, int literal, float literal, char literal)
- ✅ `input` - IMPLEMENTED (reads line from stdin, returns pointer)
- ✅ `char_to_int` - IMPLEMENTED (identity operation)
- ✅ `int_to_char` - IMPLEMENTED (identity operation)
- ✅ `int_to_string` - IMPLEMENTED (runtime integer to string conversion)
- ✅ `string_to_int` - IMPLEMENTED (runtime string to integer conversion)
- ⚠️ `float_to_string` - PARTIAL (x86-64 encoding issues, needs debugging)
- ⚠️ `string_to_float` - not implemented

**Implementation**:
- Implement each function with proper syscalls or library calls
- For I/O: use read/write syscalls
- For conversions: implement conversion logic in generated code

### 5.2 Runtime Library

**Location**: New file needed

**Issue**: No runtime library for complex operations.

**Implementation**:
- Create a small runtime library (possibly in assembly or generated code)
- Memory allocation (malloc)
- String operations
- Array operations

---

## Phase 6: Error Handling & Debugging

### 6.1 Parser Error Recovery

**Location**: `parser.mbt`

**Issue**: Parser fails on syntax errors without helpful messages.

**Implementation**:
- Add error reporting in parser
- Implement panic mode or recovery
- Show line/column numbers for errors

### 6.2 Better Error Messages

**Location**: `type_checker.mbt`, `codegen.mbt`

**Issue**: Error messages are basic.

**Implementation**:
- Include source location in errors
- More descriptive type mismatch messages
- Suggest possible fixes

### 6.3 Debug Information (Optional)

**Location**: `compiler.mbt`

**Issue**: No debug info in generated binaries.

**Implementation** (Future):
- Add DWARF debug sections
- Source line mapping

---

## Phase 7: Optimizations (Future)

### 7.1 Constant Folding

**Location**: New optimization pass

**Issue**: Compile-time constant expressions aren't optimized.

**Implementation**:
- Evaluate constant expressions at compile time
- Replace with literal values

### 7.2 Register Allocation Improvements

**Location**: `codegen.mbt`

**Issue**: Simple register allocation using only rax/rcx.

**Implementation**:
- Track live variables
- Use more registers
- Spill to stack when needed

### 7.3 Dead Code Elimination

**Location**: New optimization pass

**Issue**: Unused code isn't removed.

**Implementation**:
- Detect unreachable code
- Remove unused variable bindings

---

## Phase 8: Extended Language Features

### 8.1 Lambda/Anonymous Functions

**Location**: `parser.mbt`, `type_checker.mbt`, `codegen.mbt`

**Issue**: Not supported.

**Implementation**:
- Parse lambda syntax
- Type check closures
- Generate closure code

### 8.2 Generics/Type Parameters

**Location**: `parser.mbt`, `type_checker.mbt`, `codegen.mbt`

**Issue**: Not supported.

**Implementation**:
- Parse generic syntax
- Monomorphization or generic code generation

### 8.3 Pattern Matching Enhancements

**Location**: `parser.mbt`, `codegen.mbt`

**Issue**: Basic match is implemented but limited patterns.

**Implementation**:
- Range patterns (`1..10`)
- Or patterns (`1 | 2 | 3`)
- Guard conditions

---

## Priority Order Summary

| Priority | Feature | Complexity | Status |
|----------|---------|------------|--------|
| P0 | Fix println/print | Medium | ✅ COMPLETED |
| P0 | Parser bug fixes (Ident, Underscore, etc.) | Medium | ✅ COMPLETED |
| P0 | Fix RIP-relative addressing | Low | ✅ COMPLETED |
| P0 | Variable storage (LetBind) | Medium | ✅ COMPLETED |
| P0 | Function call arguments (builtins) | Medium | ✅ COMPLETED |
| P0 | User-defined function calls | Medium | ✅ COMPLETED |
| P0 | Support `fn main` entry point | Medium | ✅ COMPLETED |
| P1 | While loop codegen | Medium | ✅ COMPLETED (basic) |
| P1 | For loop codegen | Medium | ✅ COMPLETED (basic) |
| P1 | Return statement | Low | ✅ COMPLETED |
| P1 | Division/Modulo | Low | ✅ COMPLETED |
| P1 | Break/Continue | Medium | ✅ COMPLETED |
| P2 | Match expression | High | ✅ COMPLETED |
| P2 | Array operations | High | ✅ COMPLETED |
| P2 | Variable assignment | Low | ✅ COMPLETED |
| P2 | Tuple operations | Medium | ✅ COMPLETED |
| P2 | Float support | Medium | ✅ COMPLETED (arithmetic, comparison) |
| P2 | Complete stdlib functions | Medium | ⚠️ PARTIAL (input, char_to_int, int_to_char, int_to_string, string_to_int) |
| P3 | User-defined types | High | ✅ COMPLETED |
| P3 | Bitwise operators | Low | ✅ COMPLETED |
| P3 | Compound assignment operators | Low | ✅ COMPLETED |
| P3 | String operations | Medium | ✅ COMPLETED |
| P3 | Char type support | Low | ✅ COMPLETED |
| P4 | Parser error recovery | Medium | ⚠️ NOT STARTED |
| P4 | Optimizations | High | ⚠️ NOT STARTED |
| P5 | Lambda functions | High | ⚠️ NOT STARTED |
| P5 | Generics | Very High | ⚠️ NOT STARTED |

---

## Compilation Model

- **Entry Point**: The compiled program must have a `main` function that serves as the entry point
- **Output**: Standalone x86_64 Linux ELF executable
- **Target**: Linux x86_64 (64-bit)
- **ABI**: System V AMD64 ABI

---

## Testing Strategy

1. **Unit Tests**: Test each component (lexer, parser, type checker, codegen) independently
2. **Integration Tests**: Test full compilation pipeline with example programs
3. **Snapshot Tests**: Compare generated code/output against known good examples
4. **Property-Based Testing**: Test code generation for various inputs

---

## Notes

### Currently Working Features (as of Feb 2026):
- ✅ `fn main { expr }` - basic entry point
- ✅ Integer literals (`42`, `-5`, etc.)
- ✅ Boolean literals (`true`, `false`)
- ✅ Char literals (`'A'`, `'Z'`, etc.) - ASCII code support
- ✅ Float literals (`3.14`, `2.718`, etc.) - parsing, printing, and arithmetic
- ✅ Char functions (`char_to_int`, `int_to_char`)
- ✅ `input()` - read line from stdin
- ✅ Float arithmetic (`+`, `-`, `*`, `/`) and comparison (`==`, `!=`, `<`, `>`, `<=`, `>=`)
- ✅ Basic arithmetic (`+`, `-`, `*`, `/`, `%`, `==`, `!=`, `<`, `>`, `<=`, `>=`)
- ✅ Bitwise operators (`&`, `|`, `^`, `<<`, `>>`)
- ✅ Unary operators (`-`, `!`)
- ✅ Variables via `let x = value` - properly stores on stack with rbp-relative addressing
- ✅ Variable assignment (`x = value`) - reassign existing variables
- ✅ Compound assignment (`+=`, `-=`, `*=`, `/=`, `%=`, `&=`, `|=`, `^=`, `<<=`, `>>=`)
- ✅ `print("string")` / `print(int)` / `print(float)` - prints to stdout
- ✅ `println("string")` / `println(int)` / `println(float)` - prints with newline
- ✅ `int_to_string(n)` - converts integer to string at runtime
- ✅ `string_to_int(s)` - converts string to integer at runtime
- ✅ If expressions with else
- ✅ Blocks
- ✅ Nested function definitions with parameters
- ✅ User-defined function calls with up to 6 parameters
- ✅ Return statements
- ✅ While loops (with break/continue)
- ✅ For loops (with break/continue)
- ✅ Bitwise operators (`&`, `|`, `^`, `<<`, `>>`)
- ✅ Match expressions with Int/Bool/wildcard patterns
- ✅ Array literals, indexing, and element assignment
- ✅ Tuple literals and field access (`t.0`, `t.1`)
- ✅ User-defined types with named field access (`type Point { x: Int, y: Int }`, `p.x`)
- ✅ String comparison (`"hello" == "world"`, `"a" != "b"`)
- ✅ String concatenation (`string_concat("Hello", "World")`)

### Known Limitations:
- Return inside while/for loops doesn't clean up stack properly
- Runtime float values print as `<float>` (no runtime float-to-string conversion)
- Limited stdlib functions
- Parser only supports one top-level function (use nested functions for multiple functions)
- Match patterns limited to Int, Bool, and wildcard (no tuples or guards)
- Exit codes limited to 8-bit (0-255) due to Linux syscall convention
- User-defined types require all fields to be 64-bit values

The compiler currently generates basic but functional code for simple expressions. Focus on making the core MoonBit features work correctly (fn main, println, basic operators). Consider adding a `-v`/`--verbose` flag to see generated code for debugging. Consider adding an `-O` flag for optimizations in the future. The goal is MoonBit language compatibility, not custom extensions.
