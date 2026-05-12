using System.Xml.Linq;

namespace QbConnectService.Qb.Ops;

public sealed class ListCustomersOp(
    QbXmlBuilder b,
    QbConnectionManager m,
    QbXmlParser xp,
    QbReportParser rp,
    QbListExecutor le) : ReadOpBase(b, m, xp, rp, le)
{
    public override string Name => "list_customers";

    public override async Task<object?> RunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default)
    {
        var rq = QbXmlBuilder.Rq("CustomerQueryRq");
        rq.Add(EntityListFilters.ActiveStatusElement(args));

        if (EntityListFilters.NameFilterElement(args) is { } nameFilter)
        {
            rq.Add(nameFilter);
        }

        var parsed = await QueryListAsync(rq, ownerIdZero: null, ct);
        return ListResult(parsed);
    }
}

internal static class EntityListFilters
{
    public static XElement ActiveStatusElement(IReadOnlyDictionary<string, object?> args)
    {
        var normalized = (ArgReader.String(args, "activeStatus") ?? "All") switch
        {
            var value when value.Equals("Active", StringComparison.OrdinalIgnoreCase) => "ActiveOnly",
            var value when value.Equals("ActiveOnly", StringComparison.OrdinalIgnoreCase) => "ActiveOnly",
            var value when value.Equals("Inactive", StringComparison.OrdinalIgnoreCase) => "InactiveOnly",
            var value when value.Equals("InactiveOnly", StringComparison.OrdinalIgnoreCase) => "InactiveOnly",
            var value when value.Equals("All", StringComparison.OrdinalIgnoreCase) => "All",
            var value => throw new ArgumentException($"activeStatus '{value}' is not supported. Use Active, Inactive, or All."),
        };

        return new XElement("ActiveStatus", normalized);
    }

    public static XElement? NameFilterElement(IReadOnlyDictionary<string, object?> args)
    {
        var name = ArgReader.String(args, "name");
        if (string.IsNullOrWhiteSpace(name))
        {
            return null;
        }

        return new XElement(
            "NameFilter",
            new XElement("MatchCriterion", ArgReader.String(args, "nameMatch") ?? "Contains"),
            new XElement("Name", name));
    }
}
