# BST DAMAGES SCENARIO ANALYSIS — INTERNAL / PRIVILEGED WORK PRODUCT
**Matter:** *Technijian, Inc. — The Boston Group, Inc. / UCC Recycling* — Termination Reconciliation
**Date prepared:** 2026-04-15
**For:** Edward Susolik, Esq., Callahan & Blaine, PC (outside counsel)
**From:** Ravi Jain, CEO, Technijian, Inc.
**Status:** **ATTORNEY–CLIENT PRIVILEGED · ATTORNEY WORK PRODUCT · DO NOT DISCLOSE TO OPPOSING PARTY OR COUNSEL**

---

## 1. Executive Summary

| Item | Value |
|---|---|
| Client | The Boston Group, Inc. / UCC Recycling ("BST") |
| Primary contact | Jeff Klein, jklein@bostongroupwaste.com |
| Operative agreement | Client Monthly Service Agreement, DocuSigned (BST) |
| DocuSign Envelope ID | **FC626837-AEED-442F-9961-A81502402FC4** |
| Signature / effective | 2023-04-10 (Agreement date) / service commenced 2023-05-01 |
| Contract ID (ticketing) | 4925 |
| Termination notice | 2026-03-17 (Jeff Klein letter) |
| Requested effective date | 2026-04-30 (consistent with § 4.05 30-day notice) |
| Successor provider | Tech Heights (Renwick "Rich" Leggett, ex-Technijian employee) |
| Opposing counsel | Engaged 2026-03-23 ("Our attorney is reviewing the contract"); firm not yet identified |
| Our counsel | Edward Susolik, Callahan & Blaine — briefed 2026-03-19 |
| **Contract-basis cancellation fee (Method A)** | **$139,743.00** (931.62 hrs × $150) |
| Cancellation fee previously invoiced / stated to client (3/19, 3/23) | $126,442.50 (842.95 hrs × $150) — see reconciliation § 3 below |
| **Settlement offer on the table to Jeff (3/23)** | **$15,045.00** (100.30 hrs × $150 — life-of-contract net approach) |
| Deadline on settlement offer | 2026-04-30 (close of business) |
| Ancillary tort exposure on Tech Heights / Leggett | Not yet quantified — see § 8 |

**Bottom line for Ed:** The contract as written supports a range of **$0 (current cycle only) to $139,743.00 (per-row life-of-contract overage)**, with a defensible mid-point around **$126,442.50** (the number Ravi invoiced and offered). Ravi has already placed a good-faith concession of **$15,045** on the table as a fast-resolution settlement, open through 4/30.

---

## 2. Controlling Contract Language (signed BST MSA, Rev. 041522)

### 2.1 Invoice page — "Under Contract"
> *Under contract support is defined as support that will be charged monthly based on the average number of hours used, under the following conditions:*
> 1. *The under-contract period shall be 12 Months.*
> 2. *A new average will be calculated after each under contract period.*
> 3. *The first month of the new average will be charged at the previous average since that invoice will be due the first of the month.*
> 4. *If the average goes down a credit will be given on the next month's invoice. If the average goes up an extra charge will be given on the next month's invoice.*
> 5. ****If this agreement is terminated, any hours that exceeded the previous under contract period average, that were documented through ticketing, will be charged at a rate of $150 per hour and will be assessed as the cancellation fee to the client and due before agreement is terminated.***

### 2.2 Invoice page footer
> *"Hours not paid are due if support agreement is cancelled per monthly service agreement."*

### 2.3 § 4.05 — Termination by Client
> *"Client shall provide thirty (30) days' written notice to Technijian if Client desires to terminate the Services with Technijian during the term of this Agreement. Client shall be liable to pay Technijian for all services and labor costs owed to Technijian up to and including the thirty (30) days' notice period. The thirty (30) days' notice period for all non-labor services provided by Technijian to Client shall start on the 1st day of the following month when Client gave notice. Upon any termination of this Agreement, Client shall be liable to pay Technijian for all services and labor costs owed to Technijian up to and including any outstanding invoices as of the date notice of termination is provided. Technijian shall determine the remaining costs for annual licenses and services and Client shall be liable to pay Technijian for these costs."*

