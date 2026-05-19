---
name: quickbooks-bills
description: Create, list, get, and modify QuickBooks vendor bills (AP) through QbConnectService. Use when the user asks to enter a bill, record a vendor invoice, look up a bill, list AP, change a bill's header (date, terms, memo, refNumber), or pull bill line detail. Multi-tenant — every call must specify which company file via the `company` parameter (default `technijian`).
---

# QuickBooks Bills (Accounts Payable)

## When to use

- "Enter a bill from [Vendor] for [amount/items]"
- "Record vendor invoice #[N]"
- "List bills for [Vendor] / between [dates]"
- "What unpaid bills do we have? / AP aging"
- "Change the due date / terms on bill #..."
- "Look up bill by RefNumber"

## Multi-tenant

Same as all other QB ops — set `company=` or `QB_DEFAULT_COMPANY` env. Default: `technijian`. Authorized companies as of 2026-05-18: `technijian`, `electronic-corporation-of-america`.

## Bills vs Checks vs Credit Cards — which one to use?

| Situation | Use this op |
|---|---|
| Vendor sent an invoice, you owe them later (Net 30, etc.) | **`create_bill`** (this skill) |
| Already paid (wrote a check / debit card / wire) — recording the expense | `create_check` (see [quickbooks-checks-and-payments](../quickbooks-checks-and-payments/SKILL.md)) |
| Paid via credit card | raw qbXML `CreditCardChargeAdd` |
| Paying an existing bill | raw qbXML `BillPaymentCheckAdd` or `BillPaymentCreditCardAdd` |

Quickbooks tracks vendor balances through the AP account when you use bills. Checks bypass AP and post directly to the expense account. **Get this right** — it materially affects AP aging, vendor balances, and 1099s.

## Quick start

```python
from qb_client import QbClient
client = QbClient.from_env().with_company("technijian")
```

## List bills

```python
# All bills entered this month:
result = client.op("list_bills", {"dateMacro": "ThisMonth"})
for row in result["rows"]:
    print(row["RefNumber"], row["VendorRef"]["FullName"], row["AmountDue"], row["DueDate"])

# Unpaid (open balance) only - filter client-side:
result = client.op("list_bills", {"dateMacro": "ThisYearToDate"})
unpaid = [r for r in result["rows"] if float(r.get("AmountDue", 0)) > 0]
```

Args:

| Arg | Type | Description |
|---|---|---|
| `fromDate` / `toDate` | YYYY-MM-DD pair | Date range. |
| `dateMacro` | string | `Today`, `ThisMonth`, `LastMonth`, `ThisFiscalYear`, etc. Mutually exclusive with from/to. |
| `entity` | vendor name or ListID | Filter to one vendor. |

## Get one bill

```python
matches = client.op("get_transaction", {"refNumber": "ATT-2026-04", "txnType": "Bill"})["matches"]
for m in matches:
    print(m["TxnID"], m["VendorRef"]["FullName"], m["AmountDue"])
```

## Create a bill (write — dry-run first!)

⚠️ Writes are dry-run-gated. Show the user the dry-run, get explicit confirmation, then execute.

