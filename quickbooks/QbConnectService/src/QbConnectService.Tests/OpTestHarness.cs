using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using QbConnectService.Qb;
using QbConnectService.Qb.Ops;
using QbConnectService.Tests.Fakes;

namespace QbConnectService.Tests;

public static class OpTestHarness
{
    public static (FakeRequestProcessor Fake, QbConnectionManager Manager, IReadOnlyDictionary<string, IReadOp> Ops) Create(
        QbXmlOptions? options = null)
    {
        var fake = new FakeRequestProcessor();
        var manager = new QbConnectionManager(
            () => fake,
            Options.Create(new QbOptions
            {
                AppId = "app",
                AppName = "QbConnectService",
                CompanyFilePath = @"C:\co.QBW",
            }),
            Options.Create(new RequestOptions
            {
                TimeoutSeconds = 30,
                BusyWaitSeconds = 5,
            }),
            NullLogger<QbConnectionManager>.Instance);
        var xmlOptions = options ?? new QbXmlOptions
        {
            Version = "16.0",
            OwnerIdZero = false,
            MaxReturned = 1,
            MaxResponseBytes = 5_000_000,
            SpillPath = string.Empty,
        };
        var wrappedOptions = Options.Create(xmlOptions);
        var builder = new QbXmlBuilder(wrappedOptions);
        var xmlParser = new QbXmlParser();
        var reportParser = new QbReportParser();
        var spiller = new QbResponseSpiller(wrappedOptions, new ConfigurationBuilder().Build());
        var listExecutor = new QbListExecutor(
            manager,
            builder,
            xmlParser,
            spiller,
            wrappedOptions,
            NullLogger<QbListExecutor>.Instance);

        var ops = new IReadOp[]
        {
            new CompanyInfoOp(builder, manager, xmlParser, reportParser, listExecutor),
            new CompanyPreferencesOp(builder, manager, xmlParser, reportParser, listExecutor),
            new ReportOp(builder, manager, xmlParser, reportParser, listExecutor),
            new ListCustomersOp(builder, manager, xmlParser, reportParser, listExecutor),
            new ListVendorsOp(builder, manager, xmlParser, reportParser, listExecutor),
            new ListAccountsOp(builder, manager, xmlParser, reportParser, listExecutor),
            new ListItemsOp(builder, manager, xmlParser, reportParser, listExecutor),
            new ListInvoicesOp(builder, manager, xmlParser, reportParser, listExecutor),
            new ListBillsOp(builder, manager, xmlParser, reportParser, listExecutor),
            new ListPaymentsOp(builder, manager, xmlParser, reportParser, listExecutor),
            new GetTransactionOp(builder, manager, xmlParser, reportParser, listExecutor),
        }.ToDictionary(op => op.Name, StringComparer.Ordinal);

        return (fake, manager, ops);
    }

    public static string Fixture(string name) =>
        File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "Fixtures", "qbxml", name));
}
