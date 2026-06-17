#!/usr/bin/env bash
# Scaffold a single-pass eval workspace from a skill's evals/evals.json.
#
# Usage: init-workspace.sh <skill-path> <workspace-path>
#
# Creates:
#   <workspace-path>/
#     eval-<id>/
#       with_skill/outputs/
#       without_skill/outputs/
#
# Pre-creates empty timing.json and grading.json placeholders so missing files
# never confuse the aggregator.

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <skill-path> <workspace-path>" >&2
  exit 2
fi

SKILL_PATH="$1"
WORKSPACE="$2"
EVALS_JSON="$SKILL_PATH/evals/evals.json"

if [[ ! -f "$EVALS_JSON" ]]; then
  echo "ERROR: $EVALS_JSON not found" >&2
  exit 1
fi

# Extract eval ids without depending on jq. Falls back to python3.
IDS=$(python3 -c '
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
for e in data.get("evals", []):
    eid = e.get("id")
    if not eid:
        sys.stderr.write("ERROR: eval missing id\n"); sys.exit(1)
    print(eid)
' "$EVALS_JSON")

mkdir -p "$WORKSPACE"

PLACEHOLDER_TIMING='{"total_tokens": null, "duration_ms": null}'
PLACEHOLDER_GRADING='{"assertion_results": [], "summary": {"passed": 0, "failed": 0, "total": 0, "pass_rate": 0.0}}'

while IFS= read -r id; do
  [[ -z "$id" ]] && continue
  for cfg in with_skill without_skill; do
    dir="$WORKSPACE/eval-$id/$cfg"
    mkdir -p "$dir/outputs"
    [[ -f "$dir/timing.json" ]]  || echo "$PLACEHOLDER_TIMING"  > "$dir/timing.json"
    [[ -f "$dir/grading.json" ]] || echo "$PLACEHOLDER_GRADING" > "$dir/grading.json"
  done
  echo "scaffolded eval-$id"
done <<< "$IDS"

echo "workspace ready: $WORKSPACE"
