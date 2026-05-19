"""Create an Outlook DRAFT replying to Foxit Case #731733 — Ratnesh's 6 questions.

Does NOT send. Creates as Reply All (preserves thread, adds Kevin Coronel +
support-notification on Cc automatically). User reviews in Drafts and sends.

Format: Aptos 12pt rgb(0,0,0), one-div-per-line; ravi-signature.html appended.
"""
import re, sys, json, requests
from pathlib import Path
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

KEYFILE = Path(r"C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md")
SIGFILE = Path(r"C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html")
USER    = "RJain@technijian.com"

# Ratnesh's message ID from check_foxit_inbox.py output
RATNESH_MSG_ID = ("AAMkAGNlYjM0OTA4LThjMjYtNGQ3My1iNDg1LTQ2MTI5NTg0NzFlOQBGAAAAAAC88IffM67"
                  "WS4tSyVwwqYmJBwBhk-ls8ubYRazD3tGgncxCAAAAAAENAACgx7VhNWW1QYCgfGa-8kbOAA"
                  "Z2O-CdAAA=")

txt = KEYFILE.read_text(encoding="utf-8")
def g(l): return re.search(rf"\*\*{re.escape(l)}:\*\*\s*([^\s\n]+)", txt).group(1).strip()
TENANT, CID, SEC = g("Tenant ID"), g("App Client ID"), g("Client Secret")

tok = requests.post(
    f"https://login.microsoftonline.com/{TENANT}/oauth2/v2.0/token",
    data={"client_id": CID, "client_secret": SEC,
          "scope": "https://graph.microsoft.com/.default",
          "grant_type": "client_credentials"},
).json()["access_token"]
hdrs = {"Authorization": f"Bearer {tok}", "Content-Type": "application/json"}

# ─── Ravi formatting helper ─────────────────────────────────────────────────
STYLE = "font-family:Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)"
def D(text=""):
    return f'<div style="{STYLE}"><br></div>' if text == "" else f'<div style="{STYLE}">{text}</div>'

# ─── Reconstructed payloads from foxit-send.py:foxit_create_folder() ────────
# Both folders used the same code path; only the `parties` array and
# signInSequence flag differ. File contents (base64 PDF) elided for brevity.
PAYLOAD_33788882 = {
    "folderName":      "TEST-2PARTY-Sequential-Tech-First",
    "inputType":       "base64",
    "base64FileString":["<base64-encoded PDF bytes elided>"],
    "fileNames":       ["TEST-2PARTY-Sequential-Tech-First.pdf"],
    "sendNow":                                  False,
    "processTextTags":                           True,
    "createEmbeddedSigningSession":              True,
    "createEmbeddedSigningSessionForAllParties": True,
    "signInSequence":                            True,
    "signSuccessUrl":  "https://technijian.com",
    "parties": [
        {"firstName":"Ravi","lastName":"Test-Tech",  "emailId":"rjain557@hotmail.com",
         "sequence":1,"signerRole":"SIGNER"},
        {"firstName":"Ravi","lastName":"Test-Client","emailId":"rjain557@gmail.com",
         "sequence":2,"signerRole":"SIGNER"},
    ],
}

PAYLOAD_33789480 = {
    "folderName":      "SOW-BBC-001-AutoLeadGen-Build",
    "inputType":       "base64",
    "base64FileString":["<base64-encoded PDF bytes elided>"],
    "fileNames":       ["SOW-BBC-001-AutoLeadGen-Build.pdf"],
    "sendNow":                                  False,
    "processTextTags":                           True,
    "createEmbeddedSigningSession":              True,
    "createEmbeddedSigningSessionForAllParties": True,
    "signInSequence":                            True,
    "signSuccessUrl":  "https://technijian.com",
    "parties": [
        {"firstName":"Ravi", "lastName":"Jain",    "emailId":"rjain@technijian.com",
         "sequence":1,"signerRole":"SIGNER"},
        {"firstName":"Bryan","lastName":"Burkhart","emailId":"bryan@burkhartbros.com",
         "sequence":2,"signerRole":"SIGNER"},
    ],
}

