---
name: quickbooks-checks-and-payments
description: Record QuickBooks checks (direct expense disbursements bypassing AP) and customer payments via receive_payment through QbConnectService. Use when the user asks to write a check, record a debit/wire payment to a vendor, record a customer payment, apply a payment to invoices, or list payments. Multi-tenant — default `technijian`.
---

# QuickBooks Checks & Customer Payments

This skill covers two related ops:

- **`create_check`** — outgoing money. Records a check / debit-card / wire as a direct expense, bypassing AP.
- **`receive_payment`** — incoming money. Records a customer payment and applies it to one or more open invoices.

Also covers `list_payments`. For paying open AP bills (different from `create_check`), see "Paying bills" at the bottom.

## Multi-tenant

`company=` or `QB_DEFAULT_COMPANY`. Default `technijian`. Currently authorized: `technijian`, `electronic-corporation-of-america`.

---

## `create_check` — recording an outgoing payment

When to use it instead of `create_bill`:

| Situation | Use |
|---|---|
| Already paid the vendor (check, debit card, wire, EFT) and not tracking AP | `create_check` |
| Vendor invoice with terms — you'll pay later through AP | `create_bill` (see [quickbooks-bills](../quickbooks-bills/SKILL.md)) |
| Owner's draw, reimbursement, refund | `create_check` |
| 1099-eligible spend that paid immediately | `create_check` — make sure `payeeEntityRef` is the vendor (so it lands on their record for 1099 calc) |

### Write a check

⚠️ Dry-run first. Show user. Get explicit confirmation. Execute.

```python
args = {
    # The BANK account the funds came from (Operating, Payroll, etc.):
    "accountRef":      {"fullName": "1010 - Operating Checking"},
    # The payee — customer | vendor | employee | other-name. Optional but recommended.
    "payeeEntityRef":  {"fullName": "Office Depot"},
    "refNumber":       "12345",                 # check number (or "DEBIT", "WIRE", "EFT")
    "txnDate":         "2026-05-19",
    "memo":            "Office supplies for Suite 141",
    "address":         {
        "Addr1": "Office Depot",
        "Addr2": "Online order",
    },
    "isToBePrinted":   False,                    # True if you want QB to queue it for printing

    # AT LEAST ONE of expenseLines or itemLines is required.
    "expenseLines": [
        {
            "accountRef":  {"fullName": "6080 - Office General:6080.06 - Supplies"},
            "amount":      127.84,
            "memo":        "Paper, toner",
            "classRef":    {"fullName": "Admin (US)"},
        },
    ],
    # "itemLines": [...],   # if buying items that go through item accounts
}

dr = client.dryrun("create_check", args)
# Show qbXml, summary, preFlight to user. Confirm.
result = client.op("create_check", args)
print(result["status"], result["rows"][0]["TxnID"])
```

### Common check patterns

```python
# Debit card / EFT — same op, just use a non-numeric RefNumber:
args["refNumber"] = "DEBIT-20260519"
# or
args["refNumber"] = "WIRE-OUTGOING"

# Employee reimbursement:
args["payeeEntityRef"] = {"fullName": "Doe, John"}     # OtherName or Employee list
args["expenseLines"][0]["accountRef"] = {"fullName": "6110 - Travel & Ent:6110.2 - Meals"}

# Owner draw:
args["payeeEntityRef"] = {"fullName": "Owner Name"}
args["expenseLines"][0]["accountRef"] = {"fullName": "3000 - Owner Equity:3001 - Draw"}
```

### Memorize / Recurring checks

There's no `memorized` op. To set up a recurring monthly expense, either:
1. Create one check now via the op, then memorize it in the QB UI manually.
2. Script the monthly creation from the workstation — pull last cycle's check via `get_transaction`, mutate `txnDate`/`refNumber`, dry-run, confirm, execute.

---

## `receive_payment` — recording a customer payment

When a customer pays one of your invoices.

⚠️ Dry-run first.

### Apply explicitly to specific invoices (preferred)

```python
args = {
    "customerRef":           {"fullName": "VWC"},
    "txnDate":               "2026-05-19",
    "refNumber":             "ACH-20260519-VWC",   # the payment reference (their wire / check #)
    "totalAmount":           1500.00,
    "paymentMethodRef":      {"fullName": "ACH"},
    "depositToAccountRef":   {"fullName": "1010 - Operating Checking"},   # or Undeposited Funds
    "memo":                  "Wire received 5/19/26",

    # Explicit application — list each invoice this payment covers and how much:
    "appliedTo": [
        {"txnID": "INV-TXN-A...", "paymentAmount": 1000.00},
        {"txnID": "INV-TXN-B...", "paymentAmount":  500.00},
    ],
}
```

