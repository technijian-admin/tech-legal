using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using QbConnectService.Qb;
using QbConnectService.Tests.Fakes;

namespace QbConnectService.Tests;

public sealed class QbConnectionManagerTests
{
    private const string CompanyQueryRequest =
        "<?xml version=\"1.0\"?><?qbxml version=\"16.0\"?><QBXML><QBXMLMsgsRq onError=\"stopOnError\"><CompanyQueryRq/></QBXMLMsgsRq></QBXML>";

    [Fact]
    public async Task First_execute_opens_a_connection_begins_a_session_and_processes_the_request()
    {
        var (manager, created) = CreateManager();
        created[0].AddResponse("CompanyQueryRq", "<company/>");

        var response = await manager.ExecuteAsync(CompanyQueryRequest);

        Assert.Equal("<company/>", response);
        Assert.Equal(
            [nameof(IRequestProcessor.SetUnattendedModePreference), nameof(IRequestProcessor.OpenConnection), nameof(IRequestProcessor.BeginSession), nameof(IRequestProcessor.ProcessRequest)],
            created[0].CallLog);

        await manager.DisposeAsync();
    }

    [Fact]
    public async Task Connection_uses_the_required_connection_type_and_open_mode()
    {
        var (manager, created) = CreateManager();
        created[0].AddResponse("CompanyQueryRq", "<company/>");

        await manager.ExecuteAsync(CompanyQueryRequest);

        Assert.Equal(QbConnectionType.LocalQBD, created[0].LastConnectionType);
        Assert.Equal(QbFileMode.DoNotCare, created[0].LastOpenMode);
        Assert.Equal(@"C:\co.QBW", created[0].LastCompanyFilePath);
        Assert.Equal("app", created[0].LastAppId);
        Assert.Equal("QbConnectService", created[0].LastAppName);
        Assert.True(created[0].UnattendedModePreference);

        await manager.DisposeAsync();
    }

    [Fact]
    public async Task Second_execute_reuses_the_existing_session()
    {
        var (manager, created) = CreateManager();
        created[0]
            .AddResponse("CompanyQueryRq", "<first/>")
            .AddResponse("*", "<fallback/>");

        var first = await manager.ExecuteAsync(CompanyQueryRequest);
        var second = await manager.ExecuteAsync(CompanyQueryRequest);

        Assert.Equal("<first/>", first);
        Assert.Equal("<first/>", second);
        Assert.Single(created);
        Assert.Equal(1, created[0].CallLog.Count(entry => entry == nameof(IRequestProcessor.OpenConnection)));
        Assert.Equal(1, created[0].CallLog.Count(entry => entry == nameof(IRequestProcessor.BeginSession)));
        Assert.Equal(2, created[0].CallLog.Count(entry => entry == nameof(IRequestProcessor.ProcessRequest)));

        await manager.DisposeAsync();
    }

    [Fact]
    public async Task DisposeAsync_closes_the_session_connection_and_adapter_in_order()
    {
        var (manager, created) = CreateManager();
        created[0].AddResponse("CompanyQueryRq", "<company/>");

        await manager.ExecuteAsync(CompanyQueryRequest);
        await manager.DisposeAsync();

        Assert.Equal(
            [nameof(IRequestProcessor.EndSession), nameof(IRequestProcessor.CloseConnection), nameof(IDisposable.Dispose)],
            created[0].CallLog[^3..]);
    }

    [Fact]
    public async Task GetSupportedQbXmlVersions_returns_the_fake_versions()
    {
        var (manager, created) = CreateManager();
        created[0].SupportedQbXmlVersions = ["13.0", "16.0"];

        var versions = await manager.GetSupportedQbXmlVersionsAsync();

        Assert.Equal(["13.0", "16.0"], versions);
        Assert.Equal(
            [nameof(IRequestProcessor.SetUnattendedModePreference), nameof(IRequestProcessor.OpenConnection), nameof(IRequestProcessor.BeginSession), nameof(IRequestProcessor.GetSupportedQbXmlVersions)],
            created[0].CallLog);

        await manager.DisposeAsync();
    }

    [Fact]
    public async Task Concurrent_execute_calls_do_not_interleave_ProcessRequest()
    {
        var (manager, created) = CreateManager();
        var inside = 0;
        var reentered = false;
        var calls = 0;
        created[0].ProcessRequestHook = _ =>
        {
            if (Interlocked.Exchange(ref inside, 1) == 1)
            {
                reentered = true;
            }

            try
            {
                Thread.Sleep(150);
                Interlocked.Increment(ref calls);
                return "<ok/>";
            }
            finally
            {
                Interlocked.Exchange(ref inside, 0);
            }
        };

        var first = Task.Run(() => manager.ExecuteAsync(CompanyQueryRequest));
        var second = Task.Run(() => manager.ExecuteAsync(CompanyQueryRequest));
        var results = await Task.WhenAll(first, second);

        Assert.False(reentered);
        Assert.Equal(2, calls);
        Assert.All(results, result => Assert.Equal("<ok/>", result));

        await manager.DisposeAsync();
    }

    [Fact]
    public async Task ExecuteAsync_throws_QbBusyException_when_the_gate_stays_held_past_the_wait_window()
    {
        var (manager, created) = CreateManager(new RequestOptions
        {
            BusyWaitSeconds = 1,
            TimeoutSeconds = 60,
        });
        using var entered = new ManualResetEventSlim();
        using var release = new ManualResetEventSlim();
        created[0].ProcessRequestHook = _ =>
        {
            entered.Set();
            release.Wait();
            return "<ok/>";
        };

        var first = Task.Run(() => manager.ExecuteAsync(CompanyQueryRequest));
        Assert.True(entered.Wait(TimeSpan.FromSeconds(5)));

        var exception = await Assert.ThrowsAsync<QbBusyException>(() => manager.ExecuteAsync(CompanyQueryRequest));

        Assert.Equal(TimeSpan.FromSeconds(1), exception.WaitedFor);

        release.Set();
        Assert.Equal("<ok/>", await first);

        await manager.DisposeAsync();
    }

    private static (QbConnectionManager Manager, List<FakeRequestProcessor> Created) CreateManager(RequestOptions? request = null)
    {
        var created = new List<FakeRequestProcessor> { new FakeRequestProcessor() };
        var nextIndex = 0;

        IRequestProcessor Factory()
        {
            if (nextIndex >= created.Count)
            {
                created.Add(new FakeRequestProcessor());
            }

            return created[nextIndex++];
        }

        var manager = new QbConnectionManager(
            Factory,
            Options.Create(new QbOptions
            {
                AppId = "app",
                AppName = "QbConnectService",
                CompanyFilePath = @"C:\co.QBW",
            }),
            Options.Create(request ?? new RequestOptions
            {
                TimeoutSeconds = 30,
                BusyWaitSeconds = 5,
            }),
            NullLogger<QbConnectionManager>.Instance);

        return (manager, created);
    }
}
