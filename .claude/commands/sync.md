---
name: sync
description: Sync vault git — pull, review conflicts if any, commit local changes, push.
---

Run in vault directory: `C:/Users/rjain/OneDrive - Technijian, Inc/Documents/obsidian/tech-legal`

Steps:

1. `git status` — if dirty, list changes. Ask: commit (with `[manual]` prefix) or skip?
2. `git fetch origin` (if remote configured). If no remote, skip pull/push steps and just commit-in-place.
3. `git pull --ff-only` — if diverged, surface the conflict and ask how to resolve. Do not auto-resolve.
4. Commit any pending changes with `[manual] sync: <brief summary>`.
5. `git push` — if remote configured.
6. Report: local HEAD, remote HEAD, any commits ahead/behind.

If vault has no remote configured, note it and stop after step 4.

Do not push-force. Do not reset.
