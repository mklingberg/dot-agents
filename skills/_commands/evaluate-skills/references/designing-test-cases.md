# Designing test cases

A test case = `prompt` + `expected_output` + optional `files` + (later) `assertions`.

## Sourcing prompts

**Refuse to invent prompts from generic knowledge.** Sources, in order of preference:

1. Real prompts the user has actually sent that should have triggered this skill.
2. Prompts the user *plans* to send.
3. Prompts extracted from the skill's own description triggers (`Triggers: 'X', 'Y'`).
4. As last resort: ask the user to write 2–3.

If none of these are available, stop and ask. A made-up prompt that "feels reasonable" produces a test that confirms nothing.

## Variation rules

For 2–3 cases, cover:

- **Phrasing range.** One casual ("hey can you clean up this csv"), one precise ("Parse the CSV at data/input.csv, drop rows where col B is null, write to data/output.csv").
- **Specificity range.** One with full context (paths, columns, intent), one with sparse context (real users underspecify).
- **At least one edge case.** Malformed input, ambiguous request, boundary condition the skill's instructions might not cover.

## Anti-patterns

- "Process this data" — too vague, tests nothing.
- Three near-identical prompts that vary only in surface wording — measures one path, not the skill's range.
- Prompts the skill clearly *won't* trigger on (out-of-scope) — wastes a slot. Pick prompts that should trigger the skill.
- Prompts that depend on private state the agent can't access (live API, user's actual filesystem) — unreproducible.

## `expected_output` field

Free-form prose describing what success looks like for a human. Not graded directly; it's a north star for grading and for human review.

Good: "A bar chart image showing top 3 months by revenue with labeled axes and values."
Bad: "Correct output." / "A good answer."

## Input files

Place under `<skill>/evals/files/`. Reference relatively in `evals.json` (`evals/files/sales_2025.csv`). Keep small (KBs, not MBs) — they get re-read on every run.