### 2.4 Anti-hire / employee solicitation
> *"Client agrees to NOT hire any Technijian employee up to two years after this agreement is terminated. If client does hire within that period, the client agrees to pay Technijian 50% of the annual salary of that employee as verified by a third-party accounting firm paid for by the client."*
(Direct-hire clause. Tech Heights is not a direct hire of BST, so strict application is attenuated; however, a tortious interference theory against Leggett/Tech Heights stands on separate ground — see § 8.)

### 2.5 POD Specifications (contracted "Under Contract" roles for BST)

| Office-POD | Loc. Code | Role | Rate | Initial / Min Hrs | Venue |
|---|---|---|---:|---:|---|
| CHD-TS1 | BST | OS Support (Normal) | $15/hr | 9.00 / 9.00 | Remote |
| CHD-TS1 | BST | OS Support.AH (After-Hours) | $30/hr | 9.00 / 9.00 | Remote |
| IRV-AD1 | BST | Systems Architect | $200/hr | (not under-contract, scheduled) | Remote |
| IRV-TS1 | BST | Tech Support (Normal Onshore) | $125/hr | 6.50 / 6.50 | Remote |

**Three under-contract roles drive the cancellation-fee calculation:** CHD-TS1 Normal (offshore remote), CHD-TS1 AH (offshore after-hours), and IRV-TS1 Normal (onshore remote). These correspond to spreadsheet rows `OFFSHORESUPPORT.N`, `OFFSHORESUPPORT.AF`, and `Tech Support.N`.

---

## 3. Reconciliation of the Hours Data (`bst_actualvsbillable.xlsx`)

### 3.1 Three 12-month under-contract cycles
The BST agreement ran 2023-05-01 through termination effective 2026-04-30 — roughly 36 months. The spreadsheet reflects three 12-month cycles:

| Cycle | Period | Notes |
|---|---|---|
| Cycle 1 | 5/2023 – 4/2024 | Initial baseline (from original POD Min Hours) |
| Cycle 2 | 5/2024 – 4/2025 | Baseline reset using Cycle 1 average |
| Cycle 3 | 5/2025 – 4/2026 | Baseline reset using Cycle 2 average |

### 3.2 Role-by-role life-of-contract totals

| Role | Total Actual | Total Billable (baselines) | Net (Actual − Billable) | Per-Row Overage (max(0, Actual − Billable)) |
|---|---:|---:|---:|---:|
| CHD-TS1 Offshore Normal (OFFSHORESUPPORT.N) | 1,293.98 | 1,084.49 | **+209.49** | 571.11 |
| CHD-TS1 Offshore After-Hours (OFFSHORESUPPORT.AF) | 702.67 | 668.66 | **+34.01** | 311.29 |
| IRV-TS1 Onshore Remote Normal (Tech Support.N) | 207.22 | 315.88 | **−108.66** | 49.22 |
| **TOTAL** | **2,203.87** | **2,069.03** | **+134.84** | **931.62** |

