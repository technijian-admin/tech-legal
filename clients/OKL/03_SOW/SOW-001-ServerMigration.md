# STATEMENT OF WORK

**SOW Number:** SOW-OKL-001
**Effective Date:** March 23, 2026
**Master Service Agreement:** MSA-OKL-2026

This Statement of Work ("SOW") is entered into by and between:

**Technijian, Inc.** ("Technijian")
18 Technology Drive, Suite 141
Irvine, California 92618

and

**Oaktree Law** ("Client")
[CLIENT ADDRESS]
[CITY, STATE ZIP]

**Primary Contact:** Ed Pits

---

## 1. PROJECT OVERVIEW

### 1.1 Project Title

Physical Server Migration to Technijian Cloud with Cloudbrink ZTNA and OneDrive Migration

### 1.2 Project Description

Oaktree Law currently operates a physical on-premises server that requires migration to a cloud-hosted environment. This SOW covers the full migration of the existing physical server to Technijian's private cloud datacenter, deployment of a Cloudbrink Zero Trust Network Access (ZTNA) virtual appliance to provide secure remote access for end users, migration of approximately 779 GB of shared folders to Microsoft OneDrive/SharePoint Online, and deployment of security and management agents on the hosted virtual machines.

Upon completion of the migration project, Technijian will provide ongoing managed hosting, security, and support services under the terms of the Master Service Agreement (MSA-OKL-2026).

### 1.3 Current Environment

| Component | Specification |
|-----------|--------------|
| Processor | Intel Xeon E3-1220 v5 @ 3.00 GHz (2 processors) |
| Memory | 14.0 GB RAM |
| Local Drive (C:) | 119 GB total / 3.33 GB free |
| Shared Storage (D:) | 779 GB total / 60.7 GB free |
| Internet | 500 / 500 Mbps symmetric |

### 1.4 Locations

| Location Name | Code | Address | Billable |
|---------------|------|---------|----------|
| Oaktree Law — Main Office | OKL-HQ | [ADDRESS] | Yes |

---

## 2. SCOPE OF WORK

### 2.1 In Scope

- Full discovery and assessment of the existing physical server environment
- Provisioning of two (2) virtual machines in the Technijian datacenter
- Physical-to-Virtual (P2V) migration of the existing server to VM1
- Deployment and configuration of Cloudbrink ZTNA virtual appliance on VM2
- Migration of shared folders (~779 GB) to Microsoft OneDrive / SharePoint Online
- Installation and configuration of security agents: CrowdStrike, Huntress, Patch Management, My Remote
- Deployment of Veeam backup for both virtual machines
- End-to-end testing, validation, and go-live cutover
- 30-day post-migration support period

### 2.2 Out of Scope

The following items are expressly excluded from this SOW:

- Desktop/workstation support, upgrades, or reimaging
- Email migration or Microsoft 365 tenant configuration
- Line-of-business application reconfiguration beyond basic validation
- Procurement of Microsoft 365 / OneDrive licenses (Client responsibility)
- Physical decommissioning or disposal of the old server hardware
- Cloudbrink per-user subscription licensing (billed separately by Cloudbrink)
- Network equipment upgrades at Client's office

### 2.3 Assumptions

- Client will provide administrative credentials and physical/remote access to the existing server
- Client will ensure all critical data is backed up prior to migration start
- Client's existing 500/500 Mbps internet connection is sufficient for Cloudbrink ZTNA performance
- Client has or will procure Microsoft 365 licenses with OneDrive/SharePoint Online storage
- Migration work will be performed during off-hours / weekends to minimize business disruption
- Cloudbrink virtual appliance requires a Linux-based VM (no Windows license required for VM2)

---

## 3. PROJECT PHASES

### Phase 1: Discovery & Assessment

**3.1.1 Description**

Comprehensive audit of the existing physical server, including installed roles, services, applications, shared folder structure, permissions, user access patterns, and network configuration. Produce a migration strategy document.

