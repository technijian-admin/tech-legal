using System.Xml.Linq;

namespace QbConnectService.Tests;

public sealed class RunQueryOpTests
{
    [Fact]
    public async Task run_query_builds_entity_query_and_passes_filters()
    {
        var (fake, manager, ops) = OpTestHarness.Create();
        fake.AddResponse("EmployeeQueryRq", OpTestHarness.Fixture("EmployeeQueryRs.qbxml"));

        try
        {
            var result = Assert.IsAssignableFrom<IReadOnlyDictionary<string, object?>>(
                await ops["run_query"].RunAsync(
                    new Dictionary<string, object?>
                    {
                        ["entity"] = "Employee",
                        ["filters"] = new Dictionary<string, object?>
                        {
                            ["ActiveStatus"] = "ActiveOnly",
                        },
                    },
                    default));

            Assert.Equal("Employee", result["entity"]);
            var rows = Assert.IsType<List<Dictionary<string, object?>>>(result["rows"]);
            Assert.NotEmpty(rows);

            var request = QueryElement(fake.ProcessRequests[0], "EmployeeQueryRq");
            Assert.Equal("ActiveOnly", request.Element("ActiveStatus")?.Value);
            Assert.Equal("Start", request.Attribute("iterator")?.Value);
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }

    [Fact]
    public async Task run_query_supports_nested_filters()
    {
        var (fake, manager, ops) = OpTestHarness.Create();
        const string purchaseOrderResponse = """
                                             <QBXML>
                                               <QBXMLMsgsRs>
                                                 <PurchaseOrderQueryRs statusCode="0" statusSeverity="Info" statusMessage="Status OK" iteratorRemainingCount="0">
                                                   <PurchaseOrderRet>
                                                     <TxnID>PO-001</TxnID>
                                                     <RefNumber>PO-1001</RefNumber>
                                                   </PurchaseOrderRet>
                                                 </PurchaseOrderQueryRs>
                                               </QBXMLMsgsRs>
                                             </QBXML>
                                             """;
        fake.AddResponse("PurchaseOrderQueryRq", purchaseOrderResponse);

        try
        {
            await ops["run_query"].RunAsync(
                new Dictionary<string, object?>
                {
                    ["entity"] = "PurchaseOrder",
                    ["filters"] = new Dictionary<string, object?>
                    {
                        ["TxnDateRangeFilter"] = new Dictionary<string, object?>
                        {
                            ["FromTxnDate"] = "2025-01-01",
                            ["ToTxnDate"] = "2025-06-30",
                        },
                    },
                },
                default);

            var request = QueryElement(fake.ProcessRequests[0], "PurchaseOrderQueryRq");
            var filter = request.Element("TxnDateRangeFilter");
            Assert.NotNull(filter);
            Assert.Equal("2025-01-01", filter!.Element("FromTxnDate")?.Value);
            Assert.Equal("2025-06-30", filter.Element("ToTxnDate")?.Value);
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }

    [Fact]
    public async Task run_query_rejects_non_whitelisted_entity()
    {
        var (_, manager, ops) = OpTestHarness.Create();

        try
        {
            await Assert.ThrowsAsync<ArgumentException>(() => ops["run_query"].RunAsync(
                new Dictionary<string, object?>
                {
                    ["entity"] = "Banana",
                },
                default));
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }

    [Fact]
    public async Task run_query_rejects_verb_y_entity_name()
    {
        var (_, manager, ops) = OpTestHarness.Create();

        try
        {
            await Assert.ThrowsAsync<ArgumentException>(() => ops["run_query"].RunAsync(
                new Dictionary<string, object?>
                {
                    ["entity"] = "CustomerDel",
                },
                default));
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }

    [Fact]
    public async Task run_query_requires_entity()
    {
        var (_, manager, ops) = OpTestHarness.Create();

        try
        {
            await Assert.ThrowsAsync<ArgumentException>(() => ops["run_query"].RunAsync(new Dictionary<string, object?>(), default));
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }

    private static XElement QueryElement(string rawRequest, string name) =>
        XDocument.Parse(rawRequest).Root!.Element("QBXMLMsgsRq")!.Element(name)!;
}
