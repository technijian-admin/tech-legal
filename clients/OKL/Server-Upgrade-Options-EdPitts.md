# Server Upgrade Options — Oaktree Law

**Prepared for:** Ed Pitts, Oaktree Law
**Prepared by:** Technijian
**Date:** April 15, 2026
**Re:** Replacement of current Dell server (Service Tag 2KPZZV2)

---

## 1. Executive Summary

Your current Dell PowerEdge server (service tag **2KPZZV2**) is a 14th-generation platform that has been in service for several years and is approaching end-of-life for warranty, performance, and security patching. In place of the previously discussed cloud migration, we are proposing a **hardware refresh** to a newer-generation Dell PowerEdge server sourced through the **Dell Outlet** program (certified refurbished, full Dell warranty included).

This report presents **three server candidates** from Dell Outlet, all of which:

- Equal or exceed the storage capacity of your current server
- Use modern Intel Xeon Scalable CPUs (2x sockets instead of your current single socket)
- Include Dell's 3-Year Basic Hardware Warranty with Next Business Day onsite service
- Have dual redundant power supplies (matching your current setup)

We have a clear recommendation (**Option A — PowerEdge R760**) but include two alternatives so you can weigh performance, capacity, and budget tradeoffs.

---

## 2. Your Current Server — Baseline Specs

Decoded from the Dell bill of materials for service tag 2KPZZV2:

| Component | Current Configuration |
|-----------|----------------------|
| Model | Dell PowerEdge (14th Generation — T440/R440 class) |
| CPU | 1x Intel Xeon Scalable processor (single socket populated) |
| Memory | 32 GB DDR4-2666 RDIMM (2x 16 GB, dual rank) |
| Storage | 2x hard drives in RAID 1 |
| Usable data | ~900 GB in use (119 GB OS + 779 GB shared folders) |
| Power | Redundant 1+1 power supplies |
| Operating System | Windows Server 2019 Standard + CALs |
| Management | iDRAC9 Express |
| Optical | DVD±RW drive |

**Why upgrade now:**

- 14th-gen PowerEdge platforms are in the later portion of their support lifecycle
- DDR4-2666 memory is two generations behind current DDR5 speeds
- Single-socket configuration limits CPU performance for virtualization and future growth
- Warranty status should be verified — many 2KPZZV2-era servers are out of or near end-of-warranty
- Microsoft ends mainstream support for Windows Server 2019 in January 2029, making this a logical moment to modernize both hardware and OS

---

## 3. Recommended Server Options

### Option A (Recommended): Dell PowerEdge R760 — Balanced Upgrade

**Dell Outlet SKU:** `POW0194278-R0031296-SA` (Refurbished)

| Spec | This Server | vs. Current |
|------|-------------|-------------|
| Generation | 16th Gen PowerEdge | +2 generations |
| CPU | **2x Intel Xeon Silver 4509Y** (16 cores total, 4.10 GHz, 22.5 MB cache) | 2 sockets vs. 1, newer generation |
| RAM | **256 GB DDR5-5600** (4x 64 GB RDIMM, dual rank) | 8x the RAM, DDR5 (faster) |
| Boot | 2x 480 GB PCIe M.2 NVMe (mirrored) | Dedicated boot separate from data |
| Data storage | **5x 1.2 TB 10K SAS** + 960 GB SSD cache = ~4.8 TB usable RAID 5 | ~5x current usable storage |
| Networking | Broadcom 5720 quad-port 1 GbE + 2x Broadcom 57416 dual-port 10 GbE | Adds 10 GbE capability |
| Power | 800W (1+1) redundant | Same |
| Form factor | 2U rack, standard bezel | Standard data-center chassis |
| Warranty | 3-Year Basic Hardware Repair, 5x10 Next Business Day Onsite | Fresh warranty |

**Why we like it:**

