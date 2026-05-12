# Feature Research

**Domain:** qbXML-based QuickBooks Desktop / Enterprise integration service (COM `QBXMLRP2.RequestProcessor` wrapped behind a REST API for an AI agent)
**Researched:** 2026-05-11
**Confidence:** HIGH for qbXML mechanics and the table-stakes/anti-feature split (long-stable spec, multiple corroborating sources: Intuit OSR/SDK release notes, ConsoliBYTE wiki, Intuit Developer samples, productivecomputing FM Books Connector guide). MEDIUM on which *exact* report subtypes/ops competitor connectors expose (varies by product).

## Verdict on the v1 op catalog

The chosen catalog (`company_info`, `report`, `list_customers/vendors/items/accounts`, `list_invoices/bills/payments`, `get_transaction` reads; `create_customer/vendor/invoice/bill/check`, `receive_payment`, `create_journal_entry`, `mod_*` writes; plus `POST /api/qbxml` raw passthrough) is **a well-judged, conventional table-stakes set.** It maps almost exactly to what mature qbXML connectors (Webgility, Intuit's own sample apps, ConsoliBYTE's PHP library, ProductiveComputing FM Books Connector, jsgoupil/quickbooks-sync) expose for a "read reports + create transactions" use case.

**Recommendation: keep the catalog as-is for v1.** Two genuinely missing table-stakes items to consider adding (cheap, high value): a generic **`run_query` op** (pass `<XxxQuery>` element + filters, get parsed rows — covers entities you didn't wrap without forcing the agent to hand-write full qbXML) and **`get_company_preferences`** (sales-tax on/off, decimal places, multi-currency on/off — the agent needs these to build valid write requests). Everything else below is correctly deferred or out of scope.

## Feature Landscape

### Table Stakes (Users Expect These)

Features any qbXML connector for this use case is assumed to have. Missing these = the integration "doesn't really work."

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Connection + session lifecycle (`OpenConnection2` → `BeginSession` → `ProcessRequest` → `EndSession` → `CloseConnection`), serialized, single in-flight request | qbXML COM session is single-threaded; this is the entire substrate | MEDIUM | Spec covers it in `QbSession.cs`. Open-mode `DoNotCare` + auto-reconnect on dead ticket is correct. |
| `<?qbxml version="N.N"?>` processing instruction on every request, pinned in config | QuickBooks rejects requests with no/unsupported version PI; spec version gates which fields are legal | LOW | Spec pins `QbXml:Version`. **Quirk:** the version must be ≤ what the installed QB build supports; QB 2024/Enterprise 24 → spec 16.0; older builds cap lower. `HostQuery` returns supported versions — worth surfacing in `/api/health`. |
| `statusCode` / `statusSeverity` / `statusMessage` parsing on every response and per-request-element | A "200 OK" HTTP transport can still wrap a `statusCode != 0` qbXML failure; `Warn` severity ≠ `Error` | LOW–MEDIUM | Spec returns these verbatim. Make sure parser checks **both** the `<XxxRs>` element attributes **and** the outer `<QBXMLMsgsRs>` — and that "0 rows" (`statusCode=1` / "no matching") is not treated as an error. |
| `company_info` (`CompanyQuery`) | First call every integration makes; confirms the right company file is open | LOW | Already in catalog. |
| Report set: ProfitAndLoss, BalanceSheet, AgingAR (A/R Aging Summary), AgingAP (A/P Aging Summary) via `GeneralSummaryReportQueryRq` / `AgingReportQueryRq` | The four reports every accounting integration is asked for first | MEDIUM | In catalog. **Big quirk:** `ReportQuery` does **not** return typed rows. It returns `ReportTitle`, `ReportSubtitle`, `ColDesc` (column metadata), then nested `ReportData` → `DataRow` / `SubtotalRow` / `TextRow` / `TotalRow`, each with positional `ColData` (`colID` + `value`). Parser must reconstruct a table from `ColDesc` + positional cells, handle indentation/grouping rows, and not assume fixed columns. Report subtype enums differ (`ProfitAndLossStandard`, `BalanceSheetStandard`, `APAgingSummary`, `ARAgingSummary`). |
| Report date control: explicit `FromReportDate`/`ToReportDate` **or** a `ReportPeriod`/`ReportDateMacro` (`ThisMonth`, `ThisFiscalYear`, `Today`, `LastFiscalQuarter`, …) | Users say "P&L for last quarter," not ISO dates | LOW | In catalog ("date range or date macro"). Validate: macro and explicit range are mutually exclusive; aging reports use `ReportAgingAsOf` not a from/to range. |
| List queries: `CustomerQuery`, `VendorQuery`, `ItemQuery`, `AccountQuery` with active-only and name filters | The agent needs entity names/IDs to reference in writes | LOW–MEDIUM | In catalog. **Item is polymorphic** — `ItemQueryRs` returns `ItemServiceRet`, `ItemInventoryRet`, `ItemNonInventoryRet`, `ItemDiscountRet`, `ItemSalesTaxRet`, etc.; parser must normalize across subtypes. |
| Transaction queries: `InvoiceQuery`, `BillQuery`, `ReceivePaymentQuery` filtered by date range and/or entity | "Show me invoices for Acme in March" is the canonical agent ask | MEDIUM | In catalog as `list_invoices/bills/payments`. Each takes a `TxnDateRangeFilter` (or `ModifiedDateRangeFilter`) plus an `EntityFilter`. **Quirk:** include-line-items is opt-in (`IncludeLineItems`); a "lite" list query (header only) is faster and usually what you want for a list view. |
| `get_transaction` by `RefNumber` or `TxnID` (generic / by-ref lookup) | Drill-down after a list; `RefNumber` is human-facing, `TxnID` is the stable key | MEDIUM | In catalog. `RefNumber` is **not unique** (can repeat across years and is editable) — by-ref lookup may return >1 row; by `TxnID` is exact. A `TransactionQuery` (generic, all txn types) is a nice superset but per-type queries cover v1. |
| Iterator / pagination handling: `iterator="Start"` + `MaxReturned` on first call → response carries `iteratorID` + `iteratorRemainingCount` → `iterator="Continue"` with that `iteratorID` until remaining count hits 0 | Any list on a real company file (thousands of customers/invoices) blows up or truncates without it | MEDIUM | **Prerequisite for every list op** (see Dependencies). Quirks: `iteratorID` expires (next request after exhaustion errors); you cannot change filters mid-iteration; not all request types support iterators (most queries do, reports do not); only **one** iterator per request message. Decide whether the service auto-pages to completion (simpler for the agent, risk of huge responses → ties to the size-guard) or returns one page + the `iteratorID` (agent must loop). Spec's size-guard implies auto-page-then-truncate-to-file. |
| Write: `CustomerAdd`, `VendorAdd` | Onboarding a new payer/payee is step zero of any AP/AR workflow | LOW–MEDIUM | In catalog. |
| Write: `InvoiceAdd`, `BillAdd`, `CheckAdd` | Core AR/AP transaction creation | MEDIUM–HIGH | In catalog. Line items are the hard part: every line needs either an `ItemRef` (invoices/sales) or an `AccountRef` (bills/checks expense lines); amounts vs. qty×rate; `TxnLineID` must be `-1` for new lines on Add. |
| Write: `ReceivePaymentAdd` (and ideally `BillPaymentCheckAdd`) | Closing the AR loop — applying a customer payment to invoices | MEDIUM–HIGH | In catalog (`receive_payment`). Quirk: `AppliedToTxnAdd` blocks link the payment to specific invoices by `TxnID`; if you omit them QB auto-applies (or leaves a credit) — surface what happened. `BillPaymentCheckAdd` (paying vendor bills) is the AP mirror and is arguably also table stakes; v1 can lean on `CheckAdd` + raw qbXML. |
| Write: `JournalEntryAdd` | The escape hatch accountants reach for; needed for adjustments the typed ops can't express | MEDIUM | In catalog. Quirk: needs balanced `JournalDebitLine` / `JournalCreditLine` blocks; QB will reject if debits ≠ credits. |
| `*Mod` with `EditSequence` (optimistic concurrency) | Editing anything in QB requires reading the current `EditSequence` then sending it back; stale sequence → reject | MEDIUM | In catalog (`mod_*`). **Quirk to design for:** a Mod is a *full replacement* of the object, not a patch — you must echo back fields you want to keep. The agent flow should be: query the object → present current state → build the Mod from (current + changes) → dry-run → confirm → submit. Mod also returns a *new* `EditSequence`. |
| Raw qbXML passthrough (`POST /api/qbxml`) | No wrapped catalog covers everything; integrators always keep a raw door | LOW | In catalog. Keep it size-guarded and (per spec) write-gated when it contains `Add`/`Mod`/`Del`/`Void`. |
| Verbatim error surfacing + a known-code map (`0x8004xxxx` → message) | qbXML errors are cryptic hex; mapping the common ones (`0x80040420` waiting-for-permission, `0x80040401` can't-launch, `0x800404C5` stale EditSequence, `0x80040409` session-mode) is expected DX | LOW | Spec has `QbErrors.cs`. Never auto-retry/auto-fix validation errors — spec is right. |
| Health endpoint reporting company file, QB year/edition, SDK version, supported qbXML versions, `AllowWrites`, last error | First thing an operator hits to confirm the link is alive and what spec version is safe | LOW | In catalog (`GET /api/health`). Add the `HostQuery` "supported versions" list to it. |
| Dry-run / preview for writes (`POST /api/ops/{op}/dryrun`) — returns the exact qbXML it *would* send + a plain-English summary, executes nothing | This is the safety contract for letting an AI agent touch the books | LOW–MEDIUM | In catalog. See "What a good dry-run looks like" below. |

### Differentiators (Competitive Advantage)

Not expected of a generic connector, but valuable specifically because the consumer is an AI agent and the books are real.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Two-phase write workflow enforced *in the skill* (always dry-run → show qbXML + English summary → require explicit human confirm → submit), plus `Safety:AllowWrites=false` default + 403 | Makes "AI with write access to QuickBooks" defensible; most connectors have no such guardrail | LOW (it's policy + a flag, not code-heavy) | Already the design. This is the headline differentiator — keep it crisp. |
| Immutable per-write audit log (timestamp, op, args, qbXML sent, response status*, token id) | Auditability for an accounting system touched by automation; trivially answers "what did the bot do" | LOW–MEDIUM | In spec. |
| Plain-English summarizer for both reports (ColData→narrative) and write previews | A raw `ReportQuery` blob is useless to an agent's user; a summary ("Net income $X on revenue $Y, down 4% vs prior period") is the actual product | MEDIUM | The ColData/ColDesc reconstruction work pays off here. |
| Generic `run_query` op (entity name + filters → parsed rows) | Covers `EmployeeQuery`, `OtherNameQuery`, `SalesReceiptQuery`, `EstimateQuery`, `PurchaseOrderQuery`, `CreditMemoQuery`, `DepositQuery`, `ClassQuery`, etc. without 15 more wrapped ops or hand-written qbXML | MEDIUM | **Recommended for v1.** Big leverage; small surface. Reuses the iterator + parser machinery you already need. |
| `get_company_preferences` (`PreferencesQuery` / `CompanyQuery` prefs) — sales-tax enabled?, decimal places, multi-currency on?, default A/R & A/P accounts | The agent needs these to build *valid* write requests (e.g. whether to send `SalesTaxRef`, what `HomeCurrency` is) | LOW | **Recommended for v1.** Cheap, prevents a class of write failures. |
| Returning *both* parsed JSON and the raw qbXML response on every op | Lets the agent fall back to the raw XML when the parser missed a field; great for debugging | LOW | Already the design. |
| `OwnerID="0"` handling for custom fields (`DataExtRet` / `DataExtAdd`/`DataExtMod`) | Many real QB files carry workflow data in custom fields; without `OwnerID="0"` you get none of it back, and writing them needs `OwnerID="0"` + a defined `DataExtDefAdd` | MEDIUM | **Quirk to decide on, not necessarily build:** at minimum, *read* `DataExtRet` when present (it comes back if you pass `OwnerID=0` in the query — by default `OwnerID` is omitted and you get nothing). Writing custom fields is a v1.x candidate. |
| `IncludeRetElement` "lite" requests (ask QB to return only the fields you'll use) | Faster, smaller responses on big files; e.g. list customers returning just `ListID`/`Name`/`IsActive` | LOW | Worth wiring into list ops as an `lite=true` flag. |

### Anti-Features (Commonly Requested, Often Problematic)

Things that look like obvious next steps but are correctly out of scope for v1 — the spec's §10 list is right; here's why, with the alternative.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Payroll ops (`PayrollItemWageQuery`, paychecks, payroll liabilities) | "It's in QuickBooks, why not?" | Payroll qbXML is read-mostly, version-fragile, and payroll mistakes have legal/tax consequences far beyond a normal write; many editions don't expose it at all | Out of scope; if ever needed, read-only via raw qbXML + heavy human review |
| Inventory assemblies / build assemblies (`InventoryAdjustmentAdd`, `BuildAssemblyAdd`, average-cost mechanics) | Manufacturing clients want it | Inventory valuation is stateful and order-sensitive; a wrong adjustment silently corrupts COGS and stock; assemblies need BOMs that the agent has no way to validate | Out of scope; `ItemInventoryRet` read-only is enough for v1 |
| Sales-tax filing / `SalesTaxCodeAdd` / tax-agency workflows | "Automate tax" | Tax engine behavior varies by QB edition and jurisdiction setup; getting it subtly wrong creates filing errors | Out of scope; if a write needs a `SalesTaxRef`, look it up via `ItemQuery` (tax items) and let the human confirm in dry-run |
| Multi-currency specifics (`ExchangeRate` per txn, realized/unrealized FX, `CurrencyAdd`) | International clients | Multi-currency changes the shape of nearly every write request and report; turning it on in QB is irreversible; partial support is worse than none | Out of scope; `get_company_preferences` should *detect* multi-currency and the service should refuse currency-bearing writes with a clear message until v1.x |
| Bidirectional sync / change polling (delta queries on `ModifiedDateRangeFilter`, conflict resolution) | "Keep system X in sync with QB" | Sync is a different product: it needs durable cursors, conflict policy, dedup, replay — none of which a synchronous request/response agent service should own | Out of scope; the agent pulls on demand. If sync is ever needed, build it as a separate consumer of this API. |
| Scheduled jobs / job queue / QBWC polling | "Run the P&L every morning" | Reintroduces the QBWC complexity the spec deliberately dropped; scheduling belongs in whatever calls the API, not in the COM-bound service | Out of scope; spec keeps the QBWC design only as a README fallback note. A cron on the workstation hitting `POST /api/ops/report` covers this. |
| Bulk/batch write ops (one request adding 500 invoices) | "Import everything" | qbXML *does* allow multiple request elements per message, but partial-failure semantics (element 237 failed, 1–236 committed) are a nightmare to surface safely to an agent, and there's no transaction/rollback | v1: one write per call, each dry-run-confirmed. If batch import is ever needed, do it as an explicit, idempotent, resumable client-side loop with per-row audit. |
| Delete / Void as first-class ops (`TxnDelRq`, `TxnVoidRq`) | "Undo" | Destructive and often irreversible in QB; far higher blast radius than Add/Mod | Not a wrapped op in v1. Reachable only via raw qbXML, which is write-gated; the dry-run + confirm flow applies. |
| A web UI / dashboard | "Show me a screen" | The interfaces are the REST API and the Claude skill by design; a UI is a separate project | Out of scope (spec §10). |

## Feature Dependencies

```
QbSession lifecycle (Open/Begin/Process/End/Close, serialized, reconnect)
    └──required by──> EVERYTHING

<?qbxml version?> PI + QbXmlBuilder targeting that version
    └──required by──> every op (reads and writes)

status* parsing (QbXmlParser)
    └──required by──> every op  ──enhances──> QbErrors known-code map

Iterator/pagination handling (Start/Continue, iteratorID, remainingCount)
    └──required by──> list_customers / list_vendors / list_items / list_accounts
    └──required by──> list_invoices / list_bills / list_payments
    └──required by──> generic run_query (if added)
    └──ties to──────> response size-guard (auto-page → big response → spill-to-file)

ColDesc/ColData report parser
    └──required by──> report (P&L / BalanceSheet / AgingAR / AgingAP)
    └──enhances─────> plain-English report summarizer (differentiator)

CustomerQuery / VendorQuery / ItemQuery / AccountQuery (reads)
    └──practically-required-before──> create_invoice / create_bill / create_check / receive_payment
       (the agent needs ListIDs/RefNumbers to reference in line items & links)

get_company_preferences  ──enhances──> all writes (sales-tax on?, multi-currency?, default accounts)

Query-by-TxnID/ListID + EditSequence read
    └──required by──> mod_*  (Mod is full-replace; must read current state + EditSequence first)

Dry-run builder (POST /api/ops/{op}/dryrun)
    └──required by──> the skill's write-safety workflow (it never submits without a confirmed dry-run)
    └──conflicts-with──> "silent auto-apply" (explicitly disallowed)

Safety:AllowWrites flag (default false → 403)  ──gates──> all create_* / mod_* / raw-qbXML-containing-Add/Mod/Del/Void
```

### Dependency Notes

- **Iterator handling gates all list ops.** On any non-toy company file a list query without `MaxReturned`/iterator either truncates silently or returns a response so large it strains the COM bridge. Build the iterator loop once in `QbXmlBuilder`/`QbXmlParser` before wiring any `list_*` op. This is the single biggest "looks easy, isn't" item.
- **Report parsing is unlike every other parser.** `ReportQuery` responses are spreadsheet-shaped (`ColDesc` metadata + positional `ColData` in typed rows: `DataRow`/`SubtotalRow`/`TotalRow`/`TextRow`), not record-shaped. Budget for this separately from the entity parsers; reusing the entity-parser approach will fail.
- **Mod requires a prior read.** You cannot patch in qbXML — `*Mod` replaces the object. The agent workflow must be query → show current → merge change → dry-run → confirm → submit, and it must use the `EditSequence` from that same query. Stale `EditSequence` (`0x800404C5`) is the most common write failure; surface it verbatim and tell the agent to re-read.
- **Writes practically depend on reads.** `InvoiceAdd` line items need real `ItemRef`s; `BillAdd` lines need real `AccountRef`s; `ReceivePaymentAdd` `AppliedToTxnAdd` blocks need real invoice `TxnID`s. The agent will call `list_items`/`list_accounts`/`list_invoices` first — make those return the IDs it needs.
- **`OwnerID` is a silent gate.** Custom-field data (`DataExtRet`) is *omitted by default*; you only get it back if the query carries `OwnerID="0"`. Decide explicitly whether v1 list/query ops pass `OwnerID="0"` (recommended for reads) — "we don't return custom fields" is a design choice, not an accident, and should be a documented one.
- **Version PI ↔ QB build coupling.** The `<?qbxml version?>` you send must be ≤ the spec version the installed QB build supports (Enterprise 24 / QB 2024 → 16.0; older → lower). Pin it in config, but also surface `HostQuery`'s supported list in `/api/health` so a mismatch is obvious on day one. (Spec §11 already flags "confirm exact QB year/version" — this is why it matters.)

## What a good dry-run / preview affordance looks like

For an AI agent touching real books, the dry-run is the product's conscience. A good `POST /api/ops/{op}/dryrun` returns:

1. **The exact qbXML request** that would be sent, byte-for-byte (including the `<?qbxml version?>` PI) — so a human can diff it.
2. **A structured echo of the resolved arguments** — names *and* the `ListID`/`TxnID`/`EditSequence` they resolved to (so "Customer: Acme" is shown as "Acme Roofing (ListID 80000123-...)"), surfacing reference-resolution mistakes before they're committed.
3. **A plain-English summary**: "Create an invoice for Acme Roofing dated 2026-05-11, 2 lines totaling $4,200.00 (Consulting ×20 @ $200, plus $200 reimbursable), terms Net 30, to A/R account 'Accounts Receivable'." For a `mod_*`: a **field-level before/after diff** ("Terms: Net 15 → Net 30; everything else unchanged") plus the `EditSequence` it will use.
4. **Pre-flight validation results**: does the referenced customer/item/account exist? Do JE debits equal credits? Is `AllowWrites` currently true (i.e. would the real call even be permitted)? Is multi-currency on (and is this a currency-bearing write we'd refuse)? Return these as warnings/blockers, not just a 200.
5. **No side effects, ever** — it must not even open a write session; pure build + validate + describe. (And the dry-run endpoint itself should *not* be write-gated, so the agent can always preview even when writes are disabled.)

What a *bad* dry-run looks like (avoid): just echoing back the JSON the caller sent; or returning the qbXML with no English; or actually executing and calling it a "preview"; or validating nothing so the "preview" succeeds but the real call fails.

## MVP Definition

### Launch With (v1)

- [ ] `QbSession` lifecycle: serialized COM connect/begin/process/end/close, `DoNotCare` open mode, reconnect-on-dead-ticket — *everything depends on it*
- [ ] `<?qbxml version?>` PI from config; `QbXmlBuilder` targets that version — *every op needs it*
- [ ] `QbXmlParser`: `statusCode`/`statusSeverity`/`statusMessage` at message and element level; "0 rows" ≠ error; returns parsed JSON **plus** raw qbXML
- [ ] `QbErrors` known-code map for the handful of `0x8004xxxx` codes a deployer will hit
- [ ] Iterator/pagination handling (`Start`/`Continue`, `iteratorID`, `iteratorRemainingCount`) wired into all `list_*` ops; tie to the response size-guard
- [ ] `company_info`
- [ ] `report` — P&L / BalanceSheet / AgingAR / AgingAP, explicit date range or date macro; ColDesc/ColData reconstruction
- [ ] `list_customers` / `list_vendors` / `list_items` (normalize Item subtypes) / `list_accounts` — active-only + name filter
- [ ] `list_invoices` / `list_bills` / `list_payments` — date-range and/or entity filter; header-only by default
- [ ] `get_transaction` by `RefNumber` (may return >1) or `TxnID` (exact)
- [ ] Raw `POST /api/qbxml` passthrough, size-guarded, write-gated when it contains Add/Mod/Del/Void
- [ ] `GET /api/health` — company file, QB year/edition, SDK version, **supported qbXML versions (HostQuery)**, `AllowWrites`, last error
- [ ] `POST /api/ops/{op}/dryrun` for every write op (full qbXML + resolved refs + English + pre-flight validation; zero side effects; not write-gated)
- [ ] `Safety:AllowWrites=false` default → 403 on writes; immutable per-write audit log
- [ ] Writes (dry-run-gated): `create_customer`, `create_vendor`, `create_invoice`, `create_bill`, `create_check`, `receive_payment`, `create_journal_entry`, `mod_*` (read-then-replace with `EditSequence`)
- [ ] **Add: `run_query`** (generic entity query + filters → parsed rows) — small surface, big coverage
- [ ] **Add: `get_company_preferences`** — sales-tax on?, decimal places, multi-currency on?, default A/R & A/P accounts — prevents a class of write failures

### Add After Validation (v1.x)

- [ ] `BillPaymentCheckAdd` / `BillPaymentCreditCardAdd` — AP payment mirror of `receive_payment` *(trigger: any real AP-payment workflow; v1 leans on `create_check` + raw)*
- [ ] `SalesReceiptAdd`, `CreditMemoAdd`, `DepositAdd`, `EstimateAdd`, `PurchaseOrderAdd` — common transaction types beyond the core five *(trigger: agent users keep hand-writing the same raw qbXML for one of these)*
- [ ] Custom-field writes (`DataExtAdd`/`DataExtMod`, requires `OwnerID="0"` + a defined `DataExtDef`) — v1 should at least *read* `DataExtRet` *(trigger: a client's workflow data lives in custom fields)*
- [ ] `IncludeRetElement` "lite" flag on list ops for big-file performance
- [ ] `TransactionQuery` (generic, all txn types) as a superset of the per-type list ops
- [ ] Voids as a wrapped, extra-confirmation op (`TxnVoidRq`) — still no deletes

### Future Consideration (v2+)

- [ ] Payroll (read-only, raw-only) — *only if a concrete need appears; legal/tax blast radius*
- [ ] Inventory adjustments / assemblies — *stateful, valuation-corrupting; needs a dedicated design*
- [ ] Multi-currency support across writes/reports — *reshapes most requests; only if the company file turns it on*
- [ ] Sales-tax filing workflows — *jurisdiction- and edition-dependent*
- [ ] Batch/import ops with resumable, per-row-audited client loops — *only if a real migration needs it; never as a single mega-request*
- [ ] Bidirectional sync — *a separate product built on top of this API, not inside the COM-bound service*

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| `QbSession` lifecycle (serialized, reconnect) | HIGH | MEDIUM | P1 |
| Version PI + `QbXmlBuilder` | HIGH | LOW | P1 |
| `status*` + raw-qbXML-in-response parsing | HIGH | LOW–MEDIUM | P1 |
| Iterator/pagination handling | HIGH | MEDIUM | P1 (blocks all list ops) |
| `report` (4 reports) + ColDesc/ColData parser | HIGH | MEDIUM | P1 |
| `company_info` | HIGH | LOW | P1 |
| `list_customers/vendors/items/accounts` | HIGH | LOW–MEDIUM | P1 |
| `list_invoices/bills/payments` (filters) | HIGH | MEDIUM | P1 |
| `get_transaction` | MEDIUM | MEDIUM | P1 |
| Raw `POST /api/qbxml` (guarded, write-gated) | MEDIUM | LOW | P1 |
| `GET /api/health` (+ HostQuery versions) | HIGH | LOW | P1 |
| `dryrun` for writes (full preview + validation) | HIGH | LOW–MEDIUM | P1 |
| `AllowWrites=false` default + 403 + audit log | HIGH | LOW–MEDIUM | P1 |
| `create_customer/vendor` | MEDIUM | LOW–MEDIUM | P1 |
| `create_invoice/bill/check` | HIGH | MEDIUM–HIGH | P1 |
| `receive_payment` | HIGH | MEDIUM–HIGH | P1 |
| `create_journal_entry` | MEDIUM | MEDIUM | P1 |
| `mod_*` (read-then-replace + EditSequence) | MEDIUM | MEDIUM | P1 |
| `run_query` (generic query) | HIGH | MEDIUM | P1 (recommended add) |
| `get_company_preferences` | MEDIUM–HIGH | LOW | P1 (recommended add) |
| `QbErrors` known-code map | MEDIUM | LOW | P1 |
| `BillPaymentCheckAdd` | MEDIUM | MEDIUM | P2 |
| `SalesReceiptAdd`/`CreditMemoAdd`/`DepositAdd`/`EstimateAdd`/`PurchaseOrderAdd` | MEDIUM | MEDIUM | P2 |
| `DataExtRet` read (custom fields, `OwnerID=0`) | MEDIUM | LOW–MEDIUM | P2 |
| `DataExt*` writes | LOW–MEDIUM | MEDIUM | P3 |
| `IncludeRetElement` lite flag | LOW–MEDIUM | LOW | P2 |
| `TxnVoidRq` wrapped op | LOW | LOW–MEDIUM | P3 |
| Payroll / inventory assemblies / multi-currency / sales-tax filing / batch import / sync | LOW (for now) | HIGH | P3 / out of scope |

**Priority key:** P1 = must have for launch · P2 = add when possible · P3 = future consideration.

## Competitor Feature Analysis

| Feature | Intuit SDK sample apps / OSR | ConsoliBYTE PHP / FM Books Connector / jsgoupil quickbooks-sync | Our Approach |
|---------|------------------------------|----------------------------------------------------------------|--------------|
| Connection/session lifecycle | Demonstrated verbatim (`OpenConnection`/`BeginSession`/...) | Wrapped behind a helper; serialized | Same — `QbSession.cs`, serialized, auto-reconnect |
| Report queries | `GeneralSummaryReportQueryRq` etc. shown; raw `ColData` left to the dev | ConsoliBYTE wiki has dedicated "qbXML for Reporting" pages; most app frameworks expose reports as raw rows | We reconstruct a table from `ColDesc`+`ColData` and add a plain-English summary — a differentiator |
| Iterators | Documented pattern (`iterator="Start"`/`"Continue"`, `iteratorID`, `iteratorRemainingCount`) | All implement it; ConsoliBYTE has a dedicated iterator tutorial | Same pattern; decide auto-page-then-spill vs return-iteratorID (we lean auto-page + size-guard) |
| Entity & txn queries | One sample per entity | Generic query builders (pass entity + filters) | Per-type ops for the common ones **plus** a generic `run_query` for the rest |
| Add/Mod with `EditSequence` | Shown; Mod = full replace emphasized | Same; libraries fetch-then-modify | Same; agent flow = read → merge → dry-run → confirm → submit |
| Write safety / dry-run | None — samples just execute | None — frameworks just execute | **This is our headline differentiator**: `AllowWrites=false` default, mandatory dry-run + human confirm, immutable audit log |
| Payroll / inventory assemblies / multi-currency | Partially in OSR; sample coverage thin | Mostly avoided or read-only | Out of scope v1 (spec §10); detect multi-currency and refuse currency-bearing writes |
| Sync / scheduling | N/A (SDK is request/response) | jsgoupil/quickbooks-sync *is* a sync product (durable cursors, conflict handling) — shows how much extra machinery sync needs | Out of scope; on-demand pulls only; sync would be a separate consumer |

## Sources

- Intuit QuickBooks SDK release notes (14.0 / 15.0 and qbSDK-current `ReleaseNotes.pdf`) — `static.developer.intuit.com/resources/ReleaseNotes_QBXMLSDK_14_0.pdf`, `..._15_0.pdf`, `static.developer.intuit.com/qbSDK-current/doc/pdf/ReleaseNotes.pdf` — qbXML spec versions per QB build, supported request types. HIGH.
- Intuit Developer `QBXML_SDK_Samples` repo (`github.com/IntuitDeveloper/QBXML_SDK_Samples`, `readme.html`, C++ `qbXMLRPWrapper.cpp`) — canonical session lifecycle, request/response shapes. HIGH.
- ConsoliBYTE wiki & docs — "QbXML for Querying for Customers, with iterators", "QbXML for Reporting", iterator tutorials (`consolibyte.com/wiki`, `consolibyte.com/docs`) — iterator mechanics, report ColData/RowData structure, common quirks. MEDIUM–HIGH (long-stable, widely corroborated community reference).
- ProductiveComputing "FM Books Connector – Developer's Guide" PDF — independent confirmation of qbXML request/response patterns, version PI, `EditSequence`, custom-field `OwnerID`. MEDIUM.
- `jsgoupil/quickbooks-sync` (GitHub) and `to_qbxml` Ruby gem README — how connector libraries structure ops; what a *sync* product additionally requires (used to justify "sync is a separate product"). MEDIUM.
- End Point Dev blog "Demonstrating the QuickBooks Desktop SDK" (2020) and Molecularbear "QuickBooks SDK via JACOB" — corroborating walkthroughs of `QBXMLRP2.RequestProcessor` usage and `Interop.QBXMLRP2.dll`. LOW–MEDIUM.
- Project design spec `docs/superpowers/specs/2026-05-11-quickbooks-direct-sdk-accounting-design.md` — the v1 op catalog being validated.
- Prior training knowledge of the qbXML Onscreen Reference (OSR) for specific element names (`GeneralSummaryReportQueryRq`, `ReceivePaymentAdd`/`AppliedToTxnAdd`, `JournalEntryAdd`, `DataExtRet`, `ItemQueryRs` polymorphism) — treated as hypothesis, consistent with the above sources where they overlap. MEDIUM.

---
*Feature research for: qbXML-based QuickBooks Desktop/Enterprise integration service*
*Researched: 2026-05-11*
