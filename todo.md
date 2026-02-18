# Todo List - Mooner Project

## Phase 1: Critical Bug Fixes & Core Stability

### 1.1 Fix println/print Function Implementation
- **Location**: codegen.mbt:720-724
- **Status**: NOT STARTED
- **Priority**: P0
- **Issue**: println and print are stubs that output fixed content (always 1), ignoring arguments

### 1.2 Fix Function Call Argument Handling
- **Location**: codegen.mbt:713-728
- **Status**: NOT STARTED
- **Priority**: P0
- **Issue**: Function calls don't properly handle arguments - `_args` is ignored, no proper register allocation (rdi, rsi, rdx, etc.)

### 1.3 Implement Proper Function Prologue/Epilogue
- **Location**: codegen.mbt:766-776
- **Status**: PARTIALLY DONE
- **Priority**: P0
- **Issue**: Basic function handling exists but stack frame management for local variables needs improvement

---

## Phase 2: Language Features

### 2.1 While Loop Code Generation
- **Location**: codegen.mbt
- **Status**: NOT STARTED
- **Priority**: P1
- **Issue**: WhileLoop AST node exists but no codegen implementation

### 2.2 For Loop Code Generation
- **Location**: codegen.mbt
- **Status**: NOT STARTED
- **Priority**: P1
- **Issue**: ForLoop AST node exists but no codegen implementation

### 2.3 Match Expression Code Generation
- **Location**: codegen.mbt
- **Status**: NOT STARTED
- **Priority**: P2
- **Issue**: MatchExpr AST node exists but no codegen implementation

### 2.4 Break/Continue Statement Support
- **Location**: codegen.mbt
- **Status**: NOT STARTED
- **Priority**: P1
- **Issue**: Break and Continue AST nodes exist but no codegen implementation

### 2.5 Return Statement Implementation
- **Location**: codegen.mbt:777-779
- **Status**: PARTIALLY DONE
- **Priority**: P1
- **Issue**: ReturnExpr is handled but return value handling needs improvement

### 2.6 Array Operations
- **Location**: codegen.mbt
- **Status**: NOT STARTED
- **Priority**: P2
- **Issue**: ArrayLit and IndexExpr AST nodes exist but no codegen implementation

### 2.7 Tuple Operations
- **Location**: codegen.mbt
- **Status**: NOT STARTED
- **Priority**: P2
- **Issue**: Tuple AST node exists but no codegen implementation

### 2.8 Field Expression (Struct/Record Access)
- **Location**: codegen.mbt
- **Status**: NOT STARTED
- **Priority**: P2
- **Issue**: FieldExpr AST node exists but no codegen implementation

---

## Phase 3: Operators & Expressions

### 3.1 Division and Modulo Operators
- **Location**: codegen.mbt:640-696
- **Status**: NOT STARTED
- **Priority**: P1
- **Issue**: "/" and "%" operators parsed but not handled in codegen (falls through to default case)

### 3.2 Bitwise Operators
- **Location**: codegen.mbt:640-696
- **Status**: NOT STARTED
- **Priority**: P3
- **Issue**: "|", "&", "^", "<<", ">>" operators not implemented in codegen (type checker handles them)

### 3.3 Compound Assignment Operators
- **Location**: parser.mbt, codegen.mbt
- **Status**: NOT STARTED
- **Priority**: P2
- **Issue**: "+=", "-=", "*=", "/=", "%=", etc. are lexed but AST doesn't have AssignOp node for them

### 3.4 Float/Double Support
- **Location**: codegen.mbt, type_checker.mbt
- **Status**: PARTIALLY DONE
- **Priority**: P2
- **Issue**: Float AST node exists, type checker handles Float type, but no codegen for float operations

### 3.5 String Operations
- **Location**: codegen.mbt:624-627
- **Status**: PARTIALLY DONE
- **Priority**: P3
- **Issue**: String literals partially supported but string comparison/concatenation not implemented

### 3.6 Char Type Support
- **Location**: codegen.mbt
- **Status**: NOT STARTED
- **Priority**: P3
- **Issue**: Char literals parsed but not compiled

---

## Phase 4: Type System Enhancements

### 4.1 User-Defined Types
- **Location**: type_checker.mbt, codegen.mbt
- **Status**: NOT STARTED
- **Priority**: P3
- **Issue**: No support for custom types/structs

### 4.2 Type Annotations in Code Generation
- **Location**: codegen.mbt
- **Status**: NOT STARTED
- **Priority**: P3
- **Issue**: Type annotations in AST not used during code generation

### 4.3 Function Type Support (Closures)
- **Location**: type_checker.mbt:164-190
- **Status**: NOT STARTED
- **Priority**: P5
- **Issue**: Functions typed but closures not supported

---

## Phase 5: Standard Library

### 5.1 Implement Missing Built-in Functions
- **Location**: type_checker.mbt:113-125, codegen.mbt:720-724
- **Status**: NOT STARTED
- **Priority**: P2
- **Issue**: Built-in functions are declared but stub implementations:
  - `println` - stub
  - `print` - stub
  - `input` - not implemented
  - `int_to_string` - not implemented
  - `float_to_string` - not implemented
  - `string_to_int` - not implemented
  - `string_to_float` - not implemented
  - `char_to_int` - not implemented
  - `int_to_char` - not implemented

### 5.2 Runtime Library
- **Location**: New file needed
- **Status**: NOT STARTED
- **Priority**: P3
- **Issue**: No runtime library for complex operations (memory allocation, string operations, array operations)

---

## Phase 6: Error Handling & Debugging

### 6.1 Parser Error Recovery
- **Location**: parser.mbt
- **Status**: NOT STARTED
- **Priority**: P4
- **Issue**: Parser fails on syntax errors without helpful messages

### 6.2 Better Error Messages
- **Location**: type_checker.mbt, codegen.mbt
- **Status**: PARTIALLY DONE
- **Priority**: P4
- **Issue**: Basic error messages exist but lack source location information

### 6.3 Debug Information (Optional)
- **Location**: compiler.mbt
- **Status**: NOT STARTED
- **Priority**: P5
- **Issue**: No debug info in generated binaries

---

## Phase 7: Optimizations (Future)

### 7.1 Constant Folding
- **Location**: New optimization pass
- **Status**: NOT STARTED
- **Priority**: P5
- **Issue**: Compile-time constant expressions aren't optimized

### 7.2 Register Allocation Improvements
- **Location**: codegen.mbt
- **Status**: NOT STARTED
- **Priority**: P5
- **Issue**: Simple register allocation using only rax/rcx

### 7.3 Dead Code Elimination
- **Location**: New optimization pass
- **Status**: NOT STARTED
- **Priority**: P5
- **Issue**: Unused code isn't removed

---

## Phase 8: Extended Language Features

### 8.1 Lambda/Anonymous Functions
- **Location**: parser.mbt, type_checker.mbt, codegen.mbt
- **Status**: NOT STARTED
- **Priority**: P5
- **Issue**: Not supported

### 8.2 Generics/Type Parameters
- **Location**: parser.mbt, type_checker.mbt, codegen.mbt
- **Status**: NOT STARTED
- **Priority**: P5
- **Issue**: Not supported

### 8.3 Pattern Matching Enhancements
- **Location**: parser.mbt, codegen.mbt
- **Status**: NOT STARTED
- **Priority**: P5
- **Issue**: Basic match implemented but range patterns, or patterns, guard conditions not supported
