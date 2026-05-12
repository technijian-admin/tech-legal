"""
Create an Outlook DRAFT reply to Yogesh Kumar Dixit's 2026-05-12 email, which
raised two points:
  1. His personal email on file is wrong — correct address is yogeshdixit0@gmail.com.
  2. His May 2026 night-shift allowance was not in his F&F — he worked 6 night
     shifts (May 1–9, excluding weekends/leave).

Cross-checked vs MS Teams Shifts ("Tech India", IST): Yogesh rostered on the
Third Shift (22:30–07:30 IST) on May 1, 2, 6, 7, 8, 9 = exactly 6 night shifts.
At Rs. 300/shift = Rs. 1,800. His current cash F&F is Rs. 1,12,138 (May salary
47,589 + 10-day notice 15,863 + §70 retrenchment 48,686 + EL encashment 0), so
the revised cash F&F = Rs. 1,13,938 gross, payable June 1, 2026, less TDS.

This draft confirms both points and says a revised Notice of Retrenchment (with
the shift-allowance line) will be sent to yogeshdixit0@gmail.com for signature.
Does NOT send. Leaves the draft in rjain@technijian.com Drafts for review.
"""

import re
from pathlib import Path

import requests

KEY_DIR = Path(r"C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys")
SIG_HTML_PATH = Path(r"c:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html")
USER = "rjain@technijian.com"
YOGESH_NEW_EMAIL = "yogeshdixit0@gmail.com"


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

    # Find Yogesh's most recent message from the corrected gmail.
    r = requests.get(
        f"https://graph.microsoft.com/v1.0/users/{USER}/messages",
        headers={**H, "ConsistencyLevel": "eventual"},
        params={"$search": '"yogesh"', "$top": 25,
                "$select": "id,subject,from,receivedDateTime"},
    )
    r.raise_for_status()
    msgs = sorted(r.json()["value"], key=lambda m: m["receivedDateTime"], reverse=True)
    target = next((m for m in msgs
                   if m["from"]["emailAddress"]["address"].lower() == YOGESH_NEW_EMAIL), None)
    if target is None:
        target = next((m for m in msgs
                       if "yogesh" in m["from"]["emailAddress"]["address"].lower()), None)
    if target is None:
        raise SystemExit("Could not locate a message from Yogesh to reply to.")
    print(f"Replying to: {target['receivedDateTime']}  {target['subject']}  (from {target['from']['emailAddress']['address']})")

    r = requests.post(
        f"https://graph.microsoft.com/v1.0/users/{USER}/messages/{target['id']}/createReplyAll",
        headers=H, json={},
    )
    r.raise_for_status()
    draft_id = r.json()["id"]

    sig = SIG_HTML_PATH.read_text(encoding="utf-8")
    div = '<div style="font-family:Aptos,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)">'
    blank = f'{div}<br></div>'

    body = "\n".join([
        f'{div}Hi Yogesh,</div>',
        blank,
        f'{div}Thanks for flagging both points &mdash; both are noted and addressed below.</div>',
        blank,
        f'{div}<b>1. Personal email correction.</b> Noted &mdash; we will use <b>{YOGESH_NEW_EMAIL}</b> for all further correspondence, and the revised signing documents (see point&nbsp;2) will be sent to that address. The earlier envelope sent to the incorrect address will be voided.</div>',
        blank,
        f'{div}<b>2. May 2026 night-shift allowance.</b> You are right &mdash; this is payable, and it is over and above your retrenchment settlement. Under the Employee Handbook (Compensation &amp; Benefits, Section&nbsp;3 &mdash; Shift Allowance) and clause&nbsp;2 of your offer letter, the Third Shift (10:30&nbsp;PM&ndash;7:30&nbsp;AM) carries Rs.&nbsp;300 per full shift. We cross-checked your figure against the shift roster and your attendance records, and both agree: <b>6 full Third-Shift (night) duties in May&nbsp;2026</b> &mdash; May&nbsp;1, 2, 6, 7, 8 and 9.</div>',
        blank,
        f'{div}So your final settlement is:</div>',
        f'{div}&bull;&nbsp;Rs.&nbsp;1,12,138 &mdash; current cash full &amp; final (May salary Rs.&nbsp;47,589 + 10-day notice pay-in-lieu Rs.&nbsp;15,863 + retrenchment compensation Rs.&nbsp;48,686)</div>',
        f'{div}&bull;&nbsp;<b>+ Rs.&nbsp;1,800</b> &mdash; May&nbsp;2026 night-shift allowance (6 &times; Rs.&nbsp;300)</div>',
        f'{div}&bull;&nbsp;<b>= Rs.&nbsp;1,13,938 gross</b>, payable June&nbsp;1, 2026, less applicable TDS</div>',
        blank,
        f'{div}We are preparing a revised Notice of Retrenchment that adds this Rs.&nbsp;1,800 as an explicit line, and it will be sent to <b>{YOGESH_NEW_EMAIL}</b> for your signature shortly. Your paid leave-of-absence and earned-leave treatment are unchanged.</div>',
        blank,
        f'{div}If you take any further night shifts before you sign, let me or Gurdeep know and we will add them. Otherwise the figure above is final.</div>',
        sig,
    ])

    r = requests.patch(
        f"https://graph.microsoft.com/v1.0/users/{USER}/messages/{draft_id}",
        headers=H,
        json={"body": {"contentType": "HTML", "content": body}},
    )
    r.raise_for_status()
    r2 = requests.get(
        f"https://graph.microsoft.com/v1.0/users/{USER}/messages/{draft_id}?$select=subject,toRecipients,ccRecipients,webLink",
        headers=H).json()
    print("  Subject:", r2["subject"])
    print("  To:", [x["emailAddress"]["address"] for x in r2.get("toRecipients", [])])
    print("  Cc:", [x["emailAddress"]["address"] for x in r2.get("ccRecipients", [])])
    print("  Open in Outlook:", r2.get("webLink"))
    print("\nDRAFT ONLY — not sent. Review in Outlook Drafts and send manually.")


if __name__ == "__main__":
    main()
