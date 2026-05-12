---
phase: 05-rest-api-auth-health
plan: 01
subsystem: api
tags: [quickbooks, kestrel, bearer-auth, problem-details, minimal-api, qbxml, integration-testing]
requires:
  - 04-01
provides:
  - HTTPS-only Kestrel bind from Server options with dev/file-cert fallback
  - Static-bearer /api middleware with constant-time token comparison
  - Global ProblemDetails exception mapping for transport/auth/COM failures
  - GET /api/health, POST /api/qbxml, GET/POST /api/ops endpoints
  - Reusable QbWriteDetector and OpRegistry for later safety/write phases
affects: [06-write-safety-dry-run-audit, 07-write-ops, 08-python-client-claude-skill-dev-tooling, deploy]
tech-stack:
  added: [Microsoft.AspNetCore.Mvc.Testing 8.0.* (test-only)]
  patterns:
    - Minimal API route-group surface over the Phase 4 IReadOp layer
    - Global IExceptionHandler + ProblemDetails while QuickBooks business status stays in 200 bodies
    - WebApplicationFactory Testing environment with FakeRequestProcessor injection
commit-range:
  - d2234b3 feat(05-01): options POCOs + Kestrel HTTPS-only bind + appsettings keys
  - f3bd100 feat(05-01): static-bearer middleware over /api + WebApplicationFactory harness
  - 71dbad0 feat(05-01): global IExceptionHandler -> ProblemDetails (API-06 mapping)
  - 8d98f52 feat(05-01): OpRegistry over IReadOp + GET /api/ops
  - c1cf0a0 feat(05-01): GET /api/health with wrapped COM liveness probe
  - 240a472 feat(05-01): QbWriteDetector + POST /api/qbxml raw passthrough with 403 verb-scan
  - 54daaa6 feat(05-01): POST /api/ops/{op} dispatch via OpRegistry
tests: 106 -> 152
key-files:
  created:
    - quickbooks/QbConnectService/src/QbConnectService/Api/BearerAuthMiddleware.cs
    - quickbooks/QbConnectService/src/QbConnectService/Api/ApiExceptionHandler.cs
    - quickbooks/QbConnectService/src/QbConnectService/Api/HealthEndpoints.cs
    - quickbooks/QbConnectService/src/QbConnectService/Api/QbXmlEndpoints.cs
    - quickbooks/QbConnectService/src/QbConnectService/Api/OpsEndpoints.cs
    - quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/OpRegistry.cs
    - quickbooks/QbConnectService/src/QbConnectService.Qb.Com/QbWriteDetector.cs
    - quickbooks/QbConnectService/src/QbConnectService.Tests/QbWebAppFactory.cs
  modified:
    - quickbooks/QbConnectService/src/QbConnectService/Program.cs
    - quickbooks/QbConnectService/src/QbConnectService/appsettings.sample.json
    - quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/ArgReader.cs
    - quickbooks/QbConnectService/src/QbConnectService.Tests/QbConnectService.Tests.csproj
key-decisions:
  - "Minimal APIs and route groups, not MVC controllers, define the Phase 5 REST surface."
  - "GET /api/health stays bearer-protected because it leaks company-file and QuickBooks version facts."
  - "SafetyOptions and QbWriteDetector live in Qb.Com so Phase 6 can reuse the same write-safety primitives."
  - "POST /api/ops/{op} returns { op, result }; raw qbXML remains POST /api/qbxml's job."
  - "Non-zero qbXML statusCode values remain normal 200 bodies; only auth/safety/transport/COM failures map to HTTP errors."
patterns-established:
  - "Server:BindUrls is parsed once into HTTPS-only listeners; http:// bindings fail at startup."
  - "Every /api request is gated by a single static bearer token compared with CryptographicOperations.FixedTimeEquals."
  - "The fake-backed WebApplicationFactory harness is the integration path for all REST endpoint tests."
duration: 1 session
completed: 2026-05-11
---

