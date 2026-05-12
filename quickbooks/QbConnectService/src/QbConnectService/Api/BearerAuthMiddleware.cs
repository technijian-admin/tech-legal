using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Options;

namespace QbConnectService.Api;

/// <summary>
/// Static bearer-token gate for the LAN-only /api surface. This is intentionally not JwtBearer: one configured
/// token is compared with FixedTimeEquals, while the root liveness path and other non-/api routes stay open.
/// </summary>
public sealed class BearerAuthMiddleware(
    RequestDelegate next,
    IOptions<AuthOptions> auth,
    ILogger<BearerAuthMiddleware> log)
{
    private readonly byte[] _expected = Encoding.UTF8.GetBytes(auth.Value.ApiToken ?? string.Empty);

    public async Task Invoke(HttpContext ctx)
    {
        if (!ctx.Request.Path.StartsWithSegments("/api", StringComparison.Ordinal))
        {
            await next(ctx);
            return;
        }

        const string scheme = "Bearer ";
        var header = ctx.Request.Headers.Authorization.ToString();
        if (header.StartsWith(scheme, StringComparison.Ordinal))
        {
            var presented = Encoding.UTF8.GetBytes(header[scheme.Length..].Trim());
            if (_expected.Length > 0 && CryptographicOperations.FixedTimeEquals(presented, _expected))
            {
                await next(ctx);
                return;
            }
        }

        log.LogWarning("Rejected unauthorized API request for {Path}.", ctx.Request.Path);
        ctx.Response.StatusCode = StatusCodes.Status401Unauthorized;
        ctx.Response.Headers.WWWAuthenticate = "Bearer";
        await Results.Problem(
                statusCode: StatusCodes.Status401Unauthorized,
                title: "Unauthorized",
                detail: "Missing or invalid bearer token.")
            .ExecuteAsync(ctx);
    }
}
