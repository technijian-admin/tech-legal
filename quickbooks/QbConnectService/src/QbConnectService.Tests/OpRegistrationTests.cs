using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using QbConnectService.Qb;
using QbConnectService.Qb.Ops;
using QbConnectService.Tests.Fakes;

namespace QbConnectService.Tests;

public sealed class OpRegistrationTests
{
    [Fact]
    public void host_resolves_all_twelve_read_ops()
    {
        using var host = Host.CreateDefaultBuilder()
            .ConfigureServices(services =>
            {
                services.Configure<QbOptions>(_ => { });
                services.Configure<RequestOptions>(_ => { });
                services.Configure<QbXmlOptions>(_ => { });
                services.AddSingleton<Func<IRequestProcessor>>(_ => () => new FakeRequestProcessor());
                services.AddSingleton<QbConnectionManager>();
                services.AddSingleton<QbXmlBuilder>();
                services.AddSingleton<QbXmlParser>();
                services.AddSingleton<QbReportParser>();
                services.AddSingleton<QbResponseSpiller>();
                services.AddSingleton<QbListExecutor>();
                services.AddSingleton<IReadOp, CompanyInfoOp>();
                services.AddSingleton<IReadOp, CompanyPreferencesOp>();
                services.AddSingleton<IReadOp, ReportOp>();
                services.AddSingleton<IReadOp, ListCustomersOp>();
                services.AddSingleton<IReadOp, ListVendorsOp>();
                services.AddSingleton<IReadOp, ListAccountsOp>();
                services.AddSingleton<IReadOp, ListItemsOp>();
                services.AddSingleton<IReadOp, ListInvoicesOp>();
                services.AddSingleton<IReadOp, ListBillsOp>();
                services.AddSingleton<IReadOp, ListPaymentsOp>();
                services.AddSingleton<IReadOp, GetTransactionOp>();
                services.AddSingleton<IReadOp, RunQueryOp>();
            })
            .Build();

        var ops = host.Services.GetServices<IReadOp>().ToList();
        var names = ops.Select(op => op.Name).ToList();

        Assert.Equal(12, ops.Count);
        Assert.Equal(12, names.Distinct().Count());

        foreach (var expected in new[]
                 {
                     "company_info",
                     "get_company_preferences",
                     "report",
                     "list_customers",
                     "list_vendors",
                     "list_items",
                     "list_accounts",
                     "list_invoices",
                     "list_bills",
                     "list_payments",
                     "get_transaction",
                     "run_query",
                 })
        {
            Assert.Contains(expected, names);
        }
    }
}
