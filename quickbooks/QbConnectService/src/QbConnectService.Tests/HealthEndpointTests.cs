using System.Net;
using System.Net.Http.Headers;
using System.Text.Json;

namespace QbConnectService.Tests;

public sealed class HealthEndpointTests
{
    [Fact]
    public async Task health_reports_healthy_when_probe_succeeds()
    {
        await using var factory = new QbWebAppFactory();
        factory.Fake.AddResponse("HostQueryRq", QbWebAppFactory.Fixture("HostCompanyQueryRs.qbxml"));

        using var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", QbWebAppFactory.Token);

        var response = await client.GetAsync("/api/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.Equal("healthy", document.RootElement.GetProperty("status").GetString());
        // With Qb.ReleaseAfterEachRequest=true (the production default), the probe auto-
        // releases the session, so connectionState is Disconnected right after the probe.
        // lastProbe="ok" carries the actual probe outcome.
        Assert.Equal("Disconnected", document.RootElement.GetProperty("connectionState").GetString());
        Assert.Equal("ok", document.RootElement.GetProperty("lastProbe").GetString());
        Assert.True(document.RootElement.GetProperty("releaseAfterEachRequest").GetBoolean());
        Assert.False(document.RootElement.GetProperty("allowWrites").GetBoolean());
        Assert.Equal("16.0", document.RootElement.GetProperty("qbXmlVersionConfigured").GetString());
        Assert.Equal(@"C:\co.QBW", document.RootElement.GetProperty("companyFile").GetString());
        Assert.False(string.IsNullOrWhiteSpace(document.RootElement.GetProperty("quickBooksVersion").GetString()));
        Assert.Equal(JsonValueKind.Null, document.RootElement.GetProperty("lastError").ValueKind);
    }

    [Fact]
    public async Task connection_release_endpoint_returns_state_before_and_after()
    {
        await using var factory = new QbWebAppFactory();

        using var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", QbWebAppFactory.Token);

        var response = await client.PostAsync("/api/connection/release", null);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.Equal("Disconnected", document.RootElement.GetProperty("stateAfter").GetString());
        Assert.Equal(JsonValueKind.Null, document.RootElement.GetProperty("companyAfter").ValueKind);
    }

    [Fact]
    public async Task connection_release_endpoint_requires_token()
    {
        await using var factory = new QbWebAppFactory();
        using var client = factory.CreateClient();

        var response = await client.PostAsync("/api/connection/release", null);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task health_reports_down_when_com_not_registered()
    {
        await using var factory = new QbWebAppFactory();
        factory.Fake.EnqueueComError(unchecked((int)0x80040154));

        using var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", QbWebAppFactory.Token);

        var response = await client.GetAsync("/api/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.Equal("down", document.RootElement.GetProperty("status").GetString());
        Assert.Equal("Disconnected", document.RootElement.GetProperty("connectionState").GetString());
        Assert.Equal(@"C:\co.QBW", document.RootElement.GetProperty("companyFile").GetString());

        var lastError = document.RootElement.GetProperty("lastError");
        Assert.Equal("REGDB_E_CLASSNOTREG", lastError.GetProperty("name").GetString());
        Assert.Equal("0x80040154", lastError.GetProperty("code").GetString());
        Assert.Equal(0, lastError.ValueKind == JsonValueKind.Null
            ? -1
            : document.RootElement.GetProperty("qbXmlVersionsSupported").GetArrayLength());
    }

    [Fact]
    public async Task health_requires_token()
    {
        await using var factory = new QbWebAppFactory();
        using var client = factory.CreateClient();

        var response = await client.GetAsync("/api/health");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task connection_restart_qb_endpoint_kills_processes_and_returns_snapshot()
    {
        await using var factory = new QbWebAppFactory();
        factory.FakeProcess.Count = 2;
        factory.FakeProcess.AnyInteractive = false;

        using var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", QbWebAppFactory.Token);

        var response = await client.PostAsync("/api/connection/restart-qb", null);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.Equal(2, document.RootElement.GetProperty("qbwProcessesBefore").GetInt32());
        Assert.False(document.RootElement.GetProperty("qbwInteractiveSessionBefore").GetBoolean());
        Assert.Equal(2, document.RootElement.GetProperty("qbwKilled").GetInt32());
        Assert.Equal(0, document.RootElement.GetProperty("qbwProcessesAfter").GetInt32());
        Assert.Equal(1, factory.FakeProcess.KillCalls);
    }

    [Fact]
    public async Task connection_restart_qb_endpoint_requires_token()
    {
        await using var factory = new QbWebAppFactory();
        using var client = factory.CreateClient();

        var response = await client.PostAsync("/api/connection/restart-qb", null);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task health_exposes_qbw_process_diagnostics_and_auto_recover_flag()
    {
        await using var factory = new QbWebAppFactory();
        factory.Fake.AddResponse("HostQueryRq", QbWebAppFactory.Fixture("HostCompanyQueryRs.qbxml"));
        factory.FakeProcess.Count = 3;
        factory.FakeProcess.AnyInteractive = true;

        using var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", QbWebAppFactory.Token);

        var response = await client.GetAsync("/api/health");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.Equal(3, document.RootElement.GetProperty("qbwProcesses").GetInt32());
        Assert.True(document.RootElement.GetProperty("qbwInteractiveSession").GetBoolean());
        Assert.True(document.RootElement.GetProperty("autoRecoverFromQbwStuck").GetBoolean());
        Assert.Equal(3, document.RootElement.GetProperty("maxQbwKillsPerMinute").GetInt32());
        Assert.Equal(0, document.RootElement.GetProperty("recentQbwKills").GetInt32());
    }
}
