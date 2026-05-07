# TALY Invoice Review — Talley & Associates (DirID 7728)

**Generated:** 2026-05-06
**Source:** Client Portal API (live pull) + `07_Assessments/Data_20260506_094149.xlsx`
**Re-run:** `python3 _pull-invoices.py` from this folder.

---

## Contract snapshot

| Field | Value |
|-------|-------|
| Contract ID | 5185 — "Monthly Support" |
| Type / Term | Net30, advance billing (May 1 invoice covers June service) |
| Monthly fixed rate | $0.00 (this is a usage + commit model, not a flat MSP fee) |
| Over-contract hours rate | **$150/hr** |
| Contract end date | **2025-04-29** — already past; on month-to-month rollover |

> **Renegotiation leverage flag:** the contract has expired and is auto-renewing month-to-month. Right time to re-paper labor commit tiers.

---

## Last 6 monthly recurring invoices

| Inv# | Issued | Service Mo | Total | US-Rem-N | India-N | India-AH | Status |
|-----:|--------|-----------|------:|---------:|--------:|---------:|--------|
| 27270 | 2025-12-01 | Jan 2026 | $650.65 | 1.38h × $125 | 2.75h × $15 | 1.38h × $30 | (older) |
| 27513 | 2026-01-01 | Feb 2026 | $597.65 | 1.38h × $125 | 2.75h × $15 | 1.38h × $30 | (older) |
| 27692 | 2026-02-01 | Mar 2026 | $770.05 | 1.38h × $125 | 2.75h × $15 | 4.86h × $30 | Paid |
| 27954 | 2026-03-01 | Apr 2026 | $1,046.10 | **3.63h** × $125 | 2.75h × $15 | **5.32h** × $30 | Pending — partial $805.65 paid |
| 28159 | 2026-04-01 | May 2026 | $1,038.10 | 3.63h × $125 | 2.75h × $15 | 5.32h × $30 | Pending Payment |
| **28363** | **2026-05-01** | **Jun 2026** | **$724.75** | 1.38h × $125 | 2.75h × $15 | 1.85h × $30 | Pending Payment |

**Mar–Apr commit step-up** drove invoices to $1,046 / $1,038, then it stepped back down for June. Worth investigating whether that was a true ramp or an accidental tier change.

**Open AR:** Invoice #27954 has $240.45 short-paid (paid $805.65 of $1,046.10).

Full list of 93 invoices (weekly + monthly) is in `invoices-list.csv`.

---

## Latest monthly invoice (#28363) — full breakdown

Service period: **2026-06-01 to 2026-06-30**

| Bucket | Lines | Amount |
|---|---|---:|
| **Endpoint stack (×7 desktops)** | AVD Crowdstrike $59.50 · **AVMH Huntress $42.00** · MR $14 · PMW $28 · SI $42 | $185.50 |
| **Network monitoring (×32 devices)** | SHM Health $64 · SSM Syslog $64 | $128.00 |
| **Pen Test / Assessment** | RTPT 6 IPs $42 · SA Site $50 | $92.00 |
| **Backup storage** | TB-BSTR 1 TB | $50.00 |
| **Committed labor** | USA Rem-N 1.38h × $125 = $172.50 · India-N 2.75h × $15 = $41.25 · India-AH 1.85h × $30 = $55.50 | **$269.25** |
| Tax | header line | $7.75 |
| | | **$724.75** |

Raw line items: `details/det_46067_28363.xml`.

---

## Actual vs billed labor (16 months: Jan-2025 → Apr-2026)

Source: `07_Assessments/Data_20260506_094149.xlsx`. Cleaned roll-up: `labor-utilization.csv`.

