namespace QbConnectService.Qb.Ops;

public interface IReadOp
{
    string Name { get; }

    Task<object?> RunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default);
}
