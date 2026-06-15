<overview>
How to integrate Figma designs into Jira stories using the Figma MCP server.
</overview>

<when_to_use>
Use Figma integration when the user provides:
- A Figma URL (figma.com/design/..., figma.com/board/...)
- A Figma file ID
- A reference to a design ("the login design", "checkout mockup")
</when_to_use>

<url_parsing>
Extract fileKey and nodeId from Figma URLs:
- `figma.com/design/:fileKey/:fileName?node-id=:nodeId` → convert "-" to ":" in nodeId
- `figma.com/design/:fileKey/branch/:branchKey/:fileName` → use branchKey as fileKey
- `figma.com/board/:fileKey/:fileName` → FigJam file, use `get_figjam`
</url_parsing>

<workflow>
1. **Fetch design context:**
   - Call `mcp__figma__get_design_context` with fileKey and nodeId
   - This returns code hints, screenshot, and contextual info

2. **Extract useful info for the story:**
   - Component names and structure → informs subtask breakdown
   - Design tokens / colors → reference in frontend subtasks
   - Layout and interactions → inform acceptance criteria
   - Annotations from designers → capture as notes or constraints

3. **Include in story description:**
   ```markdown
   ## Design
   [Brief description of the design]

   ## Links
   - Figma: https://figma.com/design/...
   ```

4. **Inform subtask breakdown:**
   - Each distinct UI component or section can become a frontend subtask
   - Design states (loading, error, empty) should be covered in subtasks
   - Responsive behavior noted in design → acceptance criteria
</workflow>

<figma_mcp_tools>
| Tool | Purpose |
|------|---------|
| `get_design_context` | Primary tool — returns code, screenshot, hints |
| `get_screenshot` | Get a visual snapshot of a node |
| `get_metadata` | Get file/node metadata |
| `get_figjam` | Read FigJam boards |
| `search_design_system` | Find design system components |
</figma_mcp_tools>
