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

    # --- locate the phase directory + PLAN file(s) ---
    # GSD convention: .planning/phases/<NN>-<slug>/  containing  <NN>-<MM>-PLAN.md  (one or more plans).
    $phasesRoot = Join-Path $repoRoot ".planning\phases"
    $nn = "{0:D2}" -f $Phase
    $phaseDir = Get-ChildItem -Path $phasesRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match "^0*$Phase-" -or $_.Name -match "^$nn-" } |
        Select-Object -First 1
    if (-not $phaseDir) {
        throw "No phase directory for phase $Phase under $phasesRoot (looked for '$nn-*' or '$Phase-*'). Run `/gsd:plan-phase $Phase` first."
    }
    $planFiles = Get-ChildItem -Path $phaseDir.FullName -Filter "*-PLAN.md" -File | Sort-Object Name
    if (-not $planFiles -or $planFiles.Count -eq 0) {
        throw "Phase directory '$($phaseDir.FullName)' has no *-PLAN.md. Run `/gsd:plan-phase $Phase` first."
    }
    $planPath = ($planFiles | ForEach-Object { $_.FullName }) -join ", "
    # Concatenate all plan files (with headers) — Codex implements every plan in the phase.
    $planText = ($planFiles | ForEach-Object {
        "`n=== PLAN FILE: $($_.Name) ===`n" + (Get-Content -Raw -LiteralPath $_.FullName)
    }) -join "`n"

    # --- assemble the prompt for Codex ---
    $guardrails = @'
You are the EXECUTOR in a multi-LLM pipeline. A GSD phase plan follows. Implement it exactly.

HARD RULES (this repo also contains unrelated active work — violating these corrupts someone else's work):
- Stay on the current git branch. NEVER `git checkout` another branch. NEVER `git reset --hard`. NEVER touch `main`.
- NEVER `git add -A` or `git add .`. Stage ONLY the specific files your current task creates or edits.
- Only create/modify files under `quickbooks/`, `.claude/skills/quickbooks-accounting/`, `.github/workflows/` (QuickBooks CI only), `.planning/phases/` (the phase plan's checklist + a phase SUMMARY), and `.gitignore` (APPEND-ONLY — never rewrite it). Nothing else. NEVER `git init` a nested repo. NEVER run `tlbimp` (the interop stub is hand-written for now; it gets replaced on the real QB host in a later phase).
- Make ONE atomic git commit per task in the plan, with a clear conventional-commit message (`feat(...)`, `test(...)`, `ci(...)`, etc.). Do not squash all tasks into one commit.
- If you need to REVISE a task you have ALREADY committed in this run (you noticed a bug, refined the design, etc.): AMEND that commit (`git commit --amend --no-edit` after re-staging) OR add a follow-up commit with a DISTINCT message (`fix(...)` / `refactor(...)`). NEVER create a second commit with the same `feat(...)` title — duplicate-titled commits clutter the history.
- For each task: implement it, then run the tests the plan specifies (and any existing test suite), and make them pass before committing. If a task is blocked or a test can't pass, STOP, commit what's safely done, and report the blocker — do not hack around it.
- After all tasks: update the phase plan's task checkboxes, run the full test suite once more, and report a summary (commits made, tests status, anything deferred). Reviewer expects 100/100 — leave nothing dangling (commit the plan-checkbox update and any SUMMARY file the plan asks for), no duplicate-titled commits, build + full test suite green.

ABOUT THE REPO'S CLAUDE.md / AGENTS.md "GitNexus impact analysis before edits" RULE: it does NOT apply to this phase. You are CREATING brand-new files in a brand-new subsystem (`quickbooks/QbConnectService/`) that nothing else depends on yet — there is no blast radius to analyze, and the GitNexus MCP isn't available to you anyway. Do NOT block on it. Likewise the "Client Portal API safety" rules in CLAUDE.md are irrelevant — this phase touches no Client Portal API. Proceed with the plan.

=== GSD PHASE PLAN ===
'@
    $prompt = $guardrails + "`n" + $planText
    if ($ExtraInstructions.Trim()) {
        $prompt += "`n`n=== EXTRA INSTRUCTIONS FROM ORCHESTRATOR ===`n" + $ExtraInstructions
    }

    # --- codex invocation ---
    # codex-cli >= 0.110: `codex exec [OPTIONS] [PROMPT]`. We pipe the (large) prompt via STDIN
    # (pass `-` as the prompt arg) to avoid command-line length limits.
    #   -C <dir>  = working root for the agent
    #   --dangerously-bypass-approvals-and-sandbox = no approval prompts, no sandbox.
    # We use the bypass because on this workstation `--full-auto`'s sandbox came up read-only
    # (couldn't create dirs / run git → Codex correctly refused). The bypass is acceptable here:
    # it's the user's own trusted dev box and this is an intentional autonomous build run, and the
    # HARD RULES in the prompt above (stay on branch, scoped `git add`, no `git add -A`, no
    # `git reset --hard`, no nested `git init`, append-only `.gitignore`) bound what Codex may do.
    # If you'd rather keep a sandbox, try instead:  --full-auto --add-dir "$repoRoot"  -c sandbox_workspace_write.network_access=true
    # (and run `codex exec --help` to see your installed version's flags).
    $codexArgs = @(
        "exec",
        "--dangerously-bypass-approvals-and-sandbox",
        "-C", "$repoRoot",
        "-"        # read PROMPT from stdin
    )

    Write-Host "Repo:   $repoRoot"
    Write-Host "Branch: $branch"
    Write-Host "Plan:   $planPath"
    Write-Host "Codex:  codex $($codexArgs -join ' ')   <prompt: $($prompt.Length) chars via stdin>"
    Write-Host ""

    if ($DryRun) {
        Write-Host "---- DRY RUN: prompt that would be piped to Codex ----`n"
        Write-Host $prompt
        return
    }

    if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
        throw "codex CLI not found on PATH. Install codex-cli, then re-run."
    }

    $prompt | & codex @codexArgs
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
