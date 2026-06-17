---
name: evaluate-skills
description: "Behavioral eval of a skill — run real prompts with/without it, grade outputs, report deltas. Triggers: 'evaluate this skill', 'test skill outputs', 'does my skill help', 'eval-driven'. For static structural review (YAML, description, gotchas), use create-agent-skills audit-skill workflow."
---

## What this skill does

Runs **single-pass behavioral evals** on an existing skill: takes test prompts, executes each one twice (once with the skill loaded, once without as a baseline), grades the outputs against assertions, and reports whether the skill is actually pulling its weight.

Output: a delta table — pass-rate / tokens / duration with vs without — plus per-assertion evidence and human-review notes.

**Scope boundary:** single iteration only. No `iteration-N+1` re-run loop. After this skill produces results, the user decides what to change in the target skill (likely via `create-agent-skills`) and may invoke this skill again.

**For purely structural critique** (frontmatter, description authoring, gotchas, ref-index hygiene) → use `create-agent-skills` `workflows/audit-skill.md` instead. Don't run behavioral eval just to flag a missing `<gotchas>` section.

## When to invoke

- "Evaluate this skill against real prompts"
- "Does the skill actually improve outputs?"
- "Test if my skill is worth the tokens"
- "Run an eval pass on `<skill>`"

If user is asking "is the YAML valid" / "is the description good" → redirect to `audit-skill`.

## Prerequisites — confirm before running

1. **Target skill path** (e.g. `~/.agents/skills/foo`).
2. **At least 2–3 test prompts** the user would actually type. If user has none, ask them to provide; *do not invent prompts from generic LLM knowledge* — see `references/designing-test-cases.md`.
3. **Input files** for prompts that reference data (CSV, etc.) — copy into `<skill>/evals/files/`.
4. **Workspace location** — default `<skill-parent>/<skill-name>-workspace/`.

If any prerequisite is missing, ask the user (group questions in one `ask_user_question` call).

## Process

### 1. Design `evals/evals.json`

If the target skill has no `evals/evals.json`, create one. Read `references/designing-test-cases.md` before drafting. Schema:

```json
{
  "skill_name": "<skill-name>",
  "evals": [
    {
      "id": "short-slug",
      "prompt": "realistic user message",
      "expected_output": "human-readable success description",
      "files": ["evals/files/example.csv"],
      "assertions": ["specific verifiable check 1", "..."]
    }
  ]
}
```

Assertions can be added *after* the first run if you don't yet know what "good" looks like — see `references/writing-assertions.md`. For a first pass, draft 3–5 assertions per eval; expect to revise.

### 2. Scaffold the workspace

Run the scaffolder script (creates the directory tree the rest of this skill expects):

```bash
bash scripts/init-workspace.sh <skill-path> <workspace-path>
```

Produces:
```
<skill-name>-workspace/
└── eval-<id>/
    ├── with_skill/{outputs/, timing.json, grading.json}
    └── without_skill/{outputs/, timing.json, grading.json}
```

### 3. Spawn runs

For each eval, spawn **two `general-purpose` subagents in parallel** (one per configuration). Each must use a **fresh context** (`inherit_context: false`) and run in background (`run_in_background: true`) per project policy in `~/.pi/agent/subagent-protocol.md`.

**With-skill prompt template:**
```
Read and follow the skill at: <absolute-skill-path>/SKILL.md

Then perform this task:
<verbatim user prompt>

Input files: <list>
Save all outputs to: <abs>/eval-<id>/with_skill/outputs/
Do not write anywhere else.
```

**Without-skill prompt template:**
```
Perform this task:
<verbatim user prompt>

Input files: <list>
Save all outputs to: <abs>/eval-<id>/without_skill/outputs/
Do not write anywhere else.
```

Do **not** include any reference to the skill in the without_skill prompt — that defeats the baseline.

When each subagent completes, capture `total_tokens` and `duration_ms` from the completion notification immediately and write them to the matching `timing.json`. These values are not persisted anywhere else.

