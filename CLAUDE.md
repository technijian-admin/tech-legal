# Claude Code Guide

Read [`AGENTS.md`](./AGENTS.md) first.

## Reasoning & Safety Settings

- **Effort:** max (set globally). Never reduce.
- **Destructive operations on Client Portal:** NEVER use delete endpoints (`stp_Con_Delete`, etc.). Only use status updates (Close/Inactive). If a status update doesn't appear to work, STOP and ask the user — do not escalate to more destructive operations.
- **Bulk operations:** Before executing any bulk write (email sends, contract changes, API updates), present the exact target list to the user and wait for confirmation.
- **Bounced email ≠ inactive client:** A bounced contact means update the contact info, not close the client. Only close a client when the user explicitly says so after reviewing.

## Client Portal API Safety Rules

1. READ operations are safe to run freely.
2. WRITE operations (any SP with Save, Update, Create, Delete in the name) require user confirmation before execution.
3. Never call `stp_Con_Delete` or any delete SP. Period.
4. If `stp_Update_Contract` returns 200 but data appears unchanged, tell the user — do not try alternative approaches autonomously.

For Client Portal work in this repo:

1. Treat `.codex/skills/` as the shared domain playbook.
2. Start with `.codex/skills/client-portal-core/SKILL.md`.
3. Use `.codex/skills/client-portal-core/references/domain-map.md` to route the task to the correct domain skill.
4. Use `.codex/skills/client-portal-core/scripts/client_portal_api.py` for live API auth, discovery, and execution.

If a prompt mentions clients, contracts, proposals, tickets, time entries, invoices, users, communications, reporting, admin, or payroll in the Client Portal, check the matching `client-portal-*` folder under `.codex/skills/` before improvising.

## Memory + Code Intelligence Stack

This repo uses a 4-layer memory + code-intelligence stack. Respect layer boundaries.

### Layer 1 — Obsidian Vault (durable human knowledge)

- **Path:** `C:\Users\rjain\OneDrive - Technijian, Inc\Documents\obsidian\tech-legal`
- **Memory folder:** `<vault>/claude-memory/topics/*.md` — one file per consolidated topic
- **Index:** `<vault>/claude-memory/index.md`
- **Changelog:** `<vault>/claude-memory/CHANGELOG.md` — every mutation prefixed
- **Health:** `<vault>/claude-memory/HEALTH.md` — live dashboard
- **Retrieval log:** `<vault>/claude-memory/.retrieval-log.jsonl`
- **Preferences:** `<vault>/claude-memory/preferences.md` (loaded on every retrieval)
- **Archive:** `<vault>/claude-memory/_archive/` — retired pages, never deleted

Vault is under git. Every `claude-memory/` mutation produces a commit with prefix: `[consolidate]`, `[reorg]`, `[health]`, `[manual]`, `[contradiction]`, `[replaced]`, `[volatility]`, or `[archive]`.

### Layer 2 — Auto-memory (Claude Code built-in)

`~/.claude/projects/c--vscode-tech-legal/memory/` — Claude's working notes. Managed by CC. Do not hand-edit unless asked.

### Layer 3 — GitNexus (code structure)

- `.gitnexus/` — code index
- MCP configured in `.claude/mcp.json`
- **Rule: `gitnexus_impact` MUST run before edits to shared code.** Block HIGH/CRITICAL risk edits; warn otherwise.
- Reindex hook runs on `git commit`/`merge`

### Layer 4 — Auto Dream (consolidation)

Stop-hook consolidation writes to vault topic pages. Triggered when an exchange produces durable knowledge.

## Topic schema

Every file under `claude-memory/topics/` uses this frontmatter:

```yaml
---
topic: <short name>
aliases: [<alternate names>]
volatility: stable|evolving|ephemeral
last_updated: <ISO date>
confidence: high|medium|low
sources: [<session hashes, commit hashes, gitnexus symbols>]
access_count: 0
last_accessed: <ISO date>
---
```

## Volatility semantics

- **stable** — architectural decisions, domain invariants, immutable facts. Review yearly. Contradiction threshold is strict. Never overwrite without "this was wrong" confirmation.
- **evolving** (default) — active development state, current approaches. Review quarterly. Normal consolidation.
- **ephemeral** — flaky tests, library workarounds, "current state of X". Review aggressively. Auto-archive after 60 days with no access and no update.

## Retrieval rules

- Load relevant topics ONLY on topic/entity match. Never load the whole vault.
- `preferences.md` is always loaded on every retrieval (universally applicable).
- Update `access_count` + `last_accessed` on each retrieval. Append a line to `.retrieval-log.jsonl`.

## Write rules

- Topic pages in place. Never transcripts. Never outside `claude-memory/`.
- Contradictions: compare new info to existing `## Key facts` / `## Decisions & rationale`.
  - **Compatible** → update normally.
  - **Clarifying** → update in place, note refinement in CHANGELOG.
  - **Contradicting** → append to `## Open questions`, preserve both versions, lower `confidence` by one step, log `[contradiction]` in CHANGELOG.
  - **Replacing** (only with explicit user signal) → overwrite, log `[replaced]` with what/why.