def pj(p):
    return ("<pre style=\"font-family:Consolas,'Courier New',monospace;font-size:10pt;"
            "background:#f5f5f5;padding:8px;border:1px solid #ddd;white-space:pre-wrap;"
            f"\">{json.dumps(p, indent=2)}</pre>")

# ─── Body lines ─────────────────────────────────────────────────────────────
lines = [
    D("Hi Ratnesh,"),
    D(),
    D("Thank you for picking this up so quickly. Answers to each of your questions below."),
    D(),
    D("<b>Account-related queries</b>"),
    D("1. <b>Account Owner / Super Admin email:</b> rjain@technijian.com"),
    D("2. <b>Account Number (My Profile):</b> 2662230"),
    D("3. <b>Sender / Author Email Address (envelope initiator):</b> rjain@technijian.com"),
    D(),
    D("<b>Issue-related queries</b>"),
    D(),
    D("<b>Q1 — Raw JSON bodies for Folder 33789480 (failed) and Folder 33788882 (working test)</b>"),
    D(),
    D("Both folders were created by the same Python helper function (<code>foxit_create_folder()</code> in our <code>foxit-send.py</code>). The flag values are identical; only the <code>parties</code> array and the file contents differ. The base64-encoded PDF bytes are elided below for size — let me know if you need the actual file payloads and I will re-send them as attachments."),
    D(),
    D("<b>Folder 33788882</b> (working test — sequential, gmail+hotmail):"),
    pj(PAYLOAD_33788882),
    D(),
    D("<b>Folder 33789480</b> (failed redirect — same flags, real two-party SOW):"),
    pj(PAYLOAD_33789480),
    D(),
    D("Note that <code>signInSequence</code>, <code>createEmbeddedSigningSession</code>, <code>createEmbeddedSigningSessionForAllParties</code>, <code>sendNow</code>, <code>processTextTags</code>, and <code>signSuccessUrl</code> are identical between the two envelopes. The only meaningful difference is the party identities (anonymous gmail/hotmail addresses vs. real corporate addresses)."),
    D(),
    D("<b>Q2 — Session rendering: iframe or full-window redirect?</b>"),
    D(),
    D("<b>Full-window redirect.</b> We do not embed Foxit inside an iframe on a Technijian portal. The flow is:"),
    D("&nbsp;&nbsp;a) Foxit returns <code>folderAccessURL</code> values from <code>/folders/createfolder</code>."),
    D("&nbsp;&nbsp;b) We send each signer a Technijian-branded HTML email (Microsoft 365 Graph <code>sendMail</code>) containing an <code>&lt;a href&gt;</code> to their <code>viewDocumentDirect?encrDocId=...</code> URL."),
    D("&nbsp;&nbsp;c) The signer clicks the link in their email client (Outlook / Gmail / etc.). Their primary browser tab navigates directly to <code>na1.foxitesign.foxit.com/documents/viewDocumentDirect?...</code>."),
    D("&nbsp;&nbsp;d) The signer signs inside Foxit's own UI in that tab. We do not wrap, frame, or post-message anything."),
    D(),
    D("After Signer 1 hits Finish, that same browser tab is the one Foxit redirects to <code>/documents/fillfieldsinfolder?eetid=&amp;embeddedType=&amp;userParam=&amp;iphiid=</code> with all parameters empty — which is the error we are reporting."),
    D(),
    D("<b>Q3 — Are you watching webhooks, or did you extract both folderAccessURL strings at create-time?</b>"),
    D(),
    D("<b>Both URLs are extracted simultaneously at envelope-creation time.</b> Specifically:"),
    D("&nbsp;&nbsp;a) Immediately after <code>POST /folders/createfolder</code> returns, we read <code>response.folder.folderRecipientParties[*].folderAccessURL</code> for every party in the array."),
    D("&nbsp;&nbsp;b) We validate each URL contains the required token <code>viewDocumentDirect</code> (we poll <code>/folders/myfolder</code> up to 5× with 3s sleep if any party's URL is initially empty — Trap #12 in our internal notes)."),
    D("&nbsp;&nbsp;c) Each URL is then immediately emailed to its respective party from our branded mailbox."),
    D(),
    D("We are <b>not</b> running a webhook listener. We do not subscribe to <code>signer_signed</code> or <code>folder_partially_signed</code> events. We only poll <code>/folders/myfolder</code> for <code>folderStatus == EXECUTED</code> after-the-fact, to know when to download the signed PDF and send the Technijian completion email."),
    D(),
    D("If the supported pattern is to defer the second party's URL fetch until <i>after</i> Signer 1 completes — via a webhook handler — please confirm. We are happy to add a webhook subscriber if that is the correct multi-party design."),
    D(),
    D("<b>Additional context that may help triage</b>"),
    D(),
    D("&nbsp;&nbsp;• Both envelopes used <code>signInSequence: true</code>. We have also tried <code>signInSequence: false</code> (parallel) — same broken-redirect symptom after the first signer."),
    D("&nbsp;&nbsp;• In the working test (33788882), both parties happened to be the same human (me) signing from two different mail clients — gmail and hotmail. I wonder whether the working result was an artifact of single-user signing both ends rather than the URLs being valid for distinct humans."),
    D("&nbsp;&nbsp;• Our Foxit API client ID is <code>076daa485dd843aeb9b6ad34f3511d14</code>. Plan: API tier (renewed 2026-04-29, $1,000/yr, 500 envelopes)."),
    D("&nbsp;&nbsp;• The folder is auto-SHARED on creation with this flag combination — no separate <code>sendDraftFolder</code> call is made. Folder status transitions <code>DRAFT → SHARED → PARTIALLY SIGNED</code> as expected. The post-sign UI is the only thing that breaks."),
    D(),
    D("Please let me know what else would be helpful. I can capture an HAR file of a fresh failure if useful."),
    D(),
]

body_text = "\n".join(lines)
signature = SIGFILE.read_text(encoding="utf-8")
new_body_html = body_text + "\n" + signature

# ─── Create reply-all draft, then PATCH body to inject our content above quote
reply_url = f"https://graph.microsoft.com/v1.0/users/{USER}/messages/{RATNESH_MSG_ID}/createReplyAll"
r = requests.post(reply_url, headers=hdrs, json={})
if r.status_code not in (200, 201):
    print(f"createReplyAll FAILED: {r.status_code}\n{r.text[:1500]}")
    sys.exit(1)

draft = r.json()
draft_id = draft["id"]
existing_body = draft.get("body", {}).get("content", "")

# Insert content immediately after the opening <body ...> tag so it appears
# above Outlook's auto-generated from-header + quoted history.
body_open_match = re.search(r"<body[^>]*>", existing_body, re.I)
if body_open_match:
    insert_at = body_open_match.end()
    full_html = existing_body[:insert_at] + new_body_html + existing_body[insert_at:]
else:
    full_html = new_body_html + existing_body

patch = {"body": {"contentType": "HTML", "content": full_html}}
patch_url = f"https://graph.microsoft.com/v1.0/users/{USER}/messages/{draft_id}"
pr = requests.patch(patch_url, headers=hdrs, json=patch)
if pr.status_code not in (200, 201, 204):
    print(f"PATCH body FAILED: {pr.status_code}\n{pr.text[:1500]}")
    sys.exit(1)

# ─── Report ──────────────────────────────────────────────────────────────────
final = requests.get(
    patch_url + "?$select=subject,toRecipients,ccRecipients,body,webLink",
    headers=hdrs).json()

print("OK — draft created in Outlook Drafts")
print(f"  draft id:  {draft_id}")
print(f"  subject:   {final['subject']}")
to_addrs = [t["emailAddress"]["address"] for t in final.get("toRecipients", [])]
cc_addrs = [t["emailAddress"]["address"] for t in final.get("ccRecipients", [])]
print(f"  to:        {to_addrs}")
print(f"  cc:        {cc_addrs}")
print(f"  body chars: {len(final.get('body',{}).get('content',''))}")
print(f"  webLink:   {final.get('webLink','')[:120]}")

Path(r"c:\tmp\_foxit-731733-reply-draft-id.txt").write_text(draft_id, encoding="utf-8")
print(f"\nDraft ID saved to c:\\tmp\\_foxit-731733-reply-draft-id.txt")
print("Review in Outlook Drafts before sending.")
