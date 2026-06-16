# C# / .NET / HotChocolate / EF Core review reference

Loaded when the diff contains `.cs` / `.csproj` or HotChocolate / EF Core packages.
Apply on top of the universal pillars in SKILL.md. Stack-specific defects only —
generic correctness/security/perf live in the universal pillars.

---

## C# language

- **Nullable reference types enabled** (`<Nullable>enable</Nullable>`). No `!` ("dammit operator") in product code unless invariant is enforced and commented.
- **`var` only when type is obvious** from the right-hand side. `var x = GetThing();` where the return type isn't visible is a smell.
- **Records for DTOs / value objects.** `record` for immutable data, `record class` if reference equality matters less than value semantics, `record struct` for small value types. Don't use mutable `class` for DTOs.
- **`sealed` by default** on classes not designed for inheritance — better perf, clearer intent.
- **`readonly` fields, `init` setters** — immutability is the default.
- **No `dynamic`, no `object`** without justification. Reach for generics or interfaces.
- **Pattern matching over type checks.** `if (x is Foo f)` over `if (x.GetType() == typeof(Foo))`.
- **`StringComparison` explicit** on every string compare. `Equals(s, "x")` ambiguous → `Equals(s, "x", StringComparison.OrdinalIgnoreCase)`.
- **No magic strings/numbers.** Constants, enums, or `nameof()`.

## Async / await

- **No `async void`.** Except event handlers. Otherwise `async Task`.
- **No `.Result` / `.Wait()` / `.GetAwaiter().GetResult()`** in async code paths — deadlocks under sync contexts. Flag every occurrence.
- **`CancellationToken` plumbed through** every async public API. Pass to inner async calls. Honor it (`token.ThrowIfCancellationRequested()` at long-running boundaries).
- **`ConfigureAwait(false)`** in library code (NuGet packages, shared assemblies). ASP.NET Core app code doesn't need it (no sync context) — flag if the codebase mixes both styles.
- **`Task.Run` only for CPU-bound work.** Wrapping I/O-bound async in `Task.Run` is anti-pattern.
- **`ValueTask`** only for hot paths where allocations matter and the result is often synchronous. Don't sprinkle.
- **No fire-and-forget tasks** without exception handling — unobserved exceptions terminate the process in some configs.
- **Parallelism**: `Parallel.ForEachAsync` or `Task.WhenAll` for independent ops. Watch for shared state.

## Resource management

- **`using` / `await using`** on every `IDisposable` / `IAsyncDisposable`. `HttpClient` typically not disposed per-call (use `IHttpClientFactory`).
- **Streams, readers, db connections** disposed.
- **`IAsyncDisposable`** properly chained — `DisposeAsyncCore` pattern when subclassing.

## Dependency injection

- **Lifetimes correct.** `Singleton` cannot depend on `Scoped` (captures stale scope). Validate via `BuildServiceProvider(validateScopes: true)` in dev.
- **`HttpClient`** via `IHttpClientFactory`, not `new HttpClient()`.
- **`DbContext` is Scoped** by registration. In parallel/background work, resolve a fresh scope; do not pass `DbContext` across threads.
- **No service locator** (`IServiceProvider.GetService` inside business code) — constructor inject.

## EF Core

- **`AsNoTracking()` on read-only queries.** Flag tracked queries that don't need tracking.
- **Projection before materialization.** `.Select(x => new Dto { ... }).ToListAsync()` not `.ToListAsync().Select(...)`. The latter pulls every column.
- **N+1 detection.** Loops calling `await db.X.FirstAsync(...)` per item → batch with `.Where(x => ids.Contains(x.Id))` or `Include`. Lazy loading enabled is a code smell on its own.
- **`Include` only what you need** — avoid cartesian explosion. `.AsSplitQuery()` for multiple collection includes.
- **Pagination always.** No `.ToListAsync()` on user-facing queries without `Skip`/`Take` or keyset pagination.
- **No raw SQL via string interpolation.** `FromSqlInterpolated` (parameterized) or `FromSqlRaw` with explicit params. Never `FromSqlRaw($"SELECT ... WHERE id = {userInput}")`.
- **Migrations checked in** alongside model changes. Migration name describes intent.
- **Concurrency tokens** (`[ConcurrencyCheck]` / `RowVersion`) on entities that race.
- **`SaveChangesAsync` once per unit of work**, not per entity in a loop.
- **Compiled queries** for hot paths.

## HotChocolate (GraphQL)