- **Right-sized upgrade without overspending.** Five times the usable storage, eight times the RAM, and a modern DDR5 platform — but uses cost-effective Silver-tier CPUs rather than Gold/Platinum that you don't need for a law firm file-server workload.
- **True storage headroom.** 4.8 TB usable gives you ~5 years of growth room from your current 900 GB footprint.
- **Newest generation available at Outlet pricing.** 16th-gen Sapphire Rapids platform with full Dell warranty and certified refurbishment.
- **Mirrored boot separation.** Two dedicated M.2 NVMe drives for OS/boot means your data RAID is independent — a modern best practice that your current server does not have.

**Best fit if:** You want meaningful performance and capacity gains, the newest generation available, and a warranty-backed refurbished deal.

---

### Option B (Alternate): Dell PowerEdge R650 — Maximum CPU Power, Compact 1U

**Dell Outlet SKU:** `POW0193711-R0031036-SA` (Refurbished)

| Spec | This Server | vs. Current |
|------|-------------|-------------|
| Generation | 15th Gen PowerEdge | +1 generation |
| CPU | **2x Intel Xeon Gold 6346** (32 cores total, 3.60 GHz, 36 MB cache, 205W) | Significant CPU uplift — Gold tier, 32 cores |
| RAM | **512 GB DDR4-3200** (16x 32 GB RDIMM, dual rank) | 16x the RAM |
| Data storage | **2x 1.2 TB 10K SAS** = 1.2 TB usable RAID 1 | Slight capacity step-up (~20% more) |
| Networking | Broadcom 57414 10/25 GbE + 57504 Quad-port 10/25 GbE OCP | 25 GbE capability |
| Power | 800W (1+1) redundant | Same |
| Form factor | 1U rack, LCD bezel | Smaller footprint |
| Warranty | 3-Year Basic Hardware Repair, 5x10 NBD Onsite | Fresh warranty |

**Why we like it:**

- **Heavy CPU and memory headroom.** 32 cores and 512 GB RAM is future-proofing for virtualization, additional workloads (SQL, document management platforms), or any line-of-business software you may add.
- **1U footprint** if rack space is a concern.
- **25 GbE networking** is a significant jump if you're considering a modern switch upgrade.

**Why we like it less than Option A:**

- **Minimal storage upgrade.** 1.2 TB usable is only ~20% more than your current footprint — not much long-term headroom.
- **10K SAS spinning disks are slower than NVMe SSDs.** For a file-server workload, disk speed often matters more than CPU.
- **You pay for performance you won't use.** 32 cores and 512 GB RAM is overkill for a ~10-person law firm file server.

**Best fit if:** You anticipate adding virtualized workloads, database servers, or document management software to the same box, and you don't need a massive storage increase.

---

### Option C (Alternate): Dell PowerEdge XR7620 — All-NVMe Premium

**Dell Outlet SKU:** `POW0193712-R0028403-SA` (Refurbished)

| Spec | This Server | vs. Current |
|------|-------------|-------------|
| Generation | 16th Gen PowerEdge (rugged XR-series) | +2 generations |
| CPU | **2x Intel Xeon Gold 6426Y** (32 cores total, 4.10 GHz, 37.5 MB cache) | Gold tier, 32 cores, high clock |
| RAM | **256 GB DDR5-5600** (16x 16 GB RDIMM) | 8x the RAM |
| Data storage | **2x 3.84 TB PCIe U.2 NVMe** (Gen 4) + 2x 480 GB M.2 boot = 3.84 TB usable RAID 1 | 4x current capacity, all-flash NVMe |
| Networking | Broadcom 5720 quad-port 1 GbE OCP | Standard gigabit |
| Power | Redundant | Same |
| Form factor | 2U rugged chassis (NAF bezel, front-access) | Designed for harsh environments |
| Warranty | 3-Year Basic Hardware Repair, 5x10 NBD Onsite | Fresh warranty |

**Why we like it:**

- **All-flash NVMe storage.** Fastest disk performance possible — dramatic improvement over spinning SAS.
- **Large, fast storage.** 3.84 TB of NVMe handles your current workload with 4x headroom.
- **Gold 6426Y CPUs** run at higher clock (4.10 GHz) than the Silver parts in Option A — better single-threaded performance for applications.

**Why we like it less than Option A:**

