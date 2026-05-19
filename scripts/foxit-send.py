#!/usr/bin/env python3
"""
Universal Foxit eSign sender for Technijian envelopes.

Single entry point for ALL eSign sends. No per-document scripts. Reads an
envelope config (JSON), converts DOCX -> PDF when needed, verifies that the
PDF actually contains Foxit text tags BEFORE submitting to Foxit (the safety
check that was missing on 2026-05-15 when BBC SOW envelope 33787642 was sent
with zero fields and had to be voided), creates the Foxit envelope with
processTextTags=True and sendNow=False, validates each party's signing URL,
and sends one Technijian-branded Graph email per party using the canonical
Build-SigningEmail template (ported from scripts/send-docusign.ps1 lines
381-586).

Modes:
  --dry-run                 print resolved config + planned actions, no API calls
  --inspect <pdf>           only run the text-tag scan against an existing PDF
  --test --test-email X     replace ALL party emails with X, dispatch a single envelope
                            (proves field placement + email rendering before real send)
  --send                    full production send to the real party emails in the config

Config JSON schema (see scripts/foxit-envelopes/ for examples):
{
  "folder_name": "SOW-CLIENT-001",
  "subject":     "Technijian - <doc> for Signature",
  "doc_subject": "Statement of Work",                 # appears inside email body
  "include_ravi_signature": true,                     # true for client-facing emails
  "documents": [
    { "path": "clients/CLIENT/03_SOW/SOW.docx", "label": "Statement of Work" }
  ],
  "parties": [
    { "first": "Ravi",  "last": "Jain",     "email": "rjain@technijian.com",  "sequence": 1, "role": "tech",   "intro": null },
    { "first": "Bryan", "last": "Burkhart", "email": "bryan@bbc.com",          "sequence": 2, "role": "client", "intro": "Please review and sign the attached SOW for ..." }
  ],
  "signing_mode": "parallel",                          # or "sequential"
  "cc": []                                             # optional [{address, name}]
}

Pre-conditions:
- Credentials in OneDrive vault at
  C:\\Users\\rjain\\OneDrive - Technijian, Inc\\Documents\\VSCODE\\keys\\
  (foxit-esign.md, m365-graph.md)
- DOCX signature blocks must embed Foxit text tags in WHITE text. Use the
  proven pattern from restructuring-2026/generate-letters-docx.js:
      P([ T('Date:  '),
          T('${datefield:1:y:Date_Signed:80:18}', { color:'FFFFFF', size:20 }) ])
- Foxit account notifications must be disabled (My Account -> Notifications
  -> all No) per workstation_integrations vault topic.
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import re
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

import requests

# ─── PATHS / CONSTANTS ──────────────────────────────────────────────────────
ROOT      = Path(__file__).resolve().parents[1]      # tech-legal repo root
KEY_DIR   = Path(r"C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys")
FOXIT_URL = "https://na1.foxitesign.foxit.com/api"
GRAPH_URL = "https://graph.microsoft.com/v1.0"
LOGO_URL  = "https://technijian.com/wp-content/uploads/2023/08/Logo.jpg"
SENDER_EMAIL = "rjain@technijian.com"
SENDER_NAME  = "Ravi Jain - Technijian"
SIGNER_TITLE = "CEO"
RAVI_PHOTO   = "https://technijian.com/wp-content/uploads/2026/03/ravi-jain.jpg"
RAVI_LOGO_FOOTER = "https://technijian.com/wp-content/uploads/2026/03/technijian-logo-full-color-600x125-1.png"


# ─── KEY LOADING ────────────────────────────────────────────────────────────
def load_keys() -> dict:
    foxit_raw = (KEY_DIR / "foxit-esign.md").read_text(encoding="utf-8")
    m365_raw  = (KEY_DIR / "m365-graph.md").read_text(encoding="utf-8")
    keys = {
        "FOXIT_ID":     re.search(r'Client ID[^:]*:\*\*\s*(\S+)', foxit_raw).group(1),
        "FOXIT_SECRET": re.search(r'Client Secret[^:]*:\*\*\s*(\S+)', foxit_raw).group(1),
        "M365_APP":     re.search(r'App Client ID[^:]*:\*\*\s*(\S+)', m365_raw).group(1),
        "M365_TEN":     re.search(r'Tenant ID[^:]*:\*\*\s*(\S+)',     m365_raw).group(1),
        "M365_SEC":     re.search(r'Client Secret[^:]*:\*\*\s*(.+)',  m365_raw).group(1).strip(),
    }
    return keys


# ─── DOCX -> PDF (via Word COM) ─────────────────────────────────────────────
def docx_to_pdf(docx_path: Path, pdf_path: Path) -> None:
    """Convert DOCX to PDF using Microsoft Word COM. Word COM preserves white
    text formatting and inline runs that npm-docx generates, which is critical
    for Foxit text-tag processing."""
    import win32com.client
    word = win32com.client.DispatchEx("Word.Application")
    word.Visible = False
    word.DisplayAlerts = 0
    try:
        doc = word.Documents.Open(str(docx_path),
                                  ConfirmConversions=False,
                                  ReadOnly=True,
                                  AddToRecentFiles=False)
        try:
            doc.SaveAs2(str(pdf_path), FileFormat=17)   # 17 = wdFormatPDF
        finally:
            doc.Close(SaveChanges=False)
    finally:
        word.Quit()


def patch_docx_content_types(docx_path: Path) -> None:
    """npm 'docx' embeds images with `.undefined` extension; Word + python-docx
    reject. Add a Default extension mapping for the file to open cleanly. No-op
    if the patch is already present."""
    import shutil, tempfile, zipfile
    work = Path(tempfile.mkdtemp())
    try:
        with zipfile.ZipFile(docx_path, "r") as zin:
            zin.extractall(work)
        ct_path = work / "[Content_Types].xml"
        ct = ct_path.read_text(encoding="utf-8")
        if 'Extension="undefined"' not in ct:
            ct = ct.replace(
                '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">',
                '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="undefined" ContentType="image/png"/>',
                1,
            )
            ct_path.write_text(ct, encoding="utf-8")
        new_path = docx_path.with_suffix(".docx.tmp")
        with zipfile.ZipFile(new_path, "w", zipfile.ZIP_DEFLATED) as zout:
            for root, _, files in os.walk(work):
                for f in files:
                    full = Path(root) / f
                    arc = full.relative_to(work).as_posix()
                    zout.write(full, arc)
        os.replace(new_path, docx_path)
    finally:
        shutil.rmtree(work, ignore_errors=True)


# ─── PRE-SEND VERIFICATION (the safety check that was missing) ──────────────
@dataclass
class TagScanResult:
    sig_count: int
    date_count: int
    text_count: int
    initial_count: int
    checkbox_count: int

    @property
    def total(self) -> int:
        return self.sig_count + self.date_count + self.text_count + self.initial_count + self.checkbox_count


def scan_pdf_for_foxit_tags(pdf_path: Path) -> TagScanResult:
    """Extract all text from PDF and count Foxit text tags. Catches the case
    where Word COM stripped or mangled the white-text tags (the 2026-05-11 and
    2026-05-15 silent failure mode). Tag colour doesn't matter for PyMuPDF
    text extraction - it returns ALL text on every page.

    Returns counts per tag type. If `total == 0` the envelope MUST NOT be sent;
    the DOCX generator embedded zero tags or Word stripped them all.
    """
    try:
        import fitz  # PyMuPDF
    except ImportError:
        print("ERROR: PyMuPDF (fitz) is required for pre-send tag verification.")
        print("       pip install pymupdf")
        sys.exit(2)

    doc = fitz.open(str(pdf_path))
    blob = ""
    for page in doc:
        blob += page.get_text("text")
    doc.close()
    return TagScanResult(
        sig_count      = blob.count("${signfield")    + blob.count("${s:"),
        date_count     = blob.count("${datefield")    + blob.count("${d:"),
        text_count     = blob.count("${textfield")    + blob.count("${t:"),
        initial_count  = blob.count("${initialfield") + blob.count("${i:"),
        checkbox_count = blob.count("${checkboxfield")+ blob.count("${c:"),
    )


# ─── FOXIT API ──────────────────────────────────────────────────────────────
def foxit_token(keys: dict) -> str:
    r = requests.post(f"{FOXIT_URL}/oauth2/access_token", data={
        "grant_type":    "client_credentials",
        "client_id":     keys["FOXIT_ID"],
        "client_secret": keys["FOXIT_SECRET"],
        "scope":         "read-write",
    })
    r.raise_for_status()
    return r.json()["access_token"]


DEFAULT_SIGN_SUCCESS_URL = "https://technijian.com"


def foxit_create_folder(keys: dict, *,
                        folder_name: str,
                        pdf_paths_with_names: list[tuple[Path, str]],
                        parties: list[dict],
                        sign_in_sequence: bool,
                        sign_success_url: str = DEFAULT_SIGN_SUCCESS_URL) -> dict:
    """Create a Foxit envelope for branded-email signing via folderAccessURL.

    Working pattern (proven 2026-05-15):
    - createEmbeddedSigningSession: True + sendNow: False
      Folder is auto-SHARED on creation (no sendDraftFolder needed).
      Foxit suppresses its own invitation email.
      folderAccessURL (viewDocumentDirect?encrDocId=...) is sent in branded
      Graph email and is the active signing link.
    - signSuccessUrl: https://technijian.com
      Where Foxit redirects each party after their signature completes.

    Multi-party caveat (open issue, see [[feedback_foxit_multiparty_unresolved]]):
    With signInSequence: False (parallel), after the FIRST party signs Foxit's
    intermediate page is the broken fillfieldsinfolder?eetid=&... URL because
    signSuccessUrl only fires on full envelope EXECUTED. With signInSequence:
    True (sequential), each party signs in turn so their signature is the
    last in their workflow segment - signSuccessUrl may fire per party.
    Sequential is the recommended config for multi-party Technijian sends
    until parallel is proven to work without the intermediate-page break.
    """
    tok  = foxit_token(keys)
    hdrs = {"Authorization": f"Bearer {tok}", "Content-Type": "application/json"}
    b64_list  = []
    name_list = []
    for path, label in pdf_paths_with_names:
        b64_list.append(base64.b64encode(path.read_bytes()).decode())
        name_list.append(path.name)
    payload = {
        "folderName":      folder_name,
        "inputType":       "base64",
        "base64FileString":b64_list,
        "fileNames":       name_list,
        "sendNow":         False,                       # suppress Foxit native email
        "processTextTags": True,                        # scan PDF for ${...} tags
        "createEmbeddedSigningSession":            True,  # auto-share folder + branded path
        "createEmbeddedSigningSessionForAllParties": True,
        "signInSequence":  sign_in_sequence,
        "signSuccessUrl":  sign_success_url,             # post-sign redirect target
        "parties":         parties,
    }
    r = requests.post(f"{FOXIT_URL}/folders/createfolder", headers=hdrs, json=payload)
    r.raise_for_status()
    return r.json()


def is_valid_signing_url(url: Optional[str]) -> bool:
    """Trap #12 (2026-05-15): createfolder can return a malformed URL with all
    empty query parameters - looks non-empty but is broken. Foxit returns one
    of three URL shapes; each is validated by its required non-empty token:

      - viewDocumentDirect?encrDocId=...&partySeq=N    (folderAccessURL)
      - embedded/embeddedsign?eetid=...                (embeddedSigningSession)
      - fillfieldsinfolder?eetid=...                   (older variant)
    """
    if not url:
        return False
    if "viewDocumentDirect" in url:
        m = re.search(r"encrDocId=([^&]+)", url)
        return bool(m and m.group(1))
    if "embeddedsign" in url or "fillfieldsinfolder" in url:
        m = re.search(r"eetid=([^&]+)", url)
        return bool(m and m.group(1))
    return False


def foxit_get_folder(keys: dict, folder_id: int) -> dict:
    tok  = foxit_token(keys)
    hdrs = {"Authorization": f"Bearer {tok}"}
    r = requests.get(f"{FOXIT_URL}/folders/myfolder?folderId={folder_id}", headers=hdrs)
    r.raise_for_status()
    return r.json()


def foxit_send_draft_folder(keys: dict, folder_id: int) -> dict:
    """Transition a DRAFT folder to SHARED so recipients can access their
    folderAccessURL. Required when createEmbeddedSigningSession=False AND
    sendNow=False (the default for email-based flows in this harness)."""
    tok  = foxit_token(keys)
    hdrs = {"Authorization": f"Bearer {tok}", "Content-Type": "application/json"}
    r = requests.post(f"{FOXIT_URL}/folders/sendDraftFolder",
                       headers=hdrs, json={"folderId": int(folder_id)})
    r.raise_for_status()
    return r.json()


def extract_signing_urls(create_resp: dict, party_emails: list[str]) -> dict[str, str]:
    """Return {email_lowercase: signing_url}. Pulls from folderRecipientParties
    first, falls back to embeddedSigningSessions. Validates every URL."""
    out: dict[str, str] = {}
    folder = create_resp.get("folder") or {}
    for p in folder.get("folderRecipientParties", []) or []:
        details = p.get("partyDetails") or {}
        email = (details.get("emailId") or "").lower()
        url = p.get("folderAccessURL") or ""
        if email and email not in out and is_valid_signing_url(url):
            out[email] = url
    for s in create_resp.get("embeddedSigningSessions", []) or []:
        email = (s.get("emailIdOfSigner") or "").lower()
        url = s.get("embeddedSessionURL") or ""
        if email and email not in out and is_valid_signing_url(url):
            out[email] = url
    return out


# ─── CANONICAL BRANDED EMAIL (port of Build-SigningEmail) ───────────────────
def build_signing_email(*, recip_name: str, signing_url: str, doc_name: str,
                        sender_name: str = "Ravi Jain", signer_title: str = SIGNER_TITLE,
                        signer_email: str = SENDER_EMAIL,
                        include_signature: bool = True,
                        extra_context: Optional[str] = None) -> str:
    """Canonical Technijian signing-invitation HTML.

    Ported verbatim from scripts/send-docusign.ps1 Build-SigningEmail (lines
    381-586). DO NOT replace this with a custom template. If you need extra
    narrative, pass `extra_context` (one HTML paragraph inserted under the
    greeting). Per vault topic [[feedback_esign_branded_email_template]]."""

    signature_block = ""
    if include_signature:
        signature_block = f"""
