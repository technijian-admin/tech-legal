---
phase: 09-packaging-deploy-smoke
plan: 01
subsystem: deployment
tags: [quickbooks, deploy, powershell, windows-service, scheduled-task, audit, docs]
requires:
  - phase: 08-python-client-skill-tooling
    provides: workstation client, repo-local skill, and the finalized multi-LLM execution loop
provides:
  - host-only deploy scripts for cert generation, service install/uninstall, and scheduled-task fallback
  - sample-config parity enforcement for appsettings.sample.json and quickbooks/clients/.env.sample
  - operator runbooks for QuickBooks authorization, host deploy, smoke verification, and live-host qbXML re-pin work
  - operator-facing --verify-audit CLI path plus CI PowerShell lint coverage
affects: [quickbooks-host-operators, planning-state, quickbooks-ci]
tech-stack:
  added: []
  patterns:
    - host-only PowerShell deploy scripts with ShouldProcess and WhatIf support
    - config-sample parity tests that bind the real option surface and client env keys
    - explicit documentation boundary between CI/dev work and live-host QuickBooks follow-up work
key-files:
  created:
    - quickbooks/QbConnectService/deploy/_common.ps1
    - quickbooks/QbConnectService/deploy/make-cert.ps1
    - quickbooks/QbConnectService/deploy/install-service.ps1
    - quickbooks/QbConnectService/deploy/uninstall-service.ps1
    - quickbooks/QbConnectService/deploy/run-as-task.ps1
    - quickbooks/QbConnectService/docs/register-integrated-app.md
    - quickbooks/QbConnectService/docs/SMOKE-CHECKLIST.md
    - quickbooks/QbConnectService/docs/QBXML-REPIN.md
    - quickbooks/QbConnectService/src/QbConnectService.Tests/SampleConfigParityTests.cs
    - quickbooks/QbConnectService/src/QbConnectService.Tests/VerifyAuditCliTests.cs
    - .planning/phases/09-packaging-deploy-smoke/09-01-SUMMARY.md
  modified:
    - quickbooks/QbConnectService/README.md
    - quickbooks/QbConnectService/src/QbConnectService/Program.cs
    - quickbooks/QbConnectService/src/QbConnectService/Options/ServerOptions.cs
    - .claude/skills/quickbooks-accounting/references/setup-and-troubleshooting.md
    - .claude/skills/quickbooks-accounting/references/qbxml-cheatsheet.md
    - .github/workflows/quickbooks-ci.yml
    - .planning/ROADMAP.md
    - .planning/REQUIREMENTS.md
    - .planning/STATE.md
key-decisions:
  - "Deploy scripts are authored, parsed, ScriptAnalyzer-clean, and WhatIf-capable in dev/CI; live execution remains a host operator step"
  - "Guarded Assert-Elevated replaced a literal #requires -RunAsAdministrator so -WhatIf can still run without elevation"
  - "--verify-audit exposes the existing AuditLog.VerifyChainAsync without starting Kestrel or the worker host"
patterns-established:
  - "Host-only QuickBooks follow-ups are documented explicitly instead of being approximated in CI"
  - "Operator runbooks link directly to the concrete deploy/docs paths created in this phase"
duration: 56 min
completed: 2026-05-12
---

# Phase 9: Packaging, Deploy & On-Box Smoke Summary

**The final deployment layer for the QuickBooks host: PowerShell deploy scripts, parity-enforced sample config, host runbooks, smoke procedures, a live-host qbXML re-pin guide, and a direct audit-chain verification CLI path.**

## Performance

- **Duration:** 56 min
- **Completed:** 2026-05-12
- **Tasks:** 8
- **Files modified:** 18

## Accomplishments

- Authored `deploy/_common.ps1`, `make-cert.ps1`, `install-service.ps1`, `uninstall-service.ps1`, and `run-as-task.ps1` under `quickbooks/QbConnectService/deploy/`, all with `SupportsShouldProcess`, host-only warnings, parse-clean syntax, and zero PSScriptAnalyzer warnings.
- Added `SampleConfigParityTests.cs` so `appsettings.sample.json` and `quickbooks/clients/.env.sample` fail the test suite if they stop matching the real option surface or the Python client env keys.
- Wrote the host operator documentation: `register-integrated-app.md`, the full deploy `README.md`, `SMOKE-CHECKLIST.md`, and `QBXML-REPIN.md`.
- Added `--verify-audit` in `Program.cs` to expose `AuditLog.VerifyChainAsync()` without starting the web host, and covered it with two direct unit tests.
- Added a `powershell-lint` CI job and fixed the remaining QuickBooks skill/readme forward references to the real `deploy/` and `docs/` paths.
- Closed Phase 9 with `dotnet test` green at **259/259** (up from 255 before this phase), zero new NuGet packages, and no `.gitignore` changes.

## Task Commits

Each task was committed atomically during this run:

1. `c46116a` — `feat(09-01): deploy/cert/install/uninstall/task PowerShell scripts`
2. `d237677` — `test(09-01): sample-config parity tests + fix ServerOptions deploy reference`
3. `91d0706` — `docs(09-01): QuickBooks integrated-app authorization runbook`
4. `e4ec629` — `docs(09-01): QbConnectService deploy runbook + HRESULT table`
5. `d727551` — `docs(09-01): on-box smoke checklist + live-host qbXML re-pin guide`
6. `407d67c` — `feat(09-01): --verify-audit CLI switch + tests`
7. `253c372` — `ci(09-01): PowerShell lint job + resolve deploy/doc forward-references`
8. The current close-out commit updates this summary plus `ROADMAP`, `REQUIREMENTS`, `STATE`, and the Phase 9 plan checklist.

## Files Created/Modified

- `quickbooks/QbConnectService/deploy/*.ps1` — host-only deploy script set for TLS cert creation, service install/remove, scheduled-task fallback, and shared service-logon-right helpers.
- `quickbooks/QbConnectService/src/QbConnectService.Tests/SampleConfigParityTests.cs` — binds the real option types and enforces `.sample` coverage for both service config and Python client env keys.
- `quickbooks/QbConnectService/docs/register-integrated-app.md` — one-time QuickBooks authorization flow with the `svc_qbsdk` identity boundary, unattended grant, PII note, and reauthorize path.
- `quickbooks/QbConnectService/README.md` — full `10.120.254.13` deploy runbook with firewall guidance, QBWC fallback note, audit verification instructions, and the `QbErrors.cs` HRESULT table.
- `quickbooks/QbConnectService/docs/SMOKE-CHECKLIST.md` — ordered host smoke checklist with environment facts, one real low-stakes write, and audit verification.
- `quickbooks/QbConnectService/docs/QBXML-REPIN.md` — live-host re-pin procedure and inventory of carried-forward constructed qbXML markers.
- `quickbooks/QbConnectService/src/QbConnectService/Program.cs` and `VerifyAuditCliTests.cs` — audit-chain CLI seam and direct tests.
- `.github/workflows/quickbooks-ci.yml` — added the parallel `powershell-lint` job.
- `.claude/skills/quickbooks-accounting/references/*.md` and `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/README.md` — resolved the new deploy/doc paths.

## Decisions Made

- Used the existing `AuditLog.VerifyChainAsync()` instead of inventing a second verification path.
- Kept the deploy scripts host-only and statically verifiable in dev/CI; no attempt was made to fake QuickBooks SDK or service-manager behavior locally.
- Chose guarded `Assert-Elevated` over a literal `#requires -RunAsAdministrator` so `-WhatIf` still works without elevation, which is required by the operator dry-run path.

## Reviewer Notes

- All five deploy scripts parse cleanly, dot-source cleanly, and pass `Invoke-ScriptAnalyzer -Path quickbooks/QbConnectService/deploy -Recurse -Severity Warning,Error`.
- The new `powershell-lint` GitHub Actions job runs `Invoke-ScriptAnalyzer` on `windows-latest`.
- `dotnet test quickbooks/QbConnectService/QbConnectService.sln` finished green at **259/259** after adding `SampleConfigParityTests` and `VerifyAuditCliTests`.
- No real `appsettings.json` or `quickbooks/clients/.env` was created or committed.
- No new NuGet packages were added in Phase 9.

## Deviations from Plan

### Deliberate implementation adjustment

**1. Elevation enforcement uses guarded runtime checks instead of a literal `#requires -RunAsAdministrator`**
- **Reason:** PowerShell enforces `#requires -RunAsAdministrator` before script code runs, which would block the required `-WhatIf` path from executing at all without elevation.
- **Outcome:** `install-service.ps1`, `uninstall-service.ps1`, and `run-as-task.ps1` enforce elevation through `Assert-Elevated` only when `-WhatIf` is not active, preserving the requested dry-run behavior.
- **Impact:** Behavior matches the plan's operator requirement even though the directive itself is not used literally.

## Issues Encountered

- Parallel local `dotnet build` and `dotnet test` runs briefly contended on `obj/` files (`QbConnectService.Qb.Com.dll` and static web assets cache files). Sequential reruns were clean and required no code changes.

## User Setup Required

The following are still operator steps on `10.120.254.13`:

- Regenerate the real QuickBooks interop on the host (`tlbimp` replacing the hand-written stub).
- Run the on-box smoke checklist in `quickbooks/QbConnectService/docs/SMOKE-CHECKLIST.md`.
- Complete the QuickBooks-side authorization in `quickbooks/QbConnectService/docs/register-integrated-app.md`.
- Perform any live-host qbXML re-pin edits documented in `quickbooks/QbConnectService/docs/QBXML-REPIN.md`.
- Execute the deploy scripts on the real host; they were authored and statically verified here, not run here.

## Project Completion

- Phase 9 is complete in-repo.
- The QuickBooks Direct-SDK Accounting Integration project is now complete across all 9 phases.
- Remaining work is host execution and validation only; no further dev-environment phase work is outstanding.

---
*Phase: 09-packaging-deploy-smoke*
*Completed: 2026-05-12*
