<overview>
Story writing conventions for Scrum teams. Defines the story template, acceptance criteria format, and definition of done.
</overview>

<story_template>
```
As a <role>
I want <capability>
So that <business value>
```

**Role** — The person or system benefiting (e.g., "logged-in user", "admin", "payment service")
**Capability** — What they can do (specific, observable behavior)
**Business value** — Why it matters (ties to a business outcome, not a technical reason)
</story_template>

<acceptance_criteria>
Write acceptance criteria as testable statements using Given/When/Then or a checklist:

**Given/When/Then format:**
```
Given <precondition>
When <action>
Then <expected result>
```

**Checklist format:**
```
- [ ] User can see X when Y
- [ ] Error message shown if Z
- [ ] Data persists after reload
```

Each criterion must be:
- **Observable** — Can be verified by looking at the UI or checking data
- **Specific** — No ambiguity about what "works" means
- **Independent** — Each criterion testable on its own
</acceptance_criteria>

<story_description_structure>
A complete story description includes:

```markdown
## Background
Brief context — why this story exists. 1-2 sentences max.

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Design
[Figma link if available]
[Screenshot or description of expected UI]

## Links
- Figma: [url]
- Related stories: [MS-xxx]
- API docs: [url if relevant]

## Notes
Any edge cases, constraints, or decisions already made.
```
</story_description_structure>

<sizing_guidance>
Stories should be completable within a single sprint. If a story feels larger than 5-8 days of work, split it into multiple stories.

Indicators a story is too big:
- More than 6-8 subtasks
- Touches more than 3 distinct system areas
- Has "and" in the capability ("I want X **and** Y")
- Acceptance criteria span multiple user flows
</sizing_guidance>

<anti_patterns>
<anti_pattern name="Technical story">
**Bad:** "As a developer, I want to refactor the auth module"
**Why:** No business value. Refactoring is a subtask or tech debt ticket, not a story.
**Instead:** Frame around the user outcome the refactoring enables.
</anti_pattern>

<anti_pattern name="Vague criteria">
**Bad:** "The page should work correctly"
**Why:** Untestable. What does "correctly" mean?
**Instead:** "The page loads within 2 seconds and displays the user's name and balance"
</anti_pattern>

<anti_pattern name="Solution in the story">
**Bad:** "As a user, I want a React modal with a form that POSTs to /api/orders"
**Why:** Stories describe WHAT, not HOW. Implementation belongs in subtasks.
**Instead:** "As a user, I want to place an order from the product page so that I can buy items without navigating away"
</anti_pattern>
</anti_patterns>
