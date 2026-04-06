const fs = require("fs");
const path = require("path");
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  Header, Footer, AlignmentType, LevelFormat,
  HeadingLevel, BorderStyle, WidthType, ShadingType,
  PageNumber, PageBreak, ImageRun
} = require("docx");

// ===== TECHNIJIAN BRAND COLORS (from Brand Guide 2026) =====
const BLUE = "006DB6";       // Core Blue - headings, links, table headers
const ORANGE = "F67D4B";     // Core Orange - accents, CTAs
const TEAL = "1EAAC8";       // Blue/Green - supporting accent
const GREY = "59595B";       // Body text, captions
const CHARCOAL = "1A1A2E";   // Dark - H2 headings, strong text
const OFF_WHITE = "F8F9FA";  // Table data rows, backgrounds
const WHITE = "FFFFFF";       // Table header text, clean areas
const FONT = "Open Sans";    // Primary typeface

// Logo
let logoBuffer = null;
const logoPath = path.join(__dirname, "logo.jpg");
try {
  logoBuffer = fs.readFileSync(logoPath);
} catch (e) {
  console.log("Logo not found at", logoPath);
}

// ===== BRAND-COMPLIANT STYLES =====
const docStyles = {
  default: {
    document: {
      run: { font: FONT, size: 22, color: GREY } // 11pt Open Sans #59595B
    }
  },
  paragraphStyles: [
    {
      id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
      run: { size: 36, bold: true, font: FONT, color: BLUE },  // 18pt Open Sans Bold #006DB6
      paragraph: { spacing: { before: 360, after: 240 }, outlineLevel: 0 }
    },
    {
      id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
      run: { size: 28, bold: true, font: FONT, color: CHARCOAL },  // 14pt Open Sans Bold #1A1A2E
      paragraph: { spacing: { before: 280, after: 160 }, outlineLevel: 1 }
    },
    {
      id: "Heading3", name: "Heading 3", basedOn: "Normal", next: "Normal", quickFormat: true,
      run: { size: 24, bold: true, font: FONT, color: CHARCOAL },  // 12pt Open Sans Bold #1A1A2E
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
      reference: "numbers",
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
  return new Paragraph(pOpts);
}

function heading1(text) { return p(text, { heading: HeadingLevel.HEADING_1 }); }
function heading2(text) { return p(text, { heading: HeadingLevel.HEADING_2 }); }
function heading3(text) { return p(text, { heading: HeadingLevel.HEADING_3 }); }
function spacer() { return p("", { spacing: { after: 120 } }); }

function brandRule() {
  // Horizontal rule using Core Blue
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

// ===== COVER PAGE =====
function coverPage(title, subtitle) {
  const items = [];
  // Spacers to push content down
  items.push(p("", { spacing: { before: 2400 } }));

  // Logo image or wordmark
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

  // Orange accent line
  items.push(orangeAccentRule());

  // Document title
  items.push(p(title, { size: 48, bold: true, color: CHARCOAL, alignment: AlignmentType.CENTER, spacing: { before: 400, after: 200 } }));

  // Subtitle
  if (subtitle) {
    items.push(p(subtitle, { size: 24, color: GREY, alignment: AlignmentType.CENTER, spacing: { after: 400 } }));
  }

  items.push(orangeAccentRule());

  // Company info
  items.push(p("", { spacing: { after: 1200 } }));
  items.push(p("Technijian, Inc.", { size: 22, bold: true, color: CHARCOAL, alignment: AlignmentType.CENTER }));
  items.push(p("18 Technology Dr., Ste 141  |  Irvine, CA 92618  |  949.379.8499", { size: 20, color: GREY, alignment: AlignmentType.CENTER }));

  // Page break after cover
  items.push(new Paragraph({ children: [new PageBreak()] }));

  return items;
}

// ===== SIGNATURE BLOCK =====
function signatureBlock() {
  return [
    brandRule(),
    heading2("SIGNATURES"),
    spacer(),
    p("TECHNIJIAN, INC.", { bold: true, color: CHARCOAL }),
    spacer(),
    p("By: ___________________________________", { color: GREY }),
    spacer(),
    p("Name: _________________________________", { color: GREY }),
    spacer(),
    p("Title: _________________________________", { color: GREY }),
    spacer(),
    p("Date: _________________________________", { color: GREY }),
    spacer(),
    spacer(),
    p("[CLIENT NAME]", { bold: true, color: CHARCOAL }),
    spacer(),
    p("By: ___________________________________", { color: GREY }),
    spacer(),
    p("Name: _________________________________", { color: GREY }),
    spacer(),
    p("Title: _________________________________", { color: GREY }),
    spacer(),
    p("Date: _________________________________", { color: GREY }),
  ];
}

// ===== BRANDED TABLES (matching Brand Guide format) =====
const thinBorder = { style: BorderStyle.SINGLE, size: 1, color: "DDDDDD" };
const tableBorders = { top: thinBorder, bottom: thinBorder, left: thinBorder, right: thinBorder };
const cellPadding = { top: 80, bottom: 80, left: 120, right: 120 };

function brandTableCell(text, opts = {}) {
  const width = opts.width || 2340;
  const isHeader = opts.header || false;
  const runOpts = {
    font: FONT,
    size: 20,  // 10pt
    text,
    color: isHeader ? WHITE : GREY,
    bold: isHeader
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
        return brandTableCell(text, { width: widths[ci], alt: ri % 2 === 0 });
      })
    }))
  ];
  return new Table({
    width: { size: totalWidth, type: WidthType.DXA },
    columnWidths: widths,
    rows: tableRows
  });
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
  // Thin blue line under header
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

// First page has cover (no header/footer), subsequent pages have header/footer
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

// ===== DOCUMENT GENERATORS =====

