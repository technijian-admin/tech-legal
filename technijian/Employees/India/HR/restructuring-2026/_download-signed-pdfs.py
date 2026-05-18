"""Download the fully-executed signed PDFs from Foxit into the repo.

For every envelope in restructuring-monitor-state.json whose status is EXECUTED,
GET /folders/download?folderId=<fid> returns the merged signed PDF (employee
signature + date applied by Foxit on top of Ravi's pre-stamped signature).

Output: letters/signed-from-foxit/<employee>.pdf

Idempotent — re-runs simply overwrite. Skips Yogesh (re-issued, SHARED).
"""

import json
import re
from pathlib import Path

import requests

ROOT = Path(__file__).parent
STATE_PATH = ROOT / "restructuring-monitor-state.json"
KEY_DIR = Path(r"C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys")
FOXIT_URL = "https://na1.foxitesign.foxit.com/api"
OUT_DIR = ROOT / "letters" / "signed-from-foxit"

FILENAMES = {
    "devesh": "01-Devesh-Bhattacharya-Termination-SIGNED.pdf",
    "rajat":  "02-Rajat-Kumar-Mutual-Separation-Agreement-SIGNED.pdf",
    "aditya": "03-Aditya-Saraf-Termination-SIGNED.pdf",
    "suresh": "04-Suresh-Kumar-Sharma-Termination-SIGNED.pdf",
    "yogesh": "05-Yogesh-Kumar-Retrenchment-SIGNED.pdf",
    "rahul":  "06-Rahul-Uniyal-Retrenchment-SIGNED.pdf",
}


def load_keys():
    foxit_raw = (KEY_DIR / "foxit-esign.md").read_text()
    return {
        "FOXIT_ID":     re.search(r'Client ID[^:]*:\*\*\s*(\S+)', foxit_raw).group(1),
        "FOXIT_SECRET": re.search(r'Client Secret[^:]*:\*\*\s*(\S+)', foxit_raw).group(1),
    }


def foxit_token(k):
    return requests.post(f"{FOXIT_URL}/oauth2/access_token", data={
        "grant_type": "client_credentials", "client_id": k["FOXIT_ID"],
        "client_secret": k["FOXIT_SECRET"], "scope": "read-write",
    }).json()["access_token"]


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    state = json.loads(STATE_PATH.read_text())
    keys = load_keys()
    tok = foxit_token(keys)

    results = []
    for key, env in state["envelopes"].items():
        status = env.get("status")
        fid = env.get("folder_id")
        out_name = FILENAMES.get(key, f"{key}-SIGNED.pdf")
        if status != "EXECUTED":
            results.append((key, fid, status, "skipped (not executed)"))
            continue
        r = requests.get(
            f"{FOXIT_URL}/folders/download",
            headers={"Authorization": f"Bearer {tok}"},
            params={"folderId": fid},
            timeout=60,
        )
        if r.status_code != 200:
            results.append((key, fid, status, f"HTTP {r.status_code}: {r.text[:120]}"))
            continue
        out_path = OUT_DIR / out_name
        out_path.write_bytes(r.content)
        results.append((key, fid, status, f"saved {out_path.name} ({len(r.content)/1024:.1f} KB)"))

    print(f"\n{'Employee':<10} {'Folder':<12} {'Status':<10} Result")
    print("-" * 88)
    for k, fid, st, msg in results:
        print(f"{k:<10} {str(fid):<12} {st or '-':<10} {msg}")


if __name__ == "__main__":
    main()
