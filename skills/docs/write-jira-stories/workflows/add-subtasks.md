# Workflow: Add Subtasks to Existing Story

<required_reading>
**Read these reference files NOW:**
1. references/subtask-patterns.md
2. references/project-config.md
3. references/figma-integration.md (if Figma URL provided)
</required_reading>

<process>

## Step 1: Get the Parent Story

Ask the user for the story key (e.g., MS-123) if not provided.

Fetch the story:
- Call `getJiraIssue` with the story key
- Read the story description, acceptance criteria, and existing subtasks
- Note the team assignment

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

After approval:
1. Call `createJiraIssue` for each subtask with parent link to the story
2. Report created issue keys

</process>

<success_criteria>
- Parent story read and understood
- No duplicate subtasks created
- New subtasks fill gaps in coverage
- Subtasks are technical, prefixed, agent-executable
- User approved before creation
- All subtasks linked to parent story
</success_criteria>
