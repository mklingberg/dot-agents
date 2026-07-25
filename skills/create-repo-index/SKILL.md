---
name: create-repo-index
description: "Create or refresh a polyrepo REPO-INDEX.md: repos, components, dependency edges. Triggers: 'index the repos', 'update repo index', repo added or moved."
---

<objective>
Produce `REPO-INDEX.md` at the root of a folder holding many sibling repos, describing what
lives there and how the repos depend on each other. One file, two kinds of content:
**derived** (re-read from disk every run) and **curated** (human judgment, preserved
across runs).
</objective>

<essential_principles>
### Derived regions are rebuilt, curated regions are untouched
Every run rewrites the content between `<!-- index:derived:* -->` fences from disk, and
carries all other prose forward verbatim. This is the whole reason the file survives:
the mechanical half stays true, the judgment half stays.

### Derive identity from paths, never from IDs
A repo's identity is its path. Worktree IDs, workspace UUIDs, and pipeline IDs belong to
tools that outlive nothing — resolve those live at the point of use.

### Record evidence for every derived edge
Each dependency row names the file it came from and the key within it. An edge whose
evidence no longer resolves is a signal to re-derive, and a reader who doubts a row can
check it in one hop.

### The node is a component, not always a repo
A monorepo publishes several independently versioned contracts. Address those as
`repo:path`, so an edge points at the thing that actually changes.

### An edge with one end outside the root is still an edge
Systems with no local checkout are the ones a reader most needs told about. Name that end
`external:<system>` and keep the row.
</essential_principles>

<process>

### 1. Load the schema, then resolve the root
Read `templates/REPO-INDEX.template.md` before anything else, every run. It carries the current
region fences and table columns, and an existing `REPO-INDEX.md` carries whichever ones were
current when it was last written. Holding the template's shape in mind while you derive is
what keeps a refresh from reproducing an older schema.


The root is the folder holding the sibling repos, and it can arrive three ways — take the
first that applies:

1. **Passed as an argument** — a path in the skill invocation (`/create-repo-index ~/Dev`)
   or named in the user's request. Use it as given; expand `~` and relative paths, then
   confirm it exists.
2. **Found by walking up** from cwd to the first directory containing `REPO-INDEX.md`.
3. **Inferred** from cwd's nearest ancestor holding many sibling repos.

State the root you resolved and continue. Worktree checkouts nest under the root (e.g.
`<root>/_workspaces/<repo>/<branch>`), so walking up from one reaches the same root.

### 2. Enumerate repos
Directories one level under the root containing `.git`. Skip:

| Skip | Why |
|---|---|
| `_`-prefixed dirs (`_workspaces`, `_external`, `_cleanup`) | staging, vendored, or alternate checkouts of repos already listed |
| `node_modules` and other dependency dirs | not source |

For each: path, stack, and one or more kinds.

| Signal | Stack | Kind |
|---|---|---|
| `*.sln`, `*.slnx`, `*.csproj` | .NET | per project name and host type, below |
| `package.json` | node | `spa` with a bundler config, `lib` when published, else `app` |
| `*.tf`, `*.tfvars` | terraform | `infra` |
| k8s manifests, CI pipeline templates, chart dirs | — | `infra` |
| config-only, `.http` collections, editor/dotfile repos | — | `tool` |

.NET kinds: project named `*.Api` → `api`; `*.Worker`/`*.Processor`/`*.Consumer`/
`*.Scheduler` → `worker`; `*.Web`/MVC host → `web`; library carrying `PackageId` or a
`nuspec` → `nuget`.

**A repo often earns several kinds** — an API alongside a background worker is common.
List every kind that applies rather than electing a primary; a reader filtering for
`worker` needs to find it.

### 3. Enumerate components
Inside each repo, find independently publishable units: projects carrying a `PackageId` or
`nuspec`, contract projects named `*.Contracts*`, and — where a repo packs by convention
rather than per-project markers (`Directory.Build.props`, an SDK default `AssemblyName`) —
every project sharing that convention. Emit these as `repo:path` nodes whenever a repo holds
more than one, so edges can point at the specific contract.

