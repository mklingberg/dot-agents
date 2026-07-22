# Subagent Delegation & Orchestration

Harness-agnostic orchestration protocol. The **Core** below is written in generic
verbs — `spawn`, `await`, `steer`, `isolate`, `re-dispatch`, `background`. Each
harness binds those verbs to concrete tools in its **Adapter** section at the end.
Read the Core, then read the one `## Harness:` section matching your environment.

---

# CORE (harness-agnostic)

## Create-Plans Pipeline

```
.planning/
├── BRIEF.md
├── ROADMAP.md
├── ISSUES.md             # deferred enhancements
└── phases/01-foundation/
    ├── 01-01-PLAN.md     # main agent writes
    └── 01-01-SUMMARY.md  # Implement writes (existence = done)
```

## Execution Loop

**Spawn** every subagent in the **background** when your harness supports it (see
Adapter). Don't poll — **await** the completion signal, then read the EXIT /
Completion Report and route per the tables below. Sequential chains
(Implement → Review, Debug → Implement) still spawn each step; the parent just
awaits between them. If your harness has no background execution, run steps
synchronously — the routing logic is identical.

PLAN.md task types: `auto`, `checkpoint:human-verify`, `checkpoint:decision`, `checkpoint:human-action`.

## Subagent Roles

Every target harness provides these roles — either as a shipped definition
(`Explore`, `Research`, `Debug`, `Review`, `Implement`) or as a **built-in**
(`general-purpose`). Reference roles by name; the Adapter maps each to the local
implementation.

**Inline vs delegate:**
- Inline tool results re-compound in parent context every turn; an isolated
  subagent's result returns once and doesn't.
- **1 targeted lookup** (known file/symbol) → inline.
- **2+ searches OR unknown location** → Explore. No exceptions.
- **general-purpose** is the most expensive delegation (see Adapter for why on
  your harness). Before spawning, state in one line why Explore + Implement +
  Debug can't cover it.

## Delegation Policy

- **Research** — any web search / online docs. Use the Research role, not raw
  web tools inline.
- **Explore** — any codebase search with 2+ steps or unknown location. Single
  targeted lookup → do inline.
- **Implement** — well-specified mechanical plans. One Implement per PLAN.md.
- **general-purpose** — only for substantial work needing parent context/judgment:
  ambiguous deviations, exploratory fixes, multi-file investigations beyond
  Explore's scope.
- **Review** — after every Implement Completion Report (not EXIT REPORT). Pass
  PLAN.md path. **Skip** if plan had ≤2 auto tasks with no writes outside
  `<files>`. Surface to user only on FAIL; warnings → note inline, don't block.
- **Debug** — on Implement exits `verification-failed`, `stuck`, or `blocker`.
  Pick a fix, re-invoke Implement.

## Implement Exit Routing

Implement exits with an `EXIT REPORT` containing a `Reason`. **The EXIT REPORT is
a text convention, not a tool** — it works identically on every harness. Each
invocation is a fresh subagent — to resolve, **re-dispatch** with the resolution
(see §Re-invocation). To redirect *while still running* (rare), **steer** if your
harness supports it; otherwise abort and re-dispatch (see Adapter).

| Reason | Try first | Escalate if |
|---|---|---|
| `checkpoint` + subtype `human-verify` | Diff modified files vs `<done>`; run task's verify command if present | Needs visual/UX eyes |
| `checkpoint` + subtype `decision` | Check BRIEF, ROADMAP, ISSUES, patterns | Genuine user preference / business call |
| `checkpoint` + subtype `human-action` | — | Always |
| `architectural-decision` | — | Almost always — summarise trade-offs |
| `auth-required` | Check env vars; if set, re-dispatch. Otherwise → user | Almost always (browser/2FA/missing creds) |
| `verification-failed` | Spawn Debug with failure | Debug ambiguous |
| `stuck` | Read "Tried" list — spawn Debug with that context, then re-dispatch Implement with a different approach | Approach unclear or scope call |
| `deviation-unclear` | — | Always |
| `blocker` | If `trigger:` starts with `malformed-plan:` → ask user. Else → spawn Debug | Debug can't resolve |
| `commit-failed` | Inspect `git status` / hooks / lock files. Resolve and re-dispatch¹ | Repo state needs human (rebase, force-push call) |

Subtypes are planner hints, not directives — parent decides routing.

¹ Implement owns its own commits — orchestrator's "no auto-commit" rule doesn't apply inside its scope.

**Debug-loop cap:** after 2 Debug → Implement cycles on the same task, escalate to user.

**Default to asking the user when unsure.** Present the EXIT REPORT options.

**Many trivial checkpoint exits = plan too coarse.** If a plan exits 3+ times for verifies you can resolve from file reads, suggest the user split it.

## Review FAIL routing

- **Trivial fix** (missing import, wrong constant): re-dispatch Implement with
  `Fix: <Review's specific issue>` and the PLAN.md path.
- **Non-trivial / root cause unclear**: spawn Debug with Review's FAIL output,
  then re-dispatch Implement with the chosen fix.
- **Plan/spec wrong**: ask the user.

## Plan Completion → Next Plan

Don't auto-chain. After Implement completes + Review passes, report to user with
the "Next: ..." line from the completion report. Wait for explicit go-ahead
before spawning the next Implement. (Matches "establish scope before spawning".)

## Aborting a Running Implement

- Graceful: **steer** it — `"Stop now. Emit EXIT REPORT with reason: blocker,
  trigger: 'aborted by parent'. Do not continue."` If steering is unavailable on
  your harness, stop dispatching to it and treat outstanding work as lost.
- Hard: stop calling it. Outstanding work is lost. Use only if graceful fails.