- Respect volatility — stable topics need much stronger signal before contradicting.

## Weekly review mandate

**Run `/review` every week.** Non-negotiable for vault hygiene. The SessionEnd hook nags after 7 days; `/graduate` refuses to recommend after 30 days without a review.

## Pointers

- `<vault>/claude-memory/index.md`
- `<vault>/claude-memory/HEALTH.md`
- Generated skills: `~/.claude/skills/` (global)

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **tech-legal** (1843 symbols, 3976 relationships, 105 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> If any GitNexus tool warns the index is stale, run `npx gitnexus analyze` in terminal first.

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `gitnexus_impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `gitnexus_detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `gitnexus_query({query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `gitnexus_context({name: "symbolName"})`.

## When Debugging

1. `gitnexus_query({query: "<error or symptom>"})` — find execution flows related to the issue
2. `gitnexus_context({name: "<suspect function>"})` — see all callers, callees, and process participation
3. `READ gitnexus://repo/tech-legal/process/{processName}` — trace the full execution flow step by step
4. For regressions: `gitnexus_detect_changes({scope: "compare", base_ref: "main"})` — see what your branch changed

## When Refactoring

- **Renaming**: MUST use `gitnexus_rename({symbol_name: "old", new_name: "new", dry_run: true})` first. Review the preview — graph edits are safe, text_search edits need manual review. Then run with `dry_run: false`.
- **Extracting/Splitting**: MUST run `gitnexus_context({name: "target"})` to see all incoming/outgoing refs, then `gitnexus_impact({target: "target", direction: "upstream"})` to find all external callers before moving code.
- After any refactor: run `gitnexus_detect_changes({scope: "all"})` to verify only expected files changed.

## Never Do

- NEVER edit a function, class, or method without first running `gitnexus_impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `gitnexus_rename` which understands the call graph.
- NEVER commit changes without running `gitnexus_detect_changes()` to check affected scope.

## Tools Quick Reference

| Tool | When to use | Command |
|------|-------------|---------|
| `query` | Find code by concept | `gitnexus_query({query: "auth validation"})` |
| `context` | 360-degree view of one symbol | `gitnexus_context({name: "validateUser"})` |
| `impact` | Blast radius before editing | `gitnexus_impact({target: "X", direction: "upstream"})` |
| `detect_changes` | Pre-commit scope check | `gitnexus_detect_changes({scope: "staged"})` |
| `rename` | Safe multi-file rename | `gitnexus_rename({symbol_name: "old", new_name: "new", dry_run: true})` |
| `cypher` | Custom graph queries | `gitnexus_cypher({query: "MATCH ..."})` |

## Impact Risk Levels

| Depth | Meaning | Action |
|-------|---------|--------|
| d=1 | WILL BREAK — direct callers/importers | MUST update these |
| d=2 | LIKELY AFFECTED — indirect deps | Should test |
| d=3 | MAY NEED TESTING — transitive | Test if critical path |

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/tech-legal/context` | Codebase overview, check index freshness |
| `gitnexus://repo/tech-legal/clusters` | All functional areas |
| `gitnexus://repo/tech-legal/processes` | All execution flows |
| `gitnexus://repo/tech-legal/process/{name}` | Step-by-step execution trace |

## Self-Check Before Finishing

Before completing any code modification task, verify:
1. `gitnexus_impact` was run for all modified symbols
2. No HIGH/CRITICAL risk warnings were ignored
3. `gitnexus_detect_changes()` confirms changes match expected scope
4. All d=1 (WILL BREAK) dependents were updated

## Keeping the Index Fresh

After committing code changes, the GitNexus index becomes stale. Re-run analyze to update it:

```bash
npx gitnexus analyze
```

If the index previously included embeddings, preserve them by adding `--embeddings`:

```bash
npx gitnexus analyze --embeddings
```

To check whether embeddings exist, inspect `.gitnexus/meta.json` — the `stats.embeddings` field shows the count (0 means no embeddings). **Running analyze without `--embeddings` will delete any previously generated embeddings.**

> Claude Code users: A PostToolUse hook handles this automatically after `git commit` and `git merge`.

## CLI

| Task | Read this skill file |
|------|---------------------|
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md` |
| Work in the _generators area (424 symbols) | `.claude/skills/generated/generators/SKILL.md` |
| Work in the Templates area (50 symbols) | `.claude/skills/generated/templates/SKILL.md` |
| Work in the Scripts area (31 symbols) | `.claude/skills/generated/scripts/SKILL.md` |
| Work in the OKL area (16 symbols) | `.claude/skills/generated/okl/SKILL.md` |
| Work in the 03_SOW area (11 symbols) | `.claude/skills/generated/03-sow/SKILL.md` |

<!-- gitnexus:end -->
