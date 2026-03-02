# Analysis: 008_basic_map

## What Works

| Feature | Example | Status |
|---------|---------|--------|
| Map creation | `{ "key1": 1, "key2": 2 }` | ✓ Works |
| Map access | `map["key1"]` | ✓ Returns value |
| Map equality | `map1 == map2` | ✓ Returns true/false |
| Map update | `map["key1"] = 10` | ✓ Works |

## What Doesn't Work

| Feature | Example | Issue |
|--------|---------|-------|
| Map printing | `println(map)` | Shows `<map>` instead of content |

## Implementation Details

### Map Storage
- Maps stored in a fixed buffer at `.Lmap_buf`
- Format: `[num_entries:4][key1:8][val1:8][key2:8][val2:8]...`
- Each map variable stores offset into the buffer

### Map Equality (`==`)
- Works by comparing map buffer offsets
- Both `MapLit` and map variables recognized via `var_is_map`

### Map Access (`map[key]`)
- Handled in `IndexExpr` codegen
- Looks up key at offset 12 in map buffer (key at offset 4, value at offset 12)

## Attempted: Full Map Printing

Tried to implement full map printing with loop through entries:
- Printed opening brace "{"
- Attempted to iterate through entries
- Count keys and print as strings
- Print ": " separator
- Print integer values
- Print ", " between entries
- Print closing brace "}"

**Result**: Crashed (segfault) - complex loop logic with many registers

The map printing requires careful register management and the complex x86_64 code caused issues. Reverted to placeholder.

## Current Output

```
Official:
{"key1": 1, "key2": 2, "key3": 3}
1
true
{"key1": 10, "key2": 2, "key3": 3}

Ours:
<map>
1
true
<map>
```

## What Works vs Doesn't Work

| Feature | Status |
|---------|--------|
| Map creation `{ "key1": 1, "key2": 2 }` | ✓ Works |
| Map access `m[k]` | ✓ Works |
| Map equality `==` | ✓ Works |
| Map update | ✓ Works |
| Map printing | ✗ Shows `<map>` placeholder |

## Attempted Full Map Printing

Multiple attempts to print full map content failed due to:
- Complex x86_64 code with many registers
- String handling for keys
- Integer-to-string conversion for values
- Loop logic for multiple entries

Reverted to simple placeholder `<map>`.

## Next Steps for Full Map Printing

1. Implement int-to-string conversion for values
2. Implement string key printing
3. Add proper loop with comma separators
4. Handle different value types (Int, String, etc.)

## Effort Estimate

**Full map printing: ~3-4 hours**

Requires:
- Int printing (already exists in println for Int)
- String printing (already exists)  
- Loop with conditional comma printing
- Type-aware value printing
