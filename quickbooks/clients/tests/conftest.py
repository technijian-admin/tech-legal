import pytest

from qb_client import QbClient

BASE_URL = "https://qb.example:8443"
TOKEN = "test-token"


@pytest.fixture
def base_url() -> str:
    return BASE_URL


@pytest.fixture
def token() -> str:
    return TOKEN


@pytest.fixture
def client(base_url: str, token: str) -> QbClient:
    return QbClient(base_url, token, verify_tls=False, retries=2)
