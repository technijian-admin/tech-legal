namespace QbConnectService;

public sealed class ServerOptions
{
    public string BindUrls { get; set; } = "https://+:8443";

    /// <summary>
    /// Path to the server TLS .pfx. When empty, a development self-signed cert is used (UseHttps() with no args).
    /// Production MUST set this; see quickbooks/QbConnectService/deploy/make-cert.ps1 and
    /// quickbooks/QbConnectService/README.md.
    /// </summary>
    public string? CertPath { get; set; }

    public string? CertPassword { get; set; }

    /// <summary>
    /// Kestrel request-body size limit for /api/qbxml etc.; distinct from QbXml:MaxResponseBytes which is the
    /// response spill threshold.
    /// </summary>
    public long MaxRequestBodyBytes { get; set; } = 5_000_000;
}
