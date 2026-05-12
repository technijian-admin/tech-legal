# Multi-LLM build pipeline - QuickBooks Direct-SDK Integration

This is the live build pipeline - phases 1-8 of the QuickBooks Direct-SDK integration were built this way.

This project deliberately splits work across models so planning and review stay
premium while the long edit/test/fix loop stays cheap and fast.

| Stage | Tool / model | Why |
|-------|--------------|-----|
| Research | Claude (GSD researcher flows) | Phase and project research stay on the strongest planning model. |
| Plan | Claude (`/gsd:plan-phase N`) | The plan is the leverage point; weak plans make cheap executors thrash. |
| Execute | Codex CLI from the phase `PLAN.md` | Highest token volume; good fit for explicit task-by-task execution. |
| Review / verify | Claude (`/gsd:code-review`, `/gsd:verify-work`) | Cross-model review catches drift, missed tests, and weak assumptions. |
| Optional cheap review | DeepSeek-backed Claude Code session | Useful for second-opinion PR or commit review. |

**Branch:** all work stays on `quickbooks/direct-sdk-integration-2026-05-11`.

## The per-phase loop

```text
/gsd:plan-phase N
-> plan-checker pass
-> pwsh quickbooks/dev/run-codex-phase.ps1 -Phase N
-> /gsd:code-review
-> address findings
-> /gsd:plan-phase (N+1)
```

`run-codex-phase.ps1` is the plan-to-execution handoff. It:

1. Finds `.planning/phases/NN-slug/*-PLAN.md` for the requested phase.
2. Builds a strict executor prompt with the repo guardrails and the plan text.
3. Runs:
   `codex exec --dangerously-bypass-approvals-and-sandbox -C <repo-root> -`
   with the prompt piped through stdin.
4. Prints the recent commit log so Claude can review what Codex actually did.

The bypass flag is intentional on this workstation. `codex exec --full-auto`
came up read-only here, which blocked directory creation and git operations.
The prompt-level HARD RULES bound the blast radius instead:

- stay on the current branch
- scoped `git add` only
- never `git add -A` / `git add .`
- never `git reset --hard`
- never `git init` a nested repo
- `.gitignore` stays append-only
- if revising an already-committed task, amend or use `fix(...)` / `refactor(...)`
  instead of creating duplicate-titled `feat(...)` commits

If your installed Codex CLI changes flags, run `codex exec --help` and update
the script's `$codexArgs` array. Keep the script small and easy to audit.

## DeepSeek as a reviewer (optional)

DeepSeek exposes an Anthropic-compatible endpoint, so a separate Claude Code
session can be pointed at it for low-cost review:

```powershell
$env:ANTHROPIC_BASE_URL = "https://api.deepseek.com/anthropic"
$env:ANTHROPIC_AUTH_TOKEN = "<your-deepseek-api-key>"
$env:ANTHROPIC_MODEL = "deepseek-reasoner"
claude
```

Then ask Claude to review the last commit against the active `PLAN.md`.
Unset those three env vars to revert. Do **not** run GSD agents under DeepSeek;
their profiles assume Anthropic model IDs.

`claude-code-router` is the finer-grained alternative if you want per-request
routing instead of shell-wide environment switching.

## Guardrails

This repo has unrelated active India HR work in the same working tree. Any
automation touching QuickBooks files here must:

- stay on `quickbooks/direct-sdk-integration-2026-05-11`
- stage only the exact files for the current task
- never `git checkout` another branch
- never `git reset --hard`
- keep QuickBooks code under `quickbooks/`
- keep the repo-local QuickBooks skill under `.claude/skills/quickbooks-accounting/`

## Conventions

- One commit per task with a conventional-commit prefix: `feat(NN-MM)`,
  `test(NN-MM)`, `ci(NN-MM)`, `docs(NN-MM)`, `fix(NN-MM)`, or `refactor(NN-MM)`.
- The final `docs(NN-MM)` commit updates the phase summary and planning state:
  phase summary, ROADMAP, REQUIREMENTS, and STATE.
- Do not create two `feat(...)` commits with the same subject. Amend the
  existing commit or use a distinct `fix(...)` / `refactor(...)` subject.
- The review bar is 100/100 before a phase is considered complete.
- Constructed qbXML fixtures carry a Phase-9 re-pin note because they are not
  validated against the live host yet.

## Phase artifacts

Per-phase research, execution plans, and summaries live under:

` .planning/phases/NN-slug/NN-MM-{RESEARCH,PLAN,SUMMARY}.md `

Those files are the handoff spine between planning, execution, review, and the
next phase.
