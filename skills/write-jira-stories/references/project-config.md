<overview>
Project-specific configuration for the Mina Sidor (MS) Jira project.
</overview>

<project>
**Project name:** Mina Sidor
**Project key:** MS
**Methodology:** Scrum
</project>

<teams>
All issues must have a "Teamy Team" assigned. Two teams available:

| Team | Description |
|------|-------------|
| **Magica** | Team Magica |
| **Merlin** | Team Merlin |

If the user doesn't specify a team, **ask before creating issues**.
</teams>

<issue_types>
| Type | When to use |
|------|-------------|
| **Story** | User-facing feature or capability |
| **Sub-task** | Technical work item belonging to a story |
| **Bug** | Defect in existing functionality |
| **Task** | Technical work not tied to a user story |
</issue_types>

<jira_mcp_usage>
Use the Atlassian MCP tools to interact with Jira:

**Finding project info:**
- `getVisibleJiraProjects` — list projects
- `getJiraProjectIssueTypesMetadata` — get issue types for MS project
- `getJiraIssueTypeMetaWithFields` — get required fields for an issue type

**Creating issues:**
- `createJiraIssue` — create story or subtask
- `createIssueLink` — link related issues

**Reading issues:**
- `getJiraIssue` — get issue details
- `searchJiraIssuesUsingJql` — search with JQL

**Updating issues:**
- `editJiraIssue` — update fields
- `addCommentToJiraIssue` — add comments

**Always** get issue type metadata before creating issues to ensure required fields are provided.
</jira_mcp_usage>
