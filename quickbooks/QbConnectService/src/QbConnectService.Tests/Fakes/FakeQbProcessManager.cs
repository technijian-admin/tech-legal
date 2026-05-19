using QbConnectService.Qb;

namespace QbConnectService.Tests.Fakes;

/// <summary>
/// In-memory IQbProcessManager for tests. The constructor takes a starting process count
/// and whether any process is interactive. KillAllAsync zeros out the count and bumps
/// KillCalls. Tests can flip InteractiveBeforeKill / SetCount to script different scenarios.
/// </summary>
public sealed class FakeQbProcessManager : IQbProcessManager
{
    public int Count { get; set; }
    public bool AnyInteractive { get; set; }
    public int KillCalls { get; private set; }
    public List<TimeSpan> KillTimeouts { get; } = new();

    public QbProcessSnapshot Snapshot() => new(Count, AnyInteractive);

    public Task<int> KillAllAsync(TimeSpan exitTimeout, CancellationToken ct = default)
    {
        KillCalls++;
        KillTimeouts.Add(exitTimeout);
        var killed = Count;
        Count = 0;
        AnyInteractive = false;
        return Task.FromResult(killed);
    }
}
