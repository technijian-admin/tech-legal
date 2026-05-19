namespace QbConnectService.Qb;

/// <summary>
/// Snapshot of the QBW.EXE process(es) currently running on the host. Used by the
/// self-healing recovery path in <see cref="QbConnectionManager"/> to decide whether
/// it's safe to kill QBW.EXE (no interactive session attached) or whether the operator
/// must be involved (a human has QB Desktop open in the foreground).
/// </summary>
public sealed record QbProcessSnapshot(int Count, bool AnyInteractive);

/// <summary>
/// Thin abstraction over QBW.EXE process lifecycle so the recovery logic in
/// <see cref="QbConnectionManager"/> is testable. Production impl wraps
/// System.Diagnostics.Process; tests use an in-memory fake.
/// </summary>
public interface IQbProcessManager
{
    /// <summary>Snapshot of QBW.EXE state right now (count + whether any has a visible window).</summary>
    QbProcessSnapshot Snapshot();

    /// <summary>
    /// Kill every QBW.EXE process on the host and wait up to <paramref name="exitTimeout"/> for them
    /// to exit. Returns the number that were killed. Throws nothing on failure - cleanup is best-effort
    /// and the caller decides whether the absence of QBW.EXE is "good enough" via a follow-up Snapshot.
    /// </summary>
    Task<int> KillAllAsync(TimeSpan exitTimeout, CancellationToken ct = default);
}
