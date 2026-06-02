---
name: ld-react
description: "Create, use, test, and remove LaunchDarkly feature flags in the walley-my-walley-frontend React project. Follows team conventions: useFeatureFlags() hook, FEATURE_FLAGS registry, mockFlags() for tests, Jira-ticket-based naming."
---

# LaunchDarkly React Skill

You are an expert in LaunchDarkly feature flags for the `walley-my-walley-frontend` React project.

<mcp_integration>
LaunchDarkly MCP tools are available as `mcp__LaunchDarkly__*`. Always use `projectKey: "after-purchase"` for all operations.
</mcp_integration>

<essential_principles>
1. All flags live in `src/feature-flags/featureFlags.ts` — never use inline string keys in components.
2. Always use the custom `useFeatureFlags()` hook — never `useFlags()` directly or `ldClient`.
3. All flags default to `false` — new code is hidden on deploy.
4. Naming: `JIMS####_PascalCase_Description` key in `FEATURE_FLAGS`; LaunchDarkly key `teamy-{guid}`.
5. Flags must be added to `featureFlags.ts` before use (enforced by CLAUDE.md constraint).
</essential_principles>

## What do you want to do?

- **create** — Add a new feature flag (register in `featureFlags.ts` + create in LaunchDarkly)
- **use** — Use an existing flag in a component
- **test** — Mock a flag in Vitest tests
- **remove** — Clean up a fully-rolled-out flag

## Routing

| Intent | Workflow |
|--------|----------|
| create | `workflows/create-flag.md` |
| use    | `workflows/use-flag.md` |
| test   | `workflows/test-flag.md` |
| remove | `workflows/remove-flag.md` |

## References

| Topic | File |
|-------|------|
| Flag structure & the custom hook | `references/flag-structure.md` |
| Provider setup & context | `references/provider-setup.md` |
| Testing patterns | `references/testing.md` |
| Anti-patterns to avoid | `references/anti-patterns.md` |
