# Git Integration Reference

## Core Principle

**Commit outcomes, not process. `.planning/` is not an outcome.**

Planning artifacts are scratch space that exists to get the work built. Once the code
ships and is verified, nobody reads them again. They are never committed.

The git log should read like a changelog of what shipped, not a diary of planning
activity.

## Ignore `.planning/` before writing into it

The moment `.planning/` is created, make sure it is ignored:

```bash
grep -qxF '.planning/' .gitignore 2>/dev/null || echo '.planning/' >> .gitignore
```

Do this in the same action that creates the folder — never leave it
untracked-but-unignored, where it will show up in `git status` and eventually get swept
into someone's `git add .`.

If the repo has no `.gitignore`, create one containing `.planning/`. The `.gitignore`
change itself **is** committed, as a normal repo-hygiene change.

## Commit points

| Event | Commit? | What |
|---|---|---|
| `.planning/` created | YES | the `.gitignore` entry only |
| BRIEF + ROADMAP created | NO | scratch |
| PLAN.md created | NO | scratch |
| SUMMARY.md written | NO | scratch |
| Handoff created | NO | scratch |
| **Phase completed** | YES | **code only** |
| Decision worth keeping | YES | the ADR under `docs/adr/` |

Never `git add .planning/`. Not at initialization, not at phase completion, not at
handoff. If a plan's reasoning deserves to survive, that is what an ADR is for — write
it, commit it, and let the plan die with the branch.

## Commit message formats

### Phase completion

```
feat([domain]): [one-liner from SUMMARY.md]

- [Key accomplishment 1]
- [Key accomplishment 2]
- [Key accomplishment 3]

[If issues encountered:]
Note: [issue and resolution]
```

Use `fix([domain])` for bug-fix phases.

What to commit:
```bash
git add src/          # the code, explicitly — never `git add .`
git commit
```

Commit in small logical groups, one topic per commit. A phase that touched three
unrelated areas is three commits, not one.

### ADR

```
docs(adr): [decision title]
```

## Example clean git log

```
a7f2d1 feat(checkout): Stripe payments with webhook verification
b3e9c4 docs(adr): use jose over jsonwebtoken for edge runtime
c8a1b2 feat(products): catalog with search, filters, and pagination
d5c3d7 feat(auth): JWT with refresh rotation using jose
e2f4a8 chore: ignore .planning/
```

Note what is absent: no `docs: initialize`, no `wip:` handoff commits, no planning
churn. The history describes the product, not the process that produced it.

## What never gets committed

- Anything under `.planning/` — plans, summaries, briefs, roadmaps, handoffs
- "Fixed typo in roadmap" style churn

If you find `.planning/` staged, unstage it and add the `.gitignore` entry:
```bash
git restore --staged .planning/
```
