namespace QbConnectService.Qb;

public sealed class QbOptions
{
    public string CompanyFilePath { get; set; } = string.Empty;

    public string AppId { get; set; } = string.Empty;

    public string AppName { get; set; } = "QbConnectService";

    public bool OwnerIdZero { get; set; }

    public QbConnectionType ConnectionType { get; set; } = QbConnectionType.LocalQBD;

    public QbFileMode OpenMode { get; set; } = QbFileMode.DoNotCare;
}

public sealed class RequestOptions
{
    public int TimeoutSeconds { get; set; } = 60;

    public int BusyWaitSeconds { get; set; } = 10;
}
