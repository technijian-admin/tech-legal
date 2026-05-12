import responses
from responses import matchers

from qb_client import QbApiError


def _client(base_url, token, client):
    return client


@responses.activate
def test_health_sends_bearer_and_returns_dict(base_url, token, client):
    payload = {"status": "healthy", "allowWrites": False, "sdkVersion": "16.0"}
    responses.get(
        f"{base_url}/api/health",
        json=payload,
        status=200,
        match=[matchers.header_matcher({"Authorization": f"Bearer {token}"})],
    )

    assert _client(base_url, token, client).health() == payload


@responses.activate
def test_op_returns_result(base_url, client):
    responses.post(
        f"{base_url}/api/ops/company_info",
        json={
            "op": "company_info",
            "result": {"companyName": "Acme", "status": {"statusCode": "0"}},
        },
        status=200,
    )

    result = client.op("company_info")

    assert result["companyName"] == "Acme"


@responses.activate
def test_unknown_op_raises_qbapierror_with_problemdetails(base_url, client):
    responses.post(
        f"{base_url}/api/ops/nope",
        json={"status": 404, "title": "Unknown op", "detail": "No op named 'nope'."},
        status=404,
        content_type="application/problem+json",
    )

    try:
        client.op("nope")
    except QbApiError as error:
        assert error.status_code == 404
        assert error.title == "Unknown op"
    else:
        raise AssertionError("Expected QbApiError")


@responses.activate
def test_qbxml_returns_raw_text(base_url, client):
    responses.post(
        f"{base_url}/api/qbxml",
        body="<QBXML>...</QBXML>",
        status=200,
        content_type="application/xml",
    )

    assert client.qbxml("<QBXML>...</QBXML>").startswith("<QBXML")


@responses.activate
def test_dryrun_returns_dryrun_block(base_url, client):
    responses.post(
        f"{base_url}/api/ops/create_customer/dryrun",
        json={
            "op": "create_customer",
            "dryRun": {
                "qbXml": "...",
                "summary": "Create customer 'Example Co'.",
                "preFlight": [{"name": "allowWrites", "ok": False, "detail": "..."}],
                "resolvedReferences": {},
                "allowWrites": False,
            },
        },
        status=200,
    )

    result = client.dryrun("create_customer", {"name": "Example Co"})

    assert result["summary"].startswith("Create customer")


@responses.activate
def test_get_retries_on_503_then_succeeds(base_url, client):
    responses.get(f"{base_url}/api/health", json={"error": "warming up"}, status=503)
    responses.get(f"{base_url}/api/health", json={"status": "healthy"}, status=200)

    assert client.health()["status"] == "healthy"


@responses.activate
def test_write_op_post_does_not_retry_on_503(base_url, client):
    responses.post(
        f"{base_url}/api/ops/create_customer",
        json={"status": 503, "title": "QuickBooks unavailable"},
        status=503,
        content_type="application/problem+json",
    )

    try:
        client.op("create_customer", {"name": "Example Co"})
    except QbApiError as error:
        assert error.status_code == 503
    else:
        raise AssertionError("Expected QbApiError")

    assert len(responses.calls) == 1