The op's pre-flight check verifies the sum of `appliedTo[*].paymentAmount` equals `totalAmount`. If not, the dry-run shows the discrepancy and `preFlight[i].ok = false`.

### Auto-apply (oldest invoices first)

```python
args = {
    "customerRef":           {"fullName": "VWC"},
    "txnDate":               "2026-05-19",
    "totalAmount":           1500.00,
    "paymentMethodRef":      {"fullName": "ACH"},
    "depositToAccountRef":   {"fullName": "1010 - Operating Checking"},
    "isAutoApply":           True,    # let QB allocate to oldest open invoices
}
```

Use auto-apply ONLY when you've confirmed (via the user's verbal "apply to oldest") — never assume.

### Find the open invoices for a customer first

Before constructing `appliedTo`, pull the open invoices for that customer:

```python
inv = client.op("list_invoices", {"entity": "VWC", "dateMacro": "ThisFiscalYearToDate"})
open_inv = [r for r in inv["rows"] if float(r.get("BalanceRemaining", 0)) > 0]
for r in open_inv:
    print(r["TxnID"], r["RefNumber"], r["TxnDate"], r["BalanceRemaining"])
```

Then show this list to the user and let them pick which invoices the payment applies to and at what amount.

### Unapplied / over-paid

If `totalAmount` > sum of explicit `appliedTo` (and `isAutoApply` is false), the remainder becomes an unapplied credit on the customer's account. The dry-run will surface this.

---

## `list_payments`

```python
result = client.op("list_payments", {"dateMacro": "ThisMonth"})
for row in result["rows"]:
    print(row["TxnDate"], row["CustomerRef"]["FullName"], row["TotalAmount"], row["PaymentMethodRef"]["FullName"])
```

Args: `fromDate` / `toDate` / `dateMacro` / `entity` (customer filter).

---

## Paying bills (BillPaymentCheck / BillPaymentCreditCard)

Not yet wrapped. To pay an open bill via raw qbXML:

```python
xml = '''<?xml version="1.0"?>
<?qbxml version="16.0"?>
<QBXML><QBXMLMsgsRq onError="stopOnError">
  <BillPaymentCheckAddRq>
    <BillPaymentCheckAdd>
      <PayeeEntityRef><FullName>AT&amp;T</FullName></PayeeEntityRef>
      <APAccountRef><FullName>2000 - Accounts Payable</FullName></APAccountRef>
      <TxnDate>2026-05-19</TxnDate>
      <BankAccountRef><FullName>1010 - Operating Checking</FullName></BankAccountRef>
      <RefNumber>12346</RefNumber>
      <Memo>Pay ATT-2026-04</Memo>
      <AppliedToTxnAdd>
        <TxnID>BILL-TXN-...</TxnID>
        <PaymentAmount>575.00</PaymentAmount>
      </AppliedToTxnAdd>
    </BillPaymentCheckAdd>
  </BillPaymentCheckAddRq>
</QBXMLMsgsRq></QBXML>'''
# Show user, get explicit confirm, then:
response = client.qbxml(xml)
```

Use `BillPaymentCreditCardAddRq` if paying with a CC instead.

---

## Common patterns

- **What checks did we cut this week?** → `list_payments` won't show outgoing checks; use `run_query` with `entity="Check"` and date filters, or raw `CheckQueryRq`
- **Customer's payment history** → `list_payments` with `entity="<customer>"`
- **Unapplied customer credit** → `run_query` with `entity="ReceivePayment"` looking for `UnusedPayment > 0`
- **Bank reconciliation prep** — pull all checks and payments for the period, cross-reference to bank statement

## Pointers

- Bills (AP) management: [quickbooks-bills](../quickbooks-bills/SKILL.md)
- Invoices (AR): [quickbooks-invoices](../quickbooks-invoices/SKILL.md)
- Chart of accounts: [quickbooks-accounts-items-classes](../quickbooks-accounts-items-classes/SKILL.md)
- Full safe-write workflow: [quickbooks-accounting](../quickbooks-accounting/SKILL.md)
