const fs = require("fs");
const path = require("path");
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  Header, Footer, AlignmentType, LevelFormat,
  HeadingLevel, BorderStyle, WidthType, ShadingType,
  PageNumber, PageBreak, ImageRun
} = require("docx");

// ===== TECHNIJIAN BRAND COLORS =====
const BLUE = "006DB6";
const ORANGE = "F67D4B";
const TEAL = "1EAAC8";
const GREY = "59595B";
const CHARCOAL = "1A1A2E";
const OFF_WHITE = "F8F9FA";
const WHITE = "FFFFFF";
const FONT = "Open Sans";

// Logo
let logoBuffer = null;
const logoPath = path.join(__dirname, "../../templates/logo.jpg");
try {
  logoBuffer = fs.readFileSync(logoPath);
} catch (e) {
  console.log("Logo not found at", logoPath);
}

// ===== STYLES =====
const docStyles = {
  default: {
    document: {
      run: { font: FONT, size: 22, color: GREY }
    }
  },
  paragraphStyles: [
    {
      id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
      run: { size: 36, bold: true, font: FONT, color: BLUE },
      paragraph: { spacing: { before: 360, after: 240 }, outlineLevel: 0 }
    },
    {
      id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
      run: { size: 28, bold: true, font: FONT, color: CHARCOAL },
      paragraph: { spacing: { before: 280, after: 160 }, outlineLevel: 1 }
    },
    {
      id: "Heading3", name: "Heading 3", basedOn: "Normal", next: "Normal", quickFormat: true,
      run: { size: 24, bold: true, font: FONT, color: CHARCOAL },
      paragraph: { spacing: { before: 200, after: 120 }, outlineLevel: 2 }
    }
  ]
};

const numbering = {
  config: [
    {
      reference: "bullets",
      levels: [{
        level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 720, hanging: 360 } } }
      }]
    },
    {
      reference: "bullets2",
      levels: [{
        level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 720, hanging: 360 } } }
      }]
    },
    {
      reference: "letters",
      levels: [{
        level: 0, format: LevelFormat.LOWER_LETTER, text: "(%1)", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 720, hanging: 360 } } }
      }]
    },
    {
      reference: "roman",
      levels: [{
        level: 0, format: LevelFormat.LOWER_ROMAN, text: "(%1)", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 1080, hanging: 360 } } }
      }]
    },
    {
      reference: "numbered",
      levels: [{
        level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 720, hanging: 360 } } }
      }]
    }
  ]
};

// ===== HELPERS =====
function p(text, opts = {}) {
  const runOpts = { font: FONT, size: opts.size || 22, color: opts.color || GREY, text };
  if (opts.bold) runOpts.bold = true;
  if (opts.italics) runOpts.italics = true;
  const pOpts = { children: [new TextRun(runOpts)] };
  if (opts.heading) pOpts.heading = opts.heading;
  if (opts.alignment) pOpts.alignment = opts.alignment;
  if (opts.spacing) pOpts.spacing = opts.spacing;
  if (opts.numbering) pOpts.numbering = opts.numbering;
  if (opts.indent) pOpts.indent = opts.indent;
  return new Paragraph(pOpts);
}

function multiRun(runs, opts = {}) {
  const children = runs.map(r => {
    const runOpts = { font: FONT, size: r.size || 22, color: r.color || GREY, text: r.text };
    if (r.bold) runOpts.bold = true;
    if (r.italics) runOpts.italics = true;
    return new TextRun(runOpts);
  });
  const pOpts = { children };
  if (opts.spacing) pOpts.spacing = opts.spacing;
  if (opts.indent) pOpts.indent = opts.indent;
  if (opts.numbering) pOpts.numbering = opts.numbering;
  return new Paragraph(pOpts);
}

function heading1(text) { return p(text, { heading: HeadingLevel.HEADING_1 }); }
function heading2(text) { return p(text, { heading: HeadingLevel.HEADING_2 }); }
function heading3(text) { return p(text, { heading: HeadingLevel.HEADING_3 }); }
function spacer() { return p("", { spacing: { after: 120 } }); }

function brandRule() {
  return new Paragraph({
    spacing: { before: 200, after: 200 },
    border: { bottom: { style: BorderStyle.SINGLE, size: 3, color: BLUE } },
    children: []
  });
}

function orangeAccentRule() {
  return new Paragraph({
    spacing: { before: 100, after: 100 },
    border: { bottom: { style: BorderStyle.SINGLE, size: 2, color: ORANGE } },
    children: []
  });
}

function bullet(text, ref = "bullets") {
  return p(text, { numbering: { reference: ref, level: 0 } });
}

function letterItem(text, ref = "letters") {
  return p(text, { numbering: { reference: ref, level: 0 } });
}

function romanItem(text, ref = "roman") {
  return p(text, { numbering: { reference: ref, level: 0 } });
}

// ===== TABLES =====
const thinBorder = { style: BorderStyle.SINGLE, size: 1, color: "DDDDDD" };
const tableBorders = { top: thinBorder, bottom: thinBorder, left: thinBorder, right: thinBorder };
const cellPadding = { top: 80, bottom: 80, left: 120, right: 120 };

function brandTableCell(text, opts = {}) {
  const width = opts.width || 2340;
  const isHeader = opts.header || false;
  const runOpts = {
    font: FONT,
    size: opts.fontSize || 20,
    text,
    color: isHeader ? WHITE : GREY,
    bold: isHeader || opts.bold
  };
  return new TableCell({
    borders: tableBorders,
    width: { size: width, type: WidthType.DXA },
    margins: cellPadding,
    shading: {
      fill: isHeader ? BLUE : (opts.alt ? OFF_WHITE : WHITE),
      type: ShadingType.CLEAR
    },
    verticalAlign: "center",
    children: [new Paragraph({
      children: [new TextRun(runOpts)]
    })]
  });
}

