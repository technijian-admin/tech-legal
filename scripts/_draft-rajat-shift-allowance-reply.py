"""
Update the existing Outlook DRAFT reply to Rajat Kumar's 2026-05-11 email about
the Rs. 300/night Third-Shift allowance.

Per Ravi's instruction: confirm the allowance is owed and additive, say we will
first confirm the number of full night shifts he worked in May 2026, and that an
updated settlement letter will follow once that count is confirmed. Do NOT quote
a final figure yet.

Does NOT send. Leaves the draft in rjain@technijian.com Drafts for review.
"""

import re
import sys
from pathlib import Path

import requests

KEY_DIR = Path(r"C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys")
SIG_HTML_PATH = Path(r"c:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html")
USER = "rjain@technijian.com"

# Rajat's message we're replying to:
RAJAT_MSG_ID = "AAMkAGNlYjM0OTA4LThjMjYtNGQ3My1iNDg1LTQ2MTI5NTg0NzFlOQBGAAAAAAC88IffM67WS4tSyVwwqYmJBwBhk-ls8ubYRazD3tGgncxCAAAAAAENAACgx7VhNWW1QYCgfGa-8kbOAAZKrJlXAAA="
# Draft already created earlier (reply-all). If it no longer exists, a fresh one is made.
EXISTING_DRAFT_ID = "AAMkAGNlYjM0OTA4LThjMjYtNGQ3My1iNDg1LTQ2MTI5NTg0NzFlOQBGAAAAAAC88IffM67WS4tSyVwwqYmJBwBhk-ls8ubYRazD3tGgncxCAAAAAAEQAACgx7VhNWW1QYCgfGa-8kbOAAZNgbLiAAA="


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

    # 1. Reuse the existing reply-all draft if it is still there; otherwise create one.
    draft_id = EXISTING_DRAFT_ID
    chk = requests.get(f"https://graph.microsoft.com/v1.0/users/{USER}/messages/{draft_id}?$select=id,isDraft", headers=H)
    if chk.status_code != 200 or not chk.json().get("isDraft", False):
        r = requests.post(
            f"https://graph.microsoft.com/v1.0/users/{USER}/messages/{RAJAT_MSG_ID}/createReplyAll",
            headers=H, json={},
        )
        r.raise_for_status()
        draft_id = r.json()["id"]
        print(f"Existing draft gone; new draft created: {draft_id}")
    else:
        print(f"Updating existing draft: {draft_id}")

    sig = SIG_HTML_PATH.read_text(encoding="utf-8")
    div = '<div style="font-family:Aptos,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)">'
    blank = f'{div}<br></div>'

    body = "\n".join([
        f'{div}Hi Rajat,</div>',
        blank,
        f'{div}Thanks for raising this &mdash; you are right that the night-shift allowance applies, and here is how we will handle it.</div>',
        blank,
        f'{div}<b>1. The allowance is payable, and it is over and above the Rs.&nbsp;56,667.</b> '
        f'Under the Employee Handbook (Compensation &amp; Benefits, Section&nbsp;3 &mdash; Shift Allowance) and clause&nbsp;2 of your offer letter, the Third Shift (10:30&nbsp;PM&ndash;7:30&nbsp;AM) carries <b>Rs.&nbsp;300 per full shift</b>. '
        f'That is separate from your Rs.&nbsp;42,500 fixed monthly salary, so it adds to &mdash; it does not replace &mdash; the Rs.&nbsp;56,667 shown in the Mutual Separation Agreement. (For completeness, the Second Shift, 2:00&ndash;11:00&nbsp;PM, is Rs.&nbsp;150 per full shift.)</div>',
        blank,
        f'{div}<b>2. Next step &mdash; we will confirm the number of qualifying shifts.</b> '
        f'Per your shift roster you are scheduled on the Third (night) shift. We will reconcile the count of full Third-Shift nights you have actually worked in May&nbsp;2026 against the clock-in / clock-out records and the roster. '
        f'Please also send me your own count when convenient so we can cross-check; if anything does not line up we will sort it out together.</div>',
        blank,
        f'{div}<b>3. Once the count is confirmed, you will receive an updated letter.</b> '
        f'As soon as the worked-shift count is agreed, we will issue you a revised settlement letter that adds an explicit line for the May&nbsp;2026 shift allowance (Rs.&nbsp;300 &times; confirmed full night shifts), so it is clearly stated and not affected by the release wording in Section&nbsp;4. '
        f'The shift allowance is paid through your May payroll and final settlement on June&nbsp;1, 2026, subject to applicable TDS.</div>',
        blank,
        f'{div}One note on timing: once you sign the Mutual Separation Agreement you go on paid leave-of-absence under Section&nbsp;1.02 and are no longer rostered, so the shift count is fixed as of your last worked night. Until then your full May salary is paid regardless.</div>',
        blank,
        f'{div}Send me your shift count when you can, and I will get the updated letter to you right after we confirm it.</div>',
        sig,
    ])

    # 2. Patch the draft body
    r = requests.patch(
        f"https://graph.microsoft.com/v1.0/users/{USER}/messages/{draft_id}",
        headers=H,
        json={
            "subject": "Re: Rajat — DOJ correction and office attendance during notice",
            "body": {"contentType": "HTML", "content": body},
        },
    )
    r.raise_for_status()
    print("Draft body updated. Recipients:")
    r2 = requests.get(
        f"https://graph.microsoft.com/v1.0/users/{USER}/messages/{draft_id}?$select=subject,toRecipients,ccRecipients,webLink",
        headers=H,
    ).json()
    print("  Subject:", r2["subject"])
    print("  To:", [x["emailAddress"]["address"] for x in r2.get("toRecipients", [])])
    print("  Cc:", [x["emailAddress"]["address"] for x in r2.get("ccRecipients", [])])
    print("  Open in Outlook:", r2.get("webLink"))
    print()
    print("DRAFT ONLY — not sent. Review in Outlook Drafts and send manually.")


if __name__ == "__main__":
    main()
