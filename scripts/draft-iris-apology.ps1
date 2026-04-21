# Draft a brief personal apology email from Ravi to Iris — save to Outlook Drafts for review
$ErrorActionPreference = "Stop"
$sigPath = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"
$sig = [System.IO.File]::ReadAllText($sigPath)

$fontStack = "Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif"
$body = @"
<html><body dir="ltr">
<div style="font-family:$fontStack;font-size:12pt;color:rgb(0,0,0)">

<p>Iris,</p>

<p>Apologies for the flurry of signature-related emails from us this afternoon &mdash; those earlier ones were sent in error and have all been voided. Please disregard them.</p>

<p>You will receive <strong>one</strong> clean DocuSign email shortly (or it may already be in your inbox) for <strong>SOW-AFFG-004 Rev 1 &mdash; Fleet Right-Sizing and Compliance Configuration</strong>. That is the final, correct version. The signing link in it will stay valid, so no rush &mdash; review when you have a moment.</p>

<p>This Rev 1 reflects everything we discussed: BYOD MAM-only for personal mobile devices, 10 managed endpoints (4 Mac Mini + 6 Windows laptops), Azure Entra SSO, CloudBrink ZTNA replacing Cisco Umbrella, and office WAN IP + CloudBrink egress whitelisting at Schwab and IBKR.</p>

<p>Sorry for the noise. Let me know if you have any questions.</p>

<p>Thank you,</p>

</div>
$sig
</body></html>
"@

$m365Keys = [System.IO.File]::ReadAllText("C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md")
$cid = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(.+)').Groups[1].Value.Trim()
$tok = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tid/oauth2/v2.0/token" -Method POST `
    -Body @{ grant_type='client_credentials'; client_id=$cid; client_secret=$sec; scope='https://graph.microsoft.com/.default' } `
    -ContentType 'application/x-www-form-urlencoded'
$gH = @{ Authorization = "Bearer $($tok.access_token)"; 'Content-Type' = 'application/json' }

$draftPayload = @{
    subject = "Apologies for the earlier signature emails"
    body = @{ contentType = "HTML"; content = [string]$body }
    toRecipients = @( @{ emailAddress = @{ address = "iris.liu@americanfundstars.com"; name = "Iris Liu" } } )
} | ConvertTo-Json -Depth 6 -Compress

$draft = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/RJain@technijian.com/messages" -Method POST -Headers $gH -Body $draftPayload
Write-Host "Apology draft created: $($draft.id)" -ForegroundColor Green
Write-Host "Review in Outlook -> Drafts, then send manually."

# Also render to file for browser preview
Set-Content -Path "C:\vscode\tech-legal\tech-legal\scripts\iris-apology-preview.html" -Value $body -Encoding UTF8
Write-Host "Browser preview: C:\vscode\tech-legal\tech-legal\scripts\iris-apology-preview.html"
