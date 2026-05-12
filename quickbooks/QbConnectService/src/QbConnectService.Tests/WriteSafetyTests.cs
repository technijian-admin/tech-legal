using System.Net;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using QbConnectService.Api;
using QbConnectService.Qb;

namespace QbConnectService.Tests;

public sealed class WriteSafetyTests
{
    [Fact]
    public async Task ops_endpoint_403s_a_write_op_when_writes_disabled()
    {
        await using var factory = new QbWebAppFactory { AllowWrites = false };
        using var client = CreateAuthorizedClient(factory);
        using var content = JsonContent("{}");

        var response = await client.PostAsync("/api/ops/fake_create", content);
        var body = await response.Content.ReadAsStringAsync();

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        Assert.Contains("Writes disabled", body, StringComparison.Ordinal);
        Assert.Empty(factory.Fake.ProcessRequests);
    }

    [Fact]
    public async Task ops_endpoint_does_not_403_a_read_op_when_writes_disabled()
    {
        await using var factory = new QbWebAppFactory { AllowWrites = false };
        factory.Fake.AddResponse(
            "CustomerQueryRq",
            """
            <QBXML>
              <QBXMLMsgsRs>
                <CustomerQueryRs statusCode="0" statusSeverity="Info" statusMessage="Status OK" iteratorRemainingCount="0">
                  <CustomerRet><Name>Acme</Name></CustomerRet>
                </CustomerQueryRs>
              </QBXMLMsgsRs>
            </QBXML>
            """);

        using var client = CreateAuthorizedClient(factory);
        using var content = JsonContent("{}");

        var response = await client.PostAsync("/api/ops/list_customers", content);

        Assert.NotEqual(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task apiexceptionhandler_maps_QbWriteForbiddenException_to_403()
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

        var handled = await handler.TryHandleAsync(
            context,
            new QbWriteForbiddenException("writes disabled"),
            CancellationToken.None);

        Assert.True(handled);
        Assert.Equal(StatusCodes.Status403Forbidden, context.Response.StatusCode);

        context.Response.Body.Position = 0;
        using var document = await JsonDocument.ParseAsync(context.Response.Body);
        Assert.Equal("Writes disabled", document.RootElement.GetProperty("title").GetString());
        Assert.Contains("writes disabled", document.RootElement.GetProperty("detail").GetString(), StringComparison.Ordinal);
    }

    private static HttpClient CreateAuthorizedClient(QbWebAppFactory factory)
    {
        var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", QbWebAppFactory.Token);
        return client;
    }

    private static StringContent JsonContent(string body) => new(body, Encoding.UTF8, "application/json");
}
