using System.Diagnostics;
using System.Runtime.InteropServices;
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

    [Fact]
    public async Task Dead_ticket_error_rebuilds_the_connection_and_retries_once()
    {
        var (manager, created) = CreateManager();
        created.Add(new FakeRequestProcessor().AddResponse("CompanyQueryRq", "<canned/>"));
        created[0].ProcessRequestHook = _ => throw new COMException("invalid ticket", unchecked((int)0x8004040D));

        var response = await manager.ExecuteAsync(CompanyQueryRequest);

        Assert.Equal("<canned/>", response);
        Assert.Equal(2, created.Count);
        Assert.Equal(
            [
                nameof(IRequestProcessor.SetUnattendedModePreference),
                nameof(IRequestProcessor.OpenConnection),
                nameof(IRequestProcessor.BeginSession),
                nameof(IRequestProcessor.ProcessRequest),
                nameof(IRequestProcessor.EndSession),
                nameof(IRequestProcessor.CloseConnection),
                nameof(IDisposable.Dispose),
            ],
            created[0].CallLog);
        Assert.Equal(
            [
                nameof(IRequestProcessor.SetUnattendedModePreference),
                nameof(IRequestProcessor.OpenConnection),
                nameof(IRequestProcessor.BeginSession),
                nameof(IRequestProcessor.ProcessRequest),
            ],
            created[1].CallLog);

        await manager.DisposeAsync();
    }

    [Fact]
    public async Task Second_dead_ticket_failure_surfaces_verbatim_without_a_third_attempt()
    {
        var (manager, created) = CreateManager();
        created.Add(new FakeRequestProcessor
        {
            ProcessRequestHook = _ => throw new COMException("invalid ticket", unchecked((int)0x8004040D)),
        });
        created[0].ProcessRequestHook = _ => throw new COMException("invalid ticket", unchecked((int)0x8004040D));

        var exception = await Assert.ThrowsAsync<QbException>(() => manager.ExecuteAsync(CompanyQueryRequest));

        Assert.Equal("QB_INVALID_TICKET", exception.Error.Name);
        Assert.Equal("QB_INVALID_TICKET", manager.LastError?.Name);
        Assert.Equal(2, created.Count);
        Assert.Equal(2, created.Sum(fake => fake.CallLog.Count(entry => entry == nameof(IRequestProcessor.ProcessRequest))));

        await manager.DisposeAsync();
    }

    [Fact]
    public async Task Non_dead_ticket_com_error_surfaces_immediately_without_rebuild()
    {
        var (manager, created) = CreateManager();
        created[0].ProcessRequestHook = _ => throw new COMException("could not start", unchecked((int)0x80040408));

        var exception = await Assert.ThrowsAsync<QbException>(() => manager.ExecuteAsync(CompanyQueryRequest));

        Assert.Equal("QB_COULD_NOT_START", exception.Error.Name);
        Assert.Equal("QB_COULD_NOT_START", manager.LastError?.Name);
        Assert.Single(created);
        Assert.Equal(1, created[0].CallLog.Count(entry => entry == nameof(IRequestProcessor.ProcessRequest)));

        await manager.DisposeAsync();
    }

    [Fact]
    public async Task Watchdog_timeout_poison_the_session_and_the_next_request_rebuilds_cleanly()
    {
        var (manager, created) = CreateManager(new RequestOptions
        {
            TimeoutSeconds = 1,
            BusyWaitSeconds = 60,
        });
        created.Add(new FakeRequestProcessor().AddResponse("CompanyQueryRq", "<ok/>"));
        created[0].ProcessRequestHook = _ =>
        {
            Thread.Sleep(5000);
            return "<late/>";
        };

        var stopwatch = Stopwatch.StartNew();
        await Assert.ThrowsAsync<QbTimeoutException>(() => manager.ExecuteAsync(CompanyQueryRequest));
        stopwatch.Stop();

        Assert.InRange(stopwatch.Elapsed, TimeSpan.Zero, TimeSpan.FromSeconds(3));
        Assert.Equal(QbConnectionState.Poisoned, manager.State);

        var response = await manager.ExecuteAsync(CompanyQueryRequest);

        Assert.Equal("<ok/>", response);
        Assert.Equal(QbConnectionState.SessionOpen, manager.State);
        Assert.Equal(
            [
                nameof(IRequestProcessor.SetUnattendedModePreference),
                nameof(IRequestProcessor.OpenConnection),
                nameof(IRequestProcessor.BeginSession),
                nameof(IRequestProcessor.ProcessRequest),
            ],
            created[1].CallLog);

        await manager.DisposeAsync();
    }

    private static (QbConnectionManager Manager, List<FakeRequestProcessor> Created) CreateManager(
        RequestOptions? request = null,
        bool releaseAfterEachRequest = false,
        FakeQbProcessManager? qbProcess = null,
        QbKillTracker? kills = null,
        bool autoRecover = true,
        bool abortRecoveryIfInteractive = true,
        int maxKillsPerMinute = 3)
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
                // Existing tests assume the persistent-session optimization, so default to false here
                // even though the production default is true. Tests that exercise the auto-release
                // behavior pass `releaseAfterEachRequest: true` explicitly.
                ReleaseAfterEachRequest = releaseAfterEachRequest,
                AutoRecoverFromQbwStuck = autoRecover,
                AbortRecoveryIfInteractiveQbDesktop = abortRecoveryIfInteractive,
                MaxQbwKillsPerMinute = maxKillsPerMinute,
                QbwKillExitTimeoutSeconds = 1, // tests are in-memory; no need to wait
            }),
            Options.Create(request ?? new RequestOptions
            {
                TimeoutSeconds = 30,
                BusyWaitSeconds = 5,
            }),
            NullLogger<QbConnectionManager>.Instance,
            Options.Create(new SafetyOptions
            {
                AllowWrites = true,
            }),
            qbProcess ?? new FakeQbProcessManager(),
            kills ?? new QbKillTracker());

        return (manager, created);
    }

    // ---------- AutoRecoverFromQbwStuck tests ----------

    private static readonly int HresultDifferentFileOpen = unchecked((int)0x8004040A);

    [Theory]
    [InlineData(0x8004040A)] // QB_DIFFERENT_FILE_OPEN
    [InlineData(0x80040414)] // QB_MODAL_DIALOG
    [InlineData(0x80010105)] // RPC_E_SERVERFAULT
    public async Task Recovery_kills_qbw_and_retries_once_on_recoverable_error(uint hresult)
    {
        var qbProcess = new FakeQbProcessManager { Count = 1, AnyInteractive = false };
        var (manager, created) = CreateManager(qbProcess: qbProcess);

        // First RP: scripted to throw the recoverable error on the very first SDK call.
        created[0].EnqueueComError(unchecked((int)hresult), "scripted");
        // Pre-add a second RP that will serve the retry successfully.
        var retryRp = new FakeRequestProcessor().AddResponse("CompanyQueryRq", "<recovered/>");
        created.Add(retryRp);

        var response = await manager.ExecuteAsync(CompanyQueryRequest);

        Assert.Equal("<recovered/>", response);
        Assert.Equal(1, qbProcess.KillCalls);
        Assert.Equal(0, qbProcess.Count); // FakeQbProcessManager zeroes Count on kill
        Assert.Equal(2, created.Count);   // factory was called twice (once for first try, once for retry)

        await manager.DisposeAsync();
    }

    [Fact]
    public async Task Recovery_refused_when_interactive_QbDesktop_session_visible()
    {
        var qbProcess = new FakeQbProcessManager { Count = 1, AnyInteractive = true };
        var (manager, created) = CreateManager(qbProcess: qbProcess);
        created[0].EnqueueComError(HresultDifferentFileOpen, "scripted");

        var ex = await Assert.ThrowsAsync<QbException>(() => manager.ExecuteAsync(CompanyQueryRequest));

        Assert.Equal(HresultDifferentFileOpen, ex.Error.Code);
        Assert.Contains("interactive", ex.Error.Message, StringComparison.OrdinalIgnoreCase);
        Assert.Equal(0, qbProcess.KillCalls); // refused, no kill happened

        await manager.DisposeAsync();
    }

    [Fact]
    public async Task Recovery_refused_when_kill_rate_ceiling_hit()
    {
        var qbProcess = new FakeQbProcessManager { Count = 1 };
        var killTracker = new QbKillTracker();
        killTracker.RecordKill();
        killTracker.RecordKill();
        killTracker.RecordKill();
        Assert.Equal(3, killTracker.RecentKills);

        var (manager, created) = CreateManager(qbProcess: qbProcess, kills: killTracker, maxKillsPerMinute: 3);
        created[0].EnqueueComError(HresultDifferentFileOpen, "scripted");

        var ex = await Assert.ThrowsAsync<QbException>(() => manager.ExecuteAsync(CompanyQueryRequest));

        Assert.Equal(HresultDifferentFileOpen, ex.Error.Code);
        Assert.Contains("circuit-broken", ex.Error.Message, StringComparison.OrdinalIgnoreCase);
        Assert.Equal(0, qbProcess.KillCalls); // ceiling hit, no kill

        await manager.DisposeAsync();
    }

    [Fact]
    public async Task Recovery_disabled_when_AutoRecoverFromQbwStuck_is_false()
    {
        var qbProcess = new FakeQbProcessManager { Count = 1 };
        var (manager, created) = CreateManager(qbProcess: qbProcess, autoRecover: false);
        created[0].EnqueueComError(HresultDifferentFileOpen, "scripted");

        var ex = await Assert.ThrowsAsync<QbException>(() => manager.ExecuteAsync(CompanyQueryRequest));

        Assert.Equal(HresultDifferentFileOpen, ex.Error.Code);
        Assert.DoesNotContain("interactive", ex.Error.Message, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("circuit", ex.Error.Message, StringComparison.OrdinalIgnoreCase);
        Assert.Equal(0, qbProcess.KillCalls);

        await manager.DisposeAsync();
    }

    [Fact]
    public async Task Recovery_does_not_trigger_on_non_recoverable_errors()
    {
        // 0x80040420 QB_ACCESS_DENIED is not in the recoverable set — must NOT trigger a kill.
        var qbProcess = new FakeQbProcessManager { Count = 1 };
        var (manager, created) = CreateManager(qbProcess: qbProcess);
        var unrelatedHr = unchecked((int)0x80040420);
        created[0].EnqueueComError(unrelatedHr, "scripted");

        var ex = await Assert.ThrowsAsync<QbException>(() => manager.ExecuteAsync(CompanyQueryRequest));

        Assert.Equal(unrelatedHr, ex.Error.Code);
        Assert.Equal(0, qbProcess.KillCalls);

        await manager.DisposeAsync();
    }

    [Fact]
    public async Task Recovery_failed_retry_surfaces_verbatim_without_third_attempt()
    {
        var qbProcess = new FakeQbProcessManager { Count = 1 };
        var (manager, created) = CreateManager(qbProcess: qbProcess);
        created[0].EnqueueComError(HresultDifferentFileOpen, "first");
        // Add a second RP that ALSO fails — recovery should NOT loop forever, it retries ONCE.
        var retryRp = new FakeRequestProcessor();
        retryRp.EnqueueComError(HresultDifferentFileOpen, "second");
        created.Add(retryRp);

        var ex = await Assert.ThrowsAsync<QbException>(() => manager.ExecuteAsync(CompanyQueryRequest));

        Assert.Equal(HresultDifferentFileOpen, ex.Error.Code);
        Assert.Equal(1, qbProcess.KillCalls); // exactly one kill (one retry, not two)
        Assert.Equal(2, created.Count);       // factory called twice (initial + one retry)

        await manager.DisposeAsync();
    }

    // ---------- ReleaseAfterEachRequest tests ----------

    [Fact]
    public async Task ReleaseAfterEachRequest_true_releases_the_session_after_a_single_execute()
    {
        var (manager, created) = CreateManager(releaseAfterEachRequest: true);
        created[0].AddResponse("CompanyQueryRq", "<company/>");

        await manager.ExecuteAsync(CompanyQueryRequest);

        // CallLog should include both EndSession and CloseConnection from the auto-release.
        Assert.Contains(nameof(IRequestProcessor.EndSession), created[0].CallLog);
        Assert.Contains(nameof(IRequestProcessor.CloseConnection), created[0].CallLog);
        Assert.Equal(QbConnectionState.Disconnected, manager.State);
        Assert.Null(manager.CurrentCompanyKey);

        await manager.DisposeAsync();
    }

    [Fact]
    public async Task ReleaseAfterEachRequest_true_forces_a_fresh_connect_on_the_next_request()
    {
        var (manager, created) = CreateManager(releaseAfterEachRequest: true);
        created[0].AddResponse("CompanyQueryRq", "<first/>");

        await manager.ExecuteAsync(CompanyQueryRequest);

        // After the first execute the manager should be Disconnected and the next request
        // must build a fresh IRequestProcessor instance from the factory.
        Assert.Equal(QbConnectionState.Disconnected, manager.State);

        created.Add(new FakeRequestProcessor()); // factory will hand this out on the next call
        created[1].AddResponse("CompanyQueryRq", "<second/>");

        var second = await manager.ExecuteAsync(CompanyQueryRequest);

        Assert.Equal("<second/>", second);
        Assert.Equal(2, created.Count);
        Assert.Equal(1, created[0].CallLog.Count(c => c == nameof(IRequestProcessor.OpenConnection)));
        Assert.Equal(1, created[1].CallLog.Count(c => c == nameof(IRequestProcessor.OpenConnection)));

        await manager.DisposeAsync();
    }

    [Fact]
    public async Task ReleaseAsync_drops_an_existing_session_idempotently()
    {
        var (manager, created) = CreateManager(); // default = persistent session
        created[0].AddResponse("CompanyQueryRq", "<company/>");

        await manager.ExecuteAsync(CompanyQueryRequest);
        Assert.Equal(QbConnectionState.SessionOpen, manager.State);

        await manager.ReleaseAsync();
        Assert.Equal(QbConnectionState.Disconnected, manager.State);
        Assert.Null(manager.CurrentCompanyKey);
        Assert.Contains(nameof(IRequestProcessor.EndSession), created[0].CallLog);
        Assert.Contains(nameof(IRequestProcessor.CloseConnection), created[0].CallLog);

        // Idempotent: a second ReleaseAsync on an already-released manager is a no-op.
        await manager.ReleaseAsync();
        Assert.Equal(QbConnectionState.Disconnected, manager.State);

        await manager.DisposeAsync();
    }
}
