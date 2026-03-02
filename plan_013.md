# Analysis: 013_pattern_matching

## What Works (from testing)

- Basic enum match: `match color { Red => ..., Green => ... }`
- Enum with data: `RGB(r, g, b) => ...`
- Simple variable binding in match

## What Doesn't Work

| Feature | Example from code | Status |
|---------|-------------------|--------|
| `guard` statement | `guard tuple is (a, b, c)` | **NOT IMPLEMENTED** - creates empty bindings |
| Tuple destructuring | `let (a, b, c) = tuple` | **NOT IMPLEMENTED** |
| Array patterns | `guard array is [d, e, f]` | **NOT IMPLEMENTED** |
| Rest patterns | `[d, e, ..]`, `[.., f, g]` | **NOT IMPLEMENTED** |
| Struct destructuring | `let { x, .. } = ...` | **NOT IMPLEMENTED** |
| Named fields | `let { x: pos_x, .. } = ...` | **NOT IMPLEMENTED** |
| Map patterns | `match map { { "guest": { x, y }, .. } => ... }` | **NOT IMPLEMENTED** |

## Effort Estimate

**Complexity: HIGH (estimated 14-19 hours)**

1. **Guard statement** (~3-4 hrs): New keyword, parser, codegen
2. **Tuple destructuring** (~2-3 hrs): Detect `let (`, generate element extraction
3. **Array patterns** (~4-5 hrs): Parse `[d,e,f]`, `[d,..]`, `[..,f]`, codegen
4. **Struct destructuring** (~2-3 hrs): Parse `{x, y}`, `{x: pos_x, ..}`, field access
5. **Map patterns** (~3-4 hrs): Parse map literal patterns, lookup keys

## Recommendation

This is a major feature requiring changes across lexer, parser, and codegen. The individual features are interconnected (guard uses patterns, patterns apply to let/match/guard).

Options:
1. **Skip for now** - Move to easier examples (007, 008)
2. **Implement incrementally** - Start with guard statement only
3. **Full implementation** - Tackle all pattern matching features
