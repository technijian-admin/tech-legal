using System.Xml.Linq;

namespace QbConnectService.Tests;

public sealed class ListTransactionOpsTests
{
    [Fact]
    public async Task list_invoices_returns_rows_and_applies_date_and_entity_filters()
    {
        var (fake, manager, ops) = OpTestHarness.Create();
        fake.AddResponse("InvoiceQueryRq", OpTestHarness.Fixture("InvoiceQueryRs.qbxml"));

        try
        {
            var result = Assert.IsAssignableFrom<IReadOnlyDictionary<string, object?>>(
                await ops["list_invoices"].RunAsync(
                    new Dictionary<string, object?>
                    {
                        ["fromDate"] = "2025-01-01",
                        ["toDate"] = "2025-06-30",
                        ["entity"] = "Acme Roofing Inc",
                    },
                    default));

            var rows = Assert.IsType<List<Dictionary<string, object?>>>(result["rows"]);
            Assert.Equal(2, rows.Count);

            var request = QueryElement(fake.ProcessRequests[0], "InvoiceQueryRq");
            var dateFilter = request.Element("TxnDateRangeFilter");
            Assert.NotNull(dateFilter);
            Assert.Equal("2025-01-01", dateFilter!.Element("FromTxnDate")?.Value);
            Assert.Equal("2025-06-30", dateFilter.Element("ToTxnDate")?.Value);
            Assert.Equal("Acme Roofing Inc", request.Element("EntityFilter")?.Element("FullNameList")?.Element("FullName")?.Value);
            Assert.Equal("Start", request.Attribute("iterator")?.Value);
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }

    [Fact]
    public async Task list_invoices_with_date_macro()
    {
        var (fake, manager, ops) = OpTestHarness.Create();
        fake.AddResponse("InvoiceQueryRq", OpTestHarness.Fixture("InvoiceQueryRs.qbxml"));

        try
        {
            await ops["list_invoices"].RunAsync(
                new Dictionary<string, object?>
                {
                    ["dateMacro"] = "ThisFiscalQuarter",
                },
                default);

            var request = QueryElement(fake.ProcessRequests[0], "InvoiceQueryRq");
            Assert.Equal("ThisFiscalQuarter", request.Element("TxnDateRangeFilter")?.Element("DateMacro")?.Value);
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }

    [Fact]
    public async Task list_invoices_with_no_filters_omits_filter_elements()
    {
        var (fake, manager, ops) = OpTestHarness.Create();
        fake.AddResponse("InvoiceQueryRq", OpTestHarness.Fixture("InvoiceQueryRs.qbxml"));

        try
        {
            await ops["list_invoices"].RunAsync(new Dictionary<string, object?>(), default);

            var request = QueryElement(fake.ProcessRequests[0], "InvoiceQueryRq");
            Assert.Null(request.Element("TxnDateRangeFilter"));
            Assert.Null(request.Element("EntityFilter"));
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }

    [Fact]
    public async Task list_invoices_include_line_items()
    {
        var (fake, manager, ops) = OpTestHarness.Create();
        fake.AddResponse("InvoiceQueryRq", OpTestHarness.Fixture("InvoiceQueryRs.qbxml"));

        try
        {
            await ops["list_invoices"].RunAsync(
                new Dictionary<string, object?>
                {
                    ["includeLineItems"] = true,
                },
                default);

            var request = QueryElement(fake.ProcessRequests[0], "InvoiceQueryRq");
            Assert.Equal("true", request.Element("IncludeLineItems")?.Value);
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }

    [Fact]
    public async Task list_bills_returns_rows()
    {
        var (fake, manager, ops) = OpTestHarness.Create();
        fake.AddResponse("BillQueryRq", OpTestHarness.Fixture("BillQueryRs.qbxml"));

        try
        {
            var result = Assert.IsAssignableFrom<IReadOnlyDictionary<string, object?>>(
                await ops["list_bills"].RunAsync(new Dictionary<string, object?>(), default));

            var rows = Assert.IsType<List<Dictionary<string, object?>>>(result["rows"]);
            Assert.Equal(2, rows.Count);
            Assert.NotNull(QueryElement(fake.ProcessRequests[0], "BillQueryRq"));
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }

    [Fact]
    public async Task list_payments_returns_rows()
    {
        var (fake, manager, ops) = OpTestHarness.Create();
        fake.AddResponse("ReceivePaymentQueryRq", OpTestHarness.Fixture("ReceivePaymentQueryRs.qbxml"));

        try
        {
            var result = Assert.IsAssignableFrom<IReadOnlyDictionary<string, object?>>(
                await ops["list_payments"].RunAsync(new Dictionary<string, object?>(), default));

            var rows = Assert.IsType<List<Dictionary<string, object?>>>(result["rows"]);
            Assert.Equal(2, rows.Count);
            Assert.NotNull(QueryElement(fake.ProcessRequests[0], "ReceivePaymentQueryRq"));
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }

    private static XElement QueryElement(string rawRequest, string name) =>
        XDocument.Parse(rawRequest).Root!.Element("QBXMLMsgsRq")!.Element(name)!;
}
