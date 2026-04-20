# Called by Windows Task Scheduler — sends the BST Jeff follow-up draft at scheduled time.
# Reads MessageId from bst-jeff-draft-id.txt; logs result to bst-jeff-scheduled-send.log

$ErrorActionPreference = "Stop"

$senderUpn = "RJain@technijian.com"
$idFile    = "C:\vscode\tech-legal\tech-legal\scripts\bst-jeff-draft-id.txt"
$logFile   = "C:\vscode\tech-legal\tech-legal\scripts\bst-jeff-scheduled-send.log"

function Log($msg) {
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $msg"
    Add-Content -Path $logFile -Value $line -Encoding UTF8
    Write-Host $line
}

Log "--- BST Jeff scheduled send starting ---"

if (-not (Test-Path $idFile)) {
    Log "ERROR: Draft ID file not found: $idFile"
    exit 1
}
$draftId = (Get-Content $idFile -Raw).Trim()
if (-not $draftId) {
    Log "ERROR: Draft ID file is empty."
    exit 1
}
Log "Draft MessageId: $draftId"

# --- Credentials ---
$m365Keys     = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $m365ClientId -or -not $m365TenantId -or -not $m365Secret) {
    Log "ERROR: Failed to parse M365 credentials."
    exit 1
}

# --- Connect ---
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome
Log "Connected to Graph."

# --- Send ---
Send-MgUserMessage -UserId $senderUpn -MessageId $draftId
Log "SENT. MessageId=$draftId"

# Clean up draft ID file after successful send
Remove-Item $idFile -Force
Log "Draft ID file removed. Done."

Disconnect-MgGraph | Out-Null
