# STATEMENT OF WORK

**SOW Number:** SOW-ART-001-NetworkAssessment
**Effective Date:** May 1, 2026
**Master Service Agreement:** None (standalone SOW — Technijian Standard Terms & Conditions apply)

This Statement of Work ("SOW") is entered into by and between:

**Technijian, Inc.** ("Technijian")
18 Technology Drive, Suite 141
Irvine, California 92618

and

**Aranda Tooling, LLC** ("Client")
13950 Yorba Avenue
Chino, California 91710

---

## 1. PROJECT OVERVIEW

### 1.1 Project Title

Aranda Tooling Network Assessment — Meraki MX/MS and Non-Meraki Switching Review with Executive Readout

### 1.2 Project Description

Aranda Tooling, LLC ("Aranda") operates an ISO 9001:2015 certified metal stamping, fabrication, tool-and-die, laser cutting, and robotic welding facility in Chino, California. Its network supports production OT systems, office users, printers, guest Wi-Fi, IoT endpoints, and administrative workloads across a mixed-vendor switching estate fronted by a Meraki MX firewall, Meraki MS switches, and downstream non-Meraki (Aranda-branded Cisco SMB and Netgear Smart/Plus) access switches.

A preliminary technical review performed from supplied switch configuration exports and the topology diagram identified multiple material observations, including: (a) private cryptographic material and privileged local management information embedded in exported switch backups, (b) inconsistent management addressing and default gateways across the non-Meraki switch estate, (c) the Meraki MS layer not being present in the supplied exports — which likely includes part of the aggregation/core switching function, (d) a mixed small-business/Plus-class vendor stack increasing support complexity, and (e) VLAN segmentation that is directionally good but not yet validated end-to-end.

This SOW covers a focused, configuration-driven network assessment that validates segmentation, management-plane security, configuration hygiene, and operational resilience across the Meraki MX/MS layer and the downstream access switches, and delivers an executive readout with a prioritized remediation roadmap. This engagement is positioned as an assessment and readout — **not** a remediation, implementation, or change-execution engagement. Remediation labor, after-hours change execution, wireless surveys, and cable certification, if subsequently requested by Client, will be scoped and priced under a separate SOW or Change Order.

### 1.3 Locations

| Location Name | Code | Address | Billable |
|---------------|------|---------|----------|
| Aranda Tooling — Primary | ART-HQ | 13950 Yorba Avenue, Chino, CA 91710 | Yes |

---

## 2. SCOPE OF WORK

### 2.1 In Scope

- Read-only review of the Meraki MX firewall configuration: addressing and VLANs, appliance ports, static routes, L3/L7 firewall rules, NAT, DHCP, WAN uplinks, site-to-site VPN, and SD-WAN / content-filtering policies relevant to segmentation
- Read-only review of the Meraki MS switch estate: switch settings, per-port configuration, link aggregations, access policies, ACLs, DHCP server policy / ARP inspection, and any Layer 3 interfaces if enabled
- Read-only review of Meraki MR wireless (if in use): SSID-to-VLAN mapping, local-LAN access policy, and SSID firewall rules
- Review of the supplied non-Meraki switch exports (Aranda-branded Cisco SMB and Netgear Smart/Plus devices) for VLAN design, trunking, local admin posture, management IP exposure, STP behavior, and configuration hygiene
- Segmentation validation across office, guest, services, IoT, printer, and OT networks
- Security and hardening baseline assessment: credentials, keys, certificates, access control, logging, and monitoring gaps
- Production of a normalized device inventory and validated topology notes
- Drafting a risk-ranked technical findings register with business impact and recommended actions
- Drafting a 30/60/90-day remediation roadmap and configuration standardization recommendations
- Preparation and delivery of an executive readout presentation (up to 90 minutes, remote)

### 2.2 Out of Scope

The following items are expressly excluded from this SOW and, if requested, will be handled under a separate SOW or Change Order:

- Remediation labor, configuration changes, credential rotation, key/certificate regeneration, or any change-execution activity on Client infrastructure
- After-hours change windows and on-call support
- Full wireless site survey, heatmaps, or RF spectrum analysis
- Physical cable certification, cable testing, or structured cabling work
- Endpoint security assessment, server/workstation review, Active Directory audit, email security, or backup/DR architecture review
- OT process-control system audit, PLC-level review, or safety-systems engineering
- Penetration testing, red-team engagements, vulnerability scanning of hosts, or external attack-surface testing
- ISP circuit engineering, carrier coordination, or contract review
- Compliance certification issuance (HIPAA, SOC 2, PCI-DSS, ISO 27001, CMMC, etc.) — this assessment is configuration-oriented and does not constitute a regulatory attestation
- Hardware procurement, appliance replacement, or refresh implementation

### 2.3 Assumptions

