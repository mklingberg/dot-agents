---
name: create-agent-skills
description: "Create or improve Claude Code SKILL.md files. Triggers: 'write a skill', 'new skill', editing SKILL.md, skill-structure questions."
---

<essential_principles>
## How Skills Work

Skills are modular, filesystem-based capabilities that provide domain expertise on demand. This skill teaches how to create effective skills.

### 1. Skills Are Prompts

All prompting best practices apply. Be clear, be direct, use semantic structure. Assume Claude is smart — only add context Claude doesn't have.

**Markdown `##` headings or XML tags are both fine.** Anthropic's own skills (skill-creator, pdf, docx, xlsx) use markdown headings. Use XML tags when a section benefits from a semantic name (e.g. `<intake>`, `<routing>`, `<success_criteria>`) or wraps content that itself contains `##`. Otherwise prefer markdown for readability — don't mechanically convert.

### 2. SKILL.md Is Always Loaded

When a skill is invoked, Claude reads SKILL.md. Use this guarantee:
- Essential principles go in SKILL.md (can't be skipped)
- Workflow-specific content goes in workflows/
- Reusable knowledge goes in references/

### 3. Router Pattern for Complex Skills

<intake>
What would you like to do?

1. Create new skill
2. Audit/modify existing skill
3. Add component (workflow/reference/template/script)
4. Get guidance

**Wait for response before proceeding.**
</intake>

<routing>
| Response | Next Action | Workflow |
|----------|-------------|----------|
| 1, "create", "new", "build" | Ask: "Task-execution skill or domain expertise skill?" | Route to appropriate create workflow |
| 2, "audit", "modify", "existing" | Ask: "Path to skill?" | Route to appropriate workflow |
| 3, "add", "component" | Ask: "Add what? (workflow/reference/template/script)" | workflows/add-{type}.md |
| 4, "guidance", "help" | General guidance | workflows/get-guidance.md |

**Progressive disclosure for option 1 (create):**
- If user selects "Task-execution skill" → workflows/create-new-skill.md
- If user selects "Domain expertise skill" → workflows/create-domain-expertise-skill.md

**Progressive disclosure for option 3 (add component):**
- If user specifies workflow → workflows/add-workflow.md
- If user specifies reference → workflows/add-reference.md
- If user specifies template → workflows/add-template.md
- If user specifies script → workflows/add-script.md

**Intent-based routing (if user provides clear intent without selecting menu):**
- "audit this skill", "check skill", "review" → workflows/audit-skill.md
- "verify content", "check if current" → workflows/verify-skill.md
- "create domain expertise", "exhaustive knowledge base" → workflows/create-domain-expertise-skill.md
- "create skill for X", "build new skill" → workflows/create-new-skill.md
- "add workflow", "add reference", etc. → workflows/add-{type}.md
- "upgrade to router" → workflows/upgrade-to-router.md

**After reading the workflow, follow it exactly.**
</routing>

<quick_reference>
## Skill Structure Quick Reference

**Simple skill (single file):**
```yaml
---
name: skill-name
description: What it does and when to use it.
---

## Overview
What this skill does

## Quick Start
Immediate actionable guidance

## Process
Step-by-step procedure

<success_criteria>
How to know it worked
</success_criteria>
```

XML tags are optional — use them where the semantic name adds clarity (commonly `<success_criteria>`, `<intake>`, `<routing>`). Plain `##` headings are equally valid.

**Complex skill (router pattern):**
```
SKILL.md:
  <essential_principles> - Always applies
  <intake> - Question to ask
  <routing> - Maps answers to workflows

workflows/:
  <required_reading> - Which refs to load
  <process> - Steps
  <success_criteria> - Done when...

references/:
  Domain knowledge, patterns, examples

templates/:
  Output structures Claude copies and fills
  (plans, specs, configs, documents)

scripts/:
  Executable code Claude runs as-is
  (deploy, setup, API calls, data processing)
```
</quick_reference>

<reference_index>
## Domain Knowledge — load on demand

All in `references/`. Don't preload — read only when the trigger condition matches:

| Read this | When |
|---|---|
| `recommended-structure.md` | Drafting a new skill's directory layout |
| `skill-structure.md` | Deciding what goes in SKILL.md vs references vs workflows |
| `core-principles.md` | User asks "why is my skill bad" / general critique |
| `be-clear-and-direct.md` | Reviewing skill prose for clarity |
| `use-xml-tags.md` | Deciding XML vs markdown for a specific section (rarely needed; SKILL.md covers the rule) |
| `common-patterns.md` | Looking for an example pattern (gotchas, validation loops, plan-validate-execute) |
| `workflows-and-validation.md` | Building multi-step workflow files |
| `using-templates.md` | Adding a `templates/` asset |
| `using-scripts.md` | Adding a `scripts/` asset |
| `executable-code.md` | Skill needs to run code/tools |
| `api-security.md` | Skill touches secrets, tokens, or external APIs |
| `iteration-and-testing.md` | Running the skill against test prompts to refine it |
</reference_index>

<workflows_index>
## Workflows

All in `workflows/`:

| Workflow | Purpose |
|----------|---------|
| create-new-skill.md | Build a skill from scratch |
| create-domain-expertise-skill.md | Build comprehensive domain expertise skill with full lifecycle workflows |
| audit-skill.md | Analyze skill against best practices |
| verify-skill.md | Check if content is still accurate |
| add-workflow.md | Add a workflow to existing skill |
| add-reference.md | Add a reference to existing skill |
| add-template.md | Add a template to existing skill |
| add-script.md | Add a script to existing skill |
| upgrade-to-router.md | Convert simple skill to router pattern |
| get-guidance.md | Help decide what kind of skill to build |
</workflows_index>

<yaml_requirements>
## YAML Frontmatter

Required fields:
```yaml
---
name: skill-name          # lowercase-with-hyphens, matches directory
description: ...          # See <description_authoring> below
---
```

Name conventions: `create-*`, `manage-*`, `setup-*`, `generate-*`, `build-*`
</yaml_requirements>

<grounding>
## Ground in Real Expertise Before Drafting

A skill written from generic knowledge produces vague guidance ("handle errors appropriately"). A skill grounded in real artifacts produces specific guidance ("the `users` table uses soft deletes — always filter `deleted_at IS NULL`").

**Before writing a new skill, gather concrete material:**
- Read 2–3 existing skills in this workspace (`~/.agents/skills/` and `.pi/agents/`) for tone and structure
- If capturing a workflow the user just performed, extract from the conversation: tools used, corrections made, edge cases hit, input/output shapes
- If synthesizing from artifacts, ask the user for: existing docs, runbooks, code-review comments, recent fixes, failure cases

**Refuse to draft a skill purely from the LLM's general training knowledge.** If no domain material is available, ask the user for examples or run a real task first, then extract the skill from it.
</grounding>

<gotchas>
## Gotchas

Non-obvious facts that bite skill authors. Add to this list whenever a skill produces a wrong result you have to correct.

- **Skill name must match directory name exactly** — `name: foo-bar` requires `foo-bar/SKILL.md`, not `foo_bar/` or `FooBar/`.
- **Description is always-loaded tax** — every char sits in the system prompt for every conversation. 80–150 chars target; 200 hard cap.
- **Description is a trigger detector, not documentation** — internal mechanics belong in SKILL.md body, not the description.
- **`disable-model-invocation: true` is a Claude Code extension, not in the agentskills spec.** In this workspace it marks a skill as command-like — invoked explicitly by the user, never auto-triggered. Skills with this flag live in `skills/_commands/` (e.g. `to-plan`, `handoff`, `manage-worktrees`). Don't add it to discoverable/auto-triggered skills.
- **`workflows/` is a project-specific convention, not in the spec.** The spec defines `scripts/`, `references/`, `assets/`. We use `workflows/` for procedural step-by-step files (distinct from `references/` which holds knowledge). A strict `skills-ref validate` won't understand the semantics but won't reject it.
- **Router pattern is overhead unless intake is genuinely ambiguous** — a skill that always does one thing should be a single SKILL.md, not a router.
- **Reference files are not auto-loaded** — listing them in `<reference_index>` does nothing unless SKILL.md tells the agent *when* to read each one.
- **Avoid menus without defaults** — "use pypdf, pdfplumber, or PyMuPDF" wastes tokens; pick one default and mention alternatives briefly.
- **Procedures generalise, declarations don't** — teach how to approach a class of problems, not what to produce for one instance.
- **Sibling skills with overlapping triggers must name each other** — e.g. `to-prd` vs `create-a-prd` — at least one description must say "for X, use other-skill".
- **Markdown `##` and XML tags are both valid** — Anthropic's official skills use markdown. Use XML only where the tag name adds semantic value.
</gotchas>

<description_authoring>
## Writing Descriptions (Critical)

**Descriptions are always-loaded tax.** Every skill's description sits in the agent's system prompt for every conversation, used solely to decide *when to activate this skill*. Treat them as trigger detectors, not documentation.

**Format:** `{Action + scope}. Triggers: '{phrase}', '{phrase}', {context cue}.`

**Target:** 80–150 chars. Hard cap 200 unless the skill has unusual disambiguation needs.

**Include:**
- Verb + object (what it does)
- Distinctive scope markers that disambiguate from sibling skills (language, tool, project name, e.g. `C#`, `Azure DevOps`, `Mina Sidor`)
- Literal trigger phrases the user is likely to say
- Explicit differentiator when a sibling skill overlaps (e.g. `For X, use other-skill.`)

**Exclude:**
- How it works internally (loaded when skill activates — belongs in SKILL.md body)
- Selling adjectives (`expert`, `stunning`, `senior-level`, `comprehensive`)
- Repeated nouns ("plans... planning... plan")
- Generic verbs without scope ("helps with", "processes")

**Examples:**
- ✅ `Write xUnit + AutoFixture + FakeItEasy unit tests for C#. Triggers: 'write tests', 'test this handler/validator/service'.`
- ✅ `Open a PR in Azure DevOps from a feature branch. Runs review-code first. Triggers: 'open PR', 'create PR', 'ready to merge'.`
- ❌ `Expert guidance for creating, writing, building, and refining Claude Code Skills.` (selling, no triggers)
- ❌ `Helps with documents` (no scope, no triggers)

**When two skills overlap** (e.g. `to-prd` vs `create-a-prd`): each description must encode the discriminator, and at least one should name the other. Example: `...Triggers: greenfield 'write a PRD'. For converting current conversation, use to-prd.`
</description_authoring>

<validation_loop>
## Validate Before Finishing

A first draft is rarely the final version. After writing or editing a skill, run this loop at least once:

1. **Pick one realistic test prompt** the user would actually say to trigger this skill.
2. **Mentally (or actually) run the skill against it.** Does the agent produce the right output? Does it follow the procedure? Does it stop at the right place?
3. **Identify the failure mode:**
   - Vague instructions → agent tries multiple approaches before landing
   - Instructions that don't apply → agent follows them anyway, wastes tokens
   - Menu of options without default → agent picks the wrong one
   - Missing gotcha → agent makes a known mistake
4. **Revise the skill** to address the specific failure. Add a gotcha if the failure was a recurring kind of mistake.
5. **Repeat** until the prompt produces the right output without correction.

For structured eval-driven iteration with assertions and grading, see `references/iteration-and-testing.md`.

**Objective validation:** run `skills-ref validate ./skill-name` from the [agentskills reference library](https://github.com/agentskills/agentskills/tree/main/skills-ref) to check frontmatter and naming conventions against the formal spec.
</validation_loop>

<success_criteria>
A well-structured skill:
- Has valid YAML frontmatter
- Uses consistent section structure (markdown `##` or XML tags) — mix only when XML adds semantic value
- Has essential principles inline in SKILL.md
- Routes directly to appropriate workflows based on user intent
- SKILL.md contains only what's needed on every invocation (conditional content in sub-files, hard ceiling 500 lines)
- Asks minimal clarifying questions only when truly needed
- Grounded in real domain material, not generic LLM knowledge (see `<grounding>`)
- Has a `<gotchas>` section if the domain has non-obvious failure modes
- References use trigger conditions ("read X when Y"), not flat menus
- Has been validated against at least one real test prompt (see `<validation_loop>`)
</success_criteria>
