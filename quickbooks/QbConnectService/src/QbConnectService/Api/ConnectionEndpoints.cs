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

        // POST /api/connection/restart-qb
        //
        // Explicit operator hook: drop the SDK session AND kill every QBW.EXE on the host,
        // so the next request cold-starts QuickBooks fresh on the requested file. Safe to
        // call when no human session is using QB Desktop on the server console. Returns the
        // pre/post snapshot so the caller can see what happened.
        //
        // This is the same kill-and-restart the auto-recovery path performs internally,
        // exposed as an explicit verb for cases where the operator KNOWS QBW.EXE needs to
        // be restarted (e.g., before switching companies to pre-pay the cold-start cost, or
        // after manually dismissing a modal and wanting a clean slate).
        app.MapPost("/connection/restart-qb", async (
            QbConnectionManager manager,
            IQbProcessManager qbProcess,
            CancellationToken ct) =>
        {
            var stateBefore = manager.State.ToString();
            var companyBefore = manager.CurrentCompanyKey;
            var snapBefore = qbProcess.Snapshot();

            await manager.ReleaseAsync(ct);

            var killed = await qbProcess.KillAllAsync(TimeSpan.FromSeconds(10), ct);
            var snapAfter = qbProcess.Snapshot();

            return Results.Ok(new
            {
                stateBefore,
                companyBefore,
                qbwProcessesBefore = snapBefore.Count,
                qbwInteractiveSessionBefore = snapBefore.AnyInteractive,
                qbwKilled = killed,
                stateAfter = manager.State.ToString(),
                companyAfter = manager.CurrentCompanyKey,
                qbwProcessesAfter = snapAfter.Count,
                qbwInteractiveSessionAfter = snapAfter.AnyInteractive,
                time = DateTimeOffset.UtcNow,
            });
        });
    }
}
