---
name: azure-devops
description: "Azure DevOps via REST+PAT: PRs, PR comment replies, builds. Triggers: 'open PR', 'PR comments', 'why did the build fail'."
---

<config>
Everything team- or machine-specific lives here. Fork the skill, edit this block,
leave the rest alone.

| Setting | Value |
|---|---|
| Organisation | `collectorbank` |
| Default project | `Teamy McTeamface` — encode as `Teamy%20McTeamface` in URLs; GUID `2cca68fc-4c5c-42c2-bb57-2a45f031ea75` |
| PAT env var | `AZURE_DEVOPS_PAT` (`ORCA_AZURE_DEVOPS_TOKEN` holds the same value) |
| Branch convention | `{type}/{TicketNo}_{short-description}`, type ∈ `feature` \| `task` \| `bug` |
| PR title format | `Short description [TicketNo]` |
| Resolve threads after replying | **no** |
| Make code changes from a comment reply | **no** |

Shell variables used throughout this skill and its references:
```bash
ORG="collectorbank"
PROJ="Teamy%20McTeamface"
REPO="<repo-name>"          # from git remote
```
</config>

<essential_principles>
### Comments are published under the operator's name
Every thread reply, PR description, and comment posted through this skill appears as
the person whose PAT is in use — not as an AI. If the operator's global agent
instructions define a writing persona, follow it. Otherwise, default to: senior-dev
register, short, correct, concrete, no apologies unless something was actually broken,
no filler praise.

Always **reply in the same language the comment was written in** (Swedish comment →
Swedish reply), regardless of the language used when talking to the operator.

### Never write without explicit confirmation
Show the exact text and the exact target (PR id, thread id) and wait for approval
before any POST/PATCH. Reads need no confirmation.

### Never resolve threads
Do not PATCH thread status while `Resolve threads after replying` is **no**.
Resolution is a social signal to the reviewer that the point is settled — that call
belongs to the operator, not the agent. Reply only.

### Reply, don't fix
When a comment asks for a code change, report what the reviewer wants and stop.
Making the change is a separate, explicitly-given instruction. Pushing commits to
a branch that someone is mid-review on is worse than answering slowly.
</essential_principles>

<integration>
## How to talk to Azure DevOps

**Default: raw REST with a PAT.** Works in every harness (pi, Claude Code, Copilot),
costs no tool-definition context, and behaves identically everywhere.

```bash
curl -s -u ":$AZURE_DEVOPS_PAT" "https://dev.azure.com/$ORG/..."
```

The PAT env var is named in `<config>`. Never echo, log, or paste the token — always
reference it as the variable.

Fallbacks, in order:
1. **Azure DevOps MCP server** — when REST is unavailable or blocked. Non-interactive
   and consistent. Its tool definitions cost context in every conversation whether or
   not they are called, so REST stays the default — but if the server is connected,
   that cost is already paid.
2. **`az` CLI** (with the `azure-devops` extension) — last resort. Auth is inconsistent
   across subcommands: `az repos pr policy list` ignores `AZURE_DEVOPS_EXT_PAT` and
   demands an interactive `az devops login`, which an agent cannot complete. Use only
   for a call verified to work non-interactively, and never in an unattended run.

### Verify auth before writing
An invalid or expired PAT does **not** return 401. It returns 302 → an HTML sign-in
page (or 203 with an HTML body). Any check based on status code alone will parse a
login page as data.

```bash
# valid JSON response starts with { or [ ; an HTML page starts with <
curl -s -u ":$AZURE_DEVOPS_PAT" \
  "https://dev.azure.com/$ORG/_apis/projects?api-version=7.1" | head -c 1
```
If the first byte is `<`, tell the user the PAT is invalid or expired and stop.
Do not attempt to parse it as an API error.

Before posting anything, confirm whose identity is being used:
```bash
curl -s -u ":$AZURE_DEVOPS_PAT" \
  "https://dev.azure.com/$ORG/_apis/connectionData?api-version=7.1-preview" \
  | jq -r '.authenticatedUser.properties.Account."$value"'
```

