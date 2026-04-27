# Email Frank Dunn (Callahan & Blaine, handling) requesting direct counsel-to-counsel
# contact with Lawrence Cron (BST opposing counsel) before the 2026-04-30 settlement
# deadline. Ed Susolik cc'd as supervising partner.
#
# Pattern: draft via Graph -> render preview to file -> send.
# Body uses single-quoted here-string (no $ escaping needed for dollar amounts).
# Signature loaded from canonical ravi-signature.html and concatenated.

$ErrorActionPreference = 'Stop'

# --- Auth ---
$keysFile = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md"
$m365Keys = Get-Content $keysFile -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(.+)').Groups[1].Value.Trim()
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $cred -NoWelcome | Out-Null
Write-Host "M365 auth OK." -ForegroundColor Green

# --- Signature ---
$sigPath = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"
$raviSignature = [System.IO.File]::ReadAllText($sigPath)

# --- Subject + body ---
$subject = "BST (Boston Group) -- please contact opposing counsel Lawrence Cron before Thursday 4/30 deadline"

# Single-quoted here-string: NO variable expansion, dollar signs are literal.
# Closing '@ MUST be at column 0 (no leading whitespace) on its own line.
$bodyCore = @'
<div style="font-family:Aptos,Calibri,Helvetica,sans-serif; font-size:12pt; color:#1A1A2E;">

<p>Hi Frank,</p>

<p>The BST (Boston Group) settlement deadline is Thursday April 30 COB &mdash; three business days. I just left a voicemail for Jeff Klein (BST primary, 310-283-6937) asking him to confirm written acceptance of the $15,045 settlement by Wednesday COB. Email-only follow-ups have not produced a written acceptance.</p>

<p>Asking you to make direct counsel-to-counsel contact this week with BST&rsquo;s attorney:</p>

<p style="margin-left:24px;">
<strong>Lawrence M. Cron, Esq.</strong><br>
Solo practitioner, 360 E 1st St #313, Tustin CA 92780<br>
Email: <a href="mailto:lcronlaw@gmail.com">lcronlaw@gmail.com</a><br>
Phone: 714-803-6247<br>
CA Bar #144630 (admitted 1989, clean record)
</p>

<p><strong>Background on Cron.</strong> Solo OC generalist, no specialty in MSP/IT contracts or AAA commercial arbitration, no firm website, no published appellate decisions. He surfaced April 16 when Jeff cc&rsquo;d him on a reply, but has not directly engaged me at any point in the eleven days since. Based on the profile, likely a friends-and-family or modest-fee referral to BST.</p>

<p><strong>What I&rsquo;d like from the contact:</strong></p>

