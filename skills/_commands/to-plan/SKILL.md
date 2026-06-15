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
- **No asking about path** — determine it and proceed.
</rules>

<process>

1. **Determine output path:**
   ```bash
   ls .planning/ 2>/dev/null && echo "EXISTS" || echo "MISSING"
   ```
   - **Exists** → use existing phase naming: `.planning/phases/XX-name/{phase}-{plan}-PLAN.md`
   - **Missing** → create it, infer phase name from conversation, write to `.planning/phases/01-[name]/01-01-PLAN.md`

2. **Extract tasks** from the conversation — every concrete agreed action becomes a task candidate.

3. **Confirm breakdown** — present inline, wait for confirmation before writing:
   ```
   ### {phase}-01-PLAN.md — [Subsystem]
   1. [Task name] [auto/checkpoint]
   2. [Task name] [auto/checkpoint]

   ### {phase}-02-PLAN.md — [Subsystem] (if needed)
   ...

   Does this look right?
   ```

4. **Write PLAN.md file(s)** using the template below.

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
@~/.agents/skills/create-plans/workflows/execute-phase.md
@~/.agents/skills/create-plans/templates/summary.md
[If any checkpoint tasks:]
@~/.agents/skills/create-plans/references/checkpoints.md
</execution_context>

<context>
[If .planning/BRIEF.md and ROADMAP.md exist, reference them:]
@.planning/BRIEF.md
@.planning/ROADMAP.md
[If previous plan in same phase:]
@.planning/phases/XX-name/{phase}-{prev}-SUMMARY.md

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
