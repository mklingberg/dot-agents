# Slice template

A vertical slice is one folder per use case under `Features/<Area>/<UseCase>/`. Everything that use case needs lives in that folder. Cross-slice sharing is opt-in via `Shared/`, never inherited from a base class.

## Folder shape

```
src/MyService/
├── Features/
│   └── Orders/
│       ├── CreateOrder/
│       │   ├── CreateOrder.cs           ← request + endpoint mapping + handler + validator
│       │   └── CreateOrderTests.cs      ← (or mirrored under test/)
│       ├── GetOrder/
│       │   └── GetOrder.cs
│       └── _Shared/
│           └── OrderDbContext.cs        ← scoped to Orders area, only if shared by 2+ slices
├── Shared/
│   ├── Errors/
│   ├── Validation/                       ← endpoint filter + base validator helpers
│   └── Auth/
├── Infrastructure/
│   ├── Persistence/                      ← DbContext registration, Migrations/
│   └── Observability/
├── Program.cs
└── MyService.csproj
```

## One-file-per-slice convention

Default: collapse Endpoint + Request + Handler + Validator into **one file** per slice. The slice is the unit of change; splitting four files for what is one feature adds navigation tax with no payoff. Split into multiple files only when a single class exceeds ~150 lines.

```csharp
// Features/Orders/CreateOrder/CreateOrder.cs
namespace MyService.Features.Orders.CreateOrder;

public static class CreateOrder
{
    public sealed record Request(string CustomerId, IReadOnlyList<LineItem> Items);
    public sealed record Response(Guid OrderId);
    public sealed record LineItem(string Sku, int Quantity);

    public sealed class Validator : AbstractValidator<Request>
    {
        public Validator()
        {
            RuleFor(x => x.CustomerId).NotEmpty();
            RuleFor(x => x.Items).NotEmpty();
            RuleForEach(x => x.Items).ChildRules(item =>
            {
                item.RuleFor(i => i.Sku).NotEmpty();
                item.RuleFor(i => i.Quantity).GreaterThan(0);
            });
        }
    }

    public sealed class Handler(OrdersDbContext db, TimeProvider clock, ILogger<Handler> logger)
    {
        public async Task<Results<Created<Response>, ValidationProblem>> Handle(
            Request request,
            CancellationToken cancellationToken)
        {
            var order = new Order(
                Id: Guid.CreateVersion7(),
                CustomerId: request.CustomerId,
                CreatedAt: clock.GetUtcNow(),
                Items: request.Items.Select(i => new OrderItem(i.Sku, i.Quantity)).ToList());

            db.Orders.Add(order);
            await db.SaveChangesAsync(cancellationToken);

            logger.LogInformation("Order {OrderId} created for {CustomerId}", order.Id, request.CustomerId);

            return TypedResults.Created($"/orders/{order.Id}", new Response(order.Id));
        }
    }

    public static void Map(IEndpointRouteBuilder app) =>
        app.MapPost("/orders", (
                Request request,
                Handler handler,
                CancellationToken cancellationToken)
            => handler.Handle(request, cancellationToken))
            .AddEndpointFilter<ValidationFilter<Request>>()
            .RequireAuthorization("orders:write")
            .WithName(nameof(CreateOrder))
            .WithTags("Orders");
}
```

In `Program.cs`:
```csharp
app.MapGroup("/v1").CreateOrder.Map(app); // or auto-discover via assembly scan + source generator
```

## Naming

- Folder/file/class share the use-case name: `CreateOrder/CreateOrder.cs` containing `static class CreateOrder`.
- Records: `Request`, `Response`, `LineItem` (nested types — no `CreateOrderRequest` repetition).
- Handler always called `Handler`. Validator always `Validator`. Disambiguation comes from namespace.

## What goes outside a slice

Only the following live in `Shared/` or `Infrastructure/`:
- The `DbContext` (or one per bounded area).
- The validation `IEndpointFilter` implementation.
- The error contract types.
- Auth policies.
- OpenTelemetry / Serilog wiring.

Everything else is in the slice. Resist the urge to extract a "service layer" — handlers ARE the service layer.

## When to split a slice into multiple files

Hit any of these and split:
- Single file > 200 lines.
- Validator has 3+ external dependencies (move to `Validator.cs`).
- Handler has 5+ private helper methods (consider extracting one or two named domain methods).

Splitting is a refactor, not a starting point.

## Tests

Mirror the source path under `test/MyService.Tests/Features/Orders/CreateOrder/CreateOrderTests.cs`. Follow `create-tests-autofixture` skill for unit tests on the handler and validator. Integration tests use `WebApplicationFactory<Program>` and live under `test/MyService.IntegrationTests/`.
