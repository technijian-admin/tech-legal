---
name: quickbooks-item-revenue-analysis
description: Analyze which QuickBooks items drive revenue for each class — pull items mapped to each class via their IncomeAccountRef, run Sales by Item reports, and identify the top-revenue items per service line. Use when the user asks "what items make up the [class] revenue?", "which items are driving [service line]?", "show me sales by item", "what's our top SKU?", or wants to validate item→class→income-account chains. Multi-tenant — default `technijian`.
---

# QuickBooks Item Revenue Analysis

This skill answers questions about WHICH items are generating revenue and HOW that revenue rolls up to classes:

- "What items are driving the Office 365 revenue?"
- "Show me YTD revenue by item for the Data Center class"
- "Are there items mapped to the wrong income account?"
- "What's our top-revenue SKU?"
- "Sales by item for the last month"

The mechanics chain three things QuickBooks tracks:

1. **Items** carry an `IncomeAccountRef` — the GL account the SALE of that item posts to
2. **Income accounts** are typically tied to a class category (e.g. `1001 - Online Services` accounts feed Online Services classes)
3. **Each invoice line** with that item can ALSO override the class → so the line's revenue lands on the line's class, NOT the item's "default" class (items don't have a default class — only invoice lines do)

So the actual mapping is **item → income account** is static, but **item revenue → class** depends on what classes were used on the invoice lines.

## Multi-tenant

`company=` or `QB_DEFAULT_COMPANY`. Default `technijian`. Authorized: `technijian`, `electronic-corporation-of-america`.

## The two main analyses

### A. Item catalog → income account map (static metadata)

```python
from qb_client import QbClient
client = QbClient.from_env().with_company("technijian")

items = client.op("list_items", {"activeStatus": "Active"})["rows"]
by_income_account = {}
for item in items:
    inc = (item.get("IncomeAccountRef") or {}).get("FullName", "—")
    by_income_account.setdefault(inc, []).append(item["FullName"])

for acct, item_names in sorted(by_income_account.items()):
    print(f"\n{acct}  ({len(item_names)} items)")
    for n in item_names[:10]:
        print(f"  {n}")
    if len(item_names) > 10:
        print(f"  ... +{len(item_names) - 10} more")
```

This tells you which items LITERALLY post to which income account. Useful for catching items mapped to the wrong account (the most common QB hygiene issue — a salesperson creates an item and picks the wrong income account, and now revenue ends up in the wrong P&L line).

### B. Sales by Item — revenue analysis (transactional)

Use the QB SDK's `SalesByItemSummaryReport`:

```python
xml = '''<?xml version="1.0"?>
<?qbxml version="16.0"?>
<QBXML><QBXMLMsgsRq onError="stopOnError">
  <GeneralSummaryReportQueryRq>
    <GeneralSummaryReportType>SalesByItemSummary</GeneralSummaryReportType>
    <DisplayReport>false</DisplayReport>
    <ReportPeriod>
      <FromReportDate>2026-01-01</FromReportDate>
      <ToReportDate>2026-05-31</ToReportDate>
    </ReportPeriod>
  </GeneralSummaryReportQueryRq>
</QBXMLMsgsRq></QBXML>'''
response_xml = client.qbxml(xml)
# Parse: rows = items, columns = [Quantity, Amount, %, Avg]
```

For richer line-level detail (one row per invoice line):

```python
xml = '''<?xml version="1.0"?>
<?qbxml version="16.0"?>
<QBXML><QBXMLMsgsRq onError="stopOnError">
  <GeneralDetailReportQueryRq>
    <GeneralDetailReportType>SalesByItemDetail</GeneralDetailReportType>
    <DisplayReport>false</DisplayReport>
    <ReportPeriod>
      <FromReportDate>2026-01-01</FromReportDate>
      <ToReportDate>2026-05-31</ToReportDate>
    </ReportPeriod>
  </GeneralDetailReportQueryRq>
</QBXMLMsgsRq></QBXML>'''
```

