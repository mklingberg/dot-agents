# Persistence

Default: **EF Core 9/10 + PostgreSQL** (or SQL Server, the choice rarely matters at design level). One `DbContext` per bounded context. The service owns its schema; no other service queries this database directly.

## DbContext lifetime

- **HTTP services:** `AddDbContext<T>()` — scoped, one per request. Default.
- **Workers / hosted services:** `AddDbContextFactory<T>()` — explicit factory; create one per unit of work. Required because there is no per-request scope.
- **GraphQL (HotChocolate):** `AddDbContextFactory<T>()` + `RegisterDbContextFactory<T>()`. Required because resolvers run in parallel.

```csharp
// HTTP
builder.Services.AddDbContext<OrdersDbContext>(o => o.UseNpgsql(connStr));

// Worker / GraphQL
builder.Services.AddDbContextFactory<OrdersDbContext>(o => o.UseNpgsql(connStr));
```

## Where the code lives

```
src/MyService/
├── Infrastructure/
│   └── Persistence/
│       ├── OrdersDbContext.cs
│       ├── Configurations/
│       │   ├── OrderConfiguration.cs       ← IEntityTypeConfiguration<Order>
│       │   └── OrderItemConfiguration.cs
│       └── Migrations/
│           └── 20260101_InitialCreate.cs
```

Entity types live alongside their slices when used by one slice; promote to `Domain/` (or a `_Shared/` per area) only when shared by multiple slices.

## DbContext shape

```csharp
public sealed class OrdersDbContext(DbContextOptions<OrdersDbContext> options) : DbContext(options)
{
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderItem> OrderItems => Set<OrderItem>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("orders");
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(OrdersDbContext).Assembly);
    }
}
```

- One schema per service (`orders`, `inventory`). Makes ownership explicit at the DB level.
- `IEntityTypeConfiguration<T>` per entity — never inline configuration in `OnModelCreating`.

## Reads

- **`AsNoTracking()` on every query that does not write** — projection alone doesn't disable change tracking.
- **Project before materialising:** `.Select(x => new Dto { ... }).ToListAsync()` — never `.ToListAsync().Select(...)`.
- **Pagination always.** Keyset pagination over `Skip/Take` for stable ordered lists.
- **`Include` only what's needed.** `AsSplitQuery()` for multiple collection includes (avoids cartesian explosion).

## Writes

- One `SaveChangesAsync()` per unit of work — never per-entity in a loop.
- Concurrency tokens (`[ConcurrencyCheck]` or `RowVersion`) on entities that race.
- Use `Guid.CreateVersion7()` for new IDs (sortable; better B-tree behaviour than v4).
- Inject `TimeProvider` (.NET 8+) instead of using `DateTimeOffset.UtcNow` directly — testability.

## Migrations

- One migration per logical change. Migration name describes intent: `AddIdempotencyKeyToOrders`, not `Update1`.
- Migrations checked into source. Generated `Migrations/<timestamp>_<name>.cs` + `Migrations/<DbContext>ModelSnapshot.cs`.
- Apply at deploy, not at app startup, for production. Startup application is fine for dev/local.

## Compiled models

EF Core 8+ compiled models cut cold-start time. Worth it when:
- AOT compilation is on the table.
- Cold-start latency matters (serverless, low-traffic services).

Otherwise skip — the runtime model build is fast enough for warm processes.

## When to reach beyond EF

- **Dapper** for hot-path read queries where projection or shape outpaces what EF generates well. Keep it side-by-side with EF, not as a replacement.
- **Raw SQL via `FromSqlInterpolated`** for analytics or reports. Always parameterised; never `FromSqlRaw($"...{userInput}...")`.
- **Bulk extensions** (`EFCore.BulkExtensions`) for >10k-row inserts/updates. EF's change tracker is the bottleneck, not the DB.

## Connection management

- Connection string from configuration, never hard-coded.
- For Postgres, `Npgsql` connection pooling is enabled by default — don't disable.
- `EnableRetryOnFailure()` for transient errors when the DB is across a network with known flakiness (e.g. cloud-managed DB across regions).

## Outbox pattern

If the service writes to the DB AND publishes events / makes external calls, you have a dual-write problem. Outbox:

1. In the same DB transaction as your write, insert a row into `outbox`.
2. A background worker reads `outbox` rows and publishes them, then marks them sent.

Skip only if the side-effect is idempotent and tolerable to lose, or if you have no external side-effects.

## What this skill does NOT default to

- **No repository pattern wrapper over `DbContext`.** EF Core IS the data-access abstraction. A repository is justified only when you have multiple storage backends or need to hide LINQ from a domain layer that exists for other reasons.
- **No Unit-of-Work abstraction.** `DbContext` IS the unit of work. Wrapping it adds zero value.
- **No specifications / `ISpecification<T>`.** LINQ is the specification language. Reach for the pattern only if you need to compose dynamic queries from user input across many entry points.
