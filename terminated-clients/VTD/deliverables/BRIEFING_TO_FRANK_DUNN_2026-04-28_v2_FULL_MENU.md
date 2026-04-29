# Briefing v2 to Frank Dunn — Full Menu of Readings of the VTD Cancellation Clause

**To:** Franklin T. Dunn, Esq. — Callahan & Blaine, PC
**Cc:** Edward Susolik, Esq.
**From:** Ravi Jain, CEO, Technijian, Inc.
**Re:** *Technijian, Inc. v. Vintage Design, LLC* — Comprehensive reading menu for the 3:30 call; response framework for Stambuk
**Date:** April 28, 2026

> **ATTORNEY-CLIENT PRIVILEGED / WORK PRODUCT — Confidential**

---

## TL;DR

The signed Client Monthly Service Agreement's "Under Contract" section is short — five paragraphs of substantive text — and it can be read in **eight different ways** that produce results from $0 to $386,903. This brief lays out all eight so we can pick the lead position and the contingent fallbacks before the 3:30 call.

The two strongest plain-text-grounded positions for Technijian are:

1. **Course-of-performance / ratification reading** — 27 months of paid invoices at the elevated averaged rate, no objection from Erica Garcia (VP Finance). Anchors at the **Demand: $240,487.50**.
2. **Matching-duration reading** — the contract expressly chose **12 months** as the averaging period (¶ 1). That choice means the averaging "collection" mechanism is a 12-month process. P3 ran only 3 of 12 months; P4 never ran. Result: **$386,903.55** (chain-extended). Strongest fallback.

Both Stambuk's E2 reading (~$52,765) and the textual-strict reading ($0) require silently overriding the contract's plain duration choice or its course-of-performance gloss. We have at least four arguments against each.

---

## 1. Verbatim Contract Text — Under Contract ¶¶ 1–5 (signed 5/4/2023, page 4)

> **Under Contract**
> Under contract support is defined as support that will be charged monthly based on the average number of hours used, under the following conditions:
>
> 1. **The under-contract period shall be 12 Months.**
> 2. **A new average will be calculated after each under contract period.**
> 3. **The first month of the new average will be charged at the previous average since that invoice will be due the first of the month.**
> 4. **If the average goes down a credit will be given on the next month's invoice. If the average goes up an extra charge will be given on the next month's invoice.**
> 5. If this agreement is terminated, **any hours that exceeded the previous under contract period average, that were documented through ticketing, will be charged at a rate of $150 per hour** and will be assessed as the cancellation fee to the client and due before agreement is terminated.

(POD Specifications, same page, set the *initial* monthly hours: CHD-TS1 OS Support 40 hrs/mo @ $15; CHD-TS1 OS Support.AH 20 hrs/mo @ $30; IRV-TS1 Tech Support 20 hrs/mo @ $125. Total initial = 80 hrs/mo.)

---

## 2. Anchor Hours (from `vtd_actual_vs_bill.xlsx`)

| Period | Span | Months | Billed | Actual | Billing rate set to |
|---|---|---:|---:|---:|---|
| **P1** | May 2023 – Apr 2024 | 12 | 960.00 | 1,970.97 | Original (80 hrs/mo per POD Specs) |
| **P2** | May 2024 – Apr 2025 | 12 | 2,025.08 | 2,584.18 | P1 actual average (~164.25 hrs/mo) |
| **P3** (terminated) | May – Jul 2025 | **3 of 12** | 624.25 | 384.94 | P2 actual average (~215.35 hrs/mo) |
| **P4** | Would have been May 2026 – Apr 2027 | **0 of 12** | 0 | 0 | Would have been P3 actual average |

Cancellation rate: **$150/hr**. Late fee: 10% (Other Terms ¶ 3, discretionary).

---

## 3. The June 24, 2025 Email — Verbatim (Stambuk's Anchor)

Full thread at `terminated-clients/VTD/emails/message-1-1537054.eml`. Ravi's substantive paragraph from June 24, 2025 at 8:42 AM, in full:

> "Erica
>
> Based on the lifetime of the contract and the contract terms you were set on a 12 month cycle. **That means every 12 months we adjust the average to collect the last 12 months of actual support.** While we allow 30 day termination, you were on the 1st month of the next cycle currently. So to allow the 30 day termination we calculate all the hours billed to you versus the actual hours of support given. **Any actual hours that have not been billed are billed at the hourly rate of $150 per hour.**
>
> **I have attached a spreadsheet that shows these hours since we started working with you.**
>
> [...]
>
> Based on this analysis and accounting for the july 1 invoice, **the number of actual hours of support that have not been billed are 1,143.98. This at $150 per hour would be a cancellation fee of $171,597.00.**"

