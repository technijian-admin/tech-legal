---
name: india-employment-lifecycle
description: Use when the user wants to confirm, terminate, or separate a Technijian India employee — routes between Confirmation Letter, Probation Termination, §70 Retrenchment, or Termination for Cause based on the employee's actual status in the Confirmation register. Examples: "Confirm Ankit as a permanent employee", "Issue a termination letter to [employee]", "Lay off [employee]", "Retrench the CSE team", "Process [employee]'s exit".
---

# India Employment Lifecycle — Confirmation, Termination, Retrenchment

## When to use

Trigger this skill the moment the user asks for any of:

- A **Confirmation Letter** for an India employee
- A **Probation Termination** (employee not yet confirmed)
- A **Retrenchment** / cost-reduction layoff
- A **separation** / "let [employee] go" / "exit [employee]" without specifying the reason

Use the sibling [`india-disciplinary-process`](../india-disciplinary-process/SKILL.md) skill instead when the trigger is misconduct or for-cause termination.

## The four pathways and how to pick

```
                 ┌─────────────────────────────────────────────────┐
                 │ Why is this employee separating?                │
                 └─────────────────────────────────────────────────┘
                                       │
            ┌──────────────────────────┼──────────────────────────┐
            ▼                          ▼                          ▼
      Misconduct                 Cost reduction /            Successful
      (theft, fraud,             redundancy / role           probation
      insubordination,           elimination                 → CONFIRM
      harassment, etc.)
            │                          │
            ▼                          ▼
      ┌──────────┐         ┌──────────────────────┐
      │ Use      │         │ Confirmed in register?│
      │ disciplin│         └──────────────────────┘
      │ -ary     │              │              │
      │ skill    │              ▼              ▼
      └──────────┘            Yes            No
                              │              │
                              ▼              ▼
                    §70 Retrenchment    Probation
                    Letter              Termination
                    (full §70 comp,     (no §70 comp,
                    notice, EL,         no Re-skilling,
                    Re-skilling Fund)   §Confirmations §3
                                        clause cited)
```

## Step 1 — Read the Confirmation register

**Source of truth:** [`tech-legal/technijian/India/HR/Confirmation Letters Given.docx`](../../../technijian/India/HR/Confirmation%20Letters%20Given.docx)

This document lists every India employee who has been formally confirmed by written letter. Currently 20 names (as of 2026-05-06; see [[india_confirmation_letters_tracking]] for the snapshot).

**Decision rule:**
- Employee's first name **on** the register → Confirmed → §70 Retrenchment path (or Termination for Cause via disciplinary skill)
- Employee's first name **NOT on** the register → Probationary (initial or extended per Handbook §Confirmations §3) → Probation Termination path

**Caveat — confirmation by conduct.** A long-tenured employee (≥2 years) NOT on the register is still vulnerable to a tribunal finding of "confirmation by conduct" (continued payment, performance reviews, increments, EL accrual on payslips). For such employees, treat them as confirmed for risk purposes even though the paperwork says otherwise. Examples (as of 2026-05-06): Saroj Kumari, Navjit Kaur.

## Step 2 — Pick the template

| Pathway | Template | Where it lives |
|---|---|---|
| **Confirmation** of a successful probationer | [`Confirmation-Letter.md`](../../../docs/employees/India/00-Templates/04-Performance/Confirmation-Letter.md) | 04-Performance |
| **Probation Extension** (max 6 mo per Handbook §Confirmations §2) | [`Probation-Extension.md`](../../../docs/employees/India/00-Templates/04-Performance/Probation-Extension.md) | 04-Performance |
| **Probation Termination** (unconfirmed → exit) | [`India-Termination-Letter-Probation.md`](../../../docs/employees/India/00-Templates/07-Separation/India-Termination-Letter-Probation.md) | 07-Separation |
| **§70 Retrenchment** (confirmed workman → cost-reduction exit) | [`India-Retrenchment-Letter-Section70.md`](../../../docs/employees/India/00-Templates/07-Separation/India-Retrenchment-Letter-Section70.md) | 07-Separation |
| **Resignation Acceptance** (employee initiated) | [`Resignation-Acceptance.md`](../../../docs/employees/India/00-Templates/07-Separation/Resignation-Acceptance.md) | 07-Separation |
| **Relieving Letter** (post-exit clearance) | [`Relieving-Letter.md`](../../../docs/employees/India/00-Templates/07-Separation/Relieving-Letter.md) | 07-Separation |
| **Experience Letter** | [`Experience-Letter.md`](../../../docs/employees/India/00-Templates/07-Separation/Experience-Letter.md) | 07-Separation |
| **Full and Final Settlement** | [`Full-and-Final-Settlement.md`](../../../docs/employees/India/00-Templates/07-Separation/Full-and-Final-Settlement.md) | 07-Separation |

