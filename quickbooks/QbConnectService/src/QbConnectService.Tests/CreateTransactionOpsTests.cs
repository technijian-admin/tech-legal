using System.Text.Json.Nodes;
using System.Xml.Linq;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using QbConnectService.Qb;
using QbConnectService.Qb.Ops;
using QbConnectService.Tests.Fakes;

namespace QbConnectService.Tests;

public sealed class CreateTransactionOpsTests
{
    [Fact]
    public async Task create_invoice_dryrun_is_byte_exact_and_only_reads_for_preflight()
    {
        var fixture = CreateFixture(allowWrites: false, CreateInvoice);
        var args = InvoiceArgs();
        fixture.Fake.AddResponse("CustomerQueryRq", Fixture("CustomerQueryRs.formod.qbxml"));
        fixture.Fake.AddResponse("ItemQueryRq", Fixture("ItemQueryRs.normal.qbxml"));

        try
        {
            var result = await fixture.Op.DryRunAsync(args);

            Assert.Equal(fixture.Op.BuildRequest(args), result.QbXml);
            Assert.Contains(result.PreFlight, check => check.Name == "line-count" && check.Ok && check.Detail == "1 line(s)");
            Assert.Equal(2, fixture.Fake.ProcessRequests.Count);
            Assert.All(fixture.Fake.ProcessRequests, request => Assert.DoesNotContain("<InvoiceAddRq>", request, StringComparison.Ordinal));
            Assert.False(File.Exists(Path.Combine(fixture.AuditDir, "audit.jsonl")));

            var add = RequestBody(result.QbXml, "InvoiceAddRq").Element("InvoiceAdd")!;
            Assert.Equal("Acme Co", add.Element("CustomerRef")?.Element("FullName")?.Value);
            var line = add.Element("InvoiceLineAdd");
            Assert.NotNull(line);
            Assert.Equal("Consulting", line!.Element("ItemRef")?.Element("FullName")?.Value);
            Assert.Equal("100.00", line.Element("Rate")?.Value);
            Assert.Null(line.Element("TxnLineID"));
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task create_invoice_missing_or_empty_lines_throws_argumentexception()
    {
        var fixture = CreateFixture(allowWrites: false, CreateInvoice);

        try
        {
            var missingLinesArgs = new Dictionary<string, object?>(StringComparer.Ordinal)
            {
                ["customerRef"] = "Acme Co",
            };
            await Assert.ThrowsAsync<ArgumentException>(() => fixture.Op.DryRunAsync(missingLinesArgs));
            Assert.Throws<ArgumentException>(() => fixture.Op.BuildRequest(missingLinesArgs));

            var emptyLinesArgs = new Dictionary<string, object?>(StringComparer.Ordinal)
            {
                ["customerRef"] = "Acme Co",
                ["lines"] = new List<object?>(),
            };
            await Assert.ThrowsAsync<ArgumentException>(() => fixture.Op.DryRunAsync(emptyLinesArgs));
            Assert.Throws<ArgumentException>(() => fixture.Op.BuildRequest(emptyLinesArgs));

            Assert.Empty(fixture.Fake.ProcessRequests);
            Assert.False(File.Exists(Path.Combine(fixture.AuditDir, "audit.jsonl")));
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task create_invoice_without_customerref_throws_argumentexception()
    {
        var fixture = CreateFixture(allowWrites: false, CreateInvoice);

        try
        {
            var args = new Dictionary<string, object?>(StringComparer.Ordinal)
            {
                ["lines"] = new List<object?> { new Dictionary<string, object?> { ["itemRef"] = "Consulting", ["rate"] = "100.00" } },
            };

            var ex = Assert.Throws<ArgumentException>(() => fixture.Op.BuildRequest(args));
            Assert.Equal("'customerRef' is required.", ex.Message);
            Assert.Empty(fixture.Fake.ProcessRequests);
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task create_invoice_execute_happy_path_writes_exactly_one_audit_row()
    {
        var fixture = CreateFixture(allowWrites: true, CreateInvoice);
        var args = InvoiceArgs();
        fixture.Fake.AddResponse("InvoiceAddRq", Fixture("InvoiceAddRs.success.qbxml"));

        try
        {
            var result = Assert.IsType<Dictionary<string, object?>>(await fixture.Op.RunAsync(args));

            Assert.Equal(fixture.Op.BuildRequest(args), fixture.Fake.ProcessRequests.Last());
            Assert.Single(fixture.Fake.ProcessRequests);
            var status = Assert.IsType<QbStatus>(result["status"]);
            Assert.Equal("0", status.Code);
            var rows = Assert.IsType<List<Dictionary<string, object?>>>(result["rows"]);
            Assert.Equal("1A2B-3C4D5E6F7G", rows[0]["TxnID"]);

            var auditRows = ReadAuditRows(fixture.AuditDir);
            Assert.Single(auditRows);
            Assert.Equal("create_invoice", auditRows[0]["op"]!.GetValue<string>());
            Assert.Equal("0", auditRows[0]["responseStatusCode"]!.GetValue<string>());
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task create_invoice_execute_qb_error_returns_status_and_audits_once()
    {
        var fixture = CreateFixture(allowWrites: true, CreateInvoice);
        fixture.Fake.AddResponse(
            "InvoiceAddRq",
            """
            <QBXML>
              <QBXMLMsgsRs statusCode="3140" statusSeverity="Error" statusMessage="There is an invalid reference to QuickBooks Item &quot;Missing Item&quot; in the Invoice line.">
                <InvoiceAddRs requestID="1" statusCode="3140" statusSeverity="Error" statusMessage="There is an invalid reference to QuickBooks Item &quot;Missing Item&quot; in the Invoice line." />
              </QBXMLMsgsRs>
            </QBXML>
            """);

        try
        {
            var result = Assert.IsType<Dictionary<string, object?>>(await fixture.Op.RunAsync(InvoiceArgs()));

            var status = Assert.IsType<QbStatus>(result["status"]);
            Assert.Equal("3140", status.Code);
            Assert.Equal("Error", status.Severity);

            var auditRows = ReadAuditRows(fixture.AuditDir);
            Assert.Single(auditRows);
            Assert.Equal("3140", auditRows[0]["responseStatusCode"]!.GetValue<string>());
            Assert.Equal("Error", auditRows[0]["responseStatusSeverity"]!.GetValue<string>());
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task create_invoice_execute_with_writes_disabled_throws_without_side_effects()
    {
        var fixture = CreateFixture(allowWrites: false, CreateInvoice);

        try
        {
            await Assert.ThrowsAsync<QbWriteForbiddenException>(() => fixture.Op.RunAsync(InvoiceArgs()));
            Assert.Empty(fixture.Fake.ProcessRequests);
            Assert.False(File.Exists(Path.Combine(fixture.AuditDir, "audit.jsonl")));
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    private static CreateInvoiceOp CreateInvoice(
        QbXmlBuilder builder,
        QbConnectionManager manager,
        QbXmlParser parser,
        QbReportParser reportParser,
        QbListExecutor listExecutor,
        AuditLog audit,
        IOptions<SafetyOptions> safety) =>
        new(builder, manager, parser, reportParser, listExecutor, audit, safety);

    private static IReadOnlyDictionary<string, object?> InvoiceArgs()
    {
        return new Dictionary<string, object?>(StringComparer.Ordinal)
        {
            ["customerRef"] = "Acme Co",
            ["txnDate"] = "2026-05-11",
            ["refNumber"] = "INV-1001",
            ["lines"] = new List<object?>
            {
                new Dictionary<string, object?>(StringComparer.Ordinal)
                {
                    ["itemRef"] = "Consulting",
                    ["desc"] = "Consulting",
                    ["quantity"] = "1",
                    ["rate"] = "100.00",
                },
            },
        };
    }

    private static string Fixture(string name) =>
        File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "Fixtures", "qbxml", name));

    private static IReadOnlyList<JsonObject> ReadAuditRows(string auditDir) =>
        File.ReadAllLines(Path.Combine(auditDir, "audit.jsonl"))
            .Where(line => !string.IsNullOrWhiteSpace(line))
            .Select(line => JsonNode.Parse(line)!.AsObject())
            .ToList();

    private static XElement RequestBody(string qbXml, string requestName) =>
        XDocument.Parse(qbXml).Root!.Element("QBXMLMsgsRq")!.Element(requestName)!;

    private static TransactionOpFixture<TOp> CreateFixture<TOp>(
        bool allowWrites,
        Func<QbXmlBuilder, QbConnectionManager, QbXmlParser, QbReportParser, QbListExecutor, AuditLog, IOptions<SafetyOptions>, TOp> factory)
        where TOp : class, IWriteOp
    {
        var auditDir = Path.Combine(Path.GetTempPath(), "qbtest", Guid.NewGuid().ToString());
        Directory.CreateDirectory(auditDir);

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
            NullLogger<QbConnectionManager>.Instance,
            Options.Create(new SafetyOptions { AllowWrites = allowWrites }));

        var xmlOptions = Options.Create(new QbXmlOptions
        {
            Version = "16.0",
            MaxReturned = 100,
            MaxResponseBytes = 5_000_000,
        });
        var builder = new QbXmlBuilder(xmlOptions);
        var parser = new QbXmlParser();
        var reportParser = new QbReportParser();
        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?> { ["Audit:Path"] = auditDir })
            .Build();
        var spiller = new QbResponseSpiller(xmlOptions, configuration);
        var listExecutor = new QbListExecutor(
            manager,
            builder,
            parser,
            spiller,
            xmlOptions,
            NullLogger<QbListExecutor>.Instance);
        var audit = new AuditLog(
            Options.Create(new AuditOptions { Path = auditDir }),
            Options.Create(new AuditAuthOptions { ApiToken = "test-token" }),
            NullLogger<AuditLog>.Instance);
        var safety = Options.Create(new SafetyOptions { AllowWrites = allowWrites });

        return new TransactionOpFixture<TOp>(
            factory(builder, manager, parser, reportParser, listExecutor, audit, safety),
            manager,
            fake,
            auditDir);
    }

    private sealed class TransactionOpFixture<TOp>(TOp op, QbConnectionManager manager, FakeRequestProcessor fake, string auditDir) : IAsyncDisposable
        where TOp : class, IWriteOp
    {
        public TOp Op { get; } = op;
        public QbConnectionManager Manager { get; } = manager;
        public FakeRequestProcessor Fake { get; } = fake;
        public string AuditDir { get; } = auditDir;

        public async ValueTask DisposeAsync()
        {
            await Manager.DisposeAsync();
            if (Directory.Exists(AuditDir))
            {
                Directory.Delete(AuditDir, recursive: true);
            }
        }
    }
}
