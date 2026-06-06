# ~/.agents

A personal skill library for [pi](https://github.com/earendil-works/pi-coding-agent): planning, grilling, workflow control, and a few sharp domain tools that make the agent more useful than raw prompting.

This is not a pile of prompt snippets. It is a working system for getting from vague idea to durable execution with less drift, less context loss, and better decisions.

> Better plans. Harder questions. Cleaner execution.

## What this library is really for

The center of gravity is not “more skills.” It is **better agent behavior**:
- challenge weak plans early
- turn discussion into executable artifacts
- preserve context across long work
- break work into reviewable chunks
- keep specialist knowledge reusable

## Structure

```text
~/.agents/
└── skills/
    ├── code/           Targeted implementation conventions
    ├── experimental/   Useful, but still being proven
    ├── misc/           Meta-tools and workflow helpers
    ├── planning/       PRDs, plans, issues, stories
    └── thinking/       Pressure-testing and decision support
```

## The real spine of the library

### 1. Thinking before action

These skills improve the idea before code starts.

- **`grill-me`** — stress-tests a plan in pure conversation
- **`grill-with-docs`** — pressure-tests a plan against the real codebase and docs
- **`pros-cons`** — forces a decision instead of endless “maybe” analysis

This layer exists for one reason: most bad implementation work starts as bad framing.

### 2. Planning that survives long sessions

This is the strongest part of the library.

- **`create-plans`** — builds a durable planning system with `BRIEF.md`, `ROADMAP.md`, phase plans, summaries, and handoffs
- **`to-plan`** — fast path when the conversation is already clear and just needs to become an executable `PLAN.md`
- **`handoff`** — compresses working state so another agent/session can resume without guessing

The goal is not documentation theater. The goal is executable planning and continuity.

### 3. Breaking work into trackable follow-ups

Once direction is clear, these skills turn it into project-management artifacts.

- **`to-issues`** — splits work into grab-able implementation slices
- **`write-a-prd`** — interview-driven PRD creation
- **`to-prd`** — capture-driven PRD from an already-developed discussion
- **`write-jira-stories`** — Jira story/subtask generation for a specific workflow

### 4. Focused specialist help

A few skills encode concrete patterns so the agent does not reinvent them badly.

- **`write-tests-autofixture`** — opinionated xUnit + AutoFixture + FakeItEasy test conventions
- **`feature-flags-csharp`** — LaunchDarkly/C# feature-flag workflow aligned to team conventions
- **`create-subagents`** — how to structure and use subagents well
- **`create-agent-skills`** — how to write better skills instead of cargo-culting prompt files
- **`create-frontend-slides`** — presentation-building specialist

## Recommended usage patterns

### Brownfield feature work

```text
grill-with-docs
  ↓
to-plan           (small/clear work)
or
create-plans      (larger/multi-phase work)
  ↓
to-issues         (if work needs tracking)
```

### Greenfield / early exploration

```text
grill-me
  ↓
pros-cons         (if decision is fuzzy)
  ↓
write-a-prd or to-prd
  ↓
to-plan or create-plans
```

### Long-running work

```text
create-plans
  ↓
handoff           (when pausing)
  ↓
resume later with less context loss
```

## Key distinctions that matter

### `grill-me` vs `grill-with-docs`
- **`grill-me`** = idea pressure test, no project grounding required
- **`grill-with-docs`** = design pressure test against actual docs, terminology, and code reality

### `to-plan` vs `create-plans`
- **`to-plan`** = one-shot capture of a clear conversation into a `PLAN.md`
- **`create-plans`** = durable planning system for larger or staged work

### `to-prd` vs `write-a-prd`
- **`to-prd`** = convert existing discussion into a PRD
- **`write-a-prd`** = discover the PRD through guided questioning and exploration

## Experimental skills

`experimental/` holds skills that are useful but not yet promoted as core.

Current examples:
- **`review-code`** — structured senior-style code review
- **`manage-worktrees`** — git worktree workflow support

These are real tools, just not as central to the library’s identity as planning + thinking.

## Adding a new skill

1. Create `skills/<category>/<name>/SKILL.md`
2. Add frontmatter with `name` and `description`
3. Write focused instructions for a real repeated problem
4. Promote only if it proves durable in actual use

Rule of thumb: if a skill is just a fancy alias for a one-off prompt, it probably should not exist.

## Why this repo matters

Raw model capability is not usually the bottleneck.

The bottleneck is:
- weak problem framing
- context loss
- oversized tasks
- no durable memory
- no repeatable workflow

This library exists to fix that.

## Kudos

Some skills here are adapted from strong existing work:

- **[the-maniac](https://github.com/the-maniac/claude-code-resources)** — source of `create-plans`, `create-agent-skills`, and `create-subagents`
- **[Matt Pocock](https://github.com/mattpocock/skills)** — strong skill patterns and inspiration
- **[Marwen Amamou](https://github.com/mamamou/ai-coding-skills)** — source of `review-code`

## Related repos

- [dot-pi](https://github.com/mklingberg/dot-pi) — pi setup, agents, planning workflow
- [dot-config](https://github.com/mklingberg/dot-config) — macOS/dev environment config
- [dot-agents](https://github.com/mklingberg/dot-agents) — personal pi skill library