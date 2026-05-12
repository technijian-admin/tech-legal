using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Options;

namespace QbConnectService.Qb;

public sealed class QbResponseSpiller
{
    private readonly QbXmlOptions _opts;
    private readonly string? _auditPath;

    public QbResponseSpiller(IOptions<QbXmlOptions> opts, IConfiguration config)
    {
        _opts = opts.Value;
        _auditPath = config["Audit:Path"];
    }

    public int Threshold => _opts.MaxResponseBytes;

    public bool ExceedsThreshold(string raw) => System.Text.Encoding.UTF8.GetByteCount(raw) > _opts.MaxResponseBytes;

    public async Task<string> SpillAsync(string rawQbXml, CancellationToken ct = default)
    {
        var directory = !string.IsNullOrWhiteSpace(_opts.SpillPath)
            ? _opts.SpillPath
            : !string.IsNullOrWhiteSpace(_auditPath)
                ? _auditPath
                : Path.Combine(Path.GetTempPath(), "QbConnectService", "spill");

        Directory.CreateDirectory(directory);

        var filePath = Path.Combine(directory, $"{DateTime.UtcNow:yyyyMMdd-HHmmssfff}-{Guid.NewGuid():N}.qbxml");
        await File.WriteAllTextAsync(filePath, rawQbXml, ct);
        return filePath;
    }
}
