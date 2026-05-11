"""
Rajat v2: Correct date of joining (Feb 2 -> Feb 12) and clarify office
attendance during paid LOA.

Steps:
1. Cancel envelope 33686595 (the v1 MSA with wrong DOJ).
2. Create new Foxit envelope with v2 MSA (corrected DOJ).
3. Send branded reply to Gurdeep (CC Rajat, Ajay) covering:
   - DOJ correction acknowledged and new MSA sent
   - Confirmation that once MSA is signed, Rajat is on paid LOA (per §1.02)
     and not required to come to office through the Separation Date.
4. Send the new signing invitation to Rajat directly.
5. Update monitor state.
"""

import base64
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

import requests

ROOT = Path(__file__).parent
STATE_PATH = ROOT / "restructuring-monitor-state.json"
KEY_DIR = Path(r"C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys")
SIG_HTML_PATH = Path(r"c:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html")
LOGO_URL = "https://technijian.com/wp-content/uploads/2023/08/Logo.jpg"
FOXIT_URL = "https://na1.foxitesign.foxit.com/api"

OLD_FOLDER_ID = 33686595
NEW_LETTER = ROOT / "letters" / "pdf-signed" / "02-Rajat-Kumar-Mutual-Separation-Agreement.pdf"
RAJAT_EMAIL = "rajatkumar07860@gmail.com"
RAJAT_NAME = "Rajat Kumar"

# Internal recipients
GURDEEP = {"address": "GKumar@technijian.com",    "name": "Gurdeep Kumar"}
AJAY    = {"address": "ABhardwaj@technijian.com", "name": "Ajay Bhardwaj"}


def load_keys():
    foxit_raw = (KEY_DIR / "foxit-esign.md").read_text()
    m365_raw  = (KEY_DIR / "m365-graph.md").read_text()
    return {
        "FOXIT_ID":     re.search(r'Client ID[^:]*:\*\*\s*(\S+)', foxit_raw).group(1),
        "FOXIT_SECRET": re.search(r'Client Secret[^:]*:\*\*\s*(\S+)', foxit_raw).group(1),
        "M365_APP":     re.search(r'App Client ID[^:]*:\*\*\s*(\S+)', m365_raw).group(1),
        "M365_TEN":     re.search(r'Tenant ID[^:]*:\*\*\s*(\S+)',     m365_raw).group(1),
        "M365_SEC":     re.search(r'Client Secret[^:]*:\*\*\s*(.+)',  m365_raw).group(1).strip(),
    }


def graph_token(k):
    return requests.post(
        f"https://login.microsoftonline.com/{k['M365_TEN']}/oauth2/v2.0/token",
        data={"grant_type":"client_credentials","client_id":k["M365_APP"],
              "client_secret":k["M365_SEC"],"scope":"https://graph.microsoft.com/.default"},
    ).json()["access_token"]


def foxit_token(k):
    return requests.post(f"{FOXIT_URL}/oauth2/access_token", data={
        "grant_type":"client_credentials","client_id":k["FOXIT_ID"],
        "client_secret":k["FOXIT_SECRET"],"scope":"read-write",
    }).json()["access_token"]


