---
name: to-plan
description: "Convert current conversation into a standalone Claude-executable PLAN.md (no .planning/ needed). Trigger: 'turn this into a plan', after grill-me/grill-with-docs."
disable-model-invocation: true
---

<objective>
Synthesise the current conversation into one or more executable PLAN.md files.
Do NOT interview the user — context is already established.
</objective>

<rules>
- **2-3 tasks max per PLAN.md.** Split by subsystem or dependency order if more.
- **Task types:** `auto` = Claude can do it via CLI/API/tool. `checkpoint:human-verify` = Claude did it, human confirms visually. `checkpoint:decision` = human must choose before proceeding.
- **Testable behaviour → vertical slice.** For a task that builds behaviour, fix the test **seam** first, write `<action>` as failing-test-first → minimal impl, and make `<verify>` run that test. Loop rules & test anti-patterns: `~/.agents/skills/tdd/SKILL.md`.
- **No asking about path** — determine it and proceed.
</rules>

<process>

1. **Read slicing reference:**
   Read `~/.agents/skills/create-plans/references/scope-estimation.md` before deciding how to split tasks.

2. **Determine output path:**
   ```bash
   ls .planning/ 2>/dev/null && echo "EXISTS" || echo "MISSING"
   ```
   - **Exists** → use existing phase naming: `.planning/phases/XX-name/{phase}-{plan}-PLAN.md`
   - **Missing** → create it, infer phase name from conversation, write to `.planning/phases/01-[name]/01-01-PLAN.md`

   When creating `.planning/`, ignore it in the same action — plans are scratch and are
   never committed:
   ```bash
   grep -qxF '.planning/' .gitignore 2>/dev/null || echo '.planning/' >> .gitignore
   ```

3. **Extract tasks** from the conversation — every concrete agreed action becomes a task candidate.

4. **Confirm breakdown** — present inline, wait for confirmation before writing:
   ```
   ### {phase}-01-PLAN.md — [Subsystem]
   1. [Task name] [auto/checkpoint]
   2. [Task name] [auto/checkpoint]

   ### {phase}-02-PLAN.md — [Subsystem] (if needed)
   ...

   Does this look right?
   ```

5. **Bind conventions.** Implement can't see `AGENTS.md`/`CLAUDE.md`; the plan's `<context>` is its only channel. Follow `<project_conventions>` in `~/.agents/skills/create-plans/SKILL.md`: embed the project and global skills each plan touches, and inline the `AGENTS.md` rules that govern its tasks.

6. **Write PLAN.md file(s)** using the template below.

7. **Hand off.** Execution is the `Implement` agent's job, not this skill's. Call the Skill tool with `delegate-subagents` to dispatch, or tell the user the plan path if they'd rather run it later.

</process>

<template>
```markdown
---
phase: XX-name
plan: {plan-number}
type: execute
---

<objective>
[What this plan accomplishes and why it matters]
Output: [Artifacts created]
</objective>

<execution_context>
@~/.agents/skills/create-plans/templates/summary.md
[If any checkpoint tasks:]
@~/.agents/skills/create-plans/references/checkpoints.md
</execution_context>

<context>
[If .planning/BRIEF.md and ROADMAP.md exist, reference them:]
@.planning/BRIEF.md
@.planning/ROADMAP.md
[If research exists:]
@.planning/phases/XX-name/FINDINGS.md
[If previous plan in same phase:]
@.planning/phases/XX-name/{phase}-{prev}-SUMMARY.md
[Relevant source files:]
@src/path/to/relevant.ext
[Conventions this plan touches (step 5):]
@.agents/skills/<relevant-skill>/SKILL.md
@~/.agents/skills/<relevant-global-skill>/SKILL.md

[If standalone — replace above with:]
<inline_context>
Project: [1-line description]
Goal: [what this plan works toward]
Decisions made:
- [key decision from conversation]
Relevant files:
- path/to/file.ext
</inline_context>
</context>

<tasks>

<task type="auto">
  <name>Task N: [Action-oriented name]</name>
  <files>path/to/file.ext</files>
  <action>[What to do, how, and what to avoid and WHY]</action>
  <verify>[Command or check proving it worked]</verify>
  <done>[Measurable acceptance criteria]</done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>[What Claude automated]</what-built>
  <how-to-verify>
    1. Run: [command]
    2. Confirm: [expected behaviour]
  </how-to-verify>
  <resume-signal>Type "approved" to continue, or describe issues</resume-signal>
</task>

<task type="checkpoint:decision" gate="blocking">
  <decision>[What needs deciding]</decision>
  <options>
    <option id="a"><name>[Option]</name><pros/><cons/></option>
    <option id="b"><name>[Option]</name><pros/><cons/></option>
  </options>
  <resume-signal>[How to indicate choice]</resume-signal>
</task>

</tasks>

<verification>
- [ ] [Test command]
- [ ] [Build/type check]
- [ ] [Behaviour check]
</verification>

<success_criteria>
- All tasks completed and verification passes
- [Specific criteria from conversation]
</success_criteria>

<output>
Create `.planning/phases/XX-name/{phase}-{plan}-SUMMARY.md` using:
@~/.agents/skills/create-plans/templates/summary.md
</output>
```
</template>
