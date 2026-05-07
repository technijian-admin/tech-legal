---
name: india-disciplinary-process
description: Use when the user wants to issue a disciplinary notice, warning, suspension, or termination-for-cause to a Technijian India employee — orchestrates the natural-justice ladder (Verbal → Written → Show Cause → Suspension → Charge Sheet → Inquiry → Final Warning → Termination for Cause) using the existing template set, with proper Indian labour law clauses, handbook citations, and procedural safeguards. Examples: "Issue a written warning to Vinod for late attendance", "Draft a show cause notice for Rajat", "Start a disciplinary inquiry against [employee]", "Termination for cause for [misconduct]".
---

# India Disciplinary Process — Natural Justice Ladder

## When to use

Trigger this skill the moment the user asks for **any** of:

- A verbal/written warning to an India employee
- A Show Cause Notice
- A suspension order pending inquiry
- A Charge Sheet
- An Inquiry Notice (or to set up a domestic inquiry)
- A Final Warning
- A Termination for Cause / Termination for Misconduct
- Any reference to "disciplinary action", "PIP for misconduct", or "punish [employee]"

**Do NOT use for:**
- Cost-reduction terminations / retrenchment of confirmed workmen → use [`India-Retrenchment-Letter-Section70.md`](../../../docs/employees/India/00-Templates/07-Separation/India-Retrenchment-Letter-Section70.md) under §70 IR Code instead
- Probation terminations of unconfirmed employees → use [`India-Termination-Letter-Probation.md`](../../../docs/employees/India/00-Templates/07-Separation/India-Termination-Letter-Probation.md)
- Performance-only issues without a misconduct event → use Performance Improvement Plan ([`Performance-Improvement-Plan.md`](../../../docs/employees/India/00-Templates/04-Performance/Performance-Improvement-Plan.md))

The distinction is rigid: **performance ≠ misconduct** under Indian labour law (see [[india_employee_handbook_key_clauses]]). Tribunals will set aside a misconduct termination if the underlying issue is really poor performance.

## Pre-flight checks (BEFORE drafting anything)

Run these in order. Do not draft any disciplinary document until each is answered:

1. **Is this misconduct or performance?** Map the conduct to the 16-item misconduct schedule in §Standards of Performance and Conduct of the Employee Handbook (theft, insubordination, falsification of records, harassment, confidentiality breach, etc.). If the conduct doesn't fit the schedule, it's likely a performance issue → stop and use the PIP path.
2. **Read the Confirmation register.** Open [`tech-legal/technijian/India/HR/Confirmation Letters Given.docx`](../../../technijian/India/HR/Confirmation%20Letters%20Given.docx) — does the employee's first name appear? This determines whether Standing Orders Act 1946 protections + IR Code §70 carve-out applies.
3. **Read the employee's offer letter and any prior disciplinary records** in their folder under `tech-legal/technijian/India/<Employee Name>/` to determine the right rung of the ladder. Skipping rungs without a proportionality basis is a tribunal red flag.
4. **Identify the misconduct evidence trail.** What documentary proof exists (logs, emails, attendance records, witness statements, screenshots)? If proof is thin, recommend a preliminary fact-finding step before any formal notice.
5. **POSH overlap check.** If the misconduct alleged includes any sexual-harassment element, the matter routes through the Internal Complaints Committee under POSH Act 2013 — NOT the regular disciplinary ladder. Defer to the POSH-Complaint-Form template instead.

## The eight-rung ladder (templates pre-built)