function makeTable(headers, rows, widths) {
  const totalWidth = widths.reduce((a, b) => a + b, 0);
  const tableRows = [
    new TableRow({
      children: headers.map((h, i) => brandTableCell(h, { width: widths[i], header: true }))
    }),
    ...rows.map((row, ri) => new TableRow({
      children: row.map((cell, ci) => {
        const text = typeof cell === "string" ? cell : cell.text;
        const bold = typeof cell === "object" ? cell.bold : false;
        return brandTableCell(text, { width: widths[ci], alt: ri % 2 === 0, bold });
      })
    }))
  ];
  return new Table({
    width: { size: totalWidth, type: WidthType.DXA },
    columnWidths: widths,
    rows: tableRows
  });
}

// ===== COVER PAGE =====
function coverPage() {
  const items = [];
  items.push(p("", { spacing: { before: 2400 } }));

  if (logoBuffer) {
    items.push(new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { after: 200 },
      children: [new ImageRun({
        type: "jpg",
        data: logoBuffer,
        transformation: { width: 250, height: 63 },
        altText: { title: "Technijian Logo", description: "Technijian Inc.", name: "logo" }
      })]
    }));
  } else {
    items.push(p("TECHNIJIAN", { size: 72, bold: true, color: BLUE, alignment: AlignmentType.CENTER }));
    items.push(p("technology as a solution", { size: 28, color: GREY, alignment: AlignmentType.CENTER }));
  }

  items.push(p("", { spacing: { after: 600 } }));
  items.push(orangeAccentRule());
  items.push(p("Statement of Work", { size: 48, bold: true, color: CHARCOAL, alignment: AlignmentType.CENTER, spacing: { before: 400, after: 200 } }));
  items.push(p("Endpoint Storage Upgrade \u2014 SSD Replacement", { size: 28, color: GREY, alignment: AlignmentType.CENTER, spacing: { after: 120 } }));
  items.push(p("SOW-JDH-001", { size: 24, color: GREY, alignment: AlignmentType.CENTER, spacing: { after: 400 } }));
  items.push(orangeAccentRule());
  items.push(p("", { spacing: { after: 600 } }));
  items.push(p("Prepared for: JDH Pacific", { size: 24, bold: true, color: CHARCOAL, alignment: AlignmentType.CENTER, spacing: { after: 120 } }));
  items.push(p("March 30, 2026", { size: 22, color: GREY, alignment: AlignmentType.CENTER, spacing: { after: 200 } }));
  items.push(p("", { spacing: { after: 400 } }));
  items.push(p("Technijian, Inc.", { size: 22, bold: true, color: CHARCOAL, alignment: AlignmentType.CENTER }));
  items.push(p("18 Technology Dr., Ste 141  |  Irvine, CA 92618  |  949.379.8499", { size: 20, color: GREY, alignment: AlignmentType.CENTER }));
  items.push(new Paragraph({ children: [new PageBreak()] }));
  return items;
}

// ===== HEADER / FOOTER =====
function makeHeader() {
  const children = [];
  if (logoBuffer) {
    children.push(new Paragraph({
      alignment: AlignmentType.LEFT,
      children: [new ImageRun({
        type: "jpg",
        data: logoBuffer,
        transformation: { width: 130, height: 33 },
        altText: { title: "Technijian", description: "Technijian Inc.", name: "logo" }
      })]
    }));
  } else {
    children.push(new Paragraph({
      children: [
        new TextRun({ text: "TECHNIJIAN", font: FONT, bold: true, size: 20, color: BLUE }),
        new TextRun({ text: "  technology as a solution", font: FONT, size: 16, color: GREY })
      ]
    }));
  }
  children.push(new Paragraph({
    border: { bottom: { style: BorderStyle.SINGLE, size: 1, color: BLUE } },
    children: []
  }));
  return new Header({ children });
}

function makeFooter() {
  return new Footer({
    children: [
      new Paragraph({
        border: { top: { style: BorderStyle.SINGLE, size: 1, color: BLUE } },
        spacing: { before: 100 },
        children: []
      }),
      new Paragraph({
        alignment: AlignmentType.CENTER,
        children: [
          new TextRun({ text: "Technijian, Inc.  |  18 Technology Dr., Ste 141, Irvine, CA 92618  |  949.379.8499", font: FONT, size: 14, color: GREY }),
        ]
      }),
      new Paragraph({
        alignment: AlignmentType.CENTER,
        children: [
          new TextRun({ text: "Page ", font: FONT, size: 14, color: GREY }),
          new TextRun({ children: [PageNumber.CURRENT], font: FONT, size: 14, color: GREY }),
          new TextRun({ text: " of ", font: FONT, size: 14, color: GREY }),
          new TextRun({ children: [PageNumber.TOTAL_PAGES], font: FONT, size: 14, color: GREY }),
        ]
      })
    ]
  });
}

