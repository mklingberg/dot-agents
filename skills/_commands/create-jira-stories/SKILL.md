---
name: create-jira-stories
description: Plan and create Jira stories + FE/BE subtasks for Mina Sidor (Scrum, Figma). Triggers: 'create Jira stories', 'write tickets for Mina Sidor'.
disable-model-invocation: true
---

<essential_principles>

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
4. Only then use Atlassian MCP to create issues
</approval_gate>

<subtask_rules>
Subtasks:
- Are technical directives (written so an agent or developer can execute them directly)
- Split by frontend / backend
- Do NOT repeat full story context — reference the parent
- Size: 0.5–2 days each
- Final subtask is always an **acceptance test** that verifies the parent story's criteria
- Use existing labels to indicate type Backend, Frontend, etc. Do not create new labels without confirming with user.
</subtask_rules>

<team_assignment>
All issues go to project **"Mina Sidor" (MS)**. Each issue must have a "Teamy Team" assigned — either **Magica** or **Merlin**. Ask the user which team if not obvious from context.
</team_assignment>

<figma_integration>
If the user provides a Figma URL, file ID, or design reference:
1. Use Figma MCP to fetch design context / metadata
2. Include the Figma link in the story description under a **Links** section
3. Use design details to inform acceptance criteria and subtask breakdown
</figma_integration>

</essential_principles>

<intake>
What would you like to do?

1. **Create a new story** with subtasks
2. **Add subtasks** to an existing story
3. **Refine** an existing story

Also tell me:
- Which team? (Magica or Merlin)
- Any Figma designs to reference?

**Wait for response before proceeding.**
</intake>

<routing>
| Response | Workflow |
|----------|----------|
| 1, "new", "create", "story", "build" | `workflows/create-story.md` |
| 2, "subtask", "add", "break down" | `workflows/add-subtasks.md` |
| 3, "refine", "improve", "rewrite", "update" | `workflows/refine-story.md` |

**After reading the workflow, follow it exactly.**
</routing>

<reference_index>
All domain knowledge in `references/`:

**Story writing:** story-format.md
**Subtask patterns:** subtask-patterns.md
**Project config:** project-config.md
**Figma integration:** figma-integration.md
</reference_index>

<workflows_index>
| Workflow | Purpose |
|----------|---------|
| create-story.md | Plan and create a new story with subtasks |
| add-subtasks.md | Add subtasks to an existing story |
| refine-story.md | Improve or rewrite an existing story |
</workflows_index>
