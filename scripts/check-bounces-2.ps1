# Check inbox for bounce-back / undeliverable emails — second pass
$m365Keys     = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome

# Search for all bounces related to our DC upgrade subject
$filter = "subject eq 'Undeliverable: Scheduled Data Center Network Upgrade - Saturday, April 18 | Enhanced Security and Redundancy'"
$msgs = Get-MgUserMessage -UserId "RJain@technijian.com" -Filter $filter -Property "id,from,subject,receivedDateTime,body" -Top 50

Write-Host "=== Bounce messages for DC Upgrade Notice ==="
Write-Host "Total bounces found: $($msgs.Count)"
Write-Host ""

$allBounced = @()
foreach ($m in $msgs) {
    $dt = $m.ReceivedDateTime
    $bodyText = $m.Body.Content
    $matches = [regex]::Matches($bodyText, '[\w.+-]+@[\w.-]+\.\w{2,}')
    $failedAddrs = @()
    foreach ($match in $matches) {
        $addr = $match.Value.ToLower()
        if ($addr -notmatch "technijian|postmaster|namprd|prod\.outlook") {
            $failedAddrs += $addr
        }
    }
    $unique = $failedAddrs | Select-Object -Unique
    foreach ($a in $unique) {
        $allBounced += $a
        Write-Host "[$dt] BOUNCED: $a"
    }
}

Write-Host ""
Write-Host "=== UNIQUE BOUNCED ADDRESSES ==="
$allBounced | Select-Object -Unique | ForEach-Object { Write-Host $_ }

Disconnect-MgGraph | Out-Null
