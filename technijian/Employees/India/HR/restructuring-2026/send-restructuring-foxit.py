"""
Send all 6 India restructuring letters via Foxit eSign with Technijian-branded
emails (zero Foxit platform emails per workstation_integrations + foxit_esign_workflow
vault notes).

Pre-conditions (all done):
- letters/pdf-signed/*.pdf  (5 termination + 1 MSA, pre-stamped with Ravi)
- leave-applications/pdf-signed/*.pdf  (3 leave apps, pre-stamped director-approval)
- Foxit account notifications already disabled (My Account → Notifications all No)
- Foxit creds in OneDrive keys/foxit-esign.md
- M365 Graph creds in OneDrive keys/m365-graph.md

Modes:
  --test          Send ONE envelope to rjain@technijian.com (verify field placement)
  --send          Send all 6 envelopes to real personal emails
  --dry-run       Print payloads, no API calls

Usage:
  python send-restructuring-foxit.py --test
  python send-restructuring-foxit.py --send
"""

import argparse
import base64
import re
import sys
from pathlib import Path

import requests

# ─── PATHS & CONFIG ──────────────────────────────────────────────────────────
ROOT = Path(__file__).parent
LETTERS_DIR = ROOT / "letters" / "pdf-signed"
LEAVES_DIR  = ROOT / "leave-applications" / "pdf-signed"
KEY_DIR = Path(r"C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys")
LOGO_URL = "https://technijian.com/wp-content/uploads/2023/08/Logo.jpg"

# CC India leads on every signing invitation so they have a copy of the letter
# being delivered. Ajay handed over the printed copies in person on May 11; this
# Foxit re-send is the corrected electronic version.
CC_RECIPIENTS = [
    {"address": "ABhardwaj@technijian.com", "name": "Ajay Bhardwaj"},
    {"address": "GKumar@technijian.com",    "name": "Gurdeep Kumar"},
]

# ─── ENVELOPE CONFIG (per employee) ──────────────────────────────────────────
# All letters are US Letter (792 pt high). All leave apps are A4 (842 pt high).
#
# Coordinates derived by running fitz.search_for on the regenerated pre-stamped
# PDFs. Field bottom (y_foxit) is aligned to the underscore line baseline.
#
# Letter signature row (page where "Employee Signature: ___ Date: ___" lives):
#   sig_x=170, sig_w=145, date_x=360, date_w=70, height=22-24
#
# Leave-app signature row (page 1, employee underscore line above name):
#   sig_x=72,  sig_w=240, date_x=395, date_w=80
#
# MSA Rajat — page 5 employee block: signature on underscore line above "Rajat Kumar"
#   sig at x=72 width=240 above name at y=524; date row at y~555.

