using System.Xml.Linq;

namespace QbConnectService.Qb.Ops;

/// <summary>
/// Reads PreferencesRet plus default A/R and A/P accounts. PreferencesRet does not expose a clean default
/// A/R or A/P account element, so those values come from AccountQueryRq filtered by AccountType. Field names
/// such as IsMultiCurrencyOn, IsUsingClassTracking, and DefaultItemSalesTaxRef are Phase 9 re-pin candidates.
/// </summary>
public sealed class CompanyPreferencesOp(
    QbXmlBuilder b,
    QbConnectionManager m,
    QbXmlParser xp,
    QbReportParser rp,
    QbListExecutor le) : ReadOpBase(b, m, xp, rp, le)
{
    public override string Name => "get_company_preferences";

    public override async Task<object?> RunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default)
    {
        var prefParsed = await QuerySingleAsync(QbXmlBuilder.Rq("PreferencesQueryRq"), ct);
        var preferences = prefParsed.First.Rows.FirstOrDefault() ?? new Dictionary<string, object?>(StringComparer.Ordinal);

        var salesTax = AsDict(preferences.GetValueOrDefault("SalesTaxPreferences"));
        var accounting = AsDict(preferences.GetValueOrDefault("AccountingPreferences"));
        var multiCurrency = AsDict(preferences.GetValueOrDefault("MultiCurrencyPreferences"));
        var purchases = AsDict(preferences.GetValueOrDefault("PurchasesAndVendorsPreferences"));
        var itemsInventory = AsDict(preferences.GetValueOrDefault("ItemsAndInventoryPreferences"));

        var arParsed = await QueryListAsync(
            QbXmlBuilder.Rq("AccountQueryRq", new XElement("AccountType", "AccountsReceivable")),
            ownerIdZero: null,
            ct);
        var apParsed = await QueryListAsync(
            QbXmlBuilder.Rq("AccountQueryRq", new XElement("AccountType", "AccountsPayable")),
            ownerIdZero: null,
            ct);

        var defaultArAccount = arParsed.First.Rows.FirstOrDefault();
        var defaultApAccount = apParsed.First.Rows.FirstOrDefault();

        return new Dictionary<string, object?>
        {
            ["status"] = prefParsed.First.Status,
            ["salesTaxEnabled"] = salesTax is not null,
            ["defaultItemSalesTaxRef"] = salesTax?.GetValueOrDefault("DefaultItemSalesTaxRef"),
            ["multiCurrencyEnabled"] = TryParseBool(multiCurrency?.GetValueOrDefault("IsMultiCurrencyOn")) ?? false,
            ["homeCurrencyRef"] = multiCurrency?.GetValueOrDefault("HomeCurrencyRef"),
            ["decimalPlaces"] = FirstValue(
                itemsInventory,
                "QuantityDecimals",
                "PriceDecimals",
                "AmountDecimals",
                "NumberOfDecimalPlaces"),
            ["classTrackingOn"] = accounting?.GetValueOrDefault("IsUsingClassTracking"),
            ["requireAccounts"] = accounting?.GetValueOrDefault("IsRequiringAccounts"),
            ["useAccountNumbers"] = accounting?.GetValueOrDefault("IsUsingAccountNumbers"),
            ["defaultDiscountAccountRef"] = purchases?.GetValueOrDefault("DefaultDiscountAccountRef"),
            ["defaultArAccount"] = defaultArAccount,
            ["defaultArAccountSource"] = "AccountQuery",
            ["defaultApAccount"] = defaultApAccount,
            ["defaultApAccountSource"] = "AccountQuery",
            ["rawPreferencesRet"] = preferences,
        };
    }

    private static IReadOnlyDictionary<string, object?>? AsDict(object? value) =>
        value as IReadOnlyDictionary<string, object?>;

    private static bool? TryParseBool(object? value) =>
        value switch
        {
            bool b => b,
            string s when bool.TryParse(s, out var parsed) => parsed,
            _ => null,
        };

    private static object? FirstValue(IReadOnlyDictionary<string, object?>? dict, params string[] keys)
    {
        if (dict is null)
        {
            return null;
        }

        foreach (var key in keys)
        {
            if (dict.TryGetValue(key, out var value) && value is not null)
            {
                return value;
            }
        }

        return null;
    }
}