## Parallelism

Gate on **dependency**, not files:
- **Independent plans** (neither reads the other's output) → spawn in parallel,
  each **isolated** (see Adapter for the isolation mechanism / whether it exists).
  Cap waves at 4. After all complete, merge the resulting branches sequentially;
  resolve conflicts at merge.
- **Dependent plans** (B reads A's code) → sequential, no isolation.

If your harness has no isolated-parallel mechanism, run plans **sequentially** —
correctness over speed.

Batch Review: one call with all PLAN.md paths after the wave completes.

## Re-invocation

```
Continue executing .planning/phases/<phase>/<plan>-PLAN.md.
Exit at Task [X] (<reason>) resolved: <decision / action / human's answer>.
Restart at: Task [X] (retry the stopped task) OR Task [X+1] (continue past it).
```

The `Restart at` instruction overrides Implement's auto-skip of evidenced-complete
tasks. Implement is stateless across invocations — it re-reads PLAN.md and
@context every time.

---

# HARNESS ADAPTERS

Read only the section matching your environment. Each maps the Core's generic
verbs to concrete mechanisms, states capabilities, and defines degradation
fallbacks.

## Harness: Pi

**Verb mapping**

| Verb | Mechanism |
|---|---|
| spawn | `Agent({ subagent_type, prompt, description })` |
| background | `run_in_background: true` (always use — see AGENTS.md) |
| await | completion notification (`<task-notification>`); do not poll |
| steer | `steer_subagent(id, message)` |
| isolate | `isolation: "worktree"` (independent parallel waves) |
| re-dispatch | fresh `Agent(...)` call, or `resume: <id>` |
| result | `get_subagent_result(id)` |

**Capabilities:** background ✅ · steering ✅ · worktree isolation ✅ (loud on
failure — safe to default-on for independent waves) · structured await ✅

**general-purpose:** `prompt_mode: append` — a *parent twin*. Inherits the
parent's entire system prompt + AGENTS.md + a sub-agent context bridge, so it
follows the same rules the parent does. This is why it's the most expensive
delegation (~10k+ parent-equivalent tokens vs ~150–1,500 for replace-mode agents).

**Economics (Pi-specific)** — `prompt_mode: replace` = fresh isolated prompt;
`append` = inherits full parent prompt.

| Agent | Mode | ~Input tokens |
|---|---|---|
| Explore | replace | ~144 |
| Research | replace | ~239 |
| Debug | replace | ~280 |
| Review | replace | ~276 |
| Implement | replace | ~1,453 |
| general-purpose | append | ~10k+ |

**Degradation:** none — Pi is the reference harness with full capabilities.

## Harness: Claude Code

**Verb mapping**

| Verb | Mechanism |
|---|---|
| spawn | Task tool (`subagent_type` = agent name) or model-mediated auto-delegation |
| background | `background: true` frontmatter / recent default; else runs foreground |
| await | tool result returns when subagent finishes (model-mediated) |
| steer | **unavailable** — subagents run in isolated context |
| isolate | `isolation: worktree` frontmatter (supported) |
| re-dispatch | fresh Task call with the resolution prompt |
| result | subagent's final response returns as the tool result |

**Capabilities:** background ~ (per-agent/global flag) · steering ❌ · worktree
isolation ✅ · structured await ✅ (synchronous tool-result)

**general-purpose:** built-in — no shipped definition needed. Its system prompt
is *replaced* (not appended), but CLAUDE.md still loads via message flow, so your
rules reach it. It does **not** inherit the parent's live conversation. →
**Degradation:** when delegating to general-purpose, pass more explicit context
in the prompt than you would on Pi; don't assume it sees parent turns.

**Degradation:**
- **No steering** → to abort/redirect a running subagent, you cannot inject
  mid-run. Let it finish or stop consuming its result, then re-dispatch. The
  "Aborting" graceful path degrades to the hard path.
- `--append-subagent-system-prompt` (CLI flag, global) can inject shared rules
  into every subagent if needed — coarse analog to Pi's append mode.

## Harness: GitHub Copilot CLI

**Verb mapping**

| Verb | Mechanism |
|---|---|
| spawn | `/agent <name>` (interactive) or `--agent <name>` (flag); model may auto-delegate |
| background | `/delegate <task>` = async **cloud** agent (commits, branch, draft PR) — different semantics; local subagents run inline |
| await | tool result / `/tasks` for delegated cloud work |
| steer | **unavailable** — subagents run isolated |
| isolate | no documented local worktree mechanism |
| re-dispatch | fresh `/agent` invocation with the resolution prompt |
| parallel | `/fleet <task>` = parallel local subagents, coordinated via shared task state (SQL todos), isolated prompts |

**Capabilities:** background ~ (`/delegate` = cloud only, not local-isolated) ·
steering ❌ · worktree isolation ❌ · parallel via `/fleet` (shared task state,
not prompt inheritance)

**general-purpose:** built-in (alongside `explore, task, research, code-review,
rubber-duck`). Isolated context; custom instructions from AGENTS.md /
`.github/copilot-instructions.md` combine into it, but parent live-conversation
inheritance is undocumented. → **Degradation:** same as Claude — pass explicit
context when delegating.

**Degradation:**
- **No steering** → abort = stop dispatching; graceful abort path unavailable.
- **No local worktree isolation** → run independent plans **sequentially**, not
  as parallel isolated waves. `/fleet` can parallelise but shares task state
  rather than isolating filesystem — don't use it for plans that write
  overlapping files.
- **`/delegate` is cloud** → treat as a different tool; the background execution
  loop above assumes *local* subagents. Prefer inline/sequential Implement.
