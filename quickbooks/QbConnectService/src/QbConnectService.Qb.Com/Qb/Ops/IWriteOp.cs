namespace QbConnectService.Qb.Ops;

public interface IWriteOp : IReadOp
{
    /// <summary>
    /// Byte-exact qbXML this op WOULD send for these args. Pure: no I/O, no COM, deterministic.
    /// Throws ArgumentException on bad/missing args. RunAsync and DryRunAsync both call this.
    /// </summary>
    string BuildRequest(IReadOnlyDictionary<string, object?> args);

    /// <summary>
    /// Build the request plus pre-flight validation. May do read round-trips, but MUST NOT execute a write
    /// request and MUST NOT append to the audit log.
    /// </summary>
    Task<DryRunResult> DryRunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default);
}