async function generateNDA() {
  const doc = new Document({
    styles: docStyles,
    numbering,
    sections: [
      {
        properties: coverSectionProps(),
        children: coverPage("Non-Disclosure Agreement", "Confidential")
      },
      {
        properties: contentSectionProps(),
        children: [
          heading1("NON-DISCLOSURE AGREEMENT"),
          multiRun([{ text: "Effective Date: ", bold: true, color: CHARCOAL }, { text: "[DATE]" }]),
          spacer(),
          p("This Non-Disclosure Agreement (\"Agreement\") is entered into by and between:"),
          spacer(),
          p("Technijian, Inc. (\"Disclosing Party\")", { bold: true, color: CHARCOAL }),
          p("18 Technology Drive, Suite 141"),
          p("Irvine, California 92618"),
          spacer(),
          p("and"),
          spacer(),
          p("[CLIENT NAME] (\"Receiving Party\")", { bold: true, color: CHARCOAL }),
          p("[CLIENT ADDRESS]"),
          p("[CITY, STATE ZIP]"),
          spacer(),
          p("(collectively, the \"Parties\")"),
          brandRule(),

          heading2("1. PURPOSE"),
          p("The Parties wish to explore a potential business relationship regarding managed IT services, cybersecurity, cloud infrastructure, and related technology solutions (the \"Purpose\"). In connection with the Purpose, each Party may disclose Confidential Information to the other Party."),
          spacer(),

          heading2("2. DEFINITION OF CONFIDENTIAL INFORMATION"),
          p("\"Confidential Information\" means any and all non-public information disclosed by either Party to the other, whether orally, in writing, electronically, or by inspection, including but not limited to:"),
          spacer(),
          p("(a) Business information, including pricing, client lists, vendor relationships, financial data, business plans, and marketing strategies;", { indent: { left: 360 } }),
          p("(b) Technical information, including network architecture, system configurations, security assessments, audit reports, IP addresses, credentials, and infrastructure documentation;", { indent: { left: 360 } }),
          p("(c) Proprietary methodologies, software, tools, and processes;", { indent: { left: 360 } }),
          p("(d) Any information marked or identified as \"Confidential\" at the time of disclosure; and", { indent: { left: 360 } }),
          p("(e) Any information that a reasonable person would understand to be confidential given the nature of the information and the circumstances of disclosure.", { indent: { left: 360 } }),
          spacer(),
          p("Confidential Information does not include information that:"),
          spacer(),
          p("(i) Is or becomes publicly available through no fault of the Receiving Party;", { indent: { left: 360 } }),
          p("(ii) Was already known to the Receiving Party prior to disclosure, as demonstrated by written records;", { indent: { left: 360 } }),
          p("(iii) Is independently developed by the Receiving Party without use of or reference to the Confidential Information; or", { indent: { left: 360 } }),
          p("(iv) Is rightfully received from a third party without restriction on disclosure.", { indent: { left: 360 } }),
          spacer(),

          heading2("3. OBLIGATIONS OF THE RECEIVING PARTY"),
          p("The Receiving Party agrees to:"),
          spacer(),
          p("(a) Hold all Confidential Information in strict confidence;", { indent: { left: 360 } }),
          p("(b) Not disclose Confidential Information to any third party without the prior written consent of the Disclosing Party;", { indent: { left: 360 } }),
          p("(c) Use the Confidential Information solely for the Purpose described in Section 1;", { indent: { left: 360 } }),
          p("(d) Limit access to Confidential Information to those employees, agents, and advisors who have a need to know and who are bound by confidentiality obligations at least as protective as those in this Agreement;", { indent: { left: 360 } }),
          p("(e) Take reasonable measures to protect the Confidential Information from unauthorized disclosure, using at least the same degree of care the Receiving Party uses for its own confidential information, but in no event less than reasonable care; and", { indent: { left: 360 } }),
          p("(f) Promptly notify the Disclosing Party in writing of any unauthorized disclosure or use of Confidential Information.", { indent: { left: 360 } }),
          spacer(),

          heading2("4. RETURN OF MATERIALS"),
          p("Upon termination of this Agreement or upon written request by the Disclosing Party, the Receiving Party shall promptly return or destroy all Confidential Information in its possession, including all copies, notes, summaries, and extracts thereof, and shall certify such return or destruction in writing upon request."),
          spacer(),

          heading2("5. NO LICENSE OR WARRANTY"),
          p("Nothing in this Agreement grants either Party any rights to the other Party's Confidential Information, intellectual property, or proprietary materials, except the limited right to use such information for the Purpose. All Confidential Information is provided \"AS IS\" without warranty of any kind."),
          spacer(),

          heading2("6. NO OBLIGATION"),
          p("This Agreement does not obligate either Party to enter into any further agreement, transaction, or business relationship. Either Party may terminate discussions at any time without liability."),
          spacer(),

          heading2("7. TERM AND TERMINATION"),
          p("This Agreement shall remain in effect for a period of two (2) years from the Effective Date. The confidentiality obligations set forth in this Agreement shall survive termination for a period of three (3) years following the date of disclosure of the Confidential Information."),
          spacer(),

          heading2("8. REMEDIES"),
          p("The Receiving Party acknowledges that any breach of this Agreement may cause irreparable harm to the Disclosing Party for which monetary damages may be inadequate. Accordingly, the Disclosing Party shall be entitled to seek injunctive relief in addition to any other remedies available at law or in equity."),
          spacer(),

          heading2("9. GOVERNING LAW AND DISPUTE RESOLUTION"),
          p("This Agreement shall be governed by and construed in accordance with the laws of the State of California. Any dispute arising under this Agreement shall be resolved in the state or federal courts located in Orange County, California, and each Party consents to the jurisdiction of such courts."),
          spacer(),

          heading2("10. GENERAL PROVISIONS"),
          p("(a) Entire Agreement. This Agreement constitutes the entire agreement between the Parties with respect to the subject matter hereof and supersedes all prior or contemporaneous agreements, whether written or oral.", { indent: { left: 360 } }),
          spacer(),
          p("(b) Amendment. This Agreement may not be amended except by a written instrument signed by both Parties.", { indent: { left: 360 } }),
          spacer(),
          p("(c) Severability. If any provision of this Agreement is found to be invalid or unenforceable, the remaining provisions shall continue in full force and effect.", { indent: { left: 360 } }),
          spacer(),
          p("(d) Assignment. Neither Party may assign this Agreement without the prior written consent of the other Party.", { indent: { left: 360 } }),
          spacer(),
          p("(e) Counterparts. This Agreement may be executed in counterparts, each of which shall be deemed an original.", { indent: { left: 360 } }),

          ...signatureBlock()
        ]
      }
    ]
  });
  const buffer = await Packer.toBuffer(doc);
  fs.writeFileSync("templates/01-NDA.docx", buffer);
  console.log("Generated: 01-NDA.docx");
}

