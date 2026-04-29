$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$senderUpn = "RJain@technijian.com"
$draftId   = "AAMkAGNlYjM0OTA4LThjMjYtNGQ3My1iNDg1LTQ2MTI5NTg0NzFlOQBGAAAAAAC88IffM67WS4tSyVwwqYmJBwBhk-ls8ubYRazD3tGgncxCAAAAAAEQAACgx7VhNWW1QYCgfGa-8kbOAAX693XBAAA="

$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$cid = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
$cred = New-Object System.Management.Automation.PSCredential($cid, (ConvertTo-SecureString $sec -AsPlainText -Force))
Connect-MgGraph -TenantId $tid -ClientSecretCredential $cred -NoWelcome | Out-Null

# Fetch current draft body
$getUri = "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$draftId" + "?`$select=body"
$draft  = Invoke-MgGraphRequest -Method GET -Uri $getUri
$html   = $draft.body.content

# Load branded signature
$raviSig = Get-Content "c:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html" -Raw -Encoding UTF8

# ---- Fix 1: Replace Section 2 using regex to handle em-dash/hyphen variants ----
# Find from the Section 2 h3 opening to just before the Section 3 h3
$sec2Start = '<h3>2. Local/Onsite'
$sec3Start = '<h3>3. Fixed-Price'

$idxStart = $html.IndexOf($sec2Start)
$idxEnd   = $html.IndexOf($sec3Start)

if ($idxStart -lt 0) {
    Write-Host "Section 2 start anchor not found. Checking for 'Local/Onsite'..." -ForegroundColor Red
    $idx = $html.IndexOf("Local/Onsite")
    if ($idx -ge 0) {
        Write-Host "  Found 'Local/Onsite' at $idx. Surrounding context:" -ForegroundColor Yellow
        Write-Host $html.Substring([Math]::Max(0,$idx-30), [Math]::Min(250, $html.Length-$idx))
    }
    Disconnect-MgGraph | Out-Null
    exit 1
}
if ($idxEnd -lt 0) {
    Write-Host "Section 3 anchor '<h3>3. Fixed-Price' not found — trying alternate" -ForegroundColor Yellow
    $sec3Start = '<h3>3.'
    $idxEnd = $html.IndexOf($sec3Start)
}
if ($idxEnd -lt 0 -or $idxEnd -le $idxStart) {
    Write-Host "Cannot find Section 3 boundary — cannot safely replace" -ForegroundColor Red
    Disconnect-MgGraph | Out-Null
    exit 1
}

$newSec2 = '<h3>2. US Remote Support (IRV-TS1 team) &mdash; per-hour billing at the prior-period average rate</h3><p>The second contracted category is our US-based support team (IRV-TS1). Like the offshore team, all hours are billed per hour at $150. The key to understand is the billing mechanism in the MSA: the number of hours billed each cycle is based on the <em>average hours from the prior contract period</em> &mdash; not on actual hours in the current period. We track actual hours in each period, compute the monthly average, and apply that average as the billed quantity for the following period.</p><p>This means the hours billed in any given period will naturally differ from hours actually worked. That difference is the intended operation of the averaging mechanism &mdash; it is not an over-billing and does not create a credit owed to Vintage.</p><ul><li>Total hours <strong>worked</strong> under the monthly contract: <strong>497.82 hrs</strong></li><li>Total hours <strong>billed</strong> under the contract (prior-period average applied): <strong>540 hrs</strong></li><li>The gap between 497.82 and 540 hrs reflects the averaging mechanism at work. Vintage contracted to be billed at the prior period&rsquo;s average; those are the hours they owe.</li></ul><p>The deduction for US remote support hours in the damages spreadsheet should be zero. Vintage has no credit for periods where actual hours fell below the prior-period average &mdash; that is exactly what the averaging model anticipates.</p>'

$before = $html.Substring(0, $idxStart)
$after  = $html.Substring($idxEnd)
$html   = $before + $newSec2 + $after
Write-Host "Fix 1 (Section 2 corrected): applied ($idxStart to $idxEnd)" -ForegroundColor Green

# ---- Fix 2: Check whether branded signature is already present; if plain text remains, replace it ----
$plainSig = 'Ravi Jain<br>CEO, Technijian<br>T: 949.379.8499 x201'
if ($html.Contains($plainSig)) {
    # Find the enclosing <p> ... </p> to remove it cleanly
    $pStart = $html.LastIndexOf('<p>', $html.IndexOf($plainSig))
    $pEnd   = $html.IndexOf('</p>', $html.IndexOf($plainSig)) + 4  # +4 for </p>
    if ($pStart -ge 0 -and $pEnd -gt $pStart) {
        $html = $html.Substring(0, $pStart) + $raviSig + $html.Substring($pEnd)
        Write-Host "Fix 2 (branded signature): applied" -ForegroundColor Green
    } else {
        Write-Host "Fix 2: could not find enclosing <p> for plain-text signature" -ForegroundColor Yellow
    }
} else {
    Write-Host "Fix 2: plain-text signature not found (may already be patched)" -ForegroundColor Yellow
}

# -- Proofread: guard against stripped dollar signs --
if ($html -match '[\s>](\,\d{3})') {
    Write-Error "BLOCKED: Stripped dollar sign detected: '$($Matches[1])'. Fix dollar escaping."
    Disconnect-MgGraph | Out-Null
    exit 1
}

# PATCH the draft
$patchBody = @{ body = @{ contentType = "HTML"; content = $html } } | ConvertTo-Json -Depth 5
Invoke-MgGraphRequest -Method PATCH `
    -Uri "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$draftId" `
    -Body $patchBody `
    -Headers @{ "Content-Type" = "application/json" } | Out-Null

Write-Host "Draft patched successfully." -ForegroundColor Cyan

Disconnect-MgGraph | Out-Null
