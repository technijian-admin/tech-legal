using System.Text;
using System.Text.Json;
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
            CancellationToken ct) =>
        {
            if (!registry.TryGet(op, out var readOp))
            {
                return Results.Problem(
                    statusCode: StatusCodes.Status404NotFound,
                    title: "Unknown op",
                    detail: $"No op named '{op}'. GET /api/ops for the list.");
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
