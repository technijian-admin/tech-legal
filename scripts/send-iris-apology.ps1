# Send apology email to Iris for the duplicate signature emails earlier today.
# Persistent-URL DocuSign email (envelope 653f30f8-d94a-8224-82b3-c07b11d0174f) was just sent separately.

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sigPath   = Join-Path $scriptDir "ravi-signature.html"
$sig       = [System.IO.File]::ReadAllText($sigPath)

$fontStack = "Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif"
$body = @"
<html><body dir="ltr">
<div style="font-family:$fontStack;font-size:12pt;color:rgb(0,0,0)">

<p>Iris,</p>

<p>Apologies for the flurry of signature-related emails from our side this afternoon &mdash; those earlier invitations were sent in error and have all been voided. Please disregard them.</p>

<p>The final, correct DocuSign invitation for <strong>SOW-AFFG-004 Rev 1 &mdash; Fleet Right-Sizing and Compliance Configuration</strong> has just been sent. That one is good to go and the signing link in it stays valid, so no rush &mdash; please review and sign at your convenience.</p>

<p>Rev 1 reflects everything we discussed: BYOD MAM-only for personal mobile devices, 10 managed endpoints (4 Mac Mini + 6 Windows laptops), Azure Entra SSO, CloudBrink ZTNA replacing Cisco Umbrella, and office WAN IP + CloudBrink egress whitelisting at Schwab and IBKR.</p>

<p>Sorry again for the noise. Happy to jump on a quick call if anything in the SOW needs further discussion &mdash; use the booking link in my signature below.</p>

<p>Thank you,</p>

</div>
$sig
</body></html>
"@

# --- Preview for sanity check ---
$previewPath = Join-Path $scriptDir "iris-apology-preview.html"
Set-Content -Path $previewPath -Value $body -Encoding UTF8
if ($body -match '[^\w`]\,\d{3}') { Write-Warning "Possible stripped `$ sign detected" }
if ($body -match '\{\{|\$\w+\b') { Write-Warning "Unresolved placeholder or variable detected" }
Write-Host "Body length: $($body.Length). Preview: $previewPath"

# --- M365 Graph token ---
$m365Keys = [System.IO.File]::ReadAllText("C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md")
$cid = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(.+)').Groups[1].Value.Trim()
$tok = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tid/oauth2/v2.0/token" -Method POST `
    -Body @{ grant_type='client_credentials'; client_id=$cid; client_secret=$sec; scope='https://graph.microsoft.com/.default' } `
    -ContentType 'application/x-www-form-urlencoded'
$gH = @{ Authorization = "Bearer $($tok.access_token)"; 'Content-Type' = 'application/json' }

$payload = @{
    Message = @{
        Subject = "Apologies for the earlier signature emails"
        Body = @{ ContentType = "HTML"; Content = [string]$body }
        ToRecipients = @( @{ EmailAddress = @{ Address = "iris.liu@americanfundstars.com"; Name = "Iris Liu" } } )
        From = @{ EmailAddress = @{ Address = "rjain@technijian.com"; Name = "Ravi Jain - Technijian" } }
    }
    SaveToSentItems = $true
} | ConvertTo-Json -Depth 6 -Compress

$r = Invoke-WebRequest -Uri "https://graph.microsoft.com/v1.0/users/RJain@technijian.com/sendMail" -Method POST -Headers $gH -Body $payload -UseBasicParsing
Write-Host "Apology sent to Iris Liu: $($r.StatusCode)" -ForegroundColor Green
