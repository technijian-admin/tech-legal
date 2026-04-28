# Create BWH revised-MSA reply DRAFT on the accepted thread (does NOT send)
# Pattern: createReply -> patch body -> loop attach 4 docs -> STOP at draft
# Per Dave's 2026-04-28 acceptance of the Friday 2:18 PM Point-by-Point response

# --- Credentials (M365 Graph app) ---
$m365Keys     = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value

# --- Identifiers ---
$senderUpn     = "RJain@technijian.com"
# Dave's "It looks acceptable Ravi, let's write it up and get it going" (2026-04-28 15:43 UTC)
$daveMessageId = "AAMkAGNlYjM0OTA4LThjMjYtNGQ3My1iNDg1LTQ2MTI5NTg0NzFlOQBGAAAAAAC88IffM67WS4tSyVwwqYmJBwBhk-ls8ubYRazD3tGgncxCAAAAAAENAACgx7VhNWW1QYCgfGa-8kbOAAX6um1xAAA="

# --- Attachments (4 documents) ---
$attachments = @(
    "C:\vscode\tech-legal\tech-legal\clients\BWH\02_MSA\MSA-BWH-Agreement.docx",
    "C:\vscode\tech-legal\tech-legal\clients\BWH\02_MSA\BWH-Schedule-A-Monthly-Services.docx",
    "C:\vscode\tech-legal\tech-legal\clients\BWH\02_MSA\BWH-Schedule-B-Subscriptions.docx",
    "C:\vscode\tech-legal\tech-legal\clients\BWH\02_MSA\BWH-Schedule-C-Rate-Card.docx"
)
foreach ($f in $attachments) {
    if (-not (Test-Path $f)) { Write-Host "MISSING: $f" -ForegroundColor Red; exit 1 }
}

# --- Signature ---
$sig = [System.IO.File]::ReadAllText("C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html")

# --- Body ---
$replyBody = @"
<div style="font-family:Aptos,Calibri,Helvetica,sans-serif;font-size:11pt;color:#1a1a2e;line-height:1.5;">
<p>Dave,</p>

<p>Thanks for confirming this morning. Attached is the revised MSA package incorporating everything we agreed to in our Friday exchange. Four documents: the MSA, Schedule A (Monthly Managed Services), Schedule B (Subscriptions), and Schedule C (Rate Card).</p>

<p><strong>What changed in the MSA</strong></p>
<ul style="margin:0 0 12px 0;padding-left:24px;">
<li><strong>&sect;2.02</strong> &mdash; Removed automatic renewal. Initial Term is 12 months; afterward we continue month-to-month. Either side can end the month-to-month with 60 days written notice and no wind-down fee.</li>
<li><strong>&sect;2.03</strong> &mdash; Wind-down fee formula written out explicitly: <em>75% &times; (12 &minus; N) / 12 &times; Average MRR</em>, where N is months completed of the Initial Term. Reaches zero by Month 12. Average MRR is the rolling 3-month average of fully-billed Monthly Service Invoices for recurring services only. Wind-down fee only applies during the Initial Term.</li>
<li><strong>&sect;2.05(b)</strong> &mdash; Transition assistance starts within 5 business days of the termination date. Good-faith dispute carve-out requires written particularization and an escrow account for the disputed amount.</li>
<li><strong>&sect;3.07</strong> &mdash; 10-business-day cure period for the non-payment trigger only. Insolvency, bankruptcy, termination-with-unpaid-balance, and material adverse change still trigger acceleration immediately.</li>
<li><strong>NEW &sect;12 &mdash; Transition Provisions / Legacy Balance Acknowledgment</strong>
  <ul style="margin:6px 0 0 0;padding-left:22px;">
    <li>Acknowledged Legacy Balance: <strong>1,007.30 hours</strong> per Invoice #28148 footer (4/1/2026), broken out as 573.81 India NH / 290.23 India AH / 143.26 USA NH / 0.00 SA. Locked at signing.</li>
    <li>Resolution path is the cycle paydown via Schedule A &sect;3.3. While the Agreement is in effect, no separate hourly invoicing of the Legacy Balance.</li>
    <li>On termination: the unresolved Legacy Balance is invoiced at $150/hr Rate Card. <strong>Exception:</strong> if Brandywine terminates for cause under &sect;2.04(a) due to Technijian's <em>material uncured</em> Response Time SLA failure as defined in &sect;12.01(d), the Legacy Balance is waived in full. Material uncured failure = Response Time miss on more than 25% of tickets in a billing month, for three consecutive months, with written notice and 30 business days to cure.</li>
  </ul>
</li>
</ul>

