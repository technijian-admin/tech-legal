# TECHNIJIAN, INC.
# Datacenter Operations Runbook

**Document Reference:** TECH-DC-RB-MASTER
**Version:** 1.0  | **Effective Date:** April 2026
**Classification:** Confidential — Internal Infrastructure Document
**Owner:** Sai Revanth, US Datacenter Lead
**Approved By:** Ravi Jain, CEO
**Review Cycle:** Quarterly — next review July 2026

---

## Table of Contents

<!--WORD_TOC_FIELD-->

---

## 1. Site & Facility

### 1.1 Site Overview

#### 1.1.1 Primary Site — TPX Irvine, California

| Attribute | Detail |
|---|---|
| Facility | TPX Communications Datacenter, Irvine, CA |
| Role | Primary production DC |
| Cage / Suite | [Cage ID — TBD] |
| Technijian Colocation Contact | Sai Revanth (US DC Lead) |
| Emergency DC Contact | [TPX NOC Number — TBD] |
| 24x7 Remote Ops | India team (Parveen Biswal, Gurdeep Kumar, Aditya Saraf, Ajay Bhardwaj) |

#### 1.1.2 Secondary Site — TPX Las Vegas, Nevada

| Attribute | Detail |
|---|---|
| Facility | TPX Communications Datacenter, Las Vegas, NV |
| Role | Geographic redundancy — DNS failover, secondary workloads |
| Hardware Generation | Older generation (equivalent stack, earlier firmware) |
| Remote Ops | India team (same 24x7 rotation) |
| On-site Contact | [TPX Las Vegas NOC — TBD] |

---

### 1.2 Physical Access Controls

#### 1.2.1 Access Roster

| Person | Role | Access Level |
|---|---|---|
| Sai Revanth | US DC Lead | Full physical — both sites |
| Ravi Jain | Director | Full physical — both sites |
| [TPX Staff] | Escorted hands-and-eyes only | Cage-level, escorted |

#### 1.2.2 Access Procedures

**Unescorted access:** Only Sai Revanth and Ravi Jain hold unescorted access badges. All third-party vendors (Cisco TAC, hardware replacement) require pre-authorization via TPX facility request + Technijian Client Portal ticket (Priority: P2 Maintenance).

**Remote hands:** Request via TPX customer portal. India team creates the ticket; Sai Revanth approves within 2 hours during business hours, or directly contacts TPX NOC for emergency remote hands.

**Visitor log:** Maintain a physical visitor log in the cage binder AND create a corresponding Client Portal ticket for every physical access event. Minimum fields: date, time-in, time-out, person, purpose, authorized by.

#### 1.2.3 After-Hours Access

- India team detects alert → opens P1 Client Portal ticket → calls Sai Revanth mobile
- If Sai unavailable: escalate to Ravi Jain → rjain@technijian.com / mobile
- TPX emergency number must be posted inside cage door and pinned in the `#dc-ops` channel

---

### 1.3 Power & Cooling

#### 1.3.1 Irvine

| Circuit | Feed | UPS | Notes |
|---|---|---|---|
| A-feed | [TPX PDU A] | [UPS Model — TBD] | Cisco UCS FI-A, Nimbus SAN A-port |
| B-feed | [TPX PDU B] | [UPS Model — TBD] | Cisco UCS FI-B, Nimbus SAN B-port |
| Network | [TPX PDU C] | [UPS Model — TBD] | Nexus 3K, Catalyst 3850, Meraki |

**Power capacity:** [kW — TBD]. Alert threshold: >80% of contracted draw triggers P2 ticket to Sai.

**Cooling:** TPX facility-managed. SLA: maintained at 68–72°F (20–22°C). ManageEngine OpsManager ambient sensor alert threshold: >77°F (25°C) = P1.

#### 1.3.2 Las Vegas

Same dual-feed UPS architecture; older UPS units — inspect battery test dates quarterly. [kW contracted — TBD].

---

### 1.4 Connectivity

#### 1.4.1 Internet / WAN Circuits — Irvine

| Circuit | Provider | Bandwidth | Purpose |
|---|---|---|---|
| Primary | [ISP — TBD] | [Mbps — TBD] | Client VDI, production traffic |
| Secondary | [ISP — TBD] | [Mbps — TBD] | CloudBrink SDWAN failover path |

#### 1.4.2 Internet / WAN Circuits — Las Vegas

| Circuit | Provider | Bandwidth | Purpose |
|---|---|---|---|
| Primary | [ISP — TBD] | [Mbps — TBD] | DNS geographic redundancy, failover VMs |
| Secondary | [ISP — TBD] | [Mbps — TBD] | CloudBrink SDWAN failover path |

#### 1.4.3 Cross-Site Link

CloudBrink SDWAN zero-trust overlay provides encrypted site-to-site tunnel between Irvine and Las Vegas (deployed April 18, 2026 cutover). Physical underlay: each site's primary ISP circuit. CloudBrink management console: [URL — TBD].

---

### 1.5 Cage Inventory & Rack Layout

#### 1.5.1 Rack Manifest — Irvine

| Rack # | Contents | Notes |
|---|---|---|
| R01 | Cisco UCS FI Pair + 8 blades | Primary compute |
| R02 | Cisco UCS FI Pair + 8 blades | Secondary compute |
| R03 | Nimbus Data All-Flash SAN | Production storage |
| R04 | 2× QNAP NAS | Backup storage (both units in Irvine) |
| R05 | 2× Nexus 3K (core), 2× Catalyst 3850 stack (mgmt) | Network core |
| R06 | Meraki firewalls, CloudBrink appliance(s), patch panels | Edge / WAN |

*Note: Update rack positions after any physical change. Photograph rack layout after every maintenance window.*

#### 1.5.2 Rack Manifest — Las Vegas

| Rack # | Contents | Notes |
|---|---|---|
| R01 | UCS compute (older gen) | [Blade count — TBD] |
| R02 | Storage | [Model — TBD] |
| R03 | Network (equivalent Nexus/Catalyst config, older HW) | [Model — TBD] |
| R04 | Meraki firewalls, WAN edge | |

---

### 1.6 Labels, Documentation & Cage Binder

Every piece of equipment must have:

1. **Asset tag** — Technijian asset number (format: TECH-IRV-XXXX or TECH-LAS-XXXX)
2. **Cable labels** — both ends of every copper and fiber run
3. **IP label** — IPMI/iDRAC/CIMC management IP taped to the unit

**Cage binder (physical, kept in cage):**
- Current network diagram (printed, dated)
- IP address allocation sheet
- Circuit IDs and ISP contact numbers
- TPX emergency contacts
- UPS battery replacement schedule
- Last 3 maintenance window reports

**Digital copies** — all binder contents mirrored in Client Portal under Technijian internal account, tagged `DC-DOCS`.

---

### 1.7 Maintenance Window Policy

| Type | Window | Approval Required |
|---|---|---|
| Standard maintenance | Saturday 10 PM – Sunday 4 AM PT | Sai Revanth + Ravi Jain |
| Emergency change | Any time (P1 incident) | Ravi Jain verbal + immediate Client Portal ticket |
| Vendor-scheduled | Coordinate with TPX 72h advance notice | Sai Revanth |

**Post-maintenance checklist** (mandatory — to be completed before closing the maintenance ticket):

- [ ] All VMs confirmed powered on in vCenter
- [ ] Veeam B&R: all backup jobs in Ready/Success state (not Disabled or Warning)
- [ ] Veeam ONE: dashboard shows all protected VMs
- [ ] ManageEngine OpsManager: no active critical alerts
- [ ] Nimbus SAN: all volumes online, no rebuild in progress
- [ ] QNAP NAS: both units accessible, backup repositories mounted in Veeam
- [ ] Meraki dashboard: all uplinks green
- [ ] CloudBrink tunnel: site-to-site status Active
- [ ] Nexus HSRP: active/standby roles as expected (`show standby brief`)
- [ ] Client Portal ticket updated with completion summary signed off by Sai Revanth

> **Root Cause — April 18, 2026 Incident:** Post-cutover verification checklist was not completed on Sunday, April 19. Veeam backup jobs were not confirmed in Ready state before Sunday night backup window. This runbook section and Section 6 (Backup & DR) exist to close that gap.

---

### 1.8 Emergency Contacts

| Contact | Role | Phone | Email |
|---|---|---|---|
| Sai Revanth | US DC Lead | [Mobile — TBD] | [TBD]@technijian.com |
| Ravi Jain | Director | [Mobile — TBD] | rjain@technijian.com |
| TPX Irvine NOC | Facility | [TBD] | [TBD] |
| TPX Las Vegas NOC | Facility | [TBD] | [TBD] |
| Cisco TAC | Network/Compute | 1-800-553-2447 | TAC case via cisco.com |
| Nimbus Data Support | Storage | [TBD] | support@nimbusdata.com |
| Veeam Support | Backup | [TBD] | via my.veeam.com |
| ManageEngine Support | Monitoring | [TBD] | via manageengine.com |

---

## 2. Network Architecture

### 2.1 Network Design Overview

Technijian's datacenter network uses a **collapsed core/distribution** model with two tiers:

1. **Edge / WAN tier** — Meraki MX firewalls + CloudBrink SDWAN zero-trust overlay
2. **Core switching tier** — 2× Cisco Nexus 3K (HSRP, L3 routing, SVI-per-VLAN) + 2× Catalyst 3850 stack (management VLAN only)

Traffic flows: Client devices → CloudBrink zero-trust agent → Meraki WAN handoff → Nexus core → ESXi vSwitches / Nimbus SAN / QNAP NAS.

---

### 2.2 Edge & WAN — Meraki Firewalls

#### 2.2.1 Device Details

| Site | Model | Role | Management |
|---|---|---|---|
| Irvine | Meraki MX [model — TBD] | Primary WAN firewall | dashboard.meraki.com |
| Las Vegas | Meraki MX [model — TBD] | Secondary WAN firewall | dashboard.meraki.com |

#### 2.2.2 WAN Configuration

- **Dual uplinks:** Primary ISP (active) + Secondary ISP (standby / SD-WAN failover)
- **Auto-failover:** Meraki MX automatic uplink failover. Alert threshold: latency >150ms or loss >5% = automatic failover + ManageEngine alert
- **VPN:** Site-to-site Auto VPN between Irvine and Las Vegas Meraki (backup path; CloudBrink is primary overlay)

#### 2.2.3 Security Policies — Meraki

- Outbound: permit established sessions; block by category (adult content, malware-known IPs, P2P)
- Inbound: default deny all; permit only CloudBrink relay ports + Veeam SPC inbound replication port + management VPN
- IDS/IPS: Meraki MX IDS in **Prevention mode** (not Detection only)
- Content filtering: enabled for all VLANs except dedicated management VLAN

#### 2.2.4 Meraki Monitoring

ManageEngine OpsManager monitors Meraki via SNMP v3. Alert escalation:
- Uplink down > 2 min → P1 ticket → page India team → call Sai Revanth
- IPS alert (high severity) → P1 ticket → notify Sai + Ravi Jain

---

### 2.3 CloudBrink SDWAN Zero-Trust Overlay

*Deployed: April 18, 2026 cutover*

#### 2.3.1 Architecture

CloudBrink provides a zero-trust network access (ZTNA) overlay across both sites and to remote users / India team. All management access to DC systems by India techs traverses CloudBrink (no legacy VPN split-tunnel to bare metal).

| Component | Role | Location |
|---|---|---|
| CloudBrink Gateway — Irvine | Site anchor | TPX Irvine edge rack |
| CloudBrink Gateway — Las Vegas | Site anchor | TPX Las Vegas edge rack |
| CloudBrink Cloud Controller | Policy, identity, telemetry | CloudBrink SaaS |
| CloudBrink Agent | Installed on all admin endpoints | India techs + Sai Revanth |

#### 2.3.2 Access Policy Groups

| Group | Members | Resources Permitted |
|---|---|---|
| DC-ADMIN-US | Sai Revanth | All VLANs, CIMC, vCenter, Nimbus, Veeam, Meraki SNMP |
| DC-OPS-INDIA | India tech rotation | Veeam console, vCenter (read+VM ops), OpsManager, QNAP UI |
| DC-READONLY | [Audit / Director] | OpsManager dashboards, Veeam ONE dashboards only |

#### 2.3.3 CloudBrink Operational Procedures

**Adding a new India tech:**
1. Create user in CloudBrink identity (SSO via Microsoft 365 tenant)
2. Assign to `DC-OPS-INDIA` group
3. Send CloudBrink agent installer link
4. Verify tunnel connectivity before scheduling first shift

**Revoking access:**
1. Disable user in CloudBrink console (immediate tunnel drop)
2. Remove from Microsoft 365 group
3. Record in Client Portal access log

