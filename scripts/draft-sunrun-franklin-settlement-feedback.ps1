# Reply to Franklin T. Dunn on Sunrun's 5/7 settlement agreement and
# his redline. Frank invited additional input ("You may have other
# provisions you don't want to agree to"). This reply offers three
# suggested upgrades, framed as suggestions Frank can use or skip per
# his judgment — Ravi is willing to sign as Frank already has it.
#
# Default is DRAFT-ONLY. Use -Send to dispatch.

param([switch]$Send)

$ErrorActionPreference = "Stop"

$toRecipients = @(
    @{ Address = "fdunn@callahan-law.com"; Name = "Franklin T. Dunn" }
)
$ccRecipients = @(
    @{ Address = "ES@callahan-law.com"; Name = "Edward Susolik" }
)

$senderUpn = "RJain@technijian.com"
$subject   = "RE: FW: Complaint received for Ravi Jain"
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

<p>Frank,</p>

<p>Thanks for the quick turn on this. Your three redlines &mdash; the scoped Damage Claim, the narrowed &sect;5.1 Release with the four-prong notwithstanding clause, and stripping the C&amp;B obligations &mdash; cover the points that matter most to me. I&#39;m comfortable signing the agreement as you have it.</p>

<p>Below are three additional items you mentioned I might want to consider. Treat these strictly as <strong>suggestions for your judgment</strong>, not asks. If you think any of them aren&#39;t worth pushing for at this stage given the `$2,000 settlement size and the goal of closing this out, I&#39;m fine letting them go and signing the version you sent.</p>

<h3 style="color:#b30000;">1. 2017 Limited Warranty &mdash; verification question</h3>

<p>Sunrun&#39;s Gabby wrote on April 30 that <em>&ldquo;System 1772672455 (PTO 03/14/2018) does not have any production guarantees.&rdquo;</em> Your &sect;5.1 carve-out preserves <em>future</em> warranty / service / contractual breaches but doesn&#39;t expressly preserve any <em>existing</em> rights under the 2017 Limited Warranty. <strong>Question</strong>: when you have a moment with the 2017 contract docs, does the Limited Warranty there contain any ongoing performance / output test, or is it strictly a labor/repair warranty? If it&#39;s production-related at all, an explicit carve-out preserving it would close the door on Sunrun later arguing the release ratified Gabby&#39;s &ldquo;no production guarantee&rdquo; characterization. If it&#39;s purely labor, your existing carve-out (a)+(b) already covers it and we don&#39;t need anything more. Your call.</p>

<h3 style="color:#b30000;">2. Mutual release</h3>

<p>The current draft is one-way &mdash; I release Sunrun, but Sunrun doesn&#39;t release me. For a counsel-on-counsel settlement, mutual seems standard and I&#39;d rather not leave them with a latent counterclaim option. If you think it&#39;s a low-cost ask, something like:</p>

<blockquote style="border-left:3px solid #ccc;padding-left:12px;color:#444;">
Sunrun, on behalf of itself and the Released Parties, hereby releases Customer from any and all claims arising out of or related to the Damage Claim.
</blockquote>

<p>If you&#39;d rather not slow the close-out down with this, fine to leave it.</p>

<h3 style="color:#b30000;">3. Regulatory-complaint posture</h3>

<p>The release is silent on whether I&#39;m required to withdraw any agency complaints (CSLB, BBB, CPUC). I haven&#39;t actually filed anything yet, but I prepared the CSLB and BBB complaints as part of the demand-letter pressure track. Two ways this could go:</p>

<ul>
  <li><strong>Express preservation</strong>: a one-line addition that <em>&ldquo;Nothing in this Settlement Agreement requires Customer to withdraw any complaint filed with, or to refrain from filing any complaint with, the Contractors State License Board, the Better Business Bureau, the California Public Utilities Commission, or any other governmental or regulatory body.&rdquo;</em></li>
  <li><strong>Silence</strong>: leave as-is and rely on the narrowed Release scope to keep agency-channel rights intact.</li>
</ul>

<p>Either way works for me. Do you have a preference?</p>

<h3 style="color:#b30000;">Smaller items I&#39;d only mention if you think they&#39;re free</h3>

<ul>
  <li>Define <em>&ldquo;Effective Date&rdquo;</em> expressly (date of last signature) &mdash; it&#39;s used several times but never defined.</li>
  <li>Push payment from <em>30 business days</em> to <em>30 calendar days</em> of signing + W-9 receipt &mdash; cuts ~2 weeks.</li>
  <li>Make the 14-day compelled-disclosure notice obligation in &sect;4.2 mutual rather than one-way on me.</li>
  <li>Tighten the &sect;5.1 phrase <em>&ldquo;your relationship with Sunrun&rdquo;</em> to <em>&ldquo;your relationship with Sunrun under the Service Agreement&rdquo;</em>.</li>
</ul>

<p>Net: the version you sent is acceptable. The above is for your judgment on what&#39;s worth raising vs. what&#39;s noise. Let me know how you want to proceed and I&#39;ll be ready to sign on DocuSign once you&#39;re done with Sunrun&#39;s counsel.</p>

<p>Thank you,</p>

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

$draftParams = @{
    Subject      = $subject
    Body         = @{ ContentType = "HTML"; Content = $htmlBody }
    ToRecipients = @($toGraph)
    CcRecipients = @($ccGraph)
    Importance   = "Normal"
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