### 4. Grade

For each `eval-<id>/{with_skill,without_skill}/outputs/`, evaluate every assertion and write `grading.json`:

```json
{
  "assertion_results": [
    {"text": "...", "passed": true, "evidence": "concrete quote/reference"}
  ],
  "summary": {"passed": N, "failed": N, "total": N, "pass_rate": 0.0}
}
```

Read `references/grading-principles.md` before grading. Key rule: **require concrete evidence for PASS**; quote or cite the output. Don't give the benefit of the doubt.

For mechanical checks (file exists, valid JSON, row count) prefer a small ad-hoc bash/python check over LLM judgment.

### 5. Aggregate

```bash
python3 scripts/aggregate-benchmark.py <workspace-path>
```

Writes `<workspace>/benchmark.json` with `with_skill` / `without_skill` / `delta` for `pass_rate`, `duration_ms`, `total_tokens`. Single-pass mode, so no stddev — raw numbers only.

### 6. Report to user

Present:
1. **Delta table** — pass_rate, tokens, duration: with vs without vs delta.
2. **Per-eval breakdown** — which assertions flipped (passed without, failed with → regression; failed without, passed with → skill value).
3. **Patterns** — assertions that pass/fail in both configs (candidates for removal/fixing — they don't measure skill value).
4. **Human-review notes** — for each eval, briefly review the actual outputs and call out anything assertions missed (technically correct but unhelpful, wrong approach, etc.). Empty note = output looked fine.
5. **Verdict** — is the skill earning its token cost? A skill that adds significant tokens for a small pass-rate delta may not be worth it.

Do **not** auto-edit the target skill. Iteration is the user's call.

<gotchas>
- **Without-skill run must not mention the skill.** Even hinting "this is a baseline for skill X" leaks intent into the agent's behavior.
- **Fresh context per run.** Use `inherit_context: false`. A subagent that inherits this conversation has already seen the skill — invalidates the baseline.
- **Capture timing immediately on completion.** `total_tokens`/`duration_ms` are only in the completion notification; they aren't persisted.
- **Assertions added before the first run are guesses.** Expect to revise after seeing outputs. Don't treat the first `evals.json` as final.
- **Vague prompts produce vague evals.** "Process this data" tests nothing. Real users mention paths, columns, context. Reject prompts that lack realistic specificity.
- **Single test case is not an eval.** Need ≥2–3 with varied phrasing/edge cases. One prompt only confirms one path works.
- **Assertions that pass in both configs measure nothing.** Flag them in the report; don't count them toward "skill value".
- **Mechanical checks in code, judgment checks via reading.** Don't ask an LLM "is this valid JSON" — `python3 -c 'import json; json.load(open(...))'` is more reliable.
- **This is single-pass.** Article's full flow has iteration-N dirs; we don't. If the user asks for re-runs after fixes, run the skill again — don't bolt on a loop.
- **Don't re-run if nothing changed.** If neither the skill nor evals.json changed, results are stale-but-valid; spawning again wastes tokens.
</gotchas>

<success_criteria>
- `evals/evals.json` exists with ≥2 cases, each with prompt, expected_output, assertions, and any files.
- Workspace contains `eval-<id>/{with_skill,without_skill}/{outputs,timing.json,grading.json}` for every eval.
- `benchmark.json` aggregates pass_rate / duration / tokens with deltas.
- Final report calls out: skill-value assertions (passed-with / failed-without), no-signal assertions (always-pass or always-fail in both), and timing/token cost.
- No edits made to the target skill — only evaluation artifacts written.
</success_criteria>

<reference_index>
| Read this | When |
|---|---|
| `references/designing-test-cases.md` | Drafting prompts for `evals.json`; user has no test cases yet |
| `references/writing-assertions.md` | Adding/revising assertions; first-run outputs in hand |
| `references/grading-principles.md` | About to fill in `grading.json` |
</reference_index>
