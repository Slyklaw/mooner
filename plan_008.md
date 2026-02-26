# Plan: Complete Example 008 (basic_map)

## Goal
Make example 008 output match official MoonBit compiler:
```
{"key1": 1, "key2": 2, "key3": 3}
1
true
{"key1": 10, "key2": 2, "key3": 3}
```

## Current State

### What Works
- Map literal parsing (`{ "key1": 1, "key2": 2 }`) ✓
- Type checking (TMap type) ✓
- MapLit code generation stores entries in buffer: `[num_entries:4][key:8][value:8]...` ✓
- `var_is_map` tracking correctly identifies map variables ✓
- Map index expression handler exists (linear search) ✓

### What Doesn't Work
- Map printing: shows `<map>` placeholder
- Map index access: returns wrong value (probably 0)
- Map equality: probably returns wrong value
- Map update (`map["key"] = value`): probably not working

## Tasks

### Phase 1: Fix Map Index Access (HIGH PRIORITY)

The test `println(map1["key1"])` should print `1`, not `0` or wrong value.

**Task 1.1: Debug why IndexExpr returns wrong value**
- [ ] Add debug output in IndexExpr handler to see what's being searched
- [ ] Verify map offset is being passed correctly
- [ ] Verify key comparison is working

**Task 1.2: Fix map key lookup**
- [ ] Current implementation searches linear through buffer
- [ ] Keys are stored as integers (not string pointers)
- [ ] Need to verify the key being searched matches stored key
- [ ] Need to return the correct value offset when found

**Task 1.3: Test index access**
- [ ] Create test: `let m = { "a": 5 }; println(m["a"])` → should print `5`

---

### Phase 2: Implement Map Printing (MEDIUM PRIORITY)

Need to print `{"key1": 1, "key2": 2, "key3": 3}` instead of `<map>`.

**Task 2.1: Understand the crash**
- [ ] Previous attempt crashed after printing 'A'
- [ ] Issue: register state after codegen_expr may be wrong
- [ ] Need to save/restore ALL callee-saved registers properly

**Task 2.2: Implement safe map printing**
- [ ] Save all callee-saved registers: rbx, r12, r13, r14, r15
- [ ] After `codegen_expr(arg)`, rax contains map offset
- [ ] Calculate map base address: `.Lmap_buf + offset`
- [ ] Load num_entries from offset 0
- [ ] Loop through entries, printing each key:value pair

**Task 2.3: Handle string key printing**
- [ ] Keys are stored as integers (not pointers to string data)
- [ ] Option A: Print key as integer (e.g., `12345: 1`)
- [ ] Option B: Store string length/data and print properly
- [ ] Recommendation: Start with integer keys for simplicity

**Task 2.4: Test map printing**
- [ ] `let m = { "a": 1, "b": 2 }; println(m)` → `{1: 1, 2: 2}` (integer keys)

---

### Phase 3: Map Update (MEDIUM PRIORITY)

Test: `map1["key1"] = 10`

**Task 3.1: Find Assign handler for IndexExpr**
- [ ] In codegen.mbt, find where `arr[idx] = value` is handled
- [ ] Add check for `is_map_expr(arr)` 
- [ ] If map, use map_insert logic instead of array element store

**Task 3.2: Implement map value update**
- [ ] Search for key in map buffer
- [ ] Update value at found offset
- [ ] If key not found, optionally add new entry

**Task 3.3: Test map update**
- [ ] `let m = { "a": 1 }; m["a"] = 5; println(m["a"])` → `5`

---

### Phase 4: Map Equality (MEDIUM PRIORITY)

Test: `println(map1 == map2)` should print `true`

**Task 4.1: Find equality comparison**
- [ ] Where is `==` handled in codegen?
- [ ] Add check for both operands being maps

**Task 4.2: Implement map equality**
- [ ] Compare num_entries
- [ ] Compare each key-value pair
- [ ] Return 1 if equal, 0 if not

**Task 4.3: Test map equality**
- [ ] `let m1 = { "a": 1 }; let m2 = { "a": 1 }; println(m1 == m2)` → `true`

---

### Phase 5: String Keys (LOW PRIORITY - Optional)

Current implementation stores keys as integers. To print actual string keys:

**Task 5.1: Store string data with keys**
- [ ] In MapLit, store string pointer instead of just integer
- [ ] String pointer points to: `[length:4][chars...]`

**Task 5.2: Print string keys**
- [ ] In map printing loop, detect string pointer
- [ ] Call string printing logic for keys

---

## Implementation Notes

### Map Buffer Format (current)
```
[offset 0] num_entries: 4 bytes
[offset 4] key0: 8 bytes  
[offset 12] value0: 8 bytes
[offset 20] key1: 8 bytes
[offset 28] value1: 8 bytes
...
```

### Map Index Lookup Algorithm
```
Input: map_offset, search_key
1. base = .Lmap_buf + map_offset
2. num_entries = read(base + 0)
3. For i in 0..num_entries:
   a. key_i = read(base + 4 + i * 16)
   b. if key_i == search_key:
      return read(base + 4 + i * 16 + 8)  // return value
4. Return 0 (not found)
```

### Map Printing Algorithm
```
Input: map_offset
1. Save callee-saved registers
2. base = .Lmap_buf + map_offset
3. num_entries = read(base + 0)
4. Print "{"
5. For i in 0..num_entries:
   a. key_i = read(base + 4 + i * 16)
   b. value_i = read(base + 4 + i * 16 + 8)
   c. Print "key_i: value_i"
   d. If i < num_entries - 1, print ", "
6. Print "}"
7. Restore callee-saved registers
```

## Testing Strategy

Create incremental test files:
1. `test_map_simple.mbt` - single entry, single print
2. `test_map_index.mbt` - test index access
3. `test_map_multi.mbt` - multiple entries
4. `test_map_update.mbt` - test assignment
5. `test_map_eq.mbt` - test equality

Each test should be verified against official MoonBit compiler.

## Dependencies

- Task 1.1 → Task 1.2 → Task 1.3
- Task 2.1 → Task 2.2 → Task 2.3 → Task 2.4
- Task 3.2 depends on Task 1.2 (key search)
- Task 4.2 depends on Task 1.2 (key search)
- Task 5.1 depends on Task 2.4

## Success Criteria

- [ ] `println({ "a": 1 })` prints something (not crash)
- [ ] `println({ "a": 1 })` prints `{1: 1}` or similar
- [ ] `let m = { "a": 1 }; println(m["a"])` prints `1`
- [ ] `let m = { "a": 1 }; m["a"] = 5; println(m["a"])` prints `5`
- [ ] `let m1 = { "a": 1 }; let m2 = { "a": 1 }; println(m1 == m2)` prints `true`
- [ ] Example 008 output matches official compiler EXACTLY
