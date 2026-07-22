#!/usr/bin/env bash
# sync.sh — propagate the shared ~/.agents workspace into each harness.
#
# Source of truth (this repo):
#   skills/                shared Agent Skills (SKILL.md)         -> symlink
#   subagent-protocol.md   hybrid orchestration protocol          -> symlink
#   AGENTS.md              global instructions                    -> symlink (CLAUDE.md on Claude)
#   agents/*.md            Pi-format agent defs                   -> symlink (Pi) / generate (Claude, Copilot)
#
# Codex is intentionally out of scope. general-purpose is NOT shipped — every
# harness has a native built-in.
set -euo pipefail

AG="$HOME/.agents"
GEN="$AG/bin/gen_agent.py"
PI="$HOME/.pi/agent"
CLAUDE="$HOME/.claude"
COPILOT="$HOME/.copilot"

link() { # link <target> <linkname>
  mkdir -p "$(dirname "$2")"
  ln -sfn "$1" "$2"
  echo "  link $2 -> $1"
}

echo "== instructions + protocol =="
link "$AG/subagent-protocol.md" "$PI/subagent-protocol.md"
link "$AG/AGENTS.md"            "$PI/AGENTS.md"
link "$AG/AGENTS.md"            "$CLAUDE/CLAUDE.md"
link "$AG/AGENTS.md"            "$COPILOT/AGENTS.md"   # best-effort; project-level AGENTS.md is authoritative

echo "== skills =="
# Pi and Copilot scan ~/.agents/skills natively -> no symlink needed.
# Claude scans ~/.claude/skills only -> symlink it to the shared workspace.
[ -e "$CLAUDE/skills" ] || link "$AG/skills" "$CLAUDE/skills"

echo "== agent defs =="
mkdir -p "$CLAUDE/agents" "$COPILOT/agents" "$PI/agents"
for src in "$AG"/agents/*.md; do
  name="$(basename "$src" .md)"
  lower="$(echo "$name" | tr '[:upper:]' '[:lower:]')"
  # Pi: format matches source -> symlink
  link "$src" "$PI/agents/$name.md"
  # Claude: generate
  python3 "$GEN" "$src" claude  > "$CLAUDE/agents/$lower.md"
  echo "  gen  $CLAUDE/agents/$lower.md"
  # Copilot: generate (.agent.md)
  python3 "$GEN" "$src" copilot > "$COPILOT/agents/$lower.agent.md"
  echo "  gen  $COPILOT/agents/$lower.agent.md"
done

echo "done."
