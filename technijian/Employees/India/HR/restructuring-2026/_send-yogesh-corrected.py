"""Yogesh Kumar — corrected envelope.

Two fixes vs original envelope 33686612 (issued 2026-05-11):
  1. Personal email on file was wrong. Correct: yogeshdixit0@gmail.com
     (the dot-zero — original used Yogeshdixit@gmail.com which never reached him).
  2. May 2026 night-shift allowance was missing from the F&F table:
       + Rs. 1,800 (6 nights x Rs. 300; May 1, 2, 6, 7, 8, 9 — confirmed vs
       MS Teams Shifts roster on 2026-05-12).
     Cash to employee:  Rs. 1,12,138 -> Rs. 1,13,938.

Steps:
  1. Cancel old Foxit envelope (folder_id from monitor state).
  2. Create new envelope: revised retrenchment letter + same leave application.
  3. Validate folderAccessURL contains "viewDocumentDirect" (trap #12); if not,
     GET /folders/myfolder/{folderId} to refresh.
  4. Send branded Technijian Graph email to corrected address; CC Ajay + Gurdeep.
  5. Update monitor state (prior_folder_id, new folder_id, status SHARED, reset).

Adapted from send-rajat-msa-v3-shift-allowance.py + send-restructuring-foxit.py.
"""

import base64
import json
import re
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import requests

ROOT = Path(__file__).parent
STATE_PATH = ROOT / "restructuring-monitor-state.json"
KEY_DIR = Path(r"C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys")
LOGO_URL = "https://technijian.com/wp-content/uploads/2023/08/Logo.jpg"
FOXIT_URL = "https://na1.foxitesign.foxit.com/api"

LETTER_PDF = ROOT / "letters" / "pdf-signed" / "05-Yogesh-Kumar-Retrenchment.pdf"
LEAVE_PDF  = ROOT / "leave-applications" / "pdf-signed" / "01-Yogesh-Kumar-Leave-Application.pdf"

YOGESH_EMAIL = "yogeshdixit0@gmail.com"      # corrected (was Yogeshdixit@gmail.com)
YOGESH_NAME  = "Yogesh Kumar"
GURDEEP = {"address": "GKumar@technijian.com",    "name": "Gurdeep Kumar"}
AJAY    = {"address": "ABhardwaj@technijian.com", "name": "Ajay Bhardwaj"}

OLD_TOTAL = "1,12,138"
NEW_TOTAL = "1,13,938"
SHIFT_ALLOWANCE = "1,800"
SHIFT_NIGHTS = 6


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


def extract_sign_url(folder_obj, email):
    for p in folder_obj.get("folderRecipientParties", []):
        if p.get("partyDetails", {}).get("emailId", "").lower() == email.lower():
            return p.get("folderAccessURL") or ""
    return ""


def refresh_folder(tok, folder_id):
    """Trap #12: createfolder sometimes returns a malformed URL without
    viewDocumentDirect; refreshing via GET /folders/myfolder usually returns the
    proper signing URL."""
    r = requests.get(
        f"{FOXIT_URL}/folders/myfolder",
        headers={"Authorization": f"Bearer {tok}"},
        params={"folderId": folder_id},
    )
    if r.status_code != 200:
        return None
    data = r.json()
    return data.get("folder") or data


