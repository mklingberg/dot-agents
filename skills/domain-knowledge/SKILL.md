---
name: domain-knowledge
description: "Business domain orientation from a local cached DOMAIN.md: products, markets, vocabulary. Triggers: 'how does X work', 'which systems does X touch'. Wiki search: confluence."
---

<objective>
Answer domain questions — what a product is, which market differs, what a term means, which
system owns it — without hunting the wiki every time. The knowledge lives in a local cache
file; this skill is the procedure for reading it, trusting it, and refreshing it.
</objective>

<config>
Site- and team-specific. Fork the skill, edit this block, leave the rest alone. Nothing here
is a secret, but the paths are local and the wiki is private.

| Setting | Value |
|---|---|
| Domain cache | `~/Dev/DOMAIN.md` — untracked; `~/Dev` is not a git repo |
| Repo index | `~/Dev/INDEX.md` — maintained by `create-repo-index`; reconciled against, never written |
| Root instruction file | `~/Dev/AGENTS.md` — points at both, via `@` includes |
| Wiki | Confluence, reached through the `confluence` skill; space keys and the collision table live in that skill's `<config>` |
| Cache template | `templates/DOMAIN.template.md` in this skill |

**This skill holds no domain content.** It is committed to a public remote, so the products,
markets, vocabulary and business rules live only in the cache file above. That split is the
whole design, not an accident of this repo — see `<what_not_to_record>`.
</config>

<essential_principles>

### This file is public; the domain knowledge is not
This skill is committed to a public remote. The domain cache is not — its folder is no git
repo, so nothing there is tracked or ignored. Every product fact, market difference, term
definition, partner name and page id belongs in that file. Nothing that would embarrass on
a public diff gets written here, in a commit message, or in a PR.

### Read the cache; hit the wiki only for what it cites
`DOMAIN.md` exists so an agent inside one repo can answer a cross-system question without a
Confluence round-trip. Consult it first, and fetch a page only when you need detail past the
distilled line — then cite what you fetched.

### A timestamp cannot tell settled from abandoned — in either direction
Most of this domain changes rarely. A page last edited years ago describing a stable product
boundary is settled, not stale; the same age on a page describing a migration means abandoned.
Only a human distinguishes those, and the cache records the verdict. So **never downgrade a
curated claim because its source page looks old** — the age was already considered.

**And never promote a claim because its page is recent.** A wiki page describes what someone
intended when they wrote it, which is not the same as what ships. Recency raises the odds and
settles nothing. Where a page and the code disagree, the code is what runs, and the operator
outranks both — record the divergence rather than picking the newer document.

**Dormant is a third state, and the one most often misread.** A page can be historically
accurate and currently wrong — documenting a deprecated predecessor, with nothing on it saying
so. That looks identical to abandoned and reads as settled. It matters because the action
differs: settled means rely on it, abandoned means discard it, dormant means neither — don't
build as if the capability exists, and don't strip its remnants either, because a dormant
feature is one someone intends to revive. Record which of the three a claim is, and record
that a page describes a predecessor when it does; nothing in the page metadata will say it.

### Cite space key with every page
Several Confluence spaces carry parts of this domain, and their keys collide with product
words — the space whose key reads like a product is usually not the one holding that
product's docs. A page id without its space key is a citation nobody can check. The
`confluence` skill's `<config>` holds the key map and the collision table; read it there and
don't restate it here.

### Curated prose is never silently rewritten
A refresh rebuilds the derived tables and leaves every curated word byte-identical. When
disk or wiki contradicts a curated claim, the finding goes in the contradictions table and
waits for the user. That includes helpful notes: a signpost appended to curated text is
still a write to it.

</essential_principles>

<orientation>
The frequent path. Three sources, in this order, stopping when answered:

