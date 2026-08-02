---
name: confluence
description: "Find business, domain and workflow docs in norionbank Confluence. Read-only. Triggers: 'search Confluence', 'how does X work', 'find the doc on'."
---

<config>
Site- and team-specific. Fork the skill, edit this block, leave the rest alone.

| Setting | Value |
|---|---|
| Site | `https://norionbank.atlassian.net/wiki` |
| Auth | basic `$ATLASSIAN_USER` : `$ATLASSIAN_PAT` (keychain `atlassian-token`) |
| APIs | reads on **v2** `/wiki/api/v2`; search only on **v1** `/wiki/rest/api/search` |
| Scope | **read-only.** Writing is deferred and untested — see `<read_only>` |
| Own team space | `TM` — "Teamy McTeamface", spaceId `23887873`, homepage `23855107` |
| Main business system | `EDGE` (Edge) and `Gaia` |
| Checkout | `CHEC` (Lambda) |
| Shared payments | `PAY` (Payments IT) · `MS` (Payments) · `PP` (Payments Product) · `Payments` (Walley Wiki) |
| Author accountId | `613779557eb35f006928eb06` |

```bash
W="https://norionbank.atlassian.net/wiki"
AUTH="-u $ATLASSIAN_USER:$ATLASSIAN_PAT"
```
</config>

<essential_principles>

<space_key_collision>
**Confluence space `MS` is "Payments". The Jira project `MS` is "Mina sidor".
They are unrelated.** Reading `MS` expecting Mina Sidor content is the single
easiest way to give the user confidently wrong answers.

Related traps in the same family: `Payments` (key) is "Walley Wiki", `PAY` is
"Payments IT", `PAYM` is "PaymentsOld" — archived-in-spirit, not in status.

When a space is mentioned by name, resolve it to a key before querying:
```bash
curl -s $AUTH "$W/api/v2/spaces?limit=100" | grep -i "<name>"
```
</space_key_collision>

<read_only>
**This skill does not write to Confluence.** No page creation, no edits, no
labels, no comments.

If the user asks for a write, say the skill is read-only today and offer to
build the write path — it needs testing against the live API first. Don't
improvise a `POST` from memory.

When writing is added it will be confined to `TM`, with explicit per-page
confirmation. Every other space stays read-only permanently.
</read_only>

<retrieval_honesty>
This wiki is deep, old, and partly superseded. Search returns confident
nonsense if you take hit #1 on faith.

Every fact reported from Confluence carries its source: **page title, space,
last-modified date, URL**. If a page is older than ~18 months, say so — the
reader decides whether it still holds.

If two pages disagree, report both and say which is newer. Do not silently pick.
If nothing good is found, say that. An honest "the wiki doesn't cover this"
beats a plausible paragraph assembled from three stale pages.
</retrieval_honesty>

</essential_principles>

<routing>
One job today: find and read. Don't open with a menu — go straight to
`workflows/find-docs.md` for any lookup, research or "how does X work" question.

For "document this" / "update that page", see `<read_only>` above.
</routing>

<reference_index>
In `references/`. Read on the trigger, not up front:

| Read this | When |
|---|---|
| `rest-api.md` | Before the first curl call in a session — auth, v1/v2 split, endpoints |
| `search.md` | Any lookup — the search ladder, CQL, ranking and staleness |
</reference_index>

<workflows_index>
| Workflow | Purpose |
|---|---|
| find-docs.md | Search and read — domain knowledge retrieval with citations |
</workflows_index>
