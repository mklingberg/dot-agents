---
name: write-tests
description: Write unit tests using xUnit, AutoFixture, AutoData, and FakeItEasy following project conventions. Use when writing tests, creating test classes, adding test cases, or when the user asks to test a handler, validator, or service.
argument-hint: [class-or-file-to-test]
allowed-tools: Read, Grep, Glob, Bash(dotnet test *), Write, Edit, Agent
---

<objective>
Write unit tests for handlers, validators, and services using xUnit, AutoFixture, AutoData, and FakeItEasy. Tests follow strict project conventions for naming, layout, data attributes, and assertions.
</objective>

<quick_start>
Before writing any test:

1. Read the class under test — understand constructor dependencies, `Handle` signature, return type, all code paths
2. Read existing tests in the same domain folder for area-specific patterns
3. Check `test/MyWalley.Domain.Tests/AutoData/` and `AutoData/Customizations/` for reusable customizations
</quick_start>

<conventions>
**File layout**
- Source: `src/MyWalley.Domain/{Domain}/{Queries|Commands}/{Class}.cs`
- Test: `test/MyWalley.Domain.Tests/{Domain}/{Queries|Commands}/{Class}Tests.cs`
- Custom data attributes: `test/MyWalley.Domain.Tests/AutoData/{Name}Data.cs`
- Customizations: `test/MyWalley.Domain.Tests/AutoData/Customizations/{Name}Customization.cs`

**Naming**
- Test class: `{ClassUnderTest}Tests`
- Nested groups: `Handle_Should`, `Validate_Should`
- Methods: verb-first with underscores — `Return_error_when_not_found`, `Call_api_with_registration_number`

**Data attributes**
- **Default:** `[Theory, AutoTestData]` — use unless you have a reason not to
- **Custom:** when 3+ tests need identical complex setup or validators need valid baseline data
- **InlineTestData:** `[InlineTestData<AutoTestData>("value")]` for parameterized tests with fixed + auto values

Custom attribute pattern:
```csharp
public class {Name}Data() : AutoDataAttribute(() => new Fixture()
    .Customize(new DefaultCustomizations())
    .Customize(new {Specific}Customization()));
```

**[Frozen] parameter ordering — CRITICAL**

`[Frozen]` parameters MUST come before the SUT. AutoFixture injects in declaration order.

```csharp
public async Task My_test(
    [Frozen] IDependency dep,           // 1. frozen dependencies
    [Frozen] ConcreteType response,     // 2. frozen concrete types
    MyHandler sut,                       // 3. SUT (receives frozen instances)
    MyCommand command,                   // 4. inputs (not frozen)
    CancellationToken cancellationToken) // 5. cancellation token
```

Only freeze what you configure (`A.CallTo`) or verify (`MustHaveHappened`). Do not freeze inputs or CancellationToken.

**Assertions**
- Use **Shouldly** for all assertions
- Exception: use `Assert.ThrowsAsync<T>` for exception testing

**DefaultCustomizations (already configured via `[AutoTestData]`)**

| What | Effect |
|------|--------|
| AutoFakeItEasy | All interfaces auto-mocked (`ConfigureMembers = true`) |
| Feature flags | All flags return `true` |
| MediatR Unit | `Unit.Value` injected |
| Streams | Return 3 items |
| CancellationToken | `CancellationToken.None` injected |
| RegistrationNumber | Valid Swedish SSN for any `RegistrationNumber` string property |

Do NOT reconfigure any of the above in tests.
</conventions>

<setup_strategy>
**Happy-path-first with minimal per-test setup**

Structure every test class around one canonical happy path, then express each scenario as the *smallest possible deviation* from it.

1. **Define the happy path** — identify the configuration where all dependencies succeed, all inputs are valid, and the expected result is the normal case. Build this via a custom `[Data]` attribute (or `[AutoTestData]` if no complex setup is needed) composed of focused, reusable customizations.

2. **One change per test** — each test should only configure what makes *that scenario* different from the happy path. Override one return value, mutate one field, disable one flag. Everything else comes from the happy-path baseline.

3. **Extract when repeated** — if the same setup appears in 2 or more tests, pull it into its own `Customization`. The threshold is **2 tests**.