The Detail variant includes the customer + class + invoice ref for every line, which is the gold mine for cross-tab analysis.

### C. Cross-tab: item × class revenue matrix

This is what you actually want — "for each item, how much revenue, broken out by class?". There's no single QB report for this; build it by combining `list_invoices` with `includeLineItems=true`:

```python
from collections import defaultdict

inv = client.op("list_invoices", {
    "fromDate": "2026-01-01",
    "toDate":   "2026-05-31",
    "includeLineItems": True,
})

# Build item × class revenue matrix
matrix = defaultdict(lambda: defaultdict(float))
for row in inv["rows"]:
    for line in row.get("InvoiceLineRet", []):
        item_name = (line.get("ItemRef") or {}).get("FullName", "(no item)")
        # Class can be on the line, or fall back to the invoice header's class
        cls = (line.get("ClassRef") or row.get("ClassRef") or {"FullName": "(no class)"})["FullName"]
        amt = float(line.get("Amount", 0) or 0)
        matrix[item_name][cls] += amt

# Top 20 items by total revenue:
top_items = sorted(matrix.items(), key=lambda x: sum(x[1].values()), reverse=True)[:20]
for item, classes in top_items:
    total = sum(classes.values())
    print(f"\n{item}  total=${total:,.2f}")
    for cls, amt in sorted(classes.items(), key=lambda x: -x[1])[:5]:
        print(f"  {cls:35} ${amt:>10,.2f}")
```

This shows you "this item drove $40K of Office 365 revenue and $5K of Cisco Umbrella revenue" — which catches cases where the same item is being sold across classes (a hygiene flag — does that item really represent multiple service lines? Should it be split?).

## Pattern: items contributing to a target class

"Show me everything that contributed to Data Center class revenue in May":

```python
inv = client.op("list_invoices", {
    "fromDate": "2026-05-01",
    "toDate":   "2026-05-19",
    "includeLineItems": True,
})

target_class = "Data Center"
contributions = []
for row in inv["rows"]:
    inv_class = (row.get("ClassRef") or {}).get("FullName")
    for line in row.get("InvoiceLineRet", []):
        line_class = (line.get("ClassRef") or {}).get("FullName") or inv_class
        if line_class != target_class:
            continue
        contributions.append({
            "txn_date":  row["TxnDate"],
            "refnumber": row.get("RefNumber"),
            "customer":  (row.get("CustomerRef") or {}).get("FullName"),
            "item":      (line.get("ItemRef") or {}).get("FullName"),
            "desc":      line.get("Desc"),
            "amount":    float(line.get("Amount", 0) or 0),
        })

# Sort by amount descending:
contributions.sort(key=lambda c: -c["amount"])
total = sum(c["amount"] for c in contributions)
print(f"\n=== {target_class} revenue May 1-19 2026: ${total:,.2f} ({len(contributions)} lines) ===")
for c in contributions[:30]:
    print(f"  {c['txn_date']}  {c['refnumber']:12} {c['customer']:30} {c['item']:30} ${c['amount']:>10,.2f}")
```

## Pattern: item hygiene check (catching wrong income-account mappings)

"Are any items mapped to a 5xxx (COGS) or 6xxx (Expense) account by mistake instead of an income account?"

```python
items = client.op("list_items", {"activeStatus": "Active"})["rows"]
suspicious = []
for item in items:
    inc = (item.get("IncomeAccountRef") or {}).get("FullName", "")
    if not inc:
        continue
    # Extract leading 4-digit prefix; flag if it's 5xxx (COGS) or 6xxx+ (expense)
    import re
    m = re.match(r"^(\d{3,4})", inc)
    if m:
        n = int(m.group(1))
        if n >= 5000:
            suspicious.append((item["FullName"], item["type"], inc))

print(f"{len(suspicious)} items with suspicious income-account mapping:")
for name, t, acct in suspicious:
    print(f"  {t:14} {name:50} → {acct}")
```

