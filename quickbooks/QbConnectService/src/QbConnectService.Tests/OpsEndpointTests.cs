using System.Net;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace QbConnectService.Tests;

public sealed class OpsEndpointTests
{
    [Fact]
    public async Task ops_company_info_returns_result()
    {
        await using var factory = new QbWebAppFactory();
        factory.Fake.AddResponse("HostQueryRq", QbWebAppFactory.Fixture("HostCompanyQueryRs.qbxml"));

        using var client = CreateAuthorizedClient(factory);
        using var content = Json("{}");
        var response = await client.PostAsync("/api/ops/company_info", content);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.Equal("company_info", document.RootElement.GetProperty("op").GetString());
        Assert.Equal("0", document.RootElement.GetProperty("result").GetProperty("status").GetProperty("code").GetString());
        Assert.False(string.IsNullOrWhiteSpace(document.RootElement.GetProperty("result").GetProperty("companyName").GetString()));
    }

    [Fact]
    public async Task ops_unknown_op_returns_404()
    {
        await using var factory = new QbWebAppFactory();
        using var client = CreateAuthorizedClient(factory);
        using var content = Json("{}");

        var response = await client.PostAsync("/api/ops/does_not_exist", content);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task ops_empty_body_is_ok_for_no_arg_op()
    {
        await using var factory = new QbWebAppFactory();
        factory.Fake.AddResponse("HostQueryRq", QbWebAppFactory.Fixture("HostCompanyQueryRs.qbxml"));

        using var client = CreateAuthorizedClient(factory);
        var response = await client.PostAsync("/api/ops/company_info", content: null);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task ops_non_object_body_is_400()
    {
        await using var factory = new QbWebAppFactory();
        using var client = CreateAuthorizedClient(factory);
        using var content = Json("[]");

        var response = await client.PostAsync("/api/ops/company_info", content);
        var body = await response.Content.ReadAsStringAsync();

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Contains("Request body must be a JSON object.", body, StringComparison.Ordinal);
    }

    [Fact]
    public async Task ops_nonzero_statuscode_is_200()
    {
        await using var factory = new QbWebAppFactory();
        factory.Fake.AddResponse(
            "CustomerQueryRq",
            """
            <QBXML>
              <QBXMLMsgsRs>
                <CustomerQueryRs statusCode="500" statusSeverity="Error" statusMessage="No customer matched." />
              </QBXMLMsgsRs>
            </QBXML>
            """);

        using var client = CreateAuthorizedClient(factory);
        using var content = Json("{}");
        var response = await client.PostAsync("/api/ops/list_customers", content);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.Equal("500", document.RootElement.GetProperty("result").GetProperty("status").GetProperty("code").GetString());
    }

    [Fact]
    public async Task ops_bad_args_is_400()
    {
        await using var factory = new QbWebAppFactory();
        using var client = CreateAuthorizedClient(factory);
        using var content = Json("{}");

        var response = await client.PostAsync("/api/ops/report", content);
        var body = await response.Content.ReadAsStringAsync();

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Contains("Bad request", body, StringComparison.Ordinal);
    }

    [Fact]
    public async Task ops_503_when_com_not_registered()
    {
        await using var factory = new QbWebAppFactory();
        factory.Fake.EnqueueComError(unchecked((int)0x80040154));

        using var client = CreateAuthorizedClient(factory);
        using var content = Json("{}");
        var response = await client.PostAsync("/api/ops/company_info", content);
        var body = await response.Content.ReadAsStringAsync();

        Assert.Equal(HttpStatusCode.ServiceUnavailable, response.StatusCode);
        Assert.Contains("REGDB_E_CLASSNOTREG", body, StringComparison.Ordinal);
    }

    [Fact]
    public async Task ops_requires_token()
    {
        await using var factory = new QbWebAppFactory();
        using var content = Json("{}");
        using var client = factory.CreateClient();

        var response = await client.PostAsync("/api/ops/company_info", content);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    private static HttpClient CreateAuthorizedClient(QbWebAppFactory factory)
    {
        var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", QbWebAppFactory.Token);
        return client;
    }

    private static StringContent Json(string body) => new(body, Encoding.UTF8, "application/json");
}
