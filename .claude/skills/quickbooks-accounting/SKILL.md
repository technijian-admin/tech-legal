---
name: quickbooks-accounting
description: Top-level navigator for the QuickBooks Desktop accounting integration. Routes the work to a focused sub-skill (invoices, bills, checks-and-payments, accounts-items-classes, reports, journal-entries, bank-feeds) and owns the canonical safe-write workflow + the full op catalog. Use when the user mentions QuickBooks, QbConnectService, accounting, P&L, AR, AP, invoices, bills, checks, or the Python client at quickbooks/clients/.
---

# QuickBooks Accounting (Navigator)

This is the umbrella skill. **For specific tasks, route to a focused sub-skill**:

### Transactional (CRUD) skills

| User wants to… | Use sub-skill |
|---|---|
| Create / list / modify customer invoices, manage AR | [quickbooks-invoices](../quickbooks-invoices/SKILL.md) |
| Enter / list vendor bills, manage AP | [quickbooks-bills](../quickbooks-bills/SKILL.md) |
| Write a check, record a wire/debit/EFT, record customer payment, apply payment to invoices | [quickbooks-checks-and-payments](../quickbooks-checks-and-payments/SKILL.md) |
| Look up chart of accounts, items (with their tied accounts), or classes | [quickbooks-accounts-items-classes](../quickbooks-accounts-items-classes/SKILL.md) |
| Post a journal entry, reclassify between classes, accrue, depreciate | [quickbooks-journal-entries](../quickbooks-journal-entries/SKILL.md) |
| Read or match bank-feed downloads (raw qbXML mechanics) | [quickbooks-bank-feeds](../quickbooks-bank-feeds/SKILL.md) |
| Auto-categorize downloaded bank/ACH transactions to the right account + class | [quickbooks-bank-feed-classifier](../quickbooks-bank-feed-classifier/SKILL.md) |

### Workflow / operational skills

| User wants to… | Use sub-skill |
|---|---|
| Chase overdue AR, draft collection reminders, calculate DSO | [quickbooks-ar-collections](../quickbooks-ar-collections/SKILL.md) |
| Plan a bill-payment run, capture early-pay discounts, prioritize AP under cash constraint | [quickbooks-ap-management](../quickbooks-ap-management/SKILL.md) |
| Close the month/quarter/year (accruals, depreciation, reconciliation prep) | [quickbooks-period-close](../quickbooks-period-close/SKILL.md) |
| 1099 prep / vendor spend analysis / concentration risk | [quickbooks-vendor-spend-and-1099](../quickbooks-vendor-spend-and-1099/SKILL.md) |

### Analytical / reporting skills

| User wants to… | Use sub-skill |
|---|---|
| Pull P&L, Balance Sheet, A/R Aging, A/P Aging, by-class reports | [quickbooks-reports](../quickbooks-reports/SKILL.md) |
| Analyze gross margin by class / service line; flag classes under-margin | [quickbooks-class-margin-analysis](../quickbooks-class-margin-analysis/SKILL.md) |
| Per-customer P&L; which customers are profitable | [quickbooks-customer-profitability](../quickbooks-customer-profitability/SKILL.md) |
| Understand what items drive revenue per class; sales-by-item analysis | [quickbooks-item-revenue-analysis](../quickbooks-item-revenue-analysis/SKILL.md) |
| Check current cash position, working capital, AR/AP aging impact | [quickbooks-cash-flow](../quickbooks-cash-flow/SKILL.md) |
| Project cash, revenue, expenses 30/60/90 days forward | [quickbooks-forecasting](../quickbooks-forecasting/SKILL.md) |
| Compare actuals to budget, flag variances | [quickbooks-budget-vs-actual](../quickbooks-budget-vs-actual/SKILL.md) |

### Autonomous agent

For unattended / scheduled accounting work, see the **qb-accountant** agent in `.claude/agents/qb-accountant.md` and the scheduled-task harness under `quickbooks/agent/`. The agent uses all the skills above and runs daily/weekly/monthly routines.

Common scaffolding (multi-tenant, safe-write workflow, op catalog, raw-qbXML fallback) lives here in this top-level skill.

## Multi-tenant

