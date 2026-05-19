using System.Text.Json.Nodes;
using System.Xml.Linq;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using QbConnectService.Qb;
using QbConnectService.Qb.Ops;
using QbConnectService.Tests.Fakes;

namespace QbConnectService.Tests;

public sealed class ReceivePaymentOpTests
{
    [Fact]
    public async Task receive_payment_dryrun_with_explicit_applications_is_byte_exact_and_only_reads_preflight()
    {
        var fixture = CreateFixture(allowWrites: false);
        var args = AppliedPaymentArgs();
        fixture.Fake.AddResponse("CustomerQueryRq", Fixture("CustomerQueryRs.formod.qbxml"));

        try
        {
            var result = await fixture.Op.DryRunAsync(args);

            Assert.Equal(fixture.Op.BuildRequest(args), result.QbXml);
            Assert.Contains(result.PreFlight, check => check.Name == "application-mode" && check.Ok);
            Assert.Single(fixture.Fake.ProcessRequests);
            Assert.DoesNotContain("<ReceivePaymentAddRq>", fixture.Fake.ProcessRequests[0], StringComparison.Ordinal);
            Assert.False(File.Exists(Path.Combine(fixture.AuditDir, "audit.jsonl")));

            var add = RequestBody(result.QbXml).Element("ReceivePaymentAdd")!;
            Assert.Equal("Acme Co", add.Element("CustomerRef")?.Element("FullName")?.Value);
            var applied = add.Element("AppliedToTxnAdd");
            Assert.NotNull(applied);
            Assert.Equal("1A2B-3C4D5E6F7G", applied!.Element("TxnID")?.Value);
            Assert.Equal("100.00", applied.Element("PaymentAmount")?.Value);
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task receive_payment_dryrun_with_auto_apply_uses_IsAutoApply_and_omits_applications()
    {
        var fixture = CreateFixture(allowWrites: false);
        var args = new Dictionary<string, object?>(StringComparer.Ordinal)
        {
            ["customerRef"] = "Acme Co",
            ["isAutoApply"] = true,
            ["totalAmount"] = "100.00",
        };
        fixture.Fake.AddResponse("CustomerQueryRq", Fixture("CustomerQueryRs.formod.qbxml"));

        try
        {
            var result = await fixture.Op.DryRunAsync(args);

            Assert.Contains(result.PreFlight, check => check.Name == "application-mode" && check.Detail!.Contains("auto-applies", StringComparison.Ordinal));
            var add = RequestBody(result.QbXml).Element("ReceivePaymentAdd")!;
            Assert.Equal("true", add.Element("IsAutoApply")?.Value);
            Assert.Null(add.Element("AppliedToTxnAdd"));
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task receive_payment_without_application_mode_throws_argumentexception()
    {
        var fixture = CreateFixture(allowWrites: false);
        var args = new Dictionary<string, object?>(StringComparer.Ordinal)
        {
            ["customerRef"] = "Acme Co",
            ["totalAmount"] = "100.00",
        };

        try
        {
            await Assert.ThrowsAsync<ArgumentException>(() => fixture.Op.DryRunAsync(args));
            Assert.Throws<ArgumentException>(() => fixture.Op.BuildRequest(args));
            Assert.Empty(fixture.Fake.ProcessRequests);
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task receive_payment_without_customerref_throws_argumentexception()
    {
        var fixture = CreateFixture(allowWrites: false);
        var args = new Dictionary<string, object?>(StringComparer.Ordinal)
        {
            ["isAutoApply"] = true,
        };

        try
        {
            await Assert.ThrowsAsync<ArgumentException>(() => fixture.Op.DryRunAsync(args));
            Assert.Throws<ArgumentException>(() => fixture.Op.BuildRequest(args));
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task receive_payment_requires_payment_amount_for_each_application()
    {
        var fixture = CreateFixture(allowWrites: false);
        var args = new Dictionary<string, object?>(StringComparer.Ordinal)
        {
            ["customerRef"] = "Acme Co",
            ["appliedTo"] = new List<object?>
            {
                new Dictionary<string, object?> { ["txnID"] = "T1" },
            },
        };

        try
        {
            await Assert.ThrowsAsync<ArgumentException>(() => fixture.Op.DryRunAsync(args));
            Assert.Throws<ArgumentException>(() => fixture.Op.BuildRequest(args));
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task receive_payment_execute_happy_path_writes_exactly_one_audit_row()
    {
        var fixture = CreateFixture(allowWrites: true);
        var args = AppliedPaymentArgs();
        fixture.Fake.AddResponse("ReceivePaymentAddRq", Fixture("ReceivePaymentAddRs.qbxml"));

        try
        {
            var result = Assert.IsType<Dictionary<string, object?>>(await fixture.Op.RunAsync(args));

            Assert.Equal(fixture.Op.BuildRequest(args), fixture.Fake.ProcessRequests.Last());
            var status = Assert.IsType<QbStatus>(result["status"]);
            Assert.Equal("0", status.Code);
            var rows = Assert.IsType<List<Dictionary<string, object?>>>(result["rows"]);
            Assert.Equal("RCP-0001-AAA", rows[0]["TxnID"]);

            var auditRows = ReadAuditRows(fixture.AuditDir);
            Assert.Single(auditRows);
            Assert.Equal("receive_payment", auditRows[0]["op"]!.GetValue<string>());
            Assert.Equal("0", auditRows[0]["responseStatusCode"]!.GetValue<string>());
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task receive_payment_execute_qb_error_returns_status_and_audits_once()
    {
        var fixture = CreateFixture(allowWrites: true);
        fixture.Fake.AddResponse(
            "ReceivePaymentAddRq",
            """
            <QBXML>
              <QBXMLMsgsRs statusCode="3140" statusSeverity="Error" statusMessage="There is an invalid reference to QuickBooks Customer &quot;Missing&quot;.">
                <ReceivePaymentAddRs requestID="1" statusCode="3140" statusSeverity="Error" statusMessage="There is an invalid reference to QuickBooks Customer &quot;Missing&quot;." />
              </QBXMLMsgsRs>
            </QBXML>
            """);

        try
        {
            var result = Assert.IsType<Dictionary<string, object?>>(await fixture.Op.RunAsync(AppliedPaymentArgs()));

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
    public async Task receive_payment_with_writes_disabled_throws_without_side_effects()
    {
        var fixture = CreateFixture(allowWrites: false);

        try
        {
            await Assert.ThrowsAsync<QbWriteForbiddenException>(() => fixture.Op.RunAsync(AppliedPaymentArgs()));
            Assert.Empty(fixture.Fake.ProcessRequests);
            Assert.False(File.Exists(Path.Combine(fixture.AuditDir, "audit.jsonl")));
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    private static IReadOnlyDictionary<string, object?> AppliedPaymentArgs()
    {
        return new Dictionary<string, object?>(StringComparer.Ordinal)
        {
            ["customerRef"] = "Acme Co",
            ["totalAmount"] = "100.00",
            ["appliedTo"] = new List<object?>
            {
                new Dictionary<string, object?>(StringComparer.Ordinal)
                {
                    ["txnID"] = "1A2B-3C4D5E6F7G",
                    ["paymentAmount"] = "100.00",
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

    private static XElement RequestBody(string qbXml) =>
        XDocument.Parse(qbXml).Root!.Element("QBXMLMsgsRq")!.Element("ReceivePaymentAddRq")!;

    private static ReceivePaymentFixture CreateFixture(bool allowWrites)
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
            Options.Create(new SafetyOptions { AllowWrites = allowWrites }),
            new FakeQbProcessManager(),
            new QbKillTracker());

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
        var op = new ReceivePaymentOp(
            builder,
            manager,
            parser,
            reportParser,
            listExecutor,
            audit,
            Options.Create(new SafetyOptions { AllowWrites = allowWrites }));

        return new ReceivePaymentFixture(op, manager, fake, auditDir);
    }

    private sealed class ReceivePaymentFixture(ReceivePaymentOp op, QbConnectionManager manager, FakeRequestProcessor fake, string auditDir) : IAsyncDisposable
    {
        public ReceivePaymentOp Op { get; } = op;
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
