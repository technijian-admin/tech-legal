using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using QbConnectService.Qb;
using QbConnectService.Tests.Fakes;

namespace QbConnectService.Tests;

public sealed class QbConnectionManagerWriteGuardTests
{
    [Fact]
    public async Task execute_throws_QbWriteForbidden_for_a_write_request_when_writes_disabled()
    {
        var (manager, fake) = CreateManager(allowWrites: false);

        try
        {
            await Assert.ThrowsAsync<QbWriteForbiddenException>(() => manager.ExecuteAsync(WriteRequest));
            Assert.Empty(fake.ProcessRequests);
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }

    [Fact]
    public async Task execute_passes_a_write_request_through_when_writes_enabled()
    {
        var (manager, fake) = CreateManager(allowWrites: true);
        fake.AddResponse("CustomerAddRq", "<QBXML><QBXMLMsgsRs statusCode=\"0\"><CustomerAddRs statusCode=\"0\"/></QBXMLMsgsRs></QBXML>");

        try
        {
            var response = await manager.ExecuteAsync(WriteRequest);

            Assert.Equal("<QBXML><QBXMLMsgsRs statusCode=\"0\"><CustomerAddRs statusCode=\"0\"/></QBXMLMsgsRs></QBXML>", response);
            Assert.Single(fake.ProcessRequests);
            Assert.Equal(WriteRequest, fake.ProcessRequests[0]);
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }

    [Fact]
    public async Task execute_passes_a_read_request_through_when_writes_disabled()
    {
        var (manager, fake) = CreateManager(allowWrites: false);
        fake.AddResponse("CompanyQueryRq", "<QBXML><QBXMLMsgsRs statusCode=\"0\"><CompanyQueryRs statusCode=\"0\"/></QBXMLMsgsRs></QBXML>");

        try
        {
            var response = await manager.ExecuteAsync(ReadRequest);

            Assert.Equal("<QBXML><QBXMLMsgsRs statusCode=\"0\"><CompanyQueryRs statusCode=\"0\"/></QBXMLMsgsRs></QBXML>", response);
            Assert.Single(fake.ProcessRequests);
            Assert.Equal(ReadRequest, fake.ProcessRequests[0]);
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }

    private static (QbConnectionManager Manager, FakeRequestProcessor Fake) CreateManager(bool allowWrites)
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
            Options.Create(new SafetyOptions { AllowWrites = allowWrites }),
            new FakeQbProcessManager(),
            new QbKillTracker());

        return (manager, fake);
    }

    private const string WriteRequest =
        "<?xml version=\"1.0\"?><?qbxml version=\"16.0\"?><QBXML><QBXMLMsgsRq onError=\"stopOnError\"><CustomerAddRq/></QBXMLMsgsRq></QBXML>";

    private const string ReadRequest =
        "<?xml version=\"1.0\"?><?qbxml version=\"16.0\"?><QBXML><QBXMLMsgsRq onError=\"stopOnError\"><CompanyQueryRq/></QBXMLMsgsRq></QBXML>";
}
