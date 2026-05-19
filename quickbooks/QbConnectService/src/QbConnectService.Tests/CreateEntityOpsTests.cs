using System.Text.Json.Nodes;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using QbConnectService.Qb;
using QbConnectService.Qb.Ops;
using QbConnectService.Tests.Fakes;

namespace QbConnectService.Tests;

public sealed class CreateEntityOpsTests
{
    [Fact]
    public async Task create_customer_dryrun_is_byte_exact_and_only_reads_for_preflight()
    {
        var fixture = CreateFixture(allowWrites: false, CreateCustomer);
        var args = CustomerArgs();
        fixture.Fake.AddResponse("CustomerQueryRq", Fixture("CustomerQueryRs.zerorows.qbxml"));

        try
        {
            var result = await fixture.Op.DryRunAsync(args);

            Assert.Equal(fixture.Op.BuildRequest(args), result.QbXml);
            Assert.False(result.AllowWrites);
            Assert.Contains(result.PreFlight, check => check.Name == "name-present" && check.Ok);
            Assert.Contains(result.PreFlight, check => check.Name == "name-not-already-in-use" && check.Ok);
            Assert.Single(fixture.Fake.ProcessRequests);
            Assert.Contains("<CustomerQueryRq>", fixture.Fake.ProcessRequests[0], StringComparison.Ordinal);
            Assert.DoesNotContain("<CustomerAddRq>", fixture.Fake.ProcessRequests[0], StringComparison.Ordinal);
            Assert.False(File.Exists(Path.Combine(fixture.AuditDir, "audit.jsonl")));
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task create_customer_dryrun_warns_when_name_is_already_in_use()
    {
        var fixture = CreateFixture(allowWrites: false, CreateCustomer);
        fixture.Fake.AddResponse("CustomerQueryRq", Fixture("CustomerQueryRs.formod.qbxml"));

        try
        {
            var result = await fixture.Op.DryRunAsync(CustomerArgs());

            Assert.Contains(
                result.PreFlight,
                check => check.Name == "name-not-already-in-use" && !check.Ok && check.Detail!.Contains("ListID 80000001-AAAAAAAA", StringComparison.Ordinal));
            Assert.Single(fixture.Fake.ProcessRequests);
            Assert.False(File.Exists(Path.Combine(fixture.AuditDir, "audit.jsonl")));
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task create_customer_dryrun_resolves_terms()
    {
        var fixture = CreateFixture(allowWrites: false, CreateCustomer);
        fixture.Fake.AddResponse("CustomerQueryRq", Fixture("CustomerQueryRs.zerorows.qbxml"));
        fixture.Fake.AddResponse(
            "TermQueryRq",
            """
            <QBXML>
              <QBXMLMsgsRs statusCode="0" statusSeverity="Info" statusMessage="Status OK">
                <TermQueryRs statusCode="0" statusSeverity="Info" statusMessage="Status OK">
                  <TermRet>
                    <ListID>80000077-TERM</ListID>
                    <Name>Net 30</Name>
                    <FullName>Net 30</FullName>
                  </TermRet>
                </TermQueryRs>
              </QBXMLMsgsRs>
            </QBXML>
            """);

        try
        {
            var args = CustomerArgs(("terms", "Net 30"));
            var result = await fixture.Op.DryRunAsync(args);

            Assert.Equal("80000077-TERM", result.ResolvedReferences["termsRef"]);
            Assert.Contains(result.PreFlight, check => check.Name == "terms-resolves" && check.Ok);
            Assert.Equal(2, fixture.Fake.ProcessRequests.Count);
            Assert.Contains("<TermQueryRq>", fixture.Fake.ProcessRequests[1], StringComparison.Ordinal);
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task create_customer_execute_happy_path_writes_exactly_one_audit_row()
    {
        var fixture = CreateFixture(allowWrites: true, CreateCustomer);
        var args = CustomerArgs();
        fixture.Fake.AddResponse("CustomerAddRq", Fixture("CustomerAddRs.qbxml"));

        try
        {
            var result = Assert.IsType<Dictionary<string, object?>>(await fixture.Op.RunAsync(args));

            Assert.Equal(fixture.Op.BuildRequest(args), fixture.Fake.ProcessRequests.Last());
            Assert.Single(fixture.Fake.ProcessRequests);
            var rows = Assert.IsType<List<Dictionary<string, object?>>>(result["rows"]);
            Assert.Equal("80000001-1234567890", rows[0]["ListID"]);
            var status = Assert.IsType<QbStatus>(result["status"]);
            Assert.Equal("0", status.Code);

            var auditRows = ReadAuditRows(fixture.AuditDir);
            Assert.Single(auditRows);
            Assert.Equal("create_customer", auditRows[0]["op"]!.GetValue<string>());
            Assert.Equal("0", auditRows[0]["responseStatusCode"]!.GetValue<string>());
            Assert.Equal("Info", auditRows[0]["responseStatusSeverity"]!.GetValue<string>());
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task create_customer_execute_returns_qb_3100_and_still_audits_once()
    {
        var fixture = CreateFixture(allowWrites: true, CreateCustomer);
        fixture.Fake.AddResponse(
            "CustomerAddRq",
            """
            <QBXML>
              <QBXMLMsgsRs statusCode="3100" statusSeverity="Error" statusMessage="The name &quot;Acme Co&quot; is already in use.">
                <CustomerAddRs statusCode="3100" statusSeverity="Error" statusMessage="The name &quot;Acme Co&quot; is already in use." />
              </QBXMLMsgsRs>
            </QBXML>
            """);

        try
        {
            var result = Assert.IsType<Dictionary<string, object?>>(await fixture.Op.RunAsync(CustomerArgs()));

            var status = Assert.IsType<QbStatus>(result["status"]);
            Assert.Equal("3100", status.Code);
            Assert.Equal("Error", status.Severity);

            var auditRows = ReadAuditRows(fixture.AuditDir);
            Assert.Single(auditRows);
            Assert.Equal("3100", auditRows[0]["responseStatusCode"]!.GetValue<string>());
            Assert.Equal("Error", auditRows[0]["responseStatusSeverity"]!.GetValue<string>());
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task create_customer_execute_with_writes_disabled_throws_without_side_effects()
    {
        var fixture = CreateFixture(allowWrites: false, CreateCustomer);

        try
        {
            await Assert.ThrowsAsync<QbWriteForbiddenException>(() => fixture.Op.RunAsync(CustomerArgs()));
            Assert.Empty(fixture.Fake.ProcessRequests);
            Assert.False(File.Exists(Path.Combine(fixture.AuditDir, "audit.jsonl")));
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task create_customer_execute_propagates_com_failures_without_auditing()
    {
        var fixture = CreateFixture(allowWrites: true, CreateCustomer);
        fixture.Fake.EnqueueComError(unchecked((int)0x80040408));

        try
        {
            await Assert.ThrowsAsync<QbException>(() => fixture.Op.RunAsync(CustomerArgs()));
            Assert.False(File.Exists(Path.Combine(fixture.AuditDir, "audit.jsonl")));
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task create_vendor_dryrun_is_byte_exact_and_only_reads_for_preflight()
    {
        var fixture = CreateFixture(allowWrites: false, CreateVendor);
        var args = VendorArgs();
        fixture.Fake.AddResponse(
            "VendorQueryRq",
            """
            <QBXML>
              <QBXMLMsgsRs statusCode="0" statusSeverity="Info" statusMessage="Status OK">
                <VendorQueryRs statusCode="1" statusSeverity="Info" statusMessage="A query request did not find a matching object in QuickBooks" />
              </QBXMLMsgsRs>
            </QBXML>
            """);

        try
        {
            var result = await fixture.Op.DryRunAsync(args);

            Assert.Equal(fixture.Op.BuildRequest(args), result.QbXml);
            Assert.Contains(result.PreFlight, check => check.Name == "name-not-already-in-use" && check.Ok);
            Assert.Single(fixture.Fake.ProcessRequests);
            Assert.Contains("<VendorQueryRq>", fixture.Fake.ProcessRequests[0], StringComparison.Ordinal);
            Assert.False(File.Exists(Path.Combine(fixture.AuditDir, "audit.jsonl")));
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task create_vendor_execute_happy_path_writes_exactly_one_audit_row()
    {
        var fixture = CreateFixture(allowWrites: true, CreateVendor);
        var args = VendorArgs();
        fixture.Fake.AddResponse("VendorAddRq", Fixture("VendorAddRs.qbxml"));

        try
        {
            var result = Assert.IsType<Dictionary<string, object?>>(await fixture.Op.RunAsync(args));

            Assert.Equal(fixture.Op.BuildRequest(args), fixture.Fake.ProcessRequests.Last());
            Assert.Single(fixture.Fake.ProcessRequests);
            var status = Assert.IsType<QbStatus>(result["status"]);
            Assert.Equal("0", status.Code);

            var auditRows = ReadAuditRows(fixture.AuditDir);
            Assert.Single(auditRows);
            Assert.Equal("create_vendor", auditRows[0]["op"]!.GetValue<string>());
            Assert.Equal("0", auditRows[0]["responseStatusCode"]!.GetValue<string>());
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    private static CreateCustomerOp CreateCustomer(
        QbXmlBuilder builder,
        QbConnectionManager manager,
        QbXmlParser parser,
        QbReportParser reportParser,
        QbListExecutor listExecutor,
        AuditLog audit,
        IOptions<SafetyOptions> safety) =>
        new(builder, manager, parser, reportParser, listExecutor, audit, safety);

    private static CreateVendorOp CreateVendor(
        QbXmlBuilder builder,
        QbConnectionManager manager,
        QbXmlParser parser,
        QbReportParser reportParser,
        QbListExecutor listExecutor,
        AuditLog audit,
        IOptions<SafetyOptions> safety) =>
        new(builder, manager, parser, reportParser, listExecutor, audit, safety);

    private static IReadOnlyDictionary<string, object?> CustomerArgs(params (string Key, object? Value)[] overrides)
    {
        var dict = new Dictionary<string, object?>(StringComparer.Ordinal)
        {
            ["name"] = "Acme Co",
            ["companyName"] = "Acme Company",
            ["firstName"] = "Jane",
            ["lastName"] = "Doe",
            ["billAddress"] = new Dictionary<string, object?>(StringComparer.Ordinal)
            {
                ["addr1"] = "1 Main St",
                ["city"] = "Irvine",
                ["state"] = "CA",
                ["postalCode"] = "92614",
            },
            ["phone"] = "949-555-0100",
            ["email"] = "jane@acme.example",
            ["isActive"] = true,
        };

        foreach (var (key, value) in overrides)
        {
            dict[key] = value;
        }

        return dict;
    }

    private static IReadOnlyDictionary<string, object?> VendorArgs(params (string Key, object? Value)[] overrides)
    {
        var dict = new Dictionary<string, object?>(StringComparer.Ordinal)
        {
            ["name"] = "Office Supplies LLC",
            ["companyName"] = "Office Supplies LLC",
            ["phone"] = "949-555-0200",
            ["email"] = "ap@office.example",
            ["vendorAddress"] = new Dictionary<string, object?>(StringComparer.Ordinal)
            {
                ["addr1"] = "250 Market St",
                ["city"] = "Irvine",
                ["state"] = "CA",
                ["postalCode"] = "92614",
            },
        };

        foreach (var (key, value) in overrides)
        {
            dict[key] = value;
        }

        return dict;
    }

    private static string Fixture(string name) =>
        File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "Fixtures", "qbxml", name));

    private static IReadOnlyList<JsonObject> ReadAuditRows(string auditDir) =>
        File.ReadAllLines(Path.Combine(auditDir, "audit.jsonl"))
            .Where(line => !string.IsNullOrWhiteSpace(line))
            .Select(line => JsonNode.Parse(line)!.AsObject())
            .ToList();

    private static EntityOpFixture<TOp> CreateFixture<TOp>(
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
        var safety = Options.Create(new SafetyOptions { AllowWrites = allowWrites });

        return new EntityOpFixture<TOp>(
            factory(builder, manager, parser, reportParser, listExecutor, audit, safety),
            manager,
            fake,
            auditDir);
    }

    private sealed class EntityOpFixture<TOp>(TOp op, QbConnectionManager manager, FakeRequestProcessor fake, string auditDir) : IAsyncDisposable
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