async function generateMSA() {
  const doc = new Document({
    styles: docStyles,
    numbering,
    sections: [
      {
        properties: coverSectionProps(),
        children: coverPage("Master Service Agreement", "Technology Services")
      },
      {
        properties: contentSectionProps(),
        children: [
          heading1("MASTER SERVICE AGREEMENT"),
          multiRun([{ text: "Agreement Number: ", bold: true, color: CHARCOAL }, { text: "[MSA-XXXX]" }]),
          multiRun([{ text: "Effective Date: ", bold: true, color: CHARCOAL }, { text: "[DATE]" }]),
          spacer(),
          p("This Master Service Agreement (\"Agreement\") is entered into by and between:"),
          spacer(),
          p("Technijian, Inc. (\"Technijian\")", { bold: true, color: CHARCOAL }),
          p("18 Technology Drive, Suite 141"),
          p("Irvine, California 92618"),
          spacer(),
          p("and"),
          spacer(),
          p("[CLIENT NAME] (\"Client\")", { bold: true, color: CHARCOAL }),
          p("[CLIENT ADDRESS]"),
          p("[CITY, STATE ZIP]"),
          brandRule(),

          heading2("RECITALS"),
          p("WHEREAS, Technijian provides managed IT services, cybersecurity, cloud infrastructure, telephony, and related technology solutions; and"),
          spacer(),
          p("WHEREAS, Client desires to engage Technijian to provide certain services as described in the Schedules attached hereto;"),
          spacer(),
          p("NOW, THEREFORE, for good and valuable consideration, the receipt and sufficiency of which are hereby acknowledged, the Parties agree as follows:"),
          brandRule(),

          heading2("SECTION 1 -- SCOPE OF SERVICES"),
          multiRun([{ text: "1.01. Services. ", bold: true, color: CHARCOAL }, { text: "Technijian shall provide the services described in the Schedules attached to this Agreement, which are incorporated herein by reference:" }]),
          spacer(),
          p("Schedule A -- Monthly Managed Services (Online Services, SIP Trunk, Virtual Staff)", { numbering: { reference: "bullets", level: 0 } }),
          p("Schedule B -- Subscription and License Services", { numbering: { reference: "bullets", level: 0 } }),
          p("Schedule C -- Rate Card", { numbering: { reference: "bullets", level: 0 } }),
          spacer(),
          p("Additional services may be provided through Statements of Work (\"SOWs\") executed under this Agreement."),
          spacer(),
          multiRun([{ text: "1.02. Standard of Care. ", bold: true, color: CHARCOAL }, { text: "Technijian shall perform all services in a professional and workmanlike manner, consistent with industry standards for managed IT service providers." }]),
          spacer(),
          multiRun([{ text: "1.03. Service Level Agreement. ", bold: true, color: CHARCOAL }, { text: "The service levels applicable to the services are set forth in Schedule A. Technijian shall use commercially reasonable efforts to meet the service levels described therein." }]),
          spacer(),
          multiRun([{ text: "1.04. Client Responsibilities. ", bold: true, color: CHARCOAL }, { text: "Client shall:" }]),
          p("(a) Provide Technijian with reasonable access to Client's systems, facilities, and personnel as necessary for Technijian to perform the services;", { indent: { left: 360 } }),
          p("(b) Designate a primary point of contact for communications with Technijian;", { indent: { left: 360 } }),
          p("(c) Maintain current and accurate information regarding Client's systems and infrastructure;", { indent: { left: 360 } }),
          p("(d) Comply with all applicable laws and regulations in connection with its use of the services; and", { indent: { left: 360 } }),
          p("(e) Be solely responsible for the security and management of Client's account credentials and passwords.", { indent: { left: 360 } }),
          spacer(),
          multiRun([{ text: "1.05. Independent Contractor. ", bold: true, color: CHARCOAL }, { text: "Technijian is an independent contractor. Nothing in this Agreement shall be construed to create a partnership, joint venture, agency, or employment relationship between the Parties." }]),
          spacer(),

          heading2("SECTION 2 -- TERM AND RENEWAL"),
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
          multiRun([{ text: "2.05. Effect of Termination.", bold: true, color: CHARCOAL }]),
          p("(a) Upon termination, Client shall pay all fees and charges for services rendered through the date of termination, including any remaining obligations for annual licenses and subscriptions procured on Client's behalf.", { indent: { left: 360 } }),
          p("(b) Technijian shall provide reasonable transition assistance for a period of up to thirty (30) days following termination, subject to payment of applicable fees.", { indent: { left: 360 } }),
          p("(c) Technijian shall return all Client Data in its possession within thirty (30) days of termination, in a commercially standard format, provided Client is not in breach of this Agreement.", { indent: { left: 360 } }),
          p("(d) The following sections shall survive termination: Section 3 (Payment), Section 4 (Confidentiality), Section 5 (Limitation of Liability), Section 6 (Indemnification), Section 7 (Intellectual Property), Section 8 (Dispute Resolution), Section 9.09 (Personnel Transition Fee), Section 10 (Data Protection), and Section 11 (Insurance).", { indent: { left: 360 } }),
          spacer(),

          heading2("SECTION 3 -- PAYMENT"),
          multiRun([{ text: "3.01. Fees. ", bold: true, color: CHARCOAL }, { text: "Client shall pay fees for the services as set forth in the applicable Schedule, SOW, or invoice. Fees are exclusive of applicable taxes." }]),
          spacer(),
          multiRun([{ text: "3.02. Invoice Types. ", bold: true, color: CHARCOAL }, { text: "Client may receive the following types of invoices from Technijian during the term of this Agreement. Each invoice will clearly identify its type, the applicable Schedule or SOW, and the billing period or delivery event." }]),
          spacer(),
          multiRun([{ text: "(a) Monthly Service Invoice. ", bold: true, color: CHARCOAL }, { text: "Issued on the first business day of each month for recurring managed services under Schedule A (Online Services, infrastructure, monitoring, desktop/server management). Billed in advance for the upcoming month." }], { indent: { left: 360 } }),
          multiRun([{ text: "(b) Monthly Recurring Subscription Invoice. ", bold: true, color: CHARCOAL }, { text: "Issued on the first business day of each month for subscription and license services under Schedule B (software licenses, SaaS subscriptions, SIP trunk services). Billed in advance for the upcoming month. Subscription quantities and pricing are as specified in the applicable Service Order." }], { indent: { left: 360 } }),
          multiRun([{ text: "(c) Weekly In-Contract Invoice. ", bold: true, color: CHARCOAL }, { text: "Issued every Friday for Virtual Staff (contracted support) services performed under Schedule A, Part 3, during the preceding week (Monday through Friday). Each invoice includes: (i) a listing of each support ticket addressed; (ii) the assigned resource, role, and hours spent per ticket; (iii) a description of the work performed per ticket; (iv) whether work was performed during normal or after-hours; and (v) the current running balance for each contracted role. The weekly in-contract invoice is issued for transparency and tracking purposes; the actual billed amount is governed by the cycle-based billing model described in Schedule A, Section 3.3." }], { indent: { left: 360 } }),
          multiRun([{ text: "(d) Weekly Out-of-Contract Invoice. ", bold: true, color: CHARCOAL }, { text: "Issued every Friday for labor services performed outside the scope of any active Schedule or SOW \u2014 including ad-hoc support requests, emergency work, and services performed under a SOW with hourly billing (such as CTO Advisory engagements). Each invoice includes: (i) a listing of each support ticket or task performed; (ii) the assigned resource, role, and applicable hourly rate from the Rate Card (Schedule C); (iii) time entries with hours billed per activity (in 15-minute increments); (iv) whether work was performed during normal or after-hours; and (v) the total hours and total amount for the week." }], { indent: { left: 360 } }),
          multiRun([{ text: "(e) Equipment and Materials Invoice. ", bold: true, color: CHARCOAL }, { text: "Issued upon delivery or procurement of hardware, software licenses (perpetual), or other tangible goods on Client\u2019s behalf. Each invoice includes: (i) item description, manufacturer, and model/part number; (ii) quantity and unit price; (iii) applicable sales tax; (iv) shipping and handling charges, if any; and (v) total amount due. Title to equipment shall not pass to Client until payment is received in full, as set forth in Section 3.09." }], { indent: { left: 360 } }),
          multiRun([{ text: "(f) Project Milestone Invoice. ", bold: true, color: CHARCOAL }, { text: "Issued upon completion of a project milestone as defined in an applicable SOW. The milestone, deliverables, and invoiced amount are as specified in the payment schedule of the SOW. Milestone invoices are billed in arrears upon acceptance of the deliverables or deemed acceptance under the SOW\u2019s acceptance provisions." }], { indent: { left: 360 } }),
          spacer(),
          multiRun([{ text: "3.03. Payment Terms. ", bold: true, color: CHARCOAL }, { text: "All invoices are due and payable within thirty (30) days of the invoice date, unless otherwise specified in the applicable Schedule or SOW." }]),
          spacer(),
          multiRun([{ text: "3.04. Late Payment. ", bold: true, color: CHARCOAL }, { text: "Invoices not paid within terms shall accrue a late fee of 1.5% per month (or the maximum rate permitted by law, whichever is less) on the unpaid balance, calculated from the date payment was due until the date payment is received in full. Late fees shall compound monthly and are payable in addition to the outstanding principal amount." }]),
          spacer(),
          multiRun([{ text: "3.05. Disputed Invoices.", bold: true, color: CHARCOAL }]),
          multiRun([{ text: "(a) Weekly Invoices (In-Contract and Out-of-Contract). ", bold: true, color: CHARCOAL }, { text: "Because weekly invoices include detailed ticket descriptions and time entries, Client shall have thirty (30) days from the invoice date to review and dispute any portion of a weekly invoice. Client shall notify Technijian in writing, specifying the ticket number(s) and nature of the dispute with reasonable particularity. Undisputed tickets and time entries on the same invoice shall remain payable by the due date. Failure to provide a timely written dispute notice within the thirty (30) day period shall constitute acceptance of all tickets and time entries on the invoice." }], { indent: { left: 360 } }),
          multiRun([{ text: "(b) All Other Invoices. ", bold: true, color: CHARCOAL }, { text: "For monthly service invoices, monthly recurring subscription invoices, equipment invoices, and project milestone invoices, Client shall notify Technijian in writing within fifteen (15) days of the invoice date if Client disputes any portion, specifying the nature and basis of the dispute with reasonable particularity. Client shall pay all undisputed amounts by the due date. Failure to provide a timely written dispute notice shall constitute acceptance of the invoice." }], { indent: { left: 360 } }),
          multiRun([{ text: "(c) Resolution. ", bold: true, color: CHARCOAL }, { text: "The Parties shall work in good faith to resolve any invoice dispute within thirty (30) days of the dispute notice. If the dispute results in an adjustment, Technijian shall issue a credit memo or revised invoice within ten (10) business days of resolution." }], { indent: { left: 360 } }),
          spacer(),
          multiRun([{ text: "3.06. Suspension of Services. ", bold: true, color: CHARCOAL }, { text: "If Client fails to pay any undisputed invoice within thirty (30) days of the due date, Technijian may, upon ten (10) days written notice, suspend services until payment is received. Suspension of services shall not relieve Client of its payment obligations." }]),
          spacer(),
          multiRun([{ text: "3.07. Taxes. ", bold: true, color: CHARCOAL }, { text: "Client shall be responsible for all applicable sales, use, and other taxes arising from the services, excluding taxes based on Technijian's income." }]),
          spacer(),

          heading2("SECTION 4 -- CONFIDENTIALITY"),
          multiRun([{ text: "4.01. Definition. ", bold: true, color: CHARCOAL }, { text: "\"Confidential Information\" means any non-public information disclosed by either Party to the other in connection with this Agreement, including business, technical, and financial information. If the Parties have executed a separate Non-Disclosure Agreement, its terms are incorporated herein by reference." }]),
          spacer(),
          multiRun([{ text: "4.02. Obligations. ", bold: true, color: CHARCOAL }, { text: "Each Party shall:" }]),
          p("(a) Hold the other Party's Confidential Information in confidence using at least the same degree of care it uses for its own confidential information, but not less than reasonable care;", { indent: { left: 360 } }),
          p("(b) Not disclose Confidential Information to third parties without prior written consent, except to employees, agents, and subcontractors who have a need to know and are bound by equivalent obligations; and", { indent: { left: 360 } }),
          p("(c) Not use Confidential Information for any purpose other than performing obligations under this Agreement.", { indent: { left: 360 } }),
          spacer(),
          multiRun([{ text: "4.03. Exclusions. ", bold: true, color: CHARCOAL }, { text: "Confidential Information does not include information that is or becomes publicly available through no fault of the receiving Party, was known to the receiving Party prior to disclosure, is independently developed, or is received from a third party without restriction." }]),
          spacer(),
          multiRun([{ text: "4.04. Compelled Disclosure. ", bold: true, color: CHARCOAL }, { text: "If required by law or court order to disclose Confidential Information, the receiving Party shall provide prompt written notice to the disclosing Party (to the extent legally permitted) and cooperate in seeking a protective order." }]),
          spacer(),
          multiRun([{ text: "4.05. Duration. ", bold: true, color: CHARCOAL }, { text: "Confidentiality obligations shall survive termination for a period of three (3) years." }]),
          spacer(),

          heading2("SECTION 5 -- LIMITATION OF LIABILITY"),
          multiRun([{ text: "5.01. Limitation. ", bold: true, color: CHARCOAL }, { text: "EXCEPT FOR BREACHES OF SECTION 4 (CONFIDENTIALITY), WILLFUL MISCONDUCT, OR GROSS NEGLIGENCE, NEITHER PARTY'S TOTAL AGGREGATE LIABILITY UNDER THIS AGREEMENT SHALL EXCEED THE TOTAL FEES PAID OR PAYABLE BY CLIENT UNDER THIS AGREEMENT DURING THE TWELVE (12) MONTH PERIOD IMMEDIATELY PRECEDING THE EVENT GIVING RISE TO THE CLAIM." }]),
          spacer(),
          multiRun([{ text: "5.02. Exclusion of Consequential Damages. ", bold: true, color: CHARCOAL }, { text: "IN NO EVENT SHALL EITHER PARTY BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING LOSS OF PROFITS, DATA, BUSINESS OPPORTUNITY, OR GOODWILL, REGARDLESS OF WHETHER SUCH DAMAGES WERE FORESEEABLE OR WHETHER EITHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES." }]),
          spacer(),
          multiRun([{ text: "5.04. Data Liability. ", bold: true, color: CHARCOAL }, { text: "While Technijian shall use commercially reasonable efforts to protect Client Data in its possession, Client acknowledges that:" }]),
          p("(a) Client is solely responsible for maintaining backup copies of its data;", { indent: { left: 360 } }),
          p("(b) Technijian's liability for data loss shall be limited to using commercially reasonable efforts to restore data from available backups; and", { indent: { left: 360 } }),
          p("(c) Technijian shall not be liable for data loss caused by Client's actions, third-party attacks, or events beyond Technijian's reasonable control.", { indent: { left: 360 } }),
          spacer(),

          heading2("SECTION 6 -- INDEMNIFICATION"),
          multiRun([{ text: "6.01. By Technijian. ", bold: true, color: CHARCOAL }, { text: "Technijian shall indemnify, defend, and hold harmless Client from and against any third-party claims arising from Technijian's gross negligence or willful misconduct in performing the services." }]),
          spacer(),
          multiRun([{ text: "6.02. By Client. ", bold: true, color: CHARCOAL }, { text: "Client shall indemnify, defend, and hold harmless Technijian from and against any third-party claims arising from:" }]),
          p("(a) Client's use of the services in violation of applicable law;", { indent: { left: 360 } }),
          p("(b) Client's breach of this Agreement; or", { indent: { left: 360 } }),
          p("(c) Any data, content, or materials provided by Client.", { indent: { left: 360 } }),
          spacer(),
          multiRun([{ text: "6.03. Procedure. ", bold: true, color: CHARCOAL }, { text: "The indemnified Party shall provide prompt written notice of any claim, cooperate with the indemnifying Party in the defense, and not settle any claim without the indemnifying Party's prior written consent." }]),
          spacer(),

          heading2("SECTION 7 -- INTELLECTUAL PROPERTY"),
          multiRun([{ text: "7.01. Technijian IP. ", bold: true, color: CHARCOAL }, { text: "Technijian retains all right, title, and interest in its proprietary tools, methodologies, software, and processes used in providing the services (\"Technijian IP\"). Client receives no rights to Technijian IP except as expressly set forth in this Agreement." }]),
          spacer(),
          multiRun([{ text: "7.02. Client IP. ", bold: true, color: CHARCOAL }, { text: "Client retains all right, title, and interest in its data, content, and pre-existing intellectual property (\"Client IP\")." }]),
          spacer(),
          multiRun([{ text: "7.03. Custom Development. ", bold: true, color: CHARCOAL }, { text: "Ownership of any custom software or materials developed under a SOW shall be governed by the terms of that SOW. Unless otherwise specified, Technijian shall retain ownership of any general-purpose tools, frameworks, or methodologies developed during the engagement." }]),
          spacer(),

          heading2("SECTION 8 -- DISPUTE RESOLUTION"),
          multiRun([{ text: "8.01. Escalation. ", bold: true, color: CHARCOAL }, { text: "The Parties shall first attempt to resolve any dispute through good faith negotiations between their respective designated representatives for a period of thirty (30) days." }]),
          spacer(),
          multiRun([{ text: "8.02. Mediation. ", bold: true, color: CHARCOAL }, { text: "If the dispute is not resolved through negotiation, the Parties shall submit the dispute to mediation administered by a mutually agreed-upon mediator in Orange County, California, for a period not to exceed sixty (60) days." }]),
          spacer(),
          multiRun([{ text: "8.03. Arbitration. ", bold: true, color: CHARCOAL }, { text: "If mediation fails, any remaining dispute shall be resolved by binding arbitration administered by the American Arbitration Association under its Commercial Arbitration Rules. The arbitration shall take place in Orange County, California, before a single arbitrator." }]),
          spacer(),
          multiRun([{ text: "8.04. Fees. ", bold: true, color: CHARCOAL }, { text: "Each Party shall bear its own costs and attorneys' fees in connection with any dispute, unless the arbitrator determines that one Party's position was frivolous, in which case the arbitrator may award reasonable attorneys' fees to the prevailing Party." }]),
          spacer(),
          multiRun([{ text: "8.05. Injunctive Relief. ", bold: true, color: CHARCOAL }, { text: "Nothing in this Section shall prevent either Party from seeking injunctive or other equitable relief in a court of competent jurisdiction to prevent irreparable harm." }]),
          spacer(),

          heading2("SECTION 9 -- GENERAL PROVISIONS"),
          multiRun([{ text: "9.01. Entire Agreement. ", bold: true, color: CHARCOAL }, { text: "This Agreement, together with its Schedules and any SOWs, constitutes the entire agreement between the Parties and supersedes all prior agreements, whether written or oral, relating to the subject matter hereof." }]),
          spacer(),
          multiRun([{ text: "9.02. Amendment. ", bold: true, color: CHARCOAL }, { text: "This Agreement may only be amended by a written instrument signed by both Parties. Technijian may update its Rate Card (Schedule C) upon sixty (60) days written notice to Client, effective at the start of the next Renewal Term." }]),
          spacer(),
          multiRun([{ text: "9.03. Severability. ", bold: true, color: CHARCOAL }, { text: "If any provision is found to be invalid or unenforceable, the remaining provisions shall continue in full force and effect." }]),
          spacer(),
          multiRun([{ text: "9.04. Waiver. ", bold: true, color: CHARCOAL }, { text: "No waiver of any provision shall be effective unless in writing and signed by the waiving Party. A waiver of any breach shall not constitute a waiver of any subsequent breach." }]),
          spacer(),
          multiRun([{ text: "9.05. Assignment. ", bold: true, color: CHARCOAL }, { text: "Neither Party may assign this Agreement without the prior written consent of the other Party, except that either Party may assign this Agreement in connection with a merger, acquisition, or sale of substantially all of its assets." }]),
          spacer(),
          multiRun([{ text: "9.06. Force Majeure. ", bold: true, color: CHARCOAL }, { text: "Neither Party shall be liable for delays or failures caused by events beyond its reasonable control, including natural disasters, acts of government, labor disputes, pandemics, or failures of third-party services." }]),
          spacer(),
          multiRun([{ text: "9.07. Notices. ", bold: true, color: CHARCOAL }, { text: "All notices shall be in writing and delivered by email with confirmation, certified mail, or nationally recognized overnight courier to the addresses set forth above (or as updated in writing)." }]),
          spacer(),
          multiRun([{ text: "9.08. Governing Law. ", bold: true, color: CHARCOAL }, { text: "This Agreement shall be governed by and construed in accordance with the laws of the State of California without regard to conflict of law principles." }]),
          spacer(),
          multiRun([{ text: "9.09. Non-Solicitation. ", bold: true, color: CHARCOAL }, { text: "During the term of this Agreement and for a period of one (1) year following termination, neither Party shall directly solicit for employment any employee of the other Party who was involved in performing or receiving services under this Agreement, without the other Party's prior written consent." }]),
          spacer(),
          multiRun([{ text: "9.10. Counterparts. ", bold: true, color: CHARCOAL }, { text: "This Agreement may be executed in counterparts, each of which shall be deemed an original." }]),

          ...signatureBlock(),
          spacer(),
          p("Schedules:", { bold: true, color: CHARCOAL }),
          p("Schedule A -- Monthly Managed Services", { numbering: { reference: "bullets", level: 0 } }),
          p("Schedule B -- Subscription and License Services", { numbering: { reference: "bullets", level: 0 } }),
          p("Schedule C -- Rate Card", { numbering: { reference: "bullets", level: 0 } }),
        ]
      }
    ]
  });
  const buffer = await Packer.toBuffer(doc);
  fs.writeFileSync("templates/02-MSA.docx", buffer);
  console.log("Generated: 02-MSA.docx");
}

