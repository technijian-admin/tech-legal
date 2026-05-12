namespace QbConnectService.Qb.Ops;

/// <summary>
/// Reads CompanyRet plus HostRet metadata. CompanyRet does not carry the QuickBooks edition string, so
/// HostRet.ProductName is the authoritative source. Phase 9 re-pins the exact ProductName format.
/// </summary>
public sealed class CompanyInfoOp(
    QbXmlBuilder b,
    QbConnectionManager m,
    QbXmlParser xp,
    QbReportParser rp,
    QbListExecutor le) : ReadOpBase(b, m, xp, rp, le)
{
    public override string Name => "company_info";

    public override async Task<object?> RunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default)
    {
        var parsed = await QuerySingleAsync(
            [
                QbXmlBuilder.Rq("HostQueryRq"),
                QbXmlBuilder.Rq("CompanyQueryRq"),
            ],
            ct);

        var hostRs = parsed.Elements.First(element => element.Name == "HostQueryRs");
        var companyRs = parsed.Elements.First(element => element.Name == "CompanyQueryRs");
        var host = hostRs.Rows.FirstOrDefault() ?? new Dictionary<string, object?>(StringComparer.Ordinal);
        var company = companyRs.Rows.FirstOrDefault() ?? new Dictionary<string, object?>(StringComparer.Ordinal);

        return new Dictionary<string, object?>
        {
            ["status"] = companyRs.Status,
            ["companyName"] = company.GetValueOrDefault("CompanyName"),
            ["legalCompanyName"] = company.GetValueOrDefault("LegalCompanyName"),
            ["address"] = company.GetValueOrDefault("Address"),
            ["legalAddress"] = company.GetValueOrDefault("LegalAddress"),
            ["phone"] = company.GetValueOrDefault("Phone"),
            ["email"] = company.GetValueOrDefault("Email"),
            ["fiscalYearStartMonth"] = company.GetValueOrDefault("FirstMonthFiscalYear"),
            ["incomeTaxYearStartMonth"] = company.GetValueOrDefault("FirstMonthIncomeTaxYear"),
            ["taxForm"] = company.GetValueOrDefault("TaxForm"),
            ["companyType"] = company.GetValueOrDefault("CompanyType"),
            ["edition"] = host.GetValueOrDefault("ProductName"),
            ["quickBooksMajorVersion"] = host.GetValueOrDefault("MajorVersion"),
            ["quickBooksMinorVersion"] = host.GetValueOrDefault("MinorVersion"),
            ["country"] = host.GetValueOrDefault("Country"),
            ["supportedQbXmlVersions"] = host.GetValueOrDefault("SupportedQBXMLVersionList"),
            ["rawCompanyRet"] = company,
            ["rawHostRet"] = host,
        };
    }
}
