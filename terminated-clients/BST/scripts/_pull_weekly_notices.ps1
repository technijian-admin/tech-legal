# Pull Sent Items from clientportal@technijian.com addressed to Boston Group.
# Used to locate the weekly zero-dollar itemized time notices referenced in the
# BST cancellation dispute — these are Technijian's strongest factual anchor.

$ErrorActionPreference = "Stop"

# --- Config ---
$bstFolder    = "c:\vscode\tech-legal\tech-legal\terminated-clients\BST"
$mailboxes    = @("clientportal@technijian.com", "billing@technijian.com")
$bstDomain    = "bostongroupwaste.com"
$topPerPage   = 100

# --- Load credentials from OneDrive keys ---
$keysContent = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$clientId    = [regex]::Match($keysContent, 'App Client ID:\*\*\s*(\S+)').Groups[1].Value
$tenantId    = [regex]::Match($keysContent, 'Tenant ID:\*\*\s*(\S+)').Groups[1].Value
$secret      = [regex]::Match($keysContent, 'Client Secret:\*\*\s*(\S+)').Groups[1].Value

if (-not $clientId -or -not $tenantId -or -not $secret) {
    throw "Failed to parse Graph credentials from m365-graph.md"
}

Import-Module Microsoft.Graph.Authentication -ErrorAction SilentlyContinue

$secureSecret = ConvertTo-SecureString $secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($clientId, $secureSecret)
Connect-MgGraph -TenantId $tenantId -ClientSecretCredential $credential -NoWelcome

Write-Host "Connected to Graph as app." -ForegroundColor Cyan

function Format-FileName($s) {
    if (-not $s) { return "unknown" }
    $s = $s -replace '[\\/:*?"<>|]', '_'
    $s = $s -replace '\s+', ' '
    if ($s.Length -gt 120) { $s = $s.Substring(0, 120) }
    return $s.Trim()
}

# Extract address strings from recipient collections (Graph returns hashtables)
function Get-Addresses($recipients) {
    $out = @()
    if (-not $recipients) { return $out }
    foreach ($r in $recipients) {
        $addr = $null
        if ($r -is [hashtable]) {
            if ($r.ContainsKey('emailAddress') -and $r['emailAddress']) {
                $addr = $r['emailAddress']['address']
            }
        } else {
            $addr = $r.emailAddress.address
        }
        if ($addr) { $out += $addr }
    }
    return $out
}

$grandTotal = 0

foreach ($userId in $mailboxes) {
    $mboxLabel  = ($userId -split '@')[0]
    $outFolder  = Join-Path $bstFolder "mbox_${mboxLabel}"
    New-Item -ItemType Directory -Force -Path $outFolder | Out-Null

    Write-Host "`n=== Mailbox: $userId ===" -ForegroundColor Cyan

    $uri = "https://graph.microsoft.com/v1.0/users/$userId/mailFolders/SentItems/messages?`$top=$topPerPage&`$select=id,subject,from,toRecipients,ccRecipients,sentDateTime,hasAttachments,internetMessageId,bodyPreview"

    $all = @()
    $page = 0
    do {
        $page++
        if (($page % 10) -eq 0) { Write-Host "  fetching page $page ..." -ForegroundColor DarkGray }
        $resp = Invoke-MgGraphRequest -Method GET -Uri $uri
        if ($resp.value) { $all += $resp.value }
        $uri = $resp.'@odata.nextLink'
    } while ($uri)

    Write-Host ("  total sent items: {0}" -f $all.Count)

    $bst = @()
    foreach ($m in $all) {
        $recips = @()
        $recips += Get-Addresses $m.toRecipients
        $recips += Get-Addresses $m.ccRecipients
        foreach ($addr in $recips) {
            if ($addr -and $addr.ToLower() -match [regex]::Escape($bstDomain)) {
                $bst += $m
                break
            }
        }
    }

    Write-Host ("  BST-addressed sent items: {0}" -f $bst.Count) -ForegroundColor Green
    $grandTotal += $bst.Count

    if ($bst.Count -eq 0) { continue }

    Write-Host "  subject patterns (top 15):" -ForegroundColor Yellow
    $bst | Group-Object -Property Subject | Sort-Object Count -Descending | Select-Object -First 15 | ForEach-Object {
        Write-Host ("    {0,4}  {1}" -f $_.Count, $_.Name)
    }

    # Index CSV per mailbox
    $indexPath = Join-Path $bstFolder "mbox_${mboxLabel}_index.csv"
    $bst | ForEach-Object {
        [pscustomobject]@{
            Sent             = $_.sentDateTime
            Subject          = $_.subject
            To               = ((Get-Addresses $_.toRecipients) -join '; ')
            Cc               = ((Get-Addresses $_.ccRecipients) -join '; ')
            HasAttachments   = $_.hasAttachments
            Id               = $_.id
            InternetMessageId= $_.internetMessageId
        }
    } | Sort-Object Sent | Export-Csv -Path $indexPath -NoTypeInformation -Encoding UTF8

    Write-Host "  index: $indexPath" -ForegroundColor Green

    # Save bodies + attachments
    foreach ($m in $bst) {
        $dateStr = if ($m.sentDateTime) { ([datetime]$m.sentDateTime).ToString("yyyy-MM-dd_HHmm") } else { "nodate" }
        $subj = Format-FileName $m.subject
        $baseName = "$dateStr`_$subj"
        if ($baseName.Length -gt 140) { $baseName = $baseName.Substring(0, 140) }

        $full = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$userId/messages/$($m.id)?`$select=id,subject,from,toRecipients,ccRecipients,sentDateTime,body,hasAttachments,internetMessageId"

        $bodyContent = $full.body.content
        $bodyType    = $full.body.contentType
        $ext = if ($bodyType -eq 'html') { 'html' } else { 'txt' }
        $bodyPath = Join-Path $outFolder "$baseName.$ext"

        $fromName = if ($full.from) { $full.from.emailAddress.name } else { '' }
        $fromAddr = if ($full.from) { $full.from.emailAddress.address } else { '' }
        $toList   = ((Get-Addresses $full.toRecipients) -join '; ')
        $ccList   = ((Get-Addresses $full.ccRecipients) -join '; ')

        $header = @"
<!--
From:    $fromName <$fromAddr>
To:      $toList
Cc:      $ccList
Subject: $($full.subject)
Sent:    $($full.sentDateTime)
MessageId: $($full.internetMessageId)
-->
"@
        Set-Content -Path $bodyPath -Value ($header + "`r`n" + $bodyContent) -Encoding UTF8

        if ($full.hasAttachments) {
            $atts = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$userId/messages/$($m.id)/attachments"
            foreach ($a in $atts.value) {
                if ($a.'@odata.type' -eq '#microsoft.graph.fileAttachment' -and $a.contentBytes) {
                    $attName = Format-FileName $a.name
                    $attPath = Join-Path $outFolder "$dateStr`_$attName"
                    $bytes = [Convert]::FromBase64String($a.contentBytes)
                    [IO.File]::WriteAllBytes($attPath, $bytes)
                }
            }
        }
    }
}

Write-Host "`nDone. Total BST-addressed items across mailboxes: $grandTotal" -ForegroundColor Cyan
