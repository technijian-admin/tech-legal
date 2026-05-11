"""
Suresh-only follow-up:
1. Reply to Suresh's EL clarification email — confirm separate EL encashment
   (₹4,590, total ₹57,923). Branded Aptos-12pt-rgb(0,0,0) format with signature.
2. Cancel old Foxit envelope 33686608 (which had the EL-burn letter + leave app)
3. Create new Foxit envelope with ONLY the revised termination letter
4. Send branded Technijian signing-invitation email (CC Ajay + Gurdeep)
5. Update monitor state file with new folder id (replacing 33686608)

Modes:
  --dry-run   Show what would happen, do nothing
  --send      Execute all 5 steps
"""

import argparse
import base64
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

import requests

ROOT = Path(__file__).parent
LETTERS_DIR = ROOT / "letters" / "pdf-signed"
STATE_PATH = ROOT / "restructuring-monitor-state.json"
KEY_DIR = Path(r"C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys")
SIG_HTML_PATH = Path(r"c:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html")
LOGO_URL = "https://technijian.com/wp-content/uploads/2023/08/Logo.jpg"
FOXIT_URL = "https://na1.foxitesign.foxit.com/api"

OLD_FOLDER_ID = 33686608
SURESH_EMAIL = "sksvats@gmail.com"
SURESH_NAME = "Suresh Kumar Sharma"
NEW_LETTER = LETTERS_DIR / "04-Suresh-Kumar-Sharma-Termination.pdf"

CC_RECIPIENTS = [
    {"address": "ABhardwaj@technijian.com", "name": "Ajay Bhardwaj"},
    {"address": "GKumar@technijian.com",    "name": "Gurdeep Kumar"},
]


# ─── KEY LOADING ──────────────────────────────────────────────────────────────
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


def graph_token(keys):
    return requests.post(
        f"https://login.microsoftonline.com/{keys['M365_TEN']}/oauth2/v2.0/token",
        data={"grant_type":"client_credentials","client_id":keys["M365_APP"],
              "client_secret":keys["M365_SEC"],"scope":"https://graph.microsoft.com/.default"},
    ).json()["access_token"]


def foxit_token(keys):
    return requests.post(f"{FOXIT_URL}/oauth2/access_token", data={
        "grant_type":"client_credentials","client_id":keys["FOXIT_ID"],
        "client_secret":keys["FOXIT_SECRET"],"scope":"read-write",
    }).json()["access_token"]


# ─── 1) REPLY EMAIL TO SURESH ─────────────────────────────────────────────────
def build_reply_html():
    """Aptos 12pt rgb(0,0,0) one-div-per-line format with branded signature."""
    sig = SIG_HTML_PATH.read_text(encoding="utf-8")
    div = '<div style="font-family:Aptos,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)">'
    blank = f'{div}<br></div>'
    lines = [
        f'{div}Dear Suresh,</div>',
        blank,
        f'{div}Thank you for reaching out and for the careful review of the documentation.</div>',
        blank,
        f'{div}You are correct that the accrued Earned Leave balance is ordinarily encashable separately at the time of full and final settlement, and we are happy to honour that approach in your case.</div>',
        blank,
        f'{div}Accordingly, your settlement has been revised as follows:</div>',
        blank,
        f'{div}&nbsp;&nbsp;&bull;&nbsp;&nbsp;May 2026 Salary: Rs. 40,000</div>',
        f'{div}&nbsp;&nbsp;&bull;&nbsp;&nbsp;Notice pay-in-lieu (10 days): Rs. 13,333</div>',
        f'{div}&nbsp;&nbsp;&bull;&nbsp;&nbsp;Earned Leave encashment (49.13 hrs / 6.14 days &times; Basic Rs.19,434 / 26): Rs. 4,590</div>',
        f'{div}&nbsp;&nbsp;&bull;&nbsp;&nbsp;<b>Total Full and Final Settlement: Rs. 57,923</b> (payable June 1, 2026)</div>',
        blank,
        f'{div}A revised termination letter reflecting the above will arrive in a separate email shortly via Foxit eSign for your signature. The earlier letter and leave application sent on May 11, 2026 are superseded and may be disregarded; please sign the new letter when it arrives.</div>',
        blank,
        f'{div}If you have any further questions, please reach out to me directly.</div>',
        sig,
    ]
    return "\n".join(lines)


