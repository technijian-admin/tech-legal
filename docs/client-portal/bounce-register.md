# Bounce Register — Canonical Broadcast Blocklist

**Authority:** This file is the **single source of truth in the repo** for bounced client broadcast addresses. The vault-canonical copy lives at `C:\Users\rjain\OneDrive - Technijian, Inc\Documents\obsidian\tech-legal\claude-memory\bounce_register.md`.

**Rule:** Before any `send-*.ps1` broadcast builds a BCC list, cross-check against this register. Any address in the "Bounced Address" columns below **must not be included** unless the row shows it resolved via fallback.

## Active Bounces — need replacement contact

*(currently empty — all outstanding bounces have been either resolved or flagged for client closure)*

## Resolved Bounces (fallback applied; safe to keep in BCC list)

| Client Code | Client Name | Bounced Address | Resolution Date | Fallback Applied | Notes |
|---|---|---|---|---|---|
| B2I | B2 Insurance | brenna@b2insurance.com | 2026-04-21 | keith@b2insurance.com (Keith Brewer, C1 role) | Identified 2026-04-16 but not propagated to BCC until 2026-04-21 — gap caused re-bounce on 2026-04-20 send |

## Closed Clients — Pending Portal UI Closure

Clients confirmed inactive by user after bounce sweep. **Removed from all broadcast BCC lists.** Each client's active contracts still need to be closed manually in the Client Portal UI — API writes (`stp_Update_Contract`) return 200 OK but don't take effect (verified 2026-04-16).

| Client Code | Client Name | Portal DirID | Active Contracts to Close | Bounce Reason | Closed On |
|---|---|---|---|---|---|
| EAG | Ellis Advisory Group | 6236 | 4918 (1 contract) | 550 5.x mailbox unavailable | 2026-04-21 |
| KEI | Kruger & Eckels, Inc | 7933 | 5305 (1 contract) | 550 5.x mailbox unavailable (re-bounced twice) | 2026-04-21 |
| NAC | National Auto Coverage | 5697 | 4676 (1 contract) | 550 5.4.310 DNS domain `natautocoverage.com` does not exist | 2026-04-21 |
| TCH | Torch Enterprises | 7148 | 5048, 5049, 5050, 5051, 5053, 5055, 5060, 5061, 5071, 5086 (10 hourly-project contracts) | 5.1.1 recipient not found; project work completed per user | 2026-04-21 |

**Total contracts pending manual portal UI closure: 13** (EAG:1 + KEI:1 + NAC:1 + TCH:10).

## Process

See the feedback memory `feedback_post_send_ndr_sweep.md` in `C:\Users\rjain\.claude\projects\c--VSCode-tech-legal\memory\` (and vault mirror). Rule: **every broadcast send must be followed, in the same engagement, by an NDR sweep that propagates findings to this register, every `send-*.ps1` BCC list, and the affected client's `CONTACTS.md`.**

## Changelog

- **2026-04-21** — Register created. Populated with 4 bounces carried over from the 2026-04-16 sweep that were never propagated to BCC lists, plus 1 new bounce (EAG) from the 2026-04-20 send. B2I resolved by swapping brenna → keith.
- **2026-04-21** — User confirmed EAG / KEI / NAC / TCH are inactive clients (TCH's 10 contracts were a single hourly project that ended). Moved to "Closed Clients" section. 13 contracts pending manual portal UI closure.
