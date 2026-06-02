<overview>
Patterns for breaking stories into technical subtasks. Subtasks are agent-executable directives — small, technical, and scoped to one concern.
</overview>

<subtask_format>
Each subtask title should read as a **directive** — an instruction an agent or developer can act on immediately:

**Good titles (directives):**
- `[BE] Add GET /api/orders endpoint returning paginated order list`
- `[FE] Create OrderList component with loading and empty states`
- `[FE] Connect OrderList to GET /api/orders with error handling`
- `[BE] Add unit tests for OrderService.GetOrders`
- `[TEST] Verify order list displays correctly per AC in MS-123`

**Bad titles:**
- `Backend work` (too vague)
- `Implement the order feature` (too broad, repeats story)
- `Fix stuff` (not a directive)
</subtask_format>

<prefix_convention>
Prefix subtasks to indicate their domain:

| Prefix | Meaning |
|--------|---------|
| `[BE]` | Backend / API / C# |
| `[FE]` | Frontend / React / UI |
| `[TEST]` | Acceptance test / E2E verification |
| `[INFRA]` | Infrastructure / config / deployment |
| `[DATA]` | Database migration / data changes |

**Labels:** Use existing Jira labels (e.g., Backend, Frontend) to tag subtasks by type. Do **not** create new labels without user confirmation.
</prefix_convention>

<breakdown_pattern>
Standard breakdown for a typical feature story:

1. **`[DATA]`** — Database/model changes (if needed)
2. **`[BE]`** — API endpoint or service logic
3. **`[BE]`** — Backend unit/integration tests
4. **`[FE]`** — UI component(s)
5. **`[FE]`** — Connect UI to API, handle states (loading/error/empty)
6. **`[FE]`** — Frontend tests (if applicable)
7. **`[TEST]`** — Acceptance test verifying parent story's criteria

The acceptance test subtask is always last and references the parent story's acceptance criteria directly.
</breakdown_pattern>

<agent_directive_style>
Write subtask descriptions as if briefing an agent. Include:

- **What to do** — The specific technical action
- **Where** — File paths or areas of codebase (if known)
- **Constraints** — Size limits, patterns to follow, things to avoid
- **Done when** — How to verify this subtask is complete

**Example subtask description:**
```
Add a GET endpoint at /api/v1/orders that returns a paginated list of orders
for the authenticated user.

- Use OrderService to fetch data
- Return PagedResult<OrderDto>
- Include filtering by status (query param)
- Follow existing endpoint patterns in OrdersController

Done when: Endpoint returns 200 with correct data, 401 if unauthenticated.
```
</agent_directive_style>

<acceptance_test_subtask>
The final subtask verifies the parent story. Format:

**Title:** `[TEST] Verify <story summary> per AC in <story key>`

**Description:**
```
Verify the parent story's acceptance criteria:

- [ ] AC1 from parent story
- [ ] AC2 from parent story
- [ ] AC3 from parent story

Test in [environment]. Report any failures as comments on the parent story.
```

This subtask does NOT add new criteria — it verifies what the story already defines.
</acceptance_test_subtask>

<sizing>
Each subtask: **0.5–2 days** of work.

If a subtask feels larger than 2 days:
- Split it further (e.g., separate component creation from API integration)
- Check if it's actually two distinct tasks

If a subtask feels smaller than half a day:
- Consider merging with a related subtask
- Unless it's a distinct concern worth tracking separately
</sizing>

<anti_patterns>
<anti_pattern name="Repeating story context">
**Bad:** Subtask description copies the entire story background.
**Instead:** Reference the parent: "See parent story MS-123 for context."
</anti_pattern>

<anti_pattern name="Non-technical subtasks">
**Bad:** "Discuss design with team"
**Instead:** Subtasks are implementation work. Discussions happen outside Jira.
</anti_pattern>

<anti_pattern name="One giant subtask">
**Bad:** "[FE] Implement entire order page"
**Instead:** Split into component creation, API connection, state handling, etc.
</anti_pattern>
</anti_patterns>
