---
name: quickbooks-bank-feeds
description: Read/import QuickBooks Bank Feeds (Online Banking) transactions through QbConnectService, and match downloaded transactions to existing checks/deposits. Use when the user asks about bank feeds, downloading transactions from a bank, reconciling, or matching online-banking activity. NOTE — this is currently a documented gap in the service (no wrapped ops yet); the workaround uses raw qbXML.
---

# QuickBooks Bank Feeds (Online Banking)

⚠️ **Current state: GAP. The v1 op catalog does not include any bank-feed ops.** To work with bank feeds today you use raw qbXML via `client.qbxml(...)`. This skill documents:

1. What bank feeds are in QuickBooks Desktop and the SDK
2. The raw qbXML to read downloaded transactions
3. How to match feed items to existing QB transactions
4. What's missing and how to add it as a proper wrapped op

## Multi-tenant

`company=` or `QB_DEFAULT_COMPANY`. Default `technijian`. Authorized: `technijian`, `electronic-corporation-of-america`.

## Background

QuickBooks Desktop has two modes for bringing in bank/credit-card transactions:

- **Express Mode** (the modern UI) — QB Desktop talks to the bank's OFX endpoint, downloads transactions, presents a matching UI, and stages them as `OnlineBankingTransaction` records until accepted into the register.
- **Classic Mode** (older) — QFX/QBO file import; one-shot.

The SDK exposes only **Express Mode** records via `OnlineBankingTransaction` qbXML entities. The download itself happens via QB Desktop's UI; the SDK can READ what's been downloaded and what's been accepted.

## Reading downloaded transactions

The QB SDK schema is `OnlineBankingTransactionQueryRq`. Raw qbXML:

```python
from qb_client import QbClient
client = QbClient.from_env().with_company("technijian")

xml = '''<?xml version="1.0"?>
<?qbxml version="16.0"?>
<QBXML><QBXMLMsgsRq onError="stopOnError">
  <OnlineBankingTransactionQueryRq>
    <MaxReturned>500</MaxReturned>
    <!-- Optional: filter by account -->
    <!-- <AccountFilter><ListID>...</ListID></AccountFilter> -->
    <!-- Optional: filter by status. PendingMatch | PendingAdd | InRegister -->
    <!-- <Status>PendingMatch</Status> -->
  </OnlineBankingTransactionQueryRq>
</QBXMLMsgsRq></QBXML>'''

response_xml = client.qbxml(xml)
# Parse with xml.etree.ElementTree
```

Each downloaded transaction has:

| Field | Meaning |
|---|---|
| `TxnID` | The OnlineBankingTransaction's TxnID |
| `AccountRef` | The QB bank/credit-card account |
| `TxnDate` | Bank's posting date |
| `Amount` | Positive (credit / inflow) or negative (debit / outflow) |
| `PayeeName` | Bank-supplied payee text (often garbage — "WALMART #1234 ANAHEIM CA") |
| `Memo` | Bank's free-form memo |
| `TxnReferenceNumber` | Bank's reference (check number, transaction ID) |
| `Status` | `PendingMatch` (downloaded, not matched yet), `PendingAdd` (auto-suggested as new), or `InRegister` (already accepted into the register and tied to a QB transaction) |
| `MatchedTransactionRef` | If `Status=InRegister`, this points at the QB transaction (Check/Deposit/etc.) it was matched to |

### List pending downloads (most common task)

```python
xml = '''<?xml version="1.0"?>
<?qbxml version="16.0"?>
<QBXML><QBXMLMsgsRq onError="stopOnError">
  <OnlineBankingTransactionQueryRq>
    <MaxReturned>500</MaxReturned>
    <Status>PendingMatch</Status>
  </OnlineBankingTransactionQueryRq>
</QBXMLMsgsRq></QBXML>'''
```

Returns everything that's been downloaded but not yet accepted into the register. The pile that needs human review.

### Pull by date range

Wrap with date filter:

```xml
<OnlineBankingTransactionQueryRq>
  <ModifiedDateRangeFilter>
    <FromModifiedDate>2026-05-01T00:00:00</FromModifiedDate>
    <ToModifiedDate>2026-05-19T23:59:59</ToModifiedDate>
  </ModifiedDateRangeFilter>
</OnlineBankingTransactionQueryRq>
```

## Matching feed items to existing QB transactions

When QB downloads "PG&E $245.10 on 5/18", and you already have a Check #12345 to PG&E for $245.10 on 5/18 in the register, you'd "Match" them. The SDK exposes the match action:

```xml
<?xml version="1.0"?>
<?qbxml version="16.0"?>
<QBXML><QBXMLMsgsRq onError="stopOnError">
  <OnlineBankingTransactionMatchAddRq>
    <OnlineBankingTransactionMatchAdd>
      <OnlineBankingTransactionRef>
        <TxnID>OBT-12345...</TxnID>
      </OnlineBankingTransactionRef>
      <MatchedTransactionRef>
        <TxnID>CHECK-67890...</TxnID>
      </MatchedTransactionRef>
    </OnlineBankingTransactionMatchAdd>
  </OnlineBankingTransactionMatchAddRq>
</QBXMLMsgsRq></QBXML>
```

