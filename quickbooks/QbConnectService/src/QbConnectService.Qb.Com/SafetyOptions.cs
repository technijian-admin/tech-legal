namespace QbConnectService.Qb;

public sealed class SafetyOptions
{
    /// <summary>
    /// Default-off write gate. Phase 5 enforces it only on /api/qbxml's verb-scan; Phase 6 adds the in-depth
    /// ops-controller + connection-manager enforcement and the /dryrun endpoint.
    /// </summary>
    public bool AllowWrites { get; set; } = false;
}
