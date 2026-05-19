---
name: quickbooks-reports
description: Run QuickBooks financial reports through QbConnectService — Profit & Loss (standard, by class, by month), Balance Sheet, A/R Aging, A/P Aging. Use when the user asks for P&L, income statement, balance sheet, aging summary, monthly performance, or classification reports. Multi-tenant — default `technijian`.
---

# QuickBooks Reports

The wrapped `report` op supports four canned report types. For anything more complex (P&L by class, monthly columns, custom summaries) drop to raw qbXML via `client.qbxml(...)` — that's the path used for the monthly classification report at `C:\Users\rjain\Documents\technijian-pl-2026\`.

## Multi-tenant

`company=` or `QB_DEFAULT_COMPANY`. Default `technijian`. Authorized: `technijian`, `electronic-corporation-of-america`.

---

## Canned reports via `report` op

```python
from qb_client import QbClient
client = QbClient.from_env().with_company("technijian")

# P&L for YTD (Jan 1 to today):
r = client.op("report", {"type": "ProfitAndLoss", "dateMacro": "ThisFiscalYearToDate"})
report = r["report"]
print(report["title"], report["subtitle"])
for col in report["columns"]:
    print("col:", col["title"], col["type"])
for row in report["rows"]:
    print(row["rowType"], row["label"], row["cells"])

# P&L for a specific date range:
client.op("report", {"type": "ProfitAndLoss", "fromDate": "2026-01-01", "toDate": "2026-05-19"})

# Balance Sheet (as-of date — pass a single date by using fromDate==toDate, or use dateMacro):
client.op("report", {"type": "BalanceSheet", "dateMacro": "Today"})

# A/R Aging summary (open invoices by aging bucket):
client.op("report", {"type": "AgingAR", "dateMacro": "Today"})

# A/P Aging summary (open bills by aging bucket):
client.op("report", {"type": "AgingAP", "dateMacro": "Today"})
```

| Report type | Underlying qbXML | What it returns |
|---|---|---|
| `ProfitAndLoss` | `GeneralSummaryReportQueryRq` with `ProfitAndLossStandard` | Income/COGS/Expense rows, one total column |
| `BalanceSheet` | `GeneralSummaryReportQueryRq` with `BalanceSheetStandard` | Assets / Liabilities / Equity rows, single column as-of date |
| `AgingAR` | `AgingReportQueryRq` with `ARAgingSummary` | Customer rows, columns = Current / 1-30 / 31-60 / 61-90 / >90 / Total |
| `AgingAP` | `AgingReportQueryRq` with `APAgingSummary` | Vendor rows, same column buckets |

### `dateMacro` values

`Today`, `Yesterday`, `ThisWeek`, `LastWeek`, `ThisWeekToDate`, `ThisMonth`, `LastMonth`, `ThisMonthToDate`, `ThisQuarter`, `LastQuarter`, `ThisQuarterToDate`, `ThisFiscalYear`, `LastFiscalYear`, `ThisFiscalYearToDate`, `ThisFiscalQuarter`, `LastFiscalQuarter`, `NextWeek`, `NextMonth`, `NextQuarter`, `All`. Mutually exclusive with `fromDate`/`toDate`.

### Parsed report shape

```python
{
    "title": "Profit & Loss",
    "subtitle": "January 1 through May 19, 2026",
    "basis": "Accrual",
    "columns": [
        {"id": "1", "title": "Label",   "type": "Label"},
        {"id": "2", "title": "Jan 26",  "type": "Amount"},
        ...
    ],
    "rows": [
        {"rowType": "text",     "label": "Income",    "rowDataType": "Header", "cells": {}},
        {"rowType": "account",  "label": "1000 - Consulting", "cells": {"2": "15000.00"}},
        {"rowType": "subtotal", "label": "Total Income", "cells": {"2": "100000.00"}},
        ...
    ],
}
```

---

## Raw qbXML for advanced reports

When you need:
- Columns summarized by class, month, customer, or any other dimension
- Custom date ranges
- Subcolumns / multi-level summaries
- Specific report types not in the canned list (Sales by Item, Job P&L, etc.)

### P&L by Class for a month

```python
xml = '''<?xml version="1.0"?>
<?qbxml version="16.0"?>
<QBXML><QBXMLMsgsRq onError="stopOnError">
  <GeneralSummaryReportQueryRq>
    <GeneralSummaryReportType>ProfitAndLossStandard</GeneralSummaryReportType>
    <DisplayReport>false</DisplayReport>
    <ReportPeriod>
      <FromReportDate>2026-05-01</FromReportDate>
      <ToReportDate>2026-05-31</ToReportDate>
    </ReportPeriod>
    <SummarizeColumnsBy>Class</SummarizeColumnsBy>
  </GeneralSummaryReportQueryRq>
</QBXMLMsgsRq></QBXML>'''
response_xml = client.qbxml(xml)
# Parse with xml.etree.ElementTree or PowerShell's [xml]
```

