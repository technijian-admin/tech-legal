using System.Collections;
using System.Xml.Linq;

namespace QbConnectService.Qb.Ops;

/// <summary>
/// InvoiceQueryRq defaults to header-level rows. includeLineItems=true opts into line detail; the exact element
/// name is Phase 9 re-pinned against the live host.
/// </summary>
public sealed class ListInvoicesOp(
    QbXmlBuilder b,
    QbConnectionManager m,
    QbXmlParser xp,
    QbReportParser rp,
    QbListExecutor le) : ReadOpBase(b, m, xp, rp, le)
{
    public override string Name => "list_invoices";

    public override async Task<object?> RunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default)
    {
        var rq = QbXmlBuilder.Rq("InvoiceQueryRq");

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

internal static class TransactionListFilters
{
    public static XElement? TxnDateRangeFilterElement(IReadOnlyDictionary<string, object?> args)
    {
        var from = ArgReader.Date(args, "fromDate");
        var to = ArgReader.Date(args, "toDate");
        var macro = ArgReader.String(args, "dateMacro");

        if (from is null && to is null && macro is null)
        {
            return null;
        }

        if (macro is not null && (from is not null || to is not null))
        {
            throw new ArgumentException("dateMacro cannot be combined with fromDate or toDate.");
        }

        var filter = new XElement("TxnDateRangeFilter");
        if (macro is not null)
        {
            filter.Add(new XElement("DateMacro", macro));
            return filter;
        }

        if (from is not null)
        {
            filter.Add(new XElement("FromTxnDate", from.Value.ToString("yyyy-MM-dd")));
        }

        if (to is not null)
        {
            filter.Add(new XElement("ToTxnDate", to.Value.ToString("yyyy-MM-dd")));
        }

        return filter;
    }

    public static XElement? EntityFilterElement(IReadOnlyDictionary<string, object?> args)
    {
        var entity = ArgReader.String(args, "entity");
        if (string.IsNullOrWhiteSpace(entity))
        {
            return null;
        }

        return new XElement(
            "EntityFilter",
            new XElement(
                "FullNameList",
                new XElement("FullName", entity)));
    }
}
