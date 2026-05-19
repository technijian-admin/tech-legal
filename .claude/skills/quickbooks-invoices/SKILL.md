---
name: quickbooks-invoices
description: Create, list, get, and modify QuickBooks customer invoices through QbConnectService. Use when the user asks to create an invoice, send an invoice, look up an invoice, list AR invoices, change an invoice's header (date, terms, memo, refNumber), or pull invoice line detail. Multi-tenant — every call must specify which company file via the `company` parameter (technijian, electronic-corporation-of-america, etc.).
---

# QuickBooks Invoices

## When to use

- "Create an invoice for [Customer] for [items/amount]"
- "List invoices for [Customer] / between [dates]"
- "Show me invoice details with line items"
- "Change the due date / terms / memo on invoice #..."
- "What unpaid invoices does [Customer] have?" → use `list_invoices` with date range + the customer entity filter, OR pull AR Aging report

## Multi-tenant note

Every request must pick which company file to target. Default in `.env` is `QB_DEFAULT_COMPANY=technijian`. Override per-call via `company=` argument or per-client via `client.with_company("kutumba-holdings-llc")`. Currently authorized files (as of 2026-05-18):

- `technijian` (default — Technijian Inc.)
- `electronic-corporation-of-america`

The other two .qbw files (`technijian-pvt-ltd`, `kutumba-holdings-llc`) exist in config but have NOT been authorized in QuickBooks Integrated Applications yet — calls against them will return `0x80040408 QB_COULD_NOT_START`.

## Quick start

```python
from qb_client import QbClient
client = QbClient.from_env()  # picks up QB_DEFAULT_COMPANY from .env
```

Or scope to a specific company:

```python
tj = QbClient.from_env().with_company("technijian")
eca = QbClient.from_env().with_company("electronic-corporation-of-america")
```

## List invoices

```python
# Last 30 days, all customers, header rows only:
result = client.op("list_invoices", {"dateMacro": "LastMonth"})
print(f'{result["count"]} invoices')
for row in result["rows"][:10]:
    print(row["RefNumber"], row["CustomerRef"]["FullName"], row["BalanceRemaining"], row["TxnDate"])
```

Args (all optional):

| Arg | Type | Description |
|---|---|---|
| `fromDate` | YYYY-MM-DD | Inclusive start date. Pair with `toDate`. |
| `toDate` | YYYY-MM-DD | Inclusive end date. Pair with `fromDate`. |
| `dateMacro` | string | Alternative to dates: `Today`, `Yesterday`, `ThisWeek`, `LastWeek`, `ThisMonth`, `LastMonth`, `ThisQuarter`, `LastQuarter`, `ThisFiscalYear`, `LastFiscalYear`, `ThisFiscalYearToDate`, etc. **Mutually exclusive with `fromDate`/`toDate`.** |
| `entity` | string (customer name or ListID) | Filter to one customer. |
| `includeLineItems` | bool (default false) | Set true to also pull each line — slower, much bigger response. |

## Get one invoice

```python
# Look up by RefNumber (the user-visible invoice number, e.g. "12345"):
matches = client.op("get_transaction", {"refNumber": "12345", "txnType": "Invoice"})["matches"]
# RefNumber is non-unique - matches is always a list.

# Or by TxnID (the GUID-like internal QB id):
matches = client.op("get_transaction", {"txnId": "ABC-1234567890"})["matches"]
```

To get the full invoice with lines:

```python
result = client.op("list_invoices", {
    "fromDate": "2026-05-01",
    "toDate": "2026-05-18",
    "entity": "ALG",                  # customer code from list_customers
    "includeLineItems": True,
})
```

## Create an invoice (write — dry-run first!)

⚠️ Writes are dry-run-gated. **Never call `op("create_invoice", ...)` without first calling `dryrun(...)` AND getting explicit user confirmation.** See the main `quickbooks-accounting` skill for the full safe-write workflow.

