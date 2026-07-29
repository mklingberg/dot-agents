---
name: backend-microservice-architecture
description: "Architecture direction for new .NET microservices — minimal API + vertical slice. Triggers: 'design this service', 'new microservice', 'project layout', 'vertical slice setup', 'minimal API setup'."
disable-model-invocation: true
---

<objective>
Act as the platform tech lead deciding the shape of a new .NET microservice. The service will be operated for years, read by people who didn't write it, and fail at 3am. Make boring, predictable, conventional choices that age well. The deliberate move is what you choose *not* to add — every layer, library, and abstraction must earn its place against a brief that exists today, not one imagined for later.
</objective>

<quick_start>
If the brief doesn't pin them, state these four inputs before any design:

1. **Bounded context** — one sentence. What does this service own? (e.g. "order intake for the storefront")
2. **Primary consumers** — who calls it? (e.g. "storefront BFF + retail ops dashboard")
3. **Top 1–3 use cases** — the commands/queries this service exists to serve.
4. **Hard NFRs that change shape** — only the ones that move the architecture (sub-50ms p99, >1k rps, strong consistency, exactly-once, multi-region). Skip generic "fast and reliable" — that's not an NFR.

If any are missing, pin them yourself with the most likely answer and state the assumption. Then run the two-pass process.
</quick_start>

<principles>
**Slice as unit.** A feature is the only first-class concept. Layers (domain/application/infra) are an implementation detail of a slice, not a project structure. Folders are organised by use case (`CreateOrder/`), not by technical role (`Controllers/`, `Services/`).

**Layers earn their existence.** A layer is justified only when it absorbs a real change. A `Domain` project is justified when domain rules will be reused across multiple hosts. A repository is justified when there are multiple storage implementations or when LINQ-over-EF must be hidden. None of these are true on day 1 of most services.

**Boring beats clever.** Built-in over packaged. Platform over framework. The default answer for any cross-cutting concern is "ASP.NET Core has this." Reach for a library only when the platform answer is materially worse for *this* brief.

**Anti-novelty.** New libraries do not earn defaults. The skill's defaults track the platform (ASP.NET Core, EF Core, OpenTelemetry, FluentValidation), not whatever is trending on dev blogs this quarter. A pattern enters the defaults only after it has shipped in production at multiple teams for a year.

**Observability is day-1, not later.** Logs, traces, metrics, correlation, cancellation propagation — wired in `Program.cs` before the first endpoint. Adding observability after an incident is too late.

**Contracts are forever.** The HTTP/queue/proto surface is the public API. Versioning, error contract, and request/response shapes are designed deliberately and stay stable. DTOs are not entities.

**Explicit non-decisions.** Every layer or library you skip is a deliberate choice. State them. "No Domain project," "no MediatR," "no repository wrapper" are first-class outputs of the design — not omissions.
</principles>

<process>
Work in two passes.

**Pass 1 — Design plan.** Produce six rows + an explicit non-decisions block. Keep each row to one or two lines.

```
## Direction

- **Shape:** <HTTP minimal API | worker | GraphQL | gRPC | hybrid>. Bounded context: <one sentence>.
- **Layout:** <single project + Features/ | other>. Migrations in <where>. Shared/ holds <what>.
- **Slice anatomy:** <file template per feature — Endpoint.cs, Request.cs, Handler.cs, Validator.cs, Tests mirror>.
- **Cross-cutting:** validation: <FluentValidation + endpoint filter>; errors: <ProblemDetails (RFC 7807) + TypedResults>; logging: <Serilog | built-in>; auth: <JWT bearer | mTLS | none>; observability: <OpenTelemetry OTLP | Aspire ServiceDefaults>.
- **Persistence:** <EF Core 9/10 + Postgres | none>. Schema owned by this service. DbContext lifetime: <scoped | factory for workers>. Migrations: <where checked in>.
- **Contract:** <REST + JSON | GraphQL | gRPC>. Versioning: <URI /v1 | header | none>. Error contract: <ProblemDetails>.

## Explicit non-decisions
- No Domain/Application/Infra split — premature for one bounded context.
- No MediatR — direct handler invocation from endpoints; revisit if pipeline cross-cuts grow past 2.
- No repository wrapper over DbContext — EF Core IS the data access abstraction.
- No DDD aggregates — anemic models until invariants emerge.
- No AutoMapper — hand-written mapping methods until they exceed ~5 fields with logic.
- <add others made for this brief>
```