## Step 3 — Required pre-issuance facts

Before filling any template, gather:

| Fact | Source | Why needed |
|---|---|---|
| Date of joining | Offer letter signed in DocuSign / employee folder `info.md` | Tenure calc, retrenchment comp, gratuity vesting |
| Confirmation date (if confirmed) | Confirmation register entry + signed Confirmation Letter PDF | Establishes status; confirmation date drives EL accrual start |
| Last drawn monthly salary (gross) | Latest payroll report (typically `<MMM>_<YYYY>_Payroll_Report.xlsx`) | Notice pay, retrenchment comp, EL encashment, Re-skilling Fund |
| Basic + DA component | Payroll structure | §70(b) wages calc — if no split, gross used |
| EL balance | "Paid Leave Balance INR" column on latest payslip | EL encashment under Punjab S&E Act §§28-30 / Code on Wages §17(2) |
| Designation, employee ID, residential address | Employee folder | Header / acknowledgement block |
| Reporting manager | Employee folder / org chart | Clearance routing |

## Step 4 — Pathway-specific procedural gates

### Confirmation
- Performance review against Handbook §Confirmations §1 criteria (5 items)
- Add the first name to [`Confirmation Letters Given.docx`](../../../technijian/India/HR/Confirmation%20Letters%20Given.docx) **immediately after issuance**
- Update employee folder `info.md` with confirmation date
- File signed PDF

### Probation Termination
- Cite Handbook §Confirmations §3 (automatic extension when no Confirmation Letter issued) — this is the legal hook (see Clause 1.02 of the template)
- No §70 compensation, no Re-skilling Fund, no inquiry required
- Notice per offer letter (typically 1 month or pay-in-lieu)
- F&F within 2 working days per Code on Wages §17(2)

### §70 Retrenchment
- **Business-case memo** signed by Directors **before** notice issuance (see [[india_workforce_reduction_2026]] for a worked example)
- **§70(c) Government notice** to Haryana Labour Department — must be served *contemporaneously* with the retrenchment notice in the prescribed form
- **§70(b) compensation** — 15 days' wages × completed years (or part >6 mo) — calculation table in the template
- **§83 Re-skilling Fund** — 15 days' wages deposited to State fund (separate from F&F)
- **§71 LIFO-departure** analysis if multiple workmen in same category — last-in-first-out unless documented business reason
- **§72 re-employment register** — 12-month preference for re-hire
- **Counsel review** of letter before issuance
- F&F within 2 working days per Code on Wages §17(2)

### Termination for Cause
- Route to [`india-disciplinary-process`](../india-disciplinary-process/SKILL.md) — eight-rung natural-justice ladder

## Step 5 — Output location

Always file the drafted letter to the employee's folder:

```
c:\VSCode\tech-legal\tech-legal\technijian\India\<Employee Name>\
├── Confirmation-Letter.md       (when confirming)
├── Termination-Letter.md        (when probation-terminating)
├── Retrenchment-Letter.md       (when §70-retrenching)
├── F&F-Settlement.md            (final settlement)
└── info.md                      (running employee record — start date, salary, key dates)
```

## Common mistakes to avoid

| Mistake | Why it's wrong | Fix |
|---|---|---|
| Treating a probationer as a workman | No §70 compensation required for probationers | Cross-check the Confirmation register first |
| Treating a 4-year confirmed employee as probationary because no Confirmation Letter is on file | Tribunal will find confirmation by conduct → award full §70 comp + interest + back wages | Pay §70 comp; don't rely on paperwork-absence defence for long-tenured staff |
| Mixing performance issues with misconduct framing in a termination letter | Performance ≠ misconduct under Indian labour law; tribunal sets aside termination as *mala fide* | Separate the tracks: PIP for performance, disciplinary ladder for misconduct |
| Sending §70 retrenchment without contemporaneous §70(c) Government notice | Termination is voidable; tribunal can order reinstatement with back wages | Always serve §70(c) notice on the same day as the employee notice |
| Forgetting the Re-skilling Fund deposit | Statutory obligation under §83; non-payment is an IR Code offence | Treat as a non-negotiable line item in the F&F worksheet |
| Computing retrenchment comp on gross when payroll has a Basic+DA split | Could overpay (or underpay) by 30-50% | Pull the actual payroll structure; "wages" per §2(zzr) is Basic+DA |
| Issuing a Confirmation Letter without adding to the register | Future sessions will misclassify the employee as probationary | Step is part of the workflow — register update is mandatory |

## See also

- [[india_employee_handbook_key_clauses]]
- [[india_confirmation_letters_tracking]]
- [[india_labour_law_knowledge_base]]
- [[india_workforce_reduction_2026]]
- [[project_india_hr_templates]]
- Sibling skill: `india-disciplinary-process` (for misconduct path)
