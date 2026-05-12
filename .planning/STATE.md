# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-11)

**Core value:** Claude can run a QuickBooks read and get an answer in seconds — and can create/update a transaction only after an explicit dry-run-and-confirm step, with every write in an immutable audit log.
**Current focus:** Phase 1 — Foundation & Mockable COM Seam

## Current Position

Phase: 1 of 9 (Foundation & Mockable COM Seam)
Plan: 0 of TBD in current phase
Status: Ready to plan
Last activity: 2026-05-11 — Roadmap created (9 phases, 44/44 v1 requirements mapped)

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**
- Total plans completed: 0
- Average duration: —
- Total execution time: 0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| - | - | - | - |

**Recent Trend:**
- Last 5 plans: —
- Trend: —

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Roadmap]: 9-phase "seam → lifecycle → reads → API → writes → client → deploy" spine; reads split into qbXML engine (P3) + read ops (P4); writes split into safety/dry-run/audit (P6) + write ops (P7), per comprehensive depth.
- [Project]: Phases executed by Codex CLI from each PLAN.md, reviewed by Claude (multi-LLM pipeline) — keep success criteria concrete/verifiable.
- [Project]: COM behind `IRequestProcessor` so the .NET solution builds + full test suite runs with no QuickBooks SDK installed (phases 1–8 CI-able; only phase 9 needs host `10.120.254.13`).

### Pending Todos

None yet.

### Blockers/Concerns

- [Phase 2 & 9]: Environment facts unconfirmed — exact QuickBooks Enterprise build on `10.120.254.13` (pins qbXML spec ceiling + bitness), whether the `.QBW` is hosted multi-user, whether PII is enabled (could block unattended mode), `RequestProcessor` vs `RequestProcessor2` ProgID, `svc_qbsdk` creatability + "log on as a service" rights, firewall path for the HTTPS port.

## Session Continuity

Last session: 2026-05-12
Stopped at: Phases 1 & 2 COMPLETE (Codex-executed, Claude-reviewed: Phase 1 100/100, Phase 2 99/100 — one cosmetic-git-history LOW; build + 44/44 tests green; reviews in docs/review/EXECUTIVE-SUMMARY.md). Next: `/gsd:plan-phase 3` (qbXML Engine — READ-01,02,03,11) → `pwsh quickbooks/dev/run-codex-phase.ps1 -Phase 3` → review.
Resume file: None

### Completed phases

- **Phase 1 — Foundation & Mockable COM Seam** (SVC-01..05): 3-project .NET 8 solution, `IRequestProcessor` seam, `[ComImport]` placeholder interop stub + throwing `RealRequestProcessor` stub, tri-mode host, `FakeRequestProcessor`, CI. Commits `6477ead`..`3d6426c`. Reviewed 100/100.
- **Phase 2 — COM Session Lifecycle** (SESS-01..05): `QbConnectionManager` (STA worker thread + `SemaphoreSlim(1,1)` gate + bounded busy-wait → `QbBusyException` + watchdog → `QbTimeoutException`+poison + dead-ticket → rebuild-COM-object + retry-once), `QbErrors` HRESULT map, `QbException`/`QbBusyException`/`QbTimeoutException`, `StaThread`, real `RealRequestProcessor` COM forwarder + activation-failure smoke test, DI wiring (`Func<IRequestProcessor>` → `RealRequestProcessor` on Windows-non-test; `QbConnectionManager` singleton `IAsyncDisposable`). Commits `00ce1a8`..`aca78bb` (incl. 2 same-message revision commits — cosmetic). Reviewed 99/100. Zero new NuGet packages.