- Client will designate a single point of contact authorized to validate inventory, approve access, and confirm business-critical traffic paths
- Client will provide **read-only Meraki Dashboard access** or a **time-limited, read-only Meraki API key** generated by a named Aranda administrator. Shared dashboard passwords transmitted by email are not an acceptable access model
- Client will provide access to any current topology diagrams, ISP handoff details, static public IP information, and existing circuit documentation available
- The previously supplied non-Meraki switch backups (four Aranda-branded Cisco SMB configs and six Netgear Smart/Plus exports) will be treated as in scope for review
- Inter-VLAN routing is believed to reside on the Meraki MX firewall and the switch estate is primarily Layer 2; this assumption will be validated during Phase 2
- The engagement is performed remotely; no on-site presence is required. If on-site work is later requested, it will be added via Change Order at the On-Site Support rate ($150/hr, 2-hour minimum)
- Findings and recommendations are based on configuration evidence provided and collected during the engagement and do not include live traffic capture, active client impact testing, or spanning-tree state validation

---

## 3. PROJECT PHASES

### Phase 1: Discovery & Access Validation

**3.1.1 Description**

Kick off the engagement, confirm scope and inventory, validate Meraki Dashboard or API access, and close any data-collection gaps from the preliminary review. Produce a discovery memo and evidence-gap log that governs Phase 2 analysis.

**3.1.2 Deliverables**

- Kickoff meeting notes and confirmed scope statement
- Validated device inventory (Meraki MX / MS / MR plus non-Meraki switches)
- Confirmed Meraki access method (read-only Dashboard or time-limited API key)
- Discovery memo and evidence-gap log identifying any remaining data-collection items

**3.1.3 Schedule**

| Role | Description | Est. Hours | Timeline | Resource |
|------|-------------|------------|----------|----------|
| Sr. Network Engineer | Kickoff, scope confirmation, and access provisioning coordination | 2 | Week 1 | IRV-TS1 |
| Sr. Network Engineer | Meraki Dashboard/API access validation and baseline data pull | 3 | Week 1 | IRV-TS1 |
| Sr. Network Engineer | Inventory validation against supplied topology and configs | 3 | Week 1 | IRV-TS1 |
| Sr. Network Engineer | Discovery memo and evidence-gap log | 2 | Week 1 | IRV-TS1 |
| | **Phase 1 Total** | **10** | | |

---

### Phase 2: Configuration Analysis

**3.2.1 Description**

Perform the core configuration-driven analysis across the Meraki MX, Meraki MS, non-Meraki switches, wireless SSID-to-VLAN alignment, and end-to-end segmentation. Identify security, hardening, and operational-resilience gaps. This is the evidence-collection phase that feeds the findings register.

**3.2.2 Deliverables**

- Meraki MX firewall review notes (routing, VLAN gateway design, L3/L7 rules, NAT, DHCP, WAN/uplink, VPN/static-route posture)
- Meraki MS switch review notes (switch settings, port configs, LAGs, access policies, ACLs, DHCP/DAI, L3 interfaces if any)
- Non-Meraki switch review notes (VLAN design, trunking, local admin posture, management IP exposure, STP behavior, config hygiene)
- Wireless and SSID-to-VLAN alignment notes (if MR is in use)
- Segmentation validation notes for office, guest, services, IoT, printer, and OT networks
- Security and hardening baseline notes (credentials, keys, certificates, access control, logging, monitoring)

**3.2.3 Schedule**

| Role | Description | Est. Hours | Timeline | Resource |
|------|-------------|------------|----------|----------|
| Sr. Network Engineer | Meraki MX firewall configuration review | 5 | Week 2 | IRV-TS1 |
| Sr. Network Engineer | Meraki MS switch configuration review | 5 | Week 2 | IRV-TS1 |
| Sr. Network Engineer | Non-Meraki switch configuration analysis | 3 | Week 2 | IRV-TS1 |
| Sr. Network Engineer | Wireless and SSID alignment review | 2 | Week 2 | IRV-TS1 |
| Sr. Network Engineer | End-to-end segmentation validation | 3 | Week 2 | IRV-TS1 |
| Sr. Network Engineer | Security and hardening baseline review | 2 | Week 2 | IRV-TS1 |
| | **Phase 2 Total** | **20** | | |

---

### Phase 3: Findings & Remediation Roadmap

**3.3.1 Description**

Consolidate Phase 2 evidence into a risk-ranked technical findings register, produce a normalized device inventory and validated topology, and draft a 30/60/90-day remediation roadmap and configuration-standardization recommendations suitable for leadership review.

**3.3.2 Deliverables**

