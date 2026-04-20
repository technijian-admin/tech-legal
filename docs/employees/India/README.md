# India — HR, Legal & Office Documents

Folder for managing the Technijian India office and employees: templates, statutory compliance records, office administration, and per-employee files.

> **Legal disclaimer:** Templates in `00-Templates/` are drafting starts reflecting common Indian employment-law practice. They are **not legal advice**. Before first use in a real matter, have them reviewed by Indian counsel for fit with the applicable State (Shops & Establishments Act, Professional Tax), certified Standing Orders (if applicable), and current wage-code/law changes.

---

## Structure

```
00-Templates/                   ← master templates (edit here, copy into 03-Employees/ for use)
├── 01-Offer-Onboarding/
├── 02-Agreements-Policies/
├── 03-Compensation-Benefits/
├── 04-Performance/
├── 05-Disciplinary/
├── 06-Leave-Attendance/
├── 07-Separation/
└── 08-POSH-Grievance/

01-Statutory-Compliance/        ← scans / filings / registrations (Company-level)
├── Shops-Establishments/
├── PF-EPFO/
├── ESI/
├── Professional-Tax/
├── Gratuity/
├── POSH-ICC-Records/           ← ICC constitution, annual report, inquiry records
└── Labor-Returns-Filings/

02-Office-Administration/       ← non-HR office docs
├── Lease-Agreement/
├── Vendor-Contracts/
├── Insurance-GroupHealth/
├── Utilities/
└── Asset-Register/

03-Employees/                   ← one folder per employee, same 01-07 sub-buckets inside
└── <EMP-CODE>_<Name>/
    ├── 01-Offer-Onboarding/
    ├── 02-Agreements-Signed/
    ├── 03-Compensation-Letters/
    ├── 04-Performance/
    ├── 05-Disciplinary/
    ├── 06-Leave-Attendance/
    └── 07-Separation/
```

---

## Scenario routing — "which template do I use?"

### Hiring
| Scenario | Template |
|---|---|
| Extending an offer | `00-Templates/01-Offer-Onboarding/India Offer Letter.docx` |
| Employee accepts offer | `00-Templates/01-Offer-Onboarding/Appointment-Letter.md` |
| Before joining — collect docs | `00-Templates/01-Offer-Onboarding/Joining-Kit-Checklist.md` |
| BGV consent | `00-Templates/01-Offer-Onboarding/Background-Verification-Consent.md` |
| Day 1 / Month 1 walkthrough | `00-Templates/01-Offer-Onboarding/Induction-Checklist.md` |

### Day-1 paperwork
| Scenario | Template |
|---|---|
| NDA, IP | `00-Templates/02-Agreements-Policies/NDA-Employee.md` |
| Non-compete / non-solicit | `00-Templates/02-Agreements-Policies/Non-Compete-Non-Solicit.md` |
| Code of conduct sign-off | `00-Templates/02-Agreements-Policies/Code-of-Conduct-Acknowledgement.md` |
| IT acceptable use sign-off | `00-Templates/02-Agreements-Policies/IT-Acceptable-Use.md` |
| Master handbook | `00-Templates/02-Agreements-Policies/Employee Handbook - India.docx` |

### Compensation
| Scenario | Template |
|---|---|
| CTC structure for appointment | `00-Templates/03-Compensation-Benefits/CTC-Breakup-Template.md` |
| Annual increment | `00-Templates/03-Compensation-Benefits/Increment-Letter.md` |
| Performance bonus | `00-Templates/03-Compensation-Benefits/Bonus-Letter.md` |
| Expense policy reference | `00-Templates/03-Compensation-Benefits/Reimbursement-Policy.md` |

### Performance and lifecycle
| Scenario | Template |
|---|---|
| End of probation — confirmed | `00-Templates/04-Performance/Confirmation Letter.docx` |
| End of probation — extend | `00-Templates/04-Performance/Probation-Extension.md` |
| Annual / half-yearly review | `00-Templates/04-Performance/Performance-Review-Form.md` |
| Promotion | `00-Templates/04-Performance/Promotion-Letter.md` |
| Under-performance | `00-Templates/04-Performance/Performance-Improvement-Plan.md` |

