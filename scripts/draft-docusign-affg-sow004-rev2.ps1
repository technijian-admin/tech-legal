# Create the AFFG SOW-004 Rev 1 signing email as a DRAFT in Ravi's Outlook drafts folder
# Reads state from stage 1 (prepare-docusign-affg-sow004-rev2.ps1).
# Ravi reviews + sends manually from Outlook.

$ErrorActionPreference = "Stop"
$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$statePath  = Join-Path $scriptDir "affg-sow004-rev2-state.json"
if (-not (Test-Path $statePath)) { Write-Error "State file missing: $statePath. Run stage 1 first."; exit 1 }

$state = Get-Content $statePath -Raw | ConvertFrom-Json
$clientHtml = Get-Content $state.clientHtmlFile -Raw
$techHtml   = Get-Content $state.techHtmlFile   -Raw

# --- M365 credentials ---
$m365KeysFile = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md"
$m365Keys     = Get-Content $m365KeysFile -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(.+)').Groups[1].Value.Trim()

$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome

$senderUpn = "RJain@technijian.com"

# --- Draft: Iris (client) ---
$clientDraft = New-MgUserMessage -UserId $senderUpn -BodyParameter @{
    Subject = $state.emailSubject
    Body = @{ ContentType = "HTML"; Content = $clientHtml }
    ToRecipients = @( @{ EmailAddress = @{ Address = $state.clientEmail; Name = $state.clientName } } )
}
Write-Host "Client draft created in Outlook Drafts: $($clientDraft.Id)" -ForegroundColor Green

# --- Draft: Ravi's own copy (so he has his signing link) ---
$techDraft = New-MgUserMessage -UserId $senderUpn -BodyParameter @{
    Subject = "$($state.emailSubject) (your signing copy)"
    Body = @{ ContentType = "HTML"; Content = $techHtml }
    ToRecipients = @( @{ EmailAddress = @{ Address = $state.signerEmail; Name = $state.signerName } } )
}
Write-Host "Technijian draft created in Outlook Drafts: $($techDraft.Id)" -ForegroundColor Green

Disconnect-MgGraph | Out-Null

# --- Save draft ids for reference ---
$draftIdsPath = Join-Path $scriptDir "affg-sow004-rev2-draft-ids.txt"
@"
ClientDraftId : $($clientDraft.Id)
TechDraftId   : $($techDraft.Id)
"@ | Set-Content -Path $draftIdsPath -Encoding UTF8

Write-Host ""
Write-Host "================ DRAFTS READY ================" -ForegroundColor Yellow
Write-Host "Open Outlook -> Drafts folder to review:" -ForegroundColor White
Write-Host "  1. To $($state.clientName) <$($state.clientEmail)>  -- review this one, then send manually" -ForegroundColor White
Write-Host "  2. To $($state.signerName) <$($state.signerEmail)>  -- your own signing copy" -ForegroundColor White
Write-Host ""
Write-Host "DocuSign envelope $($state.envelopeId) is already active; Iris has received nothing yet." -ForegroundColor Gray
