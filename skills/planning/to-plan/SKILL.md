---
name: to-plan
description: Convert current conversation context into a Claude-executable PLAN.md. Use after a grill-me or grill-with-docs session, or whenever you have a clear implementation plan ready to capture as an executable prompt. Works outside the create-plans lifecycle — does not require an existing .planning/ structure.
---

<required_reading>
Before writing any plan, read:
1. `~/.agents/skills/create-plans/references/scope-estimation.md` — quality degradation curve, 2-3 task rule, how to split phases
2. `~/.agents/skills/create-plans/references/checkpoints.md` — checkpoint types, when to use each, structure
3. `~/.agents/skills/create-plans/references/cli-automation.md` — what Claude can automate (determines auto vs checkpoint)
</required_reading>

<objective>
Synthesise the current conversation into one or more executable PLAN.md files.

Do NOT interview the user — context is already established (from a grill session or prior discussion).
</objective>

<process>

1. **Determine output path** — ask if not clear from context:
   - After `create-plans` session: `.planning/phases/XX-name/{phase}-{plan}-PLAN.md`
   - Standalone (no `.planning/` structure): ask the user where to write it, and note that `@.planning/BRIEF.md` / `@.planning/ROADMAP.md` references in the template should be replaced with an inline context summary block describing the project and goals.

2. **Extract tasks** from the conversation — every concrete action agreed upon becomes a task.

3. **Apply scope rules** — check task count. Split into multiple PLAN files if needed (see below).

4. **Confirm breakdown** — present task list inline and wait for confirmation before writing:
   ```
   Here's the proposed plan breakdown:

   ### {phase}-01-PLAN.md — [Subsystem name]
   1. [Task name] [type: auto/checkpoint]
   2. [Task name] [type: auto/checkpoint]

   ### {phase}-02-PLAN.md — [Subsystem name] (if split needed)
   1. [Task name] [type: auto/checkpoint]
   2. [Task name] [type: auto/checkpoint]

   Does this look right? (yes / adjust)
   ```

5. **Write PLAN.md file(s)** using the template below.

</process>

<scope_rules>
**2-3 tasks maximum per PLAN.md.** Split by subsystem, dependency order, or autonomy grouping.

Split naming: `{phase}-01-PLAN.md`, `{phase}-02-PLAN.md`, etc. Each plan must be independently executable and committable.

See `scope-estimation.md` (already loaded) for the full quality degradation curve and splitting guidance.
</scope_rules>

<template>
```markdown
---
phase: XX-name
plan: {plan-number}
type: execute
domain: [optional — if domain expertise applies]
---

<objective>
[What this plan accomplishes]

Purpose: [Why this plan matters for the project]
Output: [Artifacts that will be created]
</objective>

<execution_context>
@~/.agents/skills/create-plans/workflows/execute-phase.md
@~/.agents/skills/create-plans/templates/summary.md
[If plan has ANY checkpoint tasks, add:]
@~/.agents/skills/create-plans/references/checkpoints.md
</execution_context>

<context>
@.planning/BRIEF.md
@.planning/ROADMAP.md
[If research done:]
@.planning/phases/XX-name/FINDINGS.md
[If continuing from previous plan in same phase:]
@.planning/phases/XX-name/{phase}-{prev}-SUMMARY.md
[Relevant source files:]
@src/path/to/relevant.ts
</context>

<tasks>

<task type="auto">
  <name>Task N: [Action-oriented name]</name>
  <files>path/to/file.ext</files>
  <action>[Specific implementation — what to do, how, and what to avoid and WHY]</action>
  <verify>[Command or check to prove it worked]</verify>
  <done>[Measurable acceptance criteria]</done>
</task>

<task type="checkpoint:decision" gate="blocking">
  <decision>[What needs deciding]</decision>
  <context>[Why this decision matters]</context>
  <options>
    <option id="option-a">
      <name>[Option name]</name>
      <pros>[Benefits]</pros>
      <cons>[Trade-offs]</cons>
    </option>
    <option id="option-b">
      <name>[Option name]</name>
      <pros>[Benefits]</pros>
      <cons>[Trade-offs]</cons>
    </option>
  </options>
  <resume-signal>[How to indicate choice]</resume-signal>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>[What Claude just automated that needs verification]</what-built>
  <how-to-verify>
    1. Run: [command]
    2. Visit: [URL]
    3. Confirm: [Expected behaviours]
  </how-to-verify>
  <resume-signal>Type "approved" to continue, or describe issues to fix</resume-signal>
</task>

</tasks>

<verification>
Before declaring plan complete:
- [ ] [Specific test command]
- [ ] [Build/type check]
- [ ] [Behaviour verification]
</verification>

<success_criteria>
- All tasks completed
- All verification checks pass
- [Plan-specific criteria from conversation]
</success_criteria>

<output>
After completion, create `.planning/phases/XX-name/{phase}-{plan}-SUMMARY.md` using:
@~/.agents/skills/create-plans/templates/summary.md
</output>
```
</template>

<task_quality>
**Good tasks** — specific, executable, verifiable:
- "Add User model to Prisma schema with email, passwordHash, createdAt"
- "Create POST /api/auth/login endpoint with bcrypt validation, JWT in httpOnly cookie"

**Bad tasks** — vague, unverifiable:
- "Set up authentication"
- "Handle edge cases"

A task is ready to write when you can fill in **Files + Action + Verify + Done**.
The `<action>` field must include **what to avoid and WHY** for any non-obvious choices.
</task_quality>

<anti_patterns>
- Do not interview the user — synthesise what you already know
- No story points or hour estimates
- No team assignments or RACI
- Tasks are instructions for Claude, not Jira tickets
- Do not create a single monolithic plan for a large phase — split aggressively
</anti_patterns>

<success_criteria>
Plan is well-written when:
- [ ] 2-3 tasks per PLAN.md (never more than 3)
- [ ] Each task has: type, files (if auto), action, verify, done
- [ ] `<action>` fields are specific enough to implement without guessing
- [ ] @context references point to real files
- [ ] Checkpoint types are correctly chosen
- [ ] Multi-plan phases have logical splits by subsystem or dependency order
- [ ] `<execution_context>` references are included
</success_criteria>
