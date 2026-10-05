# Roadmap Template

Copy and fill this structure for `.planning/ROADMAP.md`:

## Initial Roadmap (v1.0 Greenfield)

```markdown
# Roadmap: [Project Name]

## Overview

[One paragraph describing the journey from start to finish]

## Phases

- **Phase 1: [Name]** - [One-line description]
- **Phase 2: [Name]** - [One-line description]
- **Phase 3: [Name]** - [One-line description]
- **Phase 4: [Name]** - [One-line description]

## Phase Details

### Phase 1: [Name]
**Goal**: [What this phase delivers]
**Depends on**: Nothing (first phase)
**Plans**: [Number of plans, e.g., "3 plans" or "TBD after research"]

Plans:
- 01-01: [Brief description of first plan]
- 01-02: [Brief description of second plan]
- 01-03: [Brief description of third plan]

### Phase 2: [Name]
**Goal**: [What this phase delivers]
**Depends on**: Phase 1
**Plans**: [Number of plans]

Plans:
- 02-01: [Brief description]

### Phase 3: [Name]
**Goal**: [What this phase delivers]
**Depends on**: Phase 2
**Plans**: [Number of plans]

Plans:
- 03-01: [Brief description]
- 03-02: [Brief description]

### Phase 4: [Name]
**Goal**: [What this phase delivers]
**Depends on**: Phase 3
**Plans**: [Number of plans]

Plans:
- 04-01: [Brief description]
```

<guidelines>
**Initial planning (v1.0):**
- 3-6 phases total (more = scope creep)
- Each phase delivers something coherent
- Phases can have 1+ plans (2-3 tasks each; split by subsystem)
- Plans use naming: {phase}-{plan}-PLAN.md (e.g., 01-02-PLAN.md)
- No time estimates (this isn't enterprise PM)
- No status, checkboxes or progress table: a phase is done when every PLAN has a SUMMARY
- Plan count can be "TBD" initially, refined during planning

**Adding phases over time:**
- Keep continuous phase numbering (never restart at 01)
- Add new phases to the bottom of the roadmap
</guidelines>

<deferring>
To defer a phase, move it under a `## Deferred` heading with a one-line reason.
</deferring>
