const pptxgen = require("pptxgenjs");
const path = require("path");

const pres = new pptxgen();
pres.layout = "LAYOUT_16x9";
pres.author = "Technijian, Inc.";
pres.title = "Aranda Tooling Network Assessment — Executive Readout to DSBJ";
pres.company = "Technijian, Inc.";
pres.subject = "Network Assessment Findings, Remediation Roadmap, and Managed Services";

// ===== BRAND COLORS (no # prefix — pptxgenjs requirement) =====
const CORE_ORANGE = "F67D4B";
const CORE_BLUE = "006DB6";
const TEAL = "1EAAC8";
const DARK_CHARCOAL = "1A1A2E";
const BRAND_GREY = "59595B";
const OFF_WHITE = "F8F9FA";
const WHITE = "FFFFFF";
const LIGHT_GREY = "E9ECEF";

// Severity colors
const CRIT_RED = "C62828";
const HIGH_ORANGE = "E65100";
const MOD_AMBER = "F9A825";
const LOW_GREEN = "2E7D32";

// ===== LOGO PATHS (from tech-branding assets) =====
const brandDir = "c:/vscode/tech-branding/tech-branding/assets/logos/png";
const logoLight = path.join(brandDir, "technijian-logo-full-color-1200x251.png");
const logoDark = path.join(brandDir, "technijian-logo-reverse-white-5000x1667.png");

// ===== HELPERS =====
function addHeaderBar(slide) {
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 10, h: 0.9, fill: { color: CORE_BLUE }
  });
  slide.addImage({ path: logoDark, x: 0.4, y: 0.2, w: 1.5, h: 0.31 });
}

function addFooter(slide, pageText) {
  slide.addShape(pres.shapes.LINE, {
    x: 0.6, y: 5.2, w: 8.8, h: 0, line: { color: LIGHT_GREY, width: 0.75 }
  });
  slide.addText("technijian.com  |  Confidential — Prepared for DSBJ / Aranda Tooling", {
    x: 0.6, y: 5.25, w: 6, h: 0.3, fontSize: 9, fontFace: "Open Sans", color: BRAND_GREY, margin: 0
  });
  if (pageText) {
    slide.addText(pageText, {
      x: 6.6, y: 5.25, w: 2.8, h: 0.3,
      fontSize: 9, fontFace: "Open Sans", color: BRAND_GREY, align: "right", margin: 0
    });
  }
}

function addTitle(slide, text) {
  slide.addText(text, {
    x: 0.6, y: 1.1, w: 8.8, h: 0.7,
    fontSize: 26, fontFace: "Open Sans", bold: true, color: CORE_BLUE, margin: 0
  });
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0.6, y: 1.8, w: 0.8, h: 0.05, fill: { color: CORE_ORANGE }
  });
}

function addContentSlide() {
  const s = pres.addSlide();
  s.background = { color: WHITE };
  addHeaderBar(s);
  return s;
}

function addSectionDivider(number, title, description) {
  const s = pres.addSlide();
  s.background = { color: CORE_BLUE };
  s.addText(number, {
    x: 0.6, y: 1.0, w: 8.8, h: 1.0,
    fontSize: 60, fontFace: "Open Sans", bold: true,
    color: WHITE, align: "center", margin: 0, transparency: 30
  });
  s.addText(title, {
    x: 0.6, y: 2.2, w: 8.8, h: 1.2,
    fontSize: 32, fontFace: "Open Sans", bold: true,
    color: WHITE, align: "center", margin: 0
  });
  s.addShape(pres.shapes.LINE, {
    x: 3.5, y: 3.5, w: 3, h: 0,
    line: { color: WHITE, width: 1.5, transparency: 50 }
  });
  s.addText(description, {
    x: 1.5, y: 3.8, w: 7, h: 0.6,
    fontSize: 16, fontFace: "Open Sans",
    color: WHITE, align: "center", margin: 0, transparency: 20
  });
  s.addImage({ path: logoDark, x: 0.4, y: 5.0, w: 1.6, h: 0.33 });
  return s;
}

// ============================================================
// SLIDE 1: Title Slide
// ============================================================
{
  const s = pres.addSlide();
  s.background = { color: DARK_CHARCOAL };
  s.addImage({ path: logoDark, x: 0.6, y: 0.4, w: 2.4, h: 0.5 });
  s.addText("Aranda Tooling Network Assessment", {
    x: 0.6, y: 1.6, w: 8.8, h: 1.0,
    fontSize: 36, fontFace: "Open Sans", bold: true, color: WHITE, margin: 0
  });
  s.addText("Executive Readout to DSBJ Parent Leadership", {
    x: 0.6, y: 2.6, w: 8.8, h: 0.5,
    fontSize: 20, fontFace: "Open Sans", color: CORE_ORANGE, margin: 0
  });
  s.addText([
    { text: "Findings, Remediation Roadmap, and Managed Services Proposal", options: { breakLine: true, color: LIGHT_GREY, fontSize: 16 } },
    { text: "", options: { breakLine: true, fontSize: 8 } },
    { text: "Prepared by Technijian, Inc.  |  May 2026", options: { color: LIGHT_GREY, fontSize: 14 } }
  ], {
    x: 0.6, y: 3.3, w: 8.8, h: 1.2, fontFace: "Open Sans", margin: 0
  });
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 5.35, w: 10, h: 0.08, fill: { color: CORE_ORANGE }
  });
  s.addText("technology as a solution", {
    x: 5.5, y: 4.8, w: 4, h: 0.4,
    fontSize: 11, fontFace: "Open Sans", color: TEAL,
    align: "right", charSpacing: 3, margin: 0
  });
  s.addNotes(
    "Good morning/afternoon. Thank you for making time. " +
    "I am Ravi Jain, CEO of Technijian. Today's readout covers the network assessment we performed for Aranda Tooling at the Chino, California facility — a DSBJ group operating company. " +
    "Our goal today is straightforward: give DSBJ leadership a clear, honest picture of what the network looks like, where the real risks are, how we will fix them, and what the fixes mean for the business — particularly for compliance, manufacturing uptime, and group-level cyber-risk posture. " +
    "We'll close with how Technijian can provide ongoing managed support alongside Aranda's existing on-site IT team."
  );
}

