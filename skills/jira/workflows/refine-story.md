# Workflow: Refine an Existing Story

<required_reading>
**Read these reference files NOW:**
1. references/story-format.md
2. references/subtask-patterns.md
3. references/rest-api.md
</required_reading>

<process>

## Step 1: Get the Story

Ask the user for the story key (e.g., MS-1234) if not provided.

```bash
curl -s "${AUTH[@]}" "$B/issue/MS-1234?fields=summary,description,labels,subtasks,status,customfield_12035"
```
Flatten the ADF description for reading (see `references/adf.md`).

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

1. Update the story — `PUT $B/issue/MS-1234` with `{"fields": {...}}`, expect `204`
   and an empty body. **Rebuild the description as a fresh ADF document**; never
   flatten the existing one to text, edit the string, and write it back.
2. Create any new subtasks per `workflows/add-subtasks.md`.
3. Report what changed, with the browse URL.

</process>

<success_criteria>
- Story now follows all conventions from story-format.md
- Acceptance criteria are specific and testable
- Subtasks cover all acceptance criteria
- Acceptance test subtask exists
- User approved all changes before applying
</success_criteria>