Take the project list from `git ls-files`, so a directory holding only `bin/` and `obj/`
leftovers stays out. Names on disk outlive the projects that made them.

### 4. Derive edges
Derive from disk, not from the previous index. Reading the existing rows first anchors you to
them, and an edge that was wrong last run stays wrong; the previous file is the thing you
compare against in step 5, after you have your own answer.

Each row is `from → to`, a kind, an evidence path, and the key inside that file, in the column
order the template gives. Either end may be a repo, a `repo:path` component, or an
`external:<system>` node — a package producer depending on another producer is an ordinary
row, not a special case.

| Kind | Derive from | Evidence | Key |
|---|---|---|---|
| `nuget` | `PackageReference` whose id matches a component published anywhere in this root | the `.csproj` | package id |
| `event` | config keys naming a topic, queue, or subscription | the `appsettings*.json` | the config key |
| `rest` | config keys naming a downstream API | the `appsettings*.json` | the config key |
| `bundled` | build-tool proxy or output paths wiring one repo's assets into another's host | `vite.config.*`, `webpack.config.*`, host `.csproj` | the proxy target or output path |
| `nuget`/`rest` (node) | `dependencies` matching a sibling package; API base-URL env vars | `package.json`, `.env*` | dependency or var name |

Config keys sit at no fixed depth. Walk the whole config tree for keys shaped like a topic,
subscription, queue, or API base URL, whatever section names they nest under — one repo's
`ServiceBus:Edge` is another's `EdgeServiceBus`, and a recipe anchored to one shape finds
edges in one repo and misses them in the next.

Publisher/subscriber direction for `event` rows: a repo declaring a topic without a
subscription publishes; one declaring a subscription consumes. When the other end has no
repo in this root, the row still stands with `external:<system>` on that side.

Production references only: a package referenced solely by a test project is a testing
choice, not a dependency that constrains publish or deploy order.

A reference that resolves to no local component is an `external:<name>` row, not a dropped
one — a package pulled from a feed and a package built next door are the same dependency to
whoever has to change it.

**One row per node pair.** A dozen projects in one repo referencing the same package is
one row, citing a representative evidence path — per-project rows multiply without adding
information.

When a stack appears that these recipes don't cover — terraform module sources, GitOps
manifests — record the repos under Domain Notes naming the stack, and leave the edges
undrawn rather than guessed.

### 5. Reconcile against the previous index
Compare what you derived with the existing file and report five sets:

- **new on disk** — added to derived regions
- **gone from disk** — removed from derived regions, and named in the report, since a repo
  folded into a monorepo leaves curated rows pointing at nothing
- **schema drift** — a fenced region whose columns differ from the template's. This alone
  obliges a rewrite: an index whose content is current but whose shape is old silently
  discards every recipe added since it was written
- **curated rows now orphaned** — a curated row naming a repo that no longer exists
- **curated prose contradicted by disk** — a curated claim that understates or misstates what
  you just derived, such as a list of consumers that is missing one

Both curated sets have a destination: the `<!-- index:derived:contradictions -->` region.
Write each finding there, quoting the curated line and stating what disk shows.

Everything you have to say about curated prose belongs in that region — the correction itself,
and any note pointing a reader towards it. A curated region comes out of a refresh exactly as
it went in, byte for byte, and the contradictions table is where a proposed change waits for
the user to approve it.

### 6. Write
`templates/REPO-INDEX.template.md` defines the schema on **every** run, creating and refreshing
alike.

- **No `REPO-INDEX.md` yet** — copy the template, fill the derived regions.
- **It already exists** — copy it to `REPO-INDEX.md.bak` first; the root is rarely version
  controlled, so that backup is the only way back. Then rewrite each fenced derived region
  from what you derived this run. Where the file's columns differ from the template's,
  migrate the table to the template's shape and populate the new columns — the file's header
  is the older schema, not the target. A rewrite that lands byte-identical is a valid
  outcome; skipping the rewrite because you expect that outcome is not, because it is exactly
  how schema drift survives.

