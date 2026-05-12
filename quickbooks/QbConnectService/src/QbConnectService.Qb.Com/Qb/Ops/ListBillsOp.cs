using System.Xml.Linq;

namespace QbConnectService.Qb.Ops;

public sealed class ListBillsOp(
    QbXmlBuilder b,
    QbConnectionManager m,
    QbXmlParser xp,
    QbReportParser rp,
    QbListExecutor le) : ReadOpBase(b, m, xp, rp, le)
{
    public override string Name => "list_bills";

    public override async Task<object?> RunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default)
    {
        var rq = QbXmlBuilder.Rq("BillQueryRq");

        if (TransactionListFilters.TxnDateRangeFilterElement(args) is { } dateFilter)
        {
            rq.Add(dateFilter);
        }

        if (TransactionListFilters.EntityFilterElement(args) is { } entityFilter)
        {
            rq.Add(entityFilter);
        }

        if (ArgReader.Bool(args, "includeLineItems") == true)
        {
            rq.Add(new XElement("IncludeLineItems", "true"));
        }

        var parsed = await QueryListAsync(rq, ownerIdZero: null, ct);
        return ListResult(parsed);
    }
}
