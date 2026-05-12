using System.Xml.Linq;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using QbConnectService.Qb;
using QbConnectService.Tests.Fakes;

namespace QbConnectService.Tests;

public sealed class QbListExecutorTests
{
    [Fact]
    public async Task RunAsync_returns_a_single_page_result_without_spilling()
    {
        var setup = CreateExecutor();
        setup.Fake.AddResponses("CustomerQueryRq", Fixture("CustomerQueryRs.page2.qbxml"));

        try
        {
            var result = await setup.Executor.RunAsync(QbXmlBuilder.Rq("CustomerQueryRq"));

            Assert.Single(result.First.Rows);
            Assert.Equal("Globex", result.First.Rows[0]["Name"]);
            Assert.Equal(0, result.First.IteratorRemaining);
            Assert.Null(result.RawSpilledTo);
            Assert.Single(setup.Fake.ProcessRequests);
            Assert.Contains("iterator=\"Start\"", setup.Fake.ProcessRequests[0]);
        }
        finally
        {
            await setup.Manager.DisposeAsync();
        }
    }

    [Fact]
    public async Task RunAsync_accumulates_rows_across_iterator_pages()
    {
        var setup = CreateExecutor();
        setup.Fake.AddResponses("CustomerQueryRq", Fixture("CustomerQueryRs.page1.qbxml"), Fixture("CustomerQueryRs.page2.qbxml"));

        try
        {
            var result = await setup.Executor.RunAsync(QbXmlBuilder.Rq("CustomerQueryRq"));

            Assert.Equal(2, result.First.Rows.Count);
            Assert.Equal(["Acme Roofing", "Globex"], result.First.Rows.Select(row => (string)row["Name"]!).ToArray());
            Assert.Equal(0, result.First.IteratorRemaining);
            Assert.Null(result.RawSpilledTo);
            Assert.Equal(2, setup.Fake.ProcessRequests.Count);

            var startRequest = RequestElement(setup.Fake.ProcessRequests[0]);
            var continueRequest = RequestElement(setup.Fake.ProcessRequests[1]);

            Assert.Equal("Start", startRequest.Attribute("iterator")?.Value);
            Assert.Equal("1", startRequest.Attribute("requestID")?.Value);
            Assert.Equal("1", startRequest.Element("MaxReturned")?.Value);
            Assert.Equal("Continue", continueRequest.Attribute("iterator")?.Value);
            Assert.Equal("{eb05f701-e727-472f-8ade-6753c4f67a46}", continueRequest.Attribute("iteratorID")?.Value);
            Assert.Equal("1", continueRequest.Attribute("requestID")?.Value);
        }
        finally
        {
            await setup.Manager.DisposeAsync();
        }
    }

    [Fact]
    public async Task RunAsync_spills_large_concatenated_responses_after_parsing()
    {
        var spillDirectory = Path.Combine(Path.GetTempPath(), "qbspill-" + Guid.NewGuid().ToString("N"));
        var setup = CreateExecutor(new QbXmlOptions
        {
            MaxReturned = 1,
            MaxResponseBytes = 100,
            SpillPath = spillDirectory,
        });
        var bigRaw = """
                     <?xml version="1.0" encoding="utf-8"?>
                     <QBXML>
                       <QBXMLMsgsRs>
                         <CustomerQueryRs requestID="1" statusCode="0" statusSeverity="Info" statusMessage="Status OK" iteratorRemainingCount="0">
                           <CustomerRet>
                             <ListID>80000001-1</ListID>
                             <Name>Oversized Row</Name>
                             <Notes>
                     """ + new string('x', 5000) + """
                             </Notes>
                           </CustomerRet>
                         </CustomerQueryRs>
                       </QBXMLMsgsRs>
                     </QBXML>
                     """;
        setup.Fake.AddResponses("CustomerQueryRq", bigRaw);

        try
        {
            var result = await setup.Executor.RunAsync(QbXmlBuilder.Rq("CustomerQueryRq"));

            Assert.NotNull(result.RawSpilledTo);
            Assert.True(File.Exists(result.RawSpilledTo));
            Assert.Equal(bigRaw, await File.ReadAllTextAsync(result.RawSpilledTo!));
            Assert.Single(result.First.Rows);
        }
        finally
        {
            await setup.Manager.DisposeAsync();
            DeleteDirectory(spillDirectory);
        }
    }

    [Fact]
    public async Task RunAsync_aborts_on_mid_iteration_errors_and_keeps_prior_rows()
    {
        var setup = CreateExecutor();
        const string page2Error = """
                                  <QBXML>
                                    <QBXMLMsgsRs>
                                      <CustomerQueryRs requestID="1" statusCode="3200" statusSeverity="Error" statusMessage="Boom on continue" iteratorID="{eb05f701-e727-472f-8ade-6753c4f67a46}" />
                                    </QBXMLMsgsRs>
                                  </QBXML>
                                  """;
        setup.Fake.AddResponses("CustomerQueryRq", Fixture("CustomerQueryRs.page1.qbxml"), page2Error);

        try
        {
            var result = await setup.Executor.RunAsync(QbXmlBuilder.Rq("CustomerQueryRq"));

            Assert.True(result.First.Status.IsError);
            Assert.Equal("3200", result.First.Status.Code);
            Assert.Single(result.First.Rows);
            Assert.Equal(2, setup.Fake.ProcessRequests.Count);
        }
        finally
        {
            await setup.Manager.DisposeAsync();
        }
    }

    [Fact]
    public async Task RunAsync_does_not_mutate_the_callers_request_element()
    {
        var setup = CreateExecutor();
        var request = QbXmlBuilder.Rq("CustomerQueryRq");
        setup.Fake.AddResponses("CustomerQueryRq", Fixture("CustomerQueryRs.page2.qbxml"));

        try
        {
            await setup.Executor.RunAsync(request);

            Assert.Null(request.Attribute("iterator"));
            Assert.Null(request.Element("MaxReturned"));
        }
        finally
        {
            await setup.Manager.DisposeAsync();
        }
    }

    private static (FakeRequestProcessor Fake, QbConnectionManager Manager, QbListExecutor Executor) CreateExecutor(
        QbXmlOptions? options = null,
        IConfiguration? configuration = null)
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
            NullLogger<QbConnectionManager>.Instance,
            Options.Create(new SafetyOptions
            {
                AllowWrites = true,
            }));
        var xmlOptions = Options.Create(options ?? new QbXmlOptions
        {
            MaxReturned = 1,
            MaxResponseBytes = 5_000_000,
        });
        var builder = new QbXmlBuilder(xmlOptions);
        var parser = new QbXmlParser();
        var spiller = new QbResponseSpiller(
            xmlOptions,
            configuration ?? new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>()).Build());
        var executor = new QbListExecutor(
            manager,
            builder,
            parser,
            spiller,
            xmlOptions,
            NullLogger<QbListExecutor>.Instance);

        return (fake, manager, executor);
    }

    private static XElement RequestElement(string rawRequest) =>
        XDocument.Parse(rawRequest).Root!.Element("QBXMLMsgsRq")!.Element("CustomerQueryRq")!;

    private static string Fixture(string name) => File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "Fixtures", "qbxml", name));

    private static void DeleteDirectory(string path)
    {
        if (Directory.Exists(path))
        {
            Directory.Delete(path, recursive: true);
        }
    }
}
