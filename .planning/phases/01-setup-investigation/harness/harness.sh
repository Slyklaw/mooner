#!/bin/bash

# Test Harness for MoonBit Compiler Bugfix Project
# Compares our compiler output with the official MoonBit compiler
# Usage: ./harness.sh from this directory

set -e  # Exit on error

echo "=== MoonBit Compiler Test Harness ==="
echo "Starting baseline test run at $(date)"
echo

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Compute project root (four levels up from this script)
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../../" && pwd)"
echo "Project root: $PROJECT_ROOT"
echo

# Create outputs directory if not exists
mkdir -p outputs

# Initialize baseline results file
BASELINE_FILE="baseline_results.md"
echo "# Baseline Test Results" > "$BASELINE_FILE"
echo "Generated: $(date)" >> "$BASELINE_FILE"
echo >> "$BASELINE_FILE"
echo "## Summary" >> "$BASELINE_FILE"
echo "| Example | Our Compiler | Reference Compiler | Status |" >> "$BASELINE_FILE"
echo "|---------|-------------|-------------------|--------|" >> "$BASELINE_FILE"
echo >> "$BASELINE_FILE"

# Test examples (failures in official suite)
EXAMPLES=(004 009 011 013)

# Helper: run with timeout
run_with_timeout() {
  local cmd="$1"
  local timeout_secs="${2:-5}"
  timeout "$timeout_secs" bash -c "$cmd" 2>&1
  local exit_code=$?
  if [ $exit_code -eq 124 ]; then
    echo "TIMEOUT"
    return 124
  fi
  return $exit_code
}

# Helper: compile and run with our compiler
compile_and_run_ours() {
  local src="$1"
  local base="$2"
  local out_file="outputs/${base}_our.txt"
  
  echo "  → Compiling with OUR compiler: $base"
  if moon run cmd/main "$src" 2>&1 | tee "$out_file"; then
    local exe="${src%.mbt}.exe"
    if [ -f "$exe" ]; then
      # Make executable
      chmod +x "$exe"
      echo "  → Running our executable..." | tee -a "$out_file"
      local exe_dir="$(dirname "$exe")"
      local exe_name="$(basename "$exe")"
      (cd "$exe_dir" && run_with_timeout "./$exe_name" 5) 2>&1 | tee -a "$out_file"
      local exit_code=${PIPESTATUS[0]}
      if [ $exit_code -eq 0 ]; then
        echo "  ✓ Completed (exit code: $exit_code)" | tee -a "$out_file"
        return 0
      else
        echo "  ✗ Execution failed (exit code: $exit_code)" | tee -a "$out_file"
        return 1
      fi
    else
      echo "  ✗ Executable not found: $exe" | tee -a "$out_file"
      return 1
    fi
  else
    echo "  ✗ Compilation failed" | tee -a "$out_file"
    return 1
  fi
}

# Helper: compile and run with reference compiler
compile_and_run_ref() {
  local src="$1"
  local base="$2"
  local out_file="outputs/${base}_ref.txt"
  
  echo "  → Running REFERENCE compiler (moon run): $base"
  # Just run moon directly; it compiles and runs, capturing all output
  if moon run "$src" 2>&1 | tee "$out_file"; then
    echo "  ✓ Completed" | tee -a "$out_file"
    return 0
  else
    echo "  ✗ Execution failed" | tee -a "$out_file"
    return 1
  fi
}

# Main test loop
for ex in "${EXAMPLES[@]}"; do
  echo "========================================"
  echo "Testing Example $ex"
  echo "========================================"
  
  # Find source file
  src=$(find "$PROJECT_ROOT/examples/mbt_examples" -name "${ex}_*.mbt" -type f | head -1)
  if [ -z "$src" ]; then
    echo "  ✗ Source file not found for example $ex"
    echo "| $ex | NOT FOUND | NOT FOUND | SKIPPED |" >> "$BASELINE_FILE"
    continue
  fi
  base=$(basename "$src" .mbt)
  echo "  Source: $src"
  echo "  Base: $base"
  
  # Clean up any existing .exe from previous runs
  rm -f "${src%.mbt}.exe"
  
  # Run our compiler
  if compile_and_run_ours "$src" "$base"; then
    our_status="✓ OK"
  else
    our_status="✗ FAILED"
  fi
  
  # Clean up our .exe before reference run
  rm -f "${src%.mbt}.exe"
  
  # Run reference compiler
  if compile_and_run_ref "$src" "$base"; then
    ref_status="✓ OK"
  else
    ref_status="✗ FAILED"
  fi
  
  # Compare outputs if both succeeded
  our_out="outputs/${base}_our.txt"
  ref_out="outputs/${base}_ref.txt"
  
  if [ -f "$our_out" ] && [ -f "$ref_out" ]; then
    echo "  → Comparing outputs..."
    diff_out="outputs/${base}_diff.txt"
    if diff -u "$ref_out" "$our_out" > "$diff_out" 2>&1; then
      echo "  ✓ Outputs match!"
      status="MATCH"
      echo "| $base | $our_status | $ref_status | ✓ MATCH |" >> "$BASELINE_FILE"
    else
      echo "  ✗ Outputs differ (see $diff_out)"
      status="DIFF"
      echo "| $base | $our_status | $ref_status | ✗ DIFF |" >> "$BASELINE_FILE"
    fi
  else
    echo "  → Cannot compare (one or both executions failed)"
    status="INCOMPLETE"
    echo "| $base | $our_status | $ref_status | ⚠ INCOMPLETE |" >> "$BASELINE_FILE"
  fi
  
  # Clean up .exe
  rm -f "${src%.mbt}.exe"
  echo
done

echo "========================================"
echo "Baseline test run complete at $(date)"
echo "Results saved to: $BASELINE_FILE"
echo "Outputs directory: outputs/"
echo "========================================"
