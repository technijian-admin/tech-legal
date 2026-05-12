"""Preview a customer create request without executing it.

This is a DRY RUN ONLY - it has zero side effects and does NOT create
anything. To actually create a customer you would follow the 5-step safe-write
workflow in the quickbooks-accounting skill: dry-run -> show
qbXml/summary/preFlight -> explicit user confirmation -> execute the real
create_customer op -> report result. Do not "fix" this script to call op().

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

    # Intentionally dry-run only. Do not change this example to execute a write.
    dryrun = client.dryrun("create_customer", {"name": "Example Co"})
    print(
        json.dumps(
            {
                "qbXml": dryrun.get("qbXml"),
                "summary": dryrun.get("summary"),
                "preFlight": dryrun.get("preFlight"),
                "allowWrites": dryrun.get("allowWrites"),
            },
            indent=2,
            default=str,
        )
    )
