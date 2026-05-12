namespace QbConnectService.Qb;

public sealed class QbXmlOptions
{
    public string Version { get; set; } = "16.0";

    public bool OwnerIdZero { get; set; }

    public int MaxReturned { get; set; } = 100;

    public int MaxResponseBytes { get; set; } = 5_000_000;

    public string SpillPath { get; set; } = string.Empty;
}