All templates are at [`tech-legal/docs/employees/India/00-Templates/05-Disciplinary/`](../../../docs/employees/India/00-Templates/05-Disciplinary/). They are already drafted with proper natural-justice clauses, Indian case law citations (*Workmen of Motipur Sugar Factory*, *Managing Director v. Dhruvaraj Trivedi*, *ECIL v. Karunakar*, *Hotel Imperial v. Hotel Workers' Union*), and Standing Orders Act 1946 references. **Do NOT redraft from scratch — fill in the placeholders.**

| Rung | Template | When | Authority | Cool-off / Process |
|------|----------|------|-----------|--------------------|
| 1 | [`Verbal-Warning-Record.md`](../../../docs/employees/India/00-Templates/05-Disciplinary/Verbal-Warning-Record.md) | First-time minor infraction; correctable behaviour | Reporting Manager + HR co-sign | Document only — no employee signature required, but record retained in personnel file |
| 2 | [`Written-Warning.md`](../../../docs/employees/India/00-Templates/05-Disciplinary/Written-Warning.md) | Repeat minor or first-time moderate infraction | HR Head signature, Director cc | Employee acknowledgement required; 90-day improvement window typical |
| 3 | [`Show-Cause-Notice.md`](../../../docs/employees/India/00-Templates/05-Disciplinary/Show-Cause-Notice.md) | Suspected serious misconduct — opens the formal process | HR Head signature, Director approval | **72 hours** to respond (or 7 days if non-grave); employee has right to inspect documents relied upon |
| 4 | [`Suspension-Pending-Inquiry.md`](../../../docs/employees/India/00-Templates/05-Disciplinary/Suspension-Pending-Inquiry.md) | Risk of evidence tampering, witness intimidation, or further misconduct | Disciplinary Authority (Director) | **Subsistence allowance** payable at 50% (first 90 days) / 75% (thereafter) of basic+DA per Standing Orders / Industrial Employment rules |
| 5 | [`Charge-Sheet.md`](../../../docs/employees/India/00-Templates/05-Disciplinary/Charge-Sheet.md) | Show Cause response unsatisfactory; specific charges with date/time/place/witness/document refs | Director (Disciplinary Authority) | **14 days minimum** for written reply to charges |
| 6 | [`Inquiry-Notice.md`](../../../docs/employees/India/00-Templates/05-Disciplinary/Inquiry-Notice.md) | After charge-sheet reply (or non-reply) | Independent Inquiry Officer (NOT the complainant; NO bias) | Right to: (a) defend in person, (b) examine witnesses, (c) cross-examine Company witnesses, (d) bring co-worker as defence assistant, (e) inspect inquiry record; **inquiry report served on employee BEFORE punishment decision** (mandated by *ECIL v. Karunakar* (1993) 4 SCC 727) |
| 7 | [`Final-Warning.md`](../../../docs/employees/India/00-Templates/05-Disciplinary/Final-Warning.md) | Inquiry concluded; charges proved but punishment less than termination warranted | Disciplinary Authority | Used when proportionality favours retention with stern caution; future misconduct triggers immediate termination |
| 8 | [`Termination-for-Cause.md`](../../../docs/employees/India/00-Templates/05-Disciplinary/Termination-for-Cause.md) | Inquiry proved charges; punishment proportional to misconduct | Disciplinary Authority | Right of appeal to Appellate Authority under §7B IR Code (Chandra Jain per template hierarchy); **no §70 retrenchment compensation due** — falls outside §2(zh) IR Code |

## The non-negotiable procedural rules

Tribunals set aside misconduct terminations on procedural grounds far more often than substantive ones. The following are the most common failure modes:

1. **No charge sheet, or vague charges** — Charges must specify date, time, place, nature of misconduct, witness names, and supporting document references. *"Allegation of misconduct"* is not a charge.
2. **Inquiry Officer is the complainant or biased** — *Hotel Imperial v. Hotel Workers' Union* AIR 1959 SC 1342 voids inquiries where the IO had prior involvement.
3. **Right to cross-examine denied** — The defendant must be allowed to question Company witnesses. Telephone or written-only "inquiries" almost always fail.
4. **Inquiry report not served before punishment decision** — *ECIL v. Karunakar* (1993) 4 SCC 727 mandates service of the report and an opportunity to make further representation.
5. **Penalty disproportionate to misconduct** — *Bharat Forge v. Uttam Manohar Nakate* (2005) 2 SCC 489 lets tribunals intervene if shockingly disproportionate. Termination for a minor first-time issue without prior warnings → reversed.
6. **Probationer treated as workman or vice versa** — Always cross-check the [Confirmation register](../../../technijian/India/HR/Confirmation%20Letters%20Given.docx).
7. **Appeal right not flagged** — Termination letter must inform the employee of their §7B IR Code appeal right + the appellate authority's identity.

If the user proposes skipping any of the above, **flag it as a tribunal-loss risk before proceeding**. Quote the case law.

## Standard signatory hierarchy (per `project_india_hr_templates`)

| Role | Person | Email |
|------|--------|-------|
| Disciplinary Authority | Ravi Jain (Director) | rjain@technijian.com |
| HR Head — India | Shelja Mehta | smehta@technijian.com |
| Appellate Authority (§7B IR Code appeals) | Chandra Jain | (Director) |
| Inquiry Officer | **Independent — appoint per case** (must NOT be the complainant; cannot have prior involvement) | — |

## Workflow — when the user invokes this skill

1. **Confirm the misconduct schedule item.** Quote the specific Handbook clause being violated.
2. **Confirm the rung.** Based on prior disciplinary record, recommend the appropriate template. Do not skip rungs without proportionality reasoning.
3. **Pull the placeholder set.** Open the relevant template, list every `<placeholder>`, and ask the user for any field you can't infer (employee ID, witness names, exact date/time, supporting document refs).
4. **Draft into employee folder.** Write the filled letter to `c:\VSCode\tech-legal\tech-legal\technijian\India\<Employee Name>\<Disc-Doc-Ref>.md` and surface it for the user's review before any handover.
5. **Update the disciplinary register.** Maintain a per-employee `Disciplinary-Log.md` in their folder with: date, document type, allegations, response, outcome.
6. **Flag pre-issuance gates.** Counsel review (always for rungs 4+), HR/Director sign-off, IT/access revocation timing for suspensions, witness availability for inquiry, subsistence allowance computation for suspensions.

## Output expectations

A disciplinary document is not "done" until it has:

- Specific allegation with date/time/place/witness/document references (NOT generic)
- Handbook clause + statute cited (Industrial Employment Standing Orders Act 1946 / Code on Wages 2019 / IR Code 2020 §2(zh)(iv) / IT Act 2000 §43A / POSH Act 2013, as relevant)
- Right-to-respond timeline + delivery method (email + hard copy + acknowledgement)
- Confidentiality + non-retaliation clauses
- Signatory block matching the hierarchy above
- Acknowledgement-of-receipt block with witness fall-back if employee refuses
- Drafting notes deleted before issuance

## See also

- [[india_employee_handbook_key_clauses]] — handbook citation map
- [[india_confirmation_letters_tracking]] — confirmed-vs-probationary register
- [[india_workforce_reduction_2026]] — current restructuring context (do not confuse with disciplinary path)
- [[india_labour_law_knowledge_base]] — full statute reference (26 files)
- [[project_india_hr_templates]] — template library inventory + branded-docx build pipeline
- [[feedback_indian_law_corrections_user_made]] — corrections the user has caught (gratuity 5-yr, EL from payroll not statute)
