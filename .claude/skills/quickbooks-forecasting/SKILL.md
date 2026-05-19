---
name: quickbooks-forecasting
description: Forecast QuickBooks revenue, expenses, and cash position N weeks/months forward based on historical run-rates, scheduled bills, open AR, recurring revenue, and known commitments. Use when the user asks "what will our cash look like in 30/60/90 days?", "project revenue for the rest of the year", "forecast cash flow", "will we have enough cash to cover [X]?", or wants a what-if scenario. Multi-tenant — default `technijian`.
---

# QuickBooks Forecasting

This is the projection layer — taking what QB knows about the past + scheduled future commitments + assumptions about ongoing patterns, and producing a forward-looking cash and P&L view.

QB itself doesn't have a forecasting engine in the SDK; this skill is a CLIENT-SIDE projection layered on data the SDK CAN pull.

Multi-tenant: `company=` or `QB_DEFAULT_COMPANY`. Default `technijian`. Authorized: `technijian`, `electronic-corporation-of-america`.

## What the forecast is

A forecast is the cell-by-cell answer to "what will happen between [today] and [target date], in cash and accrual terms?", broken into:

1. **Known inflows** — open AR with due dates → predictable cash receipts (apply collection-probability haircut)
2. **Recurring revenue** — items billed every month/year on a schedule (MRR/ARR) → predictable invoice creation + downstream AR
3. **Known outflows** — open AP with due dates → predictable disbursements
4. **Recurring expenses** — ACH debits, payroll, leases, software subscriptions → predictable outflows
5. **One-off / discretionary** — investments, new hires, capex
6. **Net change in cash** = (1 + 2) − (3 + 4 + 5)

## Inputs the model needs

| Input | Source | Confidence |
|---|---|---|
| Current cash | `list_accounts` (Bank type) | HIGH |
| Open AR + due dates | `list_invoices` filtered to `BalanceRemaining > 0` | HIGH on numbers, MEDIUM on dates (some customers pay late) |
| Open AP + due dates | `list_bills` filtered to `AmountDue > 0` | HIGH |
| Recurring revenue rate | Last 3-6 months of `list_invoices`, filter to items containing "Monthly", "MRR", "Recurring" | MEDIUM — base on historical median, project flat or with growth assumption |
| Recurring expense rate | Last 3-6 months of `list_bills` + `list_payments`, find ACH/auto-debit items by payee | MEDIUM — most are predictable to ±5% |
| Historical AR collection lag | Compute days-to-pay from past invoices | MEDIUM — apply by customer segment |
| One-off items | Operator-supplied (new hire start dates, planned capex, etc.) | LOW — user-supplied assumption |

## Pattern: 30-day rolling cash forecast

