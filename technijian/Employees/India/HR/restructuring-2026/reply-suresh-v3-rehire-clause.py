"""
Suresh v3: Adds the Future Re-Employment clause to the termination letter.

Steps:
1. Cancel envelope 33688309 (the v2 letter without rehire clause).
2. Create new Foxit envelope with v3 letter (now includes "no rehire" clause).
3. Send brief branded follow-up email noting one additional clarification.
4. Update monitor state with new folder id.
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

OLD_FOLDER_ID = 33688309  # the v2 letter envelope
NEW_LETTER = ROOT / "letters" / "pdf-signed" / "04-Suresh-Kumar-Sharma-Termination.pdf"
SURESH_EMAIL = "sksvats@gmail.com"
SURESH_NAME = "Suresh Kumar Sharma"

CC_RECIPIENTS = [
    {"address": "ABhardwaj@technijian.com", "name": "Ajay Bhardwaj"},
    {"address": "GKumar@technijian.com",    "name": "Gurdeep Kumar"},
]


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

    print("Step 1 - Cancel old envelope", OLD_FOLDER_ID)
    fox = foxit_token(keys)
    r = requests.post(f"{FOXIT_URL}/folders/cancelFolder",
        headers={"Authorization": f"Bearer {fox}", "Content-Type": "application/json"},
        json={"folderId": OLD_FOLDER_ID,
              "reason_for_cancellation": "Superseded by v3 letter that includes Future Re-Employment clause"})
    print(f"  status={r.status_code}  {r.text[:150]}")

    print("Step 2 - Create new envelope")
    pdf = NEW_LETTER.read_bytes()
    b64 = base64.b64encode(pdf).decode()
    payload = {
        "folderName": "Technijian — Termination Letter (Revised v3) — Suresh Kumar Sharma",
        "inputType": "base64",
        "base64FileString": [b64],
        "fileNames": [NEW_LETTER.name],
        "sendNow": False,
        "createEmbeddedSigningSession": True,
        "createEmbeddedSigningSessionForAllParties": True,
        "signInSequence": False,
        "processTextTags": True,
        "parties": [{
            "firstName": "Suresh", "lastName": "Kumar Sharma",
            "emailId": SURESH_EMAIL, "permission": "FILL_FIELDS_AND_SIGN",
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
        if p.get("partyDetails", {}).get("emailId") == SURESH_EMAIL:
            sign_url = p.get("folderAccessURL") or ""
    if not fid:
        print(f"  FAILED: {data}")
        sys.exit(2)
    print(f"  folder_id={fid}  sign_url={'YES' if sign_url else 'NO'}")

    print("Step 3 - Send branded follow-up email")
    sig = SIG_HTML_PATH.read_text(encoding="utf-8")
    div = '<div style="font-family:Aptos,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)">'
    blank = f'{div}<br></div>'
    lines = [
        f'{div}Dear Suresh,</div>', blank,
        f'{div}Apologies for the additional message. The letter sent a short while ago has been replaced with a final version that includes one additional clarification regarding future re-employment, which is now standard for any separation case where the standard terms have been modified at the employee&rsquo;s request.</div>', blank,
        f'{div}The settlement figures are unchanged at <b>Rs. 57,923</b>. Please disregard the prior Foxit envelope and sign this revised version when it arrives in your inbox momentarily.</div>', blank,
        f'{div}Thank you for your patience.</div>',
        sig,
    ]
    html_body = "\n".join(lines)
    mail = {
        "Message": {
            "Subject": "Updated copy: Technijian — Revised Termination Letter — For Your Signature",
            "Body": {"ContentType": "HTML", "Content": html_body},
            "ToRecipients": [{"EmailAddress": {"Address": SURESH_EMAIL, "Name": SURESH_NAME}}],
            "CcRecipients": [{"EmailAddress": {"Address": cc["address"], "Name": cc["name"]}} for cc in CC_RECIPIENTS],
            "From": {"EmailAddress": {"Address": "rjain@technijian.com", "Name": "Ravi Jain - Technijian"}},
        },
        "SaveToSentItems": True,
    }
    gtok = graph_token(keys)
    r = requests.post(
        "https://graph.microsoft.com/v1.0/users/rjain@technijian.com/sendMail",
        headers={"Authorization": f"Bearer {gtok}", "Content-Type": "application/json"},
        json=mail,
    )
    print(f"  follow-up email status={r.status_code}")

    print("Step 4 - Send branded signing invitation for new envelope")
    invite_html = f"""<!DOCTYPE html><html><body style="margin:0;padding:0;background:#F8F9FA;font-family:'Open Sans',Helvetica,Arial,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" style="background:#F8F9FA;"><tr><td align="center" style="padding:32px 16px;">
