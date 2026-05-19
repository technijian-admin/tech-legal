---
name: quickbooks-ar-collections
description: Manage QuickBooks accounts receivable collections — identify overdue invoices, draft collection reminders by aging bucket, calculate days sales outstanding (DSO), and surface customers needing escalation. Use when the user asks "who owes us money?", "draft collection emails", "what's our DSO?", "AR aging", "who's overdue?", or wants to prioritize collection effort. Multi-tenant — default `technijian`.
---

# QuickBooks AR Collections

Pulls the receivables data and operationalizes it: not just "here's the aging report" but "here are the 12 customers you should call this morning and how to approach each one".

Multi-tenant: default `technijian`.

## Step 1: Pull the aging picture

```python
from qb_client import QbClient
from datetime import date
client = QbClient.from_env().with_company("technijian")

# Summary view first (one row per customer):
ar = client.op("report", {"type": "AgingAR", "dateMacro": "Today"})
# Detail view (one row per invoice):
ar_detail = client.qbxml('''<?xml version="1.0"?>
<?qbxml version="16.0"?>
<QBXML><QBXMLMsgsRq onError="stopOnError">
  <AgingReportQueryRq>
    <AgingReportType>ARAgingDetail</AgingReportType>
    <DisplayReport>false</DisplayReport>
    <ReportDate>2026-05-19</ReportDate>
  </AgingReportQueryRq>
</QBXMLMsgsRq></QBXML>''')
```

Or assemble from open invoices directly:

```python
inv = client.op("list_invoices", {"dateMacro": "ThisFiscalYearToDate"})
today = date.today()
open_invoices = []
for r in inv["rows"]:
    bal = float(r.get("BalanceRemaining", 0) or 0)
    if bal <= 0:
        continue
    due = date.fromisoformat(r["DueDate"]) if r.get("DueDate") else None
    days_overdue = (today - due).days if due else 0
    open_invoices.append({
        "customer":     (r.get("CustomerRef") or {}).get("FullName"),
        "ref":          r.get("RefNumber"),
        "txn_id":       r.get("TxnID"),
        "txn_date":     r.get("TxnDate"),
        "due_date":     r.get("DueDate"),
        "days_overdue": days_overdue,
        "balance":      bal,
    })
```

## Step 2: Bucket the action

| Days overdue | Action | Tone |
|---|---|---|
| 0 (current) | None — invoice not yet due | n/a |
| 1-15 | Friendly reminder | "Just a heads-up..." |
| 16-30 | Past-due reminder | "Your invoice is now past due..." |
| 31-60 | Firm reminder + small late fee discussion | "We need to resolve this..." |
| 61-90 | Final reminder + service-suspension warning | "Without payment by [date], we will..." |
| >90 | Escalate to direct call + collection agency consideration | Conversation, not email |

```python
def collection_bucket(days_overdue):
    if days_overdue < 1:   return "current"
    if days_overdue <= 15: return "friendly"
    if days_overdue <= 30: return "pastdue"
    if days_overdue <= 60: return "firm"
    if days_overdue <= 90: return "final"
    return "escalate"

# Group customers by their WORST aging bucket:
from collections import defaultdict
by_customer = defaultdict(list)
for inv in open_invoices:
    by_customer[inv["customer"]].append(inv)

for customer, invs in sorted(by_customer.items(), key=lambda x: -sum(i["balance"] for i in x[1])):
    worst = max(invs, key=lambda i: i["days_overdue"])
    bucket = collection_bucket(worst["days_overdue"])
    total = sum(i["balance"] for i in invs)
    if bucket == "current":
        continue   # skip current
    print(f"[{bucket:8}] {customer:30}  ${total:>10,.0f}  ({len(invs)} invs, worst {worst['days_overdue']}d overdue)")
```

## Step 3: Draft a collection email per bucket

A reminder template — customize the tone per bucket:

```python
def reminder_template(customer, invs, bucket):
    total = sum(i["balance"] for i in invs)
    inv_list = "\n".join(f"  - INV #{i['ref']} dated {i['txn_date']}, due {i['due_date']}, balance ${i['balance']:,.2f}" for i in invs)
    if bucket == "friendly":
        return f"""Hi {customer},

Hope you're well. This is a friendly reminder that the following invoice(s) are coming due or recently came due:

{inv_list}

Total outstanding: ${total:,.2f}

If you've already sent payment, please disregard. Otherwise we'd appreciate processing at your earliest convenience.

Best regards,
Technijian Accounting
finance@technijian.com
"""
    elif bucket == "pastdue":
        return f"""Hi {customer},

The following invoice(s) are now past due:

{inv_list}

Total outstanding: ${total:,.2f}

Could you please let us know when payment will be processed? If there's anything we need to address on our end, please let us know.

Thanks,
Technijian Accounting
"""
    elif bucket == "firm":
        return f"""{customer} team,

We're concerned that the following invoices remain unpaid more than 30 days past their due date:

{inv_list}

Total outstanding: ${total:,.2f}

Please process payment within the next 7 days, or contact us to discuss a payment plan. If we don't hear back, we'll need to escalate.

Technijian Accounting
"""
    elif bucket == "final":
        return f"""{customer} team,

FINAL REMINDER — the following invoices are over 60 days past due:

{inv_list}

Total outstanding: ${total:,.2f}

To avoid service suspension and/or referral to collections, please remit payment within 5 business days, or contact finance@technijian.com to arrange a payment plan.

We'd much rather resolve this collaboratively.

Technijian Accounting
"""
    elif bucket == "escalate":
        return f"""[INTERNAL: do NOT auto-send for >90 days overdue]

{customer} is more than 90 days past due — total ${total:,.2f}.

Recommended action: schedule a direct phone call. Email reminders are no longer effective at this stage.
"""
    return None
```

## Step 4: Draft batch, human reviews, send via Gmail/M365

The agent (or operator) generates reminder drafts. ALWAYS human-reviewed before send. No auto-send of past-due / firm / final reminders without confirmation.

For the friendly tier, light-touch auto-send is acceptable IF:
- The agent has been configured by the operator to allow it
- A daily summary email goes to finance@technijian.com showing what was sent

For all others, human approval is required.

## DSO (Days Sales Outstanding)

DSO measures average days from invoice to cash. Lower is better. Formula:

```
DSO = (Average AR / Total Credit Sales) × N_days
```

```python
# Pull AR balance and credit sales for a period
from datetime import datetime, timedelta

# Average AR over period — approximate using start and end balance
end_ar = sum(float(r["BalanceRemaining"]) for r in client.op("list_invoices", {"dateMacro": "ThisFiscalYearToDate"})["rows"] if float(r.get("BalanceRemaining", 0)) > 0)
# (For "start AR" you'd need a balance sheet at the start of period — use BalanceSheetStandard)

# Total credit sales over period (sum of invoice TotalAmount):
period_invoices = client.op("list_invoices", {"fromDate": "2026-01-01", "toDate": "2026-05-19"})
total_sales = sum(float(r.get("TotalAmount", 0)) for r in period_invoices["rows"])

n_days = 139  # Jan 1 - May 19
avg_ar = end_ar  # approximation; ideally average of start + end
dso = (avg_ar / total_sales) * n_days
print(f"Approximate YTD DSO: {dso:.0f} days")
```

For Technijian's typical Net 30 terms, healthy DSO is 30-45 days. Above 60 means systemic collection issues; investigate.

## Concentration check

Just like vendor concentration, AR concentration matters: if one customer is >25% of total AR, you have a single-customer risk.

```python
from collections import defaultdict
balance_by_customer = defaultdict(float)
for inv in open_invoices:
    balance_by_customer[inv["customer"]] += inv["balance"]
total_ar = sum(balance_by_customer.values())
for c, b in sorted(balance_by_customer.items(), key=lambda x: -x[1])[:10]:
    print(f"  {c:30} ${b:>10,.2f}  ({b/total_ar*100:.1f}%)")
```

## Auto-pay / ACH set-up suggestions

For chronically slow-pay customers (always 30+ days past due), the cure is structural: get them on autopay (ACH or credit card). Surface this as a recommendation in your output:

```python
chronically_slow = [c for c, invs in by_customer.items()
                    if all(i["days_overdue"] > 20 for i in invs)
                    and len(invs) >= 3]
for c in chronically_slow:
    print(f"AUTO-PAY CANDIDATE: {c} has 3+ chronically late invoices — propose ACH setup")
```

## Patterns the agent commonly handles

- **Daily**: re-pull AR, flag newly overdue (just crossed 30, 60, 90), draft friendly reminders for 1-15 day bucket
- **Weekly**: full collection cycle — send all reminders due, escalate >60-day items to manager
- **Monthly**: recalculate DSO, report trends, identify customers to fire (revenue not worth collection effort)

## Pointers

- Invoice details + line items: [quickbooks-invoices](../quickbooks-invoices/SKILL.md)
- Customer profitability (some slow-pay customers turn out to be unprofitable anyway): [quickbooks-customer-profitability](../quickbooks-customer-profitability/SKILL.md)
- Cash flow impact: [quickbooks-cash-flow](../quickbooks-cash-flow/SKILL.md)
- Receiving payments once they arrive: [quickbooks-checks-and-payments](../quickbooks-checks-and-payments/SKILL.md)
