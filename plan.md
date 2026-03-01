# Plan: Debug Self-Hosted Compiler Examples

## Status Summary

| Example | Status | Issue |
|---------|--------|-------|
| 001_hello | FAIL | Multiline string (heredoc) not printing |
| 002_variable | PASS | |
| 003_basic_constants | PASS | |
| 004_basic_function | PASS | |
| 005_basic_array | FAIL | Array indexing returns wrong value |
| 006_basic_string | FAIL | String interpolation not working |
| 007_basic_tuple | FAIL | Float tuple printing shows `<tuple>` |
| 008_basic_map | FAIL | Map not supported |
| 009_basic_control_flows | PASS | |
| 010_basic_struct | PASS | |
| 011_basic_enum | FAIL | String interpolation in enum derive |
| 012_basic_test | FAIL | Test framework not supported |
| 013_pattern_matching | FAIL | Pattern matching incomplete |

**5 passed, 8 failed**

## Debugging Order

### Phase 1: High Impact, Low Complexity

1. **005_basic_array** - Array indexing returns wrong value
   - Expected: `2`, Got: `1`
   - Likely off-by-one error in codegen or array access

2. **001_hello** - Multiline string heredoc not printing
   - Simple test case, likely lexer/parser issue

### Phase 2: String Interpolation

3. **006_basic_string** - String interpolation
4. **011_basic_enum** - String interpolation in derive

### Phase 3: Float/Tuple

5. **007_basic_tuple** - Float tuple printing

### Phase 4: Advanced Features

6. **008_basic_map** - Map support
7. **012_basic_test** - Test framework
8. **013_pattern_matching** - Pattern matching

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

- [ ] 001_hello: Debug heredoc/multiline string
- [ ] 005_basic_array: Fix array indexing
- [ ] 006_basic_string: Implement string interpolation
- [ ] 007_basic_tuple: Fix float tuple printing
- [ ] 008_basic_map: Add map support
- [ ] 011_basic_enum: Fix string interpolation in derive
- [ ] 012_basic_test: Add test framework support
- [ ] 013_pattern_matching: Complete pattern matching

---

*Created: 2026-03-01*