- **DataLoader for every 1→N field.** Resolver doing per-item DB calls in a list field is N+1 — wrap in `IDataLoader<TKey, TValue>` (`BatchDataLoader` / `GroupedDataLoader`).
- **`IDbContextFactory<T>` in resolvers, not scoped `DbContext`.** HotChocolate executes resolvers in parallel; sharing a scoped `DbContext` across them races. Use `[UseDbContext(typeof(MyContext))]` or `services.AddDbContextFactory<MyContext>()` + `factory.CreateDbContext()`.
- **Middleware order matters.** On `IQueryable`-returning resolvers: `[UsePaging] [UseProjection] [UseFiltering] [UseSorting]` — `UseProjection` last so projection is applied after filter/sort. Wrong order silently breaks projection.
- **Return `IQueryable<T>` from resolvers**, not `List<T>`. Materializing early defeats projection and pushes filter/sort to memory.
- **Pagination configured.** `[UsePaging(MaxPageSize = N, IncludeTotalCount = true)]` — never unbounded `[UsePaging]` on large tables. Cursor (`UsePaging`) for stable lists, offset (`UseOffsetPaging`) when client needs jumps.
- **Field-level authorization.** `[Authorize(Policy = "...")]` on the field — relying on top-level auth misses sub-fields. Especially mutations and sensitive scalars.
- **Query complexity / depth limits** configured: `AddMaxExecutionDepthRule`, `AddCostAnalyzer`. Flag absence on public-facing schemas.
- **Persisted queries / trusted documents** in production. Don't ship a public endpoint accepting arbitrary queries.
- **Errors via `IError` / `ErrorBuilder` / mutation error unions.** Don't throw raw exceptions to bubble up — they leak stack traces and bypass error filters. Mutations follow `Input` + `Payload` (with `errors` union) pattern.
- **Mutation conventions.** Single `Input` arg type, single `Payload` return type, payload includes both success data and typed errors.
- **Schema nullability deliberate.** GraphQL nullable-by-default ≠ C# nullable. Annotate `[GraphQLNonNullType]` / use C# nullable refs to drive schema correctness. Non-nullable list of nullable items (`[Foo!]` vs `[Foo]!`) chosen consciously.
- **Subscriptions backplane** configured (Redis / etc.) for multi-instance. In-memory only works single-process.
- **Schema diff in CI.** Breaking changes flagged before merge. `[GraphQLDeprecated]` for sunsetting fields, with timeline.
- **Naming.** PascalCase types, camelCase fields, `Input` / `Payload` suffixes. Don't expose DB column names directly — schema is API surface, not ORM dump.
- **Global object identification (Relay)** consistent if used — every node type implements `Node`, IDs encoded uniformly.

## ASP.NET Core / Web API

- **Minimal APIs or Controllers** consistently — don't mix without reason.
- **`[FromBody]` / `[FromQuery]` / `[FromRoute]` explicit** on minimal API and controller params.
- **Validation** via FluentValidation or DataAnnotations + `ModelState` check / endpoint filter. Don't trust client input.
- **`ProducesResponseType`** documented for OpenAPI accuracy.
- **`CancellationToken`** in every endpoint signature.
- **Auth** via policies, not hard-coded role strings scattered across endpoints.
- **CORS** scoped — no `AllowAnyOrigin` + credentials.
- **Rate limiting** on auth and write endpoints.

## MediatR / CQRS (if used)

- **Handler does one thing.** Validation in a separate `IPipelineBehavior` or FluentValidation validator, not inline.
- **Commands return either `Unit` or a result type — not the full entity.** Queries return DTOs, not entities.
- **No cross-handler calls.** Handlers don't `Send` to other handlers — extract shared logic to a service.
- **Pipeline behaviors** for cross-cutting (logging, validation, transactions) — not in handlers.

## Logging & observability

- **Structured logging.** `_logger.LogInformation("User {UserId} did {Action}", userId, action)` — no string interpolation in the template.
- **No PII / secrets / tokens** in logs.
- **Exceptions logged with context** (`LogError(ex, "...")`), not swallowed.
- **OpenTelemetry / Activity** for request tracing on service boundaries.

## Testing

- **xUnit + AutoFixture + FakeItEasy** per project conventions (see `create-tests-autofixture` skill if present).
- **Theory over Fact** when the test parametrizes.
- **No real DB / real network** in unit tests. Integration tests separate.
- **`WebApplicationFactory<T>`** for integration tests; `Testcontainers` for real DB scenarios.
- **Async tests return `Task`**, never `async void`.

## Common smells (always flag)

- `Task.Run(() => SomeAsyncMethod()).Result` — double anti-pattern.
- `catch (Exception) { }` — silent swallow.
- `catch (Exception ex) { throw ex; }` — resets stack trace; use `throw;`.
- `DateTime.Now` in business logic — use `DateTimeOffset.UtcNow` or an injected `IClock` / `TimeProvider`.
- `Guid.NewGuid()` scattered — inject for testability if it matters.
- Public mutable fields on entities/DTOs.
- `string.Format` / interpolated strings in SQL queries.
- `_dbContext` shared across parallel resolver calls.
- Resolvers materializing entire tables before filtering.
- `[UsePaging]` without `MaxPageSize`.
