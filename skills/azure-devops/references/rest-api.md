# Azure DevOps REST recipes

Endpoint shapes, payloads, and response schemas are plain Azure DevOps — portable to
any organisation. Only the concrete values below are environment-specific; set them
from the `<config>` block in SKILL.md.

Recipes are marked `[VERIFIED]` (executed against a live Azure DevOps organisation)
or `[DOCS-DERIVED]` (from Microsoft docs, not executed). Example ids, GUIDs, and repo
names in responses are real captures kept as evidence — substitute your own.

```bash
ORG="<organisation>"
PROJ="<Project%20Name>"       # spaces → %20 in the path
REPO="<repo-name>"
PROJID="<project-guid>"       # required by some endpoints, see A4
```

Auth is HTTP basic with an **empty username** and the PAT as password:
`curl -s -u ":$AZURE_DEVOPS_PAT" ...`

Base: `https://dev.azure.com/{org}/{project}/_apis/git/repositories/{repo}/...?api-version=7.1`
The repo segment accepts a name or a GUID; the project segment still needs encoding.

---

## 0. URLs → org / project / repo `[VERIFIED]`

```
https://<user>@dev.azure.com/<org>/<Project%20Name>/_git/<repo>
                             ^org  ^project           ^repo
```
PR web URL is the same prefix plus `/pullrequest/{id}`. `repository.webUrl` in API
responses matches the remote URL prefix exactly.

Resolve the project GUID once and prefer it — several endpoints require it:
```bash
curl -s -u ":$AZURE_DEVOPS_PAT" "https://dev.azure.com/$ORG/_apis/projects?api-version=7.1" \
  | jq -r '.value[] | "\(.id)  \(.name)"'
```

---

## A. Pull requests — read

### A1. List active PRs `[VERIFIED]`
```bash
curl -s -u ":$AZURE_DEVOPS_PAT" \
  "https://dev.azure.com/$ORG/$PROJ/_apis/git/repositories/$REPO/pullrequests?searchCriteria.status=active&api-version=7.1"
```
```json
{ "count": 1, "value": [ { "pullRequestId": 110274, "status": "active", "title": "..." } ] }
```
`searchCriteria.status`: `active` | `completed` | `abandoned` | `all`. `$top=N` pages.

### A2. Get one PR `[VERIFIED]`
```bash
curl -s -u ":$AZURE_DEVOPS_PAT" \
  "https://dev.azure.com/$ORG/$PROJ/_apis/git/repositories/$REPO/pullrequests/$PR?api-version=7.1"
```
```json
{ "pullRequestId": 110274, "status": "active", "title": "...",
  "sourceRefName": "refs/heads/task/ms6446-dry", "targetRefName": "refs/heads/master",
  "isDraft": false, "mergeStatus": "succeeded",
  "reviewers": [ { "displayName": "...", "vote": 0, "isRequired": true } ] }
```
`vote`: `10` approved · `5` approved w/ suggestions · `0` none · `-5` waiting for author · `-10` rejected.

### A3. Changed files `[VERIFIED]`
Two steps — iterations, then that iteration's changes.
```bash
curl -s -u ":$AZURE_DEVOPS_PAT" \
  "https://dev.azure.com/$ORG/$PROJ/_apis/git/repositories/$REPO/pullrequests/$PR/iterations?api-version=7.1"

curl -s -u ":$AZURE_DEVOPS_PAT" \
  "https://dev.azure.com/$ORG/$PROJ/_apis/git/repositories/$REPO/pullrequests/$PR/iterations/$LAST_IT/changes?api-version=7.1"
```
```json
{ "changeEntries": [ { "path": "/src/.../PaymentService.cs", "changeType": "edit" } ] }
```
`changeType: "delete"` entries can carry `path: null` — check `changeType` first.
For line-level diffs, use a local `git diff`; it is cheaper and clearer.

### A4. Policy evaluations and checks `[VERIFIED]`
Needs the **project GUID** in both the path and the `artifactId`, and `7.1-preview`:
```bash
curl -s -u ":$AZURE_DEVOPS_PAT" \
  "https://dev.azure.com/$ORG/$PROJID/_apis/policy/evaluations?artifactId=vstfs%3A%2F%2F%2FCodeReview%2FCodeReviewId%2F$PROJID%2F$PR&api-version=7.1-preview"
```
```json
[ { "configId": 1272, "type": "Minimum number of reviewers", "status": "queued" },
  { "configId": 1275, "type": "Build", "status": "approved" } ]
```
Plain `api-version=7.1` → HTTP 400 `VssInvalidPreviewVersionException`.

