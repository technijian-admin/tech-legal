# Briefing to Frank Dunn — VTD Cancellation Fee Math + Trap in Stambuk's Argument

**To:** Franklin T. Dunn, Esq. — Callahan & Blaine, PC
**Cc:** Edward Susolik, Esq.
**From:** Ravi Jain, CEO, Technijian, Inc.
**Re:** *Technijian, Inc. v. Vintage Design, LLC* — Response framework for Shaia Stambuk (Baker & Hostetler) and the data-room population
**Date:** April 28, 2026

> **ATTORNEY-CLIENT PRIVILEGED / WORK PRODUCT — Confidential**

---

## TL;DR

Stambuk's April 6 letter argues my June 24, 2025 email to Erica Garcia "limits" Technijian to a 2024–2025-only cancellation fee — about $52,765 — because the email mentions a 12-month averaging cycle. **Her argument has a fatal internal trap that flips the math against her**:

1. She concedes a "chain" mechanism — that the 2024–2025 cycle's elevated billing "collected" 2023–2024's excess.
2. Applied consistently, that same chain says the 2025 (terminated) cycle should have collected 2024–2025 — but the 2025 cycle was cut short at 3 of 12 months. And there is no 2026 cycle to collect 2025.
3. **Result under her own theory: Technijian is owed 2,344.87 hours × $150 = $351,730.50, plus 10% late fee = $386,903.55.** That is $146,416 *higher* than our Demand of $240,487.50.

So she has two doors and both favor us:
- **Door A — her chain premise is wrong** → averaging is prospective rate-setting only; nothing was "collected"; the full Demand of $240,487.50 stands.
- **Door B — her chain premise is right** → applied consistently it produces $386,903.55, more than the Demand.

There is no internally consistent reading of her argument that produces a number below the Demand. She picked an arbitrary stopping point that happens to help her at the P1/P2 boundary and ignores the same logic at the P2/P3 and P3/P4 boundaries.

---

## 1. Anchor numbers (signed 5/4/2023 Vintage Design Agreement)

From the reconciliation spreadsheet `vtd_actual_vs_bill.xlsx`:

| Period | Months | Billed | Actual | Billing rate set to |
|---|---|---:|---:|---|
| **P1** — May 2023 – Apr 2024 | 12 | 960.00 | 1,970.97 | Original contract (80 hrs/mo) |
| **P2** — May 2024 – Apr 2025 | 12 | 2,025.08 | 2,584.18 | P1 actual average |
| **P3** (terminated) — May–Jul 2025 | **3 of 12** | 624.25 | 384.94 | P2 actual average |
| **P4** — would have been May 2026–Apr 2027 | **0 of 12** | 0 | 0 | Would have been P3 actual average |

Cancellation rate: **$150/hr**. Late fee: **10%** (Other Terms ¶ 3).

---

## 2. The June 24, 2025 email — verbatim (Stambuk's anchor document)

The full thread is preserved at `terminated-clients/VTD/emails/message-1-1537054.eml`. Ravi's substantive paragraph from June 24, 2025 at 8:42 AM, in full:

> "Erica
>
> Based on the lifetime of the contract and the contract terms you were set on a 12 month cycle. **That means every 12 months we adjust the average to collect the last 12 months of actual support.** While we allow 30 day termination, you were on the 1st month of the next cycle currently. So to allow the 30 day termination we calculate all the hours billed to you versus the actual hours of support given. **Any actual hours that have not been billed are billed at the hourly rate of $150 per hour.**
>
> **I have attached a spreadsheet that shows these hours since we started working with you.**
>
> [...]
>
> Based on this analysis and accounting for the july 1 invoice, **the number of actual hours of support that have not been billed are 1,143.98. This at $150 per hour would be a cancellation fee of $171,597.00.**"

**Two facts Stambuk omitted from her quote:**

1. **Ravi calculated from "since we started working with you"** — i.e., from May 2023, P1 included. The 1,143.98-hour figure is a multi-period total. Stambuk is reading "the last 12 months" out of context and ignoring the very next paragraph.
2. **The "collect the last 12 months" sentence describes how the per-month billing rate is *re-set going forward*, not a representation that prior excess was retroactively paid.** The very next sentence describes the *separate* cancellation calculation: "all the hours billed to you versus the actual hours of support given. Any actual hours that have not been billed are billed at the hourly rate of $150 per hour."

---

## 3. Stambuk's argument (April 6, 2026 letter to Ed)

Verbatim from her letter (forwarded by you 4/28):

> "In our view, Ravi's email limits Technijian to seeking payment for time allegedly incurred in the prior under contract period of 2024-2025, rather than 2023-2024, as Ravi stated that 'every 12 months we adjust the average to collect the last 12 months of actual support.' In our view, Ravi's email supports that Technijian has already collected what it believes it is owed for the 2023-2024 period."

She also asserts that "Jenna agreed that excluding the 2023-2024 period would be a reasonable and accurate interpretation."

