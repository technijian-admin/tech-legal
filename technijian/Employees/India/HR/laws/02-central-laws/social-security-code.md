# Code on Social Security, 2020

**Status:** In force from **21-Nov-2025**.
**Last verified:** 2026-05-06.
**Repeals (key acts):** EPF & Misc. Provisions Act 1952 · ESI Act 1948 · Payment of Gratuity Act 1972 · Maternity Benefit Act 1961 · Employees' Compensation Act 1923 · Building & Other Construction Workers' Welfare Cess Act 1996 · Cine Workers Welfare Fund Act 1981 · Unorganised Workers' Social Security Act 2008 · Employees Exchanges (Compulsory Notification of Vacancies) Act 1959.

---

## What it does

Brings **all employment-related social-security schemes** under one umbrella code:

| Chapter | Subject | Replaces (substantively re-enacted) |
|---|---|---|
| III | Provident Fund (EPF) | EPF Act 1952 |
| IV | Employees' State Insurance (ESI) | ESI Act 1948 |
| V | Gratuity | Payment of Gratuity Act 1972 |
| VI | Maternity Benefits | Maternity Benefit Act 1961 |
| VII | Employees' Compensation | Workmen's Compensation Act 1923 |
| VIII | Social Security & Cess re Construction Workers | BOCW Acts 1996 |
| IX | Unorganised Workers, Gig & Platform Workers | Unorganised Workers Act 2008 + new gig/platform framework |

The pre-code schemes (EPF Scheme 1952, ESI General Regulations 1950, Maternity Benefit Rules) **continue** as transitional rules until corresponding code-rules are notified.

---

## Chapter III — Employees' Provident Fund (EPF)

### Applicability (§§14–15)

- Establishments with **≥20 employees** in the categories notified by Government — currently includes virtually all manufacturing, IT/ITeS, services.
- Once an establishment is covered, **continues to be covered** even if employee count subsequently falls below 20 (sticky coverage).
- Voluntary coverage available below the threshold.

### Wage ceiling for mandatory coverage

- Mandatory coverage: employees with **basic + DA up to ₹15,000/month**.
- Above ₹15,000: optional but typical (employee + employer can opt in to the entire wage; or contributions capped at ₹15,000).
- Many Technijian developers will exceed ₹15,000; standard practice is to contribute on actual wages or cap at ₹15,000 — Technijian's policy decision, but must be applied consistently.

### Contribution rates

| Component | Rate | Cap |
|---|---|---|
| Employee contribution | 12% of (Basic + DA) | None |
| Employer contribution — total | 12% of (Basic + DA) | None |
| ↳ EPS (Pension) portion | 8.33% of (Basic + DA), capped at ₹15,000 | Max **₹1,250 / month** |
| ↳ EPF portion | Balance of 12% (i.e., 3.67% if uncapped, more if salary >₹15,000) | None |
| EDLI (insurance) | 0.5% of (Basic + DA) | Capped at ₹15,000 (max ₹75/month) |
| Admin charges (employer) | 0.5% of (Basic + DA) | Min ₹500/month/establishment |

### Effect of the new wages definition

Under the Code on Wages §2(y), if allowances exceed 50% of CTC, the excess is added back to "wages" — and EPF contribution must be paid on that increased base. **Technijian's payroll structure must align Basic + DA to ≥50% of CTC** to avoid retroactive top-up demands by EPFO.

### Withdrawal / transfer

- Universal Account Number (UAN) follows the employee across employers.
- Withdrawal allowed: at retirement (after 58); at exit if unemployed >2 months; partial withdrawal for medical, marriage, education, housing, etc.
- Tax-free withdrawal if 5+ years of continuous service.

### EPS pension

- After 10 years of contributions, employee is eligible for monthly pension on retirement.
- Pension formula: pensionable salary × pensionable service ÷ 70.
- Pensionable salary capped at ₹15,000 unless employee opted for higher contributions before 1-Sep-2014 (litigated; see Supreme Court ruling on higher pension Nov 2022).

---

## Chapter IV — Employees' State Insurance (ESI)

### Applicability

