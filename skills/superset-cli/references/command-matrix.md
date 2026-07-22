# Superset CLI — command matrix

Exact flags for the installed `superset` CLI (grounded against v1.x). Global
flags on every command: `--json`, `--quiet`, `--api-key <key>` (env
`SUPERSET_API_KEY`), `--help`. Output auto-defaults to JSON under agent/CI envs.

## workspaces (alias `ws`)

| Command | Key flags |
|---|---|
| `workspaces list` | `--host <id>` \| `--local` (omit both = org-wide) |
| `workspaces get <id>` | `-f, --field <name>` (e.g. `name`, `branch`, `worktreePath`); id defaults to `$SUPERSET_WORKSPACE_ID` |
| `workspaces create` | `--project <id>` (req), `--name <n>` (req), `--branch <b>` \| `--pr <n>`, `--base-branch <b>`, `--local` \| `--host <id>` (one req), `--agent <preset\|uuid\|superset>`, `--prompt <text>` (req with `--agent`), `--command <cmd>`, `--attachment <path>` (repeatable, needs `--agent`) |
| `workspaces update <id>` | `--name <n>`, `--task-id <id>`, `--clear-task` |
| `workspaces delete <id...>` | variadic; `--local` \| `--host <id>` |
| `workspaces open <id>` | `--print` (emit deep link instead of opening app) |

Routing: `--local` (or a host that resolves to this machine) talks to the host
server over loopback — offline, no cloud roundtrip. If that host server is down,
the command errors and points at `superset start` (no silent cloud fallback).

## projects

| Command | Key flags |
|---|---|
| `projects list` | — (org-wide) |
| `projects create` | `--name <n>` (req), `--local` \| `--host <id>` (one req), `--clone <url>` + `--parent-dir <path>` \| `--import <path>` |
| `projects setup <id>` | `--local` \| `--host <id>`, `--parent-dir <path>` (clone) \| `--import <path>`, `--allow-relocate` |

- `create` = new cloud project (dedupe NOT applied). `setup` = adopt existing cloud project onto a host (idempotent).
- Clone mode lands repo at `<parent-dir>/<derived-name>/`.

## hosts

| Command | Notes |
|---|---|
| `hosts list` | Registered hosts + online status. Registration happens via `superset start` on each machine; no separate register command. |

Local host lifecycle: `superset start [--daemon] [--port <n>]`, `superset stop`,
`superset status`. Binds `127.0.0.1` only.

## agents

Terminal-agent rows configured per host (Settings → Agents). Presets seen on
this install: `claude`, `codex`, `copilot`, `pi`, plus `superset` (built-in chat).

| Command | Key flags |
|---|---|
| `agents list` | `--local` \| `--host <id>` (one req). First call seeds bundled defaults. |
| `agents create` | `--workspace <id>` (req), `--agent <preset\|uuid\|superset>` (req), `--prompt <text>` (req), `--attachment-id <uuid>` / `--attachment <path>` (repeatable) |

`agents create` returns `{ kind: "terminal"|"chat", sessionId, label }`.

## terminals (alias `term`)

| Command | Key flags |
|---|---|
| `terminals create` | `--workspace <id>` (req), `--command <cmd>` (omit = interactive shell), `--cwd <path>` (defaults to worktree) |

No `terminals list` or `terminals delete`. Returns `{ terminalId, status }`.

## Opening a specific session (deep link)

`workspaces open` targets a workspace, not a session. To focus a freshly created
session, build the link yourself keyed by the `kind` from `agents create`:

| `kind` | Example agents | Query param |
|---|---|---|
| `chat` | `superset` | `?chatSessionId=<sessionId>` |
| `terminal` | `claude`, `codex` | `?terminalId=<sessionId>` |

```bash
session=$(superset agents create --workspace <ws> --agent claude --prompt "…" --json)
kind=$(echo "$session" | jq -r '.kind')
sid=$(echo "$session" | jq -r '.sessionId')
open "superset://v2-workspace/<ws>?terminalId=$sid"     # or ?chatSessionId=$sid for chat
```

Append `&focusRequestId=<unique>` to force re-focus. Session must belong to the
workspace in the URL. On Linux/Windows use `xdg-open`/`start`.

## organization (alias `org`)

| Command | Key flags |
|---|---|
| `organization list` | marks active org |
| `organization switch <idOrSlug>` | sets active org in `~/.superset/config.json` |
| `organization members list` | `-s, --search <q>`, `--limit <n>` (default 50) |

## tasks (alias `t`)

Org task tracker. Workspaces can link to a task via `workspaces update --task-id`.

| Command | Key flags |
|---|---|
| `tasks list` | `--status <id>`, `--priority <urgent\|high\|medium\|low\|none>`, `--assignee <userId>`, `-m/--assignee-me`, `--creator-me`, `-s/--search <q>`, `--limit <n>`, `--offset <n>` |
| `tasks get <idOrSlug>` | — |
| `tasks create` | `--title <t>` (req), `--description`, `--priority`, `--assignee`, `--status-id`, `--estimate`, `--due-date <iso>`, `--labels a,b,c` |
| `tasks update <idOrSlug>` | same fields as create, all optional; also `--pr-url <url>` |
| `tasks delete <idOrSlug...>` | variadic |
| `tasks statuses list` | IDs for `--status` / `--status-id` |

## Output modes

- `--json`: raw payload, no `{data}` wrapper; empty → `null`.
- `--quiet`: one id per line for arrays; single id for objects; JSON fallback otherwise.