Translated: the 2024–2025 elevated billing rate "collected" 2023–2024's excess; therefore P1 is off the table; therefore recoverable = P2 + P3 excess only ≈ 319.79 hrs × $150 ≈ $52,765 (this is Scenario E2 in our internal model).

---

## 4. The chain trap — visualized cycle-by-cycle

Stambuk's premise: **"averaging at a cycle boundary collects the prior cycle's excess"**.

Apply that mechanic consistently across every boundary the contract creates:

```
         BILLING-RATE CHAIN (Stambuk's premise, applied as written)

   ┌───────────────────────────────────────────────────────────────────┐
   │ P1  May 2023 – Apr 2024   Billed 960.00   Actual 1,970.97         │
   │      (rate = original contract, 80 hrs/mo)                        │
   └──────────────────────────┬────────────────────────────────────────┘
                              │ at cycle boundary, rate adjusts to
                              │ P1 actual avg (164.25 hrs/mo)
                              ▼
   ┌───────────────────────────────────────────────────────────────────┐
   │ P2  May 2024 – Apr 2025   Billed 2,025.08   Actual 2,584.18       │
   │      (rate = P1 actual avg)                                       │
   │      P2 ran 12 of 12 months at the elevated rate ⇒ P1 fully       │
   │      "collected" under Stambuk's premise. ✓ (she concedes)        │
   └──────────────────────────┬────────────────────────────────────────┘
                              │ at cycle boundary, rate adjusts to
                              │ P2 actual avg (215.35 hrs/mo)
                              ▼
   ┌───────────────────────────────────────────────────────────────────┐
   │ P3  May 2025 – Jul 2025   Billed 624.25   Actual 384.94           │
   │      (rate = P2 actual avg)                                       │
   │      *** TERMINATED AFTER 3 of 12 MONTHS ***                      │
   │      Only 3/12 of P2 actuals were "collected" through P3 billing. │
   │      P2 is therefore PARTIALLY collected, not fully collected.    │
   └──────────────────────────┬────────────────────────────────────────┘
                              │ at cycle boundary, rate WOULD HAVE
                              │ adjusted to P3 actual avg
                              ▼
   ┌───────────────────────────────────────────────────────────────────┐
   │ P4  (May 2026 – Apr 2027)  NEVER HAPPENED                         │
   │      0 of 12 months at the would-be elevated rate.                │
   │      P3 actuals were therefore NEVER collected.                   │
   └───────────────────────────────────────────────────────────────────┘
```

What is **uncollected at termination**, under Stambuk's own premise:

| Cycle | What was supposed to collect it | What actually collected | Uncollected hours |
|---|---|---|---:|
| **P1** | P2 billing (12 of 12 months at P1 rate) | Full | 0 |
| **P2** | P3 billing (12 of 12 months at P2 rate) | Only 3 of 12 → 624.25 hrs | **2,584.18 − 624.25 = 1,959.93** |
| **P3** | P4 billing (would have been 12 of 12) | 0 of 12 → 0 hrs | **384.94 − 0 = 384.94** |
| **TOTAL** | | | **2,344.87 hrs** |

`2,344.87 × $150 = $351,730.50` → with 10% late fee → **$386,903.55**

Compare to the Demand: **$240,487.50**.

**Stambuk's own theory, applied symmetrically, owes us $146,416 *more* than we are asking.**

---

## 5. Why she has no escape route

She has three logical exits and all three favor us:

### Exit 1 — "The chain only runs one hop. P2 collects P1, but P3 doesn't collect P2."

**Fails because:**
- Nothing in the contract supports a one-hop limit. The averaging mechanism in Under Contract ¶¶ 3–4 describes the same adjustment at every cycle boundary, with identical language at each boundary.
- Ravi's June 24, 2025 email — Stambuk's own anchor — says "**every** 12 months we adjust the average." Not "once." Not "only at the first boundary." *Every*.
- A one-hop rule is pure outcome engineering — it stops the chain at exactly the spot that helps Vintage Design and nowhere else.
- *Powerine Oil Co. v. Superior Court* (2005) 37 Cal.4th 377, 390–391: contract terms are construed consistently and to give effect to every part. Stambuk's selective application violates this.

### Exit 2 — "The averaging is just a prospective rate adjustment; it does not 'collect' prior period excess."

**This is actually our position.** It produces the full Demand of $240,487.50:
- The averaging adjusts the per-month rate going forward; it does not retroactively forgive excess hours delivered but unbilled in the prior cycle.
- Cal. Civ. Code §§ 1638, 1641; *Powerine Oil*, supra; *MacKinnon v. Truck Ins. Exchange* (2003) 31 Cal.4th 635, 648.
- Under this reading, P1, P2, and P3 excess all roll into the cancellation fee at termination.
- **If Stambuk retreats here, she abandons her April 6 letter and we are at the Demand.** We win that exchange.

