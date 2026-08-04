# Exit Handling — Implement EXIT REPORTs, Review FAILs, abort, re-invocation

Read when an Implement EXIT REPORT or a Review FAIL arrives, or when re-dispatching
a stopped plan.

## Implement Exit Routing

Implement exits with an `EXIT REPORT` containing a `Reason`. **The EXIT REPORT is
a text convention, not a tool** — it works identically on every harness. Each
invocation is a fresh subagent — to resolve, **re-dispatch** with the resolution
(see §Re-invocation). To redirect *while still running* (rare), **steer** if your
harness supports it; otherwise abort and re-dispatch (see your adapter in `references/adapters/`).

| Reason | Try first | Escalate if |
|---|---|---|
| `checkpoint` + subtype `human-verify` | Diff modified files vs `<done>`; run task's verify command if present | Needs visual/UX eyes |
| `checkpoint` + subtype `decision` | Resolve from BRIEF, ROADMAP or ISSUES; escalate if none of them names the choice | Genuine user preference / business call |
| `checkpoint` + subtype `human-action` | — | Always |
| `architectural-decision` | — | Almost always — summarise trade-offs |
| `auth-required` | Check env vars; if set, re-dispatch. Otherwise → user | Almost always (browser/2FA/missing creds) |
| `verification-failed` | Spawn Debug with failure | Debug ambiguous |
| `stuck` | Read "Tried" list — spawn Debug with that context, then re-dispatch Implement with a different approach | Approach unclear or scope call |
| `deviation-unclear` | — | Always |
| `blocker` | If `trigger:` starts with `malformed-plan:` → ask user. Else → spawn Debug | Debug can't resolve |
| `commit-failed` | Inspect `git status` / hooks / lock files. Resolve and re-dispatch¹ | Repo state needs human (rebase, force-push call) |

Subtypes are planner hints, not directives — parent decides routing. PLAN.md task
types: `auto`, `checkpoint:human-verify`, `checkpoint:decision`,
`checkpoint:human-action`.

¹ Implement owns its own commits — orchestrator's "no auto-commit" rule doesn't apply inside its scope.

**Debug-loop cap:** after 2 Debug → Implement cycles on the same task, escalate to user.

**Many trivial checkpoint exits = plan too coarse.** If a plan exits 3+ times for verifies you can resolve from file reads, suggest the user split it.

## Review FAIL routing

- **Trivial fix** (missing import, wrong constant): re-dispatch Implement with
  `Fix: <Review's specific issue>` and the PLAN.md path.
- **Non-trivial / root cause unclear**: spawn Debug with Review's FAIL output,
  then re-dispatch Implement with the chosen fix.
- **Plan/spec wrong**: ask the user.

## Aborting a Running Implement

- Graceful: **steer** it — `"Stop now. Emit EXIT REPORT with reason: blocker,
  trigger: 'aborted by parent'. Do not continue."` If steering is unavailable on
  your harness, stop dispatching to it and treat outstanding work as lost.
- Hard: stop calling it. Outstanding work is lost. Use only if graceful fails.

## Re-invocation

```
Continue executing .planning/phases/<phase>/<plan>-PLAN.md.
Exit at Task [X] (<reason>) resolved: <decision / action / human's answer>.
Restart at: Task [X] (retry the stopped task) OR Task [X+1] (continue past it).
```

The `Restart at` instruction overrides Implement's auto-skip of evidenced-complete
tasks. Implement is stateless across invocations — it re-reads PLAN.md and
@context every time.
