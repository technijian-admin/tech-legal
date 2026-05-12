using System.Collections;
using System.Xml;
using System.Xml.Linq;

namespace QbConnectService.Qb.Ops;

/// <summary>
/// Generic read-only query op over a vetted whitelist. First-class entities such as Customer, Vendor, Item,
/// Account, Invoice, Bill, ReceivePayment, and Transaction remain allowed here, but callers should prefer the
/// dedicated read ops. Company, Host, and Preferences are single-shot; all other entities go through
/// QbListExecutor. V2-01 may promote more entities to first-class ops.
/// </summary>
public sealed class RunQueryOp(
    QbXmlBuilder b,
    QbConnectionManager m,
    QbXmlParser xp,
    QbReportParser rp,
    QbListExecutor le) : ReadOpBase(b, m, xp, rp, le)
{
    private static readonly HashSet<string> Allowed = new(StringComparer.Ordinal)
    {
        "Employee",
        "OtherName",
        "SalesRep",
        "Class",
        "Term",
        "PriceLevel",
        "PaymentMethod",
        "ShipMethod",
        "Currency",
        "SalesTaxCode",
        "Vehicle",
        "SalesReceipt",
        "Estimate",
        "PurchaseOrder",
        "CreditMemo",
        "SalesOrder",
        "Deposit",
        "Check",
        "BillPaymentCheck",
        "BillPaymentCreditCard",
        "CreditCardCharge",
        "CreditCardCredit",
        "JournalEntry",
        "InventoryAdjustment",
        "TimeTracking",
        "VendorCredit",
        "ItemReceipt",
        "Customer",
        "Vendor",
        "Item",
        "Account",
        "Invoice",
        "Bill",
        "ReceivePayment",
        "Transaction",
        "ToDo",
        "Company",
        "Host",
        "Preferences",
    };

    public override string Name => "run_query";

    public override async Task<object?> RunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default)
    {
        var entity = ArgReader.String(args, "entity")
            ?? throw new ArgumentException("run_query: 'entity' is required.");

        if (!Allowed.Contains(entity))
        {
            throw new ArgumentException(
                $"run_query: entity '{entity}' is not allowed. Allowed: {string.Join(", ", Allowed.OrderBy(x => x))}");
        }

        var rq = QbXmlBuilder.Rq(entity + "QueryRq");
        if (ArgReader.Dict(args, "filters") is { } filters)
        {
            AddFilters(rq, filters);
        }

        var noIter = entity is "Company" or "Host" or "Preferences";
        var parsed = noIter
            ? await QuerySingleAsync(rq, ct)
            : await QueryListAsync(rq, ownerIdZero: null, ct);

        return new Dictionary<string, object?>
        {
            ["entity"] = entity,
            ["status"] = parsed.First.Status,
            ["rows"] = parsed.First.Rows,
            ["count"] = parsed.First.Rows.Count,
            ["rawSpilledTo"] = parsed.RawSpilledTo,
        };
    }

    private static void AddFilters(XElement parent, IReadOnlyDictionary<string, object?> filters)
    {
        foreach (var (key, value) in filters)
        {
            EnsureValidKey(key);

            if (AsDictionary(value) is { } nested)
            {
                var child = CreateElement(key);
                AddFilters(child, nested);
                parent.Add(child);
                continue;
            }

            if (value is IEnumerable enumerable && value is not string)
            {
                foreach (var item in enumerable)
                {
                    if (AsDictionary(item) is { } itemDict)
                    {
                        var child = CreateElement(key);
                        AddFilters(child, itemDict);
                        parent.Add(child);
                    }
                    else
                    {
                        parent.Add(CreateElement(key, ToStringValue(item)));
                    }
                }

                continue;
            }

            parent.Add(CreateElement(key, ToStringValue(value)));
        }
    }

    private static IReadOnlyDictionary<string, object?>? AsDictionary(object? value) =>
        value switch
        {
            IReadOnlyDictionary<string, object?> readOnly => readOnly,
            IDictionary<string, object?> dict => new Dictionary<string, object?>(dict, StringComparer.Ordinal),
            _ => null,
        };

    private static void EnsureValidKey(string key)
    {
        if (string.IsNullOrWhiteSpace(key) ||
            key.Contains('/') ||
            key.Contains('<') ||
            key.Contains('>') ||
            key.Contains(':') ||
            key.Any(char.IsWhiteSpace))
        {
            throw new ArgumentException($"run_query: filter key '{key}' is not allowed.");
        }
    }

    private static XElement CreateElement(string key, object? value = null)
    {
        try
        {
            return value is null ? new XElement(key) : new XElement(key, value);
        }
        catch (Exception exception) when (exception is ArgumentException or XmlException)
        {
            throw new ArgumentException($"run_query: filter key '{key}' is not allowed.", exception);
        }
    }

    private static string? ToStringValue(object? value) =>
        value switch
        {
            null => null,
            DateOnly date => date.ToString("yyyy-MM-dd"),
            DateTime dateTime => dateTime.ToString("yyyy-MM-dd"),
            bool b => b ? "true" : "false",
            _ => value.ToString(),
        };
}
