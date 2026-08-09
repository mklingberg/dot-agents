<required_reading>
1. `templates/DOMAIN.template.md` — the current schema, every run
2. `~/.agents/skills/confluence/references/rest-api.md` — auth, the v1/v2 split, endpoints
3. `~/.agents/skills/confluence/SKILL.md` `<config>` — the space key map
4. the **repo index** named in `SKILL.md` `<config>`, section `## Domain Notes` — for the contradictions pass in step 6
</required_reading>

<process>

### 1. Load the schema and resolve the file
Read the template before anything else, every run. An existing `DOMAIN.md` carries whichever
schema was current when it was last written; holding the template's shape in mind while you
derive is what stops a refresh reproducing an old one.

Target is the **domain cache** named in `SKILL.md` `<config>`, beside the repo index. State which path you resolved.

### 2. Verify auth before deriving anything
```bash
curl -s -o /dev/null -w '%{http_code}\n' "${AUTH[@]}" "$W/api/v2/spaces?limit=1"   # expect 200
```
`AUTH` must be an array and `$ATLASSIAN_USER` must be set — see the `confluence` skill. A
401/403 here is a malformed request, not missing access; fix the quoting. Do not proceed on a
non-200 and do not report a permissions problem without a corrected retry.

### 3. Build the space id → key map once
Page responses carry a numeric `spaceId`, never the key. Every citation needs the key, so
resolve the map up front and reuse it:
```bash
curl -s "${AUTH[@]}" "$W/api/v2/spaces?limit=250"    # id, key, name
```

### 4. Refresh the sources table
**Refresh path** — for each page id already cited in `DOMAIN.md`:
```bash
curl -s "${AUTH[@]}" "$W/api/v2/pages/<id>"          # title, spaceId, version
```
Take `modified` from **`version.createdAt`**, the timestamp of the last edit. Do **not** use
`version.number`: a high version count means a page was edited often over its life, not
recently, and reading it as freshness inverts the answer on exactly the pages that matter
most. An id that no longer resolves is a row in Contradictions, not a silent deletion.

**Bootstrap path** — no `DOMAIN.md` yet, so there is nothing to refresh and the seeds have to
be found. Discover candidates, do not assume one space holds them:

- walk each space's tree from its homepage:
  `curl -s "${AUTH[@]}" "$W/api/v2/spaces?keys=<KEY>"` then
  `curl -s "${AUTH[@]}" "$W/api/v2/pages/<homepageId>/children?limit=100"`
- and search by domain vocabulary across spaces (v1 only):
  `curl -s -G "${AUTH[@]}" --data-urlencode 'cql=text ~ "<term>"' "$W/rest/api/search"`

Search as well as walk. The pages that answer a domain question are not reliably descendants
of the space homepage, and a walk alone silently misses them.

Then apply the leanness test to every candidate:

> **Would what is on this page change a design decision** — product boundaries, market
> differences, lifecycle states, vocabulary, a rule that constrains implementation?

`no` → leave it out. Meeting notes, retros, sprint and status pages, onboarding admin,
department pages and tooling docs are out however current they look. `unsure` → put it in the
report as a question, not in the file.

**Propose the seed set and stop for approval before writing curated prose.** Deriving the
sources table needs no permission; distilling the domain does.

### 5. Detect stale, don't re-summarise
For each curated section, compare its `distilled:` date against the `modified` of every page
it cites. Later `modified` → a Stale row naming the section.

That is the whole staleness mechanism. Do not rewrite the curated prose to match the page:
summarised prose is not idempotent, so a refresh that rewrites it produces a diff every run
and the real changes disappear into the noise.

**Age alone is never a Stale row.** Most of this domain is years old and settled. A row means
"this page moved after you read it", nothing else.

### 6. Reconcile against INDEX.md
Read the repo index's `## Domain Notes` and compare with the curated prose in the cache. Report:

- a curated claim the wiki now contradicts
- a curated claim the repo index contradicts
- domain context in the index's `Domain Notes` that belongs in the cache and is missing

All three are Contradictions rows. Do not migrate anything out of the repo index — it has its own
skill and its own curated regions, and moving prose between two hand-written files without
being asked loses the reason it was written where it was.

### 7. Write
The template defines the schema on every run, creating and refreshing alike.

- **No cache file yet** — copy the template, fill the derived regions, leave curated sections as
  the template's prompts. An empty curated section is an honest empty; invented content is
  worse than nothing because nothing signals its own absence.
- **It exists** — copy to `<cache>.bak` first; its folder is not version controlled, so that
  backup is the only way back. Then rewrite each fenced derived region. Where the file's
  columns differ from the template's, migrate to the template's shape and populate the new
  columns. A rewrite that lands byte-identical is a valid outcome; skipping it because you
  expect that outcome is how schema drift survives.

Curated regions come out exactly as they went in. Stamp `Last synced` as `YYYY-MM-DD HH:MM`.

Then verify mechanically: every page id in the sources table resolved this run, and every row
carries a space key. Report any that didn't rather than asserting they did.

### 8. Report
- counts per derived region
- new sources added, cited ids that no longer resolve
- Stale rows, each naming the section and how far behind it is
- Contradictions rows
- candidates judged `unsure`, as questions for the user
- curated sections still empty — an empty Vocabulary is the difference between a cache that
  turns a business request into a repo set and one that doesn't
- whether the root instruction file points at the cache; if not, offer to add the pointer
  alongside the existing `INDEX.md` one, as a pointer and never a copy

</process>

<success_criteria>
- the domain cache exists, derived regions fenced and populated, curated regions preserved
  byte-identically
- Every sources row carries page id, **space key**, and a `modified` taken from
  `version.createdAt`
- Refreshing an existing file leaves `DOMAIN.md.bak` beside it
- `Last synced` shows this run's date and time
- Stale rows reflect movement since `distilled`, never age alone
- No curated prose written without the user approving the seed set first
- No credentials, personal data, or long quotations anywhere in the file
- Nothing in the skill directory gained a product name, page id, or space key
</success_criteria>
