using System.Diagnostics.CodeAnalysis;

namespace QbConnectService.Qb.Ops;

/// <summary>
/// Read-op registry keyed by IReadOp.Name. Phase 5 dispatches only IReadOp instances; Phase 7 can widen the
/// registry shape when write ops arrive.
/// </summary>
public sealed class OpRegistry
{
    private readonly IReadOnlyDictionary<string, IReadOp> _byName;

    public OpRegistry(IEnumerable<IReadOp> ops)
    {
        var byName = new Dictionary<string, IReadOp>(StringComparer.Ordinal);
        foreach (var op in ops)
        {
            if (!byName.TryAdd(op.Name, op))
            {
                throw new InvalidOperationException($"Duplicate op name '{op.Name}'.");
            }
        }

        _byName = byName;
    }

    public IReadOnlyCollection<string> Names => _byName.Keys.ToArray();

    public bool TryGet(string name, [NotNullWhen(true)] out IReadOp? op) => _byName.TryGetValue(name, out op);
}
