# Draft BWH MSA redline response to Dave Barisic
# Saves to Outlook Drafts folder (not sent) for review + manual send
#
# Key numbers:
#   - Cancellation rate is flat $150/hr for ALL unpaid hours (never contracted rate)
#   - BWH unpaid balance (April 1 invoice, post-April billing): 1,040.28 hrs
#   - At $150/hr cancellation rate = $156,042
#
# Usage: powershell.exe -ExecutionPolicy Bypass -File "C:\vscode\tech-legal\tech-legal\scripts\draft-bwh-msa-redline-response.ps1"

$ErrorActionPreference = "Stop"

$toEmail    = "dave@brandywine-homes.com"
$toName     = "Dave Barisic"
$senderUpn  = "RJain@technijian.com"
$subject    = "Re: MSA-BWH Redlines - Our Response, and One Key Item to Discuss"
$idFile     = "C:\vscode\tech-legal\tech-legal\scripts\bwh-msa-redline-response-draft-id.txt"
$sigPath    = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"

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
$sig = ""
if (Test-Path $sigPath) { $sig = Get-Content $sigPath -Raw }

# --- HTML body ---
# NOTE: every literal $ in dollar amounts is escaped with backtick to avoid PowerShell variable expansion
$fontStack = "Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif"
$htmlBody = @"
<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>
<body dir="ltr">
<div style="font-family:$fontStack;font-size:12pt;color:rgb(0,0,0)">

<p>Dave,</p>

<p>Thanks for sending the redlines back. I've worked through them carefully. Rather than walk section by section, I've grouped the changes into what we can accept, where we can meet you, and two linked changes I need to talk through with you before either side papers anything further.</p>

<p><strong>Accepted as drafted</strong></p>

<ul>
  <li><strong>&sect;2.02</strong> &mdash; &ldquo;renewal date&rdquo; &rarr; &ldquo;notification deadline&rdquo;: adopted.</li>
  <li><strong>&sect;2.05(b)</strong> &mdash; Transition-assistance rewrite: the 5-business-day start and the escrow mechanism for disputed amounts are reasonable. One small tweak: we'd like the &ldquo;good-faith dispute&rdquo; carve-out to require written particularization (amount + basis), so neither side can manufacture a pretext dispute to delay transition. Otherwise adopted.</li>
</ul>

<p><strong>Middle ground</strong></p>

<ul>
  <li><strong>&sect;2.03</strong> &mdash; Wind-down fee: we can't move from 75% to 50%; the 75% figure sits at a level we believe reflects reasonable liquidated damages given our committed capacity and offshore staffing. Your 1/12th monthly pro-ration concept, however, is fair and we'll adopt it. Counter-proposal: keep 75%, apply the 1/12th monthly reduction as you drafted. The economic outcome lands close to what you're targeting without removing the base protection.</li>
</ul>

<p><strong>Where we need to hold</strong></p>

<ul>
  <li><strong>&sect;2.02</strong> &mdash; 60-day notice: 60 days is the minimum we need to unwind offshore staffing and reserved capacity responsibly. Staying at 60.</li>
  <li><strong>&sect;3.07</strong> &mdash; Acceleration clause: this only triggers on material defaults (45+ days non-payment, insolvency, termination with an unpaid balance). Standard credit protection &mdash; keeping it.</li>
</ul>

<p><strong>The two changes we can't accept &mdash; and why they're linked</strong></p>

<p>&sect;3.3(e) (cancellation rate: Hourly &rarr; Contracted) and the new &sect;9.02 (release of prior obligations) together would wipe out a very real obligation sitting on your books today. I want to lay this out because I don't think it comes across in a clean redline.</p>

<p>Your April 1 invoice itself documents the following unpaid-hour balance (after April billing):</p>

