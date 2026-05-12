using System.Xml.Linq;

namespace QbConnectService.Qb.Ops;

/// <summary>
/// Base class for in-process read ops. QuickBooks element status and zero-row results are returned in the
/// response body and are never thrown; only transport/COM failures and caller argument validation propagate.
/// </summary>
public abstract class ReadOpBase(
    QbXmlBuilder builder,
    QbConnectionManager manager,
    QbXmlParser xmlParser,
    QbReportParser reportParser,
    QbListExecutor listExecutor) : IReadOp
{
    protected readonly QbXmlBuilder _builder = builder;
    protected readonly QbConnectionManager _manager = manager;
    protected readonly QbXmlParser _xmlParser = xmlParser;
    protected readonly QbReportParser _reportParser = reportParser;
    protected readonly QbListExecutor _listExecutor = listExecutor;

    public abstract string Name { get; }

    public abstract Task<object?> RunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default);

    /// <summary>
    /// Optional: the qbXML this read op would send, for the /dryrun endpoint. Default null (no preview).
    /// Read ops have no side effects; this is a convenience for showing the would-be request.
    /// </summary>
    public virtual string? PreviewRequest(IReadOnlyDictionary<string, object?> args) => null;

    protected async Task<ParsedQbXmlResponse> QuerySingleAsync(XElement rq, CancellationToken ct) =>
        _xmlParser.Parse(await _manager.ExecuteAsync(_builder.BuildRequest(rq), ct));

    protected async Task<ParsedQbXmlResponse> QuerySingleAsync(IEnumerable<XElement> rqs, CancellationToken ct) =>
        _xmlParser.Parse(await _manager.ExecuteAsync(_builder.BuildRequest(rqs), ct));

    protected Task<ParsedQbXmlResponse> QueryListAsync(XElement rq, bool? ownerIdZero, CancellationToken ct) =>
        _listExecutor.RunAsync(rq, ownerIdZero, ct);

    protected async Task<ParsedReport> QueryReportAsync(XElement rq, CancellationToken ct) =>
        _reportParser.Parse(await _manager.ExecuteAsync(_builder.BuildRequest(rq), ct));

    protected static object ListResult(ParsedQbXmlResponse response) =>
        new Dictionary<string, object?>
        {
            ["status"] = response.First.Status,
            ["rows"] = response.First.Rows,
            ["count"] = response.First.Rows.Count,
            ["rawSpilledTo"] = response.RawSpilledTo,
        };
}
