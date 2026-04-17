# Pull the current BST response draft from Outlook so we can review Ravi's edits
# before regenerating.

$ErrorActionPreference = "Stop"
$senderUpn = "RJain@technijian.com"
$subjectNeedle = "Boston Group - Time-Sensitive Closeout Items"
$outPath = "C:\vscode\tech-legal\tech-legal\terminated-clients\BST\_current_draft_snapshot.html"

$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$cid = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value

$secure = ConvertTo-SecureString $sec -AsPlainText -Force
$cred   = New-Object System.Management.Automation.PSCredential($cid, $secure)
Connect-MgGraph -TenantId $tid -ClientSecretCredential $cred -NoWelcome

# Find the most-recent draft in Drafts folder matching the subject
$uri = "https://graph.microsoft.com/v1.0/users/$senderUpn/mailFolders/Drafts/messages?`$top=20&`$orderby=lastModifiedDateTime desc&`$select=id,subject,lastModifiedDateTime,toRecipients,ccRecipients,hasAttachments"
$resp = Invoke-MgGraphRequest -Method GET -Uri $uri

$match = $null
foreach ($m in $resp.value) {
    if ($m.subject -and $m.subject.Contains($subjectNeedle)) { $match = $m; break }
}

if (-not $match) {
    Write-Host "No draft found matching '$subjectNeedle'" -ForegroundColor Red
    Disconnect-MgGraph | Out-Null
    exit 1
}

Write-Host "Found draft: $($match.subject)"
Write-Host "  Last modified: $($match.lastModifiedDateTime)"
Write-Host "  MessageId: $($match.id)"
Write-Host ""

$full = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$($match.id)?`$select=id,subject,body,toRecipients,ccRecipients,hasAttachments,lastModifiedDateTime"

$toList = @()
foreach ($r in $full.toRecipients) { $toList += $r.emailAddress.address }
$ccList = @()
foreach ($r in $full.ccRecipients) { $ccList += $r.emailAddress.address }

Set-Content -Path $outPath -Value $full.body.content -Encoding UTF8

Write-Host "To: $($toList -join ', ')"
Write-Host "Cc: $($ccList -join ', ')"
Write-Host "Has attachments: $($full.hasAttachments)"
Write-Host ""
Write-Host "Body saved to: $outPath"

# Also list attachments if present
if ($full.hasAttachments) {
    $atts = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$($match.id)/attachments?`$select=name,size,contentType"
    Write-Host "Attachments:"
    foreach ($a in $atts.value) {
        Write-Host ("  - {0}  ({1:N0} bytes)" -f $a.name, $a.size)
    }
}

Disconnect-MgGraph | Out-Null
