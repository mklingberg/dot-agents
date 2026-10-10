---
name: grilling
description: Grill the user relentlessly about a plan, decision, or idea. Use when the user wants to stress-test their thinking, or uses any 'grill' trigger phrases.
---

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled: the questions you can ask _now_ without guessing at answers you haven't heard yet. Ask the whole frontier in one round: number each question and give your recommended answer. Then wait for the user's answers before the next round.

A **pivot** question is one whose answer could redirect the plan or make other branches irrelevant ("what problem are we solving", "is this the right approach at all"). It is a prerequisite of everything it could prune, so ask pivots alone in their own round before the rest of the frontier.

Ask every question through the ask-user tool, so a round is one coherent prompt:

- Put the number in both header and question: header `Q3 Scope` (the header is limited to 16 chars), question `Q3 – …`.
- **Discrete** questions: the real choices, recommended option first with `(Recommended)` appended. The option description carries the trade-off.
- **Open-ended** questions: offer 2–4 plausible candidate answers as options, recommended first, and say in the question that the user can type their own. The tool's free-text row takes the answer.
- The tool caps questions per call. Split a larger round across consecutive calls.

If no ask-user tool is available, fall back to a text round formatted like so:

```
❓ **Q1** - **<question title>**: <question body, might be multiple paragraphs, including multiple choices>

➡️ <your recommended answer>

---

❓ **Q2** - **<question title>**: <question body, might be multiple paragraphs, including multiple choices>

➡️ <your recommended answer>
```

Each round the user answers reshapes the tree: settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another question still open in this round belongs to a _later_ round, not this one.

Finding _facts_ is your job, never the user's. When a frontier question needs a fact from the environment (filesystem, tools, etc.), dispatch a sub-agent to find it; don't ask the user for anything you could look up yourself. Don't block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent to report; ask the rest of the frontier now. The _decisions_ are the user's: put each to them and wait.

Free-text answers can contradict earlier answers without either of you noticing. Before each round, check new answers against the settled ones and raise any conflict as a question.

The session is done when the frontier is empty: every branch of the design tree visited, nothing left silently assumed. Close with a recap of every settled decision that names any unresolved conflict. Do not act on it until the user confirms you have reached a shared understanding.
