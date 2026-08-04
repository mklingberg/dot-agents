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
