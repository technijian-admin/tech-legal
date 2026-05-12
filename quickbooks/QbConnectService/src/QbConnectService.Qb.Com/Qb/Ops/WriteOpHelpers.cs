using System.Globalization;
using System.Xml.Linq;

namespace QbConnectService.Qb.Ops;

internal static class WriteOpHelpers
{
    public static XElement? RefElement(string elementName, IReadOnlyDictionary<string, object?> args, string key)
    {
        if (ArgReader.Dict(args, key) is { } reference)
        {
            if (ArgReader.String(reference, "listID") is { } listId)
            {
                return new XElement(elementName, new XElement("ListID", listId));
            }

            if (ArgReader.String(reference, "fullName") is { } nestedFullName)
            {
                return new XElement(elementName, new XElement("FullName", nestedFullName));
            }

            if (ArgReader.String(reference, "txnID") is { } txnId)
            {
                return new XElement(elementName, new XElement("TxnID", txnId));
            }

            return null;
        }

        return ArgReader.String(args, key) is { } fullName
            ? new XElement(elementName, new XElement("FullName", fullName))
            : null;
    }

    public static string? RefValue(IReadOnlyDictionary<string, object?> args, string key)
    {
        if (ArgReader.Dict(args, key) is { } reference)
        {
            return ArgReader.String(reference, "fullName")
                ?? ArgReader.String(reference, "listID")
                ?? ArgReader.String(reference, "txnID");
        }

        return ArgReader.String(args, key);
    }

    public static XElement? AddressElement(string elementName, IReadOnlyDictionary<string, object?>? address)
    {
        if (address is null)
        {
            return null;
        }

        var element = new XElement(elementName);
        foreach (var (fromKey, toKey) in new[]
                 {
                     ("addr1", "Addr1"),
                     ("addr2", "Addr2"),
                     ("addr3", "Addr3"),
                     ("addr4", "Addr4"),
                     ("addr5", "Addr5"),
                     ("city", "City"),
                     ("state", "State"),
                     ("postalCode", "PostalCode"),
                     ("country", "Country"),
                     ("note", "Note"),
                 })
        {
            if (ArgReader.String(address, fromKey) is { } value)
            {
                element.Add(new XElement(toKey, value));
            }
        }

        return element.HasElements ? element : null;
    }

    public static XElement ExpenseLineAdd(IReadOnlyDictionary<string, object?> line)
    {
        var accountRef = RefElement("AccountRef", line, "accountRef")
            ?? throw new ArgumentException("'accountRef' is required for each expense line.");

        var element = new XElement("ExpenseLineAdd", accountRef);
        if (ArgReader.Decimal(line, "amount") is { } amount)
        {
            element.Add(new XElement("Amount", amount.ToString("0.00", CultureInfo.InvariantCulture)));
        }

        if (ArgReader.String(line, "memo") is { } memo)
        {
            element.Add(new XElement("Memo", memo));
        }

        if (RefElement("CustomerRef", line, "customerRef") is { } customerRef)
        {
            element.Add(customerRef);
        }

        if (RefElement("ClassRef", line, "classRef") is { } classRef)
        {
            element.Add(classRef);
        }

        if (ArgReader.String(line, "billableStatus") is { } billableStatus)
        {
            element.Add(new XElement("BillableStatus", billableStatus));
        }

        return element;
    }

    public static XElement ItemLineAdd(IReadOnlyDictionary<string, object?> line)
    {
        var itemRef = RefElement("ItemRef", line, "itemRef")
            ?? throw new ArgumentException("'itemRef' is required for each item line.");

        var element = new XElement("ItemLineAdd", itemRef);
        if (ArgReader.String(line, "desc") is { } description)
        {
            element.Add(new XElement("Desc", description));
        }

        if (ArgReader.Decimal(line, "quantity") is { } quantity)
        {
            element.Add(new XElement("Quantity", quantity.ToString("0.#####", CultureInfo.InvariantCulture)));
        }

        if (ArgReader.Decimal(line, "cost") is { } cost)
        {
            element.Add(new XElement("Cost", cost.ToString("0.00", CultureInfo.InvariantCulture)));
        }

        if (ArgReader.Decimal(line, "amount") is { } amount)
        {
            element.Add(new XElement("Amount", amount.ToString("0.00", CultureInfo.InvariantCulture)));
        }

        if (RefElement("CustomerRef", line, "customerRef") is { } customerRef)
        {
            element.Add(customerRef);
        }

        if (RefElement("ClassRef", line, "classRef") is { } classRef)
        {
            element.Add(classRef);
        }

        if (ArgReader.String(line, "billableStatus") is { } billableStatus)
        {
            element.Add(new XElement("BillableStatus", billableStatus));
        }

        return element;
    }
}

internal static class MultiCurrencyGuard
{
    public static void Reject(IReadOnlyDictionary<string, object?> args)
    {
        if (ArgReader.String(args, "currencyRef") is not null
            || ArgReader.Dict(args, "currencyRef") is not null
            || ArgReader.String(args, "exchangeRate") is not null)
        {
            throw new ArgumentException(
                "multi-currency is not supported in v1; remove 'currencyRef'/'exchangeRate' (v2 item).");
        }
    }
}
