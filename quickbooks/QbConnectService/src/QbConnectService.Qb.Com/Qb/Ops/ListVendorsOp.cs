namespace QbConnectService.Qb.Ops;

public sealed class ListVendorsOp(
    QbXmlBuilder b,
    QbConnectionManager m,
    QbXmlParser xp,
    QbReportParser rp,
    QbListExecutor le) : ReadOpBase(b, m, xp, rp, le)
{
    public override string Name => "list_vendors";

    public override async Task<object?> RunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default)
    {
        var rq = QbXmlBuilder.Rq("VendorQueryRq");
        rq.Add(EntityListFilters.ActiveStatusElement(args));

        if (EntityListFilters.NameFilterElement(args) is { } nameFilter)
        {
            rq.Add(nameFilter);
        }

        var parsed = await QueryListAsync(rq, ownerIdZero: null, ct);
        return ListResult(parsed);
    }
}
