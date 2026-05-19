---
name: quickbooks-vendor-spend-and-1099
description: Analyze QuickBooks vendor spending — total YTD spend per vendor, identify largest cost drivers, prep 1099-MISC/NEC data for year-end tax filings, flag renewals coming due, find duplicate vendor records. Use when the user asks "how much did we pay [Vendor]?", "top vendors by spend", "prep 1099s", "which vendors hit the 1099 threshold?", or wants a vendor concentration analysis. Multi-tenant — default `technijian`.
---

# QuickBooks Vendor Spend & 1099 Prep

Two related needs, one skill:

1. **Operational vendor spend analysis** — who are we paying, how much, on what
2. **Year-end 1099 preparation** — which vendors crossed the $600 IRS reporting threshold

Multi-tenant: default `technijian`.

## Vendor spend analysis

```python
from qb_client import QbClient
from collections import defaultdict
client = QbClient.from_env().with_company("technijian")

period = {"fromDate": "2026-01-01", "toDate": "2026-05-19"}

# Bills paid + direct checks combined
spend = defaultdict(float)
for src in [
    client.op("list_bills", period)["rows"],
    # checks via raw qbXML (no list_checks op yet — use run_query):
    client.op("run_query", {"entity": "Check", "filters": {
        "TransactionDateRangeFilter": {"FromTxnDate": period["fromDate"], "ToTxnDate": period["toDate"]}
    }})["rows"],
]:
    for r in src:
        # For bills: VendorRef. For checks: PayeeEntityRef.
        vendor = (r.get("VendorRef") or r.get("PayeeEntityRef") or {}).get("FullName", "—")
        amount = float(r.get("AmountDue", 0) or r.get("Amount", 0) or 0)
        # For bills, "AmountDue" is what's still owed; "TotalAmount" is the original. Use what's relevant.
        spend[vendor] += amount

print("=== Top 25 vendors by spend YTD 2026 ===")
for v, amt in sorted(spend.items(), key=lambda x: -x[1])[:25]:
    print(f"  {v:35} ${amt:>12,.2f}")
```

Note: this counts BILLS by amount (whether paid or not) + CHECKS (already-paid disbursements). For "cash actually paid", use BillPaymentCheck + Check transactions only.

## Pattern: concentration risk

Vendor concentration = % of total spend going to your top N vendors. High concentration (e.g., one vendor = 30% of total spend) is a risk if they raise prices, churn, or fail.

```python
total = sum(spend.values())
sorted_v = sorted(spend.items(), key=lambda x: -x[1])
top10 = sum(amt for _, amt in sorted_v[:10])
print(f"Top-10 vendor concentration: {top10/total*100:.1f}% of total spend (${top10:,.0f} / ${total:,.0f})")
```

For an MSP, expected major vendors: Microsoft (Office 365), Cisco/SonicWall (security), Sophos/Huntress/Inky/NinJio (security stack), AT&T (internet), Gusto/ADP (payroll). If one of those is >25% you have a single-vendor dependency.

## Pattern: spend by class

