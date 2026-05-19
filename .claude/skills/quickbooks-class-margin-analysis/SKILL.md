---
name: quickbooks-class-margin-analysis
description: Analyze gross margin by QuickBooks class (service line / department) — pull revenue and direct costs per class, compute gross margin %, flag classes underperforming their target, and trend margins over time. Use when the user asks "are we hitting our gross margin on [service]?", "which classes are losing money?", "show me margin by service line", or "is [class] profitable?". Multi-tenant — default `technijian`.
---

# QuickBooks Class Margin Analysis

This skill is the analytical layer on top of [quickbooks-reports](../quickbooks-reports/SKILL.md). It answers questions like:

- "Are we hitting our 60% gross margin target on Office 365?"
- "Which classes lost money last quarter?"
- "How is the Data Center margin trending?"
- "Is the Cisco Umbrella business actually profitable after direct costs?"

For Technijian as an MSP, classes ARE service lines. Each class should have a target gross margin (typically 50-70% for software pass-through, 30-50% for labor-heavy services). This skill tells you whether you're hitting it.

## Multi-tenant

`company=` or `QB_DEFAULT_COMPANY`. Default `technijian`. Authorized: `technijian`, `electronic-corporation-of-america`.

## The core calculation

```
Gross Margin % = (Revenue − Direct Costs) / Revenue × 100
```

