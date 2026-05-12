using System.Xml.Linq;
using Microsoft.Extensions.Options;
using QbConnectService.Qb;

namespace QbConnectService.Tests;

public sealed class QbXmlBuilderTests
{
    [Fact]
    public void BuildRequest_emits_the_full_qbXML_envelope()
    {
        var actual = Normalize(Build("16.0").BuildRequest(QbXmlBuilder.Rq("CompanyQueryRq")));
        var expected = Normalize(
            """
            <?xml version="1.0" encoding="utf-8"?>
            <?qbxml version="16.0"?>
            <QBXML>
              <QBXMLMsgsRq onError="stopOnError">
                <CompanyQueryRq />
              </QBXMLMsgsRq>
            </QBXML>
            """);

        Assert.Equal(expected, actual);
    }

    [Fact]
    public void BuildRequest_uses_the_configured_qbXML_version()
    {
        var actual = Build("13.0").BuildRequest(QbXmlBuilder.Rq("CompanyQueryRq"));

        Assert.Contains("<?qbxml version=\"13.0\"?>", actual);
        Assert.DoesNotContain("<?qbxml version=\"16.0\"?>", actual);
    }

    [Fact]
    public void WithIterator_Start_sets_request_attributes_and_MaxReturned()
    {
        var request = QbXmlBuilder.Rq("CustomerQueryRq");

        QbXmlBuilder.WithIterator(request, IteratorMode.Start, maxReturned: 100, requestId: "1");

        Assert.Equal("1", request.Attribute("requestID")?.Value);
        Assert.Equal("Start", request.Attribute("iterator")?.Value);
        Assert.Null(request.Attribute("iteratorID"));
        Assert.Equal("MaxReturned", request.Elements().First().Name.LocalName);
        Assert.Equal("100", request.Element("MaxReturned")?.Value);
    }

    [Fact]
    public void WithIterator_Continue_sets_iterator_id()
    {
        var request = QbXmlBuilder.Rq("CustomerQueryRq");

        QbXmlBuilder.WithIterator(request, IteratorMode.Continue, iteratorId: "{abc}", requestId: "1");

        Assert.Equal("Continue", request.Attribute("iterator")?.Value);
        Assert.Equal("{abc}", request.Attribute("iteratorID")?.Value);
        Assert.Equal("1", request.Attribute("requestID")?.Value);
    }

    [Fact]
    public void WithIterator_does_not_override_an_existing_MaxReturned()
    {
        var request = QbXmlBuilder.Rq("CustomerQueryRq", new XElement("MaxReturned", 50));

        QbXmlBuilder.WithIterator(request, IteratorMode.Start, maxReturned: 100);

        var maxReturned = request.Elements("MaxReturned").ToList();
        Assert.Single(maxReturned);
        Assert.Equal("50", maxReturned[0].Value);
    }

    [Fact]
    public void WithOwnerIdZero_is_idempotent()
    {
        var request = QbXmlBuilder.Rq("CustomerQueryRq");

        QbXmlBuilder.WithOwnerIdZero(request);
        QbXmlBuilder.WithOwnerIdZero(request);

        var ownerIds = request.Elements("OwnerID").ToList();
        Assert.Single(ownerIds);
        Assert.Equal("0", ownerIds[0].Value);
    }

    private static QbXmlBuilder Build(string version) => new(Options.Create(new QbXmlOptions { Version = version }));

    private static string Normalize(string value) => value.Replace("\r\n", "\n").Trim();
}