The QbConnectService serves multiple `.QBW` company files on the same QuickBooks host. Every API call picks a company via the `?company=<key>` query param (or `X-Qb-Company` header). The Python client honors a `default_company` and per-call `company=` override.

| Company key | .QBW path | Authorization status (as of 2026-05-19) |
|---|---|---|
| `technijian` (DEFAULT) | `D:\Quickbooks\technijian.qbw` | ✅ Authorized — full unattended access (signs in as `jian` QB user) |
| `electronic-corporation-of-america` | `D:\Quickbooks\Electronic Corporation of America.qbw` | ✅ Authorized — full unattended access (signs in as `jian` QB user) |
| `technijian-pvt-ltd` | `D:\Quickbooks\Technijian PVT Ltd..qbw` | ⏳ Configured but not yet integrated-app-authorized |
| `kutumba-holdings-llc` | `D:\Quickbooks\Kutumba Holdings LLC.qbw` | ⏳ Configured but not yet integrated-app-authorized |

Calls against unauthorized companies will return `0x80040408 QB_COULD_NOT_START`.

### Cross-company switching is now transparent (since 2026-05-19)

QuickBooks Desktop is hard-locked to one company file at a time per machine (Intuit QB SDK 16.0 Programmer's Guide, p.53), but the service handles the switch automatically. Just pass `?company=<key>` and the service:

1. Detects that QBW.EXE has the wrong file open (`0x8004040A` or `0x80010105`).
2. Kills QBW.EXE (refuses only if a human is interactively using QB Desktop on the server console).
3. Cold-starts a fresh QB Desktop on the requested file (~30-40s on the switch).
4. Retries the request and returns the data.

So a call sequence like this just works without manual intervention:

```text
POST /api/ops/list_customers                                              # technijian (default)
POST /api/ops/list_customers?company=electronic-corporation-of-america    # auto-switch, ~30-40s
POST /api/ops/list_invoices?company=electronic-corporation-of-america     # fast, same company
POST /api/ops/list_customers?company=technijian                            # auto-switch back
```

If an interactive QB Desktop session is detected, the switch returns `409 Conflict` with a clean remediation hint. Use `POST /api/connection/restart-qb` to force the kill manually (see "Connection lifecycle" below).

## When to use this top-level skill

- Generic QuickBooks / accounting questions that don't fit a specific sub-skill
- The full safe-write workflow (the steps below)
- Looking up the v1 op catalog
- The raw-qbXML fallback envelope

## Quick start

1. Install the client deps once:
   `pip install -r quickbooks/clients/requirements.txt`
2. Copy the sample env file:
   `cp quickbooks/clients/.env.sample quickbooks/clients/.env`
3. Fill in `QB_API_BASE_URL`, `QB_API_TOKEN`, and optionally `QB_DEFAULT_COMPANY=technijian`.
4. Ensure the QbConnectService scheduled task is running on the host (10.120.254.13).
5. Always start with `client.health()` and confirm:
   - `status == "healthy"`
   - `connectionState == "SessionOpen"` (or be ready to wait for cold-start QB launch)
   - `allowWrites` before considering any write

If the dev cert is self-signed, set `QB_VERIFY_TLS=false` or point at a CA
bundle / `.cer`. (On the QB server itself the cert is already trusted in
`Cert:\LocalMachine\Root`.)

## Invocation patterns

### Canned operations

Run an example from `quickbooks/clients/`:

```bash
cd quickbooks/clients && python examples/pull_pnl.py
cd quickbooks/clients && python examples/list_invoices.py
cd quickbooks/clients && python examples/create_customer_dryrun.py
```

### Ad-hoc client usage

Run a small inline script from `quickbooks/clients/`:

```bash
cd quickbooks/clients && python -c "
from qb_client import QbClient
client = QbClient.from_env()    # picks up QB_DEFAULT_COMPANY if set
print(client.health())
print(client.op('list_customers', {'activeStatus': 'Active', 'name': 'Acme'}))
"
```

The client surface (with multi-tenant `company` support):

- `client.health()`
- `client.ops()`
- `client.op(name, args_dict, company=None)`
- `client.dryrun(name, args_dict, company=None)`
- `client.qbxml(raw_xml_string, company=None)`
- `client.with_company(key)` — returns a shallow clone scoped to that company

Each method's `company=` is optional. If omitted, the client uses
`default_company` (from `QB_DEFAULT_COMPANY` env var, default `technijian`).

Errors raise `QbApiError` with `.status_code`, `.title`, `.detail`, and
`.qb_error_code`.

## Operation catalog

Arg shapes here are accurate as of Phase 8. The authoritative source is
`quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/*.cs`.
Read ops are never write-gated. Write ops are dry-run-gated and return `403`
when `Safety:AllowWrites=false` on the service; they refuse `currencyRef` and
`exchangeRate` up front. A non-zero qbXML `statusCode` is a business outcome
that rides inside `result.status` - it is not an HTTP error.

### Read ops

| Op | Args | Returns (`result`) | Notes |
|----|------|--------------------|-------|
| `company_info` | (none) | `{ ...company name, address, fiscalYearStart, edition (from HostRet.ProductName)... }` | One round-trip combining Host + Company. |
| `get_company_preferences` | (none) | `{ status, salesTaxEnabled, defaultItemSalesTaxRef, multiCurrencyEnabled, homeCurrencyRef, decimalPlaces, classTrackingOn, requireAccounts, useAccountNumbers, defaultDiscountAccountRef, defaultArAccount, defaultArAccountSource:"AccountQuery", defaultApAccount, defaultApAccountSource:"AccountQuery", rawPreferencesRet }` | Some field names (`IsMultiCurrencyOn`, `IsUsingClassTracking`, `decimalPlaces` source) are Phase-9 re-pin candidates and may shift on the live host. |
| `report` | `{ type: ProfitAndLoss|BalanceSheet|AgingAR|AgingAP, fromDate?, toDate?, dateMacro? }` - supply exactly one of (`fromDate` + `toDate`) or `dateMacro` | `{ type, report: <ParsedReport: ColDesc-driven rows> }` | P&L and BalanceSheet use `GeneralSummaryReportQueryRq`; AgingAR and AgingAP use `AgingReportQueryRq`. |
| `list_customers` | `{ activeStatus?: Active|Inactive|All (default All), name?: <substring>, nameMatch?: Contains|StartsWith|EndsWith (default Contains) }` | `{ status, rows: [...], count, rawSpilledTo }` | Iterator-driven through `QbListExecutor`. |
| `list_vendors` | same as `list_customers` | `{ status, rows, count, rawSpilledTo }` | - |
| `list_accounts` | `{ activeStatus?, name?, nameMatch? }` | `{ status, rows, count, rawSpilledTo }` | - |
| `list_items` | `{ activeStatus?, name?, nameMatch? }` | `{ status, rows, count, rawSpilledTo }` | Item polymorphism is normalized by the parser with a `type` field on each row. |
| `list_invoices` | `{ fromDate?, toDate?, dateMacro?, entity?, includeLineItems?: bool }` - `dateMacro` is mutually exclusive with `fromDate` and `toDate` | `{ status, rows, count, rawSpilledTo }` | Header rows by default; `includeLineItems:true` opts into line detail. `IncludeLineItems` is a Phase-9 re-pin candidate. |
| `list_bills` | `{ fromDate?, toDate?, dateMacro?, entity? }` | `{ status, rows, count, rawSpilledTo }` | - |
| `list_payments` | `{ fromDate?, toDate?, dateMacro?, entity? }` | `{ status, rows, count, rawSpilledTo }` | - |
| `get_transaction` | `{ txnId? | refNumber? }` - exactly one; optional `txnType?` | `{ status, matches: [...], count, ambiguous: bool, lite: true }` | `RefNumber` is non-unique, so this always returns a list. |
| `run_query` | `{ entity: <one of the read-only whitelist>, filters?: { <simple child-element key>: value | [values] | {nested} } }` | `{ entity, status, rows, count, rawSpilledTo }` | Whitelist in source includes Employee, OtherName, SalesRep, Class, Term, PriceLevel, PaymentMethod, ShipMethod, Currency, SalesTaxCode, Vehicle, SalesReceipt, Estimate, PurchaseOrder, CreditMemo, SalesOrder, Deposit, Check, BillPaymentCheck, BillPaymentCreditCard, CreditCardCharge, CreditCardCredit, JournalEntry, InventoryAdjustment, TimeTracking, VendorCredit, ItemReceipt, Customer, Vendor, Item, Account, Invoice, Bill, ReceivePayment, Transaction, ToDo, Company, Host, Preferences. Prefer dedicated ops where one exists. |

### Write ops

| Op | Args (header-level unless noted) | Notes |
|----|----------------------------------|-------|
| `create_customer` | `name` (required), `isActive?`, `parentRef?` (`{listID?|fullName?}`), `companyName?`, `salutation?`, `firstName?`, `middleName?`, `lastName?`, `suffix?`, `billAddress?` (dict), `shipAddress?`, `printAs?`, `phone?`, `mobile?`, `pager?`, `altPhone?`, `fax?`, `email?`, plus more pass-through fields | Maps to `CustomerAdd`. Refs accept `{listID}` or `{fullName}`. |
| `create_vendor` | `name` (required), `isActive?`, `companyName?`, `salutation?`, `firstName?`, `middleName?`, `lastName?`, `suffix?`, `vendorAddress?` (dict), `phone?`, `mobile?`, `pager?`, `altPhone?`, `fax?`, `email?`, `contact?`, `altContact?`, `nameOnCheck?`, `accountNumber?`, `notes?`, `vendorTypeRef?`, `terms?` (`{listID?|fullName?}`) | Maps to `VendorAdd`. |
| `create_invoice` | `customerRef` (required, `{listID?|fullName?}`), `lines` (required, list of line dicts), `classRef?`, `arAccountRef?`, `templateRef?`, `txnDate?`, `refNumber?`, `billAddress?`, `shipAddress?`, `isPending?`, `poNumber?`, `terms?`, `dueDate?`, `salesRepRef?`, `fob?`, `shipDate?`, `shipMethodRef?`, `itemSalesTaxRef?`, `memo?`, `customerMsgRef?`, `isToBePrinted?`, `isToBeEmailed?`, `isTaxIncluded?`, `customerSalesTaxCodeRef?`, `other?` | Maps to `InvoiceAdd` plus `InvoiceLineAdd`s. Line shape is summarized; see `CreateInvoiceOp.cs` and `WriteOpHelpers.cs`. |
| `create_bill` | `vendorRef` (required), `apAccountRef?`, `txnDate?`, `dueDate?`, `refNumber?`, `terms?`, `memo?`, `isTaxIncluded?`, `salesTaxCodeRef?`, `expenseLines?` (list), `itemLines?` (list) - at least one line list | Maps to `BillAdd` with `ExpenseLineAdd` and `ItemLineAdd`s. See `CreateBillOp.cs` for the exact nested line shapes. |
| `create_check` | `accountRef` (required, bank account), `payeeEntityRef?`, `refNumber?`, `txnDate?`, `memo?`, `address?` (dict), `isToBePrinted?`, `isTaxIncluded?`, `salesTaxCodeRef?`, `expenseLines?` (list), `itemLines?` (list) | Maps to `CheckAdd`. See `CreateCheckOp.cs` and `WriteOpHelpers.cs` for nested line shapes. |
| `receive_payment` | `customerRef` (required), `arAccountRef?`, `txnDate?`, `refNumber?`, `totalAmount?`, `paymentMethodRef?`, `memo?`, `depositToAccountRef?`, `isAutoApply?` (bool) or `appliedTo?` (list of `{txnID, paymentAmount}`) | Maps to `ReceivePaymentAdd`. Pre-flight checks `appliedTo` totals versus `totalAmount` when not auto-applying. |
| `create_journal_entry` | `debits` (required, list of `{accountRef, amount, memo?, entityRef?, classRef?}`-ish), `credits` (required, same shape), `txnDate?`, `refNumber?`, `memo?`, `isAdjustment?` | Maps to `JournalEntryAdd`. Rejected at pre-flight if debits do not equal credits. See `CreateJournalEntryOp.cs` for the exact line shape. |
| `mod` | `entity` (required: `customer|vendor|invoice|bill|check`), `ref` (required, `{txnID?|listID?|fullName?}`), `fields` (required, dict of header-level fields to set with full-replace semantics on the header) | One generic op, not `mod_customer` / `mod_vendor`. `mod` is header-level only in v1; see `ModOp.cs` for the exact `fields` keys per entity. A stale `EditSequence` returns `statusCode=3200` in `result.status`, audited once, never retried. |

## Safe-write workflow

The safe-write rule is hard: never execute a write until the dry-run has been
shown to the user and the user has explicitly confirmed it.

```text
A write op is NEVER executed without first completing steps 1-4.

1. DRY RUN. Call client.dryrun(opName, args). It returns
   { qbXml, summary, preFlight: [{name, ok, detail}], resolvedReferences, allowWrites }
   with ZERO side effects (it works even when AllowWrites is false).
2. SHOW THE USER:
   - the qbXml (byte-exact - the request that would be sent),
   - the plain-English summary,
   - each preFlight check and whether it passed (ok),
   - whether allowWrites is true (if false, the execute in step 4 will 403 - the
     operator must deliberately set Safety:AllowWrites=true on the service first).
3. GET EXPLICIT CONFIRMATION. The user must say, in effect, "yes, execute this."
   No silent auto-apply, ever. If a preFlight check failed, do not proceed - fix
   the args and dry-run again.
4. EXECUTE. Only now call client.op(opName, args). It returns { ...result... } with
   the embedded status (statusCode/statusSeverity/statusMessage). A 403 means
   AllowWrites is false on the service.
5. REPORT. Show the user the result, including the status, and note that the write
   was recorded in the audit log on the QuickBooks host.

For `mod`: the dry-run shows the before/after header-field diff and the EditSequence
it will use (fetched from a fresh read). If the execute comes back with statusCode 3200
(stale EditSequence, severity Error), surface it verbatim - do NOT auto-retry. The user
does a fresh dry-run (which re-reads the current EditSequence) and confirms again.

For destructive operations (Delete/Void): there is no wrapped op. Use raw qbXML via
client.qbxml("<...>") with the user's explicit confirmation, and only with
AllowWrites=true.
```

## Raw-qbXML fallback

When no wrapped op fits, use `client.qbxml(raw_xml_string)` and build the request
carefully. See `references/qbxml-cheatsheet.md` for the envelope, common
request shapes, iterators, and status handling. A raw qbXML write is still
gated by `AllowWrites` and still needs explicit user confirmation first.

## Connection lifecycle (since 2026-05-19)

Three behaviors make multi-company unattended access "just work" — all on by default in `appsettings.json` `Qb` section. Full details in `quickbooks/QbConnectService/README.md` and the topic page `quickbooks_direct_sdk_integration` in the vault.

| Setting | Default | Effect |
|---|---|---|
| `Qb:ReleaseAfterEachRequest` | `true` | SDK ticket released after each call so the `.qbw` is free between requests. ~500ms-1s reconnect cost on the next call. |
| `Qb:AutoRecoverFromQbwStuck` | `true` | Catches `0x8004040A` / `0x80040414` / `0x80010105` and kills QBW.EXE + retries once. Lets cross-company switches work transparently. |
| `Qb:AbortRecoveryIfInteractiveQbDesktop` | `true` | Safety guard - won't kill QBW if a human is using QB Desktop interactively. Returns 409. |
| `Qb:MaxQbwKillsPerMinute` | `3` | Circuit breaker against kill-loops. Beyond the cap, auto-recovery refuses (503) and asks for manual intervention. |
| `Qb:QbwKillExitTimeoutSeconds` | `10` | How long to wait for QBW.EXE to exit after Kill() before proceeding to the retry. |

### Explicit connection-management endpoints

| Endpoint | Purpose |
|---|---|
| `POST /api/connection/release` | Drop the SDK ticket only. QBW.EXE stays running. Idempotent. Use to free the file for QB Desktop without killing QB. |
| `POST /api/connection/restart-qb` | Drop ticket AND kill all QBW.EXE. Idempotent. Returns pre/post snapshot of process counts. Use to force a clean cold-start when an interactive session has blocked auto-recovery. |

### `/api/health` diagnostic fields

`/api/health` exposes the lifecycle state - use `lastProbe = "ok"` as the load-bearing health signal, NOT `connectionState` (which is normally `Disconnected` immediately after auto-release):

```json
{
  "status": "healthy",
  "lastProbe": "ok",
  "connectionState": "Disconnected",
  "releaseAfterEachRequest": true,
  "autoRecoverFromQbwStuck": true,
  "qbwProcesses": 1,
  "qbwInteractiveSession": false,
  "recentQbwKills": 0,
  "maxQbwKillsPerMinute": 3,
  "openMode": "MultiUser",
  "openModeInt": 1,
  ...
}
```

### Authoritative SDK constraint

The "must kill QBW.EXE to switch files" design isn't ours - it's dictated by Intuit. From the QB SDK 16.0 Programmer's Guide (page 53, "Limitations on Accessing Company Files"):

> Only one company file at a time can be accessed by integrated applications on any given machine running QuickBooks.

The SDK has no "switch file" API. The escape hatch is to terminate QBW.EXE and let the next BeginSession cold-launch a fresh QB Desktop on the new file. The full PDF lives at `C:\Program Files\Intuit\IDN\QBSDK16.0\doc\pdf\QBSDK_ProGuide.pdf` on the server.

## Pointers

### Focused sub-skills — transactional / CRUD (7)

- [quickbooks-invoices](../quickbooks-invoices/SKILL.md) — AR invoices
- [quickbooks-bills](../quickbooks-bills/SKILL.md) — AP bills
- [quickbooks-checks-and-payments](../quickbooks-checks-and-payments/SKILL.md) — direct checks + receive_payment
- [quickbooks-accounts-items-classes](../quickbooks-accounts-items-classes/SKILL.md) — CoA, items, classes lookup
- [quickbooks-journal-entries](../quickbooks-journal-entries/SKILL.md) — GL JEs
- [quickbooks-bank-feeds](../quickbooks-bank-feeds/SKILL.md) — bank-feed download mechanics (raw-qbXML)
- [quickbooks-bank-feed-classifier](../quickbooks-bank-feed-classifier/SKILL.md) — auto-categorization rules

### Focused sub-skills — workflow / operational (4)

- [quickbooks-ar-collections](../quickbooks-ar-collections/SKILL.md) — overdue AR follow-up
- [quickbooks-ap-management](../quickbooks-ap-management/SKILL.md) — strategic bill paying
- [quickbooks-period-close](../quickbooks-period-close/SKILL.md) — month/quarter/year close
- [quickbooks-vendor-spend-and-1099](../quickbooks-vendor-spend-and-1099/SKILL.md) — vendor analysis + tax prep

### Focused sub-skills — analytical / reporting (6)

- [quickbooks-reports](../quickbooks-reports/SKILL.md) — P&L, BS, aging, by-class
- [quickbooks-class-margin-analysis](../quickbooks-class-margin-analysis/SKILL.md) — gross margin by service line
- [quickbooks-customer-profitability](../quickbooks-customer-profitability/SKILL.md) — per-customer P&L
- [quickbooks-item-revenue-analysis](../quickbooks-item-revenue-analysis/SKILL.md) — items → revenue → class
- [quickbooks-cash-flow](../quickbooks-cash-flow/SKILL.md) — current cash position + working capital
- [quickbooks-forecasting](../quickbooks-forecasting/SKILL.md) — forward projections
- [quickbooks-budget-vs-actual](../quickbooks-budget-vs-actual/SKILL.md) — budget variance

### Autonomous agent

- `.claude/agents/qb-accountant.md` — the agent persona
- `quickbooks/agent/` — scheduled-task harness + state directory + README

### References

- `references/qbxml-cheatsheet.md`
  Raw qbXML envelope, common Query/Add/Mod/Delete/Void shapes, iterators, and
  the `3200` stale-`EditSequence` rule.
- `references/setup-and-troubleshooting.md`
  Health/auth/write-gate/TLS/busy/timeout failure modes.
- `quickbooks/clients/README.md`
  Local setup and example usage for the Python client.
- `quickbooks/dev/MULTI-LLM.md`
  The documented build and review pipeline used for this subsystem.

### Operational pointers (not in repo)

- Bearer token + per-company AppName/AppId — `D:\QbConnectService\INSTALL-RESULT.txt` on the QB host.
- DPAPI cred file for remote PSRemoting from rjain's workstation — `C:\Users\rjain\.qb-server-cred.xml`.
- Full host credentials + drives + scheduled task setup — `C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\te-hq-app-qb.md`.
