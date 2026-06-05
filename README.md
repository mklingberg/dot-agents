# ~/.agents

Personal agent skills library for [pi](https://github.com/earendil-works/pi-coding-agent) — a coding agent harness powered by Claude.

Skills live under `skills/<category>/<name>/SKILL.md` and are automatically discovered by pi recursively. Each skill provides specialized instructions that activate when the task matches its description.

---

## Structure

```
~/.agents/
└── skills/
    ├── code/           Code quality, testing, feature flags
    ├── experimental/   Skills being evaluated — not yet promoted
    ├── misc/           Skill authoring, presentations, workflow utilities
    ├── planning/       Plans, PRDs, issues, stories
    └── thinking/       Grilling, analysis, decision-making
```

---

## Skills

### `code/`
- **[feature-flags-csharp](skills/code/feature-flags-csharp/SKILL.md)** — Create, use, test, and remove LaunchDarkly feature flags in C# .NET projects. Follows team conventions: `FeatureFlag<T>` subclasses, `IFeatureFlagProvider`, Jira-ticket-based naming.
- **[write-tests-autofixture](skills/code/write-tests-autofixture/SKILL.md)** — Write unit tests using xUnit, AutoFixture, AutoData, and FakeItEasy following project conventions.

### `planning/`
- **[create-plans](skills/planning/create-plans/SKILL.md)** — Create hierarchical project plans optimized for solo agentic development. Produces Claude-executable plans with verification criteria. Handles briefs, roadmaps, phase plans, and context handoffs.
- **[to-plan](skills/planning/to-plan/SKILL.md)** — Convert the current conversation context into a PLAN.md. Use after a grilling session or design discussion where the plan is already clear.
- **[to-issues](skills/planning/to-issues/SKILL.md)** — Break a plan, spec, or PRD into independently-grabbable issues using tracer-bullet vertical slices.
- **[write-a-prd](skills/planning/write-a-prd/SKILL.md)** — Create a PRD through user interview, codebase exploration, and module design, then submit as a GitHub issue.
- **[to-prd](skills/planning/to-prd/SKILL.md)** — Turn the current conversation context into a PRD and publish it to the project issue tracker.
- **[write-jira-stories](skills/planning/write-jira-stories/SKILL.md)** — Plan and create Jira stories and subtasks. Scrum-based, with frontend/backend subtask splits, Figma integration, and agent-directive subtasks.

### `thinking/`
- **[grill-me](skills/thinking/grill-me/SKILL.md)** — Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree.
- **[grill-with-docs](skills/thinking/grill-with-docs/SKILL.md)** — Grilling session that challenges your plan against the existing domain model, sharpens terminology, and updates documentation (CONTEXT.md, ADRs) inline as decisions crystallise.
- **[pros-cons](skills/thinking/pros-cons/SKILL.md)** — Weighted pros/cons analysis with a challenging mindset, clear verdict, and alternative proposals.

### `misc/`
- **[create-agent-skills](skills/misc/create-agent-skills/SKILL.md)** — Expert guidance for creating, writing, building, and refining Claude Code Skills.
- **[create-subagents](skills/misc/create-subagents/SKILL.md)** — Expert guidance for creating and using Claude Code subagents and the Task tool.
- **[handoff](skills/misc/handoff/SKILL.md)** — Compact the current conversation into a handoff document for another agent to pick up.
- **[create-frontend-slides](skills/misc/create-frontend-slides/SKILL.md)** — Create animation-rich HTML presentations from scratch or by converting PowerPoint files.

### `experimental/`
Skills under evaluation — may be promoted, revised, or dropped.

- **[review-code](skills/experimental/review-code/SKILL.md)** — Senior-level code reviews covering correctness, security (OWASP 2025), performance, maintainability, DRY, test coverage, and technical debt.
- **[manage-worktrees](skills/experimental/manage-worktrees/SKILL.md)** — Manage git worktrees for parallel branch development. Set up bare repos, create worktrees, work on multiple branches simultaneously.

---

## Skill Relationships & Usage Patterns

### Planning workflow

The planning skills form a layered stack:

```
┌─────────────────────────────────────────────────────┐
│  grill-with-docs  →  CONTEXT.md + ADRs              │  Domain layer
│                      (why decisions were made)       │  Universal — humans & agents
├─────────────────────────────────────────────────────┤
│  create-plans     →  BRIEF.md + ROADMAP.md + PLANs  │  Execution layer
│                      (what Claude should do)         │  Claude execution pipeline
└─────────────────────────────────────────────────────┘
```

**`grill-with-docs` first, then `create-plans`** — on any serious project, run a grilling session to establish the domain model and lock in architectural decisions as ADRs before writing execution plans. BRIEF.md should reference existing ADRs rather than duplicate them.

**ADRs are agent context too** — CONTEXT.md and ADRs aren't just team documentation. They're the institutional memory an agent lacks at the start of every session. Without them, agents will "fix" intentional decisions, re-open settled debates, and violate system-wide constraints. Load relevant ADRs into PLAN.md `<context>` blocks:

```xml
<context>
@.planning/BRIEF.md
@docs/adr/0003-jose-over-jsonwebtoken.md
@src/relevant/file.ts
</context>
```

### grill-me vs grill-with-docs

- **`grill-me`** — pure thinking session, no codebase, no artifacts. Good for stress-testing an idea before any code exists.
- **`grill-with-docs`** — challenges your plan against the *existing* domain model. Cross-references code, sharpens terminology against CONTEXT.md, produces ADRs for hard decisions. Use this on brownfield work.

### to-plan vs create-plans

- **`create-plans`** — full planning session from scratch: brief → roadmap → phases → plans. Starts a conversation.
- **`to-plan`** — converts the *current conversation* into a PLAN.md. Use after a grilling session where the plan is already clear and just needs capturing.

### to-prd vs write-a-prd

- **`write-a-prd`** — interview-driven: asks questions, explores the codebase, designs modules, then publishes as a GitHub issue.
- **`to-prd`** — capture-driven: turns the current conversation context into a PRD and publishes it. Use when the design is already discussed.

### create-plans: extend vs clear

The skill is designed to **accumulate** — new features become new phases appended to ROADMAP.md, not a fresh `.planning/` folder. Clearing `.planning/` per feature loses the phase summaries (architectural decisions, deviations, the "why") and forces re-briefing the agent from scratch every time.

Prefer:
- **Extend** — append new phases (`05-payments`, `06-notifications`) to the existing ROADMAP.md
- **Milestone** — mark shipped versions (`v1.1`) in MILESTONES.md
- **Archive** — only clear for separate codebases or complete rewrites

---

## Adding a New Skill

1. Create `skills/<category>/<your-skill-name>/SKILL.md`
2. Add YAML frontmatter with `name` and `description`
3. Write the skill instructions in the body
4. Pi will auto-discover it on next session

New or unproven skills go in `experimental/` first.

> Tip: Use the **create-agent-skills** skill to get guided help authoring new skills.

---

## Kudos

Some skills in this library are adapted from the work of others — thanks to:

- **[the-maniac](https://github.com/the-maniac/claude-code-resources)** — source of `create-plans`, `create-agent-skills`, and `create-subagents`.
- **[Matt Pocock](https://github.com/mattpocock/skills)** — prolific skill author, great resource for skill inspiration and patterns.
- **[Marwen Amamou](https://github.com/mamamou/ai-coding-skills)** — source of `review-code`.
