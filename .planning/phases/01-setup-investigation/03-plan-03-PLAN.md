---
phase: 01-setup-investigation
plan: 03
type: execute
wave: 1
depends_on: []
files_modified:
  - .planning/phases/01-setup-investigation/harness/minimal/004_minimal.mbt
  - .planning/phases/01-setup-investigation/harness/minimal/009_if_minimal.mbt
  - .planning/phases/01-setup-investigation/harness/minimal/009_for_minimal.mbt
  - .planning/phases/01-setup-investigation/harness/minimal/011_minimal.mbt
  - .planning/phases/01-setup-investigation/harness/minimal/013_minimal.mbt
  - .planning/phases/01-setup-investigation/harness/minimal/README.md
autonomous: true
requirements: []
must_haves:
  truths:
    - "Each minimal file isolates exactly one bug pattern"
    - "Minimal files compile (even if they produce wrong output or crash)"
    - "README explains purpose and maps files to bug categories"
  artifacts:
    - path: "harness/minimal/004_minimal.mbt"
      provides: "Function call with 2 args returning sum"
      min_lines: 5
    - path: "harness/minimal/009_if_minimal.mbt"
      provides: "Simple if/else branching"
      min_lines: 5
    - path: "harness/minimal/009_for_minimal.mbt"
      provides: "Simple for loop"
      min_lines: 5
    - path: "harness/minimal/011_minimal.mbt"
      provides: "Enum with 2-3 variants, pattern match"
      min_lines: 10
    - path: "harness/minimal/013_minimal.mbt"
      provides: "Struct with fields, pattern match destructuring"
      min_lines: 10
    - path: "harness/minimal/README.md"
      provides: "Documentation linking files to bug IDs and explaining usage"
      min_lines: 15
  key_links:
    - from: "minimal files"
      to: "bug fixes in later phases"
      via: "used as test input to verify each fix"
      pattern: "run .*minimal.*mbt"
---

<objective>
Create minimal reproduction programs for each failing example to isolate bugs.

Purpose: Smaller test cases make debugging faster and more focused; they reduce variables and make root cause clearer.
Output: 4-5 tiny .mbt files (one per bug) + README.
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
@.planning/phases/01-setup-investigation/02-PLAN-02-SUMMARY.md (if exists)
</context>

<tasks>

<task type="auto">
  <name>Write minimal test files</name>
  <files>harness/minimal/</files>
  <action>
    - Create directory: `mkdir -p harness/minimal`
    - Write `004_minimal.mbt`: a simple function `fn add(x: Int, y: Int) -> Int { x + y }` and a `main` that calls `add(2, 40)` and prints the result. Expected: 42.
    - Write `009_if_minimal.mbt`: `if true { println(1) } else { println(0) }`. Expected: 1. Also may add `if false` variant.
    - Write `009_for_minimal.mbt`: `for i in 0..2 { println(i) }`. Expected: 0,1,2. Also while loop version maybe separate file? Keep one for simplicity.
    - Write `011_minimal.mbt`: define enum `Color { Red | Green | Blue }`, assign `c = Red`, then `match c { Red => println("Red"), Green => println("Green"), Blue => println("Blue") }`. Expected order: Red, but we'll test all.
    - Write `013_minimal.mbt`: define struct `Point(x: Int, y: Int)`, create `p = Point(10, 20)`, match `p { Point(x,y) => println(x) }`. Expected: 10. Also add more branches to test multiple arms.
    - Each file should be self-contained, using `println` (assume println is available in test examples).
  </action>
  <verify>
    # Verify file existence
    test -f harness/minimal/004_minimal.mbt
    test -f harness/minimal/009_if_minimal.mbt
    test -f harness/minimal/009_for_minimal.mbt
    test -f harness/minimal/011_minimal.mbt
    test -f harness/minimal/013_minimal.mbt
  </verify>
  <done>
    All minimal reproduction files created.
  </done>
</task>

<task type="auto">
  <name>Write README for minimal suite</name>
  <files>harness/minimal/README.md</files>
  <action>
    - Write a README.md inside `harness/minimal/` with:
      - Purpose: These files isolate specific bugs for faster debugging.
      - Mapping: 004_minimal -> function return value bug; 009_if_minimal -> conditional branching; 009_for_minimal -> loop construct; 011_minimal -> enum pattern matching; 013_minimal -> struct pattern matching.
      - Usage: How to compile and run each with our compiler and reference compiler.
      - Expected outputs for each (what they should print).
      - Note that these may currently produce wrong output or crash; that's expected.
    - Keep concise but informative.
  </action>
  <verify>
    test -f harness/minimal/README.md && grep -q "Purpose" harness/minimal/README.md
  </verify>
  <done>
    README explains the minimal test suite and its use.
  </done>
</task>

<task type="auto">
  <name>Test compile minimal files</name>
  <files>harness/minimal/</files>
  <action>
    - For each minimal file, run: `moon run cmd/main <file>` to ensure compilation produces an executable (even if runtime misbehaves).
    - Capture that the command exits without error (compilation error would be an error; but codegen crash segfault might happen, treat as expected not error for this check? Actually, if compiler segfaults, our plan should detect; but we want to note that it's failing, not succeed. For verification, we just want to confirm the files are valid MoonBit syntax that the compiler accepts. So we check that `moon run cmd/main` returns 0 (compilation success). Runtime segfault would happen after compiler exits, so compiler returns 0. So okay.)
    - If any file fails to compile (nonzero exit), note which ones and they need fixing before use.
  </action>
  <verify>
    # Loop over files; check each compiles
    for f in harness/minimal/*.mbt; do moon run cmd/main "$f" >/dev/null 2>&1 || exit 1; done
  </verify>
  <done>
    All minimal files compile successfully with our compiler.
  </done>
</task>

</tasks>

<verification>
- All minimal files exist and compile (compiler returns 0)
- README present and informative
- Files map clearly to bug IDs
</verification>

<success_criteria>
- Minimal repros ready for debugging
- Clear documentation of what each tests
- Can be compiled and run individually
</success_criteria>

<output>
After completion, create `.planning/phases/01-setup-investigation/03-PLAN-03-SUMMARY.md`
</output>