<ol>
<li>Confirm Cron is in fact engaged on the file and tracking the April 30 deadline.</li>
<li>Get a yes/no read on whether Jeff is bringing the $15,045 settlement to acceptance by Wednesday COB.</li>
<li>If yes, line up mutual release language for execution before Friday.</li>
<li>If no, transition cleanly into formal demand posture &mdash; $126,442.50 (cancellation invoice #28064) plus the 10% late fee ($12,644.25) attaching May 1, plus the two May monthly invoices ($552 + $5,694.60).</li>
</ol>

<p><strong>Settlement math anchors for the call:</strong></p>

<table cellspacing="0" cellpadding="6" border="0" style="border-collapse:collapse; font-family:Aptos,Calibri,Helvetica,sans-serif; font-size:11pt; max-width:600px;">
<tr><td style="border-bottom:1px solid #DEE2E6; padding:6px 12px;">$15,045.00</td><td style="border-bottom:1px solid #DEE2E6; padding:6px 12px;">Life-of-contract net overage settlement (open through 4/30 COB)</td></tr>
<tr><td style="border-bottom:1px solid #DEE2E6; padding:6px 12px;">$126,442.50</td><td style="border-bottom:1px solid #DEE2E6; padding:6px 12px;">Contract-basis cancellation invoice (#28064)</td></tr>
<tr><td style="border-bottom:1px solid #DEE2E6; padding:6px 12px;">$12,644.25</td><td style="border-bottom:1px solid #DEE2E6; padding:6px 12px;">10% late fee accruing on #28064 if unpaid by 4/30</td></tr>
<tr><td style="padding:6px 12px;"><strong>$138,886.45</strong></td><td style="padding:6px 12px;"><strong>Total AR exposure as of 5/1 if no settlement</strong></td></tr>
</table>

<p style="margin-top:16px;"><strong>Two open issues to flag before the call:</strong></p>

<ol>
<li><strong>Cycle-3 weakness.</strong> Termination-cycle-only overage runs $0 because actual hours ran under baseline. Our posture is the life-of-contract Method A read ($126,442.50). Cron will likely push Method D (cycle-only). Worth being on the same page with Ed before the call.</li>
<li><strong>Tech Heights / Leggett.</strong> Separate from BST settlement. Documented unauthorized access events &mdash; CrowdStrike blocked an unauthorized Domain Admins elevation attempt on April 2-3 (command captured: <code>net group "Domain Admins" thadmin /add /domain</code>). Reservation-of-rights language has been in every BST email, but no separate demand to Tech Heights yet. Want your read on whether the Tech Heights letter goes out this week regardless of how BST resolves.</li>
</ol>

<p>Full BST file is at <code>c:\vscode\tech-legal\tech-legal\terminated-clients\BST\</code> &mdash; settlement position memorandum, damages analysis (5 methodologies, with the unreconciled 88.67-hour delta noted), case law research memorandum, and the complete 109-message email record. Ed is cc&rsquo;d; he has been on every BST email since March 19.</p>

<p>Happy to jump on a call if helpful &mdash; use the booking link in my signature.</p>

<p>Thank you,</p>

<p>Ravi</p>

</div>

'@

$htmlBody = $bodyCore + $raviSignature

# --- Preflight: render preview to disk and grep for known footguns ---
$previewPath = "C:\vscode\tech-legal\tech-legal\scripts\bst-frank-contact-cron-preview.html"
[System.IO.File]::WriteAllText($previewPath, $htmlBody, [System.Text.UTF8Encoding]::new($false))
Write-Host "Preview written to: $previewPath" -ForegroundColor Cyan

# Grep for stripped-$ artifacts (e.g., ',045' would mean $ got eaten before the digit)
if ($htmlBody -match '[\s>](,\d{3})') {
    Write-Host "ABORT: Stripped-`$ pattern detected near '$($matches[1])'. Email NOT sent." -ForegroundColor Red
    exit 1
}
# Grep for cp1252 mojibake artifacts (codepoints 0xC2 / 0xC3 commonly appear in mojibake)
$bodyChars = $htmlBody.ToCharArray() | ForEach-Object { [int]$_ }
if ($bodyChars -contains 0xC2 -or $bodyChars -contains 0xC3) {
    Write-Host "ABORT: cp1252 mojibake codepoint detected. Email NOT sent." -ForegroundColor Red
    exit 1
}
# Confirm key dollar amounts present
$mustHave = @('$15,045', '$126,442.50', '$12,644.25', '$138,886.45')
foreach ($needle in $mustHave) {
    if ($htmlBody -notmatch [regex]::Escape($needle)) {
        Write-Host "ABORT: Required dollar figure '$needle' missing from body. Email NOT sent." -ForegroundColor Red
        exit 1
    }
}
Write-Host "Preflight checks passed (no stripped-$, no mojibake, all dollar figures present)." -ForegroundColor Green

# --- Send ---
$params = @{
    Message = @{
        Subject = $subject
        Body = @{ ContentType = "HTML"; Content = $htmlBody }
        ToRecipients = @(
            @{ EmailAddress = @{ Address = "fdunn@callahan-law.com"; Name = "Frank Dunn" } }
        )
        CcRecipients = @(
            @{ EmailAddress = @{ Address = "es@callahan-law.com"; Name = "Edward Susolik" } }
        )
    }
    SaveToSentItems = $true
}

Send-MgUserMail -UserId "RJain@technijian.com" -BodyParameter $params
Write-Host ""
Write-Host "===============================================" -ForegroundColor Green
Write-Host " EMAIL SENT" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host "TO:      fdunn@callahan-law.com (Frank Dunn)"
Write-Host "CC:      es@callahan-law.com (Edward Susolik)"
Write-Host "SUBJ:    $subject"
Write-Host "PREVIEW: $previewPath"