Bot/check statuses (e.g. code coverage) are a separate endpoint:
```bash
curl -s -u ":$AZURE_DEVOPS_PAT" \
  "https://dev.azure.com/$ORG/$PROJ/_apis/git/repositories/$REPO/pullrequests/$PR/statuses?api-version=7.1"
```

---

## B. Pull request comments

### B5. List threads `[VERIFIED]`
```bash
curl -s -u ":$AZURE_DEVOPS_PAT" \
  "https://dev.azure.com/$ORG/$PROJ/_apis/git/repositories/$REPO/pullrequests/$PR/threads?api-version=7.1"
```
Human thread:
```json
{ "id": 617735, "status": "active", "threadContext": null,
  "comments": [ { "id": 1, "parentCommentId": 0, "commentType": "text",
                  "author": { "displayName": "<name>" },
                  "content": "Behålla som standard? ..." } ] }
```
System thread:
```json
{ "id": 729681, "status": null,
  "comments": [ { "commentType": "system",
                  "author": { "displayName": "Microsoft.VisualStudio.Services.TFS" },
                  "content": "The reference refs/heads/... was updated." } ] }
```
- Human vs system: `comments[0].commentType` is `"text"` vs `"system"` — but NOT reliably:
  the diff-coverage bot posts `"text"`. Also filter on author. Service authors
  include `Microsoft.VisualStudio.Services.TFS`, `Azure Pipelines Test Service`.
- Thread `status`: `active` | `fixed` | `wontFix` | `closed` | `pending` | `unknown`.
  System threads commonly have `status: null` — do not filter on status alone.
- `threadContext` is `null` for general PR comments, populated for file/line comments
  with `filePath` and `rightFileStart`/`rightFileEnd` (or `leftFile*` for the old side).

### B6. New thread `[VERIFIED]`
```bash
curl -s -u ":$AZURE_DEVOPS_PAT" -X POST \
  "https://dev.azure.com/$ORG/$PROJ/_apis/git/repositories/$REPO/pullrequests/$PR/threads?api-version=7.1" \
  -H "Content-Type: application/json" \
  -d '{
    "comments": [ { "parentCommentId": 0, "content": "...", "commentType": "text" } ],
    "status": "active",
    "threadContext": {
      "filePath": "/src/File.cs",
      "rightFileStart": { "line": 2, "offset": 1 },
      "rightFileEnd":   { "line": 2, "offset": 6 }
    }
  }'
```
Omit `threadContext` entirely for a general PR-level comment.

### B7. Reply to a thread `[VERIFIED]`
Different sub-resource from thread creation. `parentCommentId` is the `id` of the
comment being answered — the opening comment is `id: 1`.
```bash
curl -s -u ":$AZURE_DEVOPS_PAT" -X POST \
  "https://dev.azure.com/$ORG/$PROJ/_apis/git/repositories/$REPO/pullrequests/$PR/threads/$THREAD/comments?api-version=7.1" \
  -H "Content-Type: application/json" \
  -d '{ "parentCommentId": 1, "content": "...", "commentType": "text" }'
```

### B8. Set thread status `[VERIFIED]` — this skill does not use it
PATCH the thread, not a comment:
```bash
curl -s -u ":$AZURE_DEVOPS_PAT" -X PATCH \
  "https://dev.azure.com/$ORG/$PROJ/_apis/git/repositories/$REPO/pullrequests/$PR/threads/$THREAD?api-version=7.1" \
  -H "Content-Type: application/json" -d '{"status": "fixed"}'
```
Documented for completeness only. Whether threads may be resolved is a policy toggle in SKILL.md `<config>` — off by default.

---

## C. Create a pull request

### C9. Create `[VERIFIED for base fields]`
```bash
curl -s -u ":$AZURE_DEVOPS_PAT" -X POST \
  "https://dev.azure.com/$ORG/$PROJ/_apis/git/repositories/$REPO/pullrequests?api-version=7.1" \
  -H "Content-Type: application/json" \
  -d '{ "sourceRefName": "refs/heads/<branch>", "targetRefName": "refs/heads/master",
        "title": "...", "description": "..." }'
```
`[DOCS-DERIVED]` extra fields: `"isDraft": true`, `"reviewers": [{"id": "<identity-guid>"}]`,
`"workItemRefs": [{"id": "12345"}]`. Reviewers need identity GUIDs, not emails.

