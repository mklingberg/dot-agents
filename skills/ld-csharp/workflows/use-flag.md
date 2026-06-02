# Workflow: Use a Flag in Code

<required_reading>
**Read before proceeding:**
1. references/flag-structure.md
2. references/context-and-sdk.md
</required_reading>

<process>
## Step 1: Identify the layer

Where is the flag being used?
- **Middleware** (e.g. kill switch) → inject `IFeatureFlagProvider` via constructor
- **Query/Command handler** → inject via constructor
- **Minimal API endpoint** → inject via `[FromServices]` parameter
- **GraphQL extension** → inject via `[Service]` parameter
- **Event handler** → inject via constructor

## Step 2: Add IFeatureFlagProvider to constructor or parameter

**Constructor injection (handlers, middleware, services):**
```csharp
public class MyQueryHandler(
    IFeatureFlagProvider featureFlagProvider,
    // ... other deps
) : IQueryHandler<MyQuery, MyResult>
```

**Minimal API endpoint:**
```csharp
app.MapGet("my-endpoint", async (
    [FromServices] IFeatureFlagProvider featureFlagProvider,
    // ... other params
) => { ... });
```

**GraphQL:**
```csharp
public async Task<MyResult> MyField(
    [Service] IFeatureFlagProvider featureFlagProvider,
    // ... other params
)
```

## Step 3: Evaluate the flag

```csharp
if (featureFlagProvider.IsFeatureEnabled<JIMS####_My_Flag>())
{
    // new behaviour
}
else {
    // any old behavior
}
```

- Default value is `false` (off). Only pass `true` if the safe default is "on".
- Use `IsFeatureEnabled<T>()` — not `GetBoolFlag<T>()` (legacy, uses default user context).

## Step 4: Add using statement

```csharp
using MyWalley.Domain.Foundation.FeatureFlags;
```

## Step 5: Verify

- Build succeeds
- Flag class exists in `Foundation/FeatureFlags/`
- No direct `ILdClient` usage introduced
</process>

<anti_patterns>
- Never inject `ILdClient` directly into business logic
- Never hardcode flag key strings — always use the typed class
- Avoid `GetBoolFlag<T>()` — it ignores user context (legacy method)
</anti_patterns>

<success_criteria>
- [ ] `IFeatureFlagProvider` injected correctly for the layer
- [ ] `IsFeatureEnabled<T>()` used (not GetBoolFlag)
- [ ] No raw flag key strings anywhere
- [ ] Project builds
</success_criteria>
