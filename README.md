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
    ├── _commands/                Manual-trigger skills (hidden from auto-detection)
    ├── _experimental/            Auto-detected but not yet promoted as core
    ├── create-agent-skills/     Promoted skills live flat at the root
    ├── create-feature-branch/
    ├── create-plans/
    ├── grill-me/
    └── …
```

Flat root by design: folders for taxonomy add nothing the agent uses. Grouping happens via **name prefix** instead.

### Name prefix conventions

| Prefix | Meaning | Examples |
|---|---|---|
| `create-` | Produce a new artifact, workflow, or thing | `create-plans`, `create-feature-branch`, `create-tests-autofixture` |
| `to-` | Convert current conversation → artifact | `to-plan`, `to-prd`, `to-issues` |
| `grill-` | Interactive pressure-test | `grill-me`, `grill-with-docs` |
| `review-` | Analyze without side effects | `review-code` |
| bare verb | Single distinct action | `handoff`, `pros-cons`, `manage-worktrees` |

Use the same prefixes when adding new skills so they cluster predictably in alphabetical listings and `/skill:` completion.

### About `_commands/`

Skills in `_commands/` set `disable-model-invocation: true` in their frontmatter. Effect:
- **Not loaded** into the system prompt — zero always-on token cost
- **Not auto-triggered** by the agent from user phrasing
- **Invoked manually** via `/skill:<name>` (or `--skill <path>`)

Use this folder for skills that are useful but rarely needed, or that you'd always invoke explicitly anyway. Keeps the agent's trigger surface focused on skills that benefit from natural-language activation.

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
- **`to-plan`** *(command)* — fast path when the conversation is already clear and just needs to become an executable `PLAN.md`
- **`handoff`** *(command)* — compresses working state so another agent/session can resume without guessing

The goal is not documentation theater. The goal is executable planning and continuity.

### 3. Breaking work into trackable follow-ups

Once direction is clear, these skills turn it into project-management artifacts.

- **`to-issues`** *(command)* — splits work into grab-able implementation slices
- **`create-a-prd`** *(command)* — interview-driven PRD creation
- **`to-prd`** *(command)* — capture-driven PRD from an already-developed discussion
- **`create-jira-stories`** *(command)* — Jira story/subtask generation for a specific workflow

### 4. Focused specialist help

A few skills encode concrete patterns so the agent does not reinvent them badly.

- **`create-tests-autofixture`** — opinionated xUnit + AutoFixture + FakeItEasy test conventions
- **`create-feature-flags`** — LaunchDarkly/C# feature-flag workflow aligned to team conventions
- **`create-subagents`** — how to structure and use subagents well
- **`create-agent-skills`** — how to write better skills instead of cargo-culting prompt files
- **`create-frontend-slides`** *(command)* — presentation-building specialist

*(command)* = lives in `_commands/`, invoked via `/skill:<name>`.

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
create-a-prd or to-prd
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

### `to-prd` vs `create-a-prd`
- **`to-prd`** = convert existing discussion into a PRD
- **`create-a-prd`** = discover the PRD through guided questioning and exploration

## Experimental skills

`_experimental/` holds skills that are auto-detected and usable, but not yet promoted as core. Same loading behavior as root-level skills — the folder just signals "still proving its value."

Current:
- **`review-code`** — structured senior-style code review
- **`create-a-prd`** — interview-driven PRD creation
- **`to-prd`** — convert existing discussion into a PRD
- **`to-issues`** — splits work into grab-able implementation slices

`manage-worktrees` lives in `_commands/` (manual trigger only).

## Adding a new skill

1. Pick a name using the prefix conventions above (`create-`, `to-`, `grill-`, `review-`, or bare verb)
2. Create `skills/<name>/SKILL.md` (or `skills/_commands/<name>/SKILL.md` for manual-only)
3. Add frontmatter with `name` and `description`
4. Write focused instructions for a real repeated problem
5. Decide activation mode:
   - **Auto-detected** (default): root of `skills/`, or `skills/_experimental/` if not yet proven. Agent triggers from user phrasing matching the description.
   - **Manual only**: `skills/_commands/` and add `disable-model-invocation: true`. Invoked via `/skill:<name>`.
6. Promote only if it proves durable in actual use — move from `_experimental/` to root

Rule of thumb: if a skill is just a fancy alias for a one-off prompt, it probably should not exist. If it works but rarely triggers, move it to `_commands/`.


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