async function generateScheduleA() {
  const doc = new Document({
    styles: docStyles,
    numbering,
    sections: [
      {
        properties: coverSectionProps(),
        children: coverPage("Schedule A", "Monthly Managed Services")
      },
      {
        properties: contentSectionProps(),
        children: [
          heading1("SCHEDULE A -- MONTHLY MANAGED SERVICES"),
          multiRun([{ text: "Attached to Master Service Agreement ", bold: true, color: CHARCOAL }, { text: "[MSA-XXXX]" }]),
          multiRun([{ text: "Effective Date: ", bold: true, color: CHARCOAL }, { text: "[DATE]" }]),
          spacer(),
          p("This Schedule describes the Monthly Managed Services provided by Technijian, Inc. (\"Technijian\") to [CLIENT NAME] (\"Client\") under the Master Service Agreement."),
          brandRule(),

          heading2("PART 1 -- ONLINE SERVICES"),
          heading3("1.1 Description"),
          p("Online Services include managed infrastructure, security, monitoring, and related IT services delivered on a recurring monthly basis. Services are selected from the Technijian Price List and itemized in the attached Service Order."),
          spacer(),
          heading3("1.2 Service Categories"),
          makeTable(
            ["Category", "Description"],
            [
              ["Cloud Infrastructure", "Virtual machines (vCores, memory, bandwidth), production/replicated/backup storage"],
              ["Server Management", "Patch management, image backup, antivirus, remote access, secure internet, network operations"],
              ["Desktop Management", "Patch management, antivirus, remote access, secure internet, network operations"],
              ["Network & Security", "Firewall appliances (Sophos), SD-WAN (VeloCloud), edge appliances, real-time penetration testing"],
              ["Email & Archiving", "Email archiving, DMARC/DKIM management, site assessments"],
              ["Backup & Recovery", "Veeam 365 backup, replicated and backup storage"],
            ],
            [3000, 6360]
          ),
          spacer(),
          heading3("1.3 Service Order"),
          p("The specific services, quantities, and monthly pricing for Client are detailed in the Service Order attached to this Schedule. The Service Order may be updated by mutual written agreement."),
          spacer(),
          heading3("1.4 Service Levels"),
          makeTable(
            ["Service Level", "Target"],
            [
              ["Infrastructure Uptime", "99.9% monthly (excluding scheduled maintenance)"],
              ["Scheduled Maintenance", "Tuesday evenings and Saturdays (with advance notice)"],
              ["Critical Incident Response", "Within 1 hour of notification"],
              ["Standard Support Response", "Within 4 business hours"],
              ["Emergency Maintenance", "As needed with reasonable notice"],
            ],
            [3500, 5860]
          ),
          spacer(),
          heading3("1.5 Monitoring and Reporting"),
          p("Technijian shall provide:"),
          p("(a) 24/7 monitoring of Client's infrastructure included in the Service Order;", { indent: { left: 360 } }),
          p("(b) Monthly service reports summarizing uptime, incidents, and support activity; and", { indent: { left: 360 } }),
          p("(c) Quarterly service reviews with Client's designated representative.", { indent: { left: 360 } }),
          spacer(),
          new Paragraph({ children: [new PageBreak()] }),

          heading2("PART 2 -- SIP TRUNK SERVICES"),
          heading3("2.1 Description"),
          p("SIP Trunk Services include voice-over-IP telephony, SIP trunking, and related telecommunications services."),
          spacer(),
          heading3("2.2 Service Components"),
          makeTable(
            ["Component", "Description"],
            [
              ["SIP Trunk", "Primary voice connectivity with failover"],
              ["Voice Package", "Bundled calling plans (domestic, long distance)"],
              ["DID Numbers", "Direct inward dialing numbers"],
              ["E911", "Emergency services routing"],
            ],
            [3000, 6360]
          ),
          spacer(),
          heading3("2.3 Service Levels"),
          makeTable(
            ["Service Level", "Target"],
            [
              ["Voice Uptime", "99.9% monthly"],
              ["Call Quality (MOS)", "4.0 or higher"],
              ["Number Porting", "Completed within 10 business days of request"],
            ],
            [3500, 5860]
          ),
          spacer(),
          new Paragraph({ children: [new PageBreak()] }),

          heading2("PART 3 -- VIRTUAL STAFF (CONTRACTED SUPPORT)"),
          heading3("3.1 Description"),
          p("Virtual Staff services provide Client with dedicated technology support personnel on a contracted basis. This service operates on a cycle-based billing model as described below."),
          spacer(),
          heading3("3.2 Support Roles"),
          p("Client may select from the following standard support roles:"),
          spacer(),
          makeTable(
            ["Role", "Location", "Hours", "Rate"],
            [
              ["CTO Advisory", "United States", "Normal Business Hours", "Per Rate Card"],
              ["Developer", "United States", "Normal Business Hours", "Per Rate Card"],
              ["Tech Support", "United States", "Normal Business Hours", "Per Rate Card"],
              ["Developer", "India (Night Shift)", "US Business Hours", "Per Rate Card"],
              ["Tech Support", "India (Night Shift)", "US Business Hours", "Per Rate Card"],
              ["Tech Support", "India (Day Shift / After-Hours)", "US After-Hours", "Per Rate Card"],
            ],
            [2200, 2200, 2500, 2460]
          ),
          spacer(),
          p("Naming Convention:", { bold: true, color: CHARCOAL }),
          p("\"India -- Night\" refers to India-based staff working during US business hours (nighttime in India).", { numbering: { reference: "bullets", level: 0 } }),
          p("\"India -- Day\" refers to India-based staff working during US after-hours (daytime in India).", { numbering: { reference: "bullets", level: 0 } }),
          spacer(),
          heading3("3.3 Cycle-Based Billing Model"),
          multiRun([{ text: "(a) Billing Cycle. ", bold: true, color: CHARCOAL }, { text: "Client selects a billing cycle of 3, 6, or 12 months (the \"Cycle\"). The Cycle is used to calculate the monthly billed amount and track actual usage." }]),
          spacer(),
          multiRun([{ text: "(b) Monthly Billed Amount Calculation. ", bold: true, color: CHARCOAL }, { text: "The fixed monthly billing rate for each role is calculated as follows:" }]),
          p("1. At the start of each new Cycle, Technijian calculates the average monthly hours consumed per role during the previous Cycle, excluding the final month of that Cycle.", { indent: { left: 720 } }),
          p("2. This average becomes the monthly billed hours for each role during the current Cycle.", { indent: { left: 720 } }),
          p("3. The monthly billed amount for each role equals the monthly billed hours multiplied by the applicable hourly rate from the Rate Card (Schedule C).", { indent: { left: 720 } }),
          spacer(),
          multiRun([{ text: "(c) Running Balance. ", bold: true, color: CHARCOAL }, { text: "Technijian maintains a running balance for each role, calculated as follows:" }]),
          p("1. At the start of each month, the running balance is adjusted by adding the actual hours used during the previous month and subtracting the monthly billed hours for that month.", { indent: { left: 720 } }),
          p("2. A positive running balance indicates hours consumed in excess of billed amounts (Client owes additional hours).", { indent: { left: 720 } }),
          p("3. A negative running balance indicates hours billed in excess of consumption (Client has a credit).", { indent: { left: 720 } }),
          spacer(),
          multiRun([{ text: "(d) Cycle Reconciliation. ", bold: true, color: CHARCOAL }, { text: "At the end of each Cycle:" }]),
          p("1. The running balance for each role is reconciled.", { indent: { left: 720 } }),
          p("2. Any net positive balance (hours consumed but not yet paid) is invoiced at the applicable hourly rate.", { indent: { left: 720 } }),
          p("3. Any net negative balance (hours paid but not consumed) carries forward to the next Cycle as a credit.", { indent: { left: 720 } }),
          spacer(),
          multiRun([{ text: "(e) Cancellation. ", bold: true, color: CHARCOAL }, { text: "If Client terminates Virtual Staff services or this Agreement:" }]),
          p("1. Any positive running balance (actual hours exceeding billed hours) shall become immediately due and payable.", { indent: { left: 720 } }),
          p("2. Any negative running balance (billed hours exceeding actual hours) will be credited to Client's final invoice, subject to a maximum credit of one month's billed amount per role.", { indent: { left: 720 } }),
          spacer(),
          heading3("3.4 Weekly Service Reports"),
          p("Technijian shall provide Client with weekly service invoices that detail:"),
          p("(a) Each support ticket addressed during the period;", { indent: { left: 360 } }),
          p("(b) The role, resource name, and hours spent per ticket;", { indent: { left: 360 } }),
          p("(c) Whether the work was performed during normal or after-hours;", { indent: { left: 360 } }),
          p("(d) A description of the work performed; and", { indent: { left: 360 } }),
          p("(e) The current running balance for each role.", { indent: { left: 360 } }),
          spacer(),
          heading3("3.5 New Client Onboarding"),
          p("For new Clients without a previous Cycle history, the initial Cycle billing shall be based on:"),
          p("(a) A mutually agreed-upon estimated monthly hours per role, documented in the Service Order; and", { indent: { left: 360 } }),
          p("(b) Actual usage tracking beginning immediately, with the first Cycle reconciliation occurring at the end of the initial Cycle period.", { indent: { left: 360 } }),
          spacer(),
          brandRule(),
          heading2("GENERAL TERMS FOR THIS SCHEDULE"),
          heading3("Changes to Services"),
          p("Either Party may request changes to the services described in this Schedule by providing thirty (30) days written notice. Changes to quantities, roles, or service levels shall be documented in an updated Service Order signed by both Parties."),
          spacer(),
          heading3("Pricing Adjustments"),
          p("Pricing for services under this Schedule is subject to the Rate Card (Schedule C). Technijian may adjust rates upon sixty (60) days written notice, effective at the start of the next Renewal Term of the Agreement."),
          ...signatureBlock()
        ]
      }
    ]
  });
  const buffer = await Packer.toBuffer(doc);
  fs.writeFileSync("templates/03-Schedule-A-Monthly-Services.docx", buffer);
  console.log("Generated: 03-Schedule-A-Monthly-Services.docx");
}

