# Send US Pay Reduction Announcement -- Irvine office distribution list
# Internal announcement: 25% US compensation reduction, effective immediately,
# chosen in lieu of (deferring) a US workforce reduction.
#
# Usage:
#   .\send-us-pay-reduction-2026-05-11.ps1                          # draft only (DEFAULT)
#   .\send-us-pay-reduction-2026-05-11.ps1 -DeletePrior <draftId>   # delete prior draft first
#   .\send-us-pay-reduction-2026-05-11.ps1 -Send                    # send immediately

param(
    [switch]$Send,
    [string]$DeletePrior
)

$ErrorActionPreference = "Stop"

$senderUpn = "RJain@technijian.com"
$subject   = "Important team update"

$to = @(
    @{ Address = "irvine@technijian.com"; Name = "Irvine" }
)

# Match Ravi's actual Outlook formatting (Aptos 12pt, one <div> per line)
$bodyText = @"
<div class="elementToProof" style="font-family:Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)">Team,</div>
<div style="font-family:Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)"><br></div>
<div style="font-family:Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)">I need to share something difficult with you.</div>
<div style="font-family:Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)"><br></div>
<div style="font-family:Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)">The September 2024 malware incident and the loss of four major client accounts in late 2024 and early 2025 have put sustained pressure on our revenue. I have done everything I could to keep that pressure off of you. Today I cannot continue to.</div>
<div style="font-family:Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)"><br></div>
<div style="font-family:Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)"><b>Effective immediately, all US compensation is being reduced by 25%.</b></div>
<div style="font-family:Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)"><br></div>
<div style="font-family:Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)">I want you to know why I am making this call and not a different one. The alternative was a US workforce reduction. I would rather everyone stay, take a hard cut, and give us a runway to recover than send anyone home. So that is the call I am making.</div>
<div style="font-family:Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)"><br></div>
<div style="font-family:Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)">There are client opportunities I am actively working that I believe can change our trajectory. I will keep you informed as those develop, and I am committed to revisiting this reduction as soon as our position allows.</div>
<div style="font-family:Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)"><br></div>
<div style="font-family:Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)">If you have questions about how this affects your specific situation, please book time with me directly and we will talk through it.</div>
<div style="font-family:Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)"><br></div>
<div style="font-family:Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)">I know this is hard, and I do not take it lightly. Thank you for staying with Technijian through this period.</div>
"@

$sigPath = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"
$signature = Get-Content $sigPath -Raw

$htmlBody = $bodyText + "`n" + $signature

Write-Host "Reading M365 Graph credentials..." -ForegroundColor Cyan
$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$cid = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value

if (-not $cid -or -not $tid -or -not $sec) {
    throw "Failed to parse M365 Graph credentials from keys file"
}

$cred = New-Object System.Management.Automation.PSCredential($cid, (ConvertTo-SecureString $sec -AsPlainText -Force))
Connect-MgGraph -TenantId $tid -ClientSecretCredential $cred -NoWelcome

if ($DeletePrior) {
    Write-Host "Deleting prior draft $DeletePrior..." -ForegroundColor Yellow
    try {
        Invoke-MgGraphRequest -Method DELETE -Uri "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$DeletePrior"
        Write-Host "Prior draft deleted." -ForegroundColor Green
    } catch {
        Write-Host "Could not delete prior draft: $_" -ForegroundColor Red
    }
}

Write-Host "Creating draft..." -ForegroundColor Cyan
$toRecipients = @()
foreach ($r in $to) {
    $toRecipients += @{ EmailAddress = @{ Address = $r.Address; Name = $r.Name } }
}

$draftParams = @{
    Subject      = $subject
    Body         = @{ ContentType = "HTML"; Content = $htmlBody }
    ToRecipients = $toRecipients
}

$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter $draftParams
Write-Host "Draft created: $($draft.Id)" -ForegroundColor Green
Write-Host "  Subject: $subject" -ForegroundColor Gray
Write-Host "  To:      $($to | ForEach-Object { $_.Address } | Join-String -Separator ', ')" -ForegroundColor Gray

if ($Send) {
    Write-Host "Sending..." -ForegroundColor Yellow
    Send-MgUserMessage -UserId $senderUpn -MessageId $draft.Id
    Write-Host "SENT." -ForegroundColor Green
} else {
    Write-Host "Draft saved. Review in Outlook Drafts; re-run with -Send to send." -ForegroundColor Cyan
}
