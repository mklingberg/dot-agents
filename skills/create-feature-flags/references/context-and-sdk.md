<overview>
How the LaunchDarkly SDK is set up, how user context is resolved, and how the DI container is wired.
</overview>

<di_registration>
Registered in `src/MyWalley.Infrastructure/ServiceCollectionExtensions.cs` via `AddLaunchDarkly()`:

```csharp
services
    .AddSingleton<LaunchDarklyLoggingAdapter>()
    .AddScoped<LdContextFactory>()
    .AddScoped(provider => provider.GetRequiredService<LdContextFactory>().GetLdContext())
    .AddScoped<IFeatureFlagProvider, LaunchDarklyFeatureFlagProvider>()
    .AddSingleton<ILdClient>(provider => new LdClient(cfg));
```

- `ILdClient` — singleton (shared for lifetime of app)
- `IFeatureFlagProvider` — scoped (per request)
- `Lazy<Context>` — scoped, resolved lazily per request
</di_registration>

<context_resolution>
`LdContextFactory` builds a `Lazy<Context>` per request:

1. **Internal beta group** — if user's registration number, email, or customer ID matches an entry in `LaunchDarklyOptions:ContextMap`, they get a named group context (e.g. `"internal-my-walley"`).
2. **Existing user group** — user's MD5-hashed ID is looked up in Elasticsearch. If found, reuse assigned group.
3. **New user group** — assign random group 1–N (configurable via `LaunchDarklyOptions:CountryGroupSize`), save to Elasticsearch.
4. **Fallback** — if user context is unavailable, uses `Context.New("Default-Default")`.

**Group key format:** `my-walley-grp{N}-{countrycode}` (e.g. `my-walley-grp42-se`)
</context_resolution>

<config>
`appsettings.json`:
```json
"LaunchDarkly": {
  "SdkKey": "<KEY_VAULT>"
},
"LaunchDarklyOptions": {
  "CountryGroupSize": 100,
  "CountryNameByCountryCode": {
    "se": "Sweden", "no": "Norway", "fi": "Finland", "dk": "Denmark"
  }
}
```

Per-environment (`appsettings.UAT.json`):
```json
"LaunchDarklyOptions": {
  "CountryGroupSize": 10,
  "ContextMap": [{
    "Keys": ["1275550", "618480"],
    "Context": { "key": "internal-my-walley", "name": "Internal Beta Group" }
  }]
}
```

`ContextMap.Keys` accepts: registration number, email, or customer ID string.
</config>

<provider_interface>
`IFeatureFlagProvider` in `Collector.Common.FeatureFlags`:

```csharp
// Use this — evaluates against current user context
bool IsFeatureEnabled<T>(bool defaultValue = false) where T : FeatureFlag<bool>, new();

// Legacy — uses hardcoded "Default-Default" context, ignores real user
bool GetBoolFlag<T>(bool defaultValue = false) where T : FeatureFlag<bool>, new();

// For subscription-based flag changes (rare)
void SubscribeToBoolFlagChange<T>(Action<bool> action) where T : FeatureFlag<bool>, new();
```

**Always use `IsFeatureEnabled<T>()`.**
</provider_interface>

<event_tracking>
To track custom LaunchDarkly events (used in `LdEventTracker`):

```csharp
// Inject ILdClient AND Lazy<Context> via constructor
ldClient.Track("event-name", context);
```

This is only for analytics/experiment tracking. Flag evaluation never needs direct `ILdClient` access.
</event_tracking>