<!-- Ravi Jain Email Signature -->
<table role="presentation" width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;margin:0 auto;">
<tr><td style="padding:24px 32px 0;">
<div style="font-family:Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)">Thank you,</div>
<div style="font-family:Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)"><br></div>
<table cellspacing="0" cellpadding="0" border="0" style="max-width:600px">
<tbody>
<tr><td colspan="2" style="border-top:3px solid rgb(246,125,75); padding-bottom:16px"></td></tr>
<tr>
<td style="padding-right:16px; vertical-align:top; width:120px">
<img alt="Ravi Jain" width="120" height="120" src="{RAVI_PHOTO}" style="width:120px; height:120px; border:2px solid rgb(233,236,239); border-radius:6px; display:block">
</td>
<td style="vertical-align:top">
<table cellspacing="0" cellpadding="0" border="0">
<tbody>
<tr><td style="line-height:1.3; padding-bottom:1px; color:rgb(26,26,46)">
<div style="line-height:1.3; font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif; font-size:18px"><span style="font-weight:700">Ravi Jain</span></div>
</td></tr>
<tr><td style="padding-bottom:2px; color:rgb(0,109,182)">
<div style="font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif; font-size:13px"><span style="font-weight:600">CEO</span></div>
</td></tr>
<tr><td style="padding-bottom:8px; color:rgb(89,89,91)">
<div style="font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif; font-size:12px">Technijian</div>
</td></tr>
<tr><td style="line-height:1.7; color:rgb(89,89,91)">
<div style="line-height:1.7; font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif">
<span style="font-size:12px; color:rgb(0,109,182); font-weight:600">T:</span>&nbsp;<span style="font-size:12px; color:rgb(89,89,91)">949.379.8499 x201</span><br>
<span style="font-size:12px; color:rgb(0,109,182); font-weight:600">C:</span>&nbsp;<span style="font-size:12px; color:rgb(89,89,91)">714.402.3164</span><br>
<span style="font-size:12px; color:rgb(0,109,182); font-weight:600">E:</span>&nbsp;<a href="mailto:rjain@technijian.com" style="font-size:12px; color:rgb(0,109,182); text-decoration:none">rjain@technijian.com</a><br>
<span style="font-size:12px; color:rgb(0,109,182); font-weight:600">W:</span>&nbsp;<a href="https://technijian.com" style="font-size:12px; color:rgb(0,109,182); text-decoration:none">technijian.com</a>
</div>
</td></tr>
<tr><td style="line-height:1.6; padding-top:6px; color:rgb(173,181,189)">
<div style="line-height:1.6; font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif; font-size:11px">
<span style="color:rgb(0,109,182); font-weight:600">USA:</span>&nbsp;18 Technology Dr., Ste 141, Irvine, CA 92618<br>
<span style="color:rgb(0,109,182); font-weight:600">India:</span>&nbsp;Plot No. 07, 1st Floor, Panchkula IT Park, Panchkula, Haryana 134109
</div>
</td></tr>
</tbody></table>
</td>
</tr>
<tr><td colspan="2" style="padding-top:14px; padding-bottom:10px">
<table cellspacing="0" cellpadding="0" border="0" style="width:100%"><tbody><tr><td style="border-top:2px solid rgb(0,109,182)"></td></tr></tbody></table>
</td></tr>
<tr><td colspan="2" style="padding-bottom:10px">
<img alt="Technijian" width="160" src="{RAVI_LOGO_FOOTER}" style="width:160px; display:block">
</td></tr>
<tr><td colspan="2" style="border-top:1px solid rgb(233,236,239); padding-top:8px">
<p style="line-height:1.4; margin:0px; font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif; font-size:10px; color:rgb(173,181,189)">This email and any attachments are confidential and intended solely for the addressee. If you have received this message in error, please notify the sender immediately and delete it from your system.</p>
</td></tr>
</tbody>
</table>
</td></tr>
</table>"""

    extra_paragraph = ""
    if extra_context:
        extra_paragraph = f"""<p style="margin:0 0 16px;font-size:15px;color:#59595B;line-height:1.65;">{extra_context}</p>"""

    return f"""<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Document Ready for Signature</title></head>