async function generateScheduleB() {
  const doc = new Document({
    styles: docStyles,
    numbering,
    sections: [
      {
        properties: coverSectionProps(),
        children: coverPage("Schedule B", "Subscription and License Services")
      },
      {
        properties: contentSectionProps(),
        children: [
          heading1("SCHEDULE B -- SUBSCRIPTION AND LICENSE SERVICES"),
          multiRun([{ text: "Attached to Master Service Agreement ", bold: true, color: CHARCOAL }, { text: "[MSA-XXXX]" }]),
          multiRun([{ text: "Effective Date: ", bold: true, color: CHARCOAL }, { text: "[DATE]" }]),
          spacer(),
          p("This Schedule describes the Subscription and License Services provided by Technijian, Inc. (\"Technijian\") to [CLIENT NAME] (\"Client\") under the Master Service Agreement."),
          brandRule(),

          heading2("1. DESCRIPTION"),
          p("Technijian procures, manages, and maintains third-party software subscriptions, licenses, SSL certificates, domain registrations, and related services on Client's behalf (\"Subscription Services\"). These services are separate from the Monthly Managed Services described in Schedule A."),
          spacer(),

          heading2("2. SERVICE CATEGORIES"),
          heading3("2.1 Software Subscriptions"),
          makeTable(["Category", "Examples"],
            [
              ["Productivity", "Microsoft 365 Business Basic, Business Standard, E3/E5"],
              ["Security", "Microsoft Entra ID, Defender, Intune"],
              ["Analytics", "Power BI Pro, Power BI Premium"],
              ["Collaboration", "Microsoft Visio, Project, Copilot"],
              ["Database", "Microsoft SQL Server licenses (SAL, CAL)"],
              ["Server", "Microsoft Server Standard, RDP/User CALs"],
              ["Specialty", "FoxIT PDF, Adobe Creative Cloud, other LOB applications"],
            ], [3000, 6360]),
          spacer(),
          heading3("2.2 SSL Certificates"),
          makeTable(["Type", "Description"],
            [
              ["Standard SSL", "Single-domain SSL certificate (1-year term)"],
              ["UCC / Multi-Domain SSL", "Unified Communications Certificate covering multiple domains"],
              ["Wildcard SSL", "SSL certificate covering all subdomains of a domain"],
            ], [3000, 6360]),
          spacer(),
          heading3("2.3 Domain Registrations"),
          makeTable(["Service", "Description"],
            [
              ["Domain Registration", "New domain registration or annual renewal"],
              ["DNS Management", "DNS hosting and record management"],
            ], [3000, 6360]),
          spacer(),

          heading2("3. PROCUREMENT AND MANAGEMENT"),
          multiRun([{ text: "3.01. Procurement. ", bold: true, color: CHARCOAL }, { text: "Technijian shall procure Subscription Services from authorized vendors and resellers on Client's behalf. Client authorizes Technijian to act as its agent for purposes of procuring and managing these subscriptions." }]),
          spacer(),
          multiRun([{ text: "3.02. License Management. ", bold: true, color: CHARCOAL }, { text: "Technijian shall:" }]),
          p("(a) Maintain an inventory of all active subscriptions and licenses;", { indent: { left: 360 } }),
          p("(b) Monitor subscription terms, renewal dates, and expiration dates;", { indent: { left: 360 } }),
          p("(c) Notify Client at least thirty (30) days prior to any annual renewal; and", { indent: { left: 360 } }),
          p("(d) Process additions, removals, and changes to subscriptions upon Client's written request.", { indent: { left: 360 } }),
          spacer(),
          multiRun([{ text: "3.03. Vendor Terms. ", bold: true, color: CHARCOAL }, { text: "Subscription Services are subject to the applicable vendor's terms and conditions (e.g., Microsoft Product Terms). Client acknowledges that Technijian is a reseller and that certain terms are passed through from the vendor. Technijian shall make applicable vendor terms available to Client upon request." }]),
          spacer(),

          heading2("4. PRICING"),
          multiRun([{ text: "4.01. Subscription Fees. ", bold: true, color: CHARCOAL }, { text: "Client shall pay the fees for Subscription Services as set forth in the Subscription Order attached to this Schedule. Fees include Technijian's management and procurement services." }]),
          spacer(),
          multiRun([{ text: "4.02. Billing Frequency. ", bold: true, color: CHARCOAL }, { text: "Subscriptions are billed as follows:" }]),
          spacer(),
          makeTable(["Billing Frequency", "Applicable To"],
            [
              ["Monthly", "Software subscriptions billed on a per-user, per-month basis"],
              ["Annually", "SSL certificates, domain registrations, and annual licenses"],
            ], [3000, 6360]),
          spacer(),
          multiRun([{ text: "4.03. Pass-Through Costs. ", bold: true, color: CHARCOAL }, { text: "If a vendor increases its pricing, Technijian may adjust the corresponding Subscription Service fee upon thirty (30) days written notice to Client." }]),
          spacer(),

          heading2("5. CHANGES TO SUBSCRIPTIONS"),
          multiRun([{ text: "5.01. Additions. ", bold: true, color: CHARCOAL }, { text: "Client may request additional licenses or subscriptions at any time. New subscriptions shall be added at the then-current pricing and prorated for the remaining billing period." }]),
          spacer(),
          multiRun([{ text: "5.02. Removals. ", bold: true, color: CHARCOAL }, { text: "Client may request removal of subscriptions upon thirty (30) days written notice. Client acknowledges that:" }]),
          p("(a) Some subscriptions have minimum commitment terms imposed by the vendor;", { indent: { left: 360 } }),
          p("(b) Removal of subscriptions mid-term may not result in a refund if the vendor does not provide one; and", { indent: { left: 360 } }),
          p("(c) Client is responsible for fees through the end of the applicable subscription term.", { indent: { left: 360 } }),
          spacer(),
          multiRun([{ text: "5.03. Annual Renewals. ", bold: true, color: CHARCOAL }, { text: "Unless Client provides written notice of non-renewal at least thirty (30) days prior to the renewal date, annual subscriptions shall automatically renew for successive one-year terms." }]),
          spacer(),

          heading2("6. DATA AND ACCESS"),
          multiRun([{ text: "6.01. Account Ownership. ", bold: true, color: CHARCOAL }, { text: "Client retains ownership of all accounts and data associated with Subscription Services. Upon termination, Technijian shall transfer administrative access to Client or Client's designated representative within thirty (30) days." }]),
          spacer(),
          multiRun([{ text: "6.02. Credentials. ", bold: true, color: CHARCOAL }, { text: "Client is responsible for maintaining the security of login credentials associated with Subscription Services." }]),

          ...signatureBlock()
        ]
      }
    ]
  });
  const buffer = await Packer.toBuffer(doc);
  fs.writeFileSync("templates/04-Schedule-B-Subscription-Services.docx", buffer);
  console.log("Generated: 04-Schedule-B-Subscription-Services.docx");
}

