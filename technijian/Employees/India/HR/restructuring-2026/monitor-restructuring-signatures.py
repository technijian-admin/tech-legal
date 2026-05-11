"""
Monitors the 6 India restructuring Foxit envelopes every 12 hours via Windows
Task Scheduler. For each envelope NOT yet EXECUTED, sends a branded Technijian
reminder email FROM Ravi to the employee with Ajay Bhardwaj + Gurdeep Kumar
on CC. Stops self-rescheduling once all 6 are EXECUTED.

State is persisted in `restructuring-monitor-state.json` next to this script.
Each run appends to `restructuring-monitor.log`.

Designed to be idempotent — safe to run as often as Task Scheduler triggers.
"""

import base64
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

import requests

# ─── PATHS & CONFIG ──────────────────────────────────────────────────────────
ROOT = Path(__file__).parent
STATE_PATH = ROOT / "restructuring-monitor-state.json"
LOG_PATH   = ROOT / "restructuring-monitor.log"
LETTERS_DIR = ROOT / "letters" / "pdf-signed"
LEAVES_DIR  = ROOT / "leave-applications" / "pdf-signed"
KEY_DIR = Path(r"C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys")
LOGO_URL = "https://technijian.com/wp-content/uploads/2023/08/Logo.jpg"
FOXIT_URL = "https://na1.foxitesign.foxit.com/api"

# Initial envelopes dispatched 2026-05-11 (from send-restructuring-foxit.py --send)
ENVELOPES = [
    {"key": "devesh", "folder_id": 33686594,
     "first": "Devesh", "last": "Bhattacharya", "email": "bhattacharyadevesh@gmail.com",
     "doc_subject": "Termination of Employment — Probation Period",
     "label": "termination letter"},
    {"key": "rajat",  "folder_id": 33686595,
     "first": "Rajat",  "last": "Kumar",        "email": "rajatkumar07860@gmail.com",
     "doc_subject": "Mutual Separation Agreement",
     "label": "mutual separation agreement"},
    {"key": "aditya", "folder_id": 33686600,
     "first": "Aditya", "last": "Saraf",        "email": "adi.psaraf@gmail.com",
     "doc_subject": "Termination of Employment — Cost Reduction",
     "label": "termination letter"},
    {"key": "suresh", "folder_id": 33686608,
     "first": "Suresh", "last": "Kumar Sharma", "email": "sksvats@gmail.com",
     "doc_subject": "Termination of Employment + Leave Application",
     "label": "termination letter and leave application"},
    {"key": "yogesh", "folder_id": 33686612,
     "first": "Yogesh", "last": "Kumar",        "email": "Yogeshdixit@gmail.com",
     "doc_subject": "Notice of Retrenchment + Leave Application",
     "label": "retrenchment letter and leave application"},
    {"key": "rahul",  "folder_id": 33686615,
     "first": "Rahul",  "last": "Uniyal",       "email": "Rahuluniyal2023@gmail.com",
     "doc_subject": "Notice of Retrenchment + Leave Application",
     "label": "retrenchment letter and leave application"},
]

CC_RECIPIENTS = [
    {"address": "ABhardwaj@technijian.com", "name": "Ajay Bhardwaj"},
    {"address": "GKumar@technijian.com",    "name": "Gurdeep Kumar"},
]

MAX_REMINDERS = 8  # 8 reminders over 4 days at 12hr intervals → stop reminding (still checking)
MIN_HOURS_BETWEEN_REMINDERS = 11  # safety guard: don't reminder within 11h of last email


# ─── HELPERS ──────────────────────────────────────────────────────────────────
def log(msg: str):
    stamp = datetime.now(timezone.utc).astimezone().strftime("%Y-%m-%d %H:%M:%S %Z")
    line = f"[{stamp}] {msg}"
    print(line)
    with LOG_PATH.open("a", encoding="utf-8") as f:
        f.write(line + "\n")