def send_reply(keys, dry_run=False):
    html = build_reply_html()
    mail = {
        "Message": {
            "Subject": "Re: Technijian — Termination of Employment + Leave Application — For Your Signature",
            "Body": {"ContentType": "HTML", "Content": html},
            "ToRecipients": [{"EmailAddress": {"Address": SURESH_EMAIL, "Name": SURESH_NAME}}],
            "CcRecipients": [{"EmailAddress": {"Address": cc["address"], "Name": cc["name"]}} for cc in CC_RECIPIENTS],
            "From": {"EmailAddress": {"Address": "rjain@technijian.com", "Name": "Ravi Jain - Technijian"}},
        },
        "SaveToSentItems": True,
    }
    if dry_run:
        print(f"[DRY] Reply email to {SURESH_EMAIL} (CC Ajay+Gurdeep), subject:")
        print(f"      {mail['Message']['Subject']}")
        print(f"      Body length: {len(html)} chars, includes branded signature: {'ravi-jain.jpg' in html}")
        return None
    tok = graph_token(keys)
    r = requests.post(
        "https://graph.microsoft.com/v1.0/users/rjain@technijian.com/sendMail",
        headers={"Authorization": f"Bearer {tok}", "Content-Type": "application/json"},
        json=mail,
    )
    return r.status_code


# ─── 2) CANCEL OLD FOXIT FOLDER ───────────────────────────────────────────────
def cancel_old_envelope(keys, dry_run=False):
    if dry_run:
        print(f"[DRY] Cancel Foxit folder {OLD_FOLDER_ID}")
        return None
    tok = foxit_token(keys)
    r = requests.post(
        f"{FOXIT_URL}/folders/cancelFolder",
        headers={"Authorization": f"Bearer {tok}", "Content-Type": "application/json"},
        json={"folderId": OLD_FOLDER_ID,
              "reason_for_cancellation": "Superseded — revised letter with separate EL encashment being sent per signer's clarification request"},
    )
    return r.status_code, r.text


# ─── 3) NEW FOXIT ENVELOPE (single-doc, no leave application) ─────────────────
def create_new_envelope(keys, dry_run=False):
    if dry_run:
        print(f"[DRY] Create new Foxit envelope")
        print(f"      Document: {NEW_LETTER.name} ({NEW_LETTER.stat().st_size/1024:.1f} KB)")
        print(f"      Recipient: {SURESH_NAME} <{SURESH_EMAIL}>")
        return None, None
    tok = foxit_token(keys)
    pdf_bytes = NEW_LETTER.read_bytes()
    b64 = base64.b64encode(pdf_bytes).decode()
    payload = {
        "folderName": "Technijian — Termination Letter (Revised) — Suresh Kumar Sharma",
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
            "emailId": SURESH_EMAIL,
            "permission": "FILL_FIELDS_AND_SIGN",
            "sequence": 1, "workflowSequence": 1,
        }],
    }
    r = requests.post(f"{FOXIT_URL}/folders/createfolder",
                       headers={"Authorization": f"Bearer {tok}", "Content-Type": "application/json"},
                       json=payload)
    data = r.json()
    folder = data.get("folder", {})
    fid = folder.get("id") or folder.get("folderId")
    sign_url = None
    for p in folder.get("folderRecipientParties", []):
        if p.get("partyDetails", {}).get("emailId") == SURESH_EMAIL:
            sign_url = p.get("folderAccessURL") or ""
    return fid, sign_url


