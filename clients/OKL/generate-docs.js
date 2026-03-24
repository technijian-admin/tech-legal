const fs = require("fs");
const path = require("path");
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  Header, Footer, AlignmentType,
  HeadingLevel, BorderStyle, WidthType, ShadingType,
  PageNumber, PageBreak, ImageRun, VerticalAlign
} = require("docx");

// Brand
const BLUE = "006DB6";
const ORANGE = "F67D4B";
const GREY = "59595B";
const CHARCOAL = "1A1A2E";
const WHITE = "FFFFFF";
const LIGHT_BLUE = "E8F4FD";
const LIGHT_GREY = "F5F5F5";
const GREEN = "2E7D32";
const FONT = "Open Sans";

// Logo
let logoBuffer = null;
try { logoBuffer = fs.readFileSync(path.join(__dirname, "..", "..", "templates", "logo.jpg")); } catch(e) {}

function p(text, opts = {}) {
  const runOpts = { font: FONT, size: opts.size || 22, color: opts.color || GREY, text };
  if (opts.bold) runOpts.bold = true;
  if (opts.italics) runOpts.italics = true;
  if (opts.underline) runOpts.underline = {};
  const pOpts = { children: [new TextRun(runOpts)] };
  if (opts.heading) pOpts.heading = opts.heading;
  if (opts.alignment) pOpts.alignment = opts.alignment;
  if (opts.spacing) pOpts.spacing = opts.spacing;
  if (opts.indent) pOpts.indent = opts.indent;
  if (opts.bullet) pOpts.bullet = opts.bullet;
  return new Paragraph(pOpts);
}

function multiRun(runs, opts = {}) {
  const children = runs.map(r => {
    const o = { font: FONT, size: r.size || 22, color: r.color || GREY, text: r.text };
    if (r.bold) o.bold = true;
    if (r.italics) o.italics = true;
    return new TextRun(o);
  });
  const pOpts = { children };
  if (opts.indent) pOpts.indent = opts.indent;
  if (opts.spacing) pOpts.spacing = opts.spacing;
  if (opts.alignment) pOpts.alignment = opts.alignment;
  return new Paragraph(pOpts);
}

function heading1(t) { return p(t, { heading: HeadingLevel.HEADING_1 }); }
function heading2(t) { return p(t, { heading: HeadingLevel.HEADING_2 }); }
function spacer(amt) { return p("", { spacing: { after: amt || 120 } }); }
function brandRule() {
  return new Paragraph({ spacing: { before: 200, after: 200 }, border: { bottom: { style: BorderStyle.SINGLE, size: 3, color: BLUE } }, children: [] });
}
function orangeRule() {
  return new Paragraph({ spacing: { before: 100, after: 100 }, border: { bottom: { style: BorderStyle.SINGLE, size: 2, color: ORANGE } }, children: [] });
}

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

// Table helpers
function cell(text, opts = {}) {
  const runOpts = { font: FONT, size: opts.size || 20, color: opts.color || GREY, text: String(text) };
  if (opts.bold) runOpts.bold = true;
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
    bold: true, color: WHITE, size: 20,
    shading: { type: ShadingType.SOLID, fill: BLUE, color: BLUE },
    width: { size: widthPct, type: WidthType.PERCENTAGE }
  });
}

function altRow(isAlt) {
  return isAlt ? { type: ShadingType.SOLID, fill: LIGHT_GREY, color: LIGHT_GREY } : undefined;
}

function makeTable(headers, rows, colWidths) {
  const headerRow = new TableRow({
    children: headers.map((h, i) => headerCell(h, colWidths ? colWidths[i] : Math.floor(100/headers.length))),
    tableHeader: true
  });
  const dataRows = rows.map((row, ri) => new TableRow({
    children: row.map((val, ci) => {
      const isNum = typeof val === "string" && (val.startsWith("$") || val.match(/^\d/) || val === "");
      return cell(val, {
        alignment: isNum ? AlignmentType.RIGHT : AlignmentType.LEFT,
        shading: altRow(ri % 2 === 1),
        bold: row[0] && String(row[0]).startsWith("**") ? true : (val && String(val).startsWith("$") && String(row[0]).includes("Total") ? true : false),
        width: colWidths ? { size: colWidths[ci], type: WidthType.PERCENTAGE } : undefined
      });
    })
  }));
  return new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    rows: [headerRow, ...dataRows]
  });
}

function highlightBox(lines, color) {
  return lines.map(l => p(l, { color: color || GREEN, bold: true, indent: { left: 200 }, spacing: { after: 60 } }));
}

function coverPage(title, subtitle) {
  return {
    properties: { page: { size: { width: 12240, height: 15840 }, margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 } } },
    children: [
      p("", { spacing: { before: 2400 } }),
      ...(logoBuffer ? [new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 200 }, children: [new ImageRun({ type: "jpg", data: logoBuffer, transformation: { width: 250, height: 63 }, altText: { title: "Technijian Logo", description: "Technijian Inc.", name: "logo" } })] })] : [p("TECHNIJIAN", { size: 72, bold: true, color: BLUE, alignment: AlignmentType.CENTER })]),
      p("", { spacing: { after: 600 } }),
      orangeRule(),
      p(title, { size: 48, bold: true, color: CHARCOAL, alignment: AlignmentType.CENTER, spacing: { before: 400, after: 200 } }),
      p(subtitle, { size: 28, bold: true, color: BLUE, alignment: AlignmentType.CENTER, spacing: { after: 100 } }),
      p("March 23, 2026", { size: 24, color: GREY, alignment: AlignmentType.CENTER, spacing: { after: 400 } }),
      orangeRule(),
      p("", { spacing: { after: 1200 } }),
      p("Technijian, Inc.", { size: 22, bold: true, color: CHARCOAL, alignment: AlignmentType.CENTER }),
      p("18 Technology Dr., Ste 141  |  Irvine, CA 92618  |  949.379.8499", { size: 20, color: GREY, alignment: AlignmentType.CENTER }),
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

