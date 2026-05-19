---
name: quickbooks-bank-feed-classifier
description: Auto-classify downloaded bank-feed transactions and recurring ACH/debit-card charges into the right GL account AND class. Pulls pending bank-feed items, matches them to existing checks/bills, or accepts new ones with rule-based account+class coding. Use when the user asks to "categorize bank transactions", "code the ACH debits", "process bank downloads", "auto-classify recurring charges", or wants to clear the bank-feed inbox. Multi-tenant — default `technijian`.
---

# QuickBooks Bank Feed Classifier

Sister skill to [quickbooks-bank-feeds](../quickbooks-bank-feeds/SKILL.md) — that one is the raw "read what QB downloaded" + "match to existing transactions" mechanics. **This one is the auto-classification engine** that turns the messy `PayeeName="WALMART #1234 ANAHEIM CA"` strings into properly coded check transactions with the right account AND the right class.

## Why this matters

Class-correct coding is the foundation of [quickbooks-class-margin-analysis](../quickbooks-class-margin-analysis/SKILL.md). If your bank-feed processor codes a Microsoft 365 wholesale debit to `6080 - Office General` with no class, you've just polluted your operating-expense bucket AND made the Office 365 class look more profitable than it is. The cure is at the classification step.

## Multi-tenant

`company=` or `QB_DEFAULT_COMPANY`. Default `technijian`. Authorized: `technijian`, `electronic-corporation-of-america`.

## Recurring ACH debits — special handling

Recurring ACH/debit-card charges follow predictable patterns:
- **Same vendor every month** (Microsoft, Cisco, Sophos, Huntress, Inky, Kaseya, AWS, Dropbox, etc.)
- **Same account** (always 5xxx for COGS pass-throughs, sometimes specific 6xxx for ops)
- **Same class** — this is the key insight: a wholesale Microsoft 365 charge ALWAYS lands on `Office 365 (Online Services)` class because that's what we resell

So a rule-based classifier with `payee → (account, class)` mappings handles 80%+ of recurring activity. The other 20% (one-off purchases, unusual vendors) needs human review.

## The classification rule structure

A "rule" is a tuple:

```python
{
    "match": {                          # how to match a bank-feed transaction
        "payee_contains": "MICROSOFT",  # any substring (case-insensitive)
        "amount_range": (None, None),   # optional min/max
        "account": "1011 - Amex Card",  # optional bank/CC account this rule applies to
    },
    "classify": {                       # how to code it
        "expense_account": "5501 - Software Licensing",
        "class": "Office 365 (Online Services)",
        "payee_entity": "Microsoft",    # vendor name in QB (for 1099 attribution)
        "memo_template": "{original_memo} - Microsoft 365 wholesale",
    },
}
```

A rule library for Technijian's recurring pass-throughs (start here, expand as you find new ones):

