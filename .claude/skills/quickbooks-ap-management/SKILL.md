---
name: quickbooks-ap-management
description: Manage QuickBooks accounts payable strategically — surface bills coming due, prioritize by cash impact + vendor relationship, identify discount-window opportunities (e.g. 2/10 net 30), suggest payment batches that optimize cash retention. Use when the user asks "what bills are due?", "what should we pay this week?", "any discounts we can capture?", or wants to plan AP payment runs. Multi-tenant — default `technijian`.
---

# QuickBooks AP Management

Most AP "management" reduces to: pay everything due, in roughly due-date order, before late fees kick in. But there's optimization to be had if:

- Some vendors offer early-payment discounts (2/10 net 30 = 2% off if paid within 10 days)
- Cash is constrained and you need to prioritize which bills get paid first
- Some vendors have stricter late-payment consequences (line of credit, automatic service suspension)

This skill operationalizes those decisions.

Multi-tenant: default `technijian`.

## Pull open bills with due dates

```python
from qb_client import QbClient
from datetime import date
from collections import defaultdict
client = QbClient.from_env().with_company("technijian")

bills = client.op("list_bills", {"dateMacro": "ThisFiscalYearToDate"})["rows"]
today = date.today()
open_bills = []
for r in bills:
    amt = float(r.get("AmountDue", 0) or 0)
    if amt <= 0:
        continue
    due = date.fromisoformat(r["DueDate"]) if r.get("DueDate") else None
    days_to_due = (due - today).days if due else None
    open_bills.append({
        "vendor":      (r.get("VendorRef") or {}).get("FullName"),
        "ref":         r.get("RefNumber"),
        "txn_id":      r.get("TxnID"),
        "txn_date":    r.get("TxnDate"),
        "due_date":    r.get("DueDate"),
        "days_to_due": days_to_due,
        "amount":      amt,
        "terms":       r.get("TermsRef", {}).get("FullName", ""),
    })

print(f"Total open AP: ${sum(b['amount'] for b in open_bills):,.2f}  ({len(open_bills)} bills)")
```

## Bucket by urgency

| Days to due | Action | Reason |
|---|---|---|
| `< 0` | PAY NOW (already late) | avoid late fees, protect vendor relationship |
| `0-3` | PAY THIS WEEK | due imminently |
| `4-10` | PAY THIS WEEK if 2/10 net 30 | capture discount; otherwise defer |
| `11-30` | DEFER (within terms) | hold cash, no benefit to paying early |
| `> 30` | DEFER | far in the future |

```python
def ap_bucket(days_to_due, terms):
    if days_to_due is None:    return "no_due_date"
    if days_to_due < 0:        return "OVERDUE"
    if days_to_due <= 3:       return "due_this_week"
    if days_to_due <= 10 and has_early_discount(terms): return "discount_window"
    if days_to_due <= 30:      return "defer_within_terms"
    return "far_future"

def has_early_discount(terms):
    """Recognize terms like '2% 10 Net 30' or '2/10 Net 30'."""
    if not terms: return False
    import re
    return bool(re.search(r"\d+\s*%?\s*[/]?\s*10", terms))
```

## Pattern: weekly payment plan

```python
weekly_payable = sum(b["amount"] for b in open_bills if b["days_to_due"] is not None and b["days_to_due"] <= 7)
print(f"AP coming due in next 7 days: ${weekly_payable:,.2f}")

current_cash = sum(float(a.get("Balance", 0)) for a in client.op("list_accounts")["rows"] if a["AccountType"] == "Bank")
print(f"Current cash: ${current_cash:,.2f}")

# Build a payment batch in priority order:
ordered = sorted(open_bills, key=lambda b: (
    0 if (b["days_to_due"] or 0) < 0 else        # overdue first
    1 if (b["days_to_due"] or 999) <= 3 else      # due this week
    2 if (b["days_to_due"] or 999) <= 10 and has_early_discount(b["terms"]) else  # discount window
    3,
    b["days_to_due"] or 999,                       # then by due date
    -b["amount"],                                   # then by amount (larger first within tier)
))

cash_available = current_cash * 0.85   # don't drain to zero
plan = []
running = 0
for b in ordered:
    if running + b["amount"] > cash_available:
        break
    plan.append(b)
    running += b["amount"]

print(f"\n=== Proposed payment batch (${running:,.2f}) ===")
for b in plan:
    print(f"  {b['vendor']:30}  REF {b['ref']:12}  due {b['due_date']}  ${b['amount']:>10,.2f}  ({b['terms']})")
```

## Capture early-payment discounts