<table width="640" cellpadding="0" cellspacing="0" style="max-width:640px;background:#FFFFFF;border-radius:8px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,.08);">
<tr><td style="padding:24px 32px 20px;border-bottom:4px solid #006DB6;"><img src="{LOGO_URL}" alt="Technijian" width="180" style="display:block;max-width:180px;height:auto;"></td></tr>
<tr><td style="background:#006DB6;padding:36px 32px;text-align:center;"><h1 style="margin:0 0 10px;font-size:24px;font-weight:700;color:#FFFFFF;">Revised Termination Letter (Final)</h1><p style="margin:0;font-size:15px;color:rgba(255,255,255,.88);">Please sign this version. Earlier copies are superseded.</p></td></tr>
<tr><td style="padding:32px;">
<p style="margin:0 0 14px;font-size:16px;color:#59595B;line-height:1.6;">Dear Suresh,</p>
<p style="margin:0 0 18px;font-size:15px;color:#59595B;line-height:1.6;">Please find the final version of your termination letter for signature. Total Full and Final Settlement: <b>Rs. 57,923</b> payable June 1, 2026.</p>
<table cellpadding="0" cellspacing="0" style="margin:0 auto 28px;"><tr><td style="background:#F67D4B;border-radius:6px;"><a href="{sign_url}" style="display:inline-block;padding:16px 44px;font-size:17px;font-weight:700;color:#FFFFFF;text-decoration:none;">Review &amp; Sign &#8594;</a></td></tr></table>
<p style="margin:0;font-size:12px;color:#888;text-align:center;line-height:1.7;">If the button does not work: <a href="{sign_url}" style="color:#006DB6;word-break:break-all;font-size:11px;">{sign_url}</a></p>
</td></tr>
<tr><td style="padding:0 32px;"><div style="border-top:2px solid #1EAAC8;"></div></td></tr>
<tr><td style="padding:18px 32px;"><p style="margin:0;font-size:13px;color:#59595B;">Questions: <a href="mailto:rjain@technijian.com" style="color:#006DB6;text-decoration:none;">Ravi Jain, Director</a> &bull; <a href="tel:9493798499" style="color:#006DB6;text-decoration:none;">+1 949.379.8499</a></p></td></tr>
<tr><td style="background:#1A1A2E;padding:24px 32px;"><p style="margin:0 0 4px;font-size:13px;color:#FFFFFF;font-weight:700;">Technijian IT Services Pvt. Ltd.</p><p style="margin:0 0 2px;font-size:12px;color:rgba(255,255,255,.6);">Twin Tower, Plot no 7, Sector 22, IT Park, Panchkula 134109, Haryana</p><p style="margin:0;font-size:10px;color:rgba(255,255,255,.4);font-style:italic;">CONFIDENTIAL.</p></td></tr>
</table></td></tr></table></body></html>"""
    mail2 = {
        "Message": {
            "Subject": "Technijian — Revised Termination Letter (Final) — For Your Signature",
            "Body": {"ContentType": "HTML", "Content": invite_html},
            "ToRecipients": [{"EmailAddress": {"Address": SURESH_EMAIL, "Name": SURESH_NAME}}],
            "CcRecipients": [{"EmailAddress": {"Address": cc["address"], "Name": cc["name"]}} for cc in CC_RECIPIENTS],
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
        e = state["envelopes"]["suresh"]
        e["folder_id"] = fid
        e["status"] = "SHARED"
        e["reminders_sent"] = 0
        e["last_reminder_at"] = None
        e["completion_email_sent"] = False
        e["revised_v3_at"] = datetime.now(timezone.utc).isoformat()
        e["prior_folder_id_v2"] = OLD_FOLDER_ID
        STATE_PATH.write_text(json.dumps(state, indent=2))
        print(f"  suresh folder {OLD_FOLDER_ID} -> {fid}")

    print()
    print("DONE.")


if __name__ == "__main__":
    main()
