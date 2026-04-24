# Inky / My AntiSpam Campaign — May 2026

Two-template campaign for the Kaseya-INKY pricing consolidation going live Monday, May 5, 2026.

## Audiences

| File | Recipients | Count | Purpose |
| ---- | ---------- | ----: | ------- |
| [email-existing-customers.md](email-existing-customers.md) | Currently on Inky | 11 | Notify of $4.25 → $4.75 price change + feature expansion |
| [email-prospects.md](email-prospects.md) | Not on Inky (base, no compliance framework) | 30 | Offer $4.75/user full-tier Inky as a new add-on |
| [email-prospects-financial.md](email-prospects-financial.md) | SEC/FINRA/GLBA firms | 4 | AFFG, EAG, VAF, JSD |
| [email-prospects-healthcare.md](email-prospects-healthcare.md) | HIPAA covered entities | 4 | PCM, ISI, RSPMD, SVE |
| [email-prospects-legal.md](email-prospects-legal.md) | Law firms (ABA/Cal RPC 1.6) | 3 | CBL, RALF, LODC |
| [email-prospects-defense.md](email-prospects-defense.md) | Aerospace/defense (CMMC) | 2 | ASC, CAM (confirm DoD work first) |
| [email-prospects-insurance.md](email-prospects-insurance.md) | Insurance/benefits (HIPAA + GLBA) | 1 | ALE |
| [compliance-classification.md](compliance-classification.md) | — | — | Framework mapping rationale for all 44 prospects |

## Merge Lists

- [merge-existing-customers.csv](merge-existing-customers.csv) — 11 rows
- [merge-prospects.csv](merge-prospects.csv) — 44 rows

## Merge Fields

Both templates use:

- `[First Name]` — greeting name (primary contact first name)
- `[Client Name]` — company name
- `[User Count]` — optional; for existing customers, the Inky user count from April 2026 invoice

## Attachment

Both emails attach the **My AntiSpam one-pager** from:
`C:\vscode\tech-branding\tech-branding\Services\My AntiSpam\` (PDF expected — pending generation by user)

Status: folder exists but deliverable not yet produced (only `assets/` subfolder present as of 2026-04-24). Do not send until PDF is confirmed final.

## Pre-send Checklist

1. **Attachment ready** — confirm `My AntiSpam` one-pager PDF exists in the tech-branding folder
2. **Confirm compliance assignments** — specifically:
   - **ASC / CAM** — confirm they hold CUI / do DoD work before using CMMC template
   - **TALY** — confirm industry (CPA vs. other); if CPA, move to Tier 1 with new AICPA/SOC variant
   - **AFFG** — verify compliance framing aligns with Iris's current SEC/FINRA posture (she's CCO)
3. Render body for 3 sample rows per template variant, grep for literal `[` / `]` to catch unmerged tokens
4. Attach Ravi's standard email signature
5. Confirm send date (not before 2026-04-28 to give 1-week lead before May 5 go-live)
6. Dropped per-user criteria: unsigned contracts, bounced-only contacts, BST (terminating 4/30), MAX (internal-only contact)

## Known Data Gaps

- Generic-inbox recipients (ANI ap@, PCM bills@, MGN jesus@) — no first name; use "Hi there," or company-level greeting
- Multi-contact rows use TO=primary; optional CC=secondary
