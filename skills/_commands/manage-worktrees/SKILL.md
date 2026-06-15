---
name: manage-worktrees
description: "Manage git worktrees for parallel branch work. Triggers: 'create worktree', 'work on multiple branches', bare-repo setup."
disable-model-invocation: true
---

<objective>
Create, manage, and clean up git worktrees for parallel branch development. Covers standard worktree operations, the bare-repo pattern, and worktree-aware workflows like hotfixes, code review, and CI parallelism.
</objective>

<quick_start>
```bash
# Create worktree for existing branch
git worktree add ../feature-auth feature/auth

# Create worktree with new branch based on main
git worktree add -b feature/login ../login main

# List all worktrees
git worktree list

# Remove when done
git worktree remove ../feature-auth
```
</quick_start>

<essential_knowledge>
**What's shared vs. per-worktree:**

| Shared (all worktrees) | Per-worktree |
|---|---|
| Object database | HEAD |
| All refs (branches, tags) | Index (staging area) |
| Config (`.git/config`) | Working directory files |
| Hooks | `refs/bisect/*`, `refs/worktree/*` |
| `refs/stash` (stash list) | |

**Critical constraints:**
- You **cannot** check out the same branch in two worktrees. Use `--detach` if you need the same commit in multiple worktrees.
- Stash is **global** — a stash in one worktree is visible in all others. Worktrees eliminate the need for stash; just leave work in place.
- Hooks are shared. If a hook uses relative paths, it may break in linked worktrees. Use `git rev-parse --show-toplevel` in hooks.
- In linked worktrees, `.git` is a **file** (not a directory) containing a `gitdir:` pointer. Tools that assume `.git` is a directory may break.
</essential_knowledge>

<commands>
**`git worktree add <path> [<commit-ish>]`**
```bash
# Existing branch
git worktree add ../hotfix main

# New branch from a base
git worktree add -b feature/login ../login main

# Detached HEAD (inspect a tag/commit without branch conflict)
git worktree add --detach ../investigate v2.0.0

# Without checkout (for sparse-checkout setup)
git worktree add --no-checkout ../sparse-work some-branch

# Create and lock atomically (for removable/network media)
git worktree add --lock --reason "on USB drive" ../portable feature-x
```

When `<commit-ish>` is omitted, git infers a branch name from the path's last component. If `worktree.guessRemote` is true, it looks for a matching remote-tracking branch.

**`git worktree list`**
```bash
git worktree list              # Human-readable
git worktree list --verbose    # Includes lock/prunable reasons
git worktree list --porcelain  # Machine-parseable
```

**`git worktree remove <worktree>`**
```bash
git worktree remove ../hotfix          # Fails if dirty
git worktree remove --force ../hotfix  # Remove even if dirty (loses uncommitted work)
```

**`git worktree move <worktree> <new-path>`**
```bash
git worktree move ../old-path ../new-path
```
Cannot move the main worktree. Cannot move worktrees with submodules.

**`git worktree lock/unlock`**
```bash
git worktree lock --reason "on NFS mount" ../remote-wt
git worktree unlock ../remote-wt
```
Prevents pruning/moving/deletion. Use for worktrees on removable or network media.

**`git worktree prune`**
```bash
git worktree prune              # Remove stale entries
git worktree prune --dry-run    # Preview
git worktree prune --verbose    # Report removals
```
Cleans up admin data for worktrees that no longer exist on disk. Also runs during `git gc`.

**`git worktree repair [<path>...]`**
```bash
git worktree repair                              # Fix after main worktree was moved
git worktree repair /new/path/to/linked-worktree # Fix after linked worktree was moved
```
Fixes broken `gitdir:` pointers after manual moves. Always use `git worktree move` instead of `mv` to avoid needing this.
</commands>

<workflows>
**Hotfix while feature work is in progress:**
```bash
git worktree add -b emergency-fix ../emergency main
cd ../emergency
# ... make fix, test, commit, push ...
cd -
git worktree remove ../emergency
```

**Code review in separate worktree:**
```bash
git fetch origin pull/42/head:pr-42
git worktree add ../review-pr-42 pr-42
# Open in separate editor, run tests
git worktree remove ../review-pr-42
git branch -d pr-42
```

**Compare behavior across versions:**
```bash
git worktree add --detach ../version-a v1.0
git worktree add --detach ../version-b v2.0
# Run benchmarks or tests side by side
```
</workflows>

<bare_repo_pattern>
The "clean" setup — a bare clone as the central store with branches as worktree directories:

```bash
# Initial setup
mkdir my-project && cd my-project
git clone --bare git@github.com:user/repo.git .bare
echo "gitdir: ./.bare" > .git

# CRITICAL: bare clone doesn't set fetch refspec
git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
git fetch origin

# Create worktrees
git worktree add main main
git worktree add develop develop
git worktree add feature/auth feature/auth
```

**Result:**
```
my-project/
  .bare/              # bare repository (all git data)
  .git                # file: "gitdir: ./.bare"
  main/               # worktree: main branch
  develop/            # worktree: develop branch
  feature/auth/       # worktree: feature branch
```

**Organized variant with namespaces:**
```
my-project/
  .bare/
  .git
  features/
    auth/             # git worktree add features/auth feature/auth
    payments/         # git worktree add features/payments feature/payments
  releases/
    v2.0/             # git worktree add releases/v2.0 release/2.0
  hotfixes/
    critical/         # git worktree add hotfixes/critical hotfix/critical
```
</bare_repo_pattern>

<advanced>
**Per-worktree configuration:**
```bash
git config extensions.worktreeConfig true
# Then per-worktree settings via:
git config --worktree core.hooksPath /path/to/hooks
git config --worktree core.sparseCheckout true
```

**Sparse checkout + worktrees (monorepo):**
```bash
git worktree add --no-checkout ../frontend-only feature/ui
cd ../frontend-only
git sparse-checkout init --cone
git sparse-checkout set frontend/ shared/
git checkout feature/ui
```

**Per-worktree hook isolation:**
```bash
git config extensions.worktreeConfig true
cd ../hotfix && git config --worktree core.hooksPath /path/to/strict-hooks
cd ../experiment && git config --worktree core.hooksPath /dev/null
```
</advanced>

<pitfalls>
- **Manual moves break links** — always use `git worktree move`, never `mv`. If you already did, run `git worktree repair`.
- **Submodules are experimental** — run `git submodule update --init --recursive` in each new worktree. `move` and `remove` require `--force` with submodules.
- **Shared config surprises** — changes to `.git/config` affect all worktrees. Use `extensions.worktreeConfig` + `--worktree` flag for per-worktree settings.
- **Stash leaks** — never rely on stash when using worktrees. It's shared globally.
- **Forgotten worktrees** — run `git worktree list` and `git worktree prune` periodically to avoid stale entries.
- **Relative paths** — by default worktree links use absolute paths. Set `worktree.useRelativePaths = true` (Git 2.40+) for portable setups, but this is incompatible with older Git versions.
</pitfalls>

<success_criteria>
Worktree operations are successful when:

- Worktrees are created with descriptive directory names
- Each worktree checks out a unique branch (no conflicts)
- Cleanup is performed promptly — `remove` when done, `prune` periodically
- The bare-repo pattern includes the fetch refspec fix
- Submodule worktrees use `--force` flags where needed
- No stash usage across worktrees
</success_criteria>