```python
RULES = [
    # === Software pass-through (COGS, class = resale class) ===
    {"match": {"payee_contains": "MICROSOFT"},          "classify": {"expense_account": "5501 - Software Licensing", "class": "Office 365 (Online Services)", "payee_entity": "Microsoft"}},
    {"match": {"payee_contains": "CISCO UMBRELLA"},     "classify": {"expense_account": "5501 - Software Licensing", "class": "Cisco Umbrella",                "payee_entity": "Cisco Systems"}},
    {"match": {"payee_contains": "SOPHOS"},             "classify": {"expense_account": "5501 - Software Licensing", "class": "Sophos",                       "payee_entity": "Sophos"}},
    {"match": {"payee_contains": "HUNTRESS"},           "classify": {"expense_account": "5501 - Software Licensing", "class": "Huntress",                     "payee_entity": "Huntress Labs"}},
    {"match": {"payee_contains": "INKY"},               "classify": {"expense_account": "5501 - Software Licensing", "class": "Inky",                         "payee_entity": "Inky Technology"}},
    {"match": {"payee_contains": "NINJIO"},             "classify": {"expense_account": "5501 - Software Licensing", "class": "NinJio",                       "payee_entity": "NINJIO"}},
    {"match": {"payee_contains": "KASEYA"},             "classify": {"expense_account": "5501 - Software Licensing", "class": "Kaseya",                       "payee_entity": "Kaseya"}},
    {"match": {"payee_contains": "MANAGEENGINE"},       "classify": {"expense_account": "5501 - Software Licensing", "class": "ManageEngine",                 "payee_entity": "ManageEngine"}},
    {"match": {"payee_contains": "GODADDY"},            "classify": {"expense_account": "5501 - Software Licensing", "class": "GoDaddy (Products)",           "payee_entity": "GoDaddy"}},
    {"match": {"payee_contains": "CENTRASTACK"},        "classify": {"expense_account": "5501 - Software Licensing", "class": "CenterStack",                  "payee_entity": "Centrastack"}},
    {"match": {"payee_contains": "PASSPORTAL"},         "classify": {"expense_account": "5501 - Software Licensing", "class": "Passportal",                   "payee_entity": "Passportal"}},
    {"match": {"payee_contains": "ONELOGIN"},           "classify": {"expense_account": "5501 - Software Licensing", "class": "OneLogin",                     "payee_entity": "OneLogin"}},
    {"match": {"payee_contains": "EASYDMARC"},          "classify": {"expense_account": "5501 - Software Licensing", "class": "EasyDMARC",                    "payee_entity": "EasyDMARC"}},
    {"match": {"payee_contains": "SCREENCONNECT"},      "classify": {"expense_account": "5501 - Software Licensing", "class": "Screen connect",               "payee_entity": "ConnectWise"}},
    {"match": {"payee_contains": "FOXIT"},              "classify": {"expense_account": "5501 - Software Licensing", "class": "FoxIT",                        "payee_entity": "Foxit Software"}},
    {"match": {"payee_contains": "SYNOLOGY"},           "classify": {"expense_account": "5501 - Software Licensing", "class": "Synology",                     "payee_entity": "Synology"}},

    # === Internet / telephony (COGS for resale; class = service line) ===
    {"match": {"payee_contains": "AT&T"},               "classify": {"expense_account": "5502 - Internet Support",   "class": "Admin (US)",      "payee_entity": "AT&T"}},
    {"match": {"payee_contains": "COX"},                "classify": {"expense_account": "5502 - Internet Support",   "class": "Admin (US)",      "payee_entity": "Cox Business"}},
    {"match": {"payee_contains": "DIDFORSALE"},         "classify": {"expense_account": "5502 - Internet Support",   "class": "DIDForSale",      "payee_entity": "DIDForSale"}},

    # === Hardware purchases ===
    {"match": {"payee_contains": "AMAZON"},             "classify": {"expense_account": "5503 - Hardware Costs",      "class": "Admin (US)",      "payee_entity": "Amazon"}},   # may need review (could be office, hardware-for-resale, etc.)
    {"match": {"payee_contains": "NEWEGG"},             "classify": {"expense_account": "5503 - Hardware Costs",      "class": "Admin (US)",      "payee_entity": "Newegg"}},
    {"match": {"payee_contains": "DELL"},               "classify": {"expense_account": "5503 - Hardware Costs",      "class": "Admin (US)",      "payee_entity": "Dell"}},

    # === Operating expenses (NOT COGS — these are 6xxx) ===
    {"match": {"payee_contains": "OFFICE DEPOT"},       "classify": {"expense_account": "6080 - Office General:6080.06 - Supplies", "class": "Admin (US)",    "payee_entity": "Office Depot"}},
    {"match": {"payee_contains": "STAPLES"},            "classify": {"expense_account": "6080 - Office General:6080.06 - Supplies", "class": "Admin (US)",    "payee_entity": "Staples"}},
    {"match": {"payee_contains": "PG&E"},               "classify": {"expense_account": "6080 - Office General:6080.09 - Utilities", "class": "Admin (US)",   "payee_entity": "PG&E"}},
    {"match": {"payee_contains": "SOCAL EDISON"},       "classify": {"expense_account": "6080 - Office General:6080.09 - Utilities", "class": "Admin (US)",   "payee_entity": "Southern California Edison"}},
    {"match": {"payee_contains": "STARBUCKS"},          "classify": {"expense_account": "6110 - Travel & Ent:6110.2 - Meals",        "class": "Admin (US)",    "payee_entity": "Starbucks"}},
    {"match": {"payee_contains": "UBER"},               "classify": {"expense_account": "6110 - Travel & Ent",                       "class": "Admin (US)",    "payee_entity": "Uber"}},

    # === Bank fees ===
    {"match": {"payee_contains": "STRIPE FEE"},         "classify": {"expense_account": "6020 - Bank Service Charges:6020.3 - Credit Card Processing Fees", "class": "Admin (US)", "payee_entity": "Stripe"}},
    {"match": {"payee_contains": "MERCHANT FEE"},       "classify": {"expense_account": "6020 - Bank Service Charges:6020.3 - Credit Card Processing Fees", "class": "Admin (US)", "payee_entity": "Bank"}},
    {"match": {"payee_contains": "WIRE FEE"},           "classify": {"expense_account": "6020 - Bank Service Charges",                                       "class": "Admin (US)", "payee_entity": "Bank"}},

    # === Payroll / benefits ===
    {"match": {"payee_contains": "GUSTO"},              "classify": {"expense_account": "6115 - Payroll Expenses:6115.01 - Processing", "class": "Admin (US)", "payee_entity": "Gusto"}},
    {"match": {"payee_contains": "ADP"},                "classify": {"expense_account": "6115 - Payroll Expenses:6115.01 - Processing", "class": "Admin (US)", "payee_entity": "ADP"}},

    # === Insurance ===
    {"match": {"payee_contains": "BLUE SHIELD"},        "classify": {"expense_account": "6130 - Insurance:6130.4 - Medical Insurance",  "class": "Admin (US)", "payee_entity": "Blue Shield"}},
    {"match": {"payee_contains": "BLUE CROSS"},         "classify": {"expense_account": "6130 - Insurance:6130.4 - Medical Insurance",  "class": "Admin (US)", "payee_entity": "Blue Cross"}},
]
```

