using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using QbConnectService.Api;
using QbConnectService.Qb;

namespace QbConnectService.Tests;

public sealed class ApiExceptionHandlerTests
{
    [Theory]
    [MemberData(nameof(Cases))]
    public async Task Handler_maps_exceptions_to_expected_problem_details(
        Exception exception,
        int expectedStatus,
        string expectedTitle,
        string expectedDetailFragment)
    {
        var services = new ServiceCollection()
            .AddLogging()
            .AddProblemDetails()
            .BuildServiceProvider();

        var handler = new ApiExceptionHandler(services.GetRequiredService<IProblemDetailsService>());
        var context = new DefaultHttpContext
        {
            RequestServices = services,
        };
        context.Response.Body = new MemoryStream();

        var handled = await handler.TryHandleAsync(context, exception, CancellationToken.None);

        Assert.True(handled);
        Assert.Equal(expectedStatus, context.Response.StatusCode);

        context.Response.Body.Position = 0;
        using var document = await JsonDocument.ParseAsync(context.Response.Body);
        Assert.Equal(expectedTitle, document.RootElement.GetProperty("title").GetString());
        Assert.Contains(expectedDetailFragment, document.RootElement.GetProperty("detail").GetString(), StringComparison.Ordinal);
    }

    public static TheoryData<Exception, int, string, string> Cases() =>
        new()
        {
            { new ArgumentException("arg issue"), StatusCodes.Status400BadRequest, "Bad request", "arg issue" },
            { new QbXmlParseException("bad xml"), StatusCodes.Status400BadRequest, "Malformed qbXML", "bad xml" },
            { new QbBusyException(TimeSpan.FromSeconds(5)), StatusCodes.Status409Conflict, "QuickBooks busy", "waited 5s" },
            { new QbTimeoutException(TimeSpan.FromSeconds(7)), StatusCodes.Status504GatewayTimeout, "QuickBooks timeout", "7s timeout" },
            {
                new QbException(QbErrors.Lookup(unchecked((int)0x80040154))),
                StatusCodes.Status503ServiceUnavailable,
                "QuickBooks unavailable",
                "REGDB_E_CLASSNOTREG"
            },
            { new InvalidOperationException("boom"), StatusCodes.Status500InternalServerError, "Unexpected error", "boom" },
        };
}
