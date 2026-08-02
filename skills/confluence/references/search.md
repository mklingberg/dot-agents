<overview>
How to find the right page in a 48-space wiki with a decade of history.

Confluence text search is a term match with weak ranking. `text ~ "feature flag"`
in `TM` returns 16 pages whose top hit is *Clarity Event Tracking* — related to
nothing. `title ~ "feature flag"` returns 4, all correct. **Precision first,
then widen.**
</overview>

<the_ladder>
Work down this ladder. Stop at the first rung that yields good hits — going
straight to full-text costs tokens and returns noise.

**1. Title, scoped to a space**
```bash
curl -s -G $AUTH \
  --data-urlencode 'cql=space=TM AND type=page AND title ~ "feature flag"' \
  --data-urlencode 'limit=10' "$W/rest/api/search"
```

**2. Label** — human-curated, high signal
```bash
--data-urlencode 'cql=label="dod" AND type=page'
```

**3. Text, scoped to a space, newest first**
```bash
--data-urlencode 'cql=space=TM AND type=page AND text ~ "feature flag" order by lastmodified desc'
```

**4. Text across the likely spaces** — name them, don't search all 48
```bash
--data-urlencode 'cql=space in (EDGE,Gaia,CHEC) AND type=page AND text ~ "reservation" order by lastmodified desc'
```

**5. Page tree walk** — when search fails but you know roughly where it lives
```bash
curl -s $AUTH "$W/api/v2/pages/23855107/children?limit=25"
```
TM's tree is organised by topic (`DevOps / Tekniskt`, `Workflow`, `🔥 Produkter`,
`🔪 Testning`), so descending it is often faster than guessing search terms.
</the_ladder>

<where_to_look>
Pick spaces from the question, don't spray:

| Question is about | Spaces |
|---|---|
| Our own team, our workflow, our how-tos, DoD | `TM` |
| The main business system, core domain | `EDGE`, `Gaia` |
| Checkout | `CHEC` (Lambda) |
| Payments domain (shared, several overlapping spaces) | `PAY`, `MS`, `PP`, `Payments` |
| Design / UX | `DG`, `WUX` |

Remember `MS` here is **Payments**, not Mina sidor.
</where_to_look>

<cql>
```
space = TM                     space in (EDGE,Gaia)
type = page                    type in (page,blogpost)
title ~ "deploy"               text ~ "feature flag"
label = "how-to"               creator = currentUser()
lastmodified >= now("-6m")     ancestor = 181764187
order by lastmodified desc
```
`~` is a fuzzy/term match, `=` is exact. Multi-word values need double quotes,
and the whole clause needs `--data-urlencode` — never interpolate into the URL.

`ancestor = <pageId>` restricts to a subtree; it is the sharpest filter
available once you know the section.
</cql>

<reading_results>
The v1 search result gives you, per hit: `title`, `lastModified`,
`resultGlobalContainer.title` (the space), `url` (relative — prefix with
`$W`... actually with the site root: `https://norionbank.atlassian.net/wiki`),
and `excerpt`.

**Triage on the excerpt before fetching bodies.** Fetching 10 full pages to
answer one question is the main way this skill wastes a context window. Pick the
2–3 that look right, then `GET /api/v2/pages/{id}?body-format=storage`.

Judge each candidate on:
- **Recency** — `lastModified`. Anything older than ~18 months is suspect.
- **Space** — a page in `PAYM` ("PaymentsOld") is probably superseded.
- **Specificity** — a page titled exactly the thing beats a page mentioning it.
</reading_results>

<citing>
Report findings as claim + source, never bare prose:

```
Feature flags are cleaned up one week after release via a CleanUp sub-task.
  — "How to: Deploy av feature samt uppstädning av flaggor" (TM, updated 2025-11-04)
    https://norionbank.atlassian.net/wiki/spaces/TM/pages/…
```

If the best source is old, say "updated 2023 — may be stale". If two pages
conflict, show both. If the wiki genuinely doesn't answer it, say so and name
what you searched, so the user can tell you where to look instead.
</citing>

<gotchas>
- **Full-text ranking is poor.** Always try `title ~` first.
- **`order by lastmodified desc` on text searches**, or you get 2017 pages on top.
- **Don't search all 48 spaces.** Name the likely ones.
- **`totalSize` is the match count, not a quality signal** — 16 hits can be 16 wrong hits.
- **Excerpts are HTML-escaped** (`&quot;`, `&amp;`). Unescape before quoting.
- **Archived-in-spirit spaces** (`PAYM`, `X`) still return results.
</gotchas>
