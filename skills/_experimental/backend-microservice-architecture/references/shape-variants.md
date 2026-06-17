# Shape variants

The default skill path is HTTP minimal API. This file covers the four other shapes a service might take. Each section lists the host pattern, slice anatomy adjustments, and what changes from the HTTP defaults.

---

## Worker / queue consumer

**Host:** `BackgroundService` (or `IHostedLifecycleService` when you need ordered start/stop hooks).

**When to choose:** the service has no synchronous request/response — it pulls work from a queue, schedule, or stream.

**Skeleton:**

```csharp
public sealed class OrderEventConsumer(
    IDbContextFactory<OrdersDbContext> dbFactory,
    IServiceBusReceiver receiver,
    ILogger<OrderEventConsumer> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await foreach (var message in receiver.ReceiveAllAsync(stoppingToken))
        {
            using var activity = ActivitySource.StartActivity("ProcessOrderEvent");
            await using var db = await dbFactory.CreateDbContextAsync(stoppingToken);

            try
            {
                await Handle(message, db, stoppingToken);
                await db.SaveChangesAsync(stoppingToken);
                await receiver.CompleteAsync(message, stoppingToken);
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                logger.LogError(ex, "Failed to process {MessageId}", message.Id);
                await receiver.AbandonAsync(message, stoppingToken);
            }
        }
    }
}
```

**Slice anatomy:** identical to HTTP — `Features/<Area>/<UseCase>/<UseCase>.cs` containing `Request` (the message contract), `Handler`, `Validator`. The host invokes the handler instead of an HTTP endpoint.

**Key differences from HTTP defaults:**
- `IDbContextFactory<T>`, not scoped `DbContext` — a worker has no per-request scope.
- Cancellation comes from `stoppingToken`, not `HttpContext.RequestAborted`.
- Errors map to retry/dead-letter, not HTTP status codes — no `ProblemDetails`.
- Idempotency by message ID (or business key) is **not optional** — networks redeliver.

---

## GraphQL via HotChocolate v15+

**Host:** ASP.NET Core + HotChocolate.

**When to choose:** the consumer is a federated graph or a UI that needs flexible projection. Don't add GraphQL for an internal service-to-service call — REST is simpler.

**Skeleton:**

```csharp
builder.Services
    .AddDbContextFactory<OrdersDbContext>(o => o.UseNpgsql(connStr))
    .AddGraphQLServer()
    .AddQueryType<OrderQuery>()
    .AddMutationType<OrderMutation>()
    .RegisterDbContextFactory<OrdersDbContext>()
    .AddProjections()
    .AddFiltering()
    .AddSorting()
    .AddAuthorization();

app.MapGraphQL();
```

**Slice anatomy adjustment:** the slice exports a query/mutation method, not an endpoint. Same one-file-per-slice rule:

```csharp
public sealed class OrderQuery
{
    [UsePaging(MaxPageSize = 100, IncludeTotalCount = true)]
    [UseProjection]
    [UseFiltering]
    [UseSorting]
    public IQueryable<Order> GetOrders(OrdersDbContext db) => db.Orders;
}
```

**Key differences:**
- `IDbContextFactory<T>` is **mandatory** — resolvers run in parallel; a scoped `DbContext` will race.
- Middleware order: `[UsePaging] [UseProjection] [UseFiltering] [UseSorting]` — projection last.
- N→1 relations use `IDataLoader<TKey, T>` — not lazy navigation properties.
- Errors via mutation `Payload + errors union`, not exceptions; never let raw exceptions reach the wire.
- Pagination: always cap with `MaxPageSize`. Never expose unbounded `[UsePaging]`.
- Field-level `[Authorize(Policy = "...")]` — top-level auth misses sub-fields.

For deeper coverage see `review-code` skill's `references/csharp-backend.md` HotChocolate section.

---

## gRPC

**Host:** ASP.NET Core gRPC.

**When to choose:** internal service-to-service calls where the client is also .NET (code-first), or polyglot clients with a shared `.proto` (proto-first).

**Skeleton (code-first, default for all-.NET fleet):**

```csharp
builder.Services.AddCodeFirstGrpc();

app.MapGrpcService<OrderService>();
```

```csharp
[ServiceContract]
public interface IOrderService
{
    [OperationContract]
    Task<GetOrderReply> GetOrder(GetOrderRequest request, CallContext ctx = default);
}

public sealed class OrderService(OrdersDbContext db) : IOrderService { /* ... */ }
```

**Choose proto-first when:** any consumer is non-.NET, or your org has a shared schema repo.

**Slice anatomy adjustment:** one slice per RPC method. The "endpoint" is the method on the service class; otherwise the structure (Request, Response, Handler, Validator) is identical.

**Key differences from HTTP defaults:**
- No `ProblemDetails` — errors are `RpcException` with status codes (`StatusCode.NotFound`, `StatusCode.InvalidArgument`).
- No URL versioning — version via package name in proto, or service name suffix in code-first.
- Cancellation via `CallContext.CancellationToken` (or `ServerCallContext.CancellationToken`).
- mTLS is the typical auth — JWT bearer is unusual on internal gRPC.

---

## GraphQL + HTTP, or HTTP + worker (hybrid)

**Allowed.** A service can host both an HTTP API and a worker in the same process. Add the `BackgroundService` to DI and map the HTTP endpoints — they coexist.

**When NOT to:** if the worker is high-throughput and the HTTP API is latency-sensitive, the GC and CPU contention will hurt both. Split into two services.
