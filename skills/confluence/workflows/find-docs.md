# Workflow: Find and Read Docs

Read-only. Answer the question, with sources.

<required_reading>
1. `references/search.md` — the ladder, CQL, where to look
2. `references/rest-api.md` — auth and page fetching (first call in a session)
</required_reading>

<process>

## Step 1: Turn the question into search terms and spaces

Restate what's actually being asked, then decide **which spaces** — see the
table in `search.md`. A question about the core business domain goes to `EDGE`
and `Gaia`; about our own process, `TM`.

If the question names a system you can't map to a space, list the spaces first
rather than guessing:
```bash
curl -s $AUTH "$W/api/v2/spaces?limit=100"
```

## Step 2: Climb the ladder

Title-in-space → label → text-in-space → text-in-several-spaces → tree walk.
Stop at the first rung with good hits. Do not start at full text.

```bash
curl -s -G $AUTH \
  --data-urlencode 'cql=space=TM AND type=page AND title ~ "<terms>"' \
  --data-urlencode 'limit=10' "$W/rest/api/search"
```

If a rung returns nothing, widen the terms before widening the scope —
Confluence `~` does not stem well, so try the noun the page would actually use
(`reservation`, not `reserving`), and try Swedish. This wiki is bilingual and
the page you want may be titled `Så fungerar…`.

## Step 3: Triage on excerpts, not bodies

From the hit list, pick **2–3** candidates on recency, space and title
specificity. Fetching every hit is the main way this workflow burns a context
window.

## Step 4: Read the chosen pages

```bash
curl -s $AUTH "$W/api/v2/pages/<id>?body-format=storage"
```
Use the `content.id` from the search hit — never construct or recall a page id.
A wrong id returns a body-less JSON object rather than a clean 404, so the
failure shows up as a confusing `KeyError: 'body'` several steps later.

Strip the tags before reasoning about the text. `<ac:structured-macro>` blocks
often contain the important bits (info panels, code, tables) — don't discard
them as markup.

If the page turns out to be an index of child pages rather than content, walk
its children instead of reporting the index as the answer:
```bash
curl -s $AUTH "$W/api/v2/pages/<id>/children?limit=25"
```

## Step 4b: Follow the links in the body

Pages cite each other. A URL in a page body — `/wiki/spaces/<KEY>/pages/<ID>/…`
— **is a direct answer, and outranks anything search will give you.** Extract the
id and fetch it:

```bash
grep -oE '/pages/[0-9]+' /tmp/body.html | sort -u
curl -s $AUTH "$W/api/v2/pages/<id>?body-format=storage"
```

When a page says "enligt kriterierna för X" or "see the Y page" and links it,
follow the link. Do not re-search for the target by title — that is how a page
that exists gets reported as `not found`. Observed for real: the DoD links the
risk-acceptance page by id, and CQL cannot find that page by title at all.

## Step 5: Answer with sources

Lead with the answer, then cite. Per `<retrieval_honesty>` in SKILL.md:

```
Feature flags are cleaned up one week after release via a CleanUp sub-task.
  — "How to: Deploy av feature samt uppstädning av flaggor" (TM, updated 2025-11-04)
    https://norionbank.atlassian.net/wiki/spaces/TM/pages/…
```

State staleness for anything older than ~18 months. Show both sides of a
conflict. If the wiki doesn't answer it, say so and list what you searched —
that tells the user where to point you next.

</process>

<success_criteria>
- Searched the right spaces, not all 48
- Started at title/label, not full text
- Followed page ids linked from bodies instead of re-searching for them
- Read at most a handful of pages, chosen deliberately
- Every claim carries page title, space, last-modified date and URL
- Stale or conflicting sources flagged rather than smoothed over
- Said "not found" only after trying a direct id fetch, not just search
- Nothing written to Confluence
</success_criteria>
