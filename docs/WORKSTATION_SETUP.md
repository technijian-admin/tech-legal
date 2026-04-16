# Workstation Setup Guide

## Purpose

This repo handles legal document generation (MSAs, SOWs, NDAs, proposals, compliance docs), client management via the Client Portal API, email sending via M365 Graph, and e-signing via Foxit eSign. This guide covers everything needed to run it on a fresh workstation.

## 1. Prerequisites

Install these before anything else:

| Tool | Version | Why | Install |
|---|---|---|---|
| **Node.js** | 18+ | DOCX/PPTX generation, MCP servers, DocuSign JWT helper | https://nodejs.org |
| **Python** | 3.10+ | `python-docx` doc generation, Office Word MCP, Client Portal scripts | https://python.org |
| **Rust / Cargo** | Latest stable | Builds `docx-mcp` (DOCX + PDF generation MCP server) | https://rustup.rs |
| **.NET SDK** | 9.0+ | Data API Builder (SQL MCP server) | https://dotnet.microsoft.com |
| **PowerShell 5.1+** | Built-in | All `scripts/*.ps1` for email, signing, Graph API | Windows built-in |
| **Git** | Latest | Repo management | https://git-scm.com |
| **uv** (Python) | Latest | Runs Python MCP servers without global installs | `pip install uv` |

### PowerShell Modules

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
```

### Python Packages

```bash
pip install python-docx office-word-mcp-server
```

### Node.js Packages (repo-local)

```bash
cd c:\vscode\tech-legal\tech-legal && npm install
```

### .NET Global Tools

```bash
dotnet tool install --global Microsoft.DataApiBuilder
```

## 2. Clone Repos

```bash
# Main repo
git clone <repo-url> c:\vscode\tech-legal

# docx-mcp (Rust-based DOCX + PDF MCP server)
git clone https://github.com/hongkongkiwi/docx-mcp.git C:\vscode\docx-mcp
cd C:\vscode\docx-mcp && cargo build --release
# Binary: C:\vscode\docx-mcp\target\release\docx-mcp.exe
```

## 3. Key Storage

All live credentials are stored in OneDrive (never in git):

```
C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys
```

The `keys/` folder in this repo contains pointer files only.

| Service | OneDrive File | Repo Pointer |
|---|---|---|
| Microsoft 365 / Graph | `m365-graph.md` | `keys/m365-graph.md` |
| Foxit eSign | `foxit-esign.md` | `keys/foxit-esign.md` |
| Client Portal API | `client-portal.md` | `keys/client-portal.md` |

### Key File Format

Scripts parse keys with regex: `'<Field>:\*\*\s*(\S+)'`. Each field must be `**Field:** value` on its own line.

#### `m365-graph.md`

```markdown
# Microsoft 365 Graph - HiringPipeline-Automation

**App Client ID:** <guid>
**Tenant ID:** <guid>
**Client Secret:** <secret>
**Send as:** RJain@technijian.com
```

#### `foxit-esign.md`

```markdown
# Foxit eSign - Technijian

