# Draft email to Jeff Klein: Cumulative cooperation pattern + access obstruction recap
# Send after Satish's 4/27 password-reset documentation email lands.
# Creates draft in Outlook only — no auto-send.

$ErrorActionPreference = "Stop"

$toEmail    = "jklein@bostongroupwaste.com"
$toName     = "Jeff Klein"
$ccList     = @(
    @{ EmailAddress = @{ Address = "gagan@bostongroupwaste.com"; Name = "Gagan Singh" } },
    @{ EmailAddress = @{ Address = "lcronlaw@gmail.com";          Name = "Mr. Cron" } },
    @{ EmailAddress = @{ Address = "fdunn@callahan-law.com";      Name = "Frank Dunn, Esq." } },
    @{ EmailAddress = @{ Address = "es@callahan-law.com";         Name = "Edward Susolik, Esq." } }
)
$senderUpn  = "RJain@technijian.com"
$subject    = "Boston Group - Continuing Cooperation Through April 30 and Access Limitations"
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
$fontStack = "Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif"
$htmlBody = @"
<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>
<body dir="ltr">
<div style="font-family:$fontStack;font-size:12pt;color:rgb(0,0,0)">

<p>Jeff,</p>

<p>This morning you called Technijian Support requesting a password reset on your office domain machine. Our engineer, Satish Sharma, attempted to assist via the MyRemote agent that remains installed on your workstation. As Satish explained on the call (and is documenting in a separate email to you on copy with me), Technijian no longer has administrative access to the Boston Group domain controller, the firewall, or the ESXi host, and we therefore cannot complete a domain password reset from our side. The current administrative credentials are held by Tech Heights.</p>

<p>I want to put the cumulative pattern of the past week in writing so the record is clear, in light of your April 16 statement that &ldquo;you have made it clear you will not help with the transition.&rdquo; That statement does not match what has actually happened. Since April 22, Technijian has honored every support request you or your team has made that did not require credentials Tech Heights has taken from us:</p>

<table cellspacing="0" cellpadding="6" border="1" style="border-collapse:collapse;border-color:#cccccc;font-family:$fontStack;font-size:11pt">
<thead style="background-color:#f3f3f3">
<tr>
  <th style="text-align:left">Date</th>
  <th style="text-align:left">Boston Group request</th>
  <th style="text-align:left">Technijian response</th>
</tr>
</thead>
<tbody>
<tr>
  <td>April 22, 2026</td>
  <td>Disable agent tamper protection on BST endpoints (token/key prompt)</td>
  <td><strong>Completed.</strong> Tamper protection disabled across all BST agents the same day; confirmed in writing by Support at 6:45 PM PT.</td>
</tr>
<tr>
  <td>April 22, 2026</td>
  <td>Push uninstall of Huntress and ManageEngine agents from BST endpoints</td>
  <td><strong>Completed.</strong> Huntress agents uninstalled from our end; ManageEngine protection disabled to allow client-side removal; confirmed in writing by Support at 7:30 PM PT.</td>
</tr>
<tr>
  <td>April 23, 2026</td>
  <td>Grant Jeff Klein Microsoft 365 Global Administrator access on the BST tenant</td>
  <td><strong>Completed.</strong> Global Administrator role assigned by Rishad Mohamed; confirmed in writing by Support at 6:06 PM PT.</td>
</tr>
<tr>
  <td>April 27, 2026 (today)</td>
  <td>Password reset on office domain machine</td>
  <td><strong>Cannot complete from our side.</strong> Technijian has no domain controller administrative credentials. The current credentials are held by Tech Heights, who replaced the on-prem infrastructure (default gateway, firewall, hypervisor passwords) starting March 31 - April 3, 2026, without sharing the new credentials with Technijian. We attempted via the MyRemote agent and confirmed on the call.</td>
</tr>
</tbody>
</table>

<p>The point is straightforward. Technijian remains willing and able to support Boston Group through the April 30, 2026 termination date for any item that does not require credentials we no longer hold. For anything that requires the on-prem domain controller, the current firewall, or the ESXi host, we cannot act unless Tech Heights restores access.</p>

<p><strong>Standing offer (unchanged from my April 3 and April 15 emails):</strong> if Boston Group directs Tech Heights to (a) restore the ESXi host credentials, (b) reinstate a Technijian administrative account on the current domain controllers, (c) provide read/admin credentials on the current firewall and gateway, and (d) reinstate Technijian's monitoring and management agents, we will resume full normal support response immediately through April 30, 2026. The offer is open today and remains open through the termination date.</p>

<p>Nothing in this email waives, releases, or limits any claim Technijian may have arising from the unauthorized credential changes, agent removals, or related conduct by Tech Heights, Mr. Leggett, or any other party. All rights are expressly reserved, including without limitation under the Computer Fraud and Abuse Act, California Penal Code &sect; 502, California Civil Code &sect;&sect; 3426 et seq. (trade secret), tortious interference, and the anti-hire and confidentiality provisions of the signed Agreement.</p>

<p>Mr. Cron - if Boston Group has questions about credential restoration or wants to coordinate with Tech Heights on this directly, please reach Frank Dunn at fdunn@callahan-law.com. Edward Susolik is supervising on copy.</p>

<p>Thank you,</p>

</div>
$sig
</body>
</html>
"@

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
    CcRecipients = $ccList
}
$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter $draftParams
Write-Host "Draft created. MessageId = $($draft.Id)" -ForegroundColor Green
Write-Host "Subject : $subject" -ForegroundColor Gray
Write-Host "To      : $toEmail" -ForegroundColor Gray
Write-Host ("Cc      : " + (($ccList | ForEach-Object { $_.EmailAddress.Address }) -join ', ')) -ForegroundColor Gray

Disconnect-MgGraph | Out-Null
Write-Host "`nDRAFT is in Outlook Drafts. Send AFTER Satish's password-reset email lands so they reference each other in the record." -ForegroundColor Yellow