Any service item whose `IncomeAccountRef` points at a 5xxx or 6xxx account is almost certainly mis-mapped — clients will be invoiced and the sale will reduce a COGS account instead of INCREASE income. Fix by editing the item to point at the right 1xxx/4xxx income account.

## Pattern: items contributing to revenue but missing class on lines

Items don't carry class; lines do. Find lines with no class:

```python
inv = client.op("list_invoices", {
    "fromDate": "2026-01-01",
    "toDate":   "2026-05-19",
    "includeLineItems": True,
})

no_class = []
for row in inv["rows"]:
    inv_class = (row.get("ClassRef") or {}).get("FullName")
    for line in row.get("InvoiceLineRet", []):
        line_class = (line.get("ClassRef") or {}).get("FullName") or inv_class
        if not line_class:
            no_class.append({
                "date":     row["TxnDate"],
                "ref":      row.get("RefNumber"),
                "customer": (row.get("CustomerRef") or {}).get("FullName"),
                "item":     (line.get("ItemRef") or {}).get("FullName"),
                "amount":   float(line.get("Amount", 0) or 0),
            })

print(f"{len(no_class)} lines without a class — total ${sum(l['amount'] for l in no_class):,.2f}")
```

These are revenue items NOT being class-tracked. Fix forward by:
1. Editing the historical invoice lines to add the class (via raw qbXML — there's no wrapped op for line-level mod yet)
2. Adjusting your sales process so the class is selected at invoice creation
3. Or adding a default class to the customer (in QB Preferences → Customers) so invoices for that customer inherit the class

## Recurring revenue / MRR analysis

For an MSP, recurring revenue is the heart of the business. Items used in recurring billing typically have names like "MS365-E3-Monthly", "Sophos-Endpoint-Monthly", "Backup-100GB-Monthly", etc. Filter:

```python
items = client.op("list_items", {"activeStatus": "Active"})["rows"]
recurring = [i for i in items if "Monthly" in i["FullName"] or "MRR" in i["FullName"]]
```

Then run `list_invoices` for the same month, sum amounts where item is in `recurring`, and you have the MRR for that month. Track month-over-month for growth/churn analysis.

## Validate item → class mapping consistency

For an MSP where item-to-class is supposed to be 1:1 (e.g., MS365-E3-Monthly should ONLY ever appear on Office 365 class), check for inconsistencies:

```python
from collections import defaultdict

inv = client.op("list_invoices", {"dateMacro": "ThisFiscalYearToDate", "includeLineItems": True})
item_classes = defaultdict(set)
for row in inv["rows"]:
    inv_class = (row.get("ClassRef") or {}).get("FullName")
    for line in row.get("InvoiceLineRet", []):
        item = (line.get("ItemRef") or {}).get("FullName")
        cls = (line.get("ClassRef") or {}).get("FullName") or inv_class
        if item and cls:
            item_classes[item].add(cls)

# Items used across multiple classes:
multi_class = {item: classes for item, classes in item_classes.items() if len(classes) > 1}
for item, classes in sorted(multi_class.items(), key=lambda x: -len(x[1])):
    print(f"{item:40} → {len(classes)} classes: {', '.join(sorted(classes))}")
```

Items appearing across many classes are either:
1. Legitimately cross-cutting (e.g. "Consulting:Senior" hour rate billed to many service lines)
2. Sloppy class selection at invoice time (most common — easy to fix going forward)

## Pointers

- Static item/account/class lookup: [quickbooks-accounts-items-classes](../quickbooks-accounts-items-classes/SKILL.md)
- Class-level margin analysis: [quickbooks-class-margin-analysis](../quickbooks-class-margin-analysis/SKILL.md)
- The general report mechanics: [quickbooks-reports](../quickbooks-reports/SKILL.md)
- Invoice CRUD: [quickbooks-invoices](../quickbooks-invoices/SKILL.md)