**3.1.2 Deliverables**

- Server inventory and application audit report
- Shared folder structure and permissions map
- Migration strategy and timeline document

**3.1.3 Schedule**

| Role | Description | Rate | Est. Hours | Timeline |
|------|-------------|------|------------|----------|
| CTO Advisory | Migration strategy, architecture planning, risk assessment | $250/hr | 2 | Week 1 |
| Tech Support | Server audit, inventory, and documentation | $150/hr | 2 | Week 1 |
| | **Phase 1 Total** | | **4** | |

---

### Phase 2: Cloud Environment Provisioning

**3.2.1 Description**

Provision and configure the target environment in the Technijian datacenter: two virtual machines, storage, networking, and firewall rules.

**3.2.2 Deliverables**

- VM1 provisioned (4 vCores, 16 GB RAM, 1 TB storage) with Windows Server
- VM2 provisioned (2 vCores, 4 GB RAM) for Cloudbrink appliance
- Network configuration, VLANs, and firewall rules
- Backup configuration (Veeam VBR)

**3.2.3 Schedule**

| Role | Description | Rate | Est. Hours | Timeline |
|------|-------------|------|------------|----------|
| Tech Support | VM provisioning and OS install | $150/hr | 4 | Week 1-2 |
| Tech Support | Network and storage configuration | $150/hr | 2 | Week 1-2 |
| Tech Support | Backup setup (Veeam) | $150/hr | 2 | Week 2 |
| | **Phase 2 Total** | | **8** | |

---

### Phase 3: Physical-to-Virtual Server Migration

**3.3.1 Description**

Migrate the existing physical server OS and applications to VM1 in the Technijian cloud using P2V conversion tools. Only the OS/local volume (~119 GB) is included in the P2V conversion; the shared folder data (~779 GB on D: drive) is migrated separately to OneDrive/SharePoint in Phase 4. The P2V process includes pre-migration verification, disk conversion, driver remediation, service validation, and network cutover.

**3.3.2 Deliverables**

- Pre-migration backup verification and snapshot
- Completed P2V conversion of server OS volume (~119 GB) to VM1
- HAL/driver cleanup and VMware/Hyper-V tools installation
- Windows Server activation and licensing validated on VM
- All server roles and services validated (AD, DNS, DHCP, file shares, print services, etc.)
- Line-of-business applications verified functional
- DNS and IP reconfiguration for new cloud environment
- Performance baseline comparison (pre vs. post migration)

**3.3.3 Schedule**

| Role | Description | Rate | Est. Hours | Timeline |
|------|-------------|------|------------|----------|
| Tech Support (US) | Pre-migration backup verification and snapshot | $150/hr | 2 | Week 2 |
| Tech Support (US) | P2V conversion setup (Disk2VHD / Veeam) | $150/hr | 2 | Week 2-3 |
| Tech Support (Offshore) | Data transfer monitoring (~119 GB OS volume) | $45/hr | 2 | Week 2-3 |
| Tech Support (US) | Driver cleanup, HAL remediation, VM tools install | $150/hr | 2 | Week 3 |
| Tech Support (US) | Windows activation, licensing validation on VM | $150/hr | 1 | Week 3 |
| Tech Support (US) | Server role and service validation (AD, DNS, DHCP, file shares, print) | $150/hr | 3 | Week 3 |
| Tech Support (US) | DNS/IP reconfiguration and network cutover | $150/hr | 2 | Week 3 |
| Tech Support (Offshore) | Performance validation and baseline comparison | $45/hr | 2 | Week 3 |
| | **Phase 3 Total** | | **16** | |

---

### Phase 4: Shared Folder Migration to OneDrive / SharePoint Online

**3.4.1 Description**

Migrate approximately 779 GB (~718 GB used) of shared folders from the server's D: drive to Microsoft SharePoint Online / OneDrive for Business. This involves designing the SharePoint site collection architecture, remediating incompatible files (long paths, special characters, unsupported file types), mapping NTFS permissions to SharePoint permission groups, executing incremental migration runs, and configuring the OneDrive sync client on each end-user workstation.

