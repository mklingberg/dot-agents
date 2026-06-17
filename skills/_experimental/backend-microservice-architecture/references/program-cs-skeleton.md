# Program.cs skeleton

Minimal but complete `Program.cs` for an HTTP minimal API service. Every line is justified — nothing decorative.

```csharp
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using MyService.Features.Orders.CreateOrder;
using MyService.Infrastructure.Persistence;
using MyService.Shared.Validation;
using OpenTelemetry.Metrics;
using OpenTelemetry.Trace;

var builder = WebApplication.CreateBuilder(args);

// --- Configuration ---
// Bind strongly-typed options at startup; fail fast on missing config.
builder.Services.Configure<DatabaseOptions>(builder.Configuration.GetSection("Database"));

// --- Persistence ---
builder.Services.AddDbContext<OrdersDbContext>((sp, options) =>
{
    var dbOptions = sp.GetRequiredService<IOptions<DatabaseOptions>>().Value;
    options.UseNpgsql(dbOptions.ConnectionString);
});

// --- Validation ---
builder.Services.AddValidatorsFromAssemblyContaining<Program>(includeInternalTypes: true);
builder.Services.AddScoped(typeof(ValidationFilter<>));

// --- Slice handlers (transient by default — they own no state) ---
builder.Services.AddTransient<CreateOrder.Handler>();
// ... one line per slice handler, OR use Scrutor / source generator to auto-register

// --- Cross-cutting platform services ---
builder.Services.AddSingleton(TimeProvider.System);
builder.Services.AddProblemDetails(options =>
{
    options.CustomizeProblemDetails = ctx =>
    {
        ctx.ProblemDetails.Extensions["traceId"] = ctx.HttpContext.TraceIdentifier;
    };
});

// --- AuthN / AuthZ ---
builder.Services.AddAuthentication().AddJwtBearer();
builder.Services.AddAuthorizationBuilder()
    .AddPolicy("orders:write", p => p.RequireClaim("scope", "orders:write"))
    .AddPolicy("orders:read", p => p.RequireClaim("scope", "orders:read"));

// --- Observability (OpenTelemetry — OTLP exporter) ---
builder.Services.AddOpenTelemetry()
    .ConfigureResource(r => r.AddService(serviceName: "my-service"))
    .WithTracing(t => t
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddEntityFrameworkCoreInstrumentation()
        .AddOtlpExporter())
    .WithMetrics(m => m
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddRuntimeInstrumentation()
        .AddOtlpExporter());

// --- OpenAPI ---
builder.Services.AddOpenApi();

// --- API versioning ---
builder.Services.AddApiVersioning(options =>
{
    options.DefaultApiVersion = new ApiVersion(1);
    options.ReportApiVersions = true;
});

var app = builder.Build();

// --- Pipeline ---
app.UseExceptionHandler();      // emits ProblemDetails for unhandled
app.UseStatusCodePages();       // emits ProblemDetails for 4xx/5xx without body
app.UseAuthentication();
app.UseAuthorization();

// --- Endpoint mapping ---
var v1 = app.MapGroup("/v1").WithApiVersionSet(/*...*/);

CreateOrder.Map(v1);
GetOrder.Map(v1);
// ... one line per slice

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.MapHealthChecks("/health/live");
app.MapHealthChecks("/health/ready");

app.Run();

public partial class Program; // for WebApplicationFactory<Program>
```

## Validation filter

```csharp
// Shared/Validation/ValidationFilter.cs
public sealed class ValidationFilter<T>(IValidator<T> validator) : IEndpointFilter
{
    public async ValueTask<object?> InvokeAsync(EndpointFilterInvocationContext ctx, EndpointFilterDelegate next)
    {
        var arg = ctx.Arguments.OfType<T>().FirstOrDefault();
        if (arg is null) return await next(ctx);

        var result = await validator.ValidateAsync(arg, ctx.HttpContext.RequestAborted);
        if (!result.IsValid)
            return TypedResults.ValidationProblem(result.ToDictionary());

        return await next(ctx);
    }
}
```

## What is *not* in this skeleton (and why)

- **No `AddControllers()`** — minimal API only.
- **No `UseRouting()` / `UseEndpoints()`** — implicit in minimal API hosting.
- **No global exception filter** — `UseExceptionHandler()` + `AddProblemDetails()` cover it.
- **No CORS** — add only when there's a cross-origin browser consumer; don't add `AllowAnyOrigin` "just in case."
- **No rate limiting middleware** — add `AddRateLimiter` per-endpoint when there's an actual abuse vector (auth, write endpoints behind public ingress).
- **No Serilog** — built-in `Microsoft.Extensions.Logging` + OTel logs is enough for most services. Add Serilog only when you need sinks OTel doesn't cover.

## With .NET Aspire ServiceDefaults

If the service is hosted under .NET Aspire, replace the entire observability + health-checks block with:

```csharp
builder.AddServiceDefaults(); // OTel, OTLP, health checks, service discovery
```

…and add the matching `Aspire.Hosting` setup in the AppHost project.