# ─── 4) BRANDED SIGNING-INVITATION EMAIL ──────────────────────────────────────
def send_invitation(keys, sign_url, dry_run=False):
    html = f"""<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"></head>
<body style="margin:0;padding:0;background:#F8F9FA;font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" style="background:#F8F9FA;">
<tr><td align="center" style="padding:32px 16px;">
<table width="640" cellpadding="0" cellspacing="0" style="max-width:640px;background:#FFFFFF;border-radius:8px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,.08);">
  <tr><td style="padding:24px 32px 20px;border-bottom:4px solid #006DB6;">
    <img src="{LOGO_URL}" alt="Technijian" width="180" style="display:block;max-width:180px;height:auto;">
  </td></tr>
  <tr><td style="background:#006DB6;padding:36px 32px;text-align:center;">
    <h1 style="margin:0 0 10px;font-size:24px;font-weight:700;color:#FFFFFF;line-height:1.25;">Revised Termination Letter</h1>
    <p style="margin:0;font-size:15px;color:rgba(255,255,255,.88);">Reflecting separate Earned Leave encashment per your request</p>
  </td></tr>
  <tr><td style="padding:32px;">
    <p style="margin:0 0 14px;font-size:16px;color:#59595B;line-height:1.6;">Dear Suresh,</p>
    <p style="margin:0 0 18px;font-size:15px;color:#59595B;line-height:1.6;">
      Please find enclosed the revised termination letter reflecting the agreed treatment of your accrued Earned Leave balance. The revised full and final settlement is <strong>Rs. 57,923</strong>, payable June 1, 2026.
    </p>
    <p style="margin:0 0 18px;font-size:15px;color:#59595B;line-height:1.6;">
      The earlier envelope (and the leave application) sent on May 11, 2026 are superseded and may be ignored. Please sign this revised letter at your earliest convenience.
    </p>
    <table cellpadding="0" cellspacing="0" style="margin:0 auto 28px;">
      <tr><td style="background:#F67D4B;border-radius:6px;">
        <a href="{sign_url}" style="display:inline-block;padding:16px 44px;font-size:17px;font-weight:700;color:#FFFFFF;text-decoration:none;">Review &amp; Sign &#8594;</a>
      </td></tr>
    </table>
    <p style="margin:0;font-size:12px;color:#888;text-align:center;line-height:1.7;">
      If the button does not work, copy this link into your browser:<br>
      <a href="{sign_url}" style="color:#006DB6;word-break:break-all;font-size:11px;">{sign_url}</a>
    </p>
  </td></tr>
  <tr><td style="padding:0 32px;"><div style="border-top:2px solid #1EAAC8;"></div></td></tr>
  <tr><td style="padding:18px 32px;">
    <p style="margin:0;font-size:13px;color:#59595B;line-height:1.6;">
      Questions: contact <a href="mailto:rjain@technijian.com" style="color:#006DB6;text-decoration:none;">Ravi Jain, Director</a> &bull; <a href="tel:9493798499" style="color:#006DB6;text-decoration:none;">+1 949.379.8499</a>
    </p>
  </td></tr>
  <tr><td style="background:#1A1A2E;padding:24px 32px;">
    <p style="margin:0 0 4px;font-size:13px;color:#FFFFFF;font-weight:700;">Technijian IT Services Pvt. Ltd.</p>
    <p style="margin:0 0 2px;font-size:12px;color:rgba(255,255,255,.6);">Twin Tower, Plot no 7, Sector 22, IT Park, Panchkula 134109, Haryana</p>
    <p style="margin:0 0 6px;font-size:12px;"><a href="https://technijian.com" style="color:#1EAAC8;text-decoration:none;">technijian.com</a></p>
    <p style="margin:0;font-size:10px;color:rgba(255,255,255,.4);font-style:italic;">CONFIDENTIAL — Employer communication.</p>
  </td></tr>
</table></td></tr></table></body></html>"""
    mail = {
        "Message": {
            "Subject": "Technijian — Revised Termination Letter — For Your Signature",
            "Body": {"ContentType": "HTML", "Content": html},
            "ToRecipients": [{"EmailAddress": {"Address": SURESH_EMAIL, "Name": SURESH_NAME}}],
            "CcRecipients": [{"EmailAddress": {"Address": cc["address"], "Name": cc["name"]}} for cc in CC_RECIPIENTS],
            "From": {"EmailAddress": {"Address": "rjain@technijian.com", "Name": "Ravi Jain - Technijian"}},
        },
        "SaveToSentItems": True,
    }
    if dry_run:
        print(f"[DRY] Branded signing invitation to {SURESH_EMAIL} (CC Ajay+Gurdeep)")
        return None
    tok = graph_token(keys)
    r = requests.post(
        "https://graph.microsoft.com/v1.0/users/rjain@technijian.com/sendMail",
        headers={"Authorization": f"Bearer {tok}", "Content-Type": "application/json"},
        json=mail,
    )
    return r.status_code