**3.4.2 Deliverables**

- SharePoint Online site collection architecture designed and documented
- SharePoint document libraries created matching existing folder structure
- Pre-migration file scan and remediation report (long paths, special characters, blocked file types)
- Full data migration of ~718 GB shared folder data via SharePoint Migration Tool
- Incremental delta sync to minimize cutover window
- NTFS permissions mapped to SharePoint permission groups and validated
- OneDrive sync client installed and configured on each end-user workstation
- User training session and quick-reference guide for accessing files via OneDrive/SharePoint
- Post-migration validation report confirming file counts and data integrity

**3.4.3 Schedule**

| Role | Description | Rate | Est. Hours | Timeline |
|------|-------------|------|------------|----------|
| CTO Advisory | SharePoint site collection architecture and library design | $250/hr | 2 | Week 3 |
| Tech Support (US) | SharePoint Migration Tool setup and configuration | $150/hr | 2 | Week 3 |
| Tech Support (Offshore) | Pre-migration file scan and remediation (long paths, special chars) | $45/hr | 3 | Week 3 |
| Tech Support (US) | Initial bulk migration kickoff (~718 GB) | $150/hr | 2 | Week 3-4 |
| Tech Support (Offshore) | Migration monitoring, failed item resolution, and delta sync | $45/hr | 3 | Week 4 |
| Tech Support (US) | NTFS-to-SharePoint permission mapping and validation | $150/hr | 4 | Week 4 |
| Tech Support (Offshore) | OneDrive sync client deployment on user workstations | $45/hr | 2 | Week 4-5 |
| Tech Support (US) | User training session and quick-reference guide | $150/hr | 2 | Week 5 |
| Tech Support (Offshore) | Post-migration validation (file counts, integrity, access testing) | $45/hr | 2 | Week 5 |
| | **Phase 4 Total** | | **22** | |

---

### Phase 5: Cloudbrink ZTNA Deployment

**3.5.1 Description**

Deploy and configure the Cloudbrink Zero Trust Network Access virtual appliance on VM2 to provide secure, high-performance remote access for end users, replacing traditional VPN. This includes Cloudbrink tenant configuration, connector appliance deployment, identity provider integration with Microsoft Entra ID (Azure AD), application resource definitions, per-user ZTNA policy creation, split tunneling configuration, and Cloudbrink agent deployment to each end-user device.

**3.5.2 Deliverables**

- Cloudbrink tenant provisioned and configured
- Cloudbrink connector virtual appliance deployed and registered on VM2
- Microsoft Entra ID (Azure AD) identity provider integration configured
- Application resources defined in Cloudbrink portal (server access, file shares, LOB apps)
- Per-user and per-group ZTNA access policies created
- Split tunneling and routing configured for optimal performance over 500/500 Mbps connection
- Cloudbrink agent deployed and configured on each end-user device
- Remote access tested and validated from multiple locations (office, home, mobile)
- Cloudbrink admin dashboard walkthrough for Client IT contact

**3.5.3 Schedule**

| Role | Description | Rate | Est. Hours | Timeline |
|------|-------------|------|------------|----------|
| CTO Advisory | ZTNA architecture, policy design, and application resource planning | $250/hr | 2 | Week 5 |
| Tech Support (US) | Cloudbrink tenant setup and connector deployment on VM2 | $150/hr | 2 | Week 5 |
| Tech Support (US) | Microsoft Entra ID (Azure AD) identity provider integration | $150/hr | 2 | Week 5 |
| Tech Support (US) | Split tunneling, routing, and performance tuning | $150/hr | 1 | Week 5 |
| Tech Support (Offshore) | Cloudbrink agent deployment to end-user devices | $45/hr | 3 | Week 5-6 |
| Tech Support (US) | Multi-location access testing and troubleshooting | $150/hr | 2 | Week 6 |
| | **Phase 5 Total** | | **12** | |

