using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using QbConnectService.Qb;
using QbConnectService.Tests.Fakes;
using System.Text.Json.Nodes;

namespace QbConnectService.Tests;

public sealed class WriteOpBaseTests
{
    [Fact]
    public async Task build_request_is_deterministic_and_pure()
    {
        var fixture = CreateFixture(allowWrites: true);
        try
        {
            var first = fixture.Op.BuildRequest(EmptyArgs);
            var second = fixture.Op.BuildRequest(EmptyArgs);

            Assert.Equal(FakeWriteOp.KnownRequestXml, first);
            Assert.Equal(first, second);
            Assert.Empty(fixture.Fake.ProcessRequests);
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task run_with_allowwrites_true_executes_byte_exact_parses_and_appends_one_audit_row()
    {
        var fixture = CreateFixture(allowWrites: true);
        fixture.Fake.AddResponse(
            "CustomerAddRq",
            """
            <QBXML>
              <QBXMLMsgsRs statusCode="0" statusSeverity="Info" statusMessage="Status OK">
                <CustomerAddRs statusCode="0" statusSeverity="Info" statusMessage="Status OK">
                  <CustomerRet><Name>FAKE</Name></CustomerRet>
                </CustomerAddRs>
              </QBXMLMsgsRs>
            </QBXML>
            """);

        try
        {
            var result = Assert.IsType<Dictionary<string, object?>>(await fixture.Op.RunAsync(EmptyArgs));

            Assert.Equal(0L, Assert.IsType<long>(result["auditSeq"]));
            Assert.Single(fixture.Fake.ProcessRequests);
            Assert.Equal(FakeWriteOp.KnownRequestXml, fixture.Fake.ProcessRequests[0]);

            var row = ReadAuditRows(fixture.AuditDir).Single();
            Assert.Equal(FakeWriteOp.OpName, row["op"]!.GetValue<string>());
            Assert.Equal("0", row["responseStatusCode"]!.GetValue<string>());
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task run_records_the_audit_row_even_when_quickbooks_rejects_the_write()
    {
        var fixture = CreateFixture(allowWrites: true);
        fixture.Fake.AddResponse(
            "CustomerAddRq",
            """
            <QBXML>
              <QBXMLMsgsRs statusCode="3140" statusSeverity="Error" statusMessage="There is an invalid reference.">
                <CustomerAddRs statusCode="3140" statusSeverity="Error" statusMessage="There is an invalid reference." />
              </QBXMLMsgsRs>
            </QBXML>
            """);

        try
        {
            _ = await fixture.Op.RunAsync(EmptyArgs);

            var row = ReadAuditRows(fixture.AuditDir).Single();
            Assert.Equal("3140", row["responseStatusCode"]!.GetValue<string>());
            Assert.Equal("Error", row["responseStatusSeverity"]!.GetValue<string>());
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task run_with_allowwrites_false_throws_and_does_not_execute_or_audit()
    {
        var fixture = CreateFixture(allowWrites: false);
        try
        {
            await Assert.ThrowsAsync<QbWriteForbiddenException>(() => fixture.Op.RunAsync(EmptyArgs));

            Assert.Empty(fixture.Fake.ProcessRequests);
            Assert.False(File.Exists(Path.Combine(fixture.AuditDir, "audit.jsonl")));
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task dryrun_returns_same_qbxml_as_buildrequest_and_does_not_execute_or_audit()
    {
        var fixture = CreateFixture(allowWrites: false);
        try
        {
            var result = await fixture.Op.DryRunAsync(EmptyArgs);

            Assert.Equal(fixture.Op.BuildRequest(EmptyArgs), result.QbXml);
            Assert.False(result.AllowWrites);
            Assert.NotEmpty(result.PreFlight);
            Assert.Empty(fixture.Fake.ProcessRequests);
            Assert.False(File.Exists(Path.Combine(fixture.AuditDir, "audit.jsonl")));
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task run_propagates_a_com_failure_without_auditing()
    {
        var fixture = CreateFixture(allowWrites: true);
        fixture.Fake.EnqueueComError(unchecked((int)0x80040408));

        try
        {
            await Assert.ThrowsAsync<QbException>(() => fixture.Op.RunAsync(EmptyArgs));

            Assert.False(File.Exists(Path.Combine(fixture.AuditDir, "audit.jsonl")));
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    private static readonly IReadOnlyDictionary<string, object?> EmptyArgs =
        new Dictionary<string, object?>(StringComparer.Ordinal);

    private static WriteOpFixture CreateFixture(bool allowWrites)
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

        var op = new FakeWriteOp(
            builder,
            manager,
            parser,
            reportParser,
            listExecutor,
            audit,
            Options.Create(new SafetyOptions { AllowWrites = allowWrites }));

        return new WriteOpFixture(op, manager, fake, auditDir);
    }

    private static IReadOnlyList<JsonObject> ReadAuditRows(string auditDir) =>
        File.ReadAllLines(Path.Combine(auditDir, "audit.jsonl"))
            .Where(line => !string.IsNullOrWhiteSpace(line))
            .Select(line => JsonNode.Parse(line)!.AsObject())
            .ToList();

    private sealed class WriteOpFixture(FakeWriteOp op, QbConnectionManager manager, FakeRequestProcessor fake, string auditDir) : IAsyncDisposable
    {
        public FakeWriteOp Op { get; } = op;
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
