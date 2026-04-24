# STATEMENT OF WORK

**SOW Number:** SOW-VWC-001-AI-Lead-Gen
**Effective Date:** April 24, 2026
**Master Service Agreement:** None (standalone SOW — Technijian Standard Terms and Conditions apply)

This Statement of Work ("SOW") is entered into by and between:

**Technijian, Inc.** ("Technijian")
18 Technology Drive, Suite 141
Irvine, California 92618

and

**VisionWise Capital, LLC** ("Client" or "VWC")
27525 Puerta Real, Suite 300-164
Mission Viejo, California 92691

**Primary Contact:** Sanford Coggins, Founder (info@visionwisecapital.com)

---

## 1. PROJECT OVERVIEW

### 1.1 Project Title

AI / CTO Advisory — AI-Driven Lead Generation System Design and Build

### 1.2 Project Description

VisionWise Capital, LLC ("VWC") is a Southern California commercial real estate investment firm specializing in the acquisition, renovation, and management of multifamily properties on behalf of accredited investors, Registered Investment Advisors (RIAs), and high-net-worth individuals. VWC's growth is directly tied to its ability to identify and engage qualified accredited investors and RIA partners.

Technijian will provide AI / CTO Advisory services to design and build an AI-powered lead generation system that automates investor prospecting, enriches and scores leads, personalizes outreach, and routes qualified prospects into VWC's sales workflow. The engagement is billed on a **time-and-materials ("T&M") basis** at Technijian's published CTO Advisory rate. As a relationship-building courtesy, **the first two (2) hours of engagement are provided at no charge**; all hours thereafter are billed at the rate specified in Section 5.1.

The scope and pace of work will be directed by Client. Either Party may pause or conclude the engagement at any time with written notice, with payment due only for hours actually performed beyond the two (2) no-charge hours.

### 1.3 Locations

| Location Name | Code | Address | Billable |
|---------------|------|---------|----------|
| VWC - Headquarters | VWC-HQ | 27525 Puerta Real, Ste 300-164, Mission Viejo, CA 92691 | Yes |

All work shall be performed remotely unless both Parties agree in writing that on-site presence is required for a specific session. On-site meetings, if requested, shall be billed in accordance with Section 5.1.

---

## 2. SCOPE OF WORK

### 2.1 In Scope

Technijian will provide the following AI / CTO Advisory services on a T&M basis:

- **Discovery and Strategy** — Working sessions with VWC leadership to define target personas (accredited investors, RIAs, family offices), total addressable market, channel mix, success metrics, and compliance guardrails for investor outreach (SEC Rule 506(b)/506(c), CAN-SPAM, TCPA, state solicitation rules).
- **Architecture and Tool Selection** — Design of the AI lead generation stack, including large language model (LLM) selection, data sources, enrichment providers (e.g., Clay, Apollo, ZoomInfo, LinkedIn), CRM integration (HubSpot, Salesforce, Pipedrive, or equivalent), and orchestration tooling (n8n, Make, Zapier, or custom).
- **Data Pipeline and Enrichment** — Build or configure ingestion and enrichment pipelines that pull prospective investor and RIA data, normalize records, and attach firmographic / demographic / wealth-screening attributes.
- **AI Scoring and Qualification** — Implement an LLM-assisted lead scoring model that ranks prospects by fit and likelihood to engage, including reasoning summaries a human reviewer can audit.
- **Personalized Outreach** — Build AI-generated, persona-aware email and LinkedIn outreach sequences with human-in-the-loop approval. Includes sender warm-up guidance, deliverability checks (SPF/DKIM/DMARC), and suppression list management.
- **CRM and Workflow Integration** — Push qualified, scored leads into VWC's CRM with full provenance, scoring rationale, and next-best-action recommendations.
- **Dashboards and Reporting** — KPI dashboard (pipeline velocity, reply rate, meetings booked, SQL-to-investor conversion) for leadership visibility.
- **Knowledge Transfer** — Documentation, runbooks, and training sessions so VWC staff can operate and evolve the system independently after go-live.
- **Ongoing CTO Advisory (optional)** — On request, Technijian will continue to provide fractional CTO / AI advisory support on a T&M basis after initial build-out.

