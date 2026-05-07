# SCHEDULE A — MONTHLY MANAGED SERVICES

**Attached to Master Service Agreement MSA-TALY-2026**
**Effective Date:** _______________ 2026

This Schedule describes the Monthly Managed Services provided by Technijian, Inc. ("Technijian") to **Talley & Associates** ("Client") under the Master Service Agreement.

---

## PART 1 — ONLINE SERVICES

### 1.1 Description

Online Services include managed infrastructure, security, monitoring, and related IT services delivered on a recurring monthly basis. Services are selected from the Rate Card (Schedule C) and itemized in the Service Order in Section 4 of this Schedule.

### 1.2 Service Categories

| Category | Description |
|----------|-------------|
| Cloud Infrastructure | Virtual machines, production/replicated/backup storage |
| Server Management | Patch management, image backup, antivirus, remote access, secure internet, network operations |
| Desktop Management | Patch management, antivirus, remote access, secure internet, network operations |
| Network & Security | Firewall appliances (Sophos), SD-WAN (VeloCloud), edge appliances |
| Email & Compliance | Email archiving, DMARC/DKIM management |
| Backup & Recovery | Veeam 365 backup, replicated and backup storage |

### 1.3 Service Levels

| Service Level | Target |
|---------------|--------|
| Infrastructure Uptime | 99.9% monthly (excluding scheduled maintenance) |
| Scheduled Maintenance | Tuesday evenings and Saturdays (with advance notice), not to exceed 8 hours per month |
| Critical Incident Response | Within 1 hour of notification |
| Standard Support Response | Within 4 business hours |
| Emergency Maintenance | As needed with reasonable notice |

### 1.4 Service Credits

**(a) Measurement.** Infrastructure Uptime is measured monthly as the percentage of total minutes in the calendar month during which the affected Online Service is operational and accessible by Client, as recorded by Technijian's monitoring system. Raw measurement data and the monthly uptime calculation shall be available to Client upon written request. The unit of measurement is per Online Service (per VM, per managed device, per network appliance) as specified in the Service Order; uptime is not aggregated across Online Services.

**(b) Credit Schedule.** If Technijian fails to meet the 99.9% Infrastructure Uptime target in any calendar month for a particular Online Service (subject to the exclusions in subsection (c) below), Client shall be entitled to a service credit calculated against the **monthly recurring fee for the affected Online Service only**, as follows:

