# QBXML Live-Host Re-Pin Guide

This procedure runs on the live QuickBooks host after deploy.

It is the only part of Phase 9 that can require production-code edits, and it happens on the host, not in the dev/CI environment.

## Scope boundary

- The build pipeline does not perform the re-pin.
- The operator captures live request and response shapes from the real host company file.
- If a live shape differs from the current builder, parser, or golden fixture, the operator fixes the fixture and the production code together on the host, then re-runs the tests.

## Procedure

For each inventory item below:

1. Call the wrapped op, its `/dryrun` route, or raw `/api/qbxml` against the live company file.
2. Capture the real qbXML request and response.
   For write ops, `/api/ops/{op}/dryrun` gives the exact request body with no side effect.
   Oversized responses spill to `QbXml:SpillPath`; smaller ones return inline.
3. Compare the live request and response against:
   the QuickBooks SDK OnScreen Reference for the host qbXML version,
   the current builder/parser in `QbConnectService.Qb.Com`,
   and the corresponding golden fixture or test expectation.
4. If the live host differs, update both:
   the fixture or test expectation,
   and the builder/parser code in `QbConnectService.Qb.Com`.
5. Re-run:

   ```powershell
   dotnet test quickbooks/QbConnectService/QbConnectService.sln
   ```

6. Remove the `Phase 9 re-pin` or `CONSTRUCTED` note from the touched source file or fixture once that item is validated.
7. Update `.claude/skills/quickbooks-accounting/references/qbxml-cheatsheet.md` as items resolve.

## Inventory

