using Microsoft.Extensions.Configuration;
using QbConnectService.Qb;

namespace QbConnectService.Tests;

public sealed class QbXmlOptionsBindingTests
{
    [Fact]
    public void Sample_config_binds_expected_qbXML_defaults()
    {
        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["QbXml:Version"] = "16.0",
                ["QbXml:OwnerIdZero"] = "false",
                ["QbXml:MaxReturned"] = "100",
                ["QbXml:MaxResponseBytes"] = "5000000",
                ["QbXml:SpillPath"] = string.Empty,
            })
            .Build();

        var options = configuration.GetSection("QbXml").Get<QbXmlOptions>();

        Assert.NotNull(options);
        Assert.Equal("16.0", options!.Version);
        Assert.False(options.OwnerIdZero);
        Assert.Equal(100, options.MaxReturned);
        Assert.Equal(5_000_000, options.MaxResponseBytes);
        Assert.Equal(string.Empty, options.SpillPath);
    }

    [Fact]
    public void Defaults_are_sensible_when_no_config_is_present()
    {
        var options = new QbXmlOptions();

        Assert.Equal("16.0", options.Version);
        Assert.False(options.OwnerIdZero);
        Assert.Equal(100, options.MaxReturned);
        Assert.Equal(5_000_000, options.MaxResponseBytes);
        Assert.Equal(string.Empty, options.SpillPath);
    }
}
