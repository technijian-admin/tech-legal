using QbConnectService.Qb;

namespace QbConnectService.Tests;

public sealed class QbReportParserTests
{
    private readonly QbReportParser _parser = new();

    [Fact]
    public void Parse_reads_report_headers_columns_and_rows_by_colID()
    {
        var report = _parser.Parse(Fixture("GeneralSummaryReportQueryRs.pnl.qbxml"));

        Assert.Equal("Profit & Loss", report.Title);
        Assert.Equal("January 2026", report.Subtitle);
        Assert.Equal("AccrualBasis", report.Basis);
        Assert.Equal(2, report.Columns.Count);
        Assert.Equal(string.Empty, report.Columns[0].Title);
        Assert.Equal("TOTAL", report.Columns[1].Title);
        Assert.Equal("Amount", report.Columns[1].Type);
        Assert.Equal(["TextRow", "DataRow", "SubtotalRow", "TotalRow"], report.Rows.Select(row => row.RowType).ToArray());
        Assert.Equal("Consulting", report.Rows[1].Label);
        Assert.Equal("12000.00", report.Rows[1].Cells["TOTAL"]);
        Assert.Equal("TotalRow", report.Rows[^1].RowType);
        Assert.Equal("Net Income", report.Rows[^1].Label);
        Assert.Equal("3500.00", report.Rows[^1].Cells["TOTAL"]);
    }

    [Fact]
    public void Parse_matches_sparse_ColData_by_colID_without_shifting_columns()
    {
        const string raw = """
                           <QBXML>
                             <QBXMLMsgsRs>
                               <GeneralSummaryReportQueryRs statusCode="0" statusSeverity="Info" statusMessage="Status OK">
                                 <ReportRet>
                                   <ColDesc colID="1">
                                     <ColTitle titleRow="1" value="" />
                                     <ColType>Amount</ColType>
                                   </ColDesc>
                                   <ColDesc colID="2">
                                     <ColTitle titleRow="1" value="TOTAL" />
                                     <ColType>Amount</ColType>
                                   </ColDesc>
                                   <ReportData>
                                     <DataRow>
                                       <RowData rowType="account" value="Consulting" />
                                       <ColData colID="2" value="9.99" />
                                     </DataRow>
                                   </ReportData>
                                 </ReportRet>
                               </GeneralSummaryReportQueryRs>
                             </QBXMLMsgsRs>
                           </QBXML>
                           """;

        var report = _parser.Parse(raw);
        var row = report.Rows.Single();

        Assert.Equal("9.99", row.Cells["TOTAL"]);
        Assert.DoesNotContain(string.Empty, row.Cells.Keys);
    }

    private static string Fixture(string name) => File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "Fixtures", "qbxml", name));
}