// ============================================================
// SLIDE 2: Agenda
// ============================================================
{
  const s = addContentSlide();
  addTitle(s, "Today's Agenda");
  s.addText([
    { text: "1.  What we assessed", options: { bold: true, color: DARK_CHARCOAL, breakLine: true, paraSpaceAfter: 10, fontSize: 16 } },
    { text: "2.  What we found — positives and concerns", options: { bold: true, color: DARK_CHARCOAL, breakLine: true, paraSpaceAfter: 10, fontSize: 16 } },
    { text: "3.  What the issues mean for the business", options: { bold: true, color: DARK_CHARCOAL, breakLine: true, paraSpaceAfter: 10, fontSize: 16 } },
    { text: "4.  How we will fix it — 72-hour / 30-day / 90-day plan", options: { bold: true, color: DARK_CHARCOAL, breakLine: true, paraSpaceAfter: 10, fontSize: 16 } },
    { text: "5.  What the fixes deliver — compliance, uptime, governance", options: { bold: true, color: DARK_CHARCOAL, breakLine: true, paraSpaceAfter: 10, fontSize: 16 } },
    { text: "6.  Ongoing managed services — augmenting on-site IT with 24x7 support", options: { bold: true, color: DARK_CHARCOAL, breakLine: true, paraSpaceAfter: 10, fontSize: 16 } },
    { text: "7.  Next steps", options: { bold: true, color: DARK_CHARCOAL, fontSize: 16 } }
  ], {
    x: 0.8, y: 2.1, w: 8.4, h: 3.0,
    fontFace: "Open Sans", color: BRAND_GREY, margin: 0
  });
  addFooter(s, "2");
  s.addNotes(
    "Seven short sections. I will keep each tight so we have time for questions. " +
    "The most important section for DSBJ leadership is Section 3 — what the issues mean for the business — and Section 5 — what the fixes deliver. " +
    "If time is short, I will prioritize those two sections and the ongoing support conversation."
  );
}

// ============================================================
// SECTION 1 DIVIDER
// ============================================================
addSectionDivider("01", "What We Assessed", "Scope, evidence reviewed, and assumptions")
  .addNotes(
    "This section is brief — just to level-set so everyone knows what this report is based on and, equally important, what it is not based on."
  );

// ============================================================
// SLIDE 4: What we assessed — scope
// ============================================================
{
  const s = addContentSlide();
  addTitle(s, "What We Assessed");

  // Left column — Evidence reviewed
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0.6, y: 2.0, w: 4.3, h: 3.0, fill: { color: OFF_WHITE }
  });
  s.addText([
    { text: "Evidence Reviewed", options: { bold: true, fontSize: 16, color: CORE_BLUE, breakLine: true, paraSpaceAfter: 8 } },
    { text: "•  Supplied network topology diagram", options: { breakLine: true, fontSize: 12, color: BRAND_GREY } },
    { text: "•  4 Aranda-branded Cisco SMB switch configs", options: { breakLine: true, fontSize: 12, color: BRAND_GREY } },
    { text: "•  6 Netgear Smart/Plus switch exports", options: { breakLine: true, fontSize: 12, color: BRAND_GREY } },
    { text: "•  Meraki MX firewall posture (via Dashboard)", options: { breakLine: true, fontSize: 12, color: BRAND_GREY } },
    { text: "•  Meraki MS switch configuration", options: { breakLine: true, fontSize: 12, color: BRAND_GREY } },
    { text: "•  Segmentation across Office, Guest, IoT, Printer, and OT VLANs", options: { fontSize: 12, color: BRAND_GREY } }
  ], {
    x: 0.85, y: 2.15, w: 3.85, h: 2.75, fontFace: "Open Sans", margin: 0, lineSpacingMultiple: 1.25
  });

  // Right column — Out of scope
  s.addShape(pres.shapes.RECTANGLE, {
    x: 5.1, y: 2.0, w: 4.3, h: 3.0, fill: { color: OFF_WHITE }
  });
  s.addText([
    { text: "What This Is NOT", options: { bold: true, fontSize: 16, color: CORE_BLUE, breakLine: true, paraSpaceAfter: 8 } },
    { text: "•  Penetration test or red-team engagement", options: { breakLine: true, fontSize: 12, color: BRAND_GREY } },
    { text: "•  Endpoint or server audit", options: { breakLine: true, fontSize: 12, color: BRAND_GREY } },
    { text: "•  Compliance attestation (SOC 2, ISO 27001, etc.)", options: { breakLine: true, fontSize: 12, color: BRAND_GREY } },
    { text: "•  OT process-control / PLC audit", options: { breakLine: true, fontSize: 12, color: BRAND_GREY } },
    { text: "•  Remediation execution — this is an assessment only", options: { fontSize: 12, color: BRAND_GREY } }
  ], {
    x: 5.35, y: 2.15, w: 3.85, h: 2.75, fontFace: "Open Sans", margin: 0, lineSpacingMultiple: 1.25
  });

  addFooter(s, "3");
  s.addNotes(
    "We reviewed configuration evidence — both the switch exports Aranda's team provided and live Meraki Dashboard data that was made available during the engagement. " +
    "This is a configuration-driven assessment, not a penetration test, compliance attestation, or OT/PLC audit. " +
    "What that means for you: findings are grounded in actual device configs, not theory. But they describe the design and hygiene of the network — they don't prove or disprove whether anyone has already been inside it. If you want that, it would be a separate engagement."
  );
}

