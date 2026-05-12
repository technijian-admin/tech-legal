using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using QbConnectService.Qb;
using QbConnectService.Qb.Ops;
using QbConnectService.Tests.Fakes;

namespace QbConnectService.Tests;

public sealed class OpRegistrationTests
{
    [Fact]
    public void host_resolves_all_registered_ops_and_write_ops_are_gated_types()
    {
        var auditPath = Path.Combine(Path.GetTempPath(), "QbConnectService.Tests", Guid.NewGuid().ToString("N"));

        using var host = Host.CreateDefaultBuilder()
            .ConfigureServices(services =>
            {
                services.Configure<QbOptions>(_ => { });
                services.Configure<RequestOptions>(_ => { });
                services.Configure<QbXmlOptions>(_ => { });
                services.Configure<SafetyOptions>(_ => { });
                services.Configure<AuditOptions>(options => options.Path = auditPath);
                services.Configure<AuditAuthOptions>(options => options.ApiToken = "test-token");
                services.AddSingleton<Func<IRequestProcessor>>(_ => () => new FakeRequestProcessor());
                services.AddSingleton<QbConnectionManager>();
                services.AddSingleton<QbXmlBuilder>();
                services.AddSingleton<QbXmlParser>();
                services.AddSingleton<QbReportParser>();
                services.AddSingleton<QbResponseSpiller>();
                services.AddSingleton<QbListExecutor>();
                services.AddSingleton<AuditLog>();
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
                services.AddSingleton<IReadOp, CreateCustomerOp>();
                services.AddSingleton<IReadOp, CreateVendorOp>();
                services.AddSingleton<IReadOp, CreateInvoiceOp>();
                services.AddSingleton<IReadOp, CreateBillOp>();
                services.AddSingleton<IReadOp, CreateCheckOp>();
                services.AddSingleton<IReadOp, ReceivePaymentOp>();
                services.AddSingleton<IReadOp, CreateJournalEntryOp>();
                services.AddSingleton<IReadOp, ModOp>();
            })
            .Build();

        var ops = host.Services.GetServices<IReadOp>().ToList();
        var names = ops.Select(op => op.Name).ToList();

        Assert.Equal(20, ops.Count);
        Assert.Equal(20, names.Distinct().Count());

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
                     "create_customer",
                     "create_vendor",
                     "create_invoice",
                     "create_bill",
                     "create_check",
                     "receive_payment",
                     "create_journal_entry",
                     "mod",
                 })
        {
            Assert.Contains(expected, names);
        }

        foreach (var expectedWrite in new[]
                 {
                     "create_customer",
                     "create_vendor",
                     "create_invoice",
                     "create_bill",
                     "create_check",
                     "receive_payment",
                     "create_journal_entry",
                     "mod",
                 })
        {
            Assert.IsAssignableFrom<IWriteOp>(ops.Single(op => op.Name == expectedWrite));
        }
    }
}