Cross-tab vendor spend with class (which service line absorbs which vendor's costs):

Use raw qbXML `BillQueryRq` + `CheckQueryRq` with `IncludeLineItems=true`. Then for each line, get the line's `ClassRef` and `AccountRef`. Aggregate `vendor × class` matrix.

This is exactly what you need to validate that "Microsoft spend" all hits "Office 365 (Online Services)" class (it should — if it's hitting other classes, your bank-feed-classifier rules are misaligned).

## Pattern: anomaly detection

Compare each vendor's current month vs trailing average:

```python
# Pull last 6 months of bills
inv6 = client.op("list_bills", {"dateMacro": "Last6Months"})    # not a real dateMacro - use date range
# Group by vendor + month
monthly = defaultdict(lambda: defaultdict(float))
for r in inv6["rows"]:
    v = (r.get("VendorRef") or {}).get("FullName")
    m = r["TxnDate"][:7]
    monthly[v][m] += float(r.get("AmountDue", 0))

# Find vendors where THIS month's spend is >2x the trailing 3-month avg:
import statistics
for v, by_month in monthly.items():
    months = sorted(by_month.keys())
    if len(months) < 4: continue
    recent = by_month[months[-1]]
    trailing = [by_month[m] for m in months[-4:-1]]
    avg = statistics.mean(trailing)
    if avg > 0 and recent > 2 * avg:
        print(f"SPIKE: {v} — last month ${recent:,.0f} vs trailing avg ${avg:,.0f} ({recent/avg:.1f}x)")
```

This catches: doubled software subscription (auto-renewal price increase), accidental duplicate billing, or a one-time big purchase mis-classified as recurring.

## 1099 preparation

US tax form 1099-NEC (formerly 1099-MISC) must be filed for each unincorporated vendor paid >= $600 in a calendar year for services. QB tracks vendor 1099-eligibility via the `IsVendorEligibleFor1099` field.

```python
vendors = client.op("list_vendors", {"activeStatus": "Active"})["rows"]
eligible = [v for v in vendors if v.get("IsVendorEligibleFor1099") == "true"]
print(f"{len(eligible)} vendors flagged as 1099-eligible")

# For each, sum YTD spend
year_period = {"fromDate": "2026-01-01", "toDate": "2026-12-31"}
spend_by_vendor = defaultdict(float)
# ... aggregate as above ...

for v in eligible:
    vname = v["Name"]
    s = spend_by_vendor.get(vname, 0)
    threshold = "FILE" if s >= 600 else "below threshold"
    print(f"  {vname:35} ${s:>10,.2f}  {threshold}")
```

### Common 1099 mistakes to catch

1. **Vendor flagged 1099-eligible but no Tax ID on file** — need W-9 from them
2. **Vendor NOT flagged 1099-eligible but paid >$600 for services** — might still need to file; flag for human review
3. **Payments to corporations** — generally NOT 1099-reportable (most exemptions); QB's flag should be off
4. **Reimbursements vs services** — only services count; reimbursements of expenses don't

### 1099 reports via raw qbXML

```python
xml = '''<?xml version="1.0"?>
<?qbxml version="16.0"?>
<QBXML><QBXMLMsgsRq onError="stopOnError">
  <GeneralDetailReportQueryRq>
    <GeneralDetailReportType>Vendor1099Review</GeneralDetailReportType>
    <DisplayReport>false</DisplayReport>
    <ReportPeriod>
      <FromReportDate>2026-01-01</FromReportDate>
      <ToReportDate>2026-12-31</ToReportDate>
    </ReportPeriod>
  </GeneralDetailReportQueryRq>
</QBXMLMsgsRq></QBXML>'''
```

QB's built-in 1099 detail report shows everything coded to 1099-mapped accounts. Use this as the authoritative source for filing.

## Duplicate vendor detection

A common QB hygiene issue: same vendor entered twice with slightly different names ("AT&T", "AT&T Internet", "ATT Wireless"). Spend is fragmented across the duplicates → wrong 1099 totals, harder spend analysis.

```python
from difflib import SequenceMatcher

vendors = client.op("list_vendors", {"activeStatus": "All"})["rows"]
suspects = []
for i, v1 in enumerate(vendors):
    for v2 in vendors[i+1:]:
        n1, n2 = v1["Name"].lower(), v2["Name"].lower()
        if SequenceMatcher(None, n1, n2).ratio() > 0.85:
            suspects.append((v1["Name"], v2["Name"]))
for a, b in suspects:
    print(f"POSSIBLE DUP: {a}  vs  {b}")
```

Manually verify each — only merge if truly the same vendor (use QB UI's "merge vendors" feature; the SDK doesn't expose merge).

## Renewals / contract dates

QB doesn't track contract dates directly. If you want renewal alerts, you'd need a custom field on the vendor record (QB Enterprise supports custom fields). Or maintain a separate spreadsheet keyed on vendor name.

Heuristic for "this vendor is on auto-renew": find their billing cadence from recent bill dates. If the gap between charges is consistently 28-31 days → monthly auto-renew. If 89-92 days → quarterly. If 364-366 → annual.

## Pointers

- Bill management (creating bills): [quickbooks-bills](../quickbooks-bills/SKILL.md)
- Check management (direct disbursements): [quickbooks-checks-and-payments](../quickbooks-checks-and-payments/SKILL.md)
- Bank-feed auto-classification (so expenses are tagged with the right vendor): [quickbooks-bank-feed-classifier](../quickbooks-bank-feed-classifier/SKILL.md)
- Per-class spend (where does Microsoft's bill HIT — should be Office 365 class): [quickbooks-class-margin-analysis](../quickbooks-class-margin-analysis/SKILL.md)
