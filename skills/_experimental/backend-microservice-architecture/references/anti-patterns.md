# Anti-patterns — Pass 2 walk

Walk both lists line by line against the Pass 1 plan. For each item, the plan must either NOT exhibit the pattern OR justify it explicitly under the "Justified when" column.

---

## Over-engineering

### Premature Clean Architecture 4-project split
**Pattern:** Domain / Application / Infrastructure / Api projects on day 1 of a single-bounded-context service.
**Cost:** Indirection, 4× project files to maintain, abstractions invented for layers that have one implementation. Refactoring crosses project boundaries.
**Justified when:** Multiple bounded contexts in one solution, OR domain logic is reused across multiple hosts (web + worker + CLI), OR strict regulatory isolation requires separate compilation units.
**Default instead:** Single project, `Features/` folder. Promote to multi-project when one of the above arrives.

### Repository wrapper over EF Core
**Pattern:** `IOrderRepository` / `OrderRepository` whose only job is to wrap `DbSet<Order>` and forward calls.
**Cost:** Loses LINQ composability inside handlers. Adds a layer that has nothing to absorb. Tests mock the repository instead of using `WebApplicationFactory` + Testcontainers.
**Justified when:** Two or more genuinely-different storage backends (rare), OR you must hide LINQ from a domain layer that exists for other reasons.
**Default instead:** Inject `DbContext` directly into handlers. Test with `WebApplicationFactory` + Testcontainers, not by mocking.

### DDD aggregates without invariants
**Pattern:** `OrderAggregate`, `OrderService`, `OrderSpecification`, value objects for every primitive — when the entity has no rules to enforce.
**Cost:** Anemic domain model dressed up as DDD. Adds vocabulary and types that don't earn their weight.
**Justified when:** The aggregate enforces real invariants (an Order can't move from Shipped to Pending; stock can't go negative; transitions follow a state machine).
**Default instead:** Anemic record/entity until a rule emerges. Promote to aggregate when the first invariant appears.

### MediatR (or any dispatcher) by reflex
**Pattern:** Adding `IMediator.Send(...)` from every endpoint, with no pipeline behaviours beyond what the platform already gives you.
**Cost:** Indirection without pipeline cross-cuts is pure overhead. Stack traces lose the call site. Plus MediatR is commercial v12+ — license cost for nothing.
**Justified when:** You have 3+ pipeline cross-cuts (logging + validation + transaction + auth) and want them composed declaratively, OR an existing fleet uses it and consistency matters.
**Default instead:** Direct handler call from the endpoint. Upgrade to `Immediate.Apis` (source-gen, free) if pipeline cross-cuts grow.

### AutoMapper for trivial DTO mapping
**Pattern:** `Profile` classes mapping `Order.Name → OrderDto.Name` 1:1.
**Cost:** Magic mapping that breaks at runtime when properties drift. Reflection cost. Profiles drift from reality.
**Justified when:** Mappings are deeply nested or contain transformation logic and there are >10 of them.
**Default instead:** Hand-written mapping methods (`order.ToDto()` extension). Move to source-generated mappers (`Mapperly`) before AutoMapper.

### Generic CRUD endpoints / microservice-per-table
**Pattern:** A service per database table with `GET / POST / PUT / DELETE / LIST` for each.
**Cost:** Schema becomes the API contract. Bounded contexts dissolve. Versioning is impossible.
**Justified when:** The product is genuinely a generic data platform (form builder, headless CMS).
**Default instead:** Endpoints are use cases, not table operations. `POST /orders` not `POST /order-rows`. One service per bounded context, not per table.

### Premature event-driven (queue/stream before need)
**Pattern:** Kafka / Service Bus / RabbitMQ added on day 1 "for future scalability."
**Cost:** Distributed-systems complexity (ordering, retries, dead-letters, schema registry) for use cases that are synchronous today.
**Justified when:** Cross-service workflows exist today, OR audit trail / replay is a real requirement, OR an HTTP call would block too long for the consumer.
**Default instead:** Synchronous HTTP between services. Add async messaging the first time you have a real reason.