### 2.2 Out of Scope

The following items are expressly excluded from this SOW unless added by written Change Order:

- Investment decisions, solicitation of investors, or any activity requiring a securities license.
- Compliance opinions or legal counsel regarding SEC, FINRA, or state securities laws. Technijian will flag obvious compliance considerations, but Client is responsible for engaging qualified securities counsel.
- Content creation beyond templates and examples (e.g., full marketing campaigns, whitepapers, thought-leadership content).
- Purchase of third-party software licenses, enrichment data, LLM API usage, or CRM seats. These are procured by and billed directly to Client unless Client expressly authorizes Technijian to procure on its behalf.
- Sending outreach at scale without Client review and authorization for each campaign.
- Web development, branding, or graphic design services.
- Any work requiring access to Client's investor records, subscription documents, or other regulated non-public personal information ("NPI") except as strictly necessary for this engagement and governed by a separate data processing / NDA agreement.
- 24x7 system monitoring, production incident response, or managed services (available under a separate Technijian MSA / Managed Services SOW).

### 2.3 Assumptions

- The engagement begins with the two (2) no-charge hours, which will be used for an initial discovery session. No obligation on either Party is created until Client authorizes billable hours in writing (email is sufficient).
- Client will designate a single empowered point of contact (default: Sanford Coggins) with authority to approve scope, spend, vendor selection, and go-live of outreach campaigns.
- Client will procure and pay for all third-party services directly (LLM APIs, enrichment providers, CRM, email sending infrastructure). Technijian will recommend; Client will purchase.
- Any outreach generated by the system will be reviewed and approved by Client before being sent. Client is solely responsible for the legality and content of all outbound communications to prospects.
- Technijian's work product is delivered "as-is" and without warranty beyond what is stated in Section 9 and the Technijian Standard Terms and Conditions.
- Time will be tracked and reported in 15-minute increments.

---

## 3. PROJECT PHASES

The engagement is organized into five (5) phases. Because this is a T&M engagement directed by Client, hour estimates below are **planning estimates only**; Technijian will bill for actual time at the rate in Section 5.1 and will notify Client before exceeding any estimate by more than 10%.

### Phase 1: Discovery & Strategy (No-Charge + T&M)

**3.1.1 Description**

Initial working sessions with Client leadership to understand VWC's investor profile, current sales motion, growth targets, compliance posture, existing tools, and budget constraints. The first two (2) hours of this phase are provided at no charge. If Client elects to continue, subsequent hours are billed at the rate in Section 5.1.

**3.1.2 Deliverables**

- Discovery notes and a one-page AI Lead Gen strategy brief.
- Target persona definitions (accredited investor, RIA partner, family office).
- Recommended channel mix and success metrics.
- Preliminary tool short-list and rough cost-of-ownership estimate.

**3.1.3 Schedule**

| Role | Description | Est. Hours | Timeline | Resource |
|------|-------------|------------|----------|----------|
| CTO Advisory | Initial discovery session (no-charge) | 2.0 | Week 1 | Ravi Jain |
| CTO Advisory | Strategy brief and persona definitions | 2.0 | Week 1-2 | Ravi Jain |
| | **Total** | **4.0** | | |

### Phase 2: Architecture & Tool Selection (T&M)

**3.2.1 Description**

Design the end-to-end AI lead generation architecture and recommend a specific vendor stack. Client retains final approval authority on all third-party purchases.

**3.2.2 Deliverables**

- Architecture diagram (data sources → enrichment → scoring → outreach → CRM → reporting).
- Vendor recommendation memo with cost, pros/cons, and compliance notes.
- Prioritized build backlog.

**3.2.3 Schedule**

| Role | Description | Est. Hours | Timeline | Resource |
|------|-------------|------------|----------|----------|
| CTO Advisory | Architecture design and vendor short-list | 4.0 | Week 2-3 | Ravi Jain |
| CTO Advisory | Client review and backlog prioritization | 2.0 | Week 3 | Ravi Jain |
| | **Total** | **6.0** | | |

