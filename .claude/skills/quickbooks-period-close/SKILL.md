---
name: quickbooks-period-close
description: Execute QuickBooks period-end close — month, quarter, or year. Includes accrual JEs, depreciation, bank reconciliation prep, intercompany checks, deferred revenue rolls, and a hygiene checklist. Use when the user asks "close the month", "month-end procedures", "year-end close", "what do we need to close [month/year]?", or "is the period ready to close?". Multi-tenant — default `technijian`.
---

# QuickBooks Period-End Close

Closing a period in QuickBooks means: every transaction belonging to the period is entered, every account is reconciled, every necessary accrual/adjustment is booked, and the period is locked so reports give stable numbers.

This skill operationalizes the close checklist.

Multi-tenant: default `technijian`.

## The monthly close checklist (10 stages)

### 1. All transactions entered

- [ ] All customer invoices for the month created (`list_invoices` with `fromDate`/`toDate` matching the period)
- [ ] All vendor bills entered (`list_bills`)
- [ ] All checks recorded (`run_query` entity=Check for the period)
- [ ] All customer payments applied (`list_payments`)
- [ ] All bank-feed downloads classified (see [quickbooks-bank-feed-classifier](../quickbooks-bank-feed-classifier/SKILL.md))

Hygiene check: scan for missing weekly/monthly recurring bills (e.g. if Microsoft normally bills on the 5th and there's no May 5 bill from Microsoft, something was missed).

### 2. Bank reconciliation

For each Bank and CreditCard account:
- [ ] Pull register transactions for the period (`run_query` entity=Check/Deposit/CreditCardCharge/etc. filtered by account + date)
- [ ] Compare to bank statement
- [ ] Flag any unmatched items
- [ ] If reconciled, lock the reconciliation (UI-only operation in QB)

The SDK doesn't expose `ReconciliationAdd` — you have to do the actual mark-as-reconciled in the QB UI. But you can pre-check the math:

```python
# Sum of cleared transactions for the period should equal (ending balance - starting balance)
# in the bank account.
xml = '''<?xml version="1.0"?>
<?qbxml version="16.0"?>
<QBXML><QBXMLMsgsRq onError="stopOnError">
  <CheckQueryRq>
    <AccountFilter><FullName>1010 - Operating Checking</FullName></AccountFilter>
    <ModifiedDateRangeFilter>
      <FromModifiedDate>2026-05-01</FromModifiedDate>
      <ToModifiedDate>2026-05-31</ToModifiedDate>
    </ModifiedDateRangeFilter>
  </CheckQueryRq>
</QBXMLMsgsRq></QBXML>'''
```

### 3. Accrue revenue earned but not invoiced

Common at month-end: work delivered in the period, but the invoice goes out in the next period. Books the revenue in the right period via a JE.

```python
# See [quickbooks-journal-entries](../quickbooks-journal-entries/SKILL.md) for the full JE pattern.
# Typical:
#   DR  1200 - Accrued Receivable  $X
#   CR  1000 - Consulting          $X
# Reverse in next period when actual invoice is created.
```

### 4. Defer revenue invoiced but not yet earned

Inverse of #3 — invoice went out in the period for service that spans into next period. Defer the unearned portion.

```python
# Typical (for an annual subscription invoiced upfront):
#   DR  1000 - Consulting           $X (reduce current revenue)
#   CR  2300 - Deferred Revenue     $X (liability)
# Recognize portion to revenue each month going forward.
```

### 5. Accrue expenses incurred but not yet billed

Expenses received but no bill yet (e.g. utility bills that arrive next month for this month's usage).

```python
#   DR  6080 - Office General:6080.09 - Utilities  $X (book in current period)
#   CR  2100 - Accrued Expenses                    $X (liability)
# Reverse next period when actual bill arrives, then book the real bill.
```

### 6. Depreciation

If you have fixed assets (computers, equipment, vehicles), book monthly depreciation.

```python
# For each depreciable asset:
#   DR  6095 - Depreciation Expense        $X
#   CR  1500 - Accumulated Depreciation    $X
```

For an MSP heavy in laptops/servers, this can be significant. Annual ~$30K depreciation = $2500/month.

### 7. Intercompany transfers / equity contributions

If you moved money between Operating, Payroll, Money Market accounts, or owners contributed/withdrew, book those.

### 8. Sales tax review

Check `Sales Tax Liability Report`:

```python
xml = '''<?xml version="1.0"?>
<?qbxml version="16.0"?>
<QBXML><QBXMLMsgsRq onError="stopOnError">
  <GeneralSummaryReportQueryRq>
    <GeneralSummaryReportType>SalesTaxLiability</GeneralSummaryReportType>
    <DisplayReport>false</DisplayReport>
    <ReportPeriod>
      <FromReportDate>2026-05-01</FromReportDate>
      <ToReportDate>2026-05-31</ToReportDate>
    </ReportPeriod>
  </GeneralSummaryReportQueryRq>
</QBXMLMsgsRq></QBXML>'''
```

Flag any sales tax that needs remitting.

### 9. Review P&L and Balance Sheet for sanity

```python
pnl = client.op("report", {"type": "ProfitAndLoss", "fromDate": "2026-05-01", "toDate": "2026-05-31"})
bs  = client.op("report", {"type": "BalanceSheet",   "dateMacro": "Today"})

# Common sanity checks:
# - Net Income changed dramatically from last month?
# - Any account with a normal-balance violation (e.g., accounts payable showing a debit balance)?
# - Class-tracked income/expense matches account-level totals?
```

Cross-check:
```python
# Total Income by class should match Total Income by account
class_report = ...    # from class-margin-analysis pattern
acct_report = pnl

# If they don't match → some transactions have NO class assignment
```

### 10. Lock the period (QB UI only)

QB Desktop's "Closing Date" feature (Edit → Preferences → Accounting → Company Preferences → Set Closing Date) locks the period. After closing, only Admin can post to a closed period. The SDK can READ but not SET the closing date directly.

Schedule a calendar reminder for the 10th of each month to lock the prior month.

---

## The full close ritual — recommended timeline

| Day of next month | Task |
|---|---|
| 1-3 | Ensure all transactions entered; run AR/AP aging |
| 3-5 | Bank-feed classification + bank reconciliation |
| 5-7 | Accruals + deferrals + depreciation JEs |
| 7-8 | Sales tax review; intercompany sweeps |
| 8-10 | P&L / BS review; flag anomalies |
| 10 | Lock the period |

For year-end, multiply by ~3x. The first month after fiscal year-end (Feb for calendar year) should also include:
- Fixed asset register review and reconciliation
- Inventory count (if applicable)
- 1099 preparation (see [quickbooks-vendor-spend-and-1099](../quickbooks-vendor-spend-and-1099/SKILL.md))
- W-2 generation (typically via payroll provider)
- Year-end auditor packet

## Patterns

### "Is the period ready to close?"

Run all 10 stages as checks; report status. Anything failing → flag for resolution.

### "Show me anomalies in May vs April"

```python
may = client.op("report", {"type": "ProfitAndLoss", "fromDate": "2026-05-01", "toDate": "2026-05-31"})
apr = client.op("report", {"type": "ProfitAndLoss", "fromDate": "2026-04-01", "toDate": "2026-04-30"})

# For each account, compute month-over-month delta and % change.
# Flag any with > 50% change.
```

### "Did we miss any recurring bills this month?"

```python
# Pull last 3 months of bills, identify vendors with monthly cadence,
# check if current month is missing.
```

## Recurring JE templates

Save these as Python dicts and run them programmatically each month (still dry-run + confirm):

```python
DEPRECIATION_JE = {
    "txnDate": "MONTH_END_DATE",
    "refNumber": "DEPR-YYYY-MM",
    "memo": "Monthly depreciation",
    "isAdjustment": True,
    "debits":  [{"accountRef": {"fullName": "6095 - Depreciation Expense"}, "amount": 2100, "classRef": {"fullName": "Admin (US)"}}],
    "credits": [{"accountRef": {"fullName": "1500 - Accumulated Depreciation"}, "amount": 2100, "classRef": {"fullName": "Admin (US)"}}],
}

PREPAID_INSURANCE_ROLL = {
    "txnDate": "MONTH_END_DATE",
    "refNumber": "PREPAID-INS-YYYY-MM",
    "memo": "Monthly allocation of prepaid insurance",
    "isAdjustment": True,
    "debits":  [{"accountRef": {"fullName": "6130 - Insurance:6130.4 - Medical Insurance"}, "amount": 1250, "classRef": {"fullName": "Admin (US)"}}],
    "credits": [{"accountRef": {"fullName": "1300 - Prepaid Insurance"}, "amount": 1250, "classRef": {"fullName": "Admin (US)"}}],
}
```

Operator confirms amounts each month (may vary), then dry-run + execute.

## Pointers

- JE mechanics: [quickbooks-journal-entries](../quickbooks-journal-entries/SKILL.md)
- Bank feeds / reconciliation prep: [quickbooks-bank-feeds](../quickbooks-bank-feeds/SKILL.md), [quickbooks-bank-feed-classifier](../quickbooks-bank-feed-classifier/SKILL.md)
- Reports: [quickbooks-reports](../quickbooks-reports/SKILL.md)
- Annual close 1099 prep: [quickbooks-vendor-spend-and-1099](../quickbooks-vendor-spend-and-1099/SKILL.md)
- Budget vs actual (often reviewed at close): [quickbooks-budget-vs-actual](../quickbooks-budget-vs-actual/SKILL.md)
