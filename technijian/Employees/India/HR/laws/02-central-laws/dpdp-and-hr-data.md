# Digital Personal Data Protection Act, 2023 (DPDP Act) — HR-Relevant Provisions

**Status:** In force (assented 11-Aug-2023); rules under finalisation; some sections operationally pending the Data Protection Board of India becoming functional.
**Last verified:** 2026-05-06.

---

## Why this matters for HR

The DPDP Act is **India's first comprehensive personal-data-protection statute**. HR is the **most data-intensive function** in any company:

- Aadhaar copies, PAN, bank details, salary, emergency contacts.
- Performance reviews, feedback, disciplinary records.
- Health information (medical insurance, sick leave certificates, accommodation requests).
- Background-verification reports, education certificates.
- Biometric attendance / facial recognition / location data.
- Family / dependent details for insurance / welfare.

Every HR system at Technijian (HRMS, payroll, attendance, learning, exit data) processes **personal data** as defined in the DPDP Act.

---

## Key concepts

### "Personal data" (§2(t))

> Any data about an individual who is identifiable by or in relation to such data.

Very broad. Covers Aadhaar, name, email, photo, IP address, employee ID, biometric template, salary, performance score, etc.

### "Data Principal" (§2(j))

The individual to whom personal data relates → **the employee**.

For minors (under 18): the parent/guardian gives consent.
For persons with disabilities: the lawful guardian gives consent.

### "Data Fiduciary" (§2(i))

The person who, alone or in conjunction with other persons, determines the purpose and means of processing of personal data → **Technijian** (as the employer).

### "Data Processor" (§2(k))

A person who processes personal data on behalf of a Data Fiduciary → **HR-tech vendors** (HRMS provider, payroll vendor, background-verification vendor, attendance system).

### "Significant Data Fiduciary" (SDF) (§10)

The Central Government can notify any Data Fiduciary or class as "significant" based on volume, sensitivity, risk to rights of Data Principals, risk to electoral democracy, etc. SDFs have **enhanced obligations** (DPO, audits, DPIA). Status of designation is being finalised.

---

## Lawful basis for processing employee data

Under the DPDP Act, processing requires either:

1. **Consent** of the Data Principal (§§5, 6) — must be free, specific, informed, unambiguous, and in clear language; presented in English or one of 22 scheduled languages.

OR

2. **Legitimate Use** (§7) — defined situations where consent is not required:
   - (a) the Data Principal voluntarily provided data and has not indicated that they don't consent (the "deemed consent" pathway);
   - (b) for performance of any function under any law / for issue of subsidy / benefit;
   - (c) for compliance with any judgment / decree / order;
   - (d) for medical emergency;
   - (e) for taking measures to provide medical treatment;
   - (f) for taking measures during disasters / public-order issues;
   - (g) for purposes related to **employment** OR **safeguarding the employer from loss / liability** OR **for provision of any service / benefit sought by the Data Principal who is an employee**.

The **(g) employment limb** is the primary basis Technijian relies on for HR data processing — it covers payroll, attendance, performance management, disciplinary action, benefits administration, etc., **without** the need for separate consent.

But: data processing for **non-employment purposes** (e.g., marketing to ex-employees, sharing data with third parties not necessary for employment, biometric monitoring beyond attendance) requires **explicit consent**.

---

## Notice obligation (§5)

Even when relying on the employment legitimate-use basis, Technijian must give a **Notice** to employees:

- Before or at the time of seeking consent (§5(1)), OR
- For pre-existing personal data: as soon as reasonable (§5(2)).

The Notice must include:
- The personal data being processed.
- The purpose of processing.
- The manner in which the Data Principal may **exercise their rights**.
- The manner of complaint to the Data Protection Board.

For employees, this is delivered through:
- The **HR Privacy Notice** in the offer letter or employee handbook.
- The HRMS landing page.
- Periodic refreshers (annually recommended).

---

## Rights of Data Principals (employees)

### Right to information (§11)

Employee can request:
- A summary of personal data being processed.
- The processing activities undertaken.
- Identities of all Data Fiduciaries / Processors with whom data has been shared.

### Right to correction and erasure (§12)

- Correct inaccurate / misleading data.
- Update data.
- **Erase data** where the purpose for which it was collected is no longer being served, **except** where retention is necessary for compliance with law (e.g., income-tax records, EPF records, gratuity records — must be retained for 7+ years).

### Right of grievance redressal (§13)

- Employee can raise complaints with Technijian's grievance officer.
- Time-bound response prescribed (period to be notified in rules).

### Right to nominate (§14)

- Employee can nominate another individual to exercise rights in case of incapacity / death.

---

## Duties of Data Fiduciary (Technijian as employer)

### Reasonable security safeguards (§8(5))

- Implement appropriate technical and organisational measures to prevent personal-data breaches.
- Includes: access controls, encryption, role-based access, audit logs, secure backups, vendor due diligence.

### Personal data breach notification (§8(6))

- On a personal-data breach, **notify** the Data Protection Board AND each affected Data Principal — in the manner and within the time prescribed by rules.
- Currently (rules under finalisation): expected within 72 hours of becoming aware of the breach.

### Erasure on completion of purpose (§8(7))

