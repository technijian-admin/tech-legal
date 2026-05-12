---
phase: 07-write-ops
plan: 01
subsystem: api
tags: [quickbooks, qbxml, audit, dry-run, dotnet]
requires:
  - phase: 06-write-safety
    provides: IWriteOp/WriteOpBase, /dryrun endpoint, AllowWrites gate, and hash-chained AuditLog
provides:
  - seven create_* write ops and one generic mod op on the existing safety/dry-run/audit spine
  - shared write pre-flight helpers in WriteOpBase, WriteOpHelpers, and ArgReader
  - registration and test coverage proving all eight write ops resolve through OpRegistry as IWriteOp
affects: [08-python-client-skill-dev-tooling, 09-packaging-deploy, quickbooks-api-surface]
tech-stack:
  added: []
  patterns:
    - thin WriteOpBase subclasses with pure BuildRequest plus DryRunAsync pre-flight
    - generic full-replace mod flow via fresh read, merge-strip, and single audited execute
key-files:
  created:
    - quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/WriteOpHelpers.cs
    - quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/CreateCustomerOp.cs
    - quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/CreateVendorOp.cs
    - quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/CreateInvoiceOp.cs
    - quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/CreateBillOp.cs
    - quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/CreateCheckOp.cs
    - quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/ReceivePaymentOp.cs
    - quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/CreateJournalEntryOp.cs
    - quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/ModOp.cs
  modified:
    - quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/WriteOpBase.cs
    - quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/ArgReader.cs
    - quickbooks/QbConnectService/src/QbConnectService/Program.cs
    - quickbooks/QbConnectService/src/QbConnectService.Tests/OpRegistrationTests.cs
    - quickbooks/QbConnectService/src/QbConnectService.Tests/OpRegistryTests.cs
key-decisions:
  - "v1 ships one generic mod op, not per-entity mod_* routes"
  - "stale EditSequence results are returned and audited verbatim with no retry or auto-fix"
  - "v1 refuses currencyRef/exchangeRate and restricts mod to header-level fields"
patterns-established:
  - "Create ops: BuildRequest is pure qbXML generation, DryRunAsync does pre-flight reads, inherited RunAsync does gate/execute/parse/audit"
  - "Mod op: fresh read on every dry-run and execute, merge current+fields, strip read-only/computed children, then emit one *ModRq"
duration: 1h 13m
completed: 2026-05-12
---

# Phase 7: Write Ops Summary

**QuickBooks v1 write ops with dry-run pre-flight, single-row audit-backed execution, and a generic full-replace mod flow using fresh EditSequence reads**

## Performance

- **Duration:** 1h 13m
- **Started:** 2026-05-12T07:40:34-07:00
- **Completed:** 2026-05-12T08:53:09-07:00
- **Tasks:** 8
- **Files modified:** 36

## Accomplishments

- Added all eight Phase 7 production write ops on top of the existing Phase 6 `IWriteOp` / `/dryrun` / audit machinery: `create_customer`, `create_vendor`, `create_invoice`, `create_bill`, `create_check`, `receive_payment`, `create_journal_entry`, and generic `mod`.
- Filled the Phase 7 write-preflight foundation with `WriteOpBase.FetchByNameAsync` / `FetchCurrentAsync`, `WriteOpHelpers`, and `ArgReader.List` / `Decimal` / `RequiredString`.
- Extended registration and test coverage so `Program.cs` now exposes 20 `IReadOp` implementations and `OpRegistrationTests` proves the eight new write ops resolve as `IWriteOp`.
- Added 11 constructed qbXML fixtures plus focused tests for dry-run byte-exact output, validation failures, business-error pass-through, stale `3200` handling, and exact audit-row counting.

## Task Commits

Each task was committed atomically:

1. **Task 1: WriteOpBase pre-flight helpers + WriteOpHelpers + ArgReader extensions + helper tests** - `4334825` (`feat(07-01): write-op pre-flight helpers, WriteOpHelpers, ArgReader extensions`)
2. **Task 2: create_customer + create_vendor ops + DI + fixtures + tests** - `c7bdaf2` (`feat(07-01): create_customer and create_vendor ops`)
3. **Task 3: create_invoice op (lines) + DI + fixture + tests** - `638db67` (`feat(07-01): create_invoice op with line items`)
4. **Task 4: create_bill + create_check ops (expense + item lines) + DI + fixtures + tests** - `cd08087` (`feat(07-01): create_bill and create_check ops`)
5. **Task 5: receive_payment op + DI + fixture + tests** - `1760f24` (`feat(07-01): receive_payment op`)
6. **Task 6: create_journal_entry op (balance validation) + DI + fixture + tests** - `57010f4` (`feat(07-01): create_journal_entry op with balance validation`)
7. **Task 7: generic mod op (read -> merge -> strip -> build -> execute -> audit; no retry on 3200)** - `d99e1ca` (`feat(07-01): generic mod op with full-replace semantics`)
8. **Task 8A: DI sweep + OpRegistrationTests updates + full build** - `4f3dd2d` (`feat(07-01): register write ops + update op-registration tests`)

**Plan metadata:** this docs commit (`docs(07-01): Phase 7 complete — write ops`)

## Files Created/Modified