**Health check command** (Sai Revanth, weekly):
- CloudBrink portal → Sites → confirm both Irvine + Las Vegas show **Connected / Active**
- Confirm last heartbeat <5 minutes ago

---

### 2.4 Core Switching — Cisco Nexus 3K

#### 2.4.1 Device Details

| Device | Role | Hostname | Management IP | HSRP Role |
|---|---|---|---|---|
| Nexus 3K #1 | Core switch A | TECH-IRV-NEXUS-01 | [IP — TBD] | Active (primary VLANs) |
| Nexus 3K #2 | Core switch B | TECH-IRV-NEXUS-02 | [IP — TBD] | Standby |

*Las Vegas: equivalent pair, older hardware. Hostnames: TECH-LAS-NEXUS-01/02*

#### 2.4.2 VLAN Table — Infrastructure VLANs (Both Sites)

| VLAN | Name | DC Subnet (Irvine) | NV Subnet (Las Vegas) | Internet | Notes |
|---|---|---|---|---|---|
| 1 | Management | 10.100.1.0/24 | 10.110.1.0/24 | Y (both) | CIMC, QNAP, Nimbus mgmt, Catalyst 3850, Nexus mgmt0 |
| 2 | Outbound | 10.100.2.0/24 | 10.110.2.0/24 | DC: Y / NV: N | General outbound / NAT |
| 3 | Voice | 10.100.3.0/24 | 10.110.3.0/24 | DC: Y / NV: N | VoIP |
| 4 | IOT | 10.100.4.0/24 | 10.110.4.0/24 | DC: Y / NV: N | IoT devices — isolated from client VLANs |
| 5 | Storage | 10.100.5.0/24 | 10.110.5.0/24 | DC: Y / NV: N | Nimbus SAN NFS/iSCSI; MTU 9000 required |
| 6 | Backup | 10.100.6.0/24 | 10.110.6.0/24 | DC: Y / NV: N | Veeam job traffic to QNAP repositories |
| 7 | vMotion | 10.100.7.0/24 | 10.110.7.0/24 | DC: Y / NV: N | VMware vMotion only — no other traffic |
| 8 | HA | 10.100.8.0/24 | 10.110.8.0/24 | DC: Y / NV: N | vSphere HA heartbeat — isolated |
| 9–99 | (Reserved) | 10.100.9–99.0/24 | 10.110.9–99.0/24 | DC: Y / NV: N | Available for future infrastructure use |

#### 2.4.3 VLAN Table — Client VLANs (Both Sites)

Each client is assigned a dedicated VLAN and subnet, mirrored across both sites. Las Vegas mirrors use the 10.110.x.0/24 prefix. All client VLANs have internet access and are isolated from each other except where explicitly noted (Internal/External cross-routing).

| VLAN | Client Code | DC Subnet | NV Subnet | Cross-Routes To | Notes |
|---|---|---|---|---|---|
| 100 | CCC | 10.100.100.0/24 | 10.110.100.0/24 | — | |
| 101 | AKT | 10.100.101.0/24 | 10.110.101.0/24 | — | |
| 102 | MGN | 10.100.102.0/24 | 10.110.102.0/24 | — | |
| 103 | VAF | 10.100.103.0/24 | 10.110.103.0/24 | — | |
| 104 | MYVDI | 10.100.104.0/24 | 10.110.104.0/24 | — | Omnissa Horizon VDI platform VLAN |
| 105 | VG | 10.100.105.0/24 | 10.110.105.0/24 | — | |
| 106 | ORX-PROD | 10.100.106.0/24 | 10.110.106.0/24 | VLAN 109 | Production — cross-routes to ORX-DEV (109) |
| 107 | PMMS | 10.100.107.0/24 | 10.110.107.0/24 | — | |
| 108 | PCM | 10.100.108.0/24 | 10.110.108.0/24 | — | |
| 109 | ORX-DEV | 10.100.109.0/24 | 10.110.109.0/24 | VLAN 106 | Dev — cross-routes to ORX-PROD (106) |
| 110 | DLC | 10.100.110.0/24 | 10.110.110.0/24 | — | |
| 111 | (Available) | 10.100.111.0/24 | 10.110.111.0/24 | — | |
| 112 | BST | 10.100.112.0/24 | 10.110.112.0/24 | — | **DECOMMISSION by 2026-04-30** — BST contract terminated; disable VLAN and remove routes after clearance |
| 113 | CDC | 10.100.113.0/24 | 10.110.113.0/24 | — | |
| 114–239 | (Available) | 10.100.x.0/24 | 10.110.x.0/24 | — | Available for new client assignments |
| 240 | Cloud | 10.100.240.0/24 | 10.110.240.0/24 | — | Cloud connectivity / transit |
| 241–252 | (Available) | 10.100.x.0/24 | 10.110.x.0/24 | — | Reserved |
| 253 | TestLab | 10.100.253.0/24 | 10.110.253.0/24 | — | Isolated test environment — no production routing |
| 254 | Technijian | 10.100.254.0/24 | 10.110.254.0/24 | — | Technijian internal systems |

**VLAN allocation rule:** New clients are assigned the next available VLAN in the 114–239 range. Assignment tracked in Client Portal → DC Assets → VLAN Register. Sai Revanth owns all allocations.

**BST VLAN 112 decommission checklist (due 2026-04-30):**

- [ ] Confirm BST access is fully terminated and no active sessions
- [ ] Remove VLAN 112 SVI from Nexus 3K (both Irvine and Las Vegas)
- [ ] Remove VLAN 112 from all trunk ports and UCS vNIC configurations
- [ ] Remove Meraki firewall rules referencing VLAN 112
- [ ] Archive BST VLAN config in Client Portal ticket before deletion
- [ ] Update VLAN register: mark 112 as Available

#### 2.4.4 HSRP Configuration

Both Nexus 3K switches run HSRP on all production SVIs. Standard configuration per VLAN:

```
interface Vlan<ID>
  ip address <primary-IP> <mask>
  hsrp <VLAN-ID>
    ip <VIP>
    priority 110  ! Nexus-01 active
    preempt
```

**Post-maintenance HSRP verification:**
```
TECH-IRV-NEXUS-01# show standby brief
TECH-IRV-NEXUS-01# show hsrp brief
```
Expected output: Nexus-01 = **Active** on all VLANs, Nexus-02 = **Standby**. Any deviation = P1 incident.

#### 2.4.5 Spanning Tree

Mode: **Rapid-PVST+** on all VLANs.
Nexus-01 is STP root for all VLANs (`spanning-tree vlan 1-4094 priority 4096`).
Nexus-02 is secondary root (`priority 8192`).

**Monthly verification:**
```
show spanning-tree summary
show spanning-tree vlan <ID> detail
```
Confirm: Root = Nexus-01, no topology change counters incrementing rapidly.

#### 2.4.6 Routing

Static default routes on both Nexus switches pointing to Meraki internal interface. OSPF or BGP is NOT currently deployed — all inter-VLAN routing via SVI + HSRP VIPs. Route redistribution is not configured; if future WAN routing complexity requires it, open a Change Request before modifying.

---

### 2.5 Management Switching — Catalyst 3850 Stack

#### 2.5.1 Role and Scope

The 2× Catalyst 3850 are stacked and carry **management VLAN 1 only**. All physical management interfaces (CIMC, iDRAC, Nimbus management port, QNAP LAN2, Meraki in-band management, Nexus management0) connect to the 3850 stack.

*Post April 18 change: Catalyst 3850 was demoted from core to management-only. It no longer routes production VLANs. This reduces blast radius if management traffic floods.*

#### 2.5.2 Device Details

| Stack Member | Priority | Hostname | Management IP |
|---|---|---|---|
| 3850 #1 (Active) | 15 | TECH-IRV-CAT-01 | [IP — TBD] |
| 3850 #2 (Standby) | 14 | TECH-IRV-CAT-02 | [IP — TBD] |

#### 2.5.3 Stack Health Check

```
show switch
show switch stack-ring speed
show switch stack-ports
```
Expected: both members **Ready**, ring speed > 40G, no stack-port errors.

---

### 2.6 DNS Architecture

| Zone | Primary | Secondary | Notes |
|---|---|---|---|
| technijian.com | [DNS server — TBD] | CloudFlare / [ISP DNS] | Public zone |
| Internal (AD/ESXi) | vCenter DNS [IP] | Nexus-01 SVI management VLAN | Internal resolution for ESXi hosts, VMs |
| Geographic redundancy | Irvine resolver | Las Vegas resolver | Failover via CloudBrink routing |

*DNS was migrated April 18, 2026 as part of the CloudBrink cutover. Verify DNS resolution after any network change using:*
```
nslookup vcenter.technijian.local [vCenter-DNS-IP]
```

---

### 2.7 Network Monitoring

#### 2.7.1 ManageEngine OpsManager

All network devices are monitored via SNMP v3:

| Device | Community / Auth | Poll Interval | Alert Profile |
|---|---|---|---|
| Nexus 3K #1/2 | [SNMP v3 creds — see Vault] | 5 min | DC-Network-Critical |
| Catalyst 3850 | [SNMP v3 creds] | 5 min | DC-Network-Critical |
| Meraki MX (Irvine) | SNMP v3 | 5 min | DC-Edge-Critical |
| CloudBrink gateways | API integration | 1 min | DC-Edge-Critical |

Alert escalation matrix:
- **P1** (device down, HSRP failover, uplink loss): immediate PagerDuty/OpsManager → India team duty engineer → Sai Revanth call within 10 minutes
- **P2** (high CPU >85% sustained 10min, high error counters, spanning tree TCN): Client Portal ticket within 30 minutes
- **P3** (degraded performance, minor interface errors): Client Portal ticket next business day

#### 2.7.2 Baseline Metrics (Capture after each maintenance window)

| Metric | Expected Baseline | Alert Threshold |
|---|---|---|
| Nexus uplink utilization | <40% | >80% for 5 min |
| HSRP state | Nexus-01 Active | Any change = P1 |
| Meraki uplink latency | <20ms to ISP handoff | >150ms = failover |
| CloudBrink tunnel RTT (Irvine↔LV) | <30ms | >100ms = P2 |
| STP TC count | 0 new TCs/hour | >5 TCs/hour = P2 |

---

### 2.8 Change Management — Network

All network changes require:

1. **Client Portal Change Request ticket** opened ≥72h before execution (emergency changes: post-hoc within 2h)
2. **Rollback plan documented** in the ticket before approval
3. **Approval:** Sai Revanth + Ravi Jain sign-off
4. **Change window:** Saturday 10 PM – Sunday 4 AM PT (standard); P1 emergency at any time
5. **Post-change verification:** Complete the post-maintenance checklist (Section 1, Clause 7.00) before closing ticket

**Configuration backup:** Running configuration saved to QNAP NAS before every change:
```
copy running-config tftp://[QNAP-IP]/network-configs/[hostname]-[YYYY-MM-DD].cfg
```
QNAP path: `\network-configs\`. Retain last 90 days.

---

## 3. Compute & Virtualization

### 3.1 Compute Platform Overview

| Component | Detail |
|---|---|
| Compute fabric | Cisco UCS (Unified Computing System) |
| Fabric Interconnects | 2× Cisco UCS FI (active/active) |
| Blade chassis | [Number of chassis — TBD] |
| Blade count | 16× UCS blades (Irvine primary) |
| Hypervisor | VMware ESXi 8.0 |
| vCenter | VMware vCenter Server 8.0 |
| VDI | Omnissa Horizon (formerly VMware Horizon) |
| Las Vegas | Equivalent UCS platform, older hardware generation |

---

### 3.2 Cisco UCS Fabric Interconnects

#### 3.2.1 Device Details

| Device | Role | Hostname | Management IP | UCS Manager |
|---|---|---|---|---|
| UCS FI-A | Primary | TECH-IRV-FI-A | [IP — TBD] | https://[FI-IP]/ucsm |
| UCS FI-B | Secondary (HA) | TECH-IRV-FI-B | [IP — TBD] | Same cluster |

UCS FI-A/B operate in **active/active** mode (End Host Mode). All blade traffic distributed across both FIs via vNIC pinning. Loss of one FI = graceful degradation, zero VM downtime.

#### 3.2.2 UCS Manager Access

- **Primary access:** CloudBrink zero-trust tunnel → UCS Manager web UI at `https://[FI-A-IP]/ucsm`
- **Emergency access:** CIMC console port (physical) on each blade; management VLAN 1 via Catalyst 3850
- **Credentials:** Stored in Technijian credential vault (do NOT store locally on admin workstations)

#### 3.2.3 Service Profiles