# ─── 5) UPDATE MONITOR STATE ──────────────────────────────────────────────────
def update_monitor_state(new_folder_id, dry_run=False):
    if dry_run:
        print(f"[DRY] Update monitor state: suresh folder_id -> {new_folder_id}, reset reminders_sent, status SHARED")
        return
    if not STATE_PATH.exists():
        print(f"  [WARN] state file {STATE_PATH} not found")
        return
    state = json.loads(STATE_PATH.read_text())
    if "suresh" in state["envelopes"]:
        state["envelopes"]["suresh"]["folder_id"] = new_folder_id
        state["envelopes"]["suresh"]["status"] = "SHARED"
        state["envelopes"]["suresh"]["reminders_sent"] = 0
        state["envelopes"]["suresh"]["last_reminder_at"] = None
        state["envelopes"]["suresh"]["completion_email_sent"] = False
        state["envelopes"]["suresh"]["revised_at"] = datetime.now(timezone.utc).isoformat()
        state["envelopes"]["suresh"]["prior_folder_id"] = OLD_FOLDER_ID
        STATE_PATH.write_text(json.dumps(state, indent=2))
        print(f"  Updated state file: suresh folder {OLD_FOLDER_ID} -> {new_folder_id}")


def main():
    ap = argparse.ArgumentParser()
    grp = ap.add_mutually_exclusive_group(required=True)
    grp.add_argument("--dry-run", action="store_true")
    grp.add_argument("--send", action="store_true")
    args = ap.parse_args()

    keys = load_keys()

    print("=" * 70)
    print("SURESH EL-CLARIFICATION FOLLOW-UP")
    print("=" * 70)

    if args.dry_run:
        print()
        print("Step 1 — Reply email")
        send_reply(keys, dry_run=True)
        print()
        print("Step 2 — Cancel old envelope")
        cancel_old_envelope(keys, dry_run=True)
        print()
        print("Step 3 — Create new envelope")
        create_new_envelope(keys, dry_run=True)
        print()
        print("Step 4 — Signing invitation")
        send_invitation(keys, "https://example.com/SIGNING_URL_PLACEHOLDER", dry_run=True)
        print()
        print("Step 5 — Update monitor state")
        update_monitor_state("NEW_FOLDER_ID_PLACEHOLDER", dry_run=True)
        return

    if args.send:
        print()
        print("Step 1 — Sending reply email...")
        status = send_reply(keys)
        print(f"  status={status}")
        if status not in (200, 202):
            print("  FAILED — aborting before envelope changes")
            sys.exit(2)

        print()
        print("Step 2 — Cancelling old envelope 33686608...")
        rc, txt = cancel_old_envelope(keys)
        print(f"  status={rc}  {txt[:200]}")

        print()
        print("Step 3 — Creating new envelope...")
        fid, sign_url = create_new_envelope(keys)
        if not fid:
            print("  FAILED to create envelope")
            sys.exit(3)
        print(f"  folder_id={fid}  sign_url={'YES' if sign_url else 'NO'}")

        print()
        print("Step 4 — Sending signing invitation...")
        status = send_invitation(keys, sign_url)
        print(f"  status={status}")

        print()
        print("Step 5 — Updating monitor state...")
        update_monitor_state(fid)

        print()
        print("DONE.")


if __name__ == "__main__":
    main()
