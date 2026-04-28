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
  items.push(p("April 28, 2026", { size: 22, color: GREY, alignment: AlignmentType.CENTER, spacing: { after: 200 } }));
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
    { text: "SOW-BBC-001-AutoLeadGen-Build" }
  ]));
  content.push(multiRun([
    { text: "Effective Date: ", bold: true, color: CHARCOAL },
    { text: "April 28, 2026" }
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
  content.push(p("Burkhart Brothers Construction (“Client” or “BBC”)", { bold: true, color: CHARCOAL }));
  content.push(p("Orange County, California"));
  content.push(p("[Full address to be confirmed at signature]"));
  content.push(spacer());
  content.push(multiRun([{ text: "Primary Contact: ", bold: true, color: CHARCOAL }, { text: "Bryan Burkhart (bryan@burkhartbros.com, 310-704-8467)" }]));
  content.push(brandRule());

  // ---- 1. PROJECT OVERVIEW ----
  content.push(heading1("1. PROJECT OVERVIEW"));

  content.push(heading2("1.1 Project Title"));
  content.push(p("Autonomous Lead Generation System — Implementation Phase (VM-Hosted Claude Code Agent)"));
  content.push(spacer());

  content.push(heading2("1.2 Project Description"));
  content.push(p("Burkhart Brothers Construction (“BBC”) is a Southern California luxury custom home builder serving Orange County’s coastal HOA communities. BBC’s growth is directly tied to the ability to identify owners and architects of permitted projects and recently sold luxury properties before competitors do."));
  content.push(spacer());
  content.push(p("This SOW covers the Implementation Phase of the Autonomous Lead Generation System defined in the BBC System Specification (March 2026, v1.0). The system replaces Kurtis Burkhart’s manual workflow of reading DRB agendas, scanning city permit portals, and watching just-sold listings with an autonomous pipeline that runs on a schedule and emails a tiered lead report to BBC every Sunday morning."));
  content.push(spacer());
  content.push(multiRun([
    { text: "Architectural approach. ", bold: true, color: CHARCOAL },
    { text: "Rather than building a bespoke “AI supervisor” from scratch, the system is built around an automated " },
    { text: "Claude Code agent running on a Technijian-hosted Windows virtual machine", bold: true, color: CHARCOAL },
    { text: ". Claude Code orchestrates the scrapers, diagnoses failures, re-runs failed steps, applies the client-fit scoring engine, drives the contact enrichment APIs, and produces the weekly branded report. Windows Task Scheduler triggers Claude Code on the cadence defined in Section 3 (city permits weekly, just-sold daily, DRB on-meeting, full digest Sunday 10:00 AM Pacific). All credentials live in a .env vault on the VM, never in source control." }
  ]));
  content.push(spacer());
  content.push(multiRun([
    { text: "Engagement model. ", bold: true, color: CHARCOAL },
    { text: "This is a fixed-scope, T&M-billed engagement. The hour estimates in Section 3 are good-faith planning estimates; Technijian will bill for actual time at the rates in Section 5.1 and will notify Client in writing before any phase exceeds its estimate by more than 10%. Of the 80 estimated hours, " },
    { text: "70 hours are development work split between US-based senior development (30 hours) and offshore development (40 hours)", bold: true, color: CHARCOAL },
    { text: ", and " },
    { text: "10 hours are CTO oversight", bold: true, color: CHARCOAL },
    { text: " (architecture, integration, deployment, calibration)." }
  ]));
  content.push(spacer());
  content.push(multiRun([
    { text: "Operational scope. ", bold: true, color: CHARCOAL },
    { text: "This SOW also covers the recurring monthly infrastructure required to run the system in production (see Section 3.10 and Section 5.3). The recurring operations period commences on the first day of Week 1 and runs for an initial twelve (12) month term from Final Acceptance, auto-renewing month-to-month thereafter under Section 5.7." }
  ]));
  content.push(spacer());

  content.push(heading2("1.3 Locations"));
  content.push(makeTable(
    ["Location Name", "Code", "Address", "Billable"],
    [
      ["BBC — Headquarters", "BBC-HQ", "Orange County, CA", "No"],
      ["Technijian Cloud — VM Host", "TECH-VM", "Technijian Data Center, Irvine, CA", "No"]
    ],
    [2340, 1400, 4060, 1560]
  ));
  content.push(spacer());
  content.push(p("All work shall be performed remotely. The Claude Code agent runs on a Technijian-hosted VM in the Irvine data center; no on-site presence at BBC is required."));
  content.push(brandRule());

  // ---- 2. SCOPE OF WORK ----
  content.push(heading1("2. SCOPE OF WORK"));

  content.push(heading2("2.1 In Scope"));
  content.push(p("Technijian will deliver the complete autonomous lead generation pipeline as defined in the BBC System Specification, with the following architectural changes from the original spec:"));
  content.push(spacer());
  content.push(bullet("VM-hosted Claude Code agent. A Windows Server VM (Technijian Cloud Tier 4: 4 vCore / 16 GB RAM) is provisioned, configured with Node.js 18+, Playwright, and the Claude Code CLI, and runs Claude Code in headless / scheduled mode as the orchestrator and supervisor for the entire pipeline. VM hosting is procured under a separate monthly Service Order at the rates in Section 5.4.", "bullets"));
  content.push(bullet("Six (6) scraper / pipeline phases as defined in Section 3, building on the 16 hours of foundational work already completed (9 city permit scrapers, the client-fit scoring engine, the OC Assessor API integration, and the Technijian-branded DOCX report generator).", "bullets"));
  content.push(bullet("Schedule-based execution. Windows Task Scheduler triggers the Claude Code agent on the cadence in the spec: city permits weekly (Sun 6 AM), DRB on each meeting (daily check), just-sold Mon-Fri 7 AM, CDP weekly, contact enrichment after each scrape, weekly report Sunday 10 AM.", "bullets"));
  content.push(bullet("Resilience. Claude Code monitors scraper health, captures structured logs, re-runs failed scrapers automatically, and sends a failure-notification email to a Technijian operator if a recovery attempt fails twice in a row.", "bullets"));
  content.push(bullet("Weekly delivery. Branded DOCX report (Tier 1 / Tier 2 / Tier 3 leads), CSV export for CRM import, JSON export for downstream consumers, and an HTML email summary delivered to Kurtis Burkhart via Microsoft 365.", "bullets"));
  content.push(bullet("Knowledge transfer. Operator runbook, Claude Code agent prompt and tool configuration, deployment notes, and a 60-minute walkthrough session.", "bullets"));
  content.push(bullet("Recurring operations. Monthly Technijian-hosted Windows Server VM, image backup, and health monitoring required to run the autonomous agent in production, billed per Section 5.3 for the term defined in Section 5.7.", "bullets"));
  content.push(spacer());

  content.push(heading2("2.2 Out of Scope"));
  content.push(p("The following items are expressly excluded from this SOW unless added by written Change Order:"));
  content.push(spacer());
  content.push(bullet("The Alpha feasibility phase (10 CTO hours). Alpha is assumed complete or covered under a separate engagement; this SOW covers only the Implementation Phase.", "bullets2"));
  content.push(bullet("The future Web Application phase described in the BBC System Specification (live map view, CRM features, multi-user access, self-service config). That phase is offered as a separate engagement after the pipeline is operational and validated.", "bullets2"));
  content.push(bullet("Building or maintaining BBC’s CRM. The pipeline produces CSV / JSON exports BBC can import into its CRM of choice.", "bullets2"));
  content.push(bullet("Outbound calls, emails, or any direct outreach to leads. The system identifies and scores leads; BBC’s sales team makes the contact.", "bullets2"));
  content.push(bullet("Any work requiring access to BBC’s personal contacts, vendor lists, financial records, or other confidential business data.", "bullets2"));
  content.push(bullet("Third-party service costs: Spokeo, Apollo.io, OC Assessor API quotas beyond the free tier, and any Microsoft 365 license uplift. These are procured by and billed directly to Client (or, where Technijian fronts the cost, reimbursed at cost plus a 10% administrative markup). Anthropic API tokens powering the Claude Code agent are Client-procured (BYOK) for Phase 1 operations; Technijian’s forthcoming Chat.AI subscription will be available as an optional no-charge migration in Phase 2 (see Section 3.10).", "bullets2"));
  content.push(bullet("Hardware procurement. The system runs on a Technijian-hosted VM; no Client-side hardware is required.", "bullets2"));
  content.push(bullet("24x7 production monitoring or incident response. Best-effort failure-notification email is included; SLA-bound monitoring is available under a separate Managed Services SOW.", "bullets2"));
  content.push(spacer());

  content.push(heading2("2.3 Assumptions"));
  content.push(bullet("The 16 hours of existing assets listed in the BBC System Specification (9 city scrapers, client-fit scoring, OC Assessor API integration, branded DOCX generation) are operational at the start of this SOW and will be reused without rewrite.", "bullets3"));
  content.push(bullet("The Alpha feasibility phase has produced a go-ahead and a confirmed technical approach. If Alpha findings invalidate any scraper target (e.g., a city has changed portals or added bot defenses), Technijian will issue a Change Order before re-architecting that portion.", "bullets3"));
  content.push(bullet("Client will designate Bryan Burkhart as the empowered point of contact for scope decisions and Kurtis Burkhart as the operator who reviews weekly output and approves any changes to scoring rules or target HOA list.", "bullets3"));
  content.push(bullet("All API keys, credentials, and account access required for the scrapers (Tyler EnerGov SSO, CentralSquare eTRAKiT, Zillow / Redfin / Realtor account access, Spokeo / Apollo accounts, OC Assessor API key, Microsoft 365 sender mailbox) will be provided to Technijian within five (5) business days of SOW execution.", "bullets3"));
  content.push(bullet("Client acknowledges that lead generation against public records and listing sites is subject to source-site rate limits, terms of service, and CAPTCHA / bot defenses. Technijian will use reasonable engineering practices to maintain reliability but cannot guarantee 100% scraper uptime against arbitrary source-site changes. Source-site changes that require non-trivial re-engineering will be tracked as Change Orders.", "bullets3"));
  content.push(bullet("Time will be tracked and reported in 15-minute increments, itemized by phase, role, and description of work.", "bullets3"));
  content.push(brandRule());

  // ---- 3. PROJECT PHASES ----
  content.push(heading1("3. PROJECT PHASES"));
  content.push(p("The Implementation Phase is organized into six (6) development phases plus CTO oversight, followed by Ongoing Operations (Section 3.10). Phases 2 and 3 may run in parallel after Phase 1 is operational. Total implementation: 80 hours over 6 weeks."));
  content.push(spacer());

  // Phase 1
  content.push(heading2("Phase 1: Foundation — VM Setup & Claude Code Agent (12 hrs)"));
  content.push(heading3("3.1.1 Description"));
  content.push(p("Provision the Windows Server VM, install the runtime, configure the Claude Code agent, build the orchestrator harness, and wire Windows Task Scheduler. This phase delivers the autonomous “supervisor” loop on which all subsequent phases plug in."));
  content.push(spacer());
  content.push(heading3("3.1.2 Deliverables"));
  content.push(bullet("Windows Server VM provisioned in Technijian Cloud (Tier 4: 4 vCore / 16 GB RAM).", "bullets4"));
  content.push(bullet("Runtime installed: Node.js 18+, Playwright (with browser binaries), Claude Code CLI, PowerShell modules, .env vault.", "bullets4"));
  content.push(bullet("Claude Code agent configured with system prompt, allowed tool list, MCP server connections (Microsoft 365 for email, OC Assessor API), and subagent definitions for each scraper.", "bullets4"));
  content.push(bullet("PowerShell orchestrator script that invokes Claude Code in headless mode with the appropriate prompt for each schedule slot.", "bullets4"));
  content.push(bullet("Windows Task Scheduler configured with all six schedule entries (city permits, DRB, just-sold, CDP, enrichment, weekly report).", "bullets4"));
  content.push(bullet("Structured logging to data/logs/YYYY-MM-DD.log with retention policy.", "bullets4"));
  content.push(bullet("Failure-notification email to a Technijian operator mailbox after two consecutive recovery failures.", "bullets4"));
  content.push(spacer());
  content.push(heading3("3.1.3 Schedule"));
  content.push(makeTable(
    ["Role", "Description", "Est. Hours", "Timeline", "Resource"],
    [
      ["US Developer", "VM provision, Claude Code agent config, MCP wiring, orchestrator harness", "8.0", "Week 1", "TBD"],
      ["Offshore Developer", "PowerShell wrappers, Task Scheduler config, log rotation", "4.0", "Week 1", "TBD"],
      ["", { text: "Total", bold: true }, { text: "12.0", bold: true }, "", ""]
    ],
    [1700, 3800, 1200, 1400, 1260]
  ));
  content.push(spacer());

  // Phase 2
  content.push(heading2("Phase 2: DRB Intelligence Scraper (16 hrs)"));
  content.push(heading3("3.2.1 Description"));
  content.push(p("Build the Design Review Board scraper that replaces Kurtis’s primary manual workflow: reading DRB agendas and extracting owner / architect names from the linked plan-set PDFs. Targets the Granicus and Legistar agenda systems used by Newport Beach, Laguna Beach, and other coastal cities, plus PDF title-block extraction from linked plan sets."));
  content.push(spacer());
  content.push(heading3("3.2.2 Deliverables"));
  content.push(bullet("Granicus / Legistar agenda parser per target city.", "bullets5"));
  content.push(bullet("PDF download + title-block OCR / text extractor that pulls owner name, architect name, and project address.", "bullets5"));
  content.push(bullet("Entity normalization (LLC / trust unwrap, common name variants).", "bullets5"));
  content.push(bullet("Integration with the existing client-fit scoring engine.", "bullets5"));
  content.push(bullet("Per-city configuration file so new cities can be added without code changes.", "bullets5"));
  content.push(bullet("Unit tests against captured sample agendas.", "bullets5"));
  content.push(spacer());
  content.push(heading3("3.2.3 Schedule"));
  content.push(makeTable(
    ["Role", "Description", "Est. Hours", "Timeline", "Resource"],
    [
      ["US Developer", "PDF title-block extraction logic, entity normalization", "6.0", "Week 2-3", "TBD"],
      ["Offshore Developer", "Per-city Granicus / Legistar parsers, configuration system", "10.0", "Week 2-3", "TBD"],
      ["", { text: "Total", bold: true }, { text: "16.0", bold: true }, "", ""]
    ],
    [1700, 3800, 1200, 1400, 1260]
  ));
  content.push(spacer());

  // Phase 3
  content.push(heading2("Phase 3: Just-Sold Monitor (14 hrs)"));
  content.push(heading3("3.3.1 Description"));
  content.push(p("Monitor Zillow, Redfin, and Realtor.com for recent luxury sales in the 18 target HOA communities. Extract buyer-agent contact information — the warm-introduction path to new homeowners planning renovations or rebuilds. Runs Mon-Fri at 7 AM Pacific because fresh sales go stale fast."));
  content.push(spacer());
  content.push(heading3("3.3.2 Deliverables"));
  content.push(bullet("Zillow, Redfin, Realtor.com scrapers with HOA-area filtering.", "bullets"));
  content.push(bullet("Buyer-agent name, brokerage, phone, and email extraction.", "bullets"));
  content.push(bullet("Sale-price filter (default $2M+, configurable).", "bullets"));
  content.push(bullet("Deduplication against previously scraped sales (rolling 90-day window).", "bullets"));
  content.push(bullet("Integration with the OC Assessor API for property valuation cross-check.", "bullets"));
  content.push(bullet("Integration with the existing client-fit scoring engine.", "bullets"));
  content.push(spacer());
  content.push(heading3("3.3.3 Schedule"));
  content.push(makeTable(
    ["Role", "Description", "Est. Hours", "Timeline", "Resource"],
    [
      ["US Developer", "Architecture, OC Assessor cross-check integration", "4.0", "Week 2-3", "TBD"],
      ["Offshore Developer", "Zillow / Redfin / Realtor scrapers, dedup, area filters", "10.0", "Week 2-3", "TBD"],
      ["", { text: "Total", bold: true }, { text: "14.0", bold: true }, "", ""]
    ],
    [1700, 3800, 1200, 1400, 1260]
  ));
  content.push(spacer());

  // Phase 4
  content.push(heading2("Phase 4: Contact Enrichment Pipeline (10 hrs)"));
  content.push(heading3("3.4.1 Description"));
  content.push(p("Automated skip-tracing and contact enrichment. Transforms anonymous leads into actionable contacts with owner phone / email and architect contact details. Triggered after each scrape cycle so only newly discovered leads consume enrichment quota."));
  content.push(spacer());
  content.push(heading3("3.4.2 Deliverables"));
  content.push(bullet("Spokeo automation for owner phone / email lookup (browser-based via Playwright).", "bullets2"));
  content.push(bullet("Apollo.io API integration for architect contact data.", "bullets2"));
  content.push(bullet("Confidence-scored enrichment results (high / medium / low).", "bullets2"));
  content.push(bullet("Quota guardrails so a runaway scrape cannot exhaust the enrichment budget.", "bullets2"));
  content.push(bullet("Lead-to-contact join logic that attaches enrichment results to the source lead record.", "bullets2"));
  content.push(spacer());
  content.push(heading3("3.4.3 Schedule"));
  content.push(makeTable(
    ["Role", "Description", "Est. Hours", "Timeline", "Resource"],
    [
      ["US Developer", "Quota guardrails, confidence scoring, join logic", "2.0", "Week 4", "TBD"],
      ["Offshore Developer", "Spokeo Playwright automation, Apollo.io API integration", "8.0", "Week 4", "TBD"],
      ["", { text: "Total", bold: true }, { text: "10.0", bold: true }, "", ""]
    ],
    [1700, 3800, 1200, 1400, 1260]
  ));
  content.push(spacer());

  // Phase 5
  content.push(heading2("Phase 5: Coastal Development Permits & Financial Signals (8 hrs)"));
  content.push(heading3("3.5.1 Description"));
  content.push(p("Coastal Development Permits (CDPs) and OC Clerk-Recorder financial-signal scrapers add high-conviction lead indicators. CDP filings indicate a coastal-zone construction project in motion; Clerk-Recorder construction deeds of trust and LLC / trust property transfers in target areas indicate financing activity that often precedes a build."));
  content.push(spacer());
  content.push(heading3("3.5.2 Deliverables"));
  content.push(bullet("CDP scrapers for Newport Beach, Laguna Beach, Dana Point, San Clemente, and the California Coastal Commission portal.", "bullets3"));
  content.push(bullet("OC Clerk-Recorder monitor for construction deeds of trust and target-area property transfers.", "bullets3"));
  content.push(bullet("Integration with the existing client-fit scoring engine as score modifiers (CDP = +20 confidence, construction deed of trust = +15 confidence).", "bullets3"));
  content.push(spacer());
  content.push(heading3("3.5.3 Schedule"));
  content.push(makeTable(
    ["Role", "Description", "Est. Hours", "Timeline", "Resource"],
    [
      ["US Developer", "Score modifier integration, signal weighting calibration", "2.0", "Week 4-5", "TBD"],
      ["Offshore Developer", "5-city CDP scrapers, OC Clerk-Recorder monitor", "6.0", "Week 4-5", "TBD"],
      ["", { text: "Total", bold: true }, { text: "8.0", bold: true }, "", ""]
    ],
    [1700, 3800, 1200, 1400, 1260]
  ));
  content.push(spacer());

  // Phase 6
  content.push(heading2("Phase 6: Report & Email Delivery (10 hrs)"));
  content.push(heading3("3.6.1 Description"));
  content.push(p("Automated weekly report generation with email delivery to BBC. Extends the existing Technijian-branded DOCX report generator. Highlights only NEW leads since the last report, archives weekly snapshots, and ships via Microsoft 365."));
  content.push(spacer());
  content.push(heading3("3.6.2 Deliverables"));
  content.push(bullet("Weekly tiered report generator: Tier 1 (Hot, score >= 80), Tier 2 (Warm, score 60–79), Tier 3 (Watch, score 40–59).", "bullets4"));
  content.push(bullet("Branded DOCX builder extending the existing template, with new-lead highlighting and full source / score / rationale attribution per lead.", "bullets4"));
  content.push(bullet("CSV export for CRM import.", "bullets4"));
  content.push(bullet("JSON export for downstream consumers.", "bullets4"));
  content.push(bullet("Microsoft 365 MCP-server-driven email composer and sender, with the DOCX and CSV attached.", "bullets4"));
  content.push(bullet("Delta detection against the previous report so only new leads are highlighted.", "bullets4"));
  content.push(bullet("Weekly archive at data/reports/YYYY-MM-DD/.", "bullets4"));
  content.push(spacer());
  content.push(heading3("3.6.3 Schedule"));
  content.push(makeTable(
    ["Role", "Description", "Est. Hours", "Timeline", "Resource"],
    [
      ["US Developer", "DOCX builder extensions, M365 MCP wiring, delta detection", "8.0", "Week 5-6", "TBD"],
      ["Offshore Developer", "CSV / JSON export, weekly archive, report assembly tests", "2.0", "Week 5-6", "TBD"],
      ["", { text: "Total", bold: true }, { text: "10.0", bold: true }, "", ""]
    ],
    [1700, 3800, 1200, 1400, 1260]
  ));
  content.push(spacer());

  // CTO Oversight
  content.push(heading2("CTO Oversight — Architecture, Deploy, Calibration (10 hrs)"));
  content.push(heading3("3.7.1 Description"));
  content.push(p("CTO oversight across the engagement: architecture review at the end of each phase, integration arbitration when Phase 2 / 3 / 4 dependencies overlap, production cutover, and post-go-live scoring calibration based on the first two weekly reports."));
  content.push(spacer());
  content.push(heading3("3.7.2 Deliverables"));
  content.push(bullet("End-of-phase architecture review notes for Phases 1-6.", "bullets5"));
  content.push(bullet("Production cutover checklist and go-live authorization.", "bullets5"));
  content.push(bullet("Post-go-live scoring calibration memo after the second weekly report.", "bullets5"));
  content.push(bullet("Operator runbook (60-minute walkthrough delivered live and recorded).", "bullets5"));
  content.push(spacer());
  content.push(heading3("3.7.3 Schedule"));
  content.push(makeTable(
    ["Role", "Description", "Est. Hours", "Timeline", "Resource"],
    [
      ["CTO Advisory", "Architecture reviews, integration arbitration, deploy, calibration", "10.0", "Weeks 1-7", "Ravi Jain"],
      ["", { text: "Total", bold: true }, { text: "10.0", bold: true }, "", ""]
    ],
    [1700, 3800, 1200, 1400, 1260]
  ));
  content.push(spacer());

  // 3.8 Schedule Summary
  content.push(heading3("3.8 Implementation Schedule Summary"));
  content.push(makeTable(
    ["Week", "Phase", "Milestone", "Deliverable"],
    [
      ["1", "Phase 1", "VM + Claude Code agent operational", "Scheduled task fires; logs written; sample run succeeds end-to-end"],
      ["2-3", "Phase 2", "DRB scraper live", "Granicus / Legistar parsers + PDF extractor pull owner / architect names"],
      ["2-3", "Phase 3", "Just-sold monitor live", "Zillow / Redfin / Realtor scrapers + buyer-agent extraction"],
      ["4", "Phase 4", "Contact enrichment integrated", "Spokeo + Apollo automation flowing into lead records"],
      ["4-5", "Phase 5", "CDP + financial signals live", "5-city CDP scrapers + Clerk-Recorder monitor as score modifiers"],
      ["5-6", "Phase 6", "Report + email delivery", "Weekly DOCX / CSV / JSON + M365 email to Kurtis"],
      ["6-7", "CTO Oversight", "Production deployment + calibration", "Go-live authorization, scoring calibration memo"]
    ],
    [800, 1500, 3300, 3760]
  ));
  content.push(spacer());

  // 3.9 Cadence
  content.push(heading3("3.9 Automated Run Cadence (Production)"));
  content.push(makeTable(
    ["Source", "Cadence", "Schedule", "Rationale"],
    [
      ["City Permits (9)", "Weekly", "Sunday 6:00 AM Pacific", "Permits update slowly, weekly is sufficient"],
      ["DRB Agendas", "After each meeting", "Daily check, scrape on new agenda", "Laguna Beach 2x/month, others vary"],
      ["Just-Sold Listings", "Daily", "Mon-Fri 7:00 AM Pacific", "Fresh sales go stale fast"],
      ["CDP Filings", "Weekly", "Sunday 6:30 AM Pacific", "Coastal permits filed infrequently"],
      ["Contact Enrichment", "On new leads", "After each scrape cycle", "Only enrich newly discovered leads"],
      ["Report + Email", "Weekly", "Sunday 10:00 AM Pacific", "Consolidated digest after all scrapes"]
    ],
    [2200, 1800, 2400, 2960]
  ));
  content.push(spacer());

  // 3.10 Ongoing Operations
  content.push(heading3("3.10 Ongoing Operations"));
  content.push(p("After Final Acceptance (Section 8.05), the system enters operations mode:"));
  content.push(spacer());
  content.push(bullet("The Technijian-hosted VM continues to run the Claude Code agent on the cadence in Section 3.9.", "bullets"));
  content.push(bullet("Best-effort failure-notification email continues to a Technijian operator mailbox after two consecutive recovery failures.", "bullets"));
  content.push(bullet("Source-site changes that require non-trivial re-engineering (a target city portal redesign, a listing site adding new bot defenses, a vendor API breaking change) are tracked as Change Orders per Section 7.02 and billed against Client’s existing Hourly contract (5516) at the rates in Section 5.1.", "bullets"));
  content.push(bullet("The Anthropic API key powering the Claude Code agent is provided by Client (BYOK) for Phase 1; Client is responsible for Anthropic token spend on its own Anthropic invoice. Technijian’s forthcoming Chat.AI subscription will be available as an optional no-charge migration in Phase 2.", "bullets"));
  content.push(bullet("The recurring charges in Section 5.3 cover infrastructure only; ad-hoc maintenance hours, source-site re-engineering, and feature additions bill separately per the Hourly contract or a written Change Order.", "bullets"));
  content.push(brandRule());

  // ---- 4. EQUIPMENT AND MATERIALS ----
  content.push(heading1("4. EQUIPMENT AND MATERIALS"));
  content.push(p("No hardware is supplied under this SOW. The system runs on a Technijian-hosted Windows Server VM, billed as a recurring monthly charge under Section 5.3. Third-party services (Spokeo, Apollo.io, OC Assessor API quotas beyond the free tier, Microsoft 365 license uplift if required) and Anthropic API tokens (BYOK) are procured by and paid directly by Client."));
  content.push(brandRule());

  // ---- 5. PRICING AND PAYMENT ----
  content.push(heading1("5. PRICING AND PAYMENT"));

  content.push(heading2("5.1 Rate Card (Implementation Phase — T&M)"));
  content.push(makeTable(
    ["Role", "Location", "Rate"],
    [
      ["CTO / AI Advisory (Ravi Jain)", "US (Remote)", "$250.00 / hr"],
      ["Senior Developer", "US (Remote)", "$150.00 / hr"],
      ["Offshore Developer", "Offshore (Remote)", "$45.00 / hr"],
      ["After-Hours Premium (CTO; weekends, holidays, or after 6 PM Pacific)", "US (Remote)", "$350.00 / hr"]
    ],
    [4800, 2200, 2360]
  ));
  content.push(spacer());
  content.push(p("Rates are fixed for the term of this engagement. Any rate changes require a written Change Order signed by both Parties."));
  content.push(spacer());

  content.push(heading2("5.2 Summary of Costs (Planning Estimate)"));
  content.push(makeTable(
    ["Phase", "Role", "Est. Hours", "Rate", "Cost"],
    [
      ["Phase 1 — Foundation & VM Setup", "US Developer", "8.0", "$150.00", "$1,200.00"],
      ["Phase 1 — Foundation & VM Setup", "Offshore Developer", "4.0", "$45.00", "$180.00"],
      ["Phase 2 — DRB Intelligence", "US Developer", "6.0", "$150.00", "$900.00"],
      ["Phase 2 — DRB Intelligence", "Offshore Developer", "10.0", "$45.00", "$450.00"],
      ["Phase 3 — Just-Sold Monitor", "US Developer", "4.0", "$150.00", "$600.00"],
      ["Phase 3 — Just-Sold Monitor", "Offshore Developer", "10.0", "$45.00", "$450.00"],
      ["Phase 4 — Contact Enrichment", "US Developer", "2.0", "$150.00", "$300.00"],
      ["Phase 4 — Contact Enrichment", "Offshore Developer", "8.0", "$45.00", "$360.00"],
      ["Phase 5 — CDP & Financial Signals", "US Developer", "2.0", "$150.00", "$300.00"],
      ["Phase 5 — CDP & Financial Signals", "Offshore Developer", "6.0", "$45.00", "$270.00"],
      ["Phase 6 — Report & Email Delivery", "US Developer", "8.0", "$150.00", "$1,200.00"],
      ["Phase 6 — Report & Email Delivery", "Offshore Developer", "2.0", "$45.00", "$90.00"],
      ["CTO Oversight", "CTO Advisory", "10.0", "$250.00", "$2,500.00"],
      [{ text: "Estimated Total (Labor)", bold: true }, "", { text: "80.0", bold: true }, "", { text: "$8,800.00", bold: true }]
    ],
    [3400, 2000, 1100, 1100, 1760]
  ));
  content.push(spacer());
  content.push(p("Pricing Type Definitions", { bold: true, color: CHARCOAL }));
  content.push(bullet("Estimate Cost. Hours and costs above are good-faith planning estimates. Technijian will bill for actual time performed, at the rates in Section 5.1. If cumulative actual hours are projected to exceed the total estimate by more than 10%, Technijian will notify Client in writing before performing the additional hours.", "bullets"));
  content.push(spacer());

  content.push(heading2("5.3 Recurring Operational Charges (Monthly)"));
  content.push(p("In addition to the one-time implementation labor in Section 5.2, the following recurring charges apply monthly for the operations term defined in Section 5.7:"));
  content.push(spacer());
  content.push(makeTable(
    ["Item", "Code", "Unit Price / mo", "Notes"],
    [
      ["Cloud VM — Tier 4 (4 vCore / 16 GB RAM)", "CL-VC + CL-GB", "$35.00 + $30.00", "Bare VM + Windows Server license"],
      ["Cloud — Shared Bandwidth", "CL-SBW", "$15.00", "Per VM"],
      ["Image Backup", "IB", "$15.00", "Per server"],
      ["Health Monitoring", "SHM", "$2.00", "Per device"],
      [{ text: "Monthly Recurring Subtotal", bold: true }, "", { text: "$97.00 / mo", bold: true }, "Anthropic API tokens excluded — see Section 3.10"]
    ],
    [3400, 1800, 2200, 1960]
  ));
  content.push(spacer());
  content.push(p("Recurring operational charges commence on the first day of Week 1 (concurrent with VM provisioning) and continue for the term defined in Section 5.7. Anthropic API token usage is excluded from the table above; see Section 3.10 for the BYOK / future Chat.AI handling."));
  content.push(spacer());

  content.push(heading2("5.4 Invoicing and Payment Schedule"));
  content.push(multiRun([
    { text: "Implementation labor. ", bold: true, color: CHARCOAL },
    { text: "Technijian will invoice Client bi-weekly for actual labor hours performed during the preceding period, itemized by date, duration, phase, role, and description of work." }
  ], { numbering: { reference: "bullets2", level: 0 } }));
  content.push(multiRun([
    { text: "Recurring operations. ", bold: true, color: CHARCOAL },
    { text: "The monthly charges in Section 5.3 are invoiced on the first business day of each month, beginning the first business day of Week 1." }
  ], { numbering: { reference: "bullets2", level: 0 } }));
  content.push(bullet("All invoices are due and payable within thirty (30) days of the invoice date.", "bullets2"));
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
  content.push(spacer());

  // 5.7 Term and Termination of Operations
  content.push(heading2("5.7 Term and Termination of Operations"));
  content.push(multiRun([
    { text: "The recurring operational charges in Section 5.3 commence on the first day of Week 1 (concurrent with VM provisioning) and continue for an initial term of " },
    { text: "twelve (12) months from Final Acceptance", bold: true, color: CHARCOAL },
    { text: " (Section 8.05). After the initial term, operational charges automatically renew on a " },
    { text: "month-to-month basis", bold: true, color: CHARCOAL },
    { text: "." }
  ]));
  content.push(spacer());
  content.push(multiRun([
    { text: "Either Party may terminate the operations period with " },
    { text: "thirty (30) days’", bold: true, color: CHARCOAL },
    { text: " written notice. Upon termination, Technijian shall: (a) safely shut down the VM after exporting the data archive at data/reports/; (b) hand over runbooks, configurations, prompts, and the Claude Code agent definition; and (c) transfer or destroy at Client’s direction any Technijian-held credentials." }
  ]));
  content.push(spacer());
  content.push(p("Termination of operations does not affect any unbilled implementation labor or any open Change Order; those are invoiced and paid out under their existing terms."));
  content.push(brandRule());

  // ---- 6. CLIENT RESPONSIBILITIES ----
  content.push(heading1("6. CLIENT RESPONSIBILITIES"));
  content.push(p("Client shall:"));
  content.push(spacer());
  content.push(p("(a) Provide all credentials and account access required for the scrapers (Tyler EnerGov, CentralSquare eTRAKiT, Granicus, Legistar, Zillow / Redfin / Realtor accounts, Spokeo, Apollo.io, OC Assessor API key, Microsoft 365 sender mailbox) within five (5) business days of SOW execution;", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(b) Designate Bryan Burkhart as the empowered point of contact for scope decisions and Kurtis Burkhart as the operator for weekly output review and scoring-rule changes;", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(c) Review and approve deliverables at the end of each phase within five (5) business days of submission;", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(d) Procure and pay for all third-party services directly (Spokeo, Apollo.io, OC Assessor API quota, LLM API usage, Microsoft 365 license uplift if required);", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(e) Authorize Technijian’s procurement of the VM hosting Service Order (Section 5.3) before Phase 1 begins;", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(f) Acknowledge that scraping public records and listing sites is subject to source-site terms of service, rate limits, and bot defenses, and that Technijian cannot guarantee 100% scraper uptime against arbitrary source-site changes;", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(g) Comply with all applicable real-estate solicitation laws (CAN-SPAM, TCPA, California state rules) when contacting any lead produced by the system. Client acknowledges that Technijian is not a law firm and is not providing legal or compliance advice;", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(h) Promptly inform Technijian of any change to the target HOA list, target city list, sale-price floor, or scoring rule that should be applied;", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(i) Inform internal stakeholders of any system changes that affect the weekly report; and", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(j) Provide and maintain the Anthropic API key used by the Claude Code agent during Phase 1 (BYOK), and authorize Technijian’s no-charge migration to a Technijian Chat.AI subscription if and when Chat.AI is generally available.", { indent: { left: 360 } }));
  content.push(brandRule());

  // ---- 7. CHANGE MANAGEMENT ----
  content.push(heading1("7. CHANGE MANAGEMENT"));
  content.push(p("7.01. Any changes to scope, schedule, or pricing of this SOW must be documented in a written Change Order signed by both Parties before work on the change begins."));
  content.push(spacer());
  content.push(p("7.02. Non-trivial source-site changes (a target city portal redesign, a listing site adding new bot defenses, a vendor API breaking change) that require re-engineering of an existing scraper shall be tracked as Change Orders. Technijian shall provide a Change Order with hours estimate before performing the re-engineering work."));
  content.push(spacer());
  content.push(p("7.03. Technijian shall not perform work that would exceed the estimate in Section 5.2 by more than 10% without notifying Client in advance, except in cases where delay would cause imminent harm to Client’s systems, in which case Technijian may perform emergency work not to exceed $2,500 (at the Section 5.1 rates) and shall notify Client as soon as practicable, with a retrospective Change Order within three (3) business days."));
  content.push(brandRule());

  // ---- 8. ACCEPTANCE ----
  content.push(heading1("8. ACCEPTANCE"));
  content.push(p("8.01. Upon completion of each phase listed in Section 3, Technijian shall notify Client in writing that the phase deliverables are ready for review."));
  content.push(spacer());
  content.push(p("8.02. Client shall review the deliverables and provide written acceptance or a detailed description of deficiencies within five (5) business days of submission. Technijian’s delivery notification shall include a conspicuous statement: “If you do not respond within five (5) business days, this phase will be deemed accepted per SOW Section 8.03.”"));
  content.push(spacer());
  content.push(p("8.03. If Client does not respond within the review period, the phase shall be deemed accepted."));
  content.push(spacer());
  content.push(p("8.04. If deficiencies are identified, Technijian shall correct them and resubmit for review. This process shall repeat until acceptance is achieved or the Parties agree on a resolution."));
  content.push(spacer());
  content.push(multiRun([
    { text: "8.05. Final Acceptance. ", bold: true, color: CHARCOAL },
    { text: "Final acceptance of the entire system shall occur upon the successful delivery of the second consecutive weekly report email (Sunday 10:00 AM Pacific) without manual operator intervention." }
  ]));
  content.push(brandRule());

  // ---- 9. GOVERNING TERMS ----
  content.push(heading1("9. GOVERNING TERMS"));
  content.push(p("9.01. No Master Service Agreement is currently in effect between the Parties. This SOW is a standalone engagement governed by the Technijian Standard Terms and Conditions (Appendix A, if attached) and the following minimum terms:"));
  content.push(spacer());
  content.push(p("(a) Neither Party’s total aggregate liability under this SOW shall exceed the total fees paid or payable under this SOW in the six (6) months preceding the claim.", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(b) In no event shall either Party be liable for indirect, incidental, special, consequential, or punitive damages, including but not limited to lost profits, lost leads, or lost business opportunity.", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(c) This SOW shall be governed by the laws of the State of California, without regard to conflict-of-laws principles. Any dispute shall be resolved by binding arbitration in Orange County, California, under the AAA Commercial Arbitration Rules, except that either Party may seek injunctive relief in court for protection of intellectual property or confidential information.", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(d) Each Party shall keep the other’s confidential information (including pricing, target HOA list, and scoring rules) strictly confidential during the engagement and for three (3) years thereafter.", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(e) Client retains ownership of all Client Data, including all leads, scores, and reports produced by the system. Technijian retains ownership of its pre-existing tools, methodologies, and templates (including the orchestration framework, branded DOCX template, and shared client-fit scoring engine, except to the extent of Client-specific calibration). Client receives a perpetual, non-exclusive license to use the deliverables and configurations produced under this SOW for its internal business purposes.", { indent: { left: 360 } }));
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
  content.push(p("BURKHART BROTHERS CONSTRUCTION", { bold: true, color: CHARCOAL }));
  content.push(spacer());
  content.push(p("By: ___________________________________"));
  content.push(spacer());
  content.push(p("Name: Bryan Burkhart"));
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
          "Autonomous Lead Generation System — Implementation Phase — Burkhart Brothers Construction"
        )
      },
      {
        properties: contentSectionProps(),
        children: content
      }
    ]
  });

  const buffer = await Packer.toBuffer(doc);
  const outputPath = path.join(__dirname, "..", "03_SOW", "SOW-BBC-001-AutoLeadGen-Build.docx");
  fs.writeFileSync(outputPath, buffer);
  console.log("Generated:", outputPath);
}

generateSOW().catch(err => {
  console.error("Error generating SOW:", err);
  process.exit(1);
});