All blades are deployed via **UCS Service Profiles** — no bare-metal manual configuration. Service profiles define:
- Boot policy (SAN boot from Nimbus LUN or local disk)
- vNIC/vHBA configuration and pinning to FI-A/FI-B
- BIOS policy, power policy, maintenance policy

**Golden rule:** Never modify hardware settings directly on a blade. All changes go through Service Profile modification in UCS Manager and must have an approved Change Request ticket.

#### 3.2.4 UCS Health Checks

**Daily (India team — morning shift handoff):**
```
UCS Manager → Equipment tab → Fabric Interconnects → verify: Operability = Operable, both FIs
UCS Manager → Equipment tab → Chassis → Blades → verify: no blade in "Degraded" or "Failed" state
UCS Manager → Faults tab → filter Critical/Major → review and ticket any new faults
```

**Weekly (Sai Revanth):**
- UCS Manager → Policies → Firmware → confirm all blades running approved firmware version
- Review thermal and power statistics (UCS Manager → Statistics)
- Verify service profile associations are correct (no blade shows "Unassociated")

#### 3.2.5 Blade Inventory — Irvine

| Blade # | Service Profile | Role | ESXi Host IP | vCenter Name |
|---|---|---|---|---|
| Blade-01 | SP-ESX-01 | Production vSphere | [IP — TBD] | esxi-01.technijian.local |
| Blade-02 | SP-ESX-02 | Production vSphere | [IP — TBD] | esxi-02.technijian.local |
| Blade-03 | SP-ESX-03 | Production vSphere | [IP — TBD] | esxi-03.technijian.local |
| Blade-04 | SP-ESX-04 | Production vSphere | [IP — TBD] | esxi-04.technijian.local |
| Blade-05 | SP-ESX-05 | VDI — Omnissa Horizon | [IP — TBD] | esxi-05.technijian.local |
| Blade-06 | SP-ESX-06 | VDI — Omnissa Horizon | [IP — TBD] | esxi-06.technijian.local |
| Blade-07 through 16 | [TBD] | [TBD] | [TBD] | [TBD] |

*Populate remaining blades based on current vCenter inventory.*

---

### 3.3 VMware vSphere (ESXi 8.0 + vCenter 8.0)

#### 3.3.1 vCenter Server Details

| Attribute | Detail |
|---|---|
| vCenter FQDN | vcenter.technijian.local |
| vCenter IP | [IP — TBD] |
| vCenter version | 8.0 Update [x] |
| SSO domain | vsphere.local |
| vCenter deployment type | vCSA (appliance) |
| Cluster name | TECH-IRV-CLUSTER-01 |
| HA/DRS | vSphere HA: Enabled; DRS: Fully Automated |

#### 3.3.2 vCenter Access

- **Web client:** `https://vcenter.technijian.local/ui` via CloudBrink tunnel
- **Admin access:** Sai Revanth — `administrator@vsphere.local`; India team — role-limited account (VM operations, no host config changes)
- **India team vCenter role permissions:** Power on/off VMs, take snapshots, view events/tasks; NO host configuration, NO storage policy changes, NO network config

#### 3.3.3 Cluster Configuration

| Setting | Value |
|---|---|
| vSphere HA | Enabled — Host Monitoring + VM Monitoring |
| HA Admission Control | Reserve capacity for [1] host failure |
| DRS | Fully Automated, migration threshold: Conservative |
| vSphere FT | Enabled only for [critical VMs — TBD] |
| EVC Mode | [CPU generation — TBD] |
| Datastore cluster | [Name — TBD], Storage DRS: Automated |

#### 3.3.4 VM Naming Convention

```
[Site]-[Role]-[Function]-[Seq]
Examples:
  IRV-PROD-DC01         (Domain Controller)
  IRV-PROD-VEEAM01      (Veeam B&R Server)
  IRV-VDI-CONN01        (Horizon Connection Server)
  IRV-MGMT-VCENTER      (vCenter Appliance)
  LAS-PROD-DC01         (Las Vegas DC)
```

#### 3.3.5 Snapshot Policy

- **Snapshots are not backups.** No VM should have a snapshot older than 72 hours (Veeam deletes after job).
- ManageEngine OpsManager alert: any VM snapshot > 72 hours = P2 ticket
- Snapshots taken manually during maintenance must be deleted immediately after maintenance window closes

#### 3.3.6 ESXi Host Maintenance Procedures

When placing an ESXi host into maintenance mode:

1. In vCenter: right-click host → Enter Maintenance Mode → select **Move powered-off VMs** option
2. Confirm DRS migrates VMs without downtime (Fully Automated)
3. Verify no VMs remain on the host: `vim-cmd vmsvc/getallvms` (SSH to host, emergency only)
4. Perform maintenance
5. Exit Maintenance Mode → monitor vCenter Events for any HA restarts
6. Verify all originally-hosted VMs are running and visible in Veeam B&R job list

#### 3.3.7 vCenter Health Checks

**Daily (India team — morning shift):**
- vCenter → Hosts & Clusters → confirm all hosts: **Connected**, green
- vCenter → VMs → confirm all production VMs: **Powered On**
- vCenter → Recent Tasks → review for any failed tasks

**Weekly:**
- vCenter → Alarms → review and clear resolved alarms
- vCenter → Storage → confirm all datastores >20% free (below 20% = P2 ticket)
- Review vSphere HA events (any HA failover events = investigate root cause, open ticket)

---

### 3.4 Omnissa Horizon (VDI Platform)

#### 3.4.1 Architecture

| Component | VM Name | Role |
|---|---|---|
| Connection Server | IRV-VDI-CONN01 | Primary broker — all client connections |
| Connection Server (replica) | IRV-VDI-CONN02 | HA replica — automatic failover |
| Enrollment Server | IRV-VDI-ENROLL01 | True SSO / certificate enrollment |
| App Volumes Manager | IRV-VDI-APPVOL01 | Application delivery (if used) |
| UAG (Unified Access Gateway) | IRV-VDI-UAG01 | External access (Blast/PCoIP) |

#### 3.4.2 Horizon Admin Console

- **URL:** `https://[Connection-Server-IP]/admin` via CloudBrink
- **Admin access:** Sai Revanth; India team has **Helpdesk Administrator** role (can reset sessions, not modify pools)

#### 3.4.3 VDI Pool Types in Use

| Pool Name | Type | Desktops | Client Assignment |
|---|---|---|---|
| [Pool-01 — TBD] | Floating / Instant Clone | [Count] | [Client — TBD] |
| [Pool-02 — TBD] | Dedicated | [Count] | [Client — TBD] |

*India team: document all active pools in Client Portal under the Technijian internal asset record.*

#### 3.4.4 VDI Operations — India Team Daily Checks

1. Horizon Admin Console → Dashboard → confirm all Connection Servers **green**
2. Desktop Pools → verify no pools in **Error** state
3. Sessions → confirm no stale disconnected sessions > 8 hours (disconnect and alert user)
4. Review Horizon events log: filter **Error** and **Critical** — open Client Portal ticket for each

#### 3.4.5 VDI Troubleshooting — Common Issues

| Symptom | First Check | Action |
|---|---|---|
| User cannot connect | UAG reachable? CloudBrink tunnel active? | Verify UAG, restart connection if tunnel down |
| Black screen on desktop | Guest VM powered on? Snap taken? | Check vCenter VM status; delete stuck snapshot |
| Pool provisioning stuck | Instant Clone errors in Horizon Events | Recompose pool during off-hours; open P2 ticket |
| High latency / choppy display | Nexus uplink utilization? | Check ManageEngine; if >80% → P1 |

---

### 3.5 VM Inventory & Documentation Requirements

All production VMs must be documented in Client Portal (Technijian internal assets):

| Field | Required |
|---|---|
| VM name | Yes |
| Role / function | Yes |
| IP addresses (all NICs) | Yes |
| Veeam backup job name | Yes |
| Client association (if client-specific) | Yes |
| RPO / RTO requirement | Yes |
| Last tested restore | Yes (date) |

Sai Revanth reviews and updates this inventory monthly. India team flags any discrepancy during daily checks.

---

### 3.6 Post-Maintenance Verification — Compute Layer

After any compute maintenance window, confirm before closing the ticket:

- [ ] UCS Manager: all blades Operable, no Critical/Major faults
- [ ] vCenter: all ESXi hosts Connected, green health
- [ ] vCenter: all production VMs Powered On
- [ ] vCenter: no active HA-triggered restarts in Events (last 2 hours)
- [ ] Omnissa Horizon: all Connection Servers green, all desktop pools Ready
- [ ] Veeam B&R: all backup jobs in **Ready** (not Disabled, not Warning, not Error) — see Section 5
- [ ] ManageEngine OpsManager: no Critical/Major alerts on compute devices

> **Root Cause — April 18, 2026:** Post-cutover, the above checklist (specifically Veeam B&R job readiness) was not verified on Sunday April 19. This checklist is mandatory for every maintenance window, including infrastructure recabling and network-only changes, since network changes can affect Veeam repository connectivity and job scheduling.

---

## 4. Storage

### 4.1 Storage Architecture Overview

| Tier | Device | Role | Location |
|---|---|---|---|
| Tier 1 — Production | Nimbus Data All-Flash Array | VM datastores, VDI desktops, production workloads | Irvine (primary) |
| Tier 2 — Backup | 2× QNAP NAS | Veeam backup repositories | Irvine only |
| Replication | Veeam SPC / Nimbus replication | Offsite DR | Las Vegas (see Section 5) |

**Critical architecture note:** Both QNAP NAS units are physically located in Irvine. There is no tape or separate physical backup media in Las Vegas. Offsite protection is achieved through Nimbus-to-Las Vegas replication and Veeam SPC cloud repository. This means a catastrophic Irvine facility failure (fire, flood, power loss) would require Las Vegas failover — confirm RTO/RPO commitments with Ravi Jain before any client SLA negotiations.

---

### 4.2 Nimbus Data All-Flash SAN

#### 4.2.1 Device Details

| Attribute | Detail |
|---|---|
| Vendor | Nimbus Data |
| Model | [Model — TBD] |
| Raw capacity | [TB — TBD] |
| Usable capacity | [TB — TBD] |
| Protocol | iSCSI / NFS (dual) |
| Management UI | `https://[Nimbus-IP]` |
| Management VLAN | 1 (Management); storage traffic on VLAN 5 |
| Support | support@nimbusdata.com |

#### 4.2.2 Volume / Datastore Layout

| Volume Name | Protocol | Mounted On | Purpose | Size |
|---|---|---|---|---|
| DS-PROD-01 | NFS | All ESXi hosts | Production VM datastores | [TB] |
| DS-PROD-02 | NFS | All ESXi hosts | Production VM datastores (overflow) | [TB] |
| DS-VDI-01 | NFS | VDI hosts | Omnissa Horizon desktop pool | [TB] |
| DS-VDI-02 | NFS | VDI hosts | Horizon Instant Clone replicas | [TB] |
| DS-MGMT | NFS | All ESXi hosts | vCenter, Veeam proxy, management VMs | [TB] |

*Populate exact sizes and IPs from Nimbus management UI and vCenter datastore inventory.*

#### 4.2.3 Nimbus Health Checks

**Daily (India team):**
- Nimbus UI → Dashboard → confirm: All volumes **Online**, no rebuild or rebalance in progress
- Nimbus UI → Capacity → confirm: Overall utilization <80% (>80% = P2 ticket)
- Nimbus UI → Alerts → review and action any active alerts

**Weekly (Sai Revanth):**
- Nimbus UI → Performance → review IOPS and latency trends (baseline from last stable week)
- Confirm snapshot schedules running (Nimbus-native snapshots supplement Veeam, not replace)
- Run Nimbus diagnostic health report; export and attach to weekly ops report ticket

#### 4.2.4 Nimbus Capacity Alert Thresholds

| Utilization | Action |
|---|---|
| >75% | P2 ticket — review VM growth rate, plan expansion |
| >85% | P1 ticket — immediately notify Sai Revanth + Ravi Jain; pause new VM provisioning |
| >90% | Emergency — contact Nimbus for emergency capacity add |

ManageEngine OpsManager monitors Nimbus via SNMP/API. Alerts configured per above thresholds.

#### 4.2.5 Adding / Expanding Volumes

All datastore additions or expansions require a Change Request ticket:
1. Confirm available raw capacity in Nimbus UI
2. Create volume in Nimbus → export via NFS to ESXi hosts
3. In vCenter: Storage → Add Storage → mount NFS datastore on all hosts in cluster
4. Verify datastore appears in all host inventory
5. Update storage documentation in Client Portal

#### 4.2.6 Nimbus Snapshot Policy

