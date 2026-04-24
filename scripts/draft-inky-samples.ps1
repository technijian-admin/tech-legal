# Create two sample Inky-campaign drafts in Ravi's Outlook Drafts folder
# for preview before blast. No attachment yet (one-pager PDF pending).
# - Sample 1: BWH (existing customer, ASA tier, 83 users) — uses email-existing-customers template
# - Sample 2: AFFG (prospect) — uses email-prospects template

$senderUpn = "RJain@technijian.com"

# ---- Auth ----
$m365Keys     = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome

# ---- Signature ----
$signature = [System.IO.File]::ReadAllText("c:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html")

# ---- Shared body style ----
$fontStack = 'Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif'
$bodyStyle = "font-family:$fontStack; font-size:12pt; color:#1A1A2E; line-height:1.5;"

# ================================================================
# Sample 1: BWH (existing customer)
# ================================================================
$bwhFirstName = "Dave"
$bwhClientName = "Brandywine Homes"
$bwhUserCount = 83
$bwhSubject = "Important: Your Technijian My AntiSpam Upgrade - Monday, May 5"
$bwhTo = "dave@brandywine-homes.com"

$bwhBody = @"
<html><body style="$bodyStyle">
<p>Hi $bwhFirstName,</p>

<p>I want to give you a heads-up about a change to $bwhClientName's Technijian My AntiSpam service effective Monday, May 5, 2026, and more importantly, explain why this is actually great news for your business.</p>

<p><strong>The Background</strong></p>

<p>Technijian My AntiSpam is powered by INKY, an industry-leading email security platform. When we originally set up your account, INKY offered &agrave; la carte pricing at `$4.25 per user per month. Last year, Kaseya acquired INKY and consolidated their pricing &mdash; your account is being moved to the full-suite tier at `$4.75 per user per month.</p>

<p><strong>The Good News</strong></p>

<p>That `$0.50 difference unlocks the complete INKY platform &mdash; every feature, fully active on your $bwhUserCount users. Comparable enterprise-tier email security platforms run `$10+ per user per month. You're getting all of it for `$4.75.</p>

<p><strong>Everything Now Included in Your Plan</strong></p>

<ul>
<li><strong>Inbound Mail Protection</strong> &mdash; AI reads every incoming email to detect phishing, scams, and malicious content before it reaches your team, with warning banners that explain exactly why something was flagged.</li>
<li><strong>Outbound Mail Protection</strong> &mdash; Scans emails your employees send to prevent data leaks and ensure nothing sensitive leaves your organization undetected.</li>
<li><strong>Internal Mail Protection</strong> &mdash; Monitors email sent between your own staff, protecting against threats from compromised internal accounts.</li>
<li><strong>Email Encryption</strong> &mdash; Automatically encrypts sensitive outbound messages so only the intended recipient can read them.</li>
<li><strong>Advanced Attachment Analysis</strong> &mdash; Deep-scans every attachment for malware and ransomware before it ever reaches an inbox.</li>
<li><strong>Graymail Protection</strong> &mdash; Filters out newsletters and bulk mail clutter so real threats don't get buried in the noise.</li>
<li><strong>Email Signatures</strong> &mdash; Enforces consistent, professional email signatures across your entire organization.</li>
<li><strong>DMARC Monitoring</strong> &mdash; Monitors your domain's email authentication to prevent cybercriminals from impersonating your company in emails to others.</li>
</ul>

<p><strong>The Bottom Line</strong></p>

