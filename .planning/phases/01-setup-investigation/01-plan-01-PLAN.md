---
phase: 01-setup-investigation
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - codegen.mbt
  - cmd/main/main.mbt
autonomous: true
requirements: []
must_haves:
  truths:
    - "Codegen supports debug tracing via runtime flag"
    - "CLI accepts --debug-codegen flag and passes it to CodeGen"
    - "Tracing prints instruction emissions when enabled"
  artifacts:
    - path: "codegen.mbt"
      provides: "Debug tracing infrastructure (debug_level, trace_instruction)"
      min_lines: 5
    - path: "cmd/main/main.mbt"
      provides: "CLI flag handling for --debug-codegen"
      min_lines: 3
  key_links:
    - from: "cmd/main/main.mbt"
      to: "codegen.mbt"
      via: "passing debug_level to CodeGen constructor"
      pattern: "CodeGen\\(.*debug_level"
---

<objective>
Add debug tracing infrastructure to codegen and expose a CLI flag to control it.

Purpose: Enable instruction-level tracing to diagnose codegen bugs in later phases.
Output: Codegen can emit assembly-like listings conditioned on a flag.
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
  <name>Add debug infrastructure to codegen.mbt</name>
  <files>codegen.mbt</files>
  <action>
    - In the CodeGen struct definition, add a field: `debug_level : Int`
    - Add a public function `trace_instruction(pos: Int, opcode: String, operands: Array[String])` that checks `if debug_level >= 1` and prints to stderr or stdout.
    - In the `emit_inst` function, after emitting bytes, call `trace_instruction(current_pos, mnemonic, operands_string)`.
    - Use the existing `emit_inst` context to format operands as readable (registers, immediates).
    - Do not break existing code; make sure conditional is compile-time evaluatable (MoonBit may optimize away dead code if debug_level is const, but we keep it simple).
  </action>
  <verify>
    moon build succeeds (no compile errors in codegen.mbt)
  </verify>
  <done>
    Codegen has debug infrastructure and emits no trace when debug_level=0.
  </done>
</task>

<task type="auto">
  <name>Add --debug-codegen flag to CLI</name>
  <files>cmd/main/main.mbt</files>
  <action>
    - Parse command-line arguments to accept: `--debug-codegen N` where N is 0,1,2,3.
    - When invoking the compiler (likely `Compiler.compile` or similar), pass the debug level to the CodeGen instance (or set a global that codegen reads).
    - If no flag provided, default debug_level = 0.
    - Ensure the flag is printed in `--help` output.
  </action>
  <verify>
    moon run cmd/main --help | grep -q "debug-codegen"
  </verify>
  <done>
    CLI accepts the flag and it affects debug output when running.
  </done>
</task>

<task type="auto">
  <name>Verify instrumentation works</name>
  <files>-</files>
  <action>
    - Run: `moon run cmd/main examples/001_hello.mbt --debug-codegen 1` should produce normal output plus instruction trace lines.
    - Run: `moon run cmd/main examples/001_hello.mbt` (no flag) should produce no trace lines.
    - Ensure both invocations produce identical executable output (same .exe behavior).
  </action>
  <verify>
    # Check that with flag we get trace; without we don't.
    moon run cmd/main examples/001_hello.mbt --debug-codegen 1 2>/dev/null | grep -q "mov" && echo "Trace present"
    moon run cmd/main examples/001_hello.mbt 2>/dev/null | grep -q "mov" && echo "Trace present" || echo "No trace"
  </verify>
  <done>
    Flag toggles trace emission; executables still work.
  </done>
</task>

</tasks>

<verification>
- All three tasks complete without errors.
- Codegen instrumentation functional.
</verification>

<success_criteria>
- Debug flag available in CLI
- Instruction tracing prints when enabled
- No trace when disabled
- Build passes
</success_criteria>

<output>
After completion, create `.planning/phases/01-setup-investigation/01-PLAN-01-SUMMARY.md`
</output>
