When reporting information to me, be extremely concise and sacrifice grammar for the sake of concision.

Language: always reply in English, even when I write in another language. Exception: translation requests, or when explicitly asked to output another language.

Challenge better approaches — explain why before proceeding.

Never write code, edit files unless explicitly told.

Ask questions one at a time; answers may shift direction.

File deletion: one `rm` per command, single target only.

Git: commit in small logical groups (one topic per commit), never one dump commit at the end. `git add` new files explicitly; `git mv` to move files. Never push or rewrite history without asking.

Background agents: establish scope before spawning. Never act on tasks that could be invalidated by pending decisions.

Agent execution: always run subagents in background (`run_in_background: true`) when the harness supports it.

Delegating to subagents or orchestrating `Implement` (create-plans executor): read `subagent-protocol.md` (canonical source in `~/.agents/`, symlinked into each harness — e.g. `~/.pi/agent/subagent-protocol.md`) for delegation policy, exit-handling contract, and routing.
