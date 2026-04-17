# Pull the 4 access-notice emails as true .eml from Ravi's sent items so we can
# attach them as transmission proof in the response package.

$ErrorActionPreference = "Stop"
$userId = "RJain@technijian.com"
$outDir = "C:\vscode\tech-legal\tech-legal\terminated-clients\BST\send_package_2026-04-17"

$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$cid = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
$cred = New-Object System.Management.Automation.PSCredential($cid, (ConvertTo-SecureString $sec -AsPlainText -Force))
Connect-MgGraph -TenantId $tid -ClientSecretCredential $cred -NoWelcome
Write-Host "Connected." -ForegroundColor Green

# Target messages: subject substring + ISO date match
$targets = @(
    @{ date = "2026-04-03"; needle = "Access Update, Transition Coordination"; outName = "2026-04-03_Access_Update_Transition.eml" },
    @{ date = "2026-04-09"; needle = "Account Closeout, Outstanding Invoices, and Counsel Review"; outName = "2026-04-09_Account_Closeout_Counsel_Review.eml" },
    @{ date = "2026-04-14"; needle = "Time-Sensitive Closeout Items"; outName = "2026-04-14_Time-Sensitive_Closeout.eml" },
    @{ date = "2026-04-15"; needle = "VPN Support Request";            outName = "2026-04-15_VPN_Support_Access_Limitations.eml" }
)

foreach ($t in $targets) {
    $search = [uri]::EscapeDataString('"' + $t.needle + '"')
    $uri = "https://graph.microsoft.com/v1.0/users/$userId/mailFolders/SentItems/messages?`$search=$search&`$top=10&`$select=id,subject,sentDateTime,internetMessageId"
    $resp = Invoke-MgGraphRequest -Method GET -Uri $uri

    # Graph search doesn't reliably order by date; pick first result whose sentDateTime date matches
    $chosen = $null
    foreach ($m in $resp.value) {
        if ($m.sentDateTime -and $m.sentDateTime.ToString().StartsWith($t.date)) { $chosen = $m; break }
    }
    if (-not $chosen -and $resp.value.Count -gt 0) { $chosen = $resp.value[0] }

    if (-not $chosen) {
        Write-Host "NO MATCH for '$($t.needle)'" -ForegroundColor Red
        continue
    }
    Write-Host ("Found: [{0}] {1}" -f $chosen.sentDateTime, $chosen.subject)

    # Download as raw MIME / .eml via $value endpoint
    $emlUri = "https://graph.microsoft.com/v1.0/users/$userId/messages/$($chosen.id)/`$value"
    $outPath = Join-Path $outDir $t.outName
    # Invoke-MgGraphRequest can write a file via -OutputFilePath in newer versions; fall back to manual handling
    try {
        Invoke-MgGraphRequest -Method GET -Uri $emlUri -OutputFilePath $outPath
    } catch {
        # Fallback: use Get-MgUserMessageContent if available
        $raw = Invoke-MgGraphRequest -Method GET -Uri $emlUri
        if ($raw -is [byte[]]) {
            [System.IO.File]::WriteAllBytes($outPath, $raw)
        } elseif ($raw -is [string]) {
            [System.IO.File]::WriteAllText($outPath, $raw, [System.Text.Encoding]::UTF8)
        } else {
            Write-Warning "Unexpected response type: $($raw.GetType())"
        }
    }
    if (Test-Path $outPath) {
        $sz = (Get-Item $outPath).Length
        Write-Host ("  saved: {0} ({1:N0} bytes)" -f $outPath, $sz) -ForegroundColor Green
    } else {
        Write-Host "  FAILED to save $outPath" -ForegroundColor Red
    }
}

Disconnect-MgGraph | Out-Null