// ============================================================
// SECTION 2 DIVIDER — Findings
// ============================================================
addSectionDivider("02", "What We Found", "Positives, concerns, and risk-ranked findings")
  .addNotes("Three short slides: positives first, then the risk-ranked findings, then the deep dive on the one critical item.");

// ============================================================
// SLIDE 6: Positives
// ============================================================
{
  const s = addContentSlide();
  addTitle(s, "Positives — Worth Preserving");
  s.addText([
    { text: "The network is functional, segmented, and recoverable.", options: { bold: true, color: DARK_CHARCOAL, fontSize: 16, breakLine: true, paraSpaceAfter: 14 } },
    { text: "✓  VLAN-based segmentation is already in place across Office, Guest, Services, IoT, Printers, and OT — not a flat network.", options: { breakLine: true, color: BRAND_GREY, fontSize: 14, paraSpaceAfter: 10 } },
    { text: "✓  Supplied topology diagram aligns with recovered switch addressing — better starting point than most SMB environments.", options: { breakLine: true, color: BRAND_GREY, fontSize: 14, paraSpaceAfter: 10 } },
    { text: "✓  Office, Guest, Printer, IoT, and OT zones are already separated at the logical-design level.", options: { breakLine: true, color: BRAND_GREY, fontSize: 14, paraSpaceAfter: 10 } },
    { text: "✓  Switch estate is documentable and recoverable — this is not a redesign-from-scratch situation.", options: { color: BRAND_GREY, fontSize: 14 } }
  ], {
    x: 0.8, y: 2.1, w: 8.4, h: 3.0, fontFace: "Open Sans", margin: 0
  });
  addFooter(s, "4");
  s.addNotes(
    "I want to lead with what's working, because it matters. Aranda's team has built a network that is functional and logically segmented. " +
    "The seven VLANs we see — Office, Office Wireless, Guest Wi-Fi, Services, IoT, Printers, and OT — indicate that someone has been thinking about segmentation for a while. " +
    "That's the foundation we're going to build on. This engagement is about standardization and hygiene, not a rebuild."
  );
}

// ============================================================
// SLIDE 7: Risk-Ranked Findings Table
// ============================================================
{
  const s = addContentSlide();
  addTitle(s, "Risk-Ranked Findings");

  const rows = [
    [
      { text: "Severity", options: { bold: true, color: WHITE, fill: CORE_BLUE, align: "center" } },
      { text: "Finding", options: { bold: true, color: WHITE, fill: CORE_BLUE } },
      { text: "Domain", options: { bold: true, color: WHITE, fill: CORE_BLUE } }
    ],
    [
      { text: "CRITICAL", options: { bold: true, color: WHITE, fill: CRIT_RED, align: "center" } },
      { text: "Private keys and certificates embedded in switch backup exports", options: { color: DARK_CHARCOAL } },
      { text: "Cyber Security", options: { color: BRAND_GREY } }
    ],
    [
      { text: "HIGH", options: { bold: true, color: WHITE, fill: HIGH_ORANGE, align: "center" } },
      { text: "Privileged local account model is not standardized across devices", options: { color: DARK_CHARCOAL } },
      { text: "Access Control", options: { color: BRAND_GREY } }
    ],
    [
      { text: "HIGH", options: { bold: true, color: WHITE, fill: HIGH_ORANGE, align: "center" } },
      { text: "Management plane is inconsistent (10.10.0.0/16 vs 10.28.x.x)", options: { color: DARK_CHARCOAL } },
      { text: "Operational", options: { color: BRAND_GREY } }
    ],
    [
      { text: "MODERATE", options: { bold: true, color: WHITE, fill: MOD_AMBER, align: "center" } },
      { text: "Segmentation enforcement not fully verified end-to-end", options: { color: DARK_CHARCOAL } },
      { text: "Architecture", options: { color: BRAND_GREY } }
    ],
    [
      { text: "MODERATE", options: { bold: true, color: WHITE, fill: MOD_AMBER, align: "center" } },
      { text: "Non-standard trunk/native VLAN combinations on several ports", options: { color: DARK_CHARCOAL } },
      { text: "Configuration", options: { color: BRAND_GREY } }
    ],
    [
      { text: "MODERATE", options: { bold: true, color: WHITE, fill: MOD_AMBER, align: "center" } },
      { text: "Mixed small-business / Plus-class switching in production", options: { color: DARK_CHARCOAL } },
      { text: "Supportability", options: { color: BRAND_GREY } }
    ]
  ];

  s.addTable(rows, {
    x: 0.5, y: 2.0, w: 9.0,
    colW: [1.3, 5.6, 2.1],
    fontFace: "Open Sans", fontSize: 11, valign: "middle",
    border: { type: "solid", color: LIGHT_GREY, pt: 0.5 },
    rowH: 0.42
  });
  addFooter(s, "5");
  s.addNotes(
    "One Critical, two Highs, and three Moderates. No Lows on this slide because we kept the view leadership-relevant. " +
    "I will spend the next slide on the Critical item — it's the one that would show up in a DSBJ board-level cyber report and is the fastest thing we can fix. " +
    "The two Highs are operational hygiene items: named admin accounts and management-plane consistency. These are not breach events today, but they are how breaches get worse once they start, and they are what auditors want to see normalized. " +
    "The Moderates are about getting Aranda to an enterprise-class standard — segmentation verification, port-level configuration cleanup, and a decision about the Netgear Plus devices in production."
  );
}