<p>Starting Monday, May 5, your price is going up by `$0.50 per user, and in exchange you're receiving a full enterprise-grade email security suite that would otherwise cost more than double what you're paying. We believe this is one of the best values in cybersecurity right now, and we're proud to be able to pass it along to you.</p>

<p>No action is required on your part &mdash; the new pricing and expanded feature set will take effect automatically on Monday, May 5. I've attached a one-page overview of the full Technijian My AntiSpam service for your reference.</p>

<p>If you have any questions about the change or want to see a report of what INKY has already been catching for $bwhClientName, please don't hesitate to reach out &mdash; or use the booking link in my signature below to grab time directly.</p>

$signature
</body></html>
"@

$draftBwh = New-MgUserMessage -UserId $senderUpn -BodyParameter @{
    Subject = $bwhSubject
    Body = @{ ContentType = "HTML"; Content = $bwhBody }
    ToRecipients = @( @{ EmailAddress = @{ Address = $bwhTo; Name = "Dave Barisic" } } )
}

Write-Host "Created BWH draft: $($draftBwh.Id)"
Write-Host "  Subject: $bwhSubject"
Write-Host "  To:      $bwhTo"

# ================================================================
# Sample 2: AFFG (prospect)
# ================================================================
$affgFirstName = "Iris"
$affgClientName = "American Fundstars Financial Group"
$affgSubject = "Protect $affgClientName from Phishing - Technijian My AntiSpam Now Available"
$affgTo = "iris.liu@americanfundstars.com"

$affgBody = @"
<html><body style="$bodyStyle">
<p>Hi $affgFirstName,</p>

<p>I'm reaching out because we've recently made a significant upgrade to our email security offering &mdash; Technijian My AntiSpam &mdash; and I wanted to personally share it with you since $affgClientName doesn't currently have it in place.</p>

<p><strong>Why This Matters</strong></p>

<p>Email is still the #1 way cybercriminals target businesses. Phishing, business email compromise, CEO impersonation, ransomware attachments, and account takeovers all start with a single malicious email slipping through. Standard email filtering &mdash; including what's built into Microsoft 365 or Google Workspace &mdash; simply isn't enough anymore, especially now that attackers are using AI to craft incredibly convincing phishing emails.</p>

<p>Additionally, many cyber insurance policies now require advanced email security for coverage, and a single successful phishing attack can cost tens of thousands of dollars in damages and recovery.</p>

<p><strong>The Offer</strong></p>

<p>Technijian My AntiSpam is powered by INKY, an industry-leading AI-driven email security platform. Kaseya's recent acquisition of INKY has allowed us to offer the complete INKY suite &mdash; every feature, fully activated &mdash; at just `$4.75 per user per month, with new accounts going live the week of Monday, May 5, 2026.</p>

<p>To put that in perspective: comparable enterprise-tier email security platforms run well over `$10.00 per user per month. We don't believe anyone can beat this price.</p>

<p><strong>Everything Included in Technijian My AntiSpam</strong></p>

<ul>
<li><strong>Inbound Mail Protection</strong> &mdash; AI reads every incoming email to detect phishing, scams, and malicious content before it reaches your team, with warning banners that explain exactly why something was flagged.</li>
<li><strong>Outbound Mail Protection</strong> &mdash; Scans emails your employees send to prevent data leaks and ensure nothing sensitive leaves your organization undetected.</li>
<li><strong>Internal Mail Protection</strong> &mdash; Monitors email sent between your own staff, protecting against threats from compromised internal accounts.</li>
<li><strong>Email Encryption</strong> &mdash; Automatically encrypts sensitive outbound messages so only the intended recipient can read them.</li>
<li><strong>Advanced Attachment Analysis</strong> &mdash; Deep-scans every attachment for malware and ransomware before it ever reaches an inbox.</li>
<li><strong>Graymail Protection</strong> &mdash; Filters out newsletters and bulk mail clutter so real threats don't get buried in the noise.</li>
<li><strong>Email Signatures</strong> &mdash; Enforces consistent, professional email signatures across your entire organization.</li>
<li><strong>DMARC Monitoring</strong> &mdash; Monitors your domain's email authentication to prevent cybercriminals from impersonating your company in emails to others.</li>
</ul>

<p><strong>Getting Started</strong></p>

<p>Deployment is fast, there's zero downtime, and we handle the entire setup for you. Most clients are fully protected within a day. I've attached a one-page overview of the full Technijian My AntiSpam service so you can share it with your team.</p>

<p>I'd love to schedule a quick call to walk you through it and answer any questions &mdash; use the booking link in my signature below to grab a slot that works for you. Or if you're ready to move forward now, just reply to this email and we'll get $affgClientName onboarded.</p>

<p>Thanks, and stay safe out there.</p>

$signature
</body></html>
"@

$draftAffg = New-MgUserMessage -UserId $senderUpn -BodyParameter @{
    Subject = $affgSubject
    Body = @{ ContentType = "HTML"; Content = $affgBody }
    ToRecipients = @( @{ EmailAddress = @{ Address = $affgTo; Name = "Iris Liu" } } )
}

Write-Host "Created AFFG draft: $($draftAffg.Id)"
Write-Host "  Subject: $affgSubject"
Write-Host "  To:      $affgTo"

Disconnect-MgGraph | Out-Null
Write-Host ""
Write-Host "Both drafts created. Check RJain@technijian.com Drafts folder in Outlook."