async function generateScheduleC() {
  const w = [2500, 1700, 1700, 3460];
  const w3 = [3000, 1500, 4860];
  const doc = new Document({
    styles: docStyles,
    numbering,
    sections: [
      {
        properties: coverSectionProps(),
        children: coverPage("Schedule C", "Rate Card")
      },
      {
        properties: contentSectionProps(),
        children: [
          heading1("SCHEDULE C -- RATE CARD"),
          multiRun([{ text: "Attached to Master Service Agreement ", bold: true, color: CHARCOAL }, { text: "[MSA-XXXX]" }]),
          multiRun([{ text: "Effective Date: ", bold: true, color: CHARCOAL }, { text: "[DATE]" }]),
          brandRule(),

          heading2("1. VIRTUAL STAFF RATES"),
          heading3("1.1 United States -- Based Staff"),
          makeTable(["Role", "Normal Hours", "After-Hours", "Description"],
            [
              ["CTO Advisory", "$[___]/hr", "$[___]/hr", "Strategic technology leadership and advisory"],
              ["Developer", "$[___]/hr", "$[___]/hr", "Software development and engineering"],
              ["Tech Support", "$[___]/hr", "$[___]/hr", "Technical support and systems administration"],
            ], w),
          spacer(),
          heading3("1.2 India -- Based Staff"),
          makeTable(["Role", "India Night (US Biz)", "India Day (US AH)", "Description"],
            [
              ["Developer", "$[___]/hr", "$[___]/hr", "Software development and engineering"],
              ["Tech Support", "$[___]/hr", "$[___]/hr", "Technical support and systems administration"],
            ], w),
          spacer(),
          p("Normal Business Hours: Monday through Friday, 8:00 AM to 6:00 PM Pacific Time, excluding US federal holidays.", { italics: true, size: 20 }),
          p("After-Hours: All hours outside of Normal Business Hours, including weekends and US federal holidays.", { italics: true, size: 20 }),
          spacer(),

          heading2("2. PROJECT RATES"),
          makeTable(["Service", "Rate", "Notes"],
            [
              ["On-Site Support (US)", "$[___]/hr", "Minimum 2-hour engagement"],
              ["Remote Support (ad hoc)", "$[___]/hr", "Billed in 15-minute increments"],
              ["Emergency / Critical Response", "$[___]/hr", "Minimum 1-hour engagement"],
              ["Project Management", "$[___]/hr", "For SOW-based engagements"],
            ], w3),
          spacer(),

          heading2("3. ONLINE SERVICES -- INFRASTRUCTURE"),
          heading3("3.1 Cloud Infrastructure"),
          makeTable(["Service", "Unit", "Monthly Rate"],
            [["Cloud VM -- vCore", "Per vCore", "$[___]"], ["Cloud VM -- Memory", "Per GB", "$[___]"], ["Cloud VM -- Shared Bandwidth", "Per connection", "$[___]"], ["Production Storage", "Per TB", "$[___]"], ["Replicated Storage", "Per TB", "$[___]"], ["Backup Storage", "Per TB", "$[___]"]], w3),
          spacer(),
          heading3("3.2 Server Management"),
          makeTable(["Service", "Unit", "Monthly Rate"],
            [["Patch Management", "Per server", "$[___]"], ["Image Backup", "Per server", "$[___]"], ["AV Protection -- Server", "Per server", "$[___]"], ["AVH Protection -- Server", "Per server", "$[___]"], ["My Secure Internet", "Per server", "$[___]"], ["My Remote", "Per server", "$[___]"], ["My Ops -- Net", "Per server", "$[___]"]], w3),
          spacer(),
          heading3("3.3 Desktop Management"),
          makeTable(["Service", "Unit", "Monthly Rate"],
            [["Patch Management", "Per desktop", "$[___]"], ["AV Protection -- Desktop", "Per desktop", "$[___]"], ["AVH Protection -- Desktop", "Per desktop", "$[___]"], ["My Secure Internet", "Per desktop", "$[___]"], ["My Remote", "Per desktop", "$[___]"], ["My Ops -- Net", "Per desktop", "$[___]"]], w3),
          spacer(),
          heading3("3.4 Network and Security"),
          makeTable(["Service", "Unit", "Monthly Rate"],
            [["VeloCloud SD-WAN (50M)", "Per appliance", "$[___]"], ["Sophos Firewall (2C-4G)", "Per appliance", "$[___]"], ["Sophos Firewall (1C-4G)", "Per appliance", "$[___]"], ["Edge Appliance (16GB)", "Per appliance", "$[___]"], ["Real-Time Penetration Testing", "Per IP", "$[___]"]], w3),
          spacer(),
          heading3("3.5 Email and Compliance"),
          makeTable(["Service", "Unit", "Monthly Rate"],
            [["Email Archiving", "Per user", "$[___]"], ["DMARC/DKIM Management", "Per domain", "$[___]"], ["Site Assessment", "Per domain", "$[___]"], ["Veeam 365 Backup", "Per user", "$[___]"]], w3),
          spacer(),

          heading2("4. SIP TRUNK SERVICES"),
          makeTable(["Service", "Unit", "Monthly Rate"],
            [["SIP Trunk", "Per trunk", "$[___]"], ["Voice Package", "Per package", "$[___]"], ["DID Number", "Per number", "$[___]"]], w3),
          spacer(),

          heading2("5. TERMS"),
          multiRun([{ text: "5.01. Rate Adjustments. ", bold: true, color: CHARCOAL }, { text: "Technijian may adjust the rates in this Schedule upon sixty (60) days written notice to Client. Adjusted rates shall take effect at the start of the next Renewal Term of the Agreement." }]),
          spacer(),
          multiRun([{ text: "5.02. Volume Discounts. ", bold: true, color: CHARCOAL }, { text: "Volume-based pricing may be negotiated and documented in the applicable Service Order or Subscription Order." }]),
          spacer(),
          multiRun([{ text: "5.03. Minimum Billing. ", bold: true, color: CHARCOAL }, { text: "Unless otherwise specified, contracted Virtual Staff hours are billed per the Cycle-Based Billing Model described in Schedule A, Part 3. Ad hoc (non-contracted) support is billed in 15-minute increments with a minimum engagement as specified above." }]),

          ...signatureBlock()
        ]
      }
    ]
  });
  const buffer = await Packer.toBuffer(doc);
  fs.writeFileSync("templates/05-Schedule-C-Rate-Card.docx", buffer);
  console.log("Generated: 05-Schedule-C-Rate-Card.docx");
}

