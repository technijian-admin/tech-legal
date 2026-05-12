using System.Net;
using System.Net.Http.Headers;

namespace QbConnectService.Tests;

public sealed class QbXmlEndpointTests
{
    [Fact]
    public async Task qbxml_read_round_trips_returns_raw_xml()
    {
        await using var factory = new QbWebAppFactory();
        factory.Fake.AddResponse(
            "CustomerQueryRq",
            """
            <?xml version="1.0"?>
            <QBXML>
              <QBXMLMsgsRs>
                <CustomerQueryRs statusCode="0" statusSeverity="Info" statusMessage="OK">
                  <CustomerRet><Name>Acme</Name></CustomerRet>
                </CustomerQueryRs>
              </QBXMLMsgsRs>
            </QBXML>
            """);

        using var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", QbWebAppFactory.Token);

        using var content = new StringContent(BuildQuery("CustomerQueryRq"), System.Text.Encoding.UTF8, "application/xml");
        var response = await client.PostAsync("/api/qbxml", content);
        var body = await response.Content.ReadAsStringAsync();

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.StartsWith("application/xml", response.Content.Headers.ContentType?.MediaType, StringComparison.Ordinal);
        Assert.Contains("CustomerQueryRs", body, StringComparison.Ordinal);
        Assert.Contains("Acme", body, StringComparison.Ordinal);
    }

    [Fact]
    public async Task qbxml_with_CustomerAddRq_is_403_when_writes_disabled()
    {
        await using var factory = new QbWebAppFactory();
        using var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", QbWebAppFactory.Token);

        using var content = new StringContent(
            """
            <QBXML>
              <QBXMLMsgsRq onError="stopOnError">
                <CustomerAddRq><CustomerAdd><Name>Acme</Name></CustomerAdd></CustomerAddRq>
              </QBXMLMsgsRq>
            </QBXML>
            """,
            System.Text.Encoding.UTF8,
            "application/xml");

        var response = await client.PostAsync("/api/qbxml", content);
        var body = await response.Content.ReadAsStringAsync();

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        Assert.Contains("Writes disabled", body, StringComparison.Ordinal);
    }

    [Fact]
    public async Task qbxml_503_when_com_not_registered()
    {
        await using var factory = new QbWebAppFactory();
        factory.Fake.EnqueueComError(unchecked((int)0x80040154));

        using var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", QbWebAppFactory.Token);

        using var content = new StringContent(BuildQuery("CustomerQueryRq"), System.Text.Encoding.UTF8, "application/xml");
        var response = await client.PostAsync("/api/qbxml", content);
        var body = await response.Content.ReadAsStringAsync();

        Assert.Equal(HttpStatusCode.ServiceUnavailable, response.StatusCode);
        Assert.Contains("REGDB_E_CLASSNOTREG", body, StringComparison.Ordinal);
    }

    [Fact]
    public async Task qbxml_nonzero_statuscode_is_still_200()
    {
        await using var factory = new QbWebAppFactory();
        factory.Fake.AddResponse(
            "CustomerQueryRq",
            """
            <?xml version="1.0"?>
            <QBXML>
              <QBXMLMsgsRs>
                <CustomerQueryRs statusCode="3000" statusSeverity="Error" statusMessage="The given object does not exist." />
              </QBXMLMsgsRs>
            </QBXML>
            """);

        using var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", QbWebAppFactory.Token);

        using var content = new StringContent(BuildQuery("CustomerQueryRq"), System.Text.Encoding.UTF8, "application/xml");
        var response = await client.PostAsync("/api/qbxml", content);
        var body = await response.Content.ReadAsStringAsync();

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Contains("statusCode=\"3000\"", body, StringComparison.Ordinal);
    }

    [Fact]
    public async Task qbxml_requires_token()
    {
        await using var factory = new QbWebAppFactory();
        using var client = factory.CreateClient();

        using var content = new StringContent(BuildQuery("CustomerQueryRq"), System.Text.Encoding.UTF8, "application/xml");
        var response = await client.PostAsync("/api/qbxml", content);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    private static string BuildQuery(string requestElement) =>
        $$"""
          <QBXML>
            <QBXMLMsgsRq onError="stopOnError">
              <{{requestElement}} />
            </QBXMLMsgsRq>
          </QBXML>
          """;
}
