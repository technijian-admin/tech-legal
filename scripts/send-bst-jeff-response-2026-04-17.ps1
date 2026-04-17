# Send BST Jeff Klein 2026-04-17 Response via Microsoft Graph
# DEFAULT: creates draft only (review in Outlook before sending)
#
# Usage:
#   .\send-bst-jeff-response-2026-04-17.ps1         # draft only (DEFAULT)
#   .\send-bst-jeff-response-2026-04-17.ps1 -Send   # send immediately

param([switch]$Send)

$ErrorActionPreference = "Stop"

# --- Recipients ---
$to = @(
    @{ Address = "jklein@bostongroupwaste.com"; Name = "Jeff Klein" },
    @{ Address = "lcronlaw@gmail.com";          Name = "Lawrence M. Cron, Esq." }
)
$cc = @(
    @{ Address = "es@callahan-law.com";         Name = "Edward Susolik, Esq." },
    @{ Address = "RMohamed@Technijian.com";     Name = "Raja Mohamed" }
)

$senderUpn = "RJain@technijian.com"
$subject   = "RE: Boston Group - Time-Sensitive Closeout Items (Reply Requested)"

$sigPath        = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"
$attachFolder   = "C:\vscode\tech-legal\tech-legal\terminated-clients\BST\send-packages\2026-04-17"

# --- Credentials ---
Write-Host "Reading M365 Graph credentials..." -ForegroundColor Cyan
$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $m365ClientId -or -not $m365TenantId -or -not $m365Secret) {
    Write-Error "Failed to parse M365 credentials"; exit 1
}

# --- Signature ---
$sig = ""
if (Test-Path $sigPath) { $sig = Get-Content $sigPath -Raw }

# --- Build HTML body (backtick-escape every literal dollar sign) ---
$fontStack = "Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif"
$htmlBody = @"
<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>
<body dir="ltr">
<div style="font-family:$fontStack;font-size:12pt;color:rgb(0,0,0)">

<p>Jeff,</p>

<p>Thank you for the reply and for identifying counsel &mdash; welcome, Mr.&nbsp;Cron. Technijian's counsel <strong>Edward Susolik of Callahan &amp; Blaine</strong> is also on copy, and we would ask that substantive discussion of the cancellation reconciliation and the release terms proceed counsel-to-counsel from here.</p>

<p><strong>We want to offer a counsel-to-counsel call before April&nbsp;30,&nbsp;2026</strong> so that both sides have a shared understanding of the contract mechanics, the cancellation-fee methodology, the outstanding invoices, and the terms of the standing settlement offer before the deadline arrives. Our strong preference is to resolve this without surprises. Ed is available this week or next &mdash; <strong>please have Mr.&nbsp;Cron propose a few times and we will make one of them work.</strong> Mr.&nbsp;Cron is welcome to reach out to Ed directly at <a href="mailto:es@callahan-law.com">es@callahan-law.com</a>.</p>

<p>A few points in reply so the record is complete and nothing is left ambiguous before April&nbsp;30:</p>

