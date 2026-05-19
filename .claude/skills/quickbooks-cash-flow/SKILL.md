---
name: quickbooks-cash-flow
description: Analyze QuickBooks cash position — pull current balances across all bank/credit-card accounts, AR/AP aging impact on cash, near-term receipts and disbursements, and net cash movement over time. Use when the user asks "how much cash do we have?", "what's our cash position?", "show me bank balances", "what's our cash flow trend?", "what's coming in / going out this week?", or wants a working-capital snapshot. Multi-tenant — default `technijian`.
---

# QuickBooks Cash Flow Analysis

This skill answers the operational cash-position questions:

- "How much cash do we have right now? In which accounts?"
- "What's our 30-day cash position projection?"
- "How much AR is expected to come in within 30 days?"
- "What bills are coming due this week?"
- "Is our cash trend positive or negative this month?"
- "What's our cash flow operating vs investing vs financing?"

Multi-tenant: `company=` or `QB_DEFAULT_COMPANY`. Default `technijian`. Authorized: `technijian`, `electronic-corporation-of-america`.

## Three levels of cash visibility

| Level | What it shows | How to pull |
|---|---|---|
| **Current cash** | Bank + CC balances as of today | `list_accounts` filtered to `Bank` + `CreditCard` types |
| **Net realizable cash (NRC)** | Current cash + collectible AR − payable AP | + `report` with `AgingAR` / `AgingAP` |
| **Cash flow trend** | Cash position over time, by category (operating/investing/financing) | + `StatementOfCashFlows` report |

## Current cash position

```python
from qb_client import QbClient
client = QbClient.from_env().with_company("technijian")

accts = client.op("list_accounts")["rows"]
banks = [a for a in accts if a["AccountType"] == "Bank" and a.get("IsActive") == "true"]
ccards = [a for a in accts if a["AccountType"] == "CreditCard" and a.get("IsActive") == "true"]

print("=== Cash on hand ===")
total_cash = 0
for a in sorted(banks, key=lambda x: -float(x.get("Balance", 0))):
    bal = float(a.get("Balance", 0))
    total_cash += bal
    print(f"  {a['FullName']:40} ${bal:>12,.2f}")
print(f"  {'TOTAL CASH':40} ${total_cash:>12,.2f}")

print("\n=== Credit card balances (liabilities) ===")
total_cc = 0
for a in sorted(ccards, key=lambda x: -float(x.get("Balance", 0))):
    bal = float(a.get("Balance", 0))
    total_cc += bal
    print(f"  {a['FullName']:40} ${bal:>12,.2f}")
print(f"  {'TOTAL CC OWED':40} ${total_cc:>12,.2f}")

print(f"\nNet liquid position: ${total_cash - total_cc:,.2f}")
```

Note: `Balance` for a Bank account is the QB ledger balance (what QB thinks you have). The actual bank balance can differ if there are uncleared checks/deposits. To get the true cleared balance, look at the latest bank reconciliation.

## Net realizable cash (NRC) — quick

```python
# AR aging — what's collectible
ar = client.op("report", {"type": "AgingAR"})
# Sum the rows' totals (last numeric column)

# AP aging — what we owe
ap = client.op("report", {"type": "AgingAP"})

# NRC ≈ current_cash + AR_total - AP_total - (overdue_haircut)
# Apply a haircut to AR balances >60 days (some won't be collected)
```

Quick aging summary:

```python
def aging_summary(ar_or_ap):
    """Returns dict: bucket -> total."""
    cols = ar_or_ap["report"]["columns"]
    # Last column is total; intermediate columns are aging buckets (Current/1-30/31-60/61-90/>90)
    bucket_cols = [c for c in cols if c["type"] == "Amount"]
    sums = {c["title"]: 0 for c in bucket_cols}
    for row in ar_or_ap["report"]["rows"]:
        if row["rowType"] == "account":   # data row
            for c in bucket_cols:
                v = row["cells"].get(c["id"])
                if v:
                    sums[c["title"]] += float(v)
    return sums
```

## Near-term inflows (AR coming due)

```python
inv = client.op("list_invoices", {"dateMacro": "ThisFiscalYearToDate"})
open_inv = [r for r in inv["rows"] if float(r.get("BalanceRemaining", 0)) > 0]

from datetime import date, timedelta
today = date.today()
buckets = {"overdue": 0, "0-7": 0, "8-15": 0, "16-30": 0, "31-60": 0, "60+": 0}
for r in open_inv:
    due = date.fromisoformat(r["DueDate"]) if r.get("DueDate") else None
    bal = float(r["BalanceRemaining"])
    if due is None:
        buckets["0-7"] += bal       # default assumption
    elif due < today:
        buckets["overdue"] += bal
    else:
        days = (due - today).days
        if   days <= 7:  buckets["0-7"]   += bal
        elif days <= 15: buckets["8-15"]  += bal
        elif days <= 30: buckets["16-30"] += bal
        elif days <= 60: buckets["31-60"] += bal
        else:            buckets["60+"]   += bal

print("=== Expected AR collections by maturity ===")
for b, amt in buckets.items():
    print(f"  {b:10} ${amt:>12,.2f}")
```

Apply collection-probability haircuts in real forecasts: 100% for current, 95% for 1-30, 85% for 31-60, 65% for 61-90, 40% for >90. Calibrate to your actual historical collection rates.

## Near-term outflows (AP coming due)

```python
bills = client.op("list_bills", {"dateMacro": "ThisFiscalYearToDate"})
open_bills = [r for r in bills["rows"] if float(r.get("AmountDue", 0)) > 0]

# Same bucket logic — when do bills come due?
# Then also add recurring outflows (payroll, recurring ACH debits, lease payments)
# that aren't yet entered as bills.
```

