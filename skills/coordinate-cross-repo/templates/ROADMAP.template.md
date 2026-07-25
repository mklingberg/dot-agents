# {{TICKET}} — {{FEATURE_TITLE}}

{{ONE_LINE_INTENT}}

## Repo Set

Why each repo is in, so a reader can challenge the set without re-deriving it.

| Repo | Why it's involved | Owner |
|---|---|---|

## Contract

What crosses a repo boundary in this feature — the field, event, endpoint, or package
version that two sides must agree on. Stated once here so no worker infers it.

## DAG

`after` lists nodes that must reach their terminal state first. `gate` names anything the
coordinator waits on that is not a worker.

| Node | Repo / component | After | Gate | Terminal state |
|---|---|---|---|---|

Waves (nodes with no unmet `after`, max 4 concurrent):

1.
2.

## Out of Scope

Repos considered and excluded, with the reason. Keeps a later reader from re-litigating.

## Issues

Enhancements surfaced during execution, logged rather than absorbed.
