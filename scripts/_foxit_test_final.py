"""
Foxit eSign final test:
- Builds a branded Technijian PDF
- Creates Foxit envelope with sendNow=False (no Foxit email)
- Sends ONE branded Technijian email via Graph with the folderAccessURL
"""
import requests, base64, json, re, io

FOXIT_ID     = "076daa485dd843aeb9b6ad34f3511d14"
FOXIT_SECRET = "aea505e511364b7a8fb533bcd1b0d099"
FOXIT_URL    = "https://na1.foxitesign.foxit.com/api"
SIGNER_NAME  = "Ravi Jain"
SIGNER_EMAIL = "rjain@technijian.com"
LOGO_URL     = "https://technijian.com/wp-content/uploads/2023/08/Logo.jpg"
PDF_OUT      = r"c:\vscode\tech-legal\tech-legal\docs\foxit-test-v5.pdf"

keys_path = r"C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md"
m365_raw  = open(keys_path).read()
M365_APP  = re.search(r'App Client ID[^:]*:\*\*\s*(\S+)', m365_raw).group(1)
M365_TEN  = re.search(r'Tenant ID[^:]*:\*\*\s*(\S+)',     m365_raw).group(1)
M365_SEC  = re.search(r'Client Secret[^:]*:\*\*\s*(.+)',  m365_raw).group(1).strip()

# ── Build branded PDF ──────────────────────────────────────────────────────────
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter
from reportlab.lib.colors import HexColor

buf = io.BytesIO()
cv  = canvas.Canvas(buf, pagesize=letter)
W, H = letter   # 612 x 792 pts; y=0 at bottom (PDF standard)

# Header
cv.setFillColor(HexColor("#006DB6"))
cv.rect(0, H-60, W, 60, fill=1, stroke=0)
cv.setFillColor(HexColor("#FFFFFF"))
cv.setFont("Helvetica-Bold", 20)
cv.drawCentredString(W/2, H-40, "TECHNIJIAN, INC.")

cv.setFillColor(HexColor("#F67D4B"))
cv.rect(0, H-65, W, 5, fill=1, stroke=0)

cv.setFillColor(HexColor("#59595B"))
cv.setFont("Helvetica", 11)
cv.drawCentredString(W/2, H-90, "eSign Integration Test  ·  May 4, 2026")

# Body
cv.setFillColor(HexColor("#1A1A2E"))
cv.setFont("Helvetica-Bold", 12)
cv.drawString(72, H-130, "Purpose")
cv.setFillColor(HexColor("#59595B"))
cv.setFont("Helvetica", 10)
for i, line in enumerate([
    "Functional test of the Foxit eSign API. Signing below confirms:",
    "  1.  API credentials are valid and the account is not in trial mode",
    "  2.  Signature fields are correctly placed on the document",
    "  3.  Signed PDF downloads without any Foxit watermark or trial branding",
    "  4.  Signing invitation arrives as a Technijian-branded email (not from Foxit)",
]):
    cv.drawString(72, H-150-(i*16), line)

# Divider
cv.setStrokeColor(HexColor("#1EAAC8"))
cv.setLineWidth(1.5)
cv.line(72, H-248, W-72, H-248)

# Signature section
cv.setFillColor(HexColor("#1A1A2E"))
cv.setFont("Helvetica-Bold", 12)
cv.drawString(72, H-276, "AUTHORIZED SIGNATURE")

# Field y-positions (from bottom of page, PDF coordinate system)
SIG_Y   = int(H - 360)   # 432 pts from bottom
NAME_Y  = int(H - 420)   # 372 pts from bottom
TITLE_Y = int(H - 456)   # 336 pts from bottom
DATE_Y  = int(H - 492)   # 300 pts from bottom

cv.setFillColor(HexColor("#59595B"))
cv.setFont("Helvetica", 9)
cv.drawString(72,  SIG_Y + 38,   "Signature:")
cv.drawString(72,  NAME_Y + 16,  "Printed Name:")
cv.drawString(72,  TITLE_Y + 16, "Title:")
cv.drawString(72,  DATE_Y + 16,  "Date Signed:")