The biggest gotcha here: bills you've ENTERED in QB are visible via `list_bills`. Recurring ACH debits that haven't been entered yet (because nobody has booked the upcoming Microsoft / Sophos / etc. debit) are NOT visible — they hit your bank feed when they hit, and you classify them. For a true forecast, you'd want to add expected ACH outflows from a master schedule.

## Cash flow statement

QB SDK report type `CashFlow`:

```python
xml = '''<?xml version="1.0"?>
<?qbxml version="16.0"?>
<QBXML><QBXMLMsgsRq onError="stopOnError">
  <GeneralSummaryReportQueryRq>
    <GeneralSummaryReportType>StatementOfCashFlows</GeneralSummaryReportType>
    <DisplayReport>false</DisplayReport>
    <ReportPeriod>
      <FromReportDate>2026-01-01</FromReportDate>
      <ToReportDate>2026-05-19</ToReportDate>
    </ReportPeriod>
  </GeneralSummaryReportQueryRq>
</QBXMLMsgsRq></QBXML>'''
```

Returns the indirect-method cash flow statement: Net Income + Operating Activities + Investing + Financing + Net Cash Increase/Decrease. Useful for understanding WHERE cash is going (paying down credit cards = financing; buying equipment = investing; everyday ops = operating).

## Daily cash trend

There's no canned "cash balance over time" report, but you can construct it from bank account registers via raw qbXML or by polling `BalanceSheetStandard` at each date:

```python
balances = []
for day in date_range("2026-01-01", "2026-05-19"):
    xml = f'''<?xml version="1.0"?><?qbxml version="16.0"?>
    <QBXML><QBXMLMsgsRq onError="stopOnError">
      <GeneralSummaryReportQueryRq>
        <GeneralSummaryReportType>BalanceSheetStandard</GeneralSummaryReportType>
        <DisplayReport>false</DisplayReport>
        <ReportPeriod><FromReportDate>{day}</FromReportDate><ToReportDate>{day}</ToReportDate></ReportPeriod>
      </GeneralSummaryReportQueryRq>
    </QBXMLMsgsRq></QBXML>'''
    response = client.qbxml(xml)
    # parse and sum Bank account balances
```

Slow (1 call per day) — only do this for special audits. For routine cash trends, use the cash flow statement.

## Working-capital sanity check

```
Working Capital = Current Assets − Current Liabilities
                 = (Cash + AR + Other CA) − (AP + CC + Other CL)
```

Pull `BalanceSheetStandard` and read the "Total Current Assets" and "Total Current Liabilities" rows.

Healthy MSPs typically have:
- Current Ratio (CA / CL) ≥ 1.5
- Quick Ratio ((Cash + AR) / CL) ≥ 1.0
- Cash on hand ≥ 30-60 days of operating expenses

## Daily / weekly cash dashboard

A useful periodic snapshot — run this daily, save to CSV, trend over time:

```python
def cash_snapshot(client, asof_date):
    snapshot = {"date": asof_date}

    # Bank balances
    accts = client.op("list_accounts")["rows"]
    snapshot["cash_total"] = sum(float(a.get("Balance", 0)) for a in accts if a["AccountType"] == "Bank")
    snapshot["cc_total"]   = sum(float(a.get("Balance", 0)) for a in accts if a["AccountType"] == "CreditCard")

    # AR aging
    ar = client.op("report", {"type": "AgingAR", "dateMacro": "Today"})
    snapshot["ar_total"] = _sum_aging(ar)

    # AP aging
    ap = client.op("report", {"type": "AgingAP", "dateMacro": "Today"})
    snapshot["ap_total"] = _sum_aging(ap)

    snapshot["nrc"] = snapshot["cash_total"] + snapshot["ar_total"] - snapshot["cc_total"] - snapshot["ap_total"]
    return snapshot
```

Append to a CSV daily and you've got a multi-month working-capital trend.

## Patterns

### "How much cash do we have right now?"

```python
accts = client.op("list_accounts")["rows"]
banks = [(a["FullName"], float(a.get("Balance", 0))) for a in accts if a["AccountType"] == "Bank"]
total = sum(b for _, b in banks)
# Output: total + per-account breakdown
```

### "Can we afford to pay all open bills today?"

```python
cash = sum(float(a.get("Balance", 0)) for a in client.op("list_accounts")["rows"] if a["AccountType"] == "Bank")
open_bills = sum(float(b.get("AmountDue", 0)) for b in client.op("list_bills", {"dateMacro": "All"})["rows"])
print(f"Cash: ${cash:,.2f}  |  Open AP: ${open_bills:,.2f}  |  Surplus: ${cash - open_bills:,.2f}")
```

### "Is our cash flow trend healthy?"

Run the Statement of Cash Flows for the YTD and look at:
- **Operating activities** = should be POSITIVE (you're generating cash from the business)
- **Investing** = typically negative (buying assets)
- **Financing** = depends on whether you're paying down or taking on debt
- **Net change in cash** = positive is healthy

If operating cash flow is NEGATIVE, that's a yellow-to-red flag — even profitable companies can run out of cash if collections lag too far behind disbursements.

## Pointers

- For projections going FORWARD, see [quickbooks-forecasting](../quickbooks-forecasting/SKILL.md)
- For chart-of-accounts lookups: [quickbooks-accounts-items-classes](../quickbooks-accounts-items-classes/SKILL.md)
- For AR/AP detail: [quickbooks-invoices](../quickbooks-invoices/SKILL.md), [quickbooks-bills](../quickbooks-bills/SKILL.md)
- For aging reports: [quickbooks-reports](../quickbooks-reports/SKILL.md)
