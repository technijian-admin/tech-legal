# STATEMENT OF WORK

**SOW Number:** SOW-JDH-001
**Effective Date:** March 30, 2026
**Master Service Agreement:** (if applicable)

This Statement of Work ("SOW") is entered into by and between:

**Technijian, Inc.** ("Technijian")
18 Technology Drive, Suite 141
Irvine, California 92618

and

**JDH Pacific** ("Client")
[CLIENT ADDRESS]
[CITY, STATE ZIP]

---

## 1. PROJECT OVERVIEW

### 1.1 Project Title

Endpoint Storage Upgrade — SSD Replacement for Critical and Low-Disk Systems

### 1.2 Project Description

JDH Pacific currently has eight (8) endpoint workstations experiencing critically low or concerning disk space utilization, as identified in the Disk Space Health Report dated March 27, 2026. Four of these systems are in a critical state with less than 15 GB of free space remaining, and four additional systems are below the operational free-space threshold.

This SOW covers the procurement, installation, and validation of replacement SSD drives for all eight affected workstations using a **loaner swap methodology** to minimize end-user downtime. Technijian will deploy three (3) preconfigured loaner workstations in rotating waves, swap each affected machine for a loaner, perform drive cloning and upgrade at the Technijian facility, and return upgraded machines in subsequent visits. End-user downtime is limited to approximately 15 minutes per swap.

### 1.3 Upgrade Methodology — Loaner Swap Process

**Why Loaner Swap:** Rather than performing on-site drive cloning (which requires 1-3 hours per machine with the user waiting), Technijian will use a rotating pool of three (3) loaner workstations to minimize disruption:

1. **Wave 1 (Visit 1):** Deploy 3 loaner workstations to the 3 most critical machines. Swap cables, verify user login on loaner, and transport affected machines to Technijian facility. (~15 min downtime per user)
2. **Wave 1 Shop Work:** Clone drives to new SSDs, install upgraded drives, validate boot and applications at Technijian facility.
3. **Wave 2 (Visit 2):** Return 3 upgraded machines, swap next 3 machines with the same 3 loaners, transport to facility. (~15 min downtime per user)
4. **Wave 2 Shop Work:** Clone and upgrade batch 2 at facility.
5. **Wave 3 (Visit 3):** Return 3 upgraded machines, swap last 2 machines with loaners, transport to facility. (~15 min downtime per user)
6. **Wave 3 Shop Work:** Clone and upgrade batch 3 at facility.
7. **Final Return (Visit 4):** Return last 2 upgraded machines, collect all 3 loaners. (~15 min downtime per user)

**User Impact:** Each user experiences approximately 15 minutes of downtime per swap (two swaps total: once to loaner, once back to upgraded machine). Users can continue working on loaner machines during the upgrade period.

### 1.4 Affected Systems Summary

| Priority | Machine | Type | Current Drive | Cap. (GB) | Free (GB) | Used % | Severity |
|----------|---------|------|---------------|-----------|-----------|--------|----------|
| 1 | JDH-HQ-PC-09 | OptiPlex 5040 | TOSHIBA TL100 | 111 | 0.1 | 100% | Critical |
| 2 | JDH-HQ-LPT-01 | Precision 7780 | Samsung PM9C1a 256GB | 235 | 6 | 97% | Critical |
| 3 | JDH-WHOFFICE | OptiPlex 7080 | SK hynix PC611 256GB | 236 | 9 | 96% | Critical |
| 4 | SupplySalesconf | ASUSTeK P8Z77-V | ST240HM000 SSD | 223 | 14 | 94% | Critical |
| 5 | JDH-HQ-PC-06 | OptiPlex Micro Plus 7010 | KIOXIA 512GB NVMe | 474 | 33 | 93% | Low |
| 6 | DESKTOP-8QP97UG | ASRock AB350 Pro4 | SanDisk SSD PLUS 240GB | 251 | 34 | 86% | Low |
| 7 | Frontdesk-JDH | OptiPlex 3000 | SK hynix BC901 256GB | 236 | 40 | 83% | Low |
| 8 | DESKTOP-ED8O2CQ | Vostro 3470 | SK hynix SC401 256GB | 224 | 46 | 79% | Low |

