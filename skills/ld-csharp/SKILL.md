---
name: ld-csharp
description: "Create, use, test, and remove LaunchDarkly feature flags in C# .NET projects. Follows team conventions: FeatureFlag<T> subclasses, IFeatureFlagProvider, Jira-ticket-based naming."
---

<mcp_integration>
## LaunchDarkly MCP

The LaunchDarkly MCP server is available and should be used for all flag management operations — no need to ask the user to use the dashboard manually. Key tools:

- `mcp__LaunchDarkly__create-feature-flag` — create a new flag (use in create-flag workflow)
- `mcp__LaunchDarkly__get-feature-flag` — look up a flag by key
- `mcp__LaunchDarkly__list-feature-flags` — list flags in a project (`projectKey: "after-purchase"`)
- `mcp__LaunchDarkly__update-feature-flag` — update flag settings or targeting
- `mcp__LaunchDarkly__delete-feature-flag` — delete a flag (use in remove-flag workflow)

Always use `projectKey: "after-purchase"` unless the user specifies another project.
</mcp_integration>

<essential_principles>
## How Feature Flags Work Here

### 1. Every flag is a class
Flags live in a project-specific directory. Find it by searching for an existing class that inherits `FeatureFlag<bool>` — all flags in the project are co-located there. Each flag is a dedicated `.cs` file, a class inheriting `FeatureFlag<bool>` (from `Collector.Common.FeatureFlags`).

```csharp
public class JIMS1234_My_New_Flag : FeatureFlag<bool>
{
    public override string Keyname => "teamy-f061bc7f-7d02-4996-b1b9-59b282199e29";
}
```

### 2. Never access ILdClient directly
All evaluation goes through `IFeatureFlagProvider.IsFeatureEnabled<T>()`. Inject it from DI. Never call `ldClient.BoolVariation(...)` yourself.

### 3. Continuous deployment — flags are mandatory
All backend systems deploy continuously. Every merge to main goes live immediately to all environments. This means **every behavior-changing code change must be gated by a feature flag** — never merge a behavior change unguarded.

Rollout flow after merging: CI → UAT → PROD (toggle the flag ON in each environment, verify, then advance). Once confirmed working in PROD, run the remove-flag workflow to clean up.

### 4. Naming conventions
- **Class name:** `JIMS####_Short_Description` (matches Jira ticket)
- **File name:** same as class name, `.cs`
- **Keyname:** `"teamy-{guid}"` — generate a new GUID at creation time. Completely independent of class name. Example: `"teamy-f061bc7f-7d02-4996-b1b9-59b282199e29"`

### 5. Context is automatic
`LdContextFactory` resolves the user context from the current request (scoped DI). Users are assigned to numbered groups per country (1–N, stored in Elasticsearch). Internal beta groups are configured per environment in `LaunchDarklyOptions:ContextMap`. Don't build context manually.
</essential_principles>

<intake>
What would you like to do?

1. Create a new feature flag
2. Use a flag in code (service, handler, endpoint, middleware)
3. Write tests for flag-gated code
4. Remove a flag after rollout

**Wait for response before proceeding.**
</intake>

<routing>
| Response | Workflow |
|----------|----------|
| 1, "create", "new flag", "add flag" | `workflows/create-flag.md` |
| 2, "use", "evaluate", "check", "inject", "add to handler" | `workflows/use-flag.md` |
| 3, "test", "unit test", "mock" | `workflows/test-flag.md` |
| 4, "remove", "clean up", "delete", "retire" | `workflows/remove-flag.md` |

**After reading the workflow, follow it exactly.**
</routing>

<reference_index>
All in `references/`:

**Structure & naming:** flag-structure.md
**SDK, context, DI setup:** context-and-sdk.md
**Testing patterns:** testing.md
**Anti-patterns:** anti-patterns.md
</reference_index>

<workflows_index>
| Workflow | Purpose |
|----------|---------|
| create-flag.md | Define a new flag class + create in LD dashboard |
| use-flag.md | Inject and evaluate a flag in any layer |
| test-flag.md | Mock IFeatureFlagProvider with FakeItEasy |
| remove-flag.md | Delete flag class and all usages safely |
</workflows_index>
