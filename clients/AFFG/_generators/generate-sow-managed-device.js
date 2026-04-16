const fs = require("fs");
const path = require("path");
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  Header, Footer, AlignmentType, LevelFormat,
  HeadingLevel, BorderStyle, WidthType, ShadingType,
  PageNumber, PageBreak, ImageRun
} = require("docx");

// ===== TECHNIJIAN BRAND COLORS (from Brand Guide 2026) =====
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
const logoPath = path.join(__dirname, "../../../templates/logo.jpg");
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
      reference: "bullets3",
      levels: [{
        level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 720, hanging: 360 } } }
      }]
    },
    {
      reference: "bullets4",
      levels: [{
        level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 720, hanging: 360 } } }
      }]
    },
    {
      reference: "bullets5",
      levels: [{
        level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 720, hanging: 360 } } }
      }]
    },
    {
      reference: "bullets6",
      levels: [{
        level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 720, hanging: 360 } } }
      }]
    },
    {
      reference: "bullets7",
      levels: [{
        level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 720, hanging: 360 } } }
      }]
    },
    {
      reference: "bullets8",
      levels: [{
        level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 720, hanging: 360 } } }
      }]
    },
    {
      reference: "bullets9",
      levels: [{
        level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 720, hanging: 360 } } }
      }]
    },
    {
      reference: "bullets10",
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

function bulletMulti(runs, ref = "bullets") {
  return multiRun(runs, { numbering: { reference: ref, level: 0 } });
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
function coverPage(title, subtitle) {
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
  items.push(p(title, { size: 48, bold: true, color: CHARCOAL, alignment: AlignmentType.CENTER, spacing: { before: 400, after: 200 } }));
  if (subtitle) {
    items.push(p(subtitle, { size: 24, color: GREY, alignment: AlignmentType.CENTER, spacing: { after: 400 } }));
  }
  items.push(orangeAccentRule());
  items.push(p("", { spacing: { after: 600 } }));
  items.push(p("May 1, 2026", { size: 22, color: GREY, alignment: AlignmentType.CENTER, spacing: { after: 200 } }));
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

function coverSectionProps() {
  return {
    page: {
      size: { width: 12240, height: 15840 },
      margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 }
    }
  };
}

function contentSectionProps() {
  return {
    page: {
      size: { width: 12240, height: 15840 },
      margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 }
    },
    headers: { default: makeHeader() },
    footers: { default: makeFooter() }
  };
}

// ===== LOAD TICKETS FROM CSV =====
function loadTickets() {
  const csvPath = path.join(__dirname, "..", "03_SOW", "SOW-AFFG-004-Tickets.csv");
  const raw = fs.readFileSync(csvPath, "utf-8");
  const lines = raw.trim().split("\n");
  const tickets = [];
  for (let i = 1; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line) continue;
    // Parse CSV with quoted fields
    const fields = [];
    let current = "";
    let inQuotes = false;
    for (let c = 0; c < line.length; c++) {
      if (line[c] === '"') {
        inQuotes = !inQuotes;
      } else if (line[c] === ',' && !inQuotes) {
        fields.push(current.trim());
        current = "";
      } else {
        current += line[c];
      }
    }
    fields.push(current.trim());
    tickets.push({
      ticket: fields[0] || "",
      title: fields[1] || "",
      phase: fields[2] || "",
      description: fields[3] || "",
      hours: fields[4] || "",
      assignedTo: fields[5] || "",
      frequency: fields[6] || ""
    });
  }
  return tickets;
}

function ticketsForPhase(allTickets, phasePrefix) {
  return allTickets.filter(t => t.phase.startsWith(phasePrefix));
}

function makeTicketTable(tickets) {
  const headers = ["Ticket", "Title", "Assigned To", "Est. Hours"];
  const widths = [1600, 4200, 1600, 960];
  const rows = tickets.map(t => [t.ticket, t.title, t.assignedTo, t.hours]);
  // Add total row
  const totalHours = tickets.reduce((sum, t) => sum + (parseFloat(t.hours) || 0), 0);
  rows.push([{ text: "", bold: true }, { text: "Phase Total", bold: true }, { text: "", bold: true }, { text: String(totalHours), bold: true }]);
  return makeTable(headers, rows, widths);
}

