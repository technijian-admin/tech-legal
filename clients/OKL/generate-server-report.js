const fs = require("fs");
const path = require("path");
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  Header, Footer, AlignmentType,
  HeadingLevel, BorderStyle, WidthType, ShadingType,
  PageNumber, PageBreak, ImageRun, VerticalAlign
} = require("docx");

// Technijian brand
const BLUE = "006DB6";
const ORANGE = "F67D4B";
const GREY = "59595B";
const CHARCOAL = "1A1A2E";
const WHITE = "FFFFFF";
const LIGHT_GREY = "F5F5F5";
const LIGHT_BLUE = "E8F4FD";
const GREEN = "2E7D32";
const FONT = "Open Sans";

let logoBuffer = null;
try { logoBuffer = fs.readFileSync(path.join(__dirname, "..", "..", "templates", "logo.jpg")); } catch(e) {}

function p(text, opts = {}) {
  const runOpts = { font: FONT, size: opts.size || 22, color: opts.color || GREY, text };
  if (opts.bold) runOpts.bold = true;
  if (opts.italics) runOpts.italics = true;
  const pOpts = { children: [new TextRun(runOpts)] };
  if (opts.heading) pOpts.heading = opts.heading;
  if (opts.alignment) pOpts.alignment = opts.alignment;
  if (opts.spacing) pOpts.spacing = opts.spacing;
  if (opts.indent) pOpts.indent = opts.indent;
  if (opts.bullet) pOpts.bullet = opts.bullet;
  return new Paragraph(pOpts);
}

function heading1(t) { return p(t, { heading: HeadingLevel.HEADING_1 }); }
function heading2(t) { return p(t, { heading: HeadingLevel.HEADING_2 }); }
function heading3(t) { return p(t, { size: 24, bold: true, color: BLUE, spacing: { before: 200, after: 100 } }); }
function spacer(amt) { return p("", { spacing: { after: amt || 120 } }); }
function bullet(text, level) { return p(text, { bullet: { level: level || 0 }, spacing: { after: 60 } }); }
function orangeRule() { return new Paragraph({ spacing: { before: 100, after: 100 }, border: { bottom: { style: BorderStyle.SINGLE, size: 2, color: ORANGE } }, children: [] }); }
function blueRule() { return new Paragraph({ spacing: { before: 100, after: 100 }, border: { bottom: { style: BorderStyle.SINGLE, size: 3, color: BLUE } }, children: [] }); }

const docStyles = {
  default: { document: { run: { font: FONT, size: 22, color: GREY } } },
  paragraphStyles: [
    { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
      run: { size: 36, bold: true, font: FONT, color: BLUE },
      paragraph: { spacing: { before: 360, after: 240 }, outlineLevel: 0 } },
    { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
      run: { size: 28, bold: true, font: FONT, color: CHARCOAL },
      paragraph: { spacing: { before: 280, after: 160 }, outlineLevel: 1 } },
  ]
};

function makeHeader() {
  const children = [];
  if (logoBuffer) {
    children.push(new Paragraph({ alignment: AlignmentType.LEFT, children: [new ImageRun({ type: "jpg", data: logoBuffer, transformation: { width: 130, height: 33 }, altText: { title: "Technijian", description: "Technijian Inc.", name: "logo" } })] }));
  } else {
    children.push(new Paragraph({ children: [new TextRun({ text: "TECHNIJIAN", font: FONT, bold: true, size: 20, color: BLUE }), new TextRun({ text: "  technology as a solution", font: FONT, size: 16, color: GREY })] }));
  }
  children.push(new Paragraph({ border: { bottom: { style: BorderStyle.SINGLE, size: 1, color: BLUE } }, children: [] }));
  return new Header({ children });
}

function makeFooter() {
  return new Footer({ children: [
    new Paragraph({ border: { top: { style: BorderStyle.SINGLE, size: 1, color: BLUE } }, spacing: { before: 100 }, children: [] }),
    new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: "Technijian, Inc.  |  18 Technology Dr., Ste 141, Irvine, CA 92618  |  949.379.8499", font: FONT, size: 14, color: GREY })] }),
    new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: "Page ", font: FONT, size: 14, color: GREY }), new TextRun({ children: [PageNumber.CURRENT], font: FONT, size: 14, color: GREY }), new TextRun({ text: " of ", font: FONT, size: 14, color: GREY }), new TextRun({ children: [PageNumber.TOTAL_PAGES], font: FONT, size: 14, color: GREY })] })
  ] });
}