### 1.5 Wave Assignments

| Wave | Visit | Machines | Priority |
|------|-------|----------|----------|
| Wave 1 | Visit 1 (deploy loaners) → Visit 2 (return upgraded) | JDH-HQ-PC-09, JDH-HQ-LPT-01, JDH-WHOFFICE | Critical |
| Wave 2 | Visit 2 (deploy loaners) → Visit 3 (return upgraded) | SupplySalesconf, JDH-HQ-PC-06, DESKTOP-8QP97UG | Critical + Low |
| Wave 3 | Visit 3 (deploy loaners) → Visit 4 (return upgraded) | Frontdesk-JDH, DESKTOP-ED8O2CQ | Low |

---

## 2. SCOPE OF WORK

### 2.1 In Scope

- Procurement of eight (8) replacement SSD drives (500/512 GB capacity)
- Pre-upgrade remote assessment and backup verification for all affected systems
- Provisioning of three (3) Technijian-owned loaner workstations for the swap rotation
- Four (4) on-site visits for loaner deployment, machine pickup, upgraded machine return, and loaner collection
- Full disk clone / data migration from existing drives to new SSDs at Technijian facility
- Physical drive installation and boot validation at Technijian facility
- Post-upgrade validation after 48 hours of production use
- Old drive labeling and return to Client

### 2.2 Out of Scope

The following items are expressly excluded from this SOW:

- Operating system reinstallation or reimaging (clone-based migration only)
- Microsoft 365 migration or tenant configuration (referenced in Disk Space Health Report as separate workstream)
- Desktop replacement or new hardware procurement beyond SSD drives
- Data recovery for corrupted or damaged files on existing drives
- Server-side upgrades or cloud migration
- Software license transfers or activation beyond what is required for drive swap
- Loaner workstation customization beyond basic Windows configuration and network access

### 2.3 Assumptions

- Client will provide physical access to all workstations during scheduled swap windows
- Existing drives are functional and clonable (not failed or failing)
- Machines currently listed as Offline / Undone will be powered on and accessible for the swap
- Loaner workstations will be configured with basic Windows, domain join, and network access sufficient for users to perform essential work
- Client will inform affected users of the swap schedule and ensure they save work prior to each swap window
- Minimum 2-hour on-site engagement per visit
- Cloning will be performed using industry-standard disk imaging tools (e.g., Macrium Reflect, Clonezilla) at Technijian facility

---

## 3. PROJECT PHASES

### Phase 1: Remote Assessment & Loaner Preparation

**3.1.1 Description**

Remote assessment of all eight affected systems to verify current drive health, confirm backup status, and validate form factor compatibility. Simultaneously, prepare three (3) Technijian-owned loaner workstations with basic Windows configuration, domain join credentials, and network access for the swap rotation.

**3.1.2 Deliverables**

