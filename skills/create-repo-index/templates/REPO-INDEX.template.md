# INDEX — {{ROOT_PATH}}

What lives in this folder and how it fits together. Derived regions are rebuilt by the
`create-repo-index` skill; everything else is curated by hand and preserved across runs.

Last derived: {{YYYY-MM-DD HH:MM}}

## Repos

<!-- index:derived:repos -->
| Repo | Path | Stack | Kind |
|---|---|---|---|
<!-- /index:derived:repos -->

## Components

Independently versioned units inside a repo. Addressed as `repo:path` so an edge can point
at the contract that actually changes.

<!-- index:derived:components -->
| Component | Repo | Path | Published as |
|---|---|---|---|
<!-- /index:derived:components -->

## Dependency Edges

`kind` decides ordering when a change spans repos: `nuget` needs the producer published
before consumers bump, `event` needs consumers able to read the new shape, `rest` needs the
callee deployed before the caller relies on it, `bundled` means one repo ships inside
another's host.

Either end may be a repo, a `repo:path` component, or `external:<system>` for a system with
no checkout under this root.

<!-- index:derived:edges -->
| From | To | Kind | Evidence | Key |
|---|---|---|---|---|
<!-- /index:derived:edges -->

## Contradictions

Where curated prose below and the derived tables above disagree. Each row is a finding for the
user to accept or reject; the curated line stays as written until they say otherwise.

<!-- index:derived:contradictions -->
| Curated claim | What disk shows | Where |
|---|---|---|
<!-- /index:derived:contradictions -->

## Ownership

<!-- index:curated -->
Who reviews and approves changes, and who operates the running app. A repo you don't own is
still changeable — the owning team reviews the pull request and runs what merges.

| Repo | Owner | Reviews/approves | Operates |
|---|---|---|---|

## Change Patterns

<!-- index:curated -->
Feature type → what it touches. This table is the reason the index earns its keep: it turns
"add a field to X" into a repo set without a codebase sweep. Derivation can't produce it —
add a row each time a feature teaches you one.

| Feature type | Repos / components | Notes |
|---|---|---|

## Conventions

<!-- index:curated -->
Cross-repo conventions worth stating once: branch naming, feature-flag placement, test
stack, config layout.

## Domain Notes

<!-- index:curated -->
Context a newcomer needs and the code doesn't say: what the systems are for, which are
legacy, where the sharp edges are, and any stack the derivation recipes don't cover yet.
