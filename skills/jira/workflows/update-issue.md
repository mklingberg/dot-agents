# Workflow: Update an Issue — fields, comments, transitions

Every step here is a **write**. The `<approval_gate>` in SKILL.md applies: state
what you're about to change, get an explicit yes, then act.

<required_reading>
1. `references/rest-api.md`
2. `references/adf.md` — required for any comment or description text
</required_reading>

<process>

## Step 1: Read the current state first

```bash
curl -s $AUTH "$B/issue/MS-6548?fields=summary,status,assignee,labels,customfield_12035"
```
Never write blind. The user's mental model of the ticket is often stale.

## Step 2: Pick the operation

### Edit fields
```bash
curl -s $AUTH -X PUT -H "Content-Type: application/json" \
  --data '{"fields":{"summary":"New summary","labels":["Frontend","MyWalley"]}}' \
  "$B/issue/MS-6548"
```
Expect `204` and an empty body. `labels` **replaces** the whole array — read the
existing labels first and send the union, or you will silently drop them.

Only use labels already in `<config>`; ask before introducing a new one.

### Add a comment
```bash
curl -s $AUTH -X POST -H "Content-Type: application/json" \
  --data @/tmp/comment.json "$B/issue/MS-6548/comment"
```
`{"body": <ADF doc>}`. Markdown 400s. Returns `201` with the comment `id` —
keep it; `DELETE $B/issue/KEY/comment/ID` is the undo.

Comments post under Marcus Klingberg, not as an AI. Write in that register.

### Transition status
```bash
curl -s $AUTH "$B/issue/MS-6548/transitions"     # always discover first
curl -s $AUTH -X POST -H "Content-Type: application/json" \
  --data '{"transition":{"id":"91"}}' "$B/issue/MS-6548/transitions"
```
Transition ids are per-workflow **and depend on the current status** — the id
that worked yesterday may not be legal today. Never hardcode, never reuse an id
from an earlier session. Match the user's words against the `to.name` values in
the discovery response, and if two plausibly match, ask which.

### Assign
```bash
curl -s $AUTH -X PUT -H "Content-Type: application/json" \
  --data '{"accountId":"613779557eb35f006928eb06"}' "$B/issue/MS-6548/assignee"
```
Find other people with `GET $B/user/search?query=<name or email>`. `null`
unassigns.

## Step 3: Confirm

Re-read the changed fields and report the new state with the browse URL. A `204`
means accepted, not that the value is what the user meant.

</process>

<success_criteria>
- Current state read before writing
- User approved the specific change, not a vague "update it"
- Labels merged, never clobbered
- Transition id discovered in this session
- Result verified by re-reading, not assumed from the status code
</success_criteria>
