---
name: quickbooks-accounts-items-classes
description: Look up QuickBooks chart of accounts, items (with their tied income/expense accounts), and classes through QbConnectService. Use when the user asks about the chart of accounts, what account an item posts to, what classes exist, or needs item/account/class metadata to construct invoices, bills, checks, or journal entries. Multi-tenant — default `technijian`.
---

# QuickBooks Accounts, Items & Classes

These three lists are the metadata layer everything else builds on:

- **Accounts** = the chart of accounts (assets, liabilities, equity, income, COGS, expense)
- **Items** = the products/services you invoice/buy — each item points at an INCOME account (for sale) and often an EXPENSE/COGS account (for purchase)
- **Classes** = the cross-cutting dimension for departments / locations / business lines (Admin, Marketing, Data Center, Support (India), CS, etc.)

You'll use this skill mostly as **lookup** when constructing transaction args for other skills.

## Multi-tenant

`company=` or `QB_DEFAULT_COMPANY`. Default `technijian`. Currently authorized: `technijian`, `electronic-corporation-of-america`.

---

## Chart of Accounts (`list_accounts`)

```python
from qb_client import QbClient
client = QbClient.from_env().with_company("technijian")

# All active accounts:
result = client.op("list_accounts", {"activeStatus": "Active"})
for row in result["rows"]:
    print(row["FullName"], "/", row["AccountType"], "/ Balance:", row.get("Balance"))
```

Args:

| Arg | Type | Description |
|---|---|---|
| `activeStatus` | `Active` / `Inactive` / `All` | Default `All`. |
| `name` | substring | Filter by name. |
| `nameMatch` | `Contains` / `StartsWith` / `EndsWith` | Default `Contains`. |

### Account fields you'll typically use

- `ListID` — stable reference, use for refs in transactions
- `FullName` — human-readable, e.g. `"6080 - Office General:6080.13 - Internet"`. Use as `{fullName}` ref.
- `AccountType` — `Bank`, `AccountsReceivable`, `OtherCurrentAsset`, `FixedAsset`, `AccountsPayable`, `CreditCard`, `OtherCurrentLiability`, `LongTermLiability`, `Equity`, `Income`, `CostOfGoodsSold`, `Expense`, `OtherIncome`, `OtherExpense`, `NonPosting`
- `AccountNumber` — the user's CoA numbering (e.g. `6080`, `6080.13`)
- `Balance` — current balance (for balance-sheet accounts) or YTD activity (for P&L accounts)
- `Sublevel` — depth in the hierarchy. `0` = top-level, `1` = first sub, etc.
- `ParentRef` — the parent account if this is a sub-account

### Technijian's CoA numbering convention

(Discovered from real data, 2026-05-18 — non-standard but consistent):

| Range | Category | Examples |
|---|---|---|
| 1000–1009 | Income (consulting, sales, services) | 1000 - Consulting, 1001 - Online Services, 1002 - Sales |
| 1010+ | Bank / current assets | 1010 - Operating Checking |
| 2000s | Liabilities | 2000 - Accounts Payable |
| 3000s | Equity | 3000 - Owner Equity |
| 4xxx | Other Income | 4020 - Other Regular Income |
| 5xxx | COGS | 5500 - Direct Labor Costs, 5501 - Software Licensing, 5502 - Internet Support, 5503 - Hardware Costs, 5504 - Commissions |
| 6xxx | Expenses | 6000 - Advertising, 6010 - Auto, 6020 - Bank Service Charges, 6030 - Commission and Fees, 6040 - Dues, 6045 - Employee Benefits, 6060 - Taxes, 6065 - Interest, 6070 - Legal & Professional, 6080 - Office General, 6085 - Office Expense, 6090 - Rent, 6110 - Travel & Ent, 6115 - Payroll, 6130 - Insurance |

When picking an account for an expense line, use `AccountType` not just the number — non-standard CoAs can break the number-prefix heuristic. Use the account-by-type pattern:

```python
expense_accts = [r for r in client.op("list_accounts")["rows"] if r["AccountType"] in ("Expense", "OtherExpense")]
income_accts  = [r for r in client.op("list_accounts")["rows"] if r["AccountType"] == "Income"]
bank_accts    = [r for r in client.op("list_accounts")["rows"] if r["AccountType"] == "Bank"]
```

---

## Items (`list_items`)

Items are polymorphic — `ServiceItem`, `InventoryItem`, `NonInventoryItem`, `OtherChargeItem`, `DiscountItem`, `PaymentItem`, `SalesTaxItem`, `GroupItem`, etc. The op's parser normalizes them and adds a `type` field on each row.

```python
result = client.op("list_items", {"activeStatus": "Active"})
for row in result["rows"]:
    print(row["type"], row["FullName"],
          "income→", (row.get("IncomeAccountRef") or {}).get("FullName"),
          "expense→", (row.get("ExpenseAccountRef") or {}).get("FullName"),
          "cogs→",    (row.get("COGSAccountRef") or {}).get("FullName"))
```

