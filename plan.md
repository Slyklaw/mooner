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

### 2.3 Match Expression Code Generation

**Location**: `codegen.mbt` (missing implementation)

**Issue**: Match expressions are parsed but not compiled.

**Implementation**:
- Generate code to evaluate the matched expression
- Create labels for each case
- Emit comparison and jumps for each pattern
- Handle wildcard (`_`) case
- Implement pattern matching for:
  - Integer literals
  - Boolean values
  - Tuple patterns

### 2.4 Break/Continue Statement Support

**Location**: `codegen.mbt` (missing implementation)

**Issue**: Break and continue statements in loops are not implemented.

**Implementation**:
- Track loop labels (start and end)
- Emit proper jump instructions
- Handle nested loops correctly (use a label stack)

### 2.5 Return Statement Implementation

**Location**: `codegen.mbt:779-782`

**Issue**: Return expressions are partially implemented but need improvement.

**Implementation**:
- Move return value to rax before jumping
- Properly handle functions with non-unit return types
- Clean up stack frame before returning

### 2.6 Array Operations

**Location**: `codegen.mbt` (missing implementation)

**Issue**: Arrays are parsed but array literals and indexing aren't fully supported.

**Implementation**:
- Array literal code generation:
  - Allocate memory for array (malloc syscall)
  - Initialize each element
  - Store pointer to array
- Array indexing:
  - Load array pointer
  - Calculate element offset (index * element_size)
  - Load/store array elements

### 2.7 Tuple Operations

**Location**: `codegen.mbt` (missing implementation)

**Issue**: Tuples are parsed but not compiled.

**Implementation**:
- Tuple literal code generation:
  - Allocate space for tuple
  - Store each element at correct offset
- Tuple field access:
  - Calculate field offset
  - Load from tuple pointer + offset

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

### 3.2 Bitwise Operators

**Location**: `codegen.mbt:632-688`

**Issue**: Bitwise operators (`|`, `&`, `^`, `<<`, `>>`) are not implemented.

**Implementation**:
- Implement `and`, `or`, `xor` instructions
- Implement shift operations (shl, shr, sar)
- Handle right shift as arithmetic vs logical

### 3.3 Compound Assignment Operators

**Location**: `codegen.mbt:632-688`, `parser.mbt`

**Issue**: Operators like `+=`, `-=`, `*=`, etc. are lexed but not fully parsed or generated.

**Implementation**:
- Parse compound assignment in parser (AST node: `AssignOp`)
- Generate code: load, operate, store

### 3.4 Float/Double Support

**Location**: `codegen.mbt`, `type_checker.mbt`

**Issue**: Float literals are parsed but floating-point operations aren't implemented.

**Implementation**:
- Use XMM registers for floating-point operations
- Implement float arithmetic (addsd, subsd, mulsd, divsd)
- Implement float comparison (ucomisd)
- Handle float-to-int and int-to-float conversions
- Implement float literal storage in .rodata section

### 3.5 String Operations

**Location**: `codegen.mbt:616-619`

**Issue**: String literals are partially supported but not fully functional.

**Implementation**:
- Store string literals in .rodata section with proper null-termination
- Generate correct pointer to string data
- Implement string comparison
- Implement string concatenation (optional)

### 3.6 Char Type Support

**Location**: `codegen.mbt`

**Issue**: Char literals are parsed but not compiled.

**Implementation**:
- Handle char as 8-bit integer
- Implement char-to-int and int-to-char conversions

---

## Phase 4: Type System Enhancements

### 4.1 User-Defined Types

**Location**: `type_checker.mbt`, `codegen.mbt`

**Issue**: No support for custom types/structs.

**Implementation**:
- Parse `type` declarations
- Store type definitions in type environment
- Generate struct layouts
- Implement type checking for struct operations

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
- ✅ `println` - IMPLEMENTED (string and int)
- ✅ `print` - IMPLEMENTED (string and int)
- ⚠️ `input` - not implemented
- ⚠️ `int_to_string` - not implemented
- ⚠️ `float_to_string` - not implemented
- ⚠️ `string_to_int` - not implemented
- ⚠️ `string_to_float` - not implemented
- ⚠️ `char_to_int` - not implemented
- ⚠️ `int_to_char` - not implemented

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
| P1 | Break/Continue | Medium | ⚠️ NOT STARTED |
| P2 | Match expression | High | ⚠️ NOT STARTED |
| P2 | Array operations | High | ⚠️ NOT STARTED |
| P2 | Tuple operations | Medium | ⚠️ NOT STARTED |
| P2 | Float support | Medium | ⚠️ NOT STARTED |
| P2 | Complete stdlib functions | Medium | ⚠️ PARTIAL |
| P3 | User-defined types | High | ⚠️ NOT STARTED |
| P3 | Bitwise operators | Low | ⚠️ NOT STARTED |
| P3 | String operations | Medium | ⚠️ PARTIAL |
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
- ✅ Basic arithmetic (`+`, `-`, `*`, `/`, `%`, `==`, `!=`, `<`, `>`, `<=`, `>=`)
- ✅ Unary operators (`-`, `!`)
- ✅ Variables via `let x = value` - properly stores on stack with rbp-relative addressing
- ✅ `print("string")` / `print(int)` - prints to stdout
- ✅ `println("string")` / `println(int)` - prints with newline
- ✅ If expressions with else
- ✅ Blocks
- ✅ Nested function definitions with parameters
- ✅ User-defined function calls with up to 6 parameters
- ✅ Return statements
- ✅ While loops (basic - no break/continue yet)
- ✅ For loops (basic - init/cond/step, no break/continue yet)

### Known Limitations:
- Return inside while/for loops doesn't clean up stack properly
- Break/continue not implemented
- Arrays/tuples not implemented
- Float operations not implemented
- No user-defined types
- Limited stdlib functions
- Parser only supports one top-level function (use nested functions for multiple functions)

The compiler currently generates basic but functional code for simple expressions. Focus on making the core MoonBit features work correctly (fn main, println, basic operators). Consider adding a `-v`/`--verbose` flag to see generated code for debugging. Consider adding an `-O` flag for optimizations in the future. The goal is MoonBit language compatibility, not custom extensions.
