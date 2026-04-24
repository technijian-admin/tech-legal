# Draft BWH point-by-point response to Dave's 4/24 19:02 email on MSA redlines
# This is the SECOND email (first was hours-accounting with xlsx attached)
# Addresses §2.05(b), §2.03, §2.02, §3.07, §3.3(e), §9.02 in order
# Saves MessageId to bwh-legal-response-draft-id.txt
#
# Usage: powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\draft-bwh-legal-point-by-point-response.ps1

$ErrorActionPreference = "Stop"

$toEmail    = "dave@brandywine-homes.com"
$toName     = "Dave Barisic"
$senderUpn  = "RJain@technijian.com"
$subject    = "Re: MSA-BWH Redlines - Point-by-Point Response on the Open Sections"
$idFile     = "C:\vscode\tech-legal\tech-legal\scripts\bwh-legal-response-draft-id.txt"
$sigPath    = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"

# --- Credentials ---
Write-Host "Reading M365 Graph credentials..." -ForegroundColor Cyan
$m365Keys     = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $m365ClientId -or -not $m365TenantId -or -not $m365Secret) {
    Write-Error "Failed to parse M365 credentials"; exit 1
}

# --- Signature ---
$sig = ""
if (Test-Path $sigPath) { $sig = Get-Content $sigPath -Raw }

# --- HTML body ---
# Outlook-safe: solid-color backgrounds, no linear-gradient. Backtick-escape every literal dollar sign.
$fontStack = "Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif"
$htmlBody = @"
<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>
<body dir="ltr">
<div style="font-family:$fontStack;font-size:11pt;color:rgb(0,0,0)">

<p>Dave,</p>

<p>Following my earlier note with the full ticket detail, this is the point-by-point on the six sections you addressed. I&rsquo;ve tried to be clear where we&rsquo;re aligned, where we can accept your ask outright, and where I&rsquo;m proposing a small refinement to protect both sides. Numbering follows your email.</p>

<h3 style="color:rgb(31,78,120);margin-bottom:6px">&sect;2.05(b) &mdash; Transition Assistance (Accepted)</h3>

<p>Agreed. The written particularization on the good-faith dispute carve-out is in. No further change needed here.</p>

<h3 style="color:rgb(31,78,120);margin-bottom:6px">&sect;2.03 &mdash; Wind-Down Fee (Accepted with one clarification)</h3>

<p>Agreed on 75% + 1/12th monthly pro-ration starting Month 1, calculated on actual average MRR. Confirmed in writing here:</p>