## The workflow

```python
from qb_client import QbClient
import xml.etree.ElementTree as ET

client = QbClient.from_env().with_company("technijian")

# 1. Pull pending bank-feed items
xml = '''<?xml version="1.0"?>
<?qbxml version="16.0"?>
<QBXML><QBXMLMsgsRq onError="stopOnError">
  <OnlineBankingTransactionQueryRq>
    <MaxReturned>500</MaxReturned>
    <Status>PendingMatch</Status>
  </OnlineBankingTransactionQueryRq>
</QBXMLMsgsRq></QBXML>'''
doc = ET.fromstring(client.qbxml(xml))

# 2. For each pending item, apply rules
pending = []
for txn in doc.findall(".//OnlineBankingTransactionRet"):
    payee  = (txn.findtext("PayeeName") or "").upper()
    amount = float(txn.findtext("Amount") or 0)
    date   = txn.findtext("TxnDate")
    obt_id = txn.findtext("TxnID")
    memo   = txn.findtext("Memo") or ""

    match = None
    for rule in RULES:
        if rule["match"]["payee_contains"].upper() in payee:
            match = rule
            break

    pending.append({
        "obt_id": obt_id,
        "date": date,
        "payee_raw": payee,
        "amount": amount,
        "memo": memo,
        "suggested": match["classify"] if match else None,
    })

# 3. SHOW THE USER the pending items + suggestions in a table format.
#    For items WITHOUT a matching rule, mark them as "needs review".
#    Wait for explicit approval batch ("approve all", "approve these 5", etc.)

# 4. For each approved item, dry-run create_check + match to bank-feed item.
#    NEVER skip the dry-run. Compound write — two qbXML calls:
#    a) create_check (the new register entry)
#    b) OnlineBankingTransactionMatchAdd (link the feed item to the new check)
```