- Nimbus-native snapshots: retained for 24 hours (hourly), 7 days (daily) — configurable per volume
- Snapshots are **supplemental recovery** for recent file/VM corruption; Veeam is the authoritative backup
- Do NOT rely on Nimbus snapshots for DR; they are not replicated to Las Vegas by default (only Veeam SPC replication is offsite)

---

### 4.3 QNAP NAS — Backup Storage

#### 4.3.1 Device Details

| Unit | Model | Role | Capacity | IP (VLAN 6/1) | Location |
|---|---|---|---|---|---|
| QNAP-01 | [Model — TBD] | Veeam backup repository (primary) | [TB — TBD] | [IP — TBD] | Irvine, Rack R04 |
| QNAP-02 | [Model — TBD] | Veeam backup repository (secondary / rotate) | [TB — TBD] | [IP — TBD] | Irvine, Rack R04 |

*Both units are in Irvine. No QNAP unit is in Las Vegas. Las Vegas backup protection is via Veeam SPC cloud repository (Section 5).*

#### 4.3.2 QNAP Configuration

- **RAID:** RAID 6 (minimum) on all storage pools — tolerates 2 simultaneous drive failures
- **Network:** Backup traffic on VLAN 6 (dedicated backup VLAN, separate from client VLANs); management on VLAN 1
- **Access:** SMB/NFS share mounted by Veeam Backup & Replication server as backup repository
- **Encryption:** Repository encryption enabled in Veeam (AES-256); QNAP volume encryption: [Enabled/Disabled — TBD]

#### 4.3.3 QNAP Repository Sizing

| Repository | Veeam Jobs Writing To It | Target Retention | Used / Total |
|---|---|---|---|
| QNAP-01\Backup | All production VM jobs | 14 days (daily), 4 weeks (weekly), 12 months (monthly GFS) | [TBD] / [TBD] TB |
| QNAP-02\Backup | Rotation copy / overflow | 30 days | [TBD] / [TBD] TB |

**Capacity alert:** Veeam automatically alerts at 80% repository capacity. India team: if Veeam shows repository Warning (capacity) → open P2 ticket immediately.

#### 4.3.4 QNAP Health Checks

**Daily (India team):**
- QNAP UI (each unit) → Storage & Snapshots → verify: all storage pools **Ready**, no degraded RAID
- QNAP UI → System → Logs → filter Error/Warning since last check
- Confirm QNAP is reachable from Veeam server (Veeam → Backup Infrastructure → Repositories → both QNAP repos show **Connected**)

**Weekly:**
- QNAP UI → Storage → confirm no drives in Failed or Warning state
- Review QNAP system temperature (UI → System Status → Temperature): alert >55°C = P2
- Verify UPS protection: both QNAPs connected to protected PDU feed

#### 4.3.5 QNAP Drive Failure Response

If a drive fails in QNAP RAID:
1. QNAP alerts → ManageEngine OpsManager → P1 ticket opened by India team
2. India team calls Sai Revanth immediately (do not wait for morning handoff)
3. Sai Revanth: identify spare drive availability in cage
4. If hot-spare available: QNAP rebuilds automatically; monitor rebuild progress
5. If no spare: purchase compatible drive immediately; do not allow RAID to run degraded >48 hours
6. Record in Client Portal ticket: drive model, serial, slot number, replacement timeline

#### 4.3.6 QNAP Recovery Procedures

**If QNAP unit is unreachable (power, network, OS crash):**
1. Check physical power (cage inspection or TPX remote hands)
2. Check Catalyst 3850 port (management VLAN 1) — verify port Up/Up
3. If OS crash: QNAP SSH → `reboot`; if SSH unavailable: request TPX remote hands for power cycle
4. After recovery: verify Veeam repositories reconnect automatically (Repositories → Rescan)
5. Verify last backup job completed to this repository; if jobs missed → initiate manual Active Full backup run

---

### 4.4 Storage Networking (iSCSI / NFS)

#### 4.4.1 VLAN 5 — Storage Network

All production SAN/NAS traffic uses dedicated VLAN 5 (Storage). ESXi hosts have dedicated vmkernels for NFS/iSCSI on VLAN 5. This VLAN is isolated from client VLANs (100+) and backup traffic (VLAN 6) to prevent congestion.

**Jumbo frames:** VLAN 5 is configured with MTU 9000 (jumbo frames) end-to-end:
- Nexus 3K VLAN 5 SVI: `mtu 9216`
- ESXi vmkernel adapter: MTU 9000
- Nimbus SAN network interfaces: MTU 9000

**MTU verification after any network change:**
```bash
# From ESXi host (SSH):
vmkping -d -s 8972 [Nimbus-Storage-IP]
# Expected: 0% packet loss; any loss = VLAN 5 MTU mismatch = immediate investigation
```

#### 4.4.2 VLAN 6 — Backup Network

Veeam backup jobs write to QNAP NAS via VLAN 6. Standard MTU (1500) — jumbo frames not required. Backup jobs are scheduled outside production hours (default: 10 PM PT start) to minimize contention.

---

### 4.5 Disaster Recovery — Storage Perspective

| Scenario | Recovery Method | RTO Estimate | Notes |
|---|---|---|---|
| Single VM corruption | Veeam restore from QNAP | <30 min | Instant VM Recovery |
| Single datastore failure | Nimbus snapshot restore | <1 hour | If within snapshot retention |
| QNAP-01 total failure | Veeam jobs re-target to QNAP-02 | <2 hours | Manual re-target in Veeam |
| Nimbus SAN failure | Veeam Instant Recovery to Las Vegas (Veeam SPC) | <4 hours | Requires Las Vegas capacity pre-provisioned |
| Irvine facility loss | Las Vegas failover (full site) | 4–8 hours | RTO must be validated in DR test (Section 5) |

*Formal DR test must be conducted semi-annually. Last test date: [TBD — schedule before June 30, 2026].*

---

### 4.6 Post-Maintenance Verification — Storage Layer

After any storage or network maintenance:

- [ ] Nimbus SAN: all volumes Online, no rebuild in progress
- [ ] Nimbus: vCenter datastores all accessible (vCenter → Storage → Datastores → all Mounted)
- [ ] QNAP-01 and QNAP-02: both units reachable, RAID status Ready
- [ ] Veeam repositories: both QNAP repositories show **Connected** (Veeam → Backup Infrastructure → Repositories)
- [ ] VMkping test from two ESXi hosts to Nimbus: 0% loss, no MTU errors
- [ ] Storage VLAN 5 on Nexus: verify SVI is up, HSRP active

---

## 5. Backup & Disaster Recovery

### 5.1 Backup Platform Overview

| Product | Role | Managed By |
|---|---|---|
| Veeam Backup & Replication (B&R) | VM backup + restore + replication | India team daily ops; Sai Revanth owns config |
| Veeam ONE | Monitoring, reporting, capacity planning for B&R | India team monitors dashboards |
| Veeam Backup for Microsoft 365 (M365) | Exchange Online, SharePoint, Teams, OneDrive backup | India team daily ops |
| Veeam Service Provider Console (SPC) | Offsite cloud repository management; tenant reporting | Sai Revanth owns |

---

### 5.2 Veeam Backup & Replication

#### 5.2.1 Server Details

| Attribute | Detail |
|---|---|
| Veeam B&R Server | IRV-PROD-VEEAM01 |
| IP | [IP — TBD] |
| Version | Veeam B&R [version — TBD] |
| Console access | RDP via CloudBrink → `\\IRV-PROD-VEEAM01` |
| Veeam Enterprise Manager | `https://[EM-IP]:9443` |
| Database | Microsoft SQL [local/remote — TBD] |

#### 5.2.2 Backup Infrastructure Components

| Component | Name | Type | Location |
|---|---|---|---|
| Backup Proxy | IRV-PROD-VEEAM01 | VMware proxy | Irvine |
| Backup Repository 1 | QNAP-01-Repo | Scale-out / simple repository | QNAP-01, Irvine |
| Backup Repository 2 | QNAP-02-Repo | Scale-out / simple repository | QNAP-02, Irvine |
| Offsite Repository | Veeam SPC Cloud | Cloud-tier (S3-compatible) | Off-site via SPC |
| WAN Accelerator | [If deployed — TBD] | WAN acceleration | Irvine / Las Vegas |

#### 5.2.3 Backup Job Inventory

| Job Name | Type | Source | Repository | Schedule | Retention |
|---|---|---|---|---|---|
| JOB-PROD-DAILY | VMware vSphere | All production VMs | QNAP-01-Repo | Daily 10 PM PT | 14 daily, 4 weekly, 12 monthly (GFS) |
| JOB-VDI-DAILY | VMware vSphere | VDI infrastructure VMs | QNAP-01-Repo | Daily 11 PM PT | 7 daily, 4 weekly |
| JOB-MGMT-DAILY | VMware vSphere | Management VMs (vCenter, Veeam, DC) | QNAP-02-Repo | Daily 10:30 PM PT | 14 daily, 4 weekly |
| JOB-REPLICATE-LV | Replication | Critical production VMs | Las Vegas target | Daily 2 AM PT | 7 restore points |

*Populate job names from Veeam B&R console → Home → Jobs → Backup.*

#### 5.2.4 Backup Scheduling Policy — After-Hours Only

**All backup jobs run exclusively during after-hours (10 PM – 6 AM PT).** No backup job is permitted to run during business hours (6 AM – 10 PM PT). This policy exists to protect client VDI and production workload performance during the hours when clients are active.

| Window | Period (Pacific Time) | Policy |
|---|---|---|
| **Production hours** | 6:00 AM – 10:00 PM PT (Mon–Fri) | **No backup jobs.** Veeam jobs must not be scheduled or manually triggered during this window except in a declared P1 emergency with Sai Revanth approval. |
| **After-hours backup window** | 10:00 PM – 6:00 AM PT (nightly) | All jobs run in this window. Primary jobs start at 10 PM; staggered to prevent simultaneous SAN and QNAP contention. |
| **Weekend** | Saturday–Sunday | Standard after-hours schedule applies. Extended active full backup (ActiveFull) jobs may run Saturday 10 PM – Sunday 6 AM if needed for GFS retention. |

**Stagger schedule (prevent simultaneous I/O spikes):**

| Time (PT) | Job |
|---|---|
| 10:00 PM | JOB-PROD-DAILY starts (largest job — production VMs) |
| 10:30 PM | JOB-MGMT-DAILY starts (management VMs — smaller) |
| 11:00 PM | JOB-VDI-DAILY starts (VDI infrastructure — after PROD finishes first VMs) |
| 12:00 AM | Veeam M365 backup starts (Exchange, SharePoint, Teams) |
| 2:00 AM | JOB-REPLICATE-LV starts (replication to Las Vegas — after QNAP writes complete) |
| 4:00 AM | Veeam SPC offsite cloud copy starts |

**Performance monitoring during backup window:** India team night shift monitors ManageEngine OpsManager for SAN latency and Nexus utilization during the backup window. If Nimbus SAN latency exceeds 10ms average during active backup jobs, flag for Sai Revanth review — may indicate job overlap or repository bottleneck.

**Emergency exception:** If a backup job must be run outside the after-hours window (e.g., immediately before a maintenance window), Sai Revanth must approve in the Change Request ticket, and the job must be triggered manually — never by schedule change.

#### 5.2.5 Recovery Point Objectives (RPO) and Recovery Time Objectives (RTO)

| VM Category | RPO | RTO | Method |
|---|---|---|---|
| Critical (domain controllers, vCenter, Veeam) | 24 hours | <1 hour | Instant VM Recovery from QNAP |
| Production VMs (client workloads) | 24 hours | <2 hours | Instant VM Recovery |
| VDI infrastructure | 24 hours | <2 hours | Instant VM Recovery |
| Las Vegas replicated VMs | 24 hours | <4 hours | Failover to Las Vegas replica |
| M365 data (Exchange/Teams/SharePoint) | 24 hours | <4 hours | Veeam M365 item-level restore |

*These RPO/RTO values must be reconciled against client MSA SLAs. If any client SLA requires RPO <24h, escalate to Ravi Jain — additional replication jobs or Veeam CDP may be required.*

---

### 5.3 MANDATORY: Post-Maintenance Veeam Verification Checklist

> **This checklist is mandatory after EVERY maintenance window — including infrastructure, network, power, and hardware changes — not just backup system changes. Network or power changes can silently break Veeam job scheduling, proxy connectivity, and repository access without generating an immediate alert.**

> **Root Cause — April 18, 2026 Incident:** The April 18 DC recabling and network cutover (HSRP migration, C3850 demotion, CloudBrink zero-trust, DNS migration) was completed successfully. However, the post-cutover verification checklist was not performed on Sunday April 19. As a result, Veeam B&R backup jobs were not confirmed in Ready/Success state before the Sunday night backup window. This checklist closes that gap. Any tech who performs or oversees a maintenance window owns this checklist — it is not optional, and it must be completed and attached to the Client Portal maintenance ticket before the ticket is closed.**

