using System.Xml.Linq;
using QbConnectService.Qb;

namespace QbConnectService.Tests;

public sealed class ReportOpTests
{
    [Fact]
    public async Task report_profit_and_loss_with_date_range_builds_GeneralSummaryReportQueryRq()
    {
        var (fake, manager, ops) = OpTestHarness.Create();
        fake.AddResponse("GeneralSummaryReportQueryRq", OpTestHarness.Fixture("GeneralSummaryReportQueryRs.pnl.qbxml"));

        try
        {
            var result = Assert.IsAssignableFrom<IReadOnlyDictionary<string, object?>>(
                await ops["report"].RunAsync(
                    new Dictionary<string, object?>
                    {
                        ["type"] = "ProfitAndLoss",
                        ["fromDate"] = "2025-01-01",
                        ["toDate"] = "2025-12-31",
                    },
                    default));

            Assert.Equal("ProfitAndLoss", result["type"]);
            var report = Assert.IsType<ParsedReport>(result["report"]);
            Assert.NotEmpty(report.Columns);
            Assert.NotEmpty(report.Rows);

            var request = XDocument.Parse(fake.ProcessRequests[0]).Root!.Element("QBXMLMsgsRq")!.Element("GeneralSummaryReportQueryRq")!;
            Assert.Equal("ProfitAndLossStandard", request.Element("GeneralSummaryReportType")?.Value);
            var period = request.Element("ReportPeriod");
            Assert.NotNull(period);
            Assert.Equal("2025-01-01", period!.Element("FromReportDate")?.Value);
            Assert.Equal("2025-12-31", period.Element("ToReportDate")?.Value);
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }

    [Fact]
    public async Task report_balance_sheet_with_date_macro_builds_ReportDateMacro()
    {
        var (fake, manager, ops) = OpTestHarness.Create();
        fake.AddResponse("GeneralSummaryReportQueryRq", OpTestHarness.Fixture("GeneralSummaryReportQueryRs.balancesheet.qbxml"));

        try
        {
            await ops["report"].RunAsync(
                new Dictionary<string, object?>
                {
                    ["type"] = "BalanceSheet",
                    ["dateMacro"] = "ThisFiscalYear",
                },
                default);

            var request = XDocument.Parse(fake.ProcessRequests[0]).Root!.Element("QBXMLMsgsRq")!.Element("GeneralSummaryReportQueryRq")!;
            Assert.Equal("BalanceSheetStandard", request.Element("GeneralSummaryReportType")?.Value);
            Assert.Equal("ThisFiscalYear", request.Element("ReportDateMacro")?.Value);
            Assert.Null(request.Element("ReportPeriod"));
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }

    [Fact]
    public async Task report_aging_ar_and_ap()
    {
        {
            var (fake, manager, ops) = OpTestHarness.Create();
            fake.AddResponse("AgingReportQueryRq", OpTestHarness.Fixture("AgingReportQueryRs.ar.qbxml"));

            try
            {
                await ops["report"].RunAsync(
                    new Dictionary<string, object?>
                    {
                        ["type"] = "AgingAR",
                        ["dateMacro"] = "Today",
                    },
                    default);

                var request = XDocument.Parse(fake.ProcessRequests[0]).Root!.Element("QBXMLMsgsRq")!.Element("AgingReportQueryRq")!;
                Assert.Equal("ARAgingSummary", request.Element("AgingReportType")?.Value);
                Assert.Equal("Today", request.Element("ReportDateMacro")?.Value);
            }
            finally
            {
                await manager.DisposeAsync();
            }
        }

        {
            var (fake, manager, ops) = OpTestHarness.Create();
            fake.AddResponse("AgingReportQueryRq", OpTestHarness.Fixture("AgingReportQueryRs.ap.qbxml"));

            try
            {
                await ops["report"].RunAsync(
                    new Dictionary<string, object?>
                    {
                        ["type"] = "AgingAP",
                        ["fromDate"] = "2025-01-01",
                        ["toDate"] = "2025-12-31",
                    },
                    default);

                var request = XDocument.Parse(fake.ProcessRequests[0]).Root!.Element("QBXMLMsgsRq")!.Element("AgingReportQueryRq")!;
                Assert.Equal("APAgingSummary", request.Element("AgingReportType")?.Value);
                Assert.NotNull(request.Element("ReportPeriod"));
            }
            finally
            {
                await manager.DisposeAsync();
            }
        }
    }

    [Fact]
    public async Task report_rejects_bad_date_args()
    {
        var (_, manager, ops) = OpTestHarness.Create();

        try
        {
            await Assert.ThrowsAsync<ArgumentException>(() => ops["report"].RunAsync(
                new Dictionary<string, object?>
                {
                    ["type"] = "ProfitAndLoss",
                },
                default));

            await Assert.ThrowsAsync<ArgumentException>(() => ops["report"].RunAsync(
                new Dictionary<string, object?>
                {
                    ["type"] = "ProfitAndLoss",
                    ["fromDate"] = "2025-01-01",
                    ["toDate"] = "2025-12-31",
                    ["dateMacro"] = "ThisMonth",
                },
                default));

            await Assert.ThrowsAsync<ArgumentException>(() => ops["report"].RunAsync(
                new Dictionary<string, object?>
                {
                    ["type"] = "ProfitAndLoss",
                    ["fromDate"] = "2025-01-01",
                },
                default));

            await Assert.ThrowsAsync<ArgumentException>(() => ops["report"].RunAsync(
                new Dictionary<string, object?>
                {
                    ["type"] = "Bogus",
                    ["dateMacro"] = "ThisMonth",
                },
                default));

            await Assert.ThrowsAsync<ArgumentException>(() => ops["report"].RunAsync(new Dictionary<string, object?>(), default));
        }
        finally
        {
            await manager.DisposeAsync();
        }
    }
}
