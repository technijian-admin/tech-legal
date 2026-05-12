using System.Text.Json;
using System.Xml.Linq;
using QbConnectService.Qb.Ops;

namespace QbConnectService.Tests;

public sealed class WriteOpHelpersTests
{
    [Fact]
    public void multicurrency_guard_rejects_string_currencyref()
    {
        var args = Args(("currencyRef", "EUR"));

        var ex = Assert.Throws<ArgumentException>(() => MultiCurrencyGuard.Reject(args));

        Assert.Contains("multi-currency", ex.Message, StringComparison.Ordinal);
    }

    [Fact]
    public void multicurrency_guard_rejects_dict_currencyref()
    {
        var args = Args(("currencyRef", Args(("fullName", "Euro"))));

        Assert.Throws<ArgumentException>(() => MultiCurrencyGuard.Reject(args));
    }

    [Fact]
    public void multicurrency_guard_rejects_exchange_rate()
    {
        var args = Args(("exchangeRate", "1.25"));

        Assert.Throws<ArgumentException>(() => MultiCurrencyGuard.Reject(args));
    }

    [Fact]
    public void multicurrency_guard_allows_absent_currency_fields()
    {
        MultiCurrencyGuard.Reject(Args(("name", "Acme")));
    }

    [Fact]
    public void refelement_uses_fullname_for_string()
    {
        var element = WriteOpHelpers.RefElement("CustomerRef", Args(("customerRef", "Acme")), "customerRef");

        Assert.Equal("<CustomerRef><FullName>Acme</FullName></CustomerRef>", Normalize(element));
    }

    [Fact]
    public void refelement_uses_listid_for_dict()
    {
        var element = WriteOpHelpers.RefElement("CustomerRef", Args(("customerRef", Args(("listID", "8000")))), "customerRef");

        Assert.Equal("<CustomerRef><ListID>8000</ListID></CustomerRef>", Normalize(element));
    }

    [Fact]
    public void refelement_uses_fullname_for_nested_dict()
    {
        var element = WriteOpHelpers.RefElement("CustomerRef", Args(("customerRef", Args(("fullName", "Acme")))), "customerRef");

        Assert.Equal("<CustomerRef><FullName>Acme</FullName></CustomerRef>", Normalize(element));
    }

    [Fact]
    public void refelement_returns_null_when_absent()
    {
        var element = WriteOpHelpers.RefElement("CustomerRef", Args(("name", "Acme")), "customerRef");

        Assert.Null(element);
    }

    [Fact]
    public void address_element_includes_only_present_keys()
    {
        var address = Args(("addr1", "1 Main"), ("city", "Irvine"), ("postalCode", "92614"));

        var element = WriteOpHelpers.AddressElement("BillAddress", address);

        Assert.Equal(
            "<BillAddress><Addr1>1 Main</Addr1><City>Irvine</City><PostalCode>92614</PostalCode></BillAddress>",
            Normalize(element));
    }

    [Fact]
    public void address_element_returns_null_for_empty_or_null_dict()
    {
        Assert.Null(WriteOpHelpers.AddressElement("BillAddress", null));
        Assert.Null(WriteOpHelpers.AddressElement("BillAddress", Args()));
    }

    [Fact]
    public void expenselineadd_requires_accountref()
    {
        var ex = Assert.Throws<ArgumentException>(() => WriteOpHelpers.ExpenseLineAdd(Args(("amount", "123.45"))));

        Assert.Contains("accountRef", ex.Message, StringComparison.Ordinal);
    }

    [Fact]
    public void expenselineadd_formats_amount_invariantly()
    {
        var element = WriteOpHelpers.ExpenseLineAdd(Args(("accountRef", "Office Expenses"), ("amount", "123.45")));

        Assert.Equal(
            "<ExpenseLineAdd><AccountRef><FullName>Office Expenses</FullName></AccountRef><Amount>123.45</Amount></ExpenseLineAdd>",
            Normalize(element));
    }

