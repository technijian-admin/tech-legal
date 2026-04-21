# Wrapper invoked by Windows Task Scheduler at Monday April 20, 2026 7:00am PT.
# 1. Cleans up any existing "Re: FORMAL DEMAND - Solar System*" drafts
# 2. Runs send-sunrun-reply-katherine.ps1 -Send to create + immediately send a fresh
#    draft with the latest body content
# 3. Logs to scheduled-send-sunrun-monday.log

$ErrorActionPreference = "Stop"
$logPath = "c:\VSCode\tech-legal\tech-legal\scripts\scheduled-send-sunrun-monday.log"
function Log($msg) {
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg"
    Add-Content -Path $logPath -Value $line
    Write-Host $line
}

try {
    Log "=== Scheduled send started ==="

    # Auth
    $m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
    $cid = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
    $tid = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
    $sec = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
    $ss  = ConvertTo-SecureString $sec -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential($cid, $ss)
    Connect-MgGraph -TenantId $tid -ClientSecretCredential $cred -NoWelcome
    Log "Connected to Graph"

    # Step 1: Clean up any existing matching drafts
    $senderUpn = "RJain@technijian.com"
    $listUri = "https://graph.microsoft.com/v1.0/users/$senderUpn/mailFolders/drafts/messages?`$top=20&`$select=id,subject,createdDateTime"
    $resp = Invoke-MgGraphRequest -Method GET -Uri $listUri
    $matchingDrafts = $resp.value | Where-Object { $_.subject -like "Re: FORMAL DEMAND - Solar System*" }
    Log "Found $($matchingDrafts.Count) existing draft(s) to clean up"
    foreach ($d in $matchingDrafts) {
        Invoke-MgGraphRequest -Method DELETE -Uri "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$($d.id)" | Out-Null
        Log "  Deleted: $($d.subject) [$($d.id)]"
    }

    Disconnect-MgGraph | Out-Null

    # Step 2: Run the main script with -Send (creates fresh draft + sends immediately)
    Log "Invoking send-sunrun-reply-katherine.ps1 -Send"
    & powershell.exe -ExecutionPolicy Bypass -File "c:\VSCode\tech-legal\tech-legal\scripts\send-sunrun-reply-katherine.ps1" -Send 2>&1 | ForEach-Object { Log "  $_" }

    Log "=== Scheduled send complete ==="
}
catch {
    Log "ERROR: $_"
    Log $_.ScriptStackTrace
    exit 1
}
