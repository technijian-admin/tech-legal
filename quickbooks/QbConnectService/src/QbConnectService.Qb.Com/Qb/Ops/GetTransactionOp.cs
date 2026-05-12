using System.Xml.Linq;

namespace QbConnectService.Qb.Ops;

/// <summary>
/// Looks up TransactionRet rows by TxnID or RefNumber. RefNumber is editable and non-unique, so results are
/// always returned as a list. TransactionRet is header-level only; lite=true signals that callers needing
/// line detail should use the dedicated transaction list ops. Query element names are Phase 9 re-pin candidates.
/// </summary>
public sealed class GetTransactionOp(
    QbXmlBuilder b,
    QbConnectionManager m,
    QbXmlParser xp,
    QbReportParser rp,
    QbListExecutor le) : ReadOpBase(b, m, xp, rp, le)
{
    public override string Name => "get_transaction";

    public override async Task<object?> RunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default)
    {
        var txnId = ArgReader.String(args, "txnId");
        var refNumber = ArgReader.String(args, "refNumber");

        if ((txnId is null) == (refNumber is null))
        {
            throw new ArgumentException("get_transaction: supply exactly one of txnId or refNumber.");
        }

        var rq = QbXmlBuilder.Rq(
            "TransactionQueryRq",
            txnId is not null
                ? new XElement("TxnIDList", new XElement("TxnID", txnId))
                : new XElement(
                    "RefNumberFilter",
                    new XElement("MatchCriterion", "Equals"),
                    new XElement("RefNumber", refNumber)));

        if (ArgReader.String(args, "txnType") is { Length: > 0 } txnType)
        {
            rq.Add(new XElement("TransactionTypeList", new XElement("TxnType", txnType)));
        }

        var parsed = await QuerySingleAsync(rq, ct);
        var rows = parsed.First.Rows;

        return new Dictionary<string, object?>
        {
            ["status"] = parsed.First.Status,
            ["matches"] = rows,
            ["count"] = rows.Count,
            ["ambiguous"] = txnId is null && rows.Count > 1,
            ["lite"] = true,
        };
    }
}