**Platform:** Foxit eSign
**Region:** NA1
**Base URL:** https://na1.foxitesign.foxit.com/api
**Client ID:** <id>
**Client Secret:** <secret>
**Auth endpoint:** https://na1.foxitesign.foxit.com/api/oauth2/token
**Grant type:** client_credentials
```

## 4. MCP Servers

These MCP servers are configured in `~/.claude/settings.json` under `mcpServers`:

### 4.1 docx-mcp (Rust DOCX + PDF)

Pure Rust, no LibreOffice. Creates/reads/edits DOCX and generates PDFs with embedded fonts.

```json
"docx-mcp": {
  "command": "C:/vscode/docx-mcp/target/release/docx-mcp.exe",
  "args": [],
  "env": { "RUST_LOG": "info" }
}
```

**Build from source:** `cd C:\vscode\docx-mcp && cargo build --release`

### 4.2 word-document-server (Python Office Word MCP)

Python-based Word document manipulation via `python-docx`. Rich formatting, tables, styles.

```json
"word-document-server": {
  "command": "C:/Users/rjain/AppData/Roaming/Python/Python314/Scripts/uv.exe",
  "args": ["tool", "run", "--from", "office-word-mcp-server", "word_mcp_server"]
}
```

**Install:** `pip install office-word-mcp-server`

### 4.3 document-generator (Node.js DOCX/PDF)

TypeScript-based professional document generation. Runs via npx (no install needed).

```json
"document-generator": {
  "command": "C:/Program Files/nodejs/npx.cmd",
  "args": ["--yes", "document-generator-mcp@latest"]
}
```

### 4.4 SQL MCP Server (Data API Builder) - Optional

Direct SQL Server access for Client Portal queries. Requires `dab-config.json` with connection string and entity definitions.

```json
"sql-mcp-server": {
  "command": "C:/Users/rjain/.dotnet/tools/dab.exe",
  "args": [
    "start", "--mcp-stdio", "role:anonymous",
    "--config", "C:/vscode/tech-legal/dab-config.json",
    "--LogLevel", "error"
  ]
}
```

**Setup:** `dotnet tool install --global Microsoft.DataApiBuilder`, then create `dab-config.json`:
```bash
dab init --database-type mssql --connection-string "Server=...;Database=...;Trusted_Connection=true;TrustServerCertificate=true;" --config dab-config.json --host-mode development
dab add Contracts --source dbo.Contracts --source.type table --permissions "anonymous:*" --config dab-config.json
```

### 4.5 Other MCP Servers (pre-existing)

| Server | Purpose |
|---|---|
| `m365` | Microsoft 365 (email, calendar, OneDrive) via Graph API |
| `playwright` | Browser automation for testing |
| `whatsapp` | WhatsApp messaging |
| `notebooklm` | NotebookLM integration |

## 5. Integration Configuration

### 5.1 Microsoft 365 / Graph

- **Mailbox:** `rjain@technijian.com`
- **Auth:** OAuth2 `client_credentials` (app-only)
- **Azure AD app:** `HiringPipeline-Automation`
- **Required permissions:** `Mail.Send`, `Mail.Read`, `Mail.ReadWrite`, `User.Read.All`
- **Important:** Use `-UserId "RJain@technijian.com"`, never `"me"` (app-only auth has no "me")

### 5.2 Foxit eSign

- **Provider:** Foxit eSign (replaced DocuSign effective May 2026)
- **Base URL:** `https://na1.foxitesign.foxit.com/api`
- **Auth:** OAuth2 `client_credentials`
- **Always use parallel signing order** (never sequential)

### 5.3 Client Portal API

- **Base URL:** `https://api-clientportal.technijian.com`
- **Swagger:** `https://api-clientportal.technijian.com/swagger`
- **Architecture:** Stored-procedure-driven API (POST with XML/scalar params)
- **Auth:** Bearer token from `keys/client-portal.md`
- **Safety:** NEVER use delete endpoints. Only status updates (Close/Inactive).

## 6. Technijian Brand Standards (for Document Generation)

All client-facing documents must follow the Technijian brand. The canonical implementation is in `c:\vscode\tech-branding\tech-branding\scripts\brand-helpers.js`.

### Brand Colors

| Color | Hex | Usage |
|---|---|---|
| **Core Blue** | `#006DB6` | Primary brand, headers, links, table headers, accent bars |
| **Core Orange** | `#F67D4B` | CTAs, dividers, important callouts, secondary accent |
| **Dark Charcoal** | `#1A1A2E` | Body text headings, document titles |
| **Brand Grey** | `#59595B` | Body text, subtitles, metadata |
| **Teal** | `#1EAAC8` | Tertiary accent (used sparingly) |
| **Off-White** | `#F8F9FA` | Alternating table row backgrounds |
| **Light Grey** | `#E9ECEF` | Borders, dividers, subtle backgrounds |

### Typography

| Element | Font | Size | Weight | Color |
|---|---|---|---|---|
| Document title | Open Sans | 26pt (52 half-pts) | Bold | Dark Charcoal |
| Section headers | Open Sans | 14pt (28 half-pts) | Bold | Core Blue |
| Subsection heads | Open Sans | 12pt (24 half-pts) | Bold | Dark Charcoal |
| Body text | Open Sans | 11pt (22 half-pts) | Regular | Brand Grey |
| Table headers | Open Sans | 11pt | Bold | White on Core Blue |
| Confidential notice | Open Sans | 9pt (18 half-pts) | Italic | Brand Grey |
| Email body | Aptos, Calibri, Helvetica, sans-serif | 12pt | Regular | Dark Charcoal |

### Document Layout

