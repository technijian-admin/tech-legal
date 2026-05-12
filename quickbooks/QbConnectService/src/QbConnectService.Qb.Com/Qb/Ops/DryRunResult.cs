namespace QbConnectService.Qb.Ops;

public sealed record DryRunResult(
    string QbXml,
    string Summary,
    IReadOnlyList<PreFlightCheck> PreFlight,
    IReadOnlyDictionary<string, object?> ResolvedReferences,
    bool AllowWrites);

public sealed record PreFlightCheck(string Name, bool Ok, string? Detail);
