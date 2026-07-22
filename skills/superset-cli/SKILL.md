---
name: superset-cli
description: "Spawn/manage Superset workspaces as parallel worktrees via the `superset` CLI. Triggers: 'superset workspace', 'run this in parallel', 'fire-and-forget agent', 'superset automation'."
---

## Overview

The `superset` CLI drives **workspaces**: branch-scoped working copies on a host
that behave like parallel git worktrees. Use it to fan out work into isolated
checkouts — either fire-and-forget (spawn a workspace with an agent + prompt and
walk away) or supervised (spawn, operate in the on-disk worktree, collect
results, delete).

**Default mode is fire-and-forget** (Model 2). Supervised collection (Model 1) is
an appendix, only viable when the host is this machine (`--local`).

Full per-command flag tables live in `references/command-matrix.md`. Scheduled
runs live in `references/automations.md`. Read those on demand (see
`<reference_index>`); do not preload.

## Core concepts

- **Project** — a repo registered with the org (org-wide cloud record + host checkouts). Has a UUID.
- **Host** — a machine running the host server. `--local` = this machine; `--host <machineId>` = a remote one.
- **Workspace** — a branch-scoped worktree on a host. Has a UUID. This is the unit you spawn/delete.
- **Agent / terminal session** — a process launched inside a workspace. Presets: `claude`, `codex`, `copilot`, `pi`, or `superset` (built-in chat).

<gotchas>
## Gotchas — read before running

- **Output is JSON by default under agents.** When `CLAUDECODE`/`CI`/`SUPERSET_AGENT` etc. are set, every command auto-emits JSON. Parse with `jq`. Add `--quiet` for ID-only.
- **No read-back of session output.** There is NO CLI to scrape a terminal's or agent's stdout, and no `terminals list`/`terminals delete`. Fire-and-forget cannot collect results via CLI — a human reviews sessions in the desktop app, OR (local only) collect via the worktree path (Model 1).
- **Local host must be running.** If `--local`/resolved-local and the host server is down, commands error and point at `superset start`. Run `superset status` first.
- **Auth is required even for local.** Expired session → `Not logged in`. Run `superset auth whoami` in preflight; if it fails the user must `superset auth login` (browser OAuth — you cannot do it non-interactively).
- **`--command` runs once; independent of `--agent`/`--prompt`.** Pass either or both. `--attachment` only applies when `--agent` is set.
- **Exactly one of `--branch` / `--pr`.** And exactly one of `--local` / `--host`.
- **`create` always makes a NEW cloud project** even if one exists for the repo. To adopt an existing project on this machine use `projects setup <id>`, not `create`.
- **SQLite fallback:** `~/.superset/local.db` (desktop app cache) is readable read-only even when logged out, but it is a stale cache — never authoritative, never write to it.
</gotchas>

## Preflight (always)

```bash
superset auth whoami --json        # fails → tell user to `superset auth login`
superset status --json             # ensure local host running; else `superset start --daemon`
superset projects list --json      # find the project UUID (field: id)
superset hosts list --json         # remote target? grab machineId. Local? use --local
```

## Spawn — fire-and-forget (default)

Create a workspace and hand it to an agent in one call:

```bash
superset workspaces create \
  --project <projectId> \
  --name "fix-login-bug" \
  --branch task/fix-login-bug \
  --base-branch main \
  --local \
  --agent claude \
  --prompt "Fix the failing login test; commit when green." \
  --json
```

- `--base-branch` forks a new branch when `--branch` doesn't exist (defaults to project default branch).
- Review an existing PR: swap `--branch`/`--base-branch` for `--pr 123`.
- Run a one-off setup command too: add `--command "bun install && bun test"`.
- Upload context for the agent: `--attachment ./trace.log` (repeatable; needs `--agent`).

Add sessions to an already-created workspace with `agents create` / `terminals create`
(see `references/command-matrix.md`).

## Inspect

```bash
superset workspaces list --local --json                       # or org-wide without --local
superset workspaces get <workspaceId> --json                  # full detail
superset workspaces get <workspaceId> -f worktreePath         # just the on-disk path
superset workspaces open <workspaceId>                        # focus in desktop app
superset workspaces open <workspaceId> --print                # print deep link instead
```

To open a **specific session** the desktop link needs a query param keyed by the
session `kind` returned from `agents create` (`chat` → `?chatSessionId=`,
`terminal` → `?terminalId=`). See the "Opening a specific session" block in
`references/command-matrix.md`.

## Cleanup

```bash
superset workspaces delete <ws1> <ws2> <ws3> --local --json   # variadic
```

Deleting the workspace tears down its sessions (there is no per-terminal delete).

## Model 1 — supervised collection (local only, optional)

When the host is this machine and you need to act on results programmatically:

```bash
ws=$(superset workspaces create --project <id> --name work --branch task/x --base-branch main --local --quiet)
path=$(superset workspaces get "$ws" -f worktreePath)
# operate directly in $path with normal git/shell/read tools, run tests, read output
superset workspaces delete "$ws" --local
```

This is the true "parallel worktree" workflow: the CLI provisions the branch
checkout, you drive it with ordinary tooling, then delete. Worktrees live under
`<parentDir>/<projectId>/<branch-dir>/`.

<reference_index>
## Load on demand

| Read this | When |
|---|---|
| `references/command-matrix.md` | Need exact flags for projects/hosts/agents/terminals/org/tasks, or the session deep-link recipe |
| `references/automations.md` | Creating/managing scheduled agent runs (RRULE), reading/writing automation prompts, run logs |
</reference_index>

<success_criteria>
- Preflight confirms auth + a running local host before any spawn.
- Spawns pick the correct project UUID and exactly one of `--local`/`--host` and `--branch`/`--pr`.
- Never promises to read session stdout via CLI; collects results only via worktreePath (local) or defers to the desktop app.
- Cleans up workspaces it created when the task is done.
</success_criteria>