- Drive health report (S.M.A.R.T. status) for all 8 systems
- Backup verification confirmation for each machine
- Form factor confirmation (2.5" SATA vs. M.2 2230 vs. M.2 2280) for each machine
- 3 loaner workstations prepared and tested
- Swap schedule coordinated with Client (4 visits)

**3.1.3 Schedule**

| Role | Description | Rate | Hours | Timeline |
|------|-------------|------|-------|----------|
| Tech Support (US) | Remote assessment, backup verification, scheduling | $150/hr | 3 | Week 1 |
| Tech Support (Offshore) | Loaner workstation preparation and configuration | $45/hr | 3 | Week 1 |
| | **Phase 1 Total** | | **6** | |

---

### Phase 2: On-Site Swap Visits (4 Visits, 3 Waves)

**3.2.1 Description**

Four on-site visits to JDH Pacific headquarters to execute the loaner swap rotation. Each visit involves disconnecting affected machines, deploying loaner workstations, verifying user login on loaners, and transporting machines to/from the Technijian facility.

**Visit 1:** Deploy 3 loaners → pick up machines #1-3 (JDH-HQ-PC-09, JDH-HQ-LPT-01, JDH-WHOFFICE)
**Visit 2:** Return upgraded #1-3, deploy loaners → pick up machines #4-6 (SupplySalesconf, JDH-HQ-PC-06, DESKTOP-8QP97UG)
**Visit 3:** Return upgraded #4-6, deploy loaners → pick up machines #7-8 (Frontdesk-JDH, DESKTOP-ED8O2CQ)
**Visit 4:** Return upgraded #7-8, collect all 3 loaners

**3.2.2 Deliverables**

- All 8 machines swapped and returned with upgraded drives
- User login verified on loaner at each swap
- User login verified on returned upgraded machine at each swap
- All 3 loaner workstations collected and returned to Technijian

**3.2.3 Schedule**

| Role | Description | Rate | Hours | Timeline |
|------|-------------|------|-------|----------|
| Tech Support (US) | Visit 1 — Deploy 3 loaners, pick up 3 critical machines | $150/hr | 2 | Week 2 |
| Tech Support (US) | Visit 2 — Return 3 upgraded, swap next 3, pick up | $150/hr | 2 | Week 2 |
| Tech Support (US) | Visit 3 — Return 3 upgraded, swap last 3, pick up | $150/hr | 2 | Week 3 |
| Tech Support (US) | Visit 4 — Return last 3 upgraded, collect loaners | $150/hr | 2 | Week 3 |
| | **Phase 2 Total** | | **8** | |

---

### Phase 3: Off-Site Drive Cloning & Upgrade (Technijian Facility)

**3.3.1 Description**

At the Technijian facility, perform full disk clone from each existing drive to the new SSD, install the new SSD into the machine, validate boot, OS functionality, and application integrity. Process runs in three batches of 3 machines aligned with the on-site swap waves.

**3.3.2 Deliverables**

- 8 machines with new SSDs installed and validated
- Boot verification and OS validation for each machine
- Application and data integrity confirmed for each machine
- Old drives labeled and securely stored for return to Client

**3.3.3 Schedule**

| Role | Description | Rate | Hours | Timeline |
|------|-------------|------|-------|----------|
| Tech Support (US) | Drive cloning setup, troubleshooting, SSD installation — 3 batches | $150/hr | 4 | Weeks 2-3 |
| Tech Support (Offshore) | Clone monitoring, validation scripts, integrity checks — 3 batches | $45/hr | 5 | Weeks 2-3 |
| | **Phase 3 Total** | | **9** | |

---

### Phase 4: Post-Upgrade Validation & Closeout

**3.4.1 Description**

Remote validation of all upgraded systems after 48 hours of production use. Verify disk health, free space, performance, and confirm no issues. Deliver old drives to Client.

**3.4.2 Deliverables**

- Post-upgrade health check report for all 8 systems
- Updated disk space inventory
- Old drives returned to Client (labeled by machine name)
- Project closeout confirmation

**3.4.3 Schedule**

| Role | Description | Rate | Hours | Timeline |
|------|-------------|------|-------|----------|
| Tech Support (Offshore) | Remote validation and health checks — all 8 systems | $45/hr | 3 | Week 4 |
| | **Phase 4 Total** | | **3** | |

---

## 4. EQUIPMENT AND MATERIALS

### 4.1 SSD Procurement

All drives are procured and supplied by Technijian. Pricing includes procurement, handling, and delivery.

**SATA SSD — 2.5" Form Factor (Samsung 870 EVO 500GB)**

| # | Machine | Type | Qty | Price | Sub-Total |
|---|---------|------|-----|-------|-----------|
| 1 | JDH-HQ-PC-09 | OptiPlex 5040 | 1 | $163.75 | $163.75 |
| 4 | SupplySalesconf | ASUSTeK P8Z77-V | 1 | $163.75 | $163.75 |
| 6 | DESKTOP-8QP97UG | ASRock AB350 Pro4 | 1 | $163.75 | $163.75 |
| 8 | DESKTOP-ED8O2CQ | Vostro 3470 | 1 | $163.75 | $163.75 |
| | | **SATA Subtotal** | **4** | | **$655.00** |

**NVMe SSD — M.2 2230 Form Factor (Kingston NV3 500GB)**

| # | Machine | Type | Qty | Price | Sub-Total |
|---|---------|------|-----|-------|-----------|
| 2 | JDH-HQ-LPT-01 | Precision 7780 | 1 | $173.75 | $173.75 |
| 5 | JDH-HQ-PC-06 | OptiPlex Micro Plus 7010 | 1 | $173.75 | $173.75 |
| 7 | Frontdesk-JDH | OptiPlex 3000 | 1 | $173.75 | $173.75 |
| | | **NVMe 2230 Subtotal** | **3** | | **$521.25** |

**NVMe SSD — M.2 2280 Form Factor (Dell 512GB PCIe Gen3)**

| # | Machine | Type | Qty | Price | Sub-Total |
|---|---------|------|-----|-------|-----------|
| 3 | JDH-WHOFFICE | OptiPlex 7080 | 1 | $156.25 | $156.25 |
| | | **NVMe 2280 Subtotal** | **1** | | **$156.25** |

| | | | | **Equipment Sub-Total** | **$1,332.50** |
| | | | | **Sales Tax (7.75%)** | **$103.27** |
| | | | | **Equipment Total** | **$1,435.77** |

### 4.2 Loaner Workstations

Technijian will provide three (3) loaner workstations from its equipment pool at no additional charge to Client. Loaner workstations remain the property of Technijian and will be collected upon project completion. Client is responsible for any physical damage to loaner equipment beyond normal wear.

### 4.3 Title and Ownership

Title to SSD equipment shall remain vested in Technijian until paid for in full. Upon receipt of full payment, title shall transfer to Client.

### 4.4 Warranty

Equipment warranty is provided by the manufacturer per the manufacturer's warranty terms. Technijian shall assist Client in processing any warranty claims during the warranty period.

- Samsung 870 EVO: 5-year limited warranty
- Kingston NV3: 3-year limited warranty
- Dell SSD: 5-year limited warranty

---

## 5. PRICING AND PAYMENT

### 5.1 Rate Card

| Role | Location | Rate |
|------|----------|------|
| Tech Support | United States (On-Site) | $150.00/hr |
| Tech Support | Offshore (India) | $45.00/hr |

**On-Site Terms:** $150.00/hr, 2-hour minimum per visit, no trip charges.

### 5.2 Labor Summary

| Phase | Description | US Tech ($150) | Offshore ($45) | Total Hrs | Cost |
|-------|-------------|----------------|----------------|-----------|------|
| Phase 1 | Remote Assessment & Loaner Preparation | 3 | 3 | 6 | $585.00 |
| Phase 2 | On-Site Swap Visits (4 visits, 3 waves) | 8 | — | 8 | $1,200.00 |
| Phase 3 | Off-Site Drive Cloning & Upgrade | 4 | 5 | 9 | $825.00 |
| Phase 4 | Post-Upgrade Validation & Closeout | — | 3 | 3 | $135.00 |
| **TOTAL** | | **15** | **10** | **25** | **$2,550.00** |

**Labor Cost Breakdown:**
- Tech Support (US): 15 hrs x $150/hr = $2,250.00
- Tech Support (Offshore): 10 hrs x $45/hr = $450.00

### 5.3 Total Project Cost

| Category | Amount |
|----------|--------|
| Equipment (8 SSDs) | $1,332.50 |
| Sales Tax (7.75%) | $103.27 |
| Labor (25 hours) | $2,550.00 |
| **Total Project Cost** | **$3,985.77** |

**Pricing Type:** Fixed Cost — Technijian will complete all work described in this SOW at the stated price regardless of actual hours consumed. The fixed price includes all labor, travel, loaner equipment, and project management. Equipment pricing is fixed and inclusive of procurement and handling.

### 5.4 Payment Schedule

| Milestone | Invoiced | Amount |
|-----------|----------|--------|
| Equipment procurement (before Phase 2 begins) | Upon SOW execution | $1,435.77 |
| Labor — fixed project fee | Upon project closeout | $2,550.00 |
| **Total** | | **$3,985.77** |

### 5.5 Payment Terms

All invoices are due and payable within **thirty (30) days** of the invoice date.

### 5.6 Late Payment and Collection Remedies

**(a)** Late payments shall accrue a late fee of **1.5% per month** (or the maximum rate permitted by law, whichever is less) on the unpaid balance, compounding monthly from the date payment was due. If an MSA is in effect, the late payment, acceleration, collection costs, lien, and fee-shifting provisions of the MSA shall apply in full to this SOW.

**(b)** If no MSA is in effect between the Parties, the following shall apply:

(i) **Acceleration.** If Client fails to pay any undisputed invoice within **forty-five (45) days** of the due date, all remaining fees under this SOW shall become immediately due and payable.

(ii) **Suspension.** Technijian may suspend all work under this SOW upon **ten (10) days** written notice if any invoice remains unpaid beyond the due date. Suspension shall not relieve Client of its payment obligations, and project timelines shall be adjusted accordingly at no cost to Technijian.

(iii) **Collection Costs and Attorney's Fees.** In any action or proceeding to collect fees, invoices, or other amounts owed under this SOW, Client shall be liable for all costs of collection, including reasonable attorney's fees (including in-house counsel at market rates), collection agency fees, court costs, arbitration fees, and all costs of appeal. This fee-shifting applies exclusively to collection of amounts owed and does not apply to disputes regarding service quality, professional performance, or other non-payment claims.

(iv) **Lien on Work Product.** Technijian shall retain a lien on all deliverables, work product, documentation, and materials under this SOW until all amounts owed are paid in full. Title to equipment under Section 4.3 shall not transfer until full payment is received.

(v) **Fees for Non-Collection Disputes.** Except as provided in subsection (iii) above, in any dispute arising under this SOW relating to service quality, professional performance, scope, or any other non-payment matter, each Party shall bear its own attorney's fees and costs.

---

## 6. CLIENT RESPONSIBILITIES

Client shall:

(a) Provide physical access to all workstations during scheduled swap windows;

(b) Designate a point of contact authorized to make decisions on behalf of Client;

(c) Review and approve deliverables within **five (5) business days** of submission;

(d) Ensure all relevant data is backed up prior to the start of work;

(e) Inform affected users of the swap schedule and ensure users save all work prior to each swap window;

(f) Power on and make accessible any machines currently listed as Offline / Undone prior to the scheduled swap;

(g) Accept responsibility for any physical damage to Technijian-owned loaner workstations beyond normal wear during the loaner period; and

(h) Notify Technijian promptly of any issues with loaner workstations during the swap period.

---

## 7. CHANGE MANAGEMENT

**7.01.** Any changes to the scope, schedule, or pricing of this SOW must be documented in a written Change Order signed by both Parties before work on the change begins.

**7.02.** If Client requests work outside the defined scope, Technijian shall provide a Change Order detailing the additional work, estimated hours, and cost impact.

**7.03.** Technijian shall not proceed with out-of-scope work without an approved Change Order, except in cases where delay would result in harm to Client's systems, in which case Technijian shall notify Client as soon as practicable.

---

## 8. ACCEPTANCE

**8.01.** Upon completion of each phase, Technijian shall notify Client in writing that the deliverables are ready for review.

**8.02.** Client shall review the deliverables and provide written acceptance or a detailed description of deficiencies within **five (5) business days**.

**8.03.** If Client does not respond within the review period, the deliverables shall be deemed accepted.

**8.04.** If deficiencies are identified, Technijian shall correct them and resubmit for review. This process shall repeat until acceptance is achieved or the Parties agree on a resolution.

---

## 9. GOVERNING TERMS

**9.01.** If a Master Service Agreement is in effect between the Parties, the terms of the MSA shall govern this SOW. In the event of a conflict between this SOW and the MSA, the MSA shall prevail unless this SOW expressly states otherwise.

**9.02.** If no MSA is in effect, the Technijian Standard Terms and Conditions (attached as Appendix A) shall govern this SOW.

---

## SIGNATURES

**TECHNIJIAN, INC.**

By: ___________________________________

Name: _________________________________

Title: _________________________________

Date: _________________________________

**JDH PACIFIC**

By: ___________________________________

Name: _________________________________

Title: _________________________________

Date: _________________________________