- Technical findings register with severity (Critical / High / Moderate / Low), business impact, affected devices, and recommended actions
- Normalized device inventory and validated topology document
- 30/60/90-day remediation roadmap (immediate stabilization, 30-day normalization, 90-day strategic actions)
- Meraki MX/MS/MR data-collection checklist and gap log (finalized)
- Draft executive summary suitable for non-technical leadership review

**3.3.3 Schedule**

| Role | Description | Est. Hours | Timeline | Resource |
|------|-------------|------------|----------|----------|
| Sr. Network Engineer | Risk-ranked findings register drafting | 4 | Week 3 | IRV-TS1 |
| Sr. Network Engineer | 30/60/90-day remediation roadmap | 4 | Week 3 | IRV-TS1 |
| Sr. Network Engineer | Normalized device inventory and topology documentation | 2 | Week 3 | IRV-TS1 |
| Sr. Network Engineer | Executive summary drafting | 2 | Week 3 | IRV-TS1 |
| | **Phase 3 Total** | **12** | | |

---

### Phase 4: Executive Readout

**3.4.1 Description**

Finalize deliverables, deliver the executive readout to Client leadership, and capture prioritization and next-step decisions. This phase closes the assessment engagement.

**3.4.2 Deliverables**

- Final executive summary (PDF)
- Final technical findings register (PDF/XLSX)
- Final remediation roadmap (PDF)
- Final device inventory and topology (PDF)
- Executive readout session (remote, up to 90 minutes) with Q&A
- Post-readout next-step memo summarizing Client priorities and any requested follow-on work for Change Order scoping

**3.4.3 Schedule**

| Role | Description | Est. Hours | Timeline | Resource |
|------|-------------|------------|----------|----------|
| Sr. Network Engineer | Final deliverable QA, formatting, and packaging | 2 | Week 4 | IRV-TS1 |
| Sr. Network Engineer | Executive readout presentation (remote) | 2 | Week 4 | IRV-TS1 |
| Sr. Network Engineer | Post-readout priorities capture and next-step memo | 2 | Week 4 | IRV-TS1 |
| | **Phase 4 Total** | **6** | | |

---

## 4. EQUIPMENT AND MATERIALS

Not applicable. This SOW is a professional-services assessment engagement. No hardware, appliances, or software licenses are being supplied by Technijian under this SOW.

---

## 5. PRICING AND PAYMENT

### 5.1 Rate Card

| Role | Location | Rate |
|------|----------|------|
| Sr. Network Engineer (Project Rate) | US | $150.00 / hr |

### 5.2 Summary of Costs

| Phase | Type | Est. Hours | Cost |
|-------|------|------------|------|
| Phase 1 — Discovery & Access Validation | Fixed | 10 | $1,500.00 |
| Phase 2 — Configuration Analysis | Fixed | 20 | $3,000.00 |
| Phase 3 — Findings & Remediation Roadmap | Fixed | 12 | $1,800.00 |
| Phase 4 — Executive Readout | Fixed | 6 | $900.00 |
| **Total (Fixed Fee)** | | **48** | **$7,200.00** |

**Pricing Type Definitions:**

- **Fixed Cost:** Technijian will complete the work described in this SOW at the stated price of $7,200.00 regardless of actual hours expended, provided the scope and assumptions in Section 2 are not materially changed by Client. The hours shown above are internal estimates for resource planning and are not separately billable.
- **Estimate Cost:** Not applicable to this SOW — pricing is fixed.

### 5.3 Payment Schedule

| Milestone | Invoiced | Amount |
|-----------|----------|--------|
| SOW Execution | Upon signing | $3,600.00 |
| Executive Readout Delivery | Upon completion of Phase 4 | $3,600.00 |
| **Total** | | **$7,200.00** |

### 5.4 Payment Terms

All invoices are due and payable within **thirty (30) days** of the invoice date.

### 5.5 Late Payment and Collection Remedies

**(a)** Because no MSA is in effect between the Parties, the following standalone provisions apply:

(i) **Late Payment.** Late payments shall accrue a late fee of **1.5% per month** (or the maximum rate permitted by law, whichever is less) on the unpaid balance, calculated as simple interest from the date payment was due. The Parties acknowledge that the late fee represents a reasonable estimate of Technijian's administrative costs and damages resulting from late payment and is not a penalty.

(ii) **Acceleration.** If Client fails to pay any undisputed invoice within **forty-five (45) days** of the due date, all remaining fees under this SOW shall become immediately due and payable.

(iii) **Suspension.** Technijian may suspend all work under this SOW upon **ten (10) days** written notice if any invoice remains unpaid beyond the due date. Suspension shall not relieve Client of its payment obligations, and project timelines shall be adjusted accordingly at no cost to Technijian.