- Establishments with **≥10 employees** in notified geographic areas.
- All notified areas of Haryana including Panchkula and Chandigarh UT are ESIC-implemented.

### Wage ceiling for mandatory coverage

- Employees with **gross wages up to ₹21,000/month** are mandatorily covered.
- Persons with disability: ceiling ₹25,000/month.
- Above the ceiling, ESI does not apply (employer typically provides private health insurance).

### Contribution rates (last revised 1-Jul-2019; unchanged in 2026)

| Party | Rate of gross wages |
|---|---|
| Employee | **0.75%** |
| Employer | **3.25%** |
| **Total** | **4.00%** |

### Benefits

ESI provides:
- **Medical** — full medical care for employee + dependents at ESIC dispensaries / empanelled hospitals.
- **Sickness** — cash benefit ~70% of wages for 91 days/year.
- **Maternity** — 26 weeks paid for women.
- **Disablement** — temporary or permanent, at scheduled rates.
- **Dependants' benefit** — to family on death due to employment injury.
- **Funeral** — fixed amount.

### IT/ITeS practical note

Most Technijian developers earn above ₹21,000 — so ESI does **not** apply to them; private group health insurance is the alternative. ESI **does apply** to support staff, junior engineers, office helpers, security earning ≤₹21,000.

---

## Chapter V — Gratuity

### Applicability (§53)

Establishments with **≥10 employees** at any time in the preceding 12 months.

### Eligibility (§53)

- Employee must have rendered **≥5 years continuous service** to be entitled to gratuity on:
  - Resignation,
  - Retirement / superannuation,
  - Death,
  - Disablement.