This is a WRITE — gated by `Safety:AllowWrites=true` and the dry-run rule still applies. See [quickbooks-accounting](../quickbooks-accounting/SKILL.md) for the safe-write workflow.

## Accepting a feed item as a new transaction

For downloaded transactions that DON'T match an existing record, you "Add" them as new — usually as a check or deposit. The SDK doesn't have a single `OnlineBankingTransactionAcceptRq` — instead you:

1. Read the downloaded transaction's fields (amount, date, payee, memo)
2. Create a new `Check` or `Deposit` via `create_check` or raw qbXML `DepositAdd`
3. Optionally call `OnlineBankingTransactionMatchAddRq` to link the new transaction back to the feed item (so it shows as matched, not duplicated)

A common pattern: the user wants Claude to auto-categorize downloaded items. Workflow:

1. Pull pending downloads via `OnlineBankingTransactionQueryRq` with `Status=PendingMatch`
2. For each item, suggest an account based on `PayeeName` + `Memo` heuristics:
   - "PG&E" → `6080 - Office General:6080.09 - Utilities`
   - "AT&T" → `6080 - Office General:6080.13 - Internet`
   - "STAPLES" / "OFFICE DEPOT" → `6080 - Office General:6080.06 - Supplies`
   - etc.
3. Show the user the suggestions for batch approval
4. For each approved: create a Check (or Deposit if amount > 0) AND match it to the feed item

This is a real opportunity to wrap as a custom op (see "Adding a wrapped op" below) but the raw-qbXML path works today.

## What's missing — proposed v2 op extensions

For this skill to become a first-class wrapped op (in `QbConnectService`), the team would add:

| Op | What it does | Layer |
|---|---|---|
| `list_pending_bank_feeds` | Wraps `OnlineBankingTransactionQueryRq` with the same date/status filter pattern as other list ops | Read |
| `match_bank_feed` | Wraps `OnlineBankingTransactionMatchAddRq` | Write (dry-run, AllowWrites-gated) |
| `accept_bank_feed_as_check` | Combines `CheckAdd` + match in one transaction. Args mirror `create_check` but include `feedTxnId` | Write (compound) |
| `accept_bank_feed_as_deposit` | Same for `DepositAdd` | Write (compound) |

If you need these and want to add them, the pattern to follow is:

1. Add an op class in `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/`
2. Register as `IReadOp` in `Program.cs`
3. Update `OpRegistry` doesn't need changes (auto-discovered)
4. Add tests in `quickbooks/QbConnectService/src/QbConnectService.Tests/`
5. Run the SDLC plan/execute loop, get to 100% test coverage, merge

For now, use the raw-qbXML approach.

## What QB Desktop UI does that the SDK doesn't

- **Initiating the actual download from the bank.** The OFX connection setup happens in QB Desktop. The SDK can only read what's been downloaded. To trigger a download, someone has to open QB Desktop, go to Banking → Bank Feeds → Bank Feeds Center → click the Download button. Plan for periodic human (or automated UI) triggers.
- **Bank-feed rules / auto-categorization.** QB has built-in rules ("anytime payee is PG&E, code to Utilities"). These rules apply when downloading; the SDK can see the resulting accepted transactions but doesn't expose the rules themselves for read/write.

## Patterns the user is likely to ask for

- **"Show me what's pending review in bank feeds"** → raw qbXML query with `Status=PendingMatch`
- **"Auto-categorize the bank downloads"** → loop pending, suggest account from payee heuristics, write checks + match
- **"Reconcile last month's bank statement"** → not via the SDK directly — that's a UI-only process. The closest you can do is query `Check` + `Deposit` + `BillPaymentCheck` for the month and compare to the bank's statement file.
- **"Was check #12345 cleared by the bank?"** → query OnlineBankingTransaction for the matching amount/date/refnumber, and check if it's `InRegister` and matched

## Limitations summary

- **Read:** Mostly works via raw qbXML; needs wrapped op for ergonomics
- **Match:** Works via raw qbXML
- **Accept as check/deposit:** Works but requires two qbXML calls (create + match)
- **Trigger download from bank:** Not available via SDK — QB Desktop UI only
- **Bank rules management:** Not available via SDK

## Pointers

- Raw qbXML envelope basics: [quickbooks-accounting](../quickbooks-accounting/SKILL.md) → references/qbxml-cheatsheet.md
- Writing checks (the typical "accept as new" output): [quickbooks-checks-and-payments](../quickbooks-checks-and-payments/SKILL.md)
- Chart of accounts for picking the right GL account: [quickbooks-accounts-items-classes](../quickbooks-accounts-items-classes/SKILL.md)