(Verified by recomputation from `attachments/2026-03-24_1721_bst_actualvsbillable.csv` on 2026-04-15. The spreadsheet's own net-column formula matches the "Net" column above.)

### 3.3 Baseline-reset pattern confirmed
Each role's "Billable" column steps up between cycles:

| Role | Cycle 1 baseline | Cycle 2 baseline | Cycle 3 baseline |
|---|---:|---:|---:|
| CHD-TS1 Offshore Normal | 9.00 | 29.50 | 56.59 |
| CHD-TS1 Offshore After-Hours | 9.00 | 15.83 | 33.70 |
| IRV-TS1 Onshore Remote Normal | 6.50 | 8.31 | 12.56 |

This matches ¶ 3 of the Under Contract clause: "*The first month of the new average will be charged at the previous average since that invoice will be due the first of the month.*"

### 3.4 Cycle-3 (current-cycle) observation — **critical**
**In Cycle 3 (5/2025 – 4/2026), every single month across all three roles shows Actual ≤ Billable.** The client has been under-consuming its baseline for the entire termination cycle:

| Month | CHD-TS1 N (Actual vs 56.59) | CHD-TS1 AH (Actual vs 33.70) | Tech Support.N (Actual vs 12.56) |
|---|---|---|---|
| 5/2025 | 40.51 | 12.73 | 2.50 |
| 6/2025 | 36.12 | 16.34 | 4.25 |
| 7/2025 | 34.36 | 13.93 | 1.00 |
| 8/2025 | 14.95 | 14.01 | 8.00 |
| 9/2025 | 14.96 | 5.36 | 1.50 |
| 10/2025 | 9.97 | 4.50 | 11.25 |
| 11/2025 | 17.82 | 6.08 | 2.00 |
| 12/2025 | 29.91 | 5.35 | 0.50 |
| 1/2026 | 25.05 | 16.50 | 1.00 |
| 2/2026 | 28.22 | 8.99 | 0.00 |
| 3/2026 | 9.00 | 4.50 | 0.00 |

**Cycle-3 per-row overage = 0.00 hrs.** Under the strictest reading of the Under Contract clause ("hours that exceeded the previous under contract period average"), the cancellation fee in the **termination cycle only** is **$0**. This is different from VTD (active overage in termination cycle) and a potential weakness if litigation centers on current-cycle conduct. See § 6 (Counsel's risk lens).

### 3.5 Weekly zero-dollar ticket-time distribution
Per Ravi's 2026-03-23 message to Jeff, BST received **weekly zero-dollar invoices enumerating ticket/time entry detail, with a 30-day dispute window** — the same mechanism used against VTD. No timely disputes are on record. This supports a course-of-dealing / account stated defense to any "records not accurate" objection (see Case Law Memo § 6).

---

## 4. Five Damages Methodologies

### 4.1 Method A — Per-row overage, life of contract (our invoice basis)
- Formula: Σ max(0, Actual − Billable) per (role, month)
- Result: **931.62 hrs × $150 = $139,743.00**
- Discards negatives (months/roles under baseline)
- **Strength:** Literal reading of Under Contract ¶ 5 — "any hours that exceeded the previous under contract period average... will be charged at a rate of $150 per hour."
- **Weakness:** Treats each month in isolation and ignores that many of these overages were already "priced in" when the new cycle's baseline reset to the prior cycle's average. Arguably double-counting.

### 4.2 Method A-adjusted — Ravi's 3/19 figure (842.95 hrs / $126,442.50)
The number Ravi stated to Jeff was 842.95 hrs → $126,442.50. The delta of **88.67 hrs** between 931.62 (my recalc) and 842.95 is unreconciled — possibly a difference in date-range cutoff or exclusion of one role's partial months. **Action item for Ed: before serving any demand, we must reconcile to a single number.** I recommend standardizing on the spreadsheet's own per-row overage (931.62) or a cycle-specific computation (see Method D below).

### 4.3 Method B — "Last cycle + current cycle unpaid" (aggressive)
Adapts the framing Ravi used in CDC negotiations:
- Last cycle (Cycle 2, 5/2024 – 4/2025) "unpaid" = Cycle 2 Actual − Cycle 2 Billable (baseline × 12)
- Current cycle (Cycle 3, to date 5/2025 – 2/2026) unpaid = Cycle 3 Actual
- Result (rough, all roles): ~2,000 hrs × $150 = **~$300,000**
- **Strength:** None clean — this is a settlement-aggressive methodology, not a "contract as written" methodology
- **Weakness:** Not supported by clause text; treats Cycle 3 billable baseline as unpaid when those invoices were issued and paid. Likely abandoned at first motion practice.

### 4.4 Method C — Life-of-contract net (our settlement offer basis)
- Formula: (Σ all Actual) − (Σ all Billable) across all roles, allowing negatives to offset positives
- Result: **134.84 hrs × $150 = $20,226.00**
- **Ravi's 3/23 settlement offer was 100.30 hrs × $150 = $15,045.00** — a further concession from even Method C
- **Strength:** Intuitive fairness; includes the negative drag of IRV-TS1 (which ran under baseline by 108.66 hrs, a net credit to BST)
- **Weakness:** Not explicitly authorized by clause language (the clause says "any hours that exceeded" — not net). Presented only as an alternative settlement methodology, not contract-compelled.

### 4.5 Method D — Cycle-3 termination-cycle only
- Formula: Σ max(0, Actual − Billable) for months 5/2025 – 4/2026
- Result: **0.00 hrs × $150 = $0.00** (every Cycle-3 row is under baseline)
- **Strength:** Narrowest textual reading — "the previous under contract period average" most naturally refers to the *current* period's baseline
- **Weakness:** Under this reading, termination in a low-consumption cycle erases liability for prior-cycle excess. Likely arguable for BST's counsel.

### 4.6 Method E — Cycle-2 (middle cycle) observation
Cycle 2 alone (5/2024 – 4/2025) was the primary over-consumption cycle:

| Role | Cycle 2 Actual | Cycle 2 Billable (12 × baseline) | Overage |
|---|---:|---:|---:|
| CHD-TS1 N | 716.89 | 354.00 | +362.89 |
| CHD-TS1 AH | 398.14 | 189.96 | +208.18 |
| IRV-TS1 N | 102.42 | 99.72 | +2.70 |
| **Cycle 2 total** | **1,217.45** | **643.68** | **+573.77** |

At $150/hr: **$86,065.50** was the at-cycle-end reconciliation exposure. But **Cycle 3's baseline-reset mechanism is itself the contract's reconciliation for that overage** (baselines jumped from 29.50 → 56.59, 15.83 → 33.70, 8.31 → 12.56). Clause ¶ 3 states "The first month of the new average will be charged at the previous average" — this is the pricing-in mechanism. So Cycle 2's overage was (at least partially) absorbed by Cycle 3's higher baseline billed rate.

### 4.7 Summary table

| Method | Hrs | $ | Posture |
|---|---:|---:|---|
| A — per-row overage, full contract | 931.62 | $139,743.00 | Contract (literal) |
| A — as stated to client 3/19 | 842.95 | $126,442.50 | Contract (our invoiced figure) |
| B — last+current unpaid | ~2,000 | ~$300,000 | Aggressive settlement only |
| C — life-of-contract net | 134.84 | $20,226.00 | Fair-settlement / alternative |
| **3/23 offer open to Jeff** | **100.30** | **$15,045.00** | **Goodwill settlement** |
| D — termination-cycle only | 0.00 | $0.00 | Narrowest literal reading |
| E — Cycle-2 overage alone | 573.77 | $86,065.50 | Historical; already reconciled via baseline reset |

---

## 5. Ancillary Final-Invoice Items (§ 4.05)

Regardless of the cancellation-fee number, BST owes under § 4.05:

| Item | Amount | Status |
|---|---:|---|
| March 2026 monthly invoice (invoice #28143) | (on record) | Issued, standard monthly |
| April 2026 monthly invoice (through 4/30) | (due 4/1/2026, invoice #27949) | Issued |
| Cancellation Fee invoice #28064 ("Service Cancellation") | (per methodology) | Issued 3/23 per Ravi email |
| Any outstanding pre-notice invoices | (verify A/R) | To confirm with billing |
| Remaining annual license balances, if any | (per Technijian determination) | To be calculated |

**Operational posture per Ravi's 3/17 email:** "Based on 30-day termination your service end date is 4/30. So you will receive the 4/1 invoice for services for April. Also, I will need to determine any unpaid support hours that will be billed as your cancellation of services fee per the contract." That email puts BST on notice of *both* the April-month services obligation and the upcoming cancellation fee calculation.

---

## 6. Counsel's Risk Lens — What BST's Attorney Will Argue

Expected defenses, with our best response:

### 6.1 "Clause is an unenforceable penalty / liquidated damages"
- Framework: Cal. Civ. Code § 1671(b); *Ridgley v. Topa Thrift* (1998) 17 Cal.4th 970; *Garrett v. Coast & Southern Fed. S&L* (1973) 9 Cal.3d 731.
- Our response: $150/hr is Technijian's published remote hourly rate (compare IRV-TS1 at $125/hr, IRV-AD1 at $200/hr); clause is **compensatory**, not punitive. It recoups actual excess labor consumed above the average the monthly fee was priced against.
- **Key distinction from VTD:** BST was shown the $150/hr rate in the invoice template the entire 36 months and never objected.

### 6.2 "Hours records aren't accurate"
- Our response: Weekly zero-dollar invoices with 30-day dispute window (per § 3.01) — **zero disputes across 36 months and ~150 weekly invoices**. Course of dealing + account stated (see Case Law Memo §§ 6-7).

### 6.3 "Clause is ambiguous — resolve against drafter"
- Our response: *Civ. Code § 1654* is a last-resort canon. *Pacific Gas & Elec. v. GW Thomas Drayage* (1968) 69 Cal.2d 33 permits parol evidence of meaning, but the clause is operationally clear: (i) 12-month cycles, (ii) baseline = prior-cycle average, (iii) overage hours charged at $150.

### 6.4 "Cycle 3 has no overage — so no fee"
- **Our weakness.** Under the strictest Method D reading, $0 is arguable.
- Our best response: The clause says "any hours that exceeded *the previous under contract period average*" — meaning the Cycle 2 → Cycle 3 reset baseline. Actual Cycle 3 consumption *vs the baseline that was actually billed* in Cycle 3 is the relevant measure. Even then, Cycle 3 shows no overage, so this is a genuine hurdle.
- **Mitigation:** Pivot to Method A's life-of-contract read — the clause does not limit to the termination cycle; it says "any hours that exceeded." Ravi's 3/19 position aligns with Method A.

### 6.5 "Clause is waived by performance / modification"
- Likely surfaces if BST points to any Technijian statement that overages would not be collected. Nothing on record suggests such waiver. If raised, we rely on § 6.12 (integration / modifications only in writing) of the signed MSA.

### 6.6 "Tech Heights already doing the work — mitigate damages"
- Our response: This is a cancellation-fee claim for past services rendered and documented, not a future-services claim. Mitigation doctrine inapplicable (*Shaffer v. Debbas* (1993) 17 Cal.App.4th 33 — mitigation required only for *future* performance).

---

## 7. Settlement Posture / Recommended Bands

Given (a) BST's counsel now involved, (b) Cycle 3 = $0 under narrowest read, (c) our prior $15,045 offer already on the table:

| Band | Amount | Rationale |
|---|---:|---|
| **Anchor / first position** | **$126,442.50** | Matches Ravi's 3/19–3/23 invoice position; already served |
| First concession | $60,000 – $80,000 | Midpoint between invoice and settlement offer; defensible as "Cycle 2 + partial Cycle 3" |
| Landing zone | $30,000 – $50,000 | Splits the baby above Method C |
| Current standing offer | **$15,045** (open through 4/30) | Ravi's 3/23 email — concession already on the table |
| Walk-away floor | $15,045 | Do not go below the standing offer; if BST counsel stalls past 4/30, withdraw and reassert full $126,442.50 |
| Internal ceiling | $139,743.00 | Method A maximum — no theoretical basis to exceed this |

**Recommendation:** If BST counsel contacts Ed and opens in good faith before 4/30, agree to hold the $15,045 offer open through a 15-day extension in exchange for written acceptance. If no counsel contact by 4/30 COB, withdraw the concession by operation of the 3/23 email's stated deadline and revert to the $126,442.50 invoice as the controlling figure.

---

## 8. Ancillary Exposure — Tech Heights / Renwick "Rich" Leggett

This is a separate cause of action to be preserved but not merged into the termination negotiation. Key facts:

### 8.1 Leggett is an ex-Technijian employee
- Multiple emails in the thread (Ravi to Ed, 2026-03-19): "Ex-Employee has taken two of my clients to his new company who also stole a client in the past."
- Leggett signs from `rleggett@techheights.com`; appears as successor-provider contact for BST.
- Ravi's email to Jeff 3/17 CCs Rich Leggett — meaning the transition hand-off was already happening by the notice date.

### 8.2 Suspected system tampering 2026-04-01
- Per Technijian support email to Jeff 4/1, re VPN issue: *"the BST-HQ-AD-01 Active Directory server is down. We also observed that someone appeared to be working on the backend last evening, possibly from Tech Heights, after which the server became unavailable. ... it appears that the ESXi host password has been changed, and we no longer have access to log in..."*
- Jeff's response (4/1): "your company has refused to cooperate so we are proceeding without your support" — confirms knowledge of the Tech Heights access.

### 8.3 Potential tort/statutory claims (preserve only)
- **Tortious interference with contract** against Tech Heights — if Tech Heights knew of Technijian's MSA with BST and induced termination or impaired performance (*Pacific Gas & Elec. v. Bear Stearns* (1990) 50 Cal.3d 1118).
- **Intentional interference with prospective economic advantage** (*Korea Supply v. Lockheed Martin* (2003) 29 Cal.4th 1134).
- **Breach of fiduciary duty / duty of loyalty** against Leggett personally, if under Technijian employment agreement with confidentiality/non-solicit terms (*Huong Que v. Luu* (2007) 150 Cal.App.4th 400).
- **Computer Fraud and Abuse Act**, 18 USC § 1030(a)(5) — unauthorized access and alteration (ESXi password change locking Technijian out).
- **California Penal Code § 502 (CDAFA)** — knowing access without permission; civil remedy under § 502(e).
- **Anti-hire clause (contract)** — § of MSA imposes 2-year / 50%-salary penalty if *BST* hires a Technijian employee directly. Direct hire of Leggett by BST is not on record (Leggett hired by Tech Heights). Clause may reach "indirect" hires on a tortious-interference theory; plain-language reads narrowly.

### 8.4 Reservation of rights
Any settlement of the cancellation fee **must expressly reserve rights** on the above tort/statutory claims. Draft settlement language for Ed's review:

> *"Nothing in this settlement shall release, waive, or compromise any claim Technijian may have against any third party (including without limitation Tech Heights and/or Renwick Leggett), or against The Boston Group, Inc. to the extent arising from any such third party's conduct, including claims for tortious interference with contract or prospective economic advantage, breach of fiduciary duty, or violation of 18 U.S.C. § 1030 or Cal. Penal Code § 502."*

---

## 9. Open Items for Ed

1. **Reconcile 842.95 (Ravi 3/19) vs 931.62 (recalc) to one defensible number before any demand is served.**
2. **Decide posture on the 4/30 deadline** — extend, withdraw, or convert to formal demand letter.
3. **Decide whether to preserve Tech Heights/Leggett claims via separate demand** before BST settles (statute of limitations timing).
4. **Determine whether to amend the 3/23 invoice** for any role-by-role detail requested by BST's counsel (invoice #28064 "Service Cancellation" was flat-amount; supporting schedule available in `bst_actualvsbillable.xlsx`).
5. **Confirm whether BST has paid the March or April monthly invoices** (invoice #27949, #28143, #28112) — current A/R status drives settlement leverage.
6. **Identify BST's attorney.** Jeff's 3/23 email says "our attorney is reviewing the contract" but provides no name; follow-up to Jeff: *"Please confirm the name, firm, and contact of counsel so future communications can be directed appropriately."*

---

## 10. Supporting Exhibits (attached to Ed's package)

1. `Boston_Group-Monthly_Service-signed (2).pdf` — signed MSA (DocuSign FC626837-AEED-442F-9961-A81502402FC4)
2. `bst_actualvsbillable (1).xlsx` — source hours data (also `.csv` in attachments/)
3. `emails/` — 109 messages spanning 2026-01-16 through 2026-04-14 (see `emails_index.csv`)
4. `attachments/` — 22 downloaded attachments incl. Service Cancellation invoice (#28064), Monthly Invoices (#27890, #27949, #28112, #28143), signed MSA PDF
5. `BST_SETTLEMENT_POSITION_MEMO.md` — position letter suitable for transmission to BST counsel
6. `BST_CASE_LAW_MEMO.md` — California authority (liquidated-damages/penalty, account stated, course of dealing, tortious interference, CFAA/CDAFA)
7. `BST_EMAIL_TO_SUSOLIK.md` — cover brief to Ed

---

## 11. Document Handling Reminders

- **This document is attorney-client privileged / attorney work product. Do not disclose to BST, Jeff Klein, or BST's counsel.**
- Only the Settlement Position Memorandum is drafted for eventual transmission to BST counsel. The numbers in that memo should match Method A ($126,442.50 invoice / $15,045 settlement offer).
- All case citations should be Shepardized before any filing or demand letter.
- Keep the $15,045 concession characterized consistently as "without prejudice" and "open through 4/30" across all future correspondence.