**The framing in this email — important.** Ravi was treating the cancellation reconciliation as a **global lifetime calculation** (all hours billed vs. all hours actually delivered, since contract inception). Not a chain calculation, not a per-period reconciliation — a single global delta.

This matters for two reasons:
- It is the **simplest reading** of ¶ 5 and the one the parties contemporaneously implemented.
- The 1,143.98 figure preceded the final July invoices being booked. The settled multi-period total later resolved to **1,330.76 net** (Scenario A) or **1,457.50** as pleaded in the Demand.

---

## 4. Stambuk's Argument (4/6/2026 letter)

Verbatim:

> "In our view, Ravi's email limits Technijian to seeking payment for time allegedly incurred in the prior under contract period of 2024-2025, rather than 2023-2024, as Ravi stated that 'every 12 months we adjust the average to collect the last 12 months of actual support.' In our view, Ravi's email supports that Technijian has already collected what it believes it is owed for the 2023-2024 period."

She also says "Jenna [Griffin, since departed Callahan & Blaine] agreed that excluding the 2023-2024 period would be a reasonable and accurate interpretation."

Translated: averaging "collected" P1; therefore recoverable = P2 + P3 excess only ≈ 319.79 hrs × $150 ≈ **$52,765**.

---

## 5. Full Menu — Eight Readings of ¶ 5

Sorted from lowest to highest dollar result. Each entry shows the math, what it requires us or them to assume, and why it is or is not defensible.

### Reading A — Literal "previous" Singular = Period of Termination Only ($0)

**Math.** "The previous under contract period average" = the immediately preceding cycle (P2). At termination, compare hours actually delivered in the terminated period (P3) against P2's average. P3 actual (384.94) ≤ P3 billed at P2 average (624.25) → no excess.

**Result.** **$0** (Scenario E1).

**Why this reading exists.** ¶ 5 uses "the previous" — singular. ¶ 3 uses the same construction ("the previous average"). Read together, "previous" plausibly refers to one immediately-preceding cycle.

**Why it fails.**
- Cal. Civ. Code § 1641: a contract is read as a whole to give every part effect. This reading renders ¶ 5 a near-dead letter — clients almost always terminate after a usage spike has subsided. The clause would have no practical work to do. *Powerine Oil Co. v. Superior Court* (2005) 37 Cal.4th 377, 390–391.
- Course of performance: 27 months of paid invoices at the elevated averaged rate, with the elevated rate explicitly tied to "Hours not paid are due if support agreement is cancelled per monthly service agreement" (text on every monthly invoice page-1). Cal. Com. Code § 1303(a)–(b).
- Ravi's June 24, 2025 email — Stambuk's own anchor — calculated 1,143.98 across all periods, not the terminated period only.

**This is Frank's BST textual reading.** We have to assume Stambuk knows it and may pivot to it if her current E2 reading collapses.

---

### Reading B — Stambuk's E2: Averaging "Collected" P1, Recoverable = P2 + P3 Only ($52,765)

**Math.** P1 off the table because P2's elevated billing "collected" it. Recoverable = P2 excess (559.10) + P3 deficit (–239.31) = 319.79 hrs.

`319.79 × $150 + 10% = $52,765.35`

**Why this reading exists.** It seizes on Ravi's "every 12 months we adjust the average to collect the last 12 months" phrase and reads "collect" as discharging prior period obligations.

**Why it fails.**
- The contract never uses "collect" or any synonym. ¶¶ 3–4 describe a forward-looking billing-rate adjustment with a one-month transitional credit/extra charge, not retroactive collection of prior period excess.
- The phrase Stambuk relies on is in Ravi's email, not in the contract — and the very next sentence in the email contradicts her reading: "we calculate all the hours billed to you versus the actual hours of support given. Any actual hours that have not been billed are billed at the hourly rate of $150 per hour." That is a global lifetime calculation, not a P2-only reading.
- It stops the chain at exactly the boundary that helps Vintage. There is no principled stopping rule (see Reading G).

---

### Reading C — Native Rates Knockdown ($20,013.73)

