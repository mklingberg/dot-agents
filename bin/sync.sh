#!/usr/bin/env bash
# sync.sh — propagate the shared ~/.agents workspace into each harness.
#
# Source of truth (this repo):
#   skills/                shared Agent Skills (SKILL.md)         -> flat per-skill symlinks (Claude)
#                          incl. delegate-subagents (orchestration protocol)
#   AGENTS.md              global instructions                    -> symlink (CLAUDE.md on Claude)
#   agents/*.md            Pi-format agent defs                   -> symlink (Pi) / generate (Claude, Copilot)
#
# Codex gets AGENTS.md only (via @import; its own file is not ours to own). Codex
# agent defs stay out of scope. general-purpose is NOT shipped — every harness has
# a native built-in.
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

echo "== instructions =="
link "$AG/AGENTS.md"            "$PI/AGENTS.md"
link "$AG/AGENTS.md"            "$CLAUDE/CLAUDE.md"
link "$AG/AGENTS.md"            "$COPILOT/AGENTS.md"   # best-effort; project-level AGENTS.md is authoritative

echo "== codex =="
# Codex AGENTS.md is user-owned (e.g. @RTK.md), so append an @import instead of
# symlinking. Covers ~/.codex plus every Orca-managed per-account home.
IMPORT="@$AG/AGENTS.md"
for ch in "$HOME/.codex" "$HOME/Library/Application Support/orca/codex-accounts"/*/home; do
  [ -d "$ch" ] || continue
  f="$ch/AGENTS.md"
  if [ -f "$f" ] && grep -qxF "$IMPORT" "$f"; then
    echo "  ok   $f"
  else
    printf '%s\n' "$IMPORT" >> "$f"
    echo "  add  $f"
  fi
done

echo "== skills =="
# Pi, Copilot and Codex discover ~/.agents/skills natively (recursive / native scan).
# Claude scans only ONE level deep -> it can't see _commands/ or _experimental/.
# Give Claude a flat dir of per-skill symlinks (Claude follows dir symlinks).
CS="$CLAUDE/skills"
[ -L "$CS" ] && rm "$CS"                                      # drop old whole-dir symlink
mkdir -p "$CS"
find "$CS" -maxdepth 1 -type l ! -exec test -e {} \; -delete  # prune broken managed links
find "$AG/skills" -name SKILL.md -print0 | while IFS= read -r -d '' sk; do
  d="$(dirname "$sk")"
  ln -sfn "$d" "$CS/$(basename "$d")"
done
echo "  flattened $(find "$CS" -maxdepth 1 -type l | wc -l | tr -d ' ') skills into $CS"

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
