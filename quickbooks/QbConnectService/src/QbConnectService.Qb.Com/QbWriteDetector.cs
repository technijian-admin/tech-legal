using System.Xml;
using System.Xml.Linq;

namespace QbConnectService.Qb;

/// <summary>
/// Detects qbXML write requests by element local name, never by substring or regex over the raw text. The
/// write-verb set (*AddRq/*ModRq/*DelRq/*VoidRq plus ListDelRq/TxnDelRq/TxnVoidRq) is medium-confidence and
/// Phase 9 re-pins it against the QuickBooks host's OSR enumeration.
/// </summary>
public static class QbWriteDetector
{
    public static bool IsWriteRequest(string rawQbXml)
    {
        try
        {
            var document = XDocument.Parse(rawQbXml);
            return document.Descendants().Any(element => IsWriteVerb(element.Name.LocalName));
        }
        catch (XmlException exception)
        {
            throw new QbXmlParseException($"Malformed qbXML request: {exception.Message}");
        }
    }

    private static bool IsWriteVerb(string localName) =>
        localName.EndsWith("AddRq", StringComparison.Ordinal) ||
        localName.EndsWith("ModRq", StringComparison.Ordinal) ||
        localName.EndsWith("DelRq", StringComparison.Ordinal) ||
        localName.EndsWith("VoidRq", StringComparison.Ordinal) ||
        localName is "ListDelRq" or "TxnDelRq" or "TxnVoidRq";
}