Stamp `Last derived` as `YYYY-MM-DD HH:MM`, so a run that found nothing to change stays
distinguishable from a run that skipped the work.

Then verify mechanically: every evidence path in the file resolves from the root. Report any
that don't rather than asserting they do.

### 7. Point the root's instruction file at the index
`AGENTS.md` is the harness-agnostic home for this pointer, so prefer it when it exists and
create it when neither file does. A `CLAUDE.md` that only contains `@AGENTS.md` is already
pointed at the index through that include — leave it as it is. Where `CLAUDE.md` carries
content of its own and no `AGENTS.md` exists, put the section there.

The section names the index and the refresh trigger:

```markdown
## Repo Topology
Repos, components, dependency edges, ownership, and change patterns: @REPO-INDEX.md
Refresh with the `create-repo-index` skill after a repo is added, moved, removed,
or folded into a monorepo.
```

A pointer, never a copy — inlining the tables recreates the duplication the index exists to
retire. Insert or update that one section and carry the rest of the file forward verbatim,
the same discipline the derived fences get.

### 8. Report
Counts per derived region, the five reconciliation sets, external nodes introduced, evidence
paths that failed to resolve, and any curated section still empty — an empty Change Patterns
table is the difference between an index that answers "which repos does this feature touch"
and one that doesn't.

List directories the enumeration rules classified as neither repo nor skip, so the user can
say where they belong instead of them vanishing from the report.

</process>

<gotchas>
- **Repos disappear mid-session.** A scan can list a repo that a later scan doesn't; folding
  a standalone repo into a monorepo is the common cause. Reconcile (step 5) every run
  instead of trusting the previous list.
- **The root's instruction file usually already holds a topology table.** Make the index
  canonical, leave the pointer from step 7, and migrate that prose into the curated sections
  rather than deriving alongside it.
- **The most consequential edges often have no local producer.** A third-party or
  other-team system publishing events you consume shapes ordering as much as any internal
  edge; `external:<system>` keeps it visible.
- **Some edges live in no config file.** An SPA served from an API host, or proxied in dev,
  is a real dependency whose only trace is bundler config or a host project's output paths.
- **The root is usually not a git repo**, so `REPO-INDEX.md` is untracked and unignored. Nothing
  to add to `.gitignore`; nothing gives you history either, which is why step 6 writes a
  backup.
- **`<root>/_workspaces/<repo>/<branch>` is the same repo, not another one.** Counting
  checkouts inflates the repo list and produces duplicate edges.
- **A repo's directory name and its package/service name differ.** Match `nuget` edges on
  package id, and keep the directory name as the node key.
- **Curated rows outlive their subject.** When a repo moves into a monorepo, its ownership
  and change-pattern rows still read as valid. Only the reconciliation report catches this.
- **Two indexes can coexist.** A project may already keep its own index for another consumer;
  leave it alone and neither read from nor write to it unless the user says to.
- **Deriving into the file's existing columns silently freezes the schema.** A refresh that
  copies the old header keeps producing the old shape forever, and every recipe added since
  goes unused. The template's columns win on every run.
- **A helpful note appended to curated prose is still a write to it.** Signposts, dated
  refresh markers, and "see the contradictions table" pointers all belong in the
  contradictions region; the curated text stays byte-identical.
</gotchas>

<success_criteria>
- `REPO-INDEX.md` exists at the root, derived regions fenced and populated
- Derived tables carry the template's current columns, migrated if the file predated them
- Refreshing an existing index leaves `REPO-INDEX.md.bak` beside it
- `Last derived` shows this run's date and time as `YYYY-MM-DD HH:MM`
- Every derived edge row carries a key and an evidence path **checked** to resolve, not
  assumed to
- Edges whose far end has no local repo appear with an `external:<system>` node
- Curated prose present in the previous version is present verbatim in the new one
- The root's instruction file points at the index, without copying it
- Report names new, gone, and orphaned entries
- No worktree, workspace, or pipeline IDs stored anywhere in the file
</success_criteria>
