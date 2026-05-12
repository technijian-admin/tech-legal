# Multi-LLM build pipeline — QuickBooks Direct-SDK Integration

> **Status:** bootstrap version. Phase 8 (`DEV-01`/`DEV-02`) fleshes this out (DeepSeek-CC review recipe, troubleshooting, examples). The core loop below is usable now.

This project is built with a deliberate split of work across LLMs to keep token cost down while keeping judgment-heavy work on the strongest model:

| Stage | Tool / model | Why |
|-------|--------------|-----|
| **Research** | Claude (GSD `gsd-project-researcher` / `gsd-phase-researcher`) | Project research done 2026-05-11 (`.planning/research/`). Per-phase research is light — kept on Claude. |
| **Plan** | Claude (GSD `gsd-planner` via `/gsd:plan-phase N`) → `.planning/phases/phase-N/PLAN.md` | The leverage point. A weak plan makes a cheap executor thrash → costs more. Kept premium. |
| **Execute** | **Codex CLI** (`codex-cli` ≥ 0.110) from the phase `PLAN.md` | The edit/test/fix loop is the highest token volume. Offloaded to OpenAI's bill. GSD plans are explicit task lists → hand off cleanly. |
| **Review / verify** | Claude (`/gsd:code-review`, `/gsd:verify-work`) — optionally a Codex review pass too | Cross-model review catches what the author missed. |
| **(optional) cheap review** | DeepSeek-backed Claude Code session | See "DeepSeek as a reviewer" below. Not in the default loop. |

**Branch:** all work is on `quickbooks/direct-sdk-integration-2026-05-11`. Never merge to `main` without a PR (repo policy).

## The per-phase loop

```text
/gsd:plan-phase N            # Claude → .planning/phases/phase-N/PLAN.md  (+ plan-checker pass)
pwsh quickbooks/dev/run-codex-phase.ps1 -Phase N    # Codex implements PLAN.md, commit-per-task
/gsd:code-review             # Claude reviews the diff   (or: /gsd:verify-work for goal-backward check)
# address review findings (Codex or Claude), then:
/gsd:plan-phase (N+1)        # next phase
```

`run-codex-phase.ps1` is a thin wrapper around `codex exec` (non-interactive). It:
1. Locates `.planning/phases/phase-N/PLAN.md` (errors if the phase isn't planned yet).
2. Builds a prompt: "Implement this GSD plan on the current git branch. Make one atomic commit per task. Do NOT touch `main`, do NOT `git checkout` another branch, do NOT `git add -A` (the working tree may contain unrelated files — stage only the files your task creates/edits). Run the tests the plan specifies and make them pass. Stop and report if a task is blocked."
3. Runs `codex exec --full-auto -C <repo-root> "<prompt + PLAN.md contents>"` (sandbox/approval flags per your `codex` config — adjust in the script).
4. Prints what Codex did so Claude can pick up the review.

> If `codex exec`'s flags differ in your installed version, run `codex exec --help` and update the `$codexArgs` array in the script. The script is intentionally small so it's easy to tweak per Codex version.

## DeepSeek as a reviewer (optional)

DeepSeek publishes an Anthropic-compatible endpoint, so a separate Claude Code session can run on DeepSeek for a cheap second-opinion review:

```powershell
$env:ANTHROPIC_BASE_URL  = "https://api.deepseek.com/anthropic"
$env:ANTHROPIC_AUTH_TOKEN = "<your-deepseek-api-key>"
$env:ANTHROPIC_MODEL      = "deepseek-reasoner"   # or deepseek-chat
claude   # then: "review the last commit on this branch for bugs / spec drift"
```

Unset those env vars (or use a separate shell) to go back to Claude. Do **not** run GSD agents under DeepSeek — GSD's model profiles assume Anthropic model IDs.

A finer-grained alternative is `claude-code-router` (community proxy) for per-request routing — out of scope for the default loop; documented here for completeness.

## Guardrails (because this repo has unrelated active work)

- The working tree directory (`C:\VSCode\tech-legal\tech-legal`) is shared with unrelated India HR work that may run automated commits. Whoever (Codex, Claude, a script) commits here must:
  - stay on `quickbooks/direct-sdk-integration-2026-05-11`,
  - `git add` only the specific files for the current task — never `git add -A` / `git add .`,
  - never `git checkout` another branch or `git reset --hard`.
- All QuickBooks code lives under `tech-legal/quickbooks/` and the skill under `tech-legal/.claude/skills/quickbooks-accounting/` — nothing outside those paths and `.planning/` should be touched by this project's work.