async function generateSOW() {
  const doc = new Document({
    styles: docStyles,
    numbering,
    sections: [
      {
        properties: coverSectionProps(),
        children: coverPage("Statement of Work", "Project Services")
      },
      {
        properties: contentSectionProps(),
        children: [
          heading1("STATEMENT OF WORK"),
          multiRun([{ text: "SOW Number: ", bold: true, color: CHARCOAL }, { text: "[SOW-XXXX]" }]),
          multiRun([{ text: "Effective Date: ", bold: true, color: CHARCOAL }, { text: "[DATE]" }]),
          multiRun([{ text: "Master Service Agreement: ", bold: true, color: CHARCOAL }, { text: "[MSA-XXXX] (if applicable)" }]),
          spacer(),
          p("This Statement of Work (\"SOW\") is entered into by and between:"),
          spacer(),
          p("Technijian, Inc. (\"Technijian\")", { bold: true, color: CHARCOAL }),
          p("18 Technology Drive, Suite 141"),
          p("Irvine, California 92618"),
          spacer(),
          p("and"),
          spacer(),
          p("[CLIENT NAME] (\"Client\")", { bold: true, color: CHARCOAL }),
          p("[CLIENT ADDRESS]"),
          p("[CITY, STATE ZIP]"),
          brandRule(),

          heading2("1. PROJECT OVERVIEW"),
          heading3("1.1 Project Title"),
          p("[PROJECT TITLE]"),
          spacer(),
          heading3("1.2 Project Description"),
          p("[Brief description of the project, including the business need and desired outcome.]"),
          spacer(),
          heading3("1.3 Locations"),
          makeTable(["Location Name", "Code", "Address", "Billable"],
            [["[Location 1]", "[CODE]", "[ADDRESS]", "Yes/No"]], [2500, 1200, 4360, 1300]),
          spacer(),

          heading2("2. SCOPE OF WORK"),
          heading3("2.1 In Scope"),
          p("[Describe what is included in this SOW.]"),
          p("[Deliverable/task 1]", { numbering: { reference: "bullets", level: 0 } }),
          p("[Deliverable/task 2]", { numbering: { reference: "bullets", level: 0 } }),
          p("[Deliverable/task 3]", { numbering: { reference: "bullets", level: 0 } }),
          spacer(),
          heading3("2.2 Out of Scope"),
          p("The following items are expressly excluded from this SOW:"),
          p("[Exclusion 1]", { numbering: { reference: "bullets", level: 0 } }),
          p("[Exclusion 2]", { numbering: { reference: "bullets", level: 0 } }),
          spacer(),
          heading3("2.3 Assumptions"),
          p("[Assumption 1]", { numbering: { reference: "bullets", level: 0 } }),
          p("[Assumption 2]", { numbering: { reference: "bullets", level: 0 } }),
          spacer(),

          heading2("3. PROJECT PHASES"),
          heading3("Phase 1: [PHASE NAME]"),
          p("3.1.1 Description", { bold: true, color: CHARCOAL }),
          p("[Description of the phase objectives and activities.]"),
          spacer(),
          p("3.1.2 Deliverables", { bold: true, color: CHARCOAL }),
          p("[Deliverable 1]", { numbering: { reference: "bullets", level: 0 } }),
          p("[Deliverable 2]", { numbering: { reference: "bullets", level: 0 } }),
          spacer(),
          p("3.1.3 Schedule", { bold: true, color: CHARCOAL }),
          makeTable(["Role", "Description", "Est. Hours", "Timeline", "Resource"],
            [["[Role]", "[Task description]", "[Hours]", "[Day/Week]", "[TBD]"], ["", "Total", "[Hours]", "", ""]], [1500, 3360, 1500, 1500, 1500]),
          spacer(),
          new Paragraph({ children: [new PageBreak()] }),

          heading2("4. EQUIPMENT AND MATERIALS"),
          p("Complete this section if the SOW includes hardware or equipment procurement.", { italics: true, size: 20 }),
          spacer(),
          makeTable(["Item", "Description", "Qty", "Unit Price", "Sub-Total"],
            [["[Item]", "[Description/specs]", "[Qty]", "$[___]", "$[___]"], ["", "", "", "Sub-Total:", "$[___]"], ["", "", "", "Sales Tax:", "$[___]"], ["", "", "", "Equipment Total:", "$[___]"]], [1700, 3460, 900, 1650, 1650]),
          spacer(),
          heading3("4.1 Title and Ownership"),
          p("Title to equipment shall remain vested in Technijian until paid for in full. Upon receipt of full payment, title shall transfer to Client."),
          spacer(),
          heading3("4.2 Warranty"),
          p("Equipment warranty is provided by the manufacturer per the manufacturer's warranty terms. Technijian shall assist Client in processing any warranty claims during the warranty period."),
          spacer(),
          heading3("4.3 Financing"),
          p("If Client elects to finance equipment through a third-party financing provider, Technijian's obligation is fulfilled upon receipt of payment from the financing provider. Client's financing obligations are between Client and the financing provider."),
          spacer(),

          heading2("5. PRICING AND PAYMENT"),
          heading3("5.1 Summary of Costs"),
          makeTable(["Phase", "Type", "Est. Hours", "Cost"],
            [["[Phase 1]", "[Fixed/Estimate]", "[Hours]", "$[___]"], ["[Phase 2]", "[Fixed/Estimate]", "[Hours]", "$[___]"], ["Equipment", "", "", "$[___]"], ["Total", "", "", "$[___]"]], [2500, 2200, 2200, 2460]),
          spacer(),
          p("Pricing Type Definitions:", { bold: true, color: CHARCOAL }),
          p("Fixed Cost: Technijian will complete the work at the stated price regardless of actual hours.", { numbering: { reference: "bullets", level: 0 } }),
          p("Estimate Cost: The stated hours and cost are estimates. Technijian will bill for actual time at the applicable rate. If actual hours are projected to exceed the estimate by more than 10%, Technijian will notify Client before proceeding.", { numbering: { reference: "bullets", level: 0 } }),
          spacer(),
          heading3("5.2 Payment Schedule"),
          makeTable(["Milestone", "Invoiced", "Amount"],
            [["[e.g., Before Phase 1 begins]", "[Timing]", "$[___]"], ["[e.g., After Phase 2 completion]", "[Timing]", "$[___]"], ["Total", "", "$[___]"]], [3800, 2800, 2760]),
          spacer(),
          heading3("5.3 Payment Terms"),
          p("All invoices are due and payable within thirty (30) days of the invoice date. Late payments are subject to the terms of the Master Service Agreement, or if no MSA is in effect, a late fee of 1.5% per month on the unpaid balance."),
          spacer(),

          heading2("6. CLIENT RESPONSIBILITIES"),
          p("Client shall:"),
          p("(a) Provide access to systems, facilities, and personnel as reasonably required;", { indent: { left: 360 } }),
          p("(b) Designate a point of contact authorized to make decisions on behalf of Client;", { indent: { left: 360 } }),
          p("(c) Review and approve deliverables within five (5) business days of submission;", { indent: { left: 360 } }),
          p("(d) Ensure all relevant data is backed up prior to the start of work; and", { indent: { left: 360 } }),
          p("(e) Inform users of planned service changes, maintenance windows, and downtime.", { indent: { left: 360 } }),
          spacer(),

          heading2("7. CHANGE MANAGEMENT"),
          multiRun([{ text: "7.01. ", bold: true, color: CHARCOAL }, { text: "Any changes to the scope, schedule, or pricing of this SOW must be documented in a written Change Order signed by both Parties before work on the change begins." }]),
          spacer(),
          multiRun([{ text: "7.02. ", bold: true, color: CHARCOAL }, { text: "If Client requests work outside the defined scope, Technijian shall provide a Change Order detailing the additional work, estimated hours, and cost impact." }]),
          spacer(),
          multiRun([{ text: "7.03. ", bold: true, color: CHARCOAL }, { text: "Technijian shall not proceed with out-of-scope work without an approved Change Order, except in cases where delay would result in harm to Client's systems, in which case Technijian shall notify Client as soon as practicable." }]),
          spacer(),

          heading2("8. ACCEPTANCE"),
          multiRun([{ text: "8.01. ", bold: true, color: CHARCOAL }, { text: "Upon completion of each phase, Technijian shall notify Client in writing that the deliverables are ready for review." }]),
          spacer(),
          multiRun([{ text: "8.02. ", bold: true, color: CHARCOAL }, { text: "Client shall review the deliverables and provide written acceptance or a detailed description of deficiencies within five (5) business days." }]),
          spacer(),
          multiRun([{ text: "8.03. ", bold: true, color: CHARCOAL }, { text: "If Client does not respond within the review period, the deliverables shall be deemed accepted." }]),
          spacer(),
          multiRun([{ text: "8.04. ", bold: true, color: CHARCOAL }, { text: "If deficiencies are identified, Technijian shall correct them and resubmit for review. This process shall repeat until acceptance is achieved or the Parties agree on a resolution." }]),
          spacer(),

          heading2("9. GOVERNING TERMS"),
          multiRun([{ text: "9.01. ", bold: true, color: CHARCOAL }, { text: "If a Master Service Agreement is in effect between the Parties, the terms of the MSA shall govern this SOW. In the event of a conflict between this SOW and the MSA, the MSA shall prevail unless this SOW expressly states otherwise." }]),
          spacer(),
          multiRun([{ text: "9.02. ", bold: true, color: CHARCOAL }, { text: "If no MSA is in effect, the Technijian Standard Terms and Conditions (attached as Appendix A) shall govern this SOW." }]),

          ...signatureBlock()
        ]
      }
    ]
  });
  const buffer = await Packer.toBuffer(doc);
  fs.writeFileSync("templates/06-SOW-Template.docx", buffer);
  console.log("Generated: 06-SOW-Template.docx");
}

// Run all
async function main() {
  try {
    await generateNDA();
    await generateMSA();
    await generateScheduleA();
    await generateScheduleB();
    await generateScheduleC();
    await generateSOW();
    console.log("\nAll documents generated with Technijian branding!");
  } catch (err) {
    console.error("Error:", err.message);
    console.error(err.stack);
  }
}

main();
