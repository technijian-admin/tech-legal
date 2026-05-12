using System.Net;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using QbConnectService.Tests.Fakes;

namespace QbConnectService.Tests;

public sealed class DryRunEndpointTests
{
    [Fact]
    public async Task dryrun_for_write_op_returns_preview_and_does_not_execute_or_audit()
    {
        await using var factory = new QbWebAppFactory { AllowWrites = false };
        using var client = CreateAuthorizedClient(factory);
        using var content = JsonContent("{}");

        var response = await client.PostAsync("/api/ops/fake_create/dryrun", content);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        var dryRun = document.RootElement.GetProperty("dryRun");
        Assert.Equal(FakeWriteOp.KnownRequestXml, dryRun.GetProperty("qbXml").GetString());
        Assert.False(dryRun.GetProperty("allowWrites").GetBoolean());
        Assert.False(string.IsNullOrWhiteSpace(dryRun.GetProperty("summary").GetString()));
        Assert.NotEqual(0, dryRun.GetProperty("preFlight").GetArrayLength());
        Assert.Empty(factory.Fake.ProcessRequests);
        Assert.False(File.Exists(Path.Combine(factory.AuditDir, "audit.jsonl")));
    }

    [Fact]
    public async Task dryrun_is_not_write_gated_works_with_allowwrites_true_too()
    {
        await using var factory = new QbWebAppFactory { AllowWrites = true };
        using var client = CreateAuthorizedClient(factory);
        using var content = JsonContent("{}");

        var response = await client.PostAsync("/api/ops/fake_create/dryrun", content);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.True(document.RootElement.GetProperty("dryRun").GetProperty("allowWrites").GetBoolean());
        Assert.Empty(factory.Fake.ProcessRequests);
        Assert.False(File.Exists(Path.Combine(factory.AuditDir, "audit.jsonl")));
    }

    [Fact]
    public async Task dryrun_unknown_op_returns_404()
    {
        await using var factory = new QbWebAppFactory();
        using var client = CreateAuthorizedClient(factory);
        using var content = JsonContent("{}");

        var response = await client.PostAsync("/api/ops/nope/dryrun", content);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task dryrun_for_read_op_returns_null_qbxml_and_a_note()
    {
        await using var factory = new QbWebAppFactory();
        using var client = CreateAuthorizedClient(factory);
        using var content = JsonContent("{}");

        var response = await client.PostAsync("/api/ops/company_info/dryrun", content);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        var dryRun = document.RootElement.GetProperty("dryRun");
        Assert.Equal(JsonValueKind.Null, dryRun.GetProperty("qbXml").ValueKind);
        Assert.Contains("read op", dryRun.GetProperty("note").GetString(), StringComparison.Ordinal);
        Assert.False(dryRun.GetProperty("allowWrites").GetBoolean());
        Assert.Empty(factory.Fake.ProcessRequests);
    }

    [Fact]
    public async Task dryrun_bad_args_returns_400()
    {
        await using var factory = new QbWebAppFactory();
        using var client = CreateAuthorizedClient(factory);
        using var content = JsonContent("not json");

        var response = await client.PostAsync("/api/ops/fake_create/dryrun", content);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    private static HttpClient CreateAuthorizedClient(QbWebAppFactory factory)
    {
        var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", QbWebAppFactory.Token);
        return client;
    }

    private static StringContent JsonContent(string body) => new(body, Encoding.UTF8, "application/json");
}
