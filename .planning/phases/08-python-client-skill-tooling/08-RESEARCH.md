# Phase 8: Python Client, Claude Skill & Dev Tooling - Research

**Researched:** 2026-05-12
**Domain:** Python HTTPS API client (`requests` + `urllib3.Retry` + `python-dotenv`), `pytest` + `responses` tests, a repo-local Claude Code skill (Markdown), PowerShell dev tooling, GitHub Actions CI
**Confidence:** HIGH on the Python stack and the API contract (read directly from Phase 5-7 source); HIGH on the skill structure (driven by the design spec §5/§6 and the actual op classes); MEDIUM on a few op arg-shape details flagged inline (constructed qbXML fixtures, Phase-9 re-pin candidates).

## Summary

Phase 8 is **Python + Markdown + PowerShell only — zero .NET changes**. The `QbConnectService` solution is frozen; the `dotnet build` / `dotnet test` (255/255) stays green trivially. The new verification surface is `pytest quickbooks/clients/tests/` green plus the `quickbooks-accounting` skill being well-formed Markdown with an accurate op catalog and an unambiguous safe-write workflow.

The stack is settled (project `STACK.md` already named it, and it is current as of 2026): `requests` 2.32.x (de-facto HTTPS client; bundles urllib3 2.x), a retrying `HTTPAdapter` mounting a `urllib3.util.retry.Retry`, `python-dotenv` 1.x for `.env`, and `pytest` 8.x + `responses` 0.25.x for tests — all in one pinned `requirements.txt`. The `QbClient` class is a thin wrapper over a `requests.Session`: ctor + `from_env()`, methods `health()` / `qbxml()` / `op()` / `dryrun()` / `ops()`, a `QbApiError` exception that parses the service's `ProblemDetails` body. The retry policy is **conservative on purpose**: retry only idempotent GET (`/api/health`, `/api/ops`) and the side-effect-free `/api/ops/{op}/dryrun` POST on connection errors / 502 / 503 / 504; do **not** auto-retry `POST /api/ops/{op}` (a write op is not idempotent) nor `POST /api/qbxml` (may contain a write).

The `quickbooks-accounting` skill lives **in the repo** at `tech-legal/.claude/skills/quickbooks-accounting/` (per the spec — not a global `~/.claude/skills/` skill). `SKILL.md` is kept lean: the quick-start, the op catalog table (20 ops: 12 read + 8 write), the **5-step safe-write workflow**, and pointers into `references/qbxml-cheatsheet.md` (raw-qbXML fallback, status codes, the `3200` stale-`EditSequence` rule) and `references/setup-and-troubleshooting.md` (failure modes; forward-references the Phase-9 deploy runbook). The dev tooling (`MULTI-LLM.md`, `run-codex-phase.ps1`) is hardening, not new build — both already work after 7 phases; the work is removing the "bootstrap version" framing, documenting the now-proven loop (the `--dangerously-bypass-approvals-and-sandbox` switch, the `docs(N-NN)` final-commit convention, the no-duplicate-`feat()`-title rule, the DeepSeek-CC review recipe), and a light polish of the script. Recommend adding a small `python-client` job to `.github/workflows/quickbooks-ci.yml` (a second job, same file) and adding `.pytest_cache/` to `.gitignore` (`__pycache__/` and `*.pyc` are already ignored at the repo root).

