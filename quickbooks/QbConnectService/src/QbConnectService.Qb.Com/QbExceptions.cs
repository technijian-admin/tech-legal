namespace QbConnectService.Qb;

public class QbException : Exception
{
    public QbException(QbError error, Exception? inner = null)
        : base($"{error.Name} (0x{error.Code:X8}): {error.Message} — {error.RemediationHint}", inner)
    {
        Error = error;
    }

    public QbError Error { get; }

    public static QbException From(System.Runtime.InteropServices.COMException ex) =>
        new(QbErrors.Lookup(ex.HResult), ex);
}

public sealed class QbBusyException : Exception
{
    public QbBusyException(TimeSpan waitedFor)
        : base($"QuickBooks is busy with another request; waited {waitedFor.TotalSeconds:F0}s.")
    {
        WaitedFor = waitedFor;
    }

    public TimeSpan WaitedFor { get; }
}

public sealed class QbTimeoutException : Exception
{
    public QbTimeoutException(TimeSpan timeout)
        : base($"QuickBooks request exceeded the {timeout.TotalSeconds:F0}s timeout; the session has been reset.")
    {
        Timeout = timeout;
    }

    public TimeSpan Timeout { get; }
}