```python
from qb_client import QbClient
from datetime import date, timedelta
from collections import defaultdict

client = QbClient.from_env().with_company("technijian")

today = date.today()
horizon = today + timedelta(days=30)

# 1. Starting cash
accts = client.op("list_accounts")["rows"]
starting_cash = sum(float(a.get("Balance", 0)) for a in accts if a["AccountType"] == "Bank")

# 2. Expected receipts (open AR with due dates in the horizon)
inflows = defaultdict(float)
for inv in client.op("list_invoices", {"dateMacro": "ThisFiscalYearToDate"})["rows"]:
    bal = float(inv.get("BalanceRemaining", 0))
    if bal <= 0:
        continue
    due = inv.get("DueDate")
    if not due:
        continue
    due_dt = date.fromisoformat(due)
    # Collection-probability haircut by aging
    days_overdue = (today - due_dt).days
    if days_overdue > 90:    prob = 0.40
    elif days_overdue > 60:  prob = 0.65
    elif days_overdue > 30:  prob = 0.85
    elif days_overdue > 0:   prob = 0.95
    else:                    prob = 0.98   # not yet due
    expected_date = max(due_dt, today)     # don't assume future overdue payments arrive today
    if expected_date <= horizon:
        inflows[expected_date] += bal * prob

# 3. Expected disbursements (open AP)
outflows = defaultdict(float)
for bill in client.op("list_bills", {"dateMacro": "ThisFiscalYearToDate"})["rows"]:
    due = bill.get("DueDate")
    amt = float(bill.get("AmountDue", 0))
    if amt <= 0 or not due:
        continue
    due_dt = date.fromisoformat(due)
    if due_dt <= horizon:
        outflows[max(due_dt, today)] += amt   # pay on or after due date

# 4. Recurring auto-debits — from operator-supplied schedule (see below for how to build it)
RECURRING_DEBITS = [
    # (day_of_month, amount, payee, account, class)
    (1,  18500.00, "Gusto",        "6115 - Payroll Expenses:6115.01 - Processing", "Admin (US)"),
    (5,  12000.00, "Microsoft",    "5501 - Software Licensing",                    "Office 365 (Online Services)"),
    (10,  3500.00, "Sophos",       "5501 - Software Licensing",                    "Sophos"),
    (15,  2800.00, "Huntress",     "5501 - Software Licensing",                    "Huntress"),
    (15,  9500.00, "Blue Shield",  "6130 - Insurance:6130.4 - Medical Insurance",  "Admin (US)"),
    (20,  4200.00, "Cisco",        "5501 - Software Licensing",                    "Cisco Umbrella"),
    # ... etc — derive from your bank-feed-classifier rule library
]
d = today
while d <= horizon:
    for dom, amt, payee, _, _ in RECURRING_DEBITS:
        if d.day == dom:
            outflows[d] += amt
    d += timedelta(days=1)

# 5. Build the day-by-day projection
projection = []
cash = starting_cash
d = today
while d <= horizon:
    inflow  = inflows.get(d, 0)
    outflow = outflows.get(d, 0)
    cash += inflow - outflow
    projection.append({"date": d, "inflow": inflow, "outflow": outflow, "ending_cash": cash})
    d += timedelta(days=1)

# Show:
print(f"\n=== 30-day cash forecast (starting ${starting_cash:,.2f}) ===")
print(f"{'Date':12} {'Inflow':>12} {'Outflow':>12} {'Ending':>12}")
for p in projection:
    print(f"{p['date'].isoformat():12} ${p['inflow']:>10,.2f} ${p['outflow']:>10,.2f} ${p['ending_cash']:>10,.2f}")

low_point = min(projection, key=lambda p: p["ending_cash"])
print(f"\nLow point: {low_point['date']} → ${low_point['ending_cash']:,.2f}")
```

## Pattern: recurring-revenue baseline

To project new invoices that will be created from recurring contracts:

```python
# Pull last 3 months of invoices to find the recurring pattern
inv = client.op("list_invoices", {"dateMacro": "LastQuarter", "includeLineItems": True})

# Find items that appeared in 3 consecutive months — those are recurring
from collections import defaultdict
item_month_revenue = defaultdict(lambda: defaultdict(float))
for r in inv["rows"]:
    month = r["TxnDate"][:7]   # YYYY-MM
    for line in r.get("InvoiceLineRet", []):
        item = (line.get("ItemRef") or {}).get("FullName")
        if item:
            item_month_revenue[item][month] += float(line.get("Amount", 0) or 0)

# Items present in all 3 last months — recurring candidates:
recurring_items = {item for item, by_month in item_month_revenue.items() if len(by_month) >= 3}

# Their median monthly revenue:
import statistics
recurring_rates = {
    item: statistics.median(by_month.values())
    for item, by_month in item_month_revenue.items()
    if item in recurring_items
}
total_mrr = sum(recurring_rates.values())
print(f"Estimated MRR: ${total_mrr:,.2f}/month from {len(recurring_rates)} recurring items")
```

Project forward by assuming MRR holds steady (or apply a growth assumption from operator).

## Pattern: scenario analysis

The user wants to know "what if we lose [customer]?" or "what if we hire 2 more engineers?":

```python
def project(starting_cash, days, recurring_revenue, recurring_expense, ar_schedule, ap_schedule, scenarios):
    """
    scenarios = list of (date, delta_cash) — positive for new revenue, negative for new expense.
    e.g. ('2026-06-15', -7500) for adding a new $7.5K/mo engineer starting 6/15
    """
    daily = defaultdict(float)
    for s_date, delta in scenarios:
        daily[s_date] += delta
    # ... layer onto base projection
```

