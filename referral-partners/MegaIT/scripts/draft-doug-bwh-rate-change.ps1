# Draft email to Doug McGaugh: BWH labor rate reduction notice (effective 2026-05-01)
# Frames the rate cut as a successful account retention (vs the BST loss).
# DEFAULT: creates draft only (review in Outlook before sending).

param([switch]$Send)

$ErrorActionPreference = "Stop"

$to = @( @{ Address = "doug@megait.us"; Name = "Douglas McGaugh" } )
$cc = @()

$senderUpn = "RJain@technijian.com"
$subject   = "BWH Rate Change - Effective May 1, 2026"

$sigPath = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"

Write-Host "Reading credentials..." -ForegroundColor Cyan
$keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$cid = [regex]::Match($keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value

$sig = ""
if (Test-Path $sigPath) { $sig = Get-Content $sigPath -Raw }

$fontStack = "Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif"

$bodyTemplate = @'
<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>
<body dir="ltr">
<div style="font-family:__FONT__;font-size:12pt;color:rgb(0,0,0)">

<p>Doug,</p>

<p>Heads-up on a BWH change effective <b>May 1, 2026</b>.</p>

<p>BWH came back with redlines on the new MSA earlier this month and pushed hard to lower their costs. Rather than risk losing the account &mdash; the same outcome we just had with Boston &mdash; we worked through the redlines with Dave and agreed to a <b>15% reduction across all Virtual Staff labor rates</b> in exchange for the consolidated MSA going forward. Dave signed off on the package on April 28, and the executed MSA is now out for DocuSign signature (envelope already dispatched). The deal is closed; the rates below are locked.</p>

<p>The new rates take effect with the May 2026 invoice:</p>

<table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse;font-family:__FONT__;font-size:11pt;margin:8px 0">
<tr style="background:#006DB6;color:#ffffff;font-weight:bold">
  <td>Line</td><td align="right">Hrs/mo</td><td align="right">Old rate</td><td align="right">New rate</td><td align="right">New monthly</td>
</tr>
<tr style="background:#FEF3EE"><td><b>Systems Architect</b></td><td align="right">5.00</td><td align="right">$200/hr</td><td align="right"><b>$170/hr</b></td><td align="right"><b>$850.00</b></td></tr>
<tr><td>USA Tech (Normal)</td><td align="right">15.26</td><td align="right">$125/hr</td><td align="right">$106.25/hr</td><td align="right">$1,621.38</td></tr>
<tr><td>India Tech (Normal)</td><td align="right">58.13</td><td align="right">$15/hr</td><td align="right">$12.75/hr</td><td align="right">$741.16</td></tr>
<tr><td>India Tech (After Hours)</td><td align="right">42.82</td><td align="right">$30/hr</td><td align="right">$25.50/hr</td><td align="right">$1,091.91</td></tr>
</table>

<p>The Systems Architect line on the BWH contract therefore goes from $1,000/mo to <b>$850/mo</b> beginning with the May invoice. I wanted you to hear it from me directly so the first new-rate invoice doesn&rsquo;t come as a surprise. Keeping BWH at $850/mo is a meaningfully better outcome than the alternative we saw with BST, and it preserves the relationship for the long run.</p>

<p>To be clear, this <b>was not a Doug-specific cut</b>. The 15% reduction applied across every Technijian labor line on the BWH agreement, and the same logic applied internally to my own rates &mdash; <b>my CTO Advisory rate moved from $250/hr to $212.50/hr</b> in parallel so the rate sheet stays uniform. Everyone took the same haircut to retain the account. If you&rsquo;d like, I can send you the BWH Schedule A so you can see the full rate sheet directly &mdash; just let me know.</p>

<p>The BWH cycle and structural mechanics are otherwise unchanged.</p>

<p>As a reminder, all communications regarding Technijian matters &mdash; including anything related to BWH, this rate change, or any other client &mdash; should be directed only to me, in writing, by email at this address. Please do not contact BWH or any Technijian staff about this. If you have questions, send them to me and I&rsquo;ll respond.</p>

<p>Thanks,</p>

__SIG__

</div>
</body>
</html>
'@

$htmlBody = $bodyTemplate.Replace('__FONT__', $fontStack).Replace('__SIG__', $sig)

if ($htmlBody -match '\$\s+\d') { throw "Stripped dollar sign before digit. Aborting." }
if ($htmlBody -match '__FONT__|__SIG__') { throw "Unfilled placeholder. Aborting." }

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$cred = New-Object System.Management.Automation.PSCredential($cid, (ConvertTo-SecureString $sec -AsPlainText -Force))
Connect-MgGraph -TenantId $tid -ClientSecretCredential $cred -NoWelcome | Out-Null

$draftParams = @{
    Subject = $subject
    Body = @{ ContentType = "HTML"; Content = $htmlBody }
    ToRecipients = @($to | ForEach-Object { @{ EmailAddress = @{ Address = $_.Address; Name = $_.Name } } })
    CcRecipients = @()
    Attachments  = @()
}
$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter $draftParams
Write-Host "Draft created. MessageId = $($draft.Id)" -ForegroundColor Green

if ($Send) {
    Write-Host "Sending..." -ForegroundColor Cyan
    Send-MgUserMessage -UserId $senderUpn -MessageId $draft.Id
    Write-Host "SENT to $($to[0].Address)." -ForegroundColor Green
} else {
    Write-Host "DRAFT saved. Review in Outlook -> Drafts -> '$subject'" -ForegroundColor Yellow
    Write-Host "  To: $($to[0].Address)" -ForegroundColor Gray
}

Disconnect-MgGraph | Out-Null