# Standard letter sig block (page 3 for all 5 termination/retrenchment letters):
#   "Employee Signature: ___ Date: ___"   ← sig underscore: x=166.8-314.5, date: x=351.0-433.2
#   "Print Name: ___          Employee No.: ___"  ← name: x=128.1-276.0, empno: x=353.6-435.7
# Y of Print Name row = Y of Signature row + 19.5pt
ENVELOPES = {
    "devesh": {
        "first": "Devesh", "last": "Bhattacharya",
        "email": "bhattacharyadevesh@gmail.com",
        "empno": "TIPL-CSE-2026-01",
        "folder_name": "Technijian — Termination Letter — Devesh Bhattacharya",
        "doc_subject": "Termination of Employment — Probation Period",
        "documents": [
            {
                "path": LETTERS_DIR / "01-Devesh-Bhattacharya-Termination.pdf",
                "label": "Termination Letter",
                "kind": "letter",
                "page_height": 792, "sig_page": 3,
                "sig_y_top": 215.9,
            },
        ],
    },
    "rajat": {
        "first": "Rajat", "last": "Kumar",
        "email": "rajatkumar07860@gmail.com",
        "empno": "TIPL-CSE-2026-02",
        "folder_name": "Technijian — Mutual Separation Agreement — Rajat Kumar",
        "doc_subject": "Mutual Separation Agreement",
        "documents": [
            {
                "path": LETTERS_DIR / "02-Rajat-Kumar-Mutual-Separation-Agreement.pdf",
                "label": "Mutual Separation Agreement",
                "kind": "msa",
                "page_height": 792, "sig_page": 5,
                "sig_y_top": 508.9,
                "date_y_top": 555.2,
            },
        ],
    },
    "aditya": {
        "first": "Aditya", "last": "Saraf",
        "email": "adi.psaraf@gmail.com",
        "empno": "TIPL-CSE-2026-03",
        "folder_name": "Technijian — Termination Letter — Aditya Saraf",
        "doc_subject": "Termination of Employment — Cost Reduction",
        "documents": [
            {
                "path": LETTERS_DIR / "03-Aditya-Saraf-Termination.pdf",
                "label": "Termination Letter",
                "kind": "letter",
                "page_height": 792, "sig_page": 3,
                "sig_y_top": 183.0,
            },
        ],
    },
    "suresh": {
        "first": "Suresh", "last": "Kumar Sharma",
        "email": "sksvats@gmail.com",
        "empno": "TIPL-CSE-2025-04",
        "folder_name": "Technijian — Termination + Leave Application — Suresh Kumar Sharma",
        "doc_subject": "Termination of Employment + Leave Application",
        "documents": [
            {
                "path": LETTERS_DIR / "04-Suresh-Kumar-Sharma-Termination.pdf",
                "label": "Termination Letter",
                "kind": "letter",
                "page_height": 792, "sig_page": 3,
                "sig_y_top": 359.0,
            },
            {
                "path": LEAVES_DIR / "03-Suresh-Kumar-Sharma-Leave-Application.pdf",
                "label": "Leave Application",
                "kind": "leave_app",
                "page_height": 842, "sig_page": 1,
                "sig_y_top": 497.0,
                "date_y_top": 527.6,
            },
        ],
    },
    "yogesh": {
        "first": "Yogesh", "last": "Kumar",
        "email": "Yogeshdixit@gmail.com",
        "empno": "TIPL-CSE-2022-05",
        "folder_name": "Technijian — Retrenchment + Leave Application — Yogesh Kumar",
        "doc_subject": "Notice of Retrenchment (IR Code 2020 §70) + Leave Application",
        "documents": [
            {
                "path": LETTERS_DIR / "05-Yogesh-Kumar-Retrenchment.pdf",
                "label": "Retrenchment Letter",
                "kind": "letter",
                "page_height": 792, "sig_page": 3,
                "sig_y_top": 505.1,
            },
            {
                "path": LEAVES_DIR / "01-Yogesh-Kumar-Leave-Application.pdf",
                "label": "Leave Application",
                "kind": "leave_app",
                "page_height": 842, "sig_page": 1,
                "sig_y_top": 497.0,
                "date_y_top": 527.6,
            },
        ],
    },
    "rahul": {
        "first": "Rahul", "last": "Uniyal",
        "email": "Rahuluniyal2023@gmail.com",
        "empno": "TIPL-CSE-2022-06",
        "folder_name": "Technijian — Retrenchment + Leave Application — Rahul Uniyal",
        "doc_subject": "Notice of Retrenchment (IR Code 2020 §70) + Leave Application",
        "documents": [
            {
                "path": LETTERS_DIR / "06-Rahul-Uniyal-Retrenchment.pdf",
                "label": "Retrenchment Letter",
                "kind": "letter",
                "page_height": 792, "sig_page": 3,
                "sig_y_top": 485.0,
            },
            {
                "path": LEAVES_DIR / "02-Rahul-Uniyal-Leave-Application.pdf",
                "label": "Leave Application",
                "kind": "leave_app",
                "page_height": 842, "sig_page": 1,
                "sig_y_top": 497.0,
                "date_y_top": 527.6,
            },
        ],
    },
}

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

FOXIT_URL = "https://na1.foxitesign.foxit.com/api"

