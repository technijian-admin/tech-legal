using System.Xml;
using System.Xml.Linq;

namespace QbConnectService.Qb;

public sealed class QbXmlParser
{
    private static readonly HashSet<string> ItemRetNames = new(StringComparer.Ordinal)
    {
        "ItemServiceRet",
        "ItemInventoryRet",
        "ItemNonInventoryRet",
        "ItemInventoryAssemblyRet",
        "ItemFixedAssetRet",
        "ItemOtherChargeRet",
        "ItemSubtotalRet",
        "ItemDiscountRet",
        "ItemPaymentRet",
        "ItemSalesTaxRet",
        "ItemSalesTaxGroupRet",
        "ItemGroupRet",
    };

    public ParsedQbXmlResponse Parse(string rawQbXmlResponse)
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

        var messages = document.Root?.Element("QBXMLMsgsRs")
            ?? throw new QbXmlParseException("Response has no <QBXMLMsgsRs>.");

        var messageStatus = messages.Attribute("statusSeverity") is not null
            ? QbStatus.FromElement(messages)
            : new QbStatus("0", "Info", "Status OK");

        var elements = new List<ParsedElement>();

        foreach (var responseElement in messages.Elements().Where(element => element.Name.LocalName.EndsWith("Rs", StringComparison.Ordinal)))
        {
            var status = QbStatus.FromElement(responseElement);
            var iteratorId = responseElement.Attribute("iteratorID")?.Value;
            var iteratorRemaining = int.TryParse(responseElement.Attribute("iteratorRemainingCount")?.Value, out var remaining)
                ? (int?)remaining
                : null;
            var rows = responseElement.Elements()
                .Where(IsRetElement)
                .Select(MapRet)
                .ToList();

            elements.Add(new ParsedElement(responseElement.Name.LocalName, status, iteratorId, iteratorRemaining, rows));
        }

        return new ParsedQbXmlResponse(messageStatus, elements);
    }

    private static bool IsRetElement(XElement element) =>
        element.Name.LocalName.EndsWith("Ret", StringComparison.Ordinal) &&
        element.Name.LocalName != "DataExtRet";

    private static Dictionary<string, object?> MapRet(XElement retElement)
    {
        var row = new Dictionary<string, object?>(StringComparer.Ordinal);

        if (ItemRetNames.Contains(retElement.Name.LocalName))
        {
            row["type"] = retElement.Name.LocalName["Item".Length..^"Ret".Length];
        }

        MapChildren(row, retElement.Elements());
        return row;
    }

    private static object MapNode(XElement element) => element.HasElements ? MapComplex(element) : element.Value;

    private static Dictionary<string, object?> MapComplex(XElement element)
    {
        var values = new Dictionary<string, object?>(StringComparer.Ordinal);
        MapChildren(values, element.Elements());
        return values;
    }

    private static void MapChildren(Dictionary<string, object?> values, IEnumerable<XElement> children)
    {
        foreach (var group in children.GroupBy(element => element.Name.LocalName, StringComparer.Ordinal))
        {
            if (group.Key == "DataExtRet")
            {
                values["customFields"] = group.Select(MapDataExt).ToList();
                continue;
            }

            var mapped = group.Select(MapNode).ToList();
            values[group.Key] = mapped.Count == 1 ? mapped[0] : mapped;
        }
    }

    private static Dictionary<string, object?> MapDataExt(XElement dataExtElement) =>
        new(StringComparer.Ordinal)
        {
            ["OwnerID"] = dataExtElement.Element("OwnerID")?.Value,
            ["DataExtName"] = dataExtElement.Element("DataExtName")?.Value,
            ["DataExtType"] = dataExtElement.Element("DataExtType")?.Value,
            ["DataExtValue"] = dataExtElement.Element("DataExtValue")?.Value,
        };
}

public sealed class QbXmlParseException(string message) : Exception(message);
