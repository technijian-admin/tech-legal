using System.Collections.Concurrent;
using System.Runtime.CompilerServices;

[assembly: InternalsVisibleTo("QbConnectService.Tests")]

namespace QbConnectService.Qb;

internal sealed class StaThread : IDisposable
{
    private readonly BlockingCollection<Action> _queue = new();
    private readonly Thread _thread;

    public StaThread(string name)
    {
        _thread = new Thread(Pump)
        {
            IsBackground = true,
            Name = name,
        };

        _thread.SetApartmentState(ApartmentState.STA);
        _thread.Start();
    }

    public Task Run(Action action, CancellationToken ct = default) =>
        Run<object?>(() =>
        {
            action();
            return null;
        }, ct);

    public Task<T> Run<T>(Func<T> func, CancellationToken ct = default)
    {
        var tcs = new TaskCompletionSource<T>(TaskCreationOptions.RunContinuationsAsynchronously);
        var registration = ct.Register(() => tcs.TrySetCanceled(ct));
        _ = tcs.Task.ContinueWith(
            _ => registration.Dispose(),
            CancellationToken.None,
            TaskContinuationOptions.ExecuteSynchronously,
            TaskScheduler.Default);

        _queue.Add(() =>
        {
            try
            {
                tcs.TrySetResult(func());
            }
            catch (Exception ex)
            {
                tcs.TrySetException(ex);
            }
        });

        return tcs.Task;
    }

    public void Dispose()
    {
        _queue.CompleteAdding();
    }

    private void Pump()
    {
        foreach (var work in _queue.GetConsumingEnumerable())
        {
            try
            {
                work();
            }
            catch
            {
                // The queued work captures its own exception into its TaskCompletionSource.
            }
        }
    }
}
