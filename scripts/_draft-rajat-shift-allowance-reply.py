"""
Create an Outlook DRAFT reply (reply-all) to Rajat Kumar's 2026-05-11 email
asking whether the Rs. 300/night Third-Shift allowance is included in his
Full & Final settlement.

Does NOT send. Leaves the draft in rjain@technijian.com Drafts for review.
"""

import re
from pathlib import Path

import requests

KEY_DIR = Path(r"C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys")
SIG_HTML_PATH = Path(r"c:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html")
USER = "rjain@technijian.com"

# Rajat's message we're replying to:
RAJAT_MSG_ID = "AAMkAGNlYjM0OTA4LThjMjYtNGQ3My1iNDg1LTQ2MTI5NTg0NzFlOQBGAAAAAAC88IffM67WS4tSyVwwqYmJBwBhk-ls8ubYRazD3tGgncxCAAAAAAENAACgx7VhNWW1QYCgfGa-8kbOAAZKrJlXAAA="


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

    # 1. Create a reply-all draft (keeps thread + Gurdeep on cc)
    r = requests.post(
        f"https://graph.microsoft.com/v1.0/users/{USER}/messages/{RAJAT_MSG_ID}/createReplyAll",
        headers=H, json={},
    )
    r.raise_for_status()
    draft = r.json()
    draft_id = draft["id"]
    print(f"Draft created: {draft_id}")

    sig = SIG_HTML_PATH.read_text(encoding="utf-8")
    div = '<div style="font-family:Aptos,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)">'
    blank = f'{div}<br></div>'

    body = "\n".join([
        f'{div}Hi Rajat,</div>',
        blank,
        f'{div}Thanks for raising this &mdash; you&rsquo;re right, and here is where it stands.</div>',
        blank,
        f'{div}<b>1. The night-shift allowance is payable, and it is in addition to the Rs.&nbsp;56,667.</b> '
        f'Under the Employee Handbook (Compensation &amp; Benefits, Section&nbsp;3 &mdash; Shift Allowance) and clause&nbsp;2 of your offer letter, '
        f'the Third Shift (10:30&nbsp;PM&ndash;7:30&nbsp;AM) carries an allowance of <b>Rs.&nbsp;300 per full shift</b>, and the Second Shift (2:00&nbsp;PM&ndash;11:00&nbsp;PM) <b>Rs.&nbsp;150 per full shift</b>. '
        f'These are paid per shift through the regular monthly payroll for every full shift you actually work. They are <b>not</b> part of the Rs.&nbsp;42,500 fixed monthly figure, so they sit <b>on top of</b> the Rs.&nbsp;56,667 shown in the Mutual Separation Agreement &mdash; not instead of it.</div>',
        blank,
        f'{div}<b>2. Why they are not a line in the Agreement.</b> '
        f'The Rs.&nbsp;56,667 in the Agreement is the separation package &mdash; Rs.&nbsp;42,500 fixed May salary plus Rs.&nbsp;14,167 ex-gratia. '
        f'Variable, work-based items such as shift allowances depend on how many qualifying shifts you actually work in May, so they are reconciled in your normal May payroll (payslip on June&nbsp;1) rather than fixed in the Agreement. '
        f'To remove any doubt, we will add an express line to the Agreement confirming that shift allowances earned for full shifts worked in May&nbsp;2026 are payable in addition to the Separation Consideration and are not affected by the release in Section&nbsp;4. I&rsquo;ll send you the updated version.</div>',
        blank,
        f'{div}<b>3. The final payable amount.</b></div>',
        f'{div}&bull;&nbsp;Rs.&nbsp;56,667 &mdash; Separation Consideration (May fixed salary + ex-gratia), paid June&nbsp;1, 2026.</div>',
        f'{div}&bull;&nbsp;<i>plus</i> Rs.&nbsp;300 for each full Third-Shift night you work in May (Rs.&nbsp;150 for each full Second Shift), taken from the Microsoft&nbsp;Shifts clock-in records when May payroll closes.</div>',
        f'{div}&bull;&nbsp;<i>less</i> applicable TDS.</div>',
        blank,
        f'{div}So for the May&nbsp;11 night shift you have worked, that is Rs.&nbsp;300; the running figure grows with each further qualifying shift until you either sign the Mutual Separation Agreement (after which you are on paid leave-of-absence under Section&nbsp;1.02 and stop accruing) or reach May&nbsp;31. '
        f'We can confirm the exact shift count with payroll at month-end, or sooner if you would like a running total &mdash; just let me know.</div>',
        blank,
        f'{div}Please watch for the updated Agreement, and tell me if you&rsquo;d like the running shift count in the meantime.</div>',
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
