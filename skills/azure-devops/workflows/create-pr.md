# Workflow — Create a pull request

Read `references/rest-api.md` section C9 before creating.

<objective>
Take the current feature branch from review to an open Azure DevOps pull request.
Never skip the review gate. Never create the PR without explicit confirmation of
title, description, and target branch.
</objective>

## Step 1 — Read git context

```bash
git branch --show-current                        # source branch
git log --oneline origin/HEAD..HEAD              # commits not yet in target
git diff --stat origin/HEAD..HEAD                # changed files
git remote show origin | grep "HEAD branch"      # target, if unclear
```

Confirm the branch is pushed. An unpushed source branch makes the create call fail
with a confusing error.

## Step 2 — Review gate

Ask: "Has this branch already been reviewed?"

**If no or unsure** → invoke the `code-review` skill now, scoped to all changed files
vs. the target branch, focused on blocking issues.

- Blocking issues found → present them, ask "fix first, or proceed anyway?"
  - fix first → stop
  - proceed anyway → record them in the PR description under `⚠️ Known issues`
- No blocking issues → continue

**If yes** → ask whether anything blocking was found, same gate.

## Step 3 — Draft PR metadata

**Title** — derive from the branch name using the `Branch convention` and
`PR title format` in the SKILL.md `<config>` block: strip the type prefix, split on
`_`, the ticket becomes a suffix, kebab-case becomes Title Case, max ~72 chars.
Example: `feature/MS6375_account-cancellation` → `Account cancellation [MS6375]`

**Description:**
```markdown
## Summary
[1–3 sentences, inferred from commits]

## Changes
[bullets from git diff --stat]

## Testing
- [ ] Unit tests pass
- [ ] Manual testing done

## Related work items
[blank if none]
```

Published under the operator's name — apply the persona rules in SKILL.md. No filler, no
self-congratulation, no apologising for the diff size.

## Step 4 — Confirm

```
📋 PR Preview
─────────────────────────────────────────
Title:       [title]
Source:      refs/heads/[source]
Target:      refs/heads/[target]
Draft:       No
Reviewers:   (none — add?)
Work items:  (none — add?)

Description:
[rendered]
─────────────────────────────────────────
Proceed? (yes / edit title / edit description / add reviewers / add work items / make draft)
```

Handle edits inline. Do not proceed on silence.

## Step 5 — Create

```bash
curl -s -u ":$AZURE_DEVOPS_PAT" -X POST \
  "https://dev.azure.com/$ORG/$PROJ/_apis/git/repositories/$REPO/pullrequests?api-version=7.1" \
  -H "Content-Type: application/json" \
  -d '{
    "sourceRefName": "refs/heads/<source>",
    "targetRefName": "refs/heads/<target>",
    "title": "...",
    "description": "...",
    "isDraft": false
  }'
```

**Reviewers:** REST needs identity GUIDs, not emails. Resolve them first — stay on REST
rather than dropping to the CLI, which may demand an interactive login an agent cannot
complete:

```bash
# email/alias → identity GUID  [UNVERIFIED — confirm on first use, then update this]
curl -s -u ":$AZURE_DEVOPS_PAT" \
  "https://vssps.dev.azure.com/$ORG/_apis/identities?searchFilter=General&filterValue=alice@example.com&api-version=7.1-preview.1" \
  | jq -r '.value[] | "\(.id)  \(.providerDisplayName)"'
```

Then add to the create body: `"reviewers": [{"id": "<guid>"}]`.

If identity lookup fails, do **not** silently drop the reviewers. Either create the PR
without them and say so plainly, so they can be added in the web UI, or use the MCP
server if connected. `az repos pr create --reviewers <email>` resolves emails itself and
is the documented escape hatch, but its auth behaviour is unreliable — see SKILL.md.

**Work items:** `"workItemRefs": [{"id": "12345"}]` in the REST body.

## Step 6 — Report

```
✅ PR created: [title]
🔗 https://dev.azure.com/{org}/{project}/_git/{repo}/pullrequest/{id}
ID: [pullRequestId]
```

On failure, show the response body. Common causes: source branch not pushed, wrong
repo name, PAT missing `vso.code_write`.

<success_criteria>
- [ ] git context read, source branch confirmed pushed
- [ ] Review run or confirmed, blocking issues resolved or recorded
- [ ] Title, description, target confirmed by the operator
- [ ] PR created with the confirmed payload
- [ ] PR URL reported
</success_criteria>
