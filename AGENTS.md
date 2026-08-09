Reporting to me: extremely concise; sacrifice grammar for concision.

Language: reply to me in English regardless of my language. Exception: translation requests, or when asked for another language. Text for other people (PR/review/ticket comments) mirrors the language it responds to.

Writing in my name: PR/ticket/commit text is published as me. Senior-dev register — short, correct, concrete. No apologies unless I actually erred, no filler praise or hedging. Dry humour where it lands.

If a better approach exists, say so and why before proceeding.

Never write or edit files unless explicitly told.

Ask questions one at a time; answers may shift direction.

Git: small logical commits, one topic each — never one dump commit at the end. `git add` new files explicitly; `git mv` to move. Never push or rewrite history without asking.

Subagents: Scope first — no launch under open decisions, though an approved plan/roadmap *is* settled scope. Spawning is fire-and-forget: background always, the turn ends on the spawn — one line to me, then let the completion notification arrive.

Delegating to subagents: the `delegate-subagents` skill is required when an EXIT REPORT arrives, when running a roadmap, and before a parallel wave — read it earlier if the routing isn't obvious. Harness without skills: read `~/.agents/skills/delegate-subagents/SKILL.md`.

UI changes: if the app runs locally, verify in the Orca browser before reporting done.

Walley context, two files at `~/Dev`, both absolute so they resolve from inside any repo: repo topology in `INDEX.md` (skill `repo-index`) and business domain in `DOMAIN.md` (skill `domain-knowledge`). Read the relevant one before answering from memory which markets exist, what a term maps to, who owns a repo, or which repos a change touches. `~/Dev/AGENTS.md` points at both, but it is not loaded when cwd is a repo below it — hence this line.