<ul>
  <li><strong>Pro-ration formula:</strong> Wind-down fee = 75% &times; (12 &minus; N) / 12 &times; Average MRR, where N = the number of completed months of the then-current Term at the time termination notice is given. By the end of Month 12, N = 12 and the fee is <strong>`$0</strong>.</li>
  <li><strong>MRR basis:</strong> &ldquo;Average MRR&rdquo; means the average of the most recent three (3) fully-billed monthly invoices for recurring services only &mdash; excludes one-time items, SOW project work, and ad-hoc hourly billings. This is actual historical MRR, not a projection.</li>
  <li><strong>Virtual Staff treatment:</strong> Contracted Virtual Staff hours (India Tech, USA Tech, Systems Architect) are part of the recurring MRR base since they&rsquo;re billed monthly at contracted rates.</li>
</ul>

<p>I&rsquo;ll paper this into &sect;2.03 exactly as described above.</p>

<h3 style="color:rgb(31,78,120);margin-bottom:6px">&sect;2.02 &mdash; 60-Day Notice and 90-Day Renewal Reminder (Accepted)</h3>

<p>Agreed. I&rsquo;ll revise &sect;2.02 to require Technijian to send the renewal reminder <strong>no later than 90 days before the renewal date</strong>, giving you at least 30 days between the reminder and your notice deadline. I&rsquo;ll add a small teeth provision on our side: if Technijian fails to send the reminder at least 90 days in advance, your notice deadline is automatically extended by the number of days we were late. That protects you in the event of an administrative miss on our end and makes the 90-day obligation meaningful rather than advisory.</p>

<h3 style="color:rgb(31,78,120);margin-bottom:6px">&sect;3.07 &mdash; Acceleration Clause (Accept cure period, but not for all triggers)</h3>

<p>I hear you on not wanting an administrative dispute to trigger acceleration of the whole balance. I can accept a 10-business-day cure period, but only for the trigger where it actually makes sense. Here&rsquo;s the split I&rsquo;m proposing:</p>

<ul>
  <li><strong>Non-payment triggers (45+ days past due):</strong> <em>10 business days</em> written notice and opportunity to cure. If the amount is in good-faith dispute with written particularization under &sect;2.05(b), the disputed portion does not count toward the non-payment threshold. Acceleration does not trigger if cure or documented dispute is received within the cure window.</li>
  <li><strong>Insolvency, bankruptcy, receivership, assignment for benefit of creditors:</strong> <em>No cure period</em>. These are objective events, not curable, and any cure period would defeat the purpose of the clause (protecting Technijian against a counterparty that&rsquo;s actively becoming uncollectible).</li>
  <li><strong>Termination-with-unpaid-balance:</strong> <em>No cure period</em>, because the termination itself is the trigger event and the amount is already crystallized.</li>
</ul>

<p>This gives you the real-world protection you&rsquo;re asking for (you can&rsquo;t get the full balance accelerated over a good-faith invoice dispute) without neutralizing the clause in the scenarios where it&rsquo;s doing its actual job. If this split works for you I&rsquo;ll paper it.</p>

<h3 style="color:rgb(31,78,120);margin-bottom:6px">&sect;3.3(e) &mdash; Cancellation Rate Split (Agreed in principle)</h3>

<p>Your framing works for us. The cleanest way to paper this:</p>

<ul>
  <li>&sect;3.3(e) applies Standard Rate on cancellation <strong>only to hours accrued after the new MSA Effective Date</strong> (May 1, 2026).</li>
  <li>The legacy unpaid balance (see next section) is governed exclusively by the &sect;9.02 mechanic &mdash; not by &sect;3.3(e).</li>
  <li>If the new cycle is terminated early, the post-Effective-Date portion of the balance is subject to &sect;3.3(e), and the pre-Effective-Date legacy portion is subject to &sect;9.02&rsquo;s termination logic. The two never stack.</li>
</ul>

<p>This solves your compounding-exposure concern and keeps the incentive structure clean on both sides.</p>

<h3 style="color:rgb(31,78,120);margin-bottom:6px">&sect;9.02 &mdash; Release of Prior Obligations (Option 2 + your two additions, with precise language)</h3>

<p>I&rsquo;m accepting your framework. Here&rsquo;s how I propose it reads when papered:</p>

<p><strong>(a) Documented acknowledged balance.</strong> The legacy balance is acknowledged at <strong>1,007.30 hours</strong>, per Invoice #28148 footer dated April 1, 2026, broken down as: 573.81 India Tech Normal, 290.23 India Tech After Hours, 143.26 USA Tech Normal, 0.00 Systems Architect. The ticket-by-ticket source documentation is the xlsx I sent you this morning (BWH-Hours-Accounting-Life-of-Contract.xlsx). The figure will be trued up once to the April 1 &ndash; April 30 delivery/billing cycle captured on the May 1 monthly invoice, and then locked at MSA signing.</p>

<p><strong>(b) Resolution path.</strong> The acknowledged balance will be absorbed through the new Schedule A 12-month cycle under the under-utilization target. No separate hourly invoicing for these hours will occur unless &sect;9.02(c) triggers.</p>

<p><strong>(c) Termination treatment.</strong></p>
<ul>
  <li><strong>If BWH terminates without cause</strong> (convenience, non-renewal outside the notice window): the remaining unabsorbed portion of the legacy balance is invoiced at the Rate Card Standard Rate (`$150/hr) per &sect;2.05(a) mechanics.</li>
  <li><strong>If Technijian terminates for cause</strong> (BWH default): same as above, Standard Rate on the remaining balance.</li>
  <li><strong>If BWH terminates for cause due to a material, uncured SLA failure by Technijian</strong>: the remaining unabsorbed portion of the legacy balance is <strong>waived in full</strong>, with no Standard Rate invoicing.</li>
