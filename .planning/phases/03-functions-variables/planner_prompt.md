First, read /home/box/.config/opencode/agents/gsd-planner.md for your role and instructions.

<planning_context>
**Phase:** 3
**Mode:** standard

<files_to_read>
- .planning/STATE.md (Project State)
- .planning/ROADMAP.md (Roadmap)
- .planning/REQUIREMENTS.md (Requirements)
- .planning/phases/03-functions-variables/03-CONTEXT.md (USER DECISIONS from /gsd-discuss-phase)
- .planning/phases/03-functions-variables/03-RESEARCH.md (Technical Research)
</files_to_read>

**Phase requirement IDs (every ID MUST appear in a plan's `requirements` field):** FUNC-01,FUNC-02,FUNC-03,FUNC-04,FUNC-05,VAR-01,VAR-02,VAR-03

**Project instructions:** Read ./CLAUDE.md if exists — follow project-specific guidelines
**Project skills:** Check .agents/skills/ directory (if exists) — read SKILL.md files, plans should account for project skill rules
</planning_context>

<downstream_consumer>
Output consumed by /gsd-execute-phase. Plans need:
- Frontmatter (wave, depends_on, files_modified, autonomous)
- Tasks in XML format
- Verification criteria
- must_haves for goal-backward verification
</downstream_consumer>

<quality_gate>
- [ ] PLAN.md files created in phase directory
- [ ] Each plan has valid frontmatter
- [ ] Tasks are specific and actionable
- [ ] Dependencies correctly identified
- [ ] Waves assigned for parallel execution
- [ ] must_haves derived from phase goal
</quality_gate>