## Pattern: dry-run a batch before executing

```python
def dryrun_batch(client, approved):
    """Show what would happen for an approved batch without writing anything."""
    drills = []
    for item in approved:
        amt = -item["amount"]  # outflow shows as positive in check Amount field
        args = {
            "accountRef":     {"fullName": item["bank_account"]},  # e.g. "1011 - Amex Card"
            "payeeEntityRef": {"fullName": item["suggested"]["payee_entity"]},
            "refNumber":      "DEBIT",
            "txnDate":        item["date"],
            "memo":           item["memo"],
            "expenseLines": [{
                "accountRef": {"fullName": item["suggested"]["expense_account"]},
                "amount":     amt,
                "memo":       item["memo"],
                "classRef":   {"fullName": item["suggested"]["class"]},
            }],
        }
        drill = client.dryrun("create_check", args)
        drills.append({"item": item, "args": args, "drill": drill})
    return drills

# Show the drills as a clean table, with per-row approval.
# Only AFTER human confirms each row OR an "approve all": execute.
```

## Pattern: execute one approved item

```python
def execute_one(client, item):
    """Create the check AND match it to the bank-feed item."""
    # Step A: create the check
    check_result = client.op("create_check", item["args"])
    new_check_txn_id = check_result["rows"][0]["TxnID"]

    # Step B: match the new check to the bank-feed item
    match_xml = f'''<?xml version="1.0"?>
    <?qbxml version="16.0"?>
    <QBXML><QBXMLMsgsRq onError="stopOnError">
      <OnlineBankingTransactionMatchAddRq>
        <OnlineBankingTransactionMatchAdd>
          <OnlineBankingTransactionRef>
            <TxnID>{item["obt_id"]}</TxnID>
          </OnlineBankingTransactionRef>
          <MatchedTransactionRef>
            <TxnID>{new_check_txn_id}</TxnID>
          </MatchedTransactionRef>
        </OnlineBankingTransactionMatchAdd>
      </OnlineBankingTransactionMatchAddRq>
    </QBXMLMsgsRq></QBXML>'''
    client.qbxml(match_xml)
    return new_check_txn_id
```

## Safety rules

1. **Every batch goes through dry-run first.** Never execute without showing the user the proposed account+class+amount for each item.
2. **Manual review required for**: items WITHOUT a rule match, items where amount > $500 (configurable threshold), items from new vendors not in your rule library.
3. **Class is REQUIRED on every line.** Items with no class assignment fall into "No Class" and break the margin analysis. If a rule doesn't include a class, treat it as needing manual review.
4. **One-shot mistakes are easy to fix; bulk mistakes are not.** When processing a large batch, do the first 5-10 manually, verify, then approve the rest.

## Rule library should be versioned

The rule library evolves as new vendors appear. Keep it in a source-controlled file (e.g. `quickbooks/clients/bank_feed_rules.py`) and update via PR — don't edit in-place. When a new vendor appears, the workflow should:
1. Flag it as "needs review"
2. Operator manually codes the first instance (which writes a check + matches via raw qbXML)
3. Operator adds a rule to the library
4. Next time the same payee appears, it's auto-coded

## Pointers

- Bank-feed read + match mechanics: [quickbooks-bank-feeds](../quickbooks-bank-feeds/SKILL.md)
- Account / class lookup to fill out the rule library: [quickbooks-accounts-items-classes](../quickbooks-accounts-items-classes/SKILL.md)
- Verifying class accuracy after a batch — run [quickbooks-class-margin-analysis](../quickbooks-class-margin-analysis/SKILL.md) periodically and look for class-allocation drift
- Full safe-write workflow: [quickbooks-accounting](../quickbooks-accounting/SKILL.md)
