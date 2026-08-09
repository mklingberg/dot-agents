# Workflow: Add Subtasks to Existing Story

<required_reading>
**Read these reference files NOW:**
1. references/subtask-patterns.md
2. references/rest-api.md
3. references/figma-integration.md (if Figma URL provided)
</required_reading>

<process>

## Step 1: Get the Parent Story

Ask the user for the story key (e.g., MS-1234) if not provided.

```bash
curl -s $AUTH "$B/issue/MS-1234?fields=summary,description,labels,subtasks,customfield_12035"
```
Flatten the ADF description (see `references/adf.md`) before reading it. Note the
existing subtasks and the Teamy Team value — new subtasks inherit both.

## Step 2: Analyze What's Missing

Compare the story's acceptance criteria against existing subtasks:
- Which criteria have subtasks covering them?
- Which criteria are uncovered?
- Is there an acceptance test subtask?

If Figma URL provided, fetch design context to identify additional UI work.

## Step 3: Plan New Subtasks

Draft subtasks following `references/subtask-patterns.md`:
- Only create subtasks for uncovered work
- Use directive-style titles with prefixes
- Size each at 0.5–2 days
- Add acceptance test subtask if missing

## Step 4: Present Plan for Approval

```
📋 Adding subtasks to [STORY-KEY]: [Story title]

Existing subtasks:
- [existing subtask 1]
- [existing subtask 2]

New subtasks to create:
1. [PREFIX] Title (estimate)
2. [PREFIX] Title (estimate)
```

**Ask: "Want me to create these subtasks?"**

**DO NOT proceed until the user approves.**

## Step 5: Create in Jira

After approval, one POST per subtask — issue type `10003`, parent by key:

```json
{"fields": {
  "project": {"key": "MS"},
  "issuetype": {"id": "10003"},
  "parent": {"key": "MS-1234"},
  "summary": "[FE] Render the invoice list",
  "description": { ...ADF... },
  "reporter": {"id": "$ATLASSIAN_ACCOUNT_ID"},
  "customfield_12035": {"value": "Magica"}
}}
```
```bash
curl -s $AUTH -X POST -H "Content-Type: application/json" --data @/tmp/sub1.json "$B/issue"
```

Create them one at a time and check each response. If one 400s, stop and fix
before continuing — don't leave a half-created set without telling the user.
Report every created key as a browse URL.

</process>

<success_criteria>
- Parent story read and understood
- No duplicate subtasks created
- New subtasks fill gaps in coverage
- Subtasks are technical, prefixed, agent-executable
- User approved before creation
- All subtasks linked to parent story
</success_criteria>
