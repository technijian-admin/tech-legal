# Follow-up to Katherine Wilson after today's (2026-04-22) unscheduled
# Sunrun tech visit to 5 Caladium. Documents the tech's verbal diagnosis
# (faulty uplink circuit replaced; "generating but not uploading" narrowly
# scoped to Apr 18-22 window) and requests the narrow-window evidence in
# writing. Nov 7 - Apr 16 outage treated as conceded by Sunrun's on-site
# agent; all prior deadlines preserved.
#
# Usage:
#   .\send-sunrun-tech-followup-katherine.ps1         # draft only (DEFAULT)
#   .\send-sunrun-tech-followup-katherine.ps1 -Send   # send immediately

param([switch]$Send)

$ErrorActionPreference = "Stop"

$toRecipients = @(
    @{ Address = "katherine.wilson@sunrun.com"; Name = "Katherine Wilson" }
)
$ccRecipients = @(
    @{ Address = "membercare@sunrun.com"; Name = "Sunrun Member Care (Warranty Notice)" }
)

$senderUpn = "RJain@technijian.com"
$subject   = "Re: FORMAL DEMAND - Solar System Disconnected 11/7/25-4/16/26 - 5 Caladium - Acct 0036 1837 1728 9 - Response Due Within 14 Days"
$sigPath   = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"

Write-Host "Reading M365 Graph credentials..." -ForegroundColor Cyan
$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $m365ClientId -or -not $m365TenantId -or -not $m365Secret) {
    Write-Error "Failed to parse M365 credentials"; exit 1
}

$sig = ""
if (Test-Path $sigPath) { $sig = Get-Content $sigPath -Raw }

$fontStack = "Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif"

$htmlBody = @"
<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>
<body dir="ltr">
<div style="font-family:$fontStack;font-size:11pt;color:rgb(0,0,0)">

<p>Katherine,</p>

<p>Follow-up from today&#39;s unscheduled Sunrun site visit at 5 Caladium. The technician has now left the property. This email memorializes what the technician stated verbally on site and requests the supporting documentation in writing.</p>

<h3 style="color:#b30000;">1. Technician&#39;s verbal diagnosis</h3>

<p>The technician stated, in substance, that the 2017 Costco system&#39;s <strong>uplink circuit was faulty</strong> and that <strong>he replaced the uplink circuit</strong> during today&#39;s visit. He further stated that after the April 16, 2026 service visit the uplink reported for approximately two days (consistent with the April 16&ndash;17 production bars in my weekly-chart screenshots from April 18), then stopped reporting on April 18 because the uplink circuit itself had failed. He described the April 18&ndash;22 window as <strong>&quot;generating just not uploading&quot;</strong> &mdash; panels producing, data not reaching Sunrun.</p>

<h3 style="color:#b30000;">2. The scope of that claim</h3>

<p>I want the record to be clear about what the on-site technician&#39;s diagnosis did and did not address:</p>

<ul>
  <li>The technician&#39;s <strong>&quot;generating but not uploading&quot;</strong> statement is narrowly scoped to the <strong>April 18&ndash;April 22, 2026</strong> window (&sim;4 days).</li>
  <li>The technician made <strong>no</strong> such claim about the <strong>November 7, 2025 &ndash; April 16, 2026</strong> period (&sim;160 days). That period was described by the technician as a real production failure cured by the April 16 visit.</li>
  <li>This matches Sunrun&#39;s own prior written record on Case #18181148 (metering issue opened 11/10/2025; January 16 &quot;our monitoring system has detected an issue&quot; email; February 16 &quot;power cycling instructions&quot;; April 10 &quot;system reboot&quot; email), as well as SDG&amp;E&#39;s NEM Summary entries on every monthly bill December 2025 through April 2026 showing zero exported kWh and excess consumption charges consistent with a non-producing system.</li>
</ul>

<p>Accordingly, the primary damages window &mdash; November 7, 2025 through April 16, 2026 &mdash; is established, and Sunrun&#39;s own on-site field technician now corroborates that narrative. Today&#39;s tech did not attempt to re-characterize that period as a monitoring issue, and his April 18 &quot;generating but not uploading&quot; language would not be available for the pre-April-16 period because the April 16 repair (not the April 22 repair) was what restored the uplink for the two-day Thu/Fri window I screenshotted.</p>

<h3 style="color:#b30000;">3. Please provide the following in writing, by end of business Friday, April 24, 2026</h3>