- **Cover page:** Blue accent bar top, logo centered, orange divider, title, subtitle, date, orange accent bar bottom, confidentiality notice
- **Headers:** Logo left-aligned with blue bottom border
- **Footers:** Centered: "Technijian | 18 Technology Dr., Ste 141, Irvine, CA 92618 | 949.379.8500 - Page X"
- **Section headers:** Blue left-bar accent (120 DXA wide) + title in Core Blue
- **Tables:** Light grey borders, Core Blue header row with white text, alternating Off-White rows
- **Important callouts:** Orange left border (6pt), light orange background (`#FEF3EE`)
- **Accent bars:** Full-width colored bars (Core Blue or Core Orange, 20 DXA height)

### Logo

- **Full logo:** `https://technijian.com/wp-content/uploads/2026/03/technijian-logo-full-color-600x125-1.png`
- **Cover page size:** 280x58px
- **Header size:** 140x29px
- **Local file:** `clients/<CODE>/_generators/technijian-logo.png`

### Email Formatting

- **Signature:** Use `scripts/ravi-signature.html` (canonical, includes photo, CTA buttons, offices, social links, confidentiality)
- **Table headers:** Core Blue background (`#006DB6`) with white text
- **Table borders:** Light Grey (`#DEE2E6`)
- **Alternating rows:** Off-White (`#F8F9FA`)
- **CTA buttons:** Blue for meetings, Orange for support
- **Never embed booking URLs in body** - always say "use the booking link in my signature"

### Brand Source of Truth

The canonical brand helpers library is at:
```
c:\vscode\tech-branding\tech-branding\scripts\brand-helpers.js
```

This exports: `colorBanner`, `accentBar`, `sectionHeader`, `numberedSectionHeader`, `bodyText`, `subsectionHeading`, `orangeDivider`, `coverPage`, `brandedHeader`, `brandedFooter`, `importantCallout`, `statusTable`, plus all color constants.

## 7. Smoke Tests

From `c:\vscode\tech-legal\tech-legal` in PowerShell:

```powershell
# 1. M365 Graph - connect + read inbox
$k = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$cid = [regex]::Match($k,'App Client ID:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($k,'Tenant ID:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($k,'Client Secret:\*\*\s*(\S+)').Groups[1].Value
$cred = New-Object System.Management.Automation.PSCredential($cid, (ConvertTo-SecureString $sec -AsPlainText -Force))
Connect-MgGraph -TenantId $tid -ClientSecretCredential $cred -NoWelcome
Get-MgUserMessage -UserId "RJain@technijian.com" -Top 1 | Select-Object Subject
Disconnect-MgGraph

# 2. Foxit eSign - OAuth token
$f = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\foxit-esign.md" -Raw
$fid = [regex]::Match($f,'Client ID:\*\*\s*(\S+)').Groups[1].Value
$fsec = [regex]::Match($f,'Client Secret:\*\*\s*(\S+)').Groups[1].Value
$body = @{ grant_type='client_credentials'; client_id=$fid; client_secret=$fsec; scope='read-write' }
Invoke-RestMethod -Method Post -Uri "https://na1.foxitesign.foxit.com/api/oauth2/token" -Body $body

# 3. MCP Servers - verify binaries exist
Test-Path "C:\vscode\docx-mcp\target\release\docx-mcp.exe"   # docx-mcp
Test-Path "C:\Users\rjain\.dotnet\tools\dab.exe"              # SQL MCP
python -c "import office_word_mcp_server; print('OK')"         # Word MCP
npx --yes document-generator-mcp@latest --help 2>&1 | Select-Object -First 1  # Doc gen
```

## 8. Fresh Workstation Checklist

1. Install prerequisites (Node.js, Python, Rust, .NET SDK, Microsoft.Graph PS module)
2. Clone repos (`tech-legal`, `docx-mcp`)
3. Build docx-mcp: `cd C:\vscode\docx-mcp && cargo build --release`
4. Install Python packages: `pip install python-docx office-word-mcp-server`
5. Install DAB: `dotnet tool install --global Microsoft.DataApiBuilder`
6. Run `cd c:\vscode\tech-legal\tech-legal && npm install`
7. Ensure OneDrive key folder synced at expected path
8. Populate key files: `m365-graph.md`, `foxit-esign.md`, `client-portal.md`
9. Add MCP server blocks to `~/.claude/settings.json`
10. Run smoke tests (all must pass)
11. Verify: send a test email, generate a test DOCX

## Repo Policy

- Document configuration in repo, keep live secrets in OneDrive
- `keys/` folder = non-secret pointers only
- If a script needs credentials, read from the OneDrive key path
- DocuSign ended April 30, 2026 - use Foxit eSign for all new signing
- All client-facing documents must follow the Technijian brand standards in Section 6
