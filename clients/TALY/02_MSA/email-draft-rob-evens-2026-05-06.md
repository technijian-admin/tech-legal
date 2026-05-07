# Email Draft — Robert L. Evens (TALY)

**Date drafted:** 2026-05-06
**From:** Ravi Jain <rjain@technijian.com>
**To:** Robert L. Evens <rob@talleyassoc.com>
**CC:** _(optional — billing@technijian.com if you want AR copied)_
**Subject:** Talley & Associates — proposed cost reductions and refreshed Master Service Agreement

**Attachments:**
- `MSA-TALY-2026.pdf` (Master Service Agreement)
- `Schedule-A-TALY.pdf` (Monthly Managed Services + Service Order)
- `Schedule-B-TALY.pdf` (Subscription Services framework)
- `Schedule-C-TALY.pdf` (Rate Card)

---

## Body

Hi Rob,

I just finished a billing review on Talley & Associates' account, and I want to walk you through two changes that should bring your monthly invoice down meaningfully. I've also drafted a refreshed Master Service Agreement so we can put the relationship on current paper — your existing contract has been on month-to-month rollover since the original 3-month term expired in April 2025, and our master agreement template has been substantially updated since then.

If you're good with what's below, I can send the package to you for electronic signature today and have it take effect retroactive to **May 1, 2026**, aligned with the start of the current billing period.

### What I'm proposing

**1. Switch US Tech Support from a committed monthly block to true hourly billing.**

Today you pay for **1.38 hours/month** of US-based Tech Support at the discounted contracted rate of $125/hr — a fixed $172.50 line on every monthly invoice, whether or not we use the time. Looking at the last 16 months of actual ticket data, you've averaged just **0.90 hours/month** of US Tech Support work, which is about 45% utilization of what you're paying for.

I'd like to drop the commitment entirely. You would pay only for the time we actually spend on US-based work, billed weekly in 15-minute increments. The rate moves from $125/hr to $150/hr (and $250/hr for after-hours emergencies) because the discount is tied to the commitment — but at your usage level you still come out ahead on average, and on a light-usage month you save the full $172.50.

India Tech Support stays on the current committed-hours model. The contracted rates there ($15/hr Normal, $30/hr After-Hours) are too good to give up.

**2. Remove Real-Time Penetration Testing and Site Assessment — pending your call.**

Two security line items together total **$92/month**:

- **Real-Time Penetration Testing (RTPT)** — continuous external attack-surface scanning across 6 of your public IPs. $42/mo.
- **Site Assessment (SA)** — recurring web application security assessment for 1 domain. $50/mo.

Before I take these out I want to make sure removing them doesn't create a problem on your end. A few things to think through:

- **Cyber liability insurance.** Most policies issued in 2024-2026 require ongoing vulnerability scanning and periodic penetration testing as a condition of coverage. Removing RTPT and SA could trigger a coverage gap, affect your renewal premium, or in the worst case give the carrier a basis to deny a claim. Worth a quick check with your broker.
- **Client and regulatory requirements.** If any of your own clients send you vendor security questionnaires, or if your firm is subject to GLBA's Safeguards Rule (the FTC's 2023 update covers a broad range of financial services and includes periodic vulnerability assessments and pen testing), or if you're working toward or maintaining SOC 2, these line items often map directly to required controls.
- **Posture.** Practically speaking, RTPT detects exploit attempts against your public IPs in real time. Without it, an attacker probing your perimeter goes unnoticed until something actually breaks.

If none of those apply and you're comfortable with the risk, we can pull both line items immediately and the $92/mo comes off the bill. If you want to keep them but feel they should be smaller in scope (fewer IPs, less frequent scanning), I'm happy to right-size instead. And if you want to keep them as-is, that's fine too — I just want to make sure the decision is yours, not a default.

### Cost summary

| Line | Today | After |
|------|------:|------:|
| Desktop endpoint stack (×7 desktops) — CrowdStrike, Huntress, patch, secure internet, remote | $185.50 | $185.50 |
| Network monitoring (×32 devices) | $128.00 | $128.00 |
| Backup storage (1 TB) | $50.00 | $50.00 |
| Real-Time Pen Testing (6 IPs) | $42.00 | $0 if you approve |
| Site Assessment (1 domain) | $50.00 | $0 if you approve |
| US Tech Support — committed 1.38 h × $125/hr | $172.50 | $0 (moves to hourly $150/hr ad-hoc) |
| India Tech Support — committed (Normal + After-Hours) | $96.75 | $96.75 |
| Tax | $7.75 | $7.75 |
| **Monthly recurring invoice** | **$724.75** | **$468.00** |

**Visible recurring savings: $256.75/month, about 35% off the monthly invoice.**

US Tech Support work, when it happens, gets billed separately on a weekly invoice at the new ad-hoc rates. At your historical average of 0.90 h/month that adds roughly $135/month, for a **blended steady state of about $603/month versus $724.75 today (about 17% real savings)**. Light-usage months will save more, heavy-usage months may save less. India Tech Support still appears as the same fixed line.

If you also approve removing RTPT and SA, take another **$92/month** off both the recurring invoice and the blended figure.

### About the new MSA

Attached you'll find four documents that together replace the existing Monthly Support contract:

1. **Master Service Agreement (MSA-TALY-2026)** — 12-month initial term with 60-day renewal notice, Net 30 payment terms, current-form data protection and insurance language.
2. **Schedule A** — Monthly Managed Services, including the cycle-based billing model for India Tech Support, the new hourly (ad-hoc) model for US Tech Support, and the Service Order with the exact line items above.
3. **Schedule B** — Subscription Services framework (no active subscriptions today; this is in place so any future Microsoft 365, SSL, or domain registration additions are clean).
4. **Schedule C** — full Rate Card with every role and per-line-item price across the entire Technijian service catalog, so any future additions are transparent and pre-priced.

Two carve-outs worth flagging in the Service Order: the existing India Tech Support cycle credit balance carries forward, and the open AR on the partially-paid March 2026 invoice (#27954, $240.45 short-pay) is preserved separately for normal AR reconciliation — it is not waived by signing the new MSA.

### Next steps

If the cost reductions and the MSA look right to you, just reply with:

1. Whether to drop RTPT and SA, keep them, or right-size them; and
2. A green light to proceed.

I'll then send the four documents to you via Foxit eSign for electronic signature. Once signed, the new MSA and Service Order take effect retroactive to **May 1, 2026**, and we'll void and reissue the current pending May 1 invoice (#28363, for the June service period) at the new lower rates so the savings hit immediately.

Happy to jump on a quick call if it's easier to work through any of this live — let me know.

Best,

Ravi Jain
President, Technijian, Inc.
rjain@technijian.com
18 Technology Drive, Suite 141, Irvine, CA 92618

---

## Notes for sender (not part of the email body)

- **Send via:** Microsoft 365 Graph from `rjain@technijian.com`, branded HTML.
- **Attachments:** Convert the four MSA `.md` files to `.pdf` (or `.docx`) before sending. The 02_MSA folder currently has only the `.md` source — DOCX/PDF generation can mirror the CCC pattern (`generate-msa.py` in CCC `_generators/`).
- **eSign provider:** Foxit eSign (per current provider rotation).
- **Effective date logic:** May 1, 2026 backdating aligns with invoice #28363 (issued 2026-05-01, service period June 1–30). On signature, plan to void #28363 and reissue at the new rates so the new pricing hits the first month.
- **Compliance angle in the email is framed as questions, not legal advice.** Robert decides; we document his decision in the reply before pulling the lines.