// ===== GENERATE SOW =====
async function generateSOW() {
  const allTickets = loadTickets();
  const content = [];

  // ---- SOW Header ----
  content.push(heading1("STATEMENT OF WORK"));
  content.push(multiRun([
    { text: "SOW Number: ", bold: true, color: CHARCOAL },
    { text: "SOW-AFFG-004" }
  ]));
  content.push(multiRun([
    { text: "Title: ", bold: true, color: CHARCOAL },
    { text: "VDI-to-Managed-Device Migration" }
  ]));
  content.push(multiRun([
    { text: "Effective Date: ", bold: true, color: CHARCOAL },
    { text: "May 1, 2026" }
  ]));
  content.push(multiRun([
    { text: "Parent Agreement: ", bold: true, color: CHARCOAL },
    { text: "MSA-AFFG-2026" }
  ]));
  content.push(multiRun([
    { text: "Source: ", bold: true, color: CHARCOAL },
    { text: "AFFG Managed Device Strategy (REF: AFFG-MDS-2026-04, April 2026)" }
  ]));
  content.push(multiRun([
    { text: "Regulatory Scope: ", bold: true, color: CHARCOAL },
    { text: "SEC Reg S-P (2024 Amendments), FINRA Rule 3110, FINRA Rule 4370, SEC Rule 17a-4, NIST SP 800-53 Rev 5" }
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
  content.push(p("American Fundstars Financial Group LLC (\u201CClient\u201D or \u201CAFFG\u201D)", { bold: true, color: CHARCOAL }));
  content.push(p("1 Park Plaza, Suite 210"));
  content.push(p("Irvine, California 92618"));
  content.push(multiRun([{ text: "Primary Contact: ", bold: true, color: CHARCOAL }, { text: "Iris Liu" }]));
  content.push(spacer());

  content.push(multiRun([
    { text: "Supersedes: ", bold: true, color: CHARCOAL },
    { text: "SOW-AFFG-003 (IT Compliance & VDI Implementation). Upon completion of this SOW, the Horizon VDI infrastructure deployed under SOW-AFFG-003 Phase 1 will be decommissioned. All compliance controls previously enforced via VDI are migrated to managed endpoints with CloudBrink ZTNA. The monthly recurring charges in Schedule A of MSA-AFFG-2026 will be amended per Section 8 of this SOW." }
  ]));
  content.push(brandRule());

  // ---- 1. PROJECT OVERVIEW ----
  content.push(heading1("1. PROJECT OVERVIEW"));

  content.push(p("Technijian will deliver a 6-phase implementation that migrates AFFG from the Technijian Horizon VDI environment (deployed under SOW-AFFG-003) to a managed-device model using company-owned, Intune-managed laptops and phones with CloudBrink Zero Trust Network Access (ZTNA). This migration maintains the identical SEC/FINRA compliance posture established under SOW-AFFG-003 while eliminating VDI hosting costs, improving user experience, and enabling secure access from any location."));
  content.push(spacer());

  content.push(heading2("1.1 Objectives"));
  content.push(bullet("Enroll 9 company laptops in Microsoft Intune via Windows Autopilot with full endpoint security stack", "bullets"));
  content.push(bullet("Deploy CloudBrink ZTNA to replace VDI egress IP whitelist with device-posture-based access", "bullets"));
  content.push(bullet("Migrate MyAudit UAM+DLP, SSO/2FA gateway, and Credential Manager from VDI to managed endpoints", "bullets"));
  content.push(bullet("Enroll 9 company phones in Intune MDM with App Protection (MAM) policies", "bullets"));
  content.push(bullet("Execute controlled VDI-to-managed-device migration with parallel operation window", "bullets"));
  content.push(bullet("Decommission Horizon VDI infrastructure and amend Schedule A for monthly savings", "bullets"));
  content.push(spacer());

  content.push(heading2("1.2 Exclusions"));
  content.push(bullet("CloudBrink per-user subscription licensing (procured directly by AFFG)", "bullets2"));
  content.push(bullet("Hardware procurement (AFFG provides company laptops and phones)", "bullets2"));
  content.push(bullet("Technijian My Archive (AFFG operates own email-archiving platform)", "bullets2"));
  content.push(brandRule());

  // ---- 2. IMPLEMENTATION SCOPE (6 Phases) ----
  content.push(heading1("2. IMPLEMENTATION SCOPE"));

  // Phase 1
  const phase1Tickets = ticketsForPhase(allTickets, "Phase 1");
  content.push(heading2("Phase 1: Endpoint Foundation (Weeks 1\u20134)"));
  content.push(p("8 tickets  |  26 hours", { bold: true, color: TEAL }));
  content.push(spacer());
  content.push(p("Configure Intune Autopilot, compliance policies, device configuration profiles, enroll and image all 9 laptops, deploy full security stack (CrowdStrike, Huntress, DNS, Patch Mgmt, ScreenConnect), MyAudit UAM+DLP, SSO/2FA gateway, and Credential Manager on all managed laptops."));
  content.push(spacer());
  content.push(heading3("Phase 1 Tickets"));
  content.push(makeTicketTable(phase1Tickets));
  content.push(spacer());

  // Phase 2
  const phase2Tickets = ticketsForPhase(allTickets, "Phase 2");
  content.push(heading2("Phase 2: Access Control (Weeks 3\u20136)"));
  content.push(p("5 tickets  |  16 hours", { bold: true, color: TEAL }));
  content.push(spacer());
  content.push(p("Configure Entra Conditional Access (require compliant device, block legacy auth, require MFA), deploy CloudBrink ZTNA (tenant, connector, agent on 9 laptops, per-app policies), migrate Schwab and IBKR from IP whitelist to ZTNA."));
  content.push(spacer());
  content.push(heading3("Phase 2 Tickets"));
  content.push(makeTicketTable(phase2Tickets));
  content.push(spacer());

  // Phase 3
  const phase3Tickets = ticketsForPhase(allTickets, "Phase 3");
  content.push(heading2("Phase 3: Mobile Device Control (Weeks 5\u20138)"));
  content.push(p("3 tickets  |  8 hours", { bold: true, color: TEAL }));
  content.push(spacer());
  content.push(p("Enroll 9 company phones in Intune MDM, deploy App Protection (MAM) policies, configure remote wipe and termination procedures."));
  content.push(spacer());
  content.push(heading3("Phase 3 Tickets"));
  content.push(makeTicketTable(phase3Tickets));
  content.push(spacer());

  // Phase 4
  const phase4Tickets = ticketsForPhase(allTickets, "Phase 4");
  content.push(heading2("Phase 4: Migration & Cutover (Weeks 7\u201312)"));
  content.push(p("4 tickets  |  17 hours", { bold: true, color: TEAL }));
  content.push(spacer());
  content.push(p("Migrate data from VDI to managed laptops, user training, 2-week parallel operation window, VDI decommission and cleanup."));
  content.push(spacer());
  content.push(heading3("Phase 4 Tickets"));
  content.push(makeTicketTable(phase4Tickets));
  content.push(spacer());

  // Phase 5
  const phase5Tickets = ticketsForPhase(allTickets, "Phase 5");
  content.push(heading2("Phase 5: Monitoring & Validation (Weeks 11\u201314)"));
  content.push(p("4 tickets  |  13 hours", { bold: true, color: TEAL }));
  content.push(spacer());
  content.push(p("Expand monitoring to device fleet + CloudBrink + mobile, configure mobile device audit, end-to-end security validation, post-migration compliance gap assessment."));
  content.push(spacer());
  content.push(heading3("Phase 5 Tickets"));
  content.push(makeTicketTable(phase5Tickets));
  content.push(spacer());

  // Phase 6
  const phase6Tickets = ticketsForPhase(allTickets, "Phase 6");
  content.push(heading2("Phase 6: Documentation Update (Weeks 13\u201316)"));
  content.push(p("2 tickets  |  9 hours", { bold: true, color: TEAL }));
  content.push(spacer());
  content.push(p("Update all SOW-003 compliance documents for managed-device architecture, draft Schedule A amendment."));
  content.push(spacer());
  content.push(heading3("Phase 6 Tickets"));
  content.push(makeTicketTable(phase6Tickets));
  content.push(brandRule());

  // ---- 3. CONTROL-TO-CITATION MAP ----
  content.push(heading1("3. CONTROL-TO-CITATION MAP"));
  content.push(p("The following table maps each design component of the managed-device architecture to its control objective and the specific regulatory citations it satisfies:"));
  content.push(spacer());
  content.push(makeTable(
    ["Design Component", "Control Objective", "Citation(s)"],
    [
      [
        "Intune-managed company laptops",
        "All 9 users on company-owned, encrypted, policy-enforced devices",
        "Reg S-P 248.30(a)(1)-(3); FINRA 3110(a)"
      ],
      [
        "Conditional Access + legacy auth block",
        "Entra ID restricts M365 to compliant devices. IMAP/POP3/SMTP blocked",
        "Reg S-P 248.30(a)(3); NIST AC-3, IA-2(1)"
      ],
      [
        "CloudBrink ZTNA",
        "Zero-trust access replaces IP whitelist. Device posture verified per session",
        "Reg S-P 248.30(a)(3); NIST AC-17, SC-7"
      ],
      [
        "Technijian MyAudit (endpoint DLP)",
        "Block USB, local download, print, clipboard, screen capture",
        "Reg S-P 248.30(a)(3); NIST AC-19, MP-7"
      ],
      [
        "Technijian SSO/2FA gateway",
        "Enforced, logged MFA on custodian portals and third-party SaaS",
        "Reg S-P 248.30 (2024); NIST IA-2(1)"
      ],
      [
        "Intune MDM/MAM (company phones)",
        "Phone enrollment, app containerization, remote wipe",
        "Reg S-P 248.30(a)(1)-(3); NIST AC-19, MP-6"
      ],
      [
        "Technijian Veeam Backup for M365",
        "Immutable, non-rewriteable backup of full M365 tenant",
        "SEC Rule 17a-4(b),(f); FINRA 4511"
      ],
      [
        "Technijian monthly assessment",
        "Detect drift; attested evidence of ongoing control operation",
        "FINRA 3110(c); FINRA 3120"
      ]
    ],
    [2700, 3600, 3060]
  ));
  content.push(brandRule());

  // ---- 4. DELIVERABLES ----
  content.push(heading1("4. DELIVERABLES"));
  content.push(bullet("9 Intune-managed company laptops with full Technijian security stack", "bullets3"));
  content.push(bullet("CloudBrink ZTNA deployed with per-application micro-segmented access", "bullets3"));
  content.push(bullet("Schwab and IBKR migrated from IP whitelist to CloudBrink ZTNA", "bullets3"));
  content.push(bullet("Conditional Access: M365 restricted to compliant managed devices, legacy auth blocked", "bullets3"));
  content.push(bullet("MyAudit UAM+DLP on all 9 managed laptops (replaces VDI-based deployment)", "bullets3"));
  content.push(bullet("SSO/2FA gateway on all managed endpoints for custodian portals", "bullets3"));
  content.push(bullet("9 company phones enrolled in Intune MDM with App Protection policies", "bullets3"));
  content.push(bullet("Updated compliance documentation suite reflecting managed-device architecture", "bullets3"));
  content.push(bullet("Schedule A amendment reflecting monthly cost reduction", "bullets3"));
  content.push(bullet("Post-migration compliance gap assessment confirming equivalent regulatory posture", "bullets3"));
  content.push(brandRule());

  // ---- 5. PRICING AND PAYMENT ----
  content.push(heading1("5. PRICING AND PAYMENT"));

  content.push(heading2("5.1 Labor Summary"));
  content.push(makeTable(
    ["Role", "Rate", "Hours", "Labor"],
    [
      ["US Tech Support (IRV-TS1)", "$150/hr", "24", "$3,600.00"],
      ["India Tech Support (CHD-TS1)", "$45/hr", "65", "$2,925.00"],
      [{ text: "TOTAL", bold: true }, { text: "", bold: true }, { text: "89 hrs", bold: true }, { text: "$6,525.00", bold: true }]
    ],
    [2800, 1800, 1800, 2960]
  ));
  content.push(spacer());

  content.push(heading2("5.2 Payment Schedule"));
  content.push(makeTable(
    ["Milestone", "Trigger", "Amount"],
    [
      ["50% upon SOW execution", "SOW signed by both parties", "$3,262.50"],
      ["25% upon Phase 4 completion", "VDI decommissioned", "$1,631.25"],
      ["25% upon Phase 6 delivery", "Documentation + Schedule A amendment accepted", "$1,631.25"],
      [{ text: "Total", bold: true }, { text: "", bold: true }, { text: "$6,525.00", bold: true }]
    ],
    [2800, 3560, 2960]
  ));
  content.push(spacer());

  content.push(heading2("5.3 Payment Terms"));
  content.push(p("All invoices are due and payable within thirty (30) days of the invoice date. Late payments are subject to a late fee of 1.5% per month on the unpaid balance."));
  content.push(brandRule());

  // ---- 6. ASSUMPTIONS ----
  content.push(heading1("6. ASSUMPTIONS"));
  content.push(bullet("AFFG has procured 9 company laptops (Windows 11 Pro or Enterprise) suitable for Intune Autopilot enrollment", "bullets4"));
  content.push(bullet("AFFG has procured 9 company phones (iOS or Android) for Intune MDM enrollment", "bullets4"));
  content.push(bullet("AFFG has procured CloudBrink ZTNA per-user subscription licenses for 9 users", "bullets4"));
  content.push(bullet("AFFG\u2019s M365 tenant remains licensed at E3 or E5 (Intune, Conditional Access, DLP included)", "bullets4"));
  content.push(bullet("The 7 VDI agents are available for managed-device migration and training during Weeks 7\u201310", "bullets4"));
  content.push(bullet("Schwab Advisor Services and Interactive Brokers approve the transition from IP whitelist to CloudBrink ZTNA within their standard processing timelines", "bullets4"));
  content.push(bullet("All MyAudit UAM+DLP, SSO/2FA, and Credential Manager licenses are transferred from VDI to managed endpoints at no additional license cost during the transition period", "bullets4"));
  content.push(brandRule());

  // ---- 7. EXCLUSIONS ----
  content.push(heading1("7. EXCLUSIONS"));
  content.push(bullet("CloudBrink per-user subscription licensing (AFFG-procured)", "bullets5"));
  content.push(bullet("Hardware procurement (company laptops and phones)", "bullets5"));
  content.push(bullet("Microsoft 365 license costs (AFFG procures directly)", "bullets5"));
  content.push(bullet("Technijian My Archive (AFFG operates own archiving)", "bullets5"));
  content.push(bullet("Any remediation beyond the scope described; significant issues discovered during migration scoped as separate change order", "bullets5"));
  content.push(brandRule());

  // ---- 8. MONTHLY COST IMPACT ----
  content.push(heading1("8. MONTHLY COST IMPACT"));

  content.push(heading2("8.1 Current vs. Proposed Monthly Recurring"));
  content.push(p("Current Monthly (SOW-003 implemented, VDI model) = $5,770.45/mo", { bold: true, color: CHARCOAL }));
  content.push(spacer());
  content.push(makeTable(
    ["Category", "Current Monthly", "Proposed Monthly", "Change"],
    [
      ["Horizon VDI Workstations (7 agents)", "$2,433.20", "$0.00", "-$2,433.20"],
      ["Managed Laptop Add-Ons (9 endpoints)", "$0.00", "$1,125.90", "+$1,125.90"],
      ["Physical Desktop Security (9)", "$238.50", "$238.50", "$0.00"],
      ["All-User Services (31 M365 users)", "$441.75", "$441.75", "$0.00"],
      ["Domain / Site / IP Services", "$162.00", "$162.00", "$0.00"],
      ["Production Storage (VDI profiles)", "$400.00", "$0.00", "-$400.00"],
      ["Backup Storage (V365 / SEC 17a-4)", "$100.00", "$100.00", "$0.00"],
      ["Virtual Staff Support (unchanged)", "$1,995.00", "$1,995.00", "$0.00"],
      [{ text: "TOTAL MONTHLY", bold: true }, { text: "$5,770.45", bold: true }, { text: "$4,063.15", bold: true }, { text: "-$1,707.30", bold: true }]
    ],
    [2800, 1800, 1800, 1960]
  ));
  content.push(spacer());

  content.push(heading2("8.2 Managed Laptop Add-Ons Detail (NEW \u2014 9 endpoints)"));
  content.push(makeTable(
    ["Service", "Code", "Qty", "Unit Price", "Monthly"],
    [
      ["MyAudit UAM+DLP / 1-Year", "AMDLP1Y", "9", "$108.10", "$972.90"],
      ["SSO / Multi-Factor", "SSO-2FA", "9", "$12.00", "$108.00"],
      ["Credential Manager", "CRM", "9", "$5.00", "$45.00"],
      [{ text: "Subtotal", bold: true }, { text: "", bold: true }, { text: "", bold: true }, { text: "", bold: true }, { text: "$1,125.90", bold: true }]
    ],
    [2400, 1400, 800, 1400, 1360]
  ));
  content.push(spacer());
  content.push(p("Note: Intune management included in M365 E3. CloudBrink subscription AFFG-procured. Physical desktop security stack ($26.50/desktop) unchanged.", { italics: true }));
  content.push(brandRule());

  // ---- 9. CHANGE MANAGEMENT ----
  content.push(heading1("9. CHANGE MANAGEMENT"));
  content.push(p("9.01. Any changes to the scope, schedule, or pricing of this SOW must be documented in a written Change Order signed by both Parties before work on the change begins."));
  content.push(spacer());
  content.push(p("9.02. If Client requests work outside the defined scope, Technijian shall provide a Change Order detailing the additional work, estimated hours, and cost impact."));
  content.push(spacer());
  content.push(p("9.03. Technijian shall not proceed with out-of-scope work without an approved Change Order, except in cases where delay would result in harm to Client\u2019s systems, in which case Technijian shall notify Client as soon as practicable."));
  content.push(brandRule());

  // ---- 10. ACCEPTANCE ----
  content.push(heading1("10. ACCEPTANCE"));
  content.push(p("10.01. Upon completion of each phase, Technijian shall notify Client in writing that the deliverables are ready for review."));
  content.push(spacer());
  content.push(p("10.02. Client shall review the deliverables and provide written acceptance or a detailed description of deficiencies within five (5) business days."));
  content.push(spacer());
  content.push(p("10.03. If Client does not respond within the review period, the deliverables shall be deemed accepted."));
  content.push(spacer());
  content.push(p("10.04. If deficiencies are identified, Technijian shall correct them and resubmit for review. This process shall repeat until acceptance is achieved or the Parties agree on a resolution."));
  content.push(brandRule());

  // ---- 11. GOVERNING TERMS ----
  content.push(heading1("11. GOVERNING TERMS"));
  content.push(p("11.01. This SOW is governed by the Master Service Agreement MSA-AFFG-2026 between the Parties. In the event of a conflict between this SOW and the MSA, the MSA shall prevail unless this SOW expressly states otherwise."));
  content.push(brandRule());

  // ---- SIGNATURES ----
  content.push(heading1("SIGNATURES"));
  content.push(spacer());
  content.push(p("TECHNIJIAN, INC.", { bold: true, color: CHARCOAL }));
  content.push(spacer());
  content.push(p("By: ___________________________________"));
  content.push(spacer());
  content.push(p("Name: _________________________________"));
  content.push(spacer());
  content.push(p("Title: _________________________________"));
  content.push(spacer());
  content.push(p("Date: _________________________________"));
  content.push(spacer());
  content.push(spacer());
  content.push(p("AMERICAN FUNDSTARS FINANCIAL GROUP LLC", { bold: true, color: CHARCOAL }));
  content.push(spacer());
  content.push(p("By: ___________________________________"));
  content.push(spacer());
  content.push(p("Name: _________________________________"));
  content.push(spacer());
  content.push(p("Title: _________________________________"));
  content.push(spacer());
  content.push(p("Date: _________________________________"));

  // ===== BUILD DOCUMENT =====
  const doc = new Document({
    styles: docStyles,
    numbering,
    sections: [
      {
        properties: coverSectionProps(),
        children: coverPage(
          "Statement of Work",
          "VDI-to-Managed-Device Migration \u2014 American Fundstars Financial Group LLC"
        )
      },
      {
        properties: contentSectionProps(),
        children: content
      }
    ]
  });

  const buffer = await Packer.toBuffer(doc);
  const outputPath = path.join(__dirname, "..", "03_SOW", "SOW-AFFG-004-Managed-Device-Migration.docx");
  fs.writeFileSync(outputPath, buffer);
  console.log("Generated:", outputPath);
}

generateSOW().catch(err => {
  console.error("Error generating SOW:", err);
  process.exit(1);
});
