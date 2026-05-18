namespace QbConnectService.Qb;

/// <summary>
/// Per-company configuration entry under Qb.Companies. Each entry represents one .QBW file
/// the service can talk to. Switching between companies is by config key (see QbCompanyContext).
/// </summary>
public sealed class QbCompany
{
    public string CompanyFilePath { get; set; } = string.Empty;

    public string AppId { get; set; } = string.Empty;

    public string AppName { get; set; } = "QbConnectService";
}
