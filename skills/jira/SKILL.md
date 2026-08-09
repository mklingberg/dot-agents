---
name: jira
description: "Jira REST for Mina Sidor (MS): stories, subtasks, JQL search, transitions. Triggers: 'create Jira stories', 'MS-1234', 'move the ticket'."
---

<config>
Everything site- or team-specific lives here. Fork the skill, edit this block,
leave the rest alone.

| Setting | Value |
|---|---|
| Site | `https://norionbank.atlassian.net` |
| Auth | basic `$ATLASSIAN_USER` : `$ATLASSIAN_PAT` (keychain item `atlassian-token`) — both published at login |
| API | REST v3 — `$JIRA_SITE/rest/api/3`. **no Atlassian MCP**; the skill works in any harness |
| Project | `MS` — "Mina sidor", company-managed (classic), Scrum |
| Issue type ids | Epic `10000` · Story `10001` · Task `10002` · Sub-task `10003` · Bug `10004` · Sub-Bug `10100` |
| Teamy Team | `customfield_12035` (select): `Magica` \| `Merlin` — **required by convention on every issue** |
| Sprint | `customfield_10007` · Epic Link `customfield_10003` |
| Required on create | `project`, `issuetype`, `summary`, `reporter` |
| Story points | not on the MS Story screen — **do not send** |
| Reporter accountId | `$ATLASSIAN_ACCOUNT_ID` — resolve once per session, never stored: see `<auth>` in `references/rest-api.md` |
| Labels in use | `MyWalley`, `Risklevel-1`, `Risklevel-2`, `Frontend`, `Android` — no `Backend` label exists today |
| Risk level | `Risklevel-1` … `Risklevel-5` as a label, 5 = highest. Set by the PM at **Up next** |
| DoD source | Confluence *Definition Of Done (DOD)*, space `TM`, page `30867490` |
| Risk policy source | Confluence *Riskhantering*, space `Payments`, page `4242636856` |

```bash
: "${ATLASSIAN_USER:?not set — see <auth> in references/rest-api.md}"
JIRA_SITE="https://norionbank.atlassian.net"
AUTH="-u $ATLASSIAN_USER:$ATLASSIAN_PAT"
B="$JIRA_SITE/rest/api/3"
```

**Never echo, log, or paste the token; always reference `$ATLASSIAN_PAT`.** Where the env
var is empty — a fresh shell, or a subagent that never sourced the login publisher — read
the keychain by expansion, never into a literal (see `references/rest-api.md`).

The token is ~190 characters and contains shell-significant characters. Pasting the literal
into a command both leaks it and corrupts it, so **a 401/403 here means a malformed request,
not missing access** — fix the quoting before concluding anything about permissions. This
token is shared with Confluence; a delegated task reporting "user not permitted" on either
product has almost certainly mangled its own auth header.
</config>

<essential_principles>

<transport>
All Jira access goes through `curl` against REST v3. Read `references/rest-api.md`
before the first call in a session, and `references/adf.md` before writing any
description or comment — **rich text is ADF JSON, never markdown**.
</transport>

<story_format>
Every story follows this format:

```
As a <role>
I want <capability>
So that <business value>
```

Stories must have acceptance criteria. Subtasks must be technical, small (0.5–2 days), and belong to a parent story.
</story_format>

<approval_gate>
**NEVER create issues in Jira without explicit user approval.**

Always:
1. Draft the full plan (story + subtasks) as text
2. Present it to the user for review
3. Wait for approval
4. Only then POST to the API

Reads (`GET`, JQL search) need no approval. Writes — create, edit, comment,
transition — always do.
</approval_gate>

<subtask_rules>
Subtasks:
- Are technical directives (written so an agent or developer can execute them directly)
- Split by frontend / backend
- Do NOT repeat full story context — reference the parent
- Size: 0.5–2 days each
- Final subtask is always an **acceptance test** that verifies the parent story's criteria
- Use existing labels only. `Frontend` exists; **`Backend` does not** — ask before applying a label that isn't in `<config>`, and never invent one.
</subtask_rules>

