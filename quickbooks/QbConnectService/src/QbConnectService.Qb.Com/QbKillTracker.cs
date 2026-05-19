namespace QbConnectService.Qb;

/// <summary>
/// Rolling-window circuit breaker for QBW.EXE kills. Tracks kill timestamps and refuses
/// further kills once the count within the last minute exceeds the configured ceiling.
/// Prevents a kill-loop if some underlying bug keeps producing recoverable errors.
/// Thread-safe; intended to be called from inside <see cref="QbConnectionManager"/>'s
/// gate so the kill rate matches actual request rate.
/// </summary>
public sealed class QbKillTracker
{
    private readonly object _lock = new();
    private readonly List<DateTimeOffset> _kills = new();
    private readonly TimeSpan _window = TimeSpan.FromMinutes(1);

    /// <summary>Number of kills recorded in the last minute (after pruning).</summary>
    public int RecentKills
    {
        get
        {
            lock (_lock)
            {
                Prune();
                return _kills.Count;
            }
        }
    }

    /// <summary>Returns true if a kill is allowed under the cap (defaults to 3 per minute).</summary>
    public bool CanKill(int maxPerMinute)
    {
        lock (_lock)
        {
            Prune();
            return _kills.Count < Math.Max(1, maxPerMinute);
        }
    }

    /// <summary>Record a kill that just succeeded.</summary>
    public void RecordKill()
    {
        lock (_lock)
        {
            _kills.Add(DateTimeOffset.UtcNow);
        }
    }

    private void Prune()
    {
        var cutoff = DateTimeOffset.UtcNow - _window;
        _kills.RemoveAll(t => t < cutoff);
    }
}
