using System.Net;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using QbConnectService.Api;
using QbConnectService.Qb;
using QbConnectService.Tests.Fakes;

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

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
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

    [Fact]
    public async Task write_op_with_allowwrites_true_executes_byte_exact_and_writes_exactly_one_audit_row_even_on_qb_error()
    {
        await using var factory = new QbWebAppFactory { AllowWrites = true };
        factory.Fake.AddResponse("CustomerAddRq", BusinessErrorResponse);

        using var client = CreateAuthorizedClient(factory);
        using var content = JsonContent("{}");

        var response = await client.PostAsync("/api/ops/fake_create", content);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.Equal("3140", document.RootElement.GetProperty("result").GetProperty("status").GetProperty("code").GetString());
        Assert.Single(factory.Fake.ProcessRequests);
        Assert.Equal(FakeWriteOp.KnownRequestXml, factory.Fake.ProcessRequests[0]);

        var row = ReadAuditRows(factory.AuditDir).Single();
        Assert.Equal(FakeWriteOp.OpName, row["op"]!.GetValue<string>());
        Assert.Equal("3140", row["responseStatusCode"]!.GetValue<string>());
        Assert.Equal("Error", row["responseStatusSeverity"]!.GetValue<string>());
        Assert.Equal(new string('0', 64), row["prevHash"]!.GetValue<string>());
        Assert.Equal(64, row["hash"]!.GetValue<string>().Length);
        Assert.True(IsLowerHex(row["hash"]!.GetValue<string>()));
        Assert.StartsWith("tok-", row["requesterId"]!.GetValue<string>(), StringComparison.Ordinal);
    }

    [Fact]
    public async Task two_writes_chain_the_audit_rows()
    {
        await using var factory = new QbWebAppFactory { AllowWrites = true };
        factory.Fake.AddResponses("CustomerAddRq", SuccessResponse, SuccessResponse);

        using var client = CreateAuthorizedClient(factory);
        using (var first = JsonContent("{}"))
        {
            _ = await client.PostAsync("/api/ops/fake_create", first);
        }

        using (var second = JsonContent("{}"))
        {
            _ = await client.PostAsync("/api/ops/fake_create", second);
        }

        var rows = ReadAuditRows(factory.AuditDir);
        Assert.Equal(2, rows.Count);
        Assert.Equal(0L, rows[0]["seq"]!.GetValue<long>());
        Assert.Equal(new string('0', 64), rows[0]["prevHash"]!.GetValue<string>());
        Assert.Equal(1L, rows[1]["seq"]!.GetValue<long>());
        Assert.Equal(rows[0]["hash"]!.GetValue<string>(), rows[1]["prevHash"]!.GetValue<string>());

        var verify = await CreateAuditLog(factory.AuditDir).VerifyChainAsync();
        Assert.True(verify.Ok);
        Assert.Null(verify.FirstBrokenSeq);
    }

    [Fact]
    public async Task raw_qbxml_endpoint_403s_a_write_request_when_writes_disabled()
    {
        await using var factory = new QbWebAppFactory { AllowWrites = false };
        using var client = CreateAuthorizedClient(factory);
        using var content = new StringContent(WriteQbXmlRequest, Encoding.UTF8, "application/xml");

        var response = await client.PostAsync("/api/qbxml", content);

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        Assert.Empty(factory.Fake.ProcessRequests);
    }

    [Fact]
    public async Task connection_manager_throws_for_write_qbxml_when_writes_disabled()
    {
        var fake = new FakeRequestProcessor();
        var manager = new QbConnectionManager(
            () => fake,
            Options.Create(new QbOptions
            {
                AppId = "app",
                AppName = "QbConnectService",
                CompanyFilePath = @"C:\co.QBW",
            }),
            Options.Create(new RequestOptions
            {
                TimeoutSeconds = 30,
                BusyWaitSeconds = 5,
            }),
            NullLogger<QbConnectionManager>.Instance,
            Options.Create(new SafetyOptions { AllowWrites = false }),
            new FakeQbProcessManager(),
            new QbKillTracker());

        try
        {
            await Assert.ThrowsAsync<QbWriteForbiddenException>(() => manager.ExecuteAsync(WriteQbXmlRequest));
            Assert.Empty(fake.ProcessRequests);
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }

    [Fact]
    public async Task dryrun_never_appends_even_after_a_real_execute()
    {
        await using var factory = new QbWebAppFactory { AllowWrites = true };
        factory.Fake.AddResponse("CustomerAddRq", SuccessResponse);

        using var client = CreateAuthorizedClient(factory);
        using (var executeContent = JsonContent("{}"))
        {
            var executeResponse = await client.PostAsync("/api/ops/fake_create", executeContent);
            Assert.Equal(HttpStatusCode.OK, executeResponse.StatusCode);
        }

        Assert.Single(ReadAuditRows(factory.AuditDir));

        using (var dryRunContent = JsonContent("{}"))
        {
            var dryRunResponse = await client.PostAsync("/api/ops/fake_create/dryrun", dryRunContent);
            Assert.Equal(HttpStatusCode.OK, dryRunResponse.StatusCode);
        }

        Assert.Single(ReadAuditRows(factory.AuditDir));
        Assert.Single(factory.Fake.ProcessRequests);
    }

    private static HttpClient CreateAuthorizedClient(QbWebAppFactory factory)
    {
        var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", QbWebAppFactory.Token);
        return client;
    }

    private static AuditLog CreateAuditLog(string auditDir) =>
        new(
            Options.Create(new AuditOptions { Path = auditDir }),
            Options.Create(new AuditAuthOptions { ApiToken = QbWebAppFactory.Token }),
            NullLogger<AuditLog>.Instance);

    private static IReadOnlyList<JsonObject> ReadAuditRows(string auditDir) =>
        File.ReadAllLines(Path.Combine(auditDir, "audit.jsonl"))
            .Where(line => !string.IsNullOrWhiteSpace(line))
            .Select(line => JsonNode.Parse(line)!.AsObject())
            .ToList();

    private static bool IsLowerHex(string value) =>
        value.All(ch => char.IsDigit(ch) || (ch >= 'a' && ch <= 'f'));

    private static StringContent JsonContent(string body) => new(body, Encoding.UTF8, "application/json");

    private const string SuccessResponse =
        "<QBXML><QBXMLMsgsRs statusCode=\"0\" statusSeverity=\"Info\" statusMessage=\"Status OK\"><CustomerAddRs statusCode=\"0\" statusSeverity=\"Info\" statusMessage=\"Status OK\"><CustomerRet><Name>FAKE</Name></CustomerRet></CustomerAddRs></QBXMLMsgsRs></QBXML>";

    private const string BusinessErrorResponse =
        "<QBXML><QBXMLMsgsRs statusCode=\"3140\" statusSeverity=\"Error\" statusMessage=\"There is an invalid reference.\"><CustomerAddRs statusCode=\"3140\" statusSeverity=\"Error\" statusMessage=\"There is an invalid reference.\"/></QBXMLMsgsRs></QBXML>";

    private const string WriteQbXmlRequest =
        "<?xml version=\"1.0\"?><?qbxml version=\"16.0\"?><QBXML><QBXMLMsgsRq onError=\"stopOnError\"><CustomerAddRq><CustomerAdd><Name>X</Name></CustomerAdd></CustomerAddRq></QBXMLMsgsRq></QBXML>";
}
