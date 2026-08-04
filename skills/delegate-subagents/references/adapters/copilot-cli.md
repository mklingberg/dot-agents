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