def load_state() -> dict:
    if STATE_PATH.exists():
        return json.loads(STATE_PATH.read_text(encoding="utf-8"))
    # First run — initialize state from the ENVELOPES list
    return {
        "initialized_at": datetime.now(timezone.utc).isoformat(),
        "all_done": False,
        "envelopes": {
            e["key"]: {
                "folder_id": e["folder_id"],
                "status": "SHARED",
                "executed_at": None,
                "reminders_sent": 0,
                "last_reminder_at": None,
                "completion_email_sent": False,
            }
            for e in ENVELOPES
        },
    }


def save_state(state: dict):
    STATE_PATH.write_text(json.dumps(state, indent=2), encoding="utf-8")


def load_keys() -> dict:
    foxit_raw = (KEY_DIR / "foxit-esign.md").read_text()
    m365_raw  = (KEY_DIR / "m365-graph.md").read_text()
    return {
        "FOXIT_ID":     re.search(r'Client ID[^:]*:\*\*\s*(\S+)', foxit_raw).group(1),
        "FOXIT_SECRET": re.search(r'Client Secret[^:]*:\*\*\s*(\S+)', foxit_raw).group(1),
        "M365_APP":     re.search(r'App Client ID[^:]*:\*\*\s*(\S+)', m365_raw).group(1),
        "M365_TEN":     re.search(r'Tenant ID[^:]*:\*\*\s*(\S+)',     m365_raw).group(1),
        "M365_SEC":     re.search(r'Client Secret[^:]*:\*\*\s*(.+)',  m365_raw).group(1).strip(),
    }


def foxit_token(keys: dict) -> str:
    return requests.post(
        f"{FOXIT_URL}/oauth2/access_token",
        data={
            "grant_type": "client_credentials",
            "client_id": keys["FOXIT_ID"],
            "client_secret": keys["FOXIT_SECRET"],
            "scope": "read-write",
        },
        timeout=30,
    ).json()["access_token"]


def graph_token(keys: dict) -> str:
    return requests.post(
        f"https://login.microsoftonline.com/{keys['M365_TEN']}/oauth2/v2.0/token",
        data={
            "grant_type": "client_credentials",
            "client_id": keys["M365_APP"],
            "client_secret": keys["M365_SEC"],
            "scope": "https://graph.microsoft.com/.default",
        },
        timeout=30,
    ).json()["access_token"]


def check_envelope_status(tok: str, folder_id: int) -> tuple[str, str | None]:
    """Return (status, accessURL) for a folder."""
    r = requests.get(
        f"{FOXIT_URL}/folders/myfolder?folderId={folder_id}",
        headers={"Authorization": f"Bearer {tok}"},
        timeout=30,
    )
    if r.status_code != 200:
        return ("UNKNOWN", None)
    data = r.json()
    folder = data.get("folder", {})
    status = folder.get("folderStatus", "UNKNOWN")
    access_url = None
    for p in folder.get("folderRecipientParties", []):
        if p.get("folderAccessURL"):
            access_url = p["folderAccessURL"]
            break
    return (status, access_url)


def download_signed_pdf(tok: str, folder_id: int) -> bytes | None:
    r = requests.get(
        f"{FOXIT_URL}/folders/download?folderId={folder_id}",
        headers={"Authorization": f"Bearer {tok}"},
        timeout=60,
    )
    if r.status_code == 200:
        return r.content
    return None