- **XR-series is a rugged/edge platform** — built for deployment in industrial or tactical environments, not standard office racks. The chassis bezel and mounting are atypical for a law firm server room.
- **Fewer networking ports** than Option A (1 GbE only, no 10 GbE).
- **Likely the most expensive of the three** options due to premium CPU tier and all-NVMe storage.

**Best fit if:** Raw disk performance is critical (large case-file databases, document imaging, frequent large-file searches), you don't mind the rugged form factor, and budget is less of a constraint.

---

## 4. Side-by-Side Comparison

| Metric | Current 2KPZZV2 | Option A — R760 | Option B — R650 | Option C — XR7620 |
|--------|-----------------|-----------------|-----------------|-------------------|
| Generation | 14th Gen | **16th Gen** | 15th Gen | **16th Gen** |
| CPU sockets | 1 | 2 | 2 | 2 |
| Total cores | ~4–8 | 16 | **32** | **32** |
| CPU tier | Scalable | Silver | **Gold** | **Gold** |
| Memory | 32 GB DDR4 | **256 GB DDR5** | 512 GB DDR4 | **256 GB DDR5** |
| Usable storage | ~1–2 TB HDD | **4.8 TB SAS** | 1.2 TB SAS | 3.84 TB NVMe |
| Storage type | HDD | SAS 10K | SAS 10K | **NVMe (all-flash)** |
| Boot separation | No | **Yes (M.2 mirrored)** | No | **Yes (M.2 mirrored)** |
| 10/25 GbE network | No | **10 GbE** | **25 GbE** | 1 GbE only |
| Form factor | 1U/2U | 2U standard | 1U standard | 2U rugged |
| Warranty | Expired/near end | **3 yr fresh** | **3 yr fresh** | **3 yr fresh** |

---

## 5. What Happens Next

1. **Dell Outlet pricing request** — Technijian will send Dell a formal quote request for all three SKUs and any add-on options (extended warranty to 5 years, ProSupport Plus, additional drives if desired).
2. **You review pricing with our recommendations** — We'll schedule a 30-minute call to walk through the final numbers and confirm direction.
3. **Order and staging (Week 1)** — Once you approve, we place the order. Dell Outlet typically ships in 5–10 business days.
4. **Migration project kickoff** — Revised Statement of Work covering: new server staging and OS install, data migration from old to new server, OneDrive/SharePoint migration for shared folders, Cloudbrink ZTNA for secure remote access, CrowdStrike/Huntress/Patch Management/MyRemote agent deployment, testing, and 30-day post-cutover support.

---

## 6. What the Full Project Includes (Working Estimate)

| Line Item | Estimated Cost |
|-----------|---------------|
| Dell PowerEdge server (Option A working estimate) | ~$6,000 – $10,000 (confirming with Dell) |
| Windows Server 2025 Standard OEM license | ~$1,100 |
| Veeam Backup & Replication perpetual license | ~$900 |
| Migration labor (82 hours across 8 phases) | ~$10,000 |
| **One-time total (estimated)** | **~$18,000 – $22,000** |
| Ongoing monthly managed services (security agents + backup) | ~$75/month |

This replaces the previously proposed cloud infrastructure monthly fee of ~$426/month. Over 3 years, the on-prem path is typically ~$12,000–$15,000 less in total cost of ownership versus cloud-hosted equivalents, once the hardware is owned.

---

## 7. Our Recommendation

**Option A — Dell PowerEdge R760 (SKU POW0194278-R0031296-SA)** is the right fit for Oaktree Law.

It gives you:

- The newest generation available (16th Gen, DDR5)
- Five times your current storage capacity on properly-tiered SAS drives with a modern NVMe boot
- Eight times your current RAM
- 10 GbE networking for future-proofing
- A conventional rack form factor suited to your server room
- A fresh 3-year Dell warranty with next-business-day onsite repair

Options B and C are legitimate alternatives if your priorities differ (more CPU/RAM without storage growth for B; raw NVMe performance for C), but Option A best matches the workload profile of a law firm file server.

---

*Questions on any of the options? Reply to this report or reach out directly and we'll walk through the details.*