def main():
    for p in (LETTER_PDF, LEAVE_PDF):
        if not p.exists():
            sys.exit(f"Required PDF not found: {p}")
    if not STATE_PATH.exists():
        sys.exit(f"State file missing: {STATE_PATH}")
    state = json.loads(STATE_PATH.read_text())
    old_folder = state["envelopes"]["yogesh"]["folder_id"]
    print(f"Current Yogesh Foxit folder (to void): {old_folder}")

    keys = load_keys()
    fox = foxit_token(keys)

    print(f"Step 1 — Cancel envelope {old_folder}")
    r = requests.post(
        f"{FOXIT_URL}/folders/cancelFolder",
        headers={"Authorization": f"Bearer {fox}", "Content-Type": "application/json"},
        json={
            "folderId": old_folder,
            "reason_for_cancellation": (
                f"Superseded: corrected personal email on file and added May 2026 "
                f"night-shift allowance (+Rs. {SHIFT_ALLOWANCE}; new total Rs. {NEW_TOTAL})."
            ),
        },
    )
    print(f"  status={r.status_code}  {r.text[:200]}")

    print("Step 2 — Create new envelope (revised letter + leave application)")
    b64_letter = base64.b64encode(LETTER_PDF.read_bytes()).decode()
    b64_leave  = base64.b64encode(LEAVE_PDF.read_bytes()).decode()
    payload = {
        "folderName": "Technijian — Retrenchment + Leave Application (Revised) — Yogesh Kumar",
        "inputType": "base64",
        "base64FileString": [b64_letter, b64_leave],
        "fileNames": [LETTER_PDF.name, LEAVE_PDF.name],
        "sendNow": False,
        "createEmbeddedSigningSession": True,
        "createEmbeddedSigningSessionForAllParties": True,
        "signInSequence": False,
        "processTextTags": True,
        "parties": [{
            "firstName": "Yogesh", "lastName": "Kumar",
            "emailId": YOGESH_EMAIL, "permission": "FILL_FIELDS_AND_SIGN",
            "sequence": 1, "workflowSequence": 1,
        }],
    }
    r = requests.post(
        f"{FOXIT_URL}/folders/createfolder",
        headers={"Authorization": f"Bearer {fox}", "Content-Type": "application/json"},
        json=payload,
    )
    data = r.json()
    folder = data.get("folder", {})
    fid = folder.get("id") or folder.get("folderId")
    if not fid:
        sys.exit(f"  createfolder FAILED: {data}")

    sign_url = extract_sign_url(folder, YOGESH_EMAIL)
    # Trap #12: validate URL contains viewDocumentDirect; refresh if not.
    if "viewDocumentDirect" not in (sign_url or ""):
        print(f"  initial URL malformed ({sign_url[:80]!r}); refreshing via GET")
        time.sleep(2)
        refreshed = refresh_folder(fox, fid)
        if refreshed:
            new_url = extract_sign_url(refreshed, YOGESH_EMAIL)
            if "viewDocumentDirect" in (new_url or ""):
                sign_url = new_url
    print(f"  folder_id={fid}  sign_url_ok={'viewDocumentDirect' in (sign_url or '')}")
    if not sign_url or "viewDocumentDirect" not in sign_url:
        sys.exit("  Aborting: signing URL still malformed after refresh.")

    print(f"Step 3 — Send branded signing invitation to {YOGESH_EMAIL} (CC Ajay + Gurdeep)")
    gtok = graph_token(keys)
    invite_html = f"""<!DOCTYPE html><html><body style="margin:0;padding:0;background:#F8F9FA;font-family:'Open Sans',Helvetica,Arial,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" style="background:#F8F9FA;"><tr><td align="center" style="padding:32px 16px;">
<table width="640" cellpadding="0" cellspacing="0" style="max-width:640px;background:#FFFFFF;border-radius:8px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,.08);">
<tr><td style="padding:24px 32px 20px;border-bottom:4px solid #006DB6;"><img src="{LOGO_URL}" alt="Technijian" width="180" style="display:block;max-width:180px;height:auto;"></td></tr>
<tr><td style="background:#006DB6;padding:36px 32px;text-align:center;"><h1 style="margin:0 0 10px;font-size:24px;font-weight:700;color:#FFFFFF;">Retrenchment Notice (Revised)</h1><p style="margin:0;font-size:15px;color:rgba(255,255,255,.88);">Corrected email + May 2026 night-shift allowance added</p></td></tr>
<tr><td style="padding:32px;">
<p style="margin:0 0 14px;font-size:16px;color:#59595B;line-height:1.6;">Dear Yogesh,</p>
<p style="margin:0 0 16px;font-size:15px;color:#59595B;line-height:1.6;">Thank you for confirming your correct personal email and flagging the missing May&nbsp;2026 night-shift allowance. We cross-checked the count against the MS Teams shift roster and have updated your retrenchment letter accordingly. The revised Full and Final settlement now includes <b>{SHIFT_NIGHTS} Third-Shift (night) duties</b> &mdash; May&nbsp;1, 2, 6, 7, 8 and 9.</p>
<table cellpadding="0" cellspacing="0" style="margin:0 0 18px;width:100%;border:1px solid #E9ECEF;border-radius:6px;">
<tr><td style="padding:10px 14px;font-size:14px;color:#59595B;">Previous Cash to Employee (May salary + 10-day notice + §70 retrenchment)</td><td style="padding:10px 14px;font-size:14px;color:#1A1A2E;text-align:right;white-space:nowrap;">Rs.&nbsp;{OLD_TOTAL}</td></tr>
<tr><td style="padding:10px 14px;font-size:14px;color:#59595B;border-top:1px solid #E9ECEF;">May 2026 night-shift allowance ({SHIFT_NIGHTS} &times; Rs.&nbsp;300)</td><td style="padding:10px 14px;font-size:14px;color:#1A1A2E;text-align:right;white-space:nowrap;border-top:1px solid #E9ECEF;">+ Rs.&nbsp;{SHIFT_ALLOWANCE}</td></tr>
<tr><td style="padding:10px 14px;font-size:15px;font-weight:700;color:#1A1A2E;border-top:2px solid #006DB6;">Total Cash to Employee &mdash; payable June&nbsp;1, 2026, less applicable TDS</td><td style="padding:10px 14px;font-size:15px;font-weight:700;color:#1A1A2E;text-align:right;white-space:nowrap;border-top:2px solid #006DB6;">Rs.&nbsp;{NEW_TOTAL}</td></tr>
</table>
<p style="margin:0 0 18px;font-size:15px;color:#59595B;line-height:1.6;">The earlier electronic envelope (which had been sent to an incorrect email address) has been voided. Please review and sign this corrected version. Everything else &mdash; the last working day of May&nbsp;31, 2026, the IR Code 2020 §70 retrenchment compensation, the EL burn during notice, and the §83 Re-Skilling Fund deposit &mdash; remains as previously communicated.</p>
<table cellpadding="0" cellspacing="0" style="margin:0 0 18px;width:100%;border:1px solid #E9ECEF;border-radius:6px;"><tr><td style="padding:16px 20px;background:#F8F9FA;"><p style="margin:0 0 8px;font-size:14px;font-weight:700;color:#1A1A2E;">Documents in this envelope:</p><ul style="margin:0;padding-left:18px;"><li style="margin:6px 0;font-size:14px;color:#1A1A2E;"><b>Retrenchment Letter</b> (revised, with shift allowance line)</li><li style="margin:6px 0;font-size:14px;color:#1A1A2E;"><b>Leave Application</b> (May 11 &ndash; May 31, 2026 — pre-approved)</li></ul></td></tr></table>
<table cellpadding="0" cellspacing="0" style="margin:0 auto 28px;"><tr><td style="background:#F67D4B;border-radius:6px;"><a href="{sign_url}" style="display:inline-block;padding:16px 44px;font-size:17px;font-weight:700;color:#FFFFFF;text-decoration:none;">Review &amp; Sign &#8594;</a></td></tr></table>
<p style="margin:0;font-size:12px;color:#888;text-align:center;line-height:1.7;">If the button does not work, copy this link into your browser:<br><a href="{sign_url}" style="color:#006DB6;word-break:break-all;font-size:11px;">{sign_url}</a></p>
</td></tr>
<tr><td style="padding:0 32px;"><div style="border-top:2px solid #1EAAC8;"></div></td></tr>
<tr><td style="padding:18px 32px;"><p style="margin:0;font-size:13px;color:#59595B;">Questions: <a href="mailto:rjain@technijian.com" style="color:#006DB6;text-decoration:none;">Ravi Jain, Director</a> &bull; <a href="tel:9493798499" style="color:#006DB6;text-decoration:none;">+1 949.379.8499</a> &bull; or speak with Gurdeep / Ajay in Panchkula</p></td></tr>
<tr><td style="background:#1A1A2E;padding:24px 32px;"><p style="margin:0 0 4px;font-size:13px;color:#FFFFFF;font-weight:700;">Technijian IT Services Pvt. Ltd.</p><p style="margin:0 0 2px;font-size:12px;color:rgba(255,255,255,.6);">Twin Tower, Plot no 7, Sector 22, IT Park, Panchkula 134109, Haryana</p><p style="margin:0;font-size:10px;color:rgba(255,255,255,.4);font-style:italic;">CONFIDENTIAL &mdash; Employer communication</p></td></tr>
</table></td></tr></table></body></html>"""
    mail = {
        "Message": {
            "Subject": "Technijian — Notice of Retrenchment (Revised) — For Your Signature",
            "Body": {"ContentType": "HTML", "Content": invite_html},
            "ToRecipients": [{"EmailAddress": {"Address": YOGESH_EMAIL, "Name": YOGESH_NAME}}],
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
        json=mail,
    )
    print(f"  signing invitation status={r.status_code}")
    if r.status_code not in (200, 202):
        print(f"  ERROR body: {r.text[:400]}")
        sys.exit(2)

    print("Step 4 — Update monitor state")
    e = state["envelopes"]["yogesh"]
    e["prior_folder_id"] = e["folder_id"]
    e["folder_id"] = fid
    e["status"] = "SHARED"
    e["reminders_sent"] = 0
    e["last_reminder_at"] = None
    e["completion_email_sent"] = False
    e["executed_at"] = None
    e["shift_allowance_revised_at"] = datetime.now(timezone.utc).isoformat()
    e["email_corrected_at"] = datetime.now(timezone.utc).isoformat()
    e["correct_email"] = YOGESH_EMAIL
    STATE_PATH.write_text(json.dumps(state, indent=2))
    print(f"  yogesh folder {old_folder} -> {fid}")
    print("\nDONE.")


if __name__ == "__main__":
    main()
