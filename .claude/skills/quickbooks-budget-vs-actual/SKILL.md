---
name: quickbooks-budget-vs-actual
description: Compare QuickBooks actual financial performance to budget — pull budget data, compute variances by account and by class, flag categories significantly over/under budget, and trend variance over time. Use when the user asks "are we on budget?", "show me budget variance", "where are we over budget?", or wants a budget review. Multi-tenant — default `technijian`.
---

# QuickBooks Budget vs Actual

QB Desktop supports budgets per fiscal year per account (optionally per class or per customer:job). This skill pulls the budget data and compares it to actual P&L performance.

Multi-tenant: default `technijian`.

## The QB budget data model

A budget in QB has:
- `BudgetName` — e.g. "FY2026 Operating Budget"
- `FiscalYear` — e.g. 2026
- `BudgetType` — `ProfitAndLoss` or `BalanceSheet`
- `BudgetCriterion` — `Accounts` (account-only), `AccountsAndClasses`, `AccountsAndCustomers`
- Per (account, optionally class/customer, month): a budgeted dollar amount

## Pull the budget

The SDK exposes `BudgetSummaryReport`:

```python
from qb_client import QbClient
client = QbClient.from_env().with_company("technijian")

xml = '''<?xml version="1.0"?>
<?qbxml version="16.0"?>
<QBXML><QBXMLMsgsRq onError="stopOnError">
  <BudgetSummaryReportQueryRq>
    <BudgetSummaryReportType>BudgetOverview</BudgetSummaryReportType>
    <DisplayReport>false</DisplayReport>
    <FiscalYear>2026</FiscalYear>
    <BudgetCriterion>Accounts</BudgetCriterion>
    <SummarizeColumnsBy>Month</SummarizeColumnsBy>
  </BudgetSummaryReportQueryRq>
</QBXMLMsgsRq></QBXML>'''

budget_xml = client.qbxml(xml)
# Parse: rows = accounts, columns = months, cells = budgeted $
```

For budget-vs-actual in one report:

```python
xml = '''<?xml version="1.0"?>
<?qbxml version="16.0"?>
<QBXML><QBXMLMsgsRq onError="stopOnError">
  <BudgetSummaryReportQueryRq>
    <BudgetSummaryReportType>BudgetVsActual</BudgetSummaryReportType>
    <DisplayReport>false</DisplayReport>
    <FiscalYear>2026</FiscalYear>
    <BudgetCriterion>Accounts</BudgetCriterion>
    <SummarizeColumnsBy>Month</SummarizeColumnsBy>
  </BudgetSummaryReportQueryRq>
</QBXMLMsgsRq></QBXML>'''
```

Returns Actual / Budget / Difference / % columns per period per account.

## Pull and compute manually

If you need more control than the canned report (e.g., variance by class, dynamic budget targets), pull the budget + actual P&L separately and compute:

```python
# Actual P&L
actual = client.op("report", {"type": "ProfitAndLoss", "fromDate": "2026-01-01", "toDate": "2026-05-19"})

# Build a per-account total
ytd_actual = {}
for row in actual["report"]["rows"]:
    if row["rowType"] != "account":
        continue
    acct = row["label"]
    # Sum the row's cells (typically just one total column for non-summarized P&L)
    ytd_actual[acct] = sum(float(v) for v in row["cells"].values() if v)

# Pull budget for same period
# ... parse BudgetSummaryReport XML, sum Jan-May budget per account ...

# Compare:
variances = []
for acct, actual_amt in ytd_actual.items():
    budgeted = budget_data.get(acct, 0)
    variance = actual_amt - budgeted
    variance_pct = (variance / budgeted * 100) if budgeted else None
    variances.append({"account": acct, "actual": actual_amt, "budget": budgeted, "variance": variance, "variance_pct": variance_pct})
```

## Flag significant variances

The rule of thumb: 10% variance is normal noise; 20%+ deserves investigation; 50%+ is structural.

```python
significant = [v for v in variances if v["variance_pct"] is not None and abs(v["variance_pct"]) > 20 and abs(v["variance"]) > 500]
significant.sort(key=lambda v: -abs(v["variance"]))

print("=== Significant variances (>20% AND >$500) ===")
print(f"{'Account':50} {'Actual':>10} {'Budget':>10} {'Var':>10} {'%':>6}")
for v in significant[:30]:
    sign = "+" if v["variance"] > 0 else ""
    print(f"  {v['account']:50} ${v['actual']:>10,.0f} ${v['budget']:>10,.0f} {sign}${v['variance']:>10,.0f} {v['variance_pct']:>6.0f}%")
```

