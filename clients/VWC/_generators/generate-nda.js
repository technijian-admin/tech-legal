const fs = require("fs");
const path = require("path");
const {
  Document, Packer, Paragraph, TextRun, Header, Footer,
  AlignmentType, LevelFormat, HeadingLevel, BorderStyle,
  PageNumber, PageBreak, ImageRun
} = require("docx");

// ===== TECHNIJIAN BRAND COLORS =====
const BLUE = "006DB6";
const ORANGE = "F67D4B";
const GREY = "59595B";
const CHARCOAL = "1A1A2E";
const WHITE = "FFFFFF";
const FONT = "Open Sans";

let logoBuffer = null;
const logoPath = path.join(__dirname, "../../../templates/logo.jpg");
try { logoBuffer = fs.readFileSync(logoPath); } catch (e) {}

const docStyles = {
  default: { document: { run: { font: FONT, size: 22, color: GREY } } },
  paragraphStyles: [
    { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
      run: { size: 32, bold: true, font: FONT, color: BLUE },
      paragraph: { spacing: { before: 320, after: 200 }, outlineLevel: 0 } },
    { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
      run: { size: 26, bold: true, font: FONT, color: CHARCOAL },
      paragraph: { spacing: { before: 240, after: 140 }, outlineLevel: 1 } }
  ]
};

const numbering = {
  config: ["bullets","bullets2","bullets3"].map(ref => ({
    reference: ref,
    levels: [{
      level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT,
      style: { paragraph: { indent: { left: 720, hanging: 360 } } }
    }]
  }))
};

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
    const runOpts = { font: FONT, size: r.size || 22, color: r.color || GREY, text: r.text };
    if (r.bold) runOpts.bold = true;
    if (r.italics) runOpts.italics = true;
    return new TextRun(runOpts);
  });
  const pOpts = { children };
  if (opts.indent) pOpts.indent = opts.indent;
  if (opts.spacing) pOpts.spacing = opts.spacing;
  return new Paragraph(pOpts);
}

function anchorLine(visibleText, anchorTag, opts = {}) {
  return new Paragraph({
    spacing: { before: opts.before || 240, after: opts.after || 0 },
    children: [
      new TextRun({ text: anchorTag, font: FONT, size: 2, color: WHITE }),
      new TextRun({ text: visibleText, font: FONT, size: 22, color: GREY })
    ]
  });
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

function makeHeader() {
  const children = [];
  if (logoBuffer) {
    children.push(new Paragraph({
      alignment: AlignmentType.LEFT,
      children: [new ImageRun({
        type: "jpg", data: logoBuffer,
        transformation: { width: 130, height: 33 },
        altText: { title: "Technijian", description: "Technijian Inc.", name: "logo" }
      })]
    }));
  } else {
    children.push(new Paragraph({ children: [
      new TextRun({ text: "TECHNIJIAN", font: FONT, bold: true, size: 20, color: BLUE }),
      new TextRun({ text: "  technology as a solution", font: FONT, size: 16, color: GREY })
    ]}));
  }
  children.push(new Paragraph({ border: { bottom: { style: BorderStyle.SINGLE, size: 1, color: BLUE } }, children: [] }));
  return new Header({ children });
}

function makeFooter() {
  return new Footer({
    children: [
      new Paragraph({ border: { top: { style: BorderStyle.SINGLE, size: 1, color: BLUE } }, spacing: { before: 100 }, children: [] }),
      new Paragraph({ alignment: AlignmentType.CENTER, children: [
        new TextRun({ text: "Technijian, Inc.  |  18 Technology Dr., Ste 141, Irvine, CA 92618  |  949.379.8499", font: FONT, size: 14, color: GREY })
      ]}),
      new Paragraph({ alignment: AlignmentType.CENTER, children: [
        new TextRun({ text: "Page ", font: FONT, size: 14, color: GREY }),
        new TextRun({ children: [PageNumber.CURRENT], font: FONT, size: 14, color: GREY }),
        new TextRun({ text: " of ", font: FONT, size: 14, color: GREY }),
        new TextRun({ children: [PageNumber.TOTAL_PAGES], font: FONT, size: 14, color: GREY })
      ]})
    ]
  });
}

function brandedLetterhead() {
  // Inline branded letterhead at top of page 1 — guaranteed to render even if DocuSign strips section headers.
  const items = [];
  if (logoBuffer) {
    items.push(new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 0, after: 120 },
      children: [new ImageRun({
        type: "jpg",
        data: logoBuffer,
        transformation: { width: 220, height: 56 },
        altText: { title: "Technijian Logo", description: "Technijian Inc.", name: "logo" }
      })]
    }));
  } else {
    items.push(new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { after: 0 },
      children: [new TextRun({ text: "TECHNIJIAN", font: FONT, size: 56, bold: true, color: BLUE })]
    }));
    items.push(new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { after: 120 },
      children: [new TextRun({ text: "technology as a solution", font: FONT, size: 18, color: GREY })]
    }));
  }
  // Orange accent rule below logo
  items.push(new Paragraph({
    spacing: { before: 60, after: 60 },
    border: { bottom: { style: BorderStyle.SINGLE, size: 8, color: ORANGE } },
    children: []
  }));
  // Address strip below the rule
  items.push(new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { before: 60, after: 60 },
    children: [new TextRun({
      text: "Technijian, Inc.  |  18 Technology Drive, Suite 141, Irvine, CA 92618  |  949.379.8499  |  technijian.com",
      font: FONT, size: 16, color: GREY
    })]
  }));
  // Blue rule under the strip
  items.push(new Paragraph({
    spacing: { before: 60, after: 240 },
    border: { bottom: { style: BorderStyle.SINGLE, size: 4, color: BLUE } },
    children: []
  }));
  return items;
}

