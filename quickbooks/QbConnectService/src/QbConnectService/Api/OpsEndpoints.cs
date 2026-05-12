using QbConnectService.Qb.Ops;

namespace QbConnectService.Api;

public static class OpsEndpoints
{
    public static void MapOpsEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapGet("/ops", (OpRegistry registry) =>
            Results.Ok(new { ops = registry.Names.OrderBy(name => name, StringComparer.Ordinal).ToArray() }));
    }
}