function cell(text, opts = {}) {
  const runOpts = { font: FONT, size: opts.size || 18, color: opts.color || GREY, text: String(text) };
  if (opts.bold) runOpts.bold = true;
  if (opts.italics) runOpts.italics = true;
  const cellOpts = {
    children: [new Paragraph({ alignment: opts.alignment || AlignmentType.LEFT, children: [new TextRun(runOpts)] })],
    verticalAlign: VerticalAlign.CENTER,
    margins: { top: 40, bottom: 40, left: 80, right: 80 },
  };
  if (opts.shading) cellOpts.shading = opts.shading;
  if (opts.width) cellOpts.width = opts.width;
  if (opts.columnSpan) cellOpts.columnSpan = opts.columnSpan;
  return new TableCell(cellOpts);
}

function headerCell(text, widthPct) {
  return cell(text, {
    bold: true, color: WHITE, size: 18,
    shading: { type: ShadingType.SOLID, fill: BLUE, color: BLUE },
    width: { size: widthPct, type: WidthType.PERCENTAGE }
  });
}

function altRow(isAlt) { return isAlt ? { type: ShadingType.SOLID, fill: LIGHT_GREY, color: LIGHT_GREY } : undefined; }

function makeTable(headers, rows, colWidths) {
  const headerRow = new TableRow({
    children: headers.map((h, i) => headerCell(h, colWidths ? colWidths[i] : Math.floor(100/headers.length))),
    tableHeader: true
  });
  const dataRows = rows.map((row, ri) => new TableRow({
    children: row.map((val, ci) => {
      const str = String(val);
      const isBold = str.startsWith("**");
      const clean = str.replace(/^\*\*|\*\*$/g, "");
      return cell(clean, {
        alignment: AlignmentType.LEFT,
        shading: altRow(ri % 2 === 1),
        bold: isBold,
        width: colWidths ? { size: colWidths[ci], type: WidthType.PERCENTAGE } : undefined
      });
    })
  }));
  return new Table({ width: { size: 100, type: WidthType.PERCENTAGE }, rows: [headerRow, ...dataRows] });
}

function coverPage() {
  return {
    properties: { page: { size: { width: 12240, height: 15840 }, margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 } } },
    children: [
      p("", { spacing: { before: 2400 } }),
      ...(logoBuffer ? [new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 200 }, children: [new ImageRun({ type: "jpg", data: logoBuffer, transformation: { width: 250, height: 63 }, altText: { title: "Technijian Logo", description: "Technijian Inc.", name: "logo" } })] })] : [p("TECHNIJIAN", { size: 72, bold: true, color: BLUE, alignment: AlignmentType.CENTER })]),
      p("", { spacing: { after: 600 } }),
      orangeRule(),
      p("Server Upgrade Options", { size: 48, bold: true, color: CHARCOAL, alignment: AlignmentType.CENTER, spacing: { before: 400, after: 200 } }),
      p("Oaktree Law", { size: 32, bold: true, color: BLUE, alignment: AlignmentType.CENTER, spacing: { after: 100 } }),
      p("Hardware Refresh Proposal", { size: 24, italics: true, color: GREY, alignment: AlignmentType.CENTER, spacing: { after: 200 } }),
      p("Replacement for Service Tag 2KPZZV2", { size: 22, color: GREY, alignment: AlignmentType.CENTER, spacing: { after: 200 } }),
      p("April 15, 2026", { size: 22, color: GREY, alignment: AlignmentType.CENTER, spacing: { after: 400 } }),
      orangeRule(),
      p("", { spacing: { after: 800 } }),
      p("Prepared For", { size: 20, bold: true, color: BLUE, alignment: AlignmentType.CENTER, spacing: { after: 60 } }),
      p("Ed Pitts", { size: 24, bold: true, color: CHARCOAL, alignment: AlignmentType.CENTER, spacing: { after: 40 } }),
      p("Oaktree Law", { size: 20, color: GREY, alignment: AlignmentType.CENTER, spacing: { after: 400 } }),
      p("Prepared By", { size: 20, bold: true, color: BLUE, alignment: AlignmentType.CENTER, spacing: { after: 60 } }),
      p("Technijian, Inc.", { size: 22, bold: true, color: CHARCOAL, alignment: AlignmentType.CENTER }),
      p("18 Technology Dr., Ste 141  |  Irvine, CA 92618  |  949.379.8499", { size: 18, color: GREY, alignment: AlignmentType.CENTER }),
      new Paragraph({ children: [new PageBreak()] })
    ]
  };
}

