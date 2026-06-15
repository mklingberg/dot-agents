---
name: create-tests-autofixture
description: Write xUnit + AutoFixture + AutoData + FakeItEasy unit tests for C#. Triggers: 'write tests', 'test this handler/validator/service', adding test cases.
argument-hint: [class-or-file-to-test]
allowed-tools: Read, Grep, Glob, Bash(dotnet test *), Write, Edit, Agent
---

<objective>
Write unit tests for handlers, validators, and services using xUnit, AutoFixture, AutoData, and FakeItEasy. Tests follow strict conventions for naming, layout, data attributes, and assertions that apply across projects.
</objective>

<quick_start>
Before writing any test:

1. Read the class under test — understand constructor dependencies, method signatures, return types, all code paths
2. Read existing tests in the same area for project-specific patterns
3. Check the project's `AutoData/` and `AutoData/Customizations/` directories for reusable customizations
</quick_start>

<setup>
**Creating a project base data attribute**

Every project should have a shared base attribute that wires up AutoFakeItEasy and common customizations. Create once, reuse everywhere:

```csharp
// {TestProject}/AutoData/AutoTestData.cs
public class AutoTestData() : AutoDataAttribute(() => new Fixture()
    .Customize(new AutoFakeItEasyCustomization { ConfigureMembers = true })
    .Customize(new YourProjectCustomizations())); // add any project-wide defaults
```

**Registration order matters — CRITICAL**

Register `AutoFakeItEasyCustomization` first. Domain customizations registered after it take priority for any type they handle. If you register domain customizations before `AutoFakeItEasyCustomization`, the domain customizations' `ISpecimenBuilder`s may intercept interface requests before FakeItEasy can auto-mock them.

```csharp
// ✅ CORRECT: AutoFakeItEasy first, domain overrides after
new Fixture()
    .Customize(new AutoFakeItEasyCustomization { ConfigureMembers = true })
    .Customize(new MyDomainCustomization()); // wins over AutoFakeItEasy for same type

// ❌ WRONG: domain first can prevent auto-mocking of interfaces
new Fixture()
    .Customize(new MyDomainCustomization())
    .Customize(new AutoFakeItEasyCustomization { ConfigureMembers = true });
```

**ConfigureMembers = true — non-virtual gotcha**

With `ConfigureMembers = true`, AutoFixture configures virtual/abstract members of fakes to return auto-generated values. Non-virtual members are not interceptable by FakeItEasy and will remain `null`/default unless explicitly set.

```csharp
public class MyService
{
    public virtual IDatabase Db { get; set; }   // ✅ configured by FakeItEasy
    public ILogger Logger { get; set; }          // ❌ non-virtual — stays null
}
```

**Creating a customization**
```csharp
// {TestProject}/AutoData/Customizations/{Name}Customization.cs
public class {Name}Customization : ICustomization
{
    public void Customize(IFixture fixture)
    {
        // configure fixture here
    }
}
```

**CompositeCustomization** — alternative to chaining `.Customize()` calls. Useful for grouping a fixed set of customizations under one name:

```csharp
public class AppCustomization : CompositeCustomization
{
    public AppCustomization() : base(
        new AutoFakeItEasyCustomization { ConfigureMembers = true },
        new CircularRefCustomization(),
        new DateTimeCustomization())
    { }
}
```

**Composing into a named data attribute** (when multiple tests share complex setup):
```csharp
public class {Name}Data() : AutoDataAttribute(() => new Fixture()
    .Customize(new AutoFakeItEasyCustomization { ConfigureMembers = true })
    .Customize(new YourProjectCustomizations())
    .Customize(new {Specific}Customization()));
```
</setup>

<conventions>
**File layout**
- Source: `src/{Project}/{Domain}/{Queries|Commands}/{Class}.cs`
- Test: `test/{Project}.Tests/{Domain}/{Queries|Commands}/{Class}Tests.cs`
- Custom data attributes: `test/{Project}.Tests/AutoData/{Name}Data.cs`
- Customizations: `test/{Project}.Tests/AutoData/Customizations/{Name}Customization.cs`

**Naming**
- Test class: `{ClassUnderTest}Tests`
- Nested groups: `Handle_Should`, `Validate_Should`
- Methods: verb-first with underscores — `Return_error_when_not_found`, `Call_api_with_registration_number`

**Data attributes**
- **Default:** `[Theory, AutoTestData]` — use unless you have a reason not to
- **Custom:** when 3+ tests need identical complex setup, or validators need a valid baseline object
- **InlineTestData:** `[InlineTestData<AutoTestData>("value")]` for parameterized tests mixing fixed + auto values

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

Only freeze what you configure (`A.CallTo`) or verify (`MustHaveHappened`). Do not freeze inputs or `CancellationToken`.

