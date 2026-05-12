---
name: quickbooks-accounting
description: Drive the QuickBooks Desktop accounting integration: pull reports and lists (P&L, balance sheet, invoices, bills, customers, vendors, accounts, items), look up transactions, run safe read queries, and perform write operations (create customer/vendor/invoice/bill/check, receive payment, journal entry, modify a record) through the dry-run-and-confirm workflow. Use when the user mentions QuickBooks, QbConnectService, pulling the P&L, listing invoices, creating an invoice or customer in QuickBooks, or the quickbooks/clients Python client.
---

# QuickBooks Accounting

## When to use

Use this skill when the task is to read or write accounting data through the
QuickBooks Desktop `QbConnectService` integration.

Typical triggers:

- Pull a Profit & Loss or Balance Sheet
- List invoices, bills, customers, vendors, items, or accounts
- Look up a transaction by `TxnID` or `RefNumber`
- Run a safe ad-hoc query through `run_query`
- Create or modify a QuickBooks object through the dry-run workflow
- Send raw qbXML because no wrapped op fits

## Quick start

1. Install the client deps once:
   `pip install -r quickbooks/clients/requirements.txt`
2. Copy the sample env file:
   `cp quickbooks/clients/.env.sample quickbooks/clients/.env`
3. Fill in `QB_API_BASE_URL` and `QB_API_TOKEN`.
4. Ensure the QuickBooks-side service is running on the host.
5. Always start with `c.health()` and confirm:
   - `status == "healthy"`
   - `connectionState` is usable
   - `allowWrites` before considering any write

If the dev cert is self-signed, set `QB_VERIFY_TLS=false` or point it at a CA
bundle / `.cer`.

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
client = QbClient.from_env()
print(client.health())
print(client.op('list_customers', {'activeStatus': 'Active', 'name': 'Acme'}))
"
```

The client surface is:

- `client.health()`
- `client.ops()`
- `client.op(name, args_dict)`
- `client.dryrun(name, args_dict)`
- `client.qbxml(raw_xml_string)`

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

## Pointers

- `references/qbxml-cheatsheet.md`
  Raw qbXML envelope, common Query/Add/Mod/Delete/Void shapes, iterators, and
  the `3200` stale-`EditSequence` rule.
- `references/setup-and-troubleshooting.md`
  Health/auth/write-gate/TLS/busy/timeout failure modes. Deploy scripts and
  host runbooks arrive in Phase 9.
- `quickbooks/clients/README.md`
  Local setup and example usage for the Python client.
- `quickbooks/dev/MULTI-LLM.md`
  The documented build and review pipeline used for this subsystem.