| Read | For | Note |
|---|---|---|
| the **domain cache** (`<config>`) | products, markets, lifecycle, vocabulary, term → system | absent? say so and offer the sync workflow — don't improvise the domain from training data |
| the **repo index** (`<config>`) | which repos and components, dependency edges, ownership, `## Domain Notes` | authoritative on topology; the cache must not duplicate it |
| the repo's own `AGENTS.md` / `CLAUDE.md` | current detail for the repo in hand | most repos carry one, and it beats both files on its own subject |

Working inside a repo or a worktree does not change this. Both paths in `<config>` are
absolute and resolve from anywhere, which is the point — the root instruction file is **not**
read when cwd is a repo below it, so its `@` includes never fire.

**If the three disagree, the narrower source wins on its own subject** — a repo's own
instruction file over `INDEX.md` over `DOMAIN.md` — and say that you saw a conflict rather
than quietly picking.
</orientation>

<system_map>
Systems in this domain have their own skills. Route to them rather than re-deriving access:

| Need | Skill |
|---|---|
| wiki search, reading a cited page in full | `confluence` |
| tickets, stories, JQL | `jira` |
| PRs, builds, pipelines | `azure-devops` |
| feature flag state per environment | `launchdarkly` |
| exercising flows locally against test data | `walley-bruno` |
| which repos a change spans | `INDEX.md`, then `coordinate-cross-repo` |

Credentials for those live in each skill's `<config>`, sourced from the login keychain.
Never copy a credential, endpoint, or account identifier into `DOMAIN.md` — it is a domain
cache, not a runbook.
</system_map>

<what_not_to_record>
Applies to this skill and to `DOMAIN.md` both, and is the reason the split holds over time.

**Never in this skill:** product names, market specifics, partner names, page ids, space
keys, customer data, credentials, account identifiers, internal URLs beyond the tenant host
already present in sibling skills.

**Never in `DOMAIN.md`:** credentials or tokens; customer or merchant personal data;
anything copied at length from a page rather than distilled and cited; repo topology that
`INDEX.md` derives.

**Anywhere:** if a page carries credentials or personal data, record that it does and stop
— do not quote it.
</what_not_to_record>

<routing>
Any orientation, lookup or design question → `<orientation>` above. No menu.

"Refresh the domain cache", "sync DOMAIN.md", "the wiki changed", or `DOMAIN.md` missing
→ read `workflows/sync-domain.md` and follow it.

Asked to write to Confluence → the `confluence` skill is read-only; say so, don't improvise
a POST.
</routing>

<gotchas>
- **The cache's folder is not a git repo.** The file has no history and no backup, which is
  why the sync workflow writes a `.bak` beside it — that is the only way back.
- **Space keys collide with product words, and one key means different things in Confluence
  and Jira.** Resolve by key against the `confluence` skill's collision table, and state the
  key you used.
- **The nominated starting point is not the freshest source.** Parts of this domain are
  documented better in a team space than in the shared one; seeds are page ids across
  several spaces, never one space's tree.
- **Hub pages hold no content.** Many pages are a children-macro and a sentence. A fetch that
  finds almost nothing means "descend", not "the wiki doesn't cover this".
- **Most source pages are years old.** That is the normal state of this domain, not a defect
  to flag on every answer. See the settled/abandoned principle.
- **Diagrams are usually external links**, not embedded. A page can look empty while its
  substance sits behind a diagram URL.
- **Much of the source material is Swedish**, including vocabulary. Keep the Swedish term as
  the key and gloss it; translating it away makes the mapping unusable against the systems.
- **`INDEX.md` has its own `## Domain Notes`.** Business context there is legitimate and
  predates this file. Reconcile, report contradictions, and don't migrate it unasked.
</gotchas>

<success_criteria>
- Domain answers cite space key, page id, and last-modified — or say the claim is curated and
  when it was distilled
- No product, market, partner, page id or space key written into this skill
- The cache's absence is reported, never papered over with training-data guesses
- Conflicts between the three sources are surfaced, not silently resolved
- Curated prose in `DOMAIN.md` is byte-identical after any refresh
</success_criteria>
