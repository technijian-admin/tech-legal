using System.Xml.Linq;

namespace QbConnectService.Tests;

public sealed class ListEntityOpsTests
{
    [Fact]
    public async Task list_customers_returns_rows_and_applies_filters()
    {
        var (fake, manager, ops) = OpTestHarness.Create();
        fake.AddResponse("CustomerQueryRq", OpTestHarness.Fixture("CustomerQueryRs.normal.qbxml"));

        try
        {
            var result = Assert.IsAssignableFrom<IReadOnlyDictionary<string, object?>>(
                await ops["list_customers"].RunAsync(
                    new Dictionary<string, object?>
                    {
                        ["activeStatus"] = "Active",
                        ["name"] = "Acme",
                    },
                    default));

            var rows = Assert.IsType<List<Dictionary<string, object?>>>(result["rows"]);
            Assert.Equal(2, rows.Count);
            Assert.Equal("Acme Roofing", rows[0]["FullName"]);

            var request = QueryElement(fake.ProcessRequests[0], "CustomerQueryRq");
            Assert.Equal("ActiveOnly", request.Element("ActiveStatus")?.Value);
            Assert.Equal("Acme", request.Element("NameFilter")?.Element("Name")?.Value);
            Assert.Equal("Start", request.Attribute("iterator")?.Value);
            Assert.Single(fake.ProcessRequests);
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }

    [Fact]
    public async Task list_customers_defaults_active_status_to_All()
    {
        var (fake, manager, ops) = OpTestHarness.Create();
        fake.AddResponse("CustomerQueryRq", OpTestHarness.Fixture("CustomerQueryRs.normal.qbxml"));

        try
        {
            await ops["list_customers"].RunAsync(new Dictionary<string, object?>(), default);

            var request = QueryElement(fake.ProcessRequests[0], "CustomerQueryRq");
            Assert.Equal("All", request.Element("ActiveStatus")?.Value);
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }

    [Fact]
    public async Task list_customers_rejects_bad_active_status()
    {
        var (_, manager, ops) = OpTestHarness.Create();

        try
        {
            await Assert.ThrowsAsync<ArgumentException>(() => ops["list_customers"].RunAsync(
                new Dictionary<string, object?>
                {
                    ["activeStatus"] = "Bogus",
                },
                default));
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }

    [Fact]
    public async Task list_vendors_returns_rows()
    {
        var (fake, manager, ops) = OpTestHarness.Create();
        fake.AddResponse("VendorQueryRq", OpTestHarness.Fixture("VendorQueryRs.qbxml"));

        try
        {
            var result = Assert.IsAssignableFrom<IReadOnlyDictionary<string, object?>>(
                await ops["list_vendors"].RunAsync(new Dictionary<string, object?>(), default));

            var rows = Assert.IsType<List<Dictionary<string, object?>>>(result["rows"]);
            Assert.Equal(2, rows.Count);

            var request = QueryElement(fake.ProcessRequests[0], "VendorQueryRq");
            Assert.Equal("All", request.Element("ActiveStatus")?.Value);
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }

    [Fact]
    public async Task list_accounts_returns_rows_and_account_type_filter()
    {
        var (fake, manager, ops) = OpTestHarness.Create();
        fake.AddResponse("AccountQueryRq", OpTestHarness.Fixture("AccountQueryRs.qbxml"));

        try
        {
            var result = Assert.IsAssignableFrom<IReadOnlyDictionary<string, object?>>(
                await ops["list_accounts"].RunAsync(
                    new Dictionary<string, object?>
                    {
                        ["accountType"] = "Bank",
                    },
                    default));

            var rows = Assert.IsType<List<Dictionary<string, object?>>>(result["rows"]);
            Assert.Equal(2, rows.Count);

            var request = QueryElement(fake.ProcessRequests[0], "AccountQueryRq");
            Assert.Equal("Bank", request.Element("AccountType")?.Value);
            Assert.Equal("All", request.Element("ActiveStatus")?.Value);
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }

    [Fact]
    public async Task list_items_normalizes_polymorphic_shapes()
    {
        var (fake, manager, ops) = OpTestHarness.Create();
        fake.AddResponse("ItemQueryRq", OpTestHarness.Fixture("ItemQueryRs.polymorphic.qbxml"));

        try
        {
            var result = Assert.IsAssignableFrom<IReadOnlyDictionary<string, object?>>(
                await ops["list_items"].RunAsync(new Dictionary<string, object?>(), default));

            var rows = Assert.IsType<List<Dictionary<string, object?>>>(result["rows"]);
            Assert.Equal("Service", rows[0]["type"]);
            Assert.Equal("Inventory", rows[1]["type"]);

            var request = QueryElement(fake.ProcessRequests[0], "ItemQueryRq");
            Assert.Equal("All", request.Element("ActiveStatus")?.Value);
            Assert.Equal("Start", request.Attribute("iterator")?.Value);
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }

    [Fact]
    public async Task list_items_returns_rows_for_simple_list()
    {
        var (fake, manager, ops) = OpTestHarness.Create();
        fake.AddResponse("ItemQueryRq", OpTestHarness.Fixture("ItemQueryRs.normal.qbxml"));

        try
        {
            var result = Assert.IsAssignableFrom<IReadOnlyDictionary<string, object?>>(
                await ops["list_items"].RunAsync(new Dictionary<string, object?>(), default));

            var rows = Assert.IsType<List<Dictionary<string, object?>>>(result["rows"]);
            Assert.Equal(2, rows.Count);
            Assert.All(rows, row => Assert.Equal("Service", row["type"]));
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }

    private static XElement QueryElement(string rawRequest, string name) =>
        XDocument.Parse(rawRequest).Root!.Element("QBXMLMsgsRq")!.Element(name)!;
}
