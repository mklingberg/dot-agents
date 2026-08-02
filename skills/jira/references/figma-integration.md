<overview>
How to pull Figma design context into Jira stories.

The Figma tooling differs per harness — **list the available Figma tools before
assuming a name.** Two servers are common:

| Server | Tools | Notes |
|---|---|---|
| `figma-developer-mcp` | `get_figma_data`, `download_figma_images` | what's configured in pi today |
| Figma Dev Mode MCP | `get_design_context`, `get_screenshot`, `get_metadata`, `get_figjam`, `search_design_system` | official; desktop app must be running |

If no Figma tool is reachable, don't stall — put the link in the story and ask
the user to describe the states that matter.
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
   - Call the harness's Figma read tool with fileKey and nodeId
     (`get_figma_data`, or `get_design_context` on Dev Mode)
   - This returns node structure, and depending on the server, code hints and a screenshot

2. **Extract useful info for the story:**
   - Component names and structure → informs subtask breakdown
   - Design tokens / colors → reference in frontend subtasks
   - Layout and interactions → inform acceptance criteria
   - Annotations from designers → capture as notes or constraints

3. **Include in story description** — as ADF, not markdown (see `adf.md`):
   a `heading` "Design" with a short prose description, then a `heading` "Links"
   with the Figma URL as a `link` mark.

4. **Inform subtask breakdown:**
   - Each distinct UI component or section can become a frontend subtask
   - Design states (loading, error, empty) should be covered in subtasks
   - Responsive behavior noted in design → acceptance criteria
</workflow>

<figjam>
`figma.com/board/...` is a FigJam file. Dev Mode reads it with `get_figjam`;
`figma-developer-mcp` does not support FigJam — fall back to asking the user.
</figjam>