<p><strong>1. April monthly invoices and late fees.</strong> Thank you for confirming payment of the April&nbsp;2026 monthly and recurring invoices (#27949 and #28112). Payment terms under the Agreement are <strong>Net-30, with a 10% late fee assessed on any balance unpaid after the 10th of the month following the invoice date</strong> (Other Terms, Paragraph&nbsp;3). For clarity, please understand:</p>

<ul>
  <li>Technijian has previously, as a business courtesy, <strong>waived late fees for Boston Group on two prior occasions</strong>. Those were discretionary, non-precedential accommodations.</li>
  <li><strong>No further waivers will be granted.</strong> Any invoice &mdash; the April monthly/recurring invoices (#27949 and #28112), the cancellation invoice (#28064), and any other open balance &mdash; that is not paid in full <strong>on or before April&nbsp;30,&nbsp;2026</strong> will accrue the contractual 10% late fee and continue to accrue per the Agreement until paid.</li>
  <li>A firm remittance date or written payment arrangement from AP would avoid this result; &ldquo;as soon as I can&rdquo; is not a commitment we can rely on to stop the late-fee clock.</li>
</ul>

<p><strong>2. Cancellation reconciliation &mdash; &ldquo;no notice of unbilled hours.&rdquo;</strong> With respect, the record does not support that characterization, and I want to put the specifics in writing so your counsel has them in front of him:</p>

<ul>
  <li><strong>Every weekly and monthly invoice included a separate time-entries spreadsheet.</strong> Throughout the 36-month term of the Agreement, every weekly and monthly invoice email from <code>billing@technijian.com</code> &mdash; addressed to you personally (<code>jklein@bostongroupwaste.com</code>) and/or to Boston Group's Accounting inbox (<code>Accounting@bostongroupwaste.com</code>) &mdash; carried <strong>two attachments</strong>: the invoice PDF and a separate &ldquo;Weekly Time Entries&rdquo; / &ldquo;Monthly Time Entries&rdquo; Excel spreadsheet. That spreadsheet is a row-per-ticket export with seventeen columns per ticket, including: ticket title, requestor, start and end timestamps, Normal hours, After-Hours, technician (Resource), <strong>POD (CHD-TS1 offshore vs.&nbsp;IRV-TS1 onshore)</strong>, role type, work type, and a free-text work note. In other words, the offshore/onshore allocation for every ticket was disclosed on every invoice, monthly and weekly, for the life of the Agreement. Representative monthly time-entry spreadsheets for February, March, and April&nbsp;2026 are attached, together with a weekly sample.</li>
  <li><strong>The April&nbsp;2026 monthly invoice (#28143) expressly showed unpaid hours.</strong> The most recent monthly invoice issued to Boston Group &mdash; <strong>Invoice&nbsp;#28143, dated April&nbsp;1,&nbsp;2026, sent April&nbsp;2,&nbsp;2026 to both <code>jklein@bostongroupwaste.com</code> and <code>Accounting@bostongroupwaste.com</code></strong> &mdash; carries a &ldquo;Support History&rdquo; table on its face that displays, for the current under-contract cycle alone, <strong>286.39 unpaid India-Tech Normal hours</strong> and <strong>35.29 unpaid India-Tech After-Hours hours</strong>, together with the reconciling Billed and Actual figures. The accompanying footnote expressly states: <em>&ldquo;Unpaid hours represent the difference between actual hours worked and hours billed during the current under-contract period. Upon termination of this Agreement, all unpaid hours documented through ticketing shall be invoiced at the applicable hourly rate per the Rate Card and are due before the agreement is terminated.&rdquo;</em> That invoice was transmitted to Boston Group <strong>two weeks before</strong> your April&nbsp;16 email stating that Boston Group &ldquo;cannot find any reference to unbilled hours in the invoices sent to us monthly.&rdquo; The invoice is attached for the record.</li>
  <li><strong>Dispute window.</strong> Each weekly and monthly transmission carried a dispute window (30-day weekly; 60-day monthly per Section&nbsp;3.01 of the Agreement's Terms &amp; Conditions). Technijian's records show <strong>no timely objection of record</strong> by Boston Group across the 36-month term &mdash; not to any reported ticket, not to any POD allocation, and not to any reported hour. If your counsel believes an objection was filed and not recorded, please identify the date and we will locate it.</li>
</ul>

<p>The hours figure on cancellation invoice&nbsp;#28064 is derived from the same ticketed-time data Boston Group received weekly and on which no objection was filed. If your counsel would like the underlying reconciliation spreadsheet or a pull of the weekly notices for a specific month, please let us know.</p>

<p><strong>3. Settlement offer &mdash; still open; deadline unchanged.</strong> The <strong>`$15,045.00 good-faith settlement alternative</strong> first offered on March&nbsp;23,&nbsp;2026 remains open, and we would be glad to close this on that number. It is expressly conditioned on <strong>written acceptance no later than April&nbsp;30,&nbsp;2026, close of business</strong>. If written acceptance is not received by that date, the offer will expire by its terms and Technijian's position will revert to the <strong>`$126,442.50</strong> contract-basis figure reflected on invoice&nbsp;#28064 (attached). This is separate from the April monthly invoices referenced in Point&nbsp;1 above.</p>

<p><strong>4. Microsoft 365 global admin.</strong> Please note that <strong>Technijian no longer has administrative access to Boston Group's Microsoft 365 tenant.</strong> As part of Tech Heights' takeover of the environment, Technijian's Global Admin access and any Microsoft partner/GDAP relationship to the tenant have already been removed &mdash; along with our access to the on-prem domain controllers and the rest of the environment. Tech Heights currently holds tenant administrative control. The appropriate way for Boston Group to obtain Global Administrator credentials is to request them directly from Tech Heights. If there is any residual Technijian partner relationship still showing on the tenant that Boston Group would like formally severed, please have your counsel or Tech Heights identify it and Raja Mohamed (copied) will process the removal on written request.</p>

<p><strong>5. Active support tickets &mdash; respectful correction for the record.</strong> We need to be clear that Technijian has <strong>not chosen to stop supporting Boston Group</strong>. The characterization in your email is not accurate, and I want the record to reflect what has actually occurred:</p>

<ul>
  <li>Beginning on or about March&nbsp;31&nbsp;&ndash;&nbsp;April&nbsp;1,&nbsp;2026, <strong>Tech Heights changed the administrative passwords on Boston Group's environment</strong> &mdash; ESXi host, Active Directory, and firewall/default gateway &mdash; <strong>and did not share the new credentials with Technijian</strong>.</li>
  <li><strong>Tech Heights also removed Technijian's monitoring and management agents</strong> from Boston Group's endpoints and servers.</li>
  <li>Without credentials on the current firewall, the current domain controllers, or the current hypervisor, and without our management tooling in place, <strong>Technijian is technically unable to diagnose or remediate VPN, access, or connectivity issues &mdash; not unwilling.</strong></li>
  <li>Technijian has <strong>repeatedly offered &mdash; in writing, across multiple emails this month &mdash; to continue supporting Boston Group through April&nbsp;30,&nbsp;2026</strong>, including by <strong>coming onsite</strong> to work the environment in person if that is what Boston Group prefers. Attached for reference are the April&nbsp;3, April&nbsp;9, April&nbsp;14, and April&nbsp;15 emails on this same topic. That offer stands today. If Boston Group directs Tech Heights to restore Technijian's credentials and reinstate our agents &mdash; or to arrange onsite access &mdash; we will resume normal support response immediately.</li>
</ul>

<p>As set out in our April&nbsp;15 email, Technijian remains contractually willing to provide support through April&nbsp;30,&nbsp;2026 under Section&nbsp;4.05. All rights are expressly reserved regarding the unauthorized credential changes and tool removals by Tech Heights.</p>

<p>Nothing in this email waives or limits any claim Technijian may have, and all rights are expressly reserved.</p>

<p>Thank you,</p>

</div>
$sig
</body>
</html>
"@

# --- Connect to Graph ---
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome
Write-Host "Connected." -ForegroundColor Green

# --- Build attachments ---
Write-Host "`nStaging attachments from $attachFolder..." -ForegroundColor Cyan
$attachments = @()
$files = Get-ChildItem -Path $attachFolder -File | Sort-Object Name
foreach ($f in $files) {
    $bytes   = [System.IO.File]::ReadAllBytes($f.FullName)
    $b64     = [Convert]::ToBase64String($bytes)
    $ctype   = switch -Wildcard ($f.Name) {
        "*.pdf"  { "application/pdf"; break }
        "*.xlsx" { "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"; break }
        default  { "application/octet-stream" }
    }
    $attachments += @{
        "@odata.type" = "#microsoft.graph.fileAttachment"
        name          = $f.Name
        contentType   = $ctype
        contentBytes  = $b64
    }
    Write-Host ("  [+] {0}  ({1:N0} bytes)" -f $f.Name, $f.Length) -ForegroundColor Gray
}
$totalBytes = ($files | Measure-Object -Property Length -Sum).Sum
Write-Host ("Total attachment payload: {0:N0} bytes ({1:N2} MB)" -f $totalBytes, ($totalBytes/1MB)) -ForegroundColor Cyan

# --- Create draft with attachments ---
Write-Host "`nCreating draft message..." -ForegroundColor Cyan
$draftParams = @{
    Subject = $subject
    Body = @{
        ContentType = "HTML"
        Content     = $htmlBody
    }
    ToRecipients = @($to | ForEach-Object { @{ EmailAddress = @{ Address = $_.Address; Name = $_.Name } } })
    CcRecipients = @($cc | ForEach-Object { @{ EmailAddress = @{ Address = $_.Address; Name = $_.Name } } })
    Attachments  = $attachments
}
$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter $draftParams
Write-Host "Draft created. MessageId = $($draft.Id)" -ForegroundColor Green

# --- Either send or leave as draft ---
if ($Send) {
    Write-Host "`nSending..." -ForegroundColor Cyan
    Send-MgUserMessage -UserId $senderUpn -MessageId $draft.Id
    Write-Host "SENT." -ForegroundColor Green
    Write-Host "  To:  $($to.Address -join ', ')" -ForegroundColor Gray
    Write-Host "  Cc:  $($cc.Address -join ', ')" -ForegroundColor Gray
} else {
    Write-Host "`nDRAFT saved to Outlook Drafts for $senderUpn." -ForegroundColor Yellow
    Write-Host "  To:  $($to.Address -join ', ')" -ForegroundColor Gray
    Write-Host "  Cc:  $($cc.Address -join ', ')" -ForegroundColor Gray
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "  1. Open Outlook -> Drafts -> 'RE: Boston Group - Time-Sensitive Closeout Items'" -ForegroundColor Yellow
    Write-Host "  2. Review the rendered body and verify all 11 attachments are present" -ForegroundColor Yellow
    Write-Host "  3. Click Send, OR re-run this script with -Send to send automatically" -ForegroundColor Yellow
}
Write-Host "`nSubject: $subject" -ForegroundColor Gray

Disconnect-MgGraph | Out-Null