#### 5.3.1 Veeam B&R Post-Maintenance Checklist

Open Veeam B&R console (RDP to IRV-PROD-VEEAM01 or via Veeam Enterprise Manager web).

**Step 1 — Verify Backup Infrastructure connectivity:**
- [ ] Home → Backup Infrastructure → Backup Repositories → **QNAP-01-Repo**: Status = **Connected** (green)
- [ ] Home → Backup Infrastructure → Backup Repositories → **QNAP-02-Repo**: Status = **Connected** (green)
- [ ] Home → Backup Infrastructure → Managed Servers → vCenter server: Status = **Connected** (green)
- [ ] Home → Backup Infrastructure → Backup Proxies → all proxies: Status = **Running** (green)

If any component shows **Disconnected** or **Warning**: do NOT proceed — diagnose and resolve before the next backup window.

**Step 2 — Verify all backup jobs are in Ready state:**
- [ ] Home → Jobs → Backup → select each job → confirm **Last Result = Success** (or **None** if never run) AND **Status = Ready** (not Disabled, not Running, not Warning)
- [ ] If any job shows **Warning**: open the job → right-click → Statistics → review last session log → identify and resolve root cause
- [ ] If any job shows **Disabled**: enable and run immediately; document why it was disabled

**Step 3 — Trigger and confirm a test backup run:**
- [ ] Right-click **JOB-MGMT-DAILY** → **Start** (management VMs — fast, low risk)
- [ ] Monitor session in real-time: Home → Last 24 Hours → watch for errors
- [ ] Confirm job completes with **Success** before signing off

**Step 4 — Verify repository capacity:**
- [ ] Home → Backup Infrastructure → Backup Repositories → check **Free Space** column for both QNAP repos
- [ ] If either repo is <20% free: P2 ticket immediately (do not wait for automated alert)

**Step 5 — Verify Veeam ONE monitoring is active:**
- [ ] Open Veeam ONE Monitor → Infrastructure → confirm all vSphere objects visible
- [ ] Veeam ONE → Alarms → confirm no unacknowledged Critical or Warning alarms on backup jobs

**Step 6 — Verify offsite (SPC) replication:**
- [ ] Veeam SPC console → Jobs → confirm last SPC offsite copy job completed successfully
- [ ] If SPC job failed during maintenance window: re-run manually; confirm success before closing ticket

**Sign-off:** Technician completing checklist must enter their name and timestamp in the Client Portal maintenance ticket. If Sai Revanth is not on-site, email sai.revanth@technijian.com with checklist screenshot before closing the ticket.

---

### 5.4 Routine Backup Monitoring (Daily — India Team)

Every morning shift start, India team duty engineer performs:

1. Veeam Enterprise Manager → `https://[EM-IP]:9443` → Dashboard
2. Confirm: **All jobs Success** (green). Any yellow (Warning) or red (Failed) = immediate action:
   - **Warning:** Open Client Portal P2 ticket → investigate session log → resolve before next run
   - **Failed:** Open Client Portal P1 ticket → call Sai Revanth immediately
3. Veeam ONE Monitor → Protected VMs → confirm VM count matches expected count (any VM dropping out of protection = P2 ticket)
4. Record daily status in Client Portal ops log entry (tag: `DC-OPS-DAILY`)

---

### 5.5 Restore Procedures

#### 5.5.1 Instant VM Recovery (fastest — for VM-level failures)

Use when: VM is corrupted, deleted, or fails to boot.

1. Veeam B&R console → Home → Backups → right-click VM → **Instant Recovery → Instant VM Recovery**
2. Select restore point (most recent Success)
3. Select target host and datastore (restore to same or alternate host)
4. Power on recovered VM — it runs directly from backup storage while vMotion copies back to production datastore
5. Once vMotion finishes: confirm VM operational → migrate completed → remove recovery session
6. Open Client Portal P1/P2 ticket documenting: VM name, restore point used, reason, completion time

#### 5.5.2 File-Level Restore (for individual files/folders)

1. Veeam B&R → Backups → right-click VM → **Restore Guest Files → Microsoft Windows** (or Linux)
2. Browse file system to required file → Restore → **Overwrite** (if original exists) or **Keep** (restore alongside)
3. Confirm file restored; close restore session

#### 5.5.3 Full VM Restore (for permanent recovery to production datastore)

Use when: Instant Recovery is not appropriate (e.g., test restore, DR test, storage-side failure).

1. Veeam B&R → Home → Backups → right-click VM → **Restore → Entire VM**
2. Select restore point → restore mode: **Restore to original location** (overwrites) or **Restore to new location** (DR test)
3. Power on → confirm application-level operation (ping, service check, application login test)
4. Document in Client Portal: restore point, elapsed time, any issues

#### 5.5.4 Replication Failover to Las Vegas

Use when: Irvine site is fully unavailable.

1. Veeam B&R console (access via Las Vegas jump host, CloudBrink tunnel to LV) → Home → Replicas
2. Right-click replica VM → **Failover Now** → select latest restore point
3. VM powers on in Las Vegas — client traffic must be rerouted (update DNS or CloudBrink policy to LV site)
4. After Irvine recovery: **Failback** → re-sync changes back to Irvine production VM

---

### 5.6 Veeam Backup for Microsoft 365

#### 5.6.1 Server Details

| Attribute | Detail |
|---|---|
| Veeam M365 Server | IRV-PROD-VEEAMM365 (or co-hosted on VEEAM01) |
| Version | Veeam B365 [version — TBD] |
| M365 tenant | Technijian.com (Microsoft 365 tenant) |
| Backup scope | Exchange Online (all mailboxes), SharePoint Online, Teams, OneDrive for Business |
| Repository | [Local disk or QNAP-02 — TBD] |
| Retention | 1 year item-level |

#### 5.6.2 M365 Daily Check

1. Veeam M365 → Organizations → Technijian → Jobs → confirm all jobs **Success**
2. Confirm mailbox count matches expected (alert if count drops — could indicate license or permissions issue)
3. Warning/Failed → P2 ticket; resolve before next 24h window

#### 5.6.3 M365 Restore — Individual Item

1. Veeam Explorers (Exchange Explorer / SharePoint Explorer / Teams Explorer)
2. Connect to backup repository → browse to user → locate item → Restore
3. Restore to original mailbox/site or export to PST/file for legal hold

---

### 5.7 Veeam Service Provider Console (SPC)

Veeam SPC provides:
- Offsite backup copy to cloud repository (secondary copy of QNAP data)
- Reporting and quota management across all backup jobs
- Client-facing backup reports (if MSP billing model applies)

#### 5.7.1 SPC Daily Check

- SPC console → Alarm Management → review any new alarms
- SPC → Protected Computers → confirm all agents/jobs reporting

#### 5.7.2 SPC Offsite Copy Retention

| Repository | Retention |
|---|---|
| Cloud offsite (SPC) | 30 days daily, 12 months monthly |

Offsite copies run after QNAP jobs complete (typically 3–5 AM PT). Any offsite copy failure = P2 ticket by morning India shift.

---

### 5.8 DR Test Schedule

| Test | Frequency | Method | Owner |
|---|---|---|---|
| Single VM restore (Instant Recovery) | Monthly | Restore non-critical VM to test host; confirm boot; delete | India team + Sai Revanth |
| File-level restore | Monthly | Restore sample file from random VM; confirm content | India team |
| M365 item restore | Monthly | Restore single email to test mailbox | India team |
| Las Vegas failover simulation | Semi-annual | Full replica failover to LV; confirm client access; failback | Sai Revanth + India team |
| Full DR tabletop (Irvine total loss) | Annual | Tabletop exercise — no production impact | Ravi Jain + Sai Revanth |

All DR tests documented in Client Portal with result (Success / Partial / Failed), restore time achieved vs RTO target, and remediation actions if RTO missed.

---

## 6. Monitoring & Alerting

### 6.1 Monitoring Stack Overview

| Tool | Scope | Primary Users |
|---|---|---|
| ManageEngine OpsManager Plus | Network, compute, storage, OS, application health | India team 24×7, Sai Revanth |
| Veeam ONE | Backup job health, protected VM count, capacity forecasting | India team + Sai Revanth |
| Meraki Dashboard | Edge firewall, WAN uplinks, security events | Sai Revanth (India team: read-only) |
| CloudBrink Portal | SDWAN tunnel health, zero-trust access events | Sai Revanth |
| vCenter Alarms | VMware cluster, host, datastore, VM events | India team via vCenter UI |
| Nimbus Data UI | SAN performance, capacity, drive health | India team (daily check) |
| QNAP UI | NAS RAID, drive health, repository capacity | India team (daily check) |

---

### 6.2 ManageEngine OpsManager Plus

#### 6.2.1 Access

| Attribute | Detail |
|---|---|
| URL | `https://[OpsManager-IP]:8443` via CloudBrink |
| Admin login | Sai Revanth — admin account |
| India team login | [OpsTeam role — read + acknowledge alarms, no config changes] |
| SNMP credentials | Stored in credential vault — do NOT store in browser or local files |

#### 6.2.2 Monitored Device Categories

| Category | Devices Monitored | Protocol |
|---|---|---|
| Network | Nexus 3K x2, Catalyst 3850 stack, Meraki MX x2 | SNMP v3 |
| Compute | UCS blades (via CIMC), ESXi hosts | SNMP v3 + VMware API |
| Storage | Nimbus SAN, QNAP NAS x2 | SNMP v3 + API |
| Applications | vCenter, Veeam B&R, Horizon Connection Server | WMI / API |
| Cloud/WAN | CloudBrink gateways | API integration |

#### 6.2.3 Alert Severity and Response Matrix

| Severity | Definition | Response SLA | Escalation |
|---|---|---|---|
| **Critical (P1)** | Service down, data loss risk, security breach, SAN failure, WAN both circuits down | India team: 10 min acknowledge + call Sai Revanth; Sai: 30 min response | Ravi Jain if Sai unreachable within 30 min |
| **Major (P2)** | Degraded performance, single circuit down, RAID degraded, capacity >80%, backup Warning | India team: 30 min acknowledge; open Client Portal ticket; resolve within 4 hours | Sai Revanth if unresolved 4h |
| **Minor (P3)** | Non-critical warnings, performance trending toward threshold | Client Portal ticket within 2 hours; resolve next business day | None |
| **Info** | Informational events, successful completions | Review at shift handoff; no ticket required unless pattern emerges | None |

#### 6.2.4 Alert Configuration — Key Thresholds

**Network:**

| Metric | Warning | Critical |
|---|---|---|
| Interface utilization | >70% for 10 min | >90% for 5 min |
| Interface error rate | >0.1% | >1% |
| HSRP state change | Any | Any (auto P1) |
| Device unreachable | — | 3 consecutive polls |

**Compute:**

| Metric | Warning | Critical |
|---|---|---|
| ESXi host CPU ready | >10% | >20% |
| ESXi host memory balloon/swap | Any balloon | Swap active |
| VM CPU usage | >90% for 15 min | >95% for 5 min |
| ESXi host unreachable | — | 2 consecutive polls |

**Storage:**

| Metric | Warning | Critical |
|---|---|---|
| Nimbus SAN capacity | >75% | >85% |
| Nimbus volume latency | >5ms avg | >15ms avg |
| QNAP RAID state | Degraded | Failed |
| Datastore free space | <25% | <15% |

**Environment:**

| Metric | Warning | Critical |
|---|---|---|
| Cage ambient temperature | >25°C | >30°C |
| UPS battery | <50% charge | <25% charge |
| UPS on battery | >2 min | >5 min |

#### 6.2.5 Alarm Acknowledgement and Closure

1. India team duty engineer monitors OpsManager console at all times during shift
2. New alarm arrives → acknowledge within SLA window (P1: 10 min, P2: 30 min)
3. Open corresponding Client Portal ticket — link OpsManager alarm ID in ticket
4. Resolve root cause → confirm alarm clears in OpsManager → close Client Portal ticket with resolution notes
5. Do NOT close the Client Portal ticket while OpsManager alarm is still active

#### 6.2.6 Shift Handoff Procedure

At each India team shift change (every 8 hours):

- Outgoing engineer: update shift log in Client Portal (tag: `DC-SHIFT-HANDOFF`) with:
  - Active alarms and their status
  - Any ongoing incidents or P1/P2 tickets
  - Any scheduled maintenance in the next 8 hours
  - Backup job status (last completed run + next scheduled)
- Incoming engineer: read handoff log before taking the console

---

### 6.3 Veeam ONE

#### 6.3.1 Access

