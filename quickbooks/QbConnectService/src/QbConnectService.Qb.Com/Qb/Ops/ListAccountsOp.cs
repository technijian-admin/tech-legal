using System.Xml.Linq;

namespace QbConnectService.Qb.Ops;

/// <summary>
/// v1 account listing supports ActiveStatus, NameFilter, and an optional AccountType passthrough. FullNameWithChildren
/// filtering is intentionally deferred because the qbXML shape is awkward and dedicated account ops are out of scope.
/// </summary>
public sealed class ListAccountsOp(
    QbXmlBuilder b,
    QbConnectionManager m,
    QbXmlParser xp,
    QbReportParser rp,
    QbListExecutor le) : ReadOpBase(b, m, xp, rp, le)
{
    public override string Name => "list_accounts";

    public override async Task<object?> RunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default)
    {
        var rq = QbXmlBuilder.Rq("AccountQueryRq");
        rq.Add(EntityListFilters.ActiveStatusElement(args));

        if (EntityListFilters.NameFilterElement(args) is { } nameFilter)
        {
            rq.Add(nameFilter);
        }

        if (ArgReader.String(args, "accountType") is { Length: > 0 } accountType)
        {
            rq.Add(new XElement("AccountType", accountType));
        }

        var parsed = await QueryListAsync(rq, ownerIdZero: null, ct);
        return ListResult(parsed);
    }
}
