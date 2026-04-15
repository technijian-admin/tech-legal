# Workstation Setup — M365, DocuSign, and Foxit eSign

## Purpose

This repo documents the working configuration for:

- Microsoft 365 / Microsoft Graph access to `rjain@technijian.com`
- DocuSign JWT-based sending and status operations
- Foxit eSign OAuth2-based sending

The repo documents the configuration, scripts, and key file schema. The live secrets themselves are **not** stored in git. They live in Ravi's OneDrive key folder:

`C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys`

The `keys/` folder in this repo contains pointer files only.

## Key Storage Standard

All live runtime credentials for these integrations must be stored in:

`C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys`

Current key files:

| Service | OneDrive file | Repo pointer |
|---|---|---|
| Microsoft 365 / Graph | `C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md` | `keys/m365-graph.md` |
| DocuSign | `C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\docusign.md` | `keys/docusign.md` |
| Foxit eSign | `C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\foxit-esign.md` | `keys/foxit-esign.md` |

Do not commit the live OneDrive key files into this repo.

## Prerequisites

Install these on any new workstation before running the integration scripts:

| Tool | Why | Install |
|---|---|---|
| PowerShell 5.1+ (Windows) | Runs all `scripts/*.ps1` | Built-in on Windows 10/11 |
| `Microsoft.Graph` PS module | `Connect-MgGraph`, `Send-MgUserMail` in email scripts | `Install-Module Microsoft.Graph -Scope CurrentUser` |
| Node.js 18+ | Runs `docusign-jwt-helper.js` (built-ins only, no extra npm deps for signing) | <https://nodejs.org> (installer puts `node.exe` at `C:\Program Files\nodejs\`) |
| Python 3.10+ | Runs `scripts/md-to-docx.py` for doc generation | <https://python.org> |
| Repo `npm install` | Only needed if regenerating DOCX/PPTX via `docx` / `pptxgenjs` | `cd tech-legal && npm install` |

## Key File Format (must match script regex)

Scripts parse the OneDrive key files with regex like `'<Field>:\*\*\s*(\S+)'`, which means **each field must be written as `**Field:** value` on its own line**. Use these templates verbatim — changing the bold markers or colons will break the parser.

### `m365-graph.md`

```markdown
# Microsoft 365 Graph - HiringPipeline-Automation

**App Client ID:** 00000000-0000-0000-0000-000000000000
**Tenant ID:** 00000000-0000-0000-0000-000000000000
**Client Secret:** <client-secret-value>
**Send as:** RJain@technijian.com
**PowerShell:** Connect-MgGraph -TenantId $tid -ClientSecretCredential $cred
```

### `docusign.md`

```markdown
# DocuSign - Technijian Integration

**Platform:** DocuSign eSignature (Production)
**URL:** https://account.docusign.com
**REST URL:** https://www.docusign.net/restapi
**Account Base URI:** https://www.docusign.net
**Client ID (Integration Key):** 00000000-0000-0000-0000-000000000000
**User ID:** 00000000-0000-0000-0000-000000000000
**Account ID:** 00000000-0000-0000-0000-000000000000
**Keypair ID:** 00000000-0000-0000-0000-000000000000

-----BEGIN RSA PRIVATE KEY-----
<multi-line base64 body>
-----END RSA PRIVATE KEY-----
```

### `foxit-esign.md`

```markdown
# Foxit eSign - Technijian

**Platform:** Foxit eSign
**Region:** NA1
**Base URL:** https://na1.foxitesign.foxit.com/api
**Client ID:** <foxit-client-id>
**Client Secret:** <foxit-client-secret>
**Auth endpoint:** https://na1.foxitesign.foxit.com/api/oauth2/access_token
**Grant type:** client_credentials
```

## Current Integration Configuration

### 1. Microsoft 365 / Graph

- Mailbox: `rjain@technijian.com`
- Primary API: Microsoft Graph
- MCP server in current Windows Claude config:

```json
{
  "mcpServers": {
    "m365": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@softeria/ms-365-mcp-server"],
      "env": {
        "MS365_MCP_CLIENT_ID": "${MS365_MCP_CLIENT_ID}",
        "MS365_MCP_TENANT_ID": "${MS365_MCP_TENANT_ID}",
        "MS365_MCP_CLIENT_SECRET": "${MS365_MCP_CLIENT_SECRET}"
      }
    }
  }
}
```

- Script auth model: OAuth2 `client_credentials`
- Token scope used by scripts: `https://graph.microsoft.com/.default` (literal string passed to Graph; do not change)
- Standard key file: `m365-graph.md`
- Azure AD app name: `HiringPipeline-Automation`
- Required Graph **Application** permissions (admin-consented):
  - `Mail.Send` — send mail as rjain@technijian.com
  - `Mail.Read` — read inbox via `search-inbox-bwh.ps1`
  - `Mail.ReadWrite` — move / update messages
  - `User.Read.All` — resolve recipient SMTP addresses (m365 MCP)
- Use `-UserId "RJain@technijian.com"` on `Send-MgUserMail`, never `"me"` (app-only auth has no "me")

Expected fields in `m365-graph.md`:

- `App Client ID`
- `Tenant ID`
- `Client Secret`
- `Send as`
- `PowerShell`

Repo scripts that consume this file include:

- `scripts/send-docusign.ps1`
- `scripts/send-foxit-esign.ps1`
- `scripts/search-inbox-bwh.ps1`
- `scripts/send-bwh-email.ps1`
- `scripts/send-aava-msa.ps1`

### 2. DocuSign

- Provider: DocuSign eSignature
- Auth model: JWT bearer
- Standard key file: `docusign.md`
- Runtime dependency: `scripts/docusign-jwt-helper.js`

Expected fields in `docusign.md`:

- `Platform`
- `URL`
- `REST URL`
- `Account Base URI`
- `Client ID (Integration Key)`
- `User ID`
- `Account ID`
- `Keypair ID`
- RSA private key block

Repo scripts that consume this file include:

- `scripts/send-docusign.ps1`
- `scripts/void-envelope.ps1`
- `scripts/test-docusign-auth.ps1`
- `scripts/send-aava-msa.ps1`

#### First-time JWT consent (per Integration Key / per user)

Before the JWT grant will issue tokens for `User ID` on a new Integration Key, that user must grant consent **once**. Paste this URL in a browser while signed in as the target user, then click **Accept**:

```text
https://account.docusign.com/oauth/auth?response_type=code&scope=signature%20impersonation&client_id=<Client ID (Integration Key)>&redirect_uri=https://www.docusign.com
```

After consent, `scripts/test-docusign-auth.ps1` should succeed. If the RSA keypair is rotated, a new `Keypair ID` is issued but consent does **not** need to be repeated.

DocuSign is currently documented and script-backed in this repo. There is no checked-in DocuSign MCP config at the project level.

### 3. Foxit eSign

- Provider: Foxit eSign
- Base API URL: `https://na1.foxitesign.foxit.com/api`
- Auth model: OAuth2 `client_credentials`
- OAuth scope: `read-write`
- Standard key file: `foxit-esign.md`

Expected fields in `foxit-esign.md`:

- `Platform`
- `Region`
- `Base URL`
- `Client ID`
- `Client Secret`
- `Auth endpoint`
- `Grant type`

Repo scripts that consume this file include:

- `scripts/send-foxit-esign.ps1`
- `scripts/send-affg-002.ps1`

Foxit is currently documented and script-backed in this repo. There is no checked-in Foxit MCP config at the project level.

Client ID and Secret are issued from the Foxit eSign admin console under **Account Settings → API → Create App**. The credentials tie back to `rjain@technijian.com` as the API owner.

## Smoke Tests (run after populating keys)

From `c:\vscode\tech-legal\tech-legal`, in a PowerShell 5.1+ session:

```powershell
# 1. M365 Graph — connect + send-as check
$k = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$cid = [regex]::Match($k,'App Client ID:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($k,'Tenant ID:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($k,'Client Secret:\*\*\s*(\S+)').Groups[1].Value
$cred = New-Object System.Management.Automation.PSCredential($cid, (ConvertTo-SecureString $sec -AsPlainText -Force))
Connect-MgGraph -TenantId $tid -ClientSecretCredential $cred -NoWelcome
Get-MgUserMessage -UserId "RJain@technijian.com" -Top 1 | Select-Object Subject
Disconnect-MgGraph

# 2. DocuSign — JWT auth (script prints access token + userinfo on success)
powershell.exe -ExecutionPolicy Bypass -File .\scripts\test-docusign-auth.ps1

# 3. Foxit — OAuth token issuance
$f = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\foxit-esign.md" -Raw
$fid = [regex]::Match($f,'Client ID:\*\*\s*(\S+)').Groups[1].Value
$fsec = [regex]::Match($f,'Client Secret:\*\*\s*(\S+)').Groups[1].Value
$body = @{ grant_type='client_credentials'; client_id=$fid; client_secret=$fsec; scope='read-write' }
Invoke-RestMethod -Method Post -Uri "https://na1.foxitesign.foxit.com/api/oauth2/access_token" -Body $body
```

All three must return without error before attempting a production send.

## Verification Notes

Verified on this workstation on `2026-04-15`:

- Microsoft Graph mailbox read for `rjain@technijian.com`
- DocuSign JWT auth plus `/oauth/userinfo`
- Foxit eSign OAuth token issuance

That verification confirms the OneDrive key store and the current script-backed flows are valid.

## Fresh Workstation Checklist

1. Clone the repo and open `tech-legal/tech-legal`.
2. Ensure the OneDrive key folder exists at:
   `C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys`
3. Populate the three live key files there:
   `m365-graph.md`, `docusign.md`, and `foxit-esign.md`
4. If Claude/Codex mailbox MCP access is needed, add the `m365` MCP server shown above to the workstation's Claude config.
5. Verify the script-based integrations:
   - M365: mailbox read via Graph
   - DocuSign: JWT auth
   - Foxit: OAuth token issuance

## Repo Policy

- Document configuration in repo.
- Keep live secrets in OneDrive.
- Keep repo `keys/` files as non-secret pointers only.
- If a script needs credentials, it should read from the standardized OneDrive key path above.