**Assertions**
- Use **Shouldly** for all assertions
- Exception: use `Assert.ThrowsAsync<T>` for exception testing
</conventions>

<setup_strategy>
**Happy-path-first with minimal per-test setup**

Structure every test class around one canonical happy path, then express each scenario as the *smallest possible deviation* from it.

1. **Define the happy path** — identify the configuration where all dependencies succeed, all inputs are valid, and the expected result is the normal case. Build this via a custom `[Data]` attribute (or `[AutoTestData]` if no complex setup is needed) composed of focused, reusable customizations.

2. **One change per test** — each test should only configure what makes *that scenario* different from the happy path. Override one return value, mutate one field, disable one flag. Everything else comes from the happy-path baseline.

3. **Extract when repeated** — if the same setup appears in 2 or more tests, pull it into its own `Customization`. The threshold is **2 tests**.

4. **Composable customizations** — each `Customization` must have a single responsibility. Build the happy path by composing several small customizations, not by writing one big one.

```csharp
// ✅ Composable: each customization does one thing
public class MyHandlerData() : AutoDataAttribute(() => new Fixture()
    .Customize(new AutoFakeItEasyCustomization { ConfigureMembers = true })
    .Customize(new YourProjectCustomizations())
    .Customize(new ActiveAccountCustomization())   // account state
    .Customize(new ValidContractCustomization()));  // contract shape

// Then in each test, only change what differs:
[Theory, MyHandlerData]
public async Task Return_error_when_contract_is_expired(
    [Frozen] IContractRepository repo,
    MyHandler sut,
    MyQuery query,
    CancellationToken cancellationToken)
{
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
namespace {Project}.Tests.{Domain}.{Queries|Commands};

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

<advanced_patterns>
**ISpecimenBuilder vs ICustomization**

Use `ICustomization` to configure the fixture pipeline (registering builders, adding behaviors, changing global settings). Use `ISpecimenBuilder` when you need custom creation logic for a specific type. Wrap builders in a customization for reuse:

```csharp
public class PasswordCustomization : ICustomization
{
    public void Customize(IFixture fixture)
        => fixture.Customizations.Add(new PasswordSpecimenBuilder());
}

public class PasswordSpecimenBuilder : ISpecimenBuilder
{
    public object Create(object request, ISpecimenContext context)
    {
        if (request is Type t && t == typeof(Password))
            return new Password("ValidP@ssw0rd");
        return new NoSpecimen();
    }
}
```

**Circular reference entities**

AutoFixture throws by default on circular references (parent → child → parent). Add `OmitOnRecursionBehavior` as a customization:

```csharp
public class CircularRefCustomization : ICustomization
{
    public void Customize(IFixture fixture)
        => fixture.Behaviors.Add(new OmitOnRecursionBehavior());
}
```

Note: `Behaviors` only apply when using `fixture.Create<T>()`, not `fixture.Build<T>()` (see gotcha below).

**OmitAutoProperties — for complex or EF-style entities**

When only a few properties matter and the rest cause noise (navigation properties, large graphs), suppress auto-population:

```csharp
// Per-type in a customization:
fixture.Customize<Order>(c => c
    .OmitAutoProperties()
    .With(x => x.Id)
    .With(x => x.Total));

// One-off in a test:
var order = fixture.Build<Order>()
    .OmitAutoProperties()
    .With(x => x.Status, OrderStatus.Active)
    .Create();
```

**Build<T>() vs Create<T>() — CRITICAL gotcha**

`Build<T>()` creates a fresh, isolated pipeline — it does NOT respect registered `Customize()` calls or `Behaviors` (including `OmitOnRecursionBehavior`). Always prefer `Create<T>()` in tests; use `Build<T>()` only for truly one-off inline overrides where you do not need the pipeline:

```csharp
// ❌ WRONG — OmitOnRecursionBehavior and AutoFakeItEasy are ignored:
var sut = fixture.Build<MyService>().With(x => x.Name, "test").Create();

// ✅ CORRECT — full pipeline applies:
fixture.Customize<MyService>(c => c.With(x => x.Name, "test"));
var sut = fixture.Create<MyService>();
```
</advanced_patterns>

<anti_patterns>
- No `// Arrange` / `// Act` / `// Assert` comments — blank lines separate sections
- Do not use `fixture.Customize` for interface mocks — use `fixture.Freeze<T>()` + FakeItEasy
- Do not use `[Fact]` when `[Theory, AutoTestData]` works
- Do not create customizations for one-off setup — modify frozen objects inline
- Do not put all test setup in a single monolithic customization — keep each customization single-purpose and composable
- One test per behavior — small, focused tests
- Validators: one nested class per field, one test per rule
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
- Test setup is DRY with reusable custom attributes and composable customizations
- All tests pass: `dotnet test`
</success_criteria>
