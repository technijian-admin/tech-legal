namespace QbConnectService.Qb;

public sealed class QbOptions
{
    /// <summary>Legacy single-tenant path. Used as the fallback default company if Companies is empty.</summary>
    public string CompanyFilePath { get; set; } = string.Empty;

    /// <summary>Legacy single-tenant AppId. Used as the fallback default company if Companies is empty.</summary>
    public string AppId { get; set; } = string.Empty;

    /// <summary>Legacy single-tenant AppName. Used as the fallback default company if Companies is empty.</summary>
    public string AppName { get; set; } = "QbConnectService";

    public QbConnectionType ConnectionType { get; set; } = QbConnectionType.LocalQBD;

    public QbFileMode OpenMode { get; set; } = QbFileMode.DoNotCare;

    /// <summary>
    /// When true (default), every successful request ends with EndSession + CloseConnection so the
    /// .qbw file is released as soon as the work is done. This lets a human at QB Desktop on the
    /// server console close/switch the company file without first stopping the service. The next
    /// request pays a ~500ms-1s reconnect cost. Set to false only when you have a tight request
    /// loop where the persistent-session pattern's reconnect-savings matter more than the
    /// "file-free between requests" property.
    /// </summary>
    public bool ReleaseAfterEachRequest { get; set; } = true;

    /// <summary>
    /// When true (default), the service self-heals from "QBW.EXE is stuck" errors by killing the
    /// existing QBW.EXE process and retrying the request once. The retry cold-starts a fresh
    /// QuickBooks Desktop on the requested company file. Triggers on:
    ///   * 0x8004040A QB_DIFFERENT_FILE_OPEN (caller asked for a different .qbw than QBW.EXE has)
    ///   * 0x80040414 QB_MODAL_DIALOG (an interactive popup is blocking the SDK)
    ///   * 0x80010105 RPC_E_SERVERFAULT (COM server faulted)
    /// Per the Intuit QB SDK 16.0 Programmer's Guide ("Limitations on Accessing Company Files",
    /// p.53), only one company file is accessible per machine and there is no "switch file" SDK
    /// API - terminating QBW.EXE is the documented escape hatch.
    /// </summary>
    public bool AutoRecoverFromQbwStuck { get; set; } = true;

    /// <summary>
    /// When true (default) AND AutoRecoverFromQbwStuck is true, the recovery path refuses to kill
    /// QBW.EXE if any QBW.EXE has a visible window (a human is RDP'd in and using QB Desktop
    /// interactively). Returns a 409 Conflict to the caller with a clear remediation hint instead.
    /// Set to false to force-kill regardless - only safe if you're sure no human session exists.
    /// </summary>
    public bool AbortRecoveryIfInteractiveQbDesktop { get; set; } = true;

    /// <summary>
    /// Rolling-1-minute kill-rate ceiling. If the recovery path would exceed this, it refuses to
    /// kill (returns a 503 to the caller and asks for manual intervention). Prevents kill-loops
    /// if an underlying bug keeps producing recoverable errors.
    /// </summary>
    public int MaxQbwKillsPerMinute { get; set; } = 3;

    /// <summary>How long to wait for QBW.EXE processes to actually exit after Kill(). Default 10s.</summary>
    public int QbwKillExitTimeoutSeconds { get; set; } = 10;

    /// <summary>Multi-tenant entries keyed by short company id (e.g. "technijian-pvt-ltd").</summary>
    public Dictionary<string, QbCompany> Companies { get; set; } = new(StringComparer.OrdinalIgnoreCase);

    /// <summary>Key in Companies to use when a request omits ?company= (or X-Qb-Company).</summary>
    public string DefaultCompany { get; set; } = string.Empty;

    /// <summary>
    /// Resolve a company key to its (key, QbCompany) pair. Resolution order:
    ///   1. If companyKey is non-empty and in Companies, return it.
    ///   2. If companyKey is empty/null and DefaultCompany is non-empty and in Companies, return DefaultCompany.
    ///   3. Fallback to the legacy single-tenant fields (CompanyFilePath/AppId/AppName) under the synthetic key "default".
    /// Throws ArgumentException if companyKey is provided but unknown.
    /// </summary>
    public (string Key, QbCompany Company) ResolveCompany(string? companyKey)
    {
        if (!string.IsNullOrWhiteSpace(companyKey))
        {
            if (Companies.TryGetValue(companyKey, out var c))
            {
                return (companyKey, c);
            }
            throw new ArgumentException($"Unknown company '{companyKey}'. Known: {string.Join(", ", Companies.Keys.OrderBy(k => k, StringComparer.Ordinal))}.");
        }

        if (!string.IsNullOrWhiteSpace(DefaultCompany) && Companies.TryGetValue(DefaultCompany, out var def))
        {
            return (DefaultCompany, def);
        }

        return ("default", new QbCompany
        {
            CompanyFilePath = CompanyFilePath,
            AppId = AppId,
            AppName = AppName,
        });
    }
}

public sealed class RequestOptions
{
    public int TimeoutSeconds { get; set; } = 60;

    public int BusyWaitSeconds { get; set; } = 10;
}