Response is the raw qbXML report XML. The columns become individual classes (one per `ColDesc`), the rows are accounts. See `C:\tmp\parse-pl-by-class.ps1` for a working parser that classifies accounts by number prefix.

### Other `SummarizeColumnsBy` values

- `TotalOnly` — single total column (the default for canned `report` op)
- `Day`, `Week`, `TwoWeek`, `FourWeek`, `HalfMonth`, `Month`, `Quarter`, `Year` — time-based
- `Customer`, `Vendor`, `Class`, `Employee`, `Item` — entity-based

### Other report types worth knowing

| `<GeneralSummaryReportType>` | What it is |
|---|---|
| `ProfitAndLossStandard` | Standard income statement |
| `ProfitAndLossDetail` | P&L with every transaction line |
| `BalanceSheetStandard` | Standard balance sheet |
| `BalanceSheetSummary` | Just totals, no detail |
| `BalanceSheetDetail` | BS with every transaction |
| `CashFlow` | Statement of cash flows |
| `TrialBalance` | Trial balance |
| `SalesByCustomerSummary`, `SalesByCustomerDetail` | Sales analysis by customer |
| `SalesByItemSummary`, `SalesByItemDetail` | Sales by item/service |
| `SalesByRepSummary`, `SalesByRepDetail` | Sales by rep |
| `JobProfitabilitySummary`, `JobProfitabilityDetail` | Job profitability (uses customer:job) |

| `<AgingReportType>` (different envelope) | What it is |
|---|---|
| `ARAgingSummary`, `ARAgingDetail` | A/R aging |
| `APAgingSummary`, `APAgingDetail` | A/P aging |
| `OpenInvoices` | All open invoices |

### Custom report filters

```xml
<ReportEntityFilter>
  <ListIDList>
    <ListID>80000123-1234567890</ListID>    <!-- specific customer/vendor/etc -->
  </ListIDList>
</ReportEntityFilter>

<ReportAccountFilter>
  <ListIDList>
    <ListID>...</ListID>
  </ListIDList>
</ReportAccountFilter>

<ReportClassFilter>
  <ListIDList>
    <ListID>...</ListID>
  </ListIDList>
</ReportClassFilter>
```

---

## Common report patterns

### "How are we doing this month?"

```python
client.op("report", {"type": "ProfitAndLoss", "dateMacro": "ThisMonth"})
```

### "Show me the AR aging"

```python
client.op("report", {"type": "AgingAR"})    # defaults to as-of today
```

Sort the rows by `Over 90 days` column to find the most concerning balances.

### "Pull a monthly P&L by class for YTD"

(This is what the monthly classification report does.) Loop months:

```python
import xml.etree.ElementTree as ET

months = [
    ("Jan", "2026-01-01", "2026-01-31"),
    ("Feb", "2026-02-01", "2026-02-28"),
    ("Mar", "2026-03-01", "2026-03-31"),
    ("Apr", "2026-04-01", "2026-04-30"),
    ("May", "2026-05-01", "2026-05-19"),
]

reports = {}
for name, frm, to in months:
    xml = f'''<?xml version="1.0"?><?qbxml version="16.0"?>
    <QBXML><QBXMLMsgsRq onError="stopOnError">
      <GeneralSummaryReportQueryRq>
        <GeneralSummaryReportType>ProfitAndLossStandard</GeneralSummaryReportType>
        <DisplayReport>false</DisplayReport>
        <ReportPeriod><FromReportDate>{frm}</FromReportDate><ToReportDate>{to}</ToReportDate></ReportPeriod>
        <SummarizeColumnsBy>Class</SummarizeColumnsBy>
      </GeneralSummaryReportQueryRq>
    </QBXMLMsgsRq></QBXML>'''
    reports[name] = ET.fromstring(client.qbxml(xml))

# ... parse each, extract per-class totals, build matrix ...
```

The reference PowerShell parser is at `C:\tmp\parse-pl-by-class.ps1` on the workstation.

### "Where do we have the most AR exposure?"

```python
ar = client.op("report", {"type": "AgingAR"})["report"]
# Find the "Total" column (last numeric column), sort rows descending by it.
```

---

## Performance notes

- A standard P&L for a small file is sub-second.
- P&L by Class for a year is ~5-10s (lots of columns).
- Detail reports (`ProfitAndLossDetail`, etc.) can be many MB; consider date-range scoping.
- Reports go through the same COM gate as ops, so don't fire reports in parallel — they serialize anyway.

## Pointers

- Full safe-write workflow (only matters if you're modifying transactions based on report findings): [quickbooks-accounting](../quickbooks-accounting/SKILL.md)
- Items / accounts / classes metadata used by reports: [quickbooks-accounts-items-classes](../quickbooks-accounts-items-classes/SKILL.md)
- The reference monthly P&L by class output is in `C:\Users\rjain\Documents\technijian-pl-2026\pl-by-class-monthly-YTD-2026.csv`
