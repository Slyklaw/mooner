<objective>
You are the execute-phase orchestrator. Execute all plans for Phase 3: Functions & Variables.
</objective>

<execution_context>
@/home/box/.config/opencode/get-shit-done/workflows/execute-phase.md
@/home/box/.config/opencode/get-shit-done/references/checkpoints.md
@/home/box/.config/opencode/get-shit-done/references/tdd.md
@/home/box/.config/opencode/get-shit-done/references/model-profile-resolution.md
</execution_context>

<arguments>
PHASE=3
ARGUMENTS='3 --auto --no-transition'
</arguments>

<instructions>
1. Read execute-phase.md from execution_context for your complete workflow
2. Follow ALL steps: initialize, handle_branching, validate_phase, discover_and_group_plans, execute_waves, aggregate_results, close_parent_artifacts, verify_phase_goal, update_roadmap
3. The --no-transition flag means: after verification + roadmap update, STOP and return status. Do NOT run transition.md.
4. When spawning executor agents, use subagent_type='gsd-executor' with the existing @file pattern from the workflow
5. When spawning verifier agents, use subagent_type='gsd-verifier'
6. Preserve the classifyHandoffIfNeeded workaround (spot-check on that specific error)
7. Do NOT use the Skill tool or /gsd- commands
</instructions>