```python
args = {
    "vendorRef": {"fullName": "AT&T"},
    "txnDate": "2026-05-15",
    "dueDate": "2026-06-14",
    "refNumber": "ATT-2026-05",
    "terms": "Net 30",
    "memo": "May internet + phone",
    # AP account is usually inferred; pass apAccountRef to override.

    # Expense lines (no item, direct to an expense account):
    "expenseLines": [
        {
            "accountRef":  {"fullName": "6080 - Office General:6080.13 - Internet"},
            "amount":      450.00,
            "memo":        "Fiber 1G",
            "classRef":    {"fullName": "Admin (US)"},
            # Optional: "customerRef": {"fullName": "VWC"}    # billable to customer
            # Optional: "billableStatus": "Billable"           # if customerRef
        },
        {
            "accountRef":  {"fullName": "6080 - Office General:6080.09 - Utilities"},
            "amount":      125.00,
            "memo":        "Phones",
            "classRef":    {"fullName": "Admin (US)"},
        },
    ],

    # Item lines (for inventory / service items — use these instead of expenseLines
    # when the bill represents goods/services that go through an item):
    # "itemLines": [
    #     {
    #         "itemRef":   {"fullName": "Hardware:Switch:Catalyst-2960"},
    #         "quantity":  2,
    #         "cost":      850.00,
    #         "classRef":  {"fullName": "Data Center"},
    #     },
    # ],
}

dr = client.dryrun("create_bill", args)
# Show user dr["qbXml"], dr["summary"], dr["preFlight"], dr["resolvedReferences"].
# Wait for explicit "yes execute".

result = client.op("create_bill", args)
print(result["status"], result["rows"][0]["TxnID"], result["auditSeq"])
```

### Line shape notes

- **A bill must have AT LEAST ONE line**, either expense or item (or both).
- **`expenseLines`** post to a GL account directly (most common for utilities, rent, professional fees, etc.).
- **`itemLines`** go through an item which has its own COGS/expense account mapping. Use for goods you stock, or service items you've configured with vendor-side accounts.
- **`classRef` per line** is critical for class-tracked accounting — set it on each line to match how the expense should classify (e.g., `Admin (US)`, `Data Center`, `CS`, `Marketing`).
- **`customerRef` + `billableStatus`** on an expense line marks it as a job-cost or reimbursable. The line then shows up as a billable expense on that customer's record.

## Modify a bill header (write — dry-run first!)

```python
args = {
    "entity": "bill",
    "ref": {"txnID": "ABC-123..."},
    "fields": {
        "DueDate":   "2026-07-15",
        "Terms":     "Net 60",
        "Memo":      "Renegotiated 2026-05-18 — extended terms",
        "RefNumber": "ATT-2026-05-REV",
    },
}
dr = client.dryrun("mod", args)
# ... show before/after diff and EditSequence ...
result = client.op("mod", args)
# 3200 statusCode = stale EditSequence — re-dry-run, never auto-retry.
```

`mod` is **header-only** in v1. To change lines, void and re-create.

## Void / Delete a bill

Not wrapped. Use raw qbXML:

```python
xml = '''<?xml version="1.0"?>
<?qbxml version="16.0"?>
<QBXML><QBXMLMsgsRq onError="stopOnError">
  <TxnVoidRq>
    <TxnVoidType>Bill</TxnVoidType>
    <TxnID>ABC-123...</TxnID>
  </TxnVoidRq>
</QBXMLMsgsRq></QBXML>'''
# Show user, confirm, then:
result = client.qbxml(xml)
```

Voiding a paid bill is messy — it leaves the bill payment dangling. Resolve the payment first (delete or re-apply) before voiding the bill.

## Common patterns

- **AP aging summary** → `client.op("report", {"type": "AgingAP"})`
- **Unpaid bills for a vendor** → `list_bills` filtered by `entity`, where `AmountDue > 0`
- **Recurring bill** — there's no "memorized transaction" op; create from a template each cycle, or copy fields from last cycle's bill via `get_transaction` then `create_bill`
- **1099-eligible vendor spend YTD** → cross-reference `list_vendors` (filter where `IsVendorEligibleFor1099 == true`) with `list_bills` plus `list_payments` (for checks paid)

## Pointers

- Paying a bill (BillPayment) is not yet wrapped — use raw qbXML
- See [quickbooks-checks-and-payments](../quickbooks-checks-and-payments/SKILL.md) for direct checks and payment ops
- For item/account/class metadata: see [quickbooks-accounts-items-classes](../quickbooks-accounts-items-classes/SKILL.md)
- Full safe-write workflow: see [quickbooks-accounting](../quickbooks-accounting/SKILL.md)
