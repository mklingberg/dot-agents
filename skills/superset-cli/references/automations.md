# Superset CLI — automations

Automations are **scheduled agent runs**: a saved prompt + schedule that fires an
agent on a host, either reusing a workspace or creating a fresh one per run.
Alias: `auto`. Same fire-and-forget limitation applies — no CLI read-back of the
run's session output; use `automations logs` for run metadata and the desktop app
(or worktreePath, local) for content.

## Schedules (RRULE)

`--rrule` takes an RFC 5545 RRULE body. Examples:

- Weekdays 09:00 — `FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR;BYHOUR=9;BYMINUTE=0`
- Daily 08:30 — `FREQ=DAILY;BYHOUR=8;BYMINUTE=30`
- Every Monday — `FREQ=WEEKLY;BYDAY=MO;BYHOUR=9;BYMINUTE=0`

`--timezone` is IANA (default: host TZ, then UTC). `--dtstart` ISO 8601 (default: now).

## Commands

| Command | Key flags / notes |
|---|---|
| `automations list` | org-wide |
| `automations get <id>` | metadata only; prompt body omitted (use `prompt get`) |
| `automations create` | `--name <n>` (req), `--rrule <rrule>` (req), `--prompt <text>` \| `--prompt-file <path>`, `--timezone <iana>`, `--dtstart <iso>`, `--workspace <id>` and/or `--project <id>` (at least one req), `--host <id>`, `--agent <preset\|uuid\|superset>` (default `claude`) |
| `automations update <id>` | `--name`, `--rrule`, `--timezone`, `--dtstart`, `--host`, `--project`, `--workspace`, `--agent`, `--mcp-scope a,b,c`, `--enabled` / `--no-enabled`. Omitted flag = no change (not clear). |
| `automations prompt get <id>` | prints raw prompt to stdout, no trailing newline (round-trips with `set`) |
| `automations prompt set <id>` | `--from-file <path>` (req; `-` = stdin). Fully overwrites prompt. |
| `automations delete <id>` | — |
| `automations pause <id>` | sets `enabled: false` |
| `automations resume <id>` | sets `enabled: true`; recomputes `nextRunAt` |
| `automations run <id>` | dispatch immediately; returns `{ automationId, runId }`, does not wait |
| `automations logs <id>` | `--limit <n>` (default 20, max 100); recent runs |

Workspace mode: pass `--workspace` to reuse one workspace across runs; pass
`--project` (without workspace) for new-workspace-per-run.

## Examples

```bash
# Weekday triage, fresh workspace per run, prompt from file
superset automations create \
  --name "Weekday triage" \
  --project <projectId> \
  --rrule "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR;BYHOUR=9;BYMINUTE=0" \
  --agent claude \
  --prompt-file ./prompts/triage.md

# Edit prompt round-trip
superset automations prompt get <id> > prompt.md
# …edit…
superset automations prompt set <id> --from-file prompt.md

# Fire now / pause / inspect
superset automations run <id>
superset automations pause <id>
superset automations logs <id> --limit 50
```

If both `--prompt` and `--prompt-file` are passed to `create`, inline `--prompt` wins.