- The 5-year requirement is **waived** for death and disablement.
- **Fixed-term employees**: gratuity accrues from **1 year** of service (per the IR Code's universal FTE-equality principle, reflected here in §53(2)). This is a **major change** from the 1972 Act's strict 5-year rule.

### Calculation (§54)

Standard formula:

> **Gratuity = (Last drawn Basic + DA) × 15 / 26 × Number of completed years of service**

Where "26" represents 26 working days in a month.

For seasonal employees: 7 days per season instead of 15 days per year.

For piece-rated employees: average of last 3 months' earnings.

### Maximum (§54(3))

- **₹25 lakh** maximum statutory gratuity (raised from ₹20 lakh under the old act; finalised in Social Security Code rules).

### Effect of new wages definition

Gratuity is computed on Basic + DA. With the 50% rule (Code on Wages §2(y)), Basic + DA in CTC will be substantially higher → gratuity payouts rise materially. Plan accruals.

### Tax treatment

- Up to ₹25 lakh of gratuity received is **tax-free** under §10(10) of the Income-tax Act 1961.
- Above ₹25 lakh, taxable as salary.

### Forfeiture

Gratuity may be forfeited (wholly or partly) if employee is terminated for **wilful omission or negligence causing damage / loss / destruction of employer's property**, or for **riotous, disorderly conduct or moral turpitude in the course of employment**.

### Payment timeline

- Within **30 days** of becoming payable.
- Delay attracts simple interest at the notified rate (typically 8–10%).

---

## Chapter VI — Maternity Benefits

### Applicability

- Establishments with **≥10 employees**.
- Substantively retains all entitlements from the Maternity Benefit Act 1961 (as amended 2017).

### Eligibility

- Female employee who has worked at least **80 days** in the establishment in the 12 months immediately preceding her expected delivery.

### Entitlements

| Benefit | Duration |
|---|---|
| Paid maternity leave for first 2 children | **26 weeks** (8 weeks pre-natal + 18 weeks post-natal) |
| Paid maternity leave for 3rd child onwards | 12 weeks |
| Adoption (child < 3 months) | 12 weeks |
| Surrogacy (commissioning mother) | 12 weeks |
| Miscarriage / medical termination | 6 weeks |
| Tubectomy operation | 2 weeks |
| Illness arising from pregnancy / delivery | 1 month additional |
| Nursing breaks until child is 15 months old | 2 breaks/day in addition to regular intervals |

### Wages during leave

- Average daily wage for the 3 calendar months preceding the leave.
- Paid by employer (not Government).

### Crèche facility (§67)

Establishments with **≥50 employees** must provide a **crèche facility** within prescribed distance, accessible to mothers up to 4 visits/day (including rest interval).

This is a hard requirement once Technijian's Indian office headcount crosses 50 — physical or shared / 3rd-party arrangement satisfies. Plan early.

### Work-from-home post-maternity

The 2017 amendment to the Maternity Benefit Act (now in §72 of the Social Security Code) provides that, **after 26 weeks**, an employee may **return to work-from-home if the nature of work allows** and as agreed with the employer. Should be in offer / handbook.

### Penalties

- Failure to pay maternity benefit: imprisonment up to 6 months or fine up to ₹50,000 or both.
- Failure to provide crèche: fine up to ₹50,000.

---

## Chapter VII — Employees' Compensation

### Coverage

- Compensation for personal injury / occupational disease caused **by accident arising out of and in the course of employment**.
- Available regardless of fault.
- Death and total/partial disablement schedule provided.

### Quantum

- Death: 50% of monthly wages × relevant factor (age-based) + ₹120,000 minimum.
- Permanent total disablement: 60% of monthly wages × relevant factor + ₹140,000 minimum.
- Permanent partial: percentage of above based on schedule.
- Temporary: half-monthly payments for the period of disablement, max 5 years.

### IT/ITeS relevance

- Covers commute injuries (from notified date), workplace incidents, fire, etc.
- Most employers carry **Workmen's Compensation insurance** to cover this exposure even though the obligation is statutory.

### ESI overlap

If an employee is covered under ESI, employees-compensation chapter generally does **not** apply (ESI provides equivalent benefit).

---

## Chapter IX — Gig Workers & Platform Workers

This is **new** in the Social Security Code and has no analogue in the old laws.

### Definitions

- **Gig worker** (§2(35)): person performing work or participating in work arrangements outside traditional employer-employee relationships, earning from such activities.
- **Platform worker** (§2(61)): person engaged in platform work (organised through online platform / intermediary).

### Social Security Fund (§§109–114)

- Aggregators (e.g., Uber, Swiggy, Urban Company) must contribute **1–2% of annual turnover** (capped at 5% of payments to gig/platform workers) to a Social Security Fund.
- Schemes for life/disability cover, accident insurance, health & maternity, old-age protection.

### Technijian relevance

If Technijian engages independent contractors / freelancers via aggregator platforms (or operates as one), this chapter may apply. For traditional W2-style employees, no impact.

---

## Chapter XIII & misc — Penalties

| Offence | Penalty |
|---|---|
| Failure to deposit EPF / ESI / gratuity contribution | **₹1 lakh – ₹3 lakh** + imprisonment 1–3 years |
| Repeat offence | Up to ₹5 lakh + imprisonment up to 5 years |
| Failure to maintain records | ₹50,000 |
| Obstruction of inspector | ₹50,000 |

---

## Returns & filings (operational)

| Return | Frequency | Authority |
|---|---|---|
| EPF — Electronic Challan-cum-Return (ECR) | Monthly, by **15th** of next month | EPFO |
| ESI — Monthly contribution challan | By **15th** of next month | ESIC |
| ESI — Half-yearly return | Twice a year | ESIC |
| EPF — Annual return | Annual | EPFO |
| Gratuity — Notice of Opening / Change | One-time / on change | Controlling Authority (Labour Commissioner) |

See [06-compliance/compliance-calendar.md](../06-compliance/compliance-calendar.md).

---

## Cross-references

- [Code on Wages](code-on-wages.md) — wage definition (50% rule cascades here)
- [05-hr-topics/compensation-benefits-deductions.md](../05-hr-topics/compensation-benefits-deductions.md) — payroll mechanics
- [05-hr-topics/leaves-and-holidays.md](../05-hr-topics/leaves-and-holidays.md) — maternity & sick-leave coordination
- [06-compliance/compliance-calendar.md](../06-compliance/compliance-calendar.md) — monthly EPF/ESI deadlines