// ============================================================
// SLIDE 8: Critical finding deep-dive
// ============================================================
{
  const s = addContentSlide();
  addTitle(s, "The Critical Finding — In Plain Terms");

  // Left — The issue
  s.addShape(pres.shapes.RECTANGLE, { x: 0.6, y: 2.0, w: 0.15, h: 3.0, fill: { color: CRIT_RED } });
  s.addText([
    { text: "What we found", options: { bold: true, color: CRIT_RED, fontSize: 14, breakLine: true, paraSpaceAfter: 8 } },
    { text: "Several switch backup files contain full private cryptographic keys and local administrative information in plain text.", options: { breakLine: true, color: BRAND_GREY, fontSize: 13, paraSpaceAfter: 10 } },
    { text: "Why this matters", options: { bold: true, color: CRIT_RED, fontSize: 14, breakLine: true, paraSpaceAfter: 8 } },
    { text: "If those backups were ever emailed, stored on a shared drive, or handled outside a secured vault, trust on those devices must be treated as exposed.", options: { breakLine: true, color: BRAND_GREY, fontSize: 13, paraSpaceAfter: 10 } },
    { text: "This is a cyber-risk finding, not a documentation issue.", options: { italic: true, color: DARK_CHARCOAL, fontSize: 13 } }
  ], {
    x: 0.95, y: 2.05, w: 4.3, h: 3.0, fontFace: "Open Sans", margin: 0, lineSpacingMultiple: 1.25
  });

  // Right — What to do
  s.addShape(pres.shapes.RECTANGLE, { x: 5.5, y: 2.0, w: 3.9, h: 3.0, fill: { color: OFF_WHITE } });
  s.addText([
    { text: "First 72 hours", options: { bold: true, color: CORE_BLUE, fontSize: 14, breakLine: true, paraSpaceAfter: 8 } },
    { text: "1.  Rotate switch admin credentials", options: { breakLine: true, color: BRAND_GREY, fontSize: 12, paraSpaceAfter: 4 } },
    { text: "2.  Regenerate SSH keys and local certificates", options: { breakLine: true, color: BRAND_GREY, fontSize: 12, paraSpaceAfter: 4 } },
    { text: "3.  Restrict access to all historical backup archives", options: { breakLine: true, color: BRAND_GREY, fontSize: 12, paraSpaceAfter: 4 } },
    { text: "4.  Identify who received the files", options: { breakLine: true, color: BRAND_GREY, fontSize: 12, paraSpaceAfter: 4 } },
    { text: "5.  Move to vault-based backup handling going forward", options: { color: BRAND_GREY, fontSize: 12 } }
  ], {
    x: 5.7, y: 2.15, w: 3.65, h: 2.75, fontFace: "Open Sans", margin: 0, lineSpacingMultiple: 1.2
  });

  addFooter(s, "6");
  s.addNotes(
    "I want to be direct about this one because it's the most important slide for DSBJ leadership. " +
    "Switch configuration backups at Aranda contain private keys and certificates in the clear. Those files existed on systems accessible to administrators and were shared with us as part of this engagement. " +
    "We must assume the trust represented by those keys is compromised — not because there has been an intrusion, but because the material was outside a secured vault. " +
    "The fix is a 72-hour program. Rotate credentials, regenerate keys, lock down the historical archives, confirm distribution, and move to secure backup handling. None of this requires downtime or production impact. " +
    "This is the one item I would recommend starting on the day this SOW is signed, regardless of the rest of the roadmap."
  );
}

// ============================================================
// SECTION 3 DIVIDER — What it means
// ============================================================
addSectionDivider("03", "What It Means", "Business impact: uptime, compliance, and group-level cyber risk")
  .addNotes("One slide to translate the technical findings into the language DSBJ leadership cares about: revenue, audit, governance.");

// ============================================================
// SLIDE 10: Business impact
// ============================================================
{
  const s = addContentSlide();
  addTitle(s, "What the Findings Mean for the Business");

  const cards = [
    {
      x: 0.5, title: "Manufacturing Uptime",
      body: "Mixed vendor stack and non-standard trunk configurations are the most common cause of outages during moves/adds/changes at small-plant scale. A stamping-line outage driven by a configuration change is a revenue event."
    },
    {
      x: 3.55, title: "Cyber / Governance",
      body: "Embedded private keys + non-standardized privileged accounts are two of the most common findings in cyber insurance renewals and parent-company security reviews. Both are straightforward to close."
    },
    {
      x: 6.6, title: "Auditability",
      body: "Inconsistent management addressing and undocumented Meraki aggregation make incident response slower and make it harder to demonstrate IT hygiene to ISO, customer, or group auditors."
    }
  ];
  cards.forEach(c => {
    s.addShape(pres.shapes.RECTANGLE, { x: c.x, y: 2.0, w: 2.95, h: 3.0, fill: { color: OFF_WHITE } });
    s.addShape(pres.shapes.RECTANGLE, { x: c.x, y: 2.0, w: 2.95, h: 0.08, fill: { color: CORE_ORANGE } });
    s.addText(c.title, {
      x: c.x + 0.15, y: 2.15, w: 2.65, h: 0.5,
      fontSize: 15, fontFace: "Open Sans", bold: true, color: CORE_BLUE, margin: 0
    });
    s.addText(c.body, {
      x: c.x + 0.15, y: 2.65, w: 2.65, h: 2.25,
      fontSize: 11, fontFace: "Open Sans", color: BRAND_GREY, margin: 0, lineSpacingMultiple: 1.3
    });
  });

  addFooter(s, "7");
  s.addNotes(
    "Three lenses. " +
    "Manufacturing uptime — Aranda is a tool-and-die and stamping operation; its risk isn't data breach in the traditional sense, it's avoidable downtime on the production floor driven by a bad configuration change. " +
    "Cyber and governance — DSBJ is publicly traded. Anything the group CISO or an insurer would flag in a review — embedded keys, shared admin accounts — should be cleaned up before it shows up in the wrong context. " +
    "Auditability — manufacturing customers increasingly require supplier cybersecurity attestations. ISO 9001 doesn't directly require cyber controls, but the management-system mindset — documented, repeatable, controlled — is exactly the discipline we'll apply to the network."
  );
}

