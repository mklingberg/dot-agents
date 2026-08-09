---
name: confluence
description: "Find business, domain and workflow docs in norionbank Confluence. Read-only. Triggers: 'search Confluence', 'how does X work', 'find the doc on'."
---

<config>
Site- and team-specific. Fork the skill, edit this block, leave the rest alone.

| Setting | Value |
|---|---|
| Site | `https://norionbank.atlassian.net/wiki` |
| Auth | basic `$ATLASSIAN_USER` : `$ATLASSIAN_PAT` (keychain `atlassian-token`) — both published at login |
| APIs | reads on **v2** `/wiki/api/v2`; search only on **v1** `/wiki/rest/api/search` |
| Scope | **read-only.** Writing is deferred and untested — see `<read_only>` |
| Own team space | `TM` — "Teamy McTeamface", spaceId `23887873`, homepage `23855107` |
| Main business system | `EDGE` (Edge) and `Gaia` |
| Checkout | `CHEC` (Lambda) |
| Cross-team / shared concerns | `Payments` — displayed as **"Walley Wiki"** |
| Merchant services, partner support | `MS` — displayed as **"Payments"** |
| Also payments-adjacent | `PAY` (Payments IT) · `PP` (Payments Product) · `PAYM` (PaymentsOld) |
| Author accountId | resolve live, never stored: `curl -s $AUTH "$W/rest/api/user/current"` → `.accountId` |

```bash
: "${ATLASSIAN_USER:?not set — see <auth> in references/rest-api.md}"
W="https://norionbank.atlassian.net/wiki"
AUTH="-u $ATLASSIAN_USER:$ATLASSIAN_PAT"
```

**Never echo, log, or paste the token; always reference `$ATLASSIAN_PAT`.** Where the env
var is empty — a fresh shell, or a subagent that never sourced the login publisher — read
the keychain by expansion inside the command that needs it, never into a literal:

```bash
AUTH="-u $ATLASSIAN_USER:$(security find-generic-password -s atlassian-token -w)"
```

The token is ~190 characters and contains shell-significant characters. Pasting the literal
into a command both leaks it and corrupts it, so **a 401/403 here means a malformed request,
not missing access** — fix the quoting before concluding anything about permissions. A
delegated task that reports "user not permitted to use Confluence" has almost certainly
mangled its own auth header.
</config>

<essential_principles>

<space_key_collision>
**Four spaces cluster around the word "Payments" and none of them mean what you'd
guess.** Resolve by key, and state the key you used when citing.

| Key | Displayed name | Actually contains |
|---|---|---|
| `Payments` | Walley Wiki | **cross-team shared concerns** — the common wiki |
| `MS` | Payments | **merchant services / partner support** |
| `PAY` | Payments IT | payments engineering |
| `PP` | Payments Product | payments product |
| `PAYM` | PaymentsOld | superseded — still returns search hits |

And separately: **Confluence space `MS` is not the Jira project `MS`.** Jira `MS`
is Mina sidor; Confluence `MS` is merchant services. Reading `MS` in Confluence
expecting Mina Sidor content is the easiest way to give confidently wrong
answers.

When a space is mentioned by name, resolve it to a key before querying — the
name the user says is often another space's key:
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
