using QbConnectService.Qb;

namespace QbConnectService.Tests;

public sealed class QbWriteDetectorTests
{
    [Theory]
    [InlineData("CustomerAddRq")]
    [InlineData("InvoiceModRq")]
    [InlineData("BillModRq")]
    [InlineData("ListDelRq")]
    [InlineData("TxnDelRq")]
    [InlineData("TxnVoidRq")]
    [InlineData("DataExtDelRq")]
    public void Write_request_elements_return_true(string requestElement)
    {
        Assert.True(QbWriteDetector.IsWriteRequest(Wrap(requestElement)));
    }

    [Theory]
    [InlineData("CustomerQueryRq")]
    [InlineData("GeneralSummaryReportQueryRq")]
    [InlineData("HostQueryRq")]
    public void Read_request_elements_return_false(string requestElement)
    {
        Assert.False(QbWriteDetector.IsWriteRequest(Wrap(requestElement)));
    }

    [Fact]
    public void comment_named_ItemAddRq_does_not_trip()
    {
        var body = """
            <QBXML>
              <QBXMLMsgsRq onError="stopOnError">
                <!-- ItemAddRq -->
                <CustomerQueryRq />
              </QBXMLMsgsRq>
            </QBXML>
            """;

        Assert.False(QbWriteDetector.IsWriteRequest(body));
    }

    [Fact]
    public void element_literally_named_CustomerAddRq_trips_even_nested()
    {
        var body = """
            <QBXML>
              <QBXMLMsgsRq onError="stopOnError">
                <Envelope>
                  <CustomerAddRq />
                </Envelope>
              </QBXMLMsgsRq>
            </QBXML>
            """;

        Assert.True(QbWriteDetector.IsWriteRequest(body));
    }

    [Fact]
    public void malformed_xml_throws_QbXmlParseException()
    {
        Assert.Throws<QbXmlParseException>(() => QbWriteDetector.IsWriteRequest("<QBXML><unclosed>"));
    }

    private static string Wrap(string requestElement) =>
        $$"""
          <?xml version="1.0"?>
          <?qbxml version="16.0"?>
          <QBXML>
            <QBXMLMsgsRq onError="stopOnError">
              <{{requestElement}} />
            </QBXMLMsgsRq>
          </QBXML>
          """;
}