# Phase 5: REST API, Auth & Health Summary

**HTTPS-only Kestrel, static bearer auth, ProblemDetails error mapping, and the fake-backed `/api` surface for health, raw qbXML, and read-op dispatch**

## Performance

- **Duration:** 1 session
- **Started:** 2026-05-11
- **Completed:** 2026-05-11
- **Tasks:** 8
- **Files modified:** 28

## Accomplishments

- Added host/server/auth/safety option binding, HTTPS-only Kestrel listener configuration, and dev-cert fallback when `Server:CertPath` is empty.
- Landed the full `/api` boundary: bearer middleware, `ProblemDetails` exception mapping, `GET /api/health`, `POST /api/qbxml`, and `GET`/`POST /api/ops`.
- Added reusable Phase 6 building blocks (`SafetyOptions`, `QbWriteDetector`, `OpRegistry`) plus `WebApplicationFactory<Program>` integration coverage against the fake processor.

## Task Commits

Each task was committed atomically:

1. **Task 1: Options POCOs + Kestrel HTTPS-only bind + appsettings keys** - `d2234b3`
2. **Task 2: Bearer middleware + WebApplicationFactory harness** - `f3bd100`
3. **Task 3: Global IExceptionHandler -> ProblemDetails** - `71dbad0`
4. **Task 4: OpRegistry + GET /api/ops** - `8d98f52`
5. **Task 5: GET /api/health** - `c1cf0a0`
6. **Task 6: QbWriteDetector + POST /api/qbxml** - `240a472`
7. **Task 7: POST /api/ops/{op} dispatch** - `54daaa6`

## Files Created/Modified

- `quickbooks/QbConnectService/src/QbConnectService/Options/ServerOptions.cs` and `Options/AuthOptions.cs` bind the host-facing server/auth config.
- `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/SafetyOptions.cs`, `QbWriteDetector.cs`, and `Qb/Ops/OpRegistry.cs` provide the reusable safety and dispatch primitives.
- `quickbooks/QbConnectService/src/QbConnectService/Api/*.cs` define the minimal-API middleware, exception handler, and endpoint surface.
- `quickbooks/QbConnectService/src/QbConnectService.Tests/QbWebAppFactory.cs` plus 9 new test classes cover API-01..06 against the fake processor.
- `quickbooks/QbConnectService/src/QbConnectService/Program.cs`, `appsettings.sample.json`, `ArgReader.cs`, and `QbConnectService.Tests.csproj` wire the surface into the existing host.

## Decisions Made

- Minimal APIs were kept instead of introducing controllers because the Phase 5 scope is a thin transport layer over the shipped read-op engine.
- `GET /api/health` is token-gated; the unauthenticated `/` route remains only the trivial process-up liveness string.
- `ArgReader.ToDictionary` was lifted to `public static` so `/api/ops/{op}` reuses the exact same JSON conversion behavior the ops already expect.
- `OpRegistry` remains `IEnumerable<IReadOp>` only in Phase 5; widening it for write ops is explicitly deferred to Phase 7.
- The write-verb scan is element-local-name based, never substring-based, and is documented as a Phase 9 re-pin item against the live host.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Running `dotnet build` and `dotnet test` in parallel produced `testhost.x86` file-lock warnings on the test output directory. Sequential build/test verification resolved it and was used for the remaining tasks.

## User Setup Required

None - runtime cert provisioning, production `appsettings.json`, and `make-cert.ps1` are deferred to Phase 9.

## Next Phase Readiness

- Phase 6 can reuse `SafetyOptions`, `QbWriteDetector`, the fake-backed API harness, and the `ProblemDetails` transport mapping immediately.
- Phase 7 still needs a deliberate `IReadOp`/`OpRegistry` widening decision for write ops; Phase 5 intentionally did not pre-build that shape.
- Phase 9 must re-pin the write-verb enumeration and the production certificate flow on the real QuickBooks host.

---
*Phase: 05-rest-api-auth-health*
*Completed: 2026-05-11*
