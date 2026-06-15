---
name: create-agent-skills
description: "Create or improve Claude Code SKILL.md files. Triggers: 'write a skill', 'new skill', editing SKILL.md, skill-structure questions."
---

<essential_principles>
## How Skills Work

Skills are modular, filesystem-based capabilities that provide domain expertise on demand. This skill teaches how to create effective skills.

### 1. Skills Are Prompts

All prompting best practices apply. Be clear, be direct, use XML structure. Assume Claude is smart - only add context Claude doesn't have.

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

<objective>What this skill does</objective>
<quick_start>Immediate actionable guidance</quick_start>
<process>Step-by-step procedure</process>
<success_criteria>How to know it worked</success_criteria>
```

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
## Domain Knowledge

All in `references/`:

**Structure:** recommended-structure.md, skill-structure.md
**Principles:** core-principles.md, be-clear-and-direct.md, use-xml-tags.md
**Patterns:** common-patterns.md, workflows-and-validation.md
**Assets:** using-templates.md, using-scripts.md
**Advanced:** executable-code.md, api-security.md, iteration-and-testing.md
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

<success_criteria>
A well-structured skill:
- Has valid YAML frontmatter
- Uses pure XML structure (no markdown headings in body)
- Has essential principles inline in SKILL.md
- Routes directly to appropriate workflows based on user intent
- SKILL.md contains only what's needed on every invocation (conditional content in sub-files, hard ceiling 500 lines)
- Asks minimal clarifying questions only when truly needed
- Has been tested with real usage
</success_criteria>
