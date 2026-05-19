"""HTTPS client for the QbConnectService REST API.

This client talks to QbConnectService over HTTPS only. It has no QuickBooks
SDK dependency itself. Every request sends ``Authorization: Bearer <token>``.
Retries are conservative by design: GET requests retry on transient transport
and 502/503/504 failures, and the side-effect-free ``/dryrun`` POST uses its
own retrying session. Write-capable POSTs never auto-retry.
"""
from __future__ import annotations

import os
from typing import Any

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

DEFAULT_TIMEOUT = 60.0
DEFAULT_RETRIES = 3
_RETRY_STATUS = (502, 503, 504)
_VERIFY_FALSE = {"0", "false", "no", "off"}
_VERIFY_TRUE = {"", "1", "true", "yes", "on"}


class QbApiError(RuntimeError):
    """Raised when QbConnectService returns a non-success HTTP response."""

    def __init__(
        self,
        status_code: int,
        title: str | None = None,
        detail: str | None = None,
        qb_error_code: str | None = None,
        body: Any = None,
    ) -> None:
        self.status_code = status_code
        self.title = title
        self.detail = detail
        self.qb_error_code = qb_error_code
        self.body = body

        message = f"{status_code} {title or ''}".strip()
        if detail:
            message += f": {detail}"
        if qb_error_code:
            message += f" [{qb_error_code}]"
        super().__init__(message)


class QbClient:
    """Thin requests.Session wrapper over the QbConnectService REST API."""

    def __init__(
        self,
        base_url: str,
        token: str,
        *,
        verify_tls: bool | str = True,
        timeout: float = DEFAULT_TIMEOUT,
        retries: int = DEFAULT_RETRIES,
        session: requests.Session | None = None,
        default_company: str | None = None,
    ) -> None:
        if not base_url:
            raise ValueError("base_url is required")
        if not token:
            raise ValueError("token is required")

        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.retries = retries
        self.verify_tls = verify_tls
        self.default_company = default_company
        self._session = session or requests.Session()
        self._session.headers["Authorization"] = f"Bearer {token}"

        retry = Retry(
            total=retries,
            connect=retries,
            read=retries,
            status=retries,
            backoff_factor=0.5,
            status_forcelist=_RETRY_STATUS,
            allowed_methods=frozenset({"GET"}),
            raise_on_status=False,
        )
        adapter = HTTPAdapter(max_retries=retry)
        self._session.mount("https://", adapter)
        self._session.mount("http://", adapter)

    @classmethod
    def from_env(cls, *, dotenv_path: str | None = None) -> "QbClient":
        try:
            from dotenv import load_dotenv
        except ImportError:
            load_dotenv = None

        if load_dotenv is not None:
            load_dotenv(dotenv_path)

        base_url = os.environ.get("QB_API_BASE_URL")
        token = os.environ.get("QB_API_TOKEN")
        if not base_url or not token:
            raise RuntimeError(
                "QB_API_BASE_URL and QB_API_TOKEN must be set in the environment or quickbooks/clients/.env"
            )

        verify_raw = os.environ.get("QB_VERIFY_TLS", "true").strip()
        verify_key = verify_raw.lower()
        if verify_key in _VERIFY_FALSE:
            verify_tls: bool | str = False
        elif verify_key in _VERIFY_TRUE:
            verify_tls = True
        else:
            verify_tls = verify_raw

        timeout = float(os.environ.get("QB_TIMEOUT", str(DEFAULT_TIMEOUT)))
        retries = int(os.environ.get("QB_RETRIES", str(DEFAULT_RETRIES)))
        default_company = os.environ.get("QB_DEFAULT_COMPANY") or None
        return cls(
            base_url,
            token,
            verify_tls=verify_tls,
            timeout=timeout,
            retries=retries,
            default_company=default_company,
        )

    def with_company(self, company: str) -> "QbClient":
        """Return a shallow clone of this client scoped to the given company key.

        Useful when working across multiple .QBW files - keeps each request scoped
        without having to thread `company=` through every call site.
        """
        clone = QbClient(
            self.base_url,
            token="placeholder",  # session below carries the real Authorization header
            verify_tls=self.verify_tls,
            timeout=self.timeout,
            retries=self.retries,
            session=self._session,
            default_company=company,
        )
        return clone

    def health(self) -> dict[str, Any]:
        return self._get("/api/health")

    def ops(self) -> list[str]:
        payload = self._get("/api/ops")
        return payload["ops"]

    def qbxml(self, raw_xml: str, *, company: str | None = None) -> str:
        response = self._session.post(
            f"{self.base_url}/api/qbxml",
            data=raw_xml.encode("utf-8"),
            headers={"Content-Type": "application/xml"},
            params=self._company_params(company),
            timeout=self.timeout,
            verify=self.verify_tls,
        )
        self._raise_for_status(response)
        return response.text

    def op(self, name: str, args: dict[str, Any] | None = None, *, company: str | None = None) -> Any:
        response = self._session.post(
            f"{self.base_url}/api/ops/{name}",
            json=args or {},
            params=self._company_params(company),
            timeout=self.timeout,
            verify=self.verify_tls,
        )
        self._raise_for_status(response)
        return response.json()["result"]

    def dryrun(self, name: str, args: dict[str, Any] | None = None, *, company: str | None = None) -> dict[str, Any]:
        response = self._post_retryable(
            f"{self.base_url}/api/ops/{name}/dryrun",
            json=args or {},
            company=company,
        )
        self._raise_for_status(response)
        return response.json()["dryRun"]

    def _company_params(self, company: str | None) -> dict[str, str] | None:
        target = company or self.default_company
        return {"company": target} if target else None

    def _get(self, path: str) -> Any:
        response = self._session.get(
            f"{self.base_url}{path}",
            timeout=self.timeout,
            verify=self.verify_tls,
        )
        self._raise_for_status(response)
        return response.json()

    def _post_retryable(
        self,
        url: str,
        *,
        json: dict[str, Any],
        company: str | None = None,
    ) -> requests.Response:
        retry = Retry(
            total=self.retries,
            connect=self.retries,
            read=self.retries,
            status=self.retries,
            backoff_factor=0.5,
            status_forcelist=_RETRY_STATUS,
            allowed_methods=frozenset({"GET", "POST"}),
            raise_on_status=False,
        )
        with requests.Session() as session:
            session.headers.update(self._session.headers)
            adapter = HTTPAdapter(max_retries=retry)
            session.mount("https://", adapter)
            session.mount("http://", adapter)
            return session.post(
                url,
                json=json,
                params=self._company_params(company),
                timeout=self.timeout,
                verify=self.verify_tls,
            )

    @staticmethod
    def _raise_for_status(response: requests.Response) -> None:
        if response.status_code < 400:
            return

        title = None
        detail = None
        qb_error_code = None
        body: Any = response.text
        content_type = response.headers.get("Content-Type", "")
        if "json" in content_type:
            try:
                body = response.json()
            except ValueError:
                body = response.text
            else:
                if isinstance(body, dict):
                    title = body.get("title")
                    detail = body.get("detail")
                    qb_error_code = body.get("qbErrorCode")

        raise QbApiError(response.status_code, title, detail, qb_error_code, body)
