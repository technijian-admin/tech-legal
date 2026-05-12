using System.IO;
using System.Text;
using System.Xml.Linq;
using Microsoft.Extensions.Options;

namespace QbConnectService.Qb;

public sealed class QbXmlBuilder
{
    private readonly QbXmlOptions _opts;

    public QbXmlBuilder(IOptions<QbXmlOptions> opts)
    {
        _opts = opts.Value;
    }

    public string Version => _opts.Version;

    public static XElement Rq(string requestName, params object[] content) => new(requestName, content);

    public static XElement WithIterator(
        XElement queryElement,
        IteratorMode mode,
        string? iteratorId = null,
        int? maxReturned = null,
        string requestId = "1")
    {
        if (mode == IteratorMode.None)
        {
            return queryElement;
        }

        queryElement.SetAttributeValue("requestID", requestId);
        queryElement.SetAttributeValue("iterator", mode == IteratorMode.Start ? "Start" : "Continue");

        if (mode == IteratorMode.Continue && iteratorId is not null)
        {
            queryElement.SetAttributeValue("iteratorID", iteratorId);
        }

        if (maxReturned is int max && queryElement.Element("MaxReturned") is null)
        {
            queryElement.AddFirst(new XElement("MaxReturned", max));
        }

        return queryElement;
    }

    public static XElement WithOwnerIdZero(XElement queryElement)
    {
        if (queryElement.Element("OwnerID") is null)
        {
            queryElement.Add(new XElement("OwnerID", "0"));
        }

        return queryElement;
    }

    public string BuildRequest(XElement requestBody) => BuildRequest(new[] { requestBody });

    public string BuildRequest(IEnumerable<XElement> requestBodies)
    {
        var document = new XDocument(
            new XDeclaration("1.0", "utf-8", null),
            new XProcessingInstruction("qbxml", $"version=\"{_opts.Version}\""),
            new XElement(
                "QBXML",
                new XElement(
                    "QBXMLMsgsRq",
                    new XAttribute("onError", "stopOnError"),
                    requestBodies)));

        using var writer = new Utf8StringWriter();
        document.Save(writer, SaveOptions.None);
        return writer.ToString();
    }

    private sealed class Utf8StringWriter : StringWriter
    {
        public override Encoding Encoding => Encoding.UTF8;
    }
}