- **Veeam ONE Monitor:** `\\IRV-PROD-VEEAM01\Veeam ONE Monitor` (Windows app) or web UI `https://[Veeam-ONE-IP]:1239`
- **Veeam ONE Reporter:** `https://[Veeam-ONE-IP]:1340` (web dashboards + scheduled reports)

#### 6.3.2 Key Dashboards

| Dashboard | What to Watch |
|---|---|
| Protected VMs | Count must match expected total; any drop = P2 |
| Backup Job Sessions | Last 24h — all Success (green); no Failed or Warning |
| Repository Capacity | Free space trending; forecast to full date |
| Recovery Verification | VM recovery test results (if SureBackup configured) |

#### 6.3.3 Weekly Veeam ONE Report

Sai Revanth receives automated Veeam ONE Reporter weekly summary every Monday 8 AM PT. Review:
- Any jobs with Warning trends (not yet Failed, but degrading)
- Capacity forecast: if any repo is forecast to fill within 30 days → immediately plan expansion
- Protected VM count: reconcile against vCenter VM inventory

#### 6.3.4 SureBackup (Automated Recovery Verification)

Configure SureBackup jobs to automatically boot VMs from backup in an isolated network and verify:
- VM powers on
- VMware Tools heartbeat active
- [Optional: application test — ping, port test, web test]

SureBackup schedule: weekly, targeting the most recent restore point of each critical VM. Any SureBackup failure = P2 ticket; investigate before next backup cycle runs.

---

### 6.4 Meraki Dashboard Monitoring

#### 6.4.1 Access

- `dashboard.meraki.com` → Technijian organization
- India team: read-only viewer role (no configuration changes)

#### 6.4.2 What India Team Monitors

- **Security → Event Log:** Review for IPS Prevention events (any high-severity = P1)
- **Appliance → Uplinks:** Both ISP circuits green; failover events = P2 ticket
- **Monitor → Summary:** Organization-wide health (if any site shows red = P1)

#### 6.4.3 Automated Meraki Alerts

Meraki sends email alerts to sai.revanth@technijian.com and dc-ops@technijian.com for:
- Uplink failover events
- Rogue AP detection (if applicable)
- IPS high-severity prevention events
- Appliance unreachable

India team: if Meraki alert email arrives during shift → open Client Portal ticket immediately + call Sai Revanth.

---

### 6.5 CloudBrink Portal Monitoring

- CloudBrink portal → Sites → Irvine gateway: must show **Connected / Active**
- CloudBrink portal → Sites → Las Vegas gateway: must show **Connected / Active**
- CloudBrink → Users → confirm no unexpected active sessions (security review: weekly)
- Any gateway showing **Disconnected** = P1 ticket; India team loses management access to DC systems; call Sai Revanth immediately

---

### 6.6 OpsManager Dashboard — India Team Daily Routine

**Beginning of every shift (before doing anything else):**

1. Open OpsManager → Home → Dashboard → review overall health (should be all green)
2. Review Alarms → Active (Critical + Major) — acknowledge any new alarms; open tickets per Clause 2.03
3. Open Veeam Enterprise Manager → confirm all backup jobs Success or Ready
4. Open vCenter → Hosts & Clusters → confirm all hosts Connected, all VMs Powered On
5. Check QNAP UI (both units) → Storage Pools → all Ready
6. Check Nimbus UI → Dashboard → all volumes Online
7. Update Client Portal shift log (tag: `DC-OPS-DAILY`)

**If any item in the above list is not green/healthy:** Do not proceed to other work until the issue is triaged, a Client Portal ticket is opened, and Sai Revanth is notified per the escalation matrix.

---

### 6.7 Monthly Baseline Snapshot

On the first Monday of every month, Sai Revanth exports and archives:

- ManageEngine OpsManager performance reports (CPU, memory, storage, network utilization) for all devices
- Veeam ONE capacity report + job success rates
- Meraki traffic and security summary
- Nimbus performance snapshot

Archive location: Client Portal → Documents → Technijian Internal → DC Monthly Reports → [YYYY-MM].

These baselines are used to detect performance drift, capacity trends, and to support root cause analysis when incidents occur.

---

## 7. Incident Response

### 7.1 Incident Classification

| Priority | Definition | Examples |
|---|---|---|
| **P1 — Critical** | Production service down, data loss active or imminent, security breach, complete site failure | All VMs down, SAN offline, both WAN circuits down, ransomware detected, Veeam backup failure day-of-recovery |
| **P2 — Major** | Degraded service, single component failure, capacity breach, backup Warning | Single ESXi host down (HA active), RAID degraded, one WAN circuit down, backup Warning |
| **P3 — Minor** | Non-critical degradation, trend toward threshold, single non-essential VM down | Dev VM offline, minor latency increase, monitoring agent gap |

---

### 7.2 Incident Response Workflow

#### 7.2.1 Detect

- ManageEngine OpsManager alert fires → India team duty engineer sees alert within the SLA window
- Or: client reports issue to Client Portal helpdesk ticket
- Or: Veeam ONE / Meraki email alert arrives

#### 7.2.2 Triage (within 10 min for P1, 30 min for P2)

1. Acknowledge alarm in OpsManager
2. Open Client Portal ticket: Priority P1/P2/P3 → assign to DC-OPS queue
3. Determine blast radius: which services / clients are affected?
4. Determine root cause category: network, compute, storage, backup, application, facility, security

#### 7.2.3 Escalate

| Condition | Action |
|---|---|
| P1 at any time | India team duty engineer → call Sai Revanth mobile immediately |
| Sai Revanth unreachable after 2 attempts | India team → call Ravi Jain (rjain@technijian.com / mobile) |
| Security incident (breach, ransomware) | Sai Revanth + Ravi Jain simultaneously; isolate affected systems immediately |
| Physical facility issue (power, cooling) | TPX NOC (Irvine or LV) + Sai Revanth |
| Vendor hardware failure needing dispatch | Open Cisco TAC / Nimbus / Veeam case; CC sai.revanth@technijian.com |

#### 7.2.4 Contain and Recover

See the playbooks in Clauses 3–8 for specific incident types.

#### 7.2.5 Document and Close

All incidents must be closed with:
- Root cause identified (5-why or equivalent)
- Timeline of events (detect → triage → contain → restore → close)
- Client communications sent (if client-impacting)
- Post-incident actions (what will be changed to prevent recurrence)
- Client Portal ticket updated and closed; OpsManager alarm confirmed cleared

---

### 7.3 Playbook: Complete VM Outage (Multiple VMs Down)

**Likely causes:** ESXi host failure (HA active), Nimbus SAN disconnect, network VLAN down.

1. vCenter → Events → check for HA events in last 15 minutes
2. If HA events: VMs are restarting on surviving hosts — wait up to 10 minutes for HA to complete; monitor
3. If HA not triggering: check affected hosts — are they Connected in vCenter? If not: CIMC (management VLAN) → check server power, POST, blade health
4. Check Nimbus SAN: volumes Online? If SAN disconnected → VMs cannot power on → restore SAN connectivity first
5. Check VLAN 5 (storage) on Nexus: is SVI up? Is HSRP active? (`show standby brief`)
6. Once root cause resolved: confirm VMs restart; check Veeam backup jobs still scheduled (do not skip post-recovery Veeam check)
7. P1 ticket — update every 30 minutes with status until closed

---

### 7.4 Playbook: Complete Network Outage (All Sites)

**Likely causes:** Meraki WAN both circuits failed, CloudBrink gateway down, Nexus core failure.

1. India team loses CloudBrink access → immediately call Sai Revanth mobile
2. Sai Revanth: physical access to TPX Irvine or console access via TPX remote hands
3. Check Meraki dashboard (Meraki has out-of-band cellular management — `dashboard.meraki.com` from mobile network)
4. If both ISP circuits down: contact primary ISP NOC (circuit ID from cage binder); contact secondary ISP NOC
5. If Nexus core failure: physical console to Nexus-01; restore from saved running-config on QNAP
6. Client communication: P1 client email/call within 30 minutes of detecting client impact

---

### 7.5 Playbook: Veeam Backup Failure (No Successful Backup)

**Trigger:** Morning India team check finds backup job Failed or no successful run in >26 hours.

1. Open Veeam B&R console → job → Statistics → review session log for error codes
2. Common causes and actions:

| Error | Likely Cause | Action |
|---|---|---|
| Repository unreachable | QNAP offline or VLAN 6 down | Check QNAP power + network; rescan repository |
| Proxy communication error | Veeam proxy VM offline | Power on IRV-PROD-VEEAM01 or proxy VM in vCenter |
| vCenter communication error | vCenter offline or credentials expired | Restore vCenter or renew credentials in Veeam |
| Snapshot commit failed | Datastore full or VM has stale snapshot | Free datastore space; remove stuck snapshots |
| Network timeout | VLAN 6 congestion or MTU mismatch | Check OpsManager VLAN 6 utilization; verify MTU |

3. Resolve root cause → right-click failed job → **Retry** or **Start** (active full if retry fails)
4. Monitor job to completion; confirm **Success** in job statistics
5. P1 Client Portal ticket; Sai Revanth must sign off on closure

> **Non-negotiable rule:** If backup jobs have not run successfully in >26 hours, this is a P1 incident regardless of time of day. Do not wait for the next shift or next morning. Call Sai Revanth.

---

### 7.6 Playbook: Security Incident (Ransomware / Breach Suspected)

**Triggers:** Unusual encryption activity on file shares, OpsManager anomaly alert, AV/EDR alert, Meraki IPS Prevention event on internal traffic.

**Immediate actions (first 15 minutes) — India team duty engineer:**

1. **Do NOT power off or reboot affected VMs without authorization** — forensic evidence may be lost
2. Call Sai Revanth immediately (do not wait to confirm)
3. If ransomware confirmed or strongly suspected: **network isolate** affected VMs in vCenter → right-click VM → Edit Settings → disconnect all NICs (do not delete VMs)
4. Open P1 Client Portal ticket tagged `SECURITY-INCIDENT`
5. Notify Ravi Jain (rjain@technijian.com) simultaneously

**Sai Revanth actions:**
1. Assess blast radius: which VMs, which VLANs, which clients affected
2. Engage Veeam for restore from last known-clean restore point
3. Engage Cisco TAC if Nexus/Meraki forensic log extraction needed
4. Document all actions with timestamps (required for potential legal/insurance proceedings)
5. If client data potentially exfiltrated: Ravi Jain must be notified within 1 hour for client disclosure decision

---

### 7.7 Playbook: Las Vegas Failover

**Trigger:** Irvine facility confirmed unavailable (not recovering within RTO window).

1. Sai Revanth confirms Irvine unrecoverable within expected RTO
2. Ravi Jain authorizes Las Vegas failover (written confirmation in Client Portal P1 ticket)
3. Sai Revanth: Veeam B&R on Las Vegas → Replicas → Failover to Las Vegas replicas
4. Update CloudBrink policy: route client traffic to Las Vegas site
5. Update DNS if applicable (Las Vegas IPs for client-facing services)
6. Confirm client VDI (Horizon) accessible from Las Vegas if VDI replicas are configured
7. Notify affected clients: estimated service restoration, Las Vegas performance profile (older hardware)
8. Begin Irvine recovery in parallel; plan failback when Irvine is ready

---

### 7.8 Playbook: ESXi Host Hardware Failure

1. vCenter shows host Disconnected or Not Responding → CIMC console (VLAN 99) → check POST
2. If hardware failure confirmed (memory, CPU, I/O card): open Cisco TAC case immediately
3. vSphere HA should have already restarted affected VMs on surviving hosts — verify in vCenter Events
4. Confirm VMs are running on surviving hosts; no data loss (HA restart does not trigger backup)
5. Run emergency Veeam backup of all VMs that failed over to surviving hosts (right-click job → Active Full)
6. Engage Cisco for blade replacement; service profile re-association via UCS Manager upon new blade install
7. Post-replacement: trigger Veeam active full backup to capture clean baseline

---

### 7.9 Incident Communication Templates

### Client Impact P1 — Initial Notification (send within 30 min of confirmed client impact)

```
Subject: [Technijian] Service Impact Notice — [Date] [HH:MM PT]

We are currently investigating a service issue affecting [service description].
Our team identified the issue at [HH:MM PT] and is actively working to restore service.

Impact: [describe client-visible impact]
Current status: Investigating / Restoring
Next update: [HH:MM PT] or sooner if status changes

We apologize for the inconvenience and will keep you updated.

Sai Revanth | Technijian Datacenter Operations
```

### Client Impact P1 — Resolution Notification

