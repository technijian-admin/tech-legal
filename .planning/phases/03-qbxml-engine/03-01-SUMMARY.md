---
phase: 03-qbxml-engine
plan: 01
subsystem: infra
tags: [quickbooks, qbxml, dotnet8, xlinq, xunit]

requires:
  - phase: 01-foundation-mockable-com-seam
    provides: IRequestProcessor seam and FakeRequestProcessor host/test foundation
  - phase: 02-com-session-lifecycle
    provides: QbConnectionManager session lifecycle, ExecuteAsync, and host wiring
provides:
  - Pure qbXML request builder and entity/report parsers
  - Iterator runner over QbConnectionManager with spill-to-file support
  - QbXmlOptions config, fixture-backed tests, and FakeRequestProcessor multi-response support
affects: [04-read-operations, 05-rest-surface, 07-write-ops]

tech-stack:
  added: [none]
  patterns: [pure builder/parser separation, fixture-backed qbXML goldens, iterator paging over QbConnectionManager]

key-files:
  created:
    - quickbooks/QbConnectService/src/QbConnectService.Qb.Com/QbXmlBuilder.cs
    - quickbooks/QbConnectService/src/QbConnectService.Qb.Com/QbXmlParser.cs
    - quickbooks/QbConnectService/src/QbConnectService.Qb.Com/QbReportParser.cs
    - quickbooks/QbConnectService/src/QbConnectService.Qb.Com/QbResponseSpiller.cs
    - quickbooks/QbConnectService/src/QbConnectService.Qb.Com/QbListExecutor.cs
    - quickbooks/QbConnectService/src/QbConnectService.Qb.Com/QbXmlModels.cs
    - quickbooks/QbConnectService/src/QbConnectService.Qb.Com/QbXmlOptions.cs
    - quickbooks/QbConnectService/src/QbConnectService.Tests/QbXmlBuilderTests.cs
    - quickbooks/QbConnectService/src/QbConnectService.Tests/QbXmlParserTests.cs
    - quickbooks/QbConnectService/src/QbConnectService.Tests/QbReportParserTests.cs
    - quickbooks/QbConnectService/src/QbConnectService.Tests/QbResponseSpillerTests.cs
    - quickbooks/QbConnectService/src/QbConnectService.Tests/QbListExecutorTests.cs
  modified:
    - quickbooks/QbConnectService/src/QbConnectService.Qb.Com/QbOptions.cs
    - quickbooks/QbConnectService/src/QbConnectService/Program.cs
    - quickbooks/QbConnectService/src/QbConnectService/appsettings.sample.json
    - quickbooks/QbConnectService/src/QbConnectService.Tests/Fakes/FakeRequestProcessor.cs
    - quickbooks/QbConnectService/src/QbConnectService.Tests/HostStartupTests.cs
    - quickbooks/QbConnectService/src/QbConnectService.Tests/QbConnectService.Tests.csproj

key-decisions:
  - "Moved OwnerIdZero from QbOptions into QbXmlOptions so qbXML behavior lives under one config section."
  - "Kept QbXmlBuilder, QbXmlParser, and QbReportParser pure; only QbListExecutor and QbResponseSpiller touch I/O."
  - "Used a constructed Profit & Loss qbXML fixture and documented that Phase 9 should re-pin report attribute casing on a live host."

patterns-established:
  - "QbXmlBuilder emits the full XML declaration + qbXML PI + QBXMLMsgsRq envelope from config-pinned version data."
  - "Entity parsing returns List<Dictionary<string, object?>> with DataExtRet normalized to customFields and Item subtype discriminators."
  - "List queries page through QbConnectionManager with iterator Start/Continue semantics and optional spill-to-file after parse."

duration: 12min
completed: 2026-05-11
---

# Phase 3: qbXML Engine Summary

**qbXML request building, entity/report parsing, iterator paging, and spill-to-file are now available as a tested engine layer under `QbConnectService.Qb`**

## Performance

- **Duration:** 12 min
- **Started:** 2026-05-11T20:19:55-07:00
- **Completed:** 2026-05-11T20:32:20-07:00
- **Tasks:** 8
- **Files modified:** 31

## Accomplishments
- Added `QbXmlOptions`, `QbXmlModels`, `QbXmlBuilder`, `QbXmlParser`, `QbReportParser`, `QbResponseSpiller`, and `QbListExecutor` in `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/`.
- Relocated `OwnerIdZero` out of `QbOptions`, documented it under `QbXml` in `appsettings.sample.json`, and wired all five engine services plus `Configure<QbXmlOptions>` in `Program.cs`.
- Added fixture-backed tests for builder, parser, report parsing, spiller behavior, iterator execution, host DI resolution, and the FakeRequestProcessor queue/capture extension; test count moved from 44 to 76.

