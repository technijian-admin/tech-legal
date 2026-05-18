using Microsoft.Extensions.Options;
using System.Xml.Linq;

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
    private static readonly HashSet<string> TxnEntities = new(StringComparer.OrdinalIgnoreCase)
    {
        "Invoice",
        "Bill",
        "Check",
        "ReceivePayment",
        "JournalEntry",
        "SalesReceipt",
        "CreditMemo",
        "PurchaseOrder",
        "Estimate",
        "BillPaymentCheck",
        "Deposit",
    };
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
        var company = _manager.CurrentCompanyKey ?? QbCompanyContext.Current ?? "default";
        var seq = await _audit.AppendAsync(
            new AuditRecord(Name, args, requestXml, status.Code, status.Severity, status.Message, company),
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

    /// <summary>
    /// Phase 9 re-pins whether list-entity name queries should use FullNameList, NameFilter, or NameRangeFilter
    /// on the live host. The fake fixtures are constructed to match the wrapper style below.
    /// </summary>
    protected async Task<IReadOnlyDictionary<string, object?>?> FetchByNameAsync(
        string entity,
        string fullName,
        CancellationToken ct)
    {
        var rq = QbXmlBuilder.Rq(
            entity + "QueryRq",
            new XElement(
                "FullNameList",
                new XElement("FullName", fullName)));

        var parsed = await QuerySingleAsync(rq, ct);
        return parsed.Elements.Count > 0 ? parsed.First.Rows.FirstOrDefault() : null;
    }

    /// <summary>
    /// Phase 9 re-pins the exact ListIDList/FullNameList/TxnIDList query-filter wrappers per entity on the
    /// live host. GetTransactionOp already uses TxnIDList in-repo, so that pattern is the current baseline.
    /// </summary>
    protected async Task<(IReadOnlyDictionary<string, object?> Record, string EditSequence)?> FetchCurrentAsync(
        string entity,
        string refKind,
        string refValue,
        CancellationToken ct)
    {
        var idElement = refKind switch
        {
            "txnID" => new XElement("TxnIDList", new XElement("TxnID", refValue)),
            "listID" => new XElement("ListIDList", new XElement("ListID", refValue)),
            "fullName" => new XElement("FullNameList", new XElement("FullName", refValue)),
            _ => throw new ArgumentException($"mod: ref must be one of txnID/listID/fullName; got '{refKind}'."),
        };

        var queryName = TxnEntities.Contains(entity) ? entity + "QueryRq" : entity + "QueryRq";
        var parsed = await QuerySingleAsync(QbXmlBuilder.Rq(queryName, idElement), ct);
        var row = parsed.Elements.Count > 0 ? parsed.First.Rows.FirstOrDefault() : null;
        if (row is null)
        {
            return null;
        }

        var editSequence = row.GetValueOrDefault("EditSequence") as string
            ?? throw new ArgumentException($"mod: {entity} record has no EditSequence - cannot modify.");

        return (row, editSequence);
    }
}
