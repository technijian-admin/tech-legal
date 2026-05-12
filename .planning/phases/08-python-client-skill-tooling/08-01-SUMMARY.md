---
phase: 08-python-client-skill-tooling
plan: 01
subsystem: api
tags: [quickbooks, python, requests, pytest, claude-skill, github-actions]
requires:
  - phase: 05-rest-api-auth-health
    provides: bearer-gated /api/health, /api/ops, /api/ops/{op}, /api/ops/{op}/dryrun, and /api/qbxml endpoints
  - phase: 07-write-ops
    provides: the frozen 20-op QuickBooks surface, dry-run workflow, and audit-backed write behavior
provides:
  - workstation-side Python client with bearer auth, env-based config, and conservative retry behavior
  - runnable examples, pinned Python requirements, and responses-based pytest coverage
  - repo-local quickbooks-accounting Claude skill plus qbXML and troubleshooting references
  - hardened multi-LLM docs, polished Codex phase runner, and a python-client CI job
affects: [09-packaging-deploy-smoke, quickbooks-client-consumers, quickbooks-agent-automation]
tech-stack:
  added: [requests, urllib3, python-dotenv, pytest, responses]
  patterns:
    - thin requests.Session client wrapper with GET-only adapter retries and retryable dryrun POST
    - repo-local Claude skill with summarized op catalog and explicit safe-write workflow
    - shared phase execution loop documented through PLAN -> Codex -> review
key-files:
  created:
    - quickbooks/clients/qb_client.py
    - quickbooks/clients/tests/test_qb_client.py
    - quickbooks/clients/examples/create_customer_dryrun.py
    - .claude/skills/quickbooks-accounting/SKILL.md
    - .planning/phases/08-python-client-skill-tooling/08-01-SUMMARY.md
  modified:
    - quickbooks/dev/MULTI-LLM.md
    - quickbooks/dev/run-codex-phase.ps1
    - .github/workflows/quickbooks-ci.yml
    - .planning/ROADMAP.md
    - .planning/REQUIREMENTS.md
    - .planning/STATE.md
key-decisions:
  - "Python client retries only GETs plus the side-effect-free /dryrun POST; write POSTs and raw qbXML never auto-retry"
  - "The QuickBooks skill is repo-local under .claude/skills/quickbooks-accounting/, not a global user skill"
  - "Write-op nested shapes are summarized in the skill and point back to Qb/Ops/*.cs as the authoritative source"
patterns-established:
  - "Client usage starts with health() and checks allowWrites before any write path is considered"
  - "Safe writes always follow dryrun -> show qbXml/summary/preFlight -> explicit confirmation -> execute -> report"
duration: 18 min
completed: 2026-05-12
---

# Phase 8: Python Client, Claude Skill & Dev Tooling Summary

**A workstation-side Python QuickBooks client with mocked test coverage, a repo-local safe-write Claude skill, and a hardened Codex/Claude build pipeline with Python CI**

## Performance

- **Duration:** 18 min
- **Started:** 2026-05-12T09:24:34-07:00
- **Completed:** 2026-05-12T09:42:00-07:00
- **Tasks:** 4
- **Files modified:** 21

## Accomplishments

- Built `quickbooks/clients/` with `QbClient`, env loading, pinned Python deps, responses-based pytest coverage, runnable examples, and a short README.
- Added the repo-local `quickbooks-accounting` skill with the full 20-op catalog, the verbatim 5-step safe-write workflow, and qbXML/troubleshooting references.
- Hardened `quickbooks/dev/MULTI-LLM.md` and `run-codex-phase.ps1`, added a parallel `python-client` CI job, and appended `.pytest_cache/` to `.gitignore`.
- Closed `CLIENT-01`, `CLIENT-02`, `CLIENT-03`, `DEV-01`, and `DEV-02` without changing any .NET source; `dotnet test` stayed 255/255 green.

## Task Commits

Each task was committed atomically:

1. **Task 1: qb_client.py + .env.sample + requirements.txt + pytest config + tests** - `700a810` (`feat(08-01): python qb_client + .env.sample + requirements + pytest config + tests`)
2. **Task 2: Client example scripts + clients README** - `f781dac` (`feat(08-01): client example scripts + clients README`)
3. **Task 3: quickbooks-accounting Claude skill (SKILL.md + 2 references)** - `f765468` (`feat(08-01): quickbooks-accounting Claude skill (SKILL.md + qbxml + troubleshooting references)`)
4. **Task 4: Hardened dev tooling, Python CI, gitignore, and phase wrap-up** - this docs commit (`docs(08-01): dev tooling hardening, python CI job, phase 8 wrap-up`)

## Files Created/Modified