Read `references/slice-template.md` for the feature file template, `references/program-cs-skeleton.md` for the host wiring, `references/persistence.md` for EF Core defaults, and `references/shape-variants.md` if the brief is anything other than HTTP minimal API.

**Pass 2 — Anti-defaults check.** Walk both anti-default lists in `references/anti-patterns.md` line by line against the Pass 1 plan. For each item:

- Confirm the plan does NOT fall into it, OR
- State explicitly why this brief justifies it (the "Justified when" column gives the bar).

If any item is hit without justification, revise the plan before writing code. The narrative principle: a reader should be able to point at the plan and say "every choice here is what I'd expect for this brief, no more and no less."

Only after Pass 2 do you write code — following Pass 1 exactly, deriving the slice structure and Program.cs from the references.
</process>

<defaults>
The defaults the skill recommends, current as of 2026. Override per-brief when justified, but state the deviation.

| Concern | Default | Upgrade when |
|---------|---------|--------------|
| Service shape | HTTP minimal API | Async ingest → worker. Polyglot clients → gRPC. Federated graph → HotChocolate. |
| Dispatch | Direct handler call from endpoint | Pipeline cross-cuts > 2 → Immediate.Apis (source-gen). Existing MediatR fleet → keep. |
| Result type | `TypedResults.Ok/BadRequest/Problem(...)` | Internal service layer with many branches → `ErrorOr<T>` or `Result<T, Error>`. |
| Validation | FluentValidation 12+ via `IEndpointFilter` | Trivial 2-field input → DataAnnotations is fine. |
| Error contract | RFC 7807 `ProblemDetails` via `AddProblemDetails()` | Never deviate at the HTTP boundary. |
| OpenAPI | `Microsoft.AspNetCore.OpenApi` (built-in .NET 9+) | Need OpenAPI v3.1 features unsupported → Swashbuckle. |
| Versioning | `Asp.Versioning.Http` v8+, URI path `/v1` | Internal-only service → skip versioning until first breaking change. |
| Persistence | EF Core 9/10, scoped `DbContext` per request | Background work → `IDbContextFactory<T>`. Bulk perf hot path → Dapper sidecar. |
| Observability | OpenTelemetry OTLP exporter + ASP.NET + EF Core instrumentation | Greenfield → wire `.AddServiceDefaults()` from .NET Aspire (gives OTel + health checks). |
| Auth | JWT bearer via `AddAuthentication().AddJwtBearer()` + policy-based authz | Service-to-service in mesh → mTLS, no JWT. |
| Testing | xUnit + AutoFixture + FakeItEasy (unit); `WebApplicationFactory<Program>` + Testcontainers (integration) | E2E across services → `Aspire.Hosting.Testing`. |
</defaults>

<see_also>
- `create-feature-branch` — start the work on a properly-named branch.
- `create-tests-autofixture` — slice tests using xUnit + AutoFixture + FakeItEasy.
- `review-code` — pre-PR review against C#/.NET conventions.
- `azure-devops` — open the PR in Azure DevOps.
- `create-feature-flags` — gate rollout via LaunchDarkly when shipping behind a flag.
</see_also>

<reference_index>
| Read this | When |
|-----------|------|
| `references/slice-template.md` | Drafting the file template for a feature slice; deciding what goes in each file. |
| `references/program-cs-skeleton.md` | Wiring `Program.cs` — DI, OTel, ProblemDetails, auth, validation filter, route groups. |
| `references/shape-variants.md` | The brief is a worker, GraphQL service, or gRPC service — read the matching section. |
| `references/persistence.md` | DbContext lifetime, IDbContextFactory, migrations location, schema ownership, AOT. |
| `references/anti-patterns.md` | Pass 2 — walk the over- and under-engineering lists against the Pass 1 plan. |
</reference_index>

<success_criteria>
- All four brief inputs explicitly stated (bounded context, consumers, use cases, hard NFRs) before any design.
- Pass 1 produces the six-row direction + explicit non-decisions block.
- Pass 2 walks both anti-default lists; every hit is either eliminated or justified in the plan text.
- Defaults table choices stated by name; any deviation from defaults is called out with reason.
- Slice structure follows `references/slice-template.md`; `Program.cs` follows `references/program-cs-skeleton.md`.
- Observability, error contract, validation, and CancellationToken propagation are wired before the first endpoint, not after.
- DTOs at the API boundary; entities never leave the persistence layer.
</success_criteria>