- Erase personal data once the purpose is no longer being served, **unless retention is required by law**.
- For HR records:
  - Active employees: retain for active employment.
  - Ex-employees: retain only as required by tax (7 years), EPF (5 years post-exit), labour-law records (3 years post-exit), or for litigation defence (until limitation).
  - Photographs / non-essential profile data: erase on exit unless consent for testimonials / archive obtained.

### Engagement of processors (§8(2))

- Only engage Data Processors **under a valid contract**.
- Contractual obligations: same standards on security, breach notification, sub-processing, audit.

### Designate (where Significant Data Fiduciary) (§10(2))

- Data Protection Officer (DPO) based in India.
- Independent data auditor.
- Periodic Data Protection Impact Assessments (DPIAs).
- Periodic audits.

### Children's data (§9)

- Cannot process personal data of children (under 18) **without verifiable consent** of parent / lawful guardian.
- Cannot undertake **tracking, behavioural monitoring, or targeted advertising** towards children.
- Implication for Technijian: any apprentice / intern below 18 → parental consent for HR processing required.

---

## Cross-border transfer (§16)

- Central Government may, by notification, restrict transfer of personal data to specified countries.
- Default: transfer permitted to all countries unless restricted.
- Implication: data export to overseas Technijian offices, US HQ, US-based HRMS / payroll vendors → currently permitted, subject to contractual safeguards.

---

## Exemptions (§17)

Some provisions don't apply where data is processed for:
- Research, archiving, statistics (under conditions).
- Court / judicial functions.
- Sovereign / security functions.
- Investigations / prosecutions.

These have limited HR application. Background-verification reports for **investigative purposes (e.g., suspected fraud)** could fall under §17(c) — investigation of an offence.

---

## Penalties (§33 and Schedule)

| Default | Penalty (per instance) |
|---|---|
| Failure to take reasonable security safeguards (breach) | Up to **₹250 crore** |
| Failure to notify data breach | Up to **₹200 crore** |
| Failure regarding children's data | Up to **₹200 crore** |
| Failure of Significant Data Fiduciary obligations | Up to **₹150 crore** |
| Breach of duty as Data Principal (false complaints, impersonation) | Up to **₹10,000** |
| Any other contravention | Up to **₹50 crore** |

These are imposed by the Data Protection Board after an inquiry. Technijian's exposure on a serious breach is **significant** — the maximum is per breach, not cumulative discount.

---

## HR data-protection compliance checklist

| # | Requirement | Status to verify |
|---|---|---|
| 1 | HR Privacy Notice issued to all employees | Yes / signed copy on file |
| 2 | Notice covers (a) categories of data, (b) purposes, (c) rights, (d) grievance, (e) sharing with vendors | Updated text matches §5 |
| 3 | All HR-tech vendors (HRMS, payroll, BG verification, attendance) under written Data Processor contracts | Yes / contracts on file |
| 4 | Vendor contracts include: security, sub-processing restrictions, breach notification (e.g., 24-72 hrs), audit rights | Reviewed by legal |
| 5 | Access controls on HR systems (role-based, MFA) | IT security audit |
| 6 | Encryption: data in transit (HTTPS / VPN); data at rest (AES-256) | IT confirmation |
| 7 | Data-retention schedule documented per category | Document on file |
| 8 | Erasure SOP for ex-employees: photos, contact, profile data | SOP document |
| 9 | Grievance redressal officer designated + contact published | Notice board / intranet |
| 10 | Breach response plan (24-72 hrs to Data Protection Board + Data Principals) | Documented IR plan |
| 11 | DPO appointed (if Significant Data Fiduciary; advisable in any case) | Board resolution |
| 12 | Annual HR data-handling training | Training records |
| 13 | Children / minor (apprentice / intern) consent flow with parental consent | Form on file |
| 14 | Cross-border transfer audit (US HQ, overseas HRMS) | Documented |

---

## Practical operational guidance for Technijian

| Scenario | Action |
|---|---|
| New employee joins | Issue HR Privacy Notice with offer letter; obtain acknowledgement |
| Background verification | Obtain explicit consent (separate from employment LU basis); contract with BG vendor as Data Processor |
| Biometric attendance | Document lawful basis (employment LU); store templates encrypted; restrict access; delete on exit |
| Employee health insurance | Sensitive personal data; share with insurer under contractual safeguards; obtain consent for medical history disclosures |
| Performance review storage | Retain only as long as employment + reasonable post-employment defence period (3 years typical) |
| Ex-employee data | Anonymise after retention period; erase non-essential identifiers |
| Camera / CCTV / monitoring | Document purpose (security, safety); notice on premises; access control |
| Whistleblower / IC investigation | Confidentiality + need-to-know access; preserve only as long as legitimate interest |
| Cross-border data flow to US HQ | Document; ensure contractual safeguards in US HQ data-sharing agreement |
| Data breach | (1) Contain; (2) Investigate; (3) Notify Data Protection Board within prescribed time; (4) Notify affected employees |

---

## Cross-references

- [05-hr-topics/data-privacy-hr.md](../05-hr-topics/data-privacy-hr.md) (operational SOP if added)
- [POSH Act](posh-act-2013.md) — confidentiality of complaint records cross-references DPDP

## Sources

- The Digital Personal Data Protection Act, 2023 (No. 22 of 2023)
- Draft Digital Personal Data Protection Rules (under finalisation, 2025)
- Ministry of Electronics and Information Technology (MeitY) press releases
- Industry guidance from NASSCOM, DSCI (Data Security Council of India), and major Indian law firms
