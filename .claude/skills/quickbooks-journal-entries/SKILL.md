---
name: quickbooks-journal-entries
description: Create QuickBooks journal entries (JEs) through QbConnectService — debit/credit pairs, balanced. Use when the user asks to record a journal entry, post a manual GL transaction, allocate expenses across classes, accrue / reclassify, do a closing entry, or correct a misposting that can't be fixed by editing a transaction. Multi-tenant — default `technijian`.
---

# QuickBooks Journal Entries

JEs are the low-level, manual posting tool. Use them when no other transaction type fits:

- Period-end accruals (e.g., accrued payroll, accrued revenue)
- Reclassifications between accounts or between classes
- Depreciation and amortization
- Closing entries
- Audit adjustments
- Recording entries from a payroll service that posts as a JE

For day-to-day operations (invoicing customers, paying vendors, writing checks), USE THE SPECIFIC SKILLS — those preserve subledger detail (customer balances, vendor balances, item costs). A JE bypasses subledgers.

## Multi-tenant

`company=` or `QB_DEFAULT_COMPANY`. Default `technijian`. Authorized: `technijian`, `electronic-corporation-of-america`.

## The hard rule: debits == credits

Every JE must balance — the sum of `debits[*].amount` MUST equal the sum of `credits[*].amount`. The `create_journal_entry` op has a pre-flight check that 400s if not. Currency is single-currency per JE; the op refuses multi-currency in v1.

## Create a journal entry (write — dry-run first!)

```python
from qb_client import QbClient
client = QbClient.from_env().with_company("technijian")

args = {
    "txnDate":    "2026-05-31",
    "refNumber":  "JE-2026-05-01",
    "memo":       "May 2026 - Allocate prepaid insurance to expense",
    "isAdjustment": False,    # set True for closing/adjusting entries

    "debits": [
        {
            "accountRef":  {"fullName": "6130 - Insurance:6130.4 - Medical Insurance"},
            "amount":      1250.00,
            "memo":        "May allocation - Medical",
            "classRef":    {"fullName": "Admin (US)"},
            "entityRef":   {"fullName": "Doe, John"},   # optional - tie to a customer/vendor/employee
        },
        {
            "accountRef":  {"fullName": "6130 - Insurance:6130.2 - Liability Insurance"},
            "amount":      450.00,
            "memo":        "May allocation - GL",
            "classRef":    {"fullName": "Admin (US)"},
        },
    ],

    "credits": [
        {
            "accountRef":  {"fullName": "1300 - Prepaid Insurance"},
            "amount":      1700.00,
            "memo":        "May allocation",
            "classRef":    {"fullName": "Admin (US)"},
        },
    ],
}

# Step 1: dry-run.
dr = client.dryrun("create_journal_entry", args)
print(dr["qbXml"])
print(dr["summary"])
for pf in dr["preFlight"]:
    print(pf["name"], "ok=", pf["ok"], "-", pf["detail"])
# Pre-flight will include a "debits_equal_credits" check.

# Step 2: SHOW to user. CONFIRM.

# Step 3: execute only after explicit "yes".
result = client.op("create_journal_entry", args)
print(result["status"], result["rows"][0]["TxnID"], "auditSeq:", result["auditSeq"])
```

### Line shape

Each line (in `debits` OR `credits`):

| Field | Required | Notes |
|---|---|---|
| `accountRef` | yes | `{listID}` or `{fullName}` |
| `amount` | yes | positive decimal — direction is determined by which list (debits or credits) |
| `memo` | no | per-line memo (shows in account register) |
| `classRef` | strongly recommended | `{listID}` or `{fullName}` — set so reports stay clean |
| `entityRef` | no | `{listID}` or `{fullName}` — customer / vendor / employee tag (e.g., for accruals tied to specific entities) |

### `isAdjustment`

Setting `isAdjustment: true` flags the JE as an "adjusting entry" — it appears differently in some reports (e.g., the Adjusting JE column in audit reports) and the trial balance comparison. Use for true period-end adjustments; leave false for reclasses.

---

## Common JE patterns

### 1. Reclassify an expense between classes

The user incorrectly classed a $500 expense as `Admin (US)` instead of `Data Center`. To fix:

```python
args = {
    "txnDate":   "2026-05-19",
    "refNumber": "RECLASS-2026-05-19",
    "memo":      "Reclass server hosting from Admin to Data Center",
    "debits": [
        {"accountRef": {"fullName": "6080 - Office General"}, "amount": 500, "classRef": {"fullName": "Data Center"}},
    ],
    "credits": [
        {"accountRef": {"fullName": "6080 - Office General"}, "amount": 500, "classRef": {"fullName": "Admin (US)"}},
    ],
}
```

(Net effect on account: $0. Net effect on classes: -$500 Admin, +$500 Data Center.)