### Phase 3: Build & Integration (T&M)

**3.3.1 Description**

Stand up the data ingestion, enrichment, AI scoring, and outreach components and wire them into Client's CRM. Work is delivered iteratively with weekly demos.

**3.3.2 Deliverables**

- Data ingestion and enrichment pipeline configured against selected sources.
- LLM-based lead scoring model with audit-ready rationale output.
- AI-generated outreach sequences with human-in-the-loop review UI.
- CRM integration (bi-directional) with scored lead records.
- KPI dashboard.

**3.3.3 Schedule**

| Role | Description | Est. Hours | Timeline | Resource |
|------|-------------|------------|----------|----------|
| CTO Advisory | Pipeline, enrichment, and scoring build | 10.0 | Week 3-5 | Ravi Jain |
| CTO Advisory | Outreach automation and CRM integration | 8.0 | Week 5-7 | Ravi Jain |
| CTO Advisory | KPI dashboard build | 3.0 | Week 7 | Ravi Jain |
| | **Total** | **21.0** | | |

### Phase 4: Pilot, Tuning & Go-Live (T&M)

**3.4.1 Description**

Run a controlled pilot against a small approved prospect list, tune scoring thresholds and outreach copy based on results, then authorize broader rollout.

**3.4.2 Deliverables**

- Pilot results report (reply rate, meetings booked, false-positive rate).
- Tuned scoring thresholds and outreach templates.
- Go-live checklist and rollout plan.

**3.4.3 Schedule**

| Role | Description | Est. Hours | Timeline | Resource |
|------|-------------|------------|----------|----------|
| CTO Advisory | Pilot run and analysis | 4.0 | Week 8 | Ravi Jain |
| CTO Advisory | Tuning and go-live enablement | 3.0 | Week 9 | Ravi Jain |
| | **Total** | **7.0** | | |

### Phase 5: Knowledge Transfer (T&M)

**3.5.1 Description**

Document the system and train Client's designated operators so VWC can run and evolve the system without Technijian.

**3.5.2 Deliverables**

- Operator runbook.
- Architecture reference document.
- Recorded training session(s).

**3.5.3 Schedule**

| Role | Description | Est. Hours | Timeline | Resource |
|------|-------------|------------|----------|----------|
| CTO Advisory | Documentation and runbooks | 2.0 | Week 9-10 | Ravi Jain |
| CTO Advisory | Training session(s) | 2.0 | Week 10 | Ravi Jain |
| | **Total** | **4.0** | | |

### Ongoing Advisory (Optional — T&M)

After Phase 5, Client may request continued fractional CTO / AI advisory support on an as-needed basis. There is no minimum commitment and no retainer; hours are billed only when performed, at the rate in Section 5.1.

**Typical activities:** periodic strategy reviews, new model evaluations, vendor renegotiations, outreach copy refresh, dashboard updates, and coaching Client staff on AI best practices.

---

## 4. EQUIPMENT AND MATERIALS

No hardware or equipment is supplied under this SOW. Third-party software, data, and API subscriptions required to operate the lead generation system (LLM APIs, enrichment providers, CRM, sending infrastructure) are procured by and paid directly by Client.

---

## 5. PRICING AND PAYMENT

### 5.1 Rate Card

| Role | Location | Rate |
|------|----------|------|
| CTO / AI Advisory (Ravi Jain) | US (Remote) | **$250.00 / hr** |
| After-Hours Premium (weekends, holidays, or after 6:00 PM Pacific) | US (Remote) | $350.00 / hr |

Rates are fixed for the term of this engagement. Any rate changes require a written Change Order signed by both Parties.

### 5.2 Introductory No-Charge Hours

The **first two (2.0) billable-eligible hours** of engagement are provided at **no charge** as a relationship-building courtesy. These hours will typically be consumed during the Phase 1 discovery session. No-charge hours are not refundable, not transferable, and not cumulative; if the engagement concludes within the first two hours, no invoice will be issued.

