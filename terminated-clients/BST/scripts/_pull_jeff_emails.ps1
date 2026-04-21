# Pull all emails to/from Jeff Klein (BST) from Ravi's mailbox via Graph app-only auth.
# Saves email bodies + attachments into the BST terminated-client folder.

$ErrorActionPreference = "Stop"

# --- Config ---
$bstFolder    = "c:\vscode\tech-legal\tech-legal\terminated-clients\BST"
$emailsFolder = Join-Path $bstFolder "emails"
$attachFolder = Join-Path $bstFolder "attachments"
$userId       = "RJain@technijian.com"
$searchTerm   = "Jeff Klein"    # broad name search first; we'll refine by address
$topPerPage   = 100

New-Item -ItemType Directory -Force -Path $emailsFolder | Out-Null
New-Item -ItemType Directory -Force -Path $attachFolder | Out-Null

# --- Load credentials from OneDrive keys ---
$keysContent = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$clientId    = [regex]::Match($keysContent, 'App Client ID:\*\*\s*(\S+)').Groups[1].Value
$tenantId    = [regex]::Match($keysContent, 'Tenant ID:\*\*\s*(\S+)').Groups[1].Value
$secret      = [regex]::Match($keysContent, 'Client Secret:\*\*\s*(\S+)').Groups[1].Value

if (-not $clientId -or -not $tenantId -or -not $secret) {
    throw "Failed to parse Graph credentials from m365-graph.md"
}

# --- Connect ---
Import-Module Microsoft.Graph.Authentication -ErrorAction SilentlyContinue
Import-Module Microsoft.Graph.Users.Actions   -ErrorAction SilentlyContinue
Import-Module Microsoft.Graph.Mail            -ErrorAction SilentlyContinue

$secureSecret = ConvertTo-SecureString $secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($clientId, $secureSecret)
Connect-MgGraph -TenantId $tenantId -ClientSecretCredential $credential -NoWelcome

Write-Host "Connected to Graph as app. Searching mailbox..." -ForegroundColor Cyan

# --- Helper: sanitize for filename ---
function Clean-Name($s) {
    if (-not $s) { return "unknown" }
    $s = $s -replace '[\\/:*?"<>|]', '_'
    $s = $s -replace '\s+', ' '
    if ($s.Length -gt 120) { $s = $s.Substring(0, 120) }
    return $s.Trim()
}

# --- Discovery pass: find messages matching "Jeff Klein" anywhere, across folders ---
# Graph search spans across folders when calling /users/{id}/messages.
$encodedSearch = [uri]::EscapeDataString('"' + $searchTerm + '"')
$uri = "https://graph.microsoft.com/v1.0/users/$userId/messages?`$search=$encodedSearch&`$top=$topPerPage&`$select=id,subject,from,toRecipients,ccRecipients,receivedDateTime,sentDateTime,hasAttachments,parentFolderId,internetMessageId,bodyPreview"

$allMessages = @()
do {
    $resp = Invoke-MgGraphRequest -Method GET -Uri $uri
    if ($resp.value) { $allMessages += $resp.value }
    $uri = $resp.'@odata.nextLink'
} while ($uri)

Write-Host ("Found {0} messages matching '{1}'" -f $allMessages.Count, $searchTerm) -ForegroundColor Green

# --- Inspect addresses to confirm Jeff's email(s) ---
$jeffAddrs = @{}
foreach ($m in $allMessages) {
    $from = $m.from.emailAddress.address
    if ($from -and ($m.from.emailAddress.name -match 'jeff' -or $from -match 'jeff')) {
        $jeffAddrs[$from.ToLower()] = ($jeffAddrs[$from.ToLower()] + 1)
    }
    foreach ($r in @($m.toRecipients) + @($m.ccRecipients)) {
        $addr = $r.emailAddress.address
        if ($addr -and ($r.emailAddress.name -match 'jeff' -or $addr -match 'jeff')) {
            $jeffAddrs[$addr.ToLower()] = ($jeffAddrs[$addr.ToLower()] + 1)
        }
    }
}

Write-Host "Jeff-candidate addresses detected:" -ForegroundColor Yellow
$jeffAddrs.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
    Write-Host ("  {0}  (hits: {1})" -f $_.Key, $_.Value)
}

# --- Save index manifest ---
$indexPath = Join-Path $bstFolder "emails_index.csv"
$allMessages | Select-Object `
    @{n='ReceivedOrSent'; e={ if ($_.receivedDateTime) { $_.receivedDateTime } else { $_.sentDateTime } }},
    @{n='From';           e={ $_.from.emailAddress.address }},
    @{n='FromName';       e={ $_.from.emailAddress.name }},
    @{n='To';             e={ ($_.toRecipients.emailAddress.address -join '; ') }},
    Subject,
    hasAttachments,
    id,
    parentFolderId,
    internetMessageId `
    | Sort-Object ReceivedOrSent `
    | Export-Csv -Path $indexPath -NoTypeInformation -Encoding UTF8

Write-Host "Index written: $indexPath" -ForegroundColor Green

# --- Save each message as markdown + download attachments ---
foreach ($m in $allMessages) {
    $dateStr = ""
    if ($m.receivedDateTime) {
        $dateStr = ([datetime]$m.receivedDateTime).ToString("yyyy-MM-dd_HHmm")
    } elseif ($m.sentDateTime) {
        $dateStr = ([datetime]$m.sentDateTime).ToString("yyyy-MM-dd_HHmm")
    } else {
        $dateStr = "nodate"
    }
    $subj = Clean-Name $m.subject
    $baseName = "$dateStr`_$subj"
    if ($baseName.Length -gt 150) { $baseName = $baseName.Substring(0, 150) }

    # Fetch full message body
    $full = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$userId/messages/$($m.id)?`$select=id,subject,from,toRecipients,ccRecipients,receivedDateTime,sentDateTime,body,hasAttachments,internetMessageId"

    $bodyContent = $full.body.content
    $bodyType    = $full.body.contentType   # html or text

    $ext = if ($bodyType -eq 'html') { 'html' } else { 'txt' }
    $bodyPath = Join-Path $emailsFolder "$baseName.$ext"

    $header = @"
<!--
From:    $($full.from.emailAddress.name) <$($full.from.emailAddress.address)>
To:      $(($full.toRecipients.emailAddress.address) -join '; ')
Cc:      $(($full.ccRecipients.emailAddress.address) -join '; ')
Subject: $($full.subject)
Date:    $($full.receivedDateTime)$($full.sentDateTime)
MessageId: $($full.internetMessageId)
-->
"@
    Set-Content -Path $bodyPath -Value ($header + "`r`n" + $bodyContent) -Encoding UTF8

    # Attachments
    if ($full.hasAttachments) {
        $atts = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$userId/messages/$($m.id)/attachments"
        foreach ($a in $atts.value) {
            if ($a.'@odata.type' -eq '#microsoft.graph.fileAttachment' -and $a.contentBytes) {
                $attName = Clean-Name $a.name
                $attPath = Join-Path $attachFolder "$dateStr`_$attName"
                $bytes = [Convert]::FromBase64String($a.contentBytes)
                [IO.File]::WriteAllBytes($attPath, $bytes)
                Write-Host "  attachment -> $attPath"
            }
        }
    }
}

Write-Host "Done. Emails saved to: $emailsFolder" -ForegroundColor Cyan
Write-Host "Attachments saved to: $attachFolder" -ForegroundColor Cyan
