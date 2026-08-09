# Workflow: Search and Read Issues

Read-only. **No approval gate applies** — answer directly.

<required_reading>
1. `references/rest-api.md` — endpoints, JQL, cursor pagination
2. `references/adf.md` — only the `<reading_adf>` section, to flatten descriptions
</required_reading>

<process>

## Step 1: Decide — key lookup or search?

| User said | Do |
|---|---|
| a key (`MS-6548`, "the invoice ticket MS-1234") | `GET $B/issue/KEY` |
| a question ("what's in the sprint", "my open bugs") | JQL via `GET $B/search/jql` |

## Step 2a: Single issue

```bash
curl -s "${AUTH[@]}" "$B/issue/MS-6548?fields=summary,status,assignee,labels,description,parent,subtasks,customfield_12035"
```
Name the fields. The unfiltered response is thousands of lines of nulls.

## Step 2b: JQL search

```bash
curl -s -G "${AUTH[@]}" \
  --data-urlencode 'jql=project=MS AND status="To be Refined" ORDER BY created DESC' \
  --data-urlencode 'fields=summary,status,assignee,labels' \
  --data-urlencode 'maxResults=50' \
  "$B/search/jql"
```

Useful clauses for MS:

| Intent | JQL |
|---|---|
| Mine, open | `project=MS AND assignee=currentUser() AND statusCategory!=Done` |
| Current sprint | `project=MS AND sprint in openSprints()` |
| One team | `project=MS AND "Teamy Team"=Magica` |
| Subtasks of a story | `parent=MS-1234` |
| Recently touched | `project=MS AND updated > -7d ORDER BY updated DESC` |

Multi-word values need quotes inside the JQL **and** `--data-urlencode` around
the whole clause. Never interpolate a JQL string straight into a URL.

## Step 3: Paginate only if needed

The response has `nextPageToken` and `isLast` — no `startAt`, no `total`. Page by
passing `nextPageToken` back. If the user asked "how many", say what you counted
and whether more pages exist; don't invent a total.

## Step 4: Report

Flatten ADF to text. One line per issue:

```
MS-6548  To be Refined  Magica  — Visa fakturor i listan
```

Link keys as `https://norionbank.atlassian.net/browse/MS-6548`. Summarise; don't
paste raw JSON unless the user asked for a field the summary doesn't cover.

</process>

<success_criteria>
- Answered with a summary, not a JSON dump
- Field list explicitly narrowed on every request
- Pagination state reported honestly when results were truncated
- No writes performed
</success_criteria>
