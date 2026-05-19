---
name: quickbooks-customer-profitability
description: Analyze per-customer profitability in QuickBooks — revenue minus direct costs (billable expenses, job-costed time) per customer over a period. Use when the user asks "which customers are profitable?", "what's our cost-to-serve [Customer]?", "show me customer P&L", or wants to rank customers by margin contribution. Multi-tenant — default `technijian`.
---

# QuickBooks Customer Profitability

For an MSP, knowing which customers ACTUALLY make money (revenue minus the labor + product cost of serving them) is critical. Some customers buy a $200/mo Office 365 subscription but consume $1500/mo of support time — they're losing money for you, even though they pay every month.

Multi-tenant: default `technijian`.

## The core calculation

```
Customer Net Margin = Revenue − Direct Costs Allocated to Customer
```

Where:
- **Revenue** = sum of invoice lines where `CustomerRef == customer` over the period
- **Direct Costs** = (a) billable expenses tied to that customer + (b) labor hours allocated to that customer × labor rate + (c) reimbursable costs

The challenge: QB tracks (a) cleanly (bills/checks with `CustomerRef`), but (b) requires good timesheet hygiene (employee time entries tagged with the customer) and (c) requires bills marked `BillableStatus=Billable`.

## QB's built-in tool: Job Profitability reports

```python
xml = '''<?xml version="1.0"?>
<?qbxml version="16.0"?>
<QBXML><QBXMLMsgsRq onError="stopOnError">
  <GeneralSummaryReportQueryRq>
    <GeneralSummaryReportType>JobProfitabilitySummary</GeneralSummaryReportType>
    <DisplayReport>false</DisplayReport>
    <ReportPeriod>
      <FromReportDate>2026-01-01</FromReportDate>
      <ToReportDate>2026-05-19</ToReportDate>
    </ReportPeriod>
  </GeneralSummaryReportQueryRq>
</QBXMLMsgsRq></QBXML>'''
response_xml = client.qbxml(xml)
# Rows = customers (and customer:job), columns = Actual Revenue, Actual Cost, Difference
```

Use `JobProfitabilityDetail` for line-level detail (which invoices, which expenses).

## Manual calc when Job Profitability isn't enough

If your timesheet hygiene is weak, supplement with this:

```python
from collections import defaultdict
from qb_client import QbClient
client = QbClient.from_env().with_company("technijian")

period_args = {"fromDate": "2026-01-01", "toDate": "2026-05-19"}

# Revenue per customer
inv = client.op("list_invoices", {**period_args, "includeLineItems": True})
revenue = defaultdict(float)
for r in inv["rows"]:
    cust = (r.get("CustomerRef") or {}).get("FullName", "(no customer)")
    revenue[cust] += float(r.get("Subtotal", 0) or r.get("TotalAmount", 0))

# Billable expenses per customer (bills + checks with CustomerRef on expense lines)
billable = defaultdict(float)
for src in (client.op("list_bills", period_args)["rows"], client.op("list_payments", period_args)["rows"]):
    for r in src:
        # NOTE: list_bills returns header rows by default. To get per-line CustomerRef
        # you need raw qbXML BillQueryRq with IncludeLineItems. Same for checks via run_query.
        pass

# A more reliable path: raw qbXML
xml = '''<?xml version="1.0"?>
<?qbxml version="16.0"?>
<QBXML><QBXMLMsgsRq onError="stopOnError">
  <BillQueryRq>
    <ModifiedDateRangeFilter>
      <FromModifiedDate>2026-01-01</FromModifiedDate>
      <ToModifiedDate>2026-05-19</ToModifiedDate>
    </ModifiedDateRangeFilter>
    <IncludeLineItems>true</IncludeLineItems>
  </BillQueryRq>
</QBXMLMsgsRq></QBXML>'''
# Parse line items, sum amounts where ExpenseLineRet/CustomerRef matches each customer
```

## Pattern: top + bottom customers by margin

