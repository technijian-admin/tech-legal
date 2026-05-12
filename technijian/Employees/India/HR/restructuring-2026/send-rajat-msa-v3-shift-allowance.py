"""
Rajat MSA v3 — adds the May-2026 night-shift allowance.

Rajat confirmed (and we cross-checked vs the MS Teams Shifts roster + attendance)
that he worked 9 full Third-Shift (night) duties in May 2026. The revised Mutual
Separation Agreement now carries:
  (f) Shift allowance — May 2026 night shifts ... Rs. 2,700 (9 × Rs. 300)
  TOTAL ............................................ Rs. 59,367 (was Rs. 56,667)
plus a new §2.04 explaining it and a carve-out in §4.01(a) so the release does
not extinguish it.

Steps:
1. Cancel the current Foxit envelope (folder_id from monitor state — the v2 DOJ-
   corrected MSA).
2. Create a new Foxit envelope with the revised, signature-stamped PDF.
3. Send a branded signing invitation to Rajat (CC Ajay + Gurdeep) explaining the
   change and carrying the Sign button.
4. Update monitor state (new folder_id, status SHARED, reminders reset).

Adapted from reply-rajat-doj-correction.py. Run from restructuring-2026/.
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
LOGO_URL = "https://technijian.com/wp-content/uploads/2023/08/Logo.jpg"
FOXIT_URL = "https://na1.foxitesign.foxit.com/api"

NEW_LETTER = ROOT / "letters" / "pdf-signed" / "02-Rajat-Kumar-Mutual-Separation-Agreement.pdf"
RAJAT_EMAIL = "rajatkumar07860@gmail.com"
RAJAT_NAME = "Rajat Kumar"
GURDEEP = {"address": "GKumar@technijian.com",    "name": "Gurdeep Kumar"}
AJAY    = {"address": "ABhardwaj@technijian.com", "name": "Ajay Bhardwaj"}

TOTAL_OLD = "56,667"
TOTAL_NEW = "59,367"
SHIFT_ALLOWANCE = "2,700"
SHIFT_NIGHTS = 9


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
        data={"grant_type": "client_credentials", "client_id": k["M365_APP"],
              "client_secret": k["M365_SEC"], "scope": "https://graph.microsoft.com/.default"},
    ).json()["access_token"]


def foxit_token(k):
    return requests.post(f"{FOXIT_URL}/oauth2/access_token", data={
        "grant_type": "client_credentials", "client_id": k["FOXIT_ID"],
        "client_secret": k["FOXIT_SECRET"], "scope": "read-write",
    }).json()["access_token"]


def main():
    if not NEW_LETTER.exists():
        sys.exit(f"Revised signed PDF not found: {NEW_LETTER}")
    state = json.loads(STATE_PATH.read_text())
    old_folder = state["envelopes"]["rajat"]["folder_id"]
    print(f"Current Rajat Foxit folder (to void): {old_folder}")

    keys = load_keys()
    fox = foxit_token(keys)

    print(f"Step 1 — Cancel envelope {old_folder}")
    r = requests.post(f"{FOXIT_URL}/folders/cancelFolder",
        headers={"Authorization": f"Bearer {fox}", "Content-Type": "application/json"},
        json={"folderId": old_folder,
              "reason_for_cancellation": f"Superseded by revised MSA adding May 2026 night-shift allowance (Rs. {SHIFT_ALLOWANCE}); new total Rs. {TOTAL_NEW}"})
    print(f"  status={r.status_code}  {r.text[:160]}")

    print("Step 2 — Create new envelope with revised signed PDF")
    b64 = base64.b64encode(NEW_LETTER.read_bytes()).decode()
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
        sys.exit(f"  createfolder FAILED: {data}")
    print(f"  folder_id={fid}  sign_url={'YES' if sign_url else 'NO'}")

    print("Step 3 — Send branded signing invitation (To: Rajat, CC Ajay + Gurdeep)")
    gtok = graph_token(keys)
    invite_html = f"""<!DOCTYPE html><html><body style="margin:0;padding:0;background:#F8F9FA;font-family:'Open Sans',Helvetica,Arial,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" style="background:#F8F9FA;"><tr><td align="center" style="padding:32px 16px;">
