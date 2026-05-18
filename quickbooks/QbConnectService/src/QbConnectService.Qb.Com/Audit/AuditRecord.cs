namespace QbConnectService.Qb;

/// <summary>
/// The caller-supplied half of an audit row; Seq/TimestampUtc/RequesterId/PrevHash/Hash are computed by AuditLog.
/// Company identifies which Qb.Companies entry the write was routed to (or "default" for the legacy single-tenant path).
/// </summary>
public sealed record AuditRecord(
    string Op,
    IReadOnlyDictionary<string, object?> Args,
    string QbXmlRequest,
    string ResponseStatusCode,
    string ResponseStatusSeverity,
    string ResponseStatusMessage,
    string Company = "default");
