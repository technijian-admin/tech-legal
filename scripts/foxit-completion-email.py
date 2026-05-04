"""
foxit-completion-email.py
Polls a Foxit folder until EXECUTED, then sends ONE branded Technijian
completion email via Graph with the signed PDF attached.

Usage:
    python foxit-completion-email.py <folderId>

Called by the main send script after envelope creation, or run standalone.
"""
import sys, time, base64, re, requests

# ── Config ─────────────────────────────────────────────────────────────────────
FOXIT_ID     = "076daa485dd843aeb9b6ad34f3511d14"
FOXIT_SECRET = "aea505e511364b7a8fb533bcd1b0d099"
FOXIT_URL    = "https://na1.foxitesign.foxit.com/api"
LOGO_URL     = "https://technijian.com/wp-content/uploads/2023/08/Logo.jpg"
SENDER_EMAIL = "rjain@technijian.com"
SENDER_NAME  = "Ravi Jain - Technijian"

POLL_INTERVAL_SEC = 20    # check every 20 seconds
POLL_TIMEOUT_SEC  = 1800  # give up after 30 minutes

keys_path = r"C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md"
m365_raw  = open(keys_path).read()
M365_APP  = re.search(r'App Client ID[^:]*:\*\*\s*(\S+)', m365_raw).group(1)
M365_TEN  = re.search(r'Tenant ID[^:]*:\*\*\s*(\S+)',     m365_raw).group(1)
M365_SEC  = re.search(r'Client Secret[^:]*:\*\*\s*(.+)',  m365_raw).group(1).strip()

# ── Helpers ─────────────────────────────────────────────────────────────────────
def foxit_token():
    return requests.post(f"{FOXIT_URL}/oauth2/access_token", data={
        "grant_type": "client_credentials",
        "client_id": FOXIT_ID, "client_secret": FOXIT_SECRET, "scope": "read-write"
    }).json()["access_token"]

def graph_token():
    return requests.post(
        f"https://login.microsoftonline.com/{M365_TEN}/oauth2/v2.0/token",
        data={"grant_type": "client_credentials", "client_id": M365_APP,
              "client_secret": M365_SEC, "scope": "https://graph.microsoft.com/.default"}
    ).json()["access_token"]

def get_folder(tok, folder_id):
    hdrs = {"Authorization": f"Bearer {tok}"}
    r = requests.get(f"{FOXIT_URL}/folders/myfolder", headers=hdrs,
                     params={"folderId": folder_id})
    return r.json().get("folder", {})

def get_activity(tok, folder_id):
    hdrs = {"Authorization": f"Bearer {tok}"}
    r = requests.get(f"{FOXIT_URL}/folders/viewActivityHistory", headers=hdrs,
                     params={"folderId": folder_id})
    return r.json().get("details", {})

def download_signed_pdf(tok, folder_id):
    hdrs = {"Authorization": f"Bearer {tok}"}
    r = requests.get(f"{FOXIT_URL}/folders/download", headers=hdrs,
                     params={"folderId": folder_id})
    if r.status_code == 200 and r.content[:4] == b'%PDF':
        return r.content
    return None

def completion_html(folder_name, signer_name, signer_email, executed_time):
    return f"""<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"></head>
<body style="margin:0;padding:0;background:#F8F9FA;
             font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" style="background:#F8F9FA;">
<tr><td align="center" style="padding:32px 16px;">
<table width="600" cellpadding="0" cellspacing="0"
  style="max-width:600px;background:#FFFFFF;border-radius:8px;overflow:hidden;
         box-shadow:0 2px 12px rgba(0,0,0,.08);">

  <tr><td style="padding:24px 32px 20px;border-bottom:4px solid #006DB6;">
    <img src="{LOGO_URL}" alt="Technijian" width="180"
         style="display:block;max-width:180px;height:auto;">
  </td></tr>

  <tr><td style="background:#006DB6;padding:36px 32px;text-align:center;">
    <div style="display:inline-block;background:rgba(255,255,255,.15);
                border-radius:50%;width:56px;height:56px;line-height:56px;
                font-size:28px;color:#FFFFFF;margin-bottom:16px;">&#10003;</div>
    <h1 style="margin:0 0 10px;font-size:24px;font-weight:700;
               color:#FFFFFF;line-height:1.25;">
      Document Successfully Executed
    </h1>
    <p style="margin:0;font-size:15px;color:rgba(255,255,255,.88);">
      All signatures have been collected and the document is now legally binding.
    </p>
  </td></tr>

  <tr><td style="padding:32px;">
    <p style="margin:0 0 20px;font-size:15px;color:#59595B;line-height:1.6;">
      Hi {signer_name.split()[0]},
    </p>

    <table width="100%" cellpadding="0" cellspacing="0"
      style="margin:0 0 28px;border:1px solid #E9ECEF;border-radius:6px;overflow:hidden;">
      <tr><td colspan="2"
        style="padding:12px 20px;background:#F8F9FA;border-bottom:1px solid #E9ECEF;">
        <p style="margin:0;font-size:13px;font-weight:700;color:#1A1A2E;">
          Document Details
        </p>
      </td></tr>
      <tr>
        <td style="padding:12px 20px;font-size:13px;color:#888;
                   border-bottom:1px solid #E9ECEF;width:140px;">Document</td>
        <td style="padding:12px 20px;font-size:13px;color:#1A1A2E;font-weight:600;
                   border-bottom:1px solid #E9ECEF;">{folder_name}</td>
      </tr>
      <tr>
        <td style="padding:12px 20px;font-size:13px;color:#888;
                   border-bottom:1px solid #E9ECEF;">Signed by</td>
        <td style="padding:12px 20px;font-size:13px;color:#1A1A2E;
                   border-bottom:1px solid #E9ECEF;">{signer_name} &lt;{signer_email}&gt;</td>
      </tr>
      <tr>
        <td style="padding:12px 20px;font-size:13px;color:#888;">Executed</td>
        <td style="padding:12px 20px;font-size:13px;color:#1A1A2E;">{executed_time}</td>
      </tr>
    </table>

    <table width="100%" cellpadding="0" cellspacing="0"
      style="margin:0 0 24px;background:#F0FBF0;border:1px solid #C3E6CB;
             border-radius:6px;">
      <tr><td style="padding:16px 20px;">
        <p style="margin:0;font-size:14px;color:#155724;line-height:1.6;">
          <strong>The signed document is attached to this email.</strong><br>
          Please save it for your records.
        </p>
      </td></tr>
    </table>
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

</table></td></tr></table></body></html>"""

