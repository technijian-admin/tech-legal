using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using QbConnectService;
using QbConnectService.Qb;

namespace QbConnectService.Tests;

public sealed class ServerOptionsBindingTests
{
    [Fact]
    public void Sample_config_binds_server_auth_and_safety_options()
    {
        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Server:BindUrls"] = "https://+:9999",
                ["Server:CertPath"] = @"C:\x.pfx",
                ["Server:CertPassword"] = "pw",
                ["Server:MaxRequestBodyBytes"] = "123",
                ["Auth:ApiToken"] = "abc",
                ["Safety:AllowWrites"] = "true",
            })
            .Build();

        var services = new ServiceCollection();
        services.Configure<ServerOptions>(configuration.GetSection("Server"));
        services.Configure<AuthOptions>(configuration.GetSection("Auth"));
        services.Configure<SafetyOptions>(configuration.GetSection("Safety"));

        using var provider = services.BuildServiceProvider();
        var server = provider.GetRequiredService<IOptions<ServerOptions>>().Value;
        var auth = provider.GetRequiredService<IOptions<AuthOptions>>().Value;
        var safety = provider.GetRequiredService<IOptions<SafetyOptions>>().Value;

        Assert.Equal("https://+:9999", server.BindUrls);
        Assert.Equal(@"C:\x.pfx", server.CertPath);
        Assert.Equal("pw", server.CertPassword);
        Assert.Equal(123, server.MaxRequestBodyBytes);
        Assert.Equal("abc", auth.ApiToken);
        Assert.True(safety.AllowWrites);
    }

    [Fact]
    public void Options_default_to_expected_values()
    {
        var server = new ServerOptions();
        var auth = new AuthOptions();
        var safety = new SafetyOptions();

        Assert.Equal("https://+:8443", server.BindUrls);
        Assert.Equal(5_000_000, server.MaxRequestBodyBytes);
        Assert.Null(auth.ApiToken);
        Assert.False(safety.AllowWrites);
    }
}
