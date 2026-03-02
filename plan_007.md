# Analysis: 007_basic_tuple

## Status: IN PROGRESS

## Issues Fixed

1. **Float parsing added**: 
   - Added Float(Double) token type
   - Updated lexer to detect floats (numbers with . or e/E)
   - Updated parser to handle Float token
   - Float expressions now work in tuples

2. **Float field detection**: 
   - var_tuple_field_types now correctly tracks float fields in tuples
   - Field access correctly identifies float fields

## Current Technical Issues

1. **Float runtime not working**:
   - Tried using strtod() to parse float strings
   - Tried embedding float constants directly
   - Float values still print as 0.0 or blank
   - The issue is likely in how floats are stored/loaded from the stack
   - Or in how printf is called with float arguments

2. **Tuple printing shows `<tuple>`**: 
   - Placeholder still in place

## Current Output

```
Official:
(3.14, false, [1, 2, 3])
(2.0999999046325684, true, 20)
3.14
[1, 2, 3]
3.14, false, [1, 2, 3]

Ours:
<tuple>
<tuple>

4200863
1, 0, 4198562
```

## What's Working

- Float literal parsing (3.14 -> Float(3.14))
- Float token and AST
- Tuple stores field types correctly [true, false, false]
- Float field detection works
- Basic codegen structure for floats

## Root Cause

The float runtime has fundamental issues that require deeper debugging of:
1. How float values are stored in let bindings
2. How float values are loaded from variables  
3. How printf is called with float arguments
4. The ABI conventions for float passing

This is a complex issue that requires stepping back and potentially using a different approach for float support.