For bills with discount terms (e.g. "2% 10 Net 30"), paying within 10 days saves 2%. On a $5000 bill, that's $100 saved. Annualized return on 20 extra days of cash:

```
($100 / $4900) × (365 / 20) = 37.2% annualized
```

That's a HUGE return — better than any investment most companies can earn on cash. ALWAYS take early-payment discounts unless cash is constrained.

```python
discount_savings = []
for b in open_bills:
    if not has_early_discount(b["terms"]):
        continue
    # 2/10 net 30 → 2% off if paid within 10 days of bill date
    bill_date = date.fromisoformat(b["txn_date"])
    discount_deadline = bill_date + timedelta(days=10)
    if today <= discount_deadline:
        savings = b["amount"] * 0.02
        discount_savings.append((b["vendor"], b["ref"], b["amount"], savings, discount_deadline))

print("\n=== Available early-pay discounts ===")
for vendor, ref, amt, save, deadline in sorted(discount_savings, key=lambda x: -x[3]):
    print(f"  {vendor:30}  REF {ref:12}  ${amt:>8,.2f}  save ${save:>5,.2f}  by {deadline}")
```

## Cash-constrained mode (pay only critical bills)

When cash is tight, prioritize by vendor-relationship impact:

| Tier | Examples | Action |
|---|---|---|
| Tier 1: Pay immediately | Payroll (Gusto/ADP), critical software (Microsoft, RMM), rent, utilities, insurance | Service stops or legal exposure if late |
| Tier 2: Pay on time | Internet/phone, recurring subscriptions where churn would hurt | Late fees / minor relationship damage |
| Tier 3: Negotiate / delay | One-off purchases, non-critical subscriptions, contractors with flexible terms | Can stretch 30-60 days without harm |

```python
TIER_1_KEYWORDS = ["payroll", "gusto", "adp", "microsoft", "rent", "lease", "electric", "edison", "pg&e", "internet", "at&t", "cox", "insurance", "blue shield", "blue cross"]
TIER_3_KEYWORDS = ["contractor", "consultant", "freelance", "one-time", "amazon", "office depot", "staples"]

def vendor_tier(vendor_name):
    n = vendor_name.lower()
    if any(k in n for k in TIER_1_KEYWORDS): return 1
    if any(k in n for k in TIER_3_KEYWORDS): return 3
    return 2

# Stratify open bills:
by_tier = defaultdict(list)
for b in open_bills:
    by_tier[vendor_tier(b["vendor"])].append(b)

for t in [1, 2, 3]:
    tot = sum(b["amount"] for b in by_tier[t])
    print(f"Tier {t}: ${tot:,.0f}  ({len(by_tier[t])} bills)")
```

Pay tier 1 first regardless. Tier 2 in due-date order. Tier 3 last; stretch if needed.

## Negotiate-with-vendor flagging

When you're going to be late on a bill, notify the vendor BEFORE the due date. Almost every vendor will work with you on payment timing if you communicate. Surface this as a daily recommendation:

```python
about_to_be_late = [b for b in open_bills if b["days_to_due"] is not None and 0 <= b["days_to_due"] <= 5]
unaffordable = []  # we won't be able to pay these
# ... logic to flag based on projected cash flow ...

for b in unaffordable:
    print(f"NEGOTIATE: {b['vendor']} bill {b['ref']} for ${b['amount']:,.2f} due {b['due_date']} — call them today to arrange extended terms")
```

## Auto-pay enrollment recommendations

For consistently-paid recurring bills (utilities, software, internet), auto-pay saves administrative effort AND ensures no missed due dates. Identify candidates:

```python
# Vendors with 3+ bills in last 6 months, all paid on or before due:
# (suggest moving them to ACH auto-pay)
```

## When to fire a vendor (or renegotiate)

Triggers:
- Multiple price increases in 12 months without comparable feature gains
- Bills consistently inaccurate / requiring dispute
- Vendor unwilling to negotiate terms even after sustained partnership
- Better alternatives at same/lower cost

Flag for human review based on historical data.

## Pointers

- Bill CRUD (creating, modifying bills): [quickbooks-bills](../quickbooks-bills/SKILL.md)
- Actually paying bills (BillPaymentCheck — not yet wrapped, use raw qbXML): [quickbooks-checks-and-payments](../quickbooks-checks-and-payments/SKILL.md)
- Cash impact of AP payments: [quickbooks-cash-flow](../quickbooks-cash-flow/SKILL.md)
- Vendor analysis (who are you paying, 1099 prep): [quickbooks-vendor-spend-and-1099](../quickbooks-vendor-spend-and-1099/SKILL.md)
- Forward-looking cash projection considering AP: [quickbooks-forecasting](../quickbooks-forecasting/SKILL.md)
