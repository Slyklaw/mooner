# Pitfalls: Compiler Codegen Bugfix

## Pitfall 1: Stack Frame Misalignment

**Symptom:** Function calls work but return values corrupted; segfaults when functions with arguments are called.

**Cause:** The System V ABI requires the stack to be 16-byte aligned at call sites. If `call` pushes an 8-byte return address, the stack just before `call` should be 16-byte aligned. Misalignment can break `movaps` instructions and some library calls.

**Detection:**
- Check `rsp` modulo 16 in function prologues (add debug trace to print `rsp & 0xF`).
- Observe patterns: functions with more args fail, functions with fewer args work.

**Prevention:**
- In `codegen_func`, ensure prologue subtracts a multiple of 16 from `rsp`.
- When emitting `call`, account for the return address push to keep alignment for the callee.
- Use `and rsp, -16` before calls if necessary (but better to allocate correctly upfront).

**Phase:** Phase 2 (Function Calls)

---

## Pitfall 2: Return Value Overwrite

**Symptom:** A function returning a constant (42) instead returns a completely different value (80), which is actually an argument value.

**Cause:** The codegen may be using the same stack slot or register for both arguments and return value. If arguments are placed at certain offsets from `rbp`, the return value might be placed in an overlapping location or the caller might overwrite the callee's return value after `call`.

**Detection:**
- Minimal test: `fn add(x, y) { x + y }` called with `add(2, 40)` expecting 42.
- Trace argument placement and return emission. Check where the sum is stored before `ret`.
- Verify caller doesn't modify `rax` after `call` before using result.

**Prevention:**
- Callee must place return value in `rax` (for integers) *before* `ret`.
- Caller must expect result in `rax` immediately after `call` and not overwrite it.
- Ensure no spills or pushes between `call` and reading `rax`.

**Phase:** Phase 2 (Function Calls)

---

## Pitfall 3: Relative Jump Offset Errors

**Symptom:** Program crashes immediately when encountering `if`, `for`, or `while`. Output may start correctly then segfault.

**Cause:** x86-64 conditional jumps (`Jcc`) and unconditional jumps (`Jmp`) use signed relative displacements: `disp = target - next_ip`. If the displacement is miscomputed (e.g., using absolute address, forgetting sign-extend, using wrong size), the CPU jumps to garbage.

**Detection:**
- Replace loop body with `println(1);` and check if it runs at all.
- Emit a single `jmp` to a known label that does `ret` – does it return cleanly?
- Dump machine code bytes and disassemble to see jump targets.

**Prevention:**
- Central function: `emit_jmp_rel(target_label)` that computes `disp = label_addr - (current_pos + instruction_size)`.
- For conditional jumps, use `emit_jcc_rel(cond, target_label)`.
- Maintain a label dictionary mapping labels to their final addresses; resolve backpatches after codegen for forward references.

**Phase:** Phase 3 (Control Flow)

---

## Pitfall 4: Label Addresses Not Finalized

**Symptom:** Jumps land in the middle of instructions, or backwards jumps go to wrong loop entry.

**Cause:** Labels are referenced before their final position is known. If offsets are computed prematurely (using 0 or placeholder), jumps go astray.

**Detection:**
- Check label handling: does `codegen` emit placeholder and later patch? Or does it assume linear order?
- Forward jumps (to later labels) are especially prone.

**Prevention:**
- Two-pass approach: emit code, record patch sites for unknown labels; second pass resolves patches.
- Or use a label table with current position placeholder and a list of fixup locations to patch when label position becomes known.

**Phase:** Phase 3 (Control Flow)

---

## Pitfall 5: Enum Discriminant Duplication

**Symptom:** Pattern match on enum with 4 variants only ever hits first variant (e.g., always prints Red).

**Cause:** All enum constants may be given the same discriminant value (e.g., 0), or pattern matching compares wrong memory offset.

**Detection:**
- Inspect how enum literals are encoded. For example, `Red` might be represented as `(tag=0, payload=())`, `Green` as `(tag=0, payload=())` by mistake.
- Check codegen for enum constructor: does it set the tag field correctly?

**Prevention:**
- Define enum layout: tag occupies lowest bits or a dedicated slot.
- In codegen for each variant, assign distinct constant tag (0,1,2,...).
- In pattern match, compare the tag value; only when equal extract payload.

**Phase:** Phase 4 (Enums)

---

