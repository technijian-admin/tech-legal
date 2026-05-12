using System.Xml.Linq;

namespace QbConnectService.Tests;

public sealed class CompanyPreferencesOpTests
{
    [Fact]
    public async Task get_company_preferences_returns_salesTax_decimals_multiCurrency_and_default_ar_ap()
    {
        var (fake, manager, ops) = OpTestHarness.Create();
        var arResponse = OpTestHarness.Fixture("AccountQueryRs.arap.qbxml");
        const string apResponse = """
                                  <!-- CONSTRUCTED fixture (not live-captured). Phase 9 re-pins AccountQuery element casing against 10.120.254.13. -->
                                  <QBXML>
                                    <QBXMLMsgsRs>
                                      <AccountQueryRs statusCode="0" statusSeverity="Info" statusMessage="Status OK" iteratorRemainingCount="0">
                                        <AccountRet>
                                          <ListID>80000022-1</ListID>
                                          <Name>Accounts Payable</Name>
                                          <FullName>Accounts Payable</FullName>
                                          <AccountType>AccountsPayable</AccountType>
                                        </AccountRet>
                                      </AccountQueryRs>
                                    </QBXMLMsgsRs>
                                  </QBXML>
                                  """;

        fake.AddResponse("PreferencesQueryRq", OpTestHarness.Fixture("PreferencesQueryRs.qbxml"));
        fake.AddResponses("AccountQueryRq", arResponse, apResponse);

        try
        {
            var result = Assert.IsAssignableFrom<IReadOnlyDictionary<string, object?>>(
                await ops["get_company_preferences"].RunAsync(new Dictionary<string, object?>(), default));

            Assert.Equal(true, result["salesTaxEnabled"]);
            Assert.Equal(false, result["multiCurrencyEnabled"]);
            Assert.Equal("2", result["decimalPlaces"]?.ToString());

            var defaultArAccount = Assert.IsType<Dictionary<string, object?>>(result["defaultArAccount"]);
            var defaultApAccount = Assert.IsType<Dictionary<string, object?>>(result["defaultApAccount"]);
            Assert.Equal("Accounts Receivable", defaultArAccount["FullName"]);
            Assert.Equal("Accounts Payable", defaultApAccount["FullName"]);

            Assert.Equal(3, fake.ProcessRequests.Count);
            Assert.Contains(fake.ProcessRequests, request => request.Contains("<PreferencesQueryRq", StringComparison.Ordinal));

            var accountRequests = fake.ProcessRequests
                .Where(request => request.Contains("<AccountQueryRq", StringComparison.Ordinal))
                .Select(request => XDocument.Parse(request).Root!.Element("QBXMLMsgsRq")!.Element("AccountQueryRq")!)
                .ToList();

            Assert.Equal(2, accountRequests.Count);
            Assert.Contains(accountRequests, request => request.Element("AccountType")?.Value == "AccountsReceivable");
            Assert.Contains(accountRequests, request => request.Element("AccountType")?.Value == "AccountsPayable");
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }
}