function signatures() {
  return [
    brandRule(),
    heading2("SIGNATURES"),
    spacer(),
    p("TECHNIJIAN, INC.", { bold: true, color: CHARCOAL }),
    spacer(),
    p("By: ___________________________________"),
    spacer(),
    p("Name: _________________________________"),
    spacer(),
    p("Title: _________________________________"),
    spacer(),
    p("Date: _________________________________"),
    spacer(), spacer(),
    p("OAKTREE LAW", { bold: true, color: CHARCOAL }),
    spacer(),
    p("By: ___________________________________"),
    spacer(),
    p("Name: Ed Pits"),
    spacer(),
    p("Title: _________________________________"),
    spacer(),
    p("Date: _________________________________"),
  ];
}

// ============================================================
// MSA DOCUMENT
// ============================================================
function buildMSA() {
  const sections = [
    coverPage("Master Service Agreement", "Oaktree Law"),
    contentSection([
      heading1("MASTER SERVICE AGREEMENT"),
      multiRun([{ text: "Agreement Number: ", bold: true, color: CHARCOAL }, { text: "MSA-OKL-2026" }]),
      multiRun([{ text: "Effective Date: ", bold: true, color: CHARCOAL }, { text: "March 23, 2026" }]),
      spacer(),
      p("This Master Service Agreement (\"Agreement\") is entered into by and between:"),
      spacer(),
      p("Technijian, Inc. (\"Technijian\")", { bold: true, color: CHARCOAL }),
      p("18 Technology Drive, Suite 141"),
      p("Irvine, California 92618"),
      spacer(), p("and"), spacer(),
      p("Oaktree Law (\"Client\")", { bold: true, color: CHARCOAL }),
      p("[CLIENT ADDRESS]"),
      p("[CITY, STATE ZIP]"),
      spacer(),
      multiRun([{ text: "Primary Contact: ", bold: true, color: CHARCOAL }, { text: "Ed Pits" }]),
      spacer(),
      p("(collectively, the \"Parties\")"),
      brandRule(),

      // SECTION 1
      heading1("SECTION 1 — SCOPE OF SERVICES"),
      multiRun([{ text: "1.01. Services. ", bold: true, color: CHARCOAL }, { text: "Technijian shall provide the services described in the Schedules attached to this Agreement, which are incorporated herein by reference:" }]),
      spacer(),
      p("Schedule A — Monthly Managed Services (Cloud Hosting, Security, Monitoring)", { indent: { left: 360 } }),
      p("Schedule B — Subscription and License Services", { indent: { left: 360 } }),
      p("Schedule C — Rate Card", { indent: { left: 360 } }),
      spacer(),
      p("Additional services may be provided through Statements of Work (\"SOWs\") executed under this Agreement."),
      spacer(),
      multiRun([{ text: "1.02. Standard of Care. ", bold: true, color: CHARCOAL }, { text: "Technijian shall perform all services in a professional and workmanlike manner, consistent with industry standards for managed IT service providers." }]),
      spacer(),
      multiRun([{ text: "1.03. Service Level Agreement. ", bold: true, color: CHARCOAL }, { text: "The service levels applicable to the services are set forth in Schedule A. Technijian shall use commercially reasonable efforts to meet the service levels described therein." }]),
      spacer(),
      multiRun([{ text: "1.04. Client Responsibilities. ", bold: true, color: CHARCOAL }, { text: "Client shall:" }]),
      spacer(),
      p("(a) Provide Technijian with reasonable access to Client's systems, facilities, and personnel as necessary for Technijian to perform the services;", { indent: { left: 360 } }),
      p("(b) Designate a primary point of contact for communications with Technijian;", { indent: { left: 360 } }),
      p("(c) Maintain current and accurate information regarding Client's systems and infrastructure;", { indent: { left: 360 } }),
      p("(d) Comply with all applicable laws and regulations in connection with its use of the services; and", { indent: { left: 360 } }),
      p("(e) Be solely responsible for the security and management of Client's account credentials and passwords.", { indent: { left: 360 } }),
      spacer(),
      multiRun([{ text: "1.05. Independent Contractor. ", bold: true, color: CHARCOAL }, { text: "Technijian is an independent contractor. Nothing in this Agreement shall be construed to create a partnership, joint venture, agency, or employment relationship between the Parties." }]),
      brandRule(),

      // SECTION 2
      heading1("SECTION 2 — TERM AND RENEWAL"),
      multiRun([{ text: "2.01. Initial Term. ", bold: true, color: CHARCOAL }, { text: "This Agreement shall commence on the Effective Date and continue for a period of twelve (12) months (the \"Initial Term\")." }]),
      spacer(),
      multiRun([{ text: "2.02. Renewal. ", bold: true, color: CHARCOAL }, { text: "Upon expiration of the Initial Term, this Agreement shall automatically renew for successive twelve (12) month periods (each a \"Renewal Term\"), unless either Party provides written notice of non-renewal at least sixty (60) days prior to the expiration of the then-current term." }]),
      spacer(),
      multiRun([{ text: "2.03. Termination for Convenience. ", bold: true, color: CHARCOAL }, { text: "Either Party may terminate this Agreement for any reason upon sixty (60) days written notice to the other Party." }]),
      spacer(),
      multiRun([{ text: "2.04. Termination for Cause. ", bold: true, color: CHARCOAL }, { text: "Either Party may terminate this Agreement immediately upon written notice if the other Party:" }]),
      p("(a) Commits a material breach of this Agreement and fails to cure such breach within thirty (30) days after receiving written notice of the breach; or", { indent: { left: 360 } }),
      p("(b) Becomes insolvent, files for bankruptcy, or has a receiver appointed for its assets.", { indent: { left: 360 } }),
      spacer(),
      multiRun([{ text: "2.05. Effect of Termination. ", bold: true, color: CHARCOAL }, { text: "" }]),
      p("(a) Upon termination, Client shall pay all fees and charges for services rendered through the date of termination, including any remaining obligations for annual licenses and subscriptions procured on Client's behalf.", { indent: { left: 360 } }),
      p("(b) Technijian shall provide reasonable transition assistance for a period of up to thirty (30) days following termination, subject to payment of applicable fees.", { indent: { left: 360 } }),
      p("(c) Technijian shall return all Client Data in its possession within thirty (30) days of termination, in a commercially standard format, provided Client is not in breach of this Agreement.", { indent: { left: 360 } }),
      p("(d) The following sections shall survive termination: Section 4 (Confidentiality), Section 5 (Limitation of Liability), Section 6 (Indemnification), and Section 8 (Dispute Resolution).", { indent: { left: 360 } }),
      brandRule(),

      // SECTION 3
      heading1("SECTION 3 — PAYMENT"),
      multiRun([{ text: "3.01. Fees. ", bold: true, color: CHARCOAL }, { text: "Client shall pay fees for the services as set forth in the applicable Schedule, SOW, or invoice. Fees are exclusive of applicable taxes." }]),
      spacer(),
      multiRun([{ text: "3.02. Invoicing. ", bold: true, color: CHARCOAL }, { text: "Technijian shall invoice Client monthly in advance for recurring services and upon delivery for one-time services, unless otherwise specified in the applicable Schedule or SOW." }]),
      spacer(),
      multiRun([{ text: "3.03. Payment Terms. ", bold: true, color: CHARCOAL }, { text: "All invoices are due and payable within thirty (30) days of the invoice date, unless otherwise specified." }]),
      spacer(),
      multiRun([{ text: "3.04. Late Payment. ", bold: true, color: CHARCOAL }, { text: "Invoices not paid within terms shall accrue a late fee of 1.5% per month (or the maximum rate permitted by law, whichever is less) on the unpaid balance." }]),
      spacer(),
      multiRun([{ text: "3.05. Disputed Invoices. ", bold: true, color: CHARCOAL }, { text: "If Client disputes any portion of an invoice, Client shall notify Technijian in writing within fifteen (15) days of the invoice date, specifying the nature of the dispute. Client shall pay all undisputed amounts by the due date." }]),
      spacer(),
      multiRun([{ text: "3.06. Suspension of Services. ", bold: true, color: CHARCOAL }, { text: "If Client fails to pay any undisputed invoice within thirty (30) days of the due date, Technijian may, upon ten (10) days written notice, suspend services until payment is received." }]),
      spacer(),
      multiRun([{ text: "3.07. Taxes. ", bold: true, color: CHARCOAL }, { text: "Client shall be responsible for all applicable sales, use, and other taxes arising from the services, excluding taxes based on Technijian's income." }]),
      brandRule(),

      // SECTION 4
      heading1("SECTION 4 — CONFIDENTIALITY"),
      multiRun([{ text: "4.01. Definition. ", bold: true, color: CHARCOAL }, { text: "\"Confidential Information\" means any non-public information disclosed by either Party to the other in connection with this Agreement, including business, technical, and financial information." }]),
      spacer(),
      multiRun([{ text: "4.02. Obligations. ", bold: true, color: CHARCOAL }, { text: "Each Party shall:" }]),
      p("(a) Hold the other Party's Confidential Information in confidence using at least the same degree of care it uses for its own confidential information, but not less than reasonable care;", { indent: { left: 360 } }),
      p("(b) Not disclose Confidential Information to third parties without prior written consent, except to employees, agents, and subcontractors who have a need to know and are bound by equivalent obligations; and", { indent: { left: 360 } }),
      p("(c) Not use Confidential Information for any purpose other than performing obligations under this Agreement.", { indent: { left: 360 } }),
      spacer(),
      multiRun([{ text: "4.03. Exclusions. ", bold: true, color: CHARCOAL }, { text: "Confidential Information does not include information that is or becomes publicly available through no fault of the receiving Party, was known to the receiving Party prior to disclosure, is independently developed, or is received from a third party without restriction." }]),
      spacer(),
      multiRun([{ text: "4.04. Compelled Disclosure. ", bold: true, color: CHARCOAL }, { text: "If required by law or court order to disclose Confidential Information, the receiving Party shall provide prompt written notice to the disclosing Party and cooperate in seeking a protective order." }]),
      spacer(),
      multiRun([{ text: "4.05. Duration. ", bold: true, color: CHARCOAL }, { text: "Confidentiality obligations shall survive termination for a period of three (3) years." }]),
      brandRule(),

      // SECTION 5
      heading1("SECTION 5 — LIMITATION OF LIABILITY"),
      p("5.01. EXCEPT FOR BREACHES OF SECTION 4 (CONFIDENTIALITY), WILLFUL MISCONDUCT, OR GROSS NEGLIGENCE, NEITHER PARTY'S TOTAL AGGREGATE LIABILITY UNDER THIS AGREEMENT SHALL EXCEED THE TOTAL FEES PAID OR PAYABLE BY CLIENT DURING THE TWELVE (12) MONTH PERIOD IMMEDIATELY PRECEDING THE EVENT GIVING RISE TO THE CLAIM.", { size: 20 }),
      spacer(),
      p("5.02. IN NO EVENT SHALL EITHER PARTY BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING LOSS OF PROFITS, DATA, BUSINESS OPPORTUNITY, OR GOODWILL.", { size: 20 }),
      spacer(),
      multiRun([{ text: "5.03. Data Liability. ", bold: true, color: CHARCOAL }, { text: "While Technijian shall use commercially reasonable efforts to protect Client Data, Client acknowledges that Client is solely responsible for maintaining backup copies of its data." }]),
      brandRule(),

      // SECTION 6
      heading1("SECTION 6 — INDEMNIFICATION"),
      multiRun([{ text: "6.01. By Technijian. ", bold: true, color: CHARCOAL }, { text: "Technijian shall indemnify, defend, and hold harmless Client from and against any third-party claims arising from Technijian's gross negligence or willful misconduct in performing the services." }]),
      spacer(),
      multiRun([{ text: "6.02. By Client. ", bold: true, color: CHARCOAL }, { text: "Client shall indemnify, defend, and hold harmless Technijian from and against any third-party claims arising from Client's use of the services in violation of applicable law, Client's breach of this Agreement, or any data, content, or materials provided by Client." }]),
      spacer(),
      multiRun([{ text: "6.03. Procedure. ", bold: true, color: CHARCOAL }, { text: "The indemnified Party shall provide prompt written notice of any claim, cooperate with the indemnifying Party in the defense, and not settle any claim without the indemnifying Party's prior written consent." }]),
      brandRule(),

      // SECTION 7
      heading1("SECTION 7 — INTELLECTUAL PROPERTY"),
      multiRun([{ text: "7.01. Technijian IP. ", bold: true, color: CHARCOAL }, { text: "Technijian retains all right, title, and interest in its proprietary tools, methodologies, software, and processes." }]),
      spacer(),
      multiRun([{ text: "7.02. Client IP. ", bold: true, color: CHARCOAL }, { text: "Client retains all right, title, and interest in its data, content, and pre-existing intellectual property." }]),
      spacer(),
      multiRun([{ text: "7.03. Custom Development. ", bold: true, color: CHARCOAL }, { text: "Ownership of any custom software or materials developed under a SOW shall be governed by the terms of that SOW." }]),
      brandRule(),

      // SECTION 8
      heading1("SECTION 8 — DISPUTE RESOLUTION"),
      multiRun([{ text: "8.01. Escalation. ", bold: true, color: CHARCOAL }, { text: "The Parties shall first attempt to resolve any dispute through good faith negotiations for a period of thirty (30) days." }]),
      spacer(),
      multiRun([{ text: "8.02. Mediation. ", bold: true, color: CHARCOAL }, { text: "If not resolved, the Parties shall submit the dispute to mediation in Orange County, California, for a period not to exceed sixty (60) days." }]),
      spacer(),
      multiRun([{ text: "8.03. Arbitration. ", bold: true, color: CHARCOAL }, { text: "If mediation fails, any remaining dispute shall be resolved by binding arbitration administered by the American Arbitration Association in Orange County, California." }]),
      spacer(),
      multiRun([{ text: "8.04. Injunctive Relief. ", bold: true, color: CHARCOAL }, { text: "Nothing in this Section shall prevent either Party from seeking injunctive or other equitable relief to prevent irreparable harm." }]),
      brandRule(),

      // SECTION 9
      heading1("SECTION 9 — GENERAL PROVISIONS"),
      multiRun([{ text: "9.01. Entire Agreement. ", bold: true, color: CHARCOAL }, { text: "This Agreement, together with its Schedules and any SOWs, constitutes the entire agreement between the Parties." }]),
      spacer(),
      multiRun([{ text: "9.02. Amendment. ", bold: true, color: CHARCOAL }, { text: "This Agreement may only be amended by a written instrument signed by both Parties." }]),
      spacer(),
      multiRun([{ text: "9.03. Severability. ", bold: true, color: CHARCOAL }, { text: "If any provision is found invalid or unenforceable, the remaining provisions shall continue in full force." }]),
      spacer(),
      multiRun([{ text: "9.04. Waiver. ", bold: true, color: CHARCOAL }, { text: "No waiver of any provision shall be effective unless in writing and signed by the waiving Party." }]),
      spacer(),
      multiRun([{ text: "9.05. Assignment. ", bold: true, color: CHARCOAL }, { text: "Neither Party may assign this Agreement without prior written consent, except in connection with a merger, acquisition, or sale of substantially all assets." }]),
      spacer(),
      multiRun([{ text: "9.06. Force Majeure. ", bold: true, color: CHARCOAL }, { text: "Neither Party shall be liable for delays or failures caused by events beyond its reasonable control." }]),
      spacer(),
      multiRun([{ text: "9.07. Notices. ", bold: true, color: CHARCOAL }, { text: "All notices shall be in writing and delivered by email with confirmation, certified mail, or nationally recognized overnight courier." }]),
      spacer(),
      multiRun([{ text: "9.08. Governing Law. ", bold: true, color: CHARCOAL }, { text: "This Agreement shall be governed by the laws of the State of California." }]),
      spacer(),
      multiRun([{ text: "9.09. Non-Solicitation. ", bold: true, color: CHARCOAL }, { text: "During the term and for one (1) year following termination, neither Party shall directly solicit for employment any employee of the other Party involved in this Agreement." }]),
      spacer(),
      multiRun([{ text: "9.10. Counterparts. ", bold: true, color: CHARCOAL }, { text: "This Agreement may be executed in counterparts, each of which shall be deemed an original." }]),

      // Signatures
      ...signatures(),

      spacer(),
      brandRule(),
      p("Schedules:", { bold: true, color: CHARCOAL }),
      p("Schedule A — Monthly Managed Services", { indent: { left: 360 } }),
      p("Schedule B — Subscription and License Services", { indent: { left: 360 } }),
      p("Schedule C — Rate Card", { indent: { left: 360 } }),
    ])
  ];
  return new Document({ styles: docStyles, sections });
}

