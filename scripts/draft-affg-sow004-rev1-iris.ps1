# Draft AFFG SOW-004 Rev 1 narrative email to Iris Liu
# Attaches SOW-AFFG-004-Rev1-Managed-Device-Migration.docx
# Saves to Outlook Drafts folder for Ravi's review before manual send
#
# Usage: powershell.exe -ExecutionPolicy Bypass -File "C:\vscode\tech-legal\tech-legal\scripts\draft-affg-sow004-rev1-iris.ps1"

$ErrorActionPreference = "Stop"

$toEmail    = "iris.liu@americanfundstars.com"
$toName     = "Iris Liu"
$senderUpn  = "RJain@technijian.com"
$subject    = "SOW-AFFG-004 Rev 1 - Updated Scope and Why MFA Alone Falls Short Under Reg S-P"
$sowPath    = "C:\vscode\tech-legal\tech-legal\clients\AFFG\03_SOW\SOW-AFFG-004-Rev1-Managed-Device-Migration.docx"
$sigPath    = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"
$idFile     = "C:\vscode\tech-legal\tech-legal\scripts\affg-sow004-rev1-draft-id.txt"
$previewHtml= "C:\vscode\tech-legal\tech-legal\scripts\affg-sow004-rev1-preview.html"

# --- Validate inputs ---
if (-not (Test-Path $sowPath)) { Write-Error "SOW not found: $sowPath"; exit 1 }
if (-not (Test-Path $sigPath)) { Write-Error "Signature file not found: $sigPath"; exit 1 }

# --- Credentials ---
Write-Host "Reading M365 Graph credentials..." -ForegroundColor Cyan
$m365Keys     = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $m365ClientId -or -not $m365TenantId -or -not $m365Secret) {
    Write-Error "Failed to parse M365 credentials"; exit 1
}

# --- Signature ---
$sig = Get-Content $sigPath -Raw

# --- HTML body ---
# IMPORTANT: Every literal `$` inside this here-string is escaped as `` `$ `` to avoid PowerShell
# variable expansion (e.g. `$2,794.50` must be written as "`$2,794.50").
$fontStack = "Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif"
$htmlBody = @"
<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>
<body dir="ltr">
<div style="font-family:$fontStack;font-size:12pt;color:rgb(0,0,0)">

<p>Iris,</p>

<p>Attached is <strong>SOW-AFFG-004 Rev 1</strong>, reflecting the corrections from our last exchange:</p>

<ul>
  <li><strong>BYOD MAM-only</strong> for personal mobile devices &mdash; no company phones, no MDM on personal devices. Intune App Protection contains corporate email in the Outlook App with selective corporate wipe on separation.</li>
  <li><strong>Managed fleet confirmed</strong> as 4 Mac Mini + 6 Windows laptops (10 endpoints); offboarding the 16 legacy desktops currently under managed services is included as Phase 4.</li>
  <li><strong>Azure Entra ID SSO</strong> (already included in your M365 E3/E5) handles identity federation and MFA &mdash; the separate Technijian SSO/2FA Gateway product has been removed from the proposal.</li>
  <li><strong>CloudBrink ZTNA</strong> replaces Cisco Umbrella on all 10 endpoints and provides a fixed egress IP we will whitelist at Schwab and IBKR.</li>
  <li><strong>Custodian portal access</strong> enforced via office WAN IP whitelist + CloudBrink egress IP for traveling laptops.</li>
</ul>

<p><strong>On the &ldquo;MFA is sufficient&rdquo; question.</strong></p>

<p>I want to spend a moment on this because it keeps coming up, and I do not want AFFG signing something you are not fully behind. MFA authenticates a <em>user</em>. It does not authenticate a <em>device</em>. A personal laptop with valid credentials and an MFA prompt reaches Schwab or IBKR the same way a company laptop does &mdash; and once in, it can download client data to a device Technijian has no visibility into and no ability to wipe. That is exactly the gap SEC and FINRA examiners focus on.</p>

<p>The enforcement record is consistent on this point:</p>

<ul>
  <li><strong>M Holdings Securities (SEC, Nov 2025).</strong> Settled Reg S-P and Reg S-ID charges after multi-year email account takeovers across 13 member firms and credential-harvesting emails to roughly 8,500 recipients. SEC cited the absence of MFA <em>across all member firms and endpoints</em> and the lack of a reasonably designed enterprise-level information security policy.</li>
  <li><strong>Osaic Wealth + Securities America (FINRA, March 2024) &mdash; `$150,000 each.</strong> 28,000 Osaic clients and 4,640 Securities America clients had SSNs, bank account details, and driver&rsquo;s license data exposed in 16 separate intrusions between January 2021 and March 2023. Specific gap cited: MFA not required on all email accounts, no outbound encryption, no access logs. FINRA noted both firms had been put on notice in prior examinations and failed to remediate.</li>
  <li><strong>JPMorgan (`$1.2M), UBS (`$925K), TradeStation (`$425K) &mdash; SEC, 2022.</strong> Reg S-ID identity-theft-program failures. Critical point: no actual identity theft occurred in any of these cases. The SEC fined them for inadequate <em>controls</em>, not for breach harm.</li>
  <li><strong>Morgan Stanley Smith Barney (SEC, 2022) &mdash; `$35 million.</strong> Failure to safeguard PII on decommissioned devices exposed approximately 15 million client records. The fine turned on MSSB&rsquo;s inability to account for every device that had touched client data.</li>
  <li><strong>Voya Financial Advisors (SEC, 2018) &mdash; `$1 million.</strong> First Reg S-ID enforcement action. Impostors used the support line to reset passwords and access client accounts. The failure was in the access path around authentication, not in authentication strength itself.</li>