### Discipline (ladder — use in order for all but gross misconduct)
| Step | Template |
|---|---|
| 1. Verbal counseling | `00-Templates/05-Disciplinary/Verbal-Warning-Record.md` |
| 2. Written warning | `00-Templates/05-Disciplinary/Written-Warning.md` |
| 3. Show cause | `00-Templates/05-Disciplinary/Show-Cause-Notice.md` |
| 4a. Suspend pending inquiry | `00-Templates/05-Disciplinary/Suspension-Pending-Inquiry.md` |
| 4b. Charge sheet | `00-Templates/05-Disciplinary/Charge-Sheet.md` |
| 5. Inquiry notice | `00-Templates/05-Disciplinary/Inquiry-Notice.md` |
| 6. Final warning (alternative to termination) | `00-Templates/05-Disciplinary/Final-Warning.md` |
| 7. Termination for cause | `00-Templates/05-Disciplinary/Termination-for-Cause.md` |

**For gross misconduct** (theft, fraud, assault, serious safety breach, proven sexual harassment), skip straight to Show Cause → Suspension → Charge Sheet → Inquiry → Termination. Do not start with a verbal warning.

### Leave and attendance
| Scenario | Template |
|---|---|
| Policy reference | `00-Templates/06-Leave-Attendance/Leave-Policy.md` |
| Employee requests leave | `00-Templates/06-Leave-Attendance/Leave-Application.md` |
| WFH policy | `00-Templates/06-Leave-Attendance/WFH-Policy.md` |
| Missed swipe / biometric issue | `00-Templates/06-Leave-Attendance/Attendance-Regularization.md` |

### Separation
| Scenario | Template |
|---|---|
| Employee resigns | `00-Templates/07-Separation/Resignation-Acceptance.md` |
| Termination without cause (notice-based) | `00-Templates/07-Separation/India Termination Letter.docx` |
| Termination for cause | `00-Templates/05-Disciplinary/Termination-for-Cause.md` |
| On LWD — relieving | `00-Templates/07-Separation/Relieving-Letter.md` |
| On LWD — experience | `00-Templates/07-Separation/Experience-Letter.md` |
| Post-LWD — F&F settlement | `00-Templates/07-Separation/Full-and-Final-Settlement.md` |
| Exit interview | `00-Templates/07-Separation/Exit-Interview-Form.md` |

### POSH and grievance
| Scenario | Template |
|---|---|
| POSH policy (publish annually) | `00-Templates/08-POSH-Grievance/POSH-Policy.md` |
| ICC constitution / rotation | `00-Templates/08-POSH-Grievance/ICC-Constitution-Notice.md` |
| Sexual harassment complaint | `00-Templates/08-POSH-Grievance/POSH-Complaint-Form.md` |
| Non-POSH grievance | `00-Templates/08-POSH-Grievance/Grievance-Form.md` |

---

## Conventions

### Per-employee folder naming
```
03-Employees/TJI-001_Ravi_Kumar/
03-Employees/TJI-002_Priya_Sharma/
```
Use the India employee code from payroll (e.g., `TJI-001`). Underscores in the name, no spaces.

### Document naming inside employee folders
```
2026-04-20_Appointment-Letter_signed.pdf
2026-10-20_Confirmation-Letter.docx
2027-01-15_Increment-Letter_FY27-28.docx
2027-06-10_Written-Warning_attendance.pdf
```
Always prefix with ISO date so sort order = chronology.

### Signed vs draft
- Drafts: keep `.docx` / `.md`.
- Signed versions: save as `.pdf` with `_signed` suffix in the per-employee folder.
- Keep signed + unsigned together so the "as sent" diff is traceable.

### Statutory retention
| Record | Minimum retention |
|---|---|
| Appointment letters, NDAs, F&F | 7 years post-separation |
| Attendance registers | 3 years |
| Wage registers / salary slips | 3 years |
| PF records | 7 years |
| POSH inquiry records | 7 years, confidential |
| Income tax / TDS | 7 years |
| Registrations (S&E, PF, ESI, PT) | Permanent |

---

## What's NOT in this folder
- **Payroll data & salary slips** — HR payroll system, not this repo.
- **Personally identifiable documents (Aadhaar, PAN copies)** — HR system with access controls, not committed to git.
- **Client-facing work product** — lives under the relevant client folder or in `clients/<CODE>/`.
- **US employees** — see sibling folder `../US/`.

## Related
- `../US/` — US office equivalents
- `../../client-portal/` — client portal API docs
- `../../Client/` — client-visible docs
