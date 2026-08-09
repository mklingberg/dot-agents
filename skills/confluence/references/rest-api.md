<overview>
Confluence Cloud via curl. Same site and same token as the `jira` skill — one
Atlassian API token covers both products.

**The API is split and you cannot avoid it:** content reads and writes live on
v2 (`/wiki/api/v2`), but **search only exists on v1** (`/wiki/rest/api/search`).
v2 has no search endpoint; `GET /api/v2/search` returns 400.
</overview>

<auth>
```bash
W="https://norionbank.atlassian.net/wiki"
AUTH=(-u "$ATLASSIAN_USER:$ATLASSIAN_PAT")
```
Basic auth with the API token as the password — not a bearer token.
`$ATLASSIAN_USER` is the account email; neither it nor the token is written into
this skill — this repo is public. Setup and the `ATLASSIAN_USER` caveat are in
`jira/references/rest-api.md` `<auth>`; the same token and email cover both
products.

If `$ATLASSIAN_PAT` is unset in this process:
```bash
export ATLASSIAN_PAT=$(security find-generic-password -s atlassian-token -a "$USER" -w)
```
Permanent fix, then restart the harness — discover the label rather than
assuming it, since it carries the local account name:
```bash
launchctl kickstart -k gui/$(id -u)/$(launchctl list | awk '/environment-secrets/{print $3}')
```

Verify before anything else:
```bash
curl -s -o /dev/null -w "%{http_code}\n" "${AUTH[@]}" "$W/api/v2/spaces?limit=1"   # 200
```
</auth>

<spaces>
```bash
curl -s "${AUTH[@]}" "$W/api/v2/spaces?limit=100"          # id, key, name, type, homepageId
curl -s "${AUTH[@]}" "$W/api/v2/spaces?keys=TM"
```
There are ~48 spaces. **Writes need `spaceId` (numeric), search needs `key`** —
`TM` is key `TM`, id `23887873`. Confusing the two produces a 400 that blames
the wrong field.
</spaces>

<reading>
**A page by id**, choosing a body format:
```bash
curl -s "${AUTH[@]}" "$W/api/v2/pages/30867490?body-format=storage"
```

| `body-format` | You get | Use for |
|---|---|---|
| `storage` | Confluence XHTML — `<ac:layout>`, `<ac:structured-macro>` | round-tripping an edit |
| `atlas_doc_format` | ADF JSON, same shape as Jira | when you'd rather walk a tree |
| `view` | rendered HTML | never — it's lossy and unwritable |

For *reading to the user*, strip tags from `storage` or flatten `atlas_doc_format`.
Do not paste raw storage XHTML into the conversation; it's mostly layout noise.

**Children** (page tree navigation — often better than search):
```bash
curl -s "${AUTH[@]}" "$W/api/v2/pages/23855107/children?limit=25"
```

**Labels** — a strong retrieval signal, curated by humans:
```bash
curl -s "${AUTH[@]}" "$W/api/v2/pages/30867490/labels"
```

**Pagination** is `_links.next`, a **relative** path. Prefix it with `$W`:
```python
nxt = d.get("_links", {}).get("next")
url = W + nxt if nxt else None
```
</reading>

<writing>
**Not implemented yet.** Writes are deliberately out of scope in this version of
the skill — the create/update payloads were never tested against the live API,
and shipping unverified write instructions is how pages get clobbered.

If the user asks to create or edit a page: say the skill is read-only today and
ask whether they want the write path built and tested first.

What's known and will need verifying when that day comes: create is
`POST /api/v2/pages` with `spaceId` + `body.representation=storage`; update is
`PUT /api/v2/pages/{id}` requiring `version.number` = current + 1 and replacing
the entire body; labels are a separate v1 call.
</writing>

<gotchas>
- **Search is v1 only.** `/api/v2/search` 400s. Use `/rest/api/search?cql=…`.
- **Search doesn't cover everything the API serves.** Pages exist that `GET /api/v2/pages/{id}` returns `200` for and CQL never finds. Always prefer an id linked from another page over a search result.
- **Basic auth, not bearer.**
- **`spaceId` (numeric) for writes, `key` for CQL.** Not interchangeable.
- **`_links.next` is relative** — prefix with `$W` or you'll request the wrong host.
- **`view` format is not writable** and is lossy. Never round-trip through it.
- **Space key `MS` is "Payments", not Mina sidor.** See SKILL.md.
</gotchas>
