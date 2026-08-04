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
| result | arrives with the completion notification. `get_subagent_result(id)` only for an agent that already reported complete — never with `wait: true`, never in the turn you spawned it (blocked by the `no-block-wait` extension) |

**Capabilities:** background ✅ · steering ✅ · worktree isolation ✅ (loud on
failure — safe to default-on for independent waves) · structured await ✅

**general-purpose:** `prompt_mode: append` — a *parent twin*. Inherits the
parent's entire system prompt + AGENTS.md + a sub-agent context bridge, so it
follows the same rules the parent does. This is why it's the most expensive
delegation (~10k+ parent-equivalent tokens vs ~150–1,500 for replace-mode agents).

**Economics (Pi-specific)** — `prompt_mode: replace` = fresh isolated prompt;
`append` = inherits full parent prompt.

These are the subagent's *own* input cost — **not** a cost charged to the
parent, and **not** a reason to inline. Doing the same work inline is more
expensive to *parent* context because every read/edit re-compounds every turn.
A higher number here (Implement ~1,453) still beats hoarding the work inline.
The number to avoid is general-purpose's ~10k+.

| Agent | Mode | ~Input tokens |
|---|---|---|
| Explore | replace | ~144 |
| Research | replace | ~239 |
| Debug | replace | ~280 |
| Review | replace | ~276 |
| Implement | replace | ~1,453 |
| general-purpose | append | ~10k+ |

**Degradation:** none — Pi is the reference harness with full capabilities.
