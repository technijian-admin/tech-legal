$ErrorActionPreference = "Stop"
$senderUpn = "RJain@technijian.com"
$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$cid = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
$cred = New-Object System.Management.Automation.PSCredential($cid, (ConvertTo-SecureString $sec -AsPlainText -Force))
Connect-MgGraph -TenantId $tid -ClientSecretCredential $cred -NoWelcome | Out-Null
$uri = "https://graph.microsoft.com/v1.0/users/$senderUpn/mailFolders/Drafts/messages?`$top=10&`$orderby=lastModifiedDateTime desc&`$select=id,subject,lastModifiedDateTime"
$drafts = Invoke-MgGraphRequest -Method GET -Uri $uri
foreach ($m in $drafts.value) {
    Write-Host "$($m.lastModifiedDateTime)  |  $($m.subject)"
    Write-Host "  ID: $($m.id)"
    Write-Host ""
}
Disconnect-MgGraph | Out-Null
