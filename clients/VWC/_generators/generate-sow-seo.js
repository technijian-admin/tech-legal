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

let logoBuffer = null;
const logoPath = path.join(__dirname, "../../../templates/logo.jpg");
try { logoBuffer = fs.readFileSync(logoPath); } catch (e) {}

// ===== STYLES =====
const docStyles = {
  default: { document: { run: { font: FONT, size: 22, color: GREY } } },
  paragraphStyles: [
    { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
      run: { size: 36, bold: true, font: FONT, color: BLUE },
      paragraph: { spacing: { before: 360, after: 240 }, outlineLevel: 0 } },
    { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
      run: { size: 28, bold: true, font: FONT, color: CHARCOAL },
      paragraph: { spacing: { before: 280, after: 160 }, outlineLevel: 1 } },
    { id: "Heading3", name: "Heading 3", basedOn: "Normal", next: "Normal", quickFormat: true,
      run: { size: 24, bold: true, font: FONT, color: CHARCOAL },
      paragraph: { spacing: { before: 200, after: 120 }, outlineLevel: 2 } }
  ]
};

const numbering = {
  config: ["bullets","bullets2","bullets3","bullets4","bullets5","bullets6"].map(ref => ({
    reference: ref,
    levels: [{
      level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT,
      style: { paragraph: { indent: { left: 720, hanging: 360 } } }
    }]
  }))
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

// Hidden DocuSign anchor — 1pt white text, invisible to readers but parseable by DocuSign
function anchorLine(visibleText, anchorTag, opts = {}) {
  const indent = opts.indent || undefined;
  return new Paragraph({
    spacing: { before: opts.before || 240, after: opts.after || 0 },
    indent,
    children: [
      new TextRun({ text: anchorTag, font: FONT, size: 2, color: WHITE }),
      new TextRun({ text: visibleText, font: FONT, size: 22, color: GREY })
    ]
  });
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
  const totalWidth = widths.reduce((a, b) => a + b, 0);
  const tableRows = [
    new TableRow({ children: headers.map((h, i) => brandTableCell(h, { width: widths[i], header: true })) }),
    ...rows.map((row, ri) => new TableRow({
      children: row.map((cell, ci) => {
        const text = typeof cell === "string" ? cell : cell.text;
        const bold = typeof cell === "object" ? cell.bold : false;
        return brandTableCell(text, { width: widths[ci], alt: ri % 2 === 0, bold });
      })
    }))
  ];
  return new Table({ width: { size: totalWidth, type: WidthType.DXA }, columnWidths: widths, rows: tableRows });
}

// ===== COVER PAGE =====
function coverPage(title, subtitle) {
  const items = [];
  items.push(p("", { spacing: { before: 2400 } }));
  if (logoBuffer) {
    items.push(new Paragraph({
      alignment: AlignmentType.CENTER, spacing: { after: 200 },
      children: [new ImageRun({
        type: "jpg", data: logoBuffer,
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
  if (subtitle) items.push(p(subtitle, { size: 24, color: GREY, alignment: AlignmentType.CENTER, spacing: { after: 400 } }));
  items.push(orangeAccentRule());
  items.push(p("", { spacing: { after: 600 } }));
  items.push(p("April 27, 2026", { size: 22, color: GREY, alignment: AlignmentType.CENTER, spacing: { after: 200 } }));
  items.push(p("", { spacing: { after: 400 } }));
  items.push(p("Technijian, Inc.", { size: 22, bold: true, color: CHARCOAL, alignment: AlignmentType.CENTER }));
  items.push(p("18 Technology Dr., Ste 141  |  Irvine, CA 92618  |  949.379.8499", { size: 20, color: GREY, alignment: AlignmentType.CENTER }));
  items.push(new Paragraph({ children: [new PageBreak()] }));
  return items;
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

function coverSectionProps() {
  return { page: { size: { width: 12240, height: 15840 }, margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 } } };
}
function contentSectionProps() {
  return {
    page: { size: { width: 12240, height: 15840 }, margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 } },
    headers: { default: makeHeader() }, footers: { default: makeFooter() }
  };
}

// ===== SOW BODY =====
async function generateSOW() {
  const c = [];

  c.push(heading1("STATEMENT OF WORK"));
  c.push(multiRun([{ text: "SOW Number: ", bold: true, color: CHARCOAL }, { text: "SOW-VWC-002-SEO" }]));
  c.push(multiRun([{ text: "Effective Date: ", bold: true, color: CHARCOAL }, { text: "May 1, 2026" }]));
  c.push(multiRun([{ text: "Initial Term: ", bold: true, color: CHARCOAL }, { text: "Twelve (12) months — May 1, 2026 through April 30, 2027" }]));
  c.push(multiRun([{ text: "Master Service Agreement: ", bold: true, color: CHARCOAL }, { text: "None (standalone SOW — Technijian Standard Terms and Conditions apply)" }]));
  c.push(spacer());
  c.push(p("This Statement of Work (\"SOW\") is entered into by and between:"));
  c.push(spacer());
  c.push(p("Technijian, Inc. (\"Technijian\")", { bold: true, color: CHARCOAL }));
  c.push(p("18 Technology Drive, Suite 141"));
  c.push(p("Irvine, California 92618"));
  c.push(spacer());
  c.push(p("and"));
  c.push(spacer());
  c.push(p("VisionWise Capital, LLC (\"Client\" or \"VWC\")", { bold: true, color: CHARCOAL }));
  c.push(p("27525 Puerta Real, Suite 300-164"));
  c.push(p("Mission Viejo, California 92691"));
  c.push(spacer());
  c.push(multiRun([{ text: "Primary Contact: ", bold: true, color: CHARCOAL }, { text: "Sanford Coggins, Founder (info@visionwisecapital.com)" }]));
  c.push(brandRule());

  // ---- 1. PROJECT OVERVIEW ----
  c.push(heading1("1. PROJECT OVERVIEW"));
  c.push(heading2("1.1 Project Title"));
  c.push(p("My SEO Program — Validation SEO for Institutional Multifamily Capital"));
  c.push(spacer());
  c.push(heading2("1.2 Project Description"));
  c.push(p("VisionWise Capital, LLC (\"VWC\") is a Southern California commercial real estate investment firm operating a syndicated multifamily fund with a hard-cap leverage policy (sub-50% Loan-to-Value), serving accredited investors, Registered Investment Advisors (RIAs), and high-net-worth individuals. Because VWC's principal is an SEC-registered investment adviser, every published word falls under SEC Marketing Rule 206(4)-1 oversight, and VWC's growth depends on a digital footprint that confirms institutional quality when sophisticated allocators conduct due diligence."));
  c.push(spacer());
  c.push(p("Technijian will deliver its My SEO program — a 12-month managed SEO retainer with unlimited monthly service hours — engineered for VWC's \"Validation SEO\" posture rather than retail lead generation. The engagement is structured in two pricing phases: Months 1 through 3 deliver the website, technical SEO, and content foundation at $1,000 per month; Months 4 through 12 layer on AI search optimization, content syndication, and PR releases at $1,550 per month, by which time the foundation is complete and amplification can produce results without burning spend on an empty backbone."));
  c.push(spacer());
  c.push(p("The first day of work is May 1, 2026 and the initial term runs through April 30, 2027."));
  c.push(spacer());
  c.push(heading2("1.3 Locations"));
  c.push(makeTable(
    ["Location Name", "Code", "Address", "Billable"],
    [["VWC — Headquarters", "VWC-HQ", "27525 Puerta Real, Ste 300-164, Mission Viejo, CA 92691", "Yes"]],
    [2200, 1200, 4800, 1100]
  ));
  c.push(spacer());
  c.push(p("All work shall be performed remotely. On-site working sessions, if requested by Client, shall be billed at the rates in the Technijian Rate Card current as of the date of service."));
  c.push(brandRule());

  // ---- 2. SCOPE OF WORK ----
  c.push(heading1("2. SCOPE OF WORK"));
  c.push(heading2("2.1 In Scope — My SEO Program"));
  c.push(p("Technijian shall provide the following recurring services for the 12-month term, with the timing of each component as specified in Section 3:"));
  c.push(spacer());
  c.push(p("Foundation (Months 1 through 12) — My SEO Tier 3:", { bold: true, color: CHARCOAL }));
  c.push(bullet("Website Design and Hosting — Custom-designed, responsive, SEO-optimized WordPress website. Hosting for two (2) WordPress sites (one production, one development), 100 GB of storage, daily backups, ongoing security updates, and core/plugin maintenance.", "bullets"));
  c.push(bullet("SEO Optimization — Keyword research, on-page SEO (content, meta tags, internal linking, image optimization), off-page SEO (high-quality backlink building), monthly analytics reporting, competitive SERP analysis, and SEO strategy refinement.", "bullets"));
  c.push(bullet("Content Production — Blogs for Five (5) Keywords — Five (5) keyword-targeted blog posts per month written for VWC's institutional audience, with a content calendar, internal-linking strategy, and post-publication amplification across VWC's own channels.", "bullets"));
  c.push(spacer());
  c.push(p("Authority and Amplification Add-Ons (Months 4 through 12 only):", { bold: true, color: CHARCOAL }));
  c.push(bullet("AI Search Optimization — Schema markup, semantic SEO clusters, featured-snippet targeting, entity optimization for VWC and Sanford Coggins, technical SEO improvements for AI/LLM readability, brand-mention building, AI-driven keyword and topic research, competitor gap analysis, content refreshes for AI indexing, and reporting on AI-search performance.", "bullets2"));
  c.push(bullet("PR Releases (Published Quarterly) — Pre-approved 500+ word releases distributed to 300+ live placements per quarter, including FOX, ABC, and NBC affiliates and digitaljournal.com (DR 87 / DA 88), with three (3) body links and one (1) bio link per release, comprehensive submission report, and natural anchor optimization.", "bullets2"));
  c.push(bullet("Content Syndication — Monthly distribution of approved long-form content to 250+ websites, coverage in media outlets and news channels, premium syndication outlets, second-tier link building with canonical/original-credit links, and detailed monthly distribution reporting.", "bullets2"));
  c.push(spacer());
  c.push(p("Reporting and Account Management (Months 1 through 12):", { bold: true, color: CHARCOAL }));
  c.push(bullet("Monthly KPI report with baseline-to-current metrics for organic traffic, branded SERP coverage, keyword rankings, Core Web Vitals, backlinks acquired, and content shipped.", "bullets3"));
  c.push(bullet("Quarterly business review with VWC leadership.", "bullets3"));
  c.push(bullet("Dedicated Technijian SEO pod with unlimited monthly service hours during the term.", "bullets3"));
  c.push(spacer());

  c.push(heading2("2.2 Out of Scope"));
  c.push(p("The following items are expressly excluded from this SOW unless added by written Change Order:"));
  c.push(spacer());
  c.push(bullet("My SEO Tier 4 (Videos for Blogs) and Tier 5 (Topical Viral Videos) — institutional audience does not consume video blog content; intentionally not included.", "bullets4"));
  c.push(bullet("Digital Marketing Management Program (paid media on Google Ads, Meta, LinkedIn, TikTok, YouTube, Display) — paid media spend and management are out of scope; available as a separate month-to-month engagement.", "bullets4"));
  c.push(bullet("Outside compliance counsel review fees — Technijian will route content requiring securities-law review through Client's designated counsel; counsel time is billed by counsel directly to Client.", "bullets4"));
  c.push(bullet("Third-party data subscriptions and tools that Client procures and pays for directly, including FINTRX / Family Office List, PitchBook, Preqin, LinkedIn Sales Navigator, DocSend or other Data Room platforms, VerifyInvestor.com, CRM seats (HubSpot, Salesforce), and dedicated email-sending infrastructure.", "bullets4"));
  c.push(bullet("Account-Based Marketing (ABM) execution — dimensional mailer design, print, postage, and fulfillment management are out of scope; available as a separate per-workstream SOW.", "bullets4"));
  c.push(bullet("Podcast placement booking and sponsorship fees.", "bullets4"));
  c.push(bullet("Whitepaper authorship requiring securities counsel coordination beyond standard editorial.", "bullets4"));
  c.push(bullet("Data Room platform selection, configuration, or analytics integration.", "bullets4"));
  c.push(bullet("Privacy-first analytics rearchitecture (e.g., replacing GA4 with Plausible/Fathom and rebuilding cookie consent).", "bullets4"));
  c.push(bullet("Custom CMS migration away from WordPress, headless architecture builds, or e-commerce platform work.", "bullets4"));
  c.push(bullet("Negative SERP suppression beyond standard SEO (online reputation management as a dedicated workstream).", "bullets4"));
  c.push(bullet("Investment decisions, solicitation of investors, or any activity requiring a securities license.", "bullets4"));
  c.push(bullet("Legal, tax, or compliance opinions regarding SEC, FINRA, or state securities laws.", "bullets4"));
  c.push(bullet("24x7 system monitoring, production incident response, or managed IT services (available under a separate Technijian MSA).", "bullets4"));
  c.push(spacer());
  c.push(p("Items above outside My SEO are typically delivered via separate per-workstream SOWs or a monthly consulting retainer; pricing for those is discussed only after this SOW is in effect.", { italics: true }));
  c.push(spacer());

  c.push(heading2("2.3 Assumptions"));
  c.push(bullet("Client procures and pays for all third-party data, software, and services listed in Section 2.2 directly.", "bullets5"));
  c.push(bullet("Client designates a single empowered Marketing Lead with authority to approve scope, content, and publication. Default Marketing Lead: Sanford Coggins until VWC names a dedicated lead.", "bullets5"));
  c.push(bullet("Client will route any content with performance claims, forward-looking statements, testimonials/endorsements, or other SEC Marketing Rule triggers through outside compliance counsel before publication. Counsel review SLA is set by counsel; Technijian content production timelines extend to accommodate counsel review without penalty.", "bullets5"));
  c.push(bullet("Client will provide Technijian with administrative access to the website, Google Search Console, Google Analytics 4, Google Business Profile, LinkedIn company page, and the chosen analytics/SEO toolset within five (5) business days of the Effective Date.", "bullets5"));
  c.push(bullet("Content drafts are submitted for Client review with a five (5) business-day default review SLA. Content not reviewed within ten (10) business days is deemed approved for publication, except for content flagged by Technijian as requiring counsel review, which awaits affirmative counsel approval.", "bullets5"));
  c.push(bullet("The Tier 3 base pricing of $1,000 per month is held flat for the entire 12-month term. Add-on pricing of $550 per month (combined) is held flat for Months 4 through 12.", "bullets5"));
  c.push(bullet("All deliverables are produced in U.S. English and target U.S.-based search engines (Google, Bing).", "bullets5"));
  c.push(bullet("Time and deliverables are tracked in calendar months; partial months at the start of the term are pro-rated.", "bullets5"));
  c.push(brandRule());

  // ---- 3. SERVICE PHASES ----
  c.push(heading1("3. SERVICE PHASES AND DELIVERY SCHEDULE"));
  c.push(p("The 12-month term is organized into two consecutive phases. There is no gap between phases; the transition from Phase 1 to Phase 2 happens automatically at the start of Month 4 (August 1, 2026) without further authorization."));
  c.push(spacer());

  c.push(heading2("Phase 1: Foundation (Months 1 through 3 — May 1, 2026 through July 31, 2026)"));
  c.push(heading3("3.1.1 Description"));
  c.push(p("Months 1 through 3 build the digital foundation that every later authority and amplification activity depends on. Add-ons (AI Search Optimization, PR Releases, Content Syndication) intentionally do not run during this phase because there is no foundation yet for them to amplify."));
  c.push(spacer());
  c.push(heading3("3.1.2 Monthly Recurring Activities"));
  c.push(bullet("Website design, build, and hosting setup (Month 1 launch focus).", "bullets6"));
  c.push(bullet("Technical SEO audit, Core Web Vitals remediation, schema baseline.", "bullets6"));
  c.push(bullet("Index cleansing (de-index or rewrite content that conflicts with Validation SEO posture).", "bullets6"));
  c.push(bullet("Keyword research and competitive SERP baseline.", "bullets6"));
  c.push(bullet("On-page SEO across all production pages.", "bullets6"));
  c.push(bullet("Backlink building (high-quality, institutional-tier referring domains).", "bullets6"));
  c.push(bullet("Five (5) keyword-targeted blog posts per month with content-calendar planning.", "bullets6"));
  c.push(bullet("Monthly KPI report.", "bullets6"));
  c.push(spacer());
  c.push(heading3("3.1.3 Phase 1 Deliverables"));
  c.push(bullet("Production WordPress site live on Technijian-hosted infrastructure by end of Month 1, with development site mirroring production.", "bullets"));
  c.push(bullet("Baseline metrics report by end of Week 2 of Month 1 (organic traffic, indexed pages, branded SERP coverage, Core Web Vitals, current backlink profile, current keyword rankings).", "bullets"));
  c.push(bullet("Existing-asset inventory and classification (keep-amplify / rewrite / de-index / suppress) by end of Month 1.", "bullets"));
  c.push(bullet("Knowledge Panel claim and optimization for VWC firm and Sanford Coggins by end of Month 2.", "bullets"));
  c.push(bullet("Fifteen (15) blog posts published over Phase 1 (5 per month × 3 months).", "bullets"));
  c.push(bullet("Monthly KPI reports at end of Months 1, 2, and 3.", "bullets"));
  c.push(spacer());

  c.push(heading2("Phase 2: Foundation Plus Authority and Amplification (Months 4 through 12 — August 1, 2026 through April 30, 2027)"));
  c.push(heading3("3.2.1 Description"));
  c.push(p("Once the foundation is live, Phase 2 layers on the AI Search Optimization, quarterly PR Releases, and monthly Content Syndication that drive authority signals, branded SERP coverage, and institutional-tier referring domains. Phase 1 activities continue throughout Phase 2."));
  c.push(spacer());
  c.push(heading3("3.2.2 Monthly Recurring Activities (Phase 1 Activities Continue, Plus)"));
  c.push(bullet("AI Search Optimization — schema markup, semantic SEO clusters, featured-snippet targeting, entity optimization for VWC and Sanford Coggins, AI/LLM citation tracking and reporting.", "bullets2"));
  c.push(bullet("Content Syndication — monthly distribution of approved long-form content to 250+ websites, coverage in media outlets and news channels, second-tier link building with canonical/original-credit links, monthly distribution report.", "bullets2"));
  c.push(bullet("Quarterly PR Releases — pre-approved 500+ word releases at the start of Months 4, 7, and 10, distributed to 300+ live placements (FOX/ABC/NBC affiliates, digitaljournal.com), with submission report.", "bullets2"));
  c.push(spacer());
  c.push(heading3("3.2.3 Phase 2 Deliverables"));
  c.push(bullet("Three (3) PR Releases over Phase 2 (Q1 of Phase 2 / Month 4, Q2 / Month 7, Q3 / Month 10).", "bullets3"));
  c.push(bullet("Nine (9) months of Content Syndication distribution reports (one per month, Months 4 through 12).", "bullets3"));
  c.push(bullet("Forty-five (45) additional blog posts published (5 per month × 9 months).", "bullets3"));
  c.push(bullet("AI Search Optimization performance report monthly, included in the monthly KPI report.", "bullets3"));
  c.push(bullet("End-of-term performance summary at end of Month 12 with recommendations for the renewal term.", "bullets3"));
  c.push(brandRule());

  // ---- 4. EQUIPMENT AND MATERIALS ----
  c.push(heading1("4. EQUIPMENT AND MATERIALS"));
  c.push(p("No hardware or equipment is supplied under this SOW. Hosting infrastructure for the production and development WordPress sites is included in the My SEO Tier 3 service fee. Third-party data subscriptions, paid-media spend, and tools listed in Section 2.2 are procured and paid by Client directly."));
  c.push(brandRule());

  // ---- 5. PRICING AND PAYMENT ----
  c.push(heading1("5. PRICING AND PAYMENT"));

  c.push(heading2("5.1 Phased Pricing Schedule"));
  c.push(p("Service fees are structured in two phases to align cost with the value being delivered each month. The transition from Phase 1 pricing ($1,000 per month) to Phase 2 pricing ($1,550 per month) occurs automatically on August 1, 2026 (start of Month 4) without further action by either Party. No invoice change order is required."));
  c.push(spacer());
  c.push(makeTable(
    ["Service Component", "Months 1–3", "Months 4–12"],
    [
      ["Tier 3 — Website + Hosting + SEO Optimization + Blog Production", "$1,000.00 / mo", "$1,000.00 / mo"],
      ["AI Search Optimization", "—", "$200.00 / mo"],
      ["PR Releases (Quarterly Publish, Billed Monthly)", "—", "$150.00 / mo"],
      ["Content Syndication", "—", "$200.00 / mo"],
      [{ text: "Monthly Total", bold: true }, { text: "$1,000.00", bold: true }, { text: "$1,550.00", bold: true }]
    ],
    [5800, 1900, 1900]
  ));
  c.push(spacer());

  c.push(heading2("5.2 Term Total — 12-Month Investment"));
  c.push(makeTable(
    ["Phase", "Months", "Monthly Fee", "Months", "Phase Subtotal"],
    [
      ["Phase 1 — Foundation", "1–3", "$1,000.00", "3", "$3,000.00"],
      ["Phase 2 — Foundation + Add-Ons", "4–12", "$1,550.00", "9", "$13,950.00"],
      [{ text: "Total 12-Month Investment", bold: true }, "", "", { text: "12", bold: true }, { text: "$16,950.00", bold: true }]
    ],
    [3400, 1200, 1700, 1300, 2000]
  ));
  c.push(spacer());

  c.push(heading2("5.3 Pricing Type"));
  c.push(p("This SOW is Fixed Cost Recurring. Technijian shall deliver the scope described in Section 2.1 for each Phase at the corresponding monthly fee, regardless of the number of service hours actually consumed. There is no overage billing for hours within the My SEO scope. Out-of-scope work requires a written Change Order under Section 7."));
  c.push(spacer());

  c.push(heading2("5.4 Invoicing and Payment Schedule"));
  c.push(bullet("Technijian invoices Client monthly in advance on the first business day of each calendar month for the services to be delivered that month.", "bullets"));
  c.push(bullet("The first invoice is dated May 1, 2026 in the amount of $1,000.00 (Month 1 Phase 1).", "bullets"));
  c.push(bullet("The fourth invoice is dated August 1, 2026 in the amount of $1,550.00 (Month 4 — first Phase 2 invoice).", "bullets"));
  c.push(bullet("All invoices are due and payable within thirty (30) days of the invoice date.", "bullets"));
  c.push(spacer());

  c.push(heading2("5.5 Late Payment and Collection Remedies"));
  c.push(p("Because no MSA is in effect between the Parties, the following standalone provisions apply:"));
  c.push(spacer());
  c.push(multiRun([
    { text: "(a) Late Payment. ", bold: true, color: CHARCOAL },
    { text: "Late payments shall accrue a late fee of 1.5% per month (or the maximum rate permitted by law, whichever is less) on the unpaid balance, calculated as simple interest from the date payment was due. The Parties acknowledge that the late fee represents a reasonable estimate of Technijian's administrative costs and damages resulting from late payment and is not a penalty." }
  ], { indent: { left: 360 } }));
  c.push(spacer());
  c.push(multiRun([
    { text: "(b) Acceleration. ", bold: true, color: CHARCOAL },
    { text: "If Client fails to pay any undisputed invoice within forty-five (45) days of the due date, all remaining fees under this SOW for the balance of the then-current term shall become immediately due and payable." }
  ], { indent: { left: 360 } }));
  c.push(spacer());
  c.push(multiRun([
    { text: "(c) Suspension. ", bold: true, color: CHARCOAL },
    { text: "Technijian may suspend all work under this SOW upon ten (10) days written notice if any invoice remains unpaid beyond the due date. Suspension does not relieve Client of its payment obligations, and the term shall not be extended on account of suspension." }
  ], { indent: { left: 360 } }));
  c.push(spacer());
  c.push(multiRun([
    { text: "(d) Collection Costs and Attorney's Fees. ", bold: true, color: CHARCOAL },
    { text: "In any action or proceeding to collect fees, invoices, or other amounts owed under this SOW, the prevailing Party shall be entitled to recover all reasonable costs of collection, including attorney's fees (including in-house counsel at market rates), collection agency fees, court costs, arbitration fees, and all costs of appeal. Pursuant to California Civil Code Section 1717, the Parties acknowledge that this attorney's fees provision is reciprocal. This fee-shifting applies exclusively to collection of amounts owed and does not apply to disputes regarding service quality, professional performance, or other non-payment claims." }
  ], { indent: { left: 360 } }));
  c.push(spacer());
  c.push(multiRun([
    { text: "(e) Lien on Work Product. ", bold: true, color: CHARCOAL },
    { text: "Technijian shall retain a lien on all deliverables, work product, documentation, and materials (excluding Client Data and any administrative credentials, root accounts, DNS, or break-glass information) under this SOW until all amounts owed are paid in full." }
  ], { indent: { left: 360 } }));
  c.push(spacer());
  c.push(multiRun([
    { text: "(f) Fees for Non-Collection Disputes. ", bold: true, color: CHARCOAL },
    { text: "Except as provided in subsection (d) above, in any dispute arising under this SOW relating to service quality, professional performance, scope, or any other non-payment matter, each Party shall bear its own attorney's fees and costs." }
  ], { indent: { left: 360 } }));
  c.push(brandRule());

  // ---- 6. CLIENT RESPONSIBILITIES ----
  c.push(heading1("6. CLIENT RESPONSIBILITIES"));
  c.push(p("Client shall:"));
  c.push(spacer());
  c.push(p("(a) Provide Technijian with administrative access to the website, Google Search Console, Google Analytics 4, Google Business Profile, LinkedIn company page, and the agreed-upon SEO toolset within five (5) business days of the Effective Date;", { indent: { left: 360 } }));
  c.push(spacer());
  c.push(p("(b) Designate a single empowered Marketing Lead (default: Sanford Coggins until otherwise named) with authority to approve scope, content, vendor selection, and publication;", { indent: { left: 360 } }));
  c.push(spacer());
  c.push(p("(c) Review and approve content deliverables within five (5) business days of submission. Content not reviewed within ten (10) business days is deemed approved for publication, except content flagged by Technijian as requiring outside counsel review, which awaits affirmative counsel approval;", { indent: { left: 360 } }));
  c.push(spacer());
  c.push(p("(d) Procure and pay directly for all third-party data, software, paid-media spend, and tools listed in Section 2.2 (e.g., FINTRX, Sales Navigator, Data Room platform, paid-media spend);", { indent: { left: 360 } }));
  c.push(spacer());
  c.push(p("(e) Engage and pay outside compliance counsel for review of any content or materials triggering SEC Marketing Rule, FINRA Rule 2210, or state securities-law obligations. Technijian is not a law firm, does not provide legal or compliance advice, and bears no responsibility for the legal sufficiency of disclosures, disclaimers, performance claims, or testimonials;", { indent: { left: 360 } }));
  c.push(spacer());
  c.push(p("(f) Ensure that all published content is reviewed for compliance with applicable securities, advertising, and privacy laws prior to publication. Client retains sole responsibility for the legality and content of all published materials;", { indent: { left: 360 } }));
  c.push(spacer());
  c.push(p("(g) Promptly notify Technijian of any compliance, regulatory, reputational, or legal matter that affects the digital presence Technijian is managing;", { indent: { left: 360 } }));
  c.push(spacer());
  c.push(p("(h) Maintain operational ownership of all accounts to which Technijian is granted administrative access. Upon termination, Technijian shall transfer or surrender all such administrative credentials within five (5) business days; and", { indent: { left: 360 } }));
  c.push(spacer());
  c.push(p("(i) Inform Technijian of any change in Marketing Lead, counsel, or signatory authority.", { indent: { left: 360 } }));
  c.push(brandRule());

  // ---- 7. CHANGE MANAGEMENT ----
  c.push(heading1("7. CHANGE MANAGEMENT"));
  c.push(p("7.01. Either Party may request a change to scope, deliverables, or timing by written notice (email is sufficient). Any change that materially alters the recurring scope, the monthly fee, or an add-on's start month requires a written Change Order signed by both Parties before the changed work begins."));
  c.push(spacer());
  c.push(p("7.02. Phase 2 add-ons (AI Search Optimization, PR Releases, Content Syndication) start automatically on August 1, 2026 without further authorization. Either Party may request acceleration or further deferral of any add-on by written notice no later than fifteen (15) days before the requested change date; acceleration or deferral becomes effective only upon a Change Order signed by both Parties."));
  c.push(spacer());
  c.push(p("7.03. Out-of-scope work that Client requests on an ad-hoc basis (for example, items in Section 2.2 such as ABM workstreams, podcast booking, Data Room configuration, or compliance whitepaper coordination) shall be quoted by Technijian on a per-workstream Change Order or separate SOW and shall not be performed until that Change Order or SOW is signed by both Parties."));
  c.push(spacer());
  c.push(p("7.04. Technijian shall not perform out-of-scope work that would result in additional fees without prior written authorization from Client, except in the case of imminent harm to Client's digital presence (for example, an active SEO attack or DNS hijack), in which case Technijian may perform emergency mitigation work not to exceed $2,500 at the rates in the Technijian Rate Card current as of the date of service, and shall notify Client as soon as practicable, with a retrospective Change Order within three (3) business days."));
  c.push(brandRule());

  // ---- 8. ACCEPTANCE AND SLA ----
  c.push(heading1("8. ACCEPTANCE AND SERVICE LEVELS"));
  c.push(p("8.01. Each calendar month's services constitute a \"Monthly Deliverable.\" Technijian shall provide a monthly KPI report no later than the tenth (10th) business day of the following month, summarizing the work performed, the deliverables produced, and the KPI movement for the prior month."));
  c.push(spacer());
  c.push(p("8.02. Client shall review the monthly KPI report and provide written acceptance or a detailed description of deficiencies within five (5) business days of receipt. Technijian's report submission shall include a conspicuous statement: \"If you do not respond within five (5) business days, this Monthly Deliverable will be deemed accepted per SOW Section 8.03.\""));
  c.push(spacer());
  c.push(p("8.03. If Client does not respond within the review period, the Monthly Deliverable is deemed accepted and the corresponding monthly invoice becomes payable per Section 5.4."));
  c.push(spacer());
  c.push(p("8.04. If Client identifies deficiencies, Technijian shall correct them within ten (10) business days at no additional charge and resubmit for review. This process shall repeat until acceptance is achieved or the Parties agree on a resolution."));
  c.push(spacer());
  c.push(p("8.05. Service Level — Technijian shall use commercially reasonable efforts to (a) keep the production WordPress site at 99.5% monthly uptime, (b) respond to Client urgent inquiries within four (4) business hours, and (c) deliver each monthly KPI report no later than the tenth (10th) business day of the following month. Failure to meet a service level is not by itself a material breach but is grounds for an after-the-fact service credit determined in good faith by the Parties."));
  c.push(brandRule());

  // ---- 9. TERM, RENEWAL, TERMINATION ----
  c.push(heading1("9. TERM, RENEWAL, AND TERMINATION"));
  c.push(p("9.01. Initial Term. The Initial Term commences on May 1, 2026 and continues for twelve (12) months through April 30, 2027."));
  c.push(spacer());
  c.push(p("9.02. Renewal. Upon expiration of the Initial Term, this SOW shall automatically renew for successive twelve (12) month periods at the then-current Phase 2 monthly fee ($1,550.00 per month at signing), unless either Party provides written notice of non-renewal at least sixty (60) days prior to the expiration of the then-current term. Technijian shall send Client a written renewal reminder at least thirty (30) days prior to each renewal date, restating the auto-renewal terms and the cancellation method."));
  c.push(spacer());
  c.push(p("9.03. Termination for Convenience. Either Party may terminate this SOW for any reason upon sixty (60) days written notice to the other Party. If Client terminates for convenience during the Initial Term, Client shall pay an early termination fee equal to the lesser of (a) the remaining monthly fees through the end of the Initial Term or (b) three (3) months of the then-current monthly fee. The early termination fee constitutes liquidated damages and represents a reasonable estimate of Technijian's anticipated damages from early termination, including committed staffing and unrecoverable third-party content/syndication commitments, and is not a penalty."));
  c.push(spacer());
  c.push(p("9.04. Termination for Cause. Either Party may terminate this SOW immediately upon written notice if the other Party (a) commits a material breach and fails to cure within thirty (30) days of written notice or (b) becomes insolvent, files for bankruptcy, or has a receiver appointed."));
  c.push(spacer());
  c.push(p("9.05. Effect of Termination. Upon termination for any reason, all fees and charges for services rendered through the date of termination, plus any early termination fee under Section 9.03, become immediately due and payable. Technijian shall transfer to Client (or Client's designee) within five (5) business days of termination all administrative credentials, root/owner accounts, DNS zone control, domain registrar access, hosting account access, and any other Operational Continuity Materials Client requires to maintain its digital presence, regardless of any unpaid balance. Technijian may retain a lien on Technijian-produced deliverables (other than Operational Continuity Materials and Client Data) until all amounts owed are paid."));
  c.push(brandRule());

  // ---- 10. GOVERNING TERMS ----
  c.push(heading1("10. GOVERNING TERMS"));
  c.push(p("10.01. No Master Service Agreement is currently in effect between the Parties. This SOW is a standalone engagement governed by the Technijian Standard Terms and Conditions and the following minimum terms:"));
  c.push(spacer());
  c.push(multiRun([
    { text: "(a) Limitation of Liability. ", bold: true, color: CHARCOAL },
    { text: "Neither Party's total aggregate liability under this SOW shall exceed the total fees paid or payable under this SOW in the six (6) months preceding the claim." }
  ], { indent: { left: 360 } }));
  c.push(spacer());
  c.push(multiRun([
    { text: "(b) Excluded Damages. ", bold: true, color: CHARCOAL },
    { text: "In no event shall either Party be liable for indirect, incidental, special, consequential, or punitive damages, including but not limited to lost profits, lost investors, lost capital commitments, or lost business opportunity." }
  ], { indent: { left: 360 } }));
  c.push(spacer());
  c.push(multiRun([
    { text: "(c) Governing Law and Forum. ", bold: true, color: CHARCOAL },
    { text: "This SOW shall be governed by the laws of the State of California, without regard to conflict-of-laws principles. Any dispute shall be resolved by binding arbitration in Orange County, California, under the AAA Commercial Arbitration Rules, except that either Party may seek injunctive relief in court for protection of intellectual property or confidential information." }
  ], { indent: { left: 360 } }));
  c.push(spacer());
  c.push(multiRun([
    { text: "(d) Confidentiality. ", bold: true, color: CHARCOAL },
    { text: "Each Party shall keep the other's confidential information (including pricing, business plans, content drafts, keyword strategies, performance data, and investor information) strictly confidential during the engagement and for three (3) years thereafter. The Parties acknowledge that they have separately executed a Mutual Non-Disclosure Agreement covering the broader business relationship; the terms of that NDA are incorporated by reference and shall control to the extent of any conflict with this Section 10.01(d)." }
  ], { indent: { left: 360 } }));
  c.push(spacer());
  c.push(multiRun([
    { text: "(e) Intellectual Property. ", bold: true, color: CHARCOAL },
    { text: "Client retains ownership of all Client Data, the production website, all content published under VWC's name, and all Knowledge Panel and Google Business Profile assets. Technijian retains ownership of its pre-existing tools, methodologies, templates, and proprietary processes. Client receives a perpetual, royalty-free, non-exclusive, non-transferable license to use the deliverables and configurations produced under this SOW for its internal business purposes. Technijian may use general learnings, anonymized benchmarks, and case-study results (without Client name, financial data, or investor information) in its own marketing materials." }
  ], { indent: { left: 360 } }));
  c.push(spacer());
  c.push(multiRun([
    { text: "(f) Compliance Disclaimer. ", bold: true, color: CHARCOAL },
    { text: "Technijian is not a law firm, is not a registered investment adviser, and is not providing legal, tax, compliance, or investment advice. Client is solely responsible for obtaining outside compliance counsel review of any content, claim, testimonial, or representation triggering SEC Marketing Rule 206(4)-1, FINRA Rule 2210, or state securities-law obligations." }
  ], { indent: { left: 360 } }));
  c.push(spacer());
  c.push(p("10.02. If the Parties subsequently execute a Master Service Agreement, the terms of the MSA shall govern and supersede this Section 10 to the extent of any conflict."));
  c.push(brandRule());

  // ---- SIGNATURES (with hidden DocuSign anchors) ----
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

  // ===== BUILD DOCUMENT =====
  const doc = new Document({
    styles: docStyles,
    numbering,
    sections: [
      {
        properties: coverSectionProps(),
        children: coverPage(
          "Statement of Work",
          "My SEO Program — Validation SEO for VisionWise Capital, LLC"
        )
      },
      {
        properties: contentSectionProps(),
        children: c
      }
    ]
  });

  const buffer = await Packer.toBuffer(doc);
  const outputPath = path.join(__dirname, "..", "03_SOW", "SOW-VWC-002-SEO.docx");
  fs.writeFileSync(outputPath, buffer);
  console.log("Generated:", outputPath);
}

generateSOW().catch(err => {
  console.error("Error generating SOW:", err);
  process.exit(1);
});
