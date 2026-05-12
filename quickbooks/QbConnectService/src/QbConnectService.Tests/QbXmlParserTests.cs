using QbConnectService.Qb;

namespace QbConnectService.Tests;

public sealed class QbXmlParserTests
{
    private readonly QbXmlParser _parser = new();

    [Fact]
    public void Parse_reads_normal_entity_rows()
    {
        var response = _parser.Parse(Fixture("CustomerQueryRs.normal.qbxml"));

        Assert.Single(response.Elements);
        Assert.Equal("CustomerQueryRs", response.Elements[0].Name);
        Assert.Equal("0", response.Elements[0].Status.Code);
        Assert.False(response.Elements[0].Status.IsError);
        Assert.Equal(2, response.Elements[0].Rows.Count);
        Assert.Equal("Acme Roofing", response.Elements[0].Rows[0]["FullName"]);

        var billAddress = Assert.IsType<Dictionary<string, object?>>(response.Elements[0].Rows[0]["BillAddress"]);
        Assert.Equal("Seattle", billAddress["City"]);
        Assert.DoesNotContain("BillAddress", response.Elements[0].Rows[1].Keys);
    }

    [Fact]
    public void Parse_treats_zero_row_results_as_success()
    {
        var response = _parser.Parse(Fixture("CustomerQueryRs.zerorows.qbxml"));

        Assert.False(response.Elements[0].Status.IsError);
        Assert.Equal("1", response.Elements[0].Status.Code);
        Assert.Equal("A query request did not find a matching object in QuickBooks", response.Elements[0].Status.Message);
        Assert.Empty(response.Elements[0].Rows);
    }

    [Fact]
    public void Parse_maps_DataExtRet_blocks_into_customFields()
    {
        var response = _parser.Parse(Fixture("CustomerQueryRs.dataext.qbxml"));

        var customFields = Assert.IsType<List<Dictionary<string, object?>>>(response.Elements[0].Rows[0]["customFields"]);
        Assert.Equal(2, customFields.Count);
        Assert.Equal("Region", customFields[0]["DataExtName"]);
        Assert.Equal("West", customFields[0]["DataExtValue"]);
        Assert.DoesNotContain("DataExtRet", response.Elements[0].Rows[0].Keys);
    }

    [Fact]
    public void Parse_adds_a_type_discriminator_for_polymorphic_item_rows()
    {
        var response = _parser.Parse(Fixture("ItemQueryRs.polymorphic.qbxml"));

        Assert.Equal(2, response.Elements[0].Rows.Count);
        Assert.Equal("Service", response.Elements[0].Rows[0]["type"]);
        Assert.Equal("Inventory", response.Elements[0].Rows[1]["type"]);
        Assert.DoesNotContain("QuantityOnHand", response.Elements[0].Rows[0].Keys);
        Assert.Equal("8", response.Elements[0].Rows[1]["QuantityOnHand"]);
    }

    [Fact]
    public void Parse_surfaces_element_errors_without_throwing()
    {
        var response = _parser.Parse(Fixture("InvoiceAddRs.error.qbxml"));

        Assert.True(response.Elements[0].Status.IsError);
        Assert.Equal("3140", response.Elements[0].Status.Code);
        Assert.Empty(response.Elements[0].Rows);
    }

    [Fact]
    public void Parse_throws_QbXmlParseException_for_malformed_input()
    {
        Assert.Throws<QbXmlParseException>(() => _parser.Parse("<not-xml"));
        Assert.Throws<QbXmlParseException>(() => _parser.Parse("<QBXML><Wrong/></QBXML>"));
    }

    [Fact]
    public void Parse_preserves_stale_EditSequence_status_codes_verbatim()
    {
        const string raw = """
                           <QBXML>
                             <QBXMLMsgsRs>
                               <CustomerModRs statusCode="3200" statusSeverity="Error" statusMessage="The EditSequence supplied is out of date." />
                             </QBXMLMsgsRs>
                           </QBXML>
                           """;

        var response = _parser.Parse(raw);

        Assert.Equal("3200", response.Elements[0].Status.Code);
        Assert.True(response.Elements[0].Status.IsError);
    }

    private static string Fixture(string name) => File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "Fixtures", "qbxml", name));
}
