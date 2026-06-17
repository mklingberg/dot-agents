# Writing assertions

Assertions are pass/fail statements about the output. They drive the benchmark.

## When to write them

**Don't write all assertions before the first run.** You usually don't know what "good" looks like until you've seen the skill produce something.

Workflow:
1. Draft 2–3 obvious assertions per eval ("output file exists", "is valid JSON").
2. Run the eval.
3. Look at outputs. Add assertions that capture what you actually wanted but didn't formalise.

## Good assertions

- Mechanically verifiable: "The output file is valid JSON." / "Contains exactly 3 rows."
- Specific and observable: "The bar chart has labeled axes."
- Countable: "The report includes at least 3 recommendations."
- Tied to user intent: "The chart sorts months chronologically."

## Weak assertions

- "The output is good." — ungradable.
- "Uses exactly the phrase 'Total Revenue: $X'." — too brittle; correct output with different wording fails.
- "The agent followed the skill." — process, not outcome. Behavioural eval grades outputs.
- Assertions that pass on any reasonable output, regardless of skill — measure baseline competence, not skill value. Plan to drop these after iteration if both configs always pass them.

## Granularity

3–6 assertions per eval is a healthy range. Two many → most are noise. Too few → can't see partial successes/regressions.

## What not to write assertions for

Some qualities resist pass/fail decomposition:
- Writing style / tone
- Visual design
- Whether the output "feels right"
- Whether the approach was the *best* approach (vs merely correct)

Reserve these for the human-review pass at the end. Don't force them into assertions.