# ─── EMAILS ───────────────────────────────────────────────────────────────────
def reminder_email_html(env: dict, sign_url: str, reminder_number: int) -> str:
    """Branded Technijian reminder email."""
    is_msa = env["key"] == "rajat"
    instr = (
        "Please review and sign the Mutual Separation Agreement at your earliest convenience."
        if is_msa else
        "Please review and sign your separation documentation at your earliest convenience."
    )
    return f"""<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"></head>
<body style="margin:0;padding:0;background:#F8F9FA;font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" style="background:#F8F9FA;">
<tr><td align="center" style="padding:32px 16px;">
<table width="640" cellpadding="0" cellspacing="0" style="max-width:640px;background:#FFFFFF;border-radius:8px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,.08);">
  <tr><td style="padding:24px 32px 20px;border-bottom:4px solid #006DB6;">
    <img src="{LOGO_URL}" alt="Technijian" width="180" style="display:block;max-width:180px;height:auto;">
  </td></tr>
  <tr><td style="background:#006DB6;padding:36px 32px;text-align:center;">
    <h1 style="margin:0 0 10px;font-size:24px;font-weight:700;color:#FFFFFF;line-height:1.25;">
      Reminder: Document Pending Your Signature
    </h1>
    <p style="margin:0;font-size:15px;color:rgba(255,255,255,.88);">
      {instr}
    </p>
  </td></tr>
  <tr><td style="padding:32px;">
    <p style="margin:0 0 14px;font-size:16px;color:#59595B;line-height:1.6;">Dear {env['first']},</p>
    <p style="margin:0 0 18px;font-size:15px;color:#59595B;line-height:1.6;">
      This is a reminder that your <strong>{env['label']}</strong> dated May 11, 2026 is awaiting
      your electronic signature. Please complete the signing at your earliest convenience.
    </p>
    <p style="margin:0 0 18px;font-size:15px;color:#59595B;line-height:1.6;">
      The signing process is straightforward — open the link below, draw your signature once,
      and the date will auto-populate. Your printed name and employee number are already filled in.
    </p>
    <table cellpadding="0" cellspacing="0" style="margin:0 auto 28px;">
      <tr><td style="background:#F67D4B;border-radius:6px;">
        <a href="{sign_url}" style="display:inline-block;padding:16px 44px;font-size:17px;font-weight:700;color:#FFFFFF;text-decoration:none;">
          Review &amp; Sign Now &#8594;
        </a>
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
      Questions: contact
      <a href="mailto:rjain@technijian.com" style="color:#006DB6;text-decoration:none;">Ravi Jain, Director</a>
      &bull;
      <a href="tel:9493798499" style="color:#006DB6;text-decoration:none;">+1 949.379.8499</a>
    </p>
  </td></tr>
  <tr><td style="background:#1A1A2E;padding:24px 32px;">
    <p style="margin:0 0 4px;font-size:13px;color:#FFFFFF;font-weight:700;">Technijian IT Services Pvt. Ltd.</p>
    <p style="margin:0 0 2px;font-size:12px;color:rgba(255,255,255,.6);">Twin Tower, Plot no 7, Sector 22, IT Park, Panchkula 134109, Haryana</p>
    <p style="margin:0 0 6px;font-size:12px;"><a href="https://technijian.com" style="color:#1EAAC8;text-decoration:none;">technijian.com</a></p>
    <p style="margin:0;font-size:10px;color:rgba(255,255,255,.4);font-style:italic;">CONFIDENTIAL — Employer communication. Reminder {reminder_number}.</p>
  </td></tr>
</table></td></tr></table></body></html>"""


def send_reminder(keys: dict, env: dict, sign_url: str, reminder_number: int) -> int:
    tok = graph_token(keys)
    mail = {
        "Message": {
            "Subject": f"Reminder: Technijian — {env['doc_subject']} — Signature Required",
            "Body": {"ContentType": "HTML", "Content": reminder_email_html(env, sign_url, reminder_number)},
            "ToRecipients": [{"EmailAddress": {"Address": env["email"], "Name": f"{env['first']} {env['last']}"}}],
            "CcRecipients": [
                {"EmailAddress": {"Address": cc["address"], "Name": cc["name"]}}
                for cc in CC_RECIPIENTS
            ],
            "From": {"EmailAddress": {"Address": "rjain@technijian.com", "Name": "Ravi Jain - Technijian"}},
        },
        "SaveToSentItems": True,
    }
    r = requests.post(
        "https://graph.microsoft.com/v1.0/users/rjain@technijian.com/sendMail",
        headers={"Authorization": f"Bearer {tok}", "Content-Type": "application/json"},
        json=mail, timeout=30,
    )
    return r.status_code


