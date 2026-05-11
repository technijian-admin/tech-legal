"""
Brief clarifying email to Suresh explaining the v2/v3 timing issue and
pointing him to the v3 Foxit envelope (33688737). Aptos 12pt rgb(0,0,0)
branded format with signature. CC Ajay and Gurdeep.
"""

import re
import requests
from pathlib import Path

KEY_DIR = Path(r"C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys")
SIG_HTML_PATH = Path(r"c:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html")
SURESH_EMAIL = "sksvats@gmail.com"
SURESH_NAME = "Suresh Kumar Sharma"
V3_FOLDER_ID = 33688737

CC_RECIPIENTS = [
    {"address": "ABhardwaj@technijian.com", "name": "Ajay Bhardwaj"},
    {"address": "GKumar@technijian.com",    "name": "Gurdeep Kumar"},
]


def main():
    m365_raw = (KEY_DIR / "m365-graph.md").read_text()
    APP = re.search(r'App Client ID[^:]*:\*\*\s*(\S+)', m365_raw).group(1)
    TEN = re.search(r'Tenant ID[^:]*:\*\*\s*(\S+)', m365_raw).group(1)
    SEC = re.search(r'Client Secret[^:]*:\*\*\s*(.+)', m365_raw).group(1).strip()
    tok = requests.post(
        f"https://login.microsoftonline.com/{TEN}/oauth2/v2.0/token",
        data={"grant_type":"client_credentials","client_id":APP,"client_secret":SEC,
              "scope":"https://graph.microsoft.com/.default"},
    ).json()["access_token"]

    # Get the v3 signing URL fresh
    foxit_raw = (KEY_DIR / "foxit-esign.md").read_text()
    fid = re.search(r'Client ID[^:]*:\*\*\s*(\S+)', foxit_raw).group(1)
    fsec = re.search(r'Client Secret[^:]*:\*\*\s*(\S+)', foxit_raw).group(1)
    ftok = requests.post(
        "https://na1.foxitesign.foxit.com/api/oauth2/access_token",
        data={"grant_type":"client_credentials","client_id":fid,"client_secret":fsec,"scope":"read-write"},
    ).json()["access_token"]
    fr = requests.get(
        f"https://na1.foxitesign.foxit.com/api/folders/myfolder?folderId={V3_FOLDER_ID}",
        headers={"Authorization": f"Bearer {ftok}"},
    ).json()
    sign_url = None
    for p in fr.get("folder", {}).get("folderRecipientParties", []):
        if p.get("folderAccessURL"):
            sign_url = p["folderAccessURL"]
            break

    sig = SIG_HTML_PATH.read_text(encoding="utf-8")
    div = '<div style="font-family:Aptos,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)">'
    blank = f'{div}<br></div>'
    lines = [
        f'{div}Dear Suresh,</div>',
        blank,
        f'{div}Thank you for your message confirming you had completed the signing.</div>',
        blank,
        f'{div}A quick clarification on the timing: the version you viewed (and likely signed) at 11:13 PM IST was the second version of the letter. A few minutes after that, at 11:20 PM IST, that version was replaced by a final third version that includes one additional standard clause regarding future re-employment. Any signature applied to the second version was voided automatically when the new version was issued.</div>',
        blank,
        f'{div}The new and final version of the letter is currently in your inbox under the subject:</div>',
        f'{div}&nbsp;&nbsp;&bull;&nbsp;&nbsp;&ldquo;<b>Technijian &mdash; Revised Termination Letter (Final) &mdash; For Your Signature</b>&rdquo;</div>',
        blank,
        f'{div}Please open that email and click <b>Review &amp; Sign</b> on the final version. The settlement figures are unchanged at <b>Rs. 57,923</b>, payable June 1, 2026.</div>',
        blank,
        f'{div}If you have any difficulty locating the new email, the direct signing link is below:</div>',
        f'{div}<a href="{sign_url}" style="color:rgb(0,109,182)">{sign_url}</a></div>',
        blank,
        f'{div}Apologies for the additional step. Thank you for your patience.</div>',
        sig,
    ]
    html = "\n".join(lines)

    mail = {
        "Message": {
            "Subject": "Re: Technijian — Revised Termination Letter — Please sign the FINAL version",
            "Body": {"ContentType": "HTML", "Content": html},
            "ToRecipients": [{"EmailAddress": {"Address": SURESH_EMAIL, "Name": SURESH_NAME}}],
            "CcRecipients": [{"EmailAddress": {"Address": cc["address"], "Name": cc["name"]}} for cc in CC_RECIPIENTS],
            "From": {"EmailAddress": {"Address": "rjain@technijian.com", "Name": "Ravi Jain - Technijian"}},
        },
        "SaveToSentItems": True,
    }
    r = requests.post(
        "https://graph.microsoft.com/v1.0/users/rjain@technijian.com/sendMail",
        headers={"Authorization": f"Bearer {tok}", "Content-Type": "application/json"},
        json=mail,
    )
    print(f"Status: {r.status_code}")
    print(f"V3 signing URL embedded: {bool(sign_url)}")
    if r.status_code not in (200, 202):
        print(r.text[:300])


if __name__ == "__main__":
    main()
