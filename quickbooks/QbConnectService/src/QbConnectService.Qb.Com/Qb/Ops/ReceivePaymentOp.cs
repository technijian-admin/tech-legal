using Microsoft.Extensions.Options;
using System.Globalization;
using System.Xml.Linq;
using QbConnectService.Qb;

namespace QbConnectService.Qb.Ops;

public sealed class ReceivePaymentOp(
    QbXmlBuilder b,
    QbConnectionManager m,
    QbXmlParser xp,
    QbReportParser rp,
    QbListExecutor le,
    AuditLog audit,
    IOptions<SafetyOptions> safety)
    : WriteOpBase(b, m, xp, rp, le, audit, safety)
{
    public override string Name => "receive_payment";

    public override string BuildRequest(IReadOnlyDictionary<string, object?> args)
    {
        MultiCurrencyGuard.Reject(args);

        var add = new XElement("ReceivePaymentAdd");
        add.Add(WriteOpHelpers.RefElement("CustomerRef", args, "customerRef")
            ?? throw new ArgumentException("'customerRef' is required."));
        AddElement(add, WriteOpHelpers.RefElement("ARAccountRef", args, "arAccountRef"));
        AddDate(add, "TxnDate", ArgReader.Date(args, "txnDate"));
        AddString(add, "RefNumber", ArgReader.String(args, "refNumber"));
        AddDecimal(add, "TotalAmount", ArgReader.Decimal(args, "totalAmount"));
        AddElement(add, WriteOpHelpers.RefElement("PaymentMethodRef", args, "paymentMethodRef"));
        AddString(add, "Memo", ArgReader.String(args, "memo"));
        AddElement(add, WriteOpHelpers.RefElement("DepositToAccountRef", args, "depositToAccountRef"));

        var isAutoApply = ArgReader.Bool(args, "isAutoApply") ?? false;
        var appliedTo = ArgReader.List(args, "appliedTo");
        if (isAutoApply)
        {
            add.Add(new XElement("IsAutoApply", "true"));
        }
        else
        {
            if (appliedTo is null || appliedTo.Count == 0)
            {
                throw new ArgumentException("receive_payment requires either 'isAutoApply':true or a non-empty 'appliedTo' array of {txnID, paymentAmount}.");
            }

            foreach (var line in appliedTo)
            {
                var paymentAmount = ArgReader.Decimal(line, "paymentAmount")
                    ?? throw new ArgumentException("each 'appliedTo' entry needs 'paymentAmount'.");

                var appliedToTxn = new XElement(
                    "AppliedToTxnAdd",
                    new XElement("TxnID", ArgReader.RequiredString(line, "txnID")),
                    new XElement("PaymentAmount", paymentAmount.ToString("0.00", CultureInfo.InvariantCulture)));

                if (ArgReader.Decimal(line, "discountAmount") is { } discountAmount)
                {
                    appliedToTxn.Add(new XElement("DiscountAmount", discountAmount.ToString("0.00", CultureInfo.InvariantCulture)));
                }

                if (WriteOpHelpers.RefElement("DiscountAccountRef", line, "discountAccountRef") is { } discountAccountRef)
                {
                    appliedToTxn.Add(discountAccountRef);
                }

                add.Add(appliedToTxn);
            }
        }

        return _builder.BuildRequest(QbXmlBuilder.Rq("ReceivePaymentAddRq", add));
    }

    public override async Task<DryRunResult> DryRunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default)
    {
        var qbXml = BuildRequest(args);
        var isAutoApply = ArgReader.Bool(args, "isAutoApply") ?? false;
        var appliedTo = ArgReader.List(args, "appliedTo");

        var checks = new List<PreFlightCheck>();
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

        if (isAutoApply)
        {
            checks.Add(new PreFlightCheck(
                "application-mode",
                true,
                appliedTo is { Count: > 0 }
                    ? "isAutoApply wins; appliedTo ignored"
                    : "QB auto-applies to oldest open invoices"));
        }
        else if (appliedTo is not null)
        {
            checks.Add(new PreFlightCheck(
                "application-mode",
                true,
                $"applying to {appliedTo.Count} txn(s): {string.Join(", ", appliedTo.Select(line => ArgReader.RequiredString(line, "txnID")))}"));
        }

        if (!isAutoApply && appliedTo is not null && ArgReader.Decimal(args, "totalAmount") is { } totalAmount)
        {
            var appliedTotal = appliedTo
                .Select(line => ArgReader.Decimal(line, "paymentAmount") ?? 0m)
                .Sum();
            checks.Add(new PreFlightCheck(
                "total-amount-covers-applications",
                appliedTotal <= totalAmount,
                $"applied total {appliedTotal.ToString("0.00", CultureInfo.InvariantCulture)} vs totalAmount {totalAmount.ToString("0.00", CultureInfo.InvariantCulture)}"));
        }

        var summary = $"Receive payment from {WriteOpHelpers.RefValue(args, "customerRef")}{(isAutoApply ? " (auto-apply)" : appliedTo is { Count: var count } ? $" applied to {count} invoice(s)" : string.Empty)}.";
        return new DryRunResult(qbXml, summary, checks, resolved, AllowWrites);
    }

    private static void AddString(XElement parent, string elementName, string? value)
    {
        if (value is not null)
        {
            parent.Add(new XElement(elementName, value));
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
