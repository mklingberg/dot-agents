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
- One test per behavior — small, focused tests
- Validators: one nested class per field, one test per rule
- Keep tests DRY — use custom attributes and customizations for shared setup, but avoid over-abstraction that makes tests hard to read
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
- All tests pass: `dotnet test`
</success_criteria>
