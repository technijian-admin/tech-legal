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

# ---- Fix 1: Replace incorrect Section 2 ----
# The old version called IRV-TS1 "local/onsite" and described billing as a "flat rate."
# Neither is correct. All work is per-hour. The billed quantity for each cycle is based on
# the prior period's average, not a fixed monthly amount.
$oldSec2 = '<h3>2. Local/Onsite Tech Support (Southern California team) - flat-rate monthly billing</h3><p>Our local Irvine-based engineers (IRV-TS1 team) provided onsite and remote support billed at a flat rate of 20 hours per month under the same monthly contract. This is a contracted flat rate - not a time-and-materials measurement. Some months they logged more than 20 hours, some months less. That is the nature of a flat-rate service level.</p><ul><li>Total hours <strong>worked</strong> on local support under the monthly contract: <strong>497.82 hrs</strong></li><li>Total hours <strong>billed</strong> at the flat rate: <strong>540 hrs</strong> (27 months x 20 hrs)</li><li>The 42-hour difference is a function of the flat-rate model - months with heavy demand (July, August, October 2023) offset months with light demand. This is not an over-billing; it is how a fixed monthly rate works by design.</li></ul><p>Accordingly, I do not believe the local support billing creates a credit owed to Vintage. The contract established a flat monthly rate for local coverage - Vintage agreed to pay 20 hours of local support capacity each month, not 20 hours of actual ticket time.</p>'

$newSec2 = '<h3>2. US Remote Support (IRV-TS1 team) &mdash; per-hour billing at the prior-period average rate</h3><p>The second contracted category is our US-based support team (IRV-TS1). Like the offshore team, all hours are billed per hour at $150. The key to understand here is the billing mechanism in the MSA: the number of hours billed each cycle is based on the <em>average hours from the prior contract period</em> &mdash; not on actual hours in the current period. We track actual hours in each period, compute the monthly average, and apply that average as the billed quantity for the following period.</p><p>This means the hours billed in any given period will naturally differ from hours actually worked. That difference is the intended operation of the averaging mechanism &mdash; it is not an over-billing and it does not create a credit owed to Vintage.</p><ul><li>Total hours <strong>worked</strong> under the monthly contract: <strong>497.82 hrs</strong></li><li>Total hours <strong>billed</strong> under the contract (prior-period average applied): <strong>540 hrs</strong></li><li>The difference between 497.82 and 540 hrs reflects the averaging mechanism at work. Vintage contracted to be billed at the prior period&rsquo;s average; those are the hours they owe.</li></ul><p>The deduction for US remote support in the damages spreadsheet should be zero. There is no credit due to Vintage for periods where actual hours came in below the prior-period average &mdash; that is exactly what the averaging model anticipates and prices in.</p>'

if ($html.Contains($oldSec2)) {
    $html = $html.Replace($oldSec2, $newSec2)
    Write-Host "Fix 1 (Section 2 - contracted hours corrected): applied" -ForegroundColor Green
} else {
    Write-Host "Fix 1: anchor not found" -ForegroundColor Red
    $idx = $html.IndexOf("Local/Onsite")
    if ($idx -ge 0) {
        Write-Host "  'Local/Onsite' found at index $idx" -ForegroundColor Yellow
        Write-Host $html.Substring($idx, [Math]::Min(200,$html.Length-$idx)) -ForegroundColor Yellow
    } else {
        Write-Host "  'Local/Onsite' not found in draft HTML either" -ForegroundColor Red
    }
}

# ---- Fix 2: Replace plain-text closing signature with branded HTML signature ----
$oldSig = '<p>Thank you,<br>Ravi Jain<br>CEO, Technijian<br>T: 949.379.8499 x201</p>'

if ($html.Contains($oldSig)) {
    $html = $html.Replace($oldSig, $raviSig)
    Write-Host "Fix 2 (branded signature): applied" -ForegroundColor Green
} else {
    Write-Host "Fix 2: plain-text signature anchor not found" -ForegroundColor Yellow
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