# ─── FIELD BUILDER (Foxit y from TOP, top-left corner, per official docs) ────
# Confirmed via developersguide.foxitesign.foxit.com:
#   "position of fields is relative to the top-left corner of that page"
#   y is the TOP edge of the field, measured from the TOP of the page
#   Field types: 'signature', 'date', 'text' (NOT 'datefield' or 'textfield')
#
# Underscore-line x positions (from PyMuPDF text extraction, all in y_from_top):
#   Letter sig underscore:  x=166.8-314.5  on row y=215.9-226.9 (Devesh) etc
#   Letter date underscore: x=351.0-433.2  same row
#   MSA sig underscore:     x=72.0-241.8   on row y=508.9-519.9 (page 5)
#   MSA date underscore:    x=98.7-246.6   row y=555.2-566.3
#   Leave-app sig line:     x=72.0-241.8   row ~y=503-515 (above name, page 1)
#   Leave-app date:         x=362.8-475.0  row y=527.6-536.6
def fields_for_document(doc_cfg, document_number, envelope_data):
    h = doc_cfg["page_height"]
    pg = doc_cfg["sig_page"]
    kind = doc_cfg["kind"]
    fields = []

    # Fields placement via TEXT TAGS embedded in the DOCX (in white text).
    # processTextTags: True in createfolder triggers Foxit to scan the PDF and
    # auto-convert ${signfield:...} / ${datefield:...} tags to interactive
    # fields at their exact rendered positions. Returns empty here — placement
    # is handled by the document content itself.
    return fields

# ─── FOXIT ENVELOPE ───────────────────────────────────────────────────────────
def create_envelope(keys, env, override_email=None, override_name_first=None, override_name_last=None):
    tok = requests.post(f"{FOXIT_URL}/oauth2/access_token", data={
        "grant_type": "client_credentials",
        "client_id": keys["FOXIT_ID"],
        "client_secret": keys["FOXIT_SECRET"],
        "scope": "read-write",
    }).json()["access_token"]
    hdrs = {"Authorization": f"Bearer {tok}", "Content-Type": "application/json"}

    b64_files, file_names, all_fields = [], [], []
    for di, doc in enumerate(env["documents"], start=1):
        if not doc["path"].exists():
            raise FileNotFoundError(doc["path"])
        b64_files.append(base64.b64encode(doc["path"].read_bytes()).decode())
        file_names.append(doc["path"].name)
        all_fields.extend(fields_for_document(doc, di, env))

    recipient_email = override_email or env["email"]
    recipient_first = override_name_first or env["first"]
    recipient_last  = override_name_last  or env["last"]

    payload = {
        "folderName": env["folder_name"],
        "inputType": "base64",
        "base64FileString": b64_files,
        "fileNames": file_names,
        "sendNow": False,                                  # suppress Foxit signing invitation
        "createEmbeddedSigningSession": True,
        "createEmbeddedSigningSessionForAllParties": True,
        "signInSequence": False,
        "processTextTags": True,                           # scan PDF for ${signfield...} tags
        "parties": [{
            "firstName": recipient_first,
            "lastName":  recipient_last,
            "emailId":   recipient_email,
            "permission": "FILL_FIELDS_AND_SIGN",
            "sequence": 1, "workflowSequence": 1,
        }],
    }
    # No coordinate-based fields — text tags in the DOCX handle placement.
    # (Keep all_fields construction to log what would have been if needed.)
    if all_fields:
        payload["fields"] = all_fields

    r = requests.post(f"{FOXIT_URL}/folders/createfolder",
                       headers=hdrs, json=payload)
    print(f"  Foxit HTTP: {r.status_code}")
    if r.status_code != 200 or not r.text.strip():
        print(f"  Raw response: {r.text[:500]!r}")
        return None, None
    try:
        resp = r.json()
    except Exception as e:
        print(f"  JSON decode failed: {e}")
        print(f"  Raw response: {r.text[:500]!r}")
        return None, None

    if "folder" not in resp:
        print(f"[ERROR] Foxit createfolder failed: {resp}", file=sys.stderr)
        return None, None

    folder = resp["folder"]
    fold_id = folder.get("id") or folder.get("folderId")
    sign_url = None
    for p in folder.get("folderRecipientParties", []):
        if p.get("partyDetails", {}).get("emailId") == recipient_email:
            sign_url = p.get("folderAccessURL") or ""
    if not sign_url:
        for s in resp.get("embeddedSigningSessions", []):
            if s.get("emailIdOfSigner") == recipient_email:
                sign_url = s.get("embeddedSessionURL", "")
    return fold_id, sign_url

# ─── GRAPH EMAIL (branded Technijian) ────────────────────────────────────────
def graph_token(keys):
    return requests.post(
        f"https://login.microsoftonline.com/{keys['M365_TEN']}/oauth2/v2.0/token",
        data={
            "grant_type": "client_credentials",
            "client_id": keys["M365_APP"],
            "client_secret": keys["M365_SEC"],
            "scope": "https://graph.microsoft.com/.default",
        },
    ).json()["access_token"]