<table width="640" cellpadding="0" cellspacing="0" style="max-width:640px;background:#FFFFFF;border-radius:8px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,.08);">
<tr><td style="padding:24px 32px 20px;border-bottom:4px solid #006DB6;"><img src="{LOGO_URL}" alt="Technijian" width="180" style="display:block;max-width:180px;height:auto;"></td></tr>
<tr><td style="background:#006DB6;padding:36px 32px;text-align:center;"><h1 style="margin:0 0 10px;font-size:24px;font-weight:700;color:#FFFFFF;">Mutual Separation Agreement (Revised)</h1><p style="margin:0;font-size:15px;color:rgba(255,255,255,.88);">Now includes your May 2026 night-shift allowance</p></td></tr>
<tr><td style="padding:32px;">
<p style="margin:0 0 14px;font-size:16px;color:#59595B;line-height:1.6;">Dear Rajat,</p>
<p style="margin:0 0 16px;font-size:15px;color:#59595B;line-height:1.6;">As discussed, the Mutual Separation Agreement has been revised to add your May&nbsp;2026 night-shift allowance. We cross-checked the count against the shift roster and your attendance records: <b>{SHIFT_NIGHTS} full Third-Shift (night) duties</b> &mdash; May&nbsp;1, 2, 3, 4, 7, 8, 9, 10 and 11.</p>
<table cellpadding="0" cellspacing="0" style="margin:0 0 18px;width:100%;border:1px solid #E9ECEF;border-radius:6px;">
<tr><td style="padding:10px 14px;font-size:14px;color:#59595B;">Separation Consideration (May fixed salary Rs.&nbsp;42,500 + ex-gratia Rs.&nbsp;14,167)</td><td style="padding:10px 14px;font-size:14px;color:#1A1A2E;text-align:right;white-space:nowrap;">Rs.&nbsp;{TOTAL_OLD}</td></tr>
<tr><td style="padding:10px 14px;font-size:14px;color:#59595B;border-top:1px solid #E9ECEF;">May 2026 night-shift allowance (9 &times; Rs.&nbsp;300)</td><td style="padding:10px 14px;font-size:14px;color:#1A1A2E;text-align:right;white-space:nowrap;border-top:1px solid #E9ECEF;">+ Rs.&nbsp;{SHIFT_ALLOWANCE}</td></tr>
<tr><td style="padding:10px 14px;font-size:15px;font-weight:700;color:#1A1A2E;border-top:2px solid #006DB6;">Total (gross) &mdash; payable June&nbsp;1, 2026, less applicable TDS</td><td style="padding:10px 14px;font-size:15px;font-weight:700;color:#1A1A2E;text-align:right;white-space:nowrap;border-top:2px solid #006DB6;">Rs.&nbsp;{TOTAL_NEW}</td></tr>
</table>
<p style="margin:0 0 18px;font-size:15px;color:#59595B;line-height:1.6;">The revised Agreement adds this as clause&nbsp;2.01(f), explains it in clause&nbsp;2.04, and confirms in §4 that May&nbsp;2026 shift allowances are paid in addition to the settlement and are not affected by the release. Everything else is unchanged &mdash; including the paid leave-of-absence from your signature date through May&nbsp;31, and your full May salary. The earlier version has been voided; please sign this one.</p>
<table cellpadding="0" cellspacing="0" style="margin:0 auto 28px;"><tr><td style="background:#F67D4B;border-radius:6px;"><a href="{sign_url}" style="display:inline-block;padding:16px 44px;font-size:17px;font-weight:700;color:#FFFFFF;text-decoration:none;">Review &amp; Sign &#8594;</a></td></tr></table>
<p style="margin:0;font-size:12px;color:#888;text-align:center;line-height:1.7;">If the button does not work: <a href="{sign_url}" style="color:#006DB6;word-break:break-all;font-size:11px;">{sign_url}</a></p>
</td></tr>
<tr><td style="padding:0 32px;"><div style="border-top:2px solid #1EAAC8;"></div></td></tr>
<tr><td style="padding:18px 32px;"><p style="margin:0;font-size:13px;color:#59595B;">Questions: <a href="mailto:rjain@technijian.com" style="color:#006DB6;text-decoration:none;">Ravi Jain, Director</a> &bull; <a href="tel:9493798499" style="color:#006DB6;text-decoration:none;">+1 949.379.8499</a> &bull; or speak with Gurdeep / Ajay in Panchkula</p></td></tr>
<tr><td style="background:#1A1A2E;padding:24px 32px;"><p style="margin:0 0 4px;font-size:13px;color:#FFFFFF;font-weight:700;">Technijian IT Services Pvt. Ltd.</p><p style="margin:0 0 2px;font-size:12px;color:rgba(255,255,255,.6);">Twin Tower, Plot no 7, Sector 22, IT Park, Panchkula 134109, Haryana</p><p style="margin:0;font-size:10px;color:rgba(255,255,255,.4);font-style:italic;">CONFIDENTIAL.</p></td></tr>
</table></td></tr></table></body></html>"""
    mail = {
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
    r = requests.post("https://graph.microsoft.com/v1.0/users/rjain@technijian.com/sendMail",
        headers={"Authorization": f"Bearer {gtok}", "Content-Type": "application/json"}, json=mail)
    print(f"  signing invitation status={r.status_code}")

    print("Step 4 — Update monitor state")
    e = state["envelopes"]["rajat"]
    e["prior_folder_id_v2"] = e["folder_id"]
    e["folder_id"] = fid
    e["status"] = "SHARED"
    e["reminders_sent"] = 0
    e["last_reminder_at"] = None
    e["completion_email_sent"] = False
    e["executed_at"] = None
    e["shift_allowance_revised_at"] = datetime.now(timezone.utc).isoformat()
    STATE_PATH.write_text(json.dumps(state, indent=2))
    print(f"  rajat folder {old_folder} -> {fid}")
    print("\nDONE.")


if __name__ == "__main__":
    main()
