using System.Text.Json.Nodes;
using System.Xml.Linq;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using QbConnectService.Qb;
using QbConnectService.Qb.Ops;
using QbConnectService.Tests.Fakes;

namespace QbConnectService.Tests;

public sealed class CreateJournalEntryOpTests
{
    [Fact]
    public async Task create_journal_entry_dryrun_is_byte_exact_and_only_reads_for_preflight()
    {
        var fixture = CreateFixture(allowWrites: false);
        var args = BalancedArgs();
        fixture.Fake.AddResponses(
            "AccountQueryRq",
            AccountQueryHit("Office Expenses", "80000040-EXP"),
            AccountQueryHit("Checking", "80000030-BANK"));

        try
        {
            var result = await fixture.Op.DryRunAsync(args);

            Assert.Equal(fixture.Op.BuildRequest(args), result.QbXml);
            Assert.Contains(result.PreFlight, check => check.Name == "balanced" && check.Ok);
            Assert.Equal(2, fixture.Fake.ProcessRequests.Count);
            Assert.All(fixture.Fake.ProcessRequests, request => Assert.DoesNotContain("<JournalEntryAddRq>", request, StringComparison.Ordinal));
            Assert.False(File.Exists(Path.Combine(fixture.AuditDir, "audit.jsonl")));

            var add = RequestBody(result.QbXml).Element("JournalEntryAdd")!;
            var debit = add.Element("JournalDebitLine");
            var credit = add.Element("JournalCreditLine");
            Assert.NotNull(debit);
            Assert.NotNull(credit);
            Assert.Equal("Office Expenses", debit!.Element("AccountRef")?.Element("FullName")?.Value);
            Assert.Equal("100.00", debit.Element("Amount")?.Value);
            Assert.Equal("Checking", credit!.Element("AccountRef")?.Element("FullName")?.Value);
            Assert.Equal("100.00", credit.Element("Amount")?.Value);
            Assert.Null(debit.Element("TxnLineID"));
            Assert.Null(credit.Element("TxnLineID"));
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task create_journal_entry_imbalanced_throws_from_buildrequest_and_dryrun_without_sending_qbxml()
    {
        var fixture = CreateFixture(allowWrites: false);
        var args = new Dictionary<string, object?>(StringComparer.Ordinal)
        {
            ["debits"] = new List<object?>
            {
                new Dictionary<string, object?> { ["accountRef"] = "Office Expenses", ["amount"] = "100.00" },
            },
            ["credits"] = new List<object?>
            {
                new Dictionary<string, object?> { ["accountRef"] = "Checking", ["amount"] = "90.00" },
            },
        };

        try
        {
            await Assert.ThrowsAsync<ArgumentException>(() => fixture.Op.DryRunAsync(args));
            Assert.Throws<ArgumentException>(() => fixture.Op.BuildRequest(args));
            Assert.Empty(fixture.Fake.ProcessRequests);
            Assert.False(File.Exists(Path.Combine(fixture.AuditDir, "audit.jsonl")));
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Theory]
    [InlineData("missing-debits")]
    [InlineData("missing-credits")]
    [InlineData("empty-debits")]
    public async Task create_journal_entry_missing_debits_or_credits_throws_argumentexception(string mode)
    {
        var fixture = CreateFixture(allowWrites: false);

        try
        {
            var args = new Dictionary<string, object?>(StringComparer.Ordinal);
            switch (mode)
            {
                case "missing-debits":
                    args["credits"] = new List<object?> { new Dictionary<string, object?> { ["accountRef"] = "Checking", ["amount"] = "100.00" } };
                    break;
                case "missing-credits":
                    args["debits"] = new List<object?> { new Dictionary<string, object?> { ["accountRef"] = "Office Expenses", ["amount"] = "100.00" } };
                    break;
                case "empty-debits":
                    args["debits"] = new List<object?>();
                    args["credits"] = new List<object?> { new Dictionary<string, object?> { ["accountRef"] = "Checking", ["amount"] = "100.00" } };
                    break;
            }

            await Assert.ThrowsAsync<ArgumentException>(() => fixture.Op.DryRunAsync(args));
            Assert.Throws<ArgumentException>(() => fixture.Op.BuildRequest(args));
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task create_journal_entry_missing_line_amount_or_accountref_throws_argumentexception()
    {
        var fixture = CreateFixture(allowWrites: false);

        try
        {
            var missingAmount = new Dictionary<string, object?>(StringComparer.Ordinal)
            {
                ["debits"] = new List<object?> { new Dictionary<string, object?> { ["accountRef"] = "Office Expenses" } },
                ["credits"] = new List<object?> { new Dictionary<string, object?> { ["accountRef"] = "Checking", ["amount"] = "5.00" } },
            };
            await Assert.ThrowsAsync<ArgumentException>(() => fixture.Op.DryRunAsync(missingAmount));
            Assert.Throws<ArgumentException>(() => fixture.Op.BuildRequest(missingAmount));

            var missingAccount = new Dictionary<string, object?>(StringComparer.Ordinal)
            {
                ["debits"] = new List<object?> { new Dictionary<string, object?> { ["amount"] = "5.00" } },
                ["credits"] = new List<object?> { new Dictionary<string, object?> { ["accountRef"] = "Checking", ["amount"] = "5.00" } },
            };
            await Assert.ThrowsAsync<ArgumentException>(() => fixture.Op.DryRunAsync(missingAccount));
            Assert.Throws<ArgumentException>(() => fixture.Op.BuildRequest(missingAccount));
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task create_journal_entry_rejects_currency_ref_from_validate()
    {
        var fixture = CreateFixture(allowWrites: false);
        var args = new Dictionary<string, object?>(BalancedArgs(), StringComparer.Ordinal)
        {
            ["currencyRef"] = "EUR",
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
    public async Task create_journal_entry_execute_happy_path_writes_exactly_one_audit_row()
    {
        var fixture = CreateFixture(allowWrites: true);
        var args = BalancedArgs();
        fixture.Fake.AddResponse("JournalEntryAddRq", Fixture("JournalEntryAddRs.qbxml"));

        try
        {
            var result = Assert.IsType<Dictionary<string, object?>>(await fixture.Op.RunAsync(args));

            Assert.Equal(fixture.Op.BuildRequest(args), fixture.Fake.ProcessRequests.Last());
            var status = Assert.IsType<QbStatus>(result["status"]);
            Assert.Equal("0", status.Code);
            Assert.Single(ReadAuditRows(fixture.AuditDir));
            Assert.Equal("create_journal_entry", ReadAuditRows(fixture.AuditDir)[0]["op"]!.GetValue<string>());
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task create_journal_entry_execute_qb_error_returns_status_and_audits_once()
    {
        var fixture = CreateFixture(allowWrites: true);
        fixture.Fake.AddResponse(
            "JournalEntryAddRq",
            """
            <QBXML>
              <QBXMLMsgsRs statusCode="3140" statusSeverity="Error" statusMessage="There is an invalid reference to QuickBooks Account &quot;Missing&quot;.">
                <JournalEntryAddRs requestID="1" statusCode="3140" statusSeverity="Error" statusMessage="There is an invalid reference to QuickBooks Account &quot;Missing&quot;." />
              </QBXMLMsgsRs>
            </QBXML>
            """);

        try
        {
            var result = Assert.IsType<Dictionary<string, object?>>(await fixture.Op.RunAsync(BalancedArgs()));

            var status = Assert.IsType<QbStatus>(result["status"]);
            Assert.Equal("3140", status.Code);
            Assert.Equal("Error", status.Severity);
            Assert.Single(ReadAuditRows(fixture.AuditDir));
            Assert.Equal("3140", ReadAuditRows(fixture.AuditDir)[0]["responseStatusCode"]!.GetValue<string>());
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    [Fact]
    public async Task create_journal_entry_with_writes_disabled_throws_without_side_effects()
    {
        var fixture = CreateFixture(allowWrites: false);

        try
        {
            await Assert.ThrowsAsync<QbWriteForbiddenException>(() => fixture.Op.RunAsync(BalancedArgs()));
            Assert.Empty(fixture.Fake.ProcessRequests);
            Assert.False(File.Exists(Path.Combine(fixture.AuditDir, "audit.jsonl")));
        }
        finally
        {
            await fixture.DisposeAsync();
        }
    }

    private static IReadOnlyDictionary<string, object?> BalancedArgs()
    {
        return new Dictionary<string, object?>(StringComparer.Ordinal)
        {
            ["txnDate"] = "2026-05-11",
            ["refNumber"] = "JE-001",
            ["debits"] = new List<object?>
            {
                new Dictionary<string, object?>(StringComparer.Ordinal)
                {
                    ["accountRef"] = "Office Expenses",
                    ["amount"] = "100.00",
                },
            },
            ["credits"] = new List<object?>
            {
                new Dictionary<string, object?>(StringComparer.Ordinal)
                {
                    ["accountRef"] = "Checking",
                    ["amount"] = "100.00",
                },
            },
        };
    }

    private static string AccountQueryHit(string fullName, string listId) =>
        $"""
         <QBXML>
           <QBXMLMsgsRs statusCode="0" statusSeverity="Info" statusMessage="Status OK">
             <AccountQueryRs statusCode="0" statusSeverity="Info" statusMessage="Status OK">
               <AccountRet>
                 <ListID>{listId}</ListID>
                 <Name>{fullName}</Name>
                 <FullName>{fullName}</FullName>
               </AccountRet>
             </AccountQueryRs>
           </QBXMLMsgsRs>
         </QBXML>
         """;

    private static string Fixture(string name) =>
        File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "Fixtures", "qbxml", name));

    private static IReadOnlyList<JsonObject> ReadAuditRows(string auditDir) =>
        File.ReadAllLines(Path.Combine(auditDir, "audit.jsonl"))
            .Where(line => !string.IsNullOrWhiteSpace(line))
            .Select(line => JsonNode.Parse(line)!.AsObject())
            .ToList();

    private static XElement RequestBody(string qbXml) =>
        XDocument.Parse(qbXml).Root!.Element("QBXMLMsgsRq")!.Element("JournalEntryAddRq")!;

    private static JournalEntryFixture CreateFixture(bool allowWrites)
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
        var op = new CreateJournalEntryOp(
            builder,
            manager,
            parser,
            reportParser,
            listExecutor,
            audit,
            Options.Create(new SafetyOptions { AllowWrites = allowWrites }));

        return new JournalEntryFixture(op, manager, fake, auditDir);
    }

    private sealed class JournalEntryFixture(CreateJournalEntryOp op, QbConnectionManager manager, FakeRequestProcessor fake, string auditDir) : IAsyncDisposable
    {
        public CreateJournalEntryOp Op { get; } = op;
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
