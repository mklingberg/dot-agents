# Roadmap Runs — auto-chain, hard stops, parallel waves

Read when executing an approved `.planning/` ROADMAP: plan-to-plan chaining, the
points that stop for the user, and parallel waves.

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

## Plan Completion → Next Plan

**Auto-chain through an approved roadmap.** When the ROADMAP is approved, running
its plans is within established scope — after Implement completes + Review passes,
proceed directly to the next `*-PLAN.md` without waiting for a fresh go-ahead.
Keep a brief progress note per plan (the "Next: ..." line) and roll on.

**Stop and ask the user only at hard stops** — the points where the plan can't be
followed without your input, i.e. a reason in `exit-handling.md` the orchestrator can't resolve itself:
- `checkpoint:human-verify` / `checkpoint:human-action`
- `architectural-decision` / `deviation-unclear` / `checkpoint:decision` the
  parent can't settle from BRIEF/ROADMAP/ISSUES/patterns
- Review FAIL where the spec/plan is wrong (not a trivial fix)
- `auth-required` with no usable creds
- Debug-loop cap reached

Everything else — the successful, plan-following path — rolls forward. Report the
full run to the user when the roadmap completes or a hard stop is hit.

## Parallelism

Gate on **dependency**, not files:
- **Independent plans** (neither reads the other's output) → spawn in parallel,
  each **isolated** (a git worktree per plan, if your harness offers it). Cap
  waves at 4. After all complete, merge the resulting branches sequentially;
  resolve conflicts at merge.
- **Dependent plans** (B reads A's code) → sequential, no isolation.

Without filesystem isolation, run independent plans **sequentially** instead. A
parallel mechanism that shares task state rather than isolating the filesystem is
safe only for plans whose file sets are disjoint.

Batch Review: one call with all PLAN.md paths after the wave completes.
