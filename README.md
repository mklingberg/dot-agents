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