<p><strong>What changed in Schedule A</strong></p>
<ul style="margin:0 0 12px 0;padding-left:24px;">
<li><strong>&sect;3.3(e)</strong> &mdash; Cancellation rate is the Rate Card $150/hr always; Contracted Rates do not apply on cancellation under any scenario.</li>
<li><strong>&sect;3.5 (revised)</strong> &mdash; A single measurable SLA: <strong>Response Time within 4 business hours</strong> of Client Portal ticket creation, all severities. Resolution time is <em>not guaranteed</em> &mdash; resolution depends on third-party vendor support, equipment warranty status, and other factors outside our control. Infrastructure uptime stays at 99.9% as commercially reasonable efforts.</li>
<li><strong>NEW &sect;3.6 &mdash; Usage Notifications and Cycle Discipline</strong> &mdash; we will notify you at 50%, 60%, 70%, and 80% of monthly billed hours. At 80% we may decline new non-emergency requests for the rest of the month so the cycle keeps paying down the Legacy Balance. Emergencies always continue. You can override the 80% practice in writing at any time. The deferral notice itself is the SLA Response, and properly-deferred tickets do not count against the &sect;12.01(d) breach calculation.</li>
<li><strong>NEW &sect;3.6(f) &mdash; Escalation Safety Valve</strong> &mdash; if you believe a ticket we deferred should have been treated as an emergency or otherwise should not have been deferred, you escalate in writing within 5 business days, identifying the ticket and reason. We reclassify and respond per the 4-hour SLA. This protects you against a ticket sitting in the deferred queue when it actually needed to be worked.</li>
<li><strong>NEW &sect;3.6(g) &mdash; Emergency Definition</strong> &mdash; precise definition of "Emergency / P1 production-down" so neither of us is arguing about it after the fact: production system used by 5+ people down, email/file shares/critical apps down for 5+ people, active cybersecurity incident, or physical site outage. You classify at submission, we may reclassify on review, you have escalation rights on any reclassification.</li>
</ul>

<p><strong>How the cycle paydown is intended to work &mdash; and what we built in to make sure it actually does</strong></p>

<p>I want to spend a minute on the design here so we're aligned on how the next 12 months should run, because the structural goal of this agreement is for the Legacy Balance to reach zero through normal operations rather than through a balloon payment or a fight at termination.</p>

<p>The cycle paydown only works if your monthly delivered hours stay <em>under</em> the monthly contracted hours. Looking at the last 36 months of delivery, you've been averaging closer to 113 hours/month against a roughly 84-hour monthly allocation. That's 35% over the allocation, which is exactly the dynamic that produced the 1,007-hour legacy balance in the first place. If we don't change anything operationally, the cycle won't shrink the balance &mdash; it will grow it.</p>

<p>The 50/60/70/80% notifications and the 80% cap practice are the mechanism we're using to invert that pattern. Here are the specific scenarios we're trying to avoid over the 12 months:</p>

<ol style="margin:0 0 12px 0;padding-left:24px;">
<li><strong>Silent overrun.</strong> Without notifications, both sides only see the gap at month-end when there's no time to course correct. The 50/60/70 alerts give you visibility well before the cap, so your team can prioritize what's actually important and either defer the rest or override.</li>
<li><strong>Drift back to the historical pattern.</strong> If we just signed without the 80% practice, the same usage curve repeats and we end Month 12 with a higher balance than we started. The 80% point is where we trigger a conversation rather than letting the queue run all the way to 100%+.</li>
<li><strong>End-of-cycle balloon.</strong> If the balance grows during the term, terminating the contract becomes financially uncomfortable for both of us &mdash; you face the $150/hr cancellation rate on a larger balance, and we face a collection situation we don't want. The cap practice is built to prevent that scenario from forming.</li>
<li><strong>Ambiguity on what's an emergency.</strong> The Emergency definition in &sect;3.6(g) and the 5-business-day escalation right in &sect;3.6(f) are there so we can apply queue management without it ever blocking real urgent work. If something truly needs attention, it gets attention, full stop.</li>
</ol>

<p>The override clause in &sect;3.6(d) is yours to use whenever you decide a particular month genuinely needs more hours. Hours worked beyond 80% on your written direction don't get blocked &mdash; they just get tracked, and if the pattern persists for 3+ months, we sit down and talk about an allocation increase or out-of-contract billing rather than letting it accumulate silently.</p>

<p>If anything in the documents reads differently than what we discussed, or if the tone of any of the new language feels off, let me know and I'll turn another revision. Otherwise I'll send the package through eSign with you and me as the signers, parallel routing.</p>

<p>Thank you,<br>Ravi</p>
</div>
$sig
"@

# --- Connect ---
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome
Write-Host "Connected." -ForegroundColor Green

# --- createReply on Dave's accepted message (preserves thread, To, quoted history) ---
Write-Host "Creating reply draft..." -ForegroundColor Cyan
$replyDraft = Invoke-MgGraphRequest -Method POST `
    -Uri "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$daveMessageId/createReply"
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
    -ContentType "application/json" | Out-Null
Write-Host "Body updated." -ForegroundColor Green

# --- Attach 4 documents ---
Write-Host "Attaching 4 documents..." -ForegroundColor Cyan
foreach ($f in $attachments) {
    $bytes = [System.IO.File]::ReadAllBytes($f)
    $b64   = [Convert]::ToBase64String($bytes)
    $name  = [System.IO.Path]::GetFileName($f)

    $attPayload = @{
        "@odata.type" = "#microsoft.graph.fileAttachment"
        name          = $name
        contentType   = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        contentBytes  = $b64
    } | ConvertTo-Json -Depth 4 -Compress

    Invoke-MgGraphRequest -Method POST `
        -Uri "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$draftId/attachments" `
        -Body $attPayload `
        -ContentType "application/json" | Out-Null
    Write-Host "  attached  $name ($([math]::Round($bytes.Length/1KB,1)) KB)" -ForegroundColor Gray
}

# --- DRAFT READY (do NOT send) ---
Disconnect-MgGraph | Out-Null

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Yellow
Write-Host "DRAFT READY in Outlook Drafts (NOT sent)." -ForegroundColor Yellow
Write-Host "Open Outlook -> Drafts -> 'RE: MSA-BWH Redlines - Point-by-Point Response on the Open Sections'" -ForegroundColor Yellow
Write-Host "Review, then click Send." -ForegroundColor Yellow
Write-Host "Draft Id: $draftId" -ForegroundColor Gray
Write-Host "=========================================================" -ForegroundColor Yellow
