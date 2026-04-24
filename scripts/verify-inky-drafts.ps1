# Verify the two sample drafts rendered correctly
$senderUpn = "RJain@technijian.com"

$m365Keys     = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome

$drafts = Get-MgUserMessage -UserId $senderUpn -Filter "isDraft eq true" -Top 5 -Property "id,subject,bodyPreview,body,toRecipients" -OrderBy "createdDateTime desc"

foreach ($d in $drafts) {
    if ($d.Subject -match "My AntiSpam") {
        $to = ($d.ToRecipients | ForEach-Object { $_.EmailAddress.Address }) -join ', '
        Write-Host ""
        Write-Host "=== $($d.Subject) ==="
        Write-Host "To: $to"
        $content = $d.Body.Content
        # Check for unmerged tokens
        $tokens = [regex]::Matches($content, '\[[A-Za-z ]+\]')
        if ($tokens.Count -gt 0) {
            Write-Host "WARNING: unmerged tokens found:"
            $tokens | ForEach-Object { Write-Host "   $($_.Value)" }
        } else {
            Write-Host "OK: no unmerged [tokens]"
        }
        # Check for broken dollar-escape (should not have `$ visible in body)
        if ($content -match '`\$') {
            Write-Host "WARNING: backtick-dollar found in body (escape did not resolve)"
        } else {
            Write-Host "OK: dollar signs rendered correctly"
        }
        # Check for specific expected content
        if ($content -match '\$4\.75') { Write-Host "OK: pricing `$4.75 present" }
        if ($content -match '\$4\.25') { Write-Host "OK: legacy `$4.25 present (existing-cust draft)" }
        if ($content -match 'Monday, May 5') { Write-Host "OK: May 5 date pinned" }
        # First paragraph preview
        Write-Host ""
        Write-Host "First 500 chars of body:"
        Write-Host $content.Substring(0, [Math]::Min(500, $content.Length))
    }
}

Disconnect-MgGraph | Out-Null
