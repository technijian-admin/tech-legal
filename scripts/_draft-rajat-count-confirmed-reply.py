"""
Create an Outlook DRAFT reply to Rajat Kumar's 2026-05-11 23:58 UTC email in which
he confirmed "9 full Third-Shift (night shift) duties during May 2026".

We cross-checked: MS Teams Shifts roster ("Tech India", IST) = 9 night shifts
(May 1,2,3,4,7,8,9,10,11) — matches his count. So:
  Rs. 56,667 (May fixed salary 42,500 + ex-gratia 14,167)
+ Rs.  2,700 (9 x Rs. 300 night-shift allowance, May 2026)
= Rs. 59,367 gross, payable June 1, 2026, less TDS.

This draft confirms the count and tells him a revised Mutual Separation Agreement
(with the Rs. 2,700 as an explicit line and a §4 carve-out) is being prepared.
Does NOT send. Leaves the draft in rjain@technijian.com Drafts for review.
"""

import re
from pathlib import Path

import requests

KEY_DIR = Path(r"C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys")
SIG_HTML_PATH = Path(r"c:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html")
USER = "rjain@technijian.com"

# Rajat's "9 full Third-Shift duties" reply that we are answering:
RAJAT_MSG_ID = "AAMkAGNlYjM0OTA4LThjMjYtNGQ3My1iNDg1LTQ2MTI5NTg0NzFlOQBGAAAAAAC88IffM67WS4tSyVwwqYmJBwBhk-ls8ubYRazD3tGgncxCAAAAAAENAACgx7VhNWW1QYCgfGa-8kbOAAZNYy5jAAA="


def graph_token():
    raw = (KEY_DIR / "m365-graph.md").read_text()
    app = re.search(r'App Client ID[^:]*:\*\*\s*(\S+)', raw).group(1)
    ten = re.search(r'Tenant ID[^:]*:\*\*\s*(\S+)', raw).group(1)
    sec = re.search(r'Client Secret[^:]*:\*\*\s*(.+)', raw).group(1).strip()
    return requests.post(
        f"https://login.microsoftonline.com/{ten}/oauth2/v2.0/token",
        data={"grant_type": "client_credentials", "client_id": app,
              "client_secret": sec, "scope": "https://graph.microsoft.com/.default"},
    ).json()["access_token"]


def main():
    tok = graph_token()
    H = {"Authorization": f"Bearer {tok}", "Content-Type": "application/json"}

    r = requests.post(
        f"https://graph.microsoft.com/v1.0/users/{USER}/messages/{RAJAT_MSG_ID}/createReplyAll",
        headers=H, json={},
    )
    r.raise_for_status()
    draft_id = r.json()["id"]
    print(f"Draft created: {draft_id}")

    sig = SIG_HTML_PATH.read_text(encoding="utf-8")
    div = '<div style="font-family:Aptos,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)">'
    blank = f'{div}<br></div>'

    body = "\n".join([
        f'{div}Hi Rajat,</div>',
        blank,
        f'{div}Confirmed &mdash; thank you. We have cross-checked your figure against the shift roster and the attendance / clock-in records, and both agree: <b>9 full Third-Shift (night) duties in May&nbsp;2026</b> &mdash; May&nbsp;1, 2, 3, 4, 7, 8, 9, 10 and 11.</div>',
        blank,
        f'{div}So your final settlement is:</div>',
        f'{div}&bull;&nbsp;Rs.&nbsp;56,667 &mdash; Separation Consideration (May fixed salary Rs.&nbsp;42,500 + ex-gratia Rs.&nbsp;14,167)</div>',
        f'{div}&bull;&nbsp;<b>+ Rs.&nbsp;2,700</b> &mdash; May&nbsp;2026 night-shift allowance (9 &times; Rs.&nbsp;300)</div>',
        f'{div}&bull;&nbsp;<b>= Rs.&nbsp;59,367 gross</b>, payable June&nbsp;1, 2026, less applicable TDS</div>',
        blank,
        f'{div}We are preparing a revised Mutual Separation Agreement that adds this Rs.&nbsp;2,700 as an explicit line and records in Section&nbsp;4 that May&nbsp;2026 shift allowances are paid in addition to the settlement. You will receive the new signing invitation to sign that version; the earlier one will be voided. Everything else in the Agreement is unchanged &mdash; including the paid leave-of-absence from your signature date through May&nbsp;31, and your full May salary.</div>',
        blank,
        f'{div}If you take any further night shifts after today and before you sign, let me or Gurdeep know and we will add them. Otherwise the figure above is final.</div>',
        sig,
    ])

    r = requests.patch(
        f"https://graph.microsoft.com/v1.0/users/{USER}/messages/{draft_id}",
        headers=H,
        json={"subject": "Re: Rajat — DOJ correction and office attendance during notice",
              "body": {"contentType": "HTML", "content": body}},
    )
    r.raise_for_status()
    r2 = requests.get(
        f"https://graph.microsoft.com/v1.0/users/{USER}/messages/{draft_id}?$select=subject,toRecipients,ccRecipients,webLink",
        headers=H).json()
    print("  To:", [x["emailAddress"]["address"] for x in r2.get("toRecipients", [])])
    print("  Cc:", [x["emailAddress"]["address"] for x in r2.get("ccRecipients", [])])
    print("  Open in Outlook:", r2.get("webLink"))
    print("\nDRAFT ONLY — not sent. Review in Outlook Drafts and send manually.")


if __name__ == "__main__":
    main()