---

### Phase 6: Security & Management Agent Deployment

**3.6.1 Description**

Install and configure all security and management agents on both virtual machines.

**3.6.2 Deliverables**

- CrowdStrike endpoint protection installed and reporting
- Huntress managed threat detection installed and reporting
- Patch Management agent configured with update policies
- My Remote agent installed for remote access/support

**3.6.3 Schedule**

| Role | Description | Rate | Est. Hours | Timeline |
|------|-------------|------|------------|----------|
| Tech Support (US) | Agent installation and configuration | $150/hr | 2 | Week 6 |
| Tech Support (Offshore) | Validation and reporting verification | $45/hr | 2 | Week 6 |
| | **Phase 6 Total** | | **4** | |

---

### Phase 7: Testing, Validation & Go-Live

**3.7.1 Description**

Comprehensive end-to-end testing of the migrated server, OneDrive/SharePoint access, Cloudbrink ZTNA connectivity, and all security agents. Includes user acceptance testing with Client staff, performance benchmarking, and coordinated production cutover during a planned maintenance window.

**3.7.2 Deliverables**

- End-to-end test plan and execution report
- Server role and application functional test results
- Cloudbrink remote access validation from multiple user locations
- OneDrive/SharePoint file access and sync validation
- Security agent status verification (all agents reporting to dashboards)
- User acceptance sign-off from Ed Pits
- Production DNS cutover completed
- Go-live monitoring (first 48 hours)

**3.7.3 Schedule**

| Role | Description | Rate | Est. Hours | Timeline |
|------|-------------|------|------------|----------|
| CTO Advisory | Go-live coordination, cutover plan review, client sign-off | $250/hr | 2 | Week 6 |
| Tech Support (US) | End-to-end functional testing (server, apps, shares) | $150/hr | 3 | Week 6 |
| Tech Support (US) | Coordinated go-live cutover (DNS, firewall, routing) | $150/hr | 2 | Week 6-7 |
| Tech Support (Offshore) | Cloudbrink and OneDrive access validation with end users | $45/hr | 1 | Week 7 |
| Tech Support (Offshore) | Post-cutover monitoring (first 48 hours) | $45/hr | 2 | Week 7 |
| | **Phase 7 Total** | | **10** | |

---

### Phase 8: Post-Migration Support (30 Days)

**3.8.1 Description**

30-day post-migration support period for issue resolution, performance tuning, and user assistance.

**3.8.2 Deliverables**

- Issue tracking and resolution
- Performance optimization as needed
- Project close-out report

**3.8.3 Schedule**

| Role | Description | Rate | Est. Hours | Timeline |
|------|-------------|------|------------|----------|
| Tech Support (US) | Escalated issue resolution and performance tuning | $150/hr | 2 | Weeks 7-11 |
| Tech Support (Offshore) | Routine support tickets, monitoring, and user assistance | $45/hr | 6 | Weeks 7-11 |
| | **Phase 8 Total** | | **8** | |

---

## 4. EQUIPMENT AND MATERIALS

No physical equipment procurement is required for this SOW. All infrastructure is provisioned in the Technijian cloud datacenter.

---

## 5. PRICING AND PAYMENT

### 5.1 Rate Card

| Role | Location | Rate |
|------|----------|------|
| CTO Advisory | United States | $250.00/hr |
| Tech Support | United States | $150.00/hr |
| Tech Support | Offshore (India) | $45.00/hr |

### 5.2 One-Time Migration Labor