def build_email_html(recipient_first_name, env, sign_url):
    doc_list_html = ""
    for d in env["documents"]:
        doc_list_html += (
            f'<li style="margin:6px 0;font-size:14px;color:#1A1A2E;">'
            f'<strong>{d["label"]}</strong></li>'
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
      Document Ready for Your Signature
    </h1>
    <p style="margin:0;font-size:15px;color:rgba(255,255,255,.88);">
      Please review and sign at your earliest convenience.
    </p>
  </td></tr>
  <tr><td style="padding:32px;">
    <p style="margin:0 0 14px;font-size:16px;color:#59595B;line-height:1.6;">Dear {recipient_first_name},</p>
    <p style="margin:0 0 18px;font-size:15px;color:#59595B;line-height:1.6;">
      Further to our communication on May 11, 2026, please find enclosed for your
      signature the corrected version of your separation documentation.
    </p>
    <p style="margin:0 0 18px;font-size:15px;color:#59595B;line-height:1.6;">
      The earlier physical copy you reviewed contained an arithmetic error in the
      Earned Leave calculation. The figures in this electronically delivered
      version reflect the corrected amounts and supersede the earlier document.
    </p>
    <table width="100%" cellpadding="0" cellspacing="0" style="margin:0 0 24px;border:1px solid #E9ECEF;border-radius:6px;">
      <tr><td style="padding:16px 20px;background:#F8F9FA;">
        <p style="margin:0 0 8px;font-size:14px;font-weight:700;color:#1A1A2E;">Documents in this envelope:</p>
        <ul style="margin:0;padding-left:18px;">{doc_list_html}</ul>
      </td></tr>
    </table>
    <table cellpadding="0" cellspacing="0" style="margin:0 auto 28px;">
      <tr><td style="background:#F67D4B;border-radius:6px;">
        <a href="{sign_url}" style="display:inline-block;padding:16px 44px;font-size:17px;font-weight:700;color:#FFFFFF;text-decoration:none;">
          Review &amp; Sign &#8594;
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
      For any questions, please contact
      <a href="mailto:rjain@technijian.com" style="color:#006DB6;text-decoration:none;">Ravi Jain, Director</a>
      &bull;
      <a href="tel:9493798499" style="color:#006DB6;text-decoration:none;">+1 949.379.8499</a>
    </p>
  </td></tr>
  <tr><td style="background:#1A1A2E;padding:24px 32px;">
    <p style="margin:0 0 4px;font-size:13px;color:#FFFFFF;font-weight:700;">Technijian IT Services Pvt. Ltd.</p>
    <p style="margin:0 0 2px;font-size:12px;color:rgba(255,255,255,.6);">Twin Tower, Plot no 7, Sector 22, IT Park, Panchkula 134109, Haryana</p>
    <p style="margin:0 0 6px;font-size:12px;"><a href="https://technijian.com" style="color:#1EAAC8;text-decoration:none;">technijian.com</a></p>
    <p style="margin:0;font-size:10px;color:rgba(255,255,255,.4);font-style:italic;">CONFIDENTIAL — Employer communication</p>
  </td></tr>
</table></td></tr></table></body></html>"""


def send_branded_email(keys, recipient_email, recipient_name, env, sign_url, include_cc=True):
    tok = graph_token(keys)
    hdrs = {"Authorization": f"Bearer {tok}", "Content-Type": "application/json"}
    html = build_email_html(env["first"], env, sign_url)
    message = {
        "Subject": f"Technijian — {env['doc_subject']} — For Your Signature",
        "Body": {"ContentType": "HTML", "Content": html},
        "ToRecipients": [{"EmailAddress": {"Address": recipient_email, "Name": recipient_name}}],
        "From": {"EmailAddress": {"Address": "rjain@technijian.com", "Name": "Ravi Jain - Technijian"}},
    }
    if include_cc:
        message["CcRecipients"] = [
            {"EmailAddress": {"Address": cc["address"], "Name": cc["name"]}}
            for cc in CC_RECIPIENTS
        ]
    mail = {"Message": message, "SaveToSentItems": True}
    r = requests.post(
        "https://graph.microsoft.com/v1.0/users/rjain@technijian.com/sendMail",
        headers=hdrs, json=mail,
    )
    return r.status_code, r.text

# ─── MAIN ─────────────────────────────────────────────────────────────────────
def main():
    ap = argparse.ArgumentParser(description="Send India restructuring envelopes via Foxit eSign")
    grp = ap.add_mutually_exclusive_group(required=True)
    grp.add_argument("--test", action="store_true",
                     help="Send ONE envelope (Devesh's, simplest single-doc) to rjain@technijian.com for verification")
    grp.add_argument("--send", action="store_true",
                     help="Send all 6 envelopes to real personal emails")
    grp.add_argument("--dry-run", action="store_true",
                     help="Print envelope payloads without API calls")
    ap.add_argument("--only", choices=list(ENVELOPES.keys()),
                     help="With --send: only send this one envelope")
    args = ap.parse_args()

    keys = load_keys()

    # Pre-flight: verify all files exist
    print("Pre-flight: verifying all PDFs exist...")
    missing = []
    for k, env in ENVELOPES.items():
        for d in env["documents"]:
            if not d["path"].exists():
                missing.append(d["path"])
    if missing:
        print("MISSING FILES:")
        for m in missing:
            print(f"  - {m}")
        sys.exit(1)
    print(f"  All {sum(len(e['documents']) for e in ENVELOPES.values())} documents present.")

    if args.dry_run:
        print("\n=== DRY-RUN: envelope payloads ===")
        for k, env in ENVELOPES.items():
            print(f"\n[{k}]")
            print(f"  Recipient: {env['first']} {env['last']} <{env['email']}>")
            print(f"  Folder:    {env['folder_name']}")
            print(f"  Documents: {len(env['documents'])}")
            for di, d in enumerate(env["documents"], start=1):
                print(f"    {di}. {d['label']}  ({d['path'].name})")
                for f in fields_for_document(d, di, env):
                    print(f"       field type={f['type']:9s} doc={f['documentNumber']} pg={f['pageNumber']} x={f['x']:6.1f} y={f['y']:6.1f} w={f['width']} h={f['height']}")
        return

    if args.test:
        # Send Devesh's envelope to rjain557@gmail.com — an external email
        # NOT in the Foxit account. This guarantees Foxit treats it as a
        # third-party signer with the proper SIGNER view (not the author view
        # we get when the API account email equals the recipient email).
        env = ENVELOPES["devesh"]
        test_email = "rjain557@gmail.com"
        print(f"\n=== TEST MODE: sending Devesh's envelope (1 doc) to {test_email} ===")
        fold_id, sign_url = create_envelope(
            keys, env,
            override_email=test_email,
            override_name_first="Devesh",
            override_name_last="Test",
        )
        if not fold_id:
            sys.exit(2)
        print(f"  Foxit folder id: {fold_id}")
        print(f"  Signing URL:     {'YES' if sign_url else 'NO'}")
        # Send the branded Technijian email TO the external gmail so the user
        # opens the URL as the gmail signer. NO CC in test mode.
        status, text = send_branded_email(keys, test_email,
                                          "Ravi Jain (TEST)", env, sign_url,
                                          include_cc=False)
        print(f"  Graph email:     {status}")
        if status not in (200, 202):
            print(f"  ERROR body: {text[:300]}")
            sys.exit(3)
        print(f"\nTEST envelope sent. Check rjain@technijian.com inbox.")
        print(f"After review, run:  python send-restructuring-foxit.py --send")
        return

    if args.send:
        keys_to_send = [args.only] if args.only else list(ENVELOPES.keys())
        print(f"\n=== SEND MODE: dispatching {len(keys_to_send)} envelopes ===")
        results = []
        for k in keys_to_send:
            env = ENVELOPES[k]
            print(f"\n[{k}] {env['first']} {env['last']} <{env['email']}>")
            fold_id, sign_url = create_envelope(keys, env)
            if not fold_id:
                results.append((k, None, "createfolder_failed"))
                continue
            print(f"  folder_id={fold_id}  sign_url={'YES' if sign_url else 'NO'}")
            status, text = send_branded_email(
                keys, env["email"], f"{env['first']} {env['last']}",
                env, sign_url,
            )
            print(f"  email_status={status}")
            results.append((k, fold_id, "ok" if status in (200, 202) else f"email_{status}"))

        print(f"\n=== RESULTS ===")
        for k, fid, status in results:
            print(f"  {k:8s}  folder={fid}  status={status}")
        print(f"\nNext step for each: poll for EXECUTED + send completion email")
        print(f"  python scripts/foxit-completion-email.py <folderId>")


if __name__ == "__main__":
    main()
