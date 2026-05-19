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
  config: Array.from({ length: 12 }, (_, i) => ({
    reference: i === 0 ? "bullets" : `bullets${i + 1}`,
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
  const isTotal = opts.total || false;
  const runOpts = {
    font: FONT,
    size: opts.fontSize || 20,
    text,
    color: isHeader ? WHITE : GREY,
    bold: isHeader || opts.bold || isTotal
  };
  let fillColor = WHITE;
  if (isHeader) fillColor = BLUE;
  else if (isTotal) fillColor = "E8EFF5";
  else if (opts.alt) fillColor = OFF_WHITE;
  return new TableCell({
    borders: tableBorders,
    width: { size: width, type: WidthType.DXA },
    margins: cellPadding,
    shading: { fill: fillColor, type: ShadingType.CLEAR },
    verticalAlign: "center",
    children: [new Paragraph({ children: [new TextRun(runOpts)] })]
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
        const total = typeof cell === "object" ? cell.total : false;
        return brandTableCell(text, { width: widths[ci], alt: ri % 2 === 0, bold, total });
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
    { text: "May 15, 2026" }
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
  content.push(p("Burkhart Brothers Construction, Inc. (“Client” or “BBC”)", { bold: true, color: CHARCOAL }));
  content.push(p("1382 Valencia Ave, Unit F"));
  content.push(p("Tustin, California 92780"));
  content.push(p("CSLB License No. 905510"));
  content.push(spacer());
  content.push(multiRun([{ text: "Primary Contact: ", bold: true, color: CHARCOAL }, { text: "Bryan Burkhart (bryan@burkhartbros.com, 310-704-8467)" }]));
  content.push(multiRun([{ text: "Operator / Day-to-Day Recipient: ", bold: true, color: CHARCOAL }, { text: "Kurtis Burkhart" }]));
  content.push(brandRule());

  // ---- 1. PROJECT OVERVIEW ----
  content.push(heading1("1. PROJECT OVERVIEW"));

  content.push(heading2("1.1 Project Title"));
  content.push(p("Autonomous Lead Generation System — Automation Phase (Technijian-Managed, Headless, Pre-Web-Application)"));
  content.push(spacer());

  content.push(heading2("1.2 Project Description"));
  content.push(p("Burkhart Brothers Construction, Inc. (“BBC”) is a Southern California luxury custom home builder serving Orange County's coastal HOA communities. BBC's growth is directly tied to the ability to identify owners and architects of permitted projects and recently sold luxury properties before competitors do. The data-extraction pipeline — eight (8) city permit scrapers, the Design Review Board (DRB) intelligence scraper, the just-sold listings monitor, the Coastal Development Permit and Clerk-Recorder financial-signal scrapers, the contact enrichment chain (ATTOM Data, BatchData, BatchLeads, Spokeo, Google Geocoding), the client-fit scoring engine, and the Technijian-branded DOCX / CSV / XLSX report generator — is operational, has produced multiple weekly lead reports, and was developed and billed under Hourly Contract 5516."));
  content.push(spacer());
  content.push(multiRun([
    { text: "This SOW covers the " },
    { text: "automation phase", bold: true, color: CHARCOAL },
    { text: ": lifting that pipeline off the developer workstation onto a Technijian-hosted Windows Server VM, wrapping the existing pipeline modules in seven purpose-built agents on the Claude Agent SDK, and orchestrating the production schedule with n8n (self-hosted workflow engine). The result is a headless, production-grade lead-generation pipeline " },
    { text: "operated and managed entirely by Technijian", bold: true, color: CHARCOAL },
    { text: " on its own infrastructure. BBC's only interface with the system is " },
    { text: "the weekly Tier 1 lead email", bold: true, color: CHARCOAL },
    { text: " delivered each Sunday morning. The system runs without any BBC-side user interface, login, or operator console. A future Web Application phase (live map view, CRM features, multi-user access) is explicitly out of scope and may be offered as a separate engagement after this automation phase has stabilized and proven value." }
  ]));
  content.push(spacer());
  content.push(multiRun([
    { text: "Architectural approach. ", bold: true, color: CHARCOAL },
    { text: "Three new layers are introduced, all hosted and operated on Technijian-internal infrastructure:" }
  ]));
  content.push(spacer());
  content.push(bulletMulti([
    { text: "n8n (Docker container on the Technijian VM): ", bold: true, color: CHARCOAL },
    { text: "Technijian-internal workflow orchestrator. Replaces Windows Task Scheduler + PowerShell supervisor with a visual, observable workflow engine with built-in retry, error branching, and Microsoft 365 nodes for email delivery. The n8n UI is accessible only to Technijian operators on the internal network; BBC does not log into n8n." }
  ], "bullets"));
  content.push(bulletMulti([
    { text: "Agent harness on Claude Agent SDK ", bold: true, color: CHARCOAL },
    { text: "(Node service in its own container, internal-only): exposes seven purpose-built agents to n8n via HTTP, with schema-validated I/O, structured logging, and per-agent token budgeting. The harness is BBC-specific; productization across other Technijian clients is out of scope." }
  ], "bullets"));
  content.push(bulletMulti([
    { text: "Seven (7) named agents: ", bold: true, color: CHARCOAL },
    { text: "pipeline-coordinator, permit-scraper, scraper-healer, enrichment-coordinator, scoring-analyst, communication-drafter, and run-supervisor. Each agent has a defined system prompt, tool list, JSON I/O contract, and unit tests. Agents wrap (rather than rewrite) the existing pipeline modules already built under Hourly Contract 5516." }
  ], "bullets"));
  content.push(spacer());
  content.push(multiRun([
    { text: "No BBC-facing interface. ", bold: true, color: CHARCOAL },
    { text: "BBC does not log into n8n, the agent harness, the VM, or any health dashboard. All operational visibility (workflow status, run logs, health dashboards, error escalation pages) is Technijian-internal. BBC receives the weekly Tier 1 email and may request changes to scoring rules, target HOA list, or sale-price floor via email to Technijian, which are implemented by Technijian as standard managed-services activity or as Change Orders depending on scope." }
  ]));
  content.push(spacer());
  content.push(multiRun([
    { text: "Engagement model. ", bold: true, color: CHARCOAL },
    { text: "This is a " },
    { text: "fixed-fee", bold: true, color: CHARCOAL },
    { text: " engagement. Build labor is delivered at a fixed price of " },
    { text: "$26,360", bold: true, color: CHARCOAL },
    { text: " for the scope defined in Section 3, regardless of actual hours expended. Recurring hosting (Section 5.3) and lead-enrichment subscriptions (Section 5.3) are also fixed monthly fees. The only variable-cost line item in this SOW is " },
    { text: "Anthropic API token usage", bold: true, color: CHARCOAL },
    { text: ", which is pass-through at Anthropic's published rates plus a 15% administrative markup, with a $200 / month soft cap (Section 5.3). Day-to-day operator support (run-health review, BBC change requests, scraper-drift first-line response) is billed at actual hours against the existing Hourly Contract 5516, not under this SOW." }
  ]));
  content.push(spacer());
  content.push(multiRun([
    { text: "Operational scope. ", bold: true, color: CHARCOAL },
    { text: "This SOW also covers the recurring monthly infrastructure required to run the system in production (see Section 3.12 and Section 5.3). The recurring operations period commences on the first day of Week 1 and runs for an initial twelve (12) month term from Final Acceptance, auto-renewing month-to-month thereafter under Section 5.7." }
  ]));
  content.push(spacer());

  content.push(heading2("1.3 Locations"));
  content.push(makeTable(
    ["Location Name", "Code", "Address", "Billable"],
    [
      ["BBC — Headquarters", "BBC-HQ", "1382 Valencia Ave, Unit F, Tustin, CA 92780", "No"],
      ["Technijian Cloud — VM Host", "TECH-VM", "Technijian Data Center, Irvine, CA", "No"]
    ],
    [2340, 1400, 4660, 960]
  ));
  content.push(spacer());
  content.push(p("All work shall be performed remotely. The agent harness, n8n, and the pipeline run on a Technijian-hosted VM in the Irvine data center; no on-site presence at BBC is required."));
  content.push(brandRule());

  // ---- 2. SCOPE OF WORK ----
  content.push(heading1("2. SCOPE OF WORK"));

  content.push(heading2("2.1 In Scope"));
  content.push(p("Technijian will deliver the production-hosted, Technijian-managed, headless lead generation pipeline with the following components. All system access (n8n UI, agent harness logs, VM RDP, health dashboard) is internal to Technijian. BBC does not log into any component."));
  content.push(spacer());
  content.push(bullet("Technijian-hosted Windows Server VM (Tier 4: 4 vCore / 16 GB RAM, Windows Server license) provisioned in the Irvine data center under the Service Order priced in Section 5.3. The VM hosts the agent harness and n8n in separate Docker containers. RDP access is restricted to Technijian operators.", "bullets"));
  content.push(bullet("Secrets migration. All credentials currently in the OneDrive vault are migrated to the Technijian internal key vault and surfaced to the agent harness via runtime environment injection. No credentials in source control. BBC does not need access to the key vault.", "bullets"));
  content.push(bullet("Microsoft 365 Graph app-only authentication. A dedicated Azure AD application registration replaces the existing PowerShell + interactive-mailbox pattern. The app is granted Mail.Send on RJain@technijian.com (or a dedicated Technijian automation sender mailbox). The weekly Tier 1 lead email is sent unattended to kurtis@burkhartbros.com and any additional BBC recipients on file.", "bullets"));
  content.push(bullet("n8n workflow engine (Technijian-internal). Docker container with HTTPS termination, basic-auth login restricted to Technijian operator credentials, automated nightly backup of the n8n SQLite store. Workflows: weekly full-run (Sunday 06:00 PT), daily just-sold (Mon-Fri 07:00 PT), DRB on-meeting check, weekly Tier 1 email (Sunday 10:00 PT), failure escalation. Each workflow node calls the agent harness via HTTP. The n8n UI is not exposed externally; BBC does not have login credentials.", "bullets"));
  content.push(bullet("Agent harness (Claude Agent SDK). Node.js service in its own container, internal-only. Exposes seven agents via REST endpoints. Per-agent JSON Schema for input and output, structured logging to JSON-line files mirrored into n8n, per-run token budget enforcement, automatic redaction of credentials from logs.", "bullets"));
  content.push(bullet("Seven (7) production agents, each with system prompt, tool list, JSON I/O schema, and unit tests: pipeline-coordinator (dispatches scrapers per run), permit-scraper (drives the existing scrapers), scraper-healer (zero-lead / error diagnosis, ported from .claude/agents/scraper-troubleshooter.md), enrichment-coordinator (orchestrates ATTOM / BatchData / BatchLeads / Spokeo / Google Geocoding with cost minimization), scoring-analyst (applies the rubric, generates Tier 1 narrative), communication-drafter (drafts the weekly email), and run-supervisor (monitors run, escalates failures, writes weekly summary).", "bullets"));
  content.push(bullet("Newport Beach 2FA persistence. One-time interactive 2FA performed by Technijian via RDP, with Kurtis Burkhart providing the Google second-factor confirmation on his phone. The Playwright user-data directory is then persisted on the VM for unattended subsequent runs. When the session expires, Technijian initiates a new RDP session and coordinates the 2FA second-factor with Kurtis as a brief support interaction.", "bullets"));
  content.push(bullet("Technijian-internal health dashboard + alerting. n8n workflow that reads per-run health JSON, produces a daily summary email to the Technijian operator mailbox, and pages the Technijian operator on two consecutive run failures. BBC does not access this dashboard. A condensed weekly status line is included at the bottom of the BBC Tier 1 email so BBC has passive visibility into how many runs succeeded over the prior week without needing a separate login.", "bullets"));
  content.push(bullet("BBC-facing deliverable. A single recurring deliverable: the weekly Tier 1 lead email (Sundays 10:00 PT) with attached DOCX and CSV reports. No portal, no dashboard, no login.", "bullets"));
  content.push(bullet("BBC orientation. A short (30-minute) walkthrough call with Bryan and Kurtis Burkhart covering: what to expect in the weekly email, how to interpret tiers, scoring fields, and confidence indicators, and how to request changes via email to Technijian. No training on n8n, the agent harness, or any operational system is needed because BBC does not operate any system component.", "bullets"));
  content.push(bullet("Technijian operator runbook (internal). Comprehensive runbook for the Technijian operator covering: how to read n8n run logs, how to re-run a failed workflow, how to roll forward agent prompts, how to reauthenticate Newport Beach with Kurtis's help, how to add a new target HOA per BBC request, how to roll back a bad release, escalation paths.", "bullets"));
  content.push(bullet("Recurring operations. Monthly Technijian-hosted Windows Server VM, image backup, antivirus, DNS filtering, monitoring (per the bundle in Section 5.3), enrichment subscriptions (pass-through + 15% admin), and Anthropic API token usage (pass-through + 15% admin, $200/mo cap), all billed for the term defined in Section 5.7. Technijian operator support for the system is billed at actual hours against the existing Hourly Contract 5516, not bundled into the recurring charges in this SOW.", "bullets"));
  content.push(spacer());

  content.push(heading2("2.2 Out of Scope"));
  content.push(p("The following items are expressly excluded unless added by written Change Order:"));
  content.push(spacer());
  content.push(bullet("The future Web Application phase. A BBC-facing web application (live map view, CRM features, multi-user access, self-service configuration, dashboards, login portal) is explicitly out of scope for this automation phase. The Web Application is a distinct future engagement to be scoped after the automation phase has stabilized and proven its lead-quality value. Nothing in this SOW grants BBC access to any system user interface.", "bullets2"));
  content.push(bullet("BBC-side operations of any system component. BBC does not operate, log into, or troubleshoot n8n, the agent harness, the VM, the key vault, the health dashboard, or any other internal system. All operational responsibility rests with Technijian.", "bullets2"));
  content.push(bullet("Re-development of any scraper, enrichment integration, scoring module, or DOCX report builder. Those modules are operational and were billed under Hourly Contract 5516. This SOW wraps that code in agents and lifts it to a Technijian VM; it does not rebuild it.", "bullets2"));
  content.push(bullet("Productizing the agent harness as a Technijian multi-tenant platform. The harness built under this SOW is BBC-specific. Refactoring it into a multi-tenant Technijian product for other clients may be addressed by a future engagement.", "bullets2"));
  content.push(bullet("Building or maintaining BBC's CRM. The pipeline produces CSV / JSON exports BBC can import into its CRM of choice.", "bullets2"));
  content.push(bullet("Outbound calls, emails, or any direct outreach to leads. The system identifies and scores leads; BBC's sales team makes the contact.", "bullets2"));
  content.push(bullet("Any work requiring access to BBC's personal contacts, vendor lists, financial records, or other confidential business data.", "bullets2"));
  content.push(bullet("Hardware procurement. The system runs on a Technijian-hosted VM; no Client-side hardware is required.", "bullets2"));
  content.push(bullet("24x7 SLA-bound production monitoring or incident response. Best-effort Technijian operator monitoring on business hours is included via Hourly Contract 5516; SLA-bound 24x7 monitoring is available under a separate Managed Services SOW.", "bullets2"));
  content.push(spacer());

  content.push(heading2("2.3 Assumptions"));
  content.push(bullet("The data-extraction pipeline modules (eight city permit scrapers, DRB scraper, just-sold monitor, CDP / Clerk-Recorder financial scrapers, ATTOM / BatchData / BatchLeads / Spokeo / Google Geocoding enrichers, client-fit scoring engine, branded DOCX / CSV / XLSX report generator, M365 PowerShell email script) are operational at the start of this SOW and will be reused without rewrite. Those modules were developed and billed under Hourly Contract 5516 and remain Client's licensed work product.", "bullets3"));
  content.push(bullet("The most recent successful end-to-end run (April 27, 2026) produced 643 raw records and 514 qualified leads across all layers, providing a baseline against which acceptance is measured.", "bullets3"));
  content.push(bullet("Client will designate Bryan Burkhart as the empowered point of contact for scope decisions and Kurtis Burkhart as the operator who reviews weekly output and approves changes to scoring rules or target HOA list.", "bullets3"));
  content.push(bullet("All third-party API keys and account access will be provided to Technijian within five (5) business days of SOW execution. Where Technijian already holds working credentials from prior Hourly Contract work, those will be carried forward and re-stored in the Technijian internal key vault.", "bullets3"));
  content.push(bullet("The Newport Beach Plan Check Portal requires interactive Google 2FA on first authentication. Client agrees that a one-time RDP-based interactive authentication is acceptable, performed by Technijian with Kurtis Burkhart's Gmail second-factor confirmation. The Playwright session is then persisted for subsequent unattended runs.", "bullets3"));
  content.push(bullet("Client acknowledges that scraping public records and listing sites is subject to source-site terms of service, rate limits, and bot defenses, and that Technijian cannot guarantee 100% scraper uptime against arbitrary source-site changes. Source-site changes that require non-trivial re-engineering will be tracked as Change Orders under Section 7.02 and billed against Hourly Contract 5516.", "bullets3"));
  content.push(bullet("Time will be tracked and reported in 15-minute increments, itemized by phase, role, and description of work.", "bullets3"));
  content.push(brandRule());

  // ---- 3. PROJECT PHASES ----
  content.push(heading1("3. PROJECT PHASES"));
  content.push(p("The build is organized into nine (9) phases plus CTO oversight. Phases 3, 4, and 5 may run in parallel after Phase 1 is operational. Total: 190 estimated hours over 6 weeks, with a 15% risk buffer."));
  content.push(spacer());

  // Helper for phase schedule tables
  function phaseSchedule(rows) {
    return makeTable(
      ["Role", "Description", "Est. Hours", "Timeline", "Resource"],
      rows,
      [1700, 4100, 1200, 1200, 1160]
    );
  }

  // Phase 1
  content.push(heading2("Phase 1: VM Provisioning & Repo Lift (9 hrs)"));
  content.push(heading3("3.1.1 Description"));
  content.push(p("Provision the Windows Server VM in the Irvine data center, install the runtime stack, lift the existing repo from the developer workstation, and prove out an end-to-end run on the VM that matches the local baseline."));
  content.push(spacer());
  content.push(heading3("3.1.2 Deliverables"));
  content.push(bullet("Windows Server VM provisioned (Tier 4: 4 vCore / 16 GB RAM).", "bullets4"));
  content.push(bullet("Runtime: Node.js 20+, Playwright (with browser binaries), Patchright, PowerShell 7, Git, Docker Desktop for Windows.", "bullets4"));
  content.push(bullet("Repo cloned to c:\\bbc-leadgen\\ with all dependencies installed.", "bullets4"));
  content.push(bullet("One successful end-to-end pipeline run from the VM that matches (within ±5% of leads) the most recent local baseline run.", "bullets4"));
  content.push(bullet("VM hardening checklist: RDP allowlist, Windows Update policy, firewall rules.", "bullets4"));
  content.push(spacer());
  content.push(heading3("3.1.3 Schedule"));
  content.push(phaseSchedule([
    ["CTO Advisory", "Architecture review, VM tier selection, security posture", "1.0", "Week 1", "Ravi Jain"],
    ["US Senior Developer", "VM provision, runtime install, repo lift, baseline parity test", "4.0", "Week 1", "TBD"],
    ["Offshore Developer", "VM hardening checklist, Docker install, dependency warmup", "4.0", "Week 1", "TBD"],
    ["", { text: "Total", bold: true }, { text: "9.0", bold: true }, "", ""]
  ]));
  content.push(spacer());

  // Phase 2
  content.push(heading2("Phase 2: Secrets Migration & M365 Graph App-Only Auth (7 hrs)"));
  content.push(heading3("3.2.1 Description"));
  content.push(p("Migrate the credential vault off OneDrive into the Technijian internal key vault. Register a new Microsoft 365 Azure AD application for app-only authentication and replace the existing interactive-mailbox PowerShell email script with a Graph SDK call that runs unattended."));
  content.push(spacer());
  content.push(heading3("3.2.2 Deliverables"));
  content.push(bullet("Azure AD application registered: BBC-LeadGen-Automation. Permissions: Mail.Send (Application). Admin consent granted.", "bullets5"));
  content.push(bullet("Client secret stored in Technijian internal key vault; rotation runbook documented.", "bullets5"));
  content.push(bullet("M365 Graph email module replaces scripts/email-tier1-leads.ps1 for production sends. PowerShell script retained for local-developer dry-run use.", "bullets5"));
  content.push(bullet("End-to-end test: weekly Tier 1 lead email sent unattended from the VM to kurtis@burkhartbros.com.", "bullets5"));
  content.push(bullet("Secrets migration runbook (where to find each credential, how to rotate).", "bullets5"));
  content.push(spacer());
  content.push(heading3("3.2.3 Schedule"));
  content.push(phaseSchedule([
    ["CTO Advisory", "Azure AD app registration review, permission scoping", "1.0", "Week 1", "Ravi Jain"],
    ["US Senior Developer", "App registration, Graph SDK integration, end-to-end send test", "6.0", "Week 1", "TBD"],
    ["", { text: "Total", bold: true }, { text: "7.0", bold: true }, "", ""]
  ]));
  content.push(spacer());

  // Phase 3
  content.push(heading2("Phase 3: n8n Install & Workflow Design (28 hrs)"));
  content.push(heading3("3.3.1 Description"));
  content.push(p("Install n8n in a Docker container on the VM, configure HTTPS, authentication, and automated backup. Design and implement the five (5) production workflows: weekly full-run, daily just-sold, DRB on-meeting check, weekly Tier 1 email, failure escalation."));
  content.push(spacer());
  content.push(heading3("3.3.2 Deliverables"));
  content.push(bullet("n8n running in Docker container, accessible at https://bbc-n8n.technijian.internal (or equivalent) with basic-auth login.", "bullets6"));
  content.push(bullet("HTTPS via self-signed or internal CA certificate.", "bullets6"));
  content.push(bullet("Nightly backup of the n8n SQLite store to Technijian backup storage with seven (7) day retention.", "bullets6"));
  content.push(bullet("Five (5) production workflows authored, tested with sample inputs, and exported as JSON: weekly-full-run (Sun 06:00 PT), daily-just-sold (Mon-Fri 07:00 PT), drb-on-meeting, weekly-tier1-email (Sun 10:00 PT), failure-escalation.", "bullets6"));
  content.push(bullet("Workflow documentation: trigger, nodes, error-branch, expected runtime, manual-rerun procedure.", "bullets6"));
  content.push(spacer());
  content.push(heading3("3.3.3 Schedule"));
  content.push(phaseSchedule([
    ["CTO Advisory", "n8n architecture, workflow patterns, security review", "4.0", "Week 2", "Ravi Jain"],
    ["US Senior Developer", "n8n install, HTTPS, backup, four production workflows", "16.0", "Week 2", "TBD"],
    ["Offshore Developer", "Workflow documentation, JSON exports, dependency tests", "8.0", "Week 2", "TBD"],
    ["", { text: "Total", bold: true }, { text: "28.0", bold: true }, "", ""]
  ]));
  content.push(spacer());

  // Phase 4
  content.push(heading2("Phase 4: Agent Harness on Claude Agent SDK (38 hrs)"));
  content.push(heading3("3.4.1 Description"));
  content.push(p("Build the agent harness as a Node.js service exposing seven (7) REST endpoints — one per agent — backed by the Claude Agent SDK. The harness handles authentication to Anthropic, per-agent system prompt loading, tool registration, JSON Schema validation on input and output, structured logging, per-run token budgeting, and credential redaction."));
  content.push(spacer());
  content.push(heading3("3.4.2 Deliverables"));
  content.push(bullet("Agent harness Node service in its own Docker container, listening on internal port 8080.", "bullets7"));
  content.push(bullet("REST endpoints: POST /agents/{agent-name}/run and GET /agents/{agent-name}/schema. Health endpoint at /health, version endpoint at /version.", "bullets7"));
  content.push(bullet("Per-agent configuration loaded from agents/<name>/system-prompt.md, tools.json, io-schema.json.", "bullets7"));
  content.push(bullet("Structured JSON-line logging at /var/log/bbc-harness/, mirrored into n8n.", "bullets7"));
  content.push(bullet("Per-run token budget: hard cap, soft warning, automatic redaction of any string matching credential patterns.", "bullets7"));
  content.push(bullet("API key authentication between n8n and the harness (shared-secret header).", "bullets7"));
  content.push(bullet("Unit-tested startup, shutdown, and request-handling paths.", "bullets7"));
  content.push(spacer());
  content.push(heading3("3.4.3 Schedule"));
  content.push(phaseSchedule([
    ["CTO Advisory", "Harness architecture, SDK selection, security review", "8.0", "Week 2-3", "Ravi Jain"],
    ["US Senior Developer", "Node service, SDK integration, schema validation, logging, auth", "30.0", "Week 2-3", "TBD"],
    ["", { text: "Total", bold: true }, { text: "38.0", bold: true }, "", ""]
  ]));
  content.push(spacer());

  // Phase 5
  content.push(heading2("Phase 5: Seven Production Agents (52 hrs)"));
  content.push(heading3("3.5.1 Description"));
  content.push(p("Author the seven production agents that wrap the existing pipeline code in Claude Agent SDK contracts. Each agent has a system prompt, a tool list, a JSON I/O schema, and unit tests against representative fixtures."));
  content.push(spacer());
  content.push(heading3("3.5.2 Deliverables"));
  content.push(bullet("pipeline-coordinator: selects layers per run, dispatches scrapers, aggregates results.", "bullets8"));
  content.push(bullet("permit-scraper: drives existing city / DRB / CDP / just-sold / Clerk-Recorder scrapers; per-city retry / skip; rate-limit honoring.", "bullets8"));
  content.push(bullet("scraper-healer: zero-lead / error diagnosis based on screenshots, network logs, self-heal report. Ports the existing scraper-troubleshooter subagent to the SDK.", "bullets8"));
  content.push(bullet("enrichment-coordinator: orchestrates ATTOM / BatchData / BatchLeads / Spokeo / Google Geocoding; minimizes spend per lead.", "bullets8"));
  content.push(bullet("scoring-analyst: applies scoring rubric; attaches \"why Tier 1\" narrative to high-tier leads.", "bullets8"));
  content.push(bullet("communication-drafter: drafts the weekly Tier 1 email with narrative context.", "bullets8"));
  content.push(bullet("run-supervisor: monitors n8n run, escalates failures, writes weekly summary.", "bullets8"));
  content.push(bullet("Per-agent unit tests against captured fixtures. Test coverage: each agent has at least three (3) representative test cases.", "bullets8"));
  content.push(bullet("Per-agent README documenting purpose, inputs, outputs, tools, and known limitations.", "bullets8"));
  content.push(spacer());
  content.push(heading3("3.5.3 Schedule"));
  content.push(phaseSchedule([
    ["CTO Advisory", "Per-agent prompt review, tool boundary validation", "6.0", "Week 3-4", "Ravi Jain"],
    ["US Senior Developer", "Agent prompts, tool wrappers, JSON schemas, fixture tests", "30.0", "Week 3-4", "TBD"],
    ["Offshore Developer", "Test fixtures, per-agent README, regression suite", "16.0", "Week 3-4", "TBD"],
    ["", { text: "Total", bold: true }, { text: "52.0", bold: true }, "", ""]
  ]));
  content.push(spacer());

  // Phase 6
  content.push(heading2("Phase 6: Wire Agents into n8n Workflows (20 hrs)"));
  content.push(heading3("3.6.1 Description"));
  content.push(p("Connect each n8n workflow to the appropriate sequence of agent endpoints, with retry policy, error branching, and observability. Validate end-to-end execution of each workflow against the April 27 baseline."));
  content.push(spacer());
  content.push(heading3("3.6.2 Deliverables"));
  content.push(bullet("Each workflow in Phase 3 wired to call the corresponding agent endpoints via the n8n HTTP Request node.", "bullets9"));
  content.push(bullet("Retry policy: each agent call retries up to two (2) times on 5xx or timeout, with exponential backoff.", "bullets9"));
  content.push(bullet("Error branching: any unrecoverable error routes to the failure-escalation workflow.", "bullets9"));
  content.push(bullet("Per-workflow observability: each n8n run produces a run-summary record consumed by the health dashboard.", "bullets9"));
  content.push(bullet("End-to-end validation: each workflow runs successfully against the April 27 baseline data within ±5% of expected lead counts.", "bullets9"));
  content.push(spacer());
  content.push(heading3("3.6.3 Schedule"));
  content.push(phaseSchedule([
    ["CTO Advisory", "Workflow review, observability standards", "2.0", "Week 4-5", "Ravi Jain"],
    ["US Senior Developer", "Workflow wiring, retry / error logic, end-to-end validation", "10.0", "Week 4-5", "TBD"],
    ["Offshore Developer", "Test runs, regression checks, n8n JSON snapshots", "8.0", "Week 4-5", "TBD"],
    ["", { text: "Total", bold: true }, { text: "20.0", bold: true }, "", ""]
  ]));
  content.push(spacer());

  // Phase 7
  content.push(heading2("Phase 7: Newport Beach 2FA Persistence (4 hrs)"));
  content.push(heading3("3.7.1 Description"));
  content.push(p("Perform one-time RDP-based interactive authentication into the Newport Beach Plan Check Portal using Kurtis Burkhart's Gmail second factor. Persist the Playwright user-data directory on the VM so subsequent runs proceed unattended. Document the re-authentication runbook."));
  content.push(spacer());
  content.push(heading3("3.7.2 Deliverables"));
  content.push(bullet("Newport Beach scraper proven to run unattended on the VM after one-time interactive 2FA.", "bullets10"));
  content.push(bullet("Re-authentication runbook: when the session expires, how to re-establish it via RDP without redeploying code.", "bullets10"));
  content.push(spacer());
  content.push(heading3("3.7.3 Schedule"));
  content.push(phaseSchedule([
    ["CTO Advisory", "Coordination with Kurtis for 2FA window", "1.0", "Week 5", "Ravi Jain"],
    ["US Senior Developer", "RDP session, persisted user-data, runbook, regression test", "3.0", "Week 5", "TBD"],
    ["", { text: "Total", bold: true }, { text: "4.0", bold: true }, "", ""]
  ]));
  content.push(spacer());

  // Phase 8
  content.push(heading2("Phase 8: Technijian-Internal Health Dashboard & Alerting (12 hrs)"));
  content.push(heading3("3.8.1 Description"));
  content.push(p("Build a Technijian-internal health dashboard that aggregates per-run health JSON from each workflow, surfaces it as a simple HTML page behind Technijian operator authentication, and pages the Technijian operator on consecutive failures. BBC does not access this dashboard; a one-line summary of the prior week's run health is appended to the BBC Tier 1 email so BBC has passive visibility without needing a login."));
  content.push(spacer());
  content.push(heading3("3.8.2 Deliverables"));
  content.push(bullet("Daily summary email to the Technijian operator mailbox showing run status of each scheduled workflow over the prior 24 hours.", "bullets11"));
  content.push(bullet("Two-consecutive-failure alert workflow that emails the Technijian operator with the full failure context.", "bullets11"));
  content.push(bullet("Technijian-internal HTML dashboard at the n8n root showing last-7-day workflow status, lead counts, and outstanding alerts (basic-auth protected, Technijian-internal network only).", "bullets11"));
  content.push(bullet("Weekly run-health summary line appended to the BBC Tier 1 email (e.g., \"This week: 5 of 5 scheduled runs succeeded; 643 raw records; 514 qualified leads after dedup\").", "bullets11"));
  content.push(spacer());
  content.push(heading3("3.8.3 Schedule"));
  content.push(phaseSchedule([
    ["CTO Advisory", "Alerting thresholds, escalation matrix", "2.0", "Week 5", "Ravi Jain"],
    ["US Senior Developer", "Dashboard, summary email workflow, alert workflow", "6.0", "Week 5", "TBD"],
    ["Offshore Developer", "HTML layout, test alerts, runbook", "4.0", "Week 5", "TBD"],
    ["", { text: "Total", bold: true }, { text: "12.0", bold: true }, "", ""]
  ]));
  content.push(spacer());

  // Phase 9
  content.push(heading2("Phase 9: Stabilization, Internal Runbook, & BBC Orientation (20 hrs)"));
  content.push(heading3("3.9.1 Description"));
  content.push(p("Run the full Technijian-managed system end-to-end for four (4) consecutive weeks. Fix any drift, source-site changes, or scoring miscalibration that surfaces during stabilization. Deliver the Technijian-internal operator runbook and a short BBC orientation call (audience: Bryan and Kurtis Burkhart, covering only what BBC receives and how to request changes)."));
  content.push(spacer());
  content.push(heading3("3.9.2 Deliverables"));
  content.push(bullet("Four (4) consecutive weekly runs completed successfully without manual intervention.", "bullets12"));
  content.push(bullet("Any in-flight scraper drift or source-site changes addressed within the 15% risk buffer.", "bullets12"));
  content.push(bullet("Technijian operator runbook covering: how to read n8n run logs, how to re-run a failed workflow, how to roll forward or roll back agent prompts, how to coordinate with Kurtis to re-authenticate Newport Beach, how to add a target HOA per BBC request, how to adjust the sale-price floor, escalation paths, key vault locations, harness log locations.", "bullets12"));
  content.push(bullet("BBC orientation call (30 minutes) with Bryan and Kurtis Burkhart covering only: what arrives in the weekly Tier 1 email, how to interpret the tier scoring and confidence indicators, how to request changes via email to Technijian, what triggers a Change Order versus what is included in managed operations, how to reach Technijian during a Newport Beach 2FA refresh window. No training on n8n, the agent harness, or any internal system is delivered to BBC.", "bullets12"));
  content.push(spacer());
  content.push(heading3("3.9.3 Schedule"));
  content.push(phaseSchedule([
    ["CTO Advisory", "Operator runbook authoring; BBC orientation call", "4.0", "Week 6-9", "Ravi Jain"],
    ["US Senior Developer", "Stabilization fixes, runbook screenshots, internal walkthrough", "8.0", "Week 6-9", "TBD"],
    ["Offshore Developer", "Regression checks, fixture refresh, archive of stabilization runs", "8.0", "Week 6-9", "TBD"],
    ["", { text: "Total", bold: true }, { text: "20.0", bold: true }, "", ""]
  ]));
  content.push(spacer());

  // 3.10 Schedule Summary
  content.push(heading2("3.10 Implementation Schedule Summary"));
  content.push(makeTable(
    ["Week", "Phase", "Milestone"],
    [
      ["1", "Phase 1 + 2", "VM operational, repo lifted, M365 Graph app-only send working"],
      ["2", "Phase 3 + 4 (start)", "n8n installed; agent harness scaffolded"],
      ["3", "Phase 4 + 5 (start)", "Agent harness complete; first three agents authored"],
      ["4", "Phase 5 + 6 (start)", "All seven agents complete; workflows wired"],
      ["5", "Phase 6 + 7 + 8", "End-to-end validation; Newport Beach 2FA done; health dashboard live"],
      ["6-9", "Phase 9", "Four-week stabilization, runbook, handoff"]
    ],
    [900, 2200, 7260]
  ));
  content.push(spacer());

  // 3.11 Cadence
  content.push(heading2("3.11 Production Run Cadence"));
  content.push(makeTable(
    ["Source", "Cadence", "Schedule", "Rationale"],
    [
      ["City Permits (8 OC cities)", "Weekly", "Sunday 06:00 Pacific", "Permits update slowly, weekly is sufficient"],
      ["DRB Agendas", "After each meeting", "Daily check, full scrape on new agenda", "Cities vary; coastal cities meet 2x/month"],
      ["Just-Sold Listings", "Daily", "Mon-Fri 07:00 Pacific", "Fresh sales go stale fast"],
      ["CDP + Clerk-Recorder", "Weekly", "Sunday 06:30 Pacific", "Filings infrequent"],
      ["Contact Enrichment", "On new leads", "After each scrape cycle", "Only enrich newly discovered leads"],
      ["Tier 1 Email", "Weekly", "Sunday 10:00 Pacific", "Consolidated digest after all scrapes"]
    ],
    [2400, 1800, 2600, 3560]
  ));
  content.push(spacer());

  // 3.12 Ongoing Operations
  content.push(heading2("3.12 Ongoing Operations"));
  content.push(p("After Final Acceptance (Section 8.05), the system enters operations mode:"));
  content.push(spacer());
  content.push(bullet("The Technijian-hosted VM continues to run n8n and the agent harness on the cadence in Section 3.11.", "bullets"));
  content.push(bullet("Daily-summary health email continues to the Technijian operator mailbox; two-consecutive-failure pages continue.", "bullets"));
  content.push(bullet("Day-to-day Technijian operator support (run-health review, weekly Tier 1 quality check, BBC change requests, scraper-drift first-line response, Newport Beach 2FA coordination) is billed at actual hours against Hourly Contract 5516 at the rates in Section 5.1 and invoiced weekly per the terms of that contract.", "bullets"));
  content.push(bullet("Source-site changes that require non-trivial re-engineering are tracked as Change Orders per Section 7.02 and billed against Hourly Contract 5516.", "bullets"));
  content.push(bullet("Anthropic API token usage is billed pass-through plus 15% admin in the recurring charges in Section 5.3, with a $200/month soft cap; overage above the cap is invoiced separately with Client notification.", "bullets"));
  content.push(bullet("Enrichment subscription overages above the contracted tier are invoiced separately with Client notification before the next tier is engaged.", "bullets"));
  content.push(bullet("The recurring charges in Section 5.3 cover infrastructure, enrichment subscriptions (within contracted tiers), and Anthropic API token usage (within the soft cap) only; all operator support, ad-hoc maintenance hours, source-site re-engineering, and feature additions bill separately per Hourly Contract 5516 or a written Change Order.", "bullets"));
  content.push(brandRule());

  // ---- 4. EQUIPMENT AND MATERIALS ----
  content.push(heading1("4. EQUIPMENT AND MATERIALS"));
  content.push(p("No hardware is supplied under this SOW. The system runs on a Technijian-hosted Windows Server VM, billed as a recurring monthly charge under Section 5.3. Third-party services (ATTOM Data, BatchData, BatchLeads, Spokeo, Google Cloud Geocoding) are procured by Technijian and billed pass-through plus 15% admin to Client in Section 5.3. Microsoft 365 license uplift (if required) is procured by and paid for directly by Client."));
  content.push(brandRule());

  // ---- 5. PRICING AND PAYMENT ----
  content.push(heading1("5. PRICING AND PAYMENT"));

  content.push(heading2("5.1 Reference Rate Card"));
  content.push(p("The build labor under this SOW is delivered at the fixed price in Section 5.2. The rates below are reference rates used for (a) Change Orders authorized under Section 7, (b) operator-support hours billed against the existing Hourly Contract 5516, and (c) any emergency work permitted under Section 7.03."));
  content.push(spacer());
  content.push(makeTable(
    ["Role", "Location", "Rate"],
    [
      ["CTO / AI Advisory (Ravi Jain)", "US (Remote)", "$250.00 / hr"],
      ["Senior Developer", "US (Remote)", "$150.00 / hr"],
      ["Offshore Developer", "Offshore (Remote)", "$45.00 / hr"],
      ["After-Hours Premium (CTO)", "US (Remote)", "$350.00 / hr"]
    ],
    [3600, 3200, 3560]
  ));
  content.push(spacer());
  content.push(p("Rates are fixed for the term of this engagement. Any rate changes require a written Change Order signed by both Parties."));
  content.push(spacer());

  content.push(heading2("5.2 Fixed-Fee Build Price"));
  content.push(p("The build phases defined in Section 3 are delivered at a fixed price of $26,360.00, regardless of actual hours expended by Technijian. Technijian assumes the risk of internal cost overrun on the scope defined in Section 3. Scope changes outside Section 3 are addressed by Change Order under Section 7.01."));
  content.push(spacer());
  content.push(p("The hour and role breakdown below shows how Technijian has scoped the effort. The fixed price equals the sum of labor at the reference rates in Section 5.1 with no risk premium added."));
  content.push(spacer());
  content.push(makeTable(
    ["Phase", "Role", "Hours", "Rate", "Cost"],
    [
      ["Phase 1 — VM Provisioning & Repo Lift", "CTO Advisory", "1.0", "$250.00", "$250.00"],
      ["Phase 1 — VM Provisioning & Repo Lift", "US Senior Developer", "4.0", "$150.00", "$600.00"],
      ["Phase 1 — VM Provisioning & Repo Lift", "Offshore Developer", "4.0", "$45.00", "$180.00"],
      ["Phase 2 — Secrets Migration & M365 Auth", "CTO Advisory", "1.0", "$250.00", "$250.00"],
      ["Phase 2 — Secrets Migration & M365 Auth", "US Senior Developer", "6.0", "$150.00", "$900.00"],
      ["Phase 3 — n8n Install & Workflows", "CTO Advisory", "4.0", "$250.00", "$1,000.00"],
      ["Phase 3 — n8n Install & Workflows", "US Senior Developer", "16.0", "$150.00", "$2,400.00"],
      ["Phase 3 — n8n Install & Workflows", "Offshore Developer", "8.0", "$45.00", "$360.00"],
      ["Phase 4 — Agent Harness", "CTO Advisory", "8.0", "$250.00", "$2,000.00"],
      ["Phase 4 — Agent Harness", "US Senior Developer", "30.0", "$150.00", "$4,500.00"],
      ["Phase 5 — Seven Production Agents", "CTO Advisory", "6.0", "$250.00", "$1,500.00"],
      ["Phase 5 — Seven Production Agents", "US Senior Developer", "30.0", "$150.00", "$4,500.00"],
      ["Phase 5 — Seven Production Agents", "Offshore Developer", "16.0", "$45.00", "$720.00"],
      ["Phase 6 — Wire Agents into n8n", "CTO Advisory", "2.0", "$250.00", "$500.00"],
      ["Phase 6 — Wire Agents into n8n", "US Senior Developer", "10.0", "$150.00", "$1,500.00"],
      ["Phase 6 — Wire Agents into n8n", "Offshore Developer", "8.0", "$45.00", "$360.00"],
      ["Phase 7 — Newport Beach 2FA", "CTO Advisory", "1.0", "$250.00", "$250.00"],
      ["Phase 7 — Newport Beach 2FA", "US Senior Developer", "3.0", "$150.00", "$450.00"],
      ["Phase 8 — Health Dashboard & Alerting", "CTO Advisory", "2.0", "$250.00", "$500.00"],
      ["Phase 8 — Health Dashboard & Alerting", "US Senior Developer", "6.0", "$150.00", "$900.00"],
      ["Phase 8 — Health Dashboard & Alerting", "Offshore Developer", "4.0", "$45.00", "$180.00"],
      ["Phase 9 — Testing, Stabilization & Handoff", "CTO Advisory", "4.0", "$250.00", "$1,000.00"],
      ["Phase 9 — Testing, Stabilization & Handoff", "US Senior Developer", "8.0", "$150.00", "$1,200.00"],
      ["Phase 9 — Testing, Stabilization & Handoff", "Offshore Developer", "8.0", "$45.00", "$360.00"],
      [{ text: "Fixed-Fee Build Price", bold: true, total: true }, { text: "", total: true }, { text: "190.0", bold: true, total: true }, { text: "", total: true }, { text: "$26,360.00", bold: true, total: true }]
    ],
    [3500, 1900, 1300, 1100, 1560]
  ));
  content.push(spacer());

  content.push(heading2("5.3 Recurring Operational Charges (Monthly)"));
  content.push(p("In addition to the one-time build labor in Section 5.2, the following recurring charges apply monthly for the operations term defined in Section 5.7. Hosting line items are priced per the Technijian Standard Rate Card. Enrichment and Anthropic charges are pass-through with a 15% administrative markup."));
  content.push(spacer());

  content.push(heading3("Hosting & Infrastructure"));
  content.push(makeTable(
    ["Code", "Service", "Unit Price / mo"],
    [
      ["CL-T4 (Bare VM)", "Cloud VM Tier 4 — 4 vCore / 16 GB RAM", "$35.00"],
      ["CL-T4 (Win)", "Windows Server license adder", "$30.00"],
      ["CL-SBW", "Cloud — Shared Bandwidth (per VM)", "$15.00"],
      ["TB-PSTR", "Production Storage (100 GB allocation)", "$20.00"],
      ["TB-BSTR", "Backup Storage (200 GB allocation)", "$10.00"],
      ["IB", "Image Backup (Veeam)", "$15.00"],
      ["PMW", "Patch Management", "$4.00"],
      ["AVS", "AV Protection — Server (CrowdStrike)", "$10.50"],
      ["AVHS", "AVH Protection — Server (Huntress)", "$6.00"],
      ["SI", "My Secure Internet (DNS filtering)", "$6.00"],
      ["MR", "My Remote (RDP)", "$2.00"],
      ["OPS-NET", "My Ops — Net (monitoring)", "$3.25"],
      ["SHM", "Health Monitoring", "$2.00"],
      [{ text: "Hosting Subtotal", bold: true, total: true }, { text: "", total: true }, { text: "$158.75 / mo", bold: true, total: true }]
    ],
    [2200, 5800, 2360]
  ));
  content.push(spacer());

  content.push(heading3("Lead Enrichment Subscriptions (pass-through + 15% admin)"));
  content.push(makeTable(
    ["Service", "Why It's Needed", "List Price", "+ 15% Admin"],
    [
      ["ATTOM Data API (Starter)", "Owner name and mailing address lookup from APN", "$299.00 / mo", "$343.85 / mo"],
      ["BatchData Skip-Trace", "Owner phone and email reverse-lookup", "~$84.00 / mo", "$96.60 / mo"],
      ["BatchLeads (Pro)", "Secondary skip-trace + bulk property data", "$99.00 / mo", "$113.85 / mo"],
      ["Spokeo (Professional)", "Fallback skip-trace when BatchData misses", "$49.95 / mo", "$57.44 / mo"],
      ["Google Cloud Geocoding API", "Address normalization + deduplication", "~$15.00 / mo", "$17.25 / mo"],
      [{ text: "Enrichment Subtotal", bold: true, total: true }, { text: "", total: true }, { text: "~$547 / mo", bold: true, total: true }, { text: "$629.00 / mo", bold: true, total: true }]
    ],
    [2700, 3800, 1900, 1960]
  ));
  content.push(spacer());

  content.push(heading3("Claude / Anthropic API Token Usage (pass-through + 15% admin, soft-capped)"));
  content.push(makeTable(
    ["Service", "Mechanism", "Soft Cap (+ 15% admin)"],
    [
      ["Anthropic API tokens (agent harness runtime)", "Pass-through plus 15% administrative markup", "$200.00 / mo"]
    ],
    [3700, 4300, 2360]
  ));
  content.push(spacer());
  content.push(p("Anthropic API token usage is billed pass-through at Anthropic's then-current published pricing for the Claude models in use (Opus, Sonnet, Haiku as appropriate per agent). Technijian adds a 15% administrative markup. Expected steady-state usage is $20-$80 / month. The $200 / month soft cap means Technijian will notify Client in writing before Anthropic spend exceeds $200 in any given month and will obtain Client confirmation before incurring overage. Overage above the soft cap is invoiced separately at pass-through plus 15%."));
  content.push(spacer());

  content.push(heading3("Technijian Operator Support (Billed Against Hourly Contract 5516, Invoiced Weekly)"));
  content.push(p("Technijian-side operation of the system — daily operator review of run health, weekly Tier 1 quality check, BBC change requests (target HOA additions, sale-price floor changes, scoring weight tweaks), first-line scraper-drift response, coordination of the Newport Beach 2FA refresh with Kurtis, and the monthly status email — is performed by Technijian on business hours and billed at actual hours against the existing Hourly Contract 5516 (signed 2026-03-10) at the rates in Section 5.1. All such hours are invoiced weekly under that contract. Operator support is not bundled into this SOW's recurring monthly charges."));
  content.push(spacer());
  content.push(p("Expected support load is 4-8 operator hours plus 1-2 CTO oversight hours per month in steady state, with occasional spikes when a source-site changes layout or adds new bot defenses (which become Change Orders under Section 7.02 if remediation exceeds the threshold defined there). Technijian shall provide Client with a monthly summary of operator hours billed under Hourly Contract 5516 alongside the recurring invoice for this SOW."));
  content.push(spacer());

  content.push(heading3("Total Recurring Subtotal"));
  content.push(makeTable(
    ["Component", "Monthly"],
    [
      ["Hosting & Infrastructure", "$158.75"],
      ["Lead Enrichment Subscriptions (pass-through + 15%)", "$629.00"],
      ["Anthropic API tokens (pass-through + 15%, soft-capped)", "up to $200.00"],
      [{ text: "Total Recurring (steady state, $50 token usage)", bold: true, total: true }, { text: "~$844.50", bold: true, total: true }],
      [{ text: "Total Recurring (with token soft cap reached)", bold: true, total: true }, { text: "~$987.75", bold: true, total: true }],
      ["Operator support (variable; billed against Hourly Contract 5516)", "not included above"]
    ],
    [7500, 2860]
  ));
  content.push(spacer());
  content.push(p("Recurring operational charges commence on the first day of Week 1 (concurrent with VM provisioning) and continue for the term defined in Section 5.7."));
  content.push(spacer());

  content.push(heading2("5.4 Invoicing and Payment Schedule"));
  content.push(bullet("Fixed-fee build. The $26,360 fixed-fee build price (Section 5.2) is invoiced in two equal installments of $13,180: 50% upon SOW execution and 50% upon Final Acceptance under Section 8.05.", "bullets"));
  content.push(bullet("Recurring hosting and enrichment. The monthly hosting and enrichment-subscription charges in Section 5.3 are invoiced on the first business day of each month, beginning the first business day of Week 1.", "bullets"));
  content.push(bullet("Anthropic API tokens. Pass-through token usage (with 15% admin markup) is invoiced monthly with the recurring hosting and enrichment charges. Any overage above the $200 / month soft cap is invoiced separately upon Client written confirmation.", "bullets"));
  content.push(bullet("Hourly operator support. All operator-support hours described in Section 3.12 and the relevant subsection of Section 5.3 are billed against the existing Hourly Contract 5516 and invoiced weekly per the terms of that contract, not under this SOW.", "bullets"));
  content.push(bullet("All invoices are due and payable within thirty (30) days of the invoice date.", "bullets"));
  content.push(spacer());

  content.push(heading2("5.5 Payment Terms"));
  content.push(p("All invoices are due and payable within thirty (30) days of the invoice date."));
  content.push(spacer());

  content.push(heading2("5.6 Late Payment and Collection Remedies"));
  content.push(p("Because no MSA is in effect between the Parties, the following standalone provisions apply:"));
  content.push(spacer());
  content.push(multiRun([
    { text: "(a) Late Payment. ", bold: true, color: CHARCOAL },
    { text: "Late payments shall accrue a late fee of 1.5% per month (or the maximum rate permitted by law, whichever is less) on the unpaid balance, calculated as simple interest from the date payment was due. The Parties acknowledge that the late fee represents a reasonable estimate of Technijian's administrative costs and damages resulting from late payment and is not a penalty." }
  ]));
  content.push(spacer());
  content.push(multiRun([
    { text: "(b) Acceleration. ", bold: true, color: CHARCOAL },
    { text: "If Client fails to pay any undisputed invoice within forty-five (45) days of the due date, all remaining fees under this SOW shall become immediately due and payable." }
  ]));
  content.push(spacer());
  content.push(multiRun([
    { text: "(c) Suspension. ", bold: true, color: CHARCOAL },
    { text: "Technijian may suspend all work under this SOW upon ten (10) days written notice if any invoice remains unpaid beyond the due date. Suspension shall not relieve Client of its payment obligations, and project timelines shall be adjusted accordingly at no cost to Technijian." }
  ]));
  content.push(spacer());
  content.push(multiRun([
    { text: "(d) Collection Costs and Attorney's Fees. ", bold: true, color: CHARCOAL },
    { text: "In any action or proceeding to collect fees, invoices, or other amounts owed under this SOW, the prevailing Party shall be entitled to recover all reasonable costs of collection, including attorney's fees (including in-house counsel at market rates), collection agency fees, court costs, arbitration fees, and all costs of appeal. Pursuant to California Civil Code Section 1717, the Parties acknowledge that this attorney's fees provision is reciprocal. This fee-shifting applies exclusively to collection of amounts owed and does not apply to disputes regarding service quality, professional performance, or other non-payment claims." }
  ]));
  content.push(spacer());
  content.push(multiRun([
    { text: "(e) Lien on Work Product. ", bold: true, color: CHARCOAL },
    { text: "Technijian shall retain a lien on all deliverables, work product, documentation, and materials (excluding Client Data) under this SOW until all amounts owed are paid in full." }
  ]));
  content.push(spacer());
  content.push(multiRun([
    { text: "(f) Fees for Non-Collection Disputes. ", bold: true, color: CHARCOAL },
    { text: "Except as provided in subsection (d) above, in any dispute arising under this SOW relating to service quality, professional performance, scope, or any other non-payment matter, each Party shall bear its own attorney's fees and costs." }
  ]));
  content.push(spacer());

  content.push(heading2("5.7 Term and Termination of Operations"));
  content.push(p("The recurring operational charges in Section 5.3 commence on the first day of Week 1 (concurrent with VM provisioning) and continue for an initial term of twelve (12) months from Final Acceptance (Section 8.05). After the initial term, operational charges automatically renew on a month-to-month basis."));
  content.push(spacer());
  content.push(p("Either Party may terminate the operations period with thirty (30) days' written notice. Upon termination, Technijian shall: (a) safely shut down the VM and the agent harness after exporting the data archive and the n8n workflow JSON snapshots; (b) hand over runbooks, agent system prompts, tool definitions, and credentials inventory; and (c) transfer or destroy at Client's direction any Technijian-held credentials."));
  content.push(spacer());
  content.push(p("Termination of operations does not affect any unbilled build labor or any open Change Order; those are invoiced and paid out under their existing terms. Termination of operations does not terminate any third-party enrichment subscription that Technijian has procured on Client's behalf; Client may elect to assume those subscriptions directly or instruct Technijian to cancel them at the next renewal date."));
  content.push(brandRule());

  // ---- 6. CLIENT RESPONSIBILITIES ----
  content.push(heading1("6. CLIENT RESPONSIBILITIES"));
  content.push(p("BBC's role in this engagement is intentionally light. The system is operated and managed entirely by Technijian; BBC has no operator responsibilities. BBC shall:"));
  content.push(spacer());
  content.push(bullet("(a) Provide any remaining credentials and account access required for the scrapers and enrichment services within five (5) business days of SOW execution. Where Technijian already holds working credentials from prior Hourly Contract 5516 work, those will be carried forward without further Client action;", "bullets"));
  content.push(bullet("(b) Designate Bryan Burkhart as the empowered point of contact for scope decisions, billing approvals, and Change Order sign-off, and Kurtis Burkhart as the recipient of the weekly Tier 1 lead email and the point person who provides Google second-factor confirmation when Technijian periodically re-authenticates the Newport Beach Plan Check Portal session;", "bullets"));
  content.push(bullet("(c) Review and approve build-phase deliverables at the end of each phase within five (5) business days of submission;", "bullets"));
  content.push(bullet("(d) Authorize Technijian's procurement of the VM hosting Service Order and the enrichment subscriptions (Section 5.3) before Phase 1 begins, and acknowledge that day-to-day operator support is billed at actual hours against existing Hourly Contract 5516;", "bullets"));
  content.push(bullet("(e) Acknowledge that scraping public records and listing sites is subject to source-site terms of service, rate limits, and bot defenses, and that Technijian cannot guarantee 100% scraper uptime against arbitrary source-site changes;", "bullets"));
  content.push(bullet("(f) Comply with all applicable real-estate solicitation laws (CAN-SPAM, TCPA, California state rules) when contacting any lead produced by the system. Client acknowledges that Technijian is not a law firm and is not providing legal or compliance advice;", "bullets"));
  content.push(bullet("(g) Send any requests to change the target HOA list, target city list, sale-price floor, or scoring rules by email to Technijian. All such adjustments are billed at actual operator hours against Hourly Contract 5516; larger structural changes that require re-engineering existing scrapers or agents are tracked as Change Orders under Section 7;", "bullets"));
  content.push(bullet("(h) Confirm in writing before Anthropic API token usage exceeds the $200 / month soft cap defined in Section 5.3 in any given month; and", "bullets"));
  content.push(bullet("(i) Provide Kurtis Burkhart's Google second-factor confirmation when Technijian initiates a Newport Beach 2FA refresh (expected once per 30-60 days, ten-minute coordination window).", "bullets"));
  content.push(brandRule());

  // ---- 7. CHANGE MANAGEMENT ----
  content.push(heading1("7. CHANGE MANAGEMENT"));
  content.push(multiRun([
    { text: "7.01. ", bold: true, color: CHARCOAL },
    { text: "Any changes to scope, schedule, or pricing of this SOW must be documented in a written Change Order signed by both Parties before work on the change begins." }
  ]));
  content.push(spacer());
  content.push(multiRun([
    { text: "7.02. ", bold: true, color: CHARCOAL },
    { text: "Non-trivial source-site changes (a target city portal redesign, a listing site adding new bot defenses, a vendor API breaking change) that require re-engineering of an existing scraper or enrichment integration shall be tracked as Change Orders. Technijian shall provide a Change Order with hours estimate before performing the re-engineering work, billed against Hourly Contract 5516 at the rates in Section 5.1." }
  ]));
  content.push(spacer());
  content.push(multiRun([
    { text: "7.03. ", bold: true, color: CHARCOAL },
    { text: "Because the build is fixed-fee under Section 5.2, Technijian absorbs any internal cost overrun on the scope defined in Section 3 and shall not bill Client for additional hours within that scope. Work outside the Section 3 scope requires a Change Order under Section 7.01. In cases where delay would cause imminent harm to Client's systems, Technijian may perform emergency work outside scope not to exceed $2,500 (at the Section 5.1 reference rates) and shall notify Client as soon as practicable, with a retrospective Change Order within three (3) business days." }
  ]));
  content.push(brandRule());

  // ---- 8. ACCEPTANCE ----
  content.push(heading1("8. ACCEPTANCE"));
  content.push(multiRun([
    { text: "8.01. ", bold: true, color: CHARCOAL },
    { text: "Upon completion of each phase listed in Section 3, Technijian shall notify Client in writing that the phase deliverables are ready for review." }
  ]));
  content.push(spacer());
  content.push(multiRun([
    { text: "8.02. ", bold: true, color: CHARCOAL },
    { text: "Client shall review the deliverables and provide written acceptance or a detailed description of deficiencies within five (5) business days of submission. Technijian's delivery notification shall include a conspicuous statement: \"If you do not respond within five (5) business days, this phase will be deemed accepted per SOW Section 8.03.\"" }
  ]));
  content.push(spacer());
  content.push(multiRun([
    { text: "8.03. ", bold: true, color: CHARCOAL },
    { text: "If Client does not respond within the review period, the phase shall be deemed accepted." }
  ]));
  content.push(spacer());
  content.push(multiRun([
    { text: "8.04. ", bold: true, color: CHARCOAL },
    { text: "If deficiencies are identified, Technijian shall correct them and resubmit for review. This process shall repeat until acceptance is achieved or the Parties agree on a resolution." }
  ]));
  content.push(spacer());
  content.push(multiRun([
    { text: "8.05. Final Acceptance. ", bold: true, color: CHARCOAL },
    { text: "Final acceptance of the entire system shall occur upon the successful delivery of four (4) consecutive weekly Tier 1 email reports (Sunday 10:00 AM Pacific) from the Technijian-hosted VM, executed end-to-end through n8n and the agent harness without manual operator intervention. The four-week count begins on the first Sunday after Phase 8 acceptance." }
  ]));
  content.push(brandRule());

  // ---- 9. GOVERNING TERMS ----
  content.push(heading1("9. GOVERNING TERMS"));
  content.push(multiRun([
    { text: "9.01. ", bold: true, color: CHARCOAL },
    { text: "No Master Service Agreement is currently in effect between the Parties. This SOW is a standalone engagement governed by the Technijian Standard Terms and Conditions (Appendix A, if attached) and the following minimum terms:" }
  ]));
  content.push(spacer());
  content.push(bullet("(a) Neither Party's total aggregate liability under this SOW shall exceed the total fees paid or payable under this SOW in the six (6) months preceding the claim.", "bullets"));
  content.push(bullet("(b) In no event shall either Party be liable for indirect, incidental, special, consequential, or punitive damages, including but not limited to lost profits, lost leads, or lost business opportunity.", "bullets"));
  content.push(bullet("(c) This SOW shall be governed by the laws of the State of California, without regard to conflict-of-laws principles. Any dispute shall be resolved by binding arbitration in Orange County, California, under the AAA Commercial Arbitration Rules, except that either Party may seek injunctive relief in court for protection of intellectual property or confidential information.", "bullets"));
  content.push(bullet("(d) Each Party shall keep the other's confidential information (including pricing, target HOA list, scoring rules, agent system prompts, and tool configurations) strictly confidential during the engagement and for three (3) years thereafter.", "bullets"));
  content.push(bullet("(e) Client retains ownership of all Client Data, including all leads, scores, and reports produced by the system. Technijian retains ownership of its pre-existing tools, methodologies, and templates (including the Technijian-branded DOCX template, the shared client-fit scoring engine, the agent harness framework, and the generic n8n workflow patterns, except to the extent of BBC-specific calibration or configuration). Client receives a perpetual, non-exclusive license to use the deliverables and configurations produced under this SOW for its internal business purposes.", "bullets"));
  content.push(spacer());
  content.push(multiRun([
    { text: "9.02. ", bold: true, color: CHARCOAL },
    { text: "If the Parties subsequently execute a Master Service Agreement, the terms of the MSA shall govern and supersede this Section 9 to the extent of any conflict." }
  ]));
  content.push(brandRule());

  // ---- SIGNATURES ----
  // Foxit eSign text tags embedded as WHITE text (invisible to reader, captured by
  // Foxit `processTextTags: True` on createfolder). Party 1 = Technijian (Ravi),
  // Party 2 = BBC (Bryan). Parallel signing (signInSequence: False).
  content.push(heading1("SIGNATURES"));
  content.push(spacer());
  content.push(p("TECHNIJIAN, INC.", { bold: true, color: CHARCOAL }));
  content.push(spacer());
  content.push(multiRun([
    { text: "By: " },
    { text: "${signfield:1:y:Tech_Sig:____________________________}", color: WHITE, size: 22 }
  ]));
  content.push(spacer());
  content.push(p("Name: Ravi Jain"));
  content.push(spacer());
  content.push(p("Title: Chief Executive Officer"));
  content.push(spacer());
  content.push(multiRun([
    { text: "Date: " },
    { text: "${datefield:1:y:Tech_Date:120:22}", color: WHITE, size: 22 }
  ]));
  content.push(spacer());
  content.push(spacer());
  content.push(p("BURKHART BROTHERS CONSTRUCTION, INC.", { bold: true, color: CHARCOAL }));
  content.push(spacer());
  content.push(multiRun([
    { text: "By: " },
    { text: "${signfield:2:y:BBC_Sig:____________________________}", color: WHITE, size: 22 }
  ]));
  content.push(spacer());
  content.push(p("Name: Bryan Burkhart"));
  content.push(spacer());
  content.push(multiRun([
    { text: "Title: " },
    { text: "${textfield:2:y:BBC_Title:240:22}", color: WHITE, size: 22 }
  ]));
  content.push(spacer());
  content.push(multiRun([
    { text: "Date: " },
    { text: "${datefield:2:y:BBC_Date:120:22}", color: WHITE, size: 22 }
  ]));

  // ===== BUILD DOCUMENT =====
  const doc = new Document({
    styles: docStyles,
    numbering,
    sections: [
      {
        properties: coverSectionProps(),
        children: coverPage(
          "Statement of Work",
          "Autonomous Lead Generation System — Automation Phase — Burkhart Brothers Construction, Inc."
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