function contentSection(children) {
  return {
    properties: {
      page: { size: { width: 12240, height: 15840 }, margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 } },
      headers: { default: makeHeader() },
      footers: { default: makeFooter() }
    },
    children
  };
}

function optionHeader(letter, name, recommended) {
  return p(`Option ${letter}${recommended ? " (Recommended)" : " (Alternate)"}: ${name}`, {
    size: 26, bold: true, color: recommended ? BLUE : CHARCOAL,
    spacing: { before: 280, after: 120 }
  });
}

// ============================================================================
// BUILD REPORT
// ============================================================================

const content = [];

// SECTION 1: Executive Summary
content.push(heading1("1. Executive Summary"));
content.push(p("Your current Dell PowerEdge server (service tag 2KPZZV2) is a 14th-generation platform that has been in service for several years and is approaching end-of-life for warranty, performance, and security patching.", { spacing: { after: 120 } }));
content.push(p("In place of the previously discussed cloud migration, Technijian is proposing a hardware refresh to a newer-generation Dell PowerEdge server sourced through the Dell Outlet program (certified refurbished, full Dell warranty included).", { spacing: { after: 120 } }));
content.push(p("This report presents three server candidates from Dell Outlet. All three:", { spacing: { after: 120 } }));
content.push(bullet("Equal or exceed the storage capacity of your current server"));
content.push(bullet("Use modern Intel Xeon Scalable CPUs (dual socket vs. your current single socket)"));
content.push(bullet("Include Dell's 3-Year Basic Hardware Warranty with Next Business Day onsite service"));
content.push(bullet("Feature dual redundant power supplies matching your current setup"));
content.push(spacer(200));
content.push(p("We have a clear recommendation (Option A — PowerEdge R760) but include two alternatives so you can weigh performance, capacity, and budget tradeoffs.", { bold: true, color: CHARCOAL }));
content.push(spacer(200));

// SECTION 2: Current Server Baseline
content.push(heading1("2. Your Current Server — Baseline Specs"));
content.push(p("The following specifications were decoded from the Dell bill of materials for service tag 2KPZZV2:", { spacing: { after: 120 } }));
content.push(makeTable(
  ["Component", "Current Configuration"],
  [
    ["Model", "Dell PowerEdge (14th Generation — T440 / R440 class)"],
    ["CPU", "1x Intel Xeon Scalable processor (single socket populated)"],
    ["Memory", "32 GB DDR4-2666 RDIMM (2x 16 GB, dual rank)"],
    ["Storage", "2x hard drives in RAID 1"],
    ["Data in use", "~900 GB (119 GB OS + 779 GB shared folders)"],
    ["Power", "Redundant 1+1 power supplies"],
    ["Operating System", "Windows Server 2019 Standard + CALs"],
    ["Management", "iDRAC9 Express"],
    ["Optical", "DVD±RW drive"],
  ],
  [30, 70]
));
content.push(spacer(200));
content.push(p("Why upgrade now:", { bold: true, color: BLUE, size: 22, spacing: { after: 80 } }));
content.push(bullet("14th-generation PowerEdge platforms are in the later portion of their support lifecycle"));
content.push(bullet("DDR4-2666 memory is two generations behind current DDR5 speeds"));
content.push(bullet("Single-socket configuration limits CPU performance for virtualization and future growth"));
content.push(bullet("Warranty status should be verified — many 2KPZZV2-era servers are out of or near end-of-warranty"));
content.push(bullet("Microsoft ends mainstream support for Windows Server 2019 in January 2029 — a logical moment to modernize both hardware and OS"));
content.push(spacer(200));

// SECTION 3: Options
content.push(heading1("3. Recommended Server Options"));