</ul>

<p>&ldquo;Material, uncured SLA failure&rdquo; needs a tight definition so neither of us has to argue about it later. I&rsquo;m proposing this three-part test:</p>

<ul>
  <li><strong>Material:</strong> a breach of a measurable SLA commitment in Schedule A (response time, resolution time, or uptime) by more than the defined threshold for <strong>three (3) consecutive billing months</strong>. Not a single missed ticket; a sustained pattern.</li>
  <li><strong>Written notice with particularization:</strong> BWH delivers written notice identifying the specific SLA(s) breached, the specific measurement period(s), and the evidence of breach.</li>
  <li><strong>30-business-day cure:</strong> Technijian has 30 business days from receipt of notice to cure. If cured within that window, termination rights under this subsection do not vest. If not cured, BWH may terminate for cause and the legacy balance is waived.</li>
</ul>

<p>This gives you a real waiver in the scenario where Technijian genuinely fails to perform, and gives us a reasonable opportunity to fix problems before you get that remedy. It also prevents a pretext termination from wiping the balance. Symmetry.</p>

<h3 style="color:rgb(31,78,120);margin-bottom:6px">Next step</h3>

<p>If the above lands for you, I&rsquo;ll produce a single clean counter-redlined DOCX reflecting everything we&rsquo;ve agreed to &mdash; &sect;2.02, &sect;2.03, &sect;2.05(b), &sect;3.07, &sect;3.3(e), &sect;9.02 &mdash; and send it over for your sign-off. A 30-minute call this week would probably be faster than another round of email, if you have time. I can be flexible on when.</p>

<p>Thank you,</p>

</div>
$sig
</body>
</html>
"@

# --- Fail-fast checks ---
# Check for stripped currency: patterns like " 150/hr" or " 0</strong>" without preceding $ (means the backtick-escape was missed in source)
if ($htmlBody -match '(?<![\$\d])(\s)(\d+(\.\d+)?)(/hr|/hour|\.00|,\d{3})' ) {
    $match = $matches[0]
    Write-Warning "WARN: Possible stripped currency found: '$match'. Verify the source has backtick-escape on that literal."
}
# Unexpanded placeholders
if ($htmlBody -match '\{\{') {
    Write-Error "FAIL: Placeholder '{{...}}' found in rendered HTML."; exit 1
}
# Confirm expected currency references are present
foreach ($expect in '$0', '$150/hr') {
    if ($htmlBody -notlike "*$expect*") {
        Write-Error "FAIL: Expected currency literal '$expect' not found in rendered HTML. Backtick-escape in source may be missing."; exit 1
    }
}

# --- Connect ---
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome
Write-Host "Connected." -ForegroundColor Green

# --- Create draft ---
Write-Host "Creating draft..." -ForegroundColor Cyan
$draftParams = @{
    Subject = $subject
    Body    = @{ ContentType = "HTML"; Content = $htmlBody }
    ToRecipients = @(
        @{ EmailAddress = @{ Address = $toEmail; Name = $toName } }
    )
}
$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter $draftParams
$draftId = $draft.Id

Set-Content -Path $idFile -Value $draftId -Encoding UTF8
Write-Host "Draft ready in Outlook Drafts. MessageId saved to: $idFile" -ForegroundColor Yellow
Write-Host "Subject : $subject" -ForegroundColor Gray
Write-Host "To      : $toEmail" -ForegroundColor Gray
Write-Host "No attachment (pure legal response)" -ForegroundColor Gray

Disconnect-MgGraph | Out-Null
Write-Host "`nPROOFREAD the draft in Outlook before sending." -ForegroundColor Yellow
