# Send BST Jeff Klein VPN Access-Unavailable Notice via Microsoft Graph
# DEFAULT: creates draft only (review in Outlook before sending)
# PURPOSE: preserves CFAA/CDAFA evidence + refutes future § 4.05 abandonment argument
# TARGET: send today while VPN request is still live
#
# Usage:
#   .\send-bst-jeff-access-notice.ps1         # draft only (DEFAULT)
#   .\send-bst-jeff-access-notice.ps1 -Send   # send immediately

param([switch]$Send)

$ErrorActionPreference = "Stop"

$senderUpn = "RJain@technijian.com"
$subject   = "VPN Support Request - Continued Access Limitations Following Tech Heights Transition"

$toList = @(
    @{ Address = "jklein@bostongroupwaste.com"; Name = "Jeff Klein" },
    @{ Address = "gagan@bostongroupwaste.com";  Name = "Gagan Singh" }
)
$ccList = @(
    @{ Address = "es@callahan-law.com";     Name = "Edward Susolik" },
    @{ Address = "support@technijian.com";  Name = "Technijian Support" },
    @{ Address = "RMohamed@Technijian.com"; Name = "Raja Mohamed" }
)

$sigPath = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"

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

# --- Build HTML body (backtick-escape every literal $) ---
$fontStack = "Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif"
$htmlBody = @"
<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>
<body dir="ltr">
<div style="font-family:$fontStack;font-size:12pt;color:rgb(0,0,0)">

<p>Hello Jeff and Gagan,</p>

<p>Gagan called in today requesting VPN assistance. I want to confirm in writing &mdash; consistent with my April 3, 2026 email on access, transition coordination, and outstanding invoices &mdash; why Technijian is unable to act on this request, what has continued to change in the environment since that email, and what we need from Boston Group to resume support through the April 30, 2026 termination date.</p>

<p><strong>Documented access obstructions &mdash; sequence of events:</strong></p>

<ol>
<li><strong>Night of March 31, 2026</strong> &mdash; Tech Heights personnel worked in the environment after hours. The <strong>ESXi host password was changed without notice to Technijian</strong>, locking us out of the virtualization layer. Reported to you in writing on April 1, 2026 at 9:28 AM (Helpdesk email, Rishad Samad).</li>

<li><strong>April 1, 2026</strong> &mdash; BST-HQ-AD-01 Active Directory server went offline. Technijian <strong>offered to dispatch an engineer (Rishad) onsite</strong> the same day to restore service. That offer was declined at 11:29 AM ("No thank you. Let's just resolve this and move on.").</li>

<li><strong>April 2, 2026 (evening) &ndash; April 3, 2026</strong> &mdash; BST-HQ-AD-02 also went offline. <strong>CrowdStrike detected and blocked an unauthorized attempt to elevate a new account to the Domain Admins group.</strong> Reported to you in writing on April 3, 2026 at 2:32 AM (Rishad Mohamed, "RE: Urgent: Suspicious Activity Detected on BST-HQ-AD-02").</li>

<li><strong>April 3, 2026</strong> &mdash; Technijian's <strong>remote management tools were removed</strong>, our <strong>administrative access account was disabled</strong>, and <strong>RDP access to the AD servers was revoked</strong>. Documented in my April 3, 2026 email (Ed Susolik cc'd) asking Boston Group to confirm Tech Heights as the primary administrator going forward and to identify authorized Tech Heights recipients for credentials.</li>

<li><strong>Since April 3, 2026</strong> &mdash; Additional environmental changes have been observed by our engineers, including:
<ul>
<li><strong>Default gateway changed</strong> from 10.1.1.254 to 10.1.1.1 and the previous firewall replaced. Technijian has no credentials on the current gateway or firewall.</li>
<li><strong>Technijian monitoring and management agents</strong> have been removed from BST endpoints and servers.</li>
<li>Domain controllers continue to be inaccessible to Technijian.</li>
</ul>
</li>
</ol>

