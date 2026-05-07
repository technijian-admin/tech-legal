#!/usr/bin/env python3
"""Patch v3 — replace GLBA bullet with industry-correct framing.

Talley & Associates is a governmental-relations / association-management firm
(per talleyassoc.weebly.com), not a financial institution. GLBA does not apply.

Replaces the entire 'Client and regulatory requirements' bullet with one tuned
to vendor questionnaires, SOC 2, contractual minimums, and state cybersecurity
statutes — relevant to lobbying / association engagements.
"""
import json
import re
import sys
import urllib.request
from pathlib import Path

KEYS = Path(r"C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md").read_text(encoding="utf-8")
CID = re.search(r"App Client ID[^:]*:\*\*\s*(\S+)", KEYS).group(1)
TID = re.search(r"Tenant ID[^:]*:\*\*\s*(\S+)", KEYS).group(1)
SEC = re.search(r"Client Secret[^:]*:\*\*\s*(\S+)", KEYS).group(1)

UPN = "RJain@technijian.com"
MSG_ID = Path(r"c:\vscode\tech-legal\tech-legal\scripts\taly-rob-msa-draft-id.txt").read_text(encoding="ascii").strip()

# OAuth token (client credentials)
token_req = urllib.request.Request(
    f"https://login.microsoftonline.com/{TID}/oauth2/v2.0/token",
    data=urllib.parse.urlencode({
        "client_id": CID,
        "scope": "https://graph.microsoft.com/.default",
        "client_secret": SEC,
        "grant_type": "client_credentials",
    }).encode(),
    headers={"Content-Type": "application/x-www-form-urlencoded"},
    method="POST",
)
token = json.loads(urllib.request.urlopen(token_req).read())["access_token"]
HDR = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

# Fetch current body
get_req = urllib.request.Request(
    f"https://graph.microsoft.com/v1.0/users/{UPN}/messages/{MSG_ID}?$select=body",
    headers=HDR,
)
current = json.loads(urllib.request.urlopen(get_req).read())
html = current["body"]["content"]
print(f"Fetched draft body: {len(html):,} chars")

# Locate the bullet by regex (whole <li>...</li> containing 'GLBA')
pattern = re.compile(
    r"<li><strong>Client and regulatory requirements\.</strong>[^<]*?(?:<[^>]*>[^<]*)*?GLBA[^<]*?(?:<[^>]*>[^<]*)*?</li>",
    re.DOTALL,
)
match = pattern.search(html)
if not match:
    # Fallback: simpler greedy match on the bullet
    fallback = re.compile(
        r"<li><strong>Client and regulatory requirements\.</strong>.*?</li>",
        re.DOTALL,
    )
    match = fallback.search(html)

if not match:
    print("ERROR: GLBA bullet not found in current draft body")
    sys.exit(1)

old_block = match.group(0)
print(f"\nMatched OLD bullet ({len(old_block)} chars):")
print(old_block[:200] + "...")

new_block = (
    "<li><strong>Client and contract requirements.</strong> If your association "
    "clients, government counterparties, or any of your engagements impose "
    "specific cybersecurity controls (vendor security questionnaires, SOC 2 "
    "expectations, contractual security minimums, or state cybersecurity "
    "statutes), RTPT and SA often map directly to required controls. Worth a "
    "quick scan of your top engagement letters before we pull either line.</li>"
)

new_html = html.replace(old_block, new_block)
if new_html == html:
    print("ERROR: replacement did not change the body")
    sys.exit(1)

# Sanity checks
if "GLBA" in new_html:
    print("ERROR: GLBA still present after replacement")
    sys.exit(1)
if re.search(r"[\s>](\,\d{3})", new_html):
    print("ERROR: stripped currency detected")
    sys.exit(1)
expected = ["$724.75", "$468.00", "$256.75", "$172.50", "$92", "$135", "$603", "$240.45"]
for v in expected:
    if v not in new_html:
        print(f"ERROR: expected amount missing after patch: {v}")
        sys.exit(1)

# Save preview
preview = Path(r"c:\tmp") / f"taly-rob-msa-preview-v3.html"
preview.write_text(new_html, encoding="utf-8")
print(f"\nPatched preview saved: {preview}")

# PATCH the draft
patch_body = json.dumps({"body": {"contentType": "HTML", "content": new_html}}).encode()
patch_req = urllib.request.Request(
    f"https://graph.microsoft.com/v1.0/users/{UPN}/messages/{MSG_ID}",
    data=patch_body,
    headers=HDR,
    method="PATCH",
)
resp = urllib.request.urlopen(patch_req)
print(f"PATCH status: {resp.status}")
print("Draft body successfully patched.")
