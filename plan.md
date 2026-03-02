# Plan: Debug Self-Hosted Compiler Examples

## Status Summary

| Example | Status | Issue |
|---------|--------|-------|
| 001_hello | PASS | Fixed heredoc syntax - correctly handles #| start/end markers |
| 002_variable | PASS | |
| 003_basic_constants | PASS | |
| 004_basic_function | PASS | |
| 005_basic_array | PASS | Fixed array indexing off-by-one |
| 006_basic_string | FAIL | String interpolation not working |
| 007_basic_tuple | FAIL | Float tuple printing shows `<tuple>` |
| 008_basic_map | FAIL | Map not supported |
| 009_basic_control_flows | PASS | |
| 010_basic_struct | PASS | |
| 011_basic_enum | FAIL | String interpolation in enum derive |
| 012_basic_test | FAIL | Test framework not supported |
| 013_pattern_matching | FAIL | Pattern matching incomplete |

**7 passed, 6 failed**

## Debugging Order

### Phase 1: High Impact, Low Complexity

1. **005_basic_array** - Array indexing returns wrong value
   - Expected: `2`, Got: `1`
   - Likely off-by-one error in codegen or array access

### Phase 2: String Interpolation

2. **006_basic_string** - String interpolation
3. **011_basic_enum** - String interpolation in derive

### Phase 3: Float/Tuple

4. **007_basic_tuple** - Float tuple printing

### Phase 4: Advanced Features

5. **008_basic_map** - Map support
6. **012_basic_test** - Test framework
7. **013_pattern_matching** - Pattern matching

### Phase 5: Complex Issues

8. **001_hello** - Multiline string crash
   - FIXED: MoonBit heredoc uses #| for both start AND end markers
   - Fixed lexer to detect end marker (#| followed by newline) vs dedent prefix (#| followed by content)
   - Also handles backslash as literal in heredocs

## Recent Fixes

- 005_basic_array: Fixed array indexing (off-by-one in codegen)
- 006_basic_string: Added unicode escape `\u{XXXX}` support in lexer
- 001_hello: Fixed heredoc syntax - uses #| for start/end, correctly detects end marker

## Verification Command

```bash
for i in 001 002 003 004 005 006 007 008 009 010 011 012 013; do
  file=$(ls examples/mbt_examples/${i}_*.mbt 2>/dev/null | head -1)
  if [ -n "$file" ]; then
    moon run cmd/main "$file" 2>/dev/null
    if [ -f "${file%.mbt}.exe" ]; then
      chmod +x "${file%.mbt}.exe"
      ./"${file%.mbt}.exe" > "/tmp/our_${i}.txt" 2>&1
      moon run "$file" > "/tmp/moon_${i}.txt" 2>&1
      if diff -q "/tmp/moon_${i}.txt" "/tmp/our_${i}.txt" > /dev/null 2>&1; then
        echo "$i: PASS"
      else
        echo "$i: FAIL"
      fi
    else
      echo "$i: COMPILE ERROR"
    fi
  fi
done
```

## Tasks

- [x] 005_basic_array: Fix array indexing
- [ ] 006_basic_string: Implement string interpolation
- [ ] 007_basic_tuple: Fix float tuple printing
- [ ] 008_basic_map: Add map support
- [ ] 011_basic_enum: Fix string interpolation in derive
- [ ] 012_basic_test: Add test framework support
- [ ] 013_pattern_matching: Complete pattern matching
- [x] 001_hello: Fixed heredoc syntax (#| for start/end, detect end marker vs dedent prefix)

---

*Created: 2026-03-01*
*Updated: 2026-03-02 - Fixed 001_hello heredoc, now 7 passed, 6 failed*
