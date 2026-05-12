namespace QbConnectService.Qb;

/// <summary>
/// The caller-supplied half of an audit row; Seq/TimestampUtc/RequesterId/PrevHash/Hash are computed by AuditLog.
/// </summary>
public sealed record AuditRecord(
    string Op,
    IReadOnlyDictionary<string, object?> Args,
    string QbXmlRequest,
    string ResponseStatusCode,
    string ResponseStatusSeverity,
    string ResponseStatusMessage);
