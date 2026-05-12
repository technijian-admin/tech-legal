using QbConnectService.Qb;

namespace QbConnectService.Tests;

public sealed class StaThreadTests
{
    [Fact]
    public async Task Run_returns_the_function_result()
    {
        using var sta = new StaThread("test-sta");

        var result = await sta.Run(() => 42);

        Assert.Equal(42, result);
    }

    [Fact]
    public async Task Run_marshals_every_call_to_the_same_sta_thread()
    {
        using var sta = new StaThread("test-sta");
        var testThreadId = Thread.CurrentThread.ManagedThreadId;
        var threadIds = new List<int>();
        var apartmentStates = new List<ApartmentState>();

        for (var i = 0; i < 5; i++)
        {
            var info = await sta.Run(() => (
                ManagedThreadId: Thread.CurrentThread.ManagedThreadId,
                ApartmentState: Thread.CurrentThread.GetApartmentState()));
            threadIds.Add(info.ManagedThreadId);
            apartmentStates.Add(info.ApartmentState);
        }

        Assert.All(threadIds, threadId => Assert.NotEqual(testThreadId, threadId));
        Assert.Single(threadIds.Distinct());
        Assert.All(apartmentStates, apartmentState => Assert.Equal(ApartmentState.STA, apartmentState));
    }

    [Fact]
    public async Task Run_propagates_exceptions_to_the_caller()
    {
        using var sta = new StaThread("test-sta");

        var exception = await Assert.ThrowsAsync<InvalidOperationException>(() => sta.Run<int>(() =>
        {
            throw new InvalidOperationException("x");
        }));

        Assert.Equal("x", exception.Message);
    }

    [Fact]
    public async Task WaitAsync_can_timeout_a_slow_work_item()
    {
        using var sta = new StaThread("test-sta");

        await Assert.ThrowsAsync<TimeoutException>(async () =>
            await sta.Run(() =>
            {
                Thread.Sleep(2000);
                return 0;
            }).WaitAsync(TimeSpan.FromMilliseconds(200)));
    }

    [Fact]
    public void Dispose_stops_accepting_new_work()
    {
        using var sta = new StaThread("test-sta");

        sta.Dispose();

        var exception = Record.Exception(() =>
        {
            _ = sta.Run(() => 1);
        });

        Assert.IsType<InvalidOperationException>(exception);
    }
}
