# Workflow: Create a New Feature Flag

<required_reading>
**Read before proceeding:**
1. references/flag-structure.md
</required_reading>

<process>
## Step 1: Get the Jira ticket number and description

Ask the user if not provided:
- Jira ticket (e.g. `JIMS6100`)
- Short description in PascalCase (e.g. `Enable_New_Checkout`)

## Step 2: Create the flag class

**Before creating the file, find the FeatureFlags directory:**
Search for any existing class inheriting `FeatureFlag<bool>` in the codebase (e.g. search for `: FeatureFlag<bool>`). That file's directory and namespace are the pattern to follow for this project.

**Generate a new GUID now (e.g. run `uuidgen` on macOS or use any online GUID generator). The key has no relation to the class name.**

Create file: `{discovered-directory}/JIMS####_Description.cs`

```csharp
using Collector.Common.FeatureFlags;

namespace {MatchedNamespaceFromExistingFlags};

public class JIMS####_Description : FeatureFlag<bool>
{
    public override string Keyname => "teamy-{generate-new-guid}";
}
```

Rules:
- Namespace: match the existing flag files in this project exactly (varies per project)
- Class name = file name = `JIMS####_Description`
- Keyname format: `"teamy-{guid}"` — a freshly generated GUID, completely independent of the class name
- Type is `bool` unless user specifies otherwise

## Step 3: Create the flag in LaunchDarkly via MCP

Use the `mcp__LaunchDarkly__create-feature-flag` tool to create the flag automatically:

```
projectKey: "after-purchase"
name: "JIMS####_Description"
key: "teamy-{the-guid-you-just-generated}"
variations: [{ value: true }, { value: false }]
defaultVariation: 1   ← index of false (off by default)
temporary: true
```

Confirm the flag was created successfully before proceeding.

> **Rollout flow:** Once merged and deployed, toggle ON in CI first → verify → then UAT → verify → then PROD → verify → run remove-flag cleanup.

## Step 4: Verify

- File exists in the discovered flags directory
- Class name matches file name
- Keyname matches exactly what will be used in the dashboard
- `using Collector.Common.FeatureFlags;` is present
- Namespace is correct
</process>

<success_criteria>
- [ ] Flag class file created with correct naming
- [ ] Keyname uses `teamy-` prefix
- [ ] Flag created in LaunchDarkly via MCP (confirmed)
- [ ] No existing flag with same ticket number
</success_criteria>
