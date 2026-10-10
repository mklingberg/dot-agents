---
name: orca
description: >-
  Orca app via the `orca` CLI: worktrees (incl. child worktrees, spawning
  codex/claude in one), terminals (read/wait/send), repos, automations,
  artifacts, worktree comments, skill sharing; handing work off to another
  agent; supervised multi-agent coordination (task dispatch, DAGs, decision
  gates, ask/reply, worker_done waits); OS-level input in native apps or
  external browser windows. Orca's embedded browser: orca-browser.
---

# Orca

Router. The real guides come version-matched from the `orca` binary; load the right one before running any Orca command.

## Executable

Use `$ORCA_CLI_COMMAND` if set, else `orca`. If it cannot run, report the exact error and stop. Don't fall through to another executable.

## Route

| Need | Run |
|---|---|
| Worktrees, terminals, repos, automations, artifacts, worktree comments, skill sharing, unsupervised handoff | `orca skills get orca-cli` |
| Supervised multi-agent coordination (dispatch, DAGs, gates, ask/reply, worker_done/escalation waits, coordinator loops) | `orca skills get orchestration` |
| OS-level input in native apps, external browser windows (Chrome/Edge/Safari), webviews, Orca app UI | `orca skills get computer-use` |
| Orca's embedded browser | use the `orca-browser` skill |
| Anything else Orca bundles (iOS/Android emulator, Linear, per-workspace env recipes) | `orca skills list`, then `orca skills get <name>` |

## Handoff vs supervise

A handoff ("hand off", "handover", "give this to another agent", "another worktree") goes to the orca-cli guide, unless the user asked to supervise, monitor, wait for results or coordinate a DAG. Supervision goes to orchestration. Coordination needs real Orca runtime state. Never substitute a non-Orca subagent tool for it.

Ordinary subagent delegation inside this harness (role choice, background spawns, EXIT REPORTs) is not Orca: use `delegate-subagents`.

## Fallbacks

- Prefer `--json`. If Orca isn't running: `orca open --json`, then retry.
- If `skills get` is unknown, say an Orca update restores it.
- Use `--help` for read-only discovery. Don't guess flags.
- Prefer a programmatic path (shell, git, HTTP, existing CLIs) over computer-use whenever it can do the job.
