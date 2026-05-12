using System.Xml;
using System.Xml.Linq;

namespace QbConnectService.Qb;

public sealed class QbReportParser
{
    public ParsedReport Parse(string rawQbXmlResponse)
    {
        XDocument document;

        try
        {
            document = XDocument.Parse(rawQbXmlResponse);
        }
        catch (XmlException exception)
        {
            throw new QbXmlParseException($"Malformed qbXML response: {exception.Message}");
        }

        var messages = document.Root?.Elements().FirstOrDefault(element => LocalNameEquals(element, "QBXMLMsgsRs"))
            ?? throw new QbXmlParseException("Response has no <QBXMLMsgsRs>.");
        var reportResponse = messages.Elements().FirstOrDefault(element => element.Name.LocalName.EndsWith("ReportQueryRs", StringComparison.Ordinal));
        var report = reportResponse?.Elements().FirstOrDefault(element => LocalNameEquals(element, "ReportRet"));

        if (report is null)
        {
            return new ParsedReport(null, null, null, new(), new());
        }

        var columns = new List<ReportColumn>();
        var columnTitlesById = new Dictionary<string, string>(StringComparer.Ordinal);

        foreach (var columnDescription in report.Elements().Where(element => LocalNameEquals(element, "ColDesc")))
        {
            var id = GetAttributeValue(columnDescription, "colID") ?? string.Empty;
            var titleElement = columnDescription.Elements()
                .Where(element => LocalNameEquals(element, "ColTitle"))
                .OrderByDescending(element => string.Equals(GetAttributeValue(element, "titleRow"), "1", StringComparison.Ordinal))
                .FirstOrDefault();
            var title = GetAttributeValue(titleElement, "value")
                ?? GetAttributeValue(columnDescription, "colTitle")
                ?? string.Empty;
            var type = columnDescription.Elements()
                .FirstOrDefault(element => LocalNameEquals(element, "ColType"))?
                .Value
                ?? GetAttributeValue(columnDescription, "colType");

            columns.Add(new ReportColumn(id, title, type));
            columnTitlesById[id] = title;
        }

        var rows = new List<ReportRow>();
        var reportData = report.Elements().FirstOrDefault(element => LocalNameEquals(element, "ReportData"));

        if (reportData is not null)
        {
            foreach (var rowElement in reportData.Elements())
            {
                var rowData = rowElement.Elements().FirstOrDefault(element => LocalNameEquals(element, "RowData"));
                var cells = new Dictionary<string, string>(StringComparer.Ordinal);

                foreach (var cell in rowElement.Elements().Where(element => LocalNameEquals(element, "ColData")))
                {
                    var columnId = GetAttributeValue(cell, "colID");
                    if (columnId is not null && columnTitlesById.TryGetValue(columnId, out var title))
                    {
                        cells[title] = GetAttributeValue(cell, "value") ?? string.Empty;
                    }
                }

                rows.Add(new ReportRow(
                    rowElement.Name.LocalName,
                    GetAttributeValue(rowData, "value"),
                    GetAttributeValue(rowData, "rowType"),
                    cells));
            }
        }

        return new ParsedReport(
            ElementValue(report, "ReportTitle"),
            ElementValue(report, "ReportSubtitle"),
            ElementValue(report, "ReportBasis"),
            columns,
            rows);
    }

    private static string? ElementValue(XElement? parent, string localName) =>
        parent?.Elements().FirstOrDefault(element => LocalNameEquals(element, localName))?.Value;

    private static bool LocalNameEquals(XElement element, string localName) =>
        string.Equals(element.Name.LocalName, localName, StringComparison.OrdinalIgnoreCase);

    private static string? GetAttributeValue(XElement? element, string localName) =>
        element?.Attributes().FirstOrDefault(attribute => string.Equals(attribute.Name.LocalName, localName, StringComparison.OrdinalIgnoreCase))?.Value;
}
