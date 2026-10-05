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

**If no or unsure** → call the Skill tool with `code-review` now, scoped to all changed files
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

**Description** — call the Skill tool with `pr` and write the body to it (Summary, Evidence, Merge Danger),
then apply these Azure DevOps rules on top:

- **One line of why** above the Summary visual — the problem this solves, in reviewer
  terms. The work item has the detail.
- **Evidence you observed, nothing else.** Only test runs, output, or screenshots seen
  this session. No observed before? Write `Not verified` and name what would verify it.
- **Blast radius names who and how many** — consumers, customers, money, data — not a
  single word.
- **No Mermaid.** PR descriptions render it as a raw code block (tested). Use the text
  views: pseudocode, call tree, file tree, `diff`.
- **Under 4000 characters** — the description cap. One visual, not a gallery.
- **Screenshots** go in as attachments; they render inline.
- **Domain language**: call the Skill tool with `domain-knowledge`; there is no `GLOSSARY.md`.
- **One-way doors by default:** DB schema migrations, removing a LaunchDarkly flag or
  its fallback path, breaking a public API or message contract, and anything that
  leaves the building — customer emails, notifications, invoices, payments. Rolling back
  the commit doesn't unsend them.
- Append, when non-empty:
  ```markdown
  ## ⚠️ Known issues
  [blocking issues the operator chose to merge anyway, from Step 2]

  ## Related work items
  [#12345]
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

**Reviewers:** REST needs identity GUIDs, not emails, and resolving them requires a PAT
with **Identity/Graph read** scope. The configured PAT does not have it — verified:

```bash
curl -s -u ":$AZURE_DEVOPS_PAT" \
  "https://vssps.dev.azure.com/$ORG/_apis/identities?searchFilter=General&filterValue=<email>&api-version=7.1-preview.1"
# → HTTP 401 with the current PAT (scope missing, token itself is valid)
```

So, when reviewers are requested: **create the PR without them and say so plainly**, so
they can be added in the web UI in one click. Do not silently drop them, and do not
stall the PR over it.

To make this work properly, the operator must either add Identity read scope to the PAT
or connect the MCP server. Mention it once; don't nag.

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
