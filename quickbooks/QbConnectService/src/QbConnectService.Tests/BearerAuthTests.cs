using System.Net;
using System.Net.Http.Headers;

namespace QbConnectService.Tests;

public sealed class BearerAuthTests
{
    [Fact]
    public async Task missing_token_is_401_with_www_authenticate()
    {
        await using var factory = new QbWebAppFactory();
        using var client = factory.CreateClient();

        var response = await client.GetAsync("/api/ping");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
        Assert.Contains("Bearer", response.Headers.WwwAuthenticate.ToString(), StringComparison.Ordinal);
    }

    [Fact]
    public async Task wrong_token_is_401()
    {
        await using var factory = new QbWebAppFactory();
        using var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", "not-the-token");

        var response = await client.GetAsync("/api/ping");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task correct_token_passes_through()
    {
        await using var factory = new QbWebAppFactory();
        using var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", QbWebAppFactory.Token);

        var response = await client.GetAsync("/api/ping");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task non_api_path_needs_no_token()
    {
        await using var factory = new QbWebAppFactory();
        using var client = factory.CreateClient();

        var response = await client.GetAsync("/");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