### Exit 3 — "Cancellation fee is limited to the period of termination only."

That is **Scenario E1**, which gives $0 because P3 under-ran P3 billing. But:
- Contract text: "**any** hours that exceeded **the previous** under contract period average" — *previous*, not *current*. The clause expressly reaches prior periods.
- Reading the cancellation fee to reach only the terminated cycle would render the clause a dead letter (clients almost always terminate after a spike has subsided). Cal. Civ. Code § 1641 forbids that.
- Ravi's own June 24, 2025 email — *Stambuk's anchor* — calculates from "since we started working with you," not just from the termination period. She cannot rely on that email and contradict its method.

---

## 6. Recommended response language to Stambuk

> "Counsel — your April 6 position relies on the premise that the averaging mechanism in the Client Monthly Service Agreement 'collected' 2023–2024 excess via 2024–2025 billing. That premise has two readings, both of which favor Technijian's Demand:
>
> 1. **If the mechanism does collect**, it collects at *every* cycle boundary — that is what Mr. Jain's June 24, 2025 email expressly describes (*'every 12 months we adjust the average to collect the last 12 months of actual support'*) and what the contract text in Under Contract ¶¶ 3–4 provides identically at every boundary. Applied consistently:
>    - P2 collected P1 (12 of 12 months at the elevated rate). ✓
>    - P3 was supposed to collect P2 over 12 months — but ran only 3, leaving 2,584.18 − 624.25 = 1,959.93 P2 hours uncollected.
>    - P4 was supposed to collect P3 over 12 months — but never started, leaving 384.94 P3 hours uncollected.
>    - Total uncollected: 2,344.87 hours × $150 = $351,730.50, plus 10% late fee = **$386,903.55**.
>    That figure is $146,416 above the Demand and is the *floor* implied by your own theory.
>
> 2. **If the mechanism does not collect** — as Technijian maintains, supported by Cal. Civ. Code §§ 1638 and 1641, *Powerine Oil Co. v. Superior Court* (2005) 37 Cal.4th 377, 390–391, and *MacKinnon v. Truck Ins. Exchange* (2003) 31 Cal.4th 635, 648 — then the averaging is a prospective rate-setting tool only, prior-period excess remains uncollected by it, and the full Demand of **$240,487.50** stands.
>
> There is no internally consistent reading of your premise that produces a number below the Demand. Mr. Jain's email itself contemplates this: he calculated 1,143.98 unbilled hours from 'since we started working with you' — i.e., the multi-period total — not from a 'last 12 months only' reading.
>
> We invite you to identify any internally consistent reading that lands below the Demand. Otherwise we will proceed on the Demand and reserve the chain-extended figure as the contingent fallback at hearing."

That is the wedge. We do not have to win the chain argument on the merits — we just have to make Stambuk choose, and every door she walks through costs her more than $52,765.

---

## 7. Data-room population

For the data room you described, here is my proposed upload list, in order of importance. I will not upload our internal damages scenario analysis (it discusses our walk-away floor) — that stays attorney-eyes-only.

| Tier | File | Why it matters |
|---|---|---|
| 1 | `Vintage_Design-Monthly_Service.pdf` (signed 5/4/2023 Agreement) | Source of cancellation clause and § 1671(b) burden allocation |
| 1 | `vtd_actual_vs_bill.xlsx` | The reconciliation that drives every scenario |
| 1 | `vtd_TicketTimeEntries_2023-01-01_to_2026-04-14.xlsx` | The ticket-by-ticket evidence backing every actual hour |
| 1 | `message-1-1537054.eml` (full June 24, 2025 thread) | Stambuk's own anchor — and our refutation of her reading |
| 2 | 4 monthly invoice .eml files (#25438, 25725, 25953, 26205) | POD-column disclosure pattern; 88–96% offshore allocation |
| 2 | 3 weekly invoice samples (#25992, 26029, 26074) | Weekly transmission pattern |
| 2 | `Settlement_Position_Memorandum.docx` | Master positioning |
| 2 | `Case_Law_Upgrade_Research_2026-04-17.docx` | 2020–2026 authorities (already with Ed) |
| 3 | Termination notice (June 23, 2025 Erica email) and final invoice (#26205, July 1, 2025) | Bookends the timeline |

**Withheld (internal only):** `Damages_Scenario_Analysis_INTERNAL.docx` — contains the walk-away floor and the Scenario D ceiling.

---

## 8. What I'd like to confirm on our 3:30 call

1. Anchoring the response to Stambuk on the Demand ($240,487.50) and using the chain-extended $386,903 figure as a contingent fallback — not as the opening number.
2. Keeping Scenario D ($309,980.55) entirely internal — it is our reserved ceiling, not for outward use.
3. Whether to file a Demand amendment under AAA Rule R-6 to fix the $67.65 arithmetic error on the late-fee line now, or fold the correction into the settlement stipulation.
4. Sign-off on the §6 language above before I share any version externally.

— Ravi
