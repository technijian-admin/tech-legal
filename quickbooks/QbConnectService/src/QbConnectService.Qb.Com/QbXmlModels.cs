using System.Xml.Linq;

namespace QbConnectService.Qb;

public enum IteratorMode
{
    None,
    Start,
    Continue,
}

public sealed record QbStatus(string Code, string Severity, string Message)
{
    public bool IsError => string.Equals(Severity, "Error", StringComparison.OrdinalIgnoreCase);

    public static QbStatus FromElement(XElement element) =>
        new(
            element.Attribute("statusCode")?.Value ?? "0",
            element.Attribute("statusSeverity")?.Value ?? "Info",
            element.Attribute("statusMessage")?.Value ?? "Status OK");
}

public sealed record ParsedElement(
    string Name,
    QbStatus Status,
    string? IteratorId,
    int? IteratorRemaining,
    List<Dictionary<string, object?>> Rows);

public sealed record ParsedQbXmlResponse(QbStatus Message, List<ParsedElement> Elements, string? RawSpilledTo = null)
{
    public ParsedElement First => Elements[0];
}

public sealed record ReportColumn(string Id, string Title, string? Type);

public sealed record ReportRow(string RowType, string? Label, string? RowDataType, Dictionary<string, string> Cells);

public sealed record ParsedReport(
    string? Title,
    string? Subtitle,
    string? Basis,
    List<ReportColumn> Columns,
    List<ReportRow> Rows);
