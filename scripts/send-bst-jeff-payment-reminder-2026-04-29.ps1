# BST payment reminder -- Wed 4/29. Jeff accepted $12,443.95 monthlies-only on 4/27.
# Wire must arrive by Thu 4/30 COB. This is a brief reminder + wire-reference request.
#
# CHECK BILLING FIRST: billing@technijian.com may have already received the wire.
# If wire confirmed received, do NOT send this -- go directly to closeout actions:
#   (1) Void invoice #28064 in Client Portal
#   (2) Mark all 4 monthly invoices paid
#   (3) Ask Frank to coordinate mutual release with Mr. Cron
#
# If no wire yet: run this script to create a draft, review in Outlook, then click Send.
#
# Encoding note: all dollar signs in the @"..."@ here-string use backtick-dollar (`$).
#                All non-ASCII uses HTML entities. Source is 7-bit ASCII.

$ErrorActionPreference = "Stop"

$senderUpn = "RJain@technijian.com"
$sigPath   = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"

$subject = "Boston Group -- Payment Due Tomorrow (April 30)"

# Credentials
$m365Keys     = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value

# Signature
$sig = ""
if (Test-Path $sigPath) { $sig = [System.IO.File]::ReadAllText($sigPath) }

$fontStack = "Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif"

$htmlBody = @"
<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>
<body dir="ltr">
<div style="font-family:$fontStack;font-size:12pt;color:rgb(0,0,0)">

<p>Jeff,</p>

<p>Just a brief note ahead of tomorrow's deadline. Per your confirmation on April 27, we are
expecting payment of <strong>`$12,443.95</strong> (the four outstanding monthly invoices) to
arrive by <strong>end of business Thursday, April 30</strong>.</p>

<p>Once the wire is sent, please reply with the wire reference number or have your AP send it
to <a href="mailto:billing@technijian.com">billing@technijian.com</a> so we can confirm
receipt and close this out on our end.</p>

<p>On our end, upon confirming receipt we will void invoice #28064 and coordinate the mutual
release with Mr. Cron so both companies have clean paper.</p>

<p>If anything has changed on your side, please let me know today so we have time to address it.</p>

<p>Thank you,</p>

</div>
$sig
</body>
</html>
"@

# Preflight checks
if ($htmlBody -match '[\s>](,\d{3})') {
    Write-Host "ABORT: Stripped-dollar pattern near '$($matches[1])'." -ForegroundColor Red; exit 1
}
$bodyChars = $htmlBody.ToCharArray() | ForEach-Object { [int]$_ }
if ($bodyChars -contains 0xC2 -or $bodyChars -contains 0xC3) {
    Write-Host "ABORT: Mojibake codepoint detected." -ForegroundColor Red; exit 1
}
$mustHave = @('`$12,443.95', 'April 30', 'billing@technijian.com', '#28064')
foreach ($needle in $mustHave) {
    if ($htmlBody -notmatch [regex]::Escape($needle.Replace('`$', '$'))) {
        Write-Host "ABORT: Required text '$needle' missing." -ForegroundColor Red; exit 1
    }
}
Write-Host "Preflight passed." -ForegroundColor Green

# Connect
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome
Write-Host "Connected to M365 Graph." -ForegroundColor Green

# Create draft
$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter @{
    Subject      = $subject
    Body         = @{ ContentType = "HTML"; Content = $htmlBody }
    ToRecipients = @(
        @{ EmailAddress = @{ Address = "jklein@bostongroupwaste.com"; Name = "Jeff Klein" } }
    )
    CcRecipients = @(
        @{ EmailAddress = @{ Address = "gagan@bostongroupwaste.com";  Name = "Gagan Singh" } }
        @{ EmailAddress = @{ Address = "lcronlaw@gmail.com";          Name = "Lawrence Cron, Esq." } }
        @{ EmailAddress = @{ Address = "fdunn@callahan-law.com";      Name = "Frank Dunn, Esq." } }
        @{ EmailAddress = @{ Address = "es@callahan-law.com";         Name = "Edward Susolik, Esq." } }
        @{ EmailAddress = @{ Address = "billing@technijian.com";      Name = "Billing" } }
    )
}

Disconnect-MgGraph | Out-Null

Write-Host ""
Write-Host "====================================================" -ForegroundColor Yellow
Write-Host " DRAFT READY -- NOT SENT" -ForegroundColor Yellow
Write-Host "====================================================" -ForegroundColor Yellow
Write-Host "TO:   jklein@bostongroupwaste.com (Jeff Klein)"
Write-Host "CC:   gagan@bostongroupwaste.com, lcronlaw@gmail.com"
Write-Host "CC:   fdunn@callahan-law.com, es@callahan-law.com, billing@technijian.com"
Write-Host "SUBJ: $subject"
Write-Host ""
Write-Host "BEFORE SENDING:" -ForegroundColor Yellow
Write-Host "  1. Check with billing -- wire may have already arrived from 4/27." -ForegroundColor Gray
Write-Host "  2. If wire confirmed received, DO NOT SEND -- go straight to closeout." -ForegroundColor Gray
Write-Host "  3. If no wire yet, review draft in Outlook and click Send." -ForegroundColor Gray
Write-Host ""
Write-Host "Draft Id: $($draft.Id)" -ForegroundColor Gray
Write-Host "====================================================" -ForegroundColor Yellow
