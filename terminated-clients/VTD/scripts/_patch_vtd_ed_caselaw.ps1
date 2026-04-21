# Patch the VTD-Ed draft with the Broader Case-Law Refresh section.
$ErrorActionPreference = "Stop"
$senderUpn = "RJain@technijian.com"
$subjectNeedle = "VTD Settlement Package - Late Add: POD-Column"

$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$cid = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
$cred = New-Object System.Management.Automation.PSCredential($cid, (ConvertTo-SecureString $sec -AsPlainText -Force))
Connect-MgGraph -TenantId $tid -ClientSecretCredential $cred -NoWelcome

# Find most-recent draft matching subject
$drafts = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$senderUpn/mailFolders/Drafts/messages?`$top=20&`$orderby=lastModifiedDateTime desc&`$select=id,subject"
$match = $null
foreach ($m in $drafts.value) {
    if ($m.subject -and $m.subject.Contains($subjectNeedle)) { $match = $m; break }
}
if (-not $match) { Write-Error "Draft not found"; Disconnect-MgGraph | Out-Null; exit 1 }
$messageId = $match.id
Write-Host "Found draft: $($match.subject)"

$full = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$messageId" + "?`$select=body"
$html = $full.body.content

if ($html.Contains('Broader case-law refresh')) {
    Write-Host "Patch already present; nothing to do." -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null
    exit 0
}

# Anchor: insert immediately BEFORE the "Proposed exhibits (attached to this email)" paragraph
$anchor = '<p><b>Proposed exhibits (attached to this email).</b>'
if (-not $html.Contains($anchor)) {
    Write-Error "Could not locate insertion anchor"
    Disconnect-MgGraph | Out-Null
    exit 1
}

$newSection = @'
<p><b>Broader case-law refresh for the 4/14 memo.</b> While I was on this, I ran a targeted 2020&ndash;2026 California sweep against the authorities in the existing Case Law Research Memorandum to see if anything newer or stronger should be cited before the settlement conference. All need Shepardizing before filing.</p>

<p><b><i>Grade A &mdash; Cite in the memo</i></b></p>

<p>1. <b><i>Gormley v. Gonzalez</i></b> (2022) 84 Cal.App.5th 72. Held that in a non-consumer contract, &sect;&nbsp;1671(b) creates "a general rule favoring the enforcement of liquidated damages provisions" and the challenger bears the burden. Pairs with <i>Ridgley</i> and sharpens the burden-shift. Belongs in &sect;&nbsp;2 of the memo, before <i>El Centro Mall</i>.</p>

<p>2. <b><i>Iyere v. Wise Auto Group</i></b> (2023) 87 Cal.App.5th 747. Bare "I don't recall signing" is insufficient to dispute authenticity; authentication may be "carried in any manner." First post-2020 published appellate decision to rebalance toward the proponent. Belongs in &sect;&nbsp;17 alongside <i>Fabian</i> and <i>Ruiz</i>. Caveat: <i>Iyere</i> concerned a physical signature and the court distinguished electronic ones &mdash; cite for the burden-framework, not as direct e-sig authority.</p>

<p>3. <b><i>People v. Hawkins</i></b> (2002) 98 Cal.App.4th 1428. Backstops the Evid.&nbsp;Code &sect;&nbsp;1552 presumption that printed representations of computer-generated information are accurate. Pre-2020 but stronger than <i>Aguimatang</i> alone on that narrow point. Belongs in &sect;&nbsp;23.</p>

<p><b><i>Grade B &mdash; Consider</i></b></p>

<p>4. <b><i>Constellation-F, LLC v. World Trading 23, Inc.</i></b> (2020) 45 Cal.App.5th 22. A lease provision imposing 150% holdover rent is not an unenforceable penalty under &sect;&nbsp;1671; &sect;&nbsp;1671 targets "unfair and unreasonable coercion." Analogy support for the arms-length cancellation-rate argument.</p>

<p>5. <b><i>Ramirez v. Charter Communications, Inc.</i></b> (2024) 16 Cal.5th 478. 2024 California Supreme Court: unconscionability is assessed at time of formation (not hindsight), and multiple unconscionable provisions trigger a <i>qualitative</i> severance analysis. Employment-origin but generalizable. Cite defensively if Vintage attacks the AAA clause on unconscionability grounds.</p>

<p><b><i>Grade C &mdash; Adverse; have ready to distinguish</i></b></p>

<p>6. <b><i>Bannister v. Marinidence Opco, LLC</i></b> (2021) 64 Cal.App.5th 541. Employer failed to authenticate e-signature where the pin/Client ID was not employee-specific. Likely Vintage playbook if Erica denies signing. Distinguish: Garcia's DocuSign was tied to her Vintage corporate email; the Certificate of Completion will show unique authentication, IP, and timestamp; 27 months of ratified performance settle attribution independently.</p>

<p>7. <b><i>Honchariw v. FJM Private Mortgage Fund, LLC</i></b> (2022) 83 Cal.App.5th 893. Late fees assessed against full loan principal violated &sect;&nbsp;1671. Distinguish: <i>Honchariw</i> fees were triggered by a single default and imposed on the entire balance (classic disproportionality). The Technijian cancellation rate applies only to hours actually worked at overage, tied to measured usage, and sits at or below the Agreement's own out-of-contract rates.</p>

<p>8. <b><i>Graylee v. Castro</i></b> (2020) 52 Cal.App.5th 1107. Stipulated-judgment LD held to violate &sect;&nbsp;1671(b) for lack of reasonable relationship to anticipated damages. Distinguish: <i>Graylee</i> involved a residential-tenancy stipulated judgment, not a negotiated commercial-services rate tied to contemporaneously measured hours.</p>

<p><b><i>Awareness only</i></b></p>

<p>9. <i>Hohenshelt v. Superior Court</i> (2025) &mdash; CCP &sect;&sect;&nbsp;1281.97/1281.98 fee-payment deadlines; FAA does not preempt, but nonpayment waives only when willful/grossly negligent/fraudulent. Relevant to fee administration once arbitration is under way, not to enforceability.</p>

<p>10. <i>New England Country Foods, LLC v. Vanlaw Food Products</i> (2025) &mdash; &sect;&nbsp;1668 bars contractual limitation-of-liability for willful injury. Only relevant if Vintage pivots to a &sect;&nbsp;1668 theory.</p>

<p><b><i>What is stable (no upgrade needed)</i></b></p>

<p>Course of performance / ratification (&sect;&nbsp;8&ndash;10), &sect;&nbsp;1717 reciprocity (&sect;&nbsp;11), &sect;&nbsp;3287(a) prejudgment interest (&sect;&nbsp;12), and the business-records foundation doctrine (&sect;&nbsp;23) are all settled; no material 2020&ndash;2026 opinion improves on the existing authority. Worth affirmatively stating in the memo that the doctrine is stable post-2020.</p>

'@

$newHtml = $html.Replace($anchor, $newSection + $anchor)
$patchBody = @{ body = @{ contentType = "HTML"; content = $newHtml } } | ConvertTo-Json -Depth 5
Invoke-MgGraphRequest -Method PATCH `
    -Uri "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$messageId" `
    -Body $patchBody `
    -Headers @{ "Content-Type" = "application/json" } | Out-Null
Write-Host "Draft patched with Broader Case-Law Refresh section." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