### 5.3 Summary of Costs (Planning Estimate Only)

| Phase | Type | Est. Hours | Rate | Cost |
|-------|------|------------|------|------|
| Phase 1 — Discovery (no-charge portion) | Credit | 2.0 | $0.00 | $0.00 |
| Phase 1 — Discovery (billable portion) | Estimate | 2.0 | $250.00 | $500.00 |
| Phase 2 — Architecture & Tool Selection | Estimate | 6.0 | $250.00 | $1,500.00 |
| Phase 3 — Build & Integration | Estimate | 21.0 | $250.00 | $5,250.00 |
| Phase 4 — Pilot, Tuning & Go-Live | Estimate | 7.0 | $250.00 | $1,750.00 |
| Phase 5 — Knowledge Transfer | Estimate | 4.0 | $250.00 | $1,000.00 |
| **Estimated Total Project (billable only)** | | **40.0** | | **$10,000.00** |

**Pricing Type Definitions**

- **Estimate Cost.** Hours and costs in the table above are good-faith planning estimates. Technijian will bill for actual time performed, at the rate in Section 5.1. If cumulative actual hours are projected to exceed the total estimate by more than **10%**, Technijian will notify Client in writing before performing the additional hours.
- **Credit.** The two no-charge hours are reflected as a $0.00 credit and will not appear as a line item on any invoice.

### 5.4 Invoicing and Payment Schedule

- Technijian will invoice Client **bi-weekly** (every two weeks) for actual hours performed during the preceding period, itemized by date, duration, phase, and description of work.
- The first invoice will not be issued until cumulative billable hours exceed the two (2) no-charge hours.
- All invoices are due and payable within **thirty (30) days** of the invoice date.

### 5.5 Payment Terms

All invoices are due and payable within **thirty (30) days** of the invoice date.

### 5.6 Late Payment and Collection Remedies

Because no MSA is in effect between the Parties, the following standalone provisions apply:

**(a) Late Payment.** Late payments shall accrue a late fee of **1.5% per month** (or the maximum rate permitted by law, whichever is less) on the unpaid balance, calculated as simple interest from the date payment was due. The Parties acknowledge that the late fee represents a reasonable estimate of Technijian's administrative costs and damages resulting from late payment and is not a penalty.

**(b) Acceleration.** If Client fails to pay any undisputed invoice within **forty-five (45) days** of the due date, all remaining fees under this SOW shall become immediately due and payable.

**(c) Suspension.** Technijian may suspend all work under this SOW upon **ten (10) days** written notice if any invoice remains unpaid beyond the due date. Suspension shall not relieve Client of its payment obligations, and project timelines shall be adjusted accordingly at no cost to Technijian.

**(d) Collection Costs and Attorney's Fees.** In any action or proceeding to collect fees, invoices, or other amounts owed under this SOW, the **prevailing Party** shall be entitled to recover all reasonable costs of collection, including attorney's fees (including in-house counsel at market rates), collection agency fees, court costs, arbitration fees, and all costs of appeal. Pursuant to California Civil Code Section 1717, the Parties acknowledge that this attorney's fees provision is reciprocal. This fee-shifting applies exclusively to collection of amounts owed and does not apply to disputes regarding service quality, professional performance, or other non-payment claims.

**(e) Lien on Work Product.** Technijian shall retain a lien on all deliverables, work product, documentation, and materials (excluding Client Data) under this SOW until all amounts owed are paid in full.

**(f) Fees for Non-Collection Disputes.** Except as provided in subsection (d) above, in any dispute arising under this SOW relating to service quality, professional performance, scope, or any other non-payment matter, each Party shall bear its own attorney's fees and costs.

---

## 6. CLIENT RESPONSIBILITIES

Client shall:

(a) Provide access to systems, tools, and personnel reasonably required for Technijian to perform the work (e.g., CRM admin access, LLM vendor accounts, sample prospect data);

(b) Designate a single empowered point of contact (default: Sanford Coggins) authorized to approve scope, spend, vendor selection, and outreach campaigns;