| Phase | Description | CTO ($250) | US Tech ($150) | Offshore ($45) | Total Hrs | Cost |
|-------|-------------|------------|----------------|----------------|-----------|------|
| Phase 1 | Discovery & Assessment | 2 | 2 | — | 4 | $800.00 |
| Phase 2 | Cloud Environment Provisioning | — | 6 | 2 | 8 | $990.00 |
| Phase 3 | Server Migration (P2V) | — | 12 | 4 | 16 | $1,980.00 |
| Phase 4 | OneDrive / SharePoint Migration (~718 GB) | 2 | 10 | 10 | 22 | $2,450.00 |
| Phase 5 | Cloudbrink ZTNA Deployment | 2 | 7 | 3 | 12 | $1,685.00 |
| Phase 6 | Security Agent Deployment | — | 2 | 2 | 4 | $390.00 |
| Phase 7 | Testing & Go-Live | 2 | 5 | 3 | 10 | $1,385.00 |
| Phase 8 | Post-Migration Support (30 days) | — | 2 | 6 | 8 | $570.00 |
| **TOTAL** | | **8** | **46** | **30** | **84** | **$10,250.00** |

**Labor Cost Breakdown:**
- CTO Advisory: 8 hrs × $250/hr = $2,000.00
- Tech Support (US): 46 hrs × $150/hr = $6,900.00
- Tech Support (Offshore): 30 hrs × $45/hr = $1,350.00

**Pricing Type:** Estimate Cost — The stated hours and cost are estimates. Technijian will bill for actual time at the applicable rate. If actual hours are projected to exceed the estimate by more than 10%, Technijian will notify Client before proceeding.

---

### 5.2 Ongoing Monthly Managed Services — Technijian Datacenter (Recommended)

The following recurring monthly charges apply after migration is complete:

**Cloud Infrastructure (2 VMs)**

| Service | Code | Qty | Unit Price | Monthly |
|---------|------|-----|-----------|---------|
| VM1 — vCores (Primary Server) | CL-VC | 4 | $6.25 | $25.00 |
| VM1 — Memory GB | CL-GB | 16 | $0.63 | $10.08 |
| VM1 — Shared Bandwidth | CL-SBW | 1 | $15.00 | $15.00 |
| VM2 — vCores (Cloudbrink Appliance) | CL-VC | 2 | $6.25 | $12.50 |
| VM2 — Memory GB | CL-GB | 4 | $0.63 | $2.52 |
| VM2 — Shared Bandwidth | CL-SBW | 1 | $15.00 | $15.00 |
| Production Storage | TB-PSTR | 1 TB | $200.00 | $200.00 |
| Backup Storage | TB-BSTR | 1 TB | $50.00 | $50.00 |
| **Infrastructure Subtotal** | | | | **$330.10** |

**Microsoft Licensing**

| Service | Code | Qty | Unit Price | Monthly |
|---------|------|-----|-----------|---------|
| Windows Server Std — 2-Core Pack | MS-STD | 4 | $5.25 | $21.00 |
| **Licensing Subtotal** | | | | **$21.00** |

**Security & Management Agents (2 Servers)**

| Service | Code | Qty | Unit Price | Monthly |
|---------|------|-----|-----------|---------|
| CrowdStrike — Server | AVS | 2 | $10.50 | $21.00 |
| Huntress — Server | AVHS | 2 | $6.00 | $12.00 |
| Patch Management | PMW | 2 | $4.00 | $8.00 |
| My Remote | MR | 2 | $2.00 | $4.00 |
| **Security Subtotal** | | | | **$45.00** |

**Backup & Recovery**

| Service | Code | Qty | Unit Price | Monthly |
|---------|------|-----|-----------|---------|
| Image Backup (Veeam) | IB | 2 | $15.00 | $30.00 |
| **Backup Subtotal** | | | | **$30.00** |

| | **TECHNIJIAN TOTAL MONTHLY** | | | **$426.10** |
|---|---|---|---|---|
| | **TECHNIJIAN TOTAL ANNUAL** | | | **$5,113.20** |

---

### 5.3 Azure Equivalent Monthly Cost (For Comparison)

The following table shows the equivalent cost to host the same environment in Microsoft Azure using pay-as-you-go pricing (West US 2 region):

