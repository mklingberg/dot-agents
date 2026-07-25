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
- **Agents must NOT create projects — only workspaces.** `projects create`/`setup` land in the host-local plane and never appear in the desktop app's project list (the app reads the `v2_projects` cloud registry; CLI-created projects never enter it). Registering an app-visible project is a **human** action via the desktop app's "Add project". Agents create *workspaces* under an existing project id. **Division of labour that avoids all known breakage: human adds/removes projects in the app; agent only creates/deletes workspaces under an existing project id.**
- **`projects list` = cloud projects ∩ host projects, matched by ID.** A repo can have a project record in BOTH stores yet stay invisible if the two ids differ (host `projects.id` ≠ cloud `v2_projects.id` for the same `repo_path`). This split-brain happens when the host project was minted by CLI/worktree automation (`projects create`) instead of adopted from the cloud id. Symptoms: repo shows in the app (cloud id) but never in `superset projects list` (host id); `projects setup <cloud-id>` returns `Project not found` (CLI setup only sees host-local ids); renaming/deduping host-side does nothing. **The CLI cannot repair an id mismatch** — `create` only makes more dupes, `setup` can't adopt a cloud-only id. Confirmed unresolvable via CLI as of v1.16.1 (likely a Superset bug). Escalate to the human / Superset support; do not try to fix it by spawning projects.
- **Never run `superset projects create`/`setup` to "fix" a missing project.** Each `create` mints another host-local dupe sharing the same `repo_path`; multiple rows on one path make `projects list` drop them all. Cleanup requires stopping the app + all daemons (`terminal-host.js`, `pty-daemon.js`) and editing `host.db` by hand — high-risk, human-supervised, offline only.
- **`projects list` is not the full org picture.** It shows only org projects **already set up on this host** (org projects ∩ host-setup). The org may hold projects you can't see here — including ones not set up locally, or stale/orphaned records where `projects setup <id>` returns `Project not found`. Never conclude "no project exists" from `projects list` alone; cross-check `workspaces list` (a workspace referencing a `projectId` your `projects list` omits = a hidden/host-local project) before considering `create`.
- **SQLite fallback:** `~/.superset/local.db` (desktop app cache) is readable read-only even when logged out, but it is a stale cache — never authoritative, never write to it.
</gotchas>

## Preflight (always)

```bash
superset auth whoami --json        # fails → tell user to `superset auth login`
superset status --json             # ensure local host running; else `superset start --daemon`
superset projects list --json     # projects SET UP ON THIS HOST only — NOT the full org list
superset workspaces list --json    # cross-check: a projectId here that projects list omits = a hidden/host-local project
superset hosts list --json         # remote target? grab machineId. Local? use --local
```

If you need a project that `projects list` doesn't show, it may exist org-wide but not be set up here — do not `projects create`. Ask the human to add it via the desktop app, then create workspaces under it.

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