4. **Composable customizations** — each `Customization` must have a single responsibility. Build the happy path by composing several small customizations, not by writing one big one. This makes individual customizations reusable across test classes.

```csharp
// ✅ Composable: each customization does one thing
public class MyHandlerData() : AutoDataAttribute(() => new Fixture()
    .Customize(new DefaultCustomizations())
    .Customize(new ActiveAccountCustomization())   // account state
    .Customize(new ValidContractCustomization())    // contract shape
    .Customize(new FeatureFlagEnabledCustomization())); // flag override

// Then in each test, only change what differs:
[Theory, MyHandlerData]
public async Task Return_error_when_contract_is_expired(
    [Frozen] IContractRepository repo,
    MyHandler sut,
    MyQuery query,
    CancellationToken cancellationToken)
{
    // Only this one thing differs from the happy path:
    A.CallTo(() => repo.GetAsync(query.ContractId, cancellationToken))
        .Returns(new Contract { Status = ContractStatus.Expired });

    var result = await sut.Handle(query, cancellationToken);

    result.IsError.ShouldBeTrue();
}
```

**Decision flow**
- Need custom setup for 1 test → configure inline on the frozen dependency or mutate the input object
- Same setup in 2+ tests → extract to a new `Customization` in `AutoData/Customizations/`
- Multiple customizations always needed together → compose them in a custom `[Data]` attribute
- Never add all setup into one large customization — keep each one focused and independently reusable
</setup_strategy>

<common_patterns>
<pattern name="handler_test">
```csharp
namespace MyWalley.Domain.Tests.{Domain}.{Queries|Commands};

public class {Handler}Tests
{
    public class Handle_Should
    {
        [Theory, AutoTestData]
        public async Task Describe_behavior(
            [Frozen] IDependency dep,
            {Handler} sut,
            {QueryOrCommand} request,
            CancellationToken cancellationToken)
        {
            A.CallTo(() => dep.Method(A<Type>._, cancellationToken)).Returns(value);

            var result = await sut.Handle(request, cancellationToken);

            result.ShouldBe(expected);
        }
    }
}
```
</pattern>

<pattern name="validator_test">
```csharp
public class {Validator}Tests
{
    [Theory, {ValidatorData}]
    public void Should_validate_valid_command({Validator} sut, {Command} command)
    {
        sut.Validate(command).IsValid.ShouldBeTrue();
    }

    public class {Field}_validation_should
    {
        [Theory, {ValidatorData}]
        public void Fail_on_empty({Validator} sut, {Command} command)
        {
            command.{Field} = string.Empty;

            sut.Validate(command).IsValid.ShouldBeFalse();
        }
    }
}
```
</pattern>
</common_patterns>

<anti_patterns>
- No `// Arrange` / `// Act` / `// Assert` comments — blank lines separate sections
- Do not use `fixture.Customize` for interface mocks — use `fixture.Freeze<T>()` + FakeItEasy
- Do not use `[Fact]` when `[Theory, AutoTestData]` works
- Do not create customizations for one-off setup — modify frozen objects inline
- Do not put all test setup in a single monolithic customization — keep each customization single-purpose and composable
- One test per behavior — small, focused tests
- Validators: one nested class per field, one test per rule
- Keep tests DRY — use custom attributes and customizations for shared setup, but avoid over-abstraction that makes tests hard to read
- Do not repeat inline setup across tests — if the same override appears in 2+ tests, extract it to a `Customization`
</anti_patterns>

<tdd_workflow>
1. **Red** — write `[Theory, AutoTestData]` test first; SUT may not exist yet
2. **Green** — implement just enough to pass; AutoFixture resolves new dependencies automatically
3. **Refactor** — adding constructor params does not break existing tests; add `[Frozen]` only when you need to configure/verify
</tdd_workflow>

<success_criteria>
Tests are well-written when:

- Each test verifies one behavior with a descriptive method name
- `[Frozen]` parameters appear before SUT in correct order
- `[Theory, AutoTestData]` is used unless a custom attribute is justified
- Shouldly assertions are used (except `Assert.ThrowsAsync<T>` for exceptions)
- No AAA comments, no redundant mock setup, no over-customization
- File placement mirrors the source structure
- Test setup is DRY with reusable custom attributes and customizations
- All tests pass: `dotnet test`
</success_criteria>