**Math.** Net excess hours (1,330.76) charged at the original POD rates ($15 / $30 / $125) instead of $150. Net dollars: $18,194.30 × 1.10 = $20,013.73.

**Why this reading exists.** Cal. Civ. Code § 1671(b) penalty/liquidated-damages attack on the $150 cancellation rate.

**Why it fails.**
- § 1671(b) places the burden on Vintage to prove the rate "was unreasonable under the circumstances existing at the time the contract was made." *Ridgley v. Topa Thrift & Loan Assn.* (1998) 17 Cal.4th 970, 977.
- The Agreement's own Out-of-Contract rate table on the same page (page 4) lists IRV-TS1 Tech Support at **$150/hr onsite normal and $200/hr onsite after-hours**. The cancellation rate equals or undercuts the bargained out-of-contract rate. As a matter of law that is not a penalty. *El Centro Mall, LLC v. Payless ShoeSource, Inc.* (2009) 174 Cal.App.4th 58, 63; *Greentree Financial Group, Inc. v. Execute Sports, Inc.* (2008) 163 Cal.App.4th 495.
- Reasonableness assessed at formation, not in hindsight. Erica Garcia, VP Finance, initialed the page. Sophisticated commercial parties.

---

### Reading D — Ravi's June 24, 2025 Global Calculation ($171,597 / 1,143.98 hrs × $150)

**Math.** Global lifetime billed-vs-actual delta as Ravi computed it on the date he sent the email. 1,143.98 unbilled hours.

**Why this reading exists.** It is what Ravi actually did. It is on the record. It is the simplest reading of ¶ 5.

**Why it is a useful anchor but not the lead position.**
- It pre-dates the final July invoices. The settled lifetime number is higher (1,330.76 net or 1,457.50 as pleaded).
- Useful as a "we under-claimed at the time" data point. Confirms the parties' contemporaneous reading was multi-period, not single-period.
- Gives Stambuk a rhetorical foothold ("even Mr. Jain's own number was lower than yours"). We need to explain the resolution between 1,143.98 and the Demand 1,457.50 cleanly: completion of final July billing + corrected accounting of in-flight tickets.

---

### Reading E — Conservative Net Excess (Scenario A — $219,575.40)

**Math.** All three contracted categories' excess netted across the full contract life: 1,330.76 hrs × $150 + 10% = $219,575.40.

**Why it works.** Direct read of `vtd_actual_vs_bill.xlsx`. Most literally provable from spreadsheet.

**Use.** Fallback anchor if counsel prefers the most conservative spreadsheet-supported figure over the Demand's 1,457.5.

---

### Reading F — Demand on Record (1,457.50 × $150 = $240,487.50) ★ ANCHOR

**Math.** 1,457.50 hrs × $150 = $218,625.00 + 10% late fee = $240,487.50. Note: Demand pleaded $240,555.15; that figure has a $67.65 arithmetic error in the late-fee line that should be amended under AAA Rule R-6 or folded into the settlement stipulation.

**Why it works.**
- On the record. AAA-pled.
- Sits between Scenario B (gross positive) and Scenario D (monthly positive). Defensible.
- Aligns with the global lifetime methodology Ravi used in his June 24, 2025 email — just with final billing booked.

**Best Tier-1 anchor for negotiation and hearing.**

---

### Reading G — Matching-Duration / Chain-Extended ($386,903.55) ⭐ STRONGEST FALLBACK

**This is the new sharpening of the prior chain-trap.** The contract template offered the client a choice of **3, 6, or 12 months** as the under-contract cycle length, made at contract formation (¶ 1). Vintage chose **12 months**. That choice is the duration of the averaging "collection" mechanism. Anything shorter is incomplete collection.

**Math.**

| Cycle | Should collect | Actually collected |
|---|---|---|
| P2 (12 of 12 mo at elevated rate) | P1 actuals | Full ✓ |
| P3 (only 3 of 12 mo) | P2 actuals | 624.25 of 2,584.18 → **1,959.93 uncollected** |
| P4 (0 of 12 mo) | P3 actuals | 0 → **384.94 uncollected** |
| **Total** | | **2,344.87 hrs × $150 + 10% = $386,903.55** |

**Why this is structurally tighter than the prior chain-trap framing.**

The prior chain-trap relied on Stambuk's *premise* that averaging "collects." The matching-duration argument doesn't need her premise — it is grounded in the contract's express choice of 12-month period under ¶ 1:

