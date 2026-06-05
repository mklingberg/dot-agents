# Workflow: Remove a Feature Flag After Rollout

<required_reading>
**Read before proceeding:**
1. references/flag-structure.md
</required_reading>

<process>
## Step 1: Confirm the flag is fully rolled out

Ask: "Has this flag been enabled in production, verified working, and are you ready to make the behavior unconditional?" Only proceed if yes.

Expected prior state: Flag was toggled ON progressively (CI → UAT → PROD) and has been verified at each stage.

## Step 2: Find all usages

Search the codebase for the flag class name:
```
JIMS####_Description
```

Locations to check:
- `src/` — all handler, endpoint, middleware, service usages
- `test/` — all test files mocking this flag

## Step 3: Replace flag-gated code with unconditional code

For each usage, inline the "enabled" branch and delete the "disabled" branch:

**Before:**
```csharp
if (featureFlagProvider.IsFeatureEnabled<JIMS####_My_Flag>())
{
    // new behaviour
}
else
{
    // old behaviour — delete this
}
```

**After:**
```csharp
// new behaviour (inlined directly)
```

If the flag wraps an entire method/endpoint that should now always run, remove the guard entirely.

## Step 4: Remove IFeatureFlagProvider injection if no longer needed

If `featureFlagProvider` is no longer used anywhere in the class after removing the flag, remove:
- The constructor parameter
- The `using MyWalley.Domain.Foundation.FeatureFlags;` (if no other flags remain)

## Step 5: Delete the flag class file

Delete the flag class file found in Step 2.

## Step 6: Update tests

- Remove test cases that test the disabled path for this flag
- Remove `A.CallTo(() => featureFlagProvider.IsFeatureEnabled<JIMS####_...>(...))` setups
- If `IFeatureFlagProvider` was only used for this flag, remove the `[Frozen]` parameter too

## Step 7: Build and test

```bash
dotnet build
dotnet test
```

## Step 8: Archive the flag in LaunchDarkly via MCP

Use `mcp__LaunchDarkly__get-feature-flag` to look up the flag by key, then use `mcp__LaunchDarkly__delete-feature-flag` (or update it to archived) to remove it from the `after-purchase` project.

Confirm deletion/archival before declaring the cleanup complete.
</process>

<anti_patterns>
- Don't leave dead `IsFeatureEnabled<T>()` calls with always-true/always-false hardcoding
- Don't leave the flag class file "just in case"
- Don't forget to clean up test mocks — they become dead code
</anti_patterns>

<success_criteria>
- [ ] Flag class file deleted
- [ ] All `IsFeatureEnabled<T>()` calls removed
- [ ] Enabled-path code inlined unconditionally
- [ ] Disabled-path code deleted
- [ ] Tests updated and passing
- [ ] Build passes
- [ ] Flag archived/deleted in LaunchDarkly via MCP (confirmed)
</success_criteria>