For an MSP context, common what-ifs:
- New hire impact: −$5-15K/mo on Admin/Engineering class
- Customer churn: −$X/mo on whatever class served them
- Customer win: +$X/mo on the relevant class
- Capex: one-time outflow on the date of purchase
- New software vendor: recurring −$Y/mo from the vendor's first ACH date

## Pattern: P&L forecast (accrual basis)

Different from cash forecast — projects net income, not cash position. Useful for "will we hit our annual budget?":

```python
# Annual P&L trajectory
ytd_pnl = client.op("report", {"type": "ProfitAndLoss", "dateMacro": "ThisFiscalYearToDate"})

# Extract revenue + expense run-rate
# ... parse rows ...
ytd_revenue = ...
ytd_expense = ...
ytd_days = (date.today() - date(2026, 1, 1)).days

# Annualized run-rate:
annual_revenue_run_rate = ytd_revenue / ytd_days * 365
annual_expense_run_rate = ytd_expense / ytd_days * 365
projected_annual_net = annual_revenue_run_rate - annual_expense_run_rate

print(f"YTD: ${ytd_revenue:,.0f} rev / ${ytd_expense:,.0f} exp / ${ytd_revenue-ytd_expense:,.0f} net")
print(f"Annualized: ${annual_revenue_run_rate:,.0f} rev / ${annual_expense_run_rate:,.0f} exp / ${projected_annual_net:,.0f} net")
```

This is the simplest possible projection — assumes the next 7 months look like the last 5. Use cautiously; refine by:
- Excluding January's prepaid lease bump from the run-rate baseline
- Layering in known seasonality (Q4 tends to be heavier in MSPs because of capex spend)
- Separating recurring revenue (high confidence) from project/one-off revenue (lower confidence)

## Confidence framing

Forecasts always come with assumptions. Surface them explicitly:

```
30-day projection assumptions:
- Starting cash: $X (current QB ledger balance, may differ from cleared bank)
- AR collection probabilities: 98% / 95% / 85% / 65% / 40% (current → >90)
- AP paid on due date (no early-pay discounts, no late-pay slack)
- Recurring ACH debits per schedule (DERIVED FROM BANK-FEED HISTORY — verify monthly)
- Recurring revenue holds steady at ${MRR}/month
- No new customer wins or losses in horizon
- No capex / one-off items unless explicitly added
```

A forecast without stated assumptions is dangerous — anyone reading it should know what's in vs out.

## Save forecasts as snapshots

A forecast is most useful when you can compare today's forecast vs last week's vs the actual outcome. Snapshot to CSV:

```python
# Save 30-day forecast snapshot
fname = f"forecast-30day-{date.today().isoformat()}.csv"
path = f"C:\\Users\\rjain\\Documents\\technijian-forecasts\\{fname}"
# write projection rows to path
```

Then a follow-up skill could compare the forecast generated 30 days ago to today's actual cash position — that's your forecast-accuracy feedback loop.

## What QB doesn't give you (and how to fill the gap)

- **Probability-weighted pipeline.** QB has no CRM/pipeline. Pipeline-weighted revenue ($X expected from prospects × probability of close) has to come from outside (CRM, spreadsheet).
- **Subscription billing complexity.** Auto-renewal, ramps, mid-month proration, etc. — QB invoice schedule is naive; you'd model these in code.
- **FX / multi-currency.** Out of scope for our v1 (single-currency).
- **Cohort-based churn projection.** For multi-tenant MSPs with hundreds of customers, you'd typically model retention by cohort. Too granular for this skill — use a BI tool.

## Pointers

- Current cash baseline: [quickbooks-cash-flow](../quickbooks-cash-flow/SKILL.md)
- Recurring-revenue identification (MRR items): [quickbooks-item-revenue-analysis](../quickbooks-item-revenue-analysis/SKILL.md)
- Recurring-expense baseline (ACH pattern from bank feeds): [quickbooks-bank-feed-classifier](../quickbooks-bank-feed-classifier/SKILL.md)
- Class-level performance to identify trends: [quickbooks-class-margin-analysis](../quickbooks-class-margin-analysis/SKILL.md)
