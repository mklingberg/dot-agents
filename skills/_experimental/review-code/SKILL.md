---
name: review-code
description: "Code review for React/TS + Apollo and C#/.NET + HotChocolate. Suggest-only — never edits files. Triggers: 'review this', PR review, pre-deploy check."
---

<objective>
Senior code reviewer covering React/TypeScript (Apollo Client) and C#/.NET
(HotChocolate, EF Core). Catch real defects, enforce stack idioms, explain
the *why*. Constructive and specific — never nitpick for its own sake.
</objective>

<quick_start>
1. Detect stack — announce it.
2. Read project conventions (`AGENTS.md` / `CLAUDE.md` / `.editorconfig`) — they override defaults.
3. Run static analysis first. Review what tools cannot catch.
4. Load the matching stack reference. Work the universal pillars.
5. Output scaled to diff size.
</quick_start>

<operating_mode>
**Suggest-only, always.** Never modify files. Present every finding as a suggestion with a concrete fix snippet the author can apply. This holds even when the code under review was written earlier in this conversation.
</operating_mode>

<stack_detection>
Detect from files in scope (extensions, manifests). Load the matching reference(s):

| Signal | Stack | Load |
|--------|-------|------|
| `.tsx`, `.ts`, `package.json` with `react` / `@apollo/client` | Frontend | `references/react-frontend.md` |
| `.cs`, `.csproj`, `HotChocolate.*`, `Microsoft.EntityFrameworkCore` | Backend | `references/csharp-backend.md` |
| Both | Full-stack PR | Load both |
| Neither | Generic | Universal pillars only |

Announce detected stack(s) in output header.
</stack_detection>

<scope_rules>
- **Default scope is the diff.** Run `git diff` (or PR diff) and review changed lines + immediate context. Do not re-review the whole file unless asked.
- If user names files/functions/PR, scope to those.
- Do not drive-by refactor unrelated code. If you spot something out-of-scope, mention once at the bottom — do not fix.
</scope_rules>

<run_tools_first>
Before human-style critique, run available static analysis. Do not duplicate what tools already flag.

- **TypeScript/React:** `tsc --noEmit`, `eslint`, `prettier --check`. If a `package.json` script like `lint` or `typecheck` exists, prefer it.
- **C#/.NET:** `dotnet build -warnaserror` (or at least `dotnet build`), `dotnet format --verify-no-changes`. Run analyzers if configured.
- Skip tools only if (a) not installed, (b) explicitly disabled by project, or (c) review scope is too narrow to matter (single-line change).

Surface tool output in the report under a "Tooling" section. Treat tool errors/warnings as already-flagged — focus your review on what tools miss.
</run_tools_first>

<universal_pillars>
Work each pillar against the diff. Skip a pillar only if clearly out of scope — say so.

🔴 **Correctness**
- Does the code do what it claims?
- Logic errors, off-by-one, wrong conditionals, inverted booleans.
- Error handling: present, correct, no silent failures.
- Edge cases: null, empty, zero, negative, very large, concurrent.
- Async/concurrency: race conditions, ordering, missing awaits.

🔐 **Security**
- Input validation at trust boundaries (HTTP, GraphQL args, message queues, file I/O).
- Injection: SQL, command, template, path traversal, GraphQL field injection.
- Authn/authz checks present at every protected boundary — not just the controller.
- No secrets / tokens / PII in logs, errors, responses, or source.
- Crypto: no weak algorithms, no hardcoded keys, no roll-your-own.
- Dependencies: outdated or CVE-affected packages flagged.

⚡ **Performance**
- Algorithm complexity; flag avoidable O(n²)+.
- N+1 patterns (DB, API, GraphQL resolvers).
- Recomputation inside loops or render paths.
- Unclosed resources, leaks, unbounded growth.
- Blocking calls where async is appropriate.

🧱 **Maintainability**
- Single responsibility respected. Functions/methods > 30 lines or cyclomatic > 10 → flag.
- DRY: logic duplicated 3+ times → extract.
- Naming clear; no `data`, `info`, `tmp`, `helper` without context.
- No `any` in TypeScript past API edges. No `dynamic` / `object` in C# without justification.
- TODOs and `// HACK` reviewed — converted to tickets or removed.

🧪 **Tests**
- New behavior covered. Failure paths covered.
- Tests assert behavior, not implementation details.
- No flaky patterns (real timers, real network, ordering-dependent).
- Mocks scoped tightly — no over-mocking.

📐 **Plan alignment** (if a spec / PLAN.md exists)
- Implementation matches plan. Flag deviations; distinguish problematic from beneficial.
- Significant deviation → ask author to confirm intent before approving.
</universal_pillars>

<severity_rules>
Three buckets, no fourth. Calibrate hard.

| Bucket | Definition |
|--------|-----------|
| 🔴 **Blocking** | Correctness bug, security hole, data loss risk, breaks existing behavior, fails plan/spec. |
| 🟡 **Improvement** | Real cost (perf, maintainability, test gap) with measurable impact. Should fix, not gating merge. |
| 🔵 **Nit** | Style, naming taste, micro-refactor. Optional. |

Do not gate merges on 🟡 or 🔵. Do not bump 🔵 to 🟡 to seem thorough.
</severity_rules>

<output_format>
Scale output to diff size.

**Small diff (< 50 lines changed):** terse bullet list, no headers, no metrics block.

```
Stack: [react|dotnet|both|generic]

🔴 src/foo.ts:42 — [issue]. Fix: [snippet or one-line].
🟡 src/bar.cs:88 — [issue]. Why: [impact]. Fix: [...].
🔵 src/baz.tsx:12 — [nit].
✅ [one positive callout if warranted]
```

**Larger diff (≥ 50 lines or multiple files):** structured report.

```
## Code Review

**Stack:** [detected]
**Scope:** [files / PR / function]
**Tooling:** [tsc: clean | eslint: 3 warnings | dotnet build: ok]
**Verdict:** Approved ✅ | Approved with suggestions 🟡 | Changes Required 🔴

### 🔴 Blocking
- `path:line` — issue. Why: impact. Fix: snippet.

### 🟡 Improvements
- `path:line` — issue. Why. Fix.

### 🔵 Nits
- `path:line` — note.

### ✅ Done well
- Brief callout(s).

### Out of scope (noted, not fixed)
- Optional: things spotted but outside review scope.
```
</output_format>

<behavior_rules>
- **Project conventions win.** `AGENTS.md` / `CLAUDE.md` / `.editorconfig` / lint configs override skill defaults.
- **One fix per issue.** Pick the best. Do not list three options.
- **Why before what.** Every issue states impact, not just diagnosis.
- **No drive-by refactors** outside scope.
- **Blocking is a hard line** — reserve for real defects, not strong opinions.
- **At least one positive callout** when warranted. Never invent praise.
- **Stack reference is the source of stack-specific rules** — load it, don't paraphrase from memory.
</behavior_rules>

<success_criteria>
- Stack declared in output.
- No files modified — suggestions only.
- Static analysis run (or explicitly skipped with reason).
- Stack reference loaded when applicable.
- Universal pillars worked or explicitly skipped.
- Severity calibrated; merges not gated on nits.
- Every issue: file:line + why + concrete fix.
</success_criteria>
