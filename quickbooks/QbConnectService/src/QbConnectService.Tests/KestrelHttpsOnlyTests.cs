namespace QbConnectService.Tests;

public sealed class KestrelHttpsOnlyTests
{
    [Fact]
    public void Validate_rejects_plain_http_bindings()
    {
        var exception = Assert.Throws<InvalidOperationException>(() => ServerBinding.Validate("http://localhost:1234"));
        Assert.Equal("Server:BindUrls must be https only; got 'http://localhost:1234'.", exception.Message);
    }

    [Fact]
    public void Validate_accepts_https_bindings()
    {
        ServerBinding.Validate("https://+:8443;https://localhost:9443");
    }
}
