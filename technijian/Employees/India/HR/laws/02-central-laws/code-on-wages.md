# Code on Wages, 2019

**Status:** In force from **21-Nov-2025**.
**Last verified:** 2026-05-06.
**Repeals:** Minimum Wages Act 1948 · Payment of Wages Act 1936 · Payment of Bonus Act 1965 · Equal Remuneration Act 1976.

---

## What it does

Consolidates **all wage-related law in India** into a single instrument. Four classical statutes that previously regulated different wage facets (minimum, timing, bonus, equality) are now four chapters of one code.

| Chapter | Subject | Replaces |
|---|---|---|
| II | Minimum Wages | Minimum Wages Act 1948 |
| III | Payment of Wages | Payment of Wages Act 1936 |
| IV | Payment of Bonus | Payment of Bonus Act 1965 |
| V | Equal Remuneration | Equal Remuneration Act 1976 |

---

## Universal coverage

**Key change:** the Code on Wages applies **across all employments** (organised and unorganised), regardless of wage ceiling, sector, or threshold.
- Old Minimum Wages Act applied only to "scheduled employments" notified by govt.
- Old Payment of Wages Act covered only employees earning ≤₹24,000/month.
- Old Payment of Bonus Act applied where ≥20 employees and wage ≤₹21,000/month.

**Now**: Chapters II, III, V apply to **every employee in India**. Chapter IV (Bonus) retains a wage ceiling (proposed ~₹21,000/month, to be confirmed in central rules).

---

## Definition of "wages"

The most operationally significant feature. Defined in §2(y):

> "Wages" means all remuneration whether by way of salaries, allowances or otherwise, expressed in terms of money or capable of being so expressed, payable to a person employed in respect of his employment or work done in such employment, and includes basic pay, dearness allowance, and retaining allowance, if any.

**Excludes** (specified items):
- (a) bonus payable under any law that doesn't form part of wages;
- (b) value of housing accommodation, supply of light, water, medical attendance or other amenity excluded by Govt order;
- (c) employer's PF / pension contribution & interest;
- (d) conveyance allowance / travel concession;
- (e) sum payable to defray special work expenses;
- (f) house rent allowance;
- (g) overtime;
- (h) commission;
- (i) gratuity;
- (j) retrenchment compensation, ex gratia, end-of-service benefit.

### The 50% rule (proviso)

> Provided that, for calculating the wages under this clause, if payments made by the employer to the employee under clauses (a) to (i) exceed **one-half**, or such other percent as may be notified by the Central Government, of the total remuneration calculated under this clause, the amount which exceeds such one-half, or the percent so notified, shall be deemed as remuneration and shall be accordingly added in wages under this clause.

**Operational consequence**: Allowances + excluded items together cannot exceed 50% of CTC. If they do, the excess is added back to "wages" — increasing EPF, gratuity, ESI and minimum-wage compliance bases.

**Same definition is used across all 4 codes** → so the 50% rule cascades to:
- EPF contribution base (Social Security Code)
- ESI contribution base (Social Security Code)
- Gratuity calculation (Social Security Code)
- Bonus calculation (Code on Wages)
- Minimum wage compliance (Code on Wages)

### Practical impact for Technijian (IT/ITeS)

Most Indian IT/ITeS pay structures historically had **Basic = 30–40% of CTC** with large allowances. Under the new rule:
- **Basic + DA must be ≥ 50% of CTC**.
- Re-balance: shift HRA, special allowance, etc. into Basic, OR accept higher EPF/gratuity costs.
- For senior staff (above ESI ceiling, no PF cap), gratuity exposure rises sharply because gratuity = 15 days × (basic+DA) × years ÷ 26.

---

## Chapter II — Minimum Wages

### Mechanism

- **Central Government** sets a national **floor wage** (§9) — applies as a non-derogable minimum across India.
- **State Governments** notify state-specific **minimum wages** (§6, §8) for various skill categories — must equal or exceed the floor wage.
- Minimum wages are revised at intervals **not exceeding 5 years** (§8(4)).
- States may notify minimum wages for any class of employee, by skill (unskilled / semi-skilled / skilled / highly-skilled), by occupation, or by geographic zone.

### Components of minimum wage (§6, §7)

A minimum wage may include:
- Basic rate of wages,
- Cost-of-living / dearness allowance,
- Cash value of concessions for essential commodities at concession rates.

### Working hours & overtime (§13)

- A "normal working day" is fixed by the appropriate government.
- Overtime is paid at **at least twice the ordinary rate**.

### State notifications applicable to Technijian

- **Haryana** (Panchkula): Notification No. 2/25/26-2 Lab dated 9-Apr-2026, effective 1-Apr-2026. See [04-haryana-panchkula/minimum-wages.md](../04-haryana-panchkula/minimum-wages.md).
- **Chandigarh UT**: notification effective 1-Oct-2025. See [03-chandigarh-ut/minimum-wages-and-welfare-fund.md](../03-chandigarh-ut/minimum-wages-and-welfare-fund.md).

