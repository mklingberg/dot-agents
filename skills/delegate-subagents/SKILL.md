---
name: delegate-subagents
description: "Delegate to subagents: role choice, fire-and-forget background spawn, EXIT REPORT routing, roadmap auto-chain, parallel waves. Triggers: before spawning, EXIT REPORT. Orca DAGs: use orchestration."
---

# Subagent Delegation

Roles are referenced by name — `Explore`, `Research`, `Debug`, `Review`,
`Implement`, and the built-in `general-purpose`. Your harness's own tool
descriptions say how to spawn them; this skill says which one to spawn and what to
do with what comes back.

## Read on demand

| Read this | When |
|---|---|
| `references/exit-handling.md` | An Implement EXIT REPORT or Review FAIL arrived, you are aborting a running Implement, or you are re-dispatching a stopped plan |
| `references/roadmap-runs.md` | Running an approved ROADMAP: plan-to-plan auto-chain, hard stops, parallel waves |

## Where harnesses differ

Capabilities vary; the routing above does not. Read these as conditionals against
whatever your spawn tool actually offers:

- **No background execution** → run steps synchronously. Routing is identical.
- **No filesystem isolation** → independent plans run sequentially, not as
  parallel waves.
- **No mid-run steering** → the graceful abort is unavailable: let the subagent
  finish or stop consuming its result, then re-dispatch.
- **Cloud/async delegation** (a spawn that commits to a branch and opens a PR) is
  a different tool with different semantics — the fire-and-forget loop above
  assumes a local subagent.
- **general-purpose context** — assume it sees none of your live conversation and
  pass what it needs explicitly, unless your harness hands it the parent's prompt
  (where it does, that inheritance is also what makes it the expensive option).

## Execution Loop

**Default: run to completion.** An approved plan or roadmap *is* settled scope —
execute it through without re-confirming between steps or plans. Problems escalate
to the **orchestrator** first (resolve via Debug / re-dispatch, see
`references/exit-handling.md`); the user is asked only at the hard stops listed in
`references/roadmap-runs.md`.

**Spawning is fire-and-forget.** The turn ends on the spawn: one line to the user
— what you dispatched, what you'll do with the result. That is a complete turn.
The completion signal arrives on its own; read the EXIT / Completion Report then
and route per the tables in `references/exit-handling.md`.

Sequential chains (Implement → Review, Debug → Implement) dispatch each step off
the previous signal.

## Inline vs delegate

Delegate what you can *specify* and a command can *check*:

- **Specifiable** — you can write clear acceptance criteria. If you can't state
  what "done" looks like, neither can the subagent → `deviation-unclear`
  ping-pong.
- **Verifiable** — there's a cheap objective check (build / test / lint). With a
  verify command, failures are self-caught and concretely reported, so each retry
  loop stays cheap. Without one, the parent inspects output subjectively — the
  failure tax.

Inline costs more than delegating: every read and edit **re-compounds** in parent
context each turn, where a subagent's result returns once. Three bands:

- **inline** — one edit in a file already in front of you.
- **general-purpose** — work needing the parent's live conversation, or judgment
  no acceptance criteria can capture: unknown solution shape, or context-transfer
  ≈ the work (specifying it means pasting `AGENTS.md` plus several files of domain
  nuance). The most expensive delegation on every harness.
- **Implement** — everything else mechanical, even a single file.

The common failure is dumping the whole middle band into "inline."

**Split the task before you pick a band.** An unspecifiable question usually wraps
a specifiable search: send the search to Explore and keep the judgment. "Why does
X feel inconsistent" is a survey (Explore: find every site) plus an analysis
(yours). Reach for general-purpose only when the two genuinely can't be separated.

**Delegate the diagnosis too.** The failure tax mostly evaporates when Debug reads
the wreckage instead of you. Implement exits with a structured EXIT REPORT (or
Review returns a specific FAIL); that routes to **Debug** (cheap, replace-mode),
which returns a root cause. The parent re-dispatches Implement with the fix.

## Delegation Policy

- **Research** — any web search / online docs, **and** any lookup in the
  company's own knowledge base (Confluence wiki, Jira history). Use the Research
  role, not raw web or Atlassian tools inline. Domain and business-process
  questions that the code can't answer go here, not to Explore.
- **Explore** — any codebase search with 2+ steps or unknown location. A single
  targeted lookup in a known file stays inline.
- **Implement** — well-specified mechanical work, in two modes:
  - **Plan Mode** — a `.planning/` PLAN.md (create-plans skill). One Implement
    per PLAN.md.
  - **Spec Mode** — ad-hoc work with no PLAN.md ceremony. Pass an inline task
    spec in the invocation: objective, the exact files/area, acceptance/verify
    criteria, and any constraints. Use for ordinary changes that don't warrant a
    full plan.
  - **Pass required context.** Implement does **not** see project
    `AGENTS.md`/`CLAUDE.md` — it only loads project *skills* on its own. If the
    task depends on any rule, convention, or constraint that lives in
    `AGENTS.md`/`CLAUDE.md` (or elsewhere) and isn't captured by a skill, quote
    the relevant section verbatim in the invocation. When in doubt, include it.
    If you find yourself pasting the same rules every time, check whether your
    harness can inject shared rules into every subagent (Claude Code:
    `--append-subagent-system-prompt`).
- **Review** — after every Implement Completion Report (not EXIT REPORT). Pass
  the PLAN.md path (Plan Mode) or the inline spec + changed files (Spec Mode).
  **Skip** only when both hold: ≤2 auto tasks, and no file changed outside those
  named in the spec. Surface to user only on FAIL; warnings → note inline and
  carry on.
- **Debug** — on Implement exits `verification-failed`, `stuck`, or `blocker`.
  Pick a fix, re-invoke Implement.
