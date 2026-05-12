using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using QbConnectService.Qb;

namespace QbConnectService.Api;

public sealed class ApiExceptionHandler(IProblemDetailsService pds) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(HttpContext ctx, Exception ex, CancellationToken ct)
    {
        var (status, title) = ex switch
        {
            ArgumentException => (StatusCodes.Status400BadRequest, "Bad request"),
            QbXmlParseException => (StatusCodes.Status400BadRequest, "Malformed qbXML"),
            QbBusyException => (StatusCodes.Status409Conflict, "QuickBooks busy"),
            QbTimeoutException => (StatusCodes.Status504GatewayTimeout, "QuickBooks timeout"),
            QbException => (StatusCodes.Status503ServiceUnavailable, "QuickBooks unavailable"),
            _ => (StatusCodes.Status500InternalServerError, "Unexpected error"),
        };

        var problem = new ProblemDetails
        {
            Status = status,
            Title = title,
            Detail = ex is QbException qb
                ? $"{qb.Error.Name}: {qb.Error.Message} ({qb.Error.RemediationHint})"
                : ex.Message,
        };

        if (ex is QbException qbException)
        {
            problem.Extensions["qbErrorCode"] = $"0x{qbException.Error.Code:X8}";
        }

        ctx.Response.StatusCode = status;
        return await pds.TryWriteAsync(new ProblemDetailsContext
        {
            HttpContext = ctx,
            ProblemDetails = problem,
        });
    }
}
