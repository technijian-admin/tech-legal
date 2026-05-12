using Microsoft.Extensions.Options;

namespace QbConnectService.Qb.Ops;

public abstract class WriteOpBase(
    QbXmlBuilder builder,
    QbConnectionManager manager,
    QbXmlParser xmlParser,
    QbReportParser reportParser,
    QbListExecutor listExecutor,
    AuditLog audit,
    IOptions<SafetyOptions> safety)
    : ReadOpBase(builder, manager, xmlParser, reportParser, listExecutor), IWriteOp
{
    protected readonly AuditLog _audit = audit;
    private readonly SafetyOptions _safety = safety.Value;

    protected bool AllowWrites => _safety.AllowWrites;

    public abstract string BuildRequest(IReadOnlyDictionary<string, object?> args);

    public virtual Task<DryRunResult> DryRunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default) =>
        Task.FromResult(new DryRunResult(
            BuildRequest(args),
            $"{Name}: would send the qbXML below.",
            Array.Empty<PreFlightCheck>(),
            new Dictionary<string, object?>(),
            _safety.AllowWrites));

    public override async Task<object?> RunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default)
    {
        var requestXml = BuildRequest(args);
        if (!_safety.AllowWrites)
        {
            throw new QbWriteForbiddenException($"{Name} is a write op and Safety:AllowWrites is false.");
        }

        var rawResponse = await _manager.ExecuteAsync(requestXml, ct);
        var parsed = _xmlParser.Parse(rawResponse);
        var status = parsed.Message;
        var rows = parsed.Elements.Count > 0 ? parsed.First.Rows : new List<Dictionary<string, object?>>();
        var seq = await _audit.AppendAsync(
            new AuditRecord(Name, args, requestXml, status.Code, status.Severity, status.Message),
            ct);

        return new Dictionary<string, object?>
        {
            ["status"] = status,
            ["rows"] = rows,
            ["auditSeq"] = seq,
            ["rawSpilledTo"] = parsed.RawSpilledTo,
        };
    }

    protected static PreFlightCheck DiffFields(
        string label,
        IReadOnlyDictionary<string, string?> before,
        IReadOnlyDictionary<string, string?> after)
    {
        var changes = after.Keys
            .Union(before.Keys)
            .Where(key => !string.Equals(before.GetValueOrDefault(key), after.GetValueOrDefault(key), StringComparison.Ordinal))
            .Select(key => $"{key}: '{before.GetValueOrDefault(key)}' -> '{after.GetValueOrDefault(key)}'")
            .ToArray();

        return new PreFlightCheck(label, true, changes.Length == 0 ? "no changes" : string.Join("; ", changes));
    }

    // TODO(Phase 7): add current-record resolution helpers for mod_* pre-flight lookups.
}