- `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/WriteOpBase.cs` - added the Phase 7 `FetchByNameAsync` and `FetchCurrentAsync` read helpers that dry-run and `mod` build on.
- `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/WriteOpHelpers.cs` - shared `MultiCurrencyGuard`, ref/address builders, and expense/item line emitters.
- `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/CreateCustomerOp.cs` and `CreateVendorOp.cs` - entity add ops with pure `BuildRequest` plus pre-flight name and terms checks.
- `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/CreateInvoiceOp.cs`, `CreateBillOp.cs`, `CreateCheckOp.cs`, and `ReceivePaymentOp.cs` - transaction add ops with required line/application validation and dry-run resolution warnings.
- `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/CreateJournalEntryOp.cs` - balanced journal-entry add op with caller-side validation before qbXML emission.
- `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/ModOp.cs` - fresh-read, full-replace generic header-level mod flow with no stale-EditSequence retry.
- `quickbooks/QbConnectService/src/QbConnectService/Program.cs` - registration of all eight write ops as `IReadOp` singletons, bringing the total to 20.
- `quickbooks/QbConnectService/src/QbConnectService.Tests/CreateEntityOpsTests.cs`, `CreateTransactionOpsTests.cs`, `ReceivePaymentOpTests.cs`, `CreateJournalEntryOpTests.cs`, `ModOpTests.cs`, and `WriteOpHelpersTests.cs` - focused behavior tests for every new op and helper surface.
- `quickbooks/QbConnectService/src/QbConnectService.Tests/OpRegistrationTests.cs` - now mirrors `Program.cs` and asserts all eight new write ops resolve and implement `IWriteOp`.
- `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/*.qbxml` - 11 constructed add/query/mod fixtures carrying the Phase 9 re-pin warning comment.

## Decisions Made

- One generic `mod` op replaced the original `mod_*` concept, because the Phase 7 scope lock required a single `{ entity, ref, fields }` shape wired through the existing ops surface.
- `create_*` ops stayed thin and inherited `WriteOpBase.RunAsync`; all write-specific behavior lives in pure `BuildRequest` methods and dry-run pre-flight reads.
- `mod` performs a fresh read on every execute and never reuses a dry-run `EditSequence`, so stale responses are surfaced as business outcomes instead of hidden retries.
- v1 explicitly refuses `currencyRef` / `exchangeRate`, and v1 `mod` rejects all line-touching fields to keep the scope at header-level updates only.
- `OpTestHarness` was intentionally left unchanged because it is only used by read-op tests; write-op tests use dedicated `WriteOpBaseTests.CreateFixture`-style harnesses with audit wiring.

## Reviewer Notes

- Phase 7 write ops are tested in-process and via `WebApplicationFactory<Program>` against `FakeRequestProcessor`; no real QuickBooks instance or SDK is involved in the test run.
- The qbXML `*AddRq` / `*ModRq` / `*QueryRq` element names, line-item element names, `ListIDList` / `FullNameList` / `TxnIDList` wrappers, the `mod` read-only/computed strip list, `*Mod` child order, and stale-`EditSequence` `statusCode` `3200` are MEDIUM-confidence constructed values based on consolibyte schema files, simulator behavior, Intuit samples, and status-code searches. Phase 9 re-pins them against `10.120.254.13`.
- Every new `*.qbxml` fixture carries `<!-- CONSTRUCTED — element names MEDIUM-confidence; Phase 9 re-pins against 10.120.254.13's qbXML 16.0 schema -->`.
- `mod.BuildRequest(...)` intentionally throws `InvalidOperationException` unless the caller has already supplied `__resolvedRecord` and `__editSequence`; the documented flow is `/api/ops/mod/dryrun` followed by `/api/ops/mod`.
- A stale `EditSequence` is never retried or auto-fixed. The response is returned verbatim, one audit row is appended, and exactly one `*ModRq` is sent.
- v1 `mod` is header-level-only, and all v1 write ops refuse multi-currency-bearing writes. Line-level mod stays a v1.x item; multi-currency support stays a v2 item.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated OpRegistryTests to tolerate the expanded op set**
- **Found during:** Task 2 (create_customer + create_vendor ops)
- **Issue:** The existing `OpRegistryTests.cs` hard-coded the pre-Phase-7 registry size and started failing as soon as new production ops were registered.
- **Fix:** Updated `OpRegistryTests.cs` to assert uniqueness and required names without pinning the old count, and added the first new write-op names to its expectation list.
- **Files modified:** `quickbooks/QbConnectService/src/QbConnectService.Tests/OpRegistryTests.cs`
- **Verification:** `dotnet test` stayed green after each subsequent task and finished at 255/255 passing.
- **Committed in:** `c7bdaf2` (part of Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking test compatibility issue)
**Impact on plan:** The deviation was necessary to keep the existing registry suite aligned with the new op surface. No runtime scope changed and no Phase 7 product behavior was widened.

## Issues Encountered

- None beyond the registry-test expectation drift noted above; the remaining work landed as planned once the legacy count assertion was corrected.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 8 can build directly on the now-stable eight-op API surface for the Python client, the `quickbooks-accounting` skill, and the Codex phase-runner documentation.
- The service already exposes the dry-run and audit behavior Phase 8 needs to teach.
- Phase 9 still needs live-host re-pin work for the constructed qbXML fixtures, filter wrapper names, child ordering, and stale-edit-sequence code behavior.

---
*Phase: 07-write-ops*
*Completed: 2026-05-12*
