# HR Topic — Compensation, Benefits, and Statutory Deductions

**Last verified:** 2026-05-06.

Operational guide for structuring CTC, computing benefits, and managing statutory payroll deductions for Technijian Chandigarh / Panchkula.

---

## CTC structure under the new wage definition

### Code on Wages §2(y) — the 50% rule

> "Wages" means basic + DA + retaining allowance, **excluding** allowances/benefits listed in (a)–(i) of §2(y), provided that excluded items together cannot exceed **50%** of total remuneration. Excess over 50% is added back.

### Recommended CTC structure for Technijian Indian employees

For each employee, structure annual CTC such that:

| Component | % of total CTC | Notes |
|---|---|---|
| **Basic salary** | **40–50%** | Forms PF / gratuity base; must be ≥50% combined with DA |
| **Dearness Allowance (DA)** | **0–10%** | Often absorbed into Basic for tech roles; required for blue-collar |
| **Basic + DA combined** | **≥ 50%** | **MUST** comply with §2(y) |
| **House Rent Allowance (HRA)** | 20–30% | Tax-exempt up to limits |
| **Special Allowance** | Balance | Fully taxable; absorbs other components |
| **Conveyance / Transport** | 0 (since 2018) | Taxed under standard deduction |
| **Communication / Internet** | 0–2% | Tax-exempt against bills |
| **LTA (Leave Travel Allowance)** | 0–5% | Tax-exempt against bills (twice in 4 yrs) |
| **Variable / Performance Bonus** | 5–20% | Taxable; often paid annually |
| **Employer EPF contribution** | 12% of (Basic + DA), capped or full | Counted in CTC |
| **Employer ESI contribution** (if gross ≤ ₹21K) | 3.25% of gross | Counted in CTC |
| **Group Health Insurance / Life / Accident** | 1–3% | Counted in CTC |
| **Gratuity provision** | 4.81% of Basic + DA (theoretical accrual) | Counted in CTC |

### Why the 50% rule matters

If Basic + DA < 50%, the EPF / ESI / gratuity / bonus computation base is **forcibly increased** by EPFO / ESIC under the new code. This can result in:
- Retroactive dues with interest.
- Penalties.
- Higher cash outgo than budgeted.

### Worked example

For an employee with annual CTC of **₹12,00,000**:

| Component | Compliant structure (₹) | Non-compliant (Basic 30%) |
|---|---|---|
| Basic + DA | 6,00,000 (50%) | 3,60,000 (30%) |
| HRA | 2,40,000 (20%) | 1,80,000 (15%) |
| Special Allowance | 1,80,000 (15%) | 4,40,000 (37%) |
| Other allowances | 60,000 (5%) | 60,000 (5%) |
| Employer EPF | 60,000 (5% of CTC ≈ 12% of Basic) | 36,000 (less) |
| Employer ESI (n/a here, salary > ₹21K) | 0 | 0 |
| Gratuity provision | 28,860 (4.81%) | 17,316 (less) |
| Insurance | 30,000 | 30,000 |
| **Total CTC** | 12,00,000 | 12,00,000 |

Effect: in the compliant structure, employer EPF and gratuity outgo are **higher**, but the structure is legally defensible. Under the non-compliant structure, EPFO can re-compute on imputed wages of 6L → demand top-up + penalties.

---

## Statutory deductions — operational guide

### EPF (Employees' Provident Fund)

| Parameter | Value |
|---|---|
| Coverage threshold | ≥20 employees (sticky after) |
| Wage ceiling for mandatory | Basic + DA ≤ ₹15,000/month |
| Employee contribution | **12%** of (Basic + DA) |
| Employer contribution (total) | **12%** of (Basic + DA), of which: |
| → EPS portion | 8.33% capped at ₹15,000 → max ₹1,250/month |
| → EPF portion | Balance |
| EDLI (insurance) — employer | 0.5% of (Basic + DA), capped at ₹15,000 → max ₹75/month |
| Admin charges — employer | 0.5%, min ₹500/establishment |
| Filing | Monthly ECR by **15th** of next month |

For employees earning > ₹15,000 (most Technijian engineers), Technijian's policy choice:
- Cap contribution at ₹15,000 base (lower employer outgo), OR
- Contribute on actual wages (higher employee retirement saving but higher employer cost).

### ESI (Employees' State Insurance)

| Parameter | Value |
|---|---|
| Coverage threshold | ≥10 employees |
| Wage ceiling | Gross wages ≤ ₹21,000/month (₹25,000 for disabled) |
| Employee contribution | **0.75%** of gross |
| Employer contribution | **3.25%** of gross |
| Total | 4% |
| Filing | Monthly challan by **15th** of next month + half-yearly returns |

For Technijian: ESI applies to support staff, junior engineers earning ≤ ₹21K; private group health insurance covers others.

### Gratuity

- No employee deduction.
- Employer **provision** of 4.81% of (Basic + DA) per month into a gratuity fund (LIC / private trust) OR pay-as-you-go.
- Payable on cessation if 5 years served (1 year for fixed-term).
- Tax-exempt up to **₹25 lakh**.

