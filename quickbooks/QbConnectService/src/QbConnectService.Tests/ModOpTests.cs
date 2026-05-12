using System.Text.Json.Nodes;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using QbConnectService.Qb;
using QbConnectService.Qb.Ops;
using QbConnectService.Tests.Fakes;

namespace QbConnectService.Tests;

public sealed class ModOpTests
{
    [Fact]
    public async Task mod_customer_dryrun_reads_merges_and_builds_without_writing_or_auditing()
    {
        var fixture = CreateFixture(allowWrites: false);
        fixture.Fake.AddResponse("CustomerQueryRq", Fixture("CustomerQueryRs.formod.qbxml"));

        try
        {
            var result = await fixture.Op.DryRunAsync(CustomerModArgs());

            Assert.Contains("<CustomerModRq>", result.QbXml, StringComparison.Ordinal);
            Assert.Contains("<ListID>80000001-AAAAAAAA</ListID>", result.QbXml, StringComparison.Ordinal);
            Assert.Contains("<EditSequence>1700000123</EditSequence>", result.QbXml, StringComparison.Ordinal);
            Assert.Contains("<CompanyName>Acme Company NEW</CompanyName>", result.QbXml, StringComparison.Ordinal);
            Assert.DoesNotContain("<TimeCreated>", result.QbXml, StringComparison.Ordinal);
            Assert.DoesNotContain("<TimeModified>", result.QbXml, StringComparison.Ordinal);
            Assert.DoesNotContain("<Balance>", result.QbXml, StringComparison.Ordinal);
            Assert.DoesNotContain("<TotalBalance>", result.QbXml, StringComparison.Ordinal);
            Assert.DoesNotContain("<FullName>", result.QbXml, StringComparison.Ordinal);
            Assert.Contains(result.PreFlight, check => check.Name == "target-resolves" && check.Ok);
            Assert.Contains(result.PreFlight, check => check.Name == "edit-sequence-fresh" && check.Detail == "1700000123");
            Assert.Contains(result.PreFlight, check => check.Name == "customer-fields" && check.Detail!.Contains("CompanyName", StringComparison.Ordinal));
            Assert.Equal("1700000123", result.ResolvedReferences["editSequence"]);
            Assert.Single(fixture.Fake.ProcessRequests);
            Assert.DoesNotContain("<CustomerModRq>", fixture.Fake.ProcessRequests[0], StringComparison.Ordinal);
            Assert.False(File.Exists(Path.Combine(fixture.AuditDir, "audit.jsonl")));
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task mod_customer_execute_happy_path_reads_once_writes_once_and_audits_once()
    {
        var fixture = CreateFixture(allowWrites: true);
        fixture.Fake.AddResponses("CustomerQueryRq", Fixture("CustomerQueryRs.formod.qbxml"));
        fixture.Fake.AddResponse("CustomerModRq", Fixture("CustomerModRs.qbxml"));

        try
        {
            var result = Assert.IsType<Dictionary<string, object?>>(await fixture.Op.RunAsync(CustomerModArgs()));

            Assert.Equal(2, fixture.Fake.ProcessRequests.Count);
            Assert.Contains("<CustomerQueryRq>", fixture.Fake.ProcessRequests[0], StringComparison.Ordinal);
            Assert.Contains("<CustomerModRq>", fixture.Fake.ProcessRequests[1], StringComparison.Ordinal);
            Assert.Contains("<EditSequence>1700000123</EditSequence>", fixture.Fake.ProcessRequests[1], StringComparison.Ordinal);
            Assert.Contains("<CompanyName>Acme Company NEW</CompanyName>", fixture.Fake.ProcessRequests[1], StringComparison.Ordinal);
            Assert.DoesNotContain("<TimeCreated>", fixture.Fake.ProcessRequests[1], StringComparison.Ordinal);

            var status = Assert.IsType<QbStatus>(result["status"]);
            Assert.Equal("0", status.Code);
            var auditRows = ReadAuditRows(fixture.AuditDir);
            Assert.Single(auditRows);
            Assert.Equal("mod", auditRows[0]["op"]!.GetValue<string>());
            Assert.Equal("0", auditRows[0]["responseStatusCode"]!.GetValue<string>());
            Assert.Equal("Info", auditRows[0]["responseStatusSeverity"]!.GetValue<string>());
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task mod_invoice_stale_editsequence_returns_verbatim_status_audits_once_and_never_retries()
    {
        var fixture = CreateFixture(allowWrites: true);
        fixture.Fake.AddResponses("InvoiceQueryRq", Fixture("InvoiceQueryRs.formod.qbxml"));
        fixture.Fake.AddResponse("InvoiceModRq", Fixture("InvoiceModRs.stale.qbxml"));
        var args = new Dictionary<string, object?>(StringComparer.Ordinal)
        {
            ["entity"] = "invoice",
            ["ref"] = new Dictionary<string, object?>(StringComparer.Ordinal) { ["txnID"] = "1A2B-3C4D5E6F7G" },
            ["fields"] = new Dictionary<string, object?>(StringComparer.Ordinal) { ["memo"] = "updated memo" },
        };

        try
        {
            var result = Assert.IsType<Dictionary<string, object?>>(await fixture.Op.RunAsync(args));

            var status = Assert.IsType<QbStatus>(result["status"]);
            Assert.Equal("3200", status.Code);
            Assert.Equal("Error", status.Severity);
            Assert.Equal(2, fixture.Fake.ProcessRequests.Count);
            Assert.Contains("<InvoiceQueryRq>", fixture.Fake.ProcessRequests[0], StringComparison.Ordinal);
            Assert.Contains("<InvoiceModRq>", fixture.Fake.ProcessRequests[1], StringComparison.Ordinal);
            var auditRows = ReadAuditRows(fixture.AuditDir);
            Assert.Single(auditRows);
            Assert.Equal("3200", auditRows[0]["responseStatusCode"]!.GetValue<string>());
            Assert.Equal("Error", auditRows[0]["responseStatusSeverity"]!.GetValue<string>());
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task mod_bad_entity_throws_argumentexception_without_side_effects()
    {
        var fixture = CreateFixture(allowWrites: true);
        var args = new Dictionary<string, object?>(StringComparer.Ordinal)
        {
            ["entity"] = "item",
            ["ref"] = new Dictionary<string, object?>(StringComparer.Ordinal) { ["listID"] = "X" },
            ["fields"] = new Dictionary<string, object?>(StringComparer.Ordinal),
        };

        try
        {
            await Assert.ThrowsAsync<ArgumentException>(() => fixture.Op.DryRunAsync(args));
            await Assert.ThrowsAsync<ArgumentException>(() => fixture.Op.RunAsync(args));
            Assert.Empty(fixture.Fake.ProcessRequests);
            Assert.False(File.Exists(Path.Combine(fixture.AuditDir, "audit.jsonl")));
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task mod_bad_ref_shapes_throw_argumentexception()
    {
        var fixture = CreateFixture(allowWrites: true);

        try
        {
            var missingRef = new Dictionary<string, object?>(StringComparer.Ordinal)
            {
                ["entity"] = "customer",
                ["ref"] = new Dictionary<string, object?>(StringComparer.Ordinal),
                ["fields"] = new Dictionary<string, object?>(StringComparer.Ordinal),
            };
            await Assert.ThrowsAsync<ArgumentException>(() => fixture.Op.DryRunAsync(missingRef));

            var duplicateRef = new Dictionary<string, object?>(StringComparer.Ordinal)
            {
                ["entity"] = "customer",
                ["ref"] = new Dictionary<string, object?>(StringComparer.Ordinal) { ["listID"] = "X", ["fullName"] = "Y" },
                ["fields"] = new Dictionary<string, object?>(StringComparer.Ordinal),
            };
            await Assert.ThrowsAsync<ArgumentException>(() => fixture.Op.DryRunAsync(duplicateRef));
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task mod_fullname_ref_on_transaction_throws_argumentexception()
    {
        var fixture = CreateFixture(allowWrites: true);
        var args = new Dictionary<string, object?>(StringComparer.Ordinal)
        {
            ["entity"] = "invoice",
            ["ref"] = new Dictionary<string, object?>(StringComparer.Ordinal) { ["fullName"] = "INV-1001" },
            ["fields"] = new Dictionary<string, object?>(StringComparer.Ordinal),
        };

        try
        {
            await Assert.ThrowsAsync<ArgumentException>(() => fixture.Op.DryRunAsync(args));
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task mod_line_touching_fields_throw_argumentexception()
    {
        var fixture = CreateFixture(allowWrites: true);
        var args = new Dictionary<string, object?>(StringComparer.Ordinal)
        {
            ["entity"] = "invoice",
            ["ref"] = new Dictionary<string, object?>(StringComparer.Ordinal) { ["txnID"] = "X" },
            ["fields"] = new Dictionary<string, object?>(StringComparer.Ordinal) { ["lines"] = new List<object?>() },
        };

        try
        {
            await Assert.ThrowsAsync<ArgumentException>(() => fixture.Op.DryRunAsync(args));
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task mod_target_not_found_throws_before_writing_or_auditing()
    {
        var dryRunFixture = CreateFixture(allowWrites: false);
        var executeFixture = CreateFixture(allowWrites: true);
        dryRunFixture.Fake.AddResponse("CustomerQueryRq", Fixture("CustomerQueryRs.zerorows.qbxml"));
        executeFixture.Fake.AddResponse("CustomerQueryRq", Fixture("CustomerQueryRs.zerorows.qbxml"));

        try
        {
            await Assert.ThrowsAsync<ArgumentException>(() => dryRunFixture.Op.DryRunAsync(CustomerModArgs()));
            await Assert.ThrowsAsync<ArgumentException>(() => executeFixture.Op.RunAsync(CustomerModArgs()));
            Assert.Single(dryRunFixture.Fake.ProcessRequests);
            Assert.Single(executeFixture.Fake.ProcessRequests);
            Assert.DoesNotContain("<CustomerModRq>", dryRunFixture.Fake.ProcessRequests[0], StringComparison.Ordinal);
            Assert.DoesNotContain("<CustomerModRq>", executeFixture.Fake.ProcessRequests[0], StringComparison.Ordinal);
            Assert.False(File.Exists(Path.Combine(dryRunFixture.AuditDir, "audit.jsonl")));
            Assert.False(File.Exists(Path.Combine(executeFixture.AuditDir, "audit.jsonl")));
        }
        finally
        {
            await dryRunFixture.DisposeAsync();
            await executeFixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task mod_with_writes_disabled_throws_before_reading()
    {
        var fixture = CreateFixture(allowWrites: false);

        try
        {
            await Assert.ThrowsAsync<QbWriteForbiddenException>(() => fixture.Op.RunAsync(CustomerModArgs()));
            Assert.Empty(fixture.Fake.ProcessRequests);
            Assert.False(File.Exists(Path.Combine(fixture.AuditDir, "audit.jsonl")));
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task mod_buildrequest_requires_preresolved_record()
    {
        var fixture = CreateFixture(allowWrites: true);

        try
        {
            Assert.Throws<InvalidOperationException>(() => fixture.Op.BuildRequest(CustomerModArgs()));
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    private static IReadOnlyDictionary<string, object?> CustomerModArgs()
    {
        return new Dictionary<string, object?>(StringComparer.Ordinal)
        {
            ["entity"] = "customer",
            ["ref"] = new Dictionary<string, object?>(StringComparer.Ordinal) { ["listID"] = "80000001-AAAAAAAA" },
            ["fields"] = new Dictionary<string, object?>(StringComparer.Ordinal) { ["companyName"] = "Acme Company NEW" },
        };
    }

    private static string Fixture(string name) =>
        File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "Fixtures", "qbxml", name));

    private static IReadOnlyList<JsonObject> ReadAuditRows(string auditDir) =>
        File.ReadAllLines(Path.Combine(auditDir, "audit.jsonl"))
            .Where(line => !string.IsNullOrWhiteSpace(line))
            .Select(line => JsonNode.Parse(line)!.AsObject())
            .ToList();

    private static ModFixture CreateFixture(bool allowWrites)
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
        var op = new ModOp(
            builder,
            manager,
            parser,
            reportParser,
            listExecutor,
            audit,
            Options.Create(new SafetyOptions { AllowWrites = allowWrites }));

        return new ModFixture(op, manager, fake, auditDir);
    }

    private sealed class ModFixture(ModOp op, QbConnectionManager manager, FakeRequestProcessor fake, string auditDir) : IAsyncDisposable
    {
        public ModOp Op { get; } = op;
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
