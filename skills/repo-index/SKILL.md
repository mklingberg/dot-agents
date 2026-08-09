---
name: repo-index
description: "What repos, components and dependencies exist, from INDEX.md. Triggers: 'what else uses', 'who owns this repo', 'what is <repo> for'. Multi-repo change: coordinate-cross-repo."
---

<objective>
Answer "what exists in this folder and how does it fit together" from `INDEX.md`, without
sweeping the tree. Reading is the common case — several times a day. Regenerating the file is
rare, and lives in `workflows/refresh-index.md`.
</objective>

<config>
Site-specific. Fork the skill, edit this block, leave the rest alone.

| Setting | Value |
|---|---|
| Polyrepo root | `~/Dev` — sibling repos one level down; not a git repo itself |
| Index | `~/Dev/INDEX.md` — untracked, so no history and no blame |
| Domain cache | `~/Dev/DOMAIN.md` — business meaning, maintained by `domain-knowledge`; read alongside, never written from here |
| Schema | `templates/INDEX.template.md` in this skill |
| Refresh | `workflows/refresh-index.md` |
</config>

<essential_principles>

### Read the index before sweeping the tree
It answers "which repos does this touch" without 40 greps, and it is the only place that
knows about systems with no local checkout. Reaching for `grep -r` across the root first is
the mistake this file exists to prevent.

### Half the file is derived and half is curated — know which you are quoting
Content between `<!-- index:derived:* -->` fences was mechanically derived from disk on the
date stamped at the top. Everything else is human judgment. Both are useful and they fail
differently: derived rows go stale silently when disk changes, curated prose goes stale
silently when reality does. **Say which half a claim came from** when it matters, and check
`Last derived` before treating a derived row as current.

### Every derived edge carries its evidence — use it
Each dependency row names the file it came from and the key within it. A row you doubt is
checkable in one hop, so check it rather than trusting or dismissing it. **An edge whose
evidence no longer resolves is a signal to refresh, not a fact to report.**

### The node is a component, not always a repo
A monorepo publishes several independently versioned contracts, addressed as `repo:path`. An
edge points at the thing that actually changes, so "repo A depends on repo B" may be too
coarse to act on — read the component.

### An `external:<system>` end is still an edge, and often the important one
Systems with no local checkout are the ones a reader most needs told about: a third-party or
other-team system publishing events you consume constrains ordering as much as any internal
edge. Never treat `external:` as "not real" or "out of scope".

### The index describes structure, never meaning
It says a repo exists, what stack it is, what it depends on, and who owns it. It does not say
what the business calls it or why it matters — that is `domain-knowledge`. Answering a
"what does this product do" question from the index alone produces confident structural
trivia.

</essential_principles>

<orientation>
What each section answers, so a lookup goes straight there:

| Question | Section |
|---|---|
| Does repo X exist, what stack, what kind (api/worker/spa/infra/tool) | Repos *(derived)* |
| What does this repo publish independently | Components *(derived)* |
| What else consumes this contract / who calls this API / who reads this topic | Dependency Edges *(derived)* |
| Where derived tables disagree with the curated prose | Contradictions *(derived)* |
| Who reviews and approves, who operates it in production | Ownership *(curated)* |
| Which repos does a feature of this type touch | Change Patterns *(curated)* |
| What is this repo for | Purpose *(curated)* |
| Branch naming, flag placement, test stack, config layout | Conventions *(curated)* |
| What's legacy, where the sharp edges are, which stack has no recipe yet | Domain Notes *(curated)* |

**Ordering for a change spanning repos** comes from the edge `kind`: `nuget` needs the
producer published before consumers bump, `event` needs consumers able to read the new shape,
`rest` needs the callee deployed before the caller relies on it, `bundled` means one repo
ships inside another's host.

**What the index cannot answer**, with where to go instead:

- business meaning, products, markets, vocabulary → `domain-knowledge`
- executing a change across several repos — plans, PR order → `coordinate-cross-repo`
- current detail about the repo you are in → that repo's own `AGENTS.md`/`CLAUDE.md`, which
  wins over the index on its own subject
- anything absent because the index is stale → `workflows/refresh-index.md`

**An empty curated section means unanswered, not "nothing to say."** An empty Change Patterns
table is the difference between an index that answers "which repos does this feature touch"
and one that doesn't — report the gap rather than inferring an answer from the derived rows.
</orientation>

<routing>
Lookups, "what else uses this", ownership, purpose → `<orientation>` above. No menu.

"Index the repos", "update the repo index", or a repo added, moved, removed, or folded into a
monorepo → read `workflows/refresh-index.md` and follow it.

`INDEX.md` missing entirely → say so and offer that workflow. Do not answer topology questions
by sweeping the tree and presenting the result as if it were the index; derive it properly or
say it isn't derived.
</routing>

<gotchas>
- **`Last derived` is the expiry date on every derived row.** A repo added since then is
  invisible, and the file gives no other hint. Check the stamp before answering "is there a
  repo for X" with "no".
- **The root is not a git repo**, so the index is untracked: no history, no blame, no way to
  see what a previous version said. A refresh writes `INDEX.md.bak` for exactly that reason.
- **`<root>/_workspaces/<repo>/<branch>` is another checkout of a listed repo, not another
  repo.** Counting them inflates any answer about how many repos exist.
- **A repo's directory name and its package or service name differ.** A question phrased with
  the service name may need matching against the package id in the edge rows, not the repo
  column.
- **One row per node pair.** A dozen projects referencing the same package appear once, so the
  edge table understates *how many* places change, and only names *which* repos do.
- **Test-only dependencies are deliberately absent.** The edges are production references; a
  package used solely by tests is not there, so "nothing depends on this" can be wrong for a
  test utility.
- **Curated rows outlive their subject.** Ownership and change-pattern rows naming a repo that
  has since moved into a monorepo still read as valid. The Contradictions section is the only
  thing that catches this, so read it before trusting curated prose.
- **Two indexes can coexist.** A project may keep its own index for another consumer; this
  skill owns only the one in `<config>`.
</gotchas>

<success_criteria>
- Topology answers come from `INDEX.md`, not from a fresh sweep of the tree
- Claims say whether they came from a derived or curated region when it affects trust
- A doubted edge row is verified against its evidence path before being reported or dismissed
- `external:` systems are included in answers about what depends on what
- `Last derived` is checked before answering that something does not exist
- Business-meaning questions are routed to `domain-knowledge` rather than answered structurally
- A missing or stale index produces an offer to refresh, never an improvised sweep
</success_criteria>
