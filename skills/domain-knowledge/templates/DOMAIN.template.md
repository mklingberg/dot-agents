# DOMAIN — Walley business domain

Domain knowledge for designing features and improving existing systems. Derived regions are
rebuilt by the `domain-knowledge` skill; everything else is curated by hand and preserved across
runs, byte for byte.

**Business domain only.** Repos, components and dependency edges live in `INDEX.md` beside
this file. No credentials, no customer or merchant personal data, no long quotations — distil
and cite.

Last synced: {{YYYY-MM-DD HH:MM}}

## Sources

Every page a curated section below rests on. `distilled` is when a human last read the page
and wrote the prose; `modified` is the page's own last edit. `modified` later than the
`distilled` date of a section citing it is what puts a row in Stale.

<!-- domain:derived:sources -->
| Page id | Space | Title | Modified | Scope |
|---|---|---|---|---|
<!-- /domain:derived:sources -->

## Stale

Cited pages that moved after the curated prose resting on them was written. A row is a
prompt to re-read, not a verdict that the prose is wrong.

<!-- domain:derived:stale -->
| Page id | Space | Modified | Section citing it | Distilled |
|---|---|---|---|---|
<!-- /domain:derived:stale -->

## Contradictions

Where curated prose here disagrees with `INDEX.md` `## Domain Notes`, or with what a source
page now says. Each row waits for the user to accept or reject; the curated line stays as
written until they say otherwise.

<!-- domain:derived:contradictions -->
| Curated claim | What the other source says | Where |
|---|---|---|
<!-- /domain:derived:contradictions -->

## Product model

<!-- domain:curated -->
distilled: {{YYYY-MM-DD}}

What the products are and where their boundaries fall. One line per product: what it is, who
uses it, what distinguishes it from its neighbour. Cite `space/page-id` per claim.

## Markets

<!-- domain:curated -->
distilled: {{YYYY-MM-DD}}

Where the markets genuinely differ — regulatory requirements, signing, payment instruments,
product availability. A market that behaves identically needs no row; the value here is the
exceptions.

| Market | Differs how | Source |
|---|---|---|

## Lifecycle

<!-- domain:curated -->
distilled: {{YYYY-MM-DD}}

The states a purchase, account or invoice moves through, and what moves it. Source material
scatters this across flow pages; a single stated model is the thing worth curating. Where no
authority exists, say so rather than inventing a state machine.

## Vocabulary

<!-- domain:curated -->
distilled: {{YYYY-MM-DD}}

Domain term → what it means → which system owns it. Keep the Swedish term as the key where
that is what people say; gloss it in English. This table is what turns a business request
into a repo set, so it earns the most rows.

| Term | Means | Owning system | Source |
|---|---|---|---|

## Business rules

<!-- domain:curated -->
distilled: {{YYYY-MM-DD}}

Rules that constrain implementation: thresholds, mandatory steps, who must approve what.
Only rules that would change a design decision — everything else is a wiki link.

## Open questions

<!-- domain:curated -->
Domain questions the sources don't answer, with what was searched. Recording the gap stops
the next agent re-running the same fruitless search, and stops it inventing an answer.