```
Subject: [Technijian] Service Restored — [Date] [HH:MM PT]

Service has been fully restored as of [HH:MM PT].

Root cause: [brief description]
Duration: [HH:MM] to [HH:MM PT] ([X] minutes)
Remediation: [what was fixed and what steps are being taken to prevent recurrence]

A detailed post-incident report will be provided within [48/72] hours.

Sai Revanth | Technijian Datacenter Operations
```

---

## 8. Routine Operations

### 8.1 Daily Operations (India Team — Every Shift Start)

Complete within the first 30 minutes of every shift. Log results in Client Portal (tag: `DC-OPS-DAILY`).

#### 8.1.1 Network

- [ ] OpsManager → Nexus 3K #1 and #2: both **Reachable**, no Critical alarms
- [ ] OpsManager → Catalyst 3850 stack: **Reachable**
- [ ] OpsManager → Meraki MX (Irvine + Las Vegas): both **Reachable**, both WAN uplinks **Active**
- [ ] CloudBrink portal → both site gateways: **Connected / Active**
- [ ] HSRP state: Nexus-01 Active on all VLANs (check `show standby brief` if any doubt — SSH via CloudBrink)

#### 8.1.2 Compute & Virtualization

- [ ] vCenter → all ESXi hosts: **Connected** (green health indicator)
- [ ] vCenter → all production VMs: **Powered On** (review against last-known inventory)
- [ ] vCenter → Recent Tasks: no failed tasks in last 8 hours
- [ ] UCS Manager → Equipment → all blades: **Operability = Operable**, no Critical/Major faults
- [ ] Omnissa Horizon → all Connection Servers: **green** dashboard
- [ ] Horizon → Desktop Pools: no pools in **Error** state
- [ ] Horizon → Sessions: no disconnected sessions older than 8 hours (disconnect stale sessions)

#### 8.1.3 Storage

- [ ] Nimbus SAN → Dashboard: all volumes **Online**, utilization <75%, no rebuild in progress
- [ ] QNAP-01 UI → Storage Pools: **Ready**, no degraded drives
- [ ] QNAP-02 UI → Storage Pools: **Ready**, no degraded drives
- [ ] vCenter → Storage → Datastores: all datastores **Mounted**, none >80% full

#### 8.1.4 Backup

- [ ] Veeam Enterprise Manager → all backup jobs: **Last Result = Success**
- [ ] Veeam B&R console → Backup Infrastructure → Repositories: both QNAP repos **Connected**
- [ ] Veeam M365 → all jobs: **Success**
- [ ] Veeam ONE → Protected VMs: count matches expected total

#### 8.1.5 Alarms

- [ ] OpsManager → Active Alarms: all Critical and Major alarms reviewed; tickets open for each
- [ ] vCenter → Alarms → Active: review and ticket any new hardware or performance alarms

#### 8.1.6 Shift Log

- [ ] Client Portal shift log entry created (tag: `DC-OPS-DAILY`) with:
  - All green/healthy items confirmed
  - Any yellow/red items and their ticket numbers
  - Any ongoing incidents with current status
  - Scheduled maintenance for next 24 hours

---

### 8.2 Weekly Operations (Sai Revanth — Every Monday)

#### 8.2.1 Network

- [ ] Nexus: `show interface status` — confirm all active ports in expected state
- [ ] Nexus: `show spanning-tree summary` — confirm Nexus-01 is root, no topology changes incrementing
- [ ] Nexus: `show interface counters errors` — review and clear; any interface with >0.1% error rate = P2 investigate
- [ ] Catalyst 3850: `show switch` — confirm both stack members Ready, ring speed nominal
- [ ] Network config backup: `copy run tftp://[QNAP-IP]/network-configs/[hostname]-[date].cfg` for all four switches
- [ ] CloudBrink: review access logs — any unexpected sessions or failed authentications?
- [ ] Meraki: review Event Log — any IPS prevention events, failed VPN events?

#### 8.2.2 Compute

- [ ] UCS Manager → Faults tab → Critical/Major: review and action any open faults
- [ ] UCS Manager → Policies → Firmware: confirm all blades at approved firmware (no drift)
- [ ] vCenter: `Host → Monitor → Storage → Storage Usage` — confirm all datastores >25% free
- [ ] vCenter: `Host → Monitor → Performance` — review any hosts with consistently high CPU ready (>10%) or memory balloon
- [ ] vCenter: `VM → Filter → Snapshots older than 72h` — delete any old snapshots (should be zero)
- [ ] Horizon: review application provisioning events — any AppVolumes errors?

#### 8.2.3 Storage

- [ ] Nimbus: export weekly health report; review and archive in Client Portal
- [ ] Nimbus: review capacity trend — at current growth rate, when will array hit 80%?
- [ ] QNAP-01: S.M.A.R.T. disk health → Storage & Snapshots → HDD S.M.A.R.T. → review all drives
- [ ] QNAP-02: S.M.A.R.T. disk health — same procedure
- [ ] Veeam: review repository capacity in Veeam ONE Reporter → forecast date to full

#### 8.2.4 Backup

- [ ] Veeam ONE Reporter: weekly job success rate report → review; any job with <100% success rate over 7 days = P2 investigate
- [ ] SureBackup: confirm weekly verification jobs completed (Veeam B&R → Jobs → SureBackup)
- [ ] Veeam SPC: offsite copy jobs — all Success; capacity within quota
- [ ] Veeam M365: confirm all mailboxes and sites protected; no new exclusions

#### 8.2.5 Security

- [ ] CloudBrink: audit user list — any former techs still active? Revoke immediately
- [ ] Review OpsManager failed login attempts (if auditing enabled on network devices)
- [ ] Meraki: confirm IPS signatures up to date (Security → IDS/IPS → Last Updated)

#### 8.2.6 Documentation

- [ ] Update blade inventory if any change occurred
- [ ] Confirm cage binder physical copy matches current network diagram
- [ ] Any new VMs deployed this week? Add to Client Portal asset inventory

---

### 8.3 Monthly Operations (Sai Revanth — First Monday of Month)

#### 8.3.1 DR and Recovery Testing

- [ ] Restore test: Instant VM Recovery of one non-critical VM → confirm boot → confirm application heartbeat → delete recovery session
- [ ] File-level restore test: select random VM → restore sample file → confirm contents → clean up
- [ ] M365 restore test: restore single email item to test mailbox → confirm → clean up
- [ ] Document test results in Client Portal: VM tested, restore point used, elapsed time vs RTO target

#### 8.3.2 Capacity Planning

- [ ] Export ManageEngine OpsManager capacity report (CPU, memory, storage, network) for all devices
- [ ] Veeam ONE Reporter: monthly backup capacity report
- [ ] Nimbus: project growth — at current rate, months to 80% capacity?
- [ ] QNAP: project growth — months to 80% repository capacity?
- [ ] If any component forecast to breach threshold within 90 days: open planning ticket with Ravi Jain

#### 8.3.3 Firmware and Patch Review

- [ ] Nimbus SAN: check for available firmware updates (Nimbus support portal)
- [ ] QNAP: QTS firmware — check for updates (QNAP UI → Control Panel → Firmware Update)
- [ ] VMware: ESXi/vCenter patch level — check VMware Security Advisories (vmware.com/security/advisories)
- [ ] Cisco UCS: UCSM firmware — check Cisco Security Advisories (tools.cisco.com/security/center)
- [ ] Veeam: check for updates (Veeam B&R → Help → Check for Updates)
- [ ] All critical/high security patches: schedule in Change Request within 30 days; document if deferring

#### 8.3.4 Access Review

- [ ] CloudBrink user list: review against current India team roster — remove departed staff
- [ ] vCenter user list: confirm all user accounts match current team; no orphan accounts
- [ ] UCS Manager: confirm service account credentials not expired
- [ ] QNAP: review SMB share access list
- [ ] Client Portal: confirm India team ticket permissions are correct

#### 8.3.5 Baseline Documentation

- [ ] Export OpsManager performance reports → archive to Client Portal → DC Monthly Reports → [YYYY-MM]
- [ ] Photograph rack layout (Irvine + Las Vegas remote hands) if any physical change occurred this month
- [ ] Update IP address allocation sheet if any new device added

#### 8.3.6 License and Support Contract Review

| Item | Review Frequency | Owner |
|---|---|---|
| VMware vSphere / vCenter | Annual (check monthly for expiry warning) | Sai Revanth |
| Veeam licenses (B&R, M365, ONE, SPC) | Annual | Sai Revanth |
| ManageEngine OpsManager | Annual | Sai Revanth |
| Cisco UCS SmartNet | Annual | Sai Revanth |
| Nimbus Data support contract | Annual | Ravi Jain |
| Omnissa Horizon | Annual | Sai Revanth |
| CloudBrink subscription | Annual | Ravi Jain |

Any license or support contract expiring within 60 days: notify Ravi Jain immediately for renewal authorization.

---

### 8.4 Quarterly Operations (Sai Revanth + Ravi Jain — Every Quarter)

- [ ] Review and update all runbook sections — are procedures still accurate? Any gaps from incidents?
- [ ] UPS battery test (Irvine + Las Vegas): coordinate with TPX; confirm UPS runtime at full load
- [ ] Full DR tabletop exercise (semi-annual for Las Vegas failover test; quarterly tabletop discussion)
- [ ] Review SLA performance against client MSAs — any missed RTO/RPO? Corrective actions?
- [ ] Review India team certifications and training: any skill gaps?
- [ ] Confirm emergency contact list is current (TPX NOC numbers, vendor support numbers)
- [ ] Physical cage inspection: cable management, labeling, no unauthorized equipment

---

## 9. Change Management

### 9.1 Change Management Principles

Every change to production infrastructure — network, compute, storage, backup, or facility — requires a documented Change Request ticket in Client Portal before execution. No verbal approvals. No undocumented changes.

> **Root Cause — April 18, 2026 Incident:** The April 18 DC recabling was a properly planned change. The gap was in the post-change verification step — the Veeam backup job health check was not completed after the network cutover. This section mandates that the post-change verification checklist (Section 1, Clause 7.00; Section 5, Clause 3.01) is always part of every Change Request, and its completion is a mandatory prerequisite to closing the ticket.

---

### 9.2 Change Categories

| Category | Definition | Examples | Notice Required |
|---|---|---|---|
| **Standard** | Pre-approved, low-risk, well-understood, reversible | Firmware patch per approved matrix, adding a VM, Veeam job config tweak | 72 hours |
| **Normal** | Planned, moderate risk, requires review and approval | Network VLAN changes, ESXi host maintenance, new storage volume, Horizon pool changes | 72 hours |
| **Major** | High risk, significant blast radius, architectural change | Core switch replacement, SAN migration, vCenter upgrade, CloudBrink reconfiguration | 2 weeks |
| **Emergency** | P1 incident response — no time for standard process | Ransomware containment, failed switch replacement mid-outage | Post-hoc within 2 hours |

---

### 9.3 Change Request Ticket — Required Fields

All Change Request tickets in Client Portal must include:

| Field | Requirement |
|---|---|
| Title | Concise, descriptive (e.g., "Nexus 3K firmware upgrade — Irvine") |
| Category | Standard / Normal / Major / Emergency |
| Change window | Date + start time + end time (PT) |
| Systems affected | All devices, VMs, services impacted |
| Client impact | Yes/No; if Yes — which clients, estimated impact duration |
| Description of change | Step-by-step implementation plan |
| Rollback plan | Specific steps to undo the change; time to rollback |
| Config backup confirmation | Confirmation that running-config saved before change |
| Approvers | Sai Revanth (required) + Ravi Jain (required for Major/Emergency) |
| Post-change verification | Link to applicable checklist; who will complete it and by when |
| Communication plan | Which clients notified; how (email, Client Portal, phone) |

---

### 9.4 Approval Matrix

| Change Category | Approver(s) Required | Min. Advance Notice |
|---|---|---|
| Standard | Sai Revanth | 72 hours |
| Normal | Sai Revanth + Ravi Jain | 72 hours |
| Major | Sai Revanth + Ravi Jain (written approval in ticket) | 2 weeks |
| Emergency | Ravi Jain verbal + ticket within 2 hours post-change | N/A |

India team: do NOT execute any change without seeing Sai Revanth's approval noted in the ticket. If instructed verbally, ask the requestor to add approval in the ticket before proceeding.

---

### 9.5 Standard Change Window

| Window | Time | Purpose |
|---|---|---|
| Primary maintenance window | Saturday 10:00 PM – Sunday 4:00 AM PT | All planned infrastructure changes |
| Secondary window (if needed) | Thursday 10:00 PM – Friday 2:00 AM PT | Overflow; requires Ravi Jain approval |
| Client freeze periods | As announced (e.g., quarter-end, major client go-live) | No changes; announce at least 1 week in advance |

---

