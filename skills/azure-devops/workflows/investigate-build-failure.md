# Workflow — Investigate a build failure

Read `references/rest-api.md` section D before starting.

<objective>
Go from "the build is red" to the actual error text and a diagnosis, with the
minimum number of API calls. Read-only — never queue or cancel a build without
being told to.
</objective>

## Step 1 — Find the failed build

By repo (needs the repo GUID — resolve it once and reuse):

```bash
REPOID=$(curl -s -u ":$AZURE_DEVOPS_PAT" \
  "https://dev.azure.com/$ORG/$PROJ/_apis/git/repositories/$REPO?api-version=7.1" | jq -r .id)

curl -s -u ":$AZURE_DEVOPS_PAT" \
  "https://dev.azure.com/$ORG/$PROJ/_apis/build/builds?repositoryId=$REPOID&repositoryType=TfsGit&resultFilter=failed&\$top=5&api-version=7.1" \
  | jq '[.value[] | {id, buildNumber, result, sourceBranch, finishTime, definition: .definition.name}]'
```

PR builds appear under `sourceBranch: "refs/pull/{prId}/merge"` — that is how a build
is tied back to a pull request.

`az pipelines build list` cannot filter by repo, only by definition id or branch.
Use REST here.

## Step 2 — Get the error from the timeline

The timeline carries structured errors. This is usually enough — do not fetch logs first.

```bash
curl -s -u ":$AZURE_DEVOPS_PAT" \
  "https://dev.azure.com/$ORG/$PROJ/_apis/build/builds/$BUILD/timeline?api-version=7.1" \
  | jq '[.records[] | select(.result == "failed")
      | {name, type, log: .log.id, issues: [.issues[]? | {type, message, line: .data.logFileLineNumber}]}]'
```

## Step 3 — Fetch the log only if the message is a symptom

Task-level errors are often wrappers. `The process '/usr/bin/docker' failed with exit
code 1` tells you nothing; the real cause is inside the log. Use the failed record's
`log.id` and the `logFileLineNumber` hint:

```bash
curl -s -u ":$AZURE_DEVOPS_PAT" \
  "https://dev.azure.com/$ORG/$PROJ/_apis/build/builds/$BUILD/logs/$LOGID?api-version=7.1" \
  > /tmp/build-$BUILD-$LOGID.log

grep -n "##\[error\]" /tmp/build-$BUILD-$LOGID.log | head -20
sed -n "$((HINT-40)),$((HINT+5))p" /tmp/build-$BUILD-$LOGID.log
```

Logs are **plain text**. Do not pipe them to `jq`. They can be large — write to a file
and grep rather than reading the whole thing into context.

## Step 4 — Diagnose

Separate the reported failure from the root cause, and say which is which. A Docker
task failing because `dotnet test` failed inside it is a test failure, not a Docker
problem — report the failing test.

State: which pipeline, which stage/task, the root-cause error, and whether it looks
like a code failure, a flaky/infra failure, or a configuration problem. If the evidence
does not distinguish them, say so rather than picking one.

## Step 5 — Stop

Do not fix the code. Do not re-queue the build. Report and let the operator decide.

Re-queueing, if explicitly asked:
```bash
curl -s -u ":$AZURE_DEVOPS_PAT" -X POST \
  "https://dev.azure.com/$ORG/$PROJ/_apis/build/builds?api-version=7.1" \
  -H "Content-Type: application/json" \
  -d '{"definition": {"id": <definitionId>}, "sourceBranch": "refs/heads/<branch>"}'
```

<success_criteria>
- [ ] Failed build identified, with pipeline name and branch
- [ ] Timeline read before any log fetch
- [ ] Root cause distinguished from the surface error
- [ ] Logs handled as text and kept out of context where large
- [ ] Nothing fixed, queued, or cancelled without instruction
</success_criteria>
