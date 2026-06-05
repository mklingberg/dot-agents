<anti_patterns>

<anti_pattern name="Merging behavior changes without a feature flag">
**Problem:** Changing business logic, adding a new endpoint, or modifying existing behavior and merging directly to main without a feature flag.
**Why it's bad:** All backends use continuous deployment — every merge to main deploys immediately to all environments including production. An unguarded change is a live change with no rollback mechanism.
**Instead:** Always wrap new or changed behavior in IsFeatureEnabled<T>(). The flag default is false, so the new code is inert on deploy until deliberately toggled.
</anti_pattern>

<anti_pattern name="Direct ILdClient injection in business logic">
**Problem:** Calling `ldClient.BoolVariation("key", context, false)` directly in handlers or services.
**Why it's bad:** Bypasses `IFeatureFlagProvider`, ties code to raw SDK, breaks the abstraction, hard to test.
**Instead:** Always inject `IFeatureFlagProvider` and use `IsFeatureEnabled<T>()`.
</anti_pattern>

<anti_pattern name="Hardcoded flag key strings">
**Problem:** `ldClient.BoolVariation("teamy-f061bc7f-7d02-4996-b1b9-59b282199e29", context, false)` or `if (flag == "teamy-...")`
**Why it's bad:** Typo-prone, no compile-time safety, not searchable by flag class. Even a correct `"teamy-{guid}"` string is wrong when hardcoded directly.
**Instead:** Use the typed class: `featureFlagProvider.IsFeatureEnabled<JIMS5885_Enable_Biometric>()`.
</anti_pattern>

<anti_pattern name="Using GetBoolFlag instead of IsFeatureEnabled">
**Problem:** `featureFlagProvider.GetBoolFlag<JIMS####_My_Flag>()`
**Why it's bad:** Uses hardcoded `"Default-Default"` context — ignores the real user. All users get same evaluation.
**Instead:** Use `IsFeatureEnabled<T>()` which resolves the correct user context from the current request.
</anti_pattern>

<anti_pattern name="Forgetting to test the off-state">
**Problem:** Only writing tests for the flag-enabled path.
**Why it's bad:** If the flag is off (default in production), untested code paths can break.
**Instead:** Write one test for each path (enabled and disabled).
</anti_pattern>

<anti_pattern name="Leaving dead flags in code">
**Problem:** Flag is 100% rolled out but class file and `IsFeatureEnabled<T>()` calls remain.
**Why it's bad:** Dead code accumulates, future readers can't tell if flags are active or stale.
**Instead:** Follow the remove-flag workflow: inline the enabled branch, delete class file, archive in LD dashboard.
</anti_pattern>

<anti_pattern name="Building LaunchDarkly context manually">
**Problem:** Creating `Context.New(...)` or `User.Builder(...).Build()` inside handlers/services.
**Why it's bad:** Bypasses group assignment logic in `LdContextFactory`. User won't be in the correct rollout group.
**Instead:** Let DI inject `Lazy<Context>` which is built by `LdContextFactory` per request. Never construct context manually except inside `LdContextFactory` and `LdContextQueryHandler`.
</anti_pattern>

</anti_patterns>
