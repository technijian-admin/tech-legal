# Reply DRAFT to Frank Dunn's "Sunrun Solar Demand" email (2026-04-27 18:22)
# Creates a reply-all draft in Outlook with factual corrections + 3 SDG&E bill attachments
# Does NOT send. User reviews in Outlook before clicking Send.

$ErrorActionPreference = "Stop"

$senderUpn        = "RJain@technijian.com"
$frankMessageId   = "AAMkAGNlYjM0OTA4LThjMjYtNGQ3My1iNDg1LTQ2MTI5NTg0NzFlOQBGAAAAAAC88IffM67WS4tSyVwwqYmJBwBhk-ls8ubYRazD3tGgncxCAAAAAAENAACgx7VhNWW1QYCgfGa-8kbOAAX6umyIAAA="

$sigPath = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"
$billDir = "C:\vscode\tech-legal\tech-legal\docs\personal\sunrun"

$attachments = @(
    "$billDir\Apr-2026.pdf",
    "$billDir\Nov-2025.pdf",
    "$billDir\Dec-2025.pdf"
)

# --- Credentials ---
Write-Host "Reading M365 Graph credentials..." -ForegroundColor Cyan
$m365Keys     = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $m365ClientId -or -not $m365TenantId -or -not $m365Secret) {
    Write-Error "Failed to parse M365 credentials"; exit 1
}

# --- Validate attachments ---
Write-Host "Validating attachments..." -ForegroundColor Cyan
foreach ($f in $attachments) {
    if (-not (Test-Path $f)) { Write-Error "Missing: $f"; exit 1 }
    $sz = [math]::Round((Get-Item $f).Length / 1KB, 1)
    Write-Host "  OK  $([System.IO.Path]::GetFileName($f))  ($sz KB)" -ForegroundColor Gray
}

# --- Signature ---
$sig = ""
if (Test-Path $sigPath) { $sig = [System.IO.File]::ReadAllText($sigPath) }

# --- Build reply body (NOTE: backtick-dollar for literal `$ in here-string) ---
$fontStack = "Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif"
$replyBody = @"
<div style="font-family:$fontStack;font-size:12pt;color:rgb(0,0,0)">

<p>Frank,</p>

<p>Thank you for the updated draft. I have reviewed it carefully against the SDG&amp;E bills and the Sunrun customer portal and have several factual corrections to flag before you send. The corrections are documented in the attached SDG&amp;E bills.</p>