### 9.6 Change Execution Procedure

### Before the Change Window

1. Change Request ticket approved by all required approvers
2. Rollback plan documented and reviewed — can it be executed within the maintenance window if needed?
3. Config backup saved: all affected network devices → QNAP NAS `\network-configs\`
4. VM snapshots taken for all VMs that could be affected (delete within 72h after confirmed stable)
5. Client notification sent if client impact expected (use template in Section 7)
6. India team briefed on the change and their role

### During the Change Window

1. Sai Revanth (or designated lead) executes change per documented steps
2. India team monitors OpsManager for unexpected alerts throughout
3. After each major step: confirm intermediate state before proceeding to next step
4. If unexpected issue arises: pause → assess → call Sai Revanth if India team is executing → decide: continue or rollback
5. **Decision to rollback:** If the change cannot be completed and stabilized before the maintenance window end time, execute rollback. Do not extend the window without Ravi Jain approval.

### After the Change Window

1. Complete the mandatory post-change verification checklist:
   - [ ] Network: HSRP state, all SVIs up, Meraki uplinks green, CloudBrink tunnel active
   - [ ] Compute: all ESXi hosts Connected, all VMs Powered On, no HA events
   - [ ] Storage: Nimbus volumes Online, QNAP repos Connected in Veeam
   - [ ] Backup: **all Veeam B&R jobs in Ready/Success state** (Clause 3.01, Section 5)
   - [ ] Monitoring: OpsManager no new Critical alarms, Veeam ONE protected VM count unchanged
2. Delete VM snapshots taken before the change (confirm stable first — wait minimum 24 hours)
3. Update Client Portal ticket with completion summary, including checklist completion timestamp
4. Send client resolution notification if client impact occurred
5. Sai Revanth signs off on ticket closure

---

### 9.7 Client Communication Templates

### Planned Maintenance Notification (send 48+ hours before)

```
Subject: [Technijian] Planned Maintenance Notice — [Date] [HH:MM]–[HH:MM] PT

Dear [Client Name],

We will be performing scheduled infrastructure maintenance on [Day, Date] between
[HH:MM] and [HH:MM] PT.

Impact: [Describe expected impact — e.g., "Brief interruption to VDI sessions
(up to 15 minutes) while we complete the maintenance. Sessions will resume
automatically."]

To minimize disruption, please save all open work before [HH:MM] PT.

For questions, contact dc-ops@technijian.com or open a ticket in the Client Portal.

Sai Revanth | Technijian Datacenter Operations
```

### No-Impact Notice (for changes with zero expected client impact)

No client notification required. Internal ticket only.

### Emergency Change — Post-hoc Client Notification

Use the incident resolution template from Section 7.

---

### 9.8 Configuration Backup Policy

All infrastructure configuration must be backed up before every change and on a weekly schedule (weekly backup automated via ManageEngine OpsManager config backup module or manual script):

| Device | Backup Method | Destination | Retention |
|---|---|---|---|
| Nexus 3K #1/2 | `copy run tftp://[QNAP-IP]/network-configs/` | QNAP-01 `\network-configs\` | 90 days |
| Catalyst 3850 | `copy run tftp://[QNAP-IP]/network-configs/` | QNAP-01 `\network-configs\` | 90 days |
| Meraki | Automatic (Meraki cloud stores 30 versions) | Meraki Dashboard | 30 versions |
| UCS Manager | Backup via UCS Manager → Admin → All Config | QNAP-01 `\ucs-configs\` | 90 days |
| vCenter | VCSA backup (VAMI → Backup) | QNAP-01 `\vcenter-configs\` | 14 days |
| Veeam B&R config | Veeam Config Backup job | QNAP-01 `\veeam-configs\` | 14 days |

File naming convention: `[hostname]-[YYYY-MM-DD]-[pre|post]-[change-ticket-ID].cfg`

---

### 9.9 Post-Incident Change Review

After any P1 incident caused by a change (or change-related omission), a post-incident review is mandatory:

| Timeline | Action |
|---|---|
| Within 24 hours | Initial incident report in Client Portal |
| Within 48 hours | Root cause analysis (5-why) documented |
| Within 72 hours | Corrective and preventive actions defined |
| Within 2 weeks | Corrective actions implemented and verified |
| Next quarterly review | Runbook updated if process gap identified |

> The April 18, 2026 incident corrective action: mandatory post-maintenance Veeam verification checklist added to this runbook (Section 5, Clause 3.01) and embedded in this Change Management section. All DC team members read and acknowledged this runbook before next maintenance window.

---

## 10. Access Control & Security

### 10.1 Access Control Principles

1. **Least privilege:** Every person has the minimum access required to perform their role — nothing more.
2. **Zero trust:** No implicit trust based on network location. All access goes through CloudBrink zero-trust; credentials + device posture are verified for every session.
3. **Just-in-time access:** Elevated access (e.g., vCenter administrator) is granted for a specific task window and reviewed after.
4. **No shared accounts:** Every person has a named individual account. No generic `admin` or shared team accounts used for production access.
5. **MFA everywhere:** All access to DC systems requires MFA enforced by Microsoft 365 SSO or CloudBrink.

---

### 10.2 Access Roles

#### 10.2.1 Physical Access

| Person | Sites | Access Type |
|---|---|---|
| Sai Revanth | Irvine + Las Vegas | Unescorted — full cage access |
| Ravi Jain | Irvine + Las Vegas | Unescorted — full cage access |
| India team | None | Remote only (CloudBrink); no physical |
| Cisco TAC / vendor | Irvine + Las Vegas | Escorted only; pre-authorized per visit |
| TPX staff | Cage perimeter | Remote hands only when requested |

#### 10.2.2 System Access Roles

| System | Sai Revanth | India Team | Ravi Jain |
|---|---|---|---|
| CloudBrink console | Full admin | Tunnel access only (no console) | Read-only |
| vCenter | administrator@vsphere.local | VM-Operator role (power on/off, snapshots, view) | None |
| UCS Manager | Full admin | None | None |
| Nimbus SAN | Full admin | Dashboard read-only | None |
| QNAP NAS | Full admin | Dashboard read-only | None |
| Veeam B&R | Full admin | Restore Operator role | None |
| Veeam ONE | Full admin | Read-only viewer | None |
| Meraki dashboard | Full admin | Read-only viewer | Read-only |
| ManageEngine OpsManager | Full admin | Operator (acknowledge alarms, view) | Read-only |
| Client Portal (DC tickets) | DC Admin | DC Operator | Director |

#### 10.2.3 Emergency Break-Glass Account

A single emergency break-glass administrator account exists for each system (e.g., vCenter `break-glass@vsphere.local`). This account:
- Has full administrator rights
- Password stored in physical sealed envelope in Irvine cage binder AND in Technijian credential vault
- Use only when all named admin accounts are inaccessible
- Any use of break-glass account triggers mandatory P1 Client Portal ticket + notification to Ravi Jain within 1 hour
- Password rotated after every use

---

### 10.3 CloudBrink Zero-Trust Access Management

All remote access to DC systems flows through CloudBrink. No legacy VPN. No direct RDP/SSH to production IPs.

#### 10.3.1 Provisioning New Access

When a new India tech joins the DC rotation:

1. Sai Revanth creates named user in CloudBrink (linked to M365 SSO)
2. Assigns to appropriate CloudBrink group (`DC-OPS-INDIA` for standard India team)
3. Grants vCenter VM-Operator role (vCenter → Administration → Users and Groups)
4. Grants Veeam Restore Operator role (Veeam B&R → Users and Roles)
5. Grants OpsManager Operator role
6. Sends agent install link; confirms tunnel established and test login to each system
7. Opens Client Portal ticket documenting provisioning, signed off by Sai Revanth

#### 10.3.2 Revoking Access (Separation or Role Change)

When a tech leaves or changes role:

1. **Immediately** disable CloudBrink user account (kills active tunnel within seconds)
2. Remove from vCenter user list
3. Remove from Veeam B&R roles
4. Remove from OpsManager
5. Remove from Meraki viewer role
6. Disable M365 account (IT team action)
7. Client Portal ticket documenting all revocations, signed off by Sai Revanth
8. Monthly access review will verify completion

> Revocation must happen on or before the last day of employment. India team manager notifies Sai Revanth at least 24 hours before a tech's last day.

---

### 10.4 Credential Management

#### 10.4.1 Credential Vault

All DC system credentials are stored in the Technijian credential vault (vault location and access per [Vault Policy — TBD]). Rules:
- No credentials stored in browser saved passwords
- No credentials in email, Slack, Teams, or any messaging tool
- No credentials in scripts committed to any repository
- Service account passwords: minimum 16 characters, rotated every 90 days
- Admin account passwords: minimum 20 characters, rotated every 60 days

#### 10.4.2 SNMP Security

All SNMP uses SNMPv3 with authentication (SHA-256) and encryption (AES-128). SNMPv1/v2c is disabled on all devices. SNMP community strings are not used.

#### 10.4.3 SSH Security

All network device SSH access:
- SSH version 2 only; SSHv1 disabled
- Key-based authentication preferred over password
- Access permitted only from CloudBrink tunnel source IPs (not from public internet)
- Login banner: configured on all Cisco devices per company policy

---

### 10.5 Security Baseline — Network Devices

All Cisco network devices (Nexus, Catalyst) must maintain:

- [ ] No default credentials (all `admin`/`cisco` default passwords changed at deployment)
- [ ] Unused ports: `shutdown` — no active unused ports
- [ ] Management access only via VLAN 99 (not from production VLANs)
- [ ] SSH access restricted to CloudBrink tunnel source (ACL on VTY lines)
- [ ] SNMP v3 only; community strings removed
- [ ] Login banner configured: "Authorized access only. All sessions logged."
- [ ] NTP synchronized to Technijian NTP source (verify `show ntp status`)
- [ ] Syslog forwarded to ManageEngine OpsManager
- [ ] No IP HTTP server enabled (`no ip http server`, `no ip http secure-server` unless explicitly needed)

Verify compliance: monthly during Sai Revanth's weekly check, and after every network change.

---

### 10.6 Security Monitoring

#### 10.6.1 Log Collection

All security-relevant logs forwarded to ManageEngine OpsManager:

| Source | Log Type | Retention in OpsManager |
|---|---|---|
| Nexus 3K / Catalyst 3850 | Syslog (auth, config changes, interface events) | 90 days |
| Meraki MX | Security events, IPS alerts, traffic logs | 90 days |
| ESXi hosts | Authentication events, VM config changes | 90 days |
| vCenter | Admin actions, login events, alarm events | 90 days |
| Veeam B&R | Job events, repository access, restore operations | 90 days |
| CloudBrink | User authentication, session events, policy hits | 90 days |

#### 10.6.2 Security Alert Response

| Alert | Response |
|---|---|
| Failed login attempt >5 in 10 min (any system) | P2 ticket; check source IP; block in CloudBrink or Meraki if external |
| Meraki IPS Prevention event (high severity) | P1 ticket; Sai Revanth + Ravi Jain; isolate if internal source |
| Unauthorized CloudBrink session | P1 ticket; revoke user; investigate |
| Config change on network device (no Change Request) | P1 ticket; identify who; rollback if unauthorized |
| Unusual Veeam activity (unexpected restore, export) | P2 ticket; Sai Revanth reviews; escalate if unauthorized |

#### 10.6.3 Meraki IDS/IPS

- Mode: **Prevention** (blocks, not just detects)
- Signature updates: automatic (Meraki cloud-managed); verify last update in Dashboard weekly
- Sensitivity: Connectivity-optimized (balance between security and false positives)
- Any Prevention event on internal-to-internal traffic = P1; could indicate lateral movement

---

### 10.7 Acceptable Use — India Team

India team members access DC systems exclusively for authorized operational tasks. The following are prohibited and will result in immediate access revocation and disciplinary action:

- Accessing DC systems outside assigned shift without prior authorization from Sai Revanth
- Downloading or exporting client VM data, backups, or credentials
- Making configuration changes without an approved Change Request ticket
- Sharing credentials or CloudBrink agent installation with any unauthorized person
- Accessing client VMs beyond what is needed to resolve the assigned ticket
- Using DC access for any personal purpose

---

### 10.8 Annual Security Review

Each year, Ravi Jain and Sai Revanth conduct a formal review:

- [ ] All access roles reviewed against current team roster
- [ ] All service account passwords rotated
- [ ] Break-glass password rotated and envelope re-sealed
- [ ] Credential vault access list reviewed
- [ ] Network security baseline compliance confirmed
- [ ] Review of all P1/P2 security incidents from the past year
- [ ] Penetration test or vulnerability scan (coordinate with Technijian security team or external vendor)
- [ ] Update this section to reflect any policy or technology changes