// ============================================================
// SECTION 4 DIVIDER — The Fix
// ============================================================
addSectionDivider("04", "How We Fix It", "72-hour / 30-day / 90-day remediation roadmap")
  .addNotes("This is the practical slide — the roadmap. Timeboxed, prioritized, and designed to avoid production-floor disruption.");

// ============================================================
// SLIDE 12: Roadmap
// ============================================================
{
  const s = addContentSlide();
  addTitle(s, "72-Hour / 30-Day / 90-Day Roadmap");

  const cols = [
    {
      x: 0.5, color: CRIT_RED, label: "FIRST 72 HOURS", sub: "Stop the bleeding",
      items: [
        "Rotate switch admin credentials",
        "Regenerate SSH keys and certificates",
        "Restrict access to historical backup archives",
        "Retire unused / unclear devices (arandaswitch04, legacy Netgear)"
      ]
    },
    {
      x: 3.55, color: HIGH_ORANGE, label: "30 DAYS", sub: "Stabilize and standardize",
      items: [
        "Normalize management addressing, NTP, logging, naming",
        "Build definitive port map (uplinks, APs, IDFs, OT)",
        "Validate trunk/native VLAN on every uplink",
        "Align on named administrative access",
        "Secure backup handling and change control"
      ]
    },
    {
      x: 6.6, color: CORE_BLUE, label: "90 DAYS", sub: "Strategic modernization",
      items: [
        "Decide on long-term switching standard",
        "Consolidate management and monitoring under MSP model",
        "End-to-end segmentation policy review",
        "Source-of-truth topology + inventory document",
        "Post-remediation validation assessment"
      ]
    }
  ];

  cols.forEach(col => {
    s.addShape(pres.shapes.RECTANGLE, { x: col.x, y: 2.0, w: 2.95, h: 0.55, fill: { color: col.color } });
    s.addText(col.label, {
      x: col.x, y: 2.0, w: 2.95, h: 0.3,
      fontSize: 12, fontFace: "Open Sans", bold: true, color: WHITE, align: "center", valign: "middle", margin: 0
    });
    s.addText(col.sub, {
      x: col.x, y: 2.25, w: 2.95, h: 0.3,
      fontSize: 10, fontFace: "Open Sans", color: WHITE, align: "center", valign: "middle", margin: 0, italic: true
    });
    s.addShape(pres.shapes.RECTANGLE, { x: col.x, y: 2.55, w: 2.95, h: 2.45, fill: { color: OFF_WHITE } });
    s.addText(col.items.map((t, i) => ({
      text: "•  " + t,
      options: { breakLine: i < col.items.length - 1, fontSize: 11, color: BRAND_GREY, paraSpaceAfter: 6 }
    })), {
      x: col.x + 0.15, y: 2.7, w: 2.65, h: 2.2, fontFace: "Open Sans", margin: 0, lineSpacingMultiple: 1.2
    });
  });

  addFooter(s, "8");
  s.addNotes(
    "Three time buckets. " +
    "First 72 hours: stop the bleeding — credential rotation, key regeneration, backup-archive lockdown. No production impact, mostly done after-hours or in small windows. " +
    "30 days: normalize the environment — one management standard, one admin-account model, a real port map, validated trunks, and secure backup handling. This is the bulk of the labor. " +
    "90 days: strategic — the big decision is what to do with the mixed small-business Netgear stack. Either isolate it to low-risk roles or consolidate to the Meraki platform. We'll recommend the right path based on Phase-2 findings. " +
    "None of this requires a weekend shutdown of the stamping lines. Everything is done in controlled change windows, coordinated with Aranda's on-site team."
  );
}

// ============================================================
// SECTION 5 DIVIDER — Value
// ============================================================
addSectionDivider("05", "What the Fixes Deliver", "Compliance, uptime, and group-level governance benefits")
  .addNotes("This slide ties back to DSBJ priorities: publicly traded manufacturer with quality-management discipline.");