### Custom `Result<T>` at the API boundary
**Pattern:** Hand-rolled `Result<T, Error>` type returned from endpoints, then mapped to HTTP somewhere generic.
**Cost:** Reinvents `TypedResults` + `ProblemDetails`. Two error contracts (yours and the platform's) that drift.
**Justified when:** `Result<T>` is internal to the service layer with multiple error branches — fine. At the HTTP boundary — not.
**Default instead:** `Results<Ok<T>, ValidationProblem, ProblemHttpResult>` from `TypedResults`. The platform owns the wire format.

### Hexagonal / onion / ports-and-adapters for a CRUD service
**Pattern:** Ports, adapters, dependency-inverted infrastructure for a service whose job is to put rows in and pull rows out.
**Cost:** Architecture cosplaying a problem the service doesn't have.
**Justified when:** The service has rich domain logic that is reused across delivery mechanisms (web + worker + CLI + scheduled job).
**Default instead:** Vertical slices. The slice IS the boundary.

---

## Under-engineering

### No validation pipeline
**Smell:** Validation logic inline in handlers; same rule re-implemented per endpoint; inconsistent error shapes.
**Cost:** Drift, duplication, untestable rules, inconsistent client errors.
**Justified to skip when:** Truly never — even a 2-field DataAnnotations check beats inline `if` checks.
**Fix:** FluentValidation + endpoint filter (see `program-cs-skeleton.md`).

### No error contract
**Smell:** `{"error": "..."}`, `{"message": "..."}`, `{"code": "..."}` returned from different endpoints with different shapes.
**Cost:** Clients can't generalise error handling. OpenAPI docs are wrong. Versioning errors is impossible.
**Justified to skip when:** Never.
**Fix:** `AddProblemDetails()` + `UseExceptionHandler()` + `UseStatusCodePages()`. RFC 7807 ProblemDetails for everything.

### No CancellationToken plumbing
**Smell:** Handlers, services, EF Core calls without `CancellationToken` propagated.
**Cost:** Cancelled requests still hit the DB, run to completion, hold connections, waste resources. Shutdown hangs.
**Justified to skip when:** Never.
**Fix:** Every async public method takes `CancellationToken` and passes it down. EF Core's `*Async` overloads all accept one — use them.

### No observability from day 1
**Smell:** No OpenTelemetry, no correlation ID, just `_logger.LogInformation(...)` plain text.
**Cost:** Production debugging is blind. SLO measurement is impossible. The first incident reveals the gap.
**Justified to skip when:** A throwaway prototype not running in production. Otherwise never.
**Fix:** `AddOpenTelemetry()` with ASP.NET, HTTP client, EF Core instrumentation + OTLP exporter. Or `AddServiceDefaults()` from .NET Aspire.

### No idempotency on commands
**Smell:** `POST /orders` can be called twice and creates two orders.
**Cost:** Duplicates from network retry / client bug / browser back button. Compliance issues. Reconciliation hell.
**Justified to skip when:** The command is naturally idempotent (uses a client-supplied ID; UPSERT semantics).
**Fix:** `Idempotency-Key` header → `IdempotencyKeys` table keyed by `(consumer, key)` storing the original response. Replay if seen.

### Exposing entities directly
**Smell:** API returns `Order` entity straight from EF.
**Cost:** Schema leak. Circular reference serialisation explosions. Versioning impossible — every column add is a contract change. N+1 from lazy navigation properties.
**Justified to skip when:** Never at a public API. Internal admin endpoints — be careful but acceptable.
**Fix:** A `Response` record per slice. `.Select(x => new Response(...))` projects in-DB.

### No outbox when DB writes have side-effects
**Smell:** Inside a handler: `db.Orders.Add(order); db.SaveChangesAsync(); await bus.Publish(...)`.
**Cost:** If `bus.Publish` fails after `SaveChanges` succeeds, the event is lost. If `SaveChanges` succeeds and the process dies before publish, the event is lost. Dual-write problem.
**Justified to skip when:** No external side-effect (pure DB write), OR side-effect is idempotent AND its loss is tolerable.
**Fix:** Transactional outbox — write `outbox` row in same transaction; relay worker publishes and marks sent.

### No health checks
**Smell:** No `/health/live` or `/health/ready`. Orchestrator can't tell if the pod is healthy.
**Cost:** Bad rollouts not caught. Dead pods serve traffic. Slow startup pods get traffic before warm-up.
**Justified to skip when:** Never on a hosted service.
**Fix:** `MapHealthChecks("/health/live")` (process is up) and `MapHealthChecks("/health/ready")` (deps reachable — DB ping, downstream ping).

### No request timeouts on outbound calls
**Smell:** `HttpClient` calls without `Timeout` or `CancellationToken` from the inbound request.
**Cost:** A slow downstream pins all your threads. One slow dependency cascades to a service-wide outage.
**Justified to skip when:** Never.
**Fix:** Configure named `HttpClient` with `Timeout`, propagate inbound `CancellationToken`, add Polly resilience handler (retry + circuit breaker).
