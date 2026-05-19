"""
Draft a Foxit API support email in Ravi's Outlook drafts folder.

Creates as DRAFT (not sent). User reviews + proofreads, then a separate call
moves it to Sent via /messages/<id>/send.
"""
import json
import re
import sys
from pathlib import Path

import requests

KEY_DIR = Path(r"C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys")
SENDER_EMAIL = "rjain@technijian.com"
SENDER_NAME  = "Ravi Jain - Technijian"
SUPPORT_TO   = "support@foxit.com"
SIG_PATH     = Path(r"C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html")

# ── Load M365 Graph creds ──────────────────────────────────────────────
m365_raw = (KEY_DIR / "m365-graph.md").read_text(encoding="utf-8")
M365_APP = re.search(r'App Client ID[^:]*:\*\*\s*(\S+)', m365_raw).group(1)
M365_TEN = re.search(r'Tenant ID[^:]*:\*\*\s*(\S+)',     m365_raw).group(1)
M365_SEC = re.search(r'Client Secret[^:]*:\*\*\s*(.+)',  m365_raw).group(1).strip()

graph_tok = requests.post(
    f"https://login.microsoftonline.com/{M365_TEN}/oauth2/v2.0/token",
    data={"grant_type":"client_credentials","client_id":M365_APP,
          "client_secret":M365_SEC,"scope":"https://graph.microsoft.com/.default"}
).json()["access_token"]
HDR = {"Authorization": f"Bearer {graph_tok}", "Content-Type": "application/json"}

# ── Build email body in Ravi's Outlook-native format ──────────────────
# Pattern (per [[feedback_ravi_email_format]] vault topic):
#   <div style="font-family:Aptos,...,sans-serif; font-size:12pt; color:rgb(0,0,0)">line</div>
# Empty line = <div ...><br></div>. Concatenate ravi-signature.html for closing.
STYLE = 'font-family:Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)'
def D(text=""):
    return f'<div style="{STYLE}">{text or "<br>"}</div>'

body_lines = [
    D("Hello Foxit Support Team,"),
    D(),
    D("I am writing to request guidance on the proper way to implement a custom multi-party signing workflow using the Foxit eSign API. We are an MSP and our internal counsel and engineering teams need to send Statements of Work, MSAs, and other agreements for electronic signature, branded as Technijian rather than as Foxit eSign."),
    D(),
    D("<b>What we are trying to accomplish</b>"),
    D(),
    D("A two-party signing flow where:"),
    D("&nbsp;&nbsp;1. Technijian (Ravi Jain, CEO) counter-signs first."),
    D("&nbsp;&nbsp;2. The client signs second."),
    D("&nbsp;&nbsp;3. Each signer receives a Technijian-branded HTML invitation email sent by us via Microsoft 365 Graph (so the brand and from-address are ours, not Foxit&rsquo;s)."),
    D("&nbsp;&nbsp;4. After each signer completes their signature, they should be redirected to a Technijian thank-you / landing page rather than to a Foxit error page."),
    D(),
    D("<b>Current implementation</b>"),
    D(),
    D("We POST to <code>/api/folders/createfolder</code> with the following payload:"),
    D("&nbsp;&nbsp;&middot; <code>sendNow: false</code> &mdash; we suppress Foxit&rsquo;s native invitation email and send our own branded one via Graph."),
    D("&nbsp;&nbsp;&middot; <code>processTextTags: true</code> &mdash; signature fields are embedded as white-text tags in the DOCX (<code>${signfield:N:y:Name:____}</code> format)."),
    D("&nbsp;&nbsp;&middot; <code>createEmbeddedSigningSession: true</code> and <code>createEmbeddedSigningSessionForAllParties: true</code>."),
    D("&nbsp;&nbsp;&middot; <code>signInSequence: true</code> for sequential signing."),
    D("&nbsp;&nbsp;&middot; <code>signSuccessUrl: \"https://technijian.com\"</code>."),
    D(),
    D("We extract <code>folderRecipientParties[].folderAccessURL</code> (the <code>viewDocumentDirect?encrDocId=...</code> URL) and send it to each party in our branded Graph email."),
    D(),
    D("<b>What works</b>"),
    D(),
    D("&nbsp;&nbsp;&middot; <b>Single-party envelopes work cleanly.</b> We have signed numerous internal documents (6 employee termination letters in May 2026) using this exact pattern with a single signer. The branded email arrives, the user clicks, signs, and Foxit redirects them cleanly &mdash; either to <code>signSuccessUrl</code> or to Foxit&rsquo;s default thank-you page."),
    D("&nbsp;&nbsp;&middot; <b>One specific multi-party envelope worked.</b> A test envelope using two external email addresses (gmail + hotmail) for both parties signed cleanly end-to-end."),
    D(),
    D("<b>The issue we cannot resolve</b>"),
    D(),
    D("When we use the same payload to send a real two-party envelope, after the FIRST party signs, Foxit redirects them to this URL:"),
    D(),
    D("<code>https://na1.foxitesign.foxit.com/documents/fillfieldsinfolder?eetid=&amp;embeddedType=&amp;userParam=&amp;iphiid=</code>"),
    D(),
    D("All query parameters are empty. The page renders Foxit&rsquo;s branded error screen:"),
    D(),
    D("<i>&ldquo;Looks like something went wrong! &mdash; some error in processing documents. Please press back and try again or contact support.&rdquo;</i>"),
    D(),
    D("The signer&rsquo;s signature IS captured (we see folder status transition to <code>PARTIALLY SIGNED</code>), but their post-sign experience is a Foxit-branded error page. We have hit this on multiple envelopes over the past day."),
    D(),
    D("<b>What we have tried</b>"),
    D(),
    D("&nbsp;&nbsp;&middot; Toggling <code>createEmbeddedSigningSession</code> on/off. When off, the folder is left in <code>DRAFT</code> status and recipients get &ldquo;This document is not available for esignature right now.&rdquo; Calling <code>/folders/sendDraftFolder</code> transitions to <code>SHARED</code> but appears to also trigger Foxit&rsquo;s own native invitation email, defeating our branded email pattern."),
    D("&nbsp;&nbsp;&middot; Toggling <code>signInSequence</code> between true and false. Both modes have surfaced the broken redirect for the intermediate signer in different scenarios."),
    D("&nbsp;&nbsp;&middot; Setting and unsetting <code>signSuccessUrl</code>. Setting it to <code>https://technijian.com</code> resolves the broken redirect for single-party envelopes but does not appear to fire for the intermediate signer in a sequential multi-party envelope."),
    D("&nbsp;&nbsp;&middot; Adjusting the document layout to keep all signature fields on a single page versus split across pages."),
    D(),
    D("As a workaround we are now pre-stamping our internal signature as an image on the PDF before uploading, and sending only the client as a single-party envelope. That works, but it sidesteps the platform&rsquo;s multi-party capability."),
    D(),
    D("<b>Questions for your support team</b>"),
    D(),
    D("&nbsp;&nbsp;1. What is the supported configuration for a Foxit eSign envelope where (a) the invitation is sent via OUR email system rather than Foxit&rsquo;s, (b) two or more parties sign, and (c) each signer is redirected to a custom landing page (<code>signSuccessUrl</code>) after their individual signature completes?"),
    D("&nbsp;&nbsp;2. Does <code>signSuccessUrl</code> fire per-party in sequential signing, or only after the entire envelope reaches <code>EXECUTED</code>?"),
    D("&nbsp;&nbsp;3. With <code>createEmbeddedSigningSession: true</code> and <code>sendNow: false</code>, what is the expected behaviour when an intermediate signer in a multi-party envelope completes their part?"),
    D("&nbsp;&nbsp;4. Is there a documented way to call <code>/folders/sendDraftFolder</code> (or transition <code>DRAFT</code> &rarr; <code>SHARED</code>) without Foxit emitting its own native invitation email?"),
    D("&nbsp;&nbsp;5. Do you recommend a different API pattern altogether for this use case (custom-branded email + multi-party signing + per-party redirect)?"),
    D(),
    D("If it helps your investigation, our affected Foxit folder IDs from today (already cancelled) are: 33787569, 33788155, 33788197, 33788227, 33788485, 33788491, 33788499, 33788649, 33789128, 33789261, 33789397, 33789480. The proven-working test folder is 33788882. Our Foxit account client ID begins <code>076daa48</code>."),
    D(),
    D("Any documentation, sample payloads, or escalation guidance would be greatly appreciated. We are willing to adjust our approach to match what the API actually supports."),
    D(),
]

# Concatenate signature
sig = SIG_PATH.read_text(encoding="utf-8")
html_body = "\n".join(body_lines) + "\n" + sig

# ── Create draft via Graph ─────────────────────────────────────────────
draft = {
    "subject": "Foxit eSign API Support Request - Multi-Party Branded Email Signing",
    "body": {"contentType": "HTML", "content": html_body},
    "toRecipients": [{"emailAddress": {"address": SUPPORT_TO, "name": "Foxit Support"}}],
}

r = requests.post(
    f"https://graph.microsoft.com/v1.0/users/{SENDER_EMAIL}/messages",
    headers=HDR, json=draft,
)
print(f"Create draft HTTP {r.status_code}")
if r.status_code not in (200, 201):
    print(r.text[:500]); sys.exit(2)
msg = r.json()
print(f"Draft message id: {msg['id']}")
print(f"Subject:          {msg['subject']}")
print(f"To:               {[t['emailAddress']['address'] for t in msg['toRecipients']]}")
print(f"BodyPreview:      {msg.get('bodyPreview','')[:160]}")
print()
print("DRAFT CREATED in Ravi's Outlook drafts folder. ID saved to /tmp.")
Path(r"c:\tmp").mkdir(exist_ok=True)
Path(r"c:\tmp\_foxit-support-draft-id.txt").write_text(msg["id"], encoding="utf-8")
print(f"Draft id stored: c:\\tmp\\_foxit-support-draft-id.txt")
