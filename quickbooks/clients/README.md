# QuickBooks Python Client

This directory contains a small Python client for the `QbConnectService` REST API.
It is pure HTTP and has no QuickBooks SDK dependency itself.
The QuickBooks-side service must already be running on the host.
Phase 9 covers packaging, deployment, and on-box smoke testing.

## Setup

1. `cd quickbooks/clients`
2. `Copy-Item .env.sample .env`
3. Edit `.env` and set:
   - `QB_API_BASE_URL`
   - `QB_API_TOKEN` (`Auth:ApiToken` from the service's `appsettings.json`)
   - `QB_VERIFY_TLS=false` if you are using the self-signed dev cert
4. `pip install -r requirements.txt`

## Run examples

- `cd quickbooks/clients && python examples/pull_pnl.py`
- `cd quickbooks/clients && python examples/list_invoices.py`
- `cd quickbooks/clients && python examples/create_customer_dryrun.py`

## Ad-hoc usage

`cd quickbooks/clients && python -c "from qb_client import QbClient; c = QbClient.from_env(); print(c.health())"`

## Tests

`cd quickbooks/clients && python -m pytest tests/ -q`

The guided way to use this client from an agent is the repo-local
`quickbooks-accounting` Claude skill at
`.claude/skills/quickbooks-accounting/`, which includes the safe-write
workflow and the raw-qbXML fallback.
