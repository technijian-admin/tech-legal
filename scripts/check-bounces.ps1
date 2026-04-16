# Check inbox for bounce-back / undeliverable emails
$m365Keys     = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome

$since = (Get-Date).AddMinutes(-60).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$msgs = Get-MgUserMessage -UserId "RJain@technijian.com" -Filter "receivedDateTime ge $since" -Property "id,from,subject,receivedDateTime,isRead,body" -Top 50 -OrderBy "receivedDateTime desc"

Write-Host "=== Messages received in last 60 minutes ==="
Write-Host "Count: $($msgs.Count)"
Write-Host ""

foreach ($m in $msgs) {
    $subj = $m.Subject
    $from = $m.From.EmailAddress.Address
    $dt   = $m.ReceivedDateTime
    Write-Host "[$dt] FROM: $from"
    Write-Host "  SUBJ: $subj"

    # Check if it's a bounce
    $isBounce = $false
    if ($subj -match "Undeliverable|Delivery.*Failed|Delivery.*Status|Mail Delivery|returned|bounce|NDR|could not be delivered") {
        $isBounce = $true
    }
    if ($from -match "postmaster|mailer-daemon|MAILER-DAEMON") {
        $isBounce = $true
    }

    if ($isBounce) {
        Write-Host "  >>> BOUNCE DETECTED <<<"
        # Try to extract the failed address from body
        $bodyText = $m.Body.Content
        $matches = [regex]::Matches($bodyText, '[\w.+-]+@[\w.-]+\.\w{2,}')
        $failedAddrs = @()
        foreach ($match in $matches) {
            $addr = $match.Value.ToLower()
            if ($addr -ne "rjain@technijian.com" -and $addr -ne "postmaster@" -and $addr -notmatch "technijian") {
                $failedAddrs += $addr
            }
        }
        $unique = $failedAddrs | Select-Object -Unique
        Write-Host "  Failed addresses: $($unique -join ', ')"
    }
    Write-Host ""
}

Disconnect-MgGraph | Out-Null