<ol>
  <li><strong>Technician identification</strong> for today&#39;s April 22, 2026 site visit at 5 Caladium: full name, Sunrun employee or contractor ID, contractor company name if applicable, on-site time and departure time.</li>
  <li><strong>Today&#39;s work order number</strong> and the work order number for the April 16, 2026 site visit.</li>
  <li><strong>SolarEdge inverter lifetime kWh counter readings</strong> for the 2017 Costco system as captured during (a) the April 16, 2026 site visit and (b) today&#39;s April 22, 2026 site visit. The delta between those two readings is the on-device evidence for or against the April 18&ndash;22 &quot;generating but not uploading&quot; narrative.</li>
  <li><strong>Panel-level optimizer production history</strong> from the SolarEdge monitoring portal for April 16, 2026 through April 22, 2026. SolarEdge optimizers log production locally and backfill to the portal once the uplink is restored. Please export and send the per-optimizer 15-minute or daily data for that window.</li>
  <li><strong>Root-cause report</strong> for the new case opened for the 2017 Costco system, specifying the failed component (uplink circuit), the replacement part installed today, part serial numbers, and the technician&#39;s assessment of when the uplink failure began.</li>
  <li><strong>Preservation and photograph</strong> of the failed uplink circuit removed today, with serial number captured. Do not dispose of, return-to-vendor, or RMA the failed part without notice to me. This is a document-preservation directive.</li>
  <li><strong>Confirmation in writing</strong> that the 2017 Costco system is now producing and uploading normally, with the first 48 hours of post-repair data from the SolarEdge portal. If the 2017 Costco system is not producing normally by end of business Thursday, April 24, 2026, the <strong>May 4, 2026 site visit must proceed</strong>.</li>
</ol>

<h3 style="color:#b30000;">4. Deadlines and preservation &mdash; unchanged</h3>

<ul>
  <li>The <strong>May 1, 2026</strong> 14-day formal-demand response deadline remains in effect.</li>
  <li>The <strong>CLRA &sect; 1782</strong> 30-day notice clock started with my April 17 formal demand and ripens on <strong>May 16, 2026</strong>.</li>
  <li>The <strong>May 4, 2026 (12:00&nbsp;PM&ndash;5:00&nbsp;PM)</strong> site visit remains scheduled until Sunrun confirms full restoration of the 2017 Costco system with 48 hours of post-repair production data.</li>
  <li>The document-preservation scope stated in Section 10 of my April 19 email is hereby expanded to include: the failed uplink circuit removed today and its serial number, the replacement part installed today and its serial number, the SolarEdge inverter lifetime kWh counter readings captured on April 16 and April 22, and the full SolarEdge portal data export for both the 2017 Costco system and the 2012 PPA system from October 1, 2025 to the date of full restoration.</li>
</ul>

<p>Nothing about today&#39;s visit or this email constitutes a waiver, release, or settlement of any claim. Compensation and legal correspondence remain on their separate track.</p>

</div>
$sig
</body>
</html>
"@

# --- Proofread: stripped-dollar-sign + placeholder check (FAIL FAST) ---
if ($htmlBody -match '[\s>](\,\d{3})') {
    Write-Error "BLOCKED: Stripped dollar sign detected near '$($matches[1])'. Backtick-escape every literal `$<digit> in the body."
    exit 1
}
if ($htmlBody -match '\[Your Name\]|TODO|TBD|\[INSERT|\[CLIENT') {
    Write-Error "BLOCKED: Placeholder text found in email body."
    exit 1
}
Write-Host "Proofread checks passed." -ForegroundColor Green

Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome
Write-Host "Connected." -ForegroundColor Green

$toGraph = $toRecipients | ForEach-Object { @{ EmailAddress = @{ Address = $_.Address; Name = $_.Name } } }
$ccGraph = $ccRecipients | ForEach-Object { @{ EmailAddress = @{ Address = $_.Address; Name = $_.Name } } }

Write-Host "Creating draft message..." -ForegroundColor Cyan
$draftParams = @{
    Subject      = $subject
    Body         = @{ ContentType = "HTML"; Content = $htmlBody }
    ToRecipients = @($toGraph)
    CcRecipients = @($ccGraph)
    Importance   = "High"
}
$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter $draftParams
Write-Host "Draft created. MessageId = $($draft.Id)" -ForegroundColor Green

if ($Send) {
    Write-Host "`nSENDING NOW..." -ForegroundColor Yellow
    Send-MgUserMessage -UserId $senderUpn -MessageId $draft.Id
    Write-Host "SENT." -ForegroundColor Green
} else {
    Write-Host "`n=== DRAFT SAVED to Outlook Drafts folder for $senderUpn ===" -ForegroundColor Yellow
    Write-Host "Subject: $subject" -ForegroundColor Gray
    Write-Host "TO:" -ForegroundColor Gray
    $toRecipients | ForEach-Object { Write-Host "  $($_.Name) <$($_.Address)>" -ForegroundColor Gray }
    Write-Host "CC:" -ForegroundColor Gray
    $ccRecipients | ForEach-Object { Write-Host "  $($_.Name) <$($_.Address)>" -ForegroundColor Gray }
    Write-Host "`nReview in Outlook (Drafts folder), edit if needed, then click Send." -ForegroundColor Yellow
    Write-Host "Re-run with -Send to send immediately." -ForegroundColor Cyan
}

Disconnect-MgGraph | Out-Null
