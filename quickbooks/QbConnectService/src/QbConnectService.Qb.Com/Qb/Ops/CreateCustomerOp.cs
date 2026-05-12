using Microsoft.Extensions.Options;
using System.Globalization;
using System.Xml.Linq;
using QbConnectService.Qb;

namespace QbConnectService.Qb.Ops;

public sealed class CreateCustomerOp(
    QbXmlBuilder b,
    QbConnectionManager m,
    QbXmlParser xp,
    QbReportParser rp,
    QbListExecutor le,
    AuditLog audit,
    IOptions<SafetyOptions> safety)
    : WriteOpBase(b, m, xp, rp, le, audit, safety)
{
    public override string Name => "create_customer";

    public override string BuildRequest(IReadOnlyDictionary<string, object?> args)
    {
        MultiCurrencyGuard.Reject(args);
        var name = ArgReader.RequiredString(args, "name");

        var add = new XElement("CustomerAdd", new XElement("Name", name));
        AddBool(add, "IsActive", ArgReader.Bool(args, "isActive"));
        AddElement(add, WriteOpHelpers.RefElement("ParentRef", args, "parentRef"));
        AddString(add, "CompanyName", ArgReader.String(args, "companyName"));
        AddString(add, "Salutation", ArgReader.String(args, "salutation"));
        AddString(add, "FirstName", ArgReader.String(args, "firstName"));
        AddString(add, "MiddleName", ArgReader.String(args, "middleName"));
        AddString(add, "LastName", ArgReader.String(args, "lastName"));
        AddString(add, "Suffix", ArgReader.String(args, "suffix"));
        AddElement(add, WriteOpHelpers.AddressElement("BillAddress", ArgReader.Dict(args, "billAddress")));
        AddElement(add, WriteOpHelpers.AddressElement("ShipAddress", ArgReader.Dict(args, "shipAddress")));
        AddString(add, "PrintAs", ArgReader.String(args, "printAs"));
        AddString(add, "Phone", ArgReader.String(args, "phone"));
        AddString(add, "Mobile", ArgReader.String(args, "mobile"));
        AddString(add, "Pager", ArgReader.String(args, "pager"));
        AddString(add, "AltPhone", ArgReader.String(args, "altPhone"));
        AddString(add, "Fax", ArgReader.String(args, "fax"));
        AddString(add, "Email", ArgReader.String(args, "email"));
        AddString(add, "Contact", ArgReader.String(args, "contact"));
        AddString(add, "AltContact", ArgReader.String(args, "altContact"));
        AddElement(add, WriteOpHelpers.RefElement("CustomerTypeRef", args, "customerTypeRef"));
        AddElement(add, WriteOpHelpers.RefElement("TermsRef", args, "terms"));
        AddElement(add, WriteOpHelpers.RefElement("SalesRepRef", args, "salesRepRef"));
        AddDecimal(add, "OpenBalance", ArgReader.Decimal(args, "openBalance"));
        AddDate(add, "OpenBalanceDate", ArgReader.Date(args, "openBalanceDate"));
        AddElement(add, WriteOpHelpers.RefElement("SalesTaxCodeRef", args, "salesTaxCodeRef"));
        AddElement(add, WriteOpHelpers.RefElement("ItemSalesTaxRef", args, "itemSalesTaxRef"));

        return _builder.BuildRequest(QbXmlBuilder.Rq("CustomerAddRq", add));
    }

    public override async Task<DryRunResult> DryRunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default)
    {
        var qbXml = BuildRequest(args);
        var name = ArgReader.RequiredString(args, "name");

        var checks = new List<PreFlightCheck>
        {
            new("name-present", true, $"name = '{name}'"),
        };
        var resolved = new Dictionary<string, object?>(StringComparer.Ordinal);

        var existing = await FetchByNameAsync("Customer", name, ct);
        checks.Add(new PreFlightCheck(
            "name-not-already-in-use",
            existing is null,
            existing is null
                ? "no existing customer with that Name"
                : $"a customer named '{name}' already exists (ListID {existing.GetValueOrDefault("ListID")}); Add will fail 3100"));

        if (ArgReader.Dict(args, "terms") is { } termsRef && ArgReader.String(termsRef, "listID") is { } termsListId)
        {
            resolved["termsRef"] = termsListId;
        }
        else if (WriteOpHelpers.RefValue(args, "terms") is { } termsName)
        {
            var term = await FetchByNameAsync("Term", termsName, ct);
            checks.Add(new PreFlightCheck(
                "terms-resolves",
                term is not null,
                term is null ? $"no Term named '{termsName}'" : "ok"));

            if (term is not null)
            {
                resolved["termsRef"] = term.GetValueOrDefault("ListID");
            }
        }

        return new DryRunResult(qbXml, $"Create customer '{name}'.", checks, resolved, AllowWrites);
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

    private static void AddDecimal(XElement parent, string elementName, decimal? value)
    {
        if (value is decimal amount)
        {
            parent.Add(new XElement(elementName, amount.ToString("0.00", CultureInfo.InvariantCulture)));
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
