using QbConnectService.Qb;

namespace QbConnectService.Api;

public static class ConnectionEndpoints
{
    public static void MapConnectionEndpoints(this IEndpointRouteBuilder app)
    {
        // POST /api/connection/release
        //
        // Drops any open SDK session so the .qbw file is released in QB Desktop. Idempotent.
        // Useful when a human at the QB server console needs to close/switch the company file
        // without first stopping the whole service. Acquires the manager's gate so it serializes
        // safely with any in-flight requests.
        app.MapPost("/connection/release", async (
            QbConnectionManager manager,
            CancellationToken ct) =>
        {
            var stateBefore = manager.State.ToString();
            var companyBefore = manager.CurrentCompanyKey;

            await manager.ReleaseAsync(ct);

            return Results.Ok(new
            {
                stateBefore,
                companyBefore,
                stateAfter = manager.State.ToString(),
                companyAfter = manager.CurrentCompanyKey,
                time = DateTimeOffset.UtcNow,
            });
        });
    }
}