// ============================================================
// SLIDE 14: Value to the business
// ============================================================
{
  const s = addContentSlide();
  addTitle(s, "Value Delivered to DSBJ / Aranda");

  const rows = [
    [
      { text: "Outcome", options: { bold: true, color: WHITE, fill: CORE_BLUE, align: "center" } },
      { text: "What It Means in Practice", options: { bold: true, color: WHITE, fill: CORE_BLUE } }
    ],
    [
      { text: "Compliance posture", options: { bold: true, color: DARK_CHARCOAL, fill: OFF_WHITE } },
      { text: "Named-admin access, secure backup handling, centralized logging — direct controls expected by cyber-insurance renewals, customer supplier reviews, and ISO management-system audits", options: { color: BRAND_GREY } }
    ],
    [
      { text: "Manufacturing uptime", options: { bold: true, color: DARK_CHARCOAL } },
      { text: "Validated trunks, documented port maps, and standardized change control reduce the #1 source of avoidable outages — unintended config changes during moves/adds/changes", options: { color: BRAND_GREY } }
    ],
    [
      { text: "OT / IT segmentation", options: { bold: true, color: DARK_CHARCOAL, fill: OFF_WHITE } },
      { text: "End-to-end verified separation between production OT and office IT — the control DSBJ's group CISO and your insurer will ask about by name", options: { color: BRAND_GREY } }
    ],
    [
      { text: "Audit readiness", options: { bold: true, color: DARK_CHARCOAL } },
      { text: "Source-of-truth topology, current device inventory, and documented management standard make customer audits, insurer reviews, and group reporting fast instead of painful", options: { color: BRAND_GREY } }
    ],
    [
      { text: "Recoverability", options: { bold: true, color: DARK_CHARCOAL, fill: OFF_WHITE } },
      { text: "Secure config backups and a documented management plane cut network-recovery time from days to hours in the event of a device failure or incident", options: { color: BRAND_GREY } }
    ]
  ];

  s.addTable(rows, {
    x: 0.5, y: 2.0, w: 9.0, colW: [2.3, 6.7],
    fontFace: "Open Sans", fontSize: 11, valign: "middle",
    border: { type: "solid", color: LIGHT_GREY, pt: 0.5 },
    rowH: 0.55
  });
  addFooter(s, "9");
  s.addNotes(
    "Five outcomes, each mapped to something a DSBJ leader or stakeholder actually asks about. " +
    "Compliance posture — the items cyber insurers look for at renewal and customers ask for in supplier reviews. " +
    "Manufacturing uptime — fewer avoidable outages on the floor. " +
    "OT / IT segmentation — the one control every group CISO asks about by name for a manufacturing subsidiary. " +
    "Audit readiness — when a customer or auditor asks 'show me your network,' you have a document instead of a scramble. " +
    "Recoverability — if a switch fails at 2 a.m., the network comes back in hours, not days, because the config and the documentation are where they should be."
  );
}

// ============================================================
// SECTION 6 DIVIDER — Ongoing Support
// ============================================================
addSectionDivider("06", "Ongoing Managed Support", "Augmenting Aranda's on-site IT with 24x7 Technijian coverage")
  .addNotes("We now shift from the assessment engagement to the managed-services proposal. This is the multi-year relationship, not the project.");

// ============================================================
// SLIDE 16: Ongoing Support Model
// ============================================================
{
  const s = addContentSlide();
  addTitle(s, "Managed Services — Augmenting On-Site IT with 24x7");

  // Model card
  s.addShape(pres.shapes.RECTANGLE, { x: 0.5, y: 2.0, w: 9.0, h: 0.55, fill: { color: CORE_BLUE } });
  s.addText("Co-Managed IT — Aranda On-Site + Technijian 24x7", {
    x: 0.5, y: 2.0, w: 9.0, h: 0.55,
    fontSize: 14, fontFace: "Open Sans", bold: true, color: WHITE, align: "center", valign: "middle", margin: 0
  });

  // Three pillars
  const pillars = [
    {
      x: 0.5, title: "Aranda On-Site IT",
      items: [
        "Physical hands",
        "User support at the site",
        "Vendor escort and floor-walk",
        "Local change execution",
        "OT / production-floor liaison"
      ]
    },
    {
      x: 3.55, title: "Technijian 24x7 NOC",
      items: [
        "Monitoring and alerting",
        "After-hours + weekend coverage",
        "Patching and firmware updates",
        "Meraki Dashboard operations",
        "Incident triage and escalation"
      ]
    },
    {
      x: 6.6, title: "Technijian Engineering",
      items: [
        "Network architecture and design",
        "Firewall and segmentation policy",
        "Cyber hygiene and credential mgmt",
        "Audit / compliance evidence",
        "Strategic roadmap each quarter"
      ]
    }
  ];
  pillars.forEach(p => {
    s.addShape(pres.shapes.RECTANGLE, { x: p.x, y: 2.65, w: 2.95, h: 2.35, fill: { color: OFF_WHITE } });
    s.addShape(pres.shapes.RECTANGLE, { x: p.x, y: 2.65, w: 2.95, h: 0.05, fill: { color: CORE_ORANGE } });
    s.addText(p.title, {
      x: p.x + 0.15, y: 2.75, w: 2.65, h: 0.4,
      fontSize: 13, fontFace: "Open Sans", bold: true, color: CORE_BLUE, margin: 0
    });
    s.addText(p.items.map((t, i) => ({
      text: "•  " + t,
      options: { breakLine: i < p.items.length - 1, fontSize: 11, color: BRAND_GREY, paraSpaceAfter: 4 }
    })), {
      x: p.x + 0.15, y: 3.2, w: 2.65, h: 1.75, fontFace: "Open Sans", margin: 0, lineSpacingMultiple: 1.2
    });
  });

  addFooter(s, "10");
  s.addNotes(
    "This is the model I'd recommend for Aranda — co-managed IT. We do not replace the on-site team. We amplify them. " +
    "Aranda's on-site IT keeps the floor running, handles users, and runs change windows. " +
    "Technijian's NOC covers the 16 hours a day and the weekends when nobody's in the building — monitoring, patching, alerting, triage. " +
    "Our engineering team is the bench behind the on-site team — architecture, firewall policy, credential hygiene, audit evidence, and a quarterly strategic review. " +
    "For a manufacturer like Aranda, this model buys you two things the on-site team can't realistically provide alone: 24x7 coverage, and senior network/security engineering on demand."
  );
}

