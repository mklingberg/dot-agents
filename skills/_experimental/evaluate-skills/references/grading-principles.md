# Grading principles

Grading = walking each assertion against the actual outputs and recording PASS/FAIL with **concrete evidence**.

## Hard rules

1. **Concrete evidence required for PASS.** Quote the output, cite a file, give a measurement. "Looks correct" is not evidence.
2. **No benefit of the doubt.** If the assertion says "includes a summary" and there's a section labelled "Summary" with one vague sentence — that's FAIL. Label without substance fails.
3. **One assertion = one outcome.** Don't combine assertions during grading. If an assertion is actually two things, FAIL it and split it for the next iteration.
4. **Mechanical checks in code, not prose.** "File exists" / "valid JSON" / "exactly N rows" → run a shell or python one-liner. LLM judgment on mechanical things is unreliable.

## Evidence examples

| Assertion | Good evidence | Bad evidence |
|---|---|---|
| "Includes a bar chart" | "Found `chart.png` (45KB) in outputs/" | "Yes, there's a chart" |
| "Both axes labeled" | "Y-axis: 'Revenue ($)'; X-axis has no label → FAIL" | "Axes look fine" |
| "Output is valid JSON" | `python3 -c 'import json; json.load(...)'` exited 0 | "Looks like JSON" |
| "Mentions revenue in title" | Title reads: 'Top 3 Months by Revenue'" | "Title is about revenue" |

## `grading.json` shape

```json
{
  "assertion_results": [
    {"text": "<verbatim assertion>", "passed": true|false, "evidence": "..."}
  ],
  "summary": {"passed": N, "failed": N, "total": N, "pass_rate": 0.0}
}
```

`pass_rate` = `passed / total`, rounded to 2 decimals.

## Grading both configurations

Use **the exact same assertions** for `with_skill/` and `without_skill/`. Different assertions per config invalidates the comparison. If an assertion only makes sense for one config, it shouldn't be in `evals.json`.

## After grading

Note assertions that:
- Pass with-skill, fail without-skill → **skill value** (highlight in report).
- Fail with-skill, pass without-skill → **regression** (highlight loudly).
- Pass both → **no signal** (candidate for removal).
- Fail both → **broken assertion or impossible task** (fix or drop).