> "Even on Respondent's own theory that the elevated billing rate captures the prior period's elevated demand, the duration of that capture is fixed by the contract at 12 months — Under Contract ¶ 1. The parties could have chosen 3 months or 6 months as the under-contract period. They chose 12. That choice has consequences. P3 ran only 3 of 12. P4 never ran at all. Under Respondent's own theory, applied symmetrically to its own structural choice, 1,959.93 hours of P2 actuals and 384.94 hours of P3 actuals were never collected. 2,344.87 × $150 + 10% = $386,903.55."

**Why it works as a fallback wedge.**
- Forces Stambuk to explain why the 12-month period choice in ¶ 1 has consequences for P1 → P2 (her concession) but not for P2 → P3 or P3 → P4.
- No textual reading lands below the Demand. Either (a) her premise is wrong (Reading F: $240,487 stands); or (b) her premise is right but the matching-duration math owes us $386,903.

**Why ¶¶ 3-4 read as a cycle-length mechanism (operational rationale).**

The seemingly awkward "first month of the new average" language has a specific operational reason rooted in **Other Terms ¶ 2** (page 4 of the signed Agreement, verbatim):

> "For Services rendered monthly, Client shall be invoiced on the **first day of previous month** due and payable by the first day of the current month of support."

That is **30-day advance invoicing on a net-30 basis**. The May invoice is generated and sent at the START of April. But the prior 12-month cycle does not finish until April 30. So when the May invoice has to be generated (early April), the cycle's last month has not completed yet — there is no finalized cycle average yet to apply.

¶ 3's solution: bill the first month of the new cycle (May) at the **previous** average. By the time the June invoice goes out (early May), Cycle 1 is fully closed and the new average is finalized — so ¶ 4 applies the delta (catch-up or credit) to that next invoice.

That gives the cycle this structural shape:

| Position in cycle | Billing basis | Source |
|---|---|---|
| **Month 1** | Previous cycle's average (transitional) | ¶ 3 |
| **Month 2** | New average + one-time delta charge/credit | ¶ 4 |
| **Months 3 through N** | New average (no further delta) | Implied; the cycle proper |

