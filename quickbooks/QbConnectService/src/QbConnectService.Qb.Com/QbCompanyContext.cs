namespace QbConnectService.Qb;

/// <summary>
/// AsyncLocal-backed per-request company selector. The HTTP endpoints set Current from the
/// 'company' query parameter (or X-Qb-Company header) before calling into the op layer, and
/// QbConnectionManager reads it to pick which company file to open. Null means "use the
/// configured default" (Qb.DefaultCompany, or the legacy Qb.CompanyFilePath fallback).
/// </summary>
public static class QbCompanyContext
{
    private static readonly AsyncLocal<string?> _current = new();

    public static string? Current
    {
        get => _current.Value;
        set => _current.Value = value;
    }

    public static IDisposable Push(string? companyKey)
    {
        var previous = _current.Value;
        _current.Value = companyKey;
        return new Resetter(previous);
    }

    private sealed class Resetter : IDisposable
    {
        private readonly string? _previous;
        private bool _disposed;
        public Resetter(string? previous) { _previous = previous; }
        public void Dispose()
        {
            if (_disposed) return;
            _disposed = true;
            _current.Value = _previous;
        }
    }
}
