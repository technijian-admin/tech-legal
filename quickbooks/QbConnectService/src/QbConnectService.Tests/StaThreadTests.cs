using QbConnectService.Qb;

namespace QbConnectService.Tests;

public sealed class StaThreadTests
{
    [Fact]
    public async Task Run_returns_the_function_result()
    {
        using var sta = new StaThread("sta-test");

        var value = await sta.Run(() => 42);

        Assert.Equal(42, value);
    }

    [Fact]
    public async Task Run_marshals_all_work_to_one_sta_thread()
    {
        using var sta = new StaThread("sta-test");
        var callerThreadId = Thread.CurrentThread.ManagedThreadId;
        var observations = new List<(int ThreadId, ApartmentState ApartmentState)>();

        for (var i = 0; i < 5; i++)
        {
            observations.Add(await sta.Run(() =>
                (Thread.CurrentThread.ManagedThreadId, Thread.CurrentThread.GetApartmentState())));
        }

        Assert.All(observations, observation => Assert.Equal(ApartmentState.STA, observation.ApartmentState));
        Assert.All(observations, observation => Assert.NotEqual(callerThreadId, observation.ThreadId));
        Assert.Single(observations.Select(observation => observation.ThreadId).Distinct());
    }

    [Fact]
    public async Task Run_propagates_exceptions_to_the_caller()
    {
        using var sta = new StaThread("sta-test");

        await Assert.ThrowsAsync<InvalidOperationException>(() => sta.Run<int>(() => throw new InvalidOperationException("x")));
    }

    [Fact]
    public async Task Run_can_be_timed_out_by_the_waiter()
    {
        using var sta = new StaThread("sta-test");

        await Assert.ThrowsAsync<TimeoutException>(async () =>
            await sta.Run(() =>
                {
                    Thread.Sleep(2000);
                    return 0;
                })
                .WaitAsync(TimeSpan.FromMilliseconds(200)));
    }

    [Fact]
    public void Run_after_dispose_throws_invalid_operation_exception()
    {
        var sta = new StaThread("sta-test");
        sta.Dispose();

        var exception = Record.Exception(() =>
        {
            _ = sta.Run(() => 42);
        });

        Assert.IsType<InvalidOperationException>(exception);
    }
}
