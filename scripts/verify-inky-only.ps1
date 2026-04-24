# Verify campaign drafts state, dedupe, spot-check bodies. No send.
$ErrorActionPreference = 'Stop'
$senderUpn = "RJain@technijian.com"

$m365Keys     = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome

# Find campaign drafts
$allDrafts = Get-MgUserMessage -UserId $senderUpn -Filter "isDraft eq true" -Top 200 -Property "id,subject,toRecipients,hasAttachments,createdDateTime" -OrderBy "createdDateTime desc"
$campaignDrafts = $allDrafts | Where-Object {
    $_.Subject -match "Technijian My AntiSpam" -or
    $_.Subject -match "Attorney-client privilege" -or
    $_.Subject -match "CMMC email-security"
}
Write-Host "Campaign drafts found: $($campaignDrafts.Count) (out of $($allDrafts.Count) total drafts)"

# Dedupe by recipient (keep newest)
$byRecipient = @{}
foreach ($d in $campaignDrafts) {
    $to = ($d.ToRecipients | Select-Object -First 1).EmailAddress.Address.ToLower()
    if (-not $byRecipient.ContainsKey($to)) { $byRecipient[$to] = @() }
    $byRecipient[$to] += $d
}
$dupesDeleted = 0
foreach ($to in $byRecipient.Keys) {
    $list = $byRecipient[$to] | Sort-Object CreatedDateTime -Descending
    if ($list.Count -gt 1) {
        Write-Host "  $to : $($list.Count) drafts -> keeping newest, deleting $($list.Count - 1)"
        for ($i = 1; $i -lt $list.Count; $i++) {
            Remove-MgUserMessage -UserId $senderUpn -MessageId $list[$i].Id
            $dupesDeleted++
        }
    }
}
Write-Host "Duplicates deleted: $dupesDeleted"
Write-Host ""

# Refresh and proofread
$finalDrafts = Get-MgUserMessage -UserId $senderUpn -Filter "isDraft eq true" -Top 200 -Property "id,subject,toRecipients,hasAttachments"
$finalCampaign = $finalDrafts | Where-Object {
    $_.Subject -match "Technijian My AntiSpam" -or
    $_.Subject -match "Attorney-client privilege" -or
    $_.Subject -match "CMMC email-security"
}
Write-Host "Final campaign draft count: $($finalCampaign.Count)"
Write-Host ""

# Spot-check one per template
$samples = @(
    @{ pattern = "Acuity Advisors";              template = "existing" }
    @{ pattern = "Protect Andersen Industries";  template = "base" }
    @{ pattern = "American Fundstars";           template = "financial" }
    @{ pattern = "Saddleback Valley Endodontic"; template = "healthcare" }
    @{ pattern = "Chris Bank Law";               template = "legal" }
    @{ pattern = "Adsys Controls";               template = "defense" }
    @{ pattern = "Alera Group";                  template = "insurance" }
)

Write-Host "=== Proofread spot-check ==="
$allOk = $true
$results = @()
foreach ($s in $samples) {
    $match = $finalCampaign | Where-Object { $_.Subject -match [regex]::Escape($s.pattern) } | Select-Object -First 1
    if ($null -eq $match) {
        Write-Host "  MISSING: $($s.template) / $($s.pattern)" -ForegroundColor Red
        $allOk = $false
        continue
    }
    $full = Get-MgUserMessage -UserId $senderUpn -MessageId $match.Id -Property "id,subject,body,toRecipients,hasAttachments"
    $body = $full.Body.Content
    $bodyLen = $body.Length
    $hasDupe = ($body -match 'Thanks,<br\s*/?>\s*Ravi' -or $body -match 'Thanks, and stay safe')
    $hasAttach = $full.HasAttachments
    $unmerged = [regex]::Matches($body, '\[[A-Za-z][A-Za-z ]+\]') | Where-Object { $_.Value -ne '[object Object]' }
    $to = ($full.ToRecipients | Select-Object -First 1).EmailAddress.Address
    $status = "OK"
    if ($hasDupe) { $status = "FAIL: Thanks-Ravi dupe"; $allOk = $false }
    if (-not $hasAttach) { $status = "FAIL: no attachment"; $allOk = $false }
    if ($unmerged.Count -gt 0) { $status = "FAIL: unmerged $($unmerged | ForEach-Object { $_.Value })"; $allOk = $false }
    Write-Host ("  {0,-11} {1,-44} attach={2} body={3}KB -- {4}" -f $s.template, $to, $hasAttach, [math]::Round($bodyLen/1KB,1), $status)
}
Write-Host ""
if ($allOk -and $finalCampaign.Count -eq 55) {
    Write-Host "ALL CHECKS PASSED. Ready to send 55 emails." -ForegroundColor Green
} else {
    Write-Host "CHECKS FAILED OR COUNT MISMATCH (got $($finalCampaign.Count), expected 55)." -ForegroundColor Red
}

Disconnect-MgGraph | Out-Null