def send_completion_email(folder_id, folder_name, signer_name, signer_email,
                           executed_time, pdf_bytes):
    gtok = graph_token()
    hdrs = {"Authorization": f"Bearer {gtok}", "Content-Type": "application/json"}

    pdf_b64 = base64.b64encode(pdf_bytes).decode()
    safe_name = re.sub(r'[^\w\-]', '-', folder_name) + "-SIGNED.pdf"

    mail = {
        "Message": {
            "Subject": f"Technijian — Document Executed: {folder_name}",
            "Body": {
                "ContentType": "HTML",
                "Content": completion_html(folder_name, signer_name,
                                           signer_email, executed_time)
            },
            "ToRecipients": [{"EmailAddress": {
                "Address": signer_email, "Name": signer_name
            }}],
            "From": {"EmailAddress": {
                "Address": SENDER_EMAIL, "Name": SENDER_NAME
            }},
            "Attachments": [{
                "@odata.type": "#microsoft.graph.fileAttachment",
                "Name": safe_name,
                "ContentType": "application/pdf",
                "ContentBytes": pdf_b64
            }]
        },
        "SaveToSentItems": True
    }

    r = requests.post(
        f"https://graph.microsoft.com/v1.0/users/{SENDER_EMAIL}/sendMail",
        headers=hdrs, json=mail
    )
    return r.status_code

# ── Main ────────────────────────────────────────────────────────────────────────
def main():
    if len(sys.argv) < 2:
        print("Usage: python foxit-completion-email.py <folderId>")
        sys.exit(1)

    folder_id   = int(sys.argv[1])
    deadline    = time.time() + POLL_TIMEOUT_SEC
    print(f"Polling folder {folder_id} for EXECUTED status "
          f"(every {POLL_INTERVAL_SEC}s, timeout {POLL_TIMEOUT_SEC//60}min)...")

    while time.time() < deadline:
        ftok   = foxit_token()
        folder = get_folder(ftok, folder_id)
        status = folder.get("folderStatus", "UNKNOWN")
        print(f"  [{time.strftime('%H:%M:%S')}] status={status}")

        if status == "EXECUTED":
            print("  EXECUTED — downloading signed PDF...")
            pdf = download_signed_pdf(ftok, folder_id)
            if not pdf:
                print("  ERROR: could not download signed PDF"); sys.exit(1)
            print(f"  Downloaded {len(pdf):,} bytes")

            # Get execution details from activity history
            activity  = get_activity(ftok, folder_id)
            executed_time = activity.get("latestActivityDate", "")
            folder_name   = folder.get("folderName", str(folder_id))
            parties       = folder.get("folderRecipientParties", [])
            signer        = parties[0].get("partyDetails", {}) if parties else {}
            signer_name   = f"{signer.get('firstName','')} {signer.get('lastName','')}".strip()
            signer_email  = signer.get("emailId", SENDER_EMAIL)

            print(f"  Signer: {signer_name} <{signer_email}>")
            print(f"  Executed: {executed_time}")
            print("  Sending branded Technijian completion email via Graph...")

            status_code = send_completion_email(
                folder_id, folder_name, signer_name,
                signer_email, executed_time, pdf
            )

            if status_code in (200, 202):
                print(f"\n  SUCCESS: Completion email sent to {signer_email}")
                print(f"  Subject: Technijian — Document Executed: {folder_name}")
                print(f"  Attachment: {safe_name}")
                print(f"  From: {SENDER_NAME} <{SENDER_EMAIL}>")
                print(f"  Foxit completion email: SUPPRESSED (disabled in account settings)")
            else:
                print(f"  ERROR sending Graph email: {status_code}")
            return

        if status in ("CANCELLED", "DECLINED", "DELETED"):
            print(f"  Folder {status} — aborting."); return

        time.sleep(POLL_INTERVAL_SEC)

    print(f"Timeout after {POLL_TIMEOUT_SEC//60} minutes — folder not yet executed.")

if __name__ == "__main__":
    main()