def completion_email_html(env: dict) -> str:
    return f"""<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"></head>
<body style="margin:0;padding:0;background:#F8F9FA;font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" style="background:#F8F9FA;">
<tr><td align="center" style="padding:32px 16px;">
<table width="640" cellpadding="0" cellspacing="0" style="max-width:640px;background:#FFFFFF;border-radius:8px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,.08);">
  <tr><td style="padding:24px 32px 20px;border-bottom:4px solid #006DB6;">
    <img src="{LOGO_URL}" alt="Technijian" width="180" style="display:block;max-width:180px;height:auto;">
  </td></tr>
  <tr><td style="background:#006DB6;padding:36px 32px;text-align:center;">
    <h1 style="margin:0 0 10px;font-size:24px;font-weight:700;color:#FFFFFF;line-height:1.25;">
      &#10004; Document Executed
    </h1>
    <p style="margin:0;font-size:15px;color:rgba(255,255,255,.88);">
      Your signed copy is attached for your records.
    </p>
  </td></tr>
  <tr><td style="padding:32px;">
    <p style="margin:0 0 14px;font-size:16px;color:#59595B;line-height:1.6;">Dear {env['first']},</p>
    <p style="margin:0 0 18px;font-size:15px;color:#59595B;line-height:1.6;">
      Thank you. Your <strong>{env['label']}</strong> dated May 11, 2026 has been executed
      successfully. The fully-signed PDF is attached to this email for your records.
    </p>
    <p style="margin:0;font-size:15px;color:#59595B;line-height:1.6;">
      The final settlement amount will be deposited to your registered bank account on or
      before June 1, 2026. Form 16 and statutory exit formalities will be processed within
      15 days of your last working day (May 31, 2026).
    </p>
  </td></tr>
  <tr><td style="padding:0 32px;"><div style="border-top:2px solid #1EAAC8;"></div></td></tr>
  <tr><td style="background:#1A1A2E;padding:24px 32px;">
    <p style="margin:0 0 4px;font-size:13px;color:#FFFFFF;font-weight:700;">Technijian IT Services Pvt. Ltd.</p>
    <p style="margin:0 0 2px;font-size:12px;color:rgba(255,255,255,.6);">Twin Tower, Plot no 7, Sector 22, IT Park, Panchkula 134109, Haryana</p>
    <p style="margin:0 0 6px;font-size:12px;"><a href="https://technijian.com" style="color:#1EAAC8;text-decoration:none;">technijian.com</a></p>
    <p style="margin:0;font-size:10px;color:rgba(255,255,255,.4);font-style:italic;">CONFIDENTIAL — Employer communication.</p>
  </td></tr>
</table></td></tr></table></body></html>"""


def send_completion_email(keys: dict, env: dict, signed_pdf: bytes) -> int:
    tok = graph_token(keys)
    safe_label = env["label"].replace(" ", "-").title()
    filename = f"Technijian-{env['first']}-{env['last'].replace(' ', '-')}-{safe_label}-SIGNED.pdf"
    mail = {
        "Message": {
            "Subject": f"Technijian — Document Executed: {env['doc_subject']}",
            "Body": {"ContentType": "HTML", "Content": completion_email_html(env)},
            "ToRecipients": [{"EmailAddress": {"Address": env["email"], "Name": f"{env['first']} {env['last']}"}}],
            "CcRecipients": [
                {"EmailAddress": {"Address": cc["address"], "Name": cc["name"]}}
                for cc in CC_RECIPIENTS
            ],
            "From": {"EmailAddress": {"Address": "rjain@technijian.com", "Name": "Ravi Jain - Technijian"}},
            "Attachments": [{
                "@odata.type": "#microsoft.graph.fileAttachment",
                "Name": filename,
                "ContentType": "application/pdf",
                "ContentBytes": base64.b64encode(signed_pdf).decode(),
            }],
        },
        "SaveToSentItems": True,
    }
    r = requests.post(
        "https://graph.microsoft.com/v1.0/users/rjain@technijian.com/sendMail",
        headers={"Authorization": f"Bearer {tok}", "Content-Type": "application/json"},
        json=mail, timeout=60,
    )
    return r.status_code


