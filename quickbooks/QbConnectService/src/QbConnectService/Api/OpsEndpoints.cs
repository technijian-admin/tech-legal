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

            var args = await ReadArgsAsync(ctx, ct);
            var result = await readOp.RunAsync(args, ct);
            return Results.Ok(new { op, result });
        });
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