### Key item fields

| Field | Present on | Description |
|---|---|---|
| `type` | all | normalized type added by parser (`Service`, `Inventory`, `NonInventory`, `OtherCharge`, etc.) |
| `ListID`, `FullName`, `Name` | all | identity |
| `IsActive` | all | bool |
| `IncomeAccountRef` | Service, Inventory, NonInventory (when sold), OtherCharge | which Income account a sale of this item posts to |
| `ExpenseAccountRef` | Service (when also tracking expense), NonInventory (when bought) | which Expense account a purchase posts to |
| `COGSAccountRef` | Inventory | the COGS account hit on sale |
| `AssetAccountRef` | Inventory | the inventory asset account |
| `SalesTaxCodeRef` | most | default tax code |
| `SalesPrice` / `SalesRate` | most | default sales rate |
| `PurchaseCost` / `Cost` | Inventory, NonInventory (when bought) | default purchase cost |
| `ParentRef` | all (when sub-item) | hierarchy |
| `IsTaxIncluded` | most | bool |

### "What accounts is item X set up for?"

```python
def item_accounts(name):
    rows = client.op("list_items", {"name": name, "nameMatch": "StartsWith"})["rows"]
    for r in rows:
        inc = (r.get("IncomeAccountRef") or {}).get("FullName")
        exp = (r.get("ExpenseAccountRef") or {}).get("FullName")
        cogs = (r.get("COGSAccountRef") or {}).get("FullName")
        asset = (r.get("AssetAccountRef") or {}).get("FullName")
        print(f"{r['type']:14} {r['FullName']:50}  income={inc}  expense={exp}  cogs={cogs}  asset={asset}")
```

This is the standard pre-write check before creating an invoice or bill with item lines — verify the item maps to the income/expense/class you expect.

### Items don't have classRef

Items don't carry a class. Class is on the **transaction line**, not the item. When you create an invoice line with `"itemRef": {"fullName": "Hardware:Switch"}` and `"classRef": {"fullName": "Data Center"}`, the class flows through the GL entry for that line.

---

## Classes (`run_query` with `entity=Class`)

There's no dedicated `list_classes` op — use the generic `run_query`:

```python
result = client.op("run_query", {"entity": "Class"})
for row in result["rows"]:
    print(row["FullName"], "/ IsActive:", row["IsActive"], "/ Sublevel:", row["Sublevel"])
```

### Filtering

```python
# Active only:
client.op("run_query", {"entity": "Class", "filters": {"ActiveStatus": "ActiveOnly"}})

# By name:
client.op("run_query", {"entity": "Class", "filters": {"FullName": "Admin (US)"}})
```

### Technijian's class structure (snapshot 2026-05-18)

67 classes total in `technijian.qbw`. Major groupings observed in the P&L by Class:

| Cost-center class | Examples |
|---|---|
| Admin / Management | Admin (US), Admin (India), Management (US), Executive |
| Sales / Marketing | Marketing, Sales |
| Engineering | Development (US), Development (India), Support (US), Support (India), A.I. |
| Operational services | Data Center, CS, My OPS, Online Services |
| Product / partner pass-through | Office 365, Cisco Umbrella, Sophos, Huntress, Inky, NinJio, Kaseya, ManageEngine, Screen connect, GoDaddy, Centrastack, FoxIT, Passportal, OneLogin, DIDForSale, EasyDMARC, ManageEngine, Synology, SPLA, My Private Cloud, Email |
| Sub-groups (hierarchical) | Amex (Finance), Leases (Finance), Total Finance is the rollup |

**Class hygiene rule:** every income and expense line should have a `classRef` set. Lines without a class fall into "No Class" in reports and obscure the by-class P&L. The classification report we ran on 2026-05-18 was clean — no major "No Class" bucket.

---

## Building an item / account / class catalog locally

If you'll be constructing many transactions, cache the lists once:

```python
accounts = {r["FullName"]: r for r in client.op("list_accounts", {"activeStatus": "Active"})["rows"]}
items    = {r["FullName"]: r for r in client.op("list_items",    {"activeStatus": "Active"})["rows"]}
classes  = {r["FullName"]: r for r in client.op("run_query", {"entity": "Class", "filters": {"ActiveStatus": "ActiveOnly"}})["rows"]}

# Then validate before building a transaction:
assert "6080 - Office General:6080.13 - Internet" in accounts
assert "Hardware:Catalyst-2960" in items
assert "Admin (US)" in classes
```

QB names are case-sensitive on the wire even though the QB UI is forgiving. Use the exact `FullName` from the lookup.

## Pointers

- Building invoices that reference these: [quickbooks-invoices](../quickbooks-invoices/SKILL.md)
- Building bills / checks: [quickbooks-bills](../quickbooks-bills/SKILL.md), [quickbooks-checks-and-payments](../quickbooks-checks-and-payments/SKILL.md)
- P&L by class reports: [quickbooks-reports](../quickbooks-reports/SKILL.md)