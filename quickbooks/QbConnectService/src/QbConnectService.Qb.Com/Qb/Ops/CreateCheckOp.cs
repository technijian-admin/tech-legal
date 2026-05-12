using Microsoft.Extensions.Options;
using System.Xml.Linq;
using QbConnectService.Qb;

namespace QbConnectService.Qb.Ops;

public sealed class CreateCheckOp(
    QbXmlBuilder b,
    QbConnectionManager m,
    QbXmlParser xp,
    QbReportParser rp,
    QbListExecutor le,
    AuditLog audit,
    IOptions<SafetyOptions> safety)
    : WriteOpBase(b, m, xp, rp, le, audit, safety)
{
    public override string Name => "create_check";

    public override string BuildRequest(IReadOnlyDictionary<string, object?> args)
    {
        MultiCurrencyGuard.Reject(args);

        var add = new XElement("CheckAdd");
        add.Add(WriteOpHelpers.RefElement("AccountRef", args, "accountRef")
            ?? throw new ArgumentException("'accountRef' (the bank account to draw the check from) is required."));
        AddElement(add, WriteOpHelpers.RefElement("PayeeEntityRef", args, "payeeEntityRef"));
        AddString(add, "RefNumber", ArgReader.String(args, "refNumber"));
        AddDate(add, "TxnDate", ArgReader.Date(args, "txnDate"));
        AddString(add, "Memo", ArgReader.String(args, "memo"));
        AddElement(add, WriteOpHelpers.AddressElement("Address", ArgReader.Dict(args, "address")));
        AddBool(add, "IsToBePrinted", ArgReader.Bool(args, "isToBePrinted"));
        AddBool(add, "IsTaxIncluded", ArgReader.Bool(args, "isTaxIncluded"));
        AddElement(add, WriteOpHelpers.RefElement("SalesTaxCodeRef", args, "salesTaxCodeRef"));

        var expenseLines = ArgReader.List(args, "expenseLines");
        var itemLines = ArgReader.List(args, "itemLines");
        if ((expenseLines is null || expenseLines.Count == 0) && (itemLines is null || itemLines.Count == 0))
        {
            throw new ArgumentException("create_check requires at least one entry in 'expenseLines' or 'itemLines'.");
        }

        foreach (var line in expenseLines ?? Array.Empty<IReadOnlyDictionary<string, object?>>())
        {
            add.Add(WriteOpHelpers.ExpenseLineAdd(line));
        }

        foreach (var line in itemLines ?? Array.Empty<IReadOnlyDictionary<string, object?>>())
        {
            add.Add(WriteOpHelpers.ItemLineAdd(line));
        }

        return _builder.BuildRequest(QbXmlBuilder.Rq("CheckAddRq", add));
    }

    public override async Task<DryRunResult> DryRunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default)
    {
        var qbXml = BuildRequest(args);
        var expenseLines = ArgReader.List(args, "expenseLines");
        var itemLines = ArgReader.List(args, "itemLines");
        var expenseCount = expenseLines?.Count ?? 0;
        var itemCount = itemLines?.Count ?? 0;

        var checks = new List<PreFlightCheck>
        {
            new("expense-line-count", true, $"{expenseCount}"),
            new("item-line-count", true, $"{itemCount}"),
        };
        var resolved = new Dictionary<string, object?>(StringComparer.Ordinal);

        if (ArgReader.Dict(args, "accountRef") is { } accountRef && ArgReader.String(accountRef, "listID") is { } accountListId)
        {
            resolved["accountRef"] = accountListId;
        }
        else if (WriteOpHelpers.RefValue(args, "accountRef") is { } accountName)
        {
            var account = await FetchByNameAsync("Account", accountName, ct);
            checks.Add(new PreFlightCheck(
                "bank-account-resolves",
                account is not null,
                account is null ? $"no Account '{accountName}'; Add will fail 3140" : "ok"));

            if (account is not null)
            {
                resolved["accountRef"] = account.GetValueOrDefault("ListID");
            }
        }

        if (ArgReader.Dict(args, "payeeEntityRef") is { } payeeRef && ArgReader.String(payeeRef, "listID") is { } payeeListId)
        {
            resolved["payeeEntityRef"] = payeeListId;
        }
        else if (WriteOpHelpers.RefValue(args, "payeeEntityRef") is { } payeeName)
        {
            var vendor = await FetchByNameAsync("Vendor", payeeName, ct);
            checks.Add(new PreFlightCheck(
                "payee-entity-resolves",
                vendor is not null,
                vendor is null ? $"no Vendor '{payeeName}'" : "ok"));

            if (vendor is not null)
            {
                resolved["payeeEntityRef"] = vendor.GetValueOrDefault("ListID");
            }
        }

        if (expenseLines is not null)
        {
            for (var i = 0; i < expenseLines.Count; i++)
            {
                var line = expenseLines[i];
                if (ArgReader.Dict(line, "accountRef") is { } lineAccountRef && ArgReader.String(lineAccountRef, "listID") is { } lineAccountListId)
                {
                    resolved[$"expenseLines[{i}].accountRef"] = lineAccountListId;
                    continue;
                }

                if (WriteOpHelpers.RefValue(line, "accountRef") is not { } lineAccountName)
                {
                    continue;
                }

                var account = await FetchByNameAsync("Account", lineAccountName, ct);
                checks.Add(new PreFlightCheck(
                    $"expense-line-{i + 1}-account-resolves",
                    account is not null,
                    account is null ? $"no Account '{lineAccountName}'; Add will fail 3140" : "ok"));

                if (account is not null)
                {
                    resolved[$"expenseLines[{i}].accountRef"] = account.GetValueOrDefault("ListID");
                }
            }
        }

        if (itemLines is not null)
        {
            for (var i = 0; i < itemLines.Count; i++)
            {
                var line = itemLines[i];
                if (ArgReader.Dict(line, "itemRef") is { } itemRef && ArgReader.String(itemRef, "listID") is { } itemListId)
                {
                    resolved[$"itemLines[{i}].itemRef"] = itemListId;
                    continue;
                }

                if (WriteOpHelpers.RefValue(line, "itemRef") is not { } itemName)
                {
                    continue;
                }

                var item = await FetchByNameAsync("Item", itemName, ct);
                checks.Add(new PreFlightCheck(
                    $"item-line-{i + 1}-item-resolves",
                    item is not null,
                    item is null ? $"no Item '{itemName}'; Add will fail 3140" : "ok"));

                if (item is not null)
                {
                    resolved[$"itemLines[{i}].itemRef"] = item.GetValueOrDefault("ListID");
                }
            }
        }

        return new DryRunResult(
            qbXml,
            $"Create check #{ArgReader.String(args, "refNumber") ?? "(auto)"} from {WriteOpHelpers.RefValue(args, "accountRef")} ({expenseCount} expense + {itemCount} item line(s)).",
            checks,
            resolved,
            AllowWrites);
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
            parent.Add(new XElement(elementName, date.ToString("yyyy-MM-dd")));
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