<p><strong>1. Excess electricity charges &mdash; use `$3,608.41 (not `$2,500).</strong> The April 2026 SDG&amp;E bill is the controlling document. Page 1 states plainly: &ldquo;Your account has a balance of `$3,608.41.&rdquo; Page 5 (Net Energy Metering Summary) breaks it down: `$3,292.38 in YTD net metering charges plus `$316.03 in non-bypassable charges, total `$3,608.41. This is SDG&amp;E&rsquo;s own accounting since the new NEM cycle began on November 7, 2025 &mdash; not my estimate. The `$2,500 figure was an early ballpark from before the April bill posted; the controlling number is now `$3,608.41 (round to `$3,600).</p>

<p><strong>2. System cessation date &mdash; November 7, 2025 (not November 6).</strong> The April 2026 SDG&amp;E bill, page 5, shows the new Net Energy Metering cycle &ldquo;Start Date: 11/07/2025.&rdquo; That is SDG&amp;E&rsquo;s system of record for when zero solar export began. November 6, 2025 was the True-Up date &mdash; the last day of the prior NEM cycle when the system was still working. My April 17 formal demand letter (which Sunrun has) used 11/7/25 throughout, and the email subject line we&rsquo;ve all been using reads &ldquo;Solar System Disconnected 11/7/25-4/16/26.&rdquo; Off by one day in the current draft.</p>

<p><strong>3. Sunrun case opening date &mdash; November 10, 2025 (not November 11).</strong> The Sunrun customer portal at my.sunrun.com lists Service Case #18181148 with &ldquo;Date opened: 11/10/2025.&rdquo;</p>

<p><strong>4. Outage end date &mdash; the 2017 (Costco) system is not yet fully restored.</strong> The 2012 system was restored on April 17, 2026, but the 2017 system was not restored as of April 17 and remains not fully operational. Sunrun has a follow-up service appointment scheduled for May 4, 2026 specifically for the 2017 system. The current draft&rsquo;s &ldquo;through April 20, 2026&rdquo; understates this. Suggested phrasing: &ldquo;from November 7, 2025 through April 17, 2026 for the 2012 System, with the 2017 System remaining not fully operational as of the date of this letter.&rdquo;</p>

<p><strong>5. Address ZIP code typo.</strong> Both addresses on page 1 reference 600 California Street, Suite 1800. Sunrun, Inc. is shown as 94108 (correct); Sunrun Installation Services, Inc. is shown as 94104 (typo unless the registered agent address differs). Recommend confirming both as 94108 or pulling the registered agent on file with the California Secretary of State.</p>

<p><strong>6. The &ldquo;over `$20,000&rdquo; figure for the 2012 PPA.</strong> Please confirm this number is from the 2012 Solar Power Service Agreement itself before signing &mdash; I want to verify the exact prepaid figure rather than rely on an estimate.</p>

<p><strong>Attachments:</strong></p>
<ol>
  <li><strong>Apr-2026.pdf</strong> &mdash; the April 2026 SDG&amp;E bill. Page 1 shows the `$3,608.41 balance; page 5 shows the NEM cycle start date 11/07/2025 and the YTD charges of `$3,292.38. This is the single most important supporting document.</li>
  <li><strong>Nov-2025.pdf</strong> &mdash; the November 2025 SDG&amp;E bill. Last billing period of the prior NEM cycle (Oct 8 &ndash; Nov 6, 2025), 1,407 kWh net, system still working.</li>
  <li><strong>Dec-2025.pdf</strong> &mdash; the December 2025 SDG&amp;E bill. First billing period of the new NEM cycle (Nov 7 &ndash; Dec 8, 2025), 2,088 kWh net, zero solar export &mdash; the smoking gun for the November 7, 2025 cessation date.</li>
</ol>

<p>The progression across all seven bills (Oct 2025 through April 2026) is unmistakable: daily-average kWh change vs prior year goes from -12.4% on the November bill (last normal month) to +7.8% in December, +40.3% in January and February, +147.5% in March, and +235.1% in April &mdash; consistent with continuous zero solar export from 11/7/25 forward as solar generation would normally grow heading into spring.</p>

<p>On your strategy points: I understand the likely Sunrun response and the no-consequential-damages clauses in both agreements. The `$3,608.41 in excess electricity charges, however, are direct out-of-pocket damages charged by SDG&amp;E to my account, not consequential damages &mdash; please make sure that distinction is preserved in the demand. I am aligned on the Section 8 Guaranteed Output Credit ask for the 2012 system.</p>

<p>Once these corrections are incorporated, please proceed with the FedEx send. Standing by if you have any questions.</p>

<p>Thanks, Frank.</p>

</div>
$sig
"@

# --- Connect ---
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome
Write-Host "Connected." -ForegroundColor Green

# --- createReplyAll on Frank's message (preserves thread, To/CC, quoted body) ---
Write-Host "Creating reply-all draft..." -ForegroundColor Cyan
$replyDraft = Invoke-MgGraphRequest -Method POST `
    -Uri "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$frankMessageId/createReplyAll"
$draftId = $replyDraft.id
Write-Host "Draft created. Id=$draftId" -ForegroundColor Green

# --- Prepend our reply body ABOVE the quoted reply chain ---
$existingBody = $replyDraft.body.content
$mergedBody   = $replyBody + "<br><br>" + $existingBody

Write-Host "Updating draft body..." -ForegroundColor Cyan
$patchPayload = @{
    body = @{
        contentType = "HTML"
        content     = $mergedBody
    }
} | ConvertTo-Json -Depth 6 -Compress

Invoke-MgGraphRequest -Method PATCH `
    -Uri "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$draftId" `
    -Body $patchPayload `
    -ContentType "application/json"
Write-Host "Body updated." -ForegroundColor Green

# --- Attach the 3 SDG&E bills ---
Write-Host "Attaching SDG&E bills..." -ForegroundColor Cyan
foreach ($f in $attachments) {
    $bytes = [System.IO.File]::ReadAllBytes($f)
    $b64   = [Convert]::ToBase64String($bytes)
    $name  = [System.IO.Path]::GetFileName($f)

    $attPayload = @{
        "@odata.type" = "#microsoft.graph.fileAttachment"
        name          = $name
        contentBytes  = $b64
    } | ConvertTo-Json -Depth 4 -Compress

    Invoke-MgGraphRequest -Method POST `
        -Uri "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$draftId/attachments" `
        -Body $attPayload `
        -ContentType "application/json" | Out-Null
    Write-Host "  attached  $name" -ForegroundColor Gray
}

Disconnect-MgGraph | Out-Null

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Yellow
Write-Host "DRAFT READY in Outlook Drafts (NOT sent)." -ForegroundColor Yellow
Write-Host "Open Outlook -> Drafts -> 'RE: Sunrun Solar Demand'" -ForegroundColor Yellow
Write-Host "Review, then click Send." -ForegroundColor Yellow
Write-Host "Draft Id: $draftId" -ForegroundColor Gray
Write-Host "=========================================================" -ForegroundColor Yellow
