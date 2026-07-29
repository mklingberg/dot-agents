# ~/.agents

A personal **cross-harness agent workspace**: skills, subagent definitions, an orchestration protocol, and global instructions — one source of truth shared across [pi](https://github.com/earendil-works/pi-coding-agent), Claude Code, and GitHub Copilot CLI.

This is not a pile of prompt snippets. It is a working system for getting from vague idea to durable execution with less drift, less context loss, and better decisions — usable from whichever agent you happen to be in.

> Better plans. Harder questions. Cleaner execution. Same setup, any harness.

Four shared assets live here and propagate to each tool (see [Cross-harness sync](#cross-harness-agents--sync)):

| Asset | What it is |
|---|---|
| `skills/` | Agent Skills (SKILL.md) — the bulk of this repo |
| `agents/` | Subagent definitions (Pi-format source) |
| `subagent-protocol.md` | Hybrid orchestration protocol (agnostic core + per-harness adapters) |
| `AGENTS.md` | Global instructions (reporting style, git rules, language, delegation) |

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
├── AGENTS.md                 Global instructions, shared across harnesses
├── subagent-protocol.md      Hybrid orchestration protocol (core + adapters)
├── agents/                   Pi-format subagent defs (source of truth)
│   ├── Explore.md  Research.md  Debug.md  Review.md  Implement.md
├── bin/                      sync.sh (propagate) + gen_agent.py (transform)
└── skills/
    ├── _commands/                Manual-trigger skills (hidden from auto-detection)
    ├── _experimental/            Auto-detected but not yet promoted as core
    ├── create-feature-flags/    Promoted skills live flat at the root
    ├── create-feature-branch/
    ├── create-plans/
    ├── grilling/
    └── …
```

Flat root by design: folders for taxonomy add nothing the agent uses. Grouping happens via **name prefix** instead.

### Name prefix conventions

| Prefix | Meaning | Examples |
|---|---|---|
| `create-` | Produce a new artifact, workflow, or thing | `create-plans`, `create-feature-branch`, `create-tests-autofixture` |
| `to-` | Convert current conversation → artifact | `to-plan` |
| `grill-` | Interactive pressure-test | `grill-me`, `grill-with-docs` |
| `review-` | Analyze without side effects | `code-review` |
| bare verb | Single distinct action | `handoff`, `pros-cons`, `prototype` |

Use the same prefixes when adding new skills so they cluster predictably in alphabetical listings and `/skill:` completion.

### About `_commands/`

Skills in `_commands/` set `disable-model-invocation: true` in their frontmatter. Effect:
- **Not loaded** into the system prompt — zero always-on token cost
- **Not auto-triggered** by the agent from user phrasing
- **Invoked manually** via `/skill:<name>` (or `--skill <path>`)

Use this folder for skills that are useful but rarely needed, or that you'd always invoke explicitly anyway. Keeps the agent's trigger surface focused on skills that benefit from natural-language activation.

## Cross-harness agents & sync

Beyond skills, `~/.agents` is the single source for **subagent definitions**, the **orchestration protocol**, and **global instructions** — propagated into each tool by `bin/sync.sh`.

### What propagates where

| Asset | Pi | Claude Code | Copilot CLI |
|---|---|---|---|
| `skills/` | native scan | **flat per-skill symlinks** `~/.claude/skills/<name>` | native scan |
| `AGENTS.md` | symlink | symlink as `~/.claude/CLAUDE.md` | symlink `~/.copilot/AGENTS.md` |
| `subagent-protocol.md` | symlink | (referenced) | (referenced) |
| `agents/*.md` | symlink | **generated** `.md` | **generated** `.agent.md` |

Pi and Copilot scan `~/.agents/skills` natively (any depth) — no symlink needed. Claude scans only **one level deep**, so it can't see skills grouped under `_commands/` or `_experimental/`; `sync.sh` rebuilds `~/.claude/skills` as a real dir of per-skill symlinks (any depth → flat), keeping the grouped source layout for your own organization.

### Why agents are generated, not symlinked

The agent frontmatter genuinely diverges per harness — mainly the `tools` vocabulary (`read,bash,grep` → Claude `Read,Bash,Grep,Glob` → Copilot `read,execute,search`) and `model`. The Pi source pins a fully-qualified id (e.g. `github-copilot/claude-sonnet-5`) so Pi resolves it deterministically and it passes `scopeModels` (must be in `enabledModels`); `bin/gen_agent.py` derives the bare Claude alias (`sonnet`/`haiku`/`opus`) from the id's family keyword, and Copilot omits `model`. Symlinking would silently break the read-only tool restriction. So `gen_agent.py` transforms the Pi-format source into each harness's schema; only `tools`/`name`/`model`/extension change — bodies are written in harness-agnostic capability language and pass through unchanged.

### The protocol is a hybrid

`subagent-protocol.md` = an **agnostic core** (create-plans pipeline, EXIT-report contract, routing tables, re-invocation — all text convention, portable everywhere) written in generic verbs (`spawn`/`await`/`steer`/`isolate`), plus per-harness **adapter** sections that bind those verbs to concrete tools, state capabilities, and define degradation fallbacks (e.g. no steering → abort + re-dispatch; no worktree isolation → sequential).

### Not shipped / excluded

- **`general-purpose`** — not shipped; every harness has a native built-in. Pi's parent-twin (`append` mode) has no equivalent elsewhere → pass explicit context when delegating on Claude/Copilot.
- **Codex** — intentionally out of scope (TOML agent format + no alias model mapping).

### Re-sync

```bash
bash ~/.agents/bin/sync.sh   # idempotent; run after editing any source
```

Pi reflects source instantly (symlink); Claude/Copilot variants regenerate on sync.

## The real spine of the library

### 1. Thinking before action

These skills improve the idea before code starts.

- **`grilling`** — model-invokable relentless stress-test of a plan, decision, or idea
- **`grill-me`** *(command)* — stress-tests a plan in pure conversation
- **`grill-with-docs`** *(command)* — pressure-tests a plan against the real codebase and docs
- **`pros-cons`** — forces a decision instead of endless “maybe” analysis

This layer exists for one reason: most bad implementation work starts as bad framing.

### 2. Planning that survives long sessions

This is the strongest part of the library.

- **`create-plans`** — builds a durable planning system with `BRIEF.md`, `ROADMAP.md`, phase plans, summaries, and handoffs
- **`to-plan`** *(command)* — fast path when the conversation is already clear and just needs to become an executable `PLAN.md`
- **`handoff`** *(command)* — compresses working state so another agent/session can resume without guessing

The goal is not documentation theater. The goal is executable planning and continuity.

### 3. Breaking work into trackable follow-ups

Once direction is clear, this turns it into project-management artifacts.

- **`create-jira-stories`** *(command)* — Jira story/subtask generation for a specific workflow

### 4. Focused specialist help

A few skills encode concrete patterns so the agent does not reinvent them badly.

- **`create-tests-autofixture`** — opinionated xUnit + AutoFixture + FakeItEasy test conventions
- **`create-feature-flags`** — LaunchDarkly/C# feature-flag workflow aligned to team conventions
- **`create-subagents`** *(command)* — how to structure and use subagents well
- **`create-agent-skills`** *(command)* — how to write better skills instead of cargo-culting prompt files
- **`tdd`** — red→green reference: test seams, vertical slices, test anti-patterns
- **`code-review`** — two-axis review (standards + spec) run as parallel sub-agents
- **`prototype`** — build a throwaway prototype to answer a design question
- **`resolving-merge-conflicts`** — intent-preserving merge/rebase conflict resolution
- **`find-skills`** — discover and install skills on demand
- **`create-frontend-slides`** *(command)* — presentation-building specialist
- **`writing-great-skills`** — model-invokable reference: the vocabulary and principles for writing predictable skills
- **`teach`** *(command)* — pedagogical walkthrough of a concept or codebase

*(command)* = lives in `_commands/`, invoked via `/skill:<name>`.

## Recommended usage patterns

### Brownfield feature work

```text
grill-with-docs
  ↓
to-plan           (small/clear work)
or
create-plans      (larger/multi-phase work)
```

### Greenfield / early exploration

```text
grill-me
  ↓
pros-cons         (if decision is fuzzy)
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

## Experimental skills

`_experimental/` holds skills that are auto-detected and usable, but not yet promoted as core. Same loading behavior as root-level skills — the folder just signals "still proving its value."

Current:
- **`frontend-design`** — visual design direction for UI (palette, type, layout, copy)
- **`backend-microservice-architecture`** *(command)* — backend service design principles
- **`evaluate-skills`** — behavioral eval of a skill against real prompts

Git worktrees are handled by `orca-cli` — Orca manages the worktrees under
`_workspaces/<repo>/<branch>`, so there is no separate raw-`git worktree` skill.

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
- **[Matt Pocock](https://github.com/mattpocock/skills)** — source of `grilling`, `grill-me`, `grill-with-docs`, `tdd`, `code-review`, `prototype`, `resolving-merge-conflicts`, `handoff`, `teach`, and `writing-great-skills`
- **[vercel-labs](https://github.com/vercel-labs/skills)** — source of `find-skills`
- **[Zara Zhang](https://github.com/zarazhangrui/frontend-slides)** — source of `create-frontend-slides`

## Related repos

- [dot-pi](https://github.com/mklingberg/dot-pi) — pi setup, agents, planning workflow
- [dot-config](https://github.com/mklingberg/dot-config) — macOS/dev environment config
- [dot-agents](https://github.com/mklingberg/dot-agents) — personal pi skill library