- `quickbooks/clients/qb_client.py` - thin HTTPS client over the frozen QbConnectService REST API, with bearer auth, env loading, dryrun support, and `QbApiError`.
- `quickbooks/clients/tests/test_qb_client.py` and `conftest.py` - seven `responses`-mocked tests covering bearer headers, result parsing, ProblemDetails mapping, GET retry, and write no-retry semantics.
- `quickbooks/clients/examples/pull_pnl.py`, `list_invoices.py`, and `create_customer_dryrun.py` - runnable workstation examples, with the dry-run script intentionally non-destructive.
- `quickbooks/clients/README.md` - local setup, ad-hoc usage, example commands, and test instructions.
- `.claude/skills/quickbooks-accounting/SKILL.md` - repo-local QuickBooks operating guide with the 20-op catalog and safe-write workflow.
- `.claude/skills/quickbooks-accounting/references/qbxml-cheatsheet.md` - raw qbXML envelope, request shapes, iterators, status rules, and Phase-9 re-pin caveats.
- `.claude/skills/quickbooks-accounting/references/setup-and-troubleshooting.md` - health/auth/write-gate/busy/timeout/TLS failure modes plus Phase-9 deploy-doc forward references.
- `quickbooks/dev/MULTI-LLM.md` and `quickbooks/dev/run-codex-phase.ps1` - finalized the proven Claude-plan -> Codex-execute -> Claude-review loop and removed the old bootstrap framing.
- `.github/workflows/quickbooks-ci.yml` - added a `python-client` job running `pip install -r requirements.txt` and `python -m pytest tests/ -q`.
- `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, and `.planning/STATE.md` - marked Phase 8 and its requirements complete and moved current focus to Phase 9.

## Decisions Made

- Used one pinned `requirements.txt` for runtime and test dependencies because the client is repo-local and Phase 8 favors low-friction setup over packaging complexity.
- Kept retries conservative: GET plus `/dryrun` only, because `POST /api/ops/{op}` and raw qbXML may write and are not idempotent.
- Kept the skill's write-op nested shapes summarized-with-pointer instead of duplicating the full server-side schema in Markdown; `Qb/Ops/*.cs` remains authoritative.
- Kept the skill repo-local so its workflow, references, and file paths stay versioned with the subsystem they drive.

## Reviewer Notes

- The new Python evidence is `python -m pytest quickbooks/clients/tests/ -q` green, including the `503 -> 200` GET retry case and the single-call write `503` case.
- No .NET code changed in Phase 8. `dotnet test quickbooks/QbConnectService/QbConnectService.sln -c Release` remained green at 255/255.
- The Python dependencies added here (`requests`, `urllib3`, `python-dotenv`, `pytest`, `responses`) are Python packages, not NuGet packages.
- The skill's write-op nested line and field shapes are intentionally summarized with pointers back to `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/*.cs`.
- The raw qbXML cheatsheet still carries Phase-9 re-pin caveats for constructed qbXML element names such as `IncludeLineItems` and some report/query shapes.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking verification] Removed a literal `.op(` example from the dry-run script docstring**
- **Found during:** Task 2 (Client example scripts + clients README)
- **Issue:** The verify step required `create_customer_dryrun.py` to contain no `.op(` match at all, but the initial docstring showed the safe-write execute step using that literal call shape.
- **Fix:** Reworded the docstring to describe the execute step without including a literal `.op(` string.
- **Files modified:** `quickbooks/clients/examples/create_customer_dryrun.py`
- **Verification:** `rg -n "\.op\(" quickbooks/clients/examples/create_customer_dryrun.py` returned no matches, and the example still compiled.
- **Committed in:** `f781dac` (part of Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 verification-blocking wording issue)
**Impact on plan:** No scope change. The auto-fix only aligned the example docstring with the plan's exact grep-based verification rule.

## Issues Encountered

- Local `pip install` downgraded `python-dotenv` to the plan-pinned `1.0.1`, which conflicts with an unrelated globally installed `litellm` preference for `1.2.2`. The repo pins stayed as planned and all Phase 8 verification passed.

## User Setup Required

None - no external service configuration required in-repo. Phase 9 will add the host deploy scripts, runbooks, and smoke checklist.

## Next Phase Readiness

- Phase 9 can now focus purely on packaging, deployment, and on-box smoke testing because the workstation client, skill, and pipeline tooling are in place.
- The client/examples/skill already assume the frozen Phase 5-7 REST surface and safe-write contract.
- Phase 9 still needs the live-host deploy artifacts, integrated-app authorization runbook, self-signed cert flow, on-box smoke checklist, and re-pin validation for the constructed qbXML caveats.

---
*Phase: 08-python-client-skill-tooling*
*Completed: 2026-05-12*
