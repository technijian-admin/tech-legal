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
const GREY = "59595B";
const CHARCOAL = "1A1A2E";
const OFF_WHITE = "F8F9FA";
const WHITE = "FFFFFF";
const FONT = "Open Sans";

// Logo
let logoBuffer = null;
const logoPath = path.join(__dirname, "../../../templates/logo.png");
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
    { reference: "bullets",  levels: [{ level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
    { reference: "bullets2", levels: [{ level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
    { reference: "bullets3", levels: [{ level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
    { reference: "bullets4", levels: [{ level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
    { reference: "bullets5", levels: [{ level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
    { reference: "letters",  levels: [{ level: 0, format: LevelFormat.LOWER_LETTER, text: "(%1)", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] }
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

// ===== TABLES =====
const thinBorder = { style: BorderStyle.SINGLE, size: 1, color: "DDDDDD" };
const tableBorders = { top: thinBorder, bottom: thinBorder, left: thinBorder, right: thinBorder };
const cellPadding = { top: 80, bottom: 80, left: 120, right: 120 };

function brandTableCell(text, opts = {}) {
  const width = opts.width || 2340;
  const isHeader = opts.header || false;
  const runOpts = {
    font: FONT, size: opts.fontSize || 20, text,
    color: isHeader ? WHITE : GREY,
    bold: isHeader || opts.bold
  };
  return new TableCell({
    borders: tableBorders,
    width: { size: width, type: WidthType.DXA },
    margins: cellPadding,
    shading: { fill: isHeader ? BLUE : (opts.alt ? OFF_WHITE : WHITE), type: ShadingType.CLEAR },
    verticalAlign: "center",
    children: [new Paragraph({ children: [new TextRun(runOpts)] })]
  });
}

function makeTable(headers, rows, widths) {
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
    width: { size: widths.reduce((a, b) => a + b, 0), type: WidthType.DXA },
    columnWidths: widths, rows: tableRows
  });
}

// ===== COVER PAGE =====
function coverPage(title, subtitle) {
  const items = [];
  items.push(p("", { spacing: { before: 2400 } }));
  if (logoBuffer) {
    items.push(new Paragraph({
      alignment: AlignmentType.CENTER, spacing: { after: 200 },
      children: [new ImageRun({
        type: "png", data: logoBuffer,
        transformation: { width: 250, height: 63 },
        altText: { title: "Technijian Logo", description: "Technijian Inc.", name: "logo" }
      })]
    }));
  } else {
    items.push(p("TECHNIJIAN", { size: 72, bold: true, color: BLUE, alignment: AlignmentType.CENTER }));
  }
  items.push(p("", { spacing: { after: 600 } }));
  items.push(orangeAccentRule());
  items.push(p(title, { size: 48, bold: true, color: CHARCOAL, alignment: AlignmentType.CENTER, spacing: { before: 400, after: 200 } }));
  if (subtitle) {
    items.push(p(subtitle, { size: 24, color: GREY, alignment: AlignmentType.CENTER, spacing: { after: 400 } }));
  }
  items.push(orangeAccentRule());
  items.push(p("", { spacing: { after: 600 } }));
  items.push(p("May 15, 2026", { size: 22, color: GREY, alignment: AlignmentType.CENTER, spacing: { after: 200 } }));
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
        type: "png", data: logoBuffer,
        transformation: { width: 130, height: 33 },
        altText: { title: "Technijian", description: "Technijian Inc.", name: "logo" }
      })]
    }));
  } else {
    children.push(new Paragraph({
      children: [new TextRun({ text: "TECHNIJIAN", font: FONT, bold: true, size: 20, color: BLUE })]
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
        spacing: { before: 100 }, children: []
      }),
      new Paragraph({
        alignment: AlignmentType.CENTER,
        children: [
          new TextRun({ text: "Technijian, Inc.  |  18 Technology Dr., Ste 141, Irvine, CA 92618  |  949.379.8499", font: FONT, size: 14, color: GREY })
        ]
      }),
      new Paragraph({
        alignment: AlignmentType.CENTER,
        children: [
          new TextRun({ text: "Page ", font: FONT, size: 14, color: GREY }),
          new TextRun({ children: [PageNumber.CURRENT], font: FONT, size: 14, color: GREY }),
          new TextRun({ text: " of ", font: FONT, size: 14, color: GREY }),
          new TextRun({ children: [PageNumber.TOTAL_PAGES], font: FONT, size: 14, color: GREY })
        ]
      })
    ]
  });
}

function coverSectionProps() {
  return { page: { size: { width: 12240, height: 15840 }, margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 } } };
}

function contentSectionProps() {
  return {
    page: { size: { width: 12240, height: 15840 }, margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 } },
    headers: { default: makeHeader() },
    footers: { default: makeFooter() }
  };
}

// ===== GENERATE SOW =====
async function generateSOW() {
  const content = [];

  // ---- SOW Header ----
  content.push(heading1("STATEMENT OF WORK"));
  content.push(multiRun([{ text: "SOW Number: ", bold: true, color: CHARCOAL }, { text: "SOW-PCAP-001-AI-Advisory" }]));
  content.push(multiRun([{ text: "Effective Date: ", bold: true, color: CHARCOAL }, { text: "May 15, 2026" }]));
  content.push(multiRun([{ text: "Master Service Agreement: ", bold: true, color: CHARCOAL }, { text: "None on file — Section 9.03 governs" }]));
  content.push(spacer());
  content.push(p("This Statement of Work (“SOW”) is entered into by and between:"));
  content.push(spacer());
  content.push(p("Technijian, Inc. (“Technijian”)", { bold: true, color: CHARCOAL }));
  content.push(p("18 Technology Drive, Suite 141"));
  content.push(p("Irvine, California 92618"));
  content.push(spacer());
  content.push(p("and"));
  content.push(spacer());
  content.push(p("Pet Care Plus (“Client”)", { bold: true, color: CHARCOAL }));
  content.push(p("[Address — to be confirmed by Client]"));
  content.push(multiRun([{ text: "Primary Contact: ", bold: true, color: CHARCOAL }, { text: "Chris Stavrianos" }]));
  content.push(brandRule());

  // ---- 1. PROJECT OVERVIEW ----
  content.push(heading1("1. PROJECT OVERVIEW"));

  content.push(heading2("1.1 Project Title"));
  content.push(p("AI Consulting and Automation — Fractional CTO Advisory Engagement"));
  content.push(spacer());

  content.push(heading2("1.2 Project Description"));
  content.push(p("Pet Care Plus (“Client”) seeks specialized advisory support to evaluate, design, and guide the adoption of artificial intelligence and automation technologies across its business operations. Technijian will provide fractional Chief Technology Officer (CTO) advisory services on a time-and-materials basis."));
  content.push(spacer());
  content.push(p("The specific work to be performed will be determined collaboratively by Client and Technijian as the engagement progresses. This SOW establishes the engagement terms, hourly rate, and governing provisions. Deliverables, timelines, and activities are not predefined — all work is authorized by Client on an as-needed basis."));
  content.push(spacer());
  content.push(p("Technijian will bill for actual hours worked at the CTO Advisory rate of ", { size: 22, color: GREY }));
  content.push(p("$250 per hour, invoiced weekly every Friday for hours worked in that week.", { bold: true, color: CHARCOAL }));
  content.push(spacer());

  content.push(heading2("1.3 Locations"));
  content.push(makeTable(
    ["Location Name", "Code", "Address", "Billable"],
    [["Pet Care Plus — Primary", "PCAP-HQ", "To be confirmed", "Yes"]],
    [2800, 1400, 2600, 1560]
  ));
  content.push(brandRule());

  // ---- 2. SCOPE OF WORK ----
  content.push(heading1("2. SCOPE OF WORK"));

  content.push(heading2("2.1 In Scope"));
  content.push(p("All CTO-level advisory, consulting, and automation guidance work requested by Client, including but not limited to:"));
  content.push(spacer());
  content.push(bullet("AI strategy and roadmap development", "bullets"));
  content.push(bullet("Technology platform and vendor evaluation", "bullets"));
  content.push(bullet("Process automation analysis and design guidance", "bullets"));
  content.push(bullet("AI tool selection, architecture guidance, and implementation oversight", "bullets"));
  content.push(bullet("Staff enablement and knowledge transfer", "bullets"));
  content.push(bullet("Vendor meeting attendance and technical representation on behalf of Client", "bullets"));
  content.push(bullet("Ad hoc consultation on any AI, automation, or technology strategy topic", "bullets"));
  content.push(spacer());

  content.push(heading2("2.2 Out of Scope"));
  content.push(p("The following items are expressly excluded from this SOW:"));
  content.push(spacer());
  content.push(bullet("Hands-on software development, coding, or application deployment (covered under a separate SOW at Developer rates)", "bullets2"));
  content.push(bullet("Direct management of Client employees or contractors", "bullets2"));
  content.push(bullet("Procurement of software licenses or hardware on behalf of Client", "bullets2"));
  content.push(bullet("Regulatory compliance certification or audit preparation (unless separately scoped)", "bullets2"));
  content.push(bullet("24/7 on-call or incident response (covered under a separate managed services engagement)", "bullets2"));
  content.push(bullet("Any work on Client’s production systems or live infrastructure (requires an executed MSA per Section 9.02)", "bullets2"));
  content.push(spacer());

  content.push(heading2("2.3 Assumptions"));
  content.push(spacer());
  content.push(bullet("Client will designate Chris Stavrianos as the primary authorized contact", "bullets3"));
  content.push(bullet("Work is initiated at Client’s direction — no minimum hours are committed by either Party", "bullets3"));
  content.push(bullet("Implementation work requiring access to Client’s production systems will trigger the MSA execution requirement under Section 9.02", "bullets3"));
  content.push(bullet("Out-of-area travel expenses (if required) are reimbursed at cost; local travel is included", "bullets3"));
  content.push(brandRule());

  // ---- 3. PROJECT PHASES ----
  content.push(heading1("3. PROJECT PHASES"));

  content.push(heading2("Ongoing Advisory (Time-and-Materials)"));
  content.push(spacer());
  content.push(p("3.1.1 Description", { bold: true, color: CHARCOAL }));
  content.push(spacer());
  content.push(p("All advisory and consulting work under this SOW is performed on a time-and-materials basis with no predefined phases, milestones, or deliverable schedule. Technijian will perform work at Client’s direction, log all time in 15-minute increments, and invoice monthly in arrears."));
  content.push(spacer());

  content.push(p("3.1.2 Deliverables", { bold: true, color: CHARCOAL }));
  content.push(spacer());
  content.push(p("Deliverables are determined by Client on an as-needed basis. Examples include:"));
  content.push(spacer());
  content.push(bullet("Strategy documents and assessments", "bullets4"));
  content.push(bullet("Vendor evaluation memos", "bullets4"));
  content.push(bullet("Architecture decision records", "bullets4"));
  content.push(bullet("Meeting notes and action items", "bullets4"));
  content.push(bullet("Knowledge-transfer materials", "bullets4"));
  content.push(spacer());

  content.push(p("3.1.3 Schedule", { bold: true, color: CHARCOAL }));
  content.push(spacer());
  content.push(makeTable(
    ["Role", "Description", "Rate", "Billing Increment", "Resource"],
    [
      ["CTO Advisory", "All AI consulting and automation advisory work", "$250.00/hr", "15 minutes", "TBD"],
      ["CTO Advisory (After-Hours)", "Advisory work outside normal business hours", "$350.00/hr", "15 minutes", "TBD"]
    ],
    [1800, 2800, 1400, 1600, 1200]
  ));
  content.push(brandRule());

  // ---- 4. EQUIPMENT ----
  content.push(heading1("4. EQUIPMENT AND MATERIALS"));
  content.push(p("Not applicable. This SOW covers advisory services only. No hardware or equipment is included."));
  content.push(brandRule());

  // ---- 5. PRICING AND PAYMENT ----
  content.push(heading1("5. PRICING AND PAYMENT"));

  content.push(heading2("5.1 Rate Card"));
  content.push(makeTable(
    ["Role", "Location", "Hourly Rate", "After-Hours Rate"],
    [["CTO Advisory", "US (Remote)", "$250.00/hr", "$350.00/hr"]],
    [2400, 2000, 2000, 2000]
  ));
  content.push(spacer());
  content.push(p("Normal business hours: Monday–Friday, 8:00 AM–6:00 PM Pacific Time, excluding US federal holidays."));
  content.push(spacer());

  content.push(heading2("5.2 Summary of Costs"));
  content.push(makeTable(
    ["Service", "Type", "Rate", "Billing"],
    [["AI Consulting and Automation — CTO Advisory", "T&M (Estimate)", "$250.00/hr", "Weekly — every Friday"]],
    [3600, 1600, 1400, 1800]
  ));
  content.push(spacer());
  content.push(p("There is no fixed project cost. All fees are based on actual hours worked at the applicable rate.", { italics: true }));
  content.push(spacer());

  content.push(heading2("5.3 Payment Schedule"));
  content.push(makeTable(
    ["Milestone", "Invoiced", "Amount"],
    [["Weekly — all hours worked Mon–Sun of the prior week", "Every Friday", "Actual hours × $250.00/hr"]],
    [3400, 2400, 2560]
  ));
  content.push(spacer());

  content.push(heading2("5.4 Payment Terms"));
  content.push(p("All invoices are due and payable within thirty (30) days of the invoice date."));
  content.push(spacer());

  content.push(heading2("5.5 Late Payment and Collection Remedies"));
  content.push(p("(a) If a Master Service Agreement is in effect between the Parties, the payment, late payment, acceleration, collection costs, lien, security interest, and fee-shifting provisions of the MSA shall apply in full to this SOW and shall supersede any conflicting provisions in this Section 5.5.", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(b) If no MSA is in effect, the following shall apply:", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(i) Late Payment. Late payments shall accrue a late fee of 1.5% per month (or the maximum rate permitted by law, whichever is less) on the unpaid balance, calculated as simple interest from the date payment was due.", { indent: { left: 720 } }));
  content.push(spacer());
  content.push(p("(ii) Acceleration. If Client fails to pay any undisputed invoice within forty-five (45) days of the due date, all remaining fees under this SOW shall become immediately due and payable.", { indent: { left: 720 } }));
  content.push(spacer());
  content.push(p("(iii) Suspension. Technijian may suspend all work under this SOW upon ten (10) days written notice if any invoice remains unpaid beyond the due date.", { indent: { left: 720 } }));
  content.push(spacer());
  content.push(p("(iv) Collection Costs and Attorney’s Fees. In any action to collect fees owed under this SOW, the prevailing Party shall be entitled to recover all reasonable costs of collection, including attorney’s fees, collection agency fees, court costs, and all costs of appeal. Pursuant to California Civil Code Section 1717, this attorney’s fees provision is reciprocal.", { indent: { left: 720 } }));
  content.push(spacer());
  content.push(p("(v) Lien on Work Product. Technijian shall retain a lien on all deliverables, work product, and materials (excluding Client Data) under this SOW until all amounts owed are paid in full.", { indent: { left: 720 } }));
  content.push(brandRule());

  // ---- 6. CLIENT RESPONSIBILITIES ----
  content.push(heading1("6. CLIENT RESPONSIBILITIES"));
  content.push(p("Client shall:"));
  content.push(spacer());
  content.push(p("(a) Provide access to relevant documentation, business processes, and personnel as reasonably required;", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(b) Designate Chris Stavrianos as the authorized point of contact with decision-making authority on behalf of Client;", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(c) Review and approve deliverables within five (5) business days of submission;", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(d) Ensure all relevant data is backed up prior to the start of any implementation work; and", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(e) Inform users of planned service changes, maintenance windows, and downtime.", { indent: { left: 360 } }));
  content.push(brandRule());

  // ---- 7. CHANGE MANAGEMENT ----
  content.push(heading1("7. CHANGE MANAGEMENT"));
  content.push(p("7.01. Any changes to the scope, schedule, or pricing of this SOW must be documented in a written Change Order signed by both Parties before work on the change begins."));
  content.push(spacer());
  content.push(p("7.02. If Client requests work outside the defined scope (e.g., hands-on development, live systems access), Technijian shall provide a Change Order detailing the additional work, applicable rates, and estimated cost impact."));
  content.push(spacer());
  content.push(p("7.03. Technijian shall not proceed with out-of-scope work without an approved Change Order, except in cases where delay would result in imminent risk to Client’s systems, in which case Technijian may perform emergency work not to exceed the lesser of (a) $2,500 or (b) 10% of the prior three months’ invoiced fees. Technijian shall issue a retrospective Change Order within three (3) business days."));
  content.push(brandRule());

  // ---- 8. ACCEPTANCE ----
  content.push(heading1("8. ACCEPTANCE"));
  content.push(p("8.01. Upon delivery of any discrete deliverable, Technijian shall notify Client in writing that the deliverable is ready for review."));
  content.push(spacer());
  content.push(p("8.02. Client shall review and provide written acceptance or a description of deficiencies within five (5) business days. Technijian’s delivery notification shall include: “If you do not respond within five (5) business days, the deliverable will be deemed accepted per SOW Section 8.03.”"));
  content.push(spacer());
  content.push(p("8.03. If Client does not respond within the review period, the deliverable shall be deemed accepted."));
  content.push(spacer());
  content.push(p("8.04. If deficiencies are identified, Technijian shall correct them and resubmit for review."));
  content.push(spacer());
  content.push(p("8.05. For advisory time billed on a T&M basis, acceptance is evidenced by Client’s payment of the monthly invoice without written objection within five (5) business days of receipt."));
  content.push(brandRule());

  // ---- 9. GOVERNING TERMS ----
  content.push(heading1("9. GOVERNING TERMS"));
  content.push(p("9.01. If a Master Service Agreement is in effect between the Parties, the terms of the MSA shall govern this SOW. In the event of a conflict between this SOW and the MSA, the MSA shall prevail unless this SOW expressly states otherwise."));
  content.push(spacer());
  content.push(p("9.02. MSA Required for Live Systems Work. An executed Master Service Agreement is required before Technijian commences any work under this SOW that involves: (a) access to or modification of Client’s production systems, networks, or infrastructure; (b) processing or transmission of Client Data including personal information under the CCPA; (c) handling of PHI, PCI, PII, or other regulated data; (d) administrative or root access to Client’s cloud tenants, identity providers, DNS, or domain registrars; or (e) any work that creates ongoing operational dependency between Technijian and Client."));
  content.push(spacer());
  content.push(p("9.03. Standalone SOW Fallback. If no MSA is in effect and the work falls outside Section 9.02(a)–(e) (advisory, strategy, and consultation not touching live systems), the following minimum terms apply: (a) neither Party’s total aggregate liability shall exceed the total fees paid in the prior twelve (12) months, except liability for breach of confidentiality or willful misconduct is capped at three (3) times that amount; (b) neither Party shall be liable for indirect, incidental, special, consequential, or punitive damages; (c) each Party shall hold the other’s confidential information in confidence; (d) disputes shall be resolved by binding arbitration under AAA Commercial Rules in Orange County, California; and (e) this SOW shall be governed by California law."));
  content.push(brandRule());

  // ---- SIGNATURES ----
  // PRE-STAMP PATTERN (proven for restructuring-2026 letters):
  //  - Ravi is NOT a Foxit signer party. His signature is pre-stamped on the
  //    rendered PDF via scripts stamp-signatures.py pattern, anchored on the
  //    printed "Ravi Jain" name. Tech Date is pre-printed in document text.
  //    No Foxit text tags in the Technijian block.
  //  - Chris is the ONLY Foxit signer (single-party envelope = sequence 1).
  //    His tags use :1: (not :2:) because he is the only party.
  // Why: Foxit multi-party sequential signing breaks for the intermediate
  // party (Ravi as party 1 of 2) — same-day incidents 2026-05-15 on folders
  // 33789261, 33789397, 33789480. Pre-stamping eliminates multi-party
  // entirely. See [[reference_pdf_signature_stamping]] and the proven
  // restructuring-2026 send pipeline.
  content.push(new Paragraph({ children: [new PageBreak()] }));
  content.push(heading1("SIGNATURES"));
  content.push(spacer());

  // ── Technijian signer (PRE-STAMPED — not a Foxit party) ──────────────────
  // Generator emits a visible underscore signature line above "Ravi Jain"
  // so stamp-signatures.py can anchor on the printed name and overlay the
  // scanned signature image at the right position. No Foxit text tags here.
  content.push(p("TECHNIJIAN, INC.", { bold: true, color: CHARCOAL }));
  content.push(spacer());
  content.push(new Paragraph({
    spacing: { before: 120, after: 0 },
    children: [
      new TextRun({ text: "By:  ", font: FONT, size: 22, bold: true, color: CHARCOAL }),
      new TextRun({ text: "_______________________________", font: FONT, size: 22, color: GREY })
    ]
  }));
  content.push(multiRun([{ text: "Name: ", bold: true, color: CHARCOAL }, { text: "Ravi Jain" }]));
  content.push(spacer());
  content.push(multiRun([{ text: "Title: ", bold: true, color: CHARCOAL }, { text: "Chief Executive Officer" }]));
  content.push(spacer());
  content.push(multiRun([{ text: "Date: ", bold: true, color: CHARCOAL }, { text: "May 15, 2026" }]));
  content.push(spacer());
  content.push(spacer());

  // ── Client signer (party 1 — the ONLY Foxit party in this envelope) ─────
  // Single-party envelope: Chris is sequence 1. His tags use :1: accordingly.
  // Tags: signfield + textfield (Title) + datefield. Name pre-printed as
  // "Chris Stavrianos" (matches BBC pattern of pre-printing client name).
  content.push(p("PET CARE PLUS", { bold: true, color: CHARCOAL }));
  content.push(spacer());
  content.push(new Paragraph({
    spacing: { before: 120, after: 400 },
    children: [
      new TextRun({ text: "By:  ", font: FONT, size: 22, bold: true, color: CHARCOAL }),
      new TextRun({ text: "${signfield:1:y:Client_Sig:____________________}", font: FONT, size: 20, color: WHITE })
    ]
  }));
  content.push(multiRun([{ text: "Name: ", bold: true, color: CHARCOAL }, { text: "Chris Stavrianos" }]));
  content.push(spacer());
  content.push(new Paragraph({
    spacing: { after: 120 },
    children: [
      new TextRun({ text: "Title:  ", font: FONT, size: 22, bold: true, color: CHARCOAL }),
      new TextRun({ text: "${textfield:1:y:Client_Title:220:18}", font: FONT, size: 20, color: WHITE })
    ]
  }));
  content.push(new Paragraph({
    children: [
      new TextRun({ text: "Date:  ", font: FONT, size: 22, bold: true, color: CHARCOAL }),
      new TextRun({ text: "${datefield:1:y:Client_Date:120:18}", font: FONT, size: 20, color: WHITE })
    ]
  }));

  // ===== BUILD DOCUMENT =====
  const doc = new Document({
    styles: docStyles,
    numbering,
    sections: [
      {
        properties: coverSectionProps(),
        children: coverPage(
          "Statement of Work",
          "AI Consulting and Automation — Fractional CTO Advisory\nPet Care Plus"
        )
      },
      {
        properties: contentSectionProps(),
        children: content
      }
    ]
  });

  const buffer = await Packer.toBuffer(doc);
  const outputPath = path.join(__dirname, "..", "03_SOW", "SOW-PCAP-001-AI-Advisory.docx");
  fs.writeFileSync(outputPath, buffer);
  console.log("Generated:", outputPath);
}

generateSOW().catch(err => {
  console.error("Error generating SOW:", err);
  process.exit(1);
});