| Service | Azure SKU / Description | Monthly |
|---------|------------------------|---------|
| VM1 — Primary Server | D4s v5 (4 vCPU, 16 GB RAM) — Windows | $281.00 |
| VM2 — Cloudbrink Appliance | B2s (2 vCPU, 4 GB RAM) — Linux | $31.00 |
| Managed Disk | 1 TB Premium SSD (P30) | $123.00 |
| Azure Backup | Recovery Services Vault (1 Server, 1 TB) | $55.00 |
| Outbound Data Transfer | Estimated ~500 GB egress / month | $44.00 |
| Static Public IP | 1 Standard Static IP | $4.00 |
| Windows Server Licensing | Included in VM1 Windows pricing | $0.00 |
| CrowdStrike — Server | 2 servers | $21.00 |
| Huntress — Server | 2 servers | $12.00 |
| Patch Management | 2 servers | $8.00 |
| My Remote | 2 servers | $4.00 |
| Azure Monitor & Alerts | Basic monitoring | $15.00 |
| | **AZURE TOTAL MONTHLY** | **$598.00** |
| | **AZURE TOTAL ANNUAL** | **$7,176.00** |

---

### 5.4 Cost Comparison Summary

| | Technijian Datacenter | Microsoft Azure | Savings |
|---|---|---|---|
| **Monthly Cost** | $426.10 | $598.00 | **$171.90 (28.7%)** |
| **Annual Cost** | $5,113.20 | $7,176.00 | **$2,062.80 (28.7%)** |
| **3-Year Cost** | $15,339.60 | $21,528.00 | **$6,188.40 (28.7%)** |

**Technijian Datacenter Advantages:**

- **28.7% lower monthly cost** compared to Azure pay-as-you-go pricing
- **$2,062.80 annual savings** on hosting alone
- **No egress / bandwidth charges** — Technijian includes shared bandwidth in VM pricing
- **No surprise Azure consumption charges** — predictable, fixed monthly billing
- **Local Technijian support team** manages the infrastructure end-to-end
- **Single vendor** for hosting, security, backup, and support — no Azure portal management required
- **Included Veeam backup** — enterprise-grade backup with faster recovery vs. Azure Backup
- **No Azure expertise required** — Technijian handles all infrastructure management

---

### 5.5 Payment Schedule

| Milestone | Invoiced | Amount |
|-----------|----------|--------|
| Project kickoff (before Phase 1 begins) | Upon SOW execution | $5,125.00 (50%) |
| Go-live completion (after Phase 7) | Upon go-live | $5,125.00 (50%) |
| Monthly managed services | 1st of each month | $426.10/month |
| **One-Time Project Total** | | **$10,250.00** |

### 5.6 Payment Terms

All invoices are due and payable within **thirty (30) days** of the invoice date. Late payments are subject to the terms of the Master Service Agreement (MSA-OKL-2026).

---

## 6. CLIENT RESPONSIBILITIES

Client shall:

(a) Provide administrative credentials and physical/remote access to the existing server;

(b) Designate Ed Pits (or alternate) as the point of contact authorized to make decisions on behalf of Client;

(c) Review and approve deliverables within **five (5) business days** of submission;

(d) Ensure all critical data is backed up prior to the start of migration work;

(e) Inform users of planned service changes, maintenance windows, and downtime;

(f) Procure and maintain Microsoft 365 licenses with adequate OneDrive/SharePoint storage for the shared folder migration (~779 GB); and

(g) Coordinate with Cloudbrink for per-user ZTNA subscription licensing (separate from this SOW).

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

**9.01.** The terms of the Master Service Agreement (MSA-OKL-2026) shall govern this SOW. In the event of a conflict between this SOW and the MSA, the MSA shall prevail unless this SOW expressly states otherwise.

---

## SIGNATURES

**TECHNIJIAN, INC.**

By: ___________________________________

Name: _________________________________

Title: _________________________________

Date: _________________________________

**OAKTREE LAW**

By: ___________________________________

Name: Ed Pits

Title: _________________________________

Date: _________________________________