### 2. Accrue revenue earned but not invoiced

```python
args = {
    "txnDate":   "2026-05-31",
    "refNumber": "ACCRUE-REV-2026-05",
    "memo":      "Accrue May consulting earned, to be invoiced June",
    "isAdjustment": True,
    "debits": [
        {"accountRef": {"fullName": "1200 - Accrued Receivable"}, "amount": 8500, "classRef": {"fullName": "CS"}},
    ],
    "credits": [
        {"accountRef": {"fullName": "1000 - Consulting"}, "amount": 8500, "classRef": {"fullName": "CS"}},
    ],
}
```

Reverse in June with the opposite entry (or `isAdjustment: true` + QB's auto-reverse feature in the UI).

### 3. Depreciation

```python
args = {
    "txnDate":   "2026-05-31",
    "refNumber": "DEPR-2026-05",
    "memo":      "May depreciation",
    "isAdjustment": True,
    "debits": [
        {"accountRef": {"fullName": "6095 - Depreciation Expense"}, "amount": 2100, "classRef": {"fullName": "Admin (US)"}},
    ],
    "credits": [
        {"accountRef": {"fullName": "1500 - Accumulated Depreciation"}, "amount": 2100, "classRef": {"fullName": "Admin (US)"}},
    ],
}
```

### 4. Owner distribution (multiple owners)

```python
args = {
    "txnDate":   "2026-05-19",
    "refNumber": "DIST-2026-05",
    "debits": [
        {"accountRef": {"fullName": "3001 - Owner A Distributions"}, "amount": 10000, "entityRef": {"fullName": "Owner A"}},
        {"accountRef": {"fullName": "3002 - Owner B Distributions"}, "amount": 10000, "entityRef": {"fullName": "Owner B"}},
    ],
    "credits": [
        {"accountRef": {"fullName": "1010 - Operating Checking"}, "amount": 20000},
    ],
}
```

But — recording a distribution as a check is usually cleaner (preserves the bank-account transaction trail). Use `create_check` instead unless there's a specific reason for a JE.

### 5. Closing entry (year-end / period-end)

The user transferring net income from `3900 - Net Income` (a system account) to `3000 - Retained Earnings`. QB does this automatically at fiscal year-end, but for interim or correction:

```python
args = {
    "txnDate":   "2026-12-31",
    "refNumber": "CLOSE-2026",
    "memo":      "Close 2026 net income to retained earnings",
    "isAdjustment": True,
    "debits":    [{"accountRef": {"fullName": "3900 - Net Income"}, "amount": NET_AMT}],
    "credits":   [{"accountRef": {"fullName": "3000 - Retained Earnings"}, "amount": NET_AMT}],
}
```

---

## Modifying an existing JE

`mod` with `entity="journalentry"` is NOT supported in v1 — the generic `mod` op only handles customer / vendor / invoice / bill / check. To change a JE: void via raw qbXML and re-create.

```python
xml = '''<?xml version="1.0"?>
<?qbxml version="16.0"?>
<QBXML><QBXMLMsgsRq onError="stopOnError">
  <TxnVoidRq>
    <TxnVoidType>JournalEntry</TxnVoidType>
    <TxnID>JE-TXN-...</TxnID>
  </TxnVoidRq>
</QBXMLMsgsRq></QBXML>'''
# Show xml + confirm, then:
result = client.qbxml(xml)
# Then create_journal_entry with corrected args.
```

## Finding JEs

```python
# All JEs this month:
jes = client.op("run_query", {"entity": "JournalEntry", "filters": {
    "TransactionDateRangeFilter": {"FromTxnDate": "2026-05-01", "ToTxnDate": "2026-05-31"}
}})

# Lookup by RefNumber:
matches = client.op("get_transaction", {"refNumber": "JE-2026-05-01", "txnType": "JournalEntry"})["matches"]
```

## What NOT to use JEs for

- Customer invoicing → use `create_invoice` (preserves AR subledger)
- Vendor bills → use `create_bill` (preserves AP subledger and 1099 tracking)
- Bank transactions → use `create_check` or bank-feed import
- Inventory adjustments → use `InventoryAdjustmentAdd` via raw qbXML (preserves item quantities)
- Sales tax remittance → use sales-tax payment via raw qbXML (preserves tax-agency tracking)

JEs to subledger accounts (AR, AP, Inventory) work but BYPASS the subledger detail — the GL balances are correct but the subledger drill-down is empty. Almost always wrong.

## Pointers

- Full safe-write workflow: [quickbooks-accounting](../quickbooks-accounting/SKILL.md)
- Account / class lookup before constructing JEs: [quickbooks-accounts-items-classes](../quickbooks-accounts-items-classes/SKILL.md)
- For invoices/bills/checks (preferred over JEs for normal txns): see those skills