<table style="border-collapse:collapse;margin:8px 0;">
  <thead>
    <tr style="background-color:#F67D4B;color:#ffffff;">
      <th style="border:1px solid #cccccc;padding:6px 12px;text-align:left;">Role</th>
      <th style="border:1px solid #cccccc;padding:6px 12px;text-align:right;">Unpaid Hours</th>
    </tr>
  </thead>
  <tbody>
    <tr><td style="border:1px solid #cccccc;padding:6px 12px;">India Tech &mdash; Normal</td><td style="border:1px solid #cccccc;padding:6px 12px;text-align:right;">600.22</td></tr>
    <tr><td style="border:1px solid #cccccc;padding:6px 12px;">India Tech &mdash; After Hours</td><td style="border:1px solid #cccccc;padding:6px 12px;text-align:right;">310.63</td></tr>
    <tr><td style="border:1px solid #cccccc;padding:6px 12px;">USA Tech &mdash; Normal</td><td style="border:1px solid #cccccc;padding:6px 12px;text-align:right;">129.43</td></tr>
    <tr><td style="border:1px solid #cccccc;padding:6px 12px;">Systems Architect</td><td style="border:1px solid #cccccc;padding:6px 12px;text-align:right;">0.00</td></tr>
    <tr style="background-color:#f5f5f5;"><td style="border:1px solid #cccccc;padding:6px 12px;"><strong>Total</strong></td><td style="border:1px solid #cccccc;padding:6px 12px;text-align:right;"><strong>1,040.28</strong></td></tr>
  </tbody>
</table>

<p>Under &sect;2.05(a) of the current Client MSA in effect today, unpaid hours on cancellation are invoiced at a flat <strong>`$150/hr Rate Card cancellation rate</strong> &mdash; not contracted rates. That footer note on your April 1 invoice states the same thing. At 1,040.28 hours &times; `$150/hr, the exposure is <strong>`$156,042</strong>.</p>

<p>The Contracted Rates in Schedule A are discounted specifically as consideration for the cycle commitment. They do not survive cancellation &mdash; that's by design, and it's what makes the cycle model work. Your &sect;3.3(e) edit tries to flip that rule, and the new &sect;9.02 would waive the entire `$156K outright. Together, those two changes amount to exiting the cycle obligation without paying for it.</p>

<p>Here's how I'd like to resolve this:</p>

<ul>
  <li><strong>If we sign the new MSA with &sect;3.3(e) as drafted (Rate Card rate on cancellation) and no &sect;9.02 release</strong>, the existing 1,040.28-hour balance gets absorbed through the 12-month cycle under the 20% under-utilization target. You never write a `$156K hourly-rate check. That is the entire design intent of the new structure &mdash; a structured path to zero, on contracted rates, over 12 months.</li>
  <li><strong>If &sect;9.02 stays in and &sect;3.3(e) changes to Contracted Rate</strong>, we'd be waiving a `$156K obligation at signing, with nothing left to protect the reserved capacity we're committing to. I can't put my name on that.</li>
</ul>

<p>A few paths forward on &sect;9.02:</p>

<ol>
  <li><strong>Delete &sect;9.02 entirely</strong> and let Schedule A's cycle mechanics resolve the prior balance organically &mdash; which is already what the new structure was designed to do. This is my strong preference.</li>
  <li><strong>Keep &sect;9.02 with an explicit carve-in and pay-down mechanic</strong> &mdash; language that acknowledges the 1,040.28-hour prior balance and commits both sides to the new cycle as the resolution path, with no separate hourly invoicing unless the new cycle itself is terminated.</li>
</ol>

<p>Can you grab 30 minutes this week? There's a booking link in my email signature &mdash; I'd rather walk through this live than trade more redlines on it.</p>

<p>Once we're aligned on &sect;9.02 and &sect;3.3(e), I'll send a clean counter-redlined DOCX reflecting everything above.</p>

<p>Thanks,</p>

</div>
$sig
</body>
</html>
"@

# --- Connect ---
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome
Write-Host "Connected." -ForegroundColor Green

# --- Create draft ---
Write-Host "Creating draft..." -ForegroundColor Cyan
$draftParams = @{
    Subject = $subject
    Body    = @{ ContentType = "HTML"; Content = $htmlBody }
    ToRecipients = @(
        @{ EmailAddress = @{ Address = $toEmail; Name = $toName } }
    )
}
$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter $draftParams
$draftId = $draft.Id

# Save MessageId for future reference
Set-Content -Path $idFile -Value $draftId -Encoding UTF8
Write-Host "Draft created. MessageId saved to: $idFile" -ForegroundColor Green
Write-Host "Subject : $subject" -ForegroundColor Gray
Write-Host "To      : $toEmail" -ForegroundColor Gray

Disconnect-MgGraph | Out-Null
Write-Host "`nDRAFT is in Outlook Drafts. Open it in Outlook, review, then send manually." -ForegroundColor Yellow