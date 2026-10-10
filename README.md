# ~/.agents

A personal **cross-harness agent workspace**: skills, subagent definitions, an orchestration protocol, and global instructions — one source of truth shared across [pi](https://github.com/earendil-works/pi-coding-agent), Claude Code, and GitHub Copilot CLI.

This is not a pile of prompt snippets. It is a working system for getting from vague idea to durable execution with less drift, less context loss, and better decisions — usable from whichever agent you happen to be in.

> Better plans. Harder questions. Cleaner execution. Same setup, any harness.

Four shared assets live here and propagate to each tool (see [Cross-harness sync](#cross-harness-agents--sync)):

| Asset | What it is |
|---|---|
| `skills/` | Agent Skills (SKILL.md) — the bulk of this repo |
| `agents/` | Subagent definitions (Pi-format source) |
| `skills/delegate-subagents/` | Delegation protocol as a skill (harness-agnostic; exit-handling + roadmap references) |
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
├── agents/                   Pi-format subagent defs (source of truth)
│   ├── Explore.md  Research.md  Debug.md  Review.md  Implement.md
├── bin/                      sync.sh (propagate) + gen_agent.py (transform)
└── skills/
    ├── _commands/                Manual-trigger skills (hidden from auto-detection)
    ├── _experimental/            Auto-detected but not yet promoted as core
    ├── azure-devops/            Promoted skills live flat at the root
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
| tool/domain noun | Everything for one external system | `azure-devops`, `orca` |
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

| Asset | Pi | Claude Code | Copilot CLI | Codex |
|---|---|---|---|---|
| `skills/` | native scan | **flat per-skill symlinks** `~/.claude/skills/<name>` | native scan | native scan |
| `AGENTS.md` | symlink | symlink as `~/.claude/CLAUDE.md` | symlink `~/.copilot/AGENTS.md` | **`@import` line appended** |
| `skills/delegate-subagents/` | (via `skills/` scan) | (via flattened symlink) | (via `skills/` scan) | (via `skills/` scan) |
| `agents/*.md` | symlink | **generated** `.md` | **generated** `.agent.md` | — |

Pi and Copilot scan `~/.agents/skills` natively (any depth) — no symlink needed. Claude scans only **one level deep**, so it can't see skills grouped under `_commands/` or `_experimental/`; `sync.sh` rebuilds `~/.claude/skills` as a real dir of per-skill symlinks (any depth → flat), keeping the grouped source layout for your own organization. Codex also scans `~/.agents/skills` natively (it's Codex's preferred user-level skills path, ahead of the legacy `~/.codex/skills`).

### Codex: instructions yes, agent defs no

Codex's `AGENTS.md` is user-owned (it typically already holds its own `@import` lines), so
sync **appends** `@~/.agents/AGENTS.md` rather than symlinking over it — idempotent, and it
covers both `~/.codex` and every Orca-managed per-account home
(`~/Library/Application Support/orca/codex-accounts/*/home`).

`@import` support is undocumented but **verified empirically** — a probe file imported into
`~/.codex/AGENTS.md` was expanded and answered correctly by `codex exec`. Don't trust a
source-grep that says otherwise; re-run the probe if it ever looks broken.

### Why agents are generated, not symlinked

The agent frontmatter genuinely diverges per harness — mainly the `tools` vocabulary (`read,bash,grep` → Claude `Read,Bash,Grep,Glob` → Copilot `read,execute,search`) and `model`. The Pi source pins a fully-qualified id (e.g. `github-copilot/claude-sonnet-5`) so Pi resolves it deterministically and it passes `scopeModels` (must be in `enabledModels`); `bin/gen_agent.py` derives the bare Claude alias (`sonnet`/`haiku`/`opus`) from the id's family keyword, and Copilot omits `model`. Symlinking would silently break the read-only tool restriction. So `gen_agent.py` transforms the Pi-format source into each harness's schema; only `tools`/`name`/`model`/extension change — bodies are written in harness-agnostic capability language and pass through unchanged.

### The protocol is harness-agnostic, with no adapters

`skills/delegate-subagents/SKILL.md` is all text convention — role routing, the EXIT-report contract, re-invocation — portable everywhere. It used to ship a per-harness adapter file mapping generic verbs (`spawn`/`await`/`steer`/`isolate`) to each harness's tools; those were deleted. Every harness already documents its own spawn tool in an always-loaded tool description, so the adapters duplicated that surface and drifted from it (the Claude Code one still claimed steering was impossible after `SendMessage` shipped). What the tool descriptions *don't* state — the protocol consequence of a missing capability — survives as conditionals in the skill: no background → synchronous, no isolation → sequential, no steering → hard abort only.

It lives as a skill so the harness's own skill machinery handles the referral — a pointer to a file competes with everything else in the turn, a listed skill does not.

### Not shipped / excluded

- **`general-purpose`** — not shipped; every harness has a native built-in. Pi's parent-twin (`append` mode) has no equivalent elsewhere → pass explicit context when delegating on Claude/Copilot.
- **Codex agent defs** — out of scope (TOML agent format + no alias model mapping). Instructions and skills *do* reach Codex; see above.

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
- **`retro`** *(command)* — retrospective on a session: suggests environment fixes (checks, pointers, tooling) so the next run goes better
- **`coordinate-cross-repo`** — extends the same model across repos: works out the repo set, orders them by real dependency, delegates a plan per repo, and lands the PRs in that order. Reads the `INDEX.md` served by `repo-index`. Single repo → use `create-plans`

The goal is not documentation theater. The goal is executable planning and continuity.

### 3. Breaking work into trackable follow-ups

Once direction is clear, this turns it into project-management artifacts.

- **`jira`** — Jira REST for Mina Sidor: stories and subtasks, JQL search, transitions

### 4. Focused specialist help

A few skills encode concrete patterns so the agent does not reinvent them badly.

- **`create-tests-autofixture`** — opinionated xUnit + AutoFixture + FakeItEasy test conventions
- **`launchdarkly`** — feature flags in the Teamy C# stack, plus the LD REST API
- **`walley-bruno`** — run Bruno/Edge requests locally: test customers, purchases, notify flows
- **`azure-devops`** — Azure DevOps over REST+PAT: open PRs, answer PR comment threads, diagnose failing builds. Environment-specific values live in one `<config>` block; the rest is portable
- **`create-agent-skills`** *(command)* — how to write better skills instead of cargo-culting prompt files
- **`tdd`** — red→green reference: test seams, vertical slices, test anti-patterns
- **`diagnosing-bugs`** — hard-bug loop: no hypothesis until a command goes red on this bug; then minimise, rank hypotheses, instrument, fix with a regression test
- **`code-review`** — two-axis review (standards + spec) run as parallel sub-agents
- **`pr`** — PR body format: a visual summary, before/after evidence, and a merge-danger call (one-way/two-way door, blast radius)
- **`prototype`** — build a throwaway prototype to answer a design question
- **`domain-knowledge`** — products, markets, vocabulary and rules, read from the untracked `DOMAIN.md`; canon lives in Confluence
- **`confluence`** — read-only Confluence search and page reads; holds the space-key map
- **`repo-index`** — answers what repos, components and dependencies exist from `INDEX.md`; its refresh workflow rebuilds the derived regions and leaves curated ones untouched. Named for the common path (reading, daily) rather than the rare one (regenerating), which is why it isn't `create-*`
- **`delegate-subagents`** — which agent role to spawn, background discipline, EXIT REPORT routing, parallel waves
- **`find-skills`** *(command)* — discover and install skills on demand
- **`frontend-design`** *(command)* — visual design direction for UI (palette, type, layout, copy)
- **`evaluate-skills`** *(command)* — behavioral eval of a skill against real prompts
- **`create-frontend-slides`** *(command)* — presentation-building specialist
- **`writing-for-agents`** — model-invokable style guide for anything agents read: skills, `AGENTS.md`, `CLAUDE.md`
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
- **`backend-microservice-architecture`** *(command)* — backend service design principles

Git worktrees are handled by `orca` — Orca manages the worktrees under
`_workspaces/<repo>/<branch>`, so there is no separate raw-`git worktree` skill.

## Orca integration skills

`orca` (router) and `orca-browser` are hand-rolled thin routers, deliberately not catalogued above.
The real guides come version-matched from the binary via `orca skills get <name>`.
They are not in `.skill-lock.json`. Never run `orca skills install`/`update`: that reinstalls
the upstream `orca-cli`/`orchestration`/`computer-use` stubs.

## Adding a new skill

1. Pick a name using the prefix conventions above (`create-`, `to-`, `grill-`, `review-`, bare verb, or a tool/domain noun)
2. Create `skills/<name>/SKILL.md` (or `skills/_commands/<name>/SKILL.md` for manual-only)
3. Add frontmatter with `name` and `description`
4. Write focused instructions for a real repeated problem
5. Decide activation mode:
   - **Auto-detected** (default): root of `skills/`, or `skills/_experimental/` if not yet proven. Agent triggers from user phrasing matching the description.
   - **Manual only**: `skills/_commands/` and add `disable-model-invocation: true`. Invoked via `/skill:<name>`.
6. Promote only if it proves durable in actual use — move from `_experimental/` to root

Rule of thumb: if a skill is just a fancy alias for a one-off prompt, it probably should not exist. If it works but rarely triggers, move it to `_commands/`.

## Adding a new agent

Never write into `~/.claude/agents/` or `~/.copilot/agents/` — sync regenerates both.

1. Create `agents/<Name>.md` in Pi format:
   ```yaml
   ---
   description: "What it does. Use when …"   # the routing signal every harness sees
   display_name: Name                          # → Claude `name` (lowercased), Copilot `name`
   tools: read, bash, grep, find, ls           # Pi vocabulary; `all` (or omit) = inherit everything
   model: github-copilot/claude-sonnet-5       # pinned for Pi; Claude gets the family alias, Copilot omits it
   prompt_mode: replace                        # Pi-only: replace = clean context, append = parent twin
   ---
   ```
   `gen_agent.py` maps `read/bash/grep/find` per harness and drops `ls`; any other token passes through verbatim. There is no `skill` token — a restricted agent can't load skills, so reference a skill it needs by path (see `agents/Debug.md`).
2. Write the body in harness-agnostic capability language ("read the file", not "use the Read tool").
3. Run `bash bin/sync.sh` and check the generated `~/.claude/agents/<name>.md` frontmatter.
4. Give it a route: add the role to `skills/delegate-subagents/SKILL.md`, or nothing will dispatch to it.


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

- **[the-maniac](https://github.com/the-maniac/claude-code-resources)** — source of `create-plans` and `create-agent-skills`
- **[Matt Pocock](https://github.com/mattpocock/skills)** — source of `grilling`, `grill-me`, `grill-with-docs`, `tdd`, `code-review`, `diagnosing-bugs`, `prototype`, `handoff`, `teach`, `writing-for-agents`, `retro`, and `pr`
- **[Dex Horthy](https://github.com/humanlayer/humanlayer)** — the visuals menu in `pr`, via his `show-me` skill
- **[vercel-labs](https://github.com/vercel-labs/skills)** — source of `find-skills`
- **[Zara Zhang](https://github.com/zarazhangrui/frontend-slides)** — source of `create-frontend-slides`

## Related repos

- [dot-pi](https://github.com/mklingberg/dot-pi) — pi setup, agents, planning workflow
- [dot-config](https://github.com/mklingberg/dot-config) — macOS/dev environment config
- [dot-agents](https://github.com/mklingberg/dot-agents) — personal pi skill library