// Option A
content.push(optionHeader("A", "Dell PowerEdge R760 — Balanced Upgrade", true));
content.push(p("Dell Outlet SKU: POW0194278-R0031296-SA (Refurbished)", { italics: true, size: 20, spacing: { after: 120 } }));
content.push(makeTable(
  ["Specification", "This Server", "vs. Current"],
  [
    ["Generation", "16th Gen PowerEdge", "+2 generations"],
    ["CPU", "2x Intel Xeon Silver 4509Y (16 cores total, 4.10 GHz, 22.5 MB cache)", "2 sockets vs. 1, newer gen"],
    ["RAM", "256 GB DDR5-5600 (4x 64 GB RDIMM, dual rank)", "8x RAM, DDR5 (faster)"],
    ["Boot", "2x 480 GB PCIe M.2 NVMe (mirrored)", "Dedicated boot separate from data"],
    ["Data storage", "5x 1.2 TB 10K SAS + 960 GB SSD cache = ~4.8 TB usable RAID 5", "~5x current usable storage"],
    ["Networking", "Broadcom 5720 quad-port 1 GbE + 2x Broadcom 57416 dual-port 10 GbE", "Adds 10 GbE capability"],
    ["Power", "800W (1+1) redundant", "Same"],
    ["Form factor", "2U rack, standard bezel", "Standard data-center chassis"],
    ["Warranty", "3-Year Basic Hardware Repair, 5x10 Next Business Day Onsite", "Fresh warranty"],
  ],
  [20, 55, 25]
));
content.push(spacer(160));
content.push(p("Why we like it:", { bold: true, color: BLUE, size: 22, spacing: { after: 80 } }));
content.push(bullet("Right-sized upgrade without overspending. Five times the usable storage, eight times the RAM, and a modern DDR5 platform — but uses cost-effective Silver-tier CPUs rather than Gold/Platinum you don't need for a law firm file-server workload."));
content.push(bullet("True storage headroom. 4.8 TB usable gives ~5 years of growth room from your current 900 GB footprint."));
content.push(bullet("Newest generation available at Outlet pricing. 16th-generation Sapphire Rapids platform with full Dell warranty and certified refurbishment."));
content.push(bullet("Mirrored boot separation. Two dedicated M.2 NVMe drives for OS/boot keeps your data RAID independent — a modern best practice that your current server does not have."));
content.push(spacer(120));
content.push(p("Best fit if: You want meaningful performance and capacity gains, the newest generation available, and a warranty-backed refurbished deal.", { italics: true, color: CHARCOAL }));
content.push(spacer(240));

// Option B
content.push(optionHeader("B", "Dell PowerEdge R650 — Maximum CPU Power, Compact 1U", false));
content.push(p("Dell Outlet SKU: POW0193711-R0031036-SA (Refurbished)", { italics: true, size: 20, spacing: { after: 120 } }));
content.push(makeTable(
  ["Specification", "This Server", "vs. Current"],
  [
    ["Generation", "15th Gen PowerEdge", "+1 generation"],
    ["CPU", "2x Intel Xeon Gold 6346 (32 cores total, 3.60 GHz, 36 MB cache, 205W)", "Gold tier, 32 cores"],
    ["RAM", "512 GB DDR4-3200 (16x 32 GB RDIMM, dual rank)", "16x RAM"],
    ["Data storage", "2x 1.2 TB 10K SAS = 1.2 TB usable RAID 1", "~20% more capacity"],
    ["Networking", "Broadcom 57414 10/25 GbE + 57504 Quad-port 10/25 GbE OCP", "25 GbE capability"],
    ["Power", "800W (1+1) redundant", "Same"],
    ["Form factor", "1U rack, LCD bezel", "Smaller footprint"],
    ["Warranty", "3-Year Basic Hardware Repair, 5x10 NBD Onsite", "Fresh warranty"],
  ],
  [20, 55, 25]
));
content.push(spacer(160));
content.push(p("Why we like it:", { bold: true, color: BLUE, size: 22, spacing: { after: 80 } }));
content.push(bullet("Heavy CPU and memory headroom. 32 cores and 512 GB RAM is future-proofing for virtualization, additional workloads (SQL, document management platforms), or any line-of-business software you may add."));
content.push(bullet("1U footprint if rack space is a concern."));
content.push(bullet("25 GbE networking — a significant jump if you're considering a modern switch upgrade."));
content.push(spacer(120));
content.push(p("Why we like it less than Option A:", { bold: true, color: ORANGE, size: 22, spacing: { after: 80 } }));
content.push(bullet("Minimal storage upgrade. 1.2 TB usable is only ~20% more than your current footprint — not much long-term headroom."));
content.push(bullet("10K SAS spinning disks are slower than NVMe SSDs. For file-server workloads, disk speed often matters more than CPU."));
content.push(bullet("You pay for performance you won't use. 32 cores and 512 GB RAM is overkill for a small law firm file server."));
content.push(spacer(120));
content.push(p("Best fit if: You anticipate adding virtualized workloads, database servers, or document management software to the same box, and you don't need a large storage increase.", { italics: true, color: CHARCOAL }));
content.push(spacer(240));

