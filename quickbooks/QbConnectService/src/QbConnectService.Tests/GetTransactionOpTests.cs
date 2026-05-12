using QbConnectService.Qb;
using System.Xml.Linq;

namespace QbConnectService.Tests;

public sealed class GetTransactionOpTests
{
    [Fact]
    public async Task get_transaction_by_txn_id_returns_single_match()
    {
        var (fake, manager, ops) = OpTestHarness.Create();
        fake.AddResponse("TransactionQueryRq", OpTestHarness.Fixture("TransactionQueryRs.byid.qbxml"));

        try
        {
            var result = Assert.IsAssignableFrom<IReadOnlyDictionary<string, object?>>(
                await ops["get_transaction"].RunAsync(
                    new Dictionary<string, object?>
                    {
                        ["txnId"] = "123-456",
                    },
                    default));

            Assert.Equal(1, result["count"]);
            Assert.Equal(false, result["ambiguous"]);
            Assert.Equal(true, result["lite"]);

            var request = QueryElement(fake.ProcessRequests[0]);
            Assert.Equal("123-456", request.Element("TxnIDList")?.Element("TxnID")?.Value);
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }

    [Fact]
    public async Task get_transaction_by_ref_number_returns_multiple_matches_and_flags_ambiguous()
    {
        var (fake, manager, ops) = OpTestHarness.Create();
        fake.AddResponse("TransactionQueryRq", OpTestHarness.Fixture("TransactionQueryRs.byref.multi.qbxml"));

        try
        {
            var result = Assert.IsAssignableFrom<IReadOnlyDictionary<string, object?>>(
                await ops["get_transaction"].RunAsync(
                    new Dictionary<string, object?>
                    {
                        ["refNumber"] = "1001",
                    },
                    default));

            Assert.Equal(2, result["count"]);
            Assert.Equal(true, result["ambiguous"]);

            var request = QueryElement(fake.ProcessRequests[0]);
            var filter = request.Element("RefNumberFilter");
            Assert.NotNull(filter);
            Assert.Equal("Equals", filter!.Element("MatchCriterion")?.Value);
            Assert.Equal("1001", filter.Element("RefNumber")?.Value);
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }

    [Fact]
    public async Task get_transaction_with_txn_type_narrows_query()
    {
        var (fake, manager, ops) = OpTestHarness.Create();
        fake.AddResponse("TransactionQueryRq", OpTestHarness.Fixture("TransactionQueryRs.byid.qbxml"));

        try
        {
            await ops["get_transaction"].RunAsync(
                new Dictionary<string, object?>
                {
                    ["txnId"] = "123-456",
                    ["txnType"] = "Invoice",
                },
                default);

            var request = QueryElement(fake.ProcessRequests[0]);
            Assert.Equal("Invoice", request.Element("TransactionTypeList")?.Element("TxnType")?.Value);
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }

    [Fact]
    public async Task get_transaction_requires_exactly_one_of_txn_id_or_ref_number()
    {
        var (_, manager, ops) = OpTestHarness.Create();

        try
        {
            await Assert.ThrowsAsync<ArgumentException>(() => ops["get_transaction"].RunAsync(new Dictionary<string, object?>(), default));
            await Assert.ThrowsAsync<ArgumentException>(() => ops["get_transaction"].RunAsync(
                new Dictionary<string, object?>
                {
                    ["txnId"] = "x",
                    ["refNumber"] = "y",
                },
                default));
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }

    [Fact]
    public async Task get_transaction_surfaces_error_status_does_not_throw()
    {
        var (fake, manager, ops) = OpTestHarness.Create();
        const string errorResponse = """
                                     <QBXML>
                                       <QBXMLMsgsRs>
                                         <TransactionQueryRs statusCode="3120" statusSeverity="Error" statusMessage="Object not found" />
                                       </QBXMLMsgsRs>
                                     </QBXML>
                                     """;
        fake.AddResponse("TransactionQueryRq", errorResponse);

        try
        {
            var result = Assert.IsAssignableFrom<IReadOnlyDictionary<string, object?>>(
                await ops["get_transaction"].RunAsync(
                    new Dictionary<string, object?>
                    {
                        ["txnId"] = "nope",
                    },
                    default));

            var status = Assert.IsType<QbStatus>(result["status"]);
            Assert.True(status.IsError);
            Assert.Equal(0, result["count"]);
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }

    private static XElement QueryElement(string rawRequest) =>
        XDocument.Parse(rawRequest).Root!.Element("QBXMLMsgsRq")!.Element("TransactionQueryRq")!;
}