`az repos pr create` takes `--reviewers`/`--required-reviewers` by email and
`--draft`/`--work-items` — simpler when reviewers are involved. `[DOCS-DERIVED]`

---

## D. Builds

### D10. Recent builds for a repo `[VERIFIED]`
```bash
curl -s -u ":$AZURE_DEVOPS_PAT" \
  "https://dev.azure.com/$ORG/$PROJ/_apis/build/builds?repositoryId=$REPOID&repositoryType=TfsGit&\$top=10&api-version=7.1"
```
```json
{ "value": [ { "id": 873400, "buildNumber": "20260701.1", "status": "completed",
               "result": "succeeded", "sourceBranch": "refs/pull/110274/merge" } ] }
```
`resultFilter=failed|succeeded|canceled|partiallySucceeded`. PR builds use
`refs/pull/{prId}/merge`. `az pipelines build list` has no repo filter — REST only.

### D11. One build `[VERIFIED]`
```bash
curl -s -u ":$AZURE_DEVOPS_PAT" \
  "https://dev.azure.com/$ORG/$PROJ/_apis/build/builds/$BUILD?api-version=7.1"
```
```json
{ "id": 890833, "status": "completed", "result": "failed",
  "definition": { "name": "<pipeline-name>" },
  "sourceBranch": "refs/pull/112534/merge", "reason": "pullRequest" }
```

### D12. Failure → error text `[VERIFIED]`
```bash
curl -s -u ":$AZURE_DEVOPS_PAT" \
  "https://dev.azure.com/$ORG/$PROJ/_apis/build/builds/$BUILD/timeline?api-version=7.1"
```
```json
{ "id": "bce25633-...", "name": "Docker", "type": "Task", "log": 8, "errorCount": 1,
  "issues": [ { "type": "error",
                "message": "The process '/usr/bin/docker' failed with exit code 1",
                "data": { "logFileLineNumber": "509" } } ] }
```
Then, only if the message is a wrapper, fetch that record's log (**plain text**):
```bash
curl -s -u ":$AZURE_DEVOPS_PAT" \
  "https://dev.azure.com/$ORG/$PROJ/_apis/build/builds/$BUILD/logs/8?api-version=7.1"
```
Real example: the Docker task error above was a symptom; the log line ~509 showed
`process "/bin/sh -c dotnet test ./MyWalley.sln --no-restore" did not complete successfully`
— a failing test suite, not a Docker problem.

### D13. Queue a build `[DOCS-DERIVED]`
```bash
curl -s -u ":$AZURE_DEVOPS_PAT" -X POST \
  "https://dev.azure.com/$ORG/$PROJ/_apis/build/builds?api-version=7.1" \
  -H "Content-Type: application/json" \
  -d '{ "definition": { "id": <definitionId> }, "sourceBranch": "refs/heads/<branch>" }'
```
CLI equivalent: `az pipelines run --id <definitionId> --branch <branch>`.

---

## PAT scopes and failure detection

Identity check `[VERIFIED]` (note `-preview`):
```bash
curl -s -u ":$AZURE_DEVOPS_PAT" \
  "https://dev.azure.com/$ORG/_apis/connectionData?api-version=7.1-preview" \
  | jq -r '.authenticatedUser.properties.Account."$value"'
```

Scopes `[DOCS-DERIVED]`: read PRs/threads/policy → `vso.code`; post comments, create PR
→ `vso.code_write`; read builds/timeline/logs → `vso.build`; queue builds →
`vso.build_execute`; `connectionData` → `vso.profile`.

**Invalid/expired PAT `[VERIFIED]`**: no 401. You get HTTP 302 to
`https://{tenant}.vssps.visualstudio.com/_signin?...`, or HTTP 203 with an HTML login
page when following redirects. Detect by `Content-Type` or a first non-whitespace byte
of `<`. Insufficient *scope* (as opposed to invalid) surfaces as HTTP 403 with
`TF400813: The user '<id>' is not authorized to access this resource.` `[DOCS-DERIVED]`

## Paging and limits

`$top`/`$skip` sufficed on every endpoint tested. Larger result sets may return an
`x-ms-continuationtoken` header — not observed here, do not assume its absence
generalises. Responses carry `X-RateLimit-Cost`; no throttling was hit.