// ===== GENERATE SOW =====
async function generateSOW() {
  const content = [];

  // ---- SOW Header ----
  content.push(heading1("STATEMENT OF WORK"));
  content.push(multiRun([
    { text: "SOW Number: ", bold: true, color: CHARCOAL },
    { text: "SOW-JDH-001" }
  ]));
  content.push(multiRun([
    { text: "Effective Date: ", bold: true, color: CHARCOAL },
    { text: "March 30, 2026" }
  ]));
  content.push(multiRun([
    { text: "Master Service Agreement: ", bold: true, color: CHARCOAL },
    { text: "(if applicable)" }
  ]));
  content.push(spacer());
  content.push(p("This Statement of Work (\u201CSOW\u201D) is entered into by and between:"));
  content.push(spacer());
  content.push(p("Technijian, Inc. (\u201CTechnijian\u201D)", { bold: true, color: CHARCOAL }));
  content.push(p("18 Technology Drive, Suite 141"));
  content.push(p("Irvine, California 92618"));
  content.push(spacer());
  content.push(p("and"));
  content.push(spacer());
  content.push(p("JDH Pacific (\u201CClient\u201D)", { bold: true, color: CHARCOAL }));
  content.push(p("[CLIENT ADDRESS]"));
  content.push(p("[CITY, STATE ZIP]"));
  content.push(brandRule());

  // ---- 1. PROJECT OVERVIEW ----
  content.push(heading1("1. PROJECT OVERVIEW"));

  content.push(heading2("1.1 Project Title"));
  content.push(p("Endpoint Storage Upgrade \u2014 SSD Replacement for Critical and Low-Disk Systems"));
  content.push(spacer());

  content.push(heading2("1.2 Project Description"));
  content.push(p("JDH Pacific currently has eight (8) endpoint workstations experiencing critically low or concerning disk space utilization, as identified in the Disk Space Health Report dated March 27, 2026. Four of these systems are in a critical state with less than 15 GB of free space remaining, and four additional systems are below the operational free-space threshold."));
  content.push(spacer());
  content.push(p("This SOW covers the procurement, installation, and validation of replacement SSD drives for all eight affected workstations using a loaner swap methodology to minimize end-user downtime. Technijian will deploy three (3) preconfigured loaner workstations in rotating waves, swap each affected machine for a loaner, perform drive cloning and upgrade at the Technijian facility, and return upgraded machines in subsequent visits. End-user downtime is limited to approximately 15 minutes per swap.", { bold: false }));
  content.push(spacer());

  // 1.3 Upgrade Methodology
  content.push(heading2("1.3 Upgrade Methodology \u2014 Loaner Swap Process"));
  content.push(multiRun([
    { text: "Why Loaner Swap: ", bold: true, color: CHARCOAL },
    { text: "Rather than performing on-site drive cloning (which requires 1-3 hours per machine with the user waiting), Technijian will use a rotating pool of three (3) loaner workstations to minimize disruption:" }
  ]));
  content.push(spacer());
  content.push(multiRun([
    { text: "Wave 1 (Visit 1): ", bold: true, color: CHARCOAL },
    { text: "Deploy 3 loaner workstations to the 3 most critical machines. Swap cables, verify user login on loaner, and transport affected machines to Technijian facility. (~15 min downtime per user)" }
  ], { numbering: { reference: "numbered", level: 0 } }));
  content.push(multiRun([
    { text: "Wave 1 Shop Work: ", bold: true, color: CHARCOAL },
    { text: "Clone drives to new SSDs, install upgraded drives, validate boot and applications at Technijian facility." }
  ], { numbering: { reference: "numbered", level: 0 } }));
  content.push(multiRun([
    { text: "Wave 2 (Visit 2): ", bold: true, color: CHARCOAL },
    { text: "Return 3 upgraded machines, swap next 3 machines with the same 3 loaners, transport to facility. (~15 min downtime per user)" }
  ], { numbering: { reference: "numbered", level: 0 } }));
  content.push(multiRun([
    { text: "Wave 2 Shop Work: ", bold: true, color: CHARCOAL },
    { text: "Clone and upgrade batch 2 at facility." }
  ], { numbering: { reference: "numbered", level: 0 } }));
  content.push(multiRun([
    { text: "Wave 3 (Visit 3): ", bold: true, color: CHARCOAL },
    { text: "Return 3 upgraded machines, swap last 2 machines with loaners, transport to facility. (~15 min downtime per user)" }
  ], { numbering: { reference: "numbered", level: 0 } }));
  content.push(multiRun([
    { text: "Wave 3 Shop Work: ", bold: true, color: CHARCOAL },
    { text: "Clone and upgrade batch 3 at facility." }
  ], { numbering: { reference: "numbered", level: 0 } }));
  content.push(multiRun([
    { text: "Final Return (Visit 4): ", bold: true, color: CHARCOAL },
    { text: "Return last 2 upgraded machines, collect all 3 loaners. (~15 min downtime per user)" }
  ], { numbering: { reference: "numbered", level: 0 } }));
  content.push(spacer());
  content.push(multiRun([
    { text: "User Impact: ", bold: true, color: CHARCOAL },
    { text: "Each user experiences approximately 15 minutes of downtime per swap (two swaps total: once to loaner, once back to upgraded machine). Users can continue working on loaner machines during the upgrade period." }
  ]));
  content.push(spacer());

  // 1.4 Affected Systems Summary
  content.push(heading2("1.4 Affected Systems Summary"));
  content.push(makeTable(
    ["#", "Machine", "Type", "Current Drive", "Cap.", "Free", "Used %", "Severity"],
    [
      ["1", "JDH-HQ-PC-09", "OptiPlex 5040", "TOSHIBA TL100", "111 GB", "0.1 GB", "100%", "Critical"],
      ["2", "JDH-HQ-LPT-01", "Precision 7780", "Samsung PM9C1a 256GB", "235 GB", "6 GB", "97%", "Critical"],
      ["3", "JDH-WHOFFICE", "OptiPlex 7080", "SK hynix PC611 256GB", "236 GB", "9 GB", "96%", "Critical"],
      ["4", "SupplySalesconf", "ASUSTeK P8Z77-V", "ST240HM000 SSD", "223 GB", "14 GB", "94%", "Critical"],
      ["5", "JDH-HQ-PC-06", "OptiPlex Micro Plus 7010", "KIOXIA 512GB NVMe", "474 GB", "33 GB", "93%", "Low"],
      ["6", "DESKTOP-8QP97UG", "ASRock AB350 Pro4", "SanDisk SSD PLUS 240GB", "251 GB", "34 GB", "86%", "Low"],
      ["7", "Frontdesk-JDH", "OptiPlex 3000", "SK hynix BC901 256GB", "236 GB", "40 GB", "83%", "Low"],
      ["8", "DESKTOP-ED8O2CQ", "Vostro 3470", "SK hynix SC401 256GB", "224 GB", "46 GB", "79%", "Low"],
    ],
    [400, 1400, 1300, 1600, 700, 700, 700, 800]
  ));
  content.push(spacer());

  // 1.5 Wave Assignments
  content.push(heading2("1.5 Wave Assignments"));
  content.push(makeTable(
    ["Wave", "Visit", "Machines", "Priority"],
    [
      ["Wave 1", "Visit 1 (deploy loaners) \u2192 Visit 2 (return upgraded)", "JDH-HQ-PC-09, JDH-HQ-LPT-01, JDH-WHOFFICE", "Critical"],
      ["Wave 2", "Visit 2 (deploy loaners) \u2192 Visit 3 (return upgraded)", "SupplySalesconf, JDH-HQ-PC-06, DESKTOP-8QP97UG", "Critical + Low"],
      ["Wave 3", "Visit 3 (deploy loaners) \u2192 Visit 4 (return upgraded)", "Frontdesk-JDH, DESKTOP-ED8O2CQ", "Low"],
    ],
    [1200, 3000, 2800, 1600]
  ));
  content.push(brandRule());

  // ---- 2. SCOPE OF WORK ----
  content.push(heading1("2. SCOPE OF WORK"));

  content.push(heading2("2.1 In Scope"));
  content.push(bullet("Procurement of eight (8) replacement SSD drives (500/512 GB capacity)"));
  content.push(bullet("Pre-upgrade remote assessment and backup verification for all affected systems", "bullets2"));
  content.push(bullet("Provisioning of three (3) Technijian-owned loaner workstations for the swap rotation"));
  content.push(bullet("Four (4) on-site visits for loaner deployment, machine pickup, upgraded machine return, and loaner collection", "bullets2"));
  content.push(bullet("Full disk clone / data migration from existing drives to new SSDs at Technijian facility"));
  content.push(bullet("Physical drive installation and boot validation at Technijian facility", "bullets2"));
  content.push(bullet("Post-upgrade validation after 48 hours of production use"));
  content.push(bullet("Old drive labeling and return to Client", "bullets2"));
  content.push(spacer());

  content.push(heading2("2.2 Out of Scope"));
  content.push(p("The following items are expressly excluded from this SOW:"));
  content.push(spacer());
  content.push(bullet("Operating system reinstallation or reimaging (clone-based migration only)"));
  content.push(bullet("Microsoft 365 migration or tenant configuration (referenced in Disk Space Health Report as separate workstream)", "bullets2"));
  content.push(bullet("Desktop replacement or new hardware procurement beyond SSD drives"));
  content.push(bullet("Data recovery for corrupted or damaged files on existing drives", "bullets2"));
  content.push(bullet("Server-side upgrades or cloud migration"));
  content.push(bullet("Software license transfers or activation beyond what is required for drive swap", "bullets2"));
  content.push(bullet("Loaner workstation customization beyond basic Windows configuration and network access"));
  content.push(spacer());

  content.push(heading2("2.3 Assumptions"));
  content.push(bullet("Client will provide physical access to all workstations during scheduled swap windows"));
  content.push(bullet("Existing drives are functional and clonable (not failed or failing)", "bullets2"));
  content.push(bullet("Machines currently listed as Offline / Undone will be powered on and accessible for the swap"));
  content.push(bullet("Loaner workstations will be configured with basic Windows, domain join, and network access sufficient for users to perform essential work", "bullets2"));
  content.push(bullet("Client will inform affected users of the swap schedule and ensure they save work prior to each swap window"));
  content.push(bullet("Minimum 2-hour on-site engagement per visit", "bullets2"));
  content.push(bullet("Cloning will be performed using industry-standard disk imaging tools (e.g., Macrium Reflect, Clonezilla) at Technijian facility"));
  content.push(brandRule());

  // ---- 3. PROJECT PHASES ----
  content.push(heading1("3. PROJECT PHASES"));

  // Phase 1
  content.push(heading2("Phase 1: Remote Assessment & Loaner Preparation"));
  content.push(heading3("3.1.1 Description"));
  content.push(p("Remote assessment of all eight affected systems to verify current drive health, confirm backup status, and validate form factor compatibility. Simultaneously, prepare three (3) Technijian-owned loaner workstations with basic Windows configuration, domain join credentials, and network access for the swap rotation."));
  content.push(spacer());
  content.push(heading3("3.1.2 Deliverables"));
  content.push(bullet("Drive health report (S.M.A.R.T. status) for all 8 systems"));
  content.push(bullet("Backup verification confirmation for each machine", "bullets2"));
  content.push(bullet("Form factor confirmation (2.5\u201D SATA vs. M.2 2230 vs. M.2 2280) for each machine"));
  content.push(bullet("3 loaner workstations prepared and tested", "bullets2"));
  content.push(bullet("Swap schedule coordinated with Client (4 visits)"));
  content.push(spacer());
  content.push(heading3("3.1.3 Schedule"));
  content.push(makeTable(
    ["Role", "Description", "Rate", "Hours", "Timeline"],
    [
      ["Tech Support (US)", "Remote assessment, backup verification, scheduling", "$150/hr", "3", "Week 1"],
      ["Tech Support (Offshore)", "Loaner workstation preparation and configuration", "$45/hr", "3", "Week 1"],
      [{ text: "", bold: true }, { text: "Phase 1 Total", bold: true }, "", { text: "6", bold: true }, ""],
    ],
    [1800, 3200, 1200, 1200, 1200]
  ));
  content.push(brandRule());

  // Phase 2
  content.push(heading2("Phase 2: On-Site Swap Visits (4 Visits, 3 Waves)"));
  content.push(heading3("3.2.1 Description"));
  content.push(p("Four on-site visits to JDH Pacific headquarters to execute the loaner swap rotation. Each visit involves disconnecting affected machines, deploying loaner workstations, verifying user login on loaners, and transporting machines to/from the Technijian facility."));
  content.push(spacer());
  content.push(multiRun([
    { text: "Visit 1: ", bold: true, color: CHARCOAL },
    { text: "Deploy 3 loaners \u2192 pick up machines #1-3 (JDH-HQ-PC-09, JDH-HQ-LPT-01, JDH-WHOFFICE)" }
  ]));
  content.push(multiRun([
    { text: "Visit 2: ", bold: true, color: CHARCOAL },
    { text: "Return upgraded #1-3, deploy loaners \u2192 pick up machines #4-6 (SupplySalesconf, JDH-HQ-PC-06, DESKTOP-8QP97UG)" }
  ]));
  content.push(multiRun([
    { text: "Visit 3: ", bold: true, color: CHARCOAL },
    { text: "Return upgraded #4-6, deploy loaners \u2192 pick up machines #7-8 (Frontdesk-JDH, DESKTOP-ED8O2CQ)" }
  ]));
  content.push(multiRun([
    { text: "Visit 4: ", bold: true, color: CHARCOAL },
    { text: "Return upgraded #7-8, collect all 3 loaners" }
  ]));
  content.push(spacer());
  content.push(heading3("3.2.2 Deliverables"));
  content.push(bullet("All 8 machines swapped and returned with upgraded drives"));
  content.push(bullet("User login verified on loaner at each swap", "bullets2"));
  content.push(bullet("User login verified on returned upgraded machine at each swap"));
  content.push(bullet("All 3 loaner workstations collected and returned to Technijian", "bullets2"));
  content.push(spacer());
  content.push(heading3("3.2.3 Schedule"));
  content.push(makeTable(
    ["Role", "Description", "Rate", "Hours", "Timeline"],
    [
      ["Tech Support (US)", "Visit 1 \u2014 Deploy 3 loaners, pick up 3 critical machines", "$150/hr", "2", "Week 2"],
      ["Tech Support (US)", "Visit 2 \u2014 Return 3 upgraded, swap next 3, pick up", "$150/hr", "2", "Week 2"],
      ["Tech Support (US)", "Visit 3 \u2014 Return 3 upgraded, swap last 3, pick up", "$150/hr", "2", "Week 3"],
      ["Tech Support (US)", "Visit 4 \u2014 Return last 3 upgraded, collect loaners", "$150/hr", "2", "Week 3"],
      [{ text: "", bold: true }, { text: "Phase 2 Total", bold: true }, "", { text: "8", bold: true }, ""],
    ],
    [1800, 3200, 1200, 1200, 1200]
  ));
  content.push(brandRule());

  // Phase 3
  content.push(heading2("Phase 3: Off-Site Drive Cloning & Upgrade (Technijian Facility)"));
  content.push(heading3("3.3.1 Description"));
  content.push(p("At the Technijian facility, perform full disk clone from each existing drive to the new SSD, install the new SSD into the machine, validate boot, OS functionality, and application integrity. Process runs in three batches of 3 machines aligned with the on-site swap waves."));
  content.push(spacer());
  content.push(heading3("3.3.2 Deliverables"));
  content.push(bullet("8 machines with new SSDs installed and validated"));
  content.push(bullet("Boot verification and OS validation for each machine", "bullets2"));
  content.push(bullet("Application and data integrity confirmed for each machine"));
  content.push(bullet("Old drives labeled and securely stored for return to Client", "bullets2"));
  content.push(spacer());
  content.push(heading3("3.3.3 Schedule"));
  content.push(makeTable(
    ["Role", "Description", "Rate", "Hours", "Timeline"],
    [
      ["Tech Support (US)", "Drive cloning setup, troubleshooting, SSD installation \u2014 3 batches", "$150/hr", "4", "Weeks 2-3"],
      ["Tech Support (Offshore)", "Clone monitoring, validation scripts, integrity checks \u2014 3 batches", "$45/hr", "5", "Weeks 2-3"],
      [{ text: "", bold: true }, { text: "Phase 3 Total", bold: true }, "", { text: "9", bold: true }, ""],
    ],
    [1800, 3200, 1200, 1200, 1200]
  ));
  content.push(brandRule());

  // Phase 4
  content.push(heading2("Phase 4: Post-Upgrade Validation & Closeout"));
  content.push(heading3("3.4.1 Description"));
  content.push(p("Remote validation of all upgraded systems after 48 hours of production use. Verify disk health, free space, performance, and confirm no issues. Deliver old drives to Client."));
  content.push(spacer());
  content.push(heading3("3.4.2 Deliverables"));
  content.push(bullet("Post-upgrade health check report for all 8 systems"));
  content.push(bullet("Updated disk space inventory", "bullets2"));
  content.push(bullet("Old drives returned to Client (labeled by machine name)"));
  content.push(bullet("Project closeout confirmation", "bullets2"));
  content.push(spacer());
  content.push(heading3("3.4.3 Schedule"));
  content.push(makeTable(
    ["Role", "Description", "Rate", "Hours", "Timeline"],
    [
      ["Tech Support (Offshore)", "Remote validation and health checks \u2014 all 8 systems", "$45/hr", "3", "Week 4"],
      [{ text: "", bold: true }, { text: "Phase 4 Total", bold: true }, "", { text: "3", bold: true }, ""],
    ],
    [1800, 3200, 1200, 1200, 1200]
  ));
  content.push(brandRule());

  // ---- 4. EQUIPMENT AND MATERIALS ----
  content.push(heading1("4. EQUIPMENT AND MATERIALS"));

  content.push(heading2("4.1 SSD Procurement"));
  content.push(p("All drives are procured and supplied by Technijian. Pricing includes procurement, handling, and delivery."));
  content.push(spacer());

  // SATA SSDs
  content.push(p("SATA SSD \u2014 2.5\u201D Form Factor (Samsung 870 EVO 500GB)", { bold: true, color: CHARCOAL }));
  content.push(spacer());
  content.push(makeTable(
    ["#", "Machine", "Type", "Qty", "Price", "Sub-Total"],
    [
      ["1", "JDH-HQ-PC-09", "OptiPlex 5040", "1", "$163.75", "$163.75"],
      ["4", "SupplySalesconf", "ASUSTeK P8Z77-V", "1", "$163.75", "$163.75"],
      ["6", "DESKTOP-8QP97UG", "ASRock AB350 Pro4", "1", "$163.75", "$163.75"],
      ["8", "DESKTOP-ED8O2CQ", "Vostro 3470", "1", "$163.75", "$163.75"],
      [{ text: "", bold: true }, "", { text: "SATA Subtotal", bold: true }, { text: "4", bold: true }, "", { text: "$655.00", bold: true }],
    ],
    [500, 1600, 1500, 600, 1200, 1200]
  ));
  content.push(spacer());

  // NVMe 2230
  content.push(p("NVMe SSD \u2014 M.2 2230 Form Factor (Kingston NV3 500GB)", { bold: true, color: CHARCOAL }));
  content.push(spacer());
  content.push(makeTable(
    ["#", "Machine", "Type", "Qty", "Price", "Sub-Total"],
    [
      ["2", "JDH-HQ-LPT-01", "Precision 7780", "1", "$173.75", "$173.75"],
      ["5", "JDH-HQ-PC-06", "OptiPlex Micro Plus 7010", "1", "$173.75", "$173.75"],
      ["7", "Frontdesk-JDH", "OptiPlex 3000", "1", "$173.75", "$173.75"],
      [{ text: "", bold: true }, "", { text: "NVMe 2230 Subtotal", bold: true }, { text: "3", bold: true }, "", { text: "$521.25", bold: true }],
    ],
    [500, 1600, 1500, 600, 1200, 1200]
  ));
  content.push(spacer());

  // NVMe 2280
  content.push(p("NVMe SSD \u2014 M.2 2280 Form Factor (Dell 512GB PCIe Gen3)", { bold: true, color: CHARCOAL }));
  content.push(spacer());
  content.push(makeTable(
    ["#", "Machine", "Type", "Qty", "Price", "Sub-Total"],
    [
      ["3", "JDH-WHOFFICE", "OptiPlex 7080", "1", "$156.25", "$156.25"],
      [{ text: "", bold: true }, "", { text: "NVMe 2280 Subtotal", bold: true }, { text: "1", bold: true }, "", { text: "$156.25", bold: true }],
    ],
    [500, 1600, 1500, 600, 1200, 1200]
  ));
  content.push(spacer());

  // Equipment totals
  content.push(makeTable(
    ["", "", "Amount"],
    [
      [{ text: "Equipment Sub-Total", bold: true }, "", { text: "$1,332.50", bold: true }],
      ["Sales Tax (7.75%)", "", "$103.27"],
      [{ text: "Equipment Total", bold: true }, "", { text: "$1,435.77", bold: true }],
    ],
    [3900, 2700, 2000]
  ));
  content.push(spacer());

  // 4.2 Loaner Workstations
  content.push(heading2("4.2 Loaner Workstations"));
  content.push(p("Technijian will provide three (3) loaner workstations from its equipment pool at no additional charge to Client. Loaner workstations remain the property of Technijian and will be collected upon project completion. Client is responsible for any physical damage to loaner equipment beyond normal wear."));
  content.push(spacer());

  content.push(heading2("4.3 Title and Ownership"));
  content.push(p("Title to SSD equipment shall remain vested in Technijian until paid for in full. Upon receipt of full payment, title shall transfer to Client."));
  content.push(spacer());

  content.push(heading2("4.4 Warranty"));
  content.push(p("Equipment warranty is provided by the manufacturer per the manufacturer\u2019s warranty terms. Technijian shall assist Client in processing any warranty claims during the warranty period."));
  content.push(bullet("Samsung 870 EVO: 5-year limited warranty"));
  content.push(bullet("Kingston NV3: 3-year limited warranty", "bullets2"));
  content.push(bullet("Dell SSD: 5-year limited warranty"));
  content.push(brandRule());

  // ---- 5. PRICING AND PAYMENT ----
  content.push(heading1("5. PRICING AND PAYMENT"));

  content.push(heading2("5.1 Rate Card"));
  content.push(makeTable(
    ["Role", "Location", "Rate"],
    [
      ["Tech Support", "United States (On-Site)", "$150.00/hr"],
      ["Tech Support", "Offshore (India)", "$45.00/hr"],
    ],
    [2700, 3200, 2700]
  ));
  content.push(spacer());
  content.push(multiRun([
    { text: "On-Site Terms: ", bold: true, color: CHARCOAL },
    { text: "$150.00/hr, 2-hour minimum per visit, no trip charges." }
  ]));
  content.push(spacer());

  content.push(heading2("5.2 Labor Summary"));
  content.push(makeTable(
    ["Phase", "Description", "US Tech ($150)", "Offshore ($45)", "Total Hrs", "Cost"],
    [
      ["Phase 1", "Remote Assessment & Loaner Preparation", "3", "3", "6", "$585.00"],
      ["Phase 2", "On-Site Swap Visits (4 visits, 3 waves)", "8", "\u2014", "8", "$1,200.00"],
      ["Phase 3", "Off-Site Drive Cloning & Upgrade", "4", "5", "9", "$825.00"],
      ["Phase 4", "Post-Upgrade Validation & Closeout", "\u2014", "3", "3", "$135.00"],
      [{ text: "TOTAL", bold: true }, "", { text: "15", bold: true }, { text: "10", bold: true }, { text: "25", bold: true }, { text: "$2,550.00", bold: true }],
    ],
    [1000, 2600, 1300, 1300, 1000, 1400]
  ));
  content.push(spacer());

  content.push(p("Labor Cost Breakdown:", { bold: true, color: CHARCOAL }));
  content.push(bullet("Tech Support (US): 15 hrs \u00D7 $150/hr = $2,250.00"));
  content.push(bullet("Tech Support (Offshore): 10 hrs \u00D7 $45/hr = $450.00", "bullets2"));
  content.push(spacer());

  content.push(heading2("5.3 Total Project Cost"));
  content.push(makeTable(
    ["Category", "Amount"],
    [
      ["Equipment (8 SSDs)", "$1,332.50"],
      ["Sales Tax (7.75%)", "$103.27"],
      ["Labor (25 hours)", "$2,550.00"],
      [{ text: "Total Project Cost", bold: true }, { text: "$3,985.77", bold: true }],
    ],
    [5400, 3200]
  ));
  content.push(spacer());

  content.push(multiRun([
    { text: "Pricing Type: ", bold: true, color: CHARCOAL },
    { text: "Fixed Cost", bold: true },
    { text: " \u2014 Technijian will complete all work described in this SOW at the stated price regardless of actual hours consumed. The fixed price includes all labor, travel, loaner equipment, and project management. Equipment pricing is fixed and inclusive of procurement and handling." }
  ]));
  content.push(spacer());

  content.push(heading2("5.4 Payment Schedule"));
  content.push(makeTable(
    ["Milestone", "Invoiced", "Amount"],
    [
      ["Equipment procurement (before Phase 2 begins)", "Upon SOW execution", "$1,435.77"],
      ["Labor \u2014 fixed project fee", "Upon project closeout", "$2,550.00"],
      [{ text: "Total", bold: true }, "", { text: "$3,985.77", bold: true }],
    ],
    [3200, 2700, 2700]
  ));
  content.push(spacer());

  content.push(heading2("5.5 Payment Terms"));
  content.push(p("All invoices are due and payable within thirty (30) days of the invoice date.", { bold: false }));
  content.push(spacer());

  content.push(heading2("5.6 Late Payment and Collection Remedies"));
  content.push(multiRun([
    { text: "(a) ", bold: true, color: CHARCOAL },
    { text: "Late payments shall accrue a late fee of " },
    { text: "1.5% per month", bold: true },
    { text: " (or the maximum rate permitted by law, whichever is less) on the unpaid balance, compounding monthly from the date payment was due. If an MSA is in effect, the late payment, acceleration, collection costs, lien, and fee-shifting provisions of the MSA shall apply in full to this SOW." }
  ]));
  content.push(spacer());

  content.push(multiRun([
    { text: "(b) ", bold: true, color: CHARCOAL },
    { text: "If no MSA is in effect between the Parties, the following shall apply:" }
  ]));
  content.push(spacer());

  content.push(multiRun([
    { text: "(i) Acceleration. ", bold: true, color: CHARCOAL },
    { text: "If Client fails to pay any undisputed invoice within forty-five (45) days of the due date, all remaining fees under this SOW shall become immediately due and payable." }
  ], { indent: { left: 720 } }));
  content.push(spacer());

  content.push(multiRun([
    { text: "(ii) Suspension. ", bold: true, color: CHARCOAL },
    { text: "Technijian may suspend all work under this SOW upon ten (10) days written notice if any invoice remains unpaid beyond the due date. Suspension shall not relieve Client of its payment obligations, and project timelines shall be adjusted accordingly at no cost to Technijian." }
  ], { indent: { left: 720 } }));
  content.push(spacer());

  content.push(multiRun([
    { text: "(iii) Collection Costs and Attorney\u2019s Fees. ", bold: true, color: CHARCOAL },
    { text: "In any action or proceeding to collect fees, invoices, or other amounts owed under this SOW, Client shall be liable for all costs of collection, including reasonable attorney\u2019s fees (including in-house counsel at market rates), collection agency fees, court costs, arbitration fees, and all costs of appeal. This fee-shifting applies exclusively to collection of amounts owed and does not apply to disputes regarding service quality, professional performance, or other non-payment claims." }
  ], { indent: { left: 720 } }));
  content.push(spacer());

  content.push(multiRun([
    { text: "(iv) Lien on Work Product. ", bold: true, color: CHARCOAL },
    { text: "Technijian shall retain a lien on all deliverables, work product, documentation, and materials under this SOW until all amounts owed are paid in full. Title to equipment under Section 4.3 shall not transfer until full payment is received." }
  ], { indent: { left: 720 } }));
  content.push(spacer());

  content.push(multiRun([
    { text: "(v) Fees for Non-Collection Disputes. ", bold: true, color: CHARCOAL },
    { text: "Except as provided in subsection (iii) above, in any dispute arising under this SOW relating to service quality, professional performance, scope, or any other non-payment matter, each Party shall bear its own attorney\u2019s fees and costs." }
  ], { indent: { left: 720 } }));
  content.push(brandRule());

  // ---- 6. CLIENT RESPONSIBILITIES ----
  content.push(heading1("6. CLIENT RESPONSIBILITIES"));
  content.push(p("Client shall:"));
  content.push(spacer());
  content.push(letterItem("Provide physical access to all workstations during scheduled swap windows;"));
  content.push(letterItem("Designate a point of contact authorized to make decisions on behalf of Client;"));
  content.push(letterItem("Review and approve deliverables within five (5) business days of submission;"));
  content.push(letterItem("Ensure all relevant data is backed up prior to the start of work;"));
  content.push(letterItem("Inform affected users of the swap schedule and ensure users save all work prior to each swap window;"));
  content.push(letterItem("Power on and make accessible any machines currently listed as Offline / Undone prior to the scheduled swap;"));
  content.push(letterItem("Accept responsibility for any physical damage to Technijian-owned loaner workstations beyond normal wear during the loaner period; and"));
  content.push(letterItem("Notify Technijian promptly of any issues with loaner workstations during the swap period."));
  content.push(brandRule());

  // ---- 7. CHANGE MANAGEMENT ----
  content.push(heading1("7. CHANGE MANAGEMENT"));
  content.push(multiRun([
    { text: "7.01. ", bold: true, color: CHARCOAL },
    { text: "Any changes to the scope, schedule, or pricing of this SOW must be documented in a written Change Order signed by both Parties before work on the change begins." }
  ]));
  content.push(spacer());
  content.push(multiRun([
    { text: "7.02. ", bold: true, color: CHARCOAL },
    { text: "If Client requests work outside the defined scope, Technijian shall provide a Change Order detailing the additional work, estimated hours, and cost impact." }
  ]));
  content.push(spacer());
  content.push(multiRun([
    { text: "7.03. ", bold: true, color: CHARCOAL },
    { text: "Technijian shall not proceed with out-of-scope work without an approved Change Order, except in cases where delay would result in harm to Client\u2019s systems, in which case Technijian shall notify Client as soon as practicable." }
  ]));
  content.push(brandRule());

  // ---- 8. ACCEPTANCE ----
  content.push(heading1("8. ACCEPTANCE"));
  content.push(multiRun([
    { text: "8.01. ", bold: true, color: CHARCOAL },
    { text: "Upon completion of each phase, Technijian shall notify Client in writing that the deliverables are ready for review." }
  ]));
  content.push(spacer());
  content.push(multiRun([
    { text: "8.02. ", bold: true, color: CHARCOAL },
    { text: "Client shall review the deliverables and provide written acceptance or a detailed description of deficiencies within five (5) business days." }
  ]));
  content.push(spacer());
  content.push(multiRun([
    { text: "8.03. ", bold: true, color: CHARCOAL },
    { text: "If Client does not respond within the review period, the deliverables shall be deemed accepted." }
  ]));
  content.push(spacer());
  content.push(multiRun([
    { text: "8.04. ", bold: true, color: CHARCOAL },
    { text: "If deficiencies are identified, Technijian shall correct them and resubmit for review. This process shall repeat until acceptance is achieved or the Parties agree on a resolution." }
  ]));
  content.push(brandRule());

  // ---- 9. GOVERNING TERMS ----
  content.push(heading1("9. GOVERNING TERMS"));
  content.push(multiRun([
    { text: "9.01. ", bold: true, color: CHARCOAL },
    { text: "If a Master Service Agreement is in effect between the Parties, the terms of the MSA shall govern this SOW. In the event of a conflict between this SOW and the MSA, the MSA shall prevail unless this SOW expressly states otherwise." }
  ]));
  content.push(spacer());
  content.push(multiRun([
    { text: "9.02. ", bold: true, color: CHARCOAL },
    { text: "If no MSA is in effect, the Technijian Standard Terms and Conditions (attached as Appendix A) shall govern this SOW." }
  ]));
  content.push(brandRule());

  // ---- SIGNATURES ----
  content.push(heading1("SIGNATURES"));
  content.push(spacer());
  content.push(p("TECHNIJIAN, INC.", { bold: true, color: CHARCOAL }));
  content.push(spacer());
  content.push(p("By: ___________________________________"));
  content.push(p("Name: _________________________________"));
  content.push(p("Title: _________________________________"));
  content.push(p("Date: _________________________________"));
  content.push(spacer());
  content.push(spacer());
  content.push(p("JDH PACIFIC", { bold: true, color: CHARCOAL }));
  content.push(spacer());
  content.push(p("By: ___________________________________"));
  content.push(p("Name: _________________________________"));
  content.push(p("Title: _________________________________"));
  content.push(p("Date: _________________________________"));

  // ===== BUILD DOCUMENT =====
  const doc = new Document({
    styles: docStyles,
    numbering,
    sections: [
      {
        properties: {
          page: {
            size: { width: 12240, height: 15840 },
            margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 }
          }
        },
        children: coverPage()
      },
      {
        properties: {
          page: {
            size: { width: 12240, height: 15840 },
            margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 }
          },
          headers: { default: makeHeader() },
          footers: { default: makeFooter() }
        },
        children: content
      }
    ]
  });

  const buffer = await Packer.toBuffer(doc);
  const outPath = path.join(__dirname, "SOW-JDH-001-DiskUpgrades.docx");
  fs.writeFileSync(outPath, buffer);
  console.log("Generated:", outPath);
}

generateSOW().catch(console.error);
