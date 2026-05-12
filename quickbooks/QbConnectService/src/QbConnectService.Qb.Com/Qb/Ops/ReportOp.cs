using System.Xml.Linq;

namespace QbConnectService.Qb.Ops;

/// <summary>
/// Runs GeneralSummaryReportQueryRq or AgingReportQueryRq for a supported report type. The report request
/// envelope is verified, while the enum values and exact aging date shape are Phase 9 re-pin candidates.
/// </summary>
public sealed class ReportOp(
    QbXmlBuilder b,
    QbConnectionManager m,
    QbXmlParser xp,
    QbReportParser rp,
    QbListExecutor le) : ReadOpBase(b, m, xp, rp, le)
{
    public override string Name => "report";

    public override async Task<object?> RunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default)
    {
        var type = ArgReader.String(args, "type")
            ?? throw new ArgumentException("report: 'type' is required (ProfitAndLoss|BalanceSheet|AgingAR|AgingAP).");
        var from = ArgReader.Date(args, "fromDate");
        var to = ArgReader.Date(args, "toDate");
        var macro = ArgReader.String(args, "dateMacro");

        if ((from is not null) != (to is not null))
        {
            throw new ArgumentException("report: fromDate and toDate must be supplied together.");
        }

        var hasRange = from is not null && to is not null;
        if (hasRange == (macro is not null))
        {
            throw new ArgumentException("report: supply exactly one of (fromDate+toDate) or dateMacro.");
        }

        XElement dateChild = macro is not null
            ? new XElement("ReportDateMacro", macro)
            : new XElement(
                "ReportPeriod",
                new XElement("FromReportDate", from!.Value.ToString("yyyy-MM-dd")),
                new XElement("ToReportDate", to!.Value.ToString("yyyy-MM-dd")));

        var rq = type switch
        {
            "ProfitAndLoss" => QbXmlBuilder.Rq(
                "GeneralSummaryReportQueryRq",
                new XElement("GeneralSummaryReportType", "ProfitAndLossStandard"),
                dateChild),
            "BalanceSheet" => QbXmlBuilder.Rq(
                "GeneralSummaryReportQueryRq",
                new XElement("GeneralSummaryReportType", "BalanceSheetStandard"),
                dateChild),
            "AgingAR" => QbXmlBuilder.Rq(
                "AgingReportQueryRq",
                new XElement("AgingReportType", "ARAgingSummary"),
                dateChild),
            "AgingAP" => QbXmlBuilder.Rq(
                "AgingReportQueryRq",
                new XElement("AgingReportType", "APAgingSummary"),
                dateChild),
            _ => throw new ArgumentException("report: 'type' is required (ProfitAndLoss|BalanceSheet|AgingAR|AgingAP)."),
        };

        var report = await QueryReportAsync(rq, ct);
        return new Dictionary<string, object?>
        {
            ["type"] = type,
            ["report"] = report,
        };
    }
}