```python
def customer_margin_report(client, from_date, to_date):
    inv = client.op("list_invoices", {"fromDate": from_date, "toDate": to_date})
    revenue = defaultdict(float)
    for r in inv["rows"]:
        cust = (r.get("CustomerRef") or {}).get("FullName", "—")
        revenue[cust] += float(r.get("Subtotal", 0) or 0)

    # Pull billable expenses (raw qbXML, IncludeLineItems=true)
    # ... sum into expense[cust]

    rows = []
    for cust, rev in revenue.items():
        exp = expense.get(cust, 0)
        net = rev - exp
        margin_pct = (net / rev * 100) if rev > 0 else None
        rows.append({"customer": cust, "revenue": rev, "direct_cost": exp, "net": net, "margin_pct": margin_pct})
    return rows

rows = customer_margin_report(client, "2026-01-01", "2026-05-19")
top = sorted([r for r in rows if r["revenue"] > 1000], key=lambda r: -r["net"])
print("=== Top 20 by net contribution ===")
for r in top[:20]:
    print(f"  {r['customer']:30} rev=${r['revenue']:>10,.0f}  cost=${r['direct_cost']:>10,.0f}  net=${r['net']:>10,.0f}  margin={r['margin_pct']:.0f}%")

bottom = sorted([r for r in rows if r["revenue"] > 0 and r["net"] < 0], key=lambda r: r["net"])
print("\n=== Customers losing money (revenue > 0, net < 0) ===")
for r in bottom[:10]:
    print(f"  {r['customer']:30} rev=${r['revenue']:>10,.0f}  cost=${r['direct_cost']:>10,.0f}  net=${r['net']:>10,.0f}")
```

## The labor-time gap

QB's built-in Job Profitability includes labor cost ONLY when employee time is entered AND the employee has an hourly cost configured AND the time entries are tagged with the right `CustomerRef`. If you don't track time per customer in QB, you can:

1. **Allocate labor by revenue mix** — total labor cost × (customer revenue / total revenue) as a proxy. Rough but informative for big customers.
2. **Manual entry** — operator supplies hours per customer per period from another system (e.g. ScreenConnect session times).
3. **Skip labor** — only count billable expenses. Underestimates true cost but easy.

## What "profitable" actually means for an MSP customer

A real customer-profitability framework needs:
- **Direct material cost** (Microsoft licenses, hardware passed through) — from billable bills
- **Direct labor cost** (support hours, project hours) — from timesheets
- **Allocated overhead** (admin, management, marketing) — typically %-allocated by revenue
- **Customer-acquisition amortization** (if applicable)

Net of all four = "fully loaded margin". MSPs commonly target 30-50% fully loaded margin per customer. Below 15% is usually unsustainable.

## Common questions

### "Who are our worst-profitability customers?"

Run `customer_margin_report` for last 6 months, filter `margin_pct < 20`, sort by revenue descending. These are the customers consuming the most support time per dollar of revenue.

### "Should we fire customer X?"

Pull their YTD revenue, billable expenses, AND estimate labor (timesheets if available, or revenue-allocated). Compare net margin to your minimum threshold. If they're losing money for 6+ months and a price increase isn't possible, fire-via-non-renewal at next contract anniversary.

### "Which customer paid us the most?"

```python
inv = client.op("list_invoices", {"dateMacro": "ThisFiscalYearToDate"})
revenue = defaultdict(float)
for r in inv["rows"]:
    cust = (r.get("CustomerRef") or {}).get("FullName", "—")
    revenue[cust] += float(r.get("TotalAmount", 0))

for cust, amt in sorted(revenue.items(), key=lambda x: -x[1])[:20]:
    print(f"  {cust:30} ${amt:>12,.2f}")
```

(That's gross revenue, not profit. Top revenue customers aren't always your most profitable — they're often the ones with the lowest margin.)

## Pointers

- For per-class margin (instead of per-customer): [quickbooks-class-margin-analysis](../quickbooks-class-margin-analysis/SKILL.md)
- For revenue by item: [quickbooks-item-revenue-analysis](../quickbooks-item-revenue-analysis/SKILL.md)
- For AR collections (the cash-collection side): [quickbooks-ar-collections](../quickbooks-ar-collections/SKILL.md)
- General report mechanics: [quickbooks-reports](../quickbooks-reports/SKILL.md)