// Option C
content.push(optionHeader("C", "Dell PowerEdge XR7620 — All-NVMe Premium", false));
content.push(p("Dell Outlet SKU: POW0193712-R0028403-SA (Refurbished)", { italics: true, size: 20, spacing: { after: 120 } }));
content.push(makeTable(
  ["Specification", "This Server", "vs. Current"],
  [
    ["Generation", "16th Gen PowerEdge (rugged XR-series)", "+2 generations"],
    ["CPU", "2x Intel Xeon Gold 6426Y (32 cores total, 4.10 GHz, 37.5 MB cache)", "Gold tier, 32 cores, high clock"],
    ["RAM", "256 GB DDR5-5600 (16x 16 GB RDIMM, single rank)", "8x RAM, DDR5"],
    ["Data storage", "2x 3.84 TB PCIe U.2 NVMe (Gen 4) + 2x 480 GB M.2 boot = 3.84 TB usable RAID 1", "4x capacity, all-flash NVMe"],
    ["Networking", "Broadcom 5720 quad-port 1 GbE OCP", "Standard gigabit"],
    ["Power", "Redundant", "Same"],
    ["Form factor", "2U rugged chassis (NAF bezel, front-access)", "Built for harsh environments"],
    ["Warranty", "3-Year Basic Hardware Repair, 5x10 NBD Onsite", "Fresh warranty"],
  ],
  [20, 55, 25]
));
content.push(spacer(160));
content.push(p("Why we like it:", { bold: true, color: BLUE, size: 22, spacing: { after: 80 } }));
content.push(bullet("All-flash NVMe storage. Fastest disk performance available — dramatic improvement over spinning SAS."));
content.push(bullet("Large, fast storage. 3.84 TB of NVMe handles your current workload with 4x headroom."));
content.push(bullet("Gold 6426Y CPUs run at higher clock (4.10 GHz) than the Silver parts in Option A — better single-threaded performance for applications."));
content.push(spacer(120));
content.push(p("Why we like it less than Option A:", { bold: true, color: ORANGE, size: 22, spacing: { after: 80 } }));
content.push(bullet("XR-series is a rugged/edge platform — built for deployment in industrial or tactical environments, not standard office racks. The chassis bezel and mounting are atypical for a law firm server room."));
content.push(bullet("Fewer networking ports than Option A (1 GbE only, no 10 GbE)."));
content.push(bullet("Likely the most expensive of the three options due to premium CPU tier and all-NVMe storage."));
content.push(spacer(120));
content.push(p("Best fit if: Raw disk performance is critical (large case-file databases, document imaging, frequent large-file searches), you don't mind the rugged form factor, and budget is less of a constraint.", { italics: true, color: CHARCOAL }));
content.push(spacer(240));

// SECTION 4: Side-by-side
content.push(heading1("4. Side-by-Side Comparison"));
content.push(makeTable(
  ["Metric", "Current 2KPZZV2", "Option A — R760", "Option B — R650", "Option C — XR7620"],
  [
    ["Generation", "14th Gen", "**16th Gen**", "15th Gen", "**16th Gen**"],
    ["CPU sockets", "1", "2", "2", "2"],
    ["Total cores", "~4-8", "16", "**32**", "**32**"],
    ["CPU tier", "Scalable", "Silver", "**Gold**", "**Gold**"],
    ["Memory", "32 GB DDR4", "**256 GB DDR5**", "512 GB DDR4", "**256 GB DDR5**"],
    ["Usable storage", "~1-2 TB HDD", "**4.8 TB SAS**", "1.2 TB SAS", "3.84 TB NVMe"],
    ["Storage type", "HDD", "SAS 10K", "SAS 10K", "**NVMe all-flash**"],
    ["Boot separation", "No", "**Yes (M.2)**", "No", "**Yes (M.2)**"],
    ["10/25 GbE", "No", "**10 GbE**", "**25 GbE**", "1 GbE only"],
    ["Form factor", "1U/2U", "2U standard", "1U standard", "2U rugged"],
    ["Warranty", "Expired/near end", "**3 yr fresh**", "**3 yr fresh**", "**3 yr fresh**"],
  ],
  [20, 20, 20, 20, 20]
));
content.push(spacer(240));