**Primary recommendation:** Build `qb_client.py` as a thin `requests.Session` wrapper with conservative POST-no-retry semantics and a `ProblemDetails`-aware `QbApiError`; pin one `requirements.txt`; mock the service with `responses` (`@responses.activate` + `responses.matchers.header_matcher`); keep `SKILL.md` lean with the op-catalog table + the 5-step dry-run-confirm-execute workflow verbatim from spec §5; harden (don't rewrite) the dev tooling; add a `python-client` CI job. ~4-5 atomic tasks.

## Standard Stack

### Core (runtime)
| Library | Version pin | Purpose | Why standard |
|---------|-------------|---------|--------------|
| `requests` | `requests==2.32.5` | HTTPS client, bearer header, `verify=` for the self-signed cert | De-facto standard sync HTTP client; trivial session + adapter mounting. 2.32.5 is the current 2.32.x patch (2.33.x exists but 2.32.x is the conservative line `STACK.md` names; either works on Python 3.10/3.11/3.12). |
| `urllib3` | `urllib3==2.2.3` (or pin `urllib3>=2,<3`) | `Retry` (`urllib3.util.retry.Retry`) + connection pooling under `HTTPAdapter` | Bundled-with-`requests` dependency; pin it explicitly since you pin `requests`. `Retry` lives in `urllib3.util.retry`. |
| `python-dotenv` | `python-dotenv==1.0.1` (1.x line) | Load `quickbooks/clients/.env` → `QB_API_BASE_URL` / `QB_API_TOKEN` / `QB_VERIFY_TLS` / `QB_TIMEOUT` / `QB_RETRIES` | Matches the spec's `.env` / `.env.sample` pattern. `load_dotenv()` + `os.environ`. |

### Supporting (dev / test)
| Library | Version pin | Purpose | When to use |
|---------|-------------|---------|-------------|
| `pytest` | `pytest==8.3.4` (8.x line) | Test runner | Standard. 9.x exists but 8.x is the conservative pick; works on 3.10/3.11/3.12. |
| `responses` | `responses==0.25.7` (0.25.x line) | Mock the service's HTTP endpoints in tests | `STACK.md` named `responses`; cleanest API for asserting request matching (headers, body) and ordered responses (for the retry test). 0.26.0 exists; 0.25.x is fine. |

**One file, not split.** The design spec says "plain pinned `requirements.txt` (no wheel/PyPI for v1)". Keep runtime + dev deps in one `quickbooks/clients/requirements.txt` for v1 simplicity. (A `requirements-dev.txt` split is a nice-to-have but adds friction for zero v1 benefit — the client travels in-repo and CI installs everything.)

### Alternatives considered
| Instead of | Could use | Tradeoff |
|------------|-----------|----------|
| `requests` + `urllib3.Retry` | `httpx` (sync + retries) | Only if async/HTTP-2 ever wanted — not for v1; calls are synchronous round-trips by design. |
| `responses` | `requests-mock` or `pytest-httpx` | `responses` is what `STACK.md` named; either of the others would also work. Don't switch. |
| one `requirements.txt` | `requirements.txt` + `requirements-dev.txt`, or `pyproject.toml` + `pip install -e .` | Defer to v1-simplicity: one file. A `pyproject.toml` is only worth it if `import qb_client` from anywhere is needed (it isn't — examples and the skill run scripts from `quickbooks/clients/`). |
| `pyproject.toml [tool.pytest.ini_options]` for test config | `pytest.ini` | Both fine. **Recommend a minimal `pyproject.toml`** under `quickbooks/clients/` with `[tool.pytest.ini_options]` `testpaths = ["tests"]` (and `pythonpath = ["."]` so `from qb_client import QbClient` resolves when running `pytest` from `quickbooks/clients/`). A bare `pytest.ini` is the lighter alternative. |
| Python 3.11/3.12 in CI | 3.10 (matches local) | Pick **3.12** for the CI `setup-python` (current stable, fast, fully compatible with all pins); the code targets 3.10+ syntax so it runs on the 3.10.11 local box too. |

**Installation:**
```bash
pip install -r quickbooks/clients/requirements.txt
# requirements.txt:
#   requests==2.32.5
#   urllib3==2.2.3
#   python-dotenv==1.0.1
#   pytest==8.3.4
#   responses==0.25.7
```
(Exact patch numbers above are current-as-of-2026-05 picks; the planner/Codex should `pip index versions <pkg>` or just take these — they are mutually compatible and Python-3.10–3.12 safe. If a patch has been yanked, the next patch in the same minor is fine.)

## Architecture Patterns

### Recommended layout (the files Phase 8 creates)
```
tech-legal/
  quickbooks/
    clients/
      qb_client.py                 # CLIENT-01: QbClient class + QbApiError + from_env()
      .env.sample                  # committed; real .env stays gitignored (already covered)
      requirements.txt             # pinned (5 lines above)
      pyproject.toml               # minimal [tool.pytest.ini_options] testpaths/pythonpath  (or pytest.ini)
      README.md                    # how to set up .env + run the client/examples (short)
      examples/
        pull_pnl.py                # CLIENT-02: op("report", {"type":"ProfitAndLoss","dateMacro":"ThisFiscalYear"})
        list_invoices.py           # CLIENT-02: op("list_invoices", {"fromDate":..., "toDate":...})
        create_customer_dryrun.py  # CLIENT-02: dryrun("create_customer", {"name":"Example Co"}) — prints qbXml/summary/preFlight, does NOT execute
      tests/
        test_qb_client.py          # CLIENT-02: pytest + responses
        conftest.py                # optional (a base_url/token/client fixture)
  .claude/skills/quickbooks-accounting/
    SKILL.md                       # CLIENT-03: frontmatter + quick-start + op catalog + safe-write workflow + pointers
    references/
      qbxml-cheatsheet.md          # raw-qbXML fallback, status codes, 3200 stale-EditSequence, iterators
      setup-and-troubleshooting.md # failure modes; forward-ref Phase-9 README/register-integrated-app.md
  quickbooks/dev/
    MULTI-LLM.md                   # DEV-01: hardened (remove "bootstrap version", document proven loop)
    run-codex-phase.ps1            # DEV-02: light polish
  .github/workflows/
    quickbooks-ci.yml              # add a `python-client` job (second job, same file)
  .gitignore                       # APPEND: .pytest_cache/   (only addition needed)
```

### Pattern 1: `QbClient` — thin `requests.Session` wrapper
**What:** One class holding a configured `requests.Session` with a retrying adapter; methods map 1:1 to the API routes.
**Recommended public surface:**
```python
# quickbooks/clients/qb_client.py
"""HTTPS client for the QbConnectService REST API (see quickbooks/QbConnectService).

All requests send `Authorization: Bearer <token>`. Pure HTTP — no QuickBooks dependency.
Conservative retries: GET + the side-effect-free /api/ops/{op}/dryrun POST retry on
connection errors / 502 / 503 / 504; write POSTs (/api/ops/{op}, /api/qbxml) never auto-retry.
"""
from __future__ import annotations
import os
from typing import Any, Optional, Union
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

DEFAULT_TIMEOUT = 60.0
DEFAULT_RETRIES = 3
_RETRY_STATUS = (502, 503, 504)            # 429 too if the service ever rate-limits; not today
_RETRY_METHODS = frozenset({"GET"})         # POST deliberately excluded (see dryrun special-case below)


class QbApiError(RuntimeError):
    """A non-2xx response from the service (its ProblemDetails body, parsed)."""
    def __init__(self, status_code: int, title: str | None = None, detail: str | None = None,
                 qb_error_code: str | None = None, body: Any = None):
        self.status_code = status_code
        self.title = title
        self.detail = detail
        self.qb_error_code = qb_error_code   # e.g. "0x80040420" when the service includes it
        self.body = body
        msg = f"{status_code} {title or ''}".strip()
        if detail:
            msg += f": {detail}"
        if qb_error_code:
            msg += f" [{qb_error_code}]"
        super().__init__(msg)


class QbClient:
    def __init__(self, base_url: str, token: str, *,
                 verify_tls: Union[bool, str] = True,
                 timeout: float = DEFAULT_TIMEOUT,
                 retries: int = DEFAULT_RETRIES,
                 session: Optional[requests.Session] = None):
        if not base_url:
            raise ValueError("base_url is required")
        if not token:
            raise ValueError("token is required")
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self._verify = verify_tls
        self._s = session or requests.Session()
        self._s.headers["Authorization"] = f"Bearer {token}"
        retry = Retry(total=retries, connect=retries, read=retries,
                      backoff_factor=0.5, status_forcelist=_RETRY_STATUS,
                      allowed_methods=_RETRY_METHODS, raise_on_status=False)
        adapter = HTTPAdapter(max_retries=retry)
        self._s.mount("https://", adapter)
        self._s.mount("http://", adapter)

    @classmethod
    def from_env(cls, *, dotenv_path: Optional[str] = None) -> "QbClient":
        try:
            from dotenv import load_dotenv
            load_dotenv(dotenv_path)        # loads quickbooks/clients/.env if present; no-op if missing
        except ImportError:
            pass
        base = os.environ.get("QB_API_BASE_URL")
        token = os.environ.get("QB_API_TOKEN")
        if not base or not token:
            raise RuntimeError("QB_API_BASE_URL and QB_API_TOKEN must be set (in the environment or quickbooks/clients/.env)")
        verify_raw = os.environ.get("QB_VERIFY_TLS", "true").strip()
        verify: Union[bool, str]
        if verify_raw.lower() in ("0", "false", "no", "off"):
            verify = False
        elif verify_raw.lower() in ("1", "true", "yes", "on", ""):
            verify = True
        else:
            verify = verify_raw            # a path to a CA bundle / .cer
        return cls(base, token,
                   verify_tls=verify,
                   timeout=float(os.environ.get("QB_TIMEOUT", DEFAULT_TIMEOUT)),
                   retries=int(os.environ.get("QB_RETRIES", DEFAULT_RETRIES)))

    # ---- API methods ----
    def health(self) -> dict:
        return self._get("/api/health")

    def ops(self) -> list[str]:
        return self._get("/api/ops")["ops"]

    def qbxml(self, raw_xml: str) -> str:
        r = self._s.post(f"{self.base_url}/api/qbxml", data=raw_xml.encode("utf-8"),
                         headers={"Content-Type": "application/xml"},
                         timeout=self.timeout, verify=self._verify)
        self._raise_for_status(r)
        return r.text

    def op(self, name: str, args: Optional[dict] = None) -> Any:
        r = self._s.post(f"{self.base_url}/api/ops/{name}", json=args or {},
                         timeout=self.timeout, verify=self._verify)
        self._raise_for_status(r)
        return r.json()["result"]

    def dryrun(self, name: str, args: Optional[dict] = None) -> dict:
        # /dryrun has no side effects → safe to retry. Use a one-off retrying call.
        r = self._post_retryable(f"{self.base_url}/api/ops/{name}/dryrun", json=args or {})
        self._raise_for_status(r)
        return r.json()["dryRun"]

    # ---- internals ----
    def _get(self, path: str) -> Any:
        r = self._s.get(f"{self.base_url}{path}", timeout=self.timeout, verify=self._verify)
        self._raise_for_status(r)
        return r.json()

    def _post_retryable(self, url: str, *, json: Any) -> requests.Response:
        # Reuse the same adapter but allow POST for this idempotent endpoint only.
        retry = Retry(total=DEFAULT_RETRIES, backoff_factor=0.5,
                      status_forcelist=_RETRY_STATUS,
                      allowed_methods=frozenset({"GET", "POST"}), raise_on_status=False)
        with requests.Session() as s2:
            s2.headers.update(self._s.headers)
            s2.mount("https://", HTTPAdapter(max_retries=retry))
            s2.mount("http://", HTTPAdapter(max_retries=retry))
            return s2.post(url, json=json, timeout=self.timeout, verify=self._verify)

    @staticmethod
    def _raise_for_status(r: requests.Response) -> None:
        if r.status_code < 400:
            return
        title = detail = qb = None
        body: Any = r.text
        ctype = r.headers.get("Content-Type", "")
        if "json" in ctype or "problem+json" in ctype:
            try:
                body = r.json()
                if isinstance(body, dict):
                    title = body.get("title")
                    detail = body.get("detail")
                    qb = body.get("qbErrorCode")
            except ValueError:
                pass
        raise QbApiError(r.status_code, title, detail, qb, body)
```
**Notes / decisions baked in above (the planner can adjust but should justify):**
- `op(name, args: dict|None)` — a single positional `args` dict, not `**kwargs`. The service args include keys like `fromDate`, and a dict matches the JSON-object body exactly and avoids name clashes; the skill and examples pass dicts. (`**kwargs` is friendlier but loses non-identifier keys and dict-valued nested args like `customerRef={"fullName": ...}`. Dict is the safer call.)
- **Retry policy (the flagged decision):** `urllib3.Retry` with `allowed_methods=frozenset({"GET"})` on the shared session adapter — GET (`/api/health`, `/api/ops`) retries on connect errors + 502/503/504; **POST is excluded** from the shared adapter so `POST /api/ops/{op}` (potential write — not idempotent) and `POST /api/qbxml` (may contain a write) never auto-retry. `dryrun()` is the one exception — it has zero side effects per spec §6, so it gets its own one-shot retrying call (`_post_retryable`). `raise_on_status=False` so the client (not urllib3) maps the status to `QbApiError`. `409 Busy` is **not** in `status_forcelist` — a busy QuickBooks should surface to the caller, not be hidden behind silent retries. (Note: `OpsEndpoints` returns `409` only via `ApiExceptionHandler` for `QbBusyException`; the caller should see it.)
- `health()` returns the raw dict (`{ status, connectionState, allowWrites, sdkVersion, qbXmlVersionConfigured, qbXmlVersionsSupported, companyFile, quickBooksVersion, lastError, time }` per Phase 5 `HealthEndpoints`). Don't model it as a class — a dict is fine and forward-compatible.
- `op()` returns the inner `result` value (the op's dict, which embeds `status`/`rows`/`count`/`rawSpilledTo`/`report`/`matches`/etc.). `dryrun()` returns the inner `dryRun` value (`{qbXml, summary, preFlight:[{name,ok,detail}], resolvedReferences, allowWrites}` for write ops; `{qbXml, summary:null, preFlight:[], resolvedReferences:{}, allowWrites, note}` for read ops). `ops()` returns the `ops` array.
- `qbxml()` posts the raw string as `application/xml`, returns `r.text` (the service responds `application/xml`). A `403` (write while `AllowWrites=false`) surfaces as `QbApiError(403, "Writes disabled", ...)`.

### Pattern 2: `responses`-based `pytest` tests
**What:** Mock the service's HTTP endpoints; assert the bearer header, status mapping, and ordered-response retry behaviour.
**Example:**
```python
# quickbooks/clients/tests/test_qb_client.py
import responses
from responses import matchers
from qb_client import QbClient, QbApiError

BASE = "https://qb.example:8443"
TOKEN = "test-token"

def _client():
    return QbClient(BASE, TOKEN, verify_tls=False, retries=2)

@responses.activate
def test_health_sends_bearer_and_returns_dict():
    payload = {"status": "healthy", "allowWrites": False, "sdkVersion": "16.0"}
    responses.get(f"{BASE}/api/health", json=payload, status=200,
                  match=[matchers.header_matcher({"Authorization": f"Bearer {TOKEN}"})])
    assert _client().health() == payload

@responses.activate
def test_op_returns_result():
    responses.post(f"{BASE}/api/ops/company_info",
                   json={"op": "company_info", "result": {"companyName": "Acme", "status": {"statusCode": "0"}}},
                   status=200)
    assert _client().op("company_info")["companyName"] == "Acme"

@responses.activate
def test_unknown_op_raises_qbapierror_with_problemdetails():
    responses.post(f"{BASE}/api/ops/nope",
                   json={"status": 404, "title": "Unknown op", "detail": "No op named 'nope'."},
                   status=404, content_type="application/problem+json")
    try:
        _client().op("nope")
        assert False, "expected QbApiError"
    except QbApiError as e:
        assert e.status_code == 404
        assert e.title == "Unknown op"

@responses.activate
def test_qbxml_returns_raw_text():
    responses.post(f"{BASE}/api/qbxml", body="<QBXML>...</QBXML>", status=200, content_type="application/xml")
    assert _client().qbxml("<QBXML>...</QBXML>").startswith("<QBXML")

@responses.activate
def test_dryrun_returns_dryrun_block():
    dry = {"qbXml": "<?qbxml version=\"16.0\"?>...", "summary": "Create customer 'Example Co'.",
           "preFlight": [{"name": "allowWrites", "ok": False, "detail": "Safety:AllowWrites is false"}],
           "resolvedReferences": {}, "allowWrites": False}
    responses.post(f"{BASE}/api/ops/create_customer/dryrun", json={"op": "create_customer", "dryRun": dry}, status=200)
    assert _client().dryrun("create_customer", {"name": "Example Co"})["summary"].startswith("Create customer")

@responses.activate
def test_get_retries_on_503_then_succeeds():
    # responses returns registered responses in order for the same URL
    responses.get(f"{BASE}/api/health", json={"error": "warming up"}, status=503)
    responses.get(f"{BASE}/api/health", json={"status": "healthy"}, status=200)
    assert _client().health()["status"] == "healthy"

@responses.activate
def test_write_op_post_does_not_retry_on_503():
    # only ONE response registered; if the client retried it would raise ConnectionError (no more matches)
    responses.post(f"{BASE}/api/ops/create_customer",
                   json={"status": 503, "title": "QuickBooks unavailable"}, status=503,
                   content_type="application/problem+json")
    try:
        _client().op("create_customer", {"name": "X"})
        assert False
    except QbApiError as e:
        assert e.status_code == 503
    # exactly one call was made
    assert len(responses.calls) == 1
```
**`pyproject.toml` test config:**
```toml
# quickbooks/clients/pyproject.toml
[tool.pytest.ini_options]
testpaths = ["tests"]
pythonpath = ["."]      # so `from qb_client import QbClient` resolves when pytest runs from quickbooks/clients/
```
Run from the repo root: `python -m pytest quickbooks/clients/tests/ -q` (or `cd quickbooks/clients && pytest`). **Codex must `pip install -r quickbooks/clients/requirements.txt` before `pytest` will pass — bake that into the task's verification step.**

### Pattern 3: example scripts
Each example: a module docstring, `if __name__ == "__main__":` guard, `QbClient.from_env()`, one or two calls, pretty-print with `json.dumps(..., indent=2, default=str)`. `create_customer_dryrun.py` calls **`dryrun(...)` only** and prints `qbXml` / `summary` / `preFlight` / `allowWrites` — it must NOT call `op(...)`. (A code comment + the docstring should say so explicitly so a reader doesn't "fix" it.)

### Anti-patterns to avoid
- **Auto-retrying write POSTs.** A `create_*` retried after a timeout could create a duplicate. Keep POST out of the shared retry adapter; only GET + `/dryrun` retry.
- **Hard-coding the base URL / token in `qb_client.py` or the examples.** Everything comes from `.env` / the ctor. `.env` stays gitignored (`STACK.md`/Phase-1 `.gitignore` already covers `quickbooks/clients/.env`).
- **A bare `requests.get(url)` without `timeout=` or `verify=`.** Always pass both; the self-signed dev cert needs `verify=False` (or a `.cer` path).
- **Modelling `health()`/`op()` results as typed dataclasses.** The service returns open dicts (with op-specific keys + the embedded `status`); a class would fight forward-compat. Return dicts.
- **A global `~/.claude/skills/quickbooks-accounting/` skill.** The spec puts it in the repo at `tech-legal/.claude/skills/quickbooks-accounting/`. Repo-local only.
- **`SKILL.md` carrying the whole qbXML spec.** Keep `SKILL.md` lean (workflow + op-catalog table + pointers); the cheatsheet and troubleshooting are `references/` files loaded on demand.

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---------|-------------|-------------|-----|
| HTTP retries with backoff | a manual `for attempt in range(3): try/except` loop | `urllib3.util.retry.Retry` mounted on `HTTPAdapter` | Handles connect-vs-read retries, backoff jitter, `Retry-After`, status-list filtering — and integrates with the session. |
| Reading `.env` | parsing the file by hand | `python-dotenv` `load_dotenv()` | Quoting, comments, `export ` prefixes, multiline values — all handled. |
| Mocking the service in tests | a stub `http.server` in a thread | `responses` (`@responses.activate`) | Per-URL/method matching, request-body/header assertions, ordered responses for the retry test, `responses.calls` for call-count assertions — far less code, no port races. |
| Bearer-header assertions in tests | inspecting raw socket data | `responses.matchers.header_matcher({...})` | First-class matcher; the test fails clearly if the header is missing/wrong. |
| Connection pooling / TLS verify path | a fresh `requests.get` per call | a single `requests.Session` on `QbClient` with `verify=` set once | Reuses the TCP/TLS connection; one place for the bearer header and the cert setting. |

**Key insight:** This is a thin client over a small, already-built REST API. The temptation is to "just use `requests.get`" everywhere — but the session + retrying adapter + `from_env` + `QbApiError` pattern is ~120 lines and gives you the whole surface cleanly. Don't reinvent any of the five things above.

## Common Pitfalls

### Pitfall 1: Auto-retrying a non-idempotent write
**What goes wrong:** A `create_invoice` POST times out on the read but actually succeeded server-side; the retry creates a duplicate invoice.
**Why:** Putting `POST` in `Retry.allowed_methods` on the shared adapter.
**Avoid:** `allowed_methods=frozenset({"GET"})` on the session adapter; `/dryrun` gets its own retrying call (zero side effects). `op()` and `qbxml()` use the non-retrying path.
**Warning sign:** A test that retries `POST /api/ops/create_customer` and "passes" — that test is wrong; the correct test asserts exactly one call (`len(responses.calls) == 1`).

### Pitfall 2: `pytest` can't import `qb_client`
**What goes wrong:** `ModuleNotFoundError: No module named 'qb_client'` when running `pytest`.
**Why:** `qb_client.py` is at `quickbooks/clients/qb_client.py`; `tests/` is a subfolder; pytest's rootdir/path discovery doesn't auto-add the parent.
**Avoid:** `pyproject.toml` `[tool.pytest.ini_options] pythonpath = ["."]` under `quickbooks/clients/` (pytest ≥ 7 supports `pythonpath`), and run pytest with `quickbooks/clients` as rootdir (it will be, since that's where the config file is). Alternatively a `tests/conftest.py` that `sys.path.insert(0, str(Path(__file__).parent.parent))` — but the `pythonpath` config is cleaner.
**Warning sign:** Works in CI from `cd quickbooks/clients && pytest` but not from the repo root — fix the config so both work.

### Pitfall 3: Codex runs `pytest` before `pip install`
**What goes wrong:** `pytest: command not found` or `ModuleNotFoundError: responses`.
**Why:** The deps aren't installed.
**Avoid:** The task's `<action>` / `<verify>` must include `pip install -r quickbooks/clients/requirements.txt` before `python -m pytest quickbooks/clients/tests/ -q`. The CI job does the same (`pip install` step before `pytest` step).
**Warning sign:** A green local box (deps already there) but a red CI run, or vice versa.

### Pitfall 4: The skill's op catalog drifts from the actual ops
**What goes wrong:** `SKILL.md` lists an op arg key that doesn't exist (e.g. `mod_customer` instead of the generic `mod` with `{entity, ref, fields}`), so a Claude session sends args the service rejects.
**Why:** Writing the catalog from memory / the spec's prose instead of the actual `Qb/Ops/*.cs`.
**Avoid:** The op-catalog table below was built from the actual op classes (read 2026-05-12). The planner should keep it, and where an arg shape is summarized rather than line-by-line verified, **say so in the table** ("header-level fields only", "see `mod` notes"). Add a one-line note in `SKILL.md`: "arg shapes here are accurate as of Phase 8; the authoritative source is `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/*.cs`."
**Warning sign:** The catalog claims an op named `mod_invoice` — there is no such op; there's one generic `mod`.

### Pitfall 5: The safe-write workflow is described loosely
**What goes wrong:** A Claude session executes a write without the dry-run-and-confirm dance, or skips showing the byte-exact qbXML.
**Why:** Vague wording ("dry-run first, then execute") instead of the explicit 5-step sequence with a hard "NEVER skip" rule.
**Avoid:** Write the 5 steps verbatim (see "Safe-write workflow" below), with the `mod` stale-`3200` sub-rule, and a bold "NEVER execute a write op without completing steps 1-4 first."
**Warning sign:** The workflow section is one sentence — it must be a numbered list with the "NEVER" rule.

### Pitfall 6: `.gitignore` rewrite instead of append
**What goes wrong:** Codex rewrites `.gitignore` and drops the Phase-1 entries or the repo-wide ones.
**Why:** Treating `.gitignore` as editable rather than append-only (the `run-codex-phase.ps1` HARD RULES already say append-only).
**Avoid:** The only addition needed is `.pytest_cache/` — append one line. `__pycache__/` and `*.pyc` are already at the repo root; `quickbooks/clients/.env` is already ignored. (Confirmed by `git check-ignore` 2026-05-12.)
**Warning sign:** A `.gitignore` diff that removes lines.

## Code Examples

### The API contract (read from Phase 5-7 source — what the client wraps)
- **`GET /api/health`** → `200` JSON: `{ status, connectionState, allowWrites, sdkVersion, qbXmlVersionConfigured, qbXmlVersionsSupported, companyFile, quickBooksVersion, lastError, time, ... }`. Bearer-gated. `status` is `"healthy"` / a down/degraded value (never lies — Phase 5 probes the COM session). Source: `Api/HealthEndpoints.cs`.
- **`GET /api/ops`** → `200 { "ops": ["company_info", "create_bill", ...] }` (sorted). Source: `Api/OpsEndpoints.cs`.
- **`POST /api/qbxml`** body = raw qbXML text → `200 application/xml` (the raw qbXML response, size-guarded) — or `403` (`ProblemDetails` "Writes disabled") if the body contains an `Add`/`Mod`/`Del`/`Void` request and `AllowWrites=false`; `400` on empty body. Source: `Api/QbXmlEndpoints.cs`.
- **`POST /api/ops/{op}`** body = JSON object of args → `200 { "op": "...", "result": {...} }`. `404` (`ProblemDetails` "Unknown op") for an unknown op; `403` ("Writes disabled") if `{op}` is a write op and `!AllowWrites`; `400` ("Bad request") on bad args; `409` ("QuickBooks busy"); `503` ("QuickBooks unavailable", with `qbErrorCode` extension); `504` ("QuickBooks timeout"). A non-zero qbXML `statusCode` is **not** an HTTP error — it rides inside `result` as `result.status` (the `200` body). Source: `Api/OpsEndpoints.cs`, `Api/ApiExceptionHandler.cs`.
- **`POST /api/ops/{op}/dryrun`** body = JSON args → `200 { "op": "...", "dryRun": {...} }`. For **write ops**: `dryRun = { qbXml, summary, preFlight: [{name, ok, detail}], resolvedReferences, allowWrites }` (byte-exact qbXML, zero side effects). For **read ops**: `dryRun = { qbXml: <preview, may be null>, summary: null, preFlight: [], resolvedReferences: {}, allowWrites, note: "dry-run preview is available for write ops; this is a read op..." }`. **NOT write-gated** — works even when `AllowWrites=false`. `404` for unknown op. Source: `Api/OpsEndpoints.cs`.
- **Error body shape (`ProblemDetails`):** `{ "status": <int>, "title": "<short>", "detail": "<message>", "qbErrorCode": "0x80040420" (only on QbException) }` (+ the RFC-7807 `type`/`instance`). The client parses `title`/`detail`/`qbErrorCode` into `QbApiError`. Source: `Api/ApiExceptionHandler.cs`.
- **Auth:** `Authorization: Bearer <token>` on every `/api/*` call; missing/wrong → `401` (`ProblemDetails` "Unauthorized", `WWW-Authenticate: Bearer`). Source: `Api/BearerAuthMiddleware.cs`.

### The op catalog — 12 read ops + 8 write ops (built from `Qb/Ops/*.cs`, 2026-05-12)

**Read ops (safe to call freely; never write-gated):**

| Op | Args | Returns (`result`) | Notes |
|----|------|--------------------|-------|
| `company_info` | (none) | `{ ...company name, address, fiscalYearStart, edition (from HostRet.ProductName)... }` | One round-trip combining Host + Company. |
| `get_company_preferences` | (none) | `{ status, salesTaxEnabled, defaultItemSalesTaxRef, multiCurrencyEnabled, homeCurrencyRef, decimalPlaces, classTrackingOn, requireAccounts, useAccountNumbers, defaultDiscountAccountRef, defaultArAccount, defaultArAccountSource:"AccountQuery", defaultApAccount, defaultApAccountSource:"AccountQuery", rawPreferencesRet }` | Some field names (`IsMultiCurrencyOn`, `IsUsingClassTracking`, `decimalPlaces` source) are Phase-9 re-pin candidates — flag as "may shift on the live host". |
| `report` | `{ type: ProfitAndLoss\|BalanceSheet\|AgingAR\|AgingAP, fromDate?, toDate?, dateMacro? }` — supply **exactly one** of (`fromDate`+`toDate`) or `dateMacro` | `{ type, report: <ParsedReport: ColDesc-driven rows> }` | P&L/BalanceSheet → `GeneralSummaryReportQueryRq`; AgingAR/AP → `AgingReportQueryRq`. Report column casing is a Phase-9 re-pin candidate (constructed fixture). |
| `list_customers` | `{ activeStatus?: Active\|Inactive\|All (default All), name?: <substring>, nameMatch?: Contains\|StartsWith\|EndsWith (default Contains) }` | `{ status, rows: [...], count, rawSpilledTo }` | Iterator-driven (`QbListExecutor`). |
| `list_vendors` | same as `list_customers` | `{ status, rows, count, rawSpilledTo }` | — |
| `list_accounts` | `{ activeStatus?, name?, nameMatch? }` | `{ status, rows, count, rawSpilledTo }` | — |
| `list_items` | `{ activeStatus?, name?, nameMatch? }` | `{ status, rows, count, rawSpilledTo }` | Item polymorphism (`ItemServiceRet`/`ItemInventoryRet`/…) normalized by the parser (`type` field on each row). |
| `list_invoices` | `{ fromDate?, toDate?, dateMacro?, entity?, includeLineItems?: bool }` — `dateMacro` is mutually exclusive with `fromDate`/`toDate` | `{ status, rows, count, rawSpilledTo }` | Header-level rows by default; `includeLineItems:true` opts into line detail (`IncludeLineItems` element name is a Phase-9 re-pin candidate). |
| `list_bills` | `{ fromDate?, toDate?, dateMacro?, entity? }` | `{ status, rows, count, rawSpilledTo }` | — |
| `list_payments` | `{ fromDate?, toDate?, dateMacro?, entity? }` | `{ status, rows, count, rawSpilledTo }` | — |
| `get_transaction` | `{ txnId? \| refNumber? }` — exactly one; optional `txnType?` | `{ status, matches: [...], count, ambiguous: bool, lite: true }` | `RefNumber` is non-unique → always a list; never collapses. `lite:true` = header-level only; use `list_*` for line detail. Query element names are Phase-9 re-pin candidates. |
| `run_query` | `{ entity: <one of the read-only whitelist>, filters?: { <simple child-element key>: value \| [values] \| {nested} } }` | `{ entity, status, rows, count, rawSpilledTo }` | Whitelist (in source): Employee, OtherName, SalesRep, Class, Term, PriceLevel, PaymentMethod, ShipMethod, Currency, SalesTaxCode, Vehicle, SalesReceipt, Estimate, PurchaseOrder, CreditMemo, SalesOrder, Deposit, Check, BillPaymentCheck, BillPaymentCreditCard, CreditCardCharge, CreditCardCredit, JournalEntry, InventoryAdjustment, TimeTracking, VendorCredit, ItemReceipt, Customer, Vendor, Item, Account, Invoice, Bill, ReceivePayment, Transaction, ToDo, Company, Host, Preferences. Filter keys are validated (no `/`, `<`, `>`, `:`, whitespace). Company/Host/Preferences are single-shot; everything else paginates. Prefer the dedicated ops where one exists. |

**Write ops (dry-run-gated; `403` when `AllowWrites=false`; refuse `currencyRef`/`exchangeRate` up front):**

| Op | Args (key ones — header-level unless noted) | Notes |
|----|---------------------------------------------|-------|
| `create_customer` | `name` (required), `isActive?`, `parentRef?` ({listID?\|fullName?}), `companyName?`, `salutation?`, `firstName?`, `middleName?`, `lastName?`, `suffix?`, `billAddress?` (dict: addr1/addr2/city/state/postalCode/country/…), `shipAddress?`, `printAs?`, `phone?`, `mobile?`, `pager?`, `altPhone?`, `fax?`, `email?`, … plus more pass-through fields | Maps to `CustomerAdd`. Refs accept `{listID}` or `{fullName}`. |
| `create_vendor` | `name` (required), `isActive?`, `companyName?`, `salutation?`/`firstName?`/`middleName?`/`lastName?`/`suffix?`, `vendorAddress?` (dict), `phone?`/`mobile?`/`pager?`/`altPhone?`/`fax?`/`email?`/`contact?`/`altContact?`/`nameOnCheck?`/`accountNumber?`/`notes?`, `vendorTypeRef?`, `terms?` ({listID?\|fullName?}) | Maps to `VendorAdd`. |
| `create_invoice` | `customerRef` (required, {listID?\|fullName?}), `lines` (required, list of line dicts), `classRef?`, `arAccountRef?`, `templateRef?`, `txnDate?`, `refNumber?`, `billAddress?`/`shipAddress?` (dicts), `isPending?`, `poNumber?`, `terms?`, `dueDate?`, `salesRepRef?`, `fob?`, `shipDate?`, `shipMethodRef?`, `itemSalesTaxRef?`, `memo?`, `customerMsgRef?`, `isToBePrinted?`/`isToBeEmailed?`/`isTaxIncluded?`, `customerSalesTaxCodeRef?`, `other?` | Maps to `InvoiceAdd` + `InvoiceLineAdd`s. Line dict shape (item/desc/qty/rate/amount/…) is summarized — see `WriteOpHelpers` line builders; flag as "line shape per `CreateInvoiceOp.cs`". |
| `create_bill` | `vendorRef` (required), `apAccountRef?`, `txnDate?`, `dueDate?`, `refNumber?`, `terms?`, `memo?`, `isTaxIncluded?`, `salesTaxCodeRef?`, `expenseLines?` (list), `itemLines?` (list) — at least one line list | Maps to `BillAdd` with `ExpenseLineAdd`/`ItemLineAdd`s. |
| `create_check` | `accountRef` (required, the bank account), `payeeEntityRef?`, `refNumber?`, `txnDate?`, `memo?`, `address?` (dict), `isToBePrinted?`, `isTaxIncluded?`, `salesTaxCodeRef?`, `expenseLines?` (list), `itemLines?` (list) | Maps to `CheckAdd`. |
| `receive_payment` | `customerRef` (required), `arAccountRef?`, `txnDate?`, `refNumber?`, `totalAmount?` (decimal), `paymentMethodRef?`, `memo?`, `depositToAccountRef?`, `isAutoApply?` (bool) **or** `appliedTo?` (list of `{txnID, paymentAmount}`) | Maps to `ReceivePaymentAdd`. Pre-flight checks `appliedTo` amounts vs `totalAmount` when not auto-applying. |
| `create_journal_entry` | `debits` (required, list of `{accountRef, amount, memo?, entityRef?, classRef?}`-ish), `credits` (required, list, same shape), `txnDate?`, `refNumber?`, `memo?`, `isAdjustment?` | Maps to `JournalEntryAdd` with `JournalDebitLine`/`JournalCreditLine`s. **Rejected at pre-flight if debits ≠ credits.** Debit/credit line shape is summarized — see `CreateJournalEntryOp.cs`. |
| `mod` | `entity` (required: `customer`\|`vendor`\|`invoice`\|`bill`\|`check`), `ref` (required, `{txnID?\|listID?\|fullName?}` — the object to update; the `EditSequence` is fetched from a **fresh read** server-side), `fields` (required, dict of **header-level** fields to set — full-replace semantics on the header) | One generic op (no `mod_customer` etc.). `mod` is **header-level only** in v1; refuses `currencyRef`/`exchangeRate` (in both args and `fields`). A stale `EditSequence` → QuickBooks `statusCode=3200` (severity Error) → **returned verbatim in `result.status`, audited once, never retried**. The exact `fields` keys per entity are summarized — see `ModOp.cs`; flag the table accordingly. |

### Safe-write workflow (the verbatim text `SKILL.md` must contain — match spec §5)
```
A write op is NEVER executed without first completing steps 1-4.

1. DRY RUN. Call client.dryrun(opName, args). It returns
   { qbXml, summary, preFlight: [{name, ok, detail}], resolvedReferences, allowWrites }
   with ZERO side effects (it works even when AllowWrites is false).
2. SHOW THE USER:
   - the qbXml (byte-exact — the request that would be sent),
   - the plain-English summary,
   - each preFlight check and whether it passed (ok),
   - whether allowWrites is true (if false, the execute in step 4 will 403 — the
     operator must deliberately set Safety:AllowWrites=true on the service first).
3. GET EXPLICIT CONFIRMATION. The user must say, in effect, "yes, execute this."
   No silent auto-apply, ever. If a preFlight check failed, do not proceed — fix
   the args and dry-run again.
4. EXECUTE. Only now call client.op(opName, args). It returns { ...result... } with
   the embedded status (statusCode/statusSeverity/statusMessage). A 403 means
   AllowWrites is false on the service.
5. REPORT. Show the user the result, including the status, and note that the write
   was recorded in the audit log on the QuickBooks host.

For `mod`: the dry-run shows the before/after header-field diff and the EditSequence
it will use (fetched from a fresh read). If the execute comes back with statusCode 3200
(stale EditSequence, severity Error), surface it verbatim — do NOT auto-retry. The user
does a fresh dry-run (which re-reads the current EditSequence) and confirms again.

For destructive operations (Delete/Void): there is no wrapped op. Use raw qbXML via
client.qbxml("<...>") with the user's explicit confirmation, and only with
AllowWrites=true.
```

### Skill invocation pattern (how `SKILL.md` tells Claude to actually run things)
Two patterns, both shown in `SKILL.md`:
- **Canned operations** → run an example script: `python quickbooks/clients/examples/pull_pnl.py` (after `pip install -r quickbooks/clients/requirements.txt` once and `cp quickbooks/clients/.env.sample quickbooks/clients/.env` + filling it in).
- **Ad-hoc** → a tiny inline script (run from `quickbooks/clients/`):
  ```bash
  cd quickbooks/clients && python -c "
  from qb_client import QbClient
  c = QbClient.from_env()
  print(c.health())
  print(c.op('list_customers', {'activeStatus': 'Active', 'name': 'Acme'}))
  "
  ```
  or write a throwaway `.py` and run it. First call should always be `c.health()` — confirm `status == 'healthy'` and check `allowWrites` before considering any write.

### `quickbooks-ci.yml` — the `python-client` job to add
```yaml
# add as a second job in .github/workflows/quickbooks-ci.yml
# and add quickbooks/clients/** to the on.push.paths / on.pull_request.paths lists
  python-client:
    runs-on: windows-latest        # has Python preinstalled; ubuntu-latest would also work — keep windows-latest for parity
    defaults:
      run:
        working-directory: quickbooks/clients
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - name: Install
        run: pip install -r requirements.txt
      - name: Test
        run: python -m pytest tests/ -q
```
- Recommend a **second job in the same file** (simpler than a second workflow file). It runs in parallel with `build-test` — no `needs:` (independent).
- Update the `paths:` filters to also trigger on `quickbooks/clients/**` (so the Python job runs when the client changes; the existing `.github/workflows/quickbooks-ci.yml` self-trigger covers workflow edits). The `.NET` job's path filter (`quickbooks/QbConnectService/**`) stays — GitHub Actions runs all jobs whose workflow file matched at least one changed path; both jobs are cheap so over-triggering is fine, or scope each step (not worth it).
- `actions/setup-python@v5` is current (v5 is the live major as of 2026). `windows-latest` ships Python — confirmed (the runner image preinstalls multiple Python versions; `setup-python` activates 3.12).

## Dev tooling hardening (DEV-01 / DEV-02) — what's actually left

**`run-codex-phase.ps1` — it works (7 phases deep).** Already has: the repo-root resolve, the branch guard (`quickbooks/direct-sdk-integration-2026-05-11`), the phase-dir glob (`^0*$Phase-` / `^$nn-`), the `-DryRun` flag, the `-ExtraInstructions` param, the `codex exec --dangerously-bypass-approvals-and-sandbox -C <repo> -` invocation (prompt via stdin), the HARD RULES prompt (stay-on-branch, scoped `git add`, no `git add -A`, no `git reset --hard`, no nested `git init`, append-only `.gitignore`, the amend / `fix(...)` no-duplicate-`feat()`-title rule, the GitNexus-N/A note, the Client-Portal-rules-irrelevant note), error handling on a non-zero exit, and a `git log --oneline -10` at the end. **Likely-needed polish (light):**
- Remove the `.SYNOPSIS`/`.DESCRIPTION` "Bootstrap version. Phase 8 (DEV-02) hardens it." line — it's now hardened.
- Optionally: the HARD RULES still say "you are CREATING brand-new files in `quickbooks/QbConnectService/`" — Phase 8 also creates `quickbooks/clients/`, `.claude/skills/quickbooks-accounting/`, `.github/workflows/`; the "Only create/modify files under …" list already covers those, but the GitNexus-N/A paragraph's parenthetical example could be generalized. Minor; don't over-edit.
- Consider documenting `pwsh` vs `powershell.exe` (the script is `#!/usr/bin/env pwsh` and uses PS7 syntax; that's correct — `pwsh quickbooks/dev/run-codex-phase.ps1 -Phase N`).
- That's about it. **Do not gold-plate.** No new params, no fancy logging.

**`MULTI-LLM.md` — bring to "final".** Currently a 56-line "bootstrap version" doc. Hardening = make it accurately describe the now-proven loop so a new contributor can run a phase:
- Remove the `> **Status:** bootstrap version.` banner; replace with a one-line "this is the live pipeline; 8 phases built this way."
- The per-phase loop block is correct (`/gsd:plan-phase N` → `pwsh quickbooks/dev/run-codex-phase.ps1 -Phase N` → `/gsd:code-review`) — keep, maybe add the plan-checker step explicitly and the "address review findings, then `/gsd:plan-phase (N+1)`" loop-back.
- The `run-codex-phase.ps1` description (steps 1-4) is slightly stale ("`codex exec --full-auto -C <repo-root> "<prompt>"`") — update to the actual `codex exec --dangerously-bypass-approvals-and-sandbox -C <repo> -` (prompt via stdin) and explain *why* the bypass (the `--full-auto` sandbox came up read-only on this box; the HARD RULES bound the blast radius). The script's own comment block already has this text — mirror it.
- The DeepSeek-CC review recipe is present and correct (`$env:ANTHROPIC_BASE_URL = "https://api.deepseek.com/anthropic"`, `ANTHROPIC_AUTH_TOKEN`, `ANTHROPIC_MODEL = "deepseek-reasoner"`, then `claude` → "review the last commit…"; unset to revert; don't run GSD agents under DeepSeek) — keep; maybe note `claude-code-router` as the finer-grained alternative (already mentioned).
- The Guardrails section (shared working tree with unrelated India HR work; stay on branch; scoped `git add`; never `git checkout`/`git reset --hard`; QuickBooks code under `quickbooks/` + the skill under `.claude/skills/quickbooks-accounting/`) — keep; this is the durable rule.
- Add a short "Conventions" subsection documenting the proven habits: commit-per-task with conventional-commit prefixes (`feat(NN-MM)`, `test(...)`, `ci(...)`, `docs(NN-MM)`); the final `docs(N-NN)` commit updates the phase plan's checkboxes + the phase SUMMARY + ROADMAP/REQUIREMENTS/STATE; no duplicate-titled `feat()` commits (amend or use `fix(...)`); the "every phase reviewed at 100/100" bar; constructed-qbXML fixtures carry a Phase-9 re-pin comment.
- A pointer to where the phase artifacts live (`.planning/phases/NN-slug/NN-MM-{RESEARCH,PLAN,SUMMARY}.md`).

**The bar:** a new contributor reading `MULTI-LLM.md` understands the pipeline (who does what, why split this way) and can run a phase (`/gsd:plan-phase` → `run-codex-phase.ps1` → `/gsd:code-review`). It is dev tooling, not product — clear and accurate, not exhaustive.

## State of the Art

| Old approach | Current approach | Notes |
|--------------|------------------|-------|
| `requests` `retries` via a manual loop | `urllib3.util.retry.Retry` on `HTTPAdapter` (urllib3 2.x) | The `Retry` API is stable; `allowed_methods` (renamed from `method_whitelist` long ago) is the param. |
| `requests-mock` | `responses` (getsentry/responses) | Both current and maintained; `STACK.md` picked `responses`. 0.25.x / 0.26.0 are current. |
| `pytest.ini` / `setup.cfg` for config | `pyproject.toml [tool.pytest.ini_options]` | pytest ≥ 6 reads `pyproject.toml`; `pythonpath` config key (pytest ≥ 7) solves the "tests/ can't import the module above" problem without `conftest.py` hacks. |
| `actions/setup-python@v4` | `actions/setup-python@v5` | v5 is the live major (2026). |
| Claude skills only in `~/.claude/skills/` | repo-local `.claude/skills/<name>/` | Claude Code discovers skills in the project's `.claude/skills/` too; the spec puts `quickbooks-accounting` in the repo so it travels with the code (the existing repo has `india-disciplinary-process`, `foxit-esign`, etc. as repo-local skills — same pattern). |

**Deprecated/outdated:** `requests`' `get_connection` is deprecated in `requests>=2.32.0` in favour of `get_connection_with_tls_context` — irrelevant here (we don't subclass `HTTPAdapter` beyond `max_retries`). `Retry`'s `method_whitelist` was renamed `allowed_methods` (use `allowed_methods`).

## Open Questions

1. **Exact patch pins for `requirements.txt`.**
   - Known: `requests` 2.32.x current patch is 2.32.5; `urllib3` 2.2.x is current 2.x; `python-dotenv` 1.x current is ~1.0.1 (1.1.x/1.2.x also exist); `pytest` 8.x current is ~8.3.4 (9.x exists); `responses` 0.25.x current is ~0.25.7 (0.26.0 exists).
   - Unclear: whether to pin exact patches or minor-range (`requests==2.32.*`). The design spec said "plain pinned" — recommend **exact patches** (reproducible) but minor-range (`requests==2.32.*`, etc.) is acceptable and what `STACK.md`'s sketch used. The planner/Codex should take the exact picks above or run `pip index versions <pkg>` at build time.
   - Recommendation: exact pins as listed in "Installation"; if any is yanked, the next patch in the same minor.

2. **`op()` signature: `args: dict|None` vs `**kwargs`.**
   - Known: the API body is a JSON object; some keys (`fromDate`) are identifier-safe but nested args are dicts (`customerRef={"fullName": ...}`).
   - Unclear: ergonomics preference.
   - Recommendation: `op(name, args: dict|None = None)` (dict) — matches the body shape, handles nested dicts, no key-name limits. If the planner prefers `**kwargs`, that's defensible for the simple read ops but breaks on nested args; the dict is the safer call. (Could offer both: `op(name, args=None, **kwargs)` merging — but that's over-design for v1.)

3. **`mod` `fields` keys per entity, journal-entry / invoice line-dict shapes.**
   - Known: read from `ModOp.cs` / `CreateJournalEntryOp.cs` / `CreateInvoiceOp.cs` (header-level fields verified; nested line/field shapes are there but summarized in this doc).
   - Unclear: whether to enumerate every key in `SKILL.md`'s catalog or summarize + point at the source.
   - Recommendation: summarize in the table (header-level keys listed; "line/field shapes per `<File>.cs`"), and have `SKILL.md` say the authoritative source is `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/*.cs`. The planner can have a task "read the write-op classes and fill the catalog table precisely" if 100/100 demands full enumeration — but a summarized-with-pointer catalog that's *accurate* (no invented keys) is the bar.

4. **CI: same-file second job vs separate workflow file.**
   - Known: both work; the existing file is `.github/workflows/quickbooks-ci.yml`.
   - Recommendation: **second job in the same file** + add `quickbooks/clients/**` to the `paths:` filters. Simpler, one place to look. (A separate `quickbooks-client-ci.yml` is the alternative — slightly cleaner path-filtering but more files.)

5. **Whether `from_env()` should also support a default `.env` path discovery.**
   - Known: `python-dotenv` `load_dotenv()` walks up from CWD looking for `.env` by default.
   - Recommendation: `from_env()` calls `load_dotenv(dotenv_path)` — `dotenv_path=None` lets `python-dotenv` do its default walk (finds `quickbooks/clients/.env` if you run from there or below); the examples/skill run scripts from `quickbooks/clients/` so the default works. Don't hardcode the path; the optional `dotenv_path` param covers the rest.

## Suggested ordered task breakdown (atomic, one commit each)

The planner can compress to 4 — the natural seams:

1. **`feat(08-01): qb_client.py + .env.sample + requirements.txt + test config + tests`** — `quickbooks/clients/qb_client.py` (the `QbClient` class + `QbApiError` + `from_env()` per Pattern 1), `quickbooks/clients/.env.sample` (`QB_API_BASE_URL=https://localhost:8443`, `QB_API_TOKEN=REPLACE-WITH-BEARER-TOKEN`, `QB_VERIFY_TLS=false`, `QB_TIMEOUT=60`, `QB_RETRIES=3` — with comments), `quickbooks/clients/requirements.txt` (the 5 pins), `quickbooks/clients/pyproject.toml` (`[tool.pytest.ini_options]` `testpaths`/`pythonpath`), `quickbooks/clients/tests/test_qb_client.py` (+ optional `conftest.py`) covering: health sends bearer + returns dict, `op` returns `result`, unknown op → `QbApiError(404, "Unknown op")`, `qbxml` returns raw text, `dryrun` returns `dryRun`, GET retries on 503-then-200, write POST does NOT retry on 503 (exactly one call). **Verify:** `pip install -r quickbooks/clients/requirements.txt && python -m pytest quickbooks/clients/tests/ -q` green.
2. **`feat(08-01): client examples + clients README`** — `quickbooks/clients/examples/{pull_pnl.py, list_invoices.py, create_customer_dryrun.py}` (each with a docstring + `__main__` guard + `QbClient.from_env()`; `create_customer_dryrun.py` calls `dryrun(...)` ONLY), `quickbooks/clients/README.md` (set up `.env`, `pip install`, run the client/examples — short). **Verify:** `pytest` still green; `python -m py_compile quickbooks/clients/examples/*.py`.
3. **`feat(08-01): quickbooks-accounting Claude skill`** — `tech-legal/.claude/skills/quickbooks-accounting/SKILL.md` (frontmatter `name: quickbooks-accounting` + a trigger `description:` mentioning QuickBooks/accounting/"pull the P&L"/"create an invoice in QuickBooks"; quick-start; the op-catalog table (20 ops); the 5-step safe-write workflow verbatim; the invocation patterns; pointers to the two references) + `references/qbxml-cheatsheet.md` (raw-qbXML envelope: `<?xml?>` decl + `<?qbxml version="16.0"?>` PI + `<QBXML><QBXMLMsgsRq onError="stopOnError">…</QBXMLMsgsRq></QBXML>`; common `*QueryRq`/`*AddRq`/`*ModRq` shapes; iterators (`iterator="Start"`/`"Continue"`, `iteratorID`, `iteratorRemainingCount`); status codes incl. `3200` stale-`EditSequence`; "non-zero `statusCode` is a business outcome, not an HTTP error"; mark element names MEDIUM-confidence / Phase-9 re-pin) + `references/setup-and-troubleshooting.md` (failure modes: `/api/health status != "healthy"` → COM session can't activate → check SDK install / integrated-app auth on the host; `401` → wrong `QB_API_TOKEN`; `403 "Writes disabled"` → `Safety:AllowWrites=false`; `503` with `qbErrorCode` → a QuickBooks COM/HRESULT error → see `QbErrors`; `409 "QuickBooks busy"`; the self-signed-cert `QB_VERIFY_TLS=false` note; forward-reference "(arrives in Phase 9)" for `quickbooks/QbConnectService/README.md` + `register-integrated-app.md`, and point at `quickbooks/dev/MULTI-LLM.md`). **Verify:** files exist; `SKILL.md` has the frontmatter, the 5-step workflow, and all 20 ops in the catalog (manual / a tiny grep check).
4. **`docs(08-01): harden MULTI-LLM.md + polish run-codex-phase.ps1 + add Python CI job + .gitignore`** — update `quickbooks/dev/MULTI-LLM.md` (remove "bootstrap version"; document the proven loop, the `--dangerously-bypass` rationale, the `docs(N-NN)` final-commit + no-dup-title conventions, the DeepSeek recipe stays); light polish of `quickbooks/dev/run-codex-phase.ps1` (drop the "bootstrap"/"DEV-02 hardens it" lines; keep everything else); add the `python-client` job to `.github/workflows/quickbooks-ci.yml` + add `quickbooks/clients/**` to the `paths:` filters; append `.pytest_cache/` to `.gitignore`. **Verify:** `pwsh quickbooks/dev/run-codex-phase.ps1 -Phase 8 -DryRun` still works; the workflow YAML parses; `pytest` green; `dotnet test quickbooks/QbConnectService/QbConnectService.sln -c Release` still 255/255 (sanity — unchanged).
5. *(or fold into 4)* **`docs(08-01): phase summary + roadmap/requirements/state`** — `.planning/phases/08-python-client-skill-tooling/08-01-SUMMARY.md`, tick the Phase-8 plan checkboxes, update ROADMAP.md (Phase 8 → complete), REQUIREMENTS.md (CLIENT-01..03, DEV-01,02 → done), STATE.md (Phase 8 complete; current focus → Phase 9). (Per the established pattern, Codex commits its own SUMMARY + checkbox + roadmap/req/state updates in the final `docs(08-01)` commit.)

**Note for the reviewer:** Phase 8 changes no .NET — the `dotnet` suite stays at 255/255 trivially; the new evidence is `pytest quickbooks/clients/tests/` green + the skill being well-formed Markdown with an accurate op catalog + the unambiguous 5-step safe-write workflow.

## Sources

### Primary (HIGH confidence)
- **Phase 5-7 source code** (read 2026-05-12): `quickbooks/QbConnectService/src/QbConnectService/Api/{HealthEndpoints,OpsEndpoints,QbXmlEndpoints,BearerAuthMiddleware,ApiExceptionHandler}.cs` — the exact API contract, error shapes, route names. `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/Qb/Ops/*.cs` (`ReportOp`, `ListInvoicesOp`, `ListCustomersOp`, `GetTransactionOp`, `RunQueryOp`, `CompanyPreferencesOp`, `ReadOpBase`, `IReadOp`, `IWriteOp`, `OpRegistry`, and the write ops via grep) — the op catalog arg keys + return shapes.
- **`quickbooks/dev/{MULTI-LLM.md, run-codex-phase.ps1}`** (read 2026-05-12) — current state of the dev tooling to harden.
- **`.github/workflows/quickbooks-ci.yml`**, **`.gitignore`** (read 2026-05-12; `git check-ignore` confirmed `quickbooks/clients/.env`, `__pycache__/`, `*.pyc` already ignored).
- **Design spec** `docs/superpowers/specs/2026-05-11-quickbooks-direct-sdk-accounting-design.md` §1/§5/§6/§9 — the layout, the write-safety model, the `.env` keys, the portability story.
- **Project research** `.planning/research/STACK.md` (Python-client section), `SUMMARY.md` — the named stack and the build-order context.
- **`.planning/{PROJECT,ROADMAP,REQUIREMENTS,STATE}.md`** — Phase 8 scope (CLIENT-01..03, DEV-01,02), success criteria, the 100/100 quality bar, the Phase 1-7 inventory.

### Secondary (MEDIUM confidence)
- WebSearch 2026-05-12: PyPI / GitHub release info for `requests` (2.32.5 current 2.32.x; 2.33.x exists), `urllib3` (2.x), `responses` (0.25.7 / 0.26.0), `pytest` (8.3.4 / 9.x), `python-dotenv` (1.0.1 / 1.x) — used only for current version numbers; the APIs themselves are stable and well-known. `actions/setup-python@v5` is the current major.

### Tertiary (LOW confidence)
- None relied on for any prescriptive claim.

## Metadata

**Confidence breakdown:**
- Standard stack (Python libs): HIGH — `STACK.md` named them; versions cross-checked against PyPI 2026-05; all mutually compatible on Python 3.10-3.12; APIs (`Retry`, `responses` matchers, `pyproject.toml` pytest config) are stable.
- Architecture / `QbClient` surface: HIGH — the API contract is read directly from the Phase 5-7 source, not inferred; the retry-policy decision is reasoned (idempotency).
- Op catalog: HIGH on op names + read-op arg keys (read from source); MEDIUM on write-op nested line/field shapes (summarized — flagged in the table; the source files are the authority).
- Skill structure / safe-write workflow: HIGH — driven by spec §5/§6 and the actual op classes.
- Dev-tooling hardening: HIGH — both files read; the "what's left" is small and concrete.
- CI: HIGH — `windows-latest` ships Python; `setup-python@v5` current; second-job-in-same-file is the simple, conventional choice.

**Research date:** 2026-05-12
**Valid until:** ~2026-06-12 (30 days — stable stack; the only thing that drifts is library patch numbers, which the planner/Codex can re-check with `pip index versions` at build time).
