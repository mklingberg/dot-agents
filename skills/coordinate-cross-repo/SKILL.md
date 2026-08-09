---
name: coordinate-cross-repo
description: "Coordinate one feature across several repos: set, order, plans, PRs. Triggers: 'cross-repo feature'. One repo: create-plans."
---

<objective>
Take a feature that touches more than one repo from description to merged pull requests:
work out which repos are involved, order them by how they actually depend on each other,
delegate planning and implementation per repo, and land the pull requests in that order.
</objective>

<essential_principles>
### Files are the source of truth
The feature's `ROADMAP.md` and `repos/*.md` hold the DAG and every repo's status. Any state
an orchestrator holds is generated from those files and disposable — regenerate it freely.
Reading orchestrator state as truth welds this skill to one tool permanently.

### This is supervised coordination
A coordinator owns the DAG and waits on each worker. Say so when engaging an orchestration
skill: those skills classify mentions of "another worktree" as ownership handoffs by default
and will decline to create the task and dispatch state the DAG needs.

### Planning per repo is delegated
`create-plans` writes `PLAN.md` inside each repo, exactly as it does for single-repo work.
This skill supplies the repo set and the order; it stays out of plan authoring.

### The orchestrator is whatever is available
Coordination speaks five verbs — **isolate**, **spawn**, **dispatch**, **await**, **gate** —
and an orchestration skill binds them to a tool. With none available, run the DAG
sequentially per the `delegate-subagents` skill: slower, same result.

### Every node reaches a terminal state you can name
`merged`, `pr-open-awaiting-owner`, `blocked-on-pipeline`, `blocked-on-user`. A node parked
in none of these is the failure this skill exists to prevent.
</essential_principles>

<process>

### 1. Resolve the repo set
Read `INDEX.md` at the polyrepo root (`repo-index` reads and maintains it). Match the feature
against its **Change Patterns** table first, then widen along **Dependency Edges** to catch
consumers the pattern misses.

Present the resulting set with a one-line reason per repo and get confirmation before
touching anything. A wrong repo set wastes every phase downstream, and the user recognises
a wrong set instantly.

Absent `INDEX.md`, offer to run `repo-index`'s refresh workflow — deriving the set by sweeping every
repo costs more than indexing them once.

### 2. Order by edge kind
Ordering follows the kind of edge between two repos, not file overlap.

| Edge kind | Order | Gate between them |
|---|---|---|
| `nuget` | producer, then consumers | producer's package **published** — a pipeline, not a sibling worker |
| `event` | consumer able to read the new shape, then publisher | none; both can proceed once the contract is agreed |
| `rest` | callee, then caller | callee deployed, or the caller's call is flagged off |
| `bundled` | host, then the repo shipping inside it | host build accepts the new asset shape |
| none | parallel | — |

An edge naming `external:<system>` marks a dependency with no checkout to plan in. Treat
that end as a **constraint**: state in the brief what the external side already provides,
and when the feature needs it to change, surface that as user-owned work before dispatching
anything that assumes it.

Write the result to `<root>/.planning/features/<ticket>/ROADMAP.md` from
`templates/ROADMAP.template.md`, and one `repos/<repo>.md` per repo from
`templates/repo-status.template.md`.

Cap concurrent workers at 4.

### 3. Prepare a checkout per repo
**isolate** each repo on its own branch. Branch names come from `create-feature-branch`, so
every repo in the feature carries the same ticket and the set is recognisable in a branch
listing.

### 4. Plan per repo
**spawn** a worker per repo whose job is `create-plans` in that checkout. Hand it: the
feature brief, its own slice, and the contract it must produce or consume. Withhold the
other repos' internals — a worker that plans against another repo's private detail couples
them.

### 5. Execute in DAG order
**dispatch** each ready node; **await** its terminal state; then dispatch whatever that
unblocked. Translate what comes back:

| Worker outcome | Coordinator action |
|---|---|
| plan complete, review passed | mark node done, dispatch newly ready nodes |
| needs a decision spanning repos | **gate** — resolve from the brief, or ask the user |
| needs a decision inside its own repo | the worker owns it; `delegate-subagents` routes it |
| blocked on a pipeline or an owning team | mark the node with that terminal state and carry on |

Waits are long — coding nodes routinely run tens of minutes. A wait that returns nothing is
a checkpoint, and the node is still alive.

### 6. Land
Open pull requests via `azure-devops` in DAG order. For a repo owned by another team,
the pull request is this feature's terminal state: that team reviews, approves, and operates
what merges. Record the reviewer from `INDEX.md`'s Ownership table, report it, and treat
downstream nodes as unblocked rather than waiting on their release.

### 7. Report
Per repo: branch, plan status, PR URL, terminal state. Then the feature's own state — fully
merged, or precisely what remains and who owns it.

</process>

<gotchas>
- **"Another worktree" reads as a handoff.** Orchestration skills default to treating that
  phrasing as an ownership transfer and skip creating lifecycle state. State that this run is
  supervised DAG coordination when you engage one.
- **A nuget gate is a pipeline, not a worker.** Waiting for a `worker_done` that a build
  server was always going to send hangs the DAG. Watch the pipeline, or gate to the user.
- **An owning team's release cadence is outside the DAG.** Blocking a node on someone else's
  merge stalls a feature for days; the open pull request is the completion.
- **A monorepo can absorb several nodes.** When two components live in one repo, they share a
  checkout and a pull request — the DAG has two nodes, the repo has one branch.
- **Per-repo `.planning/` is gitignored; the feature folder lives at the root** and is not in
  any repo. Neither is committed by this skill.
- **Worktree and workspace IDs go stale.** Resolve them from the tool at dispatch time and
  keep paths in the files.
- **A single-repo feature belongs to `create-plans`.** When step 1 resolves to one repo, hand
  over and stop — the DAG, feature folder, and orchestration are pure overhead.
- **An external node can't be dispatched.** A DAG node waiting on a system with no checkout
  never completes; it belongs in the brief as a stated assumption or in the report as
  user-owned work.
</gotchas>

<success_criteria>
- Repo set confirmed by the user before any checkout exists
- `ROADMAP.md` and one `repos/<repo>.md` per repo written under `<root>/.planning/features/<ticket>/`
- Every repo has its own branch, its own `PLAN.md`, and a pull request or a named blocker
- Every node ends in a named terminal state
- Feature works identically with no orchestrator available, sequentially
</success_criteria>
