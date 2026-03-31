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
  items.push(p("March 31, 2026", { size: 22, color: GREY, alignment: AlignmentType.CENTER, spacing: { after: 200 } }));
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

// ===== GENERATE CTO ADVISORY AGREEMENT =====
async function generateAgreement() {
  const content = [];

  // ---- Header ----
  content.push(heading1("HOURLY SERVICES AGREEMENT"));
  content.push(multiRun([
    { text: "Agreement Number: ", bold: true, color: CHARCOAL },
    { text: "SOW-TSC-001" }
  ]));
  content.push(multiRun([
    { text: "Effective Date: ", bold: true, color: CHARCOAL },
    { text: "March 31, 2026" }
  ]));
  content.push(spacer());
  content.push(p("This Hourly Services Agreement (\u201CAgreement\u201D) is entered into by and between:"));
  content.push(spacer());
  content.push(p("Technijian, Inc. (\u201CTechnijian\u201D)", { bold: true, color: CHARCOAL }));
  content.push(p("18 Technology Drive, Suite 141"));
  content.push(p("Irvine, California 92618"));
  content.push(spacer());
  content.push(p("and"));
  content.push(spacer());
  content.push(p("JVR Sheetmetal and Fabrication DBA Talsco (\u201CClient\u201D)", { bold: true, color: CHARCOAL }));
  content.push(multiRun([{ text: "Primary Contact: ", bold: true, color: CHARCOAL }, { text: "Jose Castaneda Jr., General Manager" }]));
  content.push(multiRun([{ text: "Phone: ", bold: true, color: CHARCOAL }, { text: "714-841-2464 Ext. 240" }]));
  content.push(multiRun([{ text: "Email: ", bold: true, color: CHARCOAL }, { text: "jose@talsco.com" }]));
  content.push(brandRule());

  // ---- 1. ENGAGEMENT OVERVIEW ----
  content.push(heading1("1. ENGAGEMENT OVERVIEW"));

  content.push(heading2("1.1 Service Description"));
  content.push(p("Technijian will provide fractional Chief Technology Officer (\u201CCTO\u201D) advisory services to Client on an hourly, as-needed basis. The CTO Advisory engagement provides Client with access to senior technology leadership for strategic guidance, technology planning, and IT governance without the cost of a full-time executive hire."));
  content.push(spacer());

  content.push(heading2("1.2 Engagement Model"));
  content.push(p("This is an hourly engagement with no minimum commitment. Services are rendered upon Client\u2019s request and billed in 15-minute increments. There is no retainer, no monthly minimum, and no long-term obligation. Either Party may terminate this Agreement at any time with thirty (30) days\u2019 written notice."));
  content.push(brandRule());

  // ---- 2. SCOPE OF SERVICES ----
  content.push(heading1("2. SCOPE OF SERVICES"));
  content.push(p("The CTO Advisory services may include, but are not limited to, the following areas:"));
  content.push(spacer());

  content.push(heading2("2.1 Technology Strategy & Planning"));
  content.push(bullet("Technology roadmap development and alignment with business objectives", "bullets"));
  content.push(bullet("IT budget planning and optimization recommendations", "bullets"));
  content.push(bullet("Vendor evaluation, selection, and contract review for technology purchases", "bullets"));
  content.push(bullet("Cloud strategy and digital transformation guidance", "bullets"));
  content.push(spacer());

  content.push(heading2("2.2 IT Infrastructure & Operations"));
  content.push(bullet("Assessment and recommendations for network, server, and endpoint infrastructure", "bullets2"));
  content.push(bullet("Business continuity and disaster recovery planning", "bullets2"));
  content.push(bullet("IT process improvement and operational efficiency recommendations", "bullets2"));
  content.push(bullet("Technology staff evaluation and hiring guidance", "bullets2"));
  content.push(spacer());

  content.push(heading2("2.3 Cybersecurity & Compliance"));
  content.push(bullet("Security posture assessment and risk identification", "bullets3"));
  content.push(bullet("Security policy development and review", "bullets3"));
  content.push(bullet("Compliance guidance for industry-specific requirements", "bullets3"));
  content.push(bullet("Incident response planning and tabletop exercise facilitation", "bullets3"));
  content.push(spacer());

  content.push(heading2("2.4 Project Oversight"));
  content.push(bullet("Technology project scoping, planning, and oversight", "bullets4"));
  content.push(bullet("Vendor and contractor management for IT projects", "bullets4"));
  content.push(bullet("Technical due diligence for acquisitions or major investments", "bullets4"));
  content.push(bullet("Quality assurance and deliverable review for IT initiatives", "bullets4"));
  content.push(spacer());

  content.push(heading2("2.5 Artificial Intelligence (AI) Services"));
  content.push(bullet("AI training and education for Client\u2019s leadership and staff \u2014 workshops covering AI fundamentals, capabilities, limitations, and practical business applications", "bullets5"));
  content.push(bullet("AI feasibility assessments \u2014 evaluate proposed AI/ML use cases for technical viability, data readiness, ROI potential, and organizational fit", "bullets5"));
  content.push(bullet("AI prototype development \u2014 build proof-of-concept projects to validate AI approaches before full investment, including model selection, data pipeline design, and working demonstrations", "bullets5"));
  content.push(bullet("AI application system requirements \u2014 define complete technical specifications, architecture, data requirements, integration points, and acceptance criteria for production AI applications", "bullets5"));
  content.push(bullet("AI vendor and platform evaluation \u2014 assess and recommend AI platforms, APIs, and tooling (e.g., OpenAI, Azure AI, AWS Bedrock) aligned to Client\u2019s requirements and budget", "bullets5"));
  content.push(bullet("AI governance and responsible use guidance \u2014 policy recommendations for data privacy, bias mitigation, and ethical AI deployment", "bullets5"));
  content.push(brandRule());

  // ---- 3. PRICING AND BILLING ----
  content.push(heading1("3. PRICING AND BILLING"));

  content.push(heading2("3.1 Rate"));
  content.push(makeTable(
    ["Service", "Rate", "Billing Increment", "After-Hours Rate"],
    [
      ["CTO Advisory", "$250.00/hr", "15-minute increments", "$350.00/hr"]
    ],
    [2400, 2000, 2400, 2560]
  ));
  content.push(spacer());

  content.push(heading2("3.2 Rate Definitions"));
  content.push(bulletMulti([
    { text: "Normal Business Hours: ", bold: true, color: CHARCOAL },
    { text: "Monday through Friday, 8:00 AM \u2013 6:00 PM Pacific Time, excluding U.S. federal holidays." }
  ], "bullets5"));
  content.push(bulletMulti([
    { text: "After-Hours: ", bold: true, color: CHARCOAL },
    { text: "All hours outside Normal Business Hours, including weekends and U.S. federal holidays." }
  ], "bullets5"));
  content.push(spacer());

  content.push(heading2("3.3 Weekly Invoicing"));
  content.push(p("(a) Technijian will issue a Weekly Out-of-Contract Invoice every Friday covering all CTO Advisory work performed during the preceding week (Monday through Friday).", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(b) Each weekly invoice will include a detailed breakdown of:", { indent: { left: 360 } }));
  content.push(bullet("Date(s) of service"));
  content.push(bullet("Description of activities performed"));
  content.push(bullet("Time entries with hours billed per activity (in 15-minute increments)"));
  content.push(bullet("Applicable rate (standard or after-hours)"));
  content.push(bullet("Total hours and total amount for the week"));
  content.push(spacer());

  content.push(heading2("3.4 Payment Terms & Dispute Window"));
  content.push(p("(a) All weekly invoices are Net 30 \u2014 due and payable within thirty (30) days of the invoice date.", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(b) Client has thirty (30) days from the invoice date to review and dispute any time entries or charges. Disputes must be submitted in writing (email acceptable) with specific identification of the disputed entries and the basis for the dispute.", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(c) Any invoice or line item not disputed within the 30-day dispute window shall be deemed accepted and payable in full.", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(d) Undisputed portions of an invoice remain due on the original Net 30 terms regardless of any pending dispute on other line items.", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(e) Late payments are subject to a late fee of 1.5% per month on the unpaid balance.", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(f) Technijian reserves the right to suspend services if any invoice remains unpaid for more than forty-five (45) days.", { indent: { left: 360 } }));
  content.push(brandRule());

  // ---- 4. CLIENT RESPONSIBILITIES ----
  content.push(heading1("4. CLIENT RESPONSIBILITIES"));
  content.push(p("Client shall:"));
  content.push(spacer());
  content.push(p("(a) Provide timely access to relevant systems, documentation, and personnel as reasonably required for Technijian to perform the advisory services;", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(b) Designate a primary point of contact authorized to request services and approve recommendations;", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(c) Make decisions and provide approvals in a timely manner to avoid delays in advisory engagements; and", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(d) Acknowledge that CTO Advisory services are advisory in nature and that Client retains sole responsibility for all final technology decisions and their implementation.", { indent: { left: 360 } }));
  content.push(brandRule());

  // ---- 5. CONFIDENTIALITY ----
  content.push(heading1("5. CONFIDENTIALITY"));
  content.push(p("5.01. Each Party acknowledges that in connection with this Agreement it may receive Confidential Information of the other Party. \u201CConfidential Information\u201D means all non-public information disclosed by one Party to the other, whether orally or in writing, that is designated as confidential or that reasonably should be understood to be confidential given the nature of the information and the circumstances of disclosure."));
  content.push(spacer());
  content.push(p("5.02. Each Party agrees to: (i) hold the other Party\u2019s Confidential Information in strict confidence; (ii) not disclose Confidential Information to any third party without the prior written consent of the disclosing Party; and (iii) use Confidential Information only for purposes of performing under this Agreement."));
  content.push(spacer());
  content.push(p("5.03. The obligations of confidentiality shall survive termination of this Agreement for a period of two (2) years."));
  content.push(brandRule());

  // ---- 6. LIMITATION OF LIABILITY ----
  content.push(heading1("6. LIMITATION OF LIABILITY"));
  content.push(p("6.01. CTO Advisory services are advisory in nature. Technijian provides recommendations based on professional judgment and industry best practices, but does not guarantee specific business outcomes from the adoption of its recommendations."));
  content.push(spacer());
  content.push(p("6.02. IN NO EVENT SHALL EITHER PARTY BE LIABLE TO THE OTHER FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES ARISING OUT OF OR RELATED TO THIS AGREEMENT, REGARDLESS OF THE FORM OF ACTION OR THEORY OF LIABILITY."));
  content.push(spacer());
  content.push(p("6.03. Technijian\u2019s total aggregate liability under this Agreement shall not exceed the total fees paid by Client to Technijian during the six (6) months preceding the event giving rise to the claim."));
  content.push(brandRule());

  // ---- 7. TERM AND TERMINATION ----
  content.push(heading1("7. TERM AND TERMINATION"));
  content.push(p("7.01. This Agreement shall be effective as of the Effective Date and shall continue until terminated by either Party."));
  content.push(spacer());
  content.push(p("7.02. Either Party may terminate this Agreement at any time by providing thirty (30) days\u2019 written notice to the other Party."));
  content.push(spacer());
  content.push(p("7.03. Upon termination, Client shall pay Technijian for all services rendered through the effective date of termination."));
  content.push(spacer());
  content.push(p("7.04. Sections 5 (Confidentiality), 6 (Limitation of Liability), and 8 (General Provisions) shall survive termination of this Agreement."));
  content.push(brandRule());

  // ---- 8. GENERAL PROVISIONS ----
  content.push(heading1("8. GENERAL PROVISIONS"));
  content.push(p("8.01. Independent Contractor. Technijian is an independent contractor. Nothing in this Agreement creates an employment, agency, joint venture, or partnership relationship between the Parties."));
  content.push(spacer());
  content.push(p("8.02. Governing Law. This Agreement shall be governed by and construed in accordance with the laws of the State of California, without regard to its conflicts of law provisions."));
  content.push(spacer());
  content.push(p("8.03. Entire Agreement. This Agreement constitutes the entire agreement between the Parties with respect to its subject matter and supersedes all prior or contemporaneous oral or written agreements."));
  content.push(spacer());
  content.push(p("8.04. Amendments. This Agreement may not be modified except by a written instrument signed by both Parties."));
  content.push(spacer());
  content.push(p("8.05. Notices. All notices under this Agreement shall be in writing and delivered by email with read receipt or by certified mail to the addresses specified in this Agreement."));
  content.push(brandRule());

  // ---- SIGNATURES ----
  content.push(heading1("SIGNATURES"));
  content.push(p("IN WITNESS WHEREOF, the Parties have executed this Agreement as of the Effective Date."));
  content.push(spacer());
  content.push(spacer());
  content.push(p("TECHNIJIAN, INC.", { bold: true, color: CHARCOAL }));
  content.push(spacer());
  content.push(p("By: ___________________________________"));
  content.push(spacer());
  content.push(multiRun([{ text: "Name: ", color: GREY }, { text: "Ravi Jain", bold: true, color: CHARCOAL }]));
  content.push(spacer());
  content.push(multiRun([{ text: "Title: ", color: GREY }, { text: "Chief Executive Officer", bold: true, color: CHARCOAL }]));
  content.push(spacer());
  content.push(p("Date: _________________________________"));
  content.push(spacer());
  content.push(spacer());
  content.push(spacer());
  content.push(p("JVR SHEETMETAL AND FABRICATION DBA TALSCO", { bold: true, color: CHARCOAL }));
  content.push(spacer());
  content.push(p("By: ___________________________________"));
  content.push(spacer());
  content.push(multiRun([{ text: "Name: ", color: GREY }, { text: "Jose Castaneda Jr.", bold: true, color: CHARCOAL }]));
  content.push(spacer());
  content.push(multiRun([{ text: "Title: ", color: GREY }, { text: "General Manager", bold: true, color: CHARCOAL }]));
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
          "Hourly Services Agreement",
          "CTO Advisory Services \u2014 JVR Sheetmetal and Fabrication DBA Talsco"
        )
      },
      {
        properties: contentSectionProps(),
        children: content
      }
    ]
  });

  const buffer = await Packer.toBuffer(doc);
  const outputPath = path.join(__dirname, "SOW-TSC-001-CTO-Advisory.docx");
  fs.writeFileSync(outputPath, buffer);
  console.log("Generated:", outputPath);
}

generateAgreement().catch(err => {
  console.error("Error generating agreement:", err);
  process.exit(1);
});
