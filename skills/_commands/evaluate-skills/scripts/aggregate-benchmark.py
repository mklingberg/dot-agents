#!/usr/bin/env python3
"""Aggregate single-pass eval results into <workspace>/benchmark.json.

Usage: aggregate-benchmark.py <workspace-path>

Reads every eval-*/{with_skill,without_skill}/{timing.json,grading.json}
and computes:
  - per-config means for pass_rate, duration_ms, total_tokens
  - delta (with - without) for each
  - per-eval breakdown
  - flagged assertions: skill_value / regression / no_signal / always_fail

No stddev: single-pass mode, one run per config per eval. Add multi-run
support later if needed.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from statistics import mean


def load_json(path: Path):
    if not path.is_file():
        return None
    try:
        return json.loads(path.read_text())
    except json.JSONDecodeError as e:
        print(f"WARN: invalid JSON in {path}: {e}", file=sys.stderr)
        return None


def avg(xs):
    xs = [x for x in xs if isinstance(x, (int, float))]
    return round(mean(xs), 4) if xs else None


def delta(a, b):
    if a is None or b is None:
        return None
    return round(a - b, 4)


def classify_assertions(with_results, without_results):
    """Pair assertions by text. Returns categorised dict."""
    cats = {"skill_value": [], "regression": [], "no_signal": [], "always_fail": []}
    by_text = {}
    for r in with_results or []:
        by_text.setdefault(r["text"], {})["with"] = r["passed"]
    for r in without_results or []:
        by_text.setdefault(r["text"], {})["without"] = r["passed"]
    for text, p in by_text.items():
        w = p.get("with")
        wo = p.get("without")
        if w is True and wo is False:
            cats["skill_value"].append(text)
        elif w is False and wo is True:
            cats["regression"].append(text)
        elif w is True and wo is True:
            cats["no_signal"].append(text)
        elif w is False and wo is False:
            cats["always_fail"].append(text)
    return cats


def main(argv):
    if len(argv) != 2:
        print("Usage: aggregate-benchmark.py <workspace-path>", file=sys.stderr)
        return 2
    ws = Path(argv[1])
    if not ws.is_dir():
        print(f"ERROR: {ws} not a directory", file=sys.stderr)
        return 1

    eval_dirs = sorted(p for p in ws.iterdir() if p.is_dir() and p.name.startswith("eval-"))
    if not eval_dirs:
        print(f"ERROR: no eval-* dirs in {ws}", file=sys.stderr)
        return 1

    per_eval = []
    with_pr, without_pr = [], []
    with_dur, without_dur = [], []
    with_tok, without_tok = [], []

    for ed in eval_dirs:
        eid = ed.name[len("eval-"):]
        wt = load_json(ed / "with_skill" / "timing.json") or {}
        wg = load_json(ed / "with_skill" / "grading.json") or {}
        ot = load_json(ed / "without_skill" / "timing.json") or {}
        og = load_json(ed / "without_skill" / "grading.json") or {}

        wpr = (wg.get("summary") or {}).get("pass_rate")
        opr = (og.get("summary") or {}).get("pass_rate")
        wdr = wt.get("duration_ms")
        odr = ot.get("duration_ms")
        wtk = wt.get("total_tokens")
        otk = ot.get("total_tokens")

        if wpr is not None:  with_pr.append(wpr)
        if opr is not None:  without_pr.append(opr)
        if wdr is not None:  with_dur.append(wdr)
        if odr is not None:  without_dur.append(odr)
        if wtk is not None:  with_tok.append(wtk)
        if otk is not None:  without_tok.append(otk)

        per_eval.append({
            "id": eid,
            "with_skill":    {"pass_rate": wpr, "duration_ms": wdr, "total_tokens": wtk},
            "without_skill": {"pass_rate": opr, "duration_ms": odr, "total_tokens": otk},
            "delta": {
                "pass_rate":    delta(wpr, opr),
                "duration_ms":  delta(wdr, odr),
                "total_tokens": delta(wtk, otk),
            },
            "assertions": classify_assertions(
                wg.get("assertion_results"),
                og.get("assertion_results"),
            ),
        })

    benchmark = {
        "with_skill": {
            "pass_rate":    avg(with_pr),
            "duration_ms":  avg(with_dur),
            "total_tokens": avg(with_tok),
        },
        "without_skill": {
            "pass_rate":    avg(without_pr),
            "duration_ms":  avg(without_dur),
            "total_tokens": avg(without_tok),
        },
        "delta": {
            "pass_rate":    delta(avg(with_pr),    avg(without_pr)),
            "duration_ms":  delta(avg(with_dur),   avg(without_dur)),
            "total_tokens": delta(avg(with_tok),   avg(without_tok)),
        },
        "per_eval": per_eval,
    }

    out = ws / "benchmark.json"
    out.write_text(json.dumps(benchmark, indent=2))
    print(f"wrote {out}")
    print(json.dumps(benchmark["delta"], indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