### Deriving org / project / repo
```
https://<user>@dev.azure.com/<org>/<project%20encoded>/_git/<repo>
```
Get it from `git remote get-url origin`, or from a PR web URL, which adds
`/pullrequest/{id}`. Project names contain spaces — keep them `%20`-encoded in the
URL path. Resolving the project GUID once via `/_apis/projects` avoids the encoding
question entirely and is required by some endpoints anyway.

Base pattern:
```
https://dev.azure.com/{org}/{project}/_apis/git/repositories/{repo}/...?api-version=7.1
```
</integration>

<routing>
## Workflows

Route on what the user asked for — do not ask a menu question.

| User intent | Read |
|---|---|
| "open a PR", "create PR", "ready to merge" | `workflows/create-pr.md` |
| "answer the PR comments", "what did reviewers say", "respond to feedback" | `workflows/respond-to-pr-comments.md` |
| "why did the build fail", "check the pipeline", "build is red" | `workflows/investigate-build-failure.md` |
| Anything else (list PRs, check policy status, read a diff) | `references/rest-api.md` |

`references/rest-api.md` holds verified curl recipes for every operation. Read it
when a workflow needs an endpoint, or when the task is a one-off read that no
workflow covers. Do not reconstruct endpoints from memory — they are easy to get
subtly wrong and the failures are silent.
</routing>

<gotchas>
Verified live against Azure DevOps (see `references/rest-api.md` for the evidence).
Add to this list whenever a call surprises you.

- **Invalid PAT returns 302/HTML, not 401.** Check the first byte of the body, not the status code.
- **`api-version=7.1` is not universal.** `policy/evaluations` and `connectionData` require
  `7.1-preview`; plain `7.1` gives HTTP 400 `VssInvalidPreviewVersionException`. The 400 body
  names the version to use — read it instead of guessing.
- **Three distinct comment endpoints.** New thread: `POST .../pullrequests/{id}/threads`.
  Reply: `POST .../pullrequests/{id}/threads/{threadId}/comments`. Status: `PATCH .../threads/{threadId}`.
  Posting a reply to `/threads` creates a new orphan thread instead of replying.
- **System threads look like human threads — and some bots don't even set `commentType`.**
  Filter on `comments[0].commentType == "system"` **and** on service-account authors
  (`Microsoft.VisualStudio.Services.TFS`, `Azure Pipelines Test Service`, team-group names).
  Verified: the diff-coverage bot posts with `commentType: "text"`, so the commentType
  check alone lets it through. `status` is unreliable too — system threads often have
  `status: null`. Replying to a bot is public and embarrassing.
- **Policy evaluations need the project GUID twice** — in the path *and* inside the
  `artifactId` param (`vstfs:///CodeReview/CodeReviewId/{projectGuid}/{prId}`), never the name.
- **Build logs are plain text, not JSON.** Do not pipe them to `jq`.
- **Timeline `issues[].message` already contains the error** — fetch full logs only for context.
- **`changeType: "delete"` entries can have `path: null`** in iteration changes. Check `changeType` first.
- **`az repos pr policy list` ignores `AZURE_DEVOPS_EXT_PAT`** and demands `az devops login`,
  while `az repos pr show`/`pr list` honour it. Test each subcommand; don't assume uniform auth.
- **`az pipelines build list` has no repo filter** — only `--definition-ids`/`--branch`. If you know
  the repo but not the pipeline definition, REST's `repositoryId` filter is the only way.
- **`Content-Type: application/json` is required** on every POST/PATCH body.
</gotchas>

<success_criteria>
- Correct integration path chosen (REST first), PAT validity checked before any write
- No POST/PATCH issued without the user seeing the exact text and target first
- No thread resolved
- Replies match the language of the comment they answer
- Endpoints taken from `references/rest-api.md`, not from memory
</success_criteria>