| Area | Where it lives | What to verify on the host |
| --- | --- | --- |
| Company edition / `HostRet.ProductName` | `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/CompanyInfoOp.cs`; `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/HostCompanyQueryRs.qbxml` | Exact `HostRet.ProductName` / `edition` string format, host element casing, and `SupportedQBXMLVersionList` shape from `company_info`. |
| Company preferences field names | `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/CompanyPreferencesOp.cs`; `quickbooks/QbConnectService/src/QbConnectService.Tests/CompanyPreferencesOpTests.cs`; `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/PreferencesQueryRs.qbxml`; `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/AccountQueryRs.qbxml`; `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/AccountQueryRs.arap.qbxml`; `.claude/skills/quickbooks-accounting/SKILL.md` row `get_company_preferences` | `IsMultiCurrencyOn`, `IsUsingClassTracking`, `DefaultItemSalesTaxRef`, decimal-place source fields, and the exact `AccountQueryRq` / `AccountRet` casing used to resolve default A/R and A/P accounts. |
| Report request enums and report row/column casing | `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/ReportOp.cs`; `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/QbReportParser.cs`; `quickbooks/QbConnectService/src/QbConnectService.Tests/ReportOpTests.cs`; `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/GeneralSummaryReportQueryRs.pnl.qbxml`; `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/GeneralSummaryReportQueryRs.balancesheet.qbxml`; `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/AgingReportQueryRs.ar.qbxml`; `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/AgingReportQueryRs.ap.qbxml` | `GeneralSummaryReportType`, `AgingReportType`, aging date shape, and the exact `ColDesc` / `ColTitle` / `ColType` casing and nesting the parser expects. |
| `get_transaction` query element names | `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/GetTransactionOp.cs`; `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/TransactionQueryRs.byid.qbxml`; `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/TransactionQueryRs.byref.multi.qbxml` | Whether `TxnIDList`, `RefNumberFilter`, `MatchCriterion`, `RefNumber`, and optional `TransactionTypeList` match the real host dialect. |
| Invoice detail query toggle | `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/ListInvoicesOp.cs`; `quickbooks/QbConnectService/src/QbConnectService.Tests/ListTransactionOpsTests.cs`; `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/InvoiceQueryRs.qbxml`; `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/InvoiceQueryRs.formod.qbxml`; `.claude/skills/quickbooks-accounting/SKILL.md` row `list_invoices`; `.claude/skills/quickbooks-accounting/references/qbxml-cheatsheet.md` section `Phase-9 re-pin candidates` | Confirm the live request element is really `IncludeLineItems`, along with `TxnDateRangeFilter`, `DateMacro`, and `EntityFilter` child names and casing. |
| Item subtype discriminators | `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/ListItemsOp.cs`; `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/QbXmlParser.cs`; `quickbooks/QbConnectService/src/QbConnectService.Tests/ListEntityOpsTests.cs`; `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/ItemQueryRs.normal.qbxml`; `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/ItemQueryRs.polymorphic.qbxml` | Actual item `*Ret` names from the host and the parser's derived `type` values such as `Service` and `Inventory`. |
| Name-query wrapper style for write preflight | `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/WriteOpBase.cs` (`FetchByNameAsync`) | Whether list-entity preflight reads should use `FullNameList`, `NameFilter`, or `NameRangeFilter` on the real host for customer/vendor/term-style lookups. |
| Record lookup wrapper style for `mod` | `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/WriteOpBase.cs` (`FetchCurrentAsync`); `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/ModOp.cs`; `quickbooks/QbConnectService/src/QbConnectService.Tests/ModOpTests.cs`; `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/CustomerQueryRs.formod.qbxml`; `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/InvoiceQueryRs.formod.qbxml`; `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/CustomerModRs.qbxml`; `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/InvoiceModRs.stale.qbxml` | Exact `ListIDList`, `FullNameList`, and `TxnIDList` wrapper names per entity, plus the live stale-`EditSequence` business response (`3200`) and message text. |
| Write-verb enumeration for raw qbXML gating | `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/QbWriteDetector.cs` | Whether the host OSR shows any additional write-ish verbs beyond `*AddRq`, `*ModRq`, `*DelRq`, `*VoidRq`, `ListDelRq`, `TxnDelRq`, and `TxnVoidRq`. |
| Phase 7 create-customer/vendor fixtures | `quickbooks/QbConnectService/src/QbConnectService.Tests/CreateEntityOpsTests.cs`; `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/CustomerAddRs.qbxml`; `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/VendorAddRs.qbxml`; `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/VendorQueryRs.qbxml` | Real `CustomerAddRq` / `VendorAddRq` element names, reference resolution, and response field casing. |
| Phase 7 create-invoice/bill/check fixtures | `quickbooks/QbConnectService/src/QbConnectService.Tests/CreateTransactionOpsTests.cs`; `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/InvoiceAddRs.success.qbxml`; `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/BillAddRs.qbxml`; `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/CheckAddRs.qbxml`; `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/BillQueryRs.qbxml` | Real add-request line shapes, element names, and read-back casing for invoice, bill, and check flows. |
| Phase 7 receive-payment fixtures | `quickbooks/QbConnectService/src/QbConnectService.Tests/ReceivePaymentOpTests.cs`; `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/ReceivePaymentAddRs.qbxml`; `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/ReceivePaymentQueryRs.qbxml` | `ReceivePaymentAddRq` request fields, apply-to shapes, and query response casing. |
| Phase 7 journal-entry fixture | `quickbooks/QbConnectService/src/QbConnectService.Tests/CreateJournalEntryOpTests.cs`; `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/JournalEntryAddRs.qbxml` | Debit/credit line element names, memo/reference handling, and response casing. |
| Query/list fixtures across Phase 3 and 4 | `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/EmployeeQueryRs.qbxml`; `VendorQueryRs.qbxml`; `BillQueryRs.qbxml`; `ReceivePaymentQueryRs.qbxml`; `TransactionQueryRs.byid.qbxml`; `TransactionQueryRs.byref.multi.qbxml`; `InvoiceQueryRs.qbxml`; `ItemQueryRs.normal.qbxml`; `PreferencesQueryRs.qbxml`; `AccountQueryRs.qbxml`; `AccountQueryRs.arap.qbxml` | Exact `*QueryRs` element casing, filter wrappers, iterator attributes, and nested `Ret` shapes used by the live host. |
| Skill reference rows that encode re-pin assumptions | `.claude/skills/quickbooks-accounting/SKILL.md` rows `get_company_preferences` and `list_invoices`; `.claude/skills/quickbooks-accounting/references/qbxml-cheatsheet.md` section `Phase-9 re-pin candidates` | Keep the operator-facing skill text aligned with the final live-host reality as each re-pin item is resolved. |

## Capture tips

- Use `POST /api/ops/{op}/dryrun` whenever you need the exact request body without side effects.
- Use `POST /api/qbxml` when isolating a raw request shape that has no wrapped op.
- Keep the host's QuickBooks SDK OnScreen Reference open while comparing request and response names.
- Preserve the live request and response samples you validated until the whole inventory is cleared.