## Pitfall 6: Pattern Branch Variable Capture

**Symptom:** Inside a pattern match branch, bound variables hold garbage or values from another branch.

**Cause:** The code that binds variables in a pattern may be reusing the same stack slot across branches, or the field offsets are computed incorrectly for that variant's payload.

**Detection:**
- Simple pattern: `match point { Point(x, y) => println(x) }` prints 0 instead of expected 10.
- Check how struct fields are accessed: `point + offset` should yield correct addresses.

**Prevention:**
- Ensure each branch creates its own bindings; if using stack, allocate fresh slots or use registers properly.
- Verify struct layout: fields aligned according to their types. Offsets must match packing rules.
- In pattern match codegen, for each arm, generate appropriate loads from the scrutinee address plus known offsets.

**Phase:** Phase 5 (Pattern Matching)

---

## Pitfall 7: Register Clobbering Across Calls

**Symptom:** Values computed before a function call are corrupted after the call, unless saved in callee-saved registers or on stack.

**Cause:** Caller-saved registers (rax, rcx, rdx, rsi, rdi, r8-r11, xmm0-xmm15) can be overwritten by callee. If caller expects them to survive, it must spill them before `call` and reload after.

**Detection:**
- Check codegen for expressions like `a + f(b)` where `a` is computed first, then `f(b)` called, then `a` needed for `+`. If `a` lives in a caller-saved register, it may die.
- Look for missing spills around `emit_inst(Call, ...)`.

**Prevention:**
- Before emitting a call, spill any live values that are not in callee-saved registers.
- Alternatively, assign long-lived values to callee-saved registers (rbx, rbp, r12-r15).

**Phase:** Phase 2 (Function Calls) – could impact all later phases.

---

## Pitfall 8: Float/Simd Register Stacking

**Symptom:** Floating-point operations produce slightly different string output (007) or pattern matching on float fields misbehaves.

**Cause:** Floating-point values may be passed/returned in xmm registers; conversion to string (Ryu algorithm) might have minor rounding differences. Also, mixing SSE and x87 could cause differences.

**Detection:**
- Compare outputs bitwise; if differences are only in last few digits, it's likely a rounding issue.
- Ensure float-to-string conversion uses the same algorithm as reference (double_ryu_nonjs.mbt).

**Prevention:**
- For v1, accept minor float precision differences per goal.
- Ensure float values are passed correctly in xmm0-xmm7 per SysV ABI.

**Phase:** Phase 2 (Function Calls) if float args/returns appear; otherwise monitor.

---

## Pitfall 9: Codegen State Mutation

**Symptom:** After generating one function, subsequent functions produce broken code even though they are independent.

**Cause:** The `CodeGen` struct isn't fully reset between functions. Emit position, label table, or temporary buffers carry over.

**Detection:**
- Generate two simple functions in the same file; see if the second fails even though it's identical to first.
- Check `codegen_func` entry: does it clear state? (maybe it should create fresh substate or reset fields)

**Prevention:**
- Either reset `CodeGen` before each top-level function, or use a fresh `CodeGen` instance per function.
- Ensure label names are unique (e.g., `.L_fn1_loop`, `.L_fn2_loop`).

**Phase:** Phase 2 (Function Calls) – early in the process.

---

## Pitfall 10: Over-optimistic Refactoring

**Symptom:** After making one fix, previously passing tests start failing.

**Cause:** A change intended to fix one bug inadvertently alters codegen for another construct. Common when adjusting offset calculations or shared helper functions.

**Detection:**
- After each commit, run full `test_examples.sh`. Any regression is a red flag.

**Prevention:**
- Make minimal, targeted changes. Commit after each bug fix is verified.
- If a change affects multiple areas, evaluate risk: maybe split into two stages.

**Phase:** All phases (ongoing discipline).

---

## Summary of Pitfall-Phase Mapping

| Pitfall | Primary Phase | Secondary Impact |
|---------|---------------|------------------|
| Stack misalignment | 2 | 3,4,5 |
| Return overwrite | 2 | all |
| Jump offset errors | 3 | all |
| Label address bugs | 3 | all |
| Enum duplication | 4 | 5 |
| Pattern variable capture | 5 | – |
| Register clobbering | 2 | 3,4,5 |
| Float issues | 2 (if floats) | – |
| State mutation | 2 | all |
| Regression from refactor | all | – |

Be vigilant. Run tests after every change.