// ============================================================
// SLIDE 17: Support Tiers / Scope
// ============================================================
{
  const s = addContentSlide();
  addTitle(s, "What 24x7 Coverage Looks Like");

  const rows = [
    [
      { text: "Service", options: { bold: true, color: WHITE, fill: CORE_BLUE } },
      { text: "Coverage", options: { bold: true, color: WHITE, fill: CORE_BLUE, align: "center" } },
      { text: "Response Target", options: { bold: true, color: WHITE, fill: CORE_BLUE, align: "center" } }
    ],
    [
      { text: "Critical incident (outage, security event)", options: { color: DARK_CHARCOAL, fill: OFF_WHITE } },
      { text: "24x7x365", options: { color: BRAND_GREY, align: "center", fill: OFF_WHITE } },
      { text: "15 minutes", options: { bold: true, color: CORE_BLUE, align: "center", fill: OFF_WHITE } }
    ],
    [
      { text: "High-priority service request", options: { color: DARK_CHARCOAL } },
      { text: "24x7x365", options: { color: BRAND_GREY, align: "center" } },
      { text: "1 hour", options: { bold: true, color: CORE_BLUE, align: "center" } }
    ],
    [
      { text: "Monitoring and alerting (Meraki + non-Meraki)", options: { color: DARK_CHARCOAL, fill: OFF_WHITE } },
      { text: "24x7x365", options: { color: BRAND_GREY, align: "center", fill: OFF_WHITE } },
      { text: "Continuous", options: { bold: true, color: CORE_BLUE, align: "center", fill: OFF_WHITE } }
    ],
    [
      { text: "Patching and firmware updates", options: { color: DARK_CHARCOAL } },
      { text: "Scheduled maintenance windows", options: { color: BRAND_GREY, align: "center" } },
      { text: "Monthly", options: { bold: true, color: CORE_BLUE, align: "center" } }
    ],
    [
      { text: "Quarterly security / hygiene review", options: { color: DARK_CHARCOAL, fill: OFF_WHITE } },
      { text: "Business hours", options: { color: BRAND_GREY, align: "center", fill: OFF_WHITE } },
      { text: "Quarterly", options: { bold: true, color: CORE_BLUE, align: "center", fill: OFF_WHITE } }
    ],
    [
      { text: "Executive reporting to DSBJ group", options: { color: DARK_CHARCOAL } },
      { text: "Business hours", options: { color: BRAND_GREY, align: "center" } },
      { text: "Quarterly", options: { bold: true, color: CORE_BLUE, align: "center" } }
    ]
  ];
  s.addTable(rows, {
    x: 0.5, y: 2.0, w: 9.0, colW: [4.2, 2.8, 2.0],
    fontFace: "Open Sans", fontSize: 11, valign: "middle",
    border: { type: "solid", color: LIGHT_GREY, pt: 0.5 },
    rowH: 0.42
  });

  s.addText("Pricing is a separate discussion — we price per-user / per-device with a flat on-call tier. A proposal can be delivered the week after the remediation roadmap is signed off.", {
    x: 0.5, y: 4.9, w: 9.0, h: 0.3,
    fontSize: 10, fontFace: "Open Sans", italic: true, color: BRAND_GREY, margin: 0
  });

  addFooter(s, "11");
  s.addNotes(
    "Concrete targets, not marketing language. " +
    "Critical incident — 15 minute response, 24x7. That is how we staff the NOC. " +
    "High-priority service request — one hour, 24x7. " +
    "Monitoring is continuous — Meraki Dashboard plus the non-Meraki devices pulled into one pane. " +
    "Patching is scheduled monthly in approved maintenance windows, coordinated with Aranda's on-site lead. " +
    "Quarterly we deliver a hygiene review and — relevant for DSBJ — an executive report to the parent, so group leadership has visibility into the subsidiary's network posture without asking. " +
    "Pricing is a separate conversation and we'd propose it after the remediation work is scoped, because the right pricing depends on final device count and scope."
  );
}

// ============================================================
// SLIDE 18: Why Technijian
// ============================================================
{
  const s = addContentSlide();
  addTitle(s, "Why Technijian for Aranda");
  s.addText([
    { text: "Orange County–based managed services firm with a 24x7 NOC covering clients across manufacturing, financial services, real estate, and professional services.", options: { breakLine: true, paraSpaceAfter: 14, fontSize: 14, color: BRAND_GREY } },
    { text: "✓  Deep Meraki and mixed-vendor expertise — exactly the environment Aranda has today", options: { breakLine: true, fontSize: 13, color: BRAND_GREY, paraSpaceAfter: 6 } },
    { text: "✓  Co-managed IT model — we augment on-site teams, not replace them", options: { breakLine: true, fontSize: 13, color: BRAND_GREY, paraSpaceAfter: 6 } },
    { text: "✓  Documented compliance-aware engineering — HIPAA, SOC 2, PCI, SEC, GDPR, CMMC-adjacent", options: { breakLine: true, fontSize: 13, color: BRAND_GREY, paraSpaceAfter: 6 } },
    { text: "✓  US-based senior engineering with offshore documentation leverage — right blend for a manufacturing subsidiary", options: { breakLine: true, fontSize: 13, color: BRAND_GREY, paraSpaceAfter: 6 } },
    { text: "✓  Same team assesses, remediates, and operates — no handoff loss between project and support", options: { fontSize: 13, color: BRAND_GREY } }
  ], {
    x: 0.7, y: 2.05, w: 8.6, h: 3.0,
    fontFace: "Open Sans", margin: 0, lineSpacingMultiple: 1.3
  });
  addFooter(s, "12");
  s.addNotes(
    "The last credential slide. Five reasons this is the right fit. " +
    "We already know this environment — Meraki fronting a mixed vendor stack is our day job. " +
    "Our model is co-managed, which is what works for a manufacturing subsidiary with on-site IT already in place. " +
    "We carry compliance literacy from clients in regulated industries — not because Aranda is regulated today, but because manufacturing customer audits trend that direction. " +
    "And critically — the same team that assessed is the same team that remediates and the same team that operates. No project-to-support handoff that loses context."
  );
}