| Monthly Uptime (Affected Service) | Service Credit (% of Affected Service's Monthly Fee) |
|----------------|-------------------------------------------|
| 99.0% – 99.89% | 5% |
| 98.0% – 98.99% | 10% |
| 95.0% – 97.99% | 20% |
| Below 95.0% | 30% |

**(c) Exclusions.** Excluded from the uptime calculation: (i) scheduled maintenance windows under Section 1.3; (ii) emergency maintenance with reasonable advance notice; (iii) downtime caused by Client's acts or omissions; (iv) downtime caused by Client-provided or Client-procured hardware, software, or services not under Technijian's management; (v) downtime caused by failures of third-party services outside Technijian's reasonable control; (vi) Force Majeure Events under MSA Section 9.06; (vii) any period during which Client's services are suspended for non-payment under MSA Section 3.06; and (viii) downtime resulting from Client's refusal to permit a remediation action recommended by Technijian.

**(d) Claim Procedure.** Client must request service credits in writing to contracts@technijian.com within **fifteen (15) days** of the end of the affected month, identifying the affected Online Service, the dates and times of the alleged downtime, and any supporting evidence. Technijian will validate the claim against monitoring data and apply approved credits to the next monthly invoice within thirty (30) days.

**(e) Cap and Sole Remedy.** The aggregate service credits payable under this Section in any single calendar month shall not exceed thirty percent (30%) of the affected Online Service's monthly recurring fee. Service credits are Client's sole and exclusive remedy for failure to meet the uptime target. Nothing in this Section limits Client's remedies under the MSA for Technijian's gross negligence, willful misconduct, or breach of data protection obligations under MSA Section 10.

### 1.5 Monitoring and Reporting

Technijian shall provide:

(a) 24/7 monitoring of Client's infrastructure included in the Service Order;

(b) Monthly service reports summarizing uptime, incidents, and support activity; and

(c) Quarterly service reviews with Client's designated representative.

---

## PART 2 — SIP TRUNK SERVICES

Not currently subscribed by Client. Available services and rates are listed in Schedule C, Section 4. To add SIP Trunk Services, the Parties shall execute an updated Service Order under this Schedule.

---

## PART 3 — VIRTUAL STAFF (CONTRACTED SUPPORT)

### 3.1 Description

Virtual Staff services provide Client with dedicated technology support personnel on a contracted basis. This service operates on a **cycle-based billing model** as described below, except where the Service Order in Section 4 designates a role as **hourly (ad-hoc)**, in which case work is billed in 15-minute increments at the Hourly Rate from Schedule C and not committed to a Cycle.

### 3.2 Support Roles

Client may select from the following standard support roles:

| Role | Location | Hours | Rate |
|------|----------|-------|------|
| CTO Advisory | United States | Normal Business Hours / After-Hours | Per Rate Card (Schedule C) |
| Developer | United States | Normal Business Hours | Per Rate Card (Schedule C) |
| Tech Support | United States | Normal Business Hours / After-Hours | Per Rate Card (Schedule C) |
| Developer | India (Night Shift) | US Business Hours | Per Rate Card (Schedule C) |
| Tech Support | India (Night Shift) | US Business Hours | Per Rate Card (Schedule C) |
| Tech Support | India (Day Shift / After-Hours) | US After-Hours | Per Rate Card (Schedule C) |

**Naming Convention:**
- "India — Night" refers to India-based staff working during US business hours (nighttime in India)
- "India — Day" refers to India-based staff working during US after-hours (daytime in India)

### 3.3 Cycle-Based Billing Model (applies only to roles designated as "Cycle" in the Service Order)

**(a) Billing Cycle.** For roles designated as "Cycle," Client selects a billing cycle of **3, 6, or 12 months** (the "Cycle"). The Cycle is used to calculate the monthly billed amount and track actual usage.

**(b) Monthly Billed Amount Calculation.** The fixed monthly billing rate for each Cycle role is calculated as follows:

1. At the start of each new Cycle, Technijian calculates the **average monthly hours** consumed per role during the previous Cycle, excluding the final month of that Cycle (to avoid billing spikes from ramp-down or ramp-up activity in the transition month).

2. This average becomes the **monthly billed hours** for each role during the current Cycle.

3. The monthly billed amount for each role equals the monthly billed hours multiplied by the applicable **Contracted Rate** from the Rate Card (Schedule C).

**(c) Running Balance.** Technijian maintains a running balance for each Cycle role, calculated as follows:

1. At the start of each month, the running balance is adjusted by:
   - **Adding** the actual hours used during the previous month; and
   - **Subtracting** the monthly billed hours for that month.

2. A **positive running balance** indicates hours consumed in excess of billed amounts (Client owes additional hours).

3. A **negative running balance** indicates hours billed in excess of consumption (Client has a credit).

**(d) Cycle Reconciliation.** At the end of each Cycle:

1. The running balance for each Cycle role is reconciled.

2. Any net positive balance (hours consumed but not yet paid) is invoiced at the applicable **Hourly Rate** from the Rate Card.

3. Any net negative balance (hours paid but not consumed) carries forward to the next Cycle as a credit.

**(e) Cancellation.** If Client terminates Virtual Staff services or this Agreement:

1. Any positive running balance (actual hours exceeding billed hours) shall become immediately due and payable at the **Hourly Rate** from the Rate Card.

2. Any negative running balance (billed hours exceeding actual hours) will be credited to Client's final invoice. The credit shall equal the full net negative balance for each role, up to a maximum of the total billed amount for the current Cycle for that role. Any remaining credit beyond this maximum shall be forfeited, as Technijian has committed staffing resources and reserved capacity for the duration of the Cycle.

**(f) Cycle Reconciliation Dispute Window.** Technijian shall deliver a written reconciliation statement to Client within **ten (10) business days** of the end of each Cycle. Client shall have **fifteen (15) business days** from receipt of the reconciliation statement to dispute any portion of the running balance, specifying the nature of the dispute in writing. Failure to provide a timely written dispute shall constitute acceptance of the reconciliation.

**(g) Minimum Contracted Hours.** The monthly billed hours for each Cycle role shall not fall below **fifty percent (50%)** of the initial contracted hours established in the Service Order for that role (the "Minimum Hours"). If actual usage drops below the Minimum Hours for three (3) or more consecutive months, Technijian may adjust the monthly billed hours down to the Minimum Hours at the start of the next Cycle, but shall not reduce below the Minimum Hours without mutual written agreement. If Client wishes to reduce hours below the Minimum, Client may request a Service Order amendment, subject to Technijian's approval and a **thirty (30) day** notice period.

### 3.4 Hourly (Ad-Hoc) Roles

For roles designated as **"Hourly (Ad-Hoc)"** in the Service Order:

(a) No Cycle commitment applies. There is no minimum monthly hours commitment, no running balance, and no Cycle reconciliation.

(b) Work is billed at the **Hourly Rate** (or **After-Hours Rate** for after-hours work) from Schedule C, in 15-minute increments.

(c) Each weekly out-of-contract invoice (MSA Section 3.02(d)) will list ticket-by-ticket time entries for any Hourly Ad-Hoc work performed during the week.

(d) Either Party may at any time propose converting an Hourly Ad-Hoc role to a Cycle role (or vice versa) by amending this Service Order in writing.

### 3.5 Weekly Service Invoices

Technijian shall provide Client with **weekly service invoices** that detail:

(a) Each support ticket addressed during the period;

(b) The role, resource name, and hours spent per ticket;

(c) Whether the work was performed during normal or after-hours;

(d) A description of the work performed; and

(e) The current running balance for each Cycle role (and the weekly hourly total for each Hourly Ad-Hoc role).

These weekly reports are for transparency and tracking purposes. The monthly invoice for Cycle roles reflects the billed amount per the Cycle calculation; Hourly Ad-Hoc work is billed weekly in arrears per MSA Section 3.02(d).

### 3.6 New Cycle Onboarding

For new Cycle roles without a previous Cycle history, the initial Cycle billing shall be based on:

(a) A mutually agreed-upon estimated monthly hours per role, documented in the Service Order; and

(b) Actual usage tracking beginning immediately, with the first Cycle reconciliation occurring at the end of the initial Cycle period.

---

## PART 4 — SERVICE ORDER (TALY)

**Service Order Number:** SO-TALY-2026-A
**Effective Date:** _______________ 2026

### 4.1 Client Information

| | |
|---|---|
| Client Name | Talley & Associates |
| Client Address | Suite 120, Laguna Hills, CA 92653 |
| Primary Contact | Robert L. Evens |
| Contact Email | rob@talleyassoc.com |
| Contact Phone | (949) 380-3300 |
| Portal DirID | 7728 |

### 4.2 Online Services — Monthly Recurring

#### 4.2.1 Desktop Management (×7 desktops)

| Code | Service | Qty | Unit | Unit Rate | Monthly Total |
|------|---------|-----|------|----------:|--------------:|
| AVD | AV Protection — Desktop (CrowdStrike) | 7 | Per desktop | $8.50 | $59.50 |
| AVMH | AVH Protection — Desktop (Huntress) | 7 | Per desktop | $6.00 | $42.00 |
| MR | My Remote | 7 | Per desktop | $2.00 | $14.00 |
| PMW | Patch Management | 7 | Per desktop | $4.00 | $28.00 |
| SI | My Secure Internet (DNS Filtering) | 7 | Per desktop | $6.00 | $42.00 |
| | | | | **Subtotal** | **$185.50** |

#### 4.2.2 Network Operations (×32 devices)

| Code | Service | Qty | Unit | Unit Rate | Monthly Total |
|------|---------|-----|------|----------:|--------------:|
| SHM | Health Monitoring (SNMP) | 32 | Per device | $2.00 | $64.00 |
| SSM | Syslog Monitoring | 32 | Per device | $2.00 | $64.00 |
| | | | | **Subtotal** | **$128.00** |

#### 4.2.3 Backup & Recovery

| Code | Service | Qty | Unit | Unit Rate | Monthly Total |
|------|---------|-----|------|----------:|--------------:|
| TB-BSTR | Backup Storage | 1 | Per TB | $50.00 | $50.00 |
| | | | | **Subtotal** | **$50.00** |

> **Note on prior services NOT continued under this Agreement:** Real-Time Penetration Testing (RTPT, $42.00/mo for 6 IPs) and Site Assessment (SA, $50.00/mo for 1 domain) were billed under the predecessor "Monthly Support" contract and are **not included** in this Service Order. Client acknowledges these external-attack-surface security controls have been removed at Client's direction. Either may be re-added at any time at then-current Schedule C rates by amending this Service Order.

### 4.3 Virtual Staff — Service Order

| Role | Location / Shift | Billing Mode | Cycle Length | Est. Monthly Hours | Rate | Est. Monthly Cost |
|------|-----------------|--------------|--------------|-------------------:|-----:|------------------:|
| Tech Support | India — Night (US Business Hours) | **Cycle** | 3 months | 2.75 | $15.00 / hr (Contracted) | $41.25 |
| Tech Support | India — Day (US After-Hours) | **Cycle** | 3 months | 1.85 | $30.00 / hr (Contracted) | $55.50 |
| Tech Support | United States (Remote, Normal & After-Hours) | **Hourly (Ad-Hoc)** | n/a | as used | $150.00 / hr Normal · $250.00 / hr After-Hours | as used |
| | | | | | **Committed Subtotal** | **$96.75** |

**Initial Cycle Period:** 3 months from Effective Date.

**Notes:**

(a) US Tech Support work is billed **hourly (ad-hoc)** under Section 3.4 of this Schedule. There is no monthly commitment for US Tech Support; Client pays for time actually consumed at the Schedule C Hourly Rate (Normal $150.00 / After-Hours $250.00), in 15-minute increments, on the weekly out-of-contract invoice (MSA Section 3.02(d)). The prior Cycle commitment of 1.38 hours/month at $125.00/hr is **discontinued** under this Agreement.

(b) India Tech Support — Night and India Tech Support — Day remain on the Cycle model. Initial monthly hours (2.75 N / 1.85 AH) reflect average actual usage in the prior Cycle. Monthly billed hours will be re-baselined at each Cycle reconciliation per Section 3.3(b).

(c) On-site support (US), Emergency / Critical Response, Project Management, and Developer roles are not currently subscribed but are available at the rates in Schedule C if requested.

### 4.4 Subscription Services (Schedule B)

None active at execution. See Schedule B for available subscription categories. Future subscriptions to be added by Subscription Order under Schedule B.

### 4.5 Monthly Recurring Totals

| Category | Monthly Total |
|----------|--------------:|
| Desktop Management | $185.50 |
| Network Operations | $128.00 |
| Backup & Recovery | $50.00 |
| Virtual Staff — Cycle (committed) | $96.75 |
| **Monthly Recurring Subtotal** | **$460.25** |
| Estimated Sales Tax (per applicable rate) | $7.75 |
| **Estimated Monthly Recurring Total** | **~$468.00** |

**Plus, billed weekly in arrears (out-of-contract):** US Tech Support ad-hoc time at Schedule C Hourly Rates, in 15-minute increments. Based on Client's prior 16-month average actual usage of 0.90 hours/month of US Remote (Normal) tech support, the **expected ad-hoc cost** is approximately $135.00/month, for a **blended estimated monthly cost of approximately $603.00**, inclusive of tax. Actual ad-hoc charges will vary with actual usage.

**Comparison to Prior "Monthly Support" Contract** (most recent monthly invoice #28363, May 1, 2026, for service period June 2026): $724.75. New estimated steady-state run-rate (~$603/mo blended) represents an estimated reduction of **approximately $122/month (≈17%)** at average usage, and a **$256.75/month (≈35%) reduction** in the visible recurring monthly invoice (i.e., before any ad-hoc US Tech Support consumption in a given month).

### 4.6 One-Time Setup Fees

None.

### 4.7 Service Commencement Date

Services under this Service Order shall commence on the Effective Date of this Schedule.

### 4.8 Special Terms

(a) **Carry-Forward of Cycle Balance.** Any net negative running balance (credit) on the India Tech Support — Night or India Tech Support — Day roles existing under the predecessor Monthly Support contract (Contract ID 5185) as of the Effective Date will carry forward to the first Cycle under this Service Order, subject to the cap in Section 3.3(e)(2).

(b) **Open AR Carve-Out.** This Service Order does not waive or settle any unpaid balance on prior invoices, including the partially-paid invoice #27954 (March 2026 monthly). The Parties shall reconcile any outstanding amounts in accordance with the prior contract and the MSA payment provisions.

---

## GENERAL TERMS FOR THIS SCHEDULE

### Changes to Services

Either Party may request changes to the services described in this Schedule by providing **thirty (30) days** written notice. Changes to quantities, roles, or service levels shall be documented in an updated Service Order signed by both Parties.

### Payment and Collection

All payment terms, late fees, acceleration rights, collection costs, attorney's fees, lien rights, and other payment enforcement provisions set forth in Sections 3.04 through 3.10 and Section 8.04 of the Master Service Agreement apply in full to all services under this Schedule. In the event of non-payment, Technijian may suspend services in accordance with Section 3.06 of the MSA, which provides for suspension of the specific service associated with the unpaid invoice after thirty (30) days past due, and suspension of all services across Schedules and SOWs after sixty (60) days past due.

### Pricing Adjustments

Pricing for services under this Schedule is subject to the Rate Card (Schedule C). Technijian may adjust rates per Schedule C, Section 5.01, effective at the start of the next Renewal Term of the Agreement.

---

## SIGNATURES

**TECHNIJIAN, INC.**

By: ___________________________________

Name: Ravi Jain

Title: President

Date: _________________________________

**TALLEY & ASSOCIATES**

By: ___________________________________

Name: Robert L. Evens

Title: _________________________________

Date: _________________________________
