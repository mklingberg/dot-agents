<overview>
How to test flag-gated code in this project. Uses FakeItEasy + AutoFixture (AutoTestData attribute).
</overview>

<mock_single_flag>
Mock a specific flag on or off with FakeItEasy:

```csharp
[Theory, AutoTestData]
public async Task Returns_new_behaviour_when_flag_enabled(
    [Frozen] IFeatureFlagProvider featureFlagProvider,
    MyHandler sut,
    MyQuery query,
    CancellationToken cancellationToken)
{
    A.CallTo(() => featureFlagProvider.IsFeatureEnabled<JIMS####_My_Flag>(false))
        .Returns(true);

    var result = await sut.Handle(query, cancellationToken);

    result.ShouldBe(/* expected */);
}
```

- `[Frozen]` ensures the same mock instance is injected into `sut`
- Pass the default value `false` to match the method signature
- Unmocked `IsFeatureEnabled` calls return `false` by default (safe)
</mock_single_flag>

<enable_all_flags>
Use `AllFeaturesEnabledCustomization` when the whole test class needs flags on:

Location: `test/MyWalley.Domain.Tests/AutoData/Customizations/AllFeaturesEnabledCustomization.cs`

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

Apply per test:
```csharp
[Theory, AutoTestData(typeof(AllFeaturesEnabledCustomization))]
public async Task Works_with_all_flags_on(...) { ... }
```
</enable_all_flags>

<real_test_example>
From `UserJwtQueryHandlerTests.cs`:

```csharp
[Theory, AutoTestData]
public async Task Return_empty_string_when_feature_flag_is_disabled(
    [Frozen] IFeatureFlagProvider featureFlagProvider,
    UserJwtQueryHandler sut,
    UserJwtQuery query,
    CancellationToken cancellationToken)
{
    A.CallTo(() => featureFlagProvider.IsFeatureEnabled<JIMS6015_Enable_Intercom_Chat>(false))
        .Returns(false);

    var result = await sut.Handle(query, cancellationToken);

    result.ShouldBeEmpty();
}
```
</real_test_example>

<test_coverage_rule>
For every flag-gated branch, write:
1. One test with flag `true` (new path)
2. One test with flag `false` (old/default path)
</test_coverage_rule>
