using System.Text;
using Microsoft.Extensions.Options;
using QbConnectService.Qb;

namespace QbConnectService.Api;

public static class QbXmlEndpoints
{
    public static void MapQbXmlEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapPost("/qbxml", async (
            HttpContext ctx,
            QbConnectionManager manager,
            IOptions<SafetyOptions> safety,
            CancellationToken ct) =>
        {
            string body;
            using (var reader = new StreamReader(ctx.Request.Body, Encoding.UTF8))
            {
                body = await reader.ReadToEndAsync(ct);
            }

            if (string.IsNullOrWhiteSpace(body))
            {
                return Results.Problem(
                    statusCode: StatusCodes.Status400BadRequest,
                    title: "Bad request",
                    detail: "Request body must be a qbXML document.");
            }

            if (!safety.Value.AllowWrites && QbWriteDetector.IsWriteRequest(body))
            {
                return Results.Problem(
                    statusCode: StatusCodes.Status403Forbidden,
                    title: "Writes disabled",
                    detail: "Safety:AllowWrites is false; this qbXML contains an Add/Mod/Del/Void request. Set Safety:AllowWrites=true to enable writes.");
            }

            var raw = await manager.ExecuteAsync(body, ct);
            return Results.Content(raw, "application/xml");
        });
    }
}
