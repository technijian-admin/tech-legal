using System.Diagnostics;
using Microsoft.Extensions.Logging;

namespace QbConnectService.Qb;

/// <summary>
/// Production implementation: enumerates QBW.EXE via System.Diagnostics.Process, treats any
/// process with a non-null MainWindowHandle AND non-empty MainWindowTitle as "interactive"
/// (a human attached), and uses Process.Kill(true) + Process.WaitForExitAsync to terminate.
/// </summary>
public sealed class WindowsQbProcessManager : IQbProcessManager
{
    private const string ProcessName = "QBW";
    private readonly ILogger<WindowsQbProcessManager> _log;

    public WindowsQbProcessManager(ILogger<WindowsQbProcessManager> log)
    {
        _log = log;
    }

    public QbProcessSnapshot Snapshot()
    {
        var processes = SafeGetProcesses();
        try
        {
            var count = processes.Length;
            var anyInteractive = false;
            foreach (var p in processes)
            {
                try
                {
                    if (p.MainWindowHandle != IntPtr.Zero && !string.IsNullOrWhiteSpace(p.MainWindowTitle))
                    {
                        anyInteractive = true;
                        break;
                    }
                }
                catch
                {
                    // Process may have exited between enumeration and inspection; ignore.
                }
            }
            return new QbProcessSnapshot(count, anyInteractive);
        }
        finally
        {
            foreach (var p in processes)
            {
                try { p.Dispose(); } catch { }
            }
        }
    }

    public async Task<int> KillAllAsync(TimeSpan exitTimeout, CancellationToken ct = default)
    {
        var processes = SafeGetProcesses();
        var killed = 0;
        try
        {
            foreach (var p in processes)
            {
                try
                {
                    if (!p.HasExited)
                    {
                        _log.LogInformation("Killing QBW.EXE PID {Pid} to recover from a stuck SDK state.", p.Id);
                        p.Kill(entireProcessTree: true);
                        killed++;
                    }
                }
                catch (Exception ex)
                {
                    _log.LogWarning(ex, "Failed to kill QBW.EXE PID {Pid}; proceeding.", p.Id);
                }
            }

            // Wait (poll, since the snapshot may show no processes once they all exit).
            var deadline = DateTime.UtcNow + exitTimeout;
            while (DateTime.UtcNow < deadline)
            {
                if (Process.GetProcessesByName(ProcessName).Length == 0)
                {
                    return killed;
                }
                try
                {
                    await Task.Delay(TimeSpan.FromMilliseconds(250), ct);
                }
                catch (TaskCanceledException)
                {
                    return killed;
                }
            }
        }
        finally
        {
            foreach (var p in processes)
            {
                try { p.Dispose(); } catch { }
            }
        }
        return killed;
    }

    private static Process[] SafeGetProcesses()
    {
        try
        {
            return Process.GetProcessesByName(ProcessName);
        }
        catch
        {
            return Array.Empty<Process>();
        }
    }
}
