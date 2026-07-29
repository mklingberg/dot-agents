---
name: azure-devops
description: "Azure DevOps (org collectorbank) via REST+PAT: PRs, PR comment replies, builds. Triggers: 'open PR', 'PR comments', 'why did the build fail'."
---

<essential_principles>
### Comments are published under Marcus's name
Every thread reply, PR description, and comment posted through this skill appears
as him. Follow the "Writing in my name" and "Language" rules in global AGENTS.md:
senior-dev register, short, correct, no apologies unless he actually erred, and
**reply in the same language the comment was written in** (Swedish comment →
Swedish reply).

### Never write without explicit confirmation
Show the exact text and the exact target (PR id, thread id) and wait for approval
before any POST/PATCH. Reads need no confirmation.

### Never resolve threads
Do not PATCH thread status. Resolution is a social signal to the reviewer that the
point is settled — that call is Marcus's, not the agent's. Reply only.

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
curl -s -u ":$AZURE_DEVOPS_PAT" "https://dev.azure.com/collectorbank/..."
```

`AZURE_DEVOPS_PAT` is in the environment. `ORCA_AZURE_DEVOPS_TOKEN` holds the same
value. Never echo, log, or paste the token — always reference it as the variable.

Fallbacks, in order:
1. **`az` CLI** (installed, with the `azure-devops` extension) — use only where it is
   materially simpler. Known case: `az repos pr create` accepts reviewers by email,
   while REST needs identity GUIDs. Auth is inconsistent across subcommands, see gotchas.
2. **Azure DevOps MCP server** — only if REST is unavailable. It works, but its tool
   definitions cost context in every conversation.

### Verify auth before writing
An invalid or expired PAT does **not** return 401. It returns 302 → an HTML sign-in
page (or 203 with an HTML body). Any check based on status code alone will parse a
login page as data.

```bash
# valid JSON response starts with { or [ ; an HTML page starts with <
curl -s -u ":$AZURE_DEVOPS_PAT" \
  "https://dev.azure.com/collectorbank/_apis/projects?api-version=7.1" | head -c 1
```
If the first byte is `<`, tell the user the PAT is invalid or expired and stop.
Do not attempt to parse it as an API error.

Before posting anything, confirm whose identity is being used:
```bash
curl -s -u ":$AZURE_DEVOPS_PAT" \
  "https://dev.azure.com/collectorbank/_apis/connectionData?api-version=7.1-preview" \
  | jq -r '.authenticatedUser.properties.Account."$value"'
```

### Deriving org / project / repo
```
https://<user>@dev.azure.com/collectorbank/Teamy%20McTeamface/_git/walley-autogiro-automatikk-api
                             ^org          ^project (%20-encoded)  ^repo
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
Verified against `collectorbank`. Add to this list whenever a call surprises you.

- **Invalid PAT returns 302/HTML, not 401.** Check the first byte of the body, not the status code.
- **`api-version=7.1` is not universal.** `policy/evaluations` and `connectionData` require
  `7.1-preview`; plain `7.1` gives HTTP 400 `VssInvalidPreviewVersionException`. The 400 body
  names the version to use — read it instead of guessing.
- **Three distinct comment endpoints.** New thread: `POST .../pullrequests/{id}/threads`.
  Reply: `POST .../pullrequests/{id}/threads/{threadId}/comments`. Status: `PATCH .../threads/{threadId}`.
  Posting a reply to `/threads` creates a new orphan thread instead of replying.
- **System threads look like human threads.** Discriminator is `comments[0].commentType == "system"`
  (or a service-account author like `Microsoft.VisualStudio.Services.TFS`). `status` is unreliable —
  system threads usually have `status: null`. Replying to a bot notice looks careless.
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