(iv) **Collection Costs and Attorney's Fees.** In any action or proceeding to collect fees, invoices, or other amounts owed under this SOW, the **prevailing Party** shall be entitled to recover all reasonable costs of collection, including attorney's fees (including in-house counsel at market rates), collection agency fees, court costs, arbitration fees, and all costs of appeal. Pursuant to California Civil Code Section 1717, the Parties acknowledge that this attorney's fees provision is reciprocal. This fee-shifting applies exclusively to collection of amounts owed and does not apply to disputes regarding service quality, professional performance, or other non-payment claims.

(v) **Lien on Work Product.** Technijian shall retain a lien on all deliverables, work product, documentation, and materials (excluding Client Data) under this SOW until all amounts owed are paid in full.

(vi) **Fees for Non-Collection Disputes.** Except as provided in subsection (iv) above, in any dispute arising under this SOW relating to service quality, professional performance, scope, or any other non-payment matter, each Party shall bear its own attorney's fees and costs.

---

## 6. CLIENT RESPONSIBILITIES

Client shall:

(a) Provide access to systems, cloud consoles (Meraki Dashboard), and personnel as reasonably required to complete the assessment;

(b) Designate a point of contact authorized to validate inventory, approve access, make decisions on behalf of Client, and schedule the executive readout;

(c) Review and approve deliverables (discovery memo, findings register, roadmap, executive summary) within **five (5) business days** of submission;

(d) Ensure all relevant configuration backups and network documentation provided to Technijian are authorized for external sharing, and treat any configuration material returned by Technijian as sensitive;

(e) Rotate or revoke any temporary Meraki API key issued for this engagement promptly upon conclusion of Phase 4;

(f) Acknowledge that the preliminary review identified embedded private keys and privileged management information in historical switch backups; Client is responsible for any credential rotation, key/certificate regeneration, or incident-response activity, which is out of scope of this SOW; and

(g) Inform internal stakeholders of the assessment scope so that configuration review activity is not mistaken for change-execution or troubleshooting activity.

---

## 7. CHANGE MANAGEMENT

**7.01.** Any changes to the scope, schedule, or pricing of this SOW must be documented in a written Change Order signed by both Parties before work on the change begins.

**7.02.** If Client requests work outside the defined scope — including, without limitation, remediation labor, configuration changes, after-hours work, on-site visits, wireless surveys, cable certification, or deeper compliance review — Technijian shall provide a Change Order detailing the additional work, estimated hours, and cost impact.

**7.03.** Technijian shall not proceed with out-of-scope work without an approved Change Order, except in cases where delay would result in imminent risk of data loss, security breach, or system outage to Client's systems, in which case Technijian may perform emergency out-of-scope work not to exceed **$2,500** (at applicable Rate Card rates) without prior approval. Technijian shall notify Client as soon as practicable and shall issue a retrospective Change Order within **three (3) business days** of the emergency work for Client's review and ratification.

---

## 8. ACCEPTANCE

**8.01.** Upon completion of each phase, Technijian shall notify Client in writing that the deliverables are ready for review.

**8.02.** Client shall review the deliverables and provide written acceptance or a detailed description of deficiencies within **five (5) business days**. Technijian's delivery notification shall include a conspicuous statement: "If you do not respond within five (5) business days, deliverables will be deemed accepted per SOW Section 8.03."

**8.03.** If Client does not respond within the review period, the deliverables shall be deemed accepted.

**8.04.** If deficiencies are identified, Technijian shall correct them and resubmit for review. This process shall repeat until acceptance is achieved or the Parties agree on a resolution.

---

## 9. GOVERNING TERMS

**9.01.** No Master Service Agreement is currently in effect between the Parties. The Technijian Standard Terms and Conditions (attached as Appendix A, if provided) shall govern this SOW. If Appendix A is not attached, the following shall apply as a minimum: (a) neither Party's total aggregate liability under this SOW shall exceed the total fees paid or payable under this SOW; (b) in no event shall either Party be liable for indirect, incidental, special, consequential, or punitive damages; and (c) this SOW shall be governed by the laws of the State of California, and disputes shall be resolved by binding arbitration in Orange County, California, under the AAA Commercial Arbitration Rules.

**9.02.** If the Parties subsequently execute a Master Service Agreement, the MSA shall govern this SOW on a go-forward basis and, in the event of a conflict, the MSA shall prevail unless this SOW expressly states otherwise.

**9.03.** Deliverables produced under this SOW constitute Technijian work product. Upon full payment of all amounts due, Technijian grants Client a perpetual, non-exclusive license to use the deliverables for Client's internal business purposes. Technijian retains ownership of its pre-existing methodologies, templates, and tools.

---

## SIGNATURES

**TECHNIJIAN, INC.**

By: ___________________________________

Name: Ravi Jain

Title: Chief Executive Officer

Date: _________________________________

**ARANDA TOOLING, LLC**

By: ___________________________________

Name: _________________________________

Title: _________________________________

Date: _________________________________