<p><strong>Result for today's VPN request:</strong> Without credentials to the current firewall/gateway, the current domain controllers, or the current hypervisor, Technijian cannot diagnose or remediate the reported VPN issue. Our engineer directed Gagan to contact Tech Heights, since Tech Heights currently holds the operational credentials. This email confirms that direction in writing.</p>

<p><strong>Our position through April 30, 2026:</strong></p>

<ul>
<li>Technijian <strong>remains contractually willing to provide support</strong> through the termination date per Section 4.05 of the signed agreement. Our offer of April 1 (onsite dispatch) and April 3 (coordinated access restoration) both remain available.</li>
<li><strong>We cannot provide support without administrative access.</strong> If Boston Group directs Tech Heights to (a) restore the ESXi host credentials, (b) restore a Technijian administrative account on the current domain controllers, (c) provide read/admin credentials on the current firewall/gateway, and (d) reinstate our monitoring and management agents, we will resume normal support response immediately.</li>
<li><strong>Otherwise, please direct all active support requests to Tech Heights,</strong> which currently holds the operational credentials for the BST environment.</li>
</ul>

<p><strong>Reservation of rights:</strong></p>

<p>Nothing in this email waives, releases, or limits any claim Technijian may have arising from the unauthorized credential changes, agent removals, access-account disabling, or related conduct by Tech Heights or any other third party, including without limitation claims under the Computer Fraud and Abuse Act, California Penal Code &sect; 502, or for tortious interference. All rights are expressly reserved.</p>

<p>The termination items outlined in my March 23 and April 3, 2026 emails &mdash; including the `$15,045.00 settlement offer (open through April 30, 2026), invoice #28064 (`$126,442.50 contract-basis cancellation fee, due April 30, 2026), invoice #27949 (`$5,645.35, past due), invoice #27890 (`$552.00, past due), and invoices #28112 and #28143 (due May 1, 2026) &mdash; remain as stated.</p>

<p>Please confirm by reply whether Boston Group intends to restore Technijian's access for the remaining notice period, or whether ongoing support should be routed to Tech Heights.</p>

<p>Thank you,</p>

</div>
$sig
</body>
</html>
"@

# --- Connect to Graph ---
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome
Write-Host "Connected." -ForegroundColor Green

# --- Create draft ---
Write-Host "Creating draft message..." -ForegroundColor Cyan
$toRecipients = @()
foreach ($r in $toList) {
    $toRecipients += @{ EmailAddress = @{ Address = $r.Address; Name = $r.Name } }
}
$ccRecipients = @()
foreach ($r in $ccList) {
    $ccRecipients += @{ EmailAddress = @{ Address = $r.Address; Name = $r.Name } }
}
$draftParams = @{
    Subject = $subject
    Body = @{
        ContentType = "HTML"
        Content     = $htmlBody
    }
    ToRecipients = $toRecipients
    CcRecipients = $ccRecipients
}
$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter $draftParams
Write-Host "Draft created. MessageId = $($draft.Id)" -ForegroundColor Green

if ($Send) {
    Write-Host "Sending..." -ForegroundColor Cyan
    Send-MgUserMessage -UserId $senderUpn -MessageId $draft.Id
    $toAddrs = ($toList | ForEach-Object { $_.Address }) -join ", "
    $ccAddrs = ($ccList | ForEach-Object { $_.Address }) -join ", "
    Write-Host "`nSENT to $toAddrs (cc: $ccAddrs)." -ForegroundColor Green
} else {
    Write-Host "`nDRAFT saved to Outlook Drafts folder for RJain@technijian.com." -ForegroundColor Yellow
    Write-Host "Review in Outlook, then either:" -ForegroundColor Yellow
    Write-Host "  - Click Send from Outlook, OR" -ForegroundColor Yellow
    Write-Host "  - Re-run this script with -Send flag to send automatically" -ForegroundColor Yellow
}
Write-Host "Subject: $subject" -ForegroundColor Gray

Disconnect-MgGraph | Out-Null
