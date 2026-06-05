# Workflow: Create Story with Subtasks

<required_reading>
**Read these reference files NOW:**
1. references/story-format.md
2. references/subtask-patterns.md
3. references/project-config.md
4. references/figma-integration.md (if Figma URL provided)
</required_reading>

<process>

## Step 1: Gather Requirements

Ask the user (skip questions already answered):
- What should the user be able to do? (the capability)
- Who is the user/role?
- Why does this matter? (business value)
- Which team — Magica or Merlin?
- Any Figma designs?
- Any known constraints or edge cases?

## Step 2: Fetch Figma Design (if applicable)

If a Figma URL was provided:
1. Parse the URL to extract fileKey and nodeId
2. Call `mcp__figma__get_design_context` to get design details
3. Note component structure, states, and interactions for subtask planning

## Step 3: Draft the Story

Write the story using the format from `references/story-format.md`:
- Title: concise summary of the capability
- Description with: Background, Acceptance Criteria, Design (if Figma), Links, Notes
- Assign to the correct team

## Step 4: Plan Subtasks

Break the story into subtasks following `references/subtask-patterns.md`:
1. Identify data/model changes needed → `[DATA]` subtasks
2. Identify backend work → `[BE]` subtasks
3. Identify frontend work → `[FE]` subtasks
4. Add acceptance test → `[TEST]` subtask (always last)

Each subtask must have:
- Prefixed title (directive style)
- Brief description (agent-executable)
- Estimated size (0.5–2 days)

## Step 5: Present Plan for Approval

Present the complete plan to the user:

```
📋 Story: [Title]
Team: [Magica/Merlin]

As a [role]
I want [capability]
So that [business value]

Acceptance Criteria:
- [ ] ...
- [ ] ...

Subtasks:
1. [PREFIX] Title (estimate)
2. [PREFIX] Title (estimate)
3. ...
N. [TEST] Acceptance test (estimate)
```

**Ask: "Does this look good? Want me to create it in Jira?"**

**DO NOT proceed until the user approves.**

## Step 6: Create in Jira

After approval:

1. Get project metadata:
   - Call `getJiraProjectIssueTypesMetadata` for MS project
   - Call `getJiraIssueTypeMetaWithFields` for Story type

2. Create the parent story:
   - Call `createJiraIssue` with all fields
   - Note the returned issue key (e.g., MS-456)

3. Create each subtask:
   - Call `createJiraIssue` for each subtask with parent link
   - Use the parent story key

4. Report results:
   - List all created issues with keys and links

</process>

<success_criteria>
- Story follows "As a / I want / So that" format
- Acceptance criteria are specific and testable
- Subtasks are technical, prefixed, and 0.5–2 days each
- Final subtask is acceptance test referencing parent story AC
- User approved before any Jira creation
- All issues created with correct team assignment
- Figma link included if design was provided
</success_criteria>
