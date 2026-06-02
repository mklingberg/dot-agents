# Workflow: Refine an Existing Story

<required_reading>
**Read these reference files NOW:**
1. references/story-format.md
2. references/subtask-patterns.md
3. references/project-config.md
</required_reading>

<process>

## Step 1: Get the Story

Ask the user for the story key (e.g., MS-123) if not provided.

Fetch the story:
- Call `getJiraIssue` with the story key
- Read all fields: summary, description, acceptance criteria, subtasks

## Step 2: Identify Issues

Check the story against `references/story-format.md`:

- Does it follow "As a / I want / So that"?
- Are acceptance criteria specific and testable?
- Is the description structured (Background, AC, Design, Links, Notes)?
- Is the story appropriately sized (not too large)?
- Is a team assigned?

Check subtasks against `references/subtask-patterns.md`:
- Are subtasks technical and prefixed?
- Are they sized at 0.5–2 days?
- Is there an acceptance test subtask?
- Do subtasks cover all acceptance criteria?

## Step 3: Draft Improvements

Present a before/after comparison:

```
📋 Refining [STORY-KEY]: [Story title]

Issues found:
- [issue 1]
- [issue 2]

Proposed changes:
- Summary: [old] → [new]
- Description: [what changes]
- Subtasks to add/modify: [list]
```

**Ask: "Want me to apply these changes?"**

**DO NOT proceed until the user approves.**

## Step 4: Apply Changes in Jira

After approval:
1. Call `editJiraIssue` to update story fields
2. Call `createJiraIssue` for any new subtasks
3. Report all changes made

</process>

<success_criteria>
- Story now follows all conventions from story-format.md
- Acceptance criteria are specific and testable
- Subtasks cover all acceptance criteria
- Acceptance test subtask exists
- User approved all changes before applying
</success_criteria>