Where:
- **Revenue** = sum of Income account postings for the class (1xxx + 4xxx in Technijian's CoA)
- **Direct Costs** = sum of COGS account postings for the class (5xxx in Technijian's CoA)
- Operating expenses (6xxx) are NOT in direct cost — they're below gross margin (operating margin / net margin levels)

Why exclude 6xxx from gross margin? Because gross margin reflects the unit economics of the service — every dollar of Office 365 sold costs you the wholesale Microsoft license + a chunk of support labor. 6xxx expenses (rent, admin salary, marketing) don't scale with the next unit sold; they're overhead.

## How to pull the numbers

The mechanics are the same as [quickbooks-reports](../quickbooks-reports/SKILL.md): use raw qbXML `GeneralSummaryReportQueryRq` with `SummarizeColumnsBy=Class`. The classification engine is in `C:\tmp\parse-pl-by-class.ps1`.

```python
from qb_client import QbClient
client = QbClient.from_env().with_company("technijian")

xml = '''<?xml version="1.0"?>
<?qbxml version="16.0"?>
<QBXML><QBXMLMsgsRq onError="stopOnError">
  <GeneralSummaryReportQueryRq>
    <GeneralSummaryReportType>ProfitAndLossStandard</GeneralSummaryReportType>
    <DisplayReport>false</DisplayReport>
    <ReportPeriod>
      <FromReportDate>2026-01-01</FromReportDate>
      <ToReportDate>2026-05-31</ToReportDate>
    </ReportPeriod>
    <SummarizeColumnsBy>Class</SummarizeColumnsBy>
  </GeneralSummaryReportQueryRq>
</QBXMLMsgsRq></QBXML>'''

response = client.qbxml(xml)
# Parse XML — see parse-pl-by-class.ps1 for the reference Python/PS pattern
```

Once parsed, classify each row by account number prefix (or account-type via `list_accounts`):

| Account range (Technijian CoA) | Bucket |
|---|---|
| 1000–1009, 4xxx | Revenue (Income) |
| 5xxx | Direct Cost (COGS) |
| 6xxx, 7xxx | Operating Expense (below gross margin) |
| 8xxx, 9xxx | Other Income / Expense |

Then per class:
```
gross_margin_pct[class] = (revenue[class] − cogs[class]) / revenue[class] × 100
contribution_margin[class] = revenue[class] − cogs[class] − operating_expense[class]
```

## Target margins (Technijian-specific baseline)

These are MY recommendations based on industry norms for an MSP. Validate with the actual P&L data and adjust:

| Class category | Typical gross margin target | Why |
|---|---|---|
| Software pass-through (Office 365, Cisco Umbrella, Sophos, Huntress, Inky, NinJio, Kaseya, ManageEngine, GoDaddy, Centrastack, FoxIT, Passportal, OneLogin, EasyDMARC, DIDForSale) | 30–50% | Wholesale-retail spread; competitive market |
| Managed services (CS, Support, My OPS) | 40–60% | Labor-intensive but scales |
| Cloud / Data Center | 50–70% | Higher margin infra |
| Leases (Finance) | 5–15% | Thin spread (margin financing business) |
| Development | 35–55% | Skilled labor |
| Admin / Management / Executive / Marketing | N/A | These are cost centers; should have $0 revenue, all expense |

If a class doesn't hit its target, the diagnosis is usually one of:
1. **Underpriced** — your sale price is too low relative to wholesale cost
2. **Wrong cost class allocation** — costs are landing on the wrong class
3. **Labor leak** — internal labor on this class is unbilled / over-budget
4. **Volume issue** — fixed costs amortized over too few units

## YTD 2026 reference (from the 2026-05-18 report run)

Technijian's actual margin picture YTD:

| Class | Revenue | Direct (5xxx) + OpEx (6xxx) Total | Net | Comment |
|---|---|---|---|---|
| Leases (Finance) | $516,693 | $510,766 | +$5,926 | Thin-spread financing — expected |
| Support (India) | $91,065 | $95,842 | -$4,777 | UNDER — investigate labor utilization |
| Data Center | $47,406 | $19,564 | +$27,843 | STRONG margin business |
| Office 365 | $40,709 | $28,363 | +$12,346 | Healthy |
| Development (US) | $31,163 | $42,344 | -$11,182 | UNDER — unbillable hours |
| CS | $25,000 | $7,319 | +$17,681 | STRONG |
| Cisco Umbrella | $16,181 | $2,979 | +$13,202 | STRONG |

Important caveat: this "Total" number includes 6xxx operating expenses, not just 5xxx direct costs. For TRUE gross margin, separate 5xxx and 6xxx as the parser does.

## Pattern: per-class margin breakdown for one period

```python
import xml.etree.ElementTree as ET

def class_margin_report(client, from_date, to_date, target_margins=None):
    """Returns list of {class, revenue, direct_cost, opex, gross_margin_pct, vs_target}."""
    xml = f'''<?xml version="1.0"?><?qbxml version="16.0"?>
    <QBXML><QBXMLMsgsRq onError="stopOnError">
      <GeneralSummaryReportQueryRq>
        <GeneralSummaryReportType>ProfitAndLossStandard</GeneralSummaryReportType>
        <DisplayReport>false</DisplayReport>
        <ReportPeriod><FromReportDate>{from_date}</FromReportDate><ToReportDate>{to_date}</ToReportDate></ReportPeriod>
        <SummarizeColumnsBy>Class</SummarizeColumnsBy>
      </GeneralSummaryReportQueryRq>
    </QBXMLMsgsRq></QBXML>'''
    doc = ET.fromstring(client.qbxml(xml))
    rs = doc.find(".//GeneralSummaryReportQueryRs/ReportRet")

    # Build column map: colID -> class name (skip Label and Total columns)
    cols = {}
    for cd in rs.findall("ColDesc"):
        if cd.find("ColType").text != "Amount":
            continue
        titles = [t.attrib.get("value", "") for t in cd.findall("ColTitle")]
        title = " ".join(t for t in titles if t).strip()
        if title:
            cols[cd.attrib["colID"]] = title

    # Sum per-class by category
    out = {cls: {"revenue": 0, "direct": 0, "opex": 0} for cls in cols.values()}
    for row in rs.findall("ReportData/DataRow"):
        if row.find("RowData").attrib.get("rowType") != "account":
            continue
        acct = row.find("RowData").attrib.get("value", "")
        cat = _classify_account(acct)
        if cat is None:
            continue
        for cd in row.findall("ColData"):
            cls = cols.get(cd.attrib["colID"])
            v = cd.attrib.get("value")
            if cls and v:
                out[cls][cat] += float(v)

    # Compute margin
    target_margins = target_margins or {}
    rows = []
    for cls, vals in out.items():
        rev = vals["revenue"]
        direct = vals["direct"]
        opex = vals["opex"]
        gm_pct = ((rev - direct) / rev * 100) if rev > 0 else None
        target = target_margins.get(cls)
        rows.append({
            "class": cls,
            "revenue": rev, "direct_cost": direct, "opex": opex,
            "gross_margin_pct": gm_pct,
            "target_margin_pct": target,
            "vs_target": (gm_pct - target) if gm_pct is not None and target is not None else None,
            "net": rev - direct - opex,
        })
    return rows

def _classify_account(name):
    """Return 'revenue' / 'direct' / 'opex' / None based on account number prefix."""
    import re
    m = re.match(r"^(\d{3,4})", name)
    if not m:
        return "revenue"   # default (e.g. "Finance Charges")
    n = int(m.group(1))
    if   5000 <= n <  6000: return "direct"
    elif 6000 <= n <  8000: return "opex"
    elif    1 <= n <  5000: return "revenue"
    return None

# Run it:
rows = class_margin_report(client, "2026-01-01", "2026-05-31", target_margins={
    "Office 365 (Online Services)":     45,
    "Cisco Umbrella":                    50,
    "Sophos":                            45,
    "Huntress":                          50,
    "Inky":                              45,
    "Data Center - Other (Data Center)": 55,
    "Support (India)":                   45,
    "CS":                                50,
    # ... define targets for each service line you care about
})

# Sort by GM% gap to target (worst first):
flagged = [r for r in rows if r["vs_target"] is not None]
flagged.sort(key=lambda r: r["vs_target"])
for r in flagged[:10]:
    print(f"{r['class']:35} rev=${r['revenue']:>10,.0f}  GM={r['gross_margin_pct']:.1f}%  target={r['target_margin_pct']}%  gap={r['vs_target']:+.1f}pt")
```

## Pattern: margin trend over time

Run the same query per period (month, quarter), capture the GM% per class, and plot trends:

```python
trends = {}    # cls -> list of (period, GM%)
for (label, frm, to) in [
    ("2025-Q4", "2025-10-01", "2025-12-31"),
    ("2026-Q1", "2026-01-01", "2026-03-31"),
    ("2026-QTD", "2026-04-01", "2026-05-31"),
]:
    for r in class_margin_report(client, frm, to):
        trends.setdefault(r["class"], []).append((label, r["gross_margin_pct"]))

# Surface classes whose margin is trending down:
for cls, points in trends.items():
    if all(gm is not None for _, gm in points) and points[0][1] > points[-1][1] + 5:
        print(f"DECLINING: {cls} — {points[0][0]} {points[0][1]:.1f}% → {points[-1][0]} {points[-1][1]:.1f}%")
```

## What to do when a class misses target

1. **Drill into the COGS detail** — run a `ProfitAndLossDetail` report filtered by class. Look at every transaction posting to a 5xxx account for that class. Are there entries that don't belong (wrong class assignment)?
2. **Check the labor allocation** — for labor-heavy classes (Development, Support, CS), the "direct cost" includes 5500 Direct Labor. Are timesheet hours being assigned the right class?
3. **Compare against past periods** — was this class previously hitting target? What changed? New vendor pricing? Lost customer? Increased churn?
4. **Check item pricing** — pull `list_items` for items that map to this class's income account. Are sales prices in line with current wholesale costs?

## Pointers

- Pulling raw P&L by class data: [quickbooks-reports](../quickbooks-reports/SKILL.md)
- Item→class→account mapping: [quickbooks-item-revenue-analysis](../quickbooks-item-revenue-analysis/SKILL.md)
- Forward projections of margin: [quickbooks-forecasting](../quickbooks-forecasting/SKILL.md)
- The reference parser: `C:\tmp\parse-pl-by-class.ps1`
- Latest output: `C:\Users\rjain\Documents\technijian-pl-2026\pl-by-class-monthly-YTD-2026.csv`