// ============================================================
// SOW DOCUMENT
// ============================================================
function buildSOW() {
  const sections = [
    coverPage("Statement of Work", "Oaktree Law — Server Migration & Cloud Hosting"),
    contentSection([
      heading1("STATEMENT OF WORK"),
      multiRun([{ text: "SOW Number: ", bold: true, color: CHARCOAL }, { text: "SOW-OKL-001" }]),
      multiRun([{ text: "Effective Date: ", bold: true, color: CHARCOAL }, { text: "March 23, 2026" }]),
      multiRun([{ text: "Master Service Agreement: ", bold: true, color: CHARCOAL }, { text: "MSA-OKL-2026" }]),
      spacer(),
      p("This Statement of Work (\"SOW\") is entered into by and between:"),
      spacer(),
      p("Technijian, Inc. (\"Technijian\")", { bold: true, color: CHARCOAL }),
      p("18 Technology Drive, Suite 141"),
      p("Irvine, California 92618"),
      spacer(), p("and"), spacer(),
      p("Oaktree Law (\"Client\")", { bold: true, color: CHARCOAL }),
      p("[CLIENT ADDRESS]"),
      p("[CITY, STATE ZIP]"),
      spacer(),
      multiRun([{ text: "Primary Contact: ", bold: true, color: CHARCOAL }, { text: "Ed Pits" }]),
      brandRule(),

      // 1. PROJECT OVERVIEW
      heading1("1. PROJECT OVERVIEW"),
      heading2("1.1 Project Title"),
      p("Physical Server Migration to Technijian Cloud with Cloudbrink ZTNA and OneDrive Migration"),
      spacer(),

      heading2("1.2 Project Description"),
      p("Oaktree Law currently operates a physical on-premises server that requires migration to a cloud-hosted environment. This SOW covers:"),
      spacer(),
      p("Full migration of the existing physical server to Technijian's private cloud datacenter", { indent: { left: 360 } }),
      p("Deployment of a Cloudbrink Zero Trust Network Access (ZTNA) virtual appliance for secure user access", { indent: { left: 360 } }),
      p("Migration of approximately 779 GB of shared folders to Microsoft OneDrive / SharePoint Online", { indent: { left: 360 } }),
      p("Deployment of security and management agents (CrowdStrike, Huntress, Patch Management, My Remote)", { indent: { left: 360 } }),
      p("Ongoing managed hosting, security, and support services", { indent: { left: 360 } }),
      spacer(),

      heading2("1.3 Current Environment"),
      spacer(),
      makeTable(
        ["Component", "Specification"],
        [
          ["Processor", "Intel Xeon E3-1220 v5 @ 3.00 GHz (2 processors)"],
          ["Memory", "14.0 GB RAM"],
          ["Local Drive (C:)", "119 GB total / 3.33 GB free"],
          ["Shared Storage (D:)", "779 GB total / 60.7 GB free"],
          ["Internet", "500 / 500 Mbps symmetric"],
        ],
        [30, 70]
      ),
      brandRule(),

      // 2. SCOPE
      heading1("2. SCOPE OF WORK"),
      heading2("2.1 In Scope"),
      p("Full discovery and assessment of the existing physical server environment", { indent: { left: 360 } }),
      p("Provisioning of two (2) virtual machines in the Technijian datacenter", { indent: { left: 360 } }),
      p("Physical-to-Virtual (P2V) migration of the existing server to VM1", { indent: { left: 360 } }),
      p("Deployment and configuration of Cloudbrink ZTNA virtual appliance on VM2", { indent: { left: 360 } }),
      p("Migration of shared folders (~779 GB) to Microsoft OneDrive / SharePoint Online", { indent: { left: 360 } }),
      p("Installation of security agents: CrowdStrike, Huntress, Patch Management, My Remote", { indent: { left: 360 } }),
      p("Deployment of Veeam backup for both virtual machines", { indent: { left: 360 } }),
      p("End-to-end testing, validation, and go-live cutover", { indent: { left: 360 } }),
      p("30-day post-migration support period", { indent: { left: 360 } }),
      spacer(),

      heading2("2.2 Out of Scope"),
      p("Desktop/workstation support, upgrades, or reimaging", { indent: { left: 360 } }),
      p("Email migration or Microsoft 365 tenant configuration", { indent: { left: 360 } }),
      p("Line-of-business application reconfiguration beyond basic validation", { indent: { left: 360 } }),
      p("Procurement of Microsoft 365 / OneDrive licenses (Client responsibility)", { indent: { left: 360 } }),
      p("Physical decommissioning or disposal of the old server hardware", { indent: { left: 360 } }),
      p("Cloudbrink per-user subscription licensing (billed separately by Cloudbrink)", { indent: { left: 360 } }),
      p("Network equipment upgrades at Client's office", { indent: { left: 360 } }),
      spacer(),

      heading2("2.3 Assumptions"),
      p("Client will provide administrative credentials and access to the existing server", { indent: { left: 360 } }),
      p("Client will ensure all critical data is backed up prior to migration start", { indent: { left: 360 } }),
      p("Client's 500/500 Mbps internet is sufficient for Cloudbrink performance", { indent: { left: 360 } }),
      p("Client has or will procure Microsoft 365 licenses with OneDrive/SharePoint storage", { indent: { left: 360 } }),
      p("Migration work will be performed during off-hours to minimize disruption", { indent: { left: 360 } }),
      brandRule(),

      // 3. PROJECT PHASES
      heading1("3. PROJECT PHASES"),

      heading2("Phase 1: Discovery & Assessment"),
      p("Comprehensive audit of the existing physical server including installed roles, services, applications, shared folder structure, permissions, and network configuration."),
      spacer(),
      makeTable(
        ["Role", "Description", "Rate", "Hours", "Timeline"],
        [
          ["CTO Advisory", "Migration strategy, architecture planning, risk assessment", "$250/hr", "2", "Week 1"],
          ["Tech Support (US)", "Server audit, inventory, and documentation", "$150/hr", "2", "Week 1"],
          ["", "Phase 1 Total", "", "4", ""],
        ],
        [18, 37, 12, 10, 13]
      ),
      spacer(),

      heading2("Phase 2: Cloud Environment Provisioning"),
      p("Provision and configure the target environment in Technijian datacenter: two virtual machines, storage, networking, and firewall rules."),
      spacer(),
      makeTable(
        ["Role", "Description", "Rate", "Hours", "Timeline"],
        [
          ["Tech Support (US)", "VM provisioning and OS install", "$150/hr", "4", "Week 1-2"],
          ["Tech Support (US)", "Network and storage configuration", "$150/hr", "2", "Week 1-2"],
          ["Tech Support (Offshore)", "Backup setup (Veeam)", "$45/hr", "2", "Week 2"],
          ["", "Phase 2 Total", "", "8", ""],
        ],
        [18, 37, 12, 10, 13]
      ),
      spacer(),

      heading2("Phase 3: Physical-to-Virtual Server Migration"),
      p("Migrate the server OS and applications (~119 GB local volume) to VM1 via P2V. Shared folder data (~779 GB) is migrated separately to OneDrive/SharePoint in Phase 4. Includes pre-migration backup, driver remediation, Windows activation, service validation, and network cutover."),
      spacer(),
      makeTable(
        ["Role", "Description", "Rate", "Hours", "Timeline"],
        [
          ["Tech Support (US)", "Pre-migration backup verification and snapshot", "$150/hr", "2", "Week 2"],
          ["Tech Support (US)", "P2V conversion setup (Disk2VHD / Veeam)", "$150/hr", "2", "Week 2-3"],
          ["Tech Support (Offshore)", "Data transfer monitoring (~119 GB OS volume)", "$45/hr", "2", "Week 2-3"],
          ["Tech Support (US)", "Driver cleanup, HAL remediation, VM tools install", "$150/hr", "2", "Week 3"],
          ["Tech Support (US)", "Windows activation, licensing validation", "$150/hr", "1", "Week 3"],
          ["Tech Support (US)", "Server role/service validation (AD, DNS, DHCP, file shares, print)", "$150/hr", "3", "Week 3"],
          ["Tech Support (US)", "DNS/IP reconfiguration and network cutover", "$150/hr", "2", "Week 3"],
          ["Tech Support (Offshore)", "Performance validation and baseline comparison", "$45/hr", "2", "Week 3"],
          ["", "Phase 3 Total", "", "16", ""],
        ],
        [18, 37, 12, 10, 13]
      ),
      spacer(),

      heading2("Phase 4: Shared Folder Migration to OneDrive / SharePoint"),
      p("Migrate ~718 GB of shared folder data to SharePoint Online / OneDrive for Business. Includes site architecture design, pre-migration file remediation (long paths, special characters), NTFS-to-SharePoint permission mapping, incremental migration runs, and per-workstation OneDrive sync client setup."),
      spacer(),
      makeTable(
        ["Role", "Description", "Rate", "Hours", "Timeline"],
        [
          ["CTO Advisory", "SharePoint site collection architecture and library design", "$250/hr", "2", "Week 3"],
          ["Tech Support (US)", "SharePoint Migration Tool setup and configuration", "$150/hr", "2", "Week 3"],
          ["Tech Support (Offshore)", "Pre-migration file scan and remediation (long paths, special chars)", "$45/hr", "3", "Week 3"],
          ["Tech Support (US)", "Initial bulk migration kickoff (~718 GB)", "$150/hr", "2", "Week 3-4"],
          ["Tech Support (Offshore)", "Migration monitoring, failed item resolution, delta sync", "$45/hr", "3", "Week 4"],
          ["Tech Support (US)", "NTFS-to-SharePoint permission mapping and validation", "$150/hr", "4", "Week 4"],
          ["Tech Support (Offshore)", "OneDrive sync client deployment on user workstations", "$45/hr", "2", "Week 4-5"],
          ["Tech Support (US)", "User training session and quick-reference guide", "$150/hr", "2", "Week 5"],
          ["Tech Support (Offshore)", "Post-migration validation (file counts, integrity, access)", "$45/hr", "2", "Week 5"],
          ["", "Phase 4 Total", "", "22", ""],
        ],
        [18, 37, 12, 10, 13]
      ),
      spacer(),

      heading2("Phase 5: Cloudbrink ZTNA Deployment"),
      p("Deploy Cloudbrink ZTNA virtual appliance on VM2. Includes tenant configuration, connector deployment, Microsoft Entra ID integration, application resource definitions, per-user ZTNA policies, split tunneling, and agent deployment to each end-user device."),
      spacer(),
      makeTable(
        ["Role", "Description", "Rate", "Hours", "Timeline"],
        [
          ["CTO Advisory", "ZTNA architecture, policy design, application resource planning", "$250/hr", "2", "Week 5"],
          ["Tech Support (US)", "Cloudbrink tenant setup and connector deployment on VM2", "$150/hr", "2", "Week 5"],
          ["Tech Support (US)", "Microsoft Entra ID (Azure AD) identity provider integration", "$150/hr", "2", "Week 5"],
          ["Tech Support (US)", "Split tunneling, routing, and performance tuning", "$150/hr", "1", "Week 5"],
          ["Tech Support (Offshore)", "Cloudbrink agent deployment to end-user devices", "$45/hr", "3", "Week 5-6"],
          ["Tech Support (US)", "Multi-location access testing and troubleshooting", "$150/hr", "2", "Week 6"],
          ["", "Phase 5 Total", "", "12", ""],
        ],
        [18, 37, 12, 10, 13]
      ),
      spacer(),

      heading2("Phase 6: Security & Management Agent Deployment"),
      p("Install and configure all security and management agents on both virtual machines."),
      spacer(),
      makeTable(
        ["Role", "Description", "Rate", "Hours", "Timeline"],
        [
          ["Tech Support (US)", "Agent installation and configuration", "$150/hr", "2", "Week 6"],
          ["Tech Support (Offshore)", "Validation and reporting verification", "$45/hr", "2", "Week 6"],
          ["", "Phase 6 Total", "", "4", ""],
        ],
        [18, 37, 12, 10, 13]
      ),
      spacer(),

      heading2("Phase 7: Testing, Validation & Go-Live"),
      p("End-to-end testing of migrated server, OneDrive/SharePoint access, Cloudbrink ZTNA connectivity, and all security agents. Coordinated production cutover during a planned maintenance window."),
      spacer(),
      makeTable(
        ["Role", "Description", "Rate", "Hours", "Timeline"],
        [
          ["CTO Advisory", "Go-live coordination, cutover plan review, client sign-off", "$250/hr", "2", "Week 6"],
          ["Tech Support (US)", "End-to-end functional testing (server, apps, shares)", "$150/hr", "3", "Week 6"],
          ["Tech Support (US)", "Coordinated go-live cutover (DNS, firewall, routing)", "$150/hr", "2", "Week 6-7"],
          ["Tech Support (Offshore)", "Cloudbrink and OneDrive access validation with end users", "$45/hr", "1", "Week 7"],
          ["Tech Support (Offshore)", "Post-cutover monitoring (first 48 hours)", "$45/hr", "2", "Week 7"],
          ["", "Phase 7 Total", "", "10", ""],
        ],
        [18, 37, 12, 10, 13]
      ),
      spacer(),

      heading2("Phase 8: Post-Migration Support (30 Days)"),
      p("30-day post-migration support period for issue resolution, performance tuning, and user assistance."),
      spacer(),
      makeTable(
        ["Role", "Description", "Rate", "Hours", "Timeline"],
        [
          ["Tech Support (US)", "Escalated issue resolution and performance tuning", "$150/hr", "2", "Weeks 7-11"],
          ["Tech Support (Offshore)", "Routine support tickets, monitoring, user assistance", "$45/hr", "6", "Weeks 7-11"],
          ["", "Phase 8 Total", "", "8", ""],
        ],
        [18, 37, 12, 10, 13]
      ),
      brandRule(),

      // 5. PRICING
      heading1("4. PRICING AND PAYMENT"),

      heading2("4.1 Rate Card"),
      spacer(),
      makeTable(
        ["Role", "Location", "Rate"],
        [
          ["CTO Advisory", "United States", "$250.00/hr"],
          ["Tech Support", "United States", "$150.00/hr"],
          ["Tech Support", "Offshore (India)", "$45.00/hr"],
        ],
        [30, 35, 35]
      ),
      spacer(),

      heading2("4.2 One-Time Migration Labor"),
      spacer(),
      makeTable(
        ["Phase", "Description", "CTO ($250)", "US Tech ($150)", "Offshore ($45)", "Total Hrs", "Cost"],
        [
          ["Phase 1", "Discovery & Assessment", "2", "2", "—", "4", "$800.00"],
          ["Phase 2", "Cloud Environment Provisioning", "—", "6", "2", "8", "$990.00"],
          ["Phase 3", "Server Migration (P2V)", "—", "12", "4", "16", "$1,980.00"],
          ["Phase 4", "OneDrive / SharePoint Migration", "2", "10", "10", "22", "$2,450.00"],
          ["Phase 5", "Cloudbrink ZTNA Deployment", "2", "7", "3", "12", "$1,685.00"],
          ["Phase 6", "Security Agent Deployment", "—", "2", "2", "4", "$390.00"],
          ["Phase 7", "Testing & Go-Live", "2", "5", "3", "10", "$1,385.00"],
          ["Phase 8", "Post-Migration Support", "—", "2", "6", "8", "$570.00"],
          ["TOTAL", "", "8", "46", "30", "84", "$10,250.00"],
        ],
        [10, 26, 10, 12, 12, 10, 14]
      ),
      spacer(),
      p("CTO Advisory: 8 hrs x $250/hr = $2,000  |  Tech Support US: 46 hrs x $150/hr = $6,900  |  Offshore: 30 hrs x $45/hr = $1,350", { bold: true, size: 18, color: CHARCOAL }),
      spacer(),
      p("Pricing Type: Estimate Cost — Actual time billed at the applicable rate. If hours are projected to exceed the estimate by more than 10%, Technijian will notify Client before proceeding.", { italics: true, size: 20 }),
      brandRule(),

      // ONGOING MONTHLY - TECHNIJIAN
      heading2("4.2 Ongoing Monthly Services — Technijian Datacenter (Recommended)"),
      spacer(),
      p("Cloud Infrastructure (2 VMs)", { bold: true, color: CHARCOAL }),
      spacer(),
      makeTable(
        ["Service", "Code", "Qty", "Unit Price", "Monthly"],
        [
          ["VM1 — vCores (Primary Server)", "CL-VC", "4", "$6.25", "$25.00"],
          ["VM1 — Memory (GB)", "CL-GB", "16", "$0.63", "$10.08"],
          ["VM1 — Shared Bandwidth", "CL-SBW", "1", "$15.00", "$15.00"],
          ["VM2 — vCores (Cloudbrink)", "CL-VC", "2", "$6.25", "$12.50"],
          ["VM2 — Memory (GB)", "CL-GB", "4", "$0.63", "$2.52"],
          ["VM2 — Shared Bandwidth", "CL-SBW", "1", "$15.00", "$15.00"],
          ["Production Storage", "TB-PSTR", "1 TB", "$200.00", "$200.00"],
          ["Backup Storage", "TB-BSTR", "1 TB", "$50.00", "$50.00"],
          ["Infrastructure Subtotal", "", "", "", "$330.10"],
        ],
        [35, 12, 10, 18, 25]
      ),
      spacer(),
      p("Microsoft Licensing", { bold: true, color: CHARCOAL }),
      spacer(),
      makeTable(
        ["Service", "Code", "Qty", "Unit Price", "Monthly"],
        [
          ["Windows Server Std — 2-Core Pack", "MS-STD", "4", "$5.25", "$21.00"],
          ["Licensing Subtotal", "", "", "", "$21.00"],
        ],
        [35, 12, 10, 18, 25]
      ),
      spacer(),
      p("Security & Management Agents (2 Servers)", { bold: true, color: CHARCOAL }),
      spacer(),
      makeTable(
        ["Service", "Code", "Qty", "Unit Price", "Monthly"],
        [
          ["CrowdStrike — Server", "AVS", "2", "$10.50", "$21.00"],
          ["Huntress — Server", "AVHS", "2", "$6.00", "$12.00"],
          ["Patch Management", "PMW", "2", "$4.00", "$8.00"],
          ["My Remote", "MR", "2", "$2.00", "$4.00"],
          ["Security Subtotal", "", "", "", "$45.00"],
        ],
        [35, 12, 10, 18, 25]
      ),
      spacer(),
      p("Backup & Recovery", { bold: true, color: CHARCOAL }),
      spacer(),
      makeTable(
        ["Service", "Code", "Qty", "Unit Price", "Monthly"],
        [
          ["Image Backup (Veeam)", "IB", "2", "$15.00", "$30.00"],
          ["Backup Subtotal", "", "", "", "$30.00"],
        ],
        [35, 12, 10, 18, 25]
      ),
      spacer(),
      ...highlightBox(["TECHNIJIAN TOTAL MONTHLY:  $426.10", "TECHNIJIAN TOTAL ANNUAL:  $5,113.20"]),
      brandRule(),

      // AZURE COMPARISON
      heading2("4.3 Azure Equivalent Monthly Cost (For Comparison)"),
      spacer(),
      p("Equivalent cost to host the same environment in Microsoft Azure (pay-as-you-go, West US 2 region):"),
      spacer(),
      makeTable(
        ["Service", "Azure SKU", "Monthly"],
        [
          ["VM1 — Primary Server", "D4s v5 (4 vCPU, 16 GB) Windows", "$281.00"],
          ["VM2 — Cloudbrink Appliance", "B2s (2 vCPU, 4 GB) Linux", "$31.00"],
          ["Managed Disk", "1 TB Premium SSD (P30)", "$123.00"],
          ["Azure Backup", "Recovery Services Vault (1 TB)", "$55.00"],
          ["Outbound Data Transfer", "~500 GB egress / month", "$44.00"],
          ["Static Public IP", "1 Standard Static IP", "$4.00"],
          ["Windows Server License", "Included in VM pricing", "$0.00"],
          ["CrowdStrike — Server", "2 servers", "$21.00"],
          ["Huntress — Server", "2 servers", "$12.00"],
          ["Patch Management", "2 servers", "$8.00"],
          ["My Remote", "2 servers", "$4.00"],
          ["Azure Monitor", "Basic monitoring & alerts", "$15.00"],
          ["AZURE TOTAL MONTHLY", "", "$598.00"],
          ["AZURE TOTAL ANNUAL", "", "$7,176.00"],
        ],
        [35, 40, 25]
      ),
      brandRule(),

      // COMPARISON SUMMARY
      heading2("4.4 Cost Comparison Summary"),
      spacer(),
      makeTable(
        ["", "Technijian Datacenter", "Microsoft Azure", "Savings"],
        [
          ["Monthly Cost", "$426.10", "$598.00", "$171.90 (28.7%)"],
          ["Annual Cost", "$5,113.20", "$7,176.00", "$2,062.80 (28.7%)"],
          ["3-Year Cost", "$15,339.60", "$21,528.00", "$6,188.40 (28.7%)"],
        ],
        [20, 25, 25, 30]
      ),
      spacer(),
      p("Technijian Datacenter Advantages:", { bold: true, color: BLUE, size: 24 }),
      spacer(),
      p("28.7% lower monthly cost compared to Azure pay-as-you-go pricing", { indent: { left: 360 }, color: GREEN, bold: true }),
      p("$2,062.80 annual savings on hosting alone", { indent: { left: 360 }, color: GREEN, bold: true }),
      p("No egress / bandwidth charges — shared bandwidth included", { indent: { left: 360 } }),
      p("No surprise Azure consumption charges — predictable, fixed monthly billing", { indent: { left: 360 } }),
      p("Local Technijian support team manages infrastructure end-to-end", { indent: { left: 360 } }),
      p("Single vendor for hosting, security, backup, and support", { indent: { left: 360 } }),
      p("Included Veeam backup — enterprise-grade with faster recovery", { indent: { left: 360 } }),
      p("No Azure expertise required from Client", { indent: { left: 360 } }),
      brandRule(),

      // PAYMENT SCHEDULE
      heading2("4.5 Payment Schedule"),
      spacer(),
      makeTable(
        ["Milestone", "Invoiced", "Amount"],
        [
          ["Project kickoff (before Phase 1)", "Upon SOW execution", "$5,125.00 (50%)"],
          ["Go-live completion (after Phase 7)", "Upon go-live", "$5,125.00 (50%)"],
          ["Monthly managed services", "1st of each month", "$426.10/month"],
          ["ONE-TIME PROJECT TOTAL", "", "$10,250.00"],
        ],
        [40, 30, 30]
      ),
      spacer(),
      p("All invoices are due and payable within thirty (30) days of the invoice date.", { italics: true, size: 20 }),
      brandRule(),

      // CLIENT RESPONSIBILITIES
      heading1("5. CLIENT RESPONSIBILITIES"),
      p("Client shall:"),
      spacer(),
      p("(a) Provide administrative credentials and physical/remote access to the existing server;", { indent: { left: 360 } }),
      p("(b) Designate Ed Pits (or alternate) as the authorized point of contact;", { indent: { left: 360 } }),
      p("(c) Review and approve deliverables within five (5) business days of submission;", { indent: { left: 360 } }),
      p("(d) Ensure all critical data is backed up prior to migration start;", { indent: { left: 360 } }),
      p("(e) Inform users of planned service changes, maintenance windows, and downtime;", { indent: { left: 360 } }),
      p("(f) Procure and maintain Microsoft 365 licenses with adequate OneDrive/SharePoint storage (~779 GB); and", { indent: { left: 360 } }),
      p("(g) Coordinate with Cloudbrink for per-user ZTNA subscription licensing.", { indent: { left: 360 } }),
      brandRule(),

      // CHANGE MANAGEMENT
      heading1("6. CHANGE MANAGEMENT"),
      multiRun([{ text: "6.01. ", bold: true, color: CHARCOAL }, { text: "Any changes to the scope, schedule, or pricing of this SOW must be documented in a written Change Order signed by both Parties." }]),
      spacer(),
      multiRun([{ text: "6.02. ", bold: true, color: CHARCOAL }, { text: "If Client requests out-of-scope work, Technijian shall provide a Change Order detailing the additional work, estimated hours, and cost impact." }]),
      spacer(),
      multiRun([{ text: "6.03. ", bold: true, color: CHARCOAL }, { text: "Technijian shall not proceed with out-of-scope work without an approved Change Order, except where delay would harm Client's systems." }]),
      brandRule(),

      // ACCEPTANCE
      heading1("7. ACCEPTANCE"),
      multiRun([{ text: "7.01. ", bold: true, color: CHARCOAL }, { text: "Upon completion of each phase, Technijian shall notify Client that deliverables are ready for review." }]),
      spacer(),
      multiRun([{ text: "7.02. ", bold: true, color: CHARCOAL }, { text: "Client shall review and provide written acceptance or a description of deficiencies within five (5) business days." }]),
      spacer(),
      multiRun([{ text: "7.03. ", bold: true, color: CHARCOAL }, { text: "If Client does not respond within the review period, deliverables shall be deemed accepted." }]),
      brandRule(),

      // GOVERNING TERMS
      heading1("8. GOVERNING TERMS"),
      p("The terms of the Master Service Agreement (MSA-OKL-2026) shall govern this SOW. In the event of a conflict between this SOW and the MSA, the MSA shall prevail unless this SOW expressly states otherwise."),

      // Signatures
      ...signatures(),
    ])
  ];
  return new Document({ styles: docStyles, sections });
}

// ============================================================
// MAIN
// ============================================================
async function main() {
  const msa = buildMSA();
  const sow = buildSOW();

  const msaBuffer = await Packer.toBuffer(msa);
  fs.writeFileSync(path.join(__dirname, "MSA-OKL.docx"), msaBuffer);
  console.log("Generated: clients/OKL/MSA-OKL.docx");

  const sowBuffer = await Packer.toBuffer(sow);
  fs.writeFileSync(path.join(__dirname, "SOW-001-ServerMigration.docx"), sowBuffer);
  console.log("Generated: clients/OKL/SOW-001-ServerMigration.docx");
}

main().catch(e => { console.error(e.message); console.error(e.stack); });
