#!/usr/bin/env python3
"""
Universal Foxit envelope canceler. Replaces per-folder cancel scripts.

Usage:
  python scripts/foxit-cancel.py <folderId> [--reason "<reason>"]

Per `feedback_universal_esign_send_script` vault topic: do NOT create
per-folder cancel scripts. This is the single entry point.

Foxit API quirks (proven by trial + error 2026-05-15):
- POST /folders/cancelFolder
- JSON body MUST contain `folderId` as INT (not string) and
  `reason_for_cancellation` (snake_case, not `reasonOfCancellation`).
- Content-Type: application/json. Form-encoded gets 415.
"""
import argparse
import re
import sys
from pathlib import Path

import requests

FOXIT_URL = "https://na1.foxitesign.foxit.com/api"
KEY_DIR   = Path(r"C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys")


def load_foxit_keys() -> tuple[str, str]:
    raw = (KEY_DIR / "foxit-esign.md").read_text(encoding="utf-8")
    cid = re.search(r'Client ID[^:]*:\*\*\s*(\S+)', raw).group(1)
    sec = re.search(r'Client Secret[^:]*:\*\*\s*(\S+)', raw).group(1)
    return cid, sec


def main() -> None:
    ap = argparse.ArgumentParser(description="Cancel a Foxit eSign envelope by folder id.")
    ap.add_argument("folder_id", type=int, help="Foxit folder id (integer).")
    ap.add_argument("--reason", default="Cancelled via foxit-cancel.py",
                    help="Reason for cancellation (passed to Foxit, appears in activity log).")
    args = ap.parse_args()

    cid, sec = load_foxit_keys()
    tok = requests.post(f"{FOXIT_URL}/oauth2/access_token", data={
        "grant_type": "client_credentials",
        "client_id": cid, "client_secret": sec, "scope": "read-write",
    }).json()["access_token"]
    hdrs = {"Authorization": f"Bearer {tok}", "Content-Type": "application/json"}

    r = requests.post(f"{FOXIT_URL}/folders/cancelFolder",
                       headers=hdrs,
                       json={"folderId": int(args.folder_id),
                             "reason_for_cancellation": args.reason})
    print(f"HTTP {r.status_code}")
    print(r.text)
    sys.exit(0 if r.status_code == 200 and '"result":"success"' in r.text else 1)


if __name__ == "__main__":
    main()
