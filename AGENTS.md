# ~/.agents — repo instructions

This file covers maintaining this repo. The global instructions every harness loads live in
`global/AGENTS.md`. Layout, sync table and skill conventions are in `README.md`.

## After editing

Run `bash ~/.agents/bin/sync.sh` yourself after changing `global/AGENTS.md`, `agents/*.md` or
adding/moving a skill. Claude and Copilot see only the synced copies. It writes into
`~/.claude`, otherwise write-denied: this script is the sanctioned exception, invoked by that
exact command.

## Updating upstream skills

Skills recorded in `.skill-lock.json` come from upstream repos, and `skills update` overwrites
them. The skills below carry local changes. After an update, `git diff` each one and reapply
the local changes on top of upstream's new text. Where the two overlap in intent, upstream
wins.

| Skill | Upstream | Local changes |
|---|---|---|
| `grilling` | `mattpocock/skills` | Every question via ask-user tool (open-ended as candidate options + free text); pivot questions asked alone first; contradiction check + closing recap. |

Add a row here in the same commit as any local edit to an upstream skill.

Orca skills are not in the lock file: `orca skills install`/`update` stays unused (see README
§ Orca integration skills).