    [Fact]
    public void itemlineadd_requires_itemref()
    {
        var ex = Assert.Throws<ArgumentException>(() => WriteOpHelpers.ItemLineAdd(Args(("quantity", "2.5"))));

        Assert.Contains("itemRef", ex.Message, StringComparison.Ordinal);
    }

    [Fact]
    public void itemlineadd_formats_quantity_invariantly()
    {
        var element = WriteOpHelpers.ItemLineAdd(Args(("itemRef", "Consulting"), ("quantity", "2.5")));

        Assert.Equal(
            "<ItemLineAdd><ItemRef><FullName>Consulting</FullName></ItemRef><Quantity>2.5</Quantity></ItemLineAdd>",
            Normalize(element));
    }

    [Fact]
    public void argreader_list_reads_dictionary_lists()
    {
        var args = Args(("lines", new List<object?> { Args(("itemRef", "Consulting")), Args(("itemRef", "Support")) }));

        var lines = ArgReader.List(args, "lines");

        Assert.NotNull(lines);
        Assert.Equal(2, lines.Count);
        Assert.Equal("Consulting", ArgReader.String(lines[0], "itemRef"));
        Assert.Equal("Support", ArgReader.String(lines[1], "itemRef"));
    }

    [Fact]
    public void argreader_list_reads_jsonelement_arrays()
    {
        using var document = JsonDocument.Parse("""{"lines":[{"itemRef":"Consulting"},{"itemRef":"Support"}]}""");
        var args = Args(("lines", document.RootElement.GetProperty("lines")));

        var lines = ArgReader.List(args, "lines");

        Assert.NotNull(lines);
        Assert.Equal(2, lines.Count);
        Assert.Equal("Consulting", ArgReader.String(lines[0], "itemRef"));
        Assert.Equal("Support", ArgReader.String(lines[1], "itemRef"));
    }

    [Fact]
    public void argreader_list_rejects_non_arrays()
    {
        var ex = Assert.Throws<ArgumentException>(() => ArgReader.List(Args(("lines", "nope")), "lines"));

        Assert.Equal("'lines' must be an array of objects.", ex.Message);
    }

    [Fact]
    public void argreader_list_rejects_non_object_items()
    {
        var ex = Assert.Throws<ArgumentException>(() => ArgReader.List(Args(("lines", new List<object?> { "nope" })), "lines"));

        Assert.Equal("'lines[0]' must be an object.", ex.Message);
    }

    [Fact]
    public void argreader_decimal_parses_invariant_strings()
    {
        var amount = ArgReader.Decimal(Args(("amount", "1234.50")), "amount");

        Assert.Equal(1234.50m, amount);
    }

    [Theory]
    [InlineData("1,234.50")]
    [InlineData("$5")]
    [InlineData("abc")]
    public void argreader_decimal_rejects_non_invariant_values(string value)
    {
        var ex = Assert.Throws<ArgumentException>(() => ArgReader.Decimal(Args(("amount", value)), "amount"));

        Assert.Equal($"'amount' must be a decimal number; got '{value}'.", ex.Message);
    }

    [Fact]
    public void argreader_requiredstring_returns_value()
    {
        var value = ArgReader.RequiredString(Args(("name", "Acme")), "name");

        Assert.Equal("Acme", value);
    }

    [Fact]
    public void argreader_requiredstring_throws_when_missing()
    {
        var ex = Assert.Throws<ArgumentException>(() => ArgReader.RequiredString(Args(), "name"));

        Assert.Equal("'name' is required.", ex.Message);
    }

    private static IReadOnlyDictionary<string, object?> Args(params (string Key, object? Value)[] values)
    {
        var dict = new Dictionary<string, object?>(StringComparer.Ordinal);
        foreach (var (key, value) in values)
        {
            dict[key] = value;
        }

        return dict;
    }

    private static string? Normalize(XElement? element) =>
        element?.ToString(SaveOptions.DisableFormatting);
}
