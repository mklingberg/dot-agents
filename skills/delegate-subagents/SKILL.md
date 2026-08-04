---
name: delegate-subagents
description: "Delegate to subagents: role routing, background spawn rules, Implement EXIT REPORT handling, roadmap orchestration. Triggers: before spawning, EXIT REPORT, roadmap run. Orca DAGs: use orchestration."
---

# Subagent Delegation & Orchestration

Harness-agnostic orchestration protocol. The **Core** below is written in generic
verbs — `spawn`, `await`, `steer`, `isolate`, `re-dispatch`, `background`. Each
harness binds those verbs to concrete tools in an **adapter** file.

## Adapters — read one, on demand

Read the Core below, then the single adapter matching your environment. Each maps
the generic verbs to concrete tools, states capabilities, and defines degradation
fallbacks.

| Read this | When |
|---|---|
| `references/adapters/pi.md` | Running in Pi (`Agent` tool, `run_in_background`, `steer_subagent`) |
| `references/adapters/claude-code.md` | Running in Claude Code (`Task`/`Agent` tool, `.claude/agents/`) |
| `references/adapters/copilot-cli.md` | Running in GitHub Copilot CLI (`/agent`, `/delegate`, `/fleet`) |

Not sure which? Check which spawn tool you actually have, and read that one.

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

**Default: run to completion.** Once a plan/roadmap is approved, that approval
*is* the established scope — execute it all the way through without stopping for
re-confirmation between steps or plans. Problems escalate to the **orchestrator**
first (resolve via Debug / re-dispatch, see `references/exit-handling.md`); only stop and ask the
**user** at genuine confirmation points — the hard stops listed under §Plan
Completion. The AGENTS.md rule *"establish scope before spawning"* governs the
case where there is **no** approved plan yet (e.g. Implement Spec Mode ad-hoc
work you haven't been told to run); it does not require re-asking inside an
approved plan/roadmap.

**Spawning is fire-and-forget.** Spawn every subagent in the **background** (see
Adapter), and the turn ends on the spawn: one line to the user — what you
dispatched, what you'll do with the result — and control returns to them. That is
a complete turn. The completion signal arrives on its own; read the EXIT /
Completion Report then and route per the tables below.

Sequential chains (Implement → Review, Debug → Implement) dispatch each step off
the previous signal. Where a harness has no background execution, steps run
synchronously — routing logic is identical.

PLAN.md task types: `auto`, `checkpoint:human-verify`, `checkpoint:decision`, `checkpoint:human-action`.

## Subagent Roles

Every target harness provides these roles — either as a shipped definition
(`Explore`, `Research`, `Debug`, `Review`, `Implement`) or as a **built-in**
(`general-purpose`). Reference roles by name; the Adapter maps each to the local
implementation.

**Inline vs delegate:**
- Inline tool results re-compound in parent context every turn; an isolated
  subagent's result returns once and doesn't. Doing implementation yourself is
  *more* expensive to parent context than delegating it — every file read and
  edit re-compounds.
- **Mechanical work goes to Implement**, even a single file — the win is a clean
  parent context. One trivial edit you have already located stays inline.
- **general-purpose** is the most expensive delegation (see Adapter for why on
  your harness). Before spawning it, state in one line why Explore + Implement +
  Debug can't cover the work.

**When NOT to delegate (the counterweight).** The bias above is real but has an
edge. Delegation isn't free when it *fails* — the guardrail is the
**specifiable × verifiable** test:
- **Specifiable** — you can write clear acceptance criteria. If you can't state
  what "done" looks like, neither can the subagent → `deviation-unclear`
  ping-pong.
- **Verifiable** — there's a cheap objective check (build / test / lint). This is
  load-bearing: with a verify command, failures are self-caught and concretely
  reported, so each retry loop stays cheap. Without one, the parent must inspect
  output subjectively — the failure tax.

Delegate work you can *specify* and the machine can *check*. Keep inline (or send
to general-purpose) when:
- **Not specifiable** — exploratory, "figure out why X feels wrong," unknown
  solution shape. Implement is stateless, so it re-reads context every loop and
  you pay that tax N times. This is general-purpose's band, not Implement's.
- **Context-transfer ≈ the work** — if specifying it means pasting half of
  `AGENTS.md` + several files of domain nuance, the specification *is* the work.
  Do it inline.
- **Trivial + already located** — one edit in a file open in front of you.

Map: **Implement** = specifiable/verifiable band · **general-purpose** =
judgment/exploratory band · **inline** = trivial-and-located. The common failure
is dumping the whole middle band into "inline."

**Delegate the diagnosis too.** The failure tax mostly evaporates if you don't
personally read the wreckage. Implement exits with a structured EXIT REPORT (or
Review returns a specific FAIL); that routes to **Debug** (cheap, replace-mode),
which reads the mess and returns a root cause. Parent gets a diagnosis, then
re-dispatches Implement with the fix — it does *not* re-read everything itself.
The "parent must analyse what went wrong" cost is only real when you skip Debug.
Cap: 2 Debug → Implement cycles on one task, then escalate (see `references/exit-handling.md`).

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
- **general-purpose** — only for substantial work needing parent context/judgment:
  ambiguous deviations, exploratory fixes, multi-file investigations beyond
  Explore's scope.
- **Review** — after every Implement Completion Report (not EXIT REPORT). Pass
  the PLAN.md path (Plan Mode) or the inline spec + changed files (Spec Mode).
  **Skip** if the work was ≤2 auto tasks / a trivial spec with no writes outside
  the named files. Surface to user only on FAIL; warnings → note inline and carry on.
- **Debug** — on Implement exits `verification-failed`, `stuck`, or `blocker`.
  Pick a fix, re-invoke Implement.

## Exit handling — read on demand

| Read this | When |
|---|---|
| `references/exit-handling.md` | An Implement EXIT REPORT or Review FAIL arrived, you are aborting a running Implement, or you are re-dispatching a stopped plan |

## Plan Completion → Next Plan

**Auto-chain through an approved roadmap.** When the ROADMAP is approved, running
its plans is within established scope — after Implement completes + Review passes,
proceed directly to the next `*-PLAN.md` without waiting for a fresh go-ahead.
Keep a brief progress note per plan (the "Next: ..." line) and roll on.

**Stop and ask the user only at hard stops** — the points where the plan can't be
followed without your input, i.e. an Exit Routing reason the orchestrator can't
resolve itself:
- `checkpoint:human-verify` / `checkpoint:human-action`
- `architectural-decision` / `deviation-unclear` / `checkpoint:decision` the
  parent can't settle from BRIEF/ROADMAP/ISSUES/patterns
- Review FAIL where the spec/plan is wrong (not a trivial fix)
- `auth-required` with no usable creds
- Debug-loop cap reached (2 Debug → Implement cycles on one task)

Everything else — the successful, plan-following path — rolls forward. Report the
full run to the user when the roadmap completes or a hard stop is hit.

Approval to *begin* a roadmap is still required — this section only removes the
per-plan re-confirmation once you have it.

## Parallelism

Gate on **dependency**, not files:
- **Independent plans** (neither reads the other's output) → spawn in parallel,
  each **isolated** (see Adapter for the isolation mechanism / whether it exists).
  Cap waves at 4. After all complete, merge the resulting branches sequentially;
  resolve conflicts at merge.
- **Dependent plans** (B reads A's code) → sequential, no isolation.

Where a harness has no isolated-parallel mechanism, plans run **sequentially**.

Batch Review: one call with all PLAN.md paths after the wave completes.

