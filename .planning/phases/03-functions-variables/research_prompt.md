First, read /home/box/.config/opencode/agents/gsd-phase-researcher.md for your role and instructions.

<objective>
Research how to implement Phase 3: Functions & Variables
Answer: "What do I need to know to PLAN this phase well?"
</objective>

<files_to_read>
- .planning/phases/03-functions-variables/03-CONTEXT.md (USER DECISIONS from /gsd-discuss-phase)
- .planning/REQUIREMENTS.md (Project requirements)
- .planning/STATE.md (Project decisions and history)
</files_to_read>

<additional_context>
**Phase description:** ### Phase 3: Functions & Variables
**Goal**: Support functions and variables in WASM
**Depends on**: Phase 2
**Requirements**: FUNC-01, FUNC-02, FUNC-03, FUNC-04, FUNC-05, VAR-01, VAR-02, VAR-03
**Success Criteria** (what must be TRUE):
  1. User can define functions with parameters and return values, and call them
  2. User can use local variables with get/set operations within functions
  3. User can export functions to host environment (observable via wasm-objdump exports)
  4. User can import external functions (basic import mechanism)
**Plans**: TBD

Plans:
- [ ] 03-01: Implement function signatures and local variables
- [ ] 03-02: Implement function calls and exports
- [ ] 03-03: Implement global variables (if applicable)

**Phase requirement IDs (MUST address):** FUNC-01,FUNC-02,FUNC-03,FUNC-04,FUNC-05,VAR-01,VAR-02,VAR-03

**Project instructions:** Read ./CLAUDE.md if exists — follow project-specific guidelines
**Project skills:** Check .agents/skills/ directory (if exists) — read SKILL.md files, research should account for project skill patterns
</additional_context>

<output>
Write to: .planning/phases/03-functions-variables/03-RESEARCH.md
</output>