cv.setStrokeColor(HexColor("#CCCCCC"))
cv.setLineWidth(0.75)
cv.line(72,  SIG_Y,   380, SIG_Y)
cv.line(160, NAME_Y,  420, NAME_Y)
cv.line(115, TITLE_Y, 420, TITLE_Y)
cv.line(145, DATE_Y,  360, DATE_Y)

# Footer
cv.setFillColor(HexColor("#1A1A2E"))
cv.rect(0, 0, W, 42, fill=1, stroke=0)
cv.setFillColor(HexColor("#FFFFFF"))
cv.setFont("Helvetica", 8)
cv.drawCentredString(W/2, 16,
    "Technijian, Inc.  |  18 Technology Dr., Ste 141, Irvine, CA 92618"
    "  |  949.379.8499  |  technijian.com")
cv.save()
pdf_bytes = buf.getvalue()
with open(PDF_OUT, "wb") as f:
    f.write(pdf_bytes)
print(f"PDF built: {len(pdf_bytes):,} bytes  ->  {PDF_OUT}")
print(f"Field coords (y from bottom): sig={SIG_Y}  name={NAME_Y}  title={TITLE_Y}  date={DATE_Y}")

# ── Foxit: create envelope (sendNow=False = no Foxit email) ────────────────────
tok = requests.post(f"{FOXIT_URL}/oauth2/access_token", data={
    "grant_type":"client_credentials","client_id":FOXIT_ID,
    "client_secret":FOXIT_SECRET,"scope":"read-write"
}).json()["access_token"]
hdrs = {"Authorization": f"Bearer {tok}", "Content-Type": "application/json"}

b64 = base64.b64encode(pdf_bytes).decode()
payload = {
    "folderName": "Technijian-eSign-Test-v5",
    "inputType": "base64",
    "base64FileString": [b64],
    "fileNames": ["Technijian-eSign-Test.pdf"],
    "sendNow": False,
    "createEmbeddedSigningSession": True,
    "createEmbeddedSigningSessionForAllParties": True,
    "signInSequence": False,
    # ── Technijian email branding (applies to all Foxit-sent emails for this envelope) ──
    "emailTemplateLogo": LOGO_URL,
    "includeLogo": True,
    "email_btnBgColor": "#F67D4B",
    "email_btnTxtColor": "#FFFFFF",
    "emailHeader": (
        "<table width='100%' cellpadding='0' cellspacing='0' border='0'>"
        "<tr><td style='background:#006DB6;padding:24px 32px;text-align:center;'>"
        "<p style='margin:0 0 6px;font-size:20px;font-weight:700;color:#FFFFFF;"
        "font-family:Arial,Helvetica,sans-serif;letter-spacing:1px;'>TECHNIJIAN, INC.</p>"
        "<p style='margin:0;font-size:13px;color:rgba(255,255,255,.85);"
        "font-family:Arial,Helvetica,sans-serif;'>Signed Document — For Your Records</p>"
        "</td></tr>"
        "<tr><td style='height:4px;background:#F67D4B;'></td></tr>"
        "</table>"
    ),
    "emailFooter": (
        "<table width='100%' cellpadding='0' cellspacing='0' border='0'>"
        "<tr><td style='height:2px;background:#1EAAC8;'></td></tr>"
        "<tr><td style='background:#1A1A2E;padding:20px 32px;text-align:center;'>"
        "<p style='margin:0 0 4px;font-size:13px;font-weight:700;color:#FFFFFF;"
        "font-family:Arial,Helvetica,sans-serif;'>Technijian, Inc.</p>"
        "<p style='margin:0 0 4px;font-size:11px;color:rgba(255,255,255,.6);"
        "font-family:Arial,Helvetica,sans-serif;'>18 Technology Dr., Ste 141, Irvine, CA 92618</p>"
        "<p style='margin:0 0 6px;font-size:11px;font-family:Arial,Helvetica,sans-serif;'>"
        "<a href='tel:9493798499' style='color:#1EAAC8;text-decoration:none;'>949.379.8499</a>"
        " &bull; "
        "<a href='https://technijian.com' style='color:#1EAAC8;text-decoration:none;'>technijian.com</a>"
        "</p>"
        "<p style='margin:0;font-size:10px;color:rgba(255,255,255,.4);font-style:italic;"
        "font-family:Arial,Helvetica,sans-serif;'>technology as a solution</p>"
        "</td></tr>"
        "</table>"
    ),
    "parties": [{
        "firstName": "Ravi", "lastName": "Jain",
        "emailId": SIGNER_EMAIL,
        "permission": "FILL_FIELDS_AND_SIGN",
        "sequence": 1, "workflowSequence": 1,
        "optOutEmails": True
    }],
    "fields": [
        {"type":"signature","x":72,  "y":SIG_Y,   "width":308,"height":38,
         "pageNumber":1,"documentNumber":1,"party":1,"required":True},
        {"type":"textfield","x":160, "y":NAME_Y,  "width":260,"height":22,
         "pageNumber":1,"documentNumber":1,"party":1,"name":"printed_name","required":True},
        {"type":"textfield","x":115, "y":TITLE_Y, "width":305,"height":22,
         "pageNumber":1,"documentNumber":1,"party":1,"name":"title","required":True},
        {"type":"datefield","x":145, "y":DATE_Y,  "width":215,"height":22,
         "pageNumber":1,"documentNumber":1,"party":1,"name":"date_signed","required":True},
    ]
}

resp = requests.post(f"{FOXIT_URL}/folders/createfolder", headers=hdrs, json=payload).json()

# Extract folderAccessURL (persistent) or fall back to embedded session URL
sign_url = None
for p in resp.get("folder", {}).get("folderRecipientParties", []):
    if p.get("partyDetails", {}).get("emailId") == SIGNER_EMAIL:
        sign_url = p.get("folderAccessURL") or ""
if not sign_url:
    for s in resp.get("embeddedSigningSessions", []):
        if s.get("emailIdOfSigner") == SIGNER_EMAIL:
            sign_url = s.get("embeddedSessionURL", "")

folder   = resp.get("folder", {})
fold_id  = folder.get("id") or folder.get("folderId") or "?"
print(f"Foxit envelope created. folder.id={fold_id}  signing_url={'YES' if sign_url else 'NO'}")

# ── Graph: ONE branded Technijian email ────────────────────────────────────────
graph_tok = requests.post(
    f"https://login.microsoftonline.com/{M365_TEN}/oauth2/v2.0/token",
    data={"grant_type":"client_credentials","client_id":M365_APP,
          "client_secret":M365_SEC,"scope":"https://graph.microsoft.com/.default"}
).json()["access_token"]
graph_hdrs = {"Authorization": f"Bearer {graph_tok}", "Content-Type": "application/json"}

html = """<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"></head>
<body style="margin:0;padding:0;background:#F8F9FA;
             font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" style="background:#F8F9FA;">
<tr><td align="center" style="padding:32px 16px;">
<table width="600" cellpadding="0" cellspacing="0"
  style="max-width:600px;background:#FFFFFF;border-radius:8px;overflow:hidden;
         box-shadow:0 2px 12px rgba(0,0,0,.08);">

  <tr><td style="padding:24px 32px 20px;border-bottom:4px solid #006DB6;">
    <img src="LOGO_URL_PLACEHOLDER" alt="Technijian" width="180"
         style="display:block;max-width:180px;height:auto;">
  </td></tr>

  <tr><td style="background:#006DB6;padding:36px 32px;text-align:center;">
    <h1 style="margin:0 0 10px;font-size:24px;font-weight:700;
               color:#FFFFFF;line-height:1.25;">
      Document Ready for Signature
    </h1>
    <p style="margin:0;font-size:15px;color:rgba(255,255,255,.88);">
      Please review and sign the document below.
    </p>
  </td></tr>

  <tr><td style="padding:32px;">
    <p style="margin:0 0 14px;font-size:16px;color:#59595B;line-height:1.6;">
      Hi Ravi,
    </p>
    <p style="margin:0 0 24px;font-size:15px;color:#59595B;line-height:1.6;">
      Please sign the <strong style="color:#1A1A2E;">Technijian eSign Integration Test</strong>
      document below. After signing, download the completed PDF to verify there is
      no Foxit watermark.
    </p>

    <table width="100%" cellpadding="0" cellspacing="0"
      style="margin:0 0 28px;border:1px solid #E9ECEF;border-radius:6px;">
      <tr><td style="padding:16px 20px;background:#F8F9FA;">
        <p style="margin:0 0 4px;font-size:14px;font-weight:700;color:#1A1A2E;">
          Technijian eSign Integration Test
        </p>
        <p style="margin:0;font-size:13px;color:#59595B;">
          Sent by Ravi Jain, CEO &bull; Technijian, Inc.
        </p>
      </td></tr>
    </table>

    <table cellpadding="0" cellspacing="0" style="margin:0 auto 28px;">
      <tr><td style="background:#F67D4B;border-radius:6px;">
        <a href="SIGN_URL_PLACEHOLDER"
           style="display:inline-block;padding:16px 44px;font-size:17px;
                  font-weight:700;color:#FFFFFF;text-decoration:none;">
          Review &amp; Sign &#8594;
        </a>
      </td></tr>
    </table>

    <p style="margin:0;font-size:12px;color:#888;text-align:center;line-height:1.7;">
      If the button does not work, copy this link into your browser:<br>
      <a href="SIGN_URL_PLACEHOLDER"
         style="color:#006DB6;word-break:break-all;font-size:11px;">
        SIGN_URL_PLACEHOLDER
      </a>
    </p>
  </td></tr>

  <tr><td style="padding:0 32px;">
    <div style="border-top:2px solid #1EAAC8;"></div>
  </td></tr>

  <tr><td style="padding:18px 32px;">
    <p style="margin:0;font-size:13px;color:#59595B;line-height:1.6;">
      Questions? Contact
      <a href="mailto:rjain@technijian.com"
         style="color:#006DB6;text-decoration:none;">Ravi Jain</a>
      &bull;
      <a href="tel:9493798499"
         style="color:#006DB6;text-decoration:none;">949.379.8499</a>
    </p>
  </td></tr>

  <tr><td style="background:#1A1A2E;padding:24px 32px;">
    <p style="margin:0 0 4px;font-size:13px;color:#FFFFFF;font-weight:700;">
      Technijian, Inc.
    </p>
    <p style="margin:0 0 2px;font-size:12px;color:rgba(255,255,255,.6);">
      18 Technology Dr., Ste 141, Irvine, CA 92618
    </p>
    <p style="margin:0 0 6px;font-size:12px;">
      <a href="tel:9493798499"
         style="color:#1EAAC8;text-decoration:none;">949.379.8499</a>
      &nbsp;&bull;&nbsp;
      <a href="https://technijian.com"
         style="color:#1EAAC8;text-decoration:none;">technijian.com</a>
    </p>
    <p style="margin:0;font-size:10px;color:rgba(255,255,255,.4);font-style:italic;">
      technology as a solution
    </p>
  </td></tr>

</table></td></tr></table></body></html>""".replace(
    "LOGO_URL_PLACEHOLDER", LOGO_URL
).replace(
    "SIGN_URL_PLACEHOLDER", sign_url
)

mail = {
    "Message": {
        "Subject": "Technijian — Document Ready for Signature",
        "Body": {"ContentType": "HTML", "Content": html},
        "ToRecipients": [{"EmailAddress": {"Address": SIGNER_EMAIL, "Name": SIGNER_NAME}}],
        "From": {"EmailAddress": {"Address": SIGNER_EMAIL, "Name": "Ravi Jain - Technijian"}}
    },
    "SaveToSentItems": True
}

r2 = requests.post(
    f"https://graph.microsoft.com/v1.0/users/{SIGNER_EMAIL}/sendMail",
    headers=graph_hdrs, json=mail
)
print(f"Graph email status: {r2.status_code}")
if r2.status_code in (200, 202):
    print("SUCCESS: One Technijian-branded signing invitation sent to rjain@technijian.com")
    print(f"Subject: Technijian — Document Ready for Signature")
    print(f"From:    Ravi Jain - Technijian <rjain@technijian.com>")
    print(f"Foxit email: SUPPRESSED (sendNow=False)")
    print()
    print("=" * 62)
    print(" NEXT STEP — after recipient signs, run:")
    print(f"   python scripts/foxit-completion-email.py {fold_id}")
    print(" This will detect EXECUTED status and send the branded")
    print(" Technijian completion email with the signed PDF attached.")
    print("=" * 62)
else:
    print(f"ERROR: {r2.text[:500]}")