```python
args = {
    "customerRef": {"fullName": "VWC"},   # or {"listID": "..."}
    "txnDate": "2026-05-20",
    "refNumber": "INV-2026-0142",
    "terms": "Net 30",
    "memo": "May consulting hours",
    "classRef": {"fullName": "CS"},        # optional class for the whole invoice
    "lines": [
        {
            "itemRef": {"fullName": "Consulting:Senior"},
            "desc": "Senior engineering — 12 hours",
            "quantity": 12,
            "rate": 175.00,
            # Or set "amount" directly without quantity/rate.
            # "classRef": {"fullName": "CS"},   # optional per-line class override
        },
        {
            "itemRef": {"fullName": "Travel"},
            "desc": "Onsite — Anaheim",
            "amount": 245.00,
        },
    ],
}

# Step 1: dry-run.
dr = client.dryrun("create_invoice", args)
print(dr["qbXml"])         # byte-exact request body
print(dr["summary"])        # human-readable summary
for pf in dr["preFlight"]:
    print(pf["name"], pf["ok"], pf["detail"])
print(dr["resolvedReferences"])
print("allowWrites:", dr["allowWrites"])

# Step 2: SHOW the user the dry-run. WAIT for explicit "yes, execute".

# Step 3: only after explicit user confirmation:
result = client.op("create_invoice", args)
print(result["status"])         # qbXML statusCode/Severity/Message
print(result["rows"][0]["TxnID"])    # newly created invoice's TxnID
print("auditSeq:", result["auditSeq"])
```

### Common line shapes

```python
# Item-driven line (most common):
{"itemRef": {"fullName": "Consulting:Senior"}, "desc": "...", "quantity": N, "rate": M}

# Amount-only line (no item, free-form):
{"desc": "...", "amount": 250.00}

# Discount line:
{"itemRef": {"fullName": "Discounts:Bulk"}, "desc": "10% bulk", "rate": -0.10}

# Line with class override (e.g. invoice is mostly "CS" but one line is "Data Center"):
{"itemRef": {"fullName": "Co-Lo:Rack-U"}, "amount": 500, "classRef": {"fullName": "Data Center"}}

# Line with sales-tax code:
{"itemRef": {"fullName": "Hardware:NVR"}, "amount": 1200, "salesTaxCodeRef": {"fullName": "Tax"}}
```

The header-level `itemSalesTaxRef` sets the invoice's overall tax item (e.g. "CA Flat Sales Tax 7.75%"). Combined with each line's `salesTaxCodeRef`, QB calculates tax.

## Modify an invoice header (write — dry-run first!)

The generic `mod` op handles header-level updates. Line-item editing is NOT supported in v1 — to change lines, void and re-create.

```python
args = {
    "entity": "invoice",
    "ref": {"txnID": "ABC-1234567890"},
    "fields": {
        "DueDate": "2026-06-30",
        "Terms": "Net 60",
        "Memo": "Extended terms per customer request 2026-05-18",
    },
}

dr = client.dryrun("mod", args)
# ... show user the before/after diff and the EditSequence ...

result = client.op("mod", args)
# If statusCode == "3200" (stale EditSequence), DO NOT auto-retry. Re-dry-run
# (which fetches fresh EditSequence) and re-confirm.
```

## Void / Delete an invoice

Not wrapped. Use raw qbXML via `client.qbxml(...)`. Recommend Void over Delete (Void preserves the audit trail; Delete is destructive).

```python
xml = """<?xml version="1.0"?>
<?qbxml version="16.0"?>
<QBXML><QBXMLMsgsRq onError="stopOnError">
  <TxnVoidRq>
    <TxnVoidType>Invoice</TxnVoidType>
    <TxnID>ABC-1234567890</TxnID>
  </TxnVoidRq>
</QBXMLMsgsRq></QBXML>"""
# Same safe-write rules: show xml to user, get confirmation, then send:
result = client.qbxml(xml)
```

## Patterns the user is likely to ask for

- **AR aging summary** → `client.op("report", {"type": "AgingAR"})`
- **All open invoices for a customer** → `list_invoices` + filter where `BalanceRemaining > 0`
- **Invoices created this week** → `list_invoices` with `dateMacro="ThisWeek"`
- **Top customers by outstanding balance** → cross-reference `list_customers` (has `Balance`) and `report({type: AgingAR})`
- **Re-bill / duplicate an invoice** → fetch original with `includeLineItems=true`, mutate fields, then `create_invoice` with the modified args

## Reference shapes

`{listID: "..."}` and `{fullName: "..."}` are the two ways to point at any QB list entity (customer, item, account, class). Either works — `fullName` is human-readable, `listID` is stable across renames. Prefer `listID` when you got it from a prior query.

## Pointers

- Full safe-write workflow: see [quickbooks-accounting](../quickbooks-accounting/SKILL.md)
- Items + their tied accounts/classes: see [quickbooks-accounts-items-classes](../quickbooks-accounts-items-classes/SKILL.md)
- Customer management: `create_customer` op (also dry-run-gated)
- For reports based on invoices: see [quickbooks-reports](../quickbooks-reports/SKILL.md)