// ============================================================
// SLIDE 19: Next Steps
// ============================================================
{
  const s = addContentSlide();
  addTitle(s, "Next Steps");

  const steps = [
    { n: "1", t: "Sign the Network Assessment SOW", sub: "$7,200 fixed fee · 50% on signing · 50% on readout delivery" },
    { n: "2", t: "Provision read-only Meraki access", sub: "Named read-only Dashboard user OR time-limited API key" },
    { n: "3", t: "Kickoff the assessment (Week of May 4)", sub: "Phase 1 Discovery begins · 4-week engagement · remote" },
    { n: "4", t: "Begin 72-hour credential / key remediation in parallel", sub: "Separate quick-scope Change Order if DSBJ wants it handled by Technijian" },
    { n: "5", t: "Executive readout to DSBJ", sub: "Findings, roadmap, and managed services proposal in one session" }
  ];
  steps.forEach((step, i) => {
    const y = 2.05 + i * 0.58;
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
      x: 0.7, y: y + 0.05, w: 0.45, h: 0.45,
      fill: { color: CORE_ORANGE }, rectRadius: 0.22
    });
    s.addText(step.n, {
      x: 0.7, y: y + 0.05, w: 0.45, h: 0.45,
      fontSize: 14, fontFace: "Open Sans", bold: true, color: WHITE, align: "center", valign: "middle", margin: 0
    });
    s.addText([
      { text: step.t, options: { bold: true, color: DARK_CHARCOAL, fontSize: 13, breakLine: true } },
      { text: step.sub, options: { color: BRAND_GREY, fontSize: 11, italic: true } }
    ], {
      x: 1.3, y: y, w: 8.1, h: 0.55, fontFace: "Open Sans", margin: 0
    });
  });

  addFooter(s, "13");
  s.addNotes(
    "Five concrete next steps. " +
    "One: sign the assessment SOW. $7,200 fixed fee, half on signing, half on readout. " +
    "Two: give us read-only access to the Meraki Dashboard — named user or time-limited API key. No shared passwords. " +
    "Three: kickoff Week of May 4th. Four-week engagement, entirely remote. " +
    "Four: the 72-hour credential and key rotation can run in parallel. If DSBJ wants Technijian to execute that work rather than the on-site team, we'll scope it as a small Change Order — probably a day and a half of effort. " +
    "Five: at the end of the engagement, I come back — to this audience if it's useful — and deliver the readout alongside a managed services proposal. That is the logical path to the 24x7 support conversation. " +
    "Any questions before I hand it off to Q&A?"
  );
}

// ============================================================
// SLIDE 20: Closing / CTA
// ============================================================
{
  const s = pres.addSlide();
  s.background = { color: DARK_CHARCOAL };
  s.addImage({ path: logoDark, x: 3.0, y: 0.6, w: 4.0, h: 0.83 });

  s.addText("Thank You", {
    x: 1, y: 1.8, w: 8, h: 0.9,
    fontSize: 44, fontFace: "Open Sans", bold: true, color: WHITE, align: "center", margin: 0
  });
  s.addText("Questions, objections, and next-step priorities welcome.", {
    x: 1, y: 2.7, w: 8, h: 0.6,
    fontSize: 16, fontFace: "Open Sans", color: LIGHT_GREY, align: "center", margin: 0
  });

  // Contact card
  s.addShape(pres.shapes.RECTANGLE, {
    x: 2.5, y: 3.5, w: 5.0, h: 1.1, fill: { color: CORE_BLUE }, rectRadius: 0.05
  });
  s.addText([
    { text: "Ravi Jain", options: { bold: true, fontSize: 18, color: WHITE, breakLine: true } },
    { text: "CEO, Technijian, Inc.", options: { fontSize: 12, color: LIGHT_GREY, breakLine: true } },
    { text: "rjain@technijian.com  ·  949.379.8500", options: { fontSize: 12, color: TEAL } }
  ], {
    x: 2.5, y: 3.55, w: 5.0, h: 1.0,
    fontFace: "Open Sans", align: "center", margin: 0
  });

  s.addText("Technijian, Inc.  ·  18 Technology Dr., Ste 141, Irvine, CA 92618  ·  technijian.com", {
    x: 0.5, y: 4.95, w: 9.0, h: 0.3,
    fontSize: 10, fontFace: "Open Sans", color: BRAND_GREY, align: "center", margin: 0
  });
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 5.35, w: 10, h: 0.08, fill: { color: CORE_ORANGE }
  });
  s.addNotes("Open the floor. Prioritize questions from DSBJ leadership. If no questions, close with the SOW-signing CTA from slide 13.");
}

// ============================================================
// WRITE FILE
// ============================================================
const outPath = path.join(__dirname, "..", "07_Assessments", "ART-DSBJ-Executive-Readout.pptx");
pres.writeFile({ fileName: outPath }).then(fn => {
  console.log("Generated:", fn);
}).catch(err => {
  console.error("Error:", err);
  process.exit(1);
});