def main():
    keys = load_keys()
    fox = foxit_token(keys)

    print("Step 1 - Cancel old envelope", OLD_FOLDER_ID)
    r = requests.post(f"{FOXIT_URL}/folders/cancelFolder",
        headers={"Authorization": f"Bearer {fox}", "Content-Type": "application/json"},
        json={"folderId": OLD_FOLDER_ID,
              "reason_for_cancellation": "Date of Joining correction (Feb 2 -> Feb 12); superseded by corrected MSA"})
    print(f"  status={r.status_code}  {r.text[:150]}")

    print("Step 2 - Create new envelope (corrected DOJ Feb 12)")
    pdf = NEW_LETTER.read_bytes()
    b64 = base64.b64encode(pdf).decode()
    payload = {
        "folderName": "Technijian — Mutual Separation Agreement (Revised) — Rajat Kumar",
        "inputType": "base64",
        "base64FileString": [b64],
        "fileNames": [NEW_LETTER.name],
        "sendNow": False,
        "createEmbeddedSigningSession": True,
        "createEmbeddedSigningSessionForAllParties": True,
        "signInSequence": False,
        "processTextTags": True,
        "parties": [{
            "firstName": "Rajat", "lastName": "Kumar",
            "emailId": RAJAT_EMAIL, "permission": "FILL_FIELDS_AND_SIGN",
            "sequence": 1, "workflowSequence": 1,
        }],
    }
    r = requests.post(f"{FOXIT_URL}/folders/createfolder",
        headers={"Authorization": f"Bearer {fox}", "Content-Type": "application/json"},
        json=payload)
    data = r.json()
    folder = data.get("folder", {})
    fid = folder.get("id") or folder.get("folderId")
    sign_url = None
    for p in folder.get("folderRecipientParties", []):
        if p.get("partyDetails", {}).get("emailId") == RAJAT_EMAIL:
            sign_url = p.get("folderAccessURL") or ""
    if not fid:
        print(f"  FAILED: {data}")
        sys.exit(2)
    print(f"  folder_id={fid}  sign_url={'YES' if sign_url else 'NO'}")

    gtok = graph_token(keys)

    print("Step 3 - Reply to Gurdeep (CC Rajat, Ajay)")
    sig = SIG_HTML_PATH.read_text(encoding="utf-8")
    div = '<div style="font-family:Aptos,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)">'
    blank = f'{div}<br></div>'
    lines = [
        f'{div}Hi Gurdeep,</div>',
        blank,
        f'{div}Thank you for relaying Rajat&rsquo;s points. Both addressed below.</div>',
        blank,
        f'{div}<b>1. Date of Joining correction.</b> The corrected Mutual Separation Agreement showing his actual joining date of <b>February 12, 2026</b> has been issued. The earlier envelope sent yesterday has been voided. A fresh signing invitation will arrive in Rajat&rsquo;s inbox in a moment. Settlement figures are unchanged at <b>Rs. 56,667</b>, payable June 1, 2026.</div>',
        blank,
        f'{div}<b>2. Office attendance through May 31.</b> Once Rajat signs the Mutual Separation Agreement, he is on <b>paid leave-of-absence</b> from the date of signature through the Separation Date (May 31, 2026), per §1.02 of the Agreement. He is <b>not required to attend the office</b> during that period, and is free to use that time for job-search activities. His full May 2026 salary is paid regardless.</div>',
        blank,
        f'{div}So the simplest path for him is to sign the new MSA today &mdash; that immediately releases him from attendance and starts the paid LOA. If he prefers to keep working a few more days he is welcome to, but it is not required once the MSA is executed.</div>',
        blank,
        f'{div}Hi Rajat &mdash; please open the new signing email (subject: &ldquo;Technijian &mdash; Mutual Separation Agreement (Revised) &mdash; For Your Signature&rdquo;) and sign at your convenience. Let Gurdeep or me know if anything else needs adjustment.</div>',
        sig,
    ]
    html = "\n".join(lines)
    mail = {
        "Message": {
            "Subject": "Re: Rajat — DOJ correction and office attendance during notice",
            "Body": {"ContentType": "HTML", "Content": html},
            "ToRecipients": [{"EmailAddress": {"Address": GURDEEP["address"], "Name": GURDEEP["name"]}}],
            "CcRecipients": [
                {"EmailAddress": {"Address": RAJAT_EMAIL, "Name": RAJAT_NAME}},
                {"EmailAddress": {"Address": AJAY["address"], "Name": AJAY["name"]}},
            ],
            "From": {"EmailAddress": {"Address": "rjain@technijian.com", "Name": "Ravi Jain - Technijian"}},
        },
        "SaveToSentItems": True,
    }
    r = requests.post(
        "https://graph.microsoft.com/v1.0/users/rjain@technijian.com/sendMail",
        headers={"Authorization": f"Bearer {gtok}", "Content-Type": "application/json"},
        json=mail,
    )
    print(f"  reply email status={r.status_code}")

    print("Step 4 - Send branded signing invitation to Rajat")
    invite_html = f"""<!DOCTYPE html><html><body style="margin:0;padding:0;background:#F8F9FA;font-family:'Open Sans',Helvetica,Arial,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" style="background:#F8F9FA;"><tr><td align="center" style="padding:32px 16px;">
<table width="640" cellpadding="0" cellspacing="0" style="max-width:640px;background:#FFFFFF;border-radius:8px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,.08);">
<tr><td style="padding:24px 32px 20px;border-bottom:4px solid #006DB6;"><img src="{LOGO_URL}" alt="Technijian" width="180" style="display:block;max-width:180px;height:auto;"></td></tr>
<tr><td style="background:#006DB6;padding:36px 32px;text-align:center;"><h1 style="margin:0 0 10px;font-size:24px;font-weight:700;color:#FFFFFF;">Mutual Separation Agreement (Revised)</h1><p style="margin:0;font-size:15px;color:rgba(255,255,255,.88);">Date of Joining corrected to February 12, 2026</p></td></tr>
<tr><td style="padding:32px;">
<p style="margin:0 0 14px;font-size:16px;color:#59595B;line-height:1.6;">Dear Rajat,</p>
<p style="margin:0 0 18px;font-size:15px;color:#59595B;line-height:1.6;">Please find the revised Mutual Separation Agreement reflecting the corrected Date of Joining (February 12, 2026). All other terms are unchanged. Total Full and Final Settlement: <b>Rs. 56,667</b>, payable June 1, 2026.</p>
<p style="margin:0 0 18px;font-size:15px;color:#59595B;line-height:1.6;">Once signed, you will be on paid leave-of-absence per §1.02 of the Agreement and are not required to attend the office through your Separation Date of May 31, 2026.</p>
<table cellpadding="0" cellspacing="0" style="margin:0 auto 28px;"><tr><td style="background:#F67D4B;border-radius:6px;"><a href="{sign_url}" style="display:inline-block;padding:16px 44px;font-size:17px;font-weight:700;color:#FFFFFF;text-decoration:none;">Review &amp; Sign &#8594;</a></td></tr></table>
<p style="margin:0;font-size:12px;color:#888;text-align:center;line-height:1.7;">If the button does not work: <a href="{sign_url}" style="color:#006DB6;word-break:break-all;font-size:11px;">{sign_url}</a></p>
</td></tr>
<tr><td style="padding:0 32px;"><div style="border-top:2px solid #1EAAC8;"></div></td></tr>
<tr><td style="padding:18px 32px;"><p style="margin:0;font-size:13px;color:#59595B;">Questions: <a href="mailto:rjain@technijian.com" style="color:#006DB6;text-decoration:none;">Ravi Jain, Director</a> &bull; <a href="tel:9493798499" style="color:#006DB6;text-decoration:none;">+1 949.379.8499</a></p></td></tr>
<tr><td style="background:#1A1A2E;padding:24px 32px;"><p style="margin:0 0 4px;font-size:13px;color:#FFFFFF;font-weight:700;">Technijian IT Services Pvt. Ltd.</p><p style="margin:0 0 2px;font-size:12px;color:rgba(255,255,255,.6);">Twin Tower, Plot no 7, Sector 22, IT Park, Panchkula 134109, Haryana</p><p style="margin:0;font-size:10px;color:rgba(255,255,255,.4);font-style:italic;">CONFIDENTIAL.</p></td></tr>
</table></td></tr></table></body></html>"""
    mail2 = {
        "Message": {
            "Subject": "Technijian — Mutual Separation Agreement (Revised) — For Your Signature",
            "Body": {"ContentType": "HTML", "Content": invite_html},
            "ToRecipients": [{"EmailAddress": {"Address": RAJAT_EMAIL, "Name": RAJAT_NAME}}],
            "CcRecipients": [
                {"EmailAddress": {"Address": AJAY["address"], "Name": AJAY["name"]}},
                {"EmailAddress": {"Address": GURDEEP["address"], "Name": GURDEEP["name"]}},
            ],
            "From": {"EmailAddress": {"Address": "rjain@technijian.com", "Name": "Ravi Jain - Technijian"}},
        },
        "SaveToSentItems": True,
    }
    r = requests.post(
        "https://graph.microsoft.com/v1.0/users/rjain@technijian.com/sendMail",
        headers={"Authorization": f"Bearer {gtok}", "Content-Type": "application/json"},
        json=mail2,
    )
    print(f"  signing invitation status={r.status_code}")

    print("Step 5 - Update monitor state")
    if STATE_PATH.exists():
        state = json.loads(STATE_PATH.read_text())
        e = state["envelopes"]["rajat"]
        e["folder_id"] = fid
        e["status"] = "SHARED"
        e["reminders_sent"] = 0
        e["last_reminder_at"] = None
        e["completion_email_sent"] = False
        e["revised_doj_at"] = datetime.now(timezone.utc).isoformat()
        e["prior_folder_id_v1"] = OLD_FOLDER_ID
        STATE_PATH.write_text(json.dumps(state, indent=2))
        print(f"  rajat folder {OLD_FOLDER_ID} -> {fid}")

    print()
    print("DONE.")


if __name__ == "__main__":
    main()
