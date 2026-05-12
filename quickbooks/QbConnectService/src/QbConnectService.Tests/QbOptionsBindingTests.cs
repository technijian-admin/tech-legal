using Microsoft.Extensions.Configuration;
using QbConnectService.Qb;

namespace QbConnectService.Tests;

public sealed class QbOptionsBindingTests
{
    [Fact]
    public void Sample_config_binds_expected_QuickBooks_defaults()
    {
        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Qb:CompanyFilePath"] = @"C:\path\to\company.QBW",
                ["Qb:AppId"] = "REPLACE-WITH-APP-ID",
                ["Qb:AppName"] = "QbConnectService",
                ["Qb:OwnerIdZero"] = "false",
                ["Qb:ConnectionType"] = "LocalQBD",
                ["Qb:OpenMode"] = "DoNotCare",
                ["Request:TimeoutSeconds"] = "60",
                ["Request:BusyWaitSeconds"] = "10",
            })
            .Build();

        var qb = configuration.GetSection("Qb").Get<QbOptions>();
        var request = configuration.GetSection("Request").Get<RequestOptions>();

        Assert.NotNull(qb);
        Assert.NotNull(request);
        Assert.Equal(QbFileMode.DoNotCare, qb!.OpenMode);
        Assert.Equal(QbConnectionType.LocalQBD, qb.ConnectionType);
        Assert.Equal("QbConnectService", qb.AppName);
        Assert.Equal(60, request!.TimeoutSeconds);
        Assert.Equal(10, request.BusyWaitSeconds);
    }
}
