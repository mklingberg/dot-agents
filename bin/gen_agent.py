#!/usr/bin/env python3
"""Transform a Pi-format agent definition into a Claude Code or Copilot CLI variant.

Usage: gen_agent.py <source.md> <claude|copilot>

Source is the canonical Pi-format agent file (frontmatter + body). We remap the
fields that genuinely diverge across harnesses (name, tools vocabulary, model)
and drop Pi-only keys the target ignores anyway. Body is passed through — bodies
are written in harness-agnostic capability language.
"""
import sys, re

# Pi built-in tool token -> target vocabulary. None = drop (covered by another tool).
TOOLS = {
    "claude":  {"read": "Read", "bash": "Bash", "grep": "Grep", "find": "Glob", "ls": None},
    "copilot": {"read": "read", "bash": "execute", "grep": "search", "find": "search", "ls": None},
}
ALIAS_MODELS = {"haiku", "sonnet", "opus"}  # values Claude accepts verbatim


def parse(path):
    text = open(path).read()
    m = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.S)
    if not m:
        sys.exit(f"no frontmatter: {path}")
    fm = {}
    for line in m.group(1).splitlines():
        if ":" in line:
            k, v = line.split(":", 1)
            fm[k.strip()] = v.strip()
    return fm, m.group(2)


def map_tools(raw, target):
    toks = [t.strip() for t in raw.replace(",", " ").split()]
    if any(t in ("all", "*") for t in toks):
        return None  # omit -> inherit all tools
    if "none" in toks:
        return "none" if target == "copilot" else ""
    out = []
    for t in toks:
        mapped = TOOLS[target].get(t, t)
        if mapped and mapped not in out:
            out.append(mapped)
    return ", ".join(out)


def emit(fm, body, target):
    name = fm.get("display_name") or "agent"
    desc = fm.get("description", "").strip()
    lines = ["---"]
    if target == "claude":
        lines.append(f"name: {name.lower().replace(' ', '-')}")
        lines.append(f"description: {desc}")
        model = fm.get("model", "")
        if model in ALIAS_MODELS:
            lines.append(f"model: {model}")
    else:  # copilot
        lines.append(f"name: {name}")
        lines.append(f"description: {desc}")
        # model omitted: Copilot has no alias mapping for haiku/sonnet
    tools = map_tools(fm.get("tools", "all"), target)
    if tools is not None:
        lines.append(f"tools: {tools}")
    lines.append("---")
    return "\n".join(lines) + "\n" + body


if __name__ == "__main__":
    src, target = sys.argv[1], sys.argv[2]
    fm, body = parse(src)
    sys.stdout.write(emit(fm, body, target))
