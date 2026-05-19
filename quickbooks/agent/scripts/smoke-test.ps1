<#
.SYNOPSIS
    qb-accountant agent smoke test — validates every layer the agent needs.

.DESCRIPTION
    Runs 8 checks; prints pass/fail and a remediation hint on failure.
    All 8 must pass before installing the scheduled tasks. Exit code 0 on
    full pass, 1 on any failure.

    Run from any directory:
        pwsh -NoProfile -File c:\vscode\tech-legal\tech-legal\quickbooks\agent\scripts\smoke-test.ps1

.PARAMETER RepoRoot
    Repo root. Default: c:\vscode\tech-legal\tech-legal
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = 'c:\vscode\tech-legal\tech-legal'
)

$ErrorActionPreference = 'Continue'
$failures = 0
$envPath    = Join-Path $RepoRoot 'quickbooks\clients\.env'
$configPath = Join-Path $RepoRoot 'quickbooks\agent\state\config.json'

function Pass($msg) { Write-Host ('[PASS] ' + $msg) -ForegroundColor Green }
function Fail($msg, $hint = '') {
    Write-Host ('[FAIL] ' + $msg) -ForegroundColor Red
    if ($hint) { Write-Host ('       Hint: ' + $hint) -ForegroundColor Yellow }
    $script:failures++
}

Write-Host ''
Write-Host ('=' * 70) -ForegroundColor Cyan
Write-Host ' qb-accountant smoke test' -ForegroundColor Cyan
Write-Host ('=' * 70) -ForegroundColor Cyan
Write-Host ''

# --- 1. PowerShell 7+ ---
if ($PSVersionTable.PSVersion.Major -ge 7) {
    Pass ('PowerShell ' + $PSVersionTable.PSVersion + ' (pwsh)')
} else {
    Fail ('PowerShell ' + $PSVersionTable.PSVersion + ' is too old') 'Install pwsh: `winget install Microsoft.PowerShell`'
}

# --- 2. Python 3.10+ ---
try {
    $py = & python --version 2>&1
    if ($py -match 'Python (\d+)\.(\d+)') {
        $maj = [int]$Matches[1]; $min = [int]$Matches[2]
        if ($maj -ge 3 -and $min -ge 10) {
            Pass ("Python $maj.$min")
        } else {
            Fail "Python $maj.$min is too old" 'Need 3.10+. `winget install Python.Python.3.12`'
        }
    } else {
        Fail "Could not parse Python version: $py" 'Verify python is on PATH'
    }
} catch {
    Fail 'python not on PATH' 'Install Python 3.10+ and add to PATH'
}

# --- 3. claude CLI on PATH ---
$claude = Get-Command claude -ErrorAction SilentlyContinue
if ($claude) {
    Pass ('claude CLI: ' + $claude.Source)
} else {
    Fail 'claude CLI not on PATH' 'Install Claude Code; ensure on PATH for the user the scheduled tasks will run as'
}

# --- 4. .env file exists + complete ---
if (Test-Path $envPath) {
    $envText = Get-Content $envPath -Raw
    $required = @('QB_API_BASE_URL', 'QB_API_TOKEN', 'QB_VERIFY_TLS', 'QB_DEFAULT_COMPANY')
    $missing = $required | Where-Object { $envText -notmatch ('^' + [regex]::Escape($_) + '=') }
    if ($missing.Count -eq 0) {
        Pass (".env exists with all required keys ($envPath)")
    } else {
        Fail (".env is missing keys: $($missing -join ', ')") 'Edit .env to add missing keys (see .env.sample)'
    }
    # Also flag if the token is still a placeholder
    if ($envText -match 'QB_API_TOKEN=REPLACE-WITH') {
        Fail '.env still has placeholder QB_API_TOKEN' 'Copy the real bearer token from D:\QbConnectService\INSTALL-RESULT.txt on the QB host'
    }
} else {
    Fail ".env not found at $envPath" 'Copy .env.sample to .env and fill in values'
}

