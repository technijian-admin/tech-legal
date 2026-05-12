"""List invoices for the current month.

Run from quickbooks/clients/ after `pip install -r requirements.txt` and
copying `.env.sample` to `.env`.
"""
from __future__ import annotations

import json

from qb_client import QbClient


if __name__ == "__main__":
    client = QbClient.from_env()
    health = client.health()
    print(json.dumps({"status": health.get("status"), "allowWrites": health.get("allowWrites")}, indent=2))

    # `fromDate`/`toDate` are the alternative and are mutually exclusive with `dateMacro`.
    result = client.op("list_invoices", {"dateMacro": "ThisMonth"})
    print(json.dumps({"count": result.get("count"), "rows": result.get("rows")}, indent=2, default=str))
