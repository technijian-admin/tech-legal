using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Options;
using QbConnectService.Qb;
using QbConnectService.Qb.Ops;

namespace QbConnectService.Api;

public static class OpsEndpoints
{
    private static readonly IReadOnlyDictionary<string, object?> EmptyArgs =
        new Dictionary<string, object?>(StringComparer.Ordinal);

    public static void MapOpsEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapGet("/ops", (OpRegistry registry) =>
            Results.Ok(new { ops = registry.Names.OrderBy(name => name, StringComparer.Ordinal).ToArray() }));

        app.MapPost("/ops/{op}", async (
            string op,
            HttpContext ctx,
            OpRegistry registry,
            IOptions<SafetyOptions> safety,
            IOptions<QbOptions> qb,
            ILoggerFactory loggerFactory,
            CancellationToken ct) =>
        {
            if (!registry.TryGet(op, out var readOp))
            {
                return Results.Problem(
                    statusCode: StatusCodes.Status404NotFound,
                    title: "Unknown op",
                    detail: $"No op named '{op}'. GET /api/ops for the list.");
            }

            if (readOp is IWriteOp && !safety.Value.AllowWrites)
            {
                loggerFactory.CreateLogger("QbConnectService.Api.OpsEndpoints")
                    .LogWarning("Refused write op {Op}: Safety:AllowWrites is false.", op);

                return Results.Problem(
                    statusCode: StatusCodes.Status403Forbidden,
                    title: "Writes disabled",
                    detail: $"Op '{op}' is a write op and Safety:AllowWrites is false. Set Safety:AllowWrites=true to enable writes.");
            }

            if (!TryResolveCompany(ctx, qb.Value, out var rawRequested, out var resolvedKey, out var companyError))
            {
                return companyError!;
            }

            var args = await ReadArgsAsync(ctx, ct);
            using (QbCompanyContext.Push(rawRequested))
            {
                var result = await readOp.RunAsync(args, ct);
                return Results.Ok(new { op, company = resolvedKey, result });
            }
        });

        app.MapPost("/ops/{op}/dryrun", async (
            string op,
            HttpContext ctx,
            OpRegistry registry,
            IOptions<SafetyOptions> safety,
            IOptions<QbOptions> qb,
            CancellationToken ct) =>
        {
            if (!registry.TryGet(op, out var resolved))
            {
                return Results.Problem(
                    statusCode: StatusCodes.Status404NotFound,
                    title: "Unknown op",
                    detail: $"No op named '{op}'. GET /api/ops for the list.");
            }

            if (!TryResolveCompany(ctx, qb.Value, out var rawRequested, out var resolvedKey, out var companyError))
            {
                return companyError!;
            }

            var args = await ReadArgsAsync(ctx, ct);

            using (QbCompanyContext.Push(rawRequested))
            {
                if (resolved is IWriteOp writeOp)
                {
                    var dryRun = await writeOp.DryRunAsync(args, ct);
                    return Results.Ok(new { op, company = resolvedKey, dryRun });
                }

                var preview = resolved is ReadOpBase readOp ? readOp.PreviewRequest(args) : null;
                return Results.Ok(new
                {
                    op,
                    company = resolvedKey,
                    dryRun = new
                    {
                        qbXml = preview,
                        summary = (string?)null,
                        preFlight = Array.Empty<object>(),
                        resolvedReferences = new { },
                        allowWrites = safety.Value.AllowWrites,
                        note = "dry-run preview is available for write ops; this is a read op (calling it has no side effects).",
                    },
                });
            }
        });
    }

    /// <summary>
    /// Resolve which company this request targets. Sources, in order: ?company= query, X-Qb-Company header,
    /// otherwise null (which resolves to Qb.DefaultCompany or the legacy single-tenant fallback).
    /// rawRequested is what the user passed in (or null) - this is what goes onto the AsyncLocal context so
    /// the connection manager re-resolves identically. resolvedKey is the final key after fallback rules.
    /// Returns false (with an error IResult) if an explicit company key was given but not in Qb.Companies.
    /// </summary>
    internal static bool TryResolveCompany(
        HttpContext ctx,
        QbOptions qb,
        out string? rawRequested,
        out string? resolvedKey,
        out IResult? error)
    {
        rawRequested = null;
        resolvedKey = null;
        error = null;

        if (ctx.Request.Query.TryGetValue("company", out var q) && q.Count > 0 && !string.IsNullOrWhiteSpace(q[0]))
        {
            rawRequested = q[0];
        }
        else if (ctx.Request.Headers.TryGetValue("X-Qb-Company", out var h) && h.Count > 0 && !string.IsNullOrWhiteSpace(h[0]))
        {
            rawRequested = h[0];
        }

        try
        {
            var (key, _) = qb.ResolveCompany(rawRequested);
            resolvedKey = key;
            return true;
        }
        catch (ArgumentException ex)
        {
            error = Results.Problem(
                statusCode: StatusCodes.Status400BadRequest,
                title: "Unknown company",
                detail: ex.Message);
            return false;
        }
    }

    private static async Task<IReadOnlyDictionary<string, object?>> ReadArgsAsync(HttpContext ctx, CancellationToken ct)
    {
        string body;
        using (var reader = new StreamReader(ctx.Request.Body, Encoding.UTF8))
        {
            body = await reader.ReadToEndAsync(ct);
        }

        if (string.IsNullOrWhiteSpace(body))
        {
            return EmptyArgs;
        }

        try
        {
            using var document = JsonDocument.Parse(body);
            if (document.RootElement.ValueKind != JsonValueKind.Object)
            {
                throw new ArgumentException("Request body must be a JSON object.");
            }

            return ArgReader.ToDictionary(document.RootElement);
        }
        catch (JsonException)
        {
            throw new ArgumentException("Request body is not valid JSON.");
        }
    }
}
