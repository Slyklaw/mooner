---
phase: 01-setup-investigation
plan: 02
type: execute
wave: 1
depends_on: []
files_modified:
  - .planning/phases/01-setup-investigation/harness/harness.sh
  - .planning/phases/01-setup-investigation/baseline_results.md
autonomous: true
requirements: []
must_haves:
  truths:
    - "Harness script compiles and runs all failing examples with both compilers"
    - "Baseline results document records current status and differences"
    - "Outputs captured in a structured directory"
  artifacts:
    - path: "harness/harness.sh"
      provides: "Automated script to compile/run examples and capture output"
      min_lines: 40
    - path: "baseline_results.md"
      provides: "Baseline measurement for 004,009,011,013"
      min_lines: 20
  key_links:
    - from: "harness/harness.sh"
      to: "moon run cmd/main"
      via: "calls our compiler to compile examples"
      pattern: "moon run cmd/main"
    - from: "harness/harness.sh"
      to: "baseline_results.md"
      via: "writes results summary"
      pattern: ">> .*baseline_results.md"
---

<objective>
Create a test harness script and record baseline results for the 4 failing examples.

Purpose: Have a reliable way to reproduce current behavior and measure improvements later.
Output: Harness script + baseline_results.md with captured outputs and diffs.
</objective>

<execution_context>
@/home/box/.config/opencode/get-shit-done/workflows/execute-plan.md
@/home/box/.config/opencode/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/01-setup-investigation/01-RESEARCH.md
</context>

<tasks>

<task type="auto">
  <name>Create harness script</name>
  <files>.planning/phases/01-setup-investigation/harness/harness.sh</files>
  <action>
    - Create directory: `mkdir -p .planning/phases/01-setup-investigation/harness/outputs`
    - Write shell script `harness/harness.sh` with the following logic:
      1. For each example in 004,009,011,013:
         - Locate source file: `examples/mbt_examples/${ex}_*.mbt`
         - Compile with our compiler: `moon run cmd/main "$src"` (ignore errors)
         - If .exe produced, run it and capture stdout/stderr to `outputs/${base}_our.txt`
         - Compile with reference MoonBit compiler: `moon run "$src"` (if possible; fallback: skip if not available)
         - Run reference .exe and capture to `outputs/${base}_ref.txt`
         - Compare outputs: if both succeeded, run `diff -u` and append to baseline_results.md
      2. Write a header to baseline_results.md with date and summary table.
      3. For each example, append a section with statuses and diff (if applicable).
      4. Include error handling: if compilation fails or segfault occurs, note exit code.
      5. Add timeout around execution to avoid hangs.
    - Make script executable: `chmod +x harness/harness.sh`
  </action>
  <verify>
    test -x harness/harness.sh
  </verify>
  <done>
    Harness script exists and is executable.
  </done>
</task>

<task type="auto">
  <name>Run harness to generate baseline</name>
  <files>.planning/phases/01-setup-investigation/baseline_results.md</files>
  <action>
    - Execute `./harness/harness.sh` from the phase directory.
    - Ensure it completes (may take a few minutes); allow failures but record them.
    - Verify that `baseline_results.md` is created with entries for 004, 009, 011, 013.
  </action>
  <verify>
    test -f baseline_results.md && grep -q "004" baseline_results.md && grep -q "009" baseline_results.md
  </verify>
  <done>
    Baseline results document exists with measured outputs for all failing examples.
  </done>
</task>

<task type="auto">
  <name>Verify harness outputs</name>
  <files>.planning/phases/01-setup-investigation/outputs/</files>
  <action>
    - List the `outputs/` directory; ensure files: 004_our.txt, 004_ref.txt, 009_our.txt, 009_ref.txt, 011_our.txt, 011_ref.txt, 013_our.txt, 013_ref.txt exist (at least some may be empty if compilation failed).
    - Print a short summary: for each example, indicate whether our compiler produced an executable and whether it ran.
  </action>
  <verify>
    ls outputs/ | wc -l | grep -q '[1-9]'  # at least one file
  </verify>
  <done>
    Output capture directory populated.
  </done>
</task>

</tasks>

<verification>
- Harness script present, executable, and runs to completion
- baseline_results.md exists and contains entries for all 4 failing examples
- Outputs directory has captured files
</verification>

<success_criteria>
- Script can be run repeatedly
- Baseline clearly documents current state (including segfaults, wrong outputs, etc.)
</success_criteria>

<output>
After completion, create `.planning/phases/01-setup-investigation/02-PLAN-02-SUMMARY.md`
</output>
