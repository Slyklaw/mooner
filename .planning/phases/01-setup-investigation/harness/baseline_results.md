# Baseline Test Results
Generated: Wed Mar 11 03:03:00 AM PDT 2026

## Summary
| Example | Our Compiler | Reference Compiler | Status |
|---------|-------------|-------------------|--------|

| 004_basic_function | ✓ OK | ✓ OK | ✗ DIFF |
| 009_basic_control_flows | ✗ FAILED | ✓ OK | ✗ DIFF |
| 011_basic_enum | ✗ FAILED | ✓ OK | ✗ DIFF |
| 013_pattern_matching | ✗ FAILED | ✓ OK | ✗ DIFF |

## Detailed Results

### 004_basic_function
- **Our Compiler**: ✓ OK
- **Reference**: ✓ OK
- **Status**: DIFF

**Differences (first 20 lines):**
```diff
--- outputs/004_basic_function_ref.txt
+++ outputs/004_basic_function_our.txt
@@ -1,2 +1,2 @@
-42
+80
```

### 009_basic_control_flows
- **Our Compiler**: ✗ FAILED
- **Reference**: ✓ OK
- **Status**: DIFF

**Note**: One or both compilers failed to produce runnable output.
Our compiler crashed with segmentation fault.

### 011_basic_enum
- **Our Compiler**: ✗ FAILED
- **Reference**: ✓ OK
- **Status**: DIFF

**Note**: One or both compilers failed to produce runnable output.
Our compiler exited with code 58.

### 013_pattern_matching
- **Our Compiler**: ✗ FAILED
- **Reference**: ✓ OK
- **Status**: DIFF

**Note**: One or both compilers failed to produce runnable output.
Our compiler produced a parsing error and crashed with segmentation fault.