<body style="margin:0;padding:0;background-color:#F8F9FA;font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif;">
<div style="display:none;max-height:0;overflow:hidden;">{sender_name} sent you a document to review and sign.</div>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#F8F9FA;">
<tr><td align="center" style="padding:24px 16px;">
<table role="presentation" width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background-color:#FFFFFF;border-radius:8px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.06);">
  <tr><td style="padding:24px 32px;border-bottom:3px solid #006DB6;">
    <img src="{LOGO_URL}" alt="Technijian" width="200" style="display:block;max-width:200px;height:auto;">
  </td></tr>
  <tr><td style="padding:40px 32px;background-color:#006DB6;text-align:center;">
    <h1 style="margin:0 0 12px;font-size:28px;font-weight:700;color:#FFFFFF;line-height:1.2;">Document Ready for Signature</h1>
    <p style="margin:0;font-size:16px;color:#FFFFFF;opacity:0.85;">{sender_name} has sent you a document to review and sign.</p>
  </td></tr>
  <tr><td style="padding:32px;">
    <p style="margin:0 0 16px;font-size:16px;color:#59595B;line-height:1.6;">Hi {recip_name},</p>
    <p style="margin:0 0 16px;font-size:16px;color:#59595B;line-height:1.6;">Please review and sign the following document from <strong style="color:#1A1A2E;">Technijian, Inc.</strong>:</p>
    {extra_paragraph}
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:0 0 24px;border:1px solid #E9ECEF;border-radius:6px;overflow:hidden;">
      <tr><td style="padding:16px 20px;background-color:#F8F9FA;">
        <p style="margin:0 0 4px;font-size:14px;font-weight:600;color:#1A1A2E;">{doc_name}</p>
        <p style="margin:0;font-size:13px;color:#59595B;">Sent by {sender_name}, {signer_title} &bull; Technijian, Inc.</p>
      </td></tr>
    </table>
    <table role="presentation" cellpadding="0" cellspacing="0" style="margin:0 auto;">
      <tr><td style="background-color:#F67D4B;border-radius:6px;">
        <a href="{signing_url}" style="display:inline-block;padding:16px 40px;font-size:18px;font-weight:600;color:#FFFFFF;text-decoration:none;letter-spacing:0.5px;">Review &amp; Sign Document</a>
      </td></tr>
    </table>
    <p style="margin:24px 0 0;font-size:14px;color:#59595B;line-height:1.6;text-align:center;">If the button doesn't work, copy and paste this link into your browser:<br><a href="{signing_url}" style="color:#006DB6;word-break:break-all;font-size:12px;">{signing_url}</a></p>
  </td></tr>
  <tr><td style="padding:0 32px;"><div style="border-top:2px solid #1EAAC8;"></div></td></tr>
  <tr><td style="padding:20px 32px;">
    <p style="margin:0;font-size:13px;color:#59595B;line-height:1.6;">If you have any questions about this document, please contact <a href="mailto:{signer_email}" style="color:#006DB6;text-decoration:none;">{sender_name}</a> at <a href="mailto:{signer_email}" style="color:#006DB6;text-decoration:none;">{signer_email}</a> or call <a href="tel:9493798499" style="color:#006DB6;text-decoration:none;">949.379.8499</a>.</p>
  </td></tr>
  <tr><td style="padding:24px 32px;background-color:#1A1A2E;">
    <p style="margin:0 0 8px;font-size:13px;color:#FFFFFF;"><strong>Technijian, Inc.</strong></p>
    <p style="margin:0 0 4px;font-size:12px;color:#FFFFFF;opacity:0.7;">18 Technology Dr., Ste 141, Irvine, CA 92618</p>
    <p style="margin:0 0 4px;font-size:12px;color:#FFFFFF;opacity:0.7;"><a href="tel:9493798499" style="color:#1EAAC8;text-decoration:none;">949.379.8499</a> &bull; <a href="https://technijian.com" style="color:#1EAAC8;text-decoration:none;">technijian.com</a></p>
    <p style="margin:8px 0 0;font-size:11px;color:#FFFFFF;opacity:0.5;">technology as a solution</p>
  </td></tr>