---

## Chapter III — Payment of Wages

### Wage period (§16)

The employer must fix a wage period. Cannot exceed **one month**.

### Payment schedule (§17)

- **Daily / weekly** wage period: pay at the end of the period.
- **Fortnightly** wage period: pay within **2 days** of the end of the period.
- **Monthly** wage period (Technijian's case): pay before the end of the **7th day** of the next month.
- For employees terminated, pay within **2 working days** of cessation.

### Mode of payment (§15)

- Cash, OR
- Cheque, OR
- Crediting the account of the employee, OR
- Electronic mode (this is the universal default for Technijian).

The appropriate government may notify particular industries where bank/electronic payment is mandatory.

### Permitted deductions (§18)

- Fines (subject to limits in §19);
- Absence from duty;
- Damage to or loss of goods entrusted to the employee where loss is directly attributable to neglect or default;
- House accommodation provided by employer;
- Amenities and services supplied with consent;
- Recovery of advances, loans, overpayment;
- Income-tax;
- Court-ordered;
- Statutory contributions (EPF, ESI, etc.);
- Co-operative society / insurance contributions with consent;
- Trade Union dues;
- Misc as notified.

**Total deductions in any wage period cannot exceed 50% of wages** (§18(4)).

### Fines (§19)

- Fines may be imposed only with prior approval of the appropriate Govt.
- Cannot exceed **3% of the wages** payable to the employee in respect of that wage period.
- Cannot be imposed on persons under 15 years.
- Must be recovered within 90 days of the date the act/omission for which the fine is imposed.

---

## Chapter IV — Bonus

### Eligibility (§26)

Every employee whose wages do not exceed a notified ceiling (expected ≈₹21,000/month under central rules) is entitled to bonus, **provided** they have worked at least **30 days** in the accounting year.

### Quantum (§26)

- Minimum bonus: **8.33% of wages or ₹100, whichever is higher** (per accounting year).
- Maximum bonus: **20% of wages**.

### Computation base (§29, §31)

- Computed on actual wages, OR
- On a notional ceiling (currently expected to remain at ~₹7,000/month or the minimum wage of the relevant skill category, whichever is higher), if actual wages exceed it.

### Deductions from bonus (§32, §33)

- Customary / festival bonus already paid;
- Misconduct (riot, theft, violence) leading to financial loss — bonus may be reduced by amount of loss.

### Disqualification (§29)

Bonus may be denied if employee is **dismissed** for fraud, riotous/violent behaviour, theft, misappropriation, or sabotage of property.

### Payment timeline (§39)

Bonus must be paid within **8 months from the close of the accounting year**, unless extended by the appropriate Govt.

---

## Chapter V — Equal Remuneration

### Core rule (§3)

> No employer shall make any discrimination on the ground of gender in matters of wages and recruitment, or in conditions of employment of any employee, of the same work or work of similar nature.

Applies to **all employees** including contract workers and apprentices.

**No employer can pay a woman lower wages than a man for the same or similar work**, or vice versa.

### What "same / similar work" means

- "Same work" = work performed by men and women that requires similar skill, effort, responsibility, when performed under similar working conditions.
- The standard is **substance**, not job title. Re-titling roles to evade Chapter V is itself an offence.

---

## Inspector / Inspector-cum-Facilitator (§51, §52)

- Inspectors under the four codes are now **Inspector-cum-Facilitators** with a duty to advise as well as inspect.
- A randomised inspection scheme (web-based) replaces the historical pattern of arbitrary on-site visits.
- Establishments cannot be inspected by the same officer twice in a row (rotational).

---

## Penalties (§54)

| Offence | Penalty |
|---|---|
| Paying less than the minimum wage | Up to **₹50,000** for first offence |
| Repeat offence within 5 years | Up to **₹1,00,000** + imprisonment up to 3 months |
| Other contraventions | Up to **₹20,000** for first offence; ₹40,000 + 1 month imprisonment on repeat |
| Employer fails to maintain register / record | Up to **₹10,000** |

Compounding of offences allowed (§56) for offences not punishable with imprisonment.

---

## Records & registers required

Under the central rules (when finalised) — and pre-code requirements continuing in transition:

- **Wages register** (per employee, per wage period) — name, designation, attendance, gross wages, deductions, net wages, signature/acknowledgement.
- **Wages slip** — to be issued to every employee (electronic acceptable).
- **Annual return** — Form to be notified.

Technijian's payroll vendor (or in-house payroll system) must support these registers in code-aligned format.

---

## Cross-references

- [Social Security Code](social-security-code.md) — wage definition cascades to EPF, ESI, gratuity, bonus.
- [Chandigarh minimum wages](../03-chandigarh-ut/minimum-wages-and-welfare-fund.md)
- [Haryana minimum wages](../04-haryana-panchkula/minimum-wages.md)
- [05-hr-topics/compensation-benefits-deductions.md](../05-hr-topics/compensation-benefits-deductions.md)
