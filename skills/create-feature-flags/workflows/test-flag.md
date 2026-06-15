# Workflow: Test Flag-Gated Code

<required_reading>
**Read before proceeding:**
1. references/testing.md
</required_reading>

<process>
## Step 1: Choose test approach

**Single test needs flag on/off:** Mock `IsFeatureEnabled<T>()` directly with FakeItEasy.

**Whole test class needs all flags on:** Use `AllFeaturesEnabledCustomization`.

## Step 2a: Mock a specific flag (preferred for unit tests)

```csharp
[Theory, AutoTestData]
public async Task Does_something_when_flag_is_enabled(
    [Frozen] IFeatureFlagProvider featureFlagProvider,
    MyHandler sut,
    MyQuery query,
    CancellationToken cancellationToken)
{
    A.CallTo(() => featureFlagProvider.IsFeatureEnabled<JIMS####_My_Flag>(false))
        .Returns(true);

    var result = await sut.Handle(query, cancellationToken);

    // assert
}
```

Key details:
- `[Frozen]` ensures the same `IFeatureFlagProvider` mock is injected into `sut`
- Pass the default value (`false`) in the `IsFeatureEnabled<T>()` call to match the signature
- FakeItEasy auto-returns `false` for unmocked calls — safe default

## Step 2b: Enable all flags for a test class

Apply `AllFeaturesEnabledCustomization` via `AutoTestData` or a custom attribute:

```csharp
[Theory, AutoTestData(typeof(AllFeaturesEnabledCustomization))]
public async Task Works_with_all_flags_on(...)
{
    // all IsFeatureEnabled<T>() calls return true
}
```

`AllFeaturesEnabledCustomization` (already exists in test project):
```csharp
public class AllFeaturesEnabledCustomization : ICustomization
{
    public void Customize(IFixture fixture)
    {
        var featureFlags = fixture.Freeze<IFeatureFlagProvider>();
        A.CallTo(featureFlags)
            .Where(call => call.Method.Name == "IsFeatureEnabled")
            .WithReturnType<bool>()
            .Returns(true);
    }
}
```

## Step 3: Test flag-off behavior explicitly

Always write at least one test where the flag is `false` (disabled path):

```csharp
[Theory, AutoTestData]
public async Task Returns_old_behaviour_when_flag_is_disabled(
    [Frozen] IFeatureFlagProvider featureFlagProvider,
    MyHandler sut,
    MyQuery query,
    CancellationToken cancellationToken)
{
    A.CallTo(() => featureFlagProvider.IsFeatureEnabled<JIMS####_My_Flag>(false))
        .Returns(false);

    var result = await sut.Handle(query, cancellationToken);

    // assert old behaviour
}
```

## Step 4: Verify

- Tests pass for both flag enabled and disabled
- No real `ILdClient` in tests
</process>

<success_criteria>
- [ ] At least one test for flag enabled
- [ ] At least one test for flag disabled (default/off)
- [ ] `[Frozen]` used so mock is injected into SUT
- [ ] Tests pass
</success_criteria>