(c) Review and approve deliverables, vendor recommendations, and outreach campaigns within **five (5) business days** of submission;

(d) Procure and pay for all third-party services directly (LLM APIs, enrichment data, CRM, sending infrastructure);

(e) Ensure that all outreach content is compliant with applicable law (SEC Rule 506(b)/506(c), CAN-SPAM, TCPA, state solicitation rules) prior to send. Client acknowledges that Technijian is not a law firm and is not providing legal or compliance advice;

(f) Not use the lead generation system, or any output thereof, for any activity requiring a securities license unless Client (or a licensed affiliate) holds the requisite license; and

(g) Inform internal stakeholders of any system changes that affect their workflow.

---

## 7. CHANGE MANAGEMENT

**7.01.** Because this is a T&M engagement, Client may expand, narrow, or redirect scope at any time by written instruction (email is sufficient). Changes that materially alter the rate, total estimate, or assumptions in this SOW require a written Change Order signed by both Parties before the changed work begins.

**7.02.** If Client requests work that in Technijian's reasonable judgment exceeds the skill mix or rate card of this SOW (e.g., custom software engineering beyond integration work), Technijian shall provide a Change Order detailing the additional role(s), rate(s), and estimated impact.

**7.03.** Technijian shall not perform work that would exceed the estimate in Section 5.3 by more than 10% without notifying Client in advance, except in cases where delay would cause imminent harm to Client's systems, in which case Technijian may perform emergency work not to exceed **$2,500** (at the Section 5.1 rate) and shall notify Client as soon as practicable, with a retrospective Change Order within **three (3) business days**.

---

## 8. ACCEPTANCE

**8.01.** Upon completion of each deliverable listed in Section 3, Technijian shall notify Client in writing that the deliverable is ready for review.

**8.02.** Client shall review the deliverable and provide written acceptance or a detailed description of deficiencies within **five (5) business days** of submission. Technijian's delivery notification shall include a conspicuous statement: "If you do not respond within five (5) business days, this deliverable will be deemed accepted per SOW Section 8.03."

**8.03.** If Client does not respond within the review period, the deliverable shall be deemed accepted.

**8.04.** If deficiencies are identified, Technijian shall correct them and resubmit for review. This process shall repeat until acceptance is achieved or the Parties agree on a resolution.

---

## 9. GOVERNING TERMS

**9.01.** No Master Service Agreement is currently in effect between the Parties. This SOW is a standalone engagement governed by the Technijian Standard Terms and Conditions (Appendix A, if attached) and the following minimum terms:

(a) Neither Party's total aggregate liability under this SOW shall exceed the total fees paid or payable under this SOW in the **six (6) months** preceding the claim.

(b) In no event shall either Party be liable for indirect, incidental, special, consequential, or punitive damages, including but not limited to lost profits, lost investors, or lost business opportunity.

(c) This SOW shall be governed by the laws of the State of California, without regard to conflict-of-laws principles. Any dispute shall be resolved by binding arbitration in Orange County, California, under the AAA Commercial Arbitration Rules, except that either Party may seek injunctive relief in court for protection of intellectual property or confidential information.

(d) Each Party shall keep the other's confidential information (including pricing, business plans, and investor data) strictly confidential during the engagement and for **three (3) years** thereafter.

(e) Client retains ownership of all Client Data. Technijian retains ownership of its pre-existing tools, methodologies, and templates. Client receives a perpetual, non-exclusive license to use the deliverables and configurations produced under this SOW for its internal business purposes.

**9.02.** If the Parties subsequently execute a Master Service Agreement, the terms of the MSA shall govern and supersede this Section 9 to the extent of any conflict.

---

## SIGNATURES

**TECHNIJIAN, INC.**

By: ___________________________________

Name: Ravi Jain

Title: Chief Executive Officer

Date: _________________________________

**VISIONWISE CAPITAL, LLC**

By: ___________________________________

Name: Sanford Coggins

Title: Founder

Date: _________________________________
