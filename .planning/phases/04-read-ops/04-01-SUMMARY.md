---
phase: 04-read-ops
plan: 01
subsystem: qb-read-ops
tags: [quickbooks, qbxml, dotnet, read-ops, testing]
requires: [03-01]
provides:
  - IReadOp abstraction and ReadOpBase helpers
  - 12 in-process QuickBooks read ops
  - DI registration for IEnumerable<IReadOp>
  - Fake-backed end-to-end tests and constructed qbXML fixtures
affects: [05-rest-api-auth-health, op-registry]
tech-stack:
  added: []
  patterns:
    - IReadOp singleton DI registration by Name
    - IReadOnlyDictionary<string, object?> op args
    - FakeRequestProcessor-backed in-process op tests
    - Shared qbXML request filter builders inside op layer
commit-range:
  - 26a522f feat(04-01): IReadOp + ReadOpBase + ArgReader + company_info + DI
  - 51efc50 feat(04-01): get_company_preferences op
  - 6305b85 feat(04-01): report op (ProfitAndLoss / BalanceSheet / AgingAR / AgingAP)
  - 101eeed feat(04-01): list_customers / list_vendors / list_accounts ops
  - 531a76f feat(04-01): list_items op
  - bed6bcd feat(04-01): list_invoices / list_bills / list_payments ops
  - ceae15c feat(04-01): get_transaction op (TxnID | RefNumber)
  - 8e509ca feat(04-01): run_query op (whitelist) + register all read ops + OpRegistrationTests
tests: 76 -> 106
key-files:
  created:
    - quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/IReadOp.cs
    - quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/ReadOpBase.cs
    - quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/RunQueryOp.cs
    - quickbooks/QbConnectService/src/QbConnectService.Tests/OpRegistrationTests.cs
  modified:
    - quickbooks/QbConnectService/src/QbConnectService/Program.cs
    - quickbooks/QbConnectService/src/QbConnectService.Tests/OpTestHarness.cs
    - quickbooks/QbConnectService/src/QbConnectService.Tests/ListEntityOpsTests.cs
patterns-established:
  - "Read ops build qbXML with QbXmlBuilder.Rq and return body-level status data instead of throwing business-level failures."
  - "List ops route through QbListExecutor; single-shot ops use QbConnectionManager.ExecuteAsync plus QbXmlParser/QbReportParser."
duration: 1 session
completed: 2026-05-11
---

# Phase 4: Read Ops Summary

**Twelve QuickBooks read ops now run in-process on top of the Phase 3 qbXML engine with fake-backed tests and DI registration ready for Phase 5 op dispatch**

## Performance

- **Duration:** 1 session
- **Started:** 2026-05-11
- **Completed:** 2026-05-11
- **Tasks:** 9
- **Files modified:** 43

## What Was Built

- `IReadOp`, `ReadOpBase`, and `ArgReader` as the shared read-op abstraction over `QbXmlBuilder`, `QbConnectionManager`, `QbXmlParser`, `QbReportParser`, and `QbListExecutor`.
- Twelve read ops: `company_info`, `get_company_preferences`, `report`, `list_customers`, `list_vendors`, `list_items`, `list_accounts`, `list_invoices`, `list_bills`, `list_payments`, `get_transaction`, and `run_query`.
- Shared filter builders for entity-list and transaction-list qbXML requests, plus DI registration in `Program.cs`.
- `OpTestHarness` for fake-backed in-process execution, 8 new test classes, and 15 constructed qbXML fixtures.

## Key Decisions

- One `IReadOp` interface covers all read operations; there is no split between entity/report/query op interfaces.
- `report` is one op with a `type` switch instead of four separate report ops.
- `run_query` uses a hard-coded read-only entity whitelist and always appends `QueryRq`, so verb-like writes are structurally blocked.
- `company_info` bundles `HostQueryRq` and `CompanyQueryRq` in one request and sources the edition from `HostRet.ProductName`.
- `get_company_preferences` performs an `AccountQueryRq` A/R and A/P follow-up because `PreferencesRet` does not expose clean default A/R or A/P account fields.
- Op args stay as `IReadOnlyDictionary<string, object?>`; Phase 5 owns JSON deserialization/binding.
- `statusCode != 0` and zero-row results are surfaced in the response body, never thrown. Only transport/COM failures and caller `ArgumentException`s propagate.

## CONSTRUCTED-FIXTURE NOTE

