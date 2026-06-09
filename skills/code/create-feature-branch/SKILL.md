---
name: create-feature-branch
description: Creates a git feature branch with the correct naming convention for this project. Use when starting work on a Jira ticket or when the user says "create a branch", "new branch", or "start working on [ticket]".
---

<objective>
Create a correctly named git feature branch for a Jira ticket and switch to it.
</objective>

<naming_convention>
```
{type}/{TicketNo}_{short-description-in-kebab-case}
```

| Jira issue type | Prefix    | Example                              |
|----------------|-----------|--------------------------------------|
| Story          | `feature` | `feature/MS6375_account-cancellation`|
| Task           | `task`    | `task/MS6408_update-npm-packages`    |
| Bug            | `bug`     | `bug/MS6421_fix-issue-signing`       |

Rules:
- Ticket number has **no dash**: `MS6421` not `MS-6421`
- Description is lowercase kebab-case, concise (2–5 words)
- Separator between ticket and description is `_` (underscore)
</naming_convention>

<process>
1. If branch type, ticket number, or description are not clear from context, ask the user before proceeding.
2. Confirm the branch is being created from `main` (or ask if a different base is intended).
3. Run:
```bash
git switch main && git pull
git switch -c {type}/{TicketNo}_{short-description}
```
4. Report the created branch name.
</process>

<success_criteria>
- Branch name matches the convention exactly
- User is on the new branch (`git branch --show-current`)
</success_criteria>
