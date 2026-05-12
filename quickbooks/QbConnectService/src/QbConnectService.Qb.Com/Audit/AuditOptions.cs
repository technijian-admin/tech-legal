namespace QbConnectService.Qb;

/// <summary>
/// Directory for the append-only audit log; the file is &lt;Path&gt;/audit.jsonl. Bound from the `Audit`
/// config section. Blank falls back to %TEMP%\QbConnectService\audit.
/// </summary>
public sealed class AuditOptions
{
    public string Path { get; set; } = string.Empty;
}