</ul>

<p>The common thread: MFA was present in most of these matters. Enforcement did not turn on &ldquo;did you have MFA&rdquo; &mdash; it turned on &ldquo;can you prove only authorized, managed devices accessed sensitive data, and can you contain and report a breach when one occurs.&rdquo; The managed-device + ZTNA + IP-whitelist architecture in Rev 1 is what closes that gap.</p>

<p>On Reg S-P specifically, the amended rule&rsquo;s compliance date for smaller advisers is <strong>June 3, 2026</strong> &mdash; roughly six weeks out. The controls in this SOW are what a reasonable program looks like under those amendments.</p>

<p><strong>What is in Rev 1.</strong></p>

<ul>
  <li>6 phases, 12 weeks, 72 hours total, <strong>`$5,340 fixed-fee</strong> (down from the original `$6,255 &mdash; Rev 1 is simpler because there is no VDI component).</li>
  <li>Phase 4 explicitly offboards the 16 legacy desktops and delivers a Schedule A amendment.</li>
  <li>Section 8 shows the full monthly recurring comparison against your actual signed invoice: current <strong>`$2,794.50/mo</strong> &rarr; proposed <strong>`$3,764.50/mo</strong>, net <strong>+`$970/mo</strong>. This is a compliance investment &mdash; the regulatory exposure on the other side of that number is materially larger than the monthly delta.</li>
</ul>

<p>I will send the signature request separately via Foxit eSign. Happy to walk through any of this on a quick call first &mdash; use the booking link in my email signature below.</p>

<p>Thank you,</p>

</div>
$sig
</body>
</html>
"@

# --- Preview (per feedback_preview_emails_before_send.md) ---
Set-Content -Path $previewHtml -Value $htmlBody -Encoding UTF8
Write-Host "HTML body preview written to: $previewHtml" -ForegroundColor Gray

# Grep for stripped dollar signs (would appear as ",XXX" or similar)
$previewMatch = Select-String -Path $previewHtml -Pattern ',\d{3}\.\d{2}' -AllMatches
if ($previewMatch) {
    Write-Host "Dollar-amount check: found formatted amounts in preview." -ForegroundColor Green
    $previewMatch.Matches | ForEach-Object { Write-Host "  $($_.Value)" -ForegroundColor DarkGray }
}
$strippedCheck = Select-String -Path $previewHtml -Pattern '(?<![`\$\d])[,.]\d{3}(?:\.\d{2})?' -AllMatches
if ($strippedCheck) {
    Write-Warning "Possible stripped `$ found:"
    $strippedCheck.Matches | ForEach-Object { Write-Host "  $($_.Value)" -ForegroundColor Red }
}

# --- Connect ---
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome
Write-Host "Connected." -ForegroundColor Green

# --- Create draft ---
Write-Host "Creating draft message..." -ForegroundColor Cyan
$draftParams = @{
    Subject = $subject
    Body    = @{ ContentType = "HTML"; Content = $htmlBody }
    ToRecipients = @(
        @{ EmailAddress = @{ Address = $toEmail; Name = $toName } }
    )
}
$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter $draftParams
$draftId = $draft.Id
Write-Host "Draft created: $draftId" -ForegroundColor Green

# --- Attach the SOW ---
Write-Host "Attaching SOW..." -ForegroundColor Cyan
$sowBytes = [System.IO.File]::ReadAllBytes($sowPath)
$sowBase64 = [Convert]::ToBase64String($sowBytes)
$sowFileName = [System.IO.Path]::GetFileName($sowPath)
$null = New-MgUserMessageAttachment -UserId $senderUpn -MessageId $draftId -BodyParameter @{
    "@odata.type" = "#microsoft.graph.fileAttachment"
    Name          = $sowFileName
    ContentBytes  = $sowBase64
}
Write-Host "Attached: $sowFileName ($([math]::Round($sowBytes.Length/1KB, 1)) KB)" -ForegroundColor Green

# --- Save draft id for reference ---
Set-Content -Path $idFile -Value $draftId -Encoding UTF8
Write-Host "Draft MessageId saved to: $idFile" -ForegroundColor Gray

Disconnect-MgGraph | Out-Null

Write-Host ""
Write-Host "========== DRAFT READY IN OUTLOOK ==========" -ForegroundColor Yellow
Write-Host "Subject    : $subject" -ForegroundColor White
Write-Host "To         : $toName <$toEmail>" -ForegroundColor White
Write-Host "Attachment : $sowFileName" -ForegroundColor White
Write-Host "Draft Id   : $draftId" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Open Outlook -> Drafts and review the message." -ForegroundColor White
Write-Host "  2. Send manually from Outlook when satisfied." -ForegroundColor White
Write-Host "  3. After sending, kick off Foxit eSign separately." -ForegroundColor White