# ─── MAIN LOOP ────────────────────────────────────────────────────────────────
def main():
    log("Monitor run starting")
    state = load_state()
    if state.get("all_done"):
        log("All envelopes already EXECUTED. Nothing to do — consider disabling the scheduled task.")
        return 0

    try:
        keys = load_keys()
    except Exception as e:
        log(f"FAILED to load keys: {e}")
        return 2

    try:
        fox_tok = foxit_token(keys)
    except Exception as e:
        log(f"FAILED to get Foxit token: {e}")
        return 3

    pending = 0
    for env in ENVELOPES:
        ekey = env["key"]
        entry = state["envelopes"][ekey]
        fid = entry["folder_id"]

        try:
            status, sign_url = check_envelope_status(fox_tok, fid)
        except Exception as e:
            log(f"  {ekey} folder={fid} status check FAILED: {e}")
            continue

        prev_status = entry["status"]
        entry["status"] = status
        log(f"  {ekey:8s} folder={fid} status={status} (was {prev_status})")

        if status == "EXECUTED":
            if not entry["completion_email_sent"]:
                try:
                    pdf = download_signed_pdf(fox_tok, fid)
                    if pdf:
                        rc = send_completion_email(keys, env, pdf)
                        if rc in (200, 202):
                            entry["completion_email_sent"] = True
                            entry["executed_at"] = datetime.now(timezone.utc).isoformat()
                            log(f"    -> sent completion email ({len(pdf)/1024:.1f} KB PDF attached)")
                        else:
                            log(f"    -> completion email FAILED: HTTP {rc}")
                    else:
                        log(f"    -> failed to download signed PDF")
                except Exception as e:
                    log(f"    -> completion handling FAILED: {e}")
            else:
                log(f"    -> already executed; completion email already sent on a prior run")
            continue

        # Not executed — send reminder if we haven't hit the cap and enough time has passed
        pending += 1
        if entry["reminders_sent"] >= MAX_REMINDERS:
            log(f"    -> NOT signed; reminder cap ({MAX_REMINDERS}) reached, no further reminders")
            continue
        if entry.get("last_reminder_at"):
            try:
                last = datetime.fromisoformat(entry["last_reminder_at"])
                hours_since = (datetime.now(timezone.utc) - last).total_seconds() / 3600
                if hours_since < MIN_HOURS_BETWEEN_REMINDERS:
                    log(f"    -> NOT signed; last reminder {hours_since:.1f}h ago (< {MIN_HOURS_BETWEEN_REMINDERS}h guard), skipping")
                    continue
            except Exception:
                pass
        if not sign_url:
            log(f"    -> NOT signed; no folderAccessURL available, skipping reminder")
            continue
        try:
            rc = send_reminder(keys, env, sign_url, entry["reminders_sent"] + 1)
            if rc in (200, 202):
                entry["reminders_sent"] += 1
                entry["last_reminder_at"] = datetime.now(timezone.utc).isoformat()
                log(f"    -> sent reminder #{entry['reminders_sent']} (Ajay + Gurdeep cc'd)")
            else:
                log(f"    -> reminder send FAILED: HTTP {rc}")
        except Exception as e:
            log(f"    -> reminder send FAILED: {e}")

    if pending == 0:
        state["all_done"] = True
        log("ALL 6 envelopes EXECUTED. Marking monitor complete.")
    else:
        log(f"{pending} envelope(s) still pending. Next check in 12 hours.")

    save_state(state)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:
        log(f"FATAL: {e}")
        sys.exit(1)