async function generateNDA() {
  const c = [];

  // Branded letterhead at top of page 1
  brandedLetterhead().forEach(item => c.push(item));

  c.push(heading1("MUTUAL NON-DISCLOSURE AGREEMENT"));
  c.push(multiRun([{ text: "NDA Number: ", bold: true, color: CHARCOAL }, { text: "NDA-VWC-001" }]));
  c.push(multiRun([{ text: "Effective Date: ", bold: true, color: CHARCOAL }, { text: "April 28, 2026" }]));
  c.push(spacer());
  c.push(p("This Mutual Non-Disclosure Agreement (\"Agreement\") is entered into by and between:"));
  c.push(spacer());
  c.push(p("Technijian, Inc.", { bold: true, color: CHARCOAL }));
  c.push(p("18 Technology Drive, Suite 141"));
  c.push(p("Irvine, California 92618"));
  c.push(spacer());
  c.push(p("and"));
  c.push(spacer());
  c.push(p("VisionWise Capital, LLC", { bold: true, color: CHARCOAL }));
  c.push(p("27525 Puerta Real, Suite 300-164"));
  c.push(p("Mission Viejo, California 92691"));
  c.push(spacer());
  c.push(p("(each a \"Disclosing Party\" when disclosing Confidential Information and a \"Receiving Party\" when receiving Confidential Information; collectively, the \"Parties\")", { italics: true }));
  c.push(brandRule());

  // ---- 1. PURPOSE ----
  c.push(heading1("1. PURPOSE"));
  c.push(p("The Parties have an existing engagement under SOW-VWC-001-AI-Lead-Gen (AI / CTO Advisory — AI-Driven Lead Generation) and are evaluating an additional engagement under a forthcoming Statement of Work for the My SEO Program (Validation SEO for institutional multifamily capital). In connection with both the existing engagement and the broader business relationship, each Party expects to disclose Confidential Information to the other, including but not limited to investor-targeting data, fund and offering information, regulatory and compliance materials, technical infrastructure details, marketing strategy, content drafts, pricing, and proprietary methodologies (the \"Purpose\"). This Agreement sets the confidentiality framework that governs all such disclosures going forward."));
  c.push(brandRule());

  // ---- 2. DEFINITION ----
  c.push(heading1("2. DEFINITION OF CONFIDENTIAL INFORMATION"));
  c.push(p("\"Confidential Information\" means any and all non-public information disclosed by either Party to the other, whether orally, in writing, electronically, or by inspection, including but not limited to:"));
  c.push(spacer());
  c.push(p("(a) Business information, including pricing, client lists, vendor relationships, financial data, business plans, fund and offering data, investor lists, capital commitment information, and marketing strategies;", { indent: { left: 360 } }));
  c.push(spacer());
  c.push(p("(b) Technical information, including network architecture, system configurations, security assessments, audit reports, IP addresses, credentials, infrastructure documentation, and technical SEO data;", { indent: { left: 360 } }));
  c.push(spacer());
  c.push(p("(c) Proprietary methodologies, software, tools, and processes;", { indent: { left: 360 } }));
  c.push(spacer());
  c.push(p("(d) Regulatory and compliance materials, including Form ADV drafts, compliance counsel correspondence, SEC Marketing Rule review notes, and similar non-public regulatory materials;", { indent: { left: 360 } }));
  c.push(spacer());
  c.push(p("(e) Any information marked or identified as \"Confidential\" at the time of disclosure; and", { indent: { left: 360 } }));
  c.push(spacer());
  c.push(p("(f) Any information that a reasonable person would understand to be confidential given the nature of the information and the circumstances of disclosure.", { indent: { left: 360 } }));
  c.push(spacer());
  c.push(p("Confidential Information does not include information that:"));
  c.push(spacer());
  c.push(p("(i) Is or becomes publicly available through no fault of the Receiving Party;", { indent: { left: 360 } }));
  c.push(spacer());
  c.push(p("(ii) Was already known to the Receiving Party prior to disclosure, as demonstrated by written records;", { indent: { left: 360 } }));
  c.push(spacer());
  c.push(p("(iii) Is independently developed by the Receiving Party without use of or reference to the Confidential Information; or", { indent: { left: 360 } }));
  c.push(spacer());
  c.push(p("(iv) Is rightfully received from a third party without restriction on disclosure.", { indent: { left: 360 } }));
  c.push(brandRule());

  // ---- 3. OBLIGATIONS ----
  c.push(heading1("3. OBLIGATIONS OF THE RECEIVING PARTY"));
  c.push(p("The Receiving Party agrees to:"));
  c.push(spacer());
  c.push(p("(a) Hold all Confidential Information in strict confidence;", { indent: { left: 360 } }));
  c.push(spacer());
  c.push(p("(b) Not disclose Confidential Information to any third party without the prior written consent of the Disclosing Party;", { indent: { left: 360 } }));
  c.push(spacer());
  c.push(p("(c) Use the Confidential Information solely for the Purpose described in Section 1;", { indent: { left: 360 } }));
  c.push(spacer());
  c.push(p("(d) Limit access to Confidential Information to those employees, agents, contractors, and advisors (collectively, \"Representatives\") who have a need to know and who are bound by confidentiality obligations at least as protective as those in this Agreement. The Receiving Party shall be liable for any breach of this Agreement by its Representatives as if such breach were committed by the Receiving Party itself;", { indent: { left: 360 } }));
  c.push(spacer());
  c.push(p("(e) Take reasonable measures to protect the Confidential Information from unauthorized disclosure, using at least the same degree of care the Receiving Party uses for its own confidential information, but in no event less than reasonable care;", { indent: { left: 360 } }));
  c.push(spacer());
  c.push(p("(f) Promptly notify the Disclosing Party in writing of any unauthorized disclosure or use of Confidential Information; and", { indent: { left: 360 } }));
  c.push(spacer());
  c.push(p("(g) If the Receiving Party is required by law, regulation, subpoena, civil investigative demand, or court order to disclose Confidential Information, the Receiving Party shall (to the extent legally permitted) provide prompt written notice to the Disclosing Party prior to such disclosure and cooperate in seeking a protective order or other appropriate remedy to preserve confidentiality. If a protective order is not obtained, the Receiving Party may disclose only that portion of the Confidential Information that is legally required, and shall use commercially reasonable efforts to ensure that such disclosed information receives confidential treatment. Disclosure compelled by law shall not constitute a breach of this Agreement.", { indent: { left: 360 } }));
  c.push(brandRule());

  // ---- 4. RETURN ----
  c.push(heading1("4. RETURN OF MATERIALS"));
  c.push(p("Upon termination of this Agreement or upon written request by the Disclosing Party, the Receiving Party shall promptly return or destroy all Confidential Information in its possession, including all copies, notes, summaries, and extracts thereof, and shall certify such return or destruction in writing upon request. Notwithstanding the foregoing, the Receiving Party may retain (i) one (1) archival copy in its outside legal counsel's files solely for legal-record purposes, and (ii) copies of Confidential Information contained in routine system backups or archives that cannot be deleted without unreasonable effort, provided that any such retained Confidential Information shall remain subject to the confidentiality obligations of this Agreement for so long as it is retained, and shall not be accessed, used, or restored except as required by law or for the legal-record purpose described above."));
  c.push(brandRule());

  // ---- 5. NO LICENSE ----
  c.push(heading1("5. NO LICENSE OR WARRANTY"));
  c.push(p("Nothing in this Agreement grants either Party any rights to the other Party's Confidential Information, intellectual property, or proprietary materials, except the limited right to use such information for the Purpose. All Confidential Information is provided \"AS IS\" without warranty of any kind."));
  c.push(brandRule());

  // ---- 6. NO OBLIGATION ----
  c.push(heading1("6. NO OBLIGATION"));
  c.push(p("This Agreement does not obligate either Party to enter into any further agreement, transaction, or business relationship. Either Party may terminate discussions at any time without liability. Nothing in this Agreement shall be construed as a commitment by VisionWise Capital, LLC to engage Technijian for the My SEO Program or any other future Statement of Work, nor as a commitment by Technijian to provide services beyond those expressly agreed in a separately executed Statement of Work."));
  c.push(brandRule());

  // ---- 7. TERM ----
  c.push(heading1("7. TERM AND SURVIVAL"));
  c.push(p("This Agreement shall remain in effect for a period of two (2) years from the Effective Date. The confidentiality obligations set forth in this Agreement shall survive termination for a period of three (3) years following the date of disclosure of the Confidential Information. Notwithstanding the foregoing, the confidentiality obligations with respect to any Confidential Information that constitutes a trade secret under the California Uniform Trade Secrets Act (Cal. Civ. Code § 3426 et seq.) or other applicable law shall continue for so long as such information remains a trade secret."));
  c.push(brandRule());

  // ---- 8. REMEDIES ----
  c.push(heading1("8. REMEDIES"));
  c.push(p("The Receiving Party acknowledges that any breach of this Agreement may cause irreparable harm to the Disclosing Party for which monetary damages may be inadequate. Accordingly, the Disclosing Party shall be entitled to seek injunctive relief, specific performance, and other equitable remedies, in addition to any other remedies available at law or in equity, without the necessity of posting a bond or other security and without proof of actual damages. The remedies in this Section are cumulative and not exclusive."));
  c.push(brandRule());

  // ---- 9. GOVERNING LAW ----
  c.push(heading1("9. GOVERNING LAW AND DISPUTE RESOLUTION"));
  c.push(p("This Agreement shall be governed by and construed in accordance with the laws of the State of California. Any dispute arising under this Agreement shall be resolved in the state or federal courts located in Orange County, California, and each Party consents to the jurisdiction of such courts."));
  c.push(brandRule());

  // ---- 10. GENERAL ----
  c.push(heading1("10. GENERAL PROVISIONS"));
  c.push(multiRun([
    { text: "(a) Entire Agreement. ", bold: true, color: CHARCOAL },
    { text: "This Agreement constitutes the entire agreement between the Parties with respect to the confidentiality of information exchanged in connection with the Purpose, and supersedes all prior or contemporaneous oral or written confidentiality agreements between them on the same subject. Confidentiality provisions in any separately executed Statement of Work shall be construed to coexist with this Agreement; in the event of any conflict, the provision more protective of the Disclosing Party shall control." }
  ], { indent: { left: 360 } }));
  c.push(spacer());
  c.push(multiRun([
    { text: "(b) Amendment. ", bold: true, color: CHARCOAL },
    { text: "This Agreement may not be amended except by a written instrument signed by both Parties." }
  ], { indent: { left: 360 } }));
  c.push(spacer());
  c.push(multiRun([
    { text: "(c) Severability. ", bold: true, color: CHARCOAL },
    { text: "If any provision of this Agreement is found to be invalid or unenforceable, the remaining provisions shall continue in full force and effect." }
  ], { indent: { left: 360 } }));
  c.push(spacer());
  c.push(multiRun([
    { text: "(d) Assignment. ", bold: true, color: CHARCOAL },
    { text: "Neither Party may assign this Agreement without the prior written consent of the other Party." }
  ], { indent: { left: 360 } }));
  c.push(spacer());
  c.push(multiRun([
    { text: "(e) Counterparts; Electronic Signatures. ", bold: true, color: CHARCOAL },
    { text: "This Agreement may be executed in counterparts, each of which shall be deemed an original. Electronic signatures (including signatures captured via DocuSign or another e-signature platform) shall have the same force and effect as original handwritten signatures." }
  ], { indent: { left: 360 } }));
  c.push(brandRule());

  // ---- SIGNATURES with hidden DocuSign anchors ----
  c.push(heading1("SIGNATURES"));
  c.push(spacer());
  c.push(p("TECHNIJIAN, INC.", { bold: true, color: CHARCOAL }));
  c.push(anchorLine("By: ___________________________________", "/tSign/", { before: 240 }));
  c.push(anchorLine("Name: Ravi Jain", "/tName/", { before: 240 }));
  c.push(anchorLine("Title: Chief Executive Officer", "/tTitle/", { before: 240 }));
  c.push(anchorLine("Date: _________________________________", "/tDate/", { before: 240 }));
  c.push(spacer());
  c.push(spacer());
  c.push(p("VISIONWISE CAPITAL, LLC", { bold: true, color: CHARCOAL }));
  c.push(anchorLine("By: ___________________________________", "/cSign/", { before: 240 }));
  c.push(anchorLine("Name: Sanford Coggins", "/cName/", { before: 240 }));
  c.push(anchorLine("Title: Founder", "/cTitle/", { before: 240 }));
  c.push(anchorLine("Date: _________________________________", "/cDate/", { before: 240 }));

  const doc = new Document({
    styles: docStyles,
    numbering,
    sections: [
      {
        properties: {
          page: { size: { width: 12240, height: 15840 }, margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 } },
          headers: { default: makeHeader() },
          footers: { default: makeFooter() }
        },
        children: c
      }
    ]
  });

  const buffer = await Packer.toBuffer(doc);
  const outputPath = path.join(__dirname, "..", "01_NDA", "NDA-VWC-001.docx");
  fs.writeFileSync(outputPath, buffer);
  console.log("Generated:", outputPath);
}

generateNDA().catch(err => {
  console.error("Error generating NDA:", err);
  process.exit(1);
});