## Task Commits

Each task was committed atomically:

1. **Task 1: QbXmlOptions + OwnerIdZero relocation + binding** - `d2f130d` (`feat(03-01): add QbXmlOptions, relocate OwnerIdZero, bind QbXml config`)
2. **Task 2: QbXmlModels + QbXmlBuilder** - `4025b92` (`feat(03-01): add QbXmlModels and QbXmlBuilder`)
3. **Task 3: QbXmlParser + entity fixtures** - `f725ad5` (`feat(03-01): add QbXmlParser + entity fixtures`)
4. **Task 4: QbReportParser + P&L fixture** - `e4e928b` (`feat(03-01): add QbReportParser + P&L report fixture`)
5. **Task 5: QbResponseSpiller** - `3366ac4` (`feat(03-01): add QbResponseSpiller`)
6. **Task 6: FakeRequestProcessor queue + capture** - `6425271` (`feat(03-01): FakeRequestProcessor multi-response queue + request capture`)
7. **Task 7: QbListExecutor + iterator fixtures** - `f76160f` (`feat(03-01): add QbListExecutor + iterator fixtures`)
8. **Task 8: DI smoke + final sweep** - `712818a` (`feat(03-01): wire qbXML engine DI + host-resolves smoke test`)

**Plan metadata:** `this commit` (`docs(03-01): plan checkboxes + Phase 3 summary`)

## Files Created/Modified

- `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/QbXmlOptions.cs` - qbXML config defaults for versioning, OwnerID behavior, iterator page size, response threshold, and spill path.
- `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/QbXmlModels.cs` - shared status, parsed response/report records, and the iterator mode enum.
- `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/QbXmlBuilder.cs` - pure qbXML envelope builder with iterator and `OwnerID` helpers.
- `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/QbXmlParser.cs` - pure entity-response parser with zero-row success handling, custom-field mapping, and item type discrimination.
- `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/QbReportParser.cs` - pure `ColDesc`-driven report parser that matches `ColData` by `colID`.
- `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/QbResponseSpiller.cs` - size-guard spill helper with `SpillPath -> Audit:Path -> %TEMP%` fallback.
- `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/QbListExecutor.cs` - iterator Start/Continue runner over `QbConnectionManager` with spill integration.
- `quickbooks/QbConnectService/src/QbConnectService.Tests/Fakes/FakeRequestProcessor.cs` - additive multi-response queues plus `ProcessRequests` capture for iterator tests.
- `quickbooks/QbConnectService/src/QbConnectService.Tests/Fixtures/qbxml/*.qbxml` - committed entity, iterator, error, and report fixtures copied into test output.
- `quickbooks/QbConnectService/src/QbConnectService/Program.cs` - DI wiring for `QbXmlOptions` and the qbXML engine singletons.

## Decisions Made

- Moved `OwnerIdZero` into `QbXmlOptions` and removed it from `QbOptions`, because it is a qbXML-specific behavior knob rather than a connection/session concern.
- Kept the engine split between pure parsing/building and impure execution/spill logic, matching the architecture guidance and making the core pieces QuickBooks-free in CI.
- Treated the P&L fixture as constructed rather than captured from a live SDKTestPlus3/OSR source; `QbReportParser` was written tolerantly, and Phase 9 should re-pin the exact `ColDesc`/`ColTitle`/`ColType`/`RowData` attribute casing against the live host.
- Added no NuGet packages. The only test project file change outside code was the fixture copy rule in `QbConnectService.Tests.csproj`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- A file lock occurred when `dotnet build` and `dotnet test` were launched in parallel against the same solution during Task 1 verification. Verification was rerun sequentially and all later tasks were verified sequentially without further issues.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- READ-01, READ-02, READ-03, and READ-11 are satisfied at the engine layer. Phase 4 can now compose actual read operations on top of `QbXmlBuilder`, `QbXmlParser`, `QbReportParser`, and `QbListExecutor`.
- The new host wiring resolves all engine singletons and preserves the no-SDK CI path through `FakeRequestProcessor`.
- Phase 9 should capture a real report response to re-pin the report fixture’s exact attribute casing, but this does not block Phase 4 read-op implementation.

---
*Phase: 03-qbxml-engine*
*Completed: 2026-05-11*
