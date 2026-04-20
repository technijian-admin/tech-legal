# CPUC Complaint #226711 — Sunrun (Filed 2026-04-20)

**Property:** 5 Caladium, Rancho Santa Margarita, CA 92688
**SDG&E Account:** 0036 1837 1728 9
**Sunrun Case:** #18181148
**CPUC Confirmation Number:** **226711**
**Filed:** 2026-04-20
**Filing method:** CPUC online complaint form (Playwright-assisted; reCAPTCHA submitted manually)
**Portal:** https://cims.cpuc.ca.gov/complaints/

## Why filed
Sunrun's technicians disconnected the residential 11.16 kW solar system on or about 2025-11-07 and never disclosed it. The system produced zero exportable kWh for ~5 months (Nov 2025 – Apr 2026). Excess SDG&E charges totaled approximately $3,600. Sunrun's offered compensation was $450 (Early Performance Guarantee credit) — a small fraction of the documented loss and almost certainly conditioned on a release of further claims.

## Track in parallel with
| Track | Status |
|---|---|
| Round 1 demand letter ($7,500) | Sent 2026-04-17 to Katherine Wilson + membercare@ |
| Round 2 detailed reply | Sent 2026-04-20 (this repo: scripts/send-sunrun-reply-katherine.ps1) |
| **CPUC #226711** | **Filed 2026-04-20 — awaiting CPUC response** |
| Ed Susolik review (class-action evaluation) | Forwarded 2026-04-20 — same counsel as Technijian v. Vintage Design (AAA) |
| CSLB complaint (License #750184) | Pending — file if Round 2 ignored by Apr 24 |
| Small claims (CCP §116.221, $12,500 cap) | Target filing 2026-05-15 if no resolution |
| CLRA §1782 30-day notice | Began running 2026-04-17; ripens 2026-05-17 |

## Key dates going forward
- **2026-04-22** — Sunrun-scheduled service appointment (11am-3pm). 2017 Costco system still 0 kWh as of Apr 18.
- **2026-04-24 (Friday)** — Round 2 response deadline given to Katherine Wilson.
- **2026-05-15** — Target small-claims filing if no settlement.
- **2026-05-17** — CLRA 30-day notice clock ripens to lawsuit.

## CPUC complaint narrative (preserved)
Filed via CPUC online form. Narrative covered:
1. Sunrun monitoring detected failure on or before 2025-11-10 (per their own Jan 16 email)
2. 67 days of complete silence after monitoring detected the issue
3. Pattern of vague "system issue" language never disclosing zero production
4. Marketing emails (CEO + "Value Report") sent during the outage
5. Settlement offer of $450 against ~$3,600 in excess utility charges
6. 2017 Costco system still non-operational as of Apr 18 ("Outlier detected" in Sunrun's own app)

## CPUC form gotchas (for next time)
- Street field is `#LocationService` (not `#Street`)
- No single quotes/apostrophes allowed — write "Sunruns" not "Sunrun's"
- 1000-character limit per narrative box
- Mobile phone required (`#PhoneDayTime`)
- reCAPTCHA must be solved manually — cannot be automated

## CPUC follow-up checklist
- [ ] Receive CPUC acknowledgment email (typically within 5 business days)
- [ ] Track #226711 status at https://cims.cpuc.ca.gov/complaints/
- [ ] Update CPUC if Sunrun does not substantively respond by Apr 24
- [ ] Reference #226711 in any further Sunrun correspondence
- [ ] Provide #226711 to Ed Susolik for class-action survey

## Related files
- [contacts.md](contacts.md) — Sunrun escalation ladder
- [research/MASTER-SUMMARY.md](research/MASTER-SUMMARY.md) — California case-law synthesis
- [emails/](emails/) — Sunrun email archive (Nov 2025 – Apr 2026)
- [evidence/](evidence/) — SDG&E bills, contracts, app screenshots
- [../../../scripts/send-sunrun-demand.ps1](../../../scripts/send-sunrun-demand.ps1) — Round 1 letter
- [../../../scripts/send-sunrun-reply-katherine.ps1](../../../scripts/send-sunrun-reply-katherine.ps1) — Round 2 reply