### Professional Tax (PT)

- **Chandigarh UT**: NOT applicable.
- **Haryana**: NOT applicable.
- (Karnataka, Maharashtra, West Bengal, etc., DO have PT — relevant if Technijian opens offices there.)

### Labour Welfare Fund (LWF)

| Jurisdiction | Employee | Employer | Total | Frequency |
|---|---|---|---|---|
| **Chandigarh UT** | ₹5/month | ₹20/month | ₹25/employee/month | Half-yearly remittance |
| **Haryana (Panchkula)** | **₹31/month** | **₹62/month** | **₹93/employee/month** | Half-yearly remittance |

LWF deposit deadlines:
- Apr-Sep period: by **15-October**
- Oct-Mar period: by **15-April**

### Income Tax (TDS)

- Employer is the deductor (TAN required).
- Computed monthly per declarations:
  - Old regime: HRA, LTA, 80C investments, etc.
  - New regime (from FY 2023-24, default from FY 2024-25): no major exemptions; lower slab rates.
- TDS deposited monthly: **7th** of next month (24Q quarterly returns).
- Form 16 issued annually by **15-June** of the following year.
- Employees who change regime: declaration in writing at year-start.

---

## Bonus (Code on Wages, Chapter IV)

### Eligibility

- Employee who has worked ≥30 days in accounting year.
- Wages ≤ notified ceiling (~₹21,000/month).
- For Technijian, this typically applies to junior staff and support roles.

### Quantum

- Minimum: **8.33% of wages** (or ₹100, whichever is higher).
- Maximum: **20% of wages**.
- Profitability-linked (allocable surplus formula).
- Many tech employers pay performance bonuses well above statutory minimum; ensure the statutory minimum is met for eligible employees.

### Computation base

- Actual wages, OR
- Notional ceiling (~₹7,000 or skill-category min wage, whichever higher).

### Payment

- Within **8 months** of close of accounting year (typically by 30-Nov for FY ending 31-Mar).

---

## Reimbursements

### Common reimbursements (tax-exempt against actual bills)

- LTA: economy travel within India for self + family, twice in 4 years.
- Mobile / Internet: company-provided; reimbursed against bills.
- Books / professional subscriptions: usually reimbursable.
- Training / certification: reimbursable per HR policy.
- Meal vouchers (Sodexo / Zeta): up to ₹50/meal/day, ₹26,400/year exempt.

### Documentation

- Bills / invoices retained (tax & labour records: 7+ years).
- Reimbursement claims submitted via HRMS / payroll portal.
- Audit trail maintained.

---

## End-of-employment financial reckoning

### Components on exit

| Item | Computation |
|---|---|
| Salary up to last working day | Pro-rata |
| Notice pay (if relieved before notice ends) | As per offer letter (usually basic of remaining notice period) |
| Earned leave encashment | Last drawn (Basic + DA) × unused EL days × days-divisor |
| Gratuity (if ≥5 yrs / FTE ≥1 yr / death / disablement) | (Basic + DA) × 15 / 26 × completed years |
| Bonus (pro-rata, if eligible) | Per Code on Wages |
| Reimbursements pending | Pending claims |
| Variable bonus / performance pay | Per HR policy |
| Recoveries (advances, equipment loss, notice short) | Deductions |
| Final TDS reconciliation | Form 16 |
| EPF — settlement / transfer to new UAN | Online claim |
| ESIC — closure | Online |
| Group health insurance | Cover ends as per policy |

### Timeline

- Final salary + dues: within **2 working days of cessation** under Code on Wages §17(2).
- Gratuity: within **30 days** of becoming payable (Social Security Code).
- EL encashment: typically with final settlement.
- Form 16 (final): by **15-June** of next FY.

---

## Records to maintain

| Record | Retention |
|---|---|
| Wages register | 3 years (S&E) / 7+ years (Income-tax) |
| Attendance register | 3 years |
| EPF / ESIC contribution records | 7 years (mandated retention) |
| Gratuity nomination / claim | Permanent until settled |
| Form 16 / TDS records | 8 years (Income-tax) |
| Bonus register | 8 years (Code on Wages) |
| Leave records | 3 years |
| Employee personnel file | Active + 3 years post-exit (for IR Code limitation period) |

---

## Cross-references

- [02-central-laws/code-on-wages.md](../02-central-laws/code-on-wages.md) — wage definition, payment, bonus
- [02-central-laws/social-security-code.md](../02-central-laws/social-security-code.md) — EPF, ESI, gratuity, maternity
- [03-chandigarh-ut/minimum-wages-and-welfare-fund.md](../03-chandigarh-ut/minimum-wages-and-welfare-fund.md)
- [04-haryana-panchkula/minimum-wages.md](../04-haryana-panchkula/minimum-wages.md)
- [04-haryana-panchkula/holidays-leave-welfare-fund.md](../04-haryana-panchkula/holidays-leave-welfare-fund.md) — LWF rates
- [06-compliance/compliance-calendar.md](../06-compliance/compliance-calendar.md) — filing deadlines
