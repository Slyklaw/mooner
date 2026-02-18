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

### 1.1 Fix println/print Function Implementation

**Location**: `codegen.mbt:705-730`

**Issue**: The `println` and `print` functions are stubs that output fixed content. They don't actually print the argument value.

**Implementation**:
- Implement actual string printing via Linux syscalls
- Handle the string argument properly (currently ignores it)
- Support different types (Int, String, Bool, etc.)
- Implement `write` syscall (syscall #1) for stdout
- Handle string length calculation

### 1.2 Fix Function Call Argument Handling

**Location**: `codegen.mbt:705-730`

**Issue**: Function calls don't properly handle arguments. Arguments should be passed in registers (rdi, rsi, rdx, rcx, r8, r9) according to x86_64 System V ABI.

**Implementation**:
- Save caller-saved registers before function call
- Move arguments to proper argument registers
- Handle functions with more than 6 arguments (use stack)
- Implement proper return value handling (rax)

### 1.3 Implement Proper Function Prologue/Epilogue

**Location**: `codegen.mbt:768-778`

**Issue**: Basic function handling exists but doesn't properly manage the stack frame for local variables.

**Implementation**:
- Calculate total stack space needed for all local variables
- Emit proper `sub rsp, N` instruction
- Save/restore callee-saved registers (rbx, rbp, r12-r15)
- Handle variable-sized stack allocations

---

## Phase 2: Language Features

### 2.1 While Loop Code Generation

**Location**: `codegen.mbt` (missing implementation)

**Issue**: While loops are parsed but not compiled to code.

**Implementation**:
- Generate loop header label
- Evaluate condition
- Emit conditional jump to loop exit
- Generate loop body code
- Emit unconditional jump back to loop header
- Define exit label

### 2.2 For Loop Code Generation

**Location**: `codegen.mbt` (missing implementation)

**Issue**: For loops are parsed but not compiled.

**Implementation**:
- Handle init expression (variable initialization)
- Generate condition check
- Handle step expression
- Generate loop body with proper control flow

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

### 3.1 Division and Modulo Operators

**Location**: `codegen.mbt:632-688`

**Issue**: Division and modulo (`/`, `%`) operators are not implemented in code generation.

**Implementation**:
- Implement `idiv` instruction for signed division
- Save/restore rdx before division (idiv uses rdx:rax)
- Handle remainder for modulo operation

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

**Location**: `type_checker.mbt:113-125`, `codegen.mbt:705-730`

**Current**:
- `println` - stub
- `print` - stub
- `input` - not implemented
- `int_to_string` - not implemented
- `float_to_string` - not implemented
- `string_to_int` - not implemented
- `string_to_float` - not implemented
- `char_to_int` - not implemented
- `int_to_char` - not implemented

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

| Priority | Feature | Complexity |
|----------|---------|------------|
| P0 | Fix println/print | Medium |
| P0 | Fix function call arguments | Medium |
| P0 | Support `fn main` entry point | Medium |
| P1 | While loop codegen | Medium |
| P1 | For loop codegen | Medium |
| P1 | Return statement | Low |
| P1 | Division/Modulo | Low |
| P1 | Break/Continue | Medium |
| P2 | Match expression | High |
| P2 | Array operations | High |
| P2 | Tuple operations | Medium |
| P2 | Float support | Medium |
| P2 | Complete stdlib functions | Medium |
| P3 | User-defined types | High |
| P3 | Bitwise operators | Low |
| P3 | String operations | Medium |
| P4 | Parser error recovery | Medium |
| P4 | Optimizations | High |
| P5 | Lambda functions | High |
| P5 | Generics | Very High |

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

- The compiler currently generates basic but functional code for simple expressions
- Focus on making the core MoonBit features work correctly (fn main, println, basic operators)
- Consider adding a `-v`/`--verbose` flag to see generated code for debugging
- Consider adding an `-O` flag for optimizations in the future
- The goal is MoonBit language compatibility, not custom extensions