For a 12-month cycle (VTD's choice): **1 transitional month + 11 months at the new (elevated) rate**. For a 6-month cycle (an option clients can pick at formation): 1 + 5. For a 3-month cycle: 1 + 2.

The averaging adjustment is therefore a **cycle-length mechanism** — not a single-month true-up. The new (elevated) rate operates for the back portion of each cycle. For VTD, that is the back **11 of the 12** months.

**Why this defeats Stambuk's likely "one-month-only" counter.** She could argue ¶ 4's "next month's invoice" = a one-time delta charge that closes the prior cycle, with no further obligation owed. That reading collapses the moment you account for the operational rationale: the contract template offered Vintage 3-, 6-, or 12-month cycle options at formation. Vintage chose 12. The 12-month period choice in ¶ 1 governs the duration of the new-rate regime in months 2 through 12 — which Stambuk implicitly conceded by accepting that "P2's elevated billing collected P1's excess." She cannot accept that 12 months of P2 elevated billing collected P1, then turn around and argue the same 12 months is irrelevant for P3's collection of P2.

**Termination math under this clean reading:**

- P3 was supposed to run **11 months** at the elevated rate (June 2025 – April 2026), plus 1 transitional month (May 2025).
- P3 actually ran **2 months** at the elevated rate (June and July 2025), plus 1 transitional (May 2025).
- **9 elevated-rate months were never billed.** Most of P2's "collection via P3" never happened — not because of an inferred premise, but because the contract's own cycle-length mechanism was structurally cut short.

---

### Recommended Stipulation to Lock the Reading

Putting the cycle-as-mechanism reading on the record as a stipulation forecloses Stambuk's "one-month true-up" escape route:

> *"The parties stipulate that Under Contract ¶¶ 1–4, read in conjunction with Other Terms ¶ 2 (30-day advance invoicing on net-30), operate as a cycle-length mechanism: ¶ 1 fixes the under-contract cycle length, which the client selects at contract formation from the options provided by the template (3, 6, or 12 months); the parties to this Agreement selected 12 months. ¶ 2 calculates a new average after each cycle ends. ¶ 3 charges the first month of the new cycle at the previous cycle's average for invoice-timing reasons (the new cycle's first invoice must issue before the prior cycle has fully closed and its average been finalized). ¶ 4 applies the delta between old and new averages to the next month's invoice. Thereafter the new average governs billing for the remaining months of the cycle. The averaging adjustment is therefore a cycle-length mechanism — not a single-month true-up — and for this Agreement the new (elevated) rate operates for the back eleven months of each twelve-month cycle."*

Three things this stipulation accomplishes simultaneously:

1. **Locks ¶ 1's 12-month period as the controlling duration**, with the formation-time choice of 3/6/12 establishing the period as a deliberate structural variable.
2. **Forecloses the "one-month true-up" counter** by anchoring the cycle length in the template's design.
3. **Sets up the matching-duration math as inevitable** — once the cycle is the operative unit, P3's 3-of-12 truncation is structurally significant on the record.

If Stambuk refuses to stipulate, that refusal is itself useful — it forces her to articulate a competing reading, and the only available one (one-month true-up) is textually weak under ¶ 1 + ¶ 2 + Other Terms ¶ 2 read together.

---

### Reading H — Aggressive Monthly Positive (Scenario D — $309,980.55)

**Math.** Sum of monthly positive excess (1,878.67) × $150 + 10% = $309,980.55.

**Reading.** For each contracted category and each month, count only months where actual > billed. Do not credit under-run months against over-run months.

**Use.** Internal ceiling. Do not disclose. Sit it behind the Demand and the matching-duration figure as ultimate backup.

---

## 6. Defensive Stack — Five Arguments Against Reading A or B

These are the structural arguments that protect the Demand and the matching-duration fallback regardless of which textual nit Stambuk picks at:

| # | Argument | Authority | Effect |
|---|---|---|---|
| 1 | **Course of performance** — 27 months of paid elevated invoices, no objection | Cal. Com. Code § 1303(a)–(b); *Wagner v. Glendale Adventist Med. Ctr.* (1989) 216 Cal.App.3d 1379, 1388; *Kashmiri v. Regents* (2007) 156 Cal.App.4th 809, 833 | Establishes parties' agreed reading: multi-period reconciliation, not single-cycle |
| 2 | **Ratification by signatory** — Erica Garcia (VP Finance) personally paid each elevated invoice for 27 months | *Rakestraw v. Rodrigues* (1972) 8 Cal.3d 67, 73; *Pasadena Medi-Center* (1973) 9 Cal.3d 773 | Cures any signature-authority or interpretation-authority challenge |
| 3 | **Whole-contract construction** — narrow "previous" reading renders ¶ 5 a dead letter | Cal. Civ. Code § 1641; *Powerine Oil Co. v. Superior Court* (2005) 37 Cal.4th 377, 390–391; *MacKinnon v. Truck Ins. Exchange* (2003) 31 Cal.4th 635, 648 | Defeats Reading A |
| 4 | **§ 1671(b) burden on Vintage** to prove rate unreasonable at formation | *Ridgley v. Topa Thrift* (1998) 17 Cal.4th 970, 977; *Hitz v. First Interstate* (1995) 38 Cal.App.4th 274, 286–289 | Defeats Reading C; we don't have to defend $150 affirmatively |
| 5 | **60-day waiver in T&C § 3.01** — Vintage never objected to any monthly invoice | *Cobb v. Pacific Mut. Life Ins. Co.* (1935) 4 Cal.2d 565, 573 | Forecloses ticketing-accuracy attacks at hearing |

---

## 7. Recommended Hierarchy for the 3:30 Call

**Tier 1 — Lead with these in any response to Stambuk:**

1. Course-of-performance / ratification reading (Reading F at the Demand $240,487.50 anchor).
2. Whole-contract construction defeats Reading A.
3. § 1671(b) burden on Vintage defeats Reading C.

**Tier 2 — Secondary structural arguments:**

4. Stambuk's "collected" premise has no textual basis (defeats Reading B on the merits).
5. Matching-duration argument (Reading G) — applied if Stambuk insists on her own framing or shifts to the chain theory at hearing.

**Tier 3 — Internal-only ceilings, do not disclose:**

6. Scenario D ($309,980.55).
7. Walk-away floor ($125,000).

**Confronting the textual risk honestly.** ¶ 5's "previous" wording is a real textual hook for Reading A ($0). We do not pretend it isn't there. We answer it with course of performance, ratification, and § 1641. We do not anchor on a position that ignores the textual problem.

---

## 8. Recommended Response Language to Stambuk

Three drop-in paragraphs Frank or Ed can paste, depending on which reading we lead with.

### Option 1 — Course-of-Performance Lead (recommended Tier-1)

> "Counsel — Respondent's reading of Mr. Jain's June 24, 2025 email is foreclosed by 27 months of unobjected-to course of performance. Each monthly invoice from Technijian to Vintage Design carried, on its face, a Support History table identifying actual hours, billed hours, and 'unpaid hours due if support agreement is cancelled per monthly service agreement.' Mr. Jain's June 24, 2025 email itself states the operative method: 'we calculate all the hours billed to you versus the actual hours of support given. Any actual hours that have not been billed are billed at the hourly rate of $150 per hour.' That is a global lifetime calculation. Vintage paid each monthly invoice for 27 months without objection. Cal. Com. Code § 1303(a)–(b); *Kashmiri v. Regents* (2007) 156 Cal.App.4th 809, 833; *Wagner v. Glendale Adventist Med. Ctr.* (1989) 216 Cal.App.3d 1379, 1388. The Demand of $240,487.50 (subject to the $67.65 late-fee correction under AAA Rule R-6) sits squarely within that course-of-performance reading."

### Option 2 — Matching-Duration Wedge (Tier-2 fallback)

> "Counsel — Respondent's reading depends on the premise that the averaging mechanism in Under Contract ¶¶ 3–4 'collected' 2023–2024's excess via 2024–2025's elevated billing rate. The duration of that 'collection' is not Respondent's choice — it is fixed by ¶ 1: 'The under-contract period shall be 12 Months.' The parties could have chosen 3 months or 6 months. They chose 12. By Respondent's own theory, applied symmetrically to that structural choice: P2 ran a full 12 of 12 months at the elevated rate, fully collecting P1 (Respondent concedes this); P3 ran only 3 of 12 months, leaving 1,959.93 of P2's 2,584.18 actuals uncollected; P4 never started, leaving 384.94 of P3's actuals uncollected. 2,344.87 × $150 + 10% = $386,903.55 — $146,416 above the Demand. Respondent has no principled basis to apply the 12-month duration choice to the P1/P2 boundary but not the P2/P3 or P3/P4 boundaries."

### Option 3 — Whole-Contract Construction (Tier-2 against Reading A)

> "Counsel — to the extent Respondent reads ¶ 5's 'the previous under contract period average' as limited to the immediately preceding cycle, that reading renders ¶ 5 a dead letter. Clients almost invariably terminate after a usage spike has subsided. A cancellation clause that reaches only the terminated cycle would have no practical work to do. Cal. Civ. Code § 1641 forecloses that reading. *Powerine Oil Co. v. Superior Court* (2005) 37 Cal.4th 377, 390–391; *MacKinnon v. Truck Ins. Exchange* (2003) 31 Cal.4th 635, 648."

---

## 9. Data-Room Population (unchanged from v1)

Tier 1 (must-haves) + Tier 2 (supporting). Internal damages-scenario analysis withheld.

| # | File | Why it matters |
|---|---|---|
| 01 | Ravi-Erica 2025-06-24 termination thread (full) | Stambuk's own anchor + our refutation |
| 02 | VTD reconciliation (`vtd_actual_vs_bill.xlsx`) | Drives every reading |
| 03 | Signed 5/4/2023 Client Monthly Service Agreement | Source of ¶¶ 1–5 + § 1671(b) burden |
| 04 | Lifetime ticket time entries | Ticket-by-ticket evidence |
| 05–08 | 4 monthly invoice .eml files (POD evidence) | 88–96% offshore allocation |
| 09–11 | 3 weekly invoice samples | Weekly transmission pattern |

Withheld (internal only): `Damages_Scenario_Analysis_INTERNAL.docx`.

---

## 10. Talking Points for the 3:30 Call

1. Confirm the Tier-1 anchor: course of performance + ratification → Demand $240,487.50.
2. Confirm matching-duration ($386,903.55) as the Tier-2 wedge if Stambuk insists on her chain theory.
3. Confirm Scenario D ($309,980.55) and the $125K walk-away floor are internal-only.
4. Decide whether to file the AAA Rule R-6 amendment now to fix the $67.65 late-fee error, or fold it into settlement stipulation.
5. Sign-off on Option 1 / Option 2 / Option 3 response language above before any external use.
6. Schedule the data-room upload (11 files / 3.48 MB) — propose I run it in the next 24 hours after we close on which version of the response to send.

— Ravi
