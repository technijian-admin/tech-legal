using QbConnectService.Qb;

namespace QbConnectService.Tests;

public sealed class CompanyInfoOpTests
{
    [Fact]
    public async Task company_info_returns_company_fields_and_edition()
    {
        var (fake, manager, ops) = OpTestHarness.Create();
        fake.AddResponse("HostQueryRq", OpTestHarness.Fixture("HostCompanyQueryRs.qbxml"));

        try
        {
            var result = Assert.IsAssignableFrom<IReadOnlyDictionary<string, object?>>(
                await ops["company_info"].RunAsync(new Dictionary<string, object?>(), default));

            Assert.Equal("Acme Roofing Inc", result["companyName"]?.ToString());
            Assert.Contains("Enterprise", result["edition"]?.ToString());
            Assert.Equal("January", result["fiscalYearStartMonth"]?.ToString());

            var address = Assert.IsType<Dictionary<string, object?>>(result["address"]);
            Assert.Equal("Irvine", address["City"]);

            Assert.Single(fake.ProcessRequests);
            Assert.Contains("<HostQueryRq", fake.ProcessRequests[0], StringComparison.Ordinal);
            Assert.Contains("<CompanyQueryRq", fake.ProcessRequests[0], StringComparison.Ordinal);
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }
}
