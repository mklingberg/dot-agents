---
name: create-pr-devops
description: "Open a pull request in Azure DevOps from a feature branch. Runs review-code first. Triggers: 'open PR', 'create PR', 'ready to merge'."
---

<objective>
Take the current feature branch from review to an open Azure DevOps pull request.
Never skip the review gate — it protects the team. Never create the PR without
explicit user confirmation of title, description, and target branch.
</objective>

<essential_principles>
### Review gate is mandatory
Always run (or confirm) a review before creating the PR. If the user says "skip
review", acknowledge it but still ask once — "Are you sure? Blocking issues
won't be caught." Proceed only after explicit confirmation.

### Confirm before submitting
Always show the full PR payload (title, description, source → target, reviewers,
work items, draft flag) and wait for "looks good" before calling MCP.

### Keep git commands read-only
Never commit, push, or amend. Only read git state (log, diff, branch, status).
</essential_principles>

<process>
## Step 1 — Read git context

Run these commands to understand the branch:

```bash
git branch --show-current                        # current (source) branch
git log --oneline origin/HEAD..HEAD              # commits not yet in target
git diff --stat origin/HEAD..HEAD                # changed files summary
```

If the remote default branch is unclear, check:
```bash
git remote show origin | grep "HEAD branch"
```

Store: source branch name, target branch (default: `main` or `master`), commit list, changed file count.

## Step 2 — Review gate

Ask the user:
> "Has this branch already been reviewed (via the review-code skill)?"

**If no / unsure:**
→ Load and invoke the `review-code` skill now. Pass context:
  - Scope: all changed files vs target branch
  - Mode: suggest-only (this is existing/human code)
  - Focus: blocking issues only (the user is about to ship)

After review:
- If **blocking issues found** → present them. Ask: "Fix blocking issues first, or proceed anyway?"
  - "Fix first" → stop, let user fix, re-invoke skill when ready
  - "Proceed anyway" → note the issues in the PR description under a `⚠️ Known issues` section
- If **no blocking issues** → continue

**If yes (already reviewed):**
→ Ask: "Any blocking issues found?" If yes, same gate as above.

## Step 3 — Draft PR metadata

Generate a draft using git context:

**Title:** derive from branch name using the project convention `{type}/{TicketNo}_{short-description}`
  - Strip the type prefix (`feature/`, `task/`, `bug/`)
  - Split on `_`: ticket number becomes `[TicketNo]` suffix, description becomes title
  - Convert kebab-case description to Title Case, max ~72 chars
  - Example: `feature/MS6375_account-cancellation` → `Account cancellation [MS6375]`

**Description template:**
```markdown
## Summary
[1–3 sentence description of what this PR does — infer from commits]

## Changes
[bullet list of changed files/areas from git diff --stat]

## Testing
- [ ] Unit tests pass
- [ ] Manual testing done

## Related work items
[leave blank if none; fill from user input in Step 4]
```

**Target branch:** default to `main` (or detected default). Ask user to confirm.

## Step 4 — Confirm PR details

Present the full payload for user confirmation:

```
📋 PR Preview
─────────────────────────────────────────
Title:       [title]
Source:      refs/heads/[current-branch]
Target:      refs/heads/[target-branch]
Draft:       No
Reviewers:   (none — add?)
Work items:  (none — add?)

Description:
[rendered description]
─────────────────────────────────────────
Proceed? (yes / edit title / edit description / add reviewers / add work items / make draft)
```

Handle each edit inline before proceeding. Collect:
- Reviewer emails or IDs (optional)
- Work item IDs to link (optional)
- Draft flag (default: false)

## Step 5 — Create PR via MCP

Call `azure_devops_create_pull_request` with confirmed values:

```
repositoryId:   [repo name — get from git remote URL or ask]
title:          [confirmed title]
description:    [confirmed description]
sourceRefName:  refs/heads/[source-branch]
targetRefName:  refs/heads/[target-branch]
reviewers:      [array of emails/IDs, if any]
workItemRefs:   [array of IDs, if any]
isDraft:        [true/false]
```

To derive `repositoryId` from the remote URL:
```bash
git remote get-url origin
# e.g. https://dev.azure.com/org/project/_git/my-repo → repositoryId = "my-repo"
```

If `projectId` or `organizationId` are non-default, ask the user.

## Step 6 — Report result

On success, output:
```
✅ PR created: [PR title]
🔗 [PR URL from response]
ID: [PR ID]
```

On failure, show the error and suggest fixes (wrong repo name, missing permissions, branch not pushed).
</process>

<success_criteria>
- [ ] git context read (source branch, commits, diff stat)
- [ ] Review run or confirmed already done
- [ ] Blocking issues addressed (fixed or explicitly acknowledged)
- [ ] PR title, description, and target branch confirmed by user
- [ ] `azure_devops_create_pull_request` called with confirmed payload
- [ ] PR URL returned to user
</success_criteria>
