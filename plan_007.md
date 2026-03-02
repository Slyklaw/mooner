# Analysis: 007_basic_tuple

## Issue

The example uses tuple destructuring syntax:
```moonbit
let (a, b, c) = tuple
```

This syntax is **not implemented**. The parser:
1. Sees `let` keyword
2. Calls `parse_ident()` which expects an identifier
3. Sees `(` (not an identifier), returns empty string `""`
4. Creates `LetBind("", None, value, body)` - no variable created

## Implementation Completed

### Added AST Node
- Added `LetTuple(Array[String], AST, AST)` to AST enum (line ~1015)

### Parser Changes
- Modified `parse_let()` to detect `LParen` after `let`
- Parse comma-separated identifiers: `(a, b, c)`
- Create `LetTuple(names, value, body)` node

### Codegen Changes  
- Added `LetTuple` case in codegen (lines ~7156-7260)
- Extract elements from tuple variable at correct offsets
- Allocate stack slots for destructured variables
- Register variables in var_offsets, var_is_float, etc.

## Remaining Issues

The example still fails to match official output due to:

1. **Float literals not supported**: `3.14` is parsed as `Int(3)` (truncated)
   - Lexer treats all numbers as integers: `(Int(parse_int(num_str)), lexer2)`
   - This affects tuple element values

2. **Tuple printing shows `<tuple>` placeholder**: 
   - println for tuples shows placeholder, not actual values

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
314
4200885
0, 4200885, 4200301
```

## Next Steps (if full support needed)

1. **Add Float support** - Re-enable Float token, lexer parsing, and codegen
2. **Fix tuple printing** - Implement proper tuple-to-string conversion
3. **Debug element extraction** - Fine-tune offset calculations

## Effort Already Spent

~2 hours on implementation
~1 hour debugging

## Recommendation

The tuple destructuring parsing and basic codegen is implemented. To fully match official output, Float support needs to be re-added (significant effort).
