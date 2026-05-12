#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Hand a GSD phase PLAN.md to Codex CLI to implement on the current git branch.

.DESCRIPTION
    Part of the multi-LLM build pipeline for the QuickBooks Direct-SDK Integration
    (see quickbooks/dev/MULTI-LLM.md). Claude plans (/gsd:plan-phase N), Codex executes,
    Claude reviews. This script is the plan->execute handoff.

    Bootstrap version. Phase 8 (DEV-02) hardens it. Intentionally small so it's easy to
    tweak for whatever `codex exec` flags your installed codex-cli version uses
    (run `codex exec --help` and adjust $codexArgs below).

.PARAMETER Phase
    Phase number, e.g. 1. Looks for .planning/phases/phase-<N>/PLAN.md (also tries a
    zero-padded "phase-01" form).

.PARAMETER DryRun
    Print the codex command + the assembled prompt; don't invoke codex.

.PARAMETER ExtraInstructions
    Optional extra text appended to the prompt (e.g. "skip task 3, it's done").

.EXAMPLE
    pwsh quickbooks/dev/run-codex-phase.ps1 -Phase 1
.EXAMPLE
    pwsh quickbooks/dev/run-codex-phase.ps1 -Phase 1 -DryRun
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][int]$Phase,
    [switch]$DryRun,
    [string]$ExtraInstructions = ""
)

$ErrorActionPreference = "Stop"

# --- locate repo root (this script lives at <repo>/quickbooks/dev/) ---
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Push-Location $repoRoot
try {
    # --- sanity: git branch ---
    $branch = (git rev-parse --abbrev-ref HEAD).Trim()
    $expected = "quickbooks/direct-sdk-integration-2026-05-11"
    if ($branch -ne $expected) {
        throw "On branch '$branch' but expected '$expected'. Switch branches before running Codex (and beware: this repo has unrelated active work)."
    }

    # --- locate PLAN.md ---
    $candidates = @(
        (Join-Path $repoRoot ".planning\phases\phase-$Phase\PLAN.md"),
        (Join-Path $repoRoot (".planning\phases\phase-{0:D2}\PLAN.md" -f $Phase))
    )
    $planPath = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $planPath) {
        throw "No PLAN.md for phase $Phase. Looked in:`n  $($candidates -join "`n  ")`nRun `/gsd:plan-phase $Phase` first."
    }
    $planText = Get-Content -Raw -LiteralPath $planPath

    # --- assemble the prompt for Codex ---
    $guardrails = @'
You are the EXECUTOR in a multi-LLM pipeline. A GSD phase plan follows. Implement it exactly.

HARD RULES (this repo also contains unrelated active work — violating these corrupts someone else's work):
- Stay on the current git branch. NEVER `git checkout` another branch. NEVER `git reset --hard`. NEVER touch `main`.
- NEVER `git add -A` or `git add .`. Stage ONLY the specific files your current task creates or edits.
- Only create/modify files under `quickbooks/`, `.claude/skills/quickbooks-accounting/`, and `.planning/phases/` (plus the phase plan's checklist). Nothing else.
- Make ONE atomic git commit per task in the plan, with a clear message. Do not squash all tasks into one commit.
- For each task: implement it, then run the tests the plan specifies (and any existing test suite), and make them pass before committing. If a task is blocked or a test can't pass, STOP, commit what's safely done, and report the blocker — do not hack around it.
- After all tasks: update the phase plan's task checkboxes, run the full test suite once more, and report a summary (commits made, tests status, anything deferred).

=== GSD PHASE PLAN ===
'@
    $prompt = $guardrails + "`n" + $planText
    if ($ExtraInstructions.Trim()) {
        $prompt += "`n`n=== EXTRA INSTRUCTIONS FROM ORCHESTRATOR ===`n" + $ExtraInstructions
    }

    # --- codex invocation ---
    # NOTE: adjust these flags to match your installed codex-cli (`codex exec --help`).
    # --full-auto runs without per-action approval; -C sets the working dir.
    $codexArgs = @("exec", "--full-auto", "-C", "$repoRoot", $prompt)

    Write-Host "Repo:   $repoRoot"
    Write-Host "Branch: $branch"
    Write-Host "Plan:   $planPath"
    Write-Host "Codex:  codex $($codexArgs[0..($codexArgs.Count-2)] -join ' ') <prompt: $($prompt.Length) chars>"
    Write-Host ""

    if ($DryRun) {
        Write-Host "---- DRY RUN: prompt that would be sent to Codex ----`n"
        Write-Host $prompt
        return
    }

    if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
        throw "codex CLI not found on PATH. Install codex-cli, then re-run."
    }

    & codex @codexArgs
    $exit = $LASTEXITCODE
    Write-Host ""
    Write-Host "codex exited with code $exit"
    if ($exit -ne 0) { throw "codex exec failed (exit $exit). Review output above." }
    Write-Host ""
    Write-Host "Done. Next: review Codex's commits with `/gsd:code-review` (or `/gsd:verify-work`)."
    git --no-pager log --oneline -10
}
finally {
    Pop-Location
}
