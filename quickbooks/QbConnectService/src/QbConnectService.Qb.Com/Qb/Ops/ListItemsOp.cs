namespace QbConnectService.Qb.Ops;

/// <summary>
/// Polymorphic Item*Ret shapes are normalized by QbXmlParser, which adds a "type" discriminator per row.
/// Phase 9 re-pins the exact discriminator names against the live host if needed.
/// </summary>
public sealed class ListItemsOp(
    QbXmlBuilder b,
    QbConnectionManager m,
    QbXmlParser xp,
    QbReportParser rp,
    QbListExecutor le) : ReadOpBase(b, m, xp, rp, le)
{
    public override string Name => "list_items";

    public override async Task<object?> RunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default)
    {
        var rq = QbXmlBuilder.Rq("ItemQueryRq");
        rq.Add(EntityListFilters.ActiveStatusElement(args));

        if (EntityListFilters.NameFilterElement(args) is { } nameFilter)
        {
            rq.Add(nameFilter);
        }

        var parsed = await QueryListAsync(rq, ownerIdZero: null, ct);
        return ListResult(parsed);
    }
}
