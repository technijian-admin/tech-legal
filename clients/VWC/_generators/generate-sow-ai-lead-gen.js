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
        level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 720, hanging: 360 } } }
      }]
    },
    {
      reference: "bullets2",
      levels: [{
        level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 720, hanging: 360 } } }
      }]
    },
    {
      reference: "bullets3",
      levels: [{
        level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 720, hanging: 360 } } }
      }]
    },
    {
      reference: "bullets4",
      levels: [{
        level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 720, hanging: 360 } } }
      }]
    },
    {
      reference: "bullets5",
      levels: [{
        level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT,
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
  items.push(p("April 24, 2026", { size: 22, color: GREY, alignment: AlignmentType.CENTER, spacing: { after: 200 } }));
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

// ===== GENERATE SOW =====
async function generateSOW() {
  const content = [];

  // ---- SOW Header ----
  content.push(heading1("STATEMENT OF WORK"));
  content.push(multiRun([
    { text: "SOW Number: ", bold: true, color: CHARCOAL },
    { text: "SOW-VWC-001-AI-Lead-Gen" }
  ]));
  content.push(multiRun([
    { text: "Effective Date: ", bold: true, color: CHARCOAL },
    { text: "April 24, 2026" }
  ]));
  content.push(multiRun([
    { text: "Master Service Agreement: ", bold: true, color: CHARCOAL },
    { text: "None (standalone SOW — Technijian Standard Terms and Conditions apply)" }
  ]));
  content.push(spacer());
  content.push(p("This Statement of Work (“SOW”) is entered into by and between:"));
  content.push(spacer());
  content.push(p("Technijian, Inc. (“Technijian”)", { bold: true, color: CHARCOAL }));
  content.push(p("18 Technology Drive, Suite 141"));
  content.push(p("Irvine, California 92618"));
  content.push(spacer());
  content.push(p("and"));
  content.push(spacer());
  content.push(p("VisionWise Capital, LLC (“Client” or “VWC”)", { bold: true, color: CHARCOAL }));
  content.push(p("27525 Puerta Real, Suite 300-164"));
  content.push(p("Mission Viejo, California 92691"));
  content.push(spacer());
  content.push(multiRun([{ text: "Primary Contact: ", bold: true, color: CHARCOAL }, { text: "Sanford Coggins, Founder (info@visionwisecapital.com)" }]));
  content.push(brandRule());

  // ---- 1. PROJECT OVERVIEW ----
  content.push(heading1("1. PROJECT OVERVIEW"));

  content.push(heading2("1.1 Project Title"));
  content.push(p("AI / CTO Advisory — AI-Driven Lead Generation System Design and Build"));
  content.push(spacer());

  content.push(heading2("1.2 Project Description"));
  content.push(p("VisionWise Capital, LLC (“VWC”) is a Southern California commercial real estate investment firm specializing in the acquisition, renovation, and management of multifamily properties on behalf of accredited investors, Registered Investment Advisors (RIAs), and high-net-worth individuals. VWC’s growth is directly tied to its ability to identify and engage qualified accredited investors and RIA partners."));
  content.push(spacer());
  content.push(p("Technijian will provide AI / CTO Advisory services to design and build an AI-powered lead generation system that automates investor prospecting, enriches and scores leads, personalizes outreach, and routes qualified prospects into VWC’s sales workflow. The engagement is billed on a time-and-materials (“T&M”) basis at Technijian’s published CTO Advisory rate. As a relationship-building courtesy, the first two (2) hours of engagement are provided at no charge; all hours thereafter are billed at the rate specified in Section 5.1."));
  content.push(spacer());
  content.push(p("The scope and pace of work will be directed by Client. Either Party may pause or conclude the engagement at any time with written notice, with payment due only for hours actually performed beyond the two (2) no-charge hours."));
  content.push(spacer());

  content.push(heading2("1.3 Locations"));
  content.push(makeTable(
    ["Location Name", "Code", "Address", "Billable"],
    [["VWC - Headquarters", "VWC-HQ", "27525 Puerta Real, Ste 300-164, Mission Viejo, CA 92691", "Yes"]],
    [2340, 1400, 4060, 1560]
  ));
  content.push(spacer());
  content.push(p("All work shall be performed remotely unless both Parties agree in writing that on-site presence is required for a specific session. On-site meetings, if requested, shall be billed in accordance with Section 5.1."));
  content.push(brandRule());

  // ---- 2. SCOPE OF WORK ----
  content.push(heading1("2. SCOPE OF WORK"));

  content.push(heading2("2.1 In Scope"));
  content.push(p("Technijian will provide the following AI / CTO Advisory services on a T&M basis:"));
  content.push(spacer());
  content.push(bullet("Discovery and Strategy — Working sessions with VWC leadership to define target personas (accredited investors, RIAs, family offices), total addressable market, channel mix, success metrics, and compliance guardrails for investor outreach (SEC Rule 506(b)/506(c), CAN-SPAM, TCPA, state solicitation rules).", "bullets"));
  content.push(bullet("Architecture and Tool Selection — Design of the AI lead generation stack, including LLM selection, data sources, enrichment providers (e.g., Clay, Apollo, ZoomInfo, LinkedIn), CRM integration (HubSpot, Salesforce, Pipedrive, or equivalent), and orchestration tooling (n8n, Make, Zapier, or custom).", "bullets"));
  content.push(bullet("Data Pipeline and Enrichment — Build or configure ingestion and enrichment pipelines that pull prospective investor and RIA data, normalize records, and attach firmographic / demographic / wealth-screening attributes.", "bullets"));
  content.push(bullet("AI Scoring and Qualification — Implement an LLM-assisted lead scoring model that ranks prospects by fit and likelihood to engage, including reasoning summaries a human reviewer can audit.", "bullets"));
  content.push(bullet("Personalized Outreach — Build AI-generated, persona-aware email and LinkedIn outreach sequences with human-in-the-loop approval. Includes sender warm-up guidance, deliverability checks (SPF/DKIM/DMARC), and suppression list management.", "bullets"));
  content.push(bullet("CRM and Workflow Integration — Push qualified, scored leads into VWC’s CRM with full provenance, scoring rationale, and next-best-action recommendations.", "bullets"));
  content.push(bullet("Dashboards and Reporting — KPI dashboard (pipeline velocity, reply rate, meetings booked, SQL-to-investor conversion) for leadership visibility.", "bullets"));
  content.push(bullet("Knowledge Transfer — Documentation, runbooks, and training sessions so VWC staff can operate and evolve the system independently after go-live.", "bullets"));
  content.push(bullet("Ongoing CTO Advisory (optional) — On request, Technijian will continue to provide fractional CTO / AI advisory support on a T&M basis after initial build-out.", "bullets"));
  content.push(spacer());

  content.push(heading2("2.2 Out of Scope"));
  content.push(p("The following items are expressly excluded from this SOW unless added by written Change Order:"));
  content.push(spacer());
  content.push(bullet("Investment decisions, solicitation of investors, or any activity requiring a securities license.", "bullets2"));
  content.push(bullet("Compliance opinions or legal counsel regarding SEC, FINRA, or state securities laws. Technijian will flag obvious compliance considerations, but Client is responsible for engaging qualified securities counsel.", "bullets2"));
  content.push(bullet("Content creation beyond templates and examples (e.g., full marketing campaigns, whitepapers, thought-leadership content).", "bullets2"));
  content.push(bullet("Purchase of third-party software licenses, enrichment data, LLM API usage, or CRM seats. These are procured by and billed directly to Client unless Client expressly authorizes Technijian to procure on its behalf.", "bullets2"));
  content.push(bullet("Sending outreach at scale without Client review and authorization for each campaign.", "bullets2"));
  content.push(bullet("Web development, branding, or graphic design services.", "bullets2"));
  content.push(bullet("Any work requiring access to Client’s investor records, subscription documents, or other regulated non-public personal information (“NPI”) except as strictly necessary for this engagement and governed by a separate data processing / NDA agreement.", "bullets2"));
  content.push(bullet("24x7 system monitoring, production incident response, or managed services (available under a separate Technijian MSA / Managed Services SOW).", "bullets2"));
  content.push(spacer());

  content.push(heading2("2.3 Assumptions"));
  content.push(bullet("The engagement begins with the two (2) no-charge hours, which will be used for an initial discovery session. No obligation on either Party is created until Client authorizes billable hours in writing (email is sufficient).", "bullets3"));
  content.push(bullet("Client will designate a single empowered point of contact (default: Sanford Coggins) with authority to approve scope, spend, vendor selection, and go-live of outreach campaigns.", "bullets3"));
  content.push(bullet("Client will procure and pay for all third-party services directly (LLM APIs, enrichment providers, CRM, email sending infrastructure). Technijian will recommend; Client will purchase.", "bullets3"));
  content.push(bullet("Any outreach generated by the system will be reviewed and approved by Client before being sent. Client is solely responsible for the legality and content of all outbound communications to prospects.", "bullets3"));
  content.push(bullet("Technijian’s work product is delivered “as-is” and without warranty beyond what is stated in Section 9 and the Technijian Standard Terms and Conditions.", "bullets3"));
  content.push(bullet("Time will be tracked and reported in 15-minute increments.", "bullets3"));
  content.push(brandRule());

  // ---- 3. PROJECT PHASES ----
  content.push(heading1("3. PROJECT PHASES"));
  content.push(p("The engagement is organized into five (5) phases. Because this is a T&M engagement directed by Client, hour estimates below are planning estimates only; Technijian will bill for actual time at the rate in Section 5.1 and will notify Client before exceeding any estimate by more than 10%."));
  content.push(spacer());

  // Phase 1
  content.push(heading2("Phase 1: Discovery & Strategy (No-Charge + T&M)"));
  content.push(heading3("3.1.1 Description"));
  content.push(p("Initial working sessions with Client leadership to understand VWC’s investor profile, current sales motion, growth targets, compliance posture, existing tools, and budget constraints. The first two (2) hours of this phase are provided at no charge. If Client elects to continue, subsequent hours are billed at the rate in Section 5.1."));
  content.push(spacer());
  content.push(heading3("3.1.2 Deliverables"));
  content.push(bullet("Discovery notes and a one-page AI Lead Gen strategy brief.", "bullets4"));
  content.push(bullet("Target persona definitions (accredited investor, RIA partner, family office).", "bullets4"));
  content.push(bullet("Recommended channel mix and success metrics.", "bullets4"));
  content.push(bullet("Preliminary tool short-list and rough cost-of-ownership estimate.", "bullets4"));
  content.push(spacer());
  content.push(heading3("3.1.3 Schedule"));
  content.push(makeTable(
    ["Role", "Description", "Est. Hours", "Timeline", "Resource"],
    [
      ["CTO Advisory", "Initial discovery session (no-charge)", "2.0", "Week 1", "Ravi Jain"],
      ["CTO Advisory", "Strategy brief and persona definitions", "2.0", "Week 1-2", "Ravi Jain"],
      ["", { text: "Total", bold: true }, { text: "4.0", bold: true }, "", ""]
    ],
    [1700, 3800, 1200, 1400, 1260]
  ));
  content.push(spacer());

  // Phase 2
  content.push(heading2("Phase 2: Architecture & Tool Selection (T&M)"));
  content.push(heading3("3.2.1 Description"));
  content.push(p("Design the end-to-end AI lead generation architecture and recommend a specific vendor stack. Client retains final approval authority on all third-party purchases."));
  content.push(spacer());
  content.push(heading3("3.2.2 Deliverables"));
  content.push(bullet("Architecture diagram (data sources → enrichment → scoring → outreach → CRM → reporting).", "bullets5"));
  content.push(bullet("Vendor recommendation memo with cost, pros/cons, and compliance notes.", "bullets5"));
  content.push(bullet("Prioritized build backlog.", "bullets5"));
  content.push(spacer());
  content.push(heading3("3.2.3 Schedule"));
  content.push(makeTable(
    ["Role", "Description", "Est. Hours", "Timeline", "Resource"],
    [
      ["CTO Advisory", "Architecture design and vendor short-list", "4.0", "Week 2-3", "Ravi Jain"],
      ["CTO Advisory", "Client review and backlog prioritization", "2.0", "Week 3", "Ravi Jain"],
      ["", { text: "Total", bold: true }, { text: "6.0", bold: true }, "", ""]
    ],
    [1700, 3800, 1200, 1400, 1260]
  ));
  content.push(spacer());

  // Phase 3
  content.push(heading2("Phase 3: Build & Integration (T&M)"));
  content.push(heading3("3.3.1 Description"));
  content.push(p("Stand up the data ingestion, enrichment, AI scoring, and outreach components and wire them into Client’s CRM. Work is delivered iteratively with weekly demos."));
  content.push(spacer());
  content.push(heading3("3.3.2 Deliverables"));
  content.push(bullet("Data ingestion and enrichment pipeline configured against selected sources.", "bullets"));
  content.push(bullet("LLM-based lead scoring model with audit-ready rationale output.", "bullets"));
  content.push(bullet("AI-generated outreach sequences with human-in-the-loop review UI.", "bullets"));
  content.push(bullet("CRM integration (bi-directional) with scored lead records.", "bullets"));
  content.push(bullet("KPI dashboard.", "bullets"));
  content.push(spacer());
  content.push(heading3("3.3.3 Schedule"));
  content.push(makeTable(
    ["Role", "Description", "Est. Hours", "Timeline", "Resource"],
    [
      ["CTO Advisory", "Pipeline, enrichment, and scoring build", "10.0", "Week 3-5", "Ravi Jain"],
      ["CTO Advisory", "Outreach automation and CRM integration", "8.0", "Week 5-7", "Ravi Jain"],
      ["CTO Advisory", "KPI dashboard build", "3.0", "Week 7", "Ravi Jain"],
      ["", { text: "Total", bold: true }, { text: "21.0", bold: true }, "", ""]
    ],
    [1700, 3800, 1200, 1400, 1260]
  ));
  content.push(spacer());

  // Phase 4
  content.push(heading2("Phase 4: Pilot, Tuning & Go-Live (T&M)"));
  content.push(heading3("3.4.1 Description"));
  content.push(p("Run a controlled pilot against a small approved prospect list, tune scoring thresholds and outreach copy based on results, then authorize broader rollout."));
  content.push(spacer());
  content.push(heading3("3.4.2 Deliverables"));
  content.push(bullet("Pilot results report (reply rate, meetings booked, false-positive rate).", "bullets2"));
  content.push(bullet("Tuned scoring thresholds and outreach templates.", "bullets2"));
  content.push(bullet("Go-live checklist and rollout plan.", "bullets2"));
  content.push(spacer());
  content.push(heading3("3.4.3 Schedule"));
  content.push(makeTable(
    ["Role", "Description", "Est. Hours", "Timeline", "Resource"],
    [
      ["CTO Advisory", "Pilot run and analysis", "4.0", "Week 8", "Ravi Jain"],
      ["CTO Advisory", "Tuning and go-live enablement", "3.0", "Week 9", "Ravi Jain"],
      ["", { text: "Total", bold: true }, { text: "7.0", bold: true }, "", ""]
    ],
    [1700, 3800, 1200, 1400, 1260]
  ));
  content.push(spacer());

  // Phase 5
  content.push(heading2("Phase 5: Knowledge Transfer (T&M)"));
  content.push(heading3("3.5.1 Description"));
  content.push(p("Document the system and train Client’s designated operators so VWC can run and evolve the system without Technijian."));
  content.push(spacer());
  content.push(heading3("3.5.2 Deliverables"));
  content.push(bullet("Operator runbook.", "bullets3"));
  content.push(bullet("Architecture reference document.", "bullets3"));
  content.push(bullet("Recorded training session(s).", "bullets3"));
  content.push(spacer());
  content.push(heading3("3.5.3 Schedule"));
  content.push(makeTable(
    ["Role", "Description", "Est. Hours", "Timeline", "Resource"],
    [
      ["CTO Advisory", "Documentation and runbooks", "2.0", "Week 9-10", "Ravi Jain"],
      ["CTO Advisory", "Training session(s)", "2.0", "Week 10", "Ravi Jain"],
      ["", { text: "Total", bold: true }, { text: "4.0", bold: true }, "", ""]
    ],
    [1700, 3800, 1200, 1400, 1260]
  ));
  content.push(spacer());

  // Ongoing Advisory
  content.push(heading2("Ongoing Advisory (Optional — T&M)"));
  content.push(p("After Phase 5, Client may request continued fractional CTO / AI advisory support on an as-needed basis. There is no minimum commitment and no retainer; hours are billed only when performed, at the rate in Section 5.1."));
  content.push(spacer());
  content.push(p("Typical activities: periodic strategy reviews, new model evaluations, vendor renegotiations, outreach copy refresh, dashboard updates, and coaching Client staff on AI best practices."));
  content.push(brandRule());

  // ---- 4. EQUIPMENT AND MATERIALS ----
  content.push(heading1("4. EQUIPMENT AND MATERIALS"));
  content.push(p("No hardware or equipment is supplied under this SOW. Third-party software, data, and API subscriptions required to operate the lead generation system (LLM APIs, enrichment providers, CRM, sending infrastructure) are procured by and paid directly by Client."));
  content.push(brandRule());

  // ---- 5. PRICING AND PAYMENT ----
  content.push(heading1("5. PRICING AND PAYMENT"));

  content.push(heading2("5.1 Rate Card"));
  content.push(makeTable(
    ["Role", "Location", "Rate"],
    [
      ["CTO / AI Advisory (Ravi Jain)", "US (Remote)", "$250.00 / hr"],
      ["After-Hours Premium (weekends, holidays, or after 6:00 PM Pacific)", "US (Remote)", "$350.00 / hr"]
    ],
    [4800, 2200, 2360]
  ));
  content.push(spacer());
  content.push(p("Rates are fixed for the term of this engagement. Any rate changes require a written Change Order signed by both Parties."));
  content.push(spacer());

  content.push(heading2("5.2 Introductory No-Charge Hours"));
  content.push(multiRun([
    { text: "The first two (2.0) billable-eligible hours ", bold: true, color: CHARCOAL },
    { text: "of engagement are provided at " },
    { text: "no charge ", bold: true, color: CHARCOAL },
    { text: "as a relationship-building courtesy. These hours will typically be consumed during the Phase 1 discovery session. No-charge hours are not refundable, not transferable, and not cumulative; if the engagement concludes within the first two hours, no invoice will be issued." }
  ]));
  content.push(spacer());

  content.push(heading2("5.3 Summary of Costs (Planning Estimate Only)"));
  content.push(makeTable(
    ["Phase", "Type", "Est. Hours", "Rate", "Cost"],
    [
      ["Phase 1 — Discovery (no-charge portion)", "Credit", "2.0", "$0.00", "$0.00"],
      ["Phase 1 — Discovery (billable portion)", "Estimate", "2.0", "$250.00", "$500.00"],
      ["Phase 2 — Architecture & Tool Selection", "Estimate", "6.0", "$250.00", "$1,500.00"],
      ["Phase 3 — Build & Integration", "Estimate", "21.0", "$250.00", "$5,250.00"],
      ["Phase 4 — Pilot, Tuning & Go-Live", "Estimate", "7.0", "$250.00", "$1,750.00"],
      ["Phase 5 — Knowledge Transfer", "Estimate", "4.0", "$250.00", "$1,000.00"],
      [{ text: "Estimated Total Project (billable only)", bold: true }, "", { text: "40.0", bold: true }, "", { text: "$10,000.00", bold: true }]
    ],
    [3800, 1500, 1500, 1500, 1060]
  ));
  content.push(spacer());
  content.push(p("Pricing Type Definitions", { bold: true, color: CHARCOAL }));
  content.push(bullet("Estimate Cost. Hours and costs in the table above are good-faith planning estimates. Technijian will bill for actual time performed, at the rate in Section 5.1. If cumulative actual hours are projected to exceed the total estimate by more than 10%, Technijian will notify Client in writing before performing the additional hours.", "bullets4"));
  content.push(bullet("Credit. The two no-charge hours are reflected as a $0.00 credit and will not appear as a line item on any invoice.", "bullets4"));
  content.push(spacer());

  content.push(heading2("5.4 Invoicing and Payment Schedule"));
  content.push(bullet("Technijian will invoice Client bi-weekly (every two weeks) for actual hours performed during the preceding period, itemized by date, duration, phase, and description of work.", "bullets5"));
  content.push(bullet("The first invoice will not be issued until cumulative billable hours exceed the two (2) no-charge hours.", "bullets5"));
  content.push(bullet("All invoices are due and payable within thirty (30) days of the invoice date.", "bullets5"));
  content.push(spacer());

  content.push(heading2("5.5 Payment Terms"));
  content.push(p("All invoices are due and payable within thirty (30) days of the invoice date."));
  content.push(spacer());

  content.push(heading2("5.6 Late Payment and Collection Remedies"));
  content.push(p("Because no MSA is in effect between the Parties, the following standalone provisions apply:"));
  content.push(spacer());
  content.push(multiRun([
    { text: "(a) Late Payment. ", bold: true, color: CHARCOAL },
    { text: "Late payments shall accrue a late fee of 1.5% per month (or the maximum rate permitted by law, whichever is less) on the unpaid balance, calculated as simple interest from the date payment was due. The Parties acknowledge that the late fee represents a reasonable estimate of Technijian’s administrative costs and damages resulting from late payment and is not a penalty." }
  ], { indent: { left: 360 } }));
  content.push(spacer());
  content.push(multiRun([
    { text: "(b) Acceleration. ", bold: true, color: CHARCOAL },
    { text: "If Client fails to pay any undisputed invoice within forty-five (45) days of the due date, all remaining fees under this SOW shall become immediately due and payable." }
  ], { indent: { left: 360 } }));
  content.push(spacer());
  content.push(multiRun([
    { text: "(c) Suspension. ", bold: true, color: CHARCOAL },
    { text: "Technijian may suspend all work under this SOW upon ten (10) days written notice if any invoice remains unpaid beyond the due date. Suspension shall not relieve Client of its payment obligations, and project timelines shall be adjusted accordingly at no cost to Technijian." }
  ], { indent: { left: 360 } }));
  content.push(spacer());
  content.push(multiRun([
    { text: "(d) Collection Costs and Attorney’s Fees. ", bold: true, color: CHARCOAL },
    { text: "In any action or proceeding to collect fees, invoices, or other amounts owed under this SOW, the prevailing Party shall be entitled to recover all reasonable costs of collection, including attorney’s fees (including in-house counsel at market rates), collection agency fees, court costs, arbitration fees, and all costs of appeal. Pursuant to California Civil Code Section 1717, the Parties acknowledge that this attorney’s fees provision is reciprocal. This fee-shifting applies exclusively to collection of amounts owed and does not apply to disputes regarding service quality, professional performance, or other non-payment claims." }
  ], { indent: { left: 360 } }));
  content.push(spacer());
  content.push(multiRun([
    { text: "(e) Lien on Work Product. ", bold: true, color: CHARCOAL },
    { text: "Technijian shall retain a lien on all deliverables, work product, documentation, and materials (excluding Client Data) under this SOW until all amounts owed are paid in full." }
  ], { indent: { left: 360 } }));
  content.push(spacer());
  content.push(multiRun([
    { text: "(f) Fees for Non-Collection Disputes. ", bold: true, color: CHARCOAL },
    { text: "Except as provided in subsection (d) above, in any dispute arising under this SOW relating to service quality, professional performance, scope, or any other non-payment matter, each Party shall bear its own attorney’s fees and costs." }
  ], { indent: { left: 360 } }));
  content.push(brandRule());

  // ---- 6. CLIENT RESPONSIBILITIES ----
  content.push(heading1("6. CLIENT RESPONSIBILITIES"));
  content.push(p("Client shall:"));
  content.push(spacer());
  content.push(p("(a) Provide access to systems, tools, and personnel reasonably required for Technijian to perform the work (e.g., CRM admin access, LLM vendor accounts, sample prospect data);", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(b) Designate a single empowered point of contact (default: Sanford Coggins) authorized to approve scope, spend, vendor selection, and outreach campaigns;", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(c) Review and approve deliverables, vendor recommendations, and outreach campaigns within five (5) business days of submission;", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(d) Procure and pay for all third-party services directly (LLM APIs, enrichment data, CRM, sending infrastructure);", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(e) Ensure that all outreach content is compliant with applicable law (SEC Rule 506(b)/506(c), CAN-SPAM, TCPA, state solicitation rules) prior to send. Client acknowledges that Technijian is not a law firm and is not providing legal or compliance advice;", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(f) Not use the lead generation system, or any output thereof, for any activity requiring a securities license unless Client (or a licensed affiliate) holds the requisite license; and", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(g) Inform internal stakeholders of any system changes that affect their workflow.", { indent: { left: 360 } }));
  content.push(brandRule());

  // ---- 7. CHANGE MANAGEMENT ----
  content.push(heading1("7. CHANGE MANAGEMENT"));
  content.push(p("7.01. Because this is a T&M engagement, Client may expand, narrow, or redirect scope at any time by written instruction (email is sufficient). Changes that materially alter the rate, total estimate, or assumptions in this SOW require a written Change Order signed by both Parties before the changed work begins."));
  content.push(spacer());
  content.push(p("7.02. If Client requests work that in Technijian’s reasonable judgment exceeds the skill mix or rate card of this SOW (e.g., custom software engineering beyond integration work), Technijian shall provide a Change Order detailing the additional role(s), rate(s), and estimated impact."));
  content.push(spacer());
  content.push(p("7.03. Technijian shall not perform work that would exceed the estimate in Section 5.3 by more than 10% without notifying Client in advance, except in cases where delay would cause imminent harm to Client’s systems, in which case Technijian may perform emergency work not to exceed $2,500 (at the Section 5.1 rate) and shall notify Client as soon as practicable, with a retrospective Change Order within three (3) business days."));
  content.push(brandRule());

  // ---- 8. ACCEPTANCE ----
  content.push(heading1("8. ACCEPTANCE"));
  content.push(p("8.01. Upon completion of each deliverable listed in Section 3, Technijian shall notify Client in writing that the deliverable is ready for review."));
  content.push(spacer());
  content.push(p("8.02. Client shall review the deliverable and provide written acceptance or a detailed description of deficiencies within five (5) business days of submission. Technijian’s delivery notification shall include a conspicuous statement: “If you do not respond within five (5) business days, this deliverable will be deemed accepted per SOW Section 8.03.”"));
  content.push(spacer());
  content.push(p("8.03. If Client does not respond within the review period, the deliverable shall be deemed accepted."));
  content.push(spacer());
  content.push(p("8.04. If deficiencies are identified, Technijian shall correct them and resubmit for review. This process shall repeat until acceptance is achieved or the Parties agree on a resolution."));
  content.push(brandRule());

  // ---- 9. GOVERNING TERMS ----
  content.push(heading1("9. GOVERNING TERMS"));
  content.push(p("9.01. No Master Service Agreement is currently in effect between the Parties. This SOW is a standalone engagement governed by the Technijian Standard Terms and Conditions (Appendix A, if attached) and the following minimum terms:"));
  content.push(spacer());
  content.push(p("(a) Neither Party’s total aggregate liability under this SOW shall exceed the total fees paid or payable under this SOW in the six (6) months preceding the claim.", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(b) In no event shall either Party be liable for indirect, incidental, special, consequential, or punitive damages, including but not limited to lost profits, lost investors, or lost business opportunity.", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(c) This SOW shall be governed by the laws of the State of California, without regard to conflict-of-laws principles. Any dispute shall be resolved by binding arbitration in Orange County, California, under the AAA Commercial Arbitration Rules, except that either Party may seek injunctive relief in court for protection of intellectual property or confidential information.", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(d) Each Party shall keep the other’s confidential information (including pricing, business plans, and investor data) strictly confidential during the engagement and for three (3) years thereafter.", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(e) Client retains ownership of all Client Data. Technijian retains ownership of its pre-existing tools, methodologies, and templates. Client receives a perpetual, non-exclusive license to use the deliverables and configurations produced under this SOW for its internal business purposes.", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("9.02. If the Parties subsequently execute a Master Service Agreement, the terms of the MSA shall govern and supersede this Section 9 to the extent of any conflict."));
  content.push(brandRule());

  // ---- SIGNATURES ----
  content.push(heading1("SIGNATURES"));
  content.push(spacer());
  content.push(p("TECHNIJIAN, INC.", { bold: true, color: CHARCOAL }));
  content.push(spacer());
  content.push(p("By: ___________________________________"));
  content.push(spacer());
  content.push(p("Name: Ravi Jain"));
  content.push(spacer());
  content.push(p("Title: Chief Executive Officer"));
  content.push(spacer());
  content.push(p("Date: _________________________________"));
  content.push(spacer());
  content.push(spacer());
  content.push(p("VISIONWISE CAPITAL, LLC", { bold: true, color: CHARCOAL }));
  content.push(spacer());
  content.push(p("By: ___________________________________"));
  content.push(spacer());
  content.push(p("Name: Sanford Coggins"));
  content.push(spacer());
  content.push(p("Title: Founder"));
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
          "AI / CTO Advisory — AI Lead Generation System — VisionWise Capital, LLC"
        )
      },
      {
        properties: contentSectionProps(),
        children: content
      }
    ]
  });

  const buffer = await Packer.toBuffer(doc);
  const outputPath = path.join(__dirname, "..", "03_SOW", "SOW-VWC-001-AI-Lead-Gen.docx");
  fs.writeFileSync(outputPath, buffer);
  console.log("Generated:", outputPath);
}

generateSOW().catch(err => {
  console.error("Error generating SOW:", err);
  process.exit(1);
});
