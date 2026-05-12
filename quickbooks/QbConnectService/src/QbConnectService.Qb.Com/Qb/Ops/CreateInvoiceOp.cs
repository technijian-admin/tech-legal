using Microsoft.Extensions.Options;
using System.Globalization;
using System.Xml.Linq;
using QbConnectService.Qb;

namespace QbConnectService.Qb.Ops;

public sealed class CreateInvoiceOp(
    QbXmlBuilder b,
    QbConnectionManager m,
    QbXmlParser xp,
    QbReportParser rp,
    QbListExecutor le,
    AuditLog audit,
    IOptions<SafetyOptions> safety)
    : WriteOpBase(b, m, xp, rp, le, audit, safety)
{
    public override string Name => "create_invoice";

    public override string BuildRequest(IReadOnlyDictionary<string, object?> args)
    {
        MultiCurrencyGuard.Reject(args);

        var add = new XElement("InvoiceAdd");
        add.Add(WriteOpHelpers.RefElement("CustomerRef", args, "customerRef")
            ?? throw new ArgumentException("'customerRef' is required."));
        AddElement(add, WriteOpHelpers.RefElement("ClassRef", args, "classRef"));
        AddElement(add, WriteOpHelpers.RefElement("ARAccountRef", args, "arAccountRef"));
        AddElement(add, WriteOpHelpers.RefElement("TemplateRef", args, "templateRef"));
        AddDate(add, "TxnDate", ArgReader.Date(args, "txnDate"));
        AddString(add, "RefNumber", ArgReader.String(args, "refNumber"));
        AddElement(add, WriteOpHelpers.AddressElement("BillAddress", ArgReader.Dict(args, "billAddress")));
        AddElement(add, WriteOpHelpers.AddressElement("ShipAddress", ArgReader.Dict(args, "shipAddress")));
        AddBool(add, "IsPending", ArgReader.Bool(args, "isPending"));
        AddString(add, "PONumber", ArgReader.String(args, "poNumber"));
        AddElement(add, WriteOpHelpers.RefElement("TermsRef", args, "terms"));
        AddDate(add, "DueDate", ArgReader.Date(args, "dueDate"));
        AddElement(add, WriteOpHelpers.RefElement("SalesRepRef", args, "salesRepRef"));
        AddString(add, "FOB", ArgReader.String(args, "fob"));
        AddDate(add, "ShipDate", ArgReader.Date(args, "shipDate"));
        AddElement(add, WriteOpHelpers.RefElement("ShipMethodRef", args, "shipMethodRef"));
        AddElement(add, WriteOpHelpers.RefElement("ItemSalesTaxRef", args, "itemSalesTaxRef"));
        AddString(add, "Memo", ArgReader.String(args, "memo"));
        AddElement(add, WriteOpHelpers.RefElement("CustomerMsgRef", args, "customerMsgRef"));
        AddBool(add, "IsToBePrinted", ArgReader.Bool(args, "isToBePrinted"));
        AddBool(add, "IsToBeEmailed", ArgReader.Bool(args, "isToBeEmailed"));
        AddBool(add, "IsTaxIncluded", ArgReader.Bool(args, "isTaxIncluded"));
        AddElement(add, WriteOpHelpers.RefElement("CustomerSalesTaxCodeRef", args, "customerSalesTaxCodeRef"));
        AddString(add, "Other", ArgReader.String(args, "other"));

        var lines = ArgReader.List(args, "lines")
            ?? throw new ArgumentException("'lines' is required and must be a non-empty array of line items.");
        if (lines.Count == 0)
        {
            throw new ArgumentException("'lines' must contain at least one line item.");
        }

        for (var i = 0; i < lines.Count; i++)
        {
            add.Add(BuildLine(lines[i], i));
        }

        return _builder.BuildRequest(QbXmlBuilder.Rq("InvoiceAddRq", add));
    }

    public override async Task<DryRunResult> DryRunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default)
    {
        var qbXml = BuildRequest(args);
        var lines = ArgReader.List(args, "lines")
            ?? throw new ArgumentException("'lines' is required and must be a non-empty array of line items.");

        var checks = new List<PreFlightCheck>
        {
            new("line-count", true, $"{lines.Count} line(s)"),
        };
        var resolved = new Dictionary<string, object?>(StringComparer.Ordinal);

        if (ArgReader.Dict(args, "customerRef") is { } customerRef && ArgReader.String(customerRef, "listID") is { } customerListId)
        {
            resolved["customerRef"] = customerListId;
        }
        else if (WriteOpHelpers.RefValue(args, "customerRef") is { } customerName)
        {
            var customer = await FetchByNameAsync("Customer", customerName, ct);
            checks.Add(new PreFlightCheck(
                "customer-resolves",
                customer is not null,
                customer is null ? $"no Customer '{customerName}'; Add will fail 3140" : "ok"));

            if (customer is not null)
            {
                resolved["customerRef"] = customer.GetValueOrDefault("ListID");
            }
        }

        for (var i = 0; i < lines.Count; i++)
        {
            var line = lines[i];
            if (ArgReader.Dict(line, "itemRef") is { } itemRef && ArgReader.String(itemRef, "listID") is { } itemListId)
            {
                resolved[$"lines[{i}].itemRef"] = itemListId;
                continue;
            }

            if (WriteOpHelpers.RefValue(line, "itemRef") is not { } itemName)
            {
                continue;
            }

            var item = await FetchByNameAsync("Item", itemName, ct);
            checks.Add(new PreFlightCheck(
                $"line-{i + 1}-item-resolves",
                item is not null,
                item is null ? $"no Item '{itemName}'; Add will fail 3140" : "ok"));

            if (item is not null)
            {
                resolved[$"lines[{i}].itemRef"] = item.GetValueOrDefault("ListID");
            }
        }

        return new DryRunResult(
            qbXml,
            $"Create invoice for {WriteOpHelpers.RefValue(args, "customerRef")} with {lines.Count} line(s).",
            checks,
            resolved,
            AllowWrites);
    }

    private static XElement BuildLine(IReadOnlyDictionary<string, object?> line, int index)
    {
        var element = new XElement("InvoiceLineAdd");
        element.Add(WriteOpHelpers.RefElement("ItemRef", line, "itemRef")
            ?? throw new ArgumentException($"'lines[{index}].itemRef' is required."));
        AddString(element, "Desc", ArgReader.String(line, "desc"));
        AddDecimal(element, "Quantity", ArgReader.Decimal(line, "quantity"), "0.#####");
        AddString(element, "UnitOfMeasure", ArgReader.String(line, "unitOfMeasure"));

        if (ArgReader.Decimal(line, "rate") is { } rate)
        {
            element.Add(new XElement("Rate", rate.ToString("0.00", CultureInfo.InvariantCulture)));
        }
        else if (ArgReader.Decimal(line, "amount") is { } amount)
        {
            element.Add(new XElement("Amount", amount.ToString("0.00", CultureInfo.InvariantCulture)));
        }

        AddElement(element, WriteOpHelpers.RefElement("PriceLevelRef", line, "priceLevelRef"));
        AddElement(element, WriteOpHelpers.RefElement("ClassRef", line, "classRef"));
        AddDate(element, "ServiceDate", ArgReader.Date(line, "serviceDate"));
        AddElement(element, WriteOpHelpers.RefElement("SalesTaxCodeRef", line, "salesTaxCodeRef"));
        return element;
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

    private static void AddDecimal(XElement parent, string elementName, decimal? value, string format)
    {
        if (value is decimal amount)
        {
            parent.Add(new XElement(elementName, amount.ToString(format, CultureInfo.InvariantCulture)));
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
