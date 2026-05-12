using Microsoft.Extensions.Options;
using System.Globalization;
using System.Xml.Linq;
using QbConnectService.Qb;

namespace QbConnectService.Qb.Ops;

public sealed class CreateJournalEntryOp(
    QbXmlBuilder b,
    QbConnectionManager m,
    QbXmlParser xp,
    QbReportParser rp,
    QbListExecutor le,
    AuditLog audit,
    IOptions<SafetyOptions> safety)
    : WriteOpBase(b, m, xp, rp, le, audit, safety)
{
    public override string Name => "create_journal_entry";

    public override string BuildRequest(IReadOnlyDictionary<string, object?> args)
    {
        var (debits, credits) = Validate(args);

        var add = new XElement("JournalEntryAdd");
        AddDate(add, "TxnDate", ArgReader.Date(args, "txnDate"));
        AddString(add, "RefNumber", ArgReader.String(args, "refNumber"));
        AddString(add, "Memo", ArgReader.String(args, "memo"));
        AddBool(add, "IsAdjustment", ArgReader.Bool(args, "isAdjustment"));

        foreach (var line in debits)
        {
            add.Add(BuildLine("JournalDebitLine", line, "debit"));
        }

        foreach (var line in credits)
        {
            add.Add(BuildLine("JournalCreditLine", line, "credit"));
        }

        return _builder.BuildRequest(QbXmlBuilder.Rq("JournalEntryAddRq", add));
    }

    public override async Task<DryRunResult> DryRunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default)
    {
        var (debits, credits) = Validate(args);
        var qbXml = BuildRequest(args);
        var total = debits.Sum(line => ArgReader.Decimal(line, "amount") ?? 0m);

        var checks = new List<PreFlightCheck>
        {
            new("balanced", true, $"debits = credits = {total.ToString("0.00", CultureInfo.InvariantCulture)}"),
            new("debit-line-count", true, $"{debits.Count}"),
            new("credit-line-count", true, $"{credits.Count}"),
        };
        var resolved = new Dictionary<string, object?>(StringComparer.Ordinal);

        foreach (var (line, label, key) in DebitsAndCredits(debits, credits))
        {
            if (ArgReader.Dict(line, "accountRef") is { } accountRef && ArgReader.String(accountRef, "listID") is { } accountListId)
            {
                resolved[$"{key}.accountRef"] = accountListId;
                continue;
            }

            if (WriteOpHelpers.RefValue(line, "accountRef") is not { } accountName)
            {
                continue;
            }

            var account = await FetchByNameAsync("Account", accountName, ct);
            checks.Add(new PreFlightCheck(
                $"{label}-account-resolves",
                account is not null,
                account is null ? $"no Account '{accountName}'; Add will fail 3140" : "ok"));

            if (account is not null)
            {
                resolved[$"{key}.accountRef"] = account.GetValueOrDefault("ListID");
            }
        }

        return new DryRunResult(
            qbXml,
            $"Create balanced journal entry: {debits.Count} debit + {credits.Count} credit line(s), total {total.ToString("0.00", CultureInfo.InvariantCulture)}.",
            checks,
            resolved,
            AllowWrites);
    }

    private (IReadOnlyList<IReadOnlyDictionary<string, object?>> Debits, IReadOnlyList<IReadOnlyDictionary<string, object?>> Credits) Validate(IReadOnlyDictionary<string, object?> args)
    {
        MultiCurrencyGuard.Reject(args);

        var debits = ArgReader.List(args, "debits")
            ?? throw new ArgumentException("'debits' is required and must be a non-empty array.");
        var credits = ArgReader.List(args, "credits")
            ?? throw new ArgumentException("'credits' is required and must be a non-empty array.");
        if (debits.Count == 0 || credits.Count == 0)
        {
            throw new ArgumentException("create_journal_entry requires at least one debit line and at least one credit line.");
        }

        decimal debitTotal = 0m;
        decimal creditTotal = 0m;

        foreach (var line in debits)
        {
            debitTotal += ArgReader.Decimal(line, "amount")
                ?? throw new ArgumentException("each debit line needs 'amount'.");
        }

        foreach (var line in credits)
        {
            creditTotal += ArgReader.Decimal(line, "amount")
                ?? throw new ArgumentException("each credit line needs 'amount'.");
        }

        if (debitTotal != creditTotal)
        {
            throw new ArgumentException(
                $"journal entry does not balance: debits total {debitTotal.ToString("0.00", CultureInfo.InvariantCulture)}, credits total {creditTotal.ToString("0.00", CultureInfo.InvariantCulture)}.");
        }

        return (debits, credits);
    }

    private static XElement BuildLine(string elementName, IReadOnlyDictionary<string, object?> line, string label)
    {
        var amount = ArgReader.Decimal(line, "amount")
            ?? throw new ArgumentException($"each {label} line needs 'amount'.");

        var element = new XElement(
            elementName,
            WriteOpHelpers.RefElement("AccountRef", line, "accountRef")
                ?? throw new ArgumentException($"each {label} line needs 'accountRef'."),
            new XElement("Amount", amount.ToString("0.00", CultureInfo.InvariantCulture)));

        AddString(element, "Memo", ArgReader.String(line, "memo"));
        AddElement(element, WriteOpHelpers.RefElement("EntityRef", line, "entityRef"));
        AddElement(element, WriteOpHelpers.RefElement("ClassRef", line, "classRef"));
        return element;
    }

    private static IEnumerable<(IReadOnlyDictionary<string, object?> Line, string Label, string Key)> DebitsAndCredits(
        IReadOnlyList<IReadOnlyDictionary<string, object?>> debits,
        IReadOnlyList<IReadOnlyDictionary<string, object?>> credits)
    {
        for (var i = 0; i < debits.Count; i++)
        {
            yield return (debits[i], $"debit-line-{i + 1}", $"debits[{i}]");
        }

        for (var i = 0; i < credits.Count; i++)
        {
            yield return (credits[i], $"credit-line-{i + 1}", $"credits[{i}]");
        }
    }

    private static void AddString(XElement parent, string elementName, string? value)
    {
        if (value is not null)
        {
            parent.Add(new XElement(elementName, value));
        }
    }

    private static void AddBool(XElement parent, string elementName, bool? value)
    {
        if (value is bool b)
        {
            parent.Add(new XElement(elementName, b ? "true" : "false"));
        }
    }

    private static void AddDate(XElement parent, string elementName, DateOnly? value)
    {
        if (value is DateOnly date)
        {
            parent.Add(new XElement(elementName, date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)));
        }
    }

    private static void AddElement(XElement parent, XElement? element)
    {
        if (element is not null)
        {
            parent.Add(element);
        }
    }
}