// SECTION 5: Next Steps
content.push(heading1("5. What Happens Next"));
content.push(p("1. Dell Outlet pricing request — Technijian sends Dell a formal quote request covering all three SKUs, including 10 Windows licenses, 5 RDP licenses, and both 3-year and 5-year ProSupport options.", { spacing: { after: 100 } }));
content.push(p("2. You review pricing with our recommendation — we'll schedule a 30-minute call to walk through the numbers and confirm direction.", { spacing: { after: 100 } }));
content.push(p("3. Order and staging (Week 1) — once approved, we place the order. Dell Outlet typically ships in 5-10 business days.", { spacing: { after: 100 } }));
content.push(p("4. Migration project kickoff — Revised Statement of Work covering new server staging and OS install, data migration from old to new server, OneDrive/SharePoint migration for shared folders, Cloudbrink ZTNA for secure remote access, CrowdStrike / Huntress / Patch Management / MyRemote agent deployment, testing, and 30-day post-cutover support.", { spacing: { after: 160 } }));

// SECTION 6: Cost estimate
content.push(heading1("6. What the Full Project Includes (Working Estimate)"));
content.push(makeTable(
  ["Line Item", "Estimated Cost"],
  [
    ["Dell PowerEdge server (Option A working estimate)", "~$6,000 – $10,000 (confirming with Dell)"],
    ["Windows Server 2025 Standard OEM license + 10 User CALs", "~$1,500"],
    ["5x Windows Remote Desktop Services (RDP) CALs", "~$750"],
    ["Veeam Backup & Replication perpetual license", "~$900"],
    ["Migration labor (82 hours across 8 phases)", "~$10,000"],
    ["**One-time total (estimated)**", "**~$19,000 – $23,000**"],
    ["Ongoing monthly managed services (security agents + backup)", "~$75 / month"],
  ],
  [70, 30]
));
content.push(spacer(160));
content.push(p("This replaces the previously proposed cloud infrastructure monthly fee of ~$426 / month. Over 3 years, the on-prem path is typically $12,000–$15,000 less in total cost of ownership versus cloud-hosted equivalents, once the hardware is owned.", { italics: true }));
content.push(spacer(240));

// SECTION 7: Recommendation
content.push(heading1("7. Our Recommendation"));
content.push(p("Option A — Dell PowerEdge R760 (SKU POW0194278-R0031296-SA) is the right fit for Oaktree Law.", { bold: true, color: BLUE, size: 24, spacing: { after: 160 } }));
content.push(p("It gives you:", { spacing: { after: 80 } }));
content.push(bullet("The newest generation available (16th Gen, DDR5)"));
content.push(bullet("Five times your current storage capacity on properly-tiered SAS drives with a modern NVMe boot"));
content.push(bullet("Eight times your current RAM"));
content.push(bullet("10 GbE networking for future-proofing"));
content.push(bullet("A conventional rack form factor suited to your server room"));
content.push(bullet("A fresh 3-year Dell warranty with next-business-day onsite repair"));
content.push(spacer(160));
content.push(p("Options B and C are legitimate alternatives if your priorities differ (more CPU/RAM without storage growth for B; raw NVMe performance for C), but Option A best matches the workload profile of a law firm file server.", { spacing: { after: 240 } }));

content.push(orangeRule());
content.push(p("Questions on any of the options? Reply to this report or reach out directly and we'll walk through the details.", { italics: true, color: CHARCOAL, alignment: AlignmentType.CENTER, spacing: { before: 160 } }));

// BUILD DOCUMENT
const doc = new Document({
  styles: docStyles,
  sections: [coverPage(), contentSection(content)]
});

Packer.toBuffer(doc).then(buf => {
  const out = path.join(__dirname, "Server-Upgrade-Options-EdPitts.docx");
  fs.writeFileSync(out, buf);
  console.log(`Generated: ${out}`);
});
