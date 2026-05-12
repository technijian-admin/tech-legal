"""Pull a Profit & Loss report for this fiscal year.

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

    result = client.op("report", {"type": "ProfitAndLoss", "dateMacro": "ThisFiscalYear"})
    print(json.dumps(result.get("report"), indent=2, default=str))