<team_assignment>
All issues go to project **"Mina Sidor" (MS)**. Each issue must have a "Teamy Team" assigned — either **Magica** or **Merlin**. Ask the user which team if not obvious from context.
</team_assignment>

<issue_type_choice>
| Type | When to use |
|------|-------------|
| **Story** | User-facing feature or capability |
| **Sub-task** | Technical work item belonging to a story |
| **Bug** | Defect in existing functionality |
| **Task** | Technical work not tied to a user story |
</issue_type_choice>

<risk_level>
Every story carries a risk label `Risklevel-1` … `Risklevel-5`, where **5 is the
highest risk**. It is the PM's call, assigned when the story reaches *Up next* —
so when drafting a new story, **propose a level and say it's a proposal**, don't
assert one.

`Risklevel-3` or higher carries a hard rule from the DoD: before the story
deploys, the risk must be accepted per the risk-acceptance criteria and **the
decision documented as a comment on the story**. If you're transitioning a
≥3 story toward production and no such comment exists, say so — don't move it
quietly.

Subtasks don't get risk labels; the parent story does.

**Two scales exist — use the labels.** The org-level policy page *Riskhantering*
(Confluence space `Payments`, updated 2023-12-20) describes a **Critical–Info**
scale recorded in "riskfältet" in Jira, with acceptance required at *medium or
higher*, assessed at refinement as part of Definition of Ready. The team DoD
(space `TM`, updated 2025-03-04) implements that policy as the `Risklevel-1–5`
labels with the threshold at ≥3.

The labels are what MS issues actually carry, and the DoD is newer, so follow
the labels. If someone asks about "the risk field" or a Critical/High/Medium
rating, they mean the same policy under its older name — don't invent a Jira
field for it.
</risk_level>

<figma_integration>
If the user provides a Figma URL, file ID, or design reference:
1. Use Figma MCP to fetch design context / metadata
2. Include the Figma link in the story description under a **Links** section
3. Use design details to inform acceptance criteria and subtask breakdown
</figma_integration>

</essential_principles>

<routing>
Route on what the user actually said. **Only fall through to the menu when the
intent is genuinely ambiguous** — a skill that auto-triggers must not answer
"what's MS-6548 about?" with a menu.

| User intent | Workflow |
|---|---|
| Reads an issue, asks about a key, "what's in the sprint", "my tickets", any JQL-shaped question | `workflows/search-issues.md` |
| "Move to X", "comment on", "assign", "add a label", "set the team" | `workflows/update-issue.md` |
| "Create a story", "write tickets for", new work to break down | `workflows/create-story.md` |
| "Break down MS-1234", "add subtasks" | `workflows/add-subtasks.md` |
| "Refine", "this story is bad", "rewrite the AC" | `workflows/refine-story.md` |

Ambiguous only — ask:

> 1. Create a story with subtasks · 2. Add subtasks to an existing story ·
> 3. Refine an existing story · 4. Search / read · 5. Update a ticket

Missing team (Magica/Merlin) or a Figma link is **not** a reason to open with a
menu — ask for those inside the workflow, when they're actually needed.

**After reading the workflow, follow it exactly.**
</routing>

<reference_index>
In `references/`. Read on the trigger condition, not up front:

| Read this | When |
|---|---|
| `rest-api.md` | Before the first curl call in a session — auth, endpoints, JQL, pagination |
| `adf.md` | Before writing any description or comment — rich text is ADF JSON |
| `story-format.md` | Drafting or refining a story body |
| `subtask-patterns.md` | Breaking a story into FE/BE subtasks |
| `figma-integration.md` | The user supplied a Figma link or design reference |
</reference_index>

<workflows_index>
| Workflow | Purpose |
|----------|---------|
| search-issues.md | Read an issue or run a JQL search (no approval needed) |
| update-issue.md | Edit fields, comment, transition, assign |
| create-story.md | Plan and create a new story with subtasks |
| add-subtasks.md | Add subtasks to an existing story |
| refine-story.md | Improve or rewrite an existing story |
</workflows_index>