For income accounts:
- **Over budget = good** (more revenue than expected)
- **Under budget = concerning** (missing sales targets)

For expense accounts:
- **Over budget = concerning** (spending more than planned)
- **Under budget = either good (savings) or concerning (cutting corners)**

The agent's report should call this out — don't just show numbers, interpret them.

## Per-class variance

For class-budgeted P&L:

```python
xml = '''<?xml version="1.0"?>
<?qbxml version="16.0"?>
<QBXML><QBXMLMsgsRq onError="stopOnError">
  <BudgetSummaryReportQueryRq>
    <BudgetSummaryReportType>BudgetVsActual</BudgetSummaryReportType>
    <DisplayReport>false</DisplayReport>
    <FiscalYear>2026</FiscalYear>
    <BudgetCriterion>AccountsAndClasses</BudgetCriterion>
    <SummarizeColumnsBy>Class</SummarizeColumnsBy>
  </BudgetSummaryReportQueryRq>
</QBXMLMsgsRq></QBXML>'''
```

This shows for each (account, class) combo: actual, budget, variance. Useful for "is the Data Center class on budget?" type questions.

## Trend analysis

Variance can grow over time even if any single month isn't dramatic. Track variance trend:

```python
months = ["2026-01", "2026-02", "2026-03", "2026-04", "2026-05"]
trends = {}   # account -> list of monthly variance %
for m in months:
    # Pull budget vs actual for that month
    # ... aggregate per account ...
    for acct, data in by_account.items():
        trends.setdefault(acct, []).append(data["variance_pct"])

# Flag accounts where variance is consistently negative (under budget on income) or positive (over budget on expense):
for acct, history in trends.items():
    if len(history) >= 3 and all(h > 10 for h in history[-3:]):
        # Three months consecutively > 10% over budget
        print(f"PERSISTENT OVERAGE: {acct}")
```

## Forecasting: "where will we land for the year?"

YTD actual + projected remainder = annual forecast.

```python
ytd_days = 139    # Jan 1 - May 19
year_days = 365
remaining_days = year_days - ytd_days

# Simple linear projection (assumes the rest of the year looks like YTD):
for v in variances:
    ytd_actual = v["actual"]
    annualized = ytd_actual / ytd_days * year_days
    annual_budget = v["budget"] * (year_days / ytd_days) if v["budget"] else 0  # if YTD budget was a partial annual
    # Actually you'd want the FULL annual budget, not YTD budget × scale.
    annual_budget = budget_data_annual.get(v["account"], 0)
    expected_variance = annualized - annual_budget
    # ...
```

This is the "are we going to hit the year?" view. Surface accounts where the annualized run-rate exceeds budget by >20% — those are the at-risk categories.

## What to do when over budget

The variance report is diagnostic, not prescriptive. When an expense is over:
1. **Drill into the detail** — `ProfitAndLossDetail` filtered to that account, see the actual transactions
2. **Identify cause** — one big purchase? Recurring increase? Misclassification?
3. **Take action** — reduce spend, reforecast budget, accept variance

When an income is under:
1. **Drill into items** — which items underperformed?
2. **Check pipeline** — what's expected to close in remaining quarters?
3. **Identify cause** — lost customer? Pricing pressure? Capacity issue?

## Budget hygiene

If QB has no budget data (never set up), this skill's reports return empty. Operator needs to:
1. In QB Desktop UI: Company → Planning & Budgeting → Set Up Budgets
2. Choose a fiscal year, budget type (P&L), and method (from scratch or based on last year's actuals)
3. Enter per-account monthly amounts

The SDK can READ the budget but cannot WRITE budgets in v1. Budget creation/edit is UI-only.

## Pointers

- Underlying actual P&L data: [quickbooks-reports](../quickbooks-reports/SKILL.md)
- Class-level performance (similar but no budget compare): [quickbooks-class-margin-analysis](../quickbooks-class-margin-analysis/SKILL.md)
- Forward-looking projections (without budget): [quickbooks-forecasting](../quickbooks-forecasting/SKILL.md)
- Annual budget review fits with: [quickbooks-period-close](../quickbooks-period-close/SKILL.md)
