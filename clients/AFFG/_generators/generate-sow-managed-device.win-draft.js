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

// sigLine renders a signature-block line (By: ___, Name: ___, etc.)
// with an invisible 1pt white-text DocuSign anchor tag at the start
// so send-docusign.ps1 can place signature/name/title/date fields precisely.
function sigLine(label, anchor) {
  return new Paragraph({
    spacing: { after: 40 },
    children: [
      new TextRun({ text: anchor, font: FONT, size: 2, color: WHITE }),
      new TextRun({ text: label, font: FONT, size: 20, color: GREY }),
    ]
  });
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
    { text: "Managed Device Control Deployment" }
  ]));
  content.push(multiRun([
    { text: "Effective Date: ", bold: true, color: CHARCOAL },
    { text: "May 1, 2026" }
  ]));
  content.push(multiRun([
    { text: "Parent Agreement: ", bold: true, color: CHARCOAL },
    { text: "Client Monthly Service Agreement (DocuSign Envelope F3CDFC05-B156-8A6F-8020-13A164F4E3F1, effective March 11, 2026), as amended by Section 12 of this SOW" }
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
    { text: "Note: ", bold: true, color: CHARCOAL },
    { text: "This SOW deploys the managed-device control architecture presented in the AFFG Managed Device Strategy (REF: AFFG-MDS-2026-04) as the implementation path selected by Client. The starting state is the network defined in the signed MSA-AFFG-2026 Schedule A (no VDI deployed). The monthly recurring charges in Schedule A of MSA-AFFG-2026 will be amended per Section 8 of this SOW to add the managed device control services." }
  ]));
  content.push(brandRule());

  // ---- 1. PROJECT OVERVIEW ----
  content.push(heading1("1. PROJECT OVERVIEW"));

  content.push(p("Technijian will deliver a 6-phase implementation that deploys a managed-device control architecture for AFFG, consisting of company-owned Intune-managed laptops and phones, CloudBrink Zero Trust Network Access (ZTNA), Entra Conditional Access, endpoint DLP, and SSO/2FA. The starting state is the existing production network defined in MSA-AFFG-2026 Schedule A, in which users access M365, Schwab Advisor Services, and Interactive Brokers from mixed/personal devices gated by office-IP whitelist and MFA. This SOW establishes a fully SEC/FINRA-compliant endpoint control posture for all 9 users and their company phones, enables secure access from any network, and produces the attested evidence required under FINRA 3110(c)."));
  content.push(spacer());

  content.push(heading2("1.1 Objectives"));
  content.push(bullet("Enroll 9 company laptops in Microsoft Intune via Windows Autopilot with full endpoint security stack", "bullets"));
  content.push(bullet("Deploy CloudBrink ZTNA to replace the existing office-IP whitelist with device-posture-based access from any network", "bullets"));
  content.push(bullet("Deploy MyAudit UAM+DLP, SSO/2FA gateway, and Credential Manager on all 9 managed laptops", "bullets"));
  content.push(bullet("Enroll 9 company phones in Intune MDM with App Protection (MAM) policies", "bullets"));
  content.push(bullet("Configure Entra Conditional Access (compliant-device requirement, legacy-auth block, MFA) and cut over users from their existing devices to the managed laptops via a phased pilot", "bullets"));
  content.push(bullet("Amend Schedule A of MSA-AFFG-2026 to add the managed-device control services and produce the updated monthly recurring", "bullets"));
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
  content.push(p("Configure Entra Conditional Access (require compliant device, block legacy auth, require MFA), deploy CloudBrink ZTNA (tenant, connector, agent on 9 laptops, per-app policies), and transition Schwab Advisor Services and Interactive Brokers custodian access from the existing office-IP whitelist to CloudBrink ZTNA."));
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
  content.push(heading2("Phase 4: User Cutover (Weeks 7\u201312)"));
  content.push(p("4 tickets  |  17 hours", { bold: true, color: TEAL }));
  content.push(spacer());
  content.push(p("Migrate user data, application settings, and profiles from each user\u2019s existing work device to the new managed laptop; deliver end-user training on the managed-device workflow; run a 2-week pilot operation window with 2\u20133 users on the managed laptops before fleet cutover; and decommission the legacy office-IP whitelist from Schwab and IBKR after ZTNA is validated."));
  content.push(spacer());
  content.push(heading3("Phase 4 Tickets"));
  content.push(makeTicketTable(phase4Tickets));
  content.push(spacer());

  // Phase 5
  const phase5Tickets = ticketsForPhase(allTickets, "Phase 5");
  content.push(heading2("Phase 5: Monitoring & Validation (Weeks 11\u201314)"));
  content.push(p("4 tickets  |  13 hours", { bold: true, color: TEAL }));
  content.push(spacer());
  content.push(p("Expand the existing monthly assessment to include device fleet + CloudBrink + mobile, configure monthly mobile device audit, perform end-to-end security validation, and produce a post-deployment compliance gap assessment confirming every control-to-citation commitment is met."));
  content.push(spacer());
  content.push(heading3("Phase 5 Tickets"));
  content.push(makeTicketTable(phase5Tickets));
  content.push(spacer());

  // Phase 6
  const phase6Tickets = ticketsForPhase(allTickets, "Phase 6");
  content.push(heading2("Phase 6: Documentation Update (Weeks 13\u201316)"));
  content.push(p("2 tickets  |  9 hours", { bold: true, color: TEAL }));
  content.push(spacer());
  content.push(p("Produce the compliance documentation suite aligned with the managed-device architecture (IRP, BCP disclosure, Service Provider Oversight, supervisory audit-trail architecture) and draft the Schedule A amendment to MSA-AFFG-2026 adding the managed-device control services."));
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
  content.push(bullet("Schwab and IBKR transitioned from office-IP whitelist to CloudBrink ZTNA", "bullets3"));
  content.push(bullet("Conditional Access: M365 restricted to compliant managed devices, legacy auth blocked", "bullets3"));
  content.push(bullet("MyAudit UAM+DLP deployed on all 9 managed laptops", "bullets3"));
  content.push(bullet("SSO/2FA gateway deployed on all managed endpoints for custodian portals", "bullets3"));
  content.push(bullet("9 company phones enrolled in Intune MDM with App Protection policies", "bullets3"));
  content.push(bullet("Compliance documentation suite aligned with managed-device architecture", "bullets3"));
  content.push(bullet("Schedule A amendment to MSA-AFFG-2026 adding managed-device control services", "bullets3"));
  content.push(bullet("Post-deployment compliance gap assessment confirming all control-to-citation commitments are met", "bullets3"));
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
      ["25% upon Phase 4 completion", "Fleet cutover complete (all 9 users operating on managed laptops)", "$1,631.25"],
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
  content.push(bullet("All 9 AFFG users are available for cutover coordination and training during Weeks 7\u201312", "bullets4"));
  content.push(bullet("Schwab Advisor Services and Interactive Brokers approve the transition from the existing office-IP whitelist to CloudBrink ZTNA within their standard processing timelines", "bullets4"));
  content.push(bullet("Starting-state network is the production network defined in the signed MSA-AFFG-2026 Schedule A; no Horizon VDI environment is in place and none is deployed as part of this SOW", "bullets4"));
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
  content.push(p("Baseline is the signed MSA-AFFG-2026 Schedule A as reflected on the executed Monthly Service Quote dated March 2026. Under this SOW the endpoint fleet is consolidated from the 16 existing desktops to 9 company-owned, Intune-managed laptops. The 31 M365 user services, 6 IP services, 1 domain service, and Virtual Staff Support are not altered by this SOW.", { italics: true }));
  content.push(spacer());
  content.push(p("Current Monthly (signed MSA Schedule A, no VDI) = $2,794.50/mo", { bold: true, color: CHARCOAL }));
  content.push(spacer());
  content.push(makeTable(
    ["Category", "Current Monthly", "Proposed Monthly", "Change"],
    [
      ["Desktop Security Stack (Current: 16 desktops \u2192 Proposed: 9 managed laptops)", "$424.00", "$238.50", "-$185.50"],
      ["Managed Laptop Control Stack (NEW \u2014 9 endpoints: AMDLP1Y, SSO-2FA, CRM)", "$0.00", "$1,125.90", "+$1,125.90"],
      ["M365 User Services (31 users: V365, PHT)", "$263.50", "$263.50", "$0.00"],
      ["IP Services (6 IPs: RTPT)", "$42.00", "$42.00", "$0.00"],
      ["Domain Services (1 domain: SA, DKIM)", "$70.00", "$70.00", "$0.00"],
      ["Virtual Staff Support (IRV + CHD + CTO)", "$1,995.00", "$1,995.00", "$0.00"],
      [{ text: "TOTAL MONTHLY", bold: true }, { text: "$2,794.50", bold: true }, { text: "$3,734.90", bold: true }, { text: "+$940.40", bold: true }]
    ],
    [3360, 1800, 1800, 1560]
  ));
  content.push(spacer());

  content.push(heading2("8.2 Current Desktop Security Stack Detail (16 desktops, per signed MSA)"));
  content.push(makeTable(
    ["Service", "Code", "Qty", "Unit Price", "Monthly"],
    [
      ["AV Protection \u2014 Desktop (CrowdStrike)", "AVD", "16", "$8.50", "$136.00"],
      ["AVH Protection \u2014 Desktop (Huntress)", "AVMH", "16", "$6.00", "$96.00"],
      ["My Secure Internet (DNS Filtering)", "SI", "16", "$6.00", "$96.00"],
      ["Patch Management", "PMW", "16", "$4.00", "$64.00"],
      ["My Remote", "MR", "16", "$2.00", "$32.00"],
      [{ text: "Subtotal (signed)", bold: true }, { text: "", bold: true }, { text: "16", bold: true }, { text: "$26.50", bold: true }, { text: "$424.00", bold: true }]
    ],
    [2600, 1200, 800, 1400, 1360]
  ));
  content.push(spacer());

  content.push(heading2("8.3 Proposed Endpoint Stack Detail (9 managed laptops)"));
  content.push(p("The same Technijian desktop security stack (AVD, AVMH, SI, PMW, MR) is deployed to the 9 managed laptops under Phase 1 Ticket AFFG-004-005. The reduction from 16 units to 9 units yields a -$185.50/mo savings on that stack. The Managed Laptop Control Stack (AMDLP1Y + SSO-2FA + CRM) is the NEW capability added by this SOW to satisfy Reg S-P 2024 endpoint DLP, MFA gateway, and credential vault requirements.", { italics: true }));
  content.push(spacer());
  content.push(makeTable(
    ["Service", "Code", "Qty", "Unit Price", "Monthly"],
    [
      [{ text: "Desktop Security Stack (retained, reduced to 9 units)", bold: true, color: CHARCOAL }, "", "", "", ""],
      ["AV Protection \u2014 Desktop (CrowdStrike)", "AVD", "9", "$8.50", "$76.50"],
      ["AVH Protection \u2014 Desktop (Huntress)", "AVMH", "9", "$6.00", "$54.00"],
      ["My Secure Internet (DNS Filtering)", "SI", "9", "$6.00", "$54.00"],
      ["Patch Management", "PMW", "9", "$4.00", "$36.00"],
      ["My Remote", "MR", "9", "$2.00", "$18.00"],
      [{ text: "Managed Laptop Control Stack (NEW)", bold: true, color: CHARCOAL }, "", "", "", ""],
      ["MyAudit UAM+DLP / 1-Year", "AMDLP1Y", "9", "$108.10", "$972.90"],
      ["SSO / Multi-Factor", "SSO-2FA", "9", "$12.00", "$108.00"],
      ["Credential Manager", "CRM", "9", "$5.00", "$45.00"],
      [{ text: "Subtotal per laptop", bold: true }, { text: "", bold: true }, { text: "9", bold: true }, { text: "$151.60", bold: true }, { text: "$1,364.40", bold: true }]
    ],
    [2600, 1200, 800, 1400, 1360]
  ));
  content.push(spacer());
  content.push(p("Notes: Intune management for the 9 laptops and 9 company phones is included in the M365 E3 license AFFG already holds \u2014 no additional Technijian charge. CloudBrink ZTNA subscription is AFFG-procured and therefore excluded from the Schedule A amendment. Per-managed-laptop monthly = $151.60 ($26.50 desktop security + $125.10 managed control).", { italics: true }));
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
  content.push(p("11.01. This SOW is governed by the Client Monthly Service Agreement between the Parties executed via DocuSign on March 11, 2026 (DocuSign Envelope F3CDFC05-B156-8A6F-8020-13A164F4E3F1) (the \u201COriginal Agreement\u201D), as amended by Section 12 of this SOW. In the event of a conflict between this SOW (including Section 12 and Exhibit A) and the Original Agreement, this SOW shall prevail."));
  content.push(brandRule());

  // ---- 12. INCORPORATION OF 2026 MSA FRAMEWORK ----
  content.push(heading1("12. INCORPORATION OF 2026 MSA FRAMEWORK (AMENDMENT TO ORIGINAL AGREEMENT)"));
  content.push(p("12.01. Purpose. This Section 12 is a mutual written amendment to the Original Agreement, executed pursuant to California Civil Code \u00A7 1698(a) (\u201CA contract in writing may be modified by a contract in writing\u201D). The Parties enter into this amendment to update the Original Agreement to reflect Technijian\u2019s 2026 Master Service Agreement framework, which contains additional legal and data-protection provisions appropriate to AFFG\u2019s status as a dually registered Investment Adviser and Broker-Dealer subject to SEC Regulation S-P (including the 2024 Amendments), FINRA Rule 3110, FINRA Rule 4370, and SEC Rule 17a-4."));
  content.push(spacer());
  content.push(p("12.02. Incorporation by Reference. Upon execution of this SOW by both Parties, Sections 2 through 10 of Technijian\u2019s 2026 Master Service Agreement framework (the \u201CMSA Framework Provisions\u201D), the full text of which is set forth in Exhibit A attached hereto and incorporated herein by this reference, shall apply to the Original Agreement and to this SOW as if fully set forth in the Original Agreement."));
  content.push(spacer());
  content.push(p("12.03. Addition and Substitution. The MSA Framework Provisions supplement the Original Agreement and, to the extent of any conflict with a corresponding provision of the Original Agreement, supersede such corresponding provision. For clarity:"));
  content.push(bullet("Section 2 (Term and Renewal), Section 3 (Payment), Section 4 (Confidentiality), Section 5 (Limitation of Liability), Section 6 (Indemnification), Section 7 (Intellectual Property), Section 8 (Dispute Resolution), Section 9 (General Provisions), and Section 10 (Data Protection) of the MSA Framework Provisions are added to the Original Agreement.", "bullets6"));
  content.push(bullet("The late-fee rate of 1.5% per month stated in the Original Agreement is consistent with Section 3.04 of the MSA Framework Provisions and remains unchanged.", "bullets6"));
  content.push(bullet("The Virtual Staff Support hours and rates under the Original Agreement (CTO Advisory 3 hrs @ $225, US Tech Support 6 hrs @ $125, India Tech Normal 22 hrs @ $15, India Tech After-Hours 8 hrs @ $30) remain UNCHANGED and carry forward.", "bullets6"));
  content.push(bullet("Section 9.01 (Entire Agreement) of the MSA Framework Provisions is hereby modified, for purposes of this amendment only, to provide that the Original Agreement is amended (not superseded) by this Section 12, and that the monthly service charges under the Original Agreement shall be updated only as expressly provided in Section 8 of this SOW.", "bullets6"));
  content.push(spacer());
  content.push(p("12.04. Effect on Services. Upon execution, all services provided by Technijian to Client \u2014 including the recurring services under Schedule A of the Original Agreement, the services described in this SOW, and any future Statement of Work executed between the Parties \u2014 shall be governed by the Original Agreement as amended by this Section 12. Future Statements of Work may reference the \u201CParent Agreement\u201D as \u201CClient Monthly Service Agreement as amended by SOW-AFFG-004 Section 12.\u201D"));
  content.push(spacer());
  content.push(p("12.05. No Other Changes. Except as expressly modified by this Section 12 and Section 8 of this SOW, the Original Agreement remains in full force and effect. Services already rendered, fees already paid, and rights already accrued under the Original Agreement are not affected."));
  content.push(spacer());
  content.push(p("12.06. Severability. If any provision of this Section 12 or of Exhibit A is held invalid or unenforceable by a court of competent jurisdiction, the remaining provisions of the Original Agreement (as amended) and this SOW shall continue in full force and effect."));
  content.push(spacer());
  content.push(p("12.07. Effective Date of Amendment. This amendment is effective upon execution of this SOW by authorized representatives of both Parties, and the MSA Framework Provisions shall govern services from and after the Effective Date stated in the SOW header."));
  content.push(brandRule());

  // ---- SIGNATURES ----
  content.push(heading1("SIGNATURES"));
  content.push(spacer());
  content.push(p("TECHNIJIAN, INC.", { bold: true, color: CHARCOAL }));
  content.push(spacer());
  content.push(sigLine("By: ___________________________________", "/tSign/"));
  content.push(sigLine("Name: _________________________________", "/tName/"));
  content.push(sigLine("Title: _________________________________", "/tTitle/"));
  content.push(sigLine("Date: _________________________________", "/tDate/"));
  content.push(spacer());
  content.push(spacer());
  content.push(p("AMERICAN FUNDSTARS FINANCIAL GROUP LLC", { bold: true, color: CHARCOAL }));
  content.push(spacer());
  content.push(sigLine("By: ___________________________________", "/cSign/"));
  content.push(sigLine("Name: _________________________________", "/cName/"));
  content.push(sigLine("Title: _________________________________", "/cTitle/"));
  content.push(sigLine("Date: _________________________________", "/cDate/"));

  // ---- EXHIBIT A ----
  content.push(new Paragraph({ children: [new PageBreak()] }));
  content.push(heading1("EXHIBIT A \u2014 2026 MSA FRAMEWORK PROVISIONS INCORPORATED BY REFERENCE"));
  content.push(p("The following provisions (Sections 2 through 10) are the \u201CMSA Framework Provisions\u201D incorporated into the Original Agreement by Section 12 of this SOW. This Exhibit A is an integral part of this SOW and of the Original Agreement as amended. Capitalized terms not defined herein have the meanings given in the Original Agreement or the SOW body.", { italics: true }));
  content.push(brandRule());

  // --- SECTION 2: TERM AND RENEWAL ---
  content.push(heading2("SECTION 2 \u2014 TERM AND RENEWAL"));
  content.push(p("2.01. Initial Term. This Agreement shall commence on the Effective Date and continue for a period of twelve (12) months (the \u201CInitial Term\u201D)."));
  content.push(spacer());
  content.push(p("2.02. Renewal. Upon expiration of the Initial Term, this Agreement shall automatically renew for successive twelve (12) month periods (each a \u201CRenewal Term\u201D), unless either Party provides written notice of non-renewal at least sixty (60) days prior to the expiration of the then-current term. Technijian shall send Client a written renewal reminder at least thirty (30) days prior to each renewal date, which shall restate the auto-renewal terms and cancellation method."));
  content.push(spacer());
  content.push(p("2.03. Termination for Convenience. Either Party may terminate this Agreement for any reason upon sixty (60) days written notice to the other Party."));
  content.push(spacer());
  content.push(p("2.04. Termination for Cause. Either Party may terminate this Agreement immediately upon written notice if the other Party:"));
  content.push(p("(a) Commits a material breach of this Agreement and fails to cure such breach within thirty (30) days after receiving written notice of the breach; or"));
  content.push(p("(b) Becomes insolvent, files for bankruptcy, or has a receiver appointed for its assets."));
  content.push(spacer());
  content.push(p("2.05. Effect of Termination."));
  content.push(p("(a) Upon termination, Client shall pay all fees and charges for services rendered through the date of termination, including any remaining obligations for annual licenses and subscriptions procured on Client\u2019s behalf, and any unpaid balance of contracted Virtual Staff Support hours actually worked in excess of contracted levels."));
  content.push(p("(b) Technijian shall provide reasonable transition assistance for a period of up to thirty (30) days following termination, subject to payment of applicable fees."));
  content.push(p("(c) Technijian shall return all Client Data in its possession within thirty (30) days of termination, in a commercially standard format, provided Client is not in breach of this Agreement."));
  content.push(p("(d) The following sections shall survive termination: Section 3 (Payment), Section 4 (Confidentiality), Section 5 (Limitation of Liability), Section 6 (Indemnification), Section 7 (Intellectual Property), Section 8 (Dispute Resolution), Section 9.09 (Personnel Transition Fee), and Section 10 (Data Protection)."));
  content.push(spacer());

  // --- SECTION 3: PAYMENT ---
  content.push(heading2("SECTION 3 \u2014 PAYMENT"));
  content.push(p("3.01. Fees. Client shall pay fees for the services as set forth in the applicable Schedule, SOW, or invoice. Fees are exclusive of applicable taxes."));
  content.push(spacer());
  content.push(p("3.02. Invoice Types. Client may receive the following types of invoices from Technijian during the term of this Agreement. Each invoice will clearly identify its type, the applicable Schedule or SOW, and the billing period or delivery event."));
  content.push(p("(a) Monthly Service Invoice. Issued on the first business day of each month for recurring managed services under Schedule A. Billed in advance for the upcoming month."));
  content.push(p("(b) Weekly In-Contract Invoice. Issued every Friday for Virtual Staff (contracted support) services performed under Schedule A during the preceding week (Monday through Friday). Each invoice includes: (i) a listing of each support ticket addressed; (ii) the assigned resource, role, and hours spent per ticket; (iii) a description of the work performed per ticket; (iv) whether work was performed during normal or after-hours; and (v) the current running balance for each contracted role."));
  content.push(p("(c) Weekly Out-of-Contract Invoice. Issued every Friday for labor services performed outside the scope of any active Schedule or SOW \u2014 including ad-hoc support requests, emergency work, and services performed under a SOW with hourly billing. Each invoice includes: (i) a listing of each support ticket or task performed; (ii) the assigned resource, role, and applicable hourly rate from the Rate Card (Schedule C); (iii) time entries with hours billed per activity (in 15-minute increments); (iv) whether work was performed during normal or after-hours; and (v) the total hours and total amount for the week."));
  content.push(p("(d) Equipment and Materials Invoice. Issued upon delivery or procurement of hardware, software licenses (perpetual), or other tangible goods on Client\u2019s behalf. Each invoice includes: (i) item description, manufacturer, and model/part number; (ii) quantity and unit price; (iii) applicable sales tax; (iv) shipping and handling charges, if any; and (v) total amount due. Title to equipment shall not pass to Client until payment is received in full."));
  content.push(p("(e) Project Milestone Invoice. Issued upon completion of a project milestone as defined in an applicable SOW. The milestone, deliverables, and invoiced amount are as specified in the payment schedule of the SOW. Milestone invoices are billed in arrears upon acceptance of the deliverables or deemed acceptance under the SOW\u2019s acceptance provisions."));
  content.push(spacer());
  content.push(p("3.03. Payment Terms. All invoices are due and payable within thirty (30) days of the invoice date, unless otherwise specified in the applicable Schedule or SOW."));
  content.push(spacer());
  content.push(p("3.04. Late Payment. Invoices not paid within terms shall accrue a late fee of 1.5% per month (or the maximum rate permitted by law, whichever is less) on the unpaid balance, calculated as simple interest from the date payment was due until the date payment is received in full. Late fees are payable in addition to the outstanding principal amount. The Parties acknowledge that the late fee represents a reasonable estimate of Technijian\u2019s administrative costs and damages resulting from late payment, including cash-flow disruption, collection overhead, and the cost of carrying accounts receivable, and is not intended as a penalty."));
  content.push(spacer());
  content.push(p("3.05. Disputed Invoices."));
  content.push(p("(a) Weekly Invoices (In-Contract and Out-of-Contract). Because weekly invoices include detailed ticket descriptions and time entries, Client shall have thirty (30) days from the invoice date to review and dispute any portion of a weekly invoice. Client shall notify Technijian in writing, specifying the ticket number(s) and nature of the dispute. Undisputed tickets and time entries on the same invoice shall remain payable by the due date. Failure to provide a timely written dispute notice within the thirty (30) day period shall constitute acceptance of all tickets and time entries on the invoice."));
  content.push(p("(b) All Other Invoices. For monthly service invoices, equipment invoices, and project milestone invoices, Client shall notify Technijian in writing within fifteen (15) days of the invoice date if Client disputes any portion, specifying the nature and basis of the dispute. Client shall pay all undisputed amounts by the due date. Failure to provide a timely written dispute notice shall constitute acceptance of the invoice."));
  content.push(p("(c) Resolution. The Parties shall work in good faith to resolve any invoice dispute within thirty (30) days of the dispute notice. If the dispute results in an adjustment, Technijian shall issue a credit memo or revised invoice within ten (10) business days of resolution."));
  content.push(spacer());
  content.push(p("3.06. Suspension of Services. If Client fails to pay any undisputed invoice within thirty (30) days of the due date, Technijian may, upon ten (10) days written notice, suspend services under the Schedule or SOW associated with the unpaid invoice until payment is received in full, including all accrued late fees. If Client fails to pay any undisputed invoice within sixty (60) days of the due date, Technijian may suspend all services under this Agreement and any related Schedules or SOWs. Recurring fees for suspended services shall continue to accrue for a period not to exceed thirty (30) days following the date of suspension, after which Technijian may terminate the affected Schedule, SOW, or this Agreement upon written notice. Suspension of services shall not relieve Client of its payment obligations."));
  content.push(spacer());
  content.push(p("3.07. Taxes. Client shall be responsible for all applicable sales, use, and other taxes arising from the services, excluding taxes based on Technijian\u2019s income."));
  content.push(spacer());

  // --- SECTION 4: CONFIDENTIALITY ---
  content.push(heading2("SECTION 4 \u2014 CONFIDENTIALITY"));
  content.push(p("4.01. Definition. \u201CConfidential Information\u201D means any non-public information disclosed by either Party to the other in connection with this Agreement, including business, technical, and financial information."));
  content.push(spacer());
  content.push(p("4.02. Obligations. Each Party shall:"));
  content.push(p("(a) Hold the other Party\u2019s Confidential Information in confidence using at least the same degree of care it uses for its own confidential information, but not less than reasonable care;"));
  content.push(p("(b) Not disclose Confidential Information to third parties without prior written consent, except to employees, agents, and subcontractors who have a need to know and are bound by equivalent obligations; and"));
  content.push(p("(c) Not use Confidential Information for any purpose other than performing obligations under this Agreement."));
  content.push(spacer());
  content.push(p("4.03. Exclusions. Confidential Information does not include information that is or becomes publicly available through no fault of the receiving Party, was known to the receiving Party prior to disclosure, is independently developed, or is received from a third party without restriction."));
  content.push(spacer());
  content.push(p("4.04. Compelled Disclosure. If required by law or court order to disclose Confidential Information, the receiving Party shall provide prompt written notice to the disclosing Party and cooperate in seeking a protective order."));
  content.push(spacer());
  content.push(p("4.05. Duration. Confidentiality obligations shall survive termination for a period of three (3) years."));
  content.push(spacer());

  // --- SECTION 5: LIMITATION OF LIABILITY ---
  content.push(heading2("SECTION 5 \u2014 LIMITATION OF LIABILITY"));
  content.push(p("5.01. EXCEPT AS PROVIDED IN SECTION 5.03 BELOW, NEITHER PARTY\u2019S TOTAL AGGREGATE LIABILITY UNDER THIS AGREEMENT SHALL EXCEED THE TOTAL FEES PAID OR PAYABLE BY CLIENT UNDER THIS AGREEMENT DURING THE TWELVE (12) MONTH PERIOD IMMEDIATELY PRECEDING THE EVENT GIVING RISE TO THE CLAIM (THE \u201CSTANDARD CAP\u201D).", { bold: true }));
  content.push(spacer());
  content.push(p("5.02. EXCEPT AS PROVIDED IN SECTION 5.03 BELOW, IN NO EVENT SHALL EITHER PARTY BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING LOSS OF PROFITS, DATA, BUSINESS OPPORTUNITY, OR GOODWILL, REGARDLESS OF WHETHER SUCH DAMAGES WERE FORESEEABLE OR WHETHER EITHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.", { bold: true }));
  content.push(spacer());
  content.push(p("5.03. ENHANCED CAP FOR CERTAIN CLAIMS. FOR CLAIMS ARISING FROM BREACHES OF SECTION 4 (CONFIDENTIALITY), SECTION 10 (DATA PROTECTION), INDEMNIFICATION OBLIGATIONS UNDER SECTION 6, WILLFUL MISCONDUCT, OR GROSS NEGLIGENCE, THE TOTAL AGGREGATE LIABILITY OF THE RESPONSIBLE PARTY SHALL NOT EXCEED THREE (3) TIMES THE STANDARD CAP DEFINED IN SECTION 5.01 (THE \u201CENHANCED CAP\u201D). THE ENHANCED CAP SHALL NOT APPLY TO LIABILITY ARISING FROM A PARTY\u2019S WILLFUL AND INTENTIONAL MISAPPROPRIATION OF THE OTHER PARTY\u2019S CONFIDENTIAL INFORMATION OR CLIENT DATA, FOR WHICH LIABILITY SHALL BE UNCAPPED.", { bold: true }));
  content.push(spacer());
  content.push(p("5.04. Data Liability. While Technijian shall use commercially reasonable efforts to protect Client Data, Client acknowledges that Client is solely responsible for maintaining backup copies of its data."));
  content.push(spacer());

  // --- SECTION 6: INDEMNIFICATION ---
  content.push(heading2("SECTION 6 \u2014 INDEMNIFICATION"));
  content.push(p("6.01. By Technijian. Technijian shall indemnify, defend, and hold harmless Client from and against any third-party claims arising from Technijian\u2019s gross negligence or willful misconduct in performing the services."));
  content.push(spacer());
  content.push(p("6.02. By Client. Client shall indemnify, defend, and hold harmless Technijian from and against any third-party claims arising from Client\u2019s use of the services in violation of applicable law, Client\u2019s breach of this Agreement, or any data, content, or materials provided by Client."));
  content.push(spacer());
  content.push(p("6.03. Procedure. The indemnified Party shall provide prompt written notice of any claim, cooperate with the indemnifying Party in the defense, and not settle any claim without the indemnifying Party\u2019s prior written consent."));
  content.push(spacer());

  // --- SECTION 7: INTELLECTUAL PROPERTY ---
  content.push(heading2("SECTION 7 \u2014 INTELLECTUAL PROPERTY"));
  content.push(p("7.01. Technijian IP. Technijian retains all right, title, and interest in its proprietary tools, methodologies, software, and processes."));
  content.push(spacer());
  content.push(p("7.02. Client IP. Client retains all right, title, and interest in its data, content, and pre-existing intellectual property."));
  content.push(spacer());
  content.push(p("7.03. Custom Development. Ownership of any custom software or materials developed under a SOW shall be governed by the terms of that SOW."));
  content.push(spacer());

  // --- SECTION 8: DISPUTE RESOLUTION ---
  content.push(heading2("SECTION 8 \u2014 DISPUTE RESOLUTION"));
  content.push(p("8.01. Escalation. The Parties shall first attempt to resolve any dispute through good faith negotiations for a period of thirty (30) days."));
  content.push(spacer());
  content.push(p("8.02. Mediation. If not resolved, the Parties shall submit the dispute to mediation in Orange County, California, for a period not to exceed sixty (60) days."));
  content.push(spacer());
  content.push(p("8.03. Arbitration. If mediation fails, any remaining dispute shall be resolved by binding arbitration administered by the American Arbitration Association in Orange County, California."));
  content.push(spacer());
  content.push(p("8.04. Injunctive Relief. Nothing in this Section shall prevent either Party from seeking injunctive or other equitable relief to prevent irreparable harm."));
  content.push(spacer());

  // --- SECTION 9: GENERAL PROVISIONS ---
  content.push(heading2("SECTION 9 \u2014 GENERAL PROVISIONS"));
  content.push(p("9.01. Entire Agreement. This Agreement, together with its Schedules and any SOWs, constitutes the entire agreement between the Parties. As modified by Section 12.03(d) of SOW-AFFG-004, this Section 9.01 does not supersede the Original Agreement; rather, the Original Agreement is amended by SOW-AFFG-004 Section 12 to incorporate the MSA Framework Provisions. The Virtual Staff Support hours and rates under the Original Agreement (CTO Advisory 3 hrs @ $225, US Tech Support 6 hrs @ $125, India Tech Normal 22 hrs @ $15, India Tech After-Hours 8 hrs @ $30) remain UNCHANGED and carry forward."));
  content.push(spacer());
  content.push(p("9.02. Amendment. This Agreement may only be amended by a written instrument signed by both Parties."));
  content.push(spacer());
  content.push(p("9.03. Severability. If any provision is found invalid or unenforceable, the remaining provisions shall continue in full force."));
  content.push(spacer());
  content.push(p("9.04. Waiver. No waiver of any provision shall be effective unless in writing and signed by the waiving Party."));
  content.push(spacer());
  content.push(p("9.05. Assignment. Neither Party may assign this Agreement without prior written consent, except in connection with a merger, acquisition, or sale of substantially all assets."));
  content.push(spacer());
  content.push(p("9.06. Force Majeure."));
  content.push(p("(a) Neither Party shall be liable for delays or failures in performance caused by events beyond its reasonable control, including natural disasters, acts of government, labor disputes, pandemics, cyberattacks on critical infrastructure, or failures of major third-party infrastructure services that are not attributable to the affected Party\u2019s failure to implement reasonable redundancy (\u201CForce Majeure Event\u201D)."));
  content.push(p("(b) The affected Party shall notify the other Party in writing within five (5) business days of becoming aware of a Force Majeure Event and shall use commercially reasonable efforts to mitigate the impact and resume performance."));
  content.push(p("(c) Payment obligations are not excused by a Force Majeure Event."));
  content.push(p("(d) If a Force Majeure Event prevents performance of a material portion of the services for more than ninety (90) consecutive days, either Party may terminate the affected Schedule, SOW, or this Agreement upon fifteen (15) days written notice without liability for early termination fees, and Client shall pay only for services actually rendered through the date of termination."));
  content.push(spacer());
  content.push(p("9.07. Notices. All notices shall be in writing and delivered by email with confirmation, certified mail, or nationally recognized overnight courier."));
  content.push(spacer());
  content.push(p("9.08. Governing Law. This Agreement shall be governed by the laws of the State of California."));
  content.push(spacer());
  content.push(p("9.09. Personnel Transition Fee. The Parties acknowledge that each invests significant resources in recruiting, training, and retaining skilled personnel. If either Party hires (whether as an employee or independent contractor) any individual who was an employee of the other Party and who was directly involved in performing or receiving services under this Agreement, and such hiring occurs during the term of this Agreement or within twelve (12) months following termination, the hiring Party shall pay the other Party a personnel transition fee equal to 25% of the hired individual\u2019s first-year annual compensation (base salary or annualized contractor fees). This fee represents a reasonable estimate of the non-hiring Party\u2019s recruiting and training costs and is not intended as a restraint on trade or employment. This Section does not restrict any individual\u2019s right to seek or obtain employment, and shall not apply to individuals who: (a) respond to general public job postings or advertisements not specifically targeted at the other Party\u2019s employees; or (b) are referred by a third-party recruiting firm without the hiring Party\u2019s direction to target the other Party\u2019s employees."));
  content.push(spacer());
  content.push(p("9.10. Counterparts. This Agreement may be executed in counterparts, each of which shall be deemed an original."));
  content.push(spacer());

  // --- SECTION 10: DATA PROTECTION ---
  content.push(heading2("SECTION 10 \u2014 DATA PROTECTION"));
  content.push(p("10.01. CCPA/CPRA Compliance. To the extent Technijian processes, stores, or has access to personal information (as defined under the California Consumer Privacy Act, as amended by the California Privacy Rights Act, Cal. Civ. Code \u00A7 1798.100 et seq., collectively \u201CCCPA\u201D) on behalf of Client, Technijian acts as a \u201Cservice provider\u201D as defined under Cal. Civ. Code \u00A7 1798.140(ag) and shall:"));
  content.push(p("(a) Process such personal information only as necessary to perform the services and in accordance with Client\u2019s documented instructions and this Agreement;"));
  content.push(p("(b) Not sell, share, retain, use, or disclose personal information for any purpose other than performing the services, including not using personal information for targeted advertising or cross-context behavioral advertising;"));
  content.push(p("(c) Not combine personal information received from Client with personal information received from other sources or collected from Technijian\u2019s own interactions with individuals, except as expressly permitted by the CCPA to perform the services;"));
  content.push(p("(d) Implement reasonable security measures appropriate to the nature of the personal information, consistent with the requirements of Section 10.03;"));
  content.push(p("(e) Cooperate with Client in responding to verifiable consumer rights requests under the CCPA (including access, deletion, correction, and opt-out requests) within ten (10) business days of Client\u2019s request;"));
  content.push(p("(f) Notify Client within five (5) business days if Technijian determines that it can no longer meet its obligations as a service provider under the CCPA;"));
  content.push(p("(g) Ensure that all subcontractors who process personal information on behalf of Client are bound by written agreements containing data protection obligations at least as protective as those in this Section 10, and Technijian shall remain liable for the acts and omissions of its subcontractors with respect to personal information;"));
  content.push(p("(h) Permit Client, upon thirty (30) days written notice and no more than once per twelve (12) month period, to audit or inspect Technijian\u2019s data processing practices to verify compliance with this Section 10, or, at Technijian\u2019s option, provide Client with a summary of a recent independent third-party audit (such as SOC 2 Type II) covering the relevant controls; and"));
  content.push(p("(i) Certify that Technijian understands the restrictions in this Section 10 and will comply with them."));
  content.push(spacer());
  content.push(p("10.02. Security Incident Notification. If Technijian becomes aware of a breach of security leading to the accidental or unlawful destruction, loss, alteration, unauthorized disclosure of, or access to Client Data (\u201CSecurity Incident\u201D), Technijian shall: (a) notify Client in writing without unreasonable delay and in no event later than forty-eight (48) hours after becoming aware of the Security Incident; (b) provide Client with sufficient information to enable Client to comply with its obligations under California Civil Code \u00A7 1798.82 (data breach notification), applicable SEC Regulation S-P customer notification requirements, and FINRA Rule 4530 reporting obligations, including the categories and approximate number of records affected, the nature of the incident, and the measures taken or proposed to address it; (c) cooperate with Client\u2019s investigation of the Security Incident; and (d) take reasonable steps to contain and remediate the Security Incident."));
  content.push(spacer());
  content.push(p("10.03. Data Security. Technijian shall implement and maintain administrative, technical, and physical safeguards designed to protect Client Data from unauthorized access, use, or disclosure, consistent with industry standards for managed IT service providers. Such safeguards shall include, at a minimum: (a) encryption of Client Data in transit and at rest; (b) access controls limiting access to authorized personnel; (c) regular security assessments and vulnerability testing; and (d) employee security awareness training."));
  content.push(spacer());
  content.push(p("10.04. Regulatory Compliance. Client is a dually registered Investment Adviser and Broker-Dealer subject to SEC Regulation S-P (including the 2024 Amendments), FINRA Rule 4370, FINRA Rule 3110, and SEC Rule 17a-4. The Parties shall cooperate in good faith to implement the controls described in the applicable Schedules and SOWs to support Client\u2019s compliance with these requirements. If additional industry-specific data protection requirements apply, the Parties shall execute a separate addendum addressing the additional obligations applicable to the regulated data."));
  content.push(spacer());
  content.push(p("10.05. Data Return and Deletion. Upon termination of this Agreement or upon Client\u2019s written request, Technijian shall securely delete or return all Client Data in its possession within thirty (30) days, using methods consistent with NIST SP 800-88 or equivalent standards, and shall certify such deletion in writing upon request."));
  content.push(spacer());
  content.push(brandRule());
  content.push(p("END OF EXHIBIT A", { bold: true, color: CHARCOAL, alignment: AlignmentType.CENTER }));

  // ===== BUILD DOCUMENT =====
  const doc = new Document({
    styles: docStyles,
    numbering,
    sections: [
      {
        properties: coverSectionProps(),
        children: coverPage(
          "Statement of Work",
          "Managed Device Control Deployment \u2014 American Fundstars Financial Group LLC"
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
