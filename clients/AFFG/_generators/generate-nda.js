const fs = require("fs");
const path = require("path");
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  Header, Footer, AlignmentType, LevelFormat,
  HeadingLevel, BorderStyle, WidthType, ShadingType,
  PageNumber, PageBreak, ImageRun
} = require("docx");

// Brand
const BLUE = "006DB6";
const ORANGE = "F67D4B";
const GREY = "59595B";
const CHARCOAL = "1A1A2E";
const OFF_WHITE = "F8F9FA";
const WHITE = "FFFFFF";
const FONT = "Open Sans";

// Logo
let logoBuffer = null;
try { logoBuffer = fs.readFileSync(path.join(__dirname, "..", "..", "..", "templates", "logo.jpg")); } catch(e) {}

function p(text, opts = {}) {
  const runOpts = { font: FONT, size: opts.size || 22, color: opts.color || GREY, text };
  if (opts.bold) runOpts.bold = true;
  if (opts.italics) runOpts.italics = true;
  const pOpts = { children: [new TextRun(runOpts)] };
  if (opts.heading) pOpts.heading = opts.heading;
  if (opts.alignment) pOpts.alignment = opts.alignment;
  if (opts.spacing) pOpts.spacing = opts.spacing;
  if (opts.indent) pOpts.indent = opts.indent;
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
  return new Paragraph(pOpts);
}

function heading1(t) { return p(t, { heading: HeadingLevel.HEADING_1 }); }
function heading2(t) { return p(t, { heading: HeadingLevel.HEADING_2 }); }
function spacer() { return p("", { spacing: { after: 120 } }); }
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

async function main() {
  const doc = new Document({
    styles: docStyles,
    sections: [
      // Cover page
      {
        properties: { page: { size: { width: 12240, height: 15840 }, margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 } } },
        children: [
          p("", { spacing: { before: 2400 } }),
          ...(logoBuffer ? [new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 200 }, children: [new ImageRun({ type: "jpg", data: logoBuffer, transformation: { width: 250, height: 63 }, altText: { title: "Technijian Logo", description: "Technijian Inc.", name: "logo" } })] })] : [p("TECHNIJIAN", { size: 72, bold: true, color: BLUE, alignment: AlignmentType.CENTER })]),
          p("", { spacing: { after: 600 } }),
          orangeRule(),
          p("Non-Disclosure Agreement", { size: 48, bold: true, color: CHARCOAL, alignment: AlignmentType.CENTER, spacing: { before: 400, after: 200 } }),
          p("American Fundstars Financial Group LLC", { size: 28, bold: true, color: BLUE, alignment: AlignmentType.CENTER, spacing: { after: 100 } }),
          p("March 9, 2026", { size: 24, color: GREY, alignment: AlignmentType.CENTER, spacing: { after: 400 } }),
          orangeRule(),
          p("", { spacing: { after: 1200 } }),
          p("Technijian, Inc.", { size: 22, bold: true, color: CHARCOAL, alignment: AlignmentType.CENTER }),
          p("18 Technology Dr., Ste 141  |  Irvine, CA 92618  |  949.379.8499", { size: 20, color: GREY, alignment: AlignmentType.CENTER }),
          new Paragraph({ children: [new PageBreak()] })
        ]
      },
      // Content
      {
        properties: {
          page: { size: { width: 12240, height: 15840 }, margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 } },
          headers: { default: makeHeader() },
          footers: { default: makeFooter() }
        },
        children: [
          heading1("NON-DISCLOSURE AGREEMENT"),
          multiRun([{ text: "Effective Date: ", bold: true, color: CHARCOAL }, { text: "March 9, 2026" }]),
          spacer(),
          p("This Non-Disclosure Agreement (\"Agreement\") is entered into by and between:"),
          spacer(),
          p("Technijian, Inc. (\"Disclosing Party\")", { bold: true, color: CHARCOAL }),
          p("18 Technology Drive, Suite 141"),
          p("Irvine, California 92618"),
          spacer(),
          p("and"),
          spacer(),
          p("American Fundstars Financial Group LLC (\"Receiving Party\")", { bold: true, color: CHARCOAL }),
          p("1 Park Plaza, Suite 210"),
          p("Irvine, California 92618"),
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

          // Signatures
          brandRule(),
          heading2("SIGNATURES"),
          spacer(),
          p("TECHNIJIAN, INC.", { bold: true, color: CHARCOAL }),
          spacer(),
          p("By: ___________________________________", { color: GREY }),
          spacer(),
          p("Name: Ravi Jain", { color: GREY }),
          spacer(),
          p("Title: CEO", { color: GREY }),
          spacer(),
          p("Email: rjain@technijian.com", { color: GREY }),
          spacer(),
          p("Date: _________________________________", { color: GREY }),
          spacer(),
          spacer(),
          p("AMERICAN FUNDSTARS FINANCIAL GROUP LLC", { bold: true, color: CHARCOAL }),
          spacer(),
          p("By: ___________________________________", { color: GREY }),
          spacer(),
          p("Name: Iris Liu", { color: GREY }),
          spacer(),
          p("Title: _________________________________", { color: GREY }),
          spacer(),
          p("Email: iris.liu@americanfundstars.com", { color: GREY }),
          spacer(),
          p("Date: _________________________________", { color: GREY }),
        ]
      }
    ]
  });

  const buffer = await Packer.toBuffer(doc);
  fs.writeFileSync(path.join(__dirname, "..", "01_NDA", "NDA-AFFG.docx"), buffer);
  console.log("Generated: clients/AFFG/NDA-AFFG.docx");
}

main().catch(e => { console.error(e.message); console.error(e.stack); });