All new qbXML fixtures are constructed, not live-captured, and each carries the Phase 9 re-pin header note:

- `HostCompanyQueryRs.qbxml`
- `PreferencesQueryRs.qbxml`
- `AccountQueryRs.arap.qbxml`
- `GeneralSummaryReportQueryRs.balancesheet.qbxml`
- `AgingReportQueryRs.ar.qbxml`
- `AgingReportQueryRs.ap.qbxml`
- `VendorQueryRs.qbxml`
- `AccountQueryRs.qbxml`
- `ItemQueryRs.normal.qbxml`
- `InvoiceQueryRs.qbxml`
- `BillQueryRs.qbxml`
- `ReceivePaymentQueryRs.qbxml`
- `TransactionQueryRs.byid.qbxml`
- `TransactionQueryRs.byref.multi.qbxml`
- `EmployeeQueryRs.qbxml`

Phase 9 must re-pin these MEDIUM-confidence qbXML element and enum names against `10.120.254.13`:

- Report enums and date shape: `GeneralSummaryReportType=ProfitAndLossStandard|BalanceSheetStandard`, `AgingReportType=ARAgingSummary|APAgingSummary`, and the aging-report date element shape.
- List/query filters: `ActiveStatus=ActiveOnly|InactiveOnly|All`, `TxnDateRangeFilter`, `DateMacro`, `RefNumberFilter`, `TxnIDList`, `TransactionTypeList`, and `IncludeLineItems`.
- Preferences fields: `SalesTaxPreferences`, `AccountingPreferences`, `MultiCurrencyPreferences`, `PurchasesAndVendorsPreferences`, `ItemsAndInventoryPreferences`, `DefaultItemSalesTaxRef`, `IsMultiCurrencyOn`, `IsUsingClassTracking`, `IsRequiringAccounts`, `IsUsingAccountNumbers`, and the decimal-places source field.
- Query request casing and element names for `AccountQueryRq`, `EmployeeQueryRq`, `TransactionQueryRq`, and the report request envelopes.

This carries the same caveat already used for the Phase 3 P&L fixture.

## For Phase 5

- Build `OpRegistry` from `IEnumerable<IReadOp>` via `ops.ToDictionary(o => o.Name)`.
- `/api/ops/{op}` should deserialize the JSON body to `Dictionary<string, object?>` and pass it directly to `op.RunAsync`.
- Unknown op returns `404`.
- `ArgumentException` from `RunAsync` maps to `400`.
- `QbException`, `QbBusyException`, and `QbTimeoutException` map to `502`, `409`, and `504`.
- A QuickBooks `statusCode != 0` in the result body still returns HTTP `200`.

## Out Of Scope (Deferred)

- HTTP surface, `OpRegistry`, bearer auth, HTTPS health endpoints, and raw `/api/qbxml` passthrough are Phase 5.
- Write ops, dry-run, `AllowWrites`, and audit logging are Phases 6 and 7.
- Python client, Claude skill, and deploy/on-box work are Phases 8 and 9.

## Task Commits

1. **Task 1: IReadOp + ReadOpBase + ArgReader + company_info + test harness + DI scaffolding** - `26a522f`
2. **Task 2: get_company_preferences op** - `51efc50`
3. **Task 3: report op** - `6305b85`
4. **Task 4: list_customers / list_vendors / list_accounts ops** - `101eeed`
5. **Task 5: list_items op** - `531a76f`
6. **Task 6: list_invoices / list_bills / list_payments ops** - `bed6bcd`
7. **Task 7: get_transaction op** - `ceae15c`
8. **Task 8: run_query op + registration coverage** - `8e509ca`

## Deviations From Plan

None in scope. The only implementation adjustment was omitting XML declarations from new constructed fixtures so the required leading XML comment remains parseable by `XDocument`.

## Issues Encountered

- Running `dotnet build` and `dotnet test` in parallel caused an `obj` file lock during Task 1 verification. Sequential execution resolved it and all subsequent task gates used sequential build/test as required.

## Next Phase Readiness

- Phase 5 can consume `IEnumerable<IReadOp>` directly for `OpRegistry`.
- The read-op contracts, argument shapes, and error-surfacing behavior are stable enough for the HTTP layer.
- Remaining uncertainty is limited to the constructed-fixture re-pin work deferred to Phase 9.

---
*Phase: 04-read-ops*
*Completed: 2026-05-11*