| Service | Code | Rate | Billed hrs (Σ) | Actual hrs (Σ) | Utilization | Avg actual /mo |
|---|---|---:|---:|---:|---:|---:|
| **USA Remote Normal** | TechSupport.R.N | $125 | 31.82 | 14.42 | **45.3%** | 0.90 |
| USA Remote After-Hours | TechSupport.R.AF | spot ($150) | 0 | 2.00 | spot only | 0.13 |
| USA Onsite Normal | TechSupport.O.N | spot ($150) | 0 | 3.42 | spot only | 0.21 |
| **India Remote Normal** | OffShore.R.N | $15 | 44.00 | 19.30 | **43.9%** | 1.21 |
| India Remote After-Hours | OffShore.R.AF | $30 | 28.12 | 21.23 | 75.5% | 1.42 |

**Material under-utilization on both committed labor lines** — TALY pays for ~2× what they consume on India-Normal and USA-Remote-Normal.

---

## Reduction opportunities (ranked by clarity, not just $)

| # | Lever | Monthly $ Δ | Risk / caveat |
|---|---|---:|---|
| 1 | **Drop Huntress (AVMH) OR Crowdstrike (AVD)** — both running on same 7 desktops | **−$42.00 to −$59.50** | Defense-in-depth was probably intentional; confirm with security lead before cutting. Lower-risk cut: AVMH ($42), since AVD ($59.50) is the more capable EDR. |
| 2 | **Right-size USA-Remote-Normal commit** from 1.38h → 0.75h (still slightly above 0.90 avg actual) | **−$78.75** | Cleanest move. Keeps discounted $125 rate but matches actual avg usage. If they go over, they pay $150/hr spot for the marginal time. |
| 3 | **Drop USA-Remote-Normal commit entirely** (1.38h × $125) | save $172.50; offset 0.9h × $150 = $135 → **net −$37.50** | Over-contract rate jumps from $125 to $150 for any USA remote work; only saves money if usage stays low. |
| 4 | **Reverify SHM/SSM device count** (32 today) | **−$4 / retired device** | Pull current network inventory; remove decommissioned switches/APs. |
| 5 | **Reverify RTPT IP count** (6 today) | **−$7 / IP** | Confirm against current external-facing IP list. |
| 6 | **Backup TB-BSTR sizing** (1 TB committed) | up to **−$50** if actual <0.5 TB | Pull Veeam/Wasabi actual usage. |
| 7 | India-N commit reduction | **DO NOT** | Actual 1.21h, committed 2.75h. If you drop the commit, $15/hr → $150/hr over-rate. Cheapest line on the invoice; leave it. |
| 8 | India-AH commit reduction | **DO NOT** | Same logic; $30 commit vs $150 over-rate; 76% utilized. |

**Realistic combined savings: $80 – $200 / mo (≈ 11 – 28% off the $724.75)** without dropping core security posture.

**Quickest single win: #2** (right-size USA-Rem-N commit).

---

## Files in this folder

| File | What it is |
|------|------------|
| `INVOICE_REVIEW_2026-05-06.md` | This report |
| `_pull-invoices.py` | Re-runnable script: pulls list + last 6 monthly details into this folder |
| `invoices-list.xml` | Raw `stp_xml_Inv_Org_Loc_Inv_List_Get` output (DirID 7728) |
| `invoices-list.csv` | All 93 invoices flattened (weekly + monthly) |
| `labor-utilization.csv` | Per-month billed-vs-actual labor hours (5 services × 16 months + totals) |
| `details/det_<id>_<no>.xml` | Per-invoice line-item detail (latest 6 non-void monthlies) |

---

## Recommended next actions

1. Confirm AV stack intent with security lead (AVD + AVMH both deployed — keep one or both?).
2. Pull current device inventory to validate SHM/SSM count of 32 and RTPT IP count of 6.
3. Pull Veeam/Wasabi actual storage to validate TB-BSTR commit of 1 TB.
4. Investigate Mar–Apr 2026 commit spike (USA-Rem-N 1.38 → 3.63, India-AH 1.38 → 5.32) — was this requested or accidental?
5. Chase $240.45 short-pay on invoice #27954.
6. Draft renegotiation proposal for Robert Evens at TALY: right-size USA-Rem-N commit + AV consolidation.