# --- 5. agent config.json ---
if (Test-Path $configPath) {
    try {
        $null = Get-Content $configPath -Raw | ConvertFrom-Json
        Pass ("Agent config.json exists and parses ($configPath)")
    } catch {
        Fail "config.json exists but doesn't parse as JSON" 'Fix syntax errors or re-copy from config.json.sample'
    }
} else {
    Fail "Agent config.json not found at $configPath" 'cd into agent\state and: Copy-Item config.json.sample config.json'
}

# --- 6. TCP reachable to QB service ---
try {
    $envText = if (Test-Path $envPath) { Get-Content $envPath -Raw } else { '' }
    $baseUrlMatch = [regex]::Match($envText, 'QB_API_BASE_URL=(\S+)')
    if ($baseUrlMatch.Success) {
        $u = [Uri]$baseUrlMatch.Groups[1].Value
        $reach = Test-NetConnection -ComputerName $u.Host -Port $u.Port -InformationLevel Quiet -WarningAction SilentlyContinue
        if ($reach) {
            Pass ("TCP $($u.Host):$($u.Port) reachable")
        } else {
            Fail "Cannot reach $($u.Host):$($u.Port)" 'Check firewall, VPN, QbConnectService running on host'
        }
    } else {
        Fail 'QB_API_BASE_URL missing from .env' 'See check 4'
    }
} catch {
    Fail "Network test errored: $($_.Exception.Message)" 'Check Test-NetConnection availability'
}

# --- 7. /api/health returns healthy ---
try {
    Push-Location (Join-Path $RepoRoot 'quickbooks\clients')
    $healthJson = python -c "from qb_client import QbClient; import json; print(json.dumps(QbClient.from_env().health()))" 2>&1
    Pop-Location
    if ($LASTEXITCODE -eq 0) {
        $health = $healthJson | ConvertFrom-Json
        if ($health.status -in 'healthy', 'degraded') {
            Pass ("Service /api/health status=$($health.status) connection=$($health.connectionState) companyFile=$($health.companyFile)")
        } else {
            Fail "Service /api/health status=$($health.status)" "lastError: $($health.lastError | ConvertTo-Json)"
        }
    } else {
        Fail "Python client call failed: $healthJson" 'Check Python deps installed (pip install -r requirements.txt) and .env'
    }
} catch {
    Fail "Health check errored: $($_.Exception.Message)"
}

# --- 8. Multi-tenant routing works ---
try {
    Push-Location (Join-Path $RepoRoot 'quickbooks\clients')
    $infoJson = python -c "from qb_client import QbClient; import json; print(json.dumps(QbClient.from_env().op('company_info')))" 2>&1
    Pop-Location
    if ($LASTEXITCODE -eq 0) {
        $info = $infoJson | ConvertFrom-Json
        Pass ("Multi-tenant company_info: '$($info.companyName)' (legal: '$($info.legalCompanyName)')")
    } else {
        Fail "company_info call failed: $infoJson" 'Check QB Desktop is running; integrated app authorized'
    }
} catch {
    Fail "company_info errored: $($_.Exception.Message)"
}

# --- Summary ---
Write-Host ''
Write-Host ('=' * 70) -ForegroundColor Cyan
if ($failures -eq 0) {
    Write-Host ' ALL 8 CHECKS PASSED — safe to install scheduled tasks' -ForegroundColor Green
    Write-Host ('=' * 70) -ForegroundColor Cyan
    Write-Host ''
    Write-Host 'Next:'
    Write-Host "  cd $RepoRoot\quickbooks\agent\scripts"
    Write-Host '  .\install-tasks.ps1'
    exit 0
} else {
    Write-Host (' ' + $failures + ' CHECK(S) FAILED — fix before installing tasks') -ForegroundColor Red
    Write-Host ('=' * 70) -ForegroundColor Cyan
    exit 1
}
