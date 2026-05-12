using System.Net;
using System.Net.Http.Headers;
using Microsoft.Extensions.DependencyInjection;
using QbConnectService.Qb.Ops;

namespace QbConnectService.Tests;

public sealed class OpRegistryTests
{
    private static readonly string[] ExpectedNames =
    [
        "company_info",
        "get_company_preferences",
        "report",
        "list_customers",
        "list_vendors",
        "list_accounts",
        "list_items",
        "list_invoices",
        "list_bills",
        "list_payments",
        "get_transaction",
        "run_query",
        "create_customer",
        "create_vendor",
        "fake_create",
    ];

    [Fact]
    public async Task registry_resolves_all_registered_ops()
    {
        await using var factory = new QbWebAppFactory();

        var registry = factory.Services.GetRequiredService<OpRegistry>();

        Assert.True(registry.Names.Count >= ExpectedNames.Length);
        Assert.Equal(registry.Names.Count, registry.Names.Distinct().Count());
        foreach (var name in ExpectedNames)
        {
            Assert.Contains(name, registry.Names);
            Assert.True(registry.TryGet(name, out var op));
            Assert.Equal(name, op!.Name);
        }
    }

    [Fact]
    public void duplicate_op_name_throws()
    {
        var exception = Assert.Throws<InvalidOperationException>(() => new OpRegistry(
            [new FakeOp("x"), new FakeOp("x")]));

        Assert.Equal("Duplicate op name 'x'.", exception.Message);
    }

    [Fact]
    public async Task get_api_ops_requires_token_and_lists_registered_names()
    {
        await using var factory = new QbWebAppFactory();

        using var unauthenticated = factory.CreateClient();
        var unauthorized = await unauthenticated.GetAsync("/api/ops");
        Assert.Equal(HttpStatusCode.Unauthorized, unauthorized.StatusCode);

        using var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", QbWebAppFactory.Token);

        var response = await client.GetAsync("/api/ops");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("\"company_info\"", body, StringComparison.Ordinal);
    }

    private sealed class FakeOp(string name) : IReadOp
    {
        public string Name => name;

        public Task<object?> RunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default) =>
            Task.FromResult<object?>(null);
    }
}
