# Pull specific emails as .eml by internetMessageId from Ravi's mailbox.
$ErrorActionPreference = "Stop"
$userId = "RJain@technijian.com"
$outDir = "C:\vscode\tech-legal\tech-legal\terminated-clients\BST\send_package_2026-04-17"

$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$cid = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
$cred = New-Object System.Management.Automation.PSCredential($cid, (ConvertTo-SecureString $sec -AsPlainText -Force))
Connect-MgGraph -TenantId $tid -ClientSecretCredential $cred -NoWelcome

$targets = @(
    @{ mid = '<DS1PR13MB6997170A88BBF4C635DE3740DA5EA@DS1PR13MB6997.namprd13.prod.outlook.com>'; out = '2026-04-03_Access_Update_Transition.eml' },
    @{ mid = '<DS1PR13MB6997AFEB465E67780E464A0EDA582@DS1PR13MB6997.namprd13.prod.outlook.com>'; out = '2026-04-09_Account_Closeout_Counsel_Review.eml' },
    @{ mid = '<IA3PR13MB70016080821B74A7128ABD84DA252@IA3PR13MB7001.namprd13.prod.outlook.com>'; out = '2026-04-14_Time-Sensitive_Closeout.eml' },
    @{ mid = '<IA3PR13MB700153BF26A313E21E003A2DDA222@IA3PR13MB7001.namprd13.prod.outlook.com>'; out = '2026-04-15_VPN_Support_Access_Limitations.eml' }
)

foreach ($t in $targets) {
    # Find the message by internetMessageId
    $filter = [uri]::EscapeDataString("internetMessageId eq '" + $t.mid + "'")
    $findUri = "https://graph.microsoft.com/v1.0/users/$userId/messages?`$filter=$filter&`$select=id,subject,sentDateTime"
    $resp = Invoke-MgGraphRequest -Method GET -Uri $findUri
    if (-not $resp.value -or $resp.value.Count -eq 0) {
        Write-Host "NOT FOUND: $($t.mid)" -ForegroundColor Red
        continue
    }
    $msg = $resp.value[0]
    Write-Host ("Match: [{0}] {1}" -f $msg.sentDateTime, $msg.subject)

    $emlUri = "https://graph.microsoft.com/v1.0/users/$userId/messages/$($msg.id)/`$value"
    $outPath = Join-Path $outDir $t.out
    Invoke-MgGraphRequest -Method GET -Uri $emlUri -OutputFilePath $outPath
    if (Test-Path $outPath) {
        Write-Host ("  saved: {0} ({1:N0} bytes)" -f $t.out, (Get-Item $outPath).Length) -ForegroundColor Green
    }
}

Disconnect-MgGraph | Out-Null