</table>
{signature_block}
</td></tr>
</table>
</body>
</html>"""


# ─── GRAPH SEND ─────────────────────────────────────────────────────────────
def graph_token(keys: dict) -> str:
    r = requests.post(
        f"https://login.microsoftonline.com/{keys['M365_TEN']}/oauth2/v2.0/token",
        data={"grant_type":   "client_credentials",
              "client_id":    keys["M365_APP"],
              "client_secret":keys["M365_SEC"],
              "scope":        "https://graph.microsoft.com/.default"},
    )
    r.raise_for_status()
    return r.json()["access_token"]


def graph_send(keys: dict, *, to_email: str, to_name: str,
               subject: str, html: str,
               cc: Optional[list[dict]] = None) -> tuple[int, str]:
    tok = graph_token(keys)
    hdrs = {"Authorization": f"Bearer {tok}", "Content-Type": "application/json"}
    message = {
        "Subject": subject,
        "Body":    {"ContentType": "HTML", "Content": html},
        "ToRecipients": [{"EmailAddress": {"Address": to_email, "Name": to_name}}],
        "From":         {"EmailAddress": {"Address": SENDER_EMAIL, "Name": SENDER_NAME}},
    }
    if cc:
        message["CcRecipients"] = [{"EmailAddress": {"Address": c["address"], "Name": c.get("name", c["address"])}} for c in cc]
    payload = {"Message": message, "SaveToSentItems": True}
    r = requests.post(f"{GRAPH_URL}/users/{SENDER_EMAIL}/sendMail", headers=hdrs, json=payload)
    return r.status_code, r.text


# ─── CONFIG VALIDATION ──────────────────────────────────────────────────────
@dataclass
class Envelope:
    folder_name: str
    subject: str
    doc_subject: str
    include_ravi_signature: bool
    documents: list[dict]
    parties: list[dict]
    signing_mode: str
    cc: list[dict]


def load_envelope(config_path: Path) -> Envelope:
    raw = json.loads(config_path.read_text(encoding="utf-8"))
    documents = []
    for d in raw["documents"]:
        p = Path(d["path"])
        if not p.is_absolute():
            p = ROOT / d["path"]
        if not p.exists():
            raise FileNotFoundError(f"Document not found: {p}")
        documents.append({"path": p, "label": d.get("label", p.stem)})
    parties = []
    seen_seq, seen_email = set(), set()
    for pty in raw["parties"]:
        seq = int(pty["sequence"])
        em  = pty["email"].strip().lower()
        if seq in seen_seq:
            raise ValueError(f"Duplicate party sequence: {seq}")
        if em in seen_email:
            raise ValueError(f"Duplicate party email: {em}")
        seen_seq.add(seq)
        seen_email.add(em)
        parties.append({
            "first":    pty["first"],
            "last":     pty["last"],
            "email":    pty["email"],
            "sequence": seq,
            "role":     pty.get("role", "client"),
            "intro":    pty.get("intro"),
        })
    return Envelope(
        folder_name             = raw["folder_name"],
        subject                 = raw["subject"],
        doc_subject             = raw["doc_subject"],
        include_ravi_signature  = raw.get("include_ravi_signature", True),
        documents               = documents,
        parties                 = parties,
        signing_mode            = raw.get("signing_mode", "parallel"),
        cc                      = raw.get("cc", []),
    )


# ─── ORCHESTRATION ──────────────────────────────────────────────────────────
def prepare_pdfs(envelope: Envelope, *, log_prefix: str = "") -> list[tuple[Path, str]]:
    """Patch + convert any DOCX inputs; return list of (PDF path, label).
    Patches/converts happen in-place next to the source DOCX, preserving the
    same file stem with a .pdf extension."""
    out: list[tuple[Path, str]] = []
    for d in envelope.documents:
        src: Path = d["path"]
        if src.suffix.lower() in (".docx", ".doc"):
            print(f"{log_prefix}Patching content types: {src.name}")
            patch_docx_content_types(src)
            pdf = src.with_suffix(".pdf")
            print(f"{log_prefix}Converting to PDF: {src.name} -> {pdf.name}")
            docx_to_pdf(src, pdf)
            print(f"{log_prefix}  PDF written: {pdf.stat().st_size:,} bytes")
            out.append((pdf, d["label"]))
        elif src.suffix.lower() == ".pdf":
            out.append((src, d["label"]))
        else:
            raise ValueError(f"Unsupported document type: {src}")
    return out


def verify_tags(pdfs: list[tuple[Path, str]]) -> bool:
    """Scan each PDF for Foxit text tags. Returns True iff every PDF has at
    least one signfield tag (the bare minimum for a signable envelope)."""
    all_ok = True
    print()
    print("PRE-SEND TAG VERIFICATION")
    print("=" * 70)
    for pdf, label in pdfs:
        res = scan_pdf_for_foxit_tags(pdf)
        ok = res.sig_count >= 1
        symbol = "OK " if ok else "FAIL"
        print(f"  [{symbol}] {pdf.name}: sig={res.sig_count} date={res.date_count} "
              f"text={res.text_count} initial={res.initial_count} check={res.checkbox_count}")
        if not ok:
            all_ok = False
            print(f"         ABORT: {pdf.name} has zero `${{signfield...}}` tags.")
            print(f"         The DOCX generator must embed Foxit text tags in WHITE text")
            print(f"         in the signature block (proven pattern in")
            print(f"         restructuring-2026/generate-letters-docx.js).")
    print("=" * 70)
    print()
    return all_ok


def dispatch(envelope: Envelope, *, mode: str, test_email: Optional[str] = None,
             test_first: str = "Test", test_last: str = "Recipient") -> Optional[int]:
    """Returns the Foxit folder id on success, None on failure."""
    keys = load_keys()

    print(f"\nMODE: {mode.upper()}")
    print(f"Folder name: {envelope.folder_name}")
    print(f"Subject:     {envelope.subject}")
    print(f"Documents:   {[d['label'] for d in envelope.documents]}")
    print(f"Parties:     " + ", ".join(f"{p['first']} {p['last']} <{p['email']}> seq={p['sequence']} role={p['role']}" for p in envelope.parties))
    print(f"Signing:     {envelope.signing_mode}")

    pdfs = prepare_pdfs(envelope, log_prefix="  ")

    if not verify_tags(pdfs):
        return None

    # Build the parties payload. In test mode rewrite every email to test_email.
    sign_in_sequence = envelope.signing_mode == "sequential"
    if mode == "test":
        # Send a single-party envelope to the test email so the URL is a true signer-view.
        first_party = envelope.parties[0]
        foxit_parties = [{
            "firstName": test_first,
            "lastName":  test_last,
            "emailId":   test_email,
            "permission":"FILL_FIELDS_AND_SIGN",
            "sequence":  1,
            "workflowSequence": 1,
        }]
        graph_recipients = [{
            "email": test_email,
            "name":  f"{test_first} {test_last}",
            "first": test_first,
            "intro": "TEST envelope - verifies field placement, email rendering, and signing flow.",
            "role":  "test",
        }]
    else:  # send or dry-run
        foxit_parties = [{
            "firstName": p["first"],
            "lastName":  p["last"],
            "emailId":   p["email"],
            "permission":"FILL_FIELDS_AND_SIGN",
            "sequence":  p["sequence"],
            "workflowSequence": p["sequence"] if sign_in_sequence else 1,
        } for p in envelope.parties]
        graph_recipients = [{
            "email": p["email"],
            "name":  f"{p['first']} {p['last']}",
            "first": p["first"],
            "intro": p.get("intro"),
            "role":  p["role"],
        } for p in envelope.parties]

    if mode == "dry-run":
        print("\nDRY-RUN: would create Foxit envelope with payload:")
        print(json.dumps({
            "folderName": envelope.folder_name,
            "sendNow":    False,
            "processTextTags": True,
            "createEmbeddedSigningSession": True,
            "createEmbeddedSigningSessionForAllParties": True,
            "signInSequence":  sign_in_sequence,
            "signSuccessUrl":  DEFAULT_SIGN_SUCCESS_URL,
            "parties":         foxit_parties,
        }, indent=2))
        print("\nDRY-RUN: would send Graph email to each of:")
        for r in graph_recipients:
            print(f"  - {r['name']} <{r['email']}> role={r['role']}")
        return None

    # ── Real send ───────────────────────────────────────────────────────────
    mode_label = "sequential" if sign_in_sequence else "parallel"
    print(f"\nCreating Foxit envelope (embedded session ON, signInSequence={sign_in_sequence}, {mode_label}) ...")
    resp = foxit_create_folder(keys,
                                folder_name = envelope.folder_name,
                                pdf_paths_with_names = pdfs,
                                parties = foxit_parties,
                                sign_in_sequence = sign_in_sequence)
    folder = resp.get("folder") or {}
    fold_id = folder.get("id") or folder.get("folderId")
    if not fold_id:
        print("ERROR: createfolder did not return a folder id.")
        print(json.dumps(resp, indent=2)[:1500])
        return None

    print(f"  folder id: {fold_id}")
    target_emails = [p["emailId"].lower() for p in foxit_parties]
    urls = extract_signing_urls(resp, target_emails)

    # Trap #12: malformed URL handling. Poll up to 5x with 3s sleep.
    missing = [e for e in target_emails if e not in urls]
    if missing:
        print(f"  Missing valid signing URLs for {missing} - polling /myfolder ...")
        for attempt in range(5):
            time.sleep(3)
            polled = foxit_get_folder(keys, fold_id)
            urls = extract_signing_urls({"folder": polled.get("folder", polled)}, target_emails)
            missing = [e for e in target_emails if e not in urls]
            if not missing:
                print(f"  Poll attempt {attempt+1}: all URLs ready.")
                break
        if missing:
            print(f"  ERROR: still missing URLs after 5 polls: {missing}")
            print(f"  Cancelling folder {fold_id} ...")
            cancel_folder(keys, fold_id, "Signing URLs did not become valid; abort to avoid sending broken links")
            return None

    print("  All party signing URLs validated.")
    for email, url in urls.items():
        print(f"    {email}: {url[:80]}...")

    # ── Send Graph emails per party ─────────────────────────────────────────
    print("\nSending Technijian-branded Graph emails ...")
    doc_name_for_email = envelope.documents[0]["label"] if len(envelope.documents) == 1 else envelope.folder_name
    sent_ok = True
    for r in graph_recipients:
        url = urls[r["email"].lower()]
        # Ravi signature: only for client-facing emails per [[feedback_docusign_branded_email]]
        include_sig = envelope.include_ravi_signature and r["role"] != "tech"
        html = build_signing_email(
            recip_name        = r["first"],
            signing_url       = url,
            doc_name          = doc_name_for_email,
            signer_email      = SENDER_EMAIL,
            include_signature = include_sig,
            extra_context     = r.get("intro"),
        )
        status, body = graph_send(keys,
                                   to_email = r["email"],
                                   to_name  = r["name"],
                                   subject  = envelope.subject,
                                   html     = html,
                                   cc       = envelope.cc if r["role"] == "client" else None)
        ok = status in (200, 202)
        print(f"  [{ 'OK' if ok else 'FAIL' }] {r['email']}: HTTP {status}")
        if not ok:
            print(f"        body: {body[:400]}")
            sent_ok = False

    if not sent_ok:
        print(f"\nWARNING: one or more Graph emails failed. Folder {fold_id} is still live.")
        print("         Either resend the missing emails manually or cancel the folder.")
        return fold_id

    print("\n" + "=" * 70)
    print(" SENT")
    print("=" * 70)
    print(f"  Folder ID:    {fold_id}")
    print(f"  Folder Name:  {envelope.folder_name}")
    print(f"  Parties:      {len(graph_recipients)}")
    print()
    print(" After ALL parties have signed, run:")
    print(f"   python scripts/foxit-completion-email.py {fold_id}")
    print("=" * 70)
    return fold_id


def cancel_folder(keys: dict, folder_id: int, reason: str) -> None:
    tok  = foxit_token(keys)
    hdrs = {"Authorization": f"Bearer {tok}", "Content-Type": "application/json"}
    r = requests.post(f"{FOXIT_URL}/folders/cancelFolder",
                       headers=hdrs,
                       json={"folderId": int(folder_id), "reason_for_cancellation": reason})
    print(f"  cancelFolder HTTP {r.status_code}: {r.text[:200]}")


# ─── CLI ────────────────────────────────────────────────────────────────────
def main() -> None:
    ap = argparse.ArgumentParser(description="Universal Foxit eSign sender (single entry point for ALL envelopes).")
    ap.add_argument("--config",   required=False, help="Path to envelope JSON config.")
    ap.add_argument("--inspect",  required=False, help="PDF path; only run text-tag scan (no API calls).")
    grp = ap.add_mutually_exclusive_group()
    grp.add_argument("--dry-run", action="store_true", help="Validate, scan tags, print plan. No API calls.")
    grp.add_argument("--test",    action="store_true", help="Dispatch ONE envelope to --test-email (party emails ignored).")
    grp.add_argument("--send",    action="store_true", help="Dispatch to the real parties in the config.")
    ap.add_argument("--test-email", help="Required with --test. The single recipient for the test envelope.")
    ap.add_argument("--test-first", default="Test")
    ap.add_argument("--test-last",  default="Recipient")
    args = ap.parse_args()

    if args.inspect:
        path = Path(args.inspect)
        if not path.exists():
            print(f"ERROR: {path} not found"); sys.exit(2)
        res = scan_pdf_for_foxit_tags(path)
        print(f"{path}:")
        print(f"  signfield:    {res.sig_count}")
        print(f"  datefield:    {res.date_count}")
        print(f"  textfield:    {res.text_count}")
        print(f"  initialfield: {res.initial_count}")
        print(f"  checkboxfield:{res.checkbox_count}")
        print(f"  TOTAL TAGS:   {res.total}")
        return

    if not args.config:
        ap.error("--config is required unless --inspect is used")
    envelope = load_envelope(Path(args.config))

    if args.dry_run:
        dispatch(envelope, mode="dry-run")
        return
    if args.test:
        if not args.test_email:
            ap.error("--test requires --test-email")
        dispatch(envelope, mode="test", test_email=args.test_email,
                 test_first=args.test_first, test_last=args.test_last)
        return
    if args.send:
        dispatch(envelope, mode="send")
        return
    ap.error("One of --dry-run, --test, --send (or --inspect) is required")


if __name__ == "__main__":
    main()
