# ~/.agents

Personal agent skills library for [pi](https://github.com/earendil-works/pi-coding-agent) — a coding agent harness powered by Claude.

Skills live in `skills/<name>/SKILL.md` and are automatically discovered by pi. Each skill provides specialized instructions that activate when the task matches its description.

---

## Skills

### Planning & Analysis
- **[create-plans](skills/create-plans/SKILL.md)** — Create hierarchical project plans optimized for solo agentic development. Produces Claude-executable plans with verification criteria. Handles briefs, roadmaps, phase plans, and context handoffs.
- **[write-a-prd](skills/write-a-prd/SKILL.md)** — Create a PRD through user interview, codebase exploration, and module design, then submit as a GitHub issue.
- **[to-prd](skills/to-prd/SKILL.md)** — Turn the current conversation context into a PRD and publish it to the project issue tracker.
- **[pros-cons](skills/pros-cons/SKILL.md)** — Weighted pros/cons analysis with a challenging mindset, clear verdict, and alternative proposals.

### Issue Tracking & Stories
- **[to-issues](skills/to-issues/SKILL.md)** — Break a plan, spec, or PRD into independently-grabbable issues using tracer-bullet vertical slices.
- **[write-jira-stories](skills/write-jira-stories/SKILL.md)** — Plan and create Jira stories and subtasks for the Mina Sidor project. Scrum-based, with frontend/backend subtask splits, Figma integration, and agent-directive subtasks.

### Grilling & Review
- **[grill-me](skills/grill-me/SKILL.md)** — Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree.
- **[grill-with-docs](skills/grill-with-docs/SKILL.md)** — Grilling session that challenges your plan against the existing domain model, sharpens terminology, and updates documentation (CONTEXT.md, ADRs) inline as decisions crystallise.

### Feature Flags (LaunchDarkly)
- **[ld-react](skills/ld-react/SKILL.md)** — Create, use, test, and remove LaunchDarkly feature flags in the walley-my-walley-frontend React project. Follows team conventions: `useFeatureFlags()` hook, `FEATURE_FLAGS` registry, `mockFlags()` for tests, Jira-ticket-based naming.
- **[ld-csharp](skills/ld-csharp/SKILL.md)** — Create, use, test, and remove LaunchDarkly feature flags in C# .NET projects. Follows team conventions: `FeatureFlag<T>` subclasses, `IFeatureFlagProvider`, Jira-ticket-based naming.

### Testing
- **[write-tests](skills/write-tests/SKILL.md)** — Write unit tests using xUnit, AutoFixture, AutoData, and FakeItEasy following project conventions.

### Git & Workflow
- **[manage-worktrees](skills/manage-worktrees/SKILL.md)** — Manage git worktrees for parallel branch development. Set up bare repos, create worktrees, work on multiple branches simultaneously.
- **[handoff](skills/handoff/SKILL.md)** — Compact the current conversation into a handoff document for another agent to pick up.

### Presentations
- **[create-frontend-slides](skills/create-frontend-slides/SKILL.md)** — Create stunning, animation-rich HTML presentations from scratch or by converting PowerPoint files.

### Skill Authoring
- **[create-agent-skills](skills/create-agent-skills/SKILL.md)** — Expert guidance for creating, writing, building, and refining Claude Code Skills. Use when working with SKILL.md files or authoring new skills.
- **[write-a-skill](skills/write-a-skill/SKILL.md)** — Create new agent skills with proper structure, progressive disclosure, and bundled resources.

---

## Skill Relationships & Usage Patterns

### Planning workflow

The planning skills form a layered stack. Understanding which layer you're at determines which skill to reach for:

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

### create-plans vs grill-with-docs for teams

| | create-plans | grill-with-docs |
|---|---|---|
| Primary executor | Claude | Humans (with AI assistance) |
| Artifacts useful to | Claude sessions | Anyone reading the repo |
| History format | Phase summaries, ROADMAP.md | ADRs, CONTEXT.md glossary |
| Lifespan | Per-feature or continuous | Lives in the repo permanently |
| Team noise | `.planning/` is Claude infrastructure | ADRs are standard team artifacts |

`create-plans` is optimized for solo developer + Claude. On team projects, prefer persisting decisions as ADRs via `grill-with-docs` — they survive tool changes, onboarding, and time. Use `create-plans` as the execution layer on top.

### create-plans: extend vs clear

The skill is designed to **accumulate** — new features become new phases appended to ROADMAP.md, not a fresh `.planning/` folder. Clearing `.planning/` per feature loses the phase summaries (architectural decisions, deviations, the "why") and forces re-briefing the agent from scratch every time.

Prefer:
- **Extend** — append new phases (`05-payments`, `06-notifications`) to the existing ROADMAP.md
- **Milestone** — mark shipped versions (`v1.1`) in MILESTONES.md
- **Archive** — only clear for separate codebases or complete rewrites

If `.planning/` is noise on a shared repo, add it to `.gitignore` and keep it local — you still get continuity without commit noise.

### to-plan vs create-plans

- **`create-plans`** — full planning session from scratch: brief → roadmap → phases → plans. Starts a conversation.
- **`to-plan`** — converts the *current conversation* into a PLAN.md. Use after a grilling session or design discussion where the plan is already clear and just needs capturing.

### to-prd vs write-a-prd

- **`write-a-prd`** — interview-driven: asks questions, explores the codebase, designs modules, then publishes as a GitHub issue.
- **`to-prd`** — capture-driven: turns the current conversation context into a PRD and publishes it. Use when the design is already discussed.

---

## Structure

```
~/.agents/
└── skills/
    └── <skill-name>/
        ├── SKILL.md        # Skill instructions (frontmatter: name, description)
        └── ...             # Optional: examples, templates, bundled resources
```

## Adding a New Skill

1. Create `skills/<your-skill-name>/SKILL.md`
2. Add YAML frontmatter with `name` and `description`
3. Write the skill instructions in the body
4. Pi will auto-discover it on next session

> Tip: Use the **write-a-skill** or **create-agent-skills** skills to get guided help authoring new skills.
