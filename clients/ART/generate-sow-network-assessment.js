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
    document: { run: { font: FONT, size: 22, color: GREY } }
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
  config: Array.from({ length: 15 }, (_, i) => ({
    reference: `bullets${i === 0 ? "" : i}`,
    levels: [{
      level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT,
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
  items.push(p("Effective Date: May 1, 2026", { size: 22, color: GREY, alignment: AlignmentType.CENTER, spacing: { after: 200 } }));
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
    { text: "SOW-ART-001-NetworkAssessment" }
  ]));
  content.push(multiRun([
    { text: "Effective Date: ", bold: true, color: CHARCOAL },
    { text: "May 1, 2026" }
  ]));
  content.push(multiRun([
    { text: "Master Service Agreement: ", bold: true, color: CHARCOAL },
    { text: "None (standalone SOW \u2014 Technijian Standard Terms & Conditions apply)" }
  ]));
  content.push(spacer());
  content.push(p("This Statement of Work (\u201CSOW\u201D) is entered into by and between:"));
  content.push(spacer());
  content.push(p("Technijian, Inc. (\u201CTechnijian\u201D)", { bold: true, color: CHARCOAL }));
  content.push(p("18 Technology Drive, Suite 141"));
  content.push(p("Irvine, California 92618"));
  content.push(spacer());
  content.push(p("and"));
  content.push(spacer());
  content.push(p("Aranda Tooling, LLC (\u201CClient\u201D)", { bold: true, color: CHARCOAL }));
  content.push(p("13950 Yorba Avenue"));
  content.push(p("Chino, California 91710"));
  content.push(brandRule());

  // ---- 1. PROJECT OVERVIEW ----
  content.push(heading1("1. PROJECT OVERVIEW"));

  content.push(heading2("1.1 Project Title"));
  content.push(p("Aranda Tooling Network Assessment \u2014 Meraki MX/MS and Non-Meraki Switching Review with Executive Readout"));
  content.push(spacer());

  content.push(heading2("1.2 Project Description"));
  content.push(p("Aranda Tooling, LLC (\u201CAranda\u201D) operates an ISO 9001:2015 certified metal stamping, fabrication, tool-and-die, laser cutting, and robotic welding facility in Chino, California. Its network supports production OT systems, office users, printers, guest Wi-Fi, IoT endpoints, and administrative workloads across a mixed-vendor switching estate fronted by a Meraki MX firewall, Meraki MS switches, and downstream non-Meraki (Aranda-branded Cisco SMB and Netgear Smart/Plus) access switches."));
  content.push(spacer());
  content.push(p("A preliminary technical review performed from supplied switch configuration exports and the topology diagram identified multiple material observations, including: (a) private cryptographic material and privileged local management information embedded in exported switch backups, (b) inconsistent management addressing and default gateways across the non-Meraki switch estate, (c) the Meraki MS layer not being present in the supplied exports \u2014 which likely includes part of the aggregation/core switching function, (d) a mixed small-business/Plus-class vendor stack increasing support complexity, and (e) VLAN segmentation that is directionally good but not yet validated end-to-end."));
  content.push(spacer());
  content.push(p("This SOW covers a focused, configuration-driven network assessment that validates segmentation, management-plane security, configuration hygiene, and operational resilience across the Meraki MX/MS layer and the downstream access switches, and delivers an executive readout with a prioritized remediation roadmap. This engagement is positioned as an assessment and readout \u2014 not a remediation, implementation, or change-execution engagement. Remediation labor, after-hours change execution, wireless surveys, and cable certification, if subsequently requested by Client, will be scoped and priced under a separate SOW or Change Order."));
  content.push(spacer());

  content.push(heading2("1.3 Location"));
  content.push(makeTable(
    ["Location Name", "Code", "Address", "Billable"],
    [["Aranda Tooling \u2014 Primary", "ART-HQ", "13950 Yorba Avenue, Chino, CA 91710", "Yes"]],
    [2340, 1560, 3900, 1560]
  ));
  content.push(brandRule());

  // ---- 2. SCOPE OF WORK ----
  content.push(heading1("2. SCOPE OF WORK"));

  content.push(heading2("2.1 In Scope"));
  content.push(bullet("Read-only review of the Meraki MX firewall configuration: addressing and VLANs, appliance ports, static routes, L3/L7 firewall rules, NAT, DHCP, WAN uplinks, site-to-site VPN, and SD-WAN / content-filtering policies relevant to segmentation", "bullets1"));
  content.push(bullet("Read-only review of the Meraki MS switch estate: switch settings, per-port configuration, link aggregations, access policies, ACLs, DHCP server policy / ARP inspection, and any Layer 3 interfaces if enabled", "bullets1"));
  content.push(bullet("Read-only review of Meraki MR wireless (if in use): SSID-to-VLAN mapping, local-LAN access policy, and SSID firewall rules", "bullets1"));
  content.push(bullet("Review of the supplied non-Meraki switch exports (Aranda-branded Cisco SMB and Netgear Smart/Plus devices) for VLAN design, trunking, local admin posture, management IP exposure, STP behavior, and configuration hygiene", "bullets1"));
  content.push(bullet("Segmentation validation across office, guest, services, IoT, printer, and OT networks", "bullets1"));
  content.push(bullet("Security and hardening baseline assessment: credentials, keys, certificates, access control, logging, and monitoring gaps", "bullets1"));
  content.push(bullet("Production of a normalized device inventory and validated topology notes", "bullets1"));
  content.push(bullet("Drafting a risk-ranked technical findings register with business impact and recommended actions", "bullets1"));
  content.push(bullet("Drafting a 30/60/90-day remediation roadmap and configuration standardization recommendations", "bullets1"));
  content.push(bullet("Preparation and delivery of an executive readout presentation (up to 90 minutes, remote)", "bullets1"));
  content.push(spacer());

  content.push(heading2("2.2 Out of Scope"));
  content.push(p("The following items are expressly excluded from this SOW and, if requested, will be handled under a separate SOW or Change Order:"));
  content.push(spacer());
  content.push(bullet("Remediation labor, configuration changes, credential rotation, key/certificate regeneration, or any change-execution activity on Client infrastructure", "bullets2"));
  content.push(bullet("After-hours change windows and on-call support", "bullets2"));
  content.push(bullet("Full wireless site survey, heatmaps, or RF spectrum analysis", "bullets2"));
  content.push(bullet("Physical cable certification, cable testing, or structured cabling work", "bullets2"));
  content.push(bullet("Endpoint security assessment, server/workstation review, Active Directory audit, email security, or backup/DR architecture review", "bullets2"));
  content.push(bullet("OT process-control system audit, PLC-level review, or safety-systems engineering", "bullets2"));
  content.push(bullet("Penetration testing, red-team engagements, vulnerability scanning of hosts, or external attack-surface testing", "bullets2"));
  content.push(bullet("ISP circuit engineering, carrier coordination, or contract review", "bullets2"));
  content.push(bullet("Compliance certification issuance (HIPAA, SOC 2, PCI-DSS, ISO 27001, CMMC, etc.) \u2014 this assessment is configuration-oriented and does not constitute a regulatory attestation", "bullets2"));
  content.push(bullet("Hardware procurement, appliance replacement, or refresh implementation", "bullets2"));
  content.push(spacer());

  content.push(heading2("2.3 Assumptions"));
  content.push(bullet("Client will designate a single point of contact authorized to validate inventory, approve access, and confirm business-critical traffic paths", "bullets3"));
  content.push(bullet("Client will provide read-only Meraki Dashboard access or a time-limited, read-only Meraki API key generated by a named Aranda administrator. Shared dashboard passwords transmitted by email are not an acceptable access model", "bullets3"));
  content.push(bullet("Client will provide access to any current topology diagrams, ISP handoff details, static public IP information, and existing circuit documentation available", "bullets3"));
  content.push(bullet("The previously supplied non-Meraki switch backups (four Aranda-branded Cisco SMB configs and six Netgear Smart/Plus exports) will be treated as in scope for review", "bullets3"));
  content.push(bullet("Inter-VLAN routing is believed to reside on the Meraki MX firewall and the switch estate is primarily Layer 2; this assumption will be validated during Phase 2", "bullets3"));
  content.push(bullet("The engagement is performed remotely; no on-site presence is required. If on-site work is later requested, it will be added via Change Order at the On-Site Support rate ($150/hr, 2-hour minimum)", "bullets3"));
  content.push(bullet("Findings and recommendations are based on configuration evidence provided and collected during the engagement and do not include live traffic capture, active client impact testing, or spanning-tree state validation", "bullets3"));
  content.push(brandRule());

  // ---- 3. PROJECT PHASES ----
  content.push(heading1("3. PROJECT PHASES"));

  // Phase 1
  content.push(heading2("Phase 1: Discovery & Access Validation"));
  content.push(heading3("3.1.1 Description"));
  content.push(p("Kick off the engagement, confirm scope and inventory, validate Meraki Dashboard or API access, and close any data-collection gaps from the preliminary review. Produce a discovery memo and evidence-gap log that governs Phase 2 analysis."));
  content.push(spacer());
  content.push(heading3("3.1.2 Deliverables"));
  content.push(bullet("Kickoff meeting notes and confirmed scope statement", "bullets4"));
  content.push(bullet("Validated device inventory (Meraki MX / MS / MR plus non-Meraki switches)", "bullets4"));
  content.push(bullet("Confirmed Meraki access method (read-only Dashboard or time-limited API key)", "bullets4"));
  content.push(bullet("Discovery memo and evidence-gap log identifying any remaining data-collection items", "bullets4"));
  content.push(spacer());
  content.push(heading3("3.1.3 Schedule"));
  content.push(makeTable(
    ["Role", "Description", "Est. Hours", "Timeline", "Resource"],
    [
      ["Sr. Network Engineer", "Kickoff, scope confirmation, access provisioning coordination", "2", "Week 1", "IRV-TS1"],
      ["Sr. Network Engineer", "Meraki Dashboard/API access validation and baseline data pull", "3", "Week 1", "IRV-TS1"],
      ["Sr. Network Engineer", "Inventory validation against supplied topology and configs", "3", "Week 1", "IRV-TS1"],
      ["Sr. Network Engineer", "Discovery memo and evidence-gap log", "2", "Week 1", "IRV-TS1"],
      [{ text: "", bold: true }, { text: "Phase 1 Total", bold: true }, { text: "10", bold: true }, "", ""]
    ],
    [1800, 3400, 1000, 1080, 1080]
  ));
  content.push(spacer());

  // Phase 2
  content.push(heading2("Phase 2: Configuration Analysis"));
  content.push(heading3("3.2.1 Description"));
  content.push(p("Perform the core configuration-driven analysis across the Meraki MX, Meraki MS, non-Meraki switches, wireless SSID-to-VLAN alignment, and end-to-end segmentation. Identify security, hardening, and operational-resilience gaps. This is the evidence-collection phase that feeds the findings register."));
  content.push(spacer());
  content.push(heading3("3.2.2 Deliverables"));
  content.push(bullet("Meraki MX firewall review notes (routing, VLAN gateway design, L3/L7 rules, NAT, DHCP, WAN/uplink, VPN/static-route posture)", "bullets5"));
  content.push(bullet("Meraki MS switch review notes (switch settings, port configs, LAGs, access policies, ACLs, DHCP/DAI, L3 interfaces if any)", "bullets5"));
  content.push(bullet("Non-Meraki switch review notes (VLAN design, trunking, local admin posture, management IP exposure, STP behavior, config hygiene)", "bullets5"));
  content.push(bullet("Wireless and SSID-to-VLAN alignment notes (if MR is in use)", "bullets5"));
  content.push(bullet("Segmentation validation notes for office, guest, services, IoT, printer, and OT networks", "bullets5"));
  content.push(bullet("Security and hardening baseline notes (credentials, keys, certificates, access control, logging, monitoring)", "bullets5"));
  content.push(spacer());
  content.push(heading3("3.2.3 Schedule"));
  content.push(makeTable(
    ["Role", "Description", "Est. Hours", "Timeline", "Resource"],
    [
      ["Sr. Network Engineer", "Meraki MX firewall configuration review", "5", "Week 2", "IRV-TS1"],
      ["Sr. Network Engineer", "Meraki MS switch configuration review", "5", "Week 2", "IRV-TS1"],
      ["Sr. Network Engineer", "Non-Meraki switch configuration analysis", "3", "Week 2", "IRV-TS1"],
      ["Sr. Network Engineer", "Wireless and SSID alignment review", "2", "Week 2", "IRV-TS1"],
      ["Sr. Network Engineer", "End-to-end segmentation validation", "3", "Week 2", "IRV-TS1"],
      ["Sr. Network Engineer", "Security and hardening baseline review", "2", "Week 2", "IRV-TS1"],
      [{ text: "", bold: true }, { text: "Phase 2 Total", bold: true }, { text: "20", bold: true }, "", ""]
    ],
    [1800, 3400, 1000, 1080, 1080]
  ));
  content.push(spacer());

  // Phase 3
  content.push(heading2("Phase 3: Findings & Remediation Roadmap"));
  content.push(heading3("3.3.1 Description"));
  content.push(p("Consolidate Phase 2 evidence into a risk-ranked technical findings register, produce a normalized device inventory and validated topology, and draft a 30/60/90-day remediation roadmap and configuration-standardization recommendations suitable for leadership review."));
  content.push(spacer());
  content.push(heading3("3.3.2 Deliverables"));
  content.push(bullet("Technical findings register with severity (Critical / High / Moderate / Low), business impact, affected devices, and recommended actions", "bullets6"));
  content.push(bullet("Normalized device inventory and validated topology document", "bullets6"));
  content.push(bullet("30/60/90-day remediation roadmap (immediate stabilization, 30-day normalization, 90-day strategic actions)", "bullets6"));
  content.push(bullet("Meraki MX/MS/MR data-collection checklist and gap log (finalized)", "bullets6"));
  content.push(bullet("Draft executive summary suitable for non-technical leadership review", "bullets6"));
  content.push(spacer());
  content.push(heading3("3.3.3 Schedule"));
  content.push(makeTable(
    ["Role", "Description", "Est. Hours", "Timeline", "Resource"],
    [
      ["Sr. Network Engineer", "Risk-ranked findings register drafting", "4", "Week 3", "IRV-TS1"],
      ["Sr. Network Engineer", "30/60/90-day remediation roadmap", "4", "Week 3", "IRV-TS1"],
      ["Sr. Network Engineer", "Normalized device inventory and topology documentation", "2", "Week 3", "IRV-TS1"],
      ["Sr. Network Engineer", "Executive summary drafting", "2", "Week 3", "IRV-TS1"],
      [{ text: "", bold: true }, { text: "Phase 3 Total", bold: true }, { text: "12", bold: true }, "", ""]
    ],
    [1800, 3400, 1000, 1080, 1080]
  ));
  content.push(spacer());

  // Phase 4
  content.push(heading2("Phase 4: Executive Readout"));
  content.push(heading3("3.4.1 Description"));
  content.push(p("Finalize deliverables, deliver the executive readout to Client leadership, and capture prioritization and next-step decisions. This phase closes the assessment engagement."));
  content.push(spacer());
  content.push(heading3("3.4.2 Deliverables"));
  content.push(bullet("Final executive summary (PDF)", "bullets7"));
  content.push(bullet("Final technical findings register (PDF/XLSX)", "bullets7"));
  content.push(bullet("Final remediation roadmap (PDF)", "bullets7"));
  content.push(bullet("Final device inventory and topology (PDF)", "bullets7"));
  content.push(bullet("Executive readout session (remote, up to 90 minutes) with Q&A", "bullets7"));
  content.push(bullet("Post-readout next-step memo summarizing Client priorities and any requested follow-on work for Change Order scoping", "bullets7"));
  content.push(spacer());
  content.push(heading3("3.4.3 Schedule"));
  content.push(makeTable(
    ["Role", "Description", "Est. Hours", "Timeline", "Resource"],
    [
      ["Sr. Network Engineer", "Final deliverable QA, formatting, and packaging", "2", "Week 4", "IRV-TS1"],
      ["Sr. Network Engineer", "Executive readout presentation (remote)", "2", "Week 4", "IRV-TS1"],
      ["Sr. Network Engineer", "Post-readout priorities capture and next-step memo", "2", "Week 4", "IRV-TS1"],
      [{ text: "", bold: true }, { text: "Phase 4 Total", bold: true }, { text: "6", bold: true }, "", ""]
    ],
    [1800, 3400, 1000, 1080, 1080]
  ));
  content.push(brandRule());

  // ---- 4. EQUIPMENT AND MATERIALS ----
  content.push(heading1("4. EQUIPMENT AND MATERIALS"));
  content.push(p("Not applicable. This SOW is a professional-services assessment engagement. No hardware, appliances, or software licenses are being supplied by Technijian under this SOW."));
  content.push(brandRule());

  // ---- 5. PRICING AND PAYMENT ----
  content.push(heading1("5. PRICING AND PAYMENT"));

  content.push(heading2("5.1 Rate Card"));
  content.push(makeTable(
    ["Role", "Location", "Rate"],
    [["Sr. Network Engineer (Project Rate)", "US", "$150.00 / hr"]],
    [4000, 2680, 2680]
  ));
  content.push(spacer());

  content.push(heading2("5.2 Summary of Costs"));
  content.push(makeTable(
    ["Phase", "Type", "Est. Hours", "Cost"],
    [
      ["Phase 1 \u2014 Discovery & Access Validation", "Fixed", "10", "$1,500.00"],
      ["Phase 2 \u2014 Configuration Analysis", "Fixed", "20", "$3,000.00"],
      ["Phase 3 \u2014 Findings & Remediation Roadmap", "Fixed", "12", "$1,800.00"],
      ["Phase 4 \u2014 Executive Readout", "Fixed", "6", "$900.00"],
      [{ text: "Total (Fixed Fee)", bold: true }, "", { text: "48", bold: true }, { text: "$7,200.00", bold: true }]
    ],
    [4200, 1600, 1780, 1780]
  ));
  content.push(spacer());
  content.push(p("Pricing Type Definitions:", { bold: true, color: CHARCOAL }));
  content.push(spacer());
  content.push(multiRun([
    { text: "Fixed Cost: ", bold: true, color: CHARCOAL },
    { text: "Technijian will complete the work described in this SOW at the stated price of $7,200.00 regardless of actual hours expended, provided the scope and assumptions in Section 2 are not materially changed by Client. The hours shown above are internal estimates for resource planning and are not separately billable." }
  ]));
  content.push(spacer());

  content.push(heading2("5.3 Payment Schedule"));
  content.push(makeTable(
    ["Milestone", "Invoiced", "Amount"],
    [
      ["SOW Execution", "Upon signing", "$3,600.00"],
      ["Executive Readout Delivery", "Upon completion of Phase 4", "$3,600.00"],
      [{ text: "Total", bold: true }, "", { text: "$7,200.00", bold: true }]
    ],
    [3200, 3080, 3080]
  ));
  content.push(spacer());

  content.push(heading2("5.4 Payment Terms"));
  content.push(p("All invoices are due and payable within thirty (30) days of the invoice date."));
  content.push(spacer());

  content.push(heading2("5.5 Late Payment and Collection Remedies"));
  content.push(p("Because no MSA is in effect between the Parties, the following standalone provisions apply:"));
  content.push(spacer());
  content.push(multiRun([
    { text: "(i) Late Payment. ", bold: true, color: CHARCOAL },
    { text: "Late payments shall accrue a late fee of 1.5% per month (or the maximum rate permitted by law, whichever is less) on the unpaid balance, calculated as simple interest from the date payment was due. The Parties acknowledge that the late fee represents a reasonable estimate of Technijian\u2019s administrative costs and damages resulting from late payment and is not a penalty." }
  ], { indent: { left: 360 } }));
  content.push(spacer());
  content.push(multiRun([
    { text: "(ii) Acceleration. ", bold: true, color: CHARCOAL },
    { text: "If Client fails to pay any undisputed invoice within forty-five (45) days of the due date, all remaining fees under this SOW shall become immediately due and payable." }
  ], { indent: { left: 360 } }));
  content.push(spacer());
  content.push(multiRun([
    { text: "(iii) Suspension. ", bold: true, color: CHARCOAL },
    { text: "Technijian may suspend all work under this SOW upon ten (10) days written notice if any invoice remains unpaid beyond the due date. Suspension shall not relieve Client of its payment obligations, and project timelines shall be adjusted accordingly at no cost to Technijian." }
  ], { indent: { left: 360 } }));
  content.push(spacer());
  content.push(multiRun([
    { text: "(iv) Collection Costs and Attorney\u2019s Fees. ", bold: true, color: CHARCOAL },
    { text: "In any action or proceeding to collect fees, invoices, or other amounts owed under this SOW, the prevailing Party shall be entitled to recover all reasonable costs of collection, including attorney\u2019s fees (including in-house counsel at market rates), collection agency fees, court costs, arbitration fees, and all costs of appeal. Pursuant to California Civil Code Section 1717, the Parties acknowledge that this attorney\u2019s fees provision is reciprocal. This fee-shifting applies exclusively to collection of amounts owed and does not apply to disputes regarding service quality, professional performance, or other non-payment claims." }
  ], { indent: { left: 360 } }));
  content.push(spacer());
  content.push(multiRun([
    { text: "(v) Lien on Work Product. ", bold: true, color: CHARCOAL },
    { text: "Technijian shall retain a lien on all deliverables, work product, documentation, and materials (excluding Client Data) under this SOW until all amounts owed are paid in full." }
  ], { indent: { left: 360 } }));
  content.push(spacer());
  content.push(multiRun([
    { text: "(vi) Fees for Non-Collection Disputes. ", bold: true, color: CHARCOAL },
    { text: "Except as provided in subsection (iv) above, in any dispute arising under this SOW relating to service quality, professional performance, scope, or any other non-payment matter, each Party shall bear its own attorney\u2019s fees and costs." }
  ], { indent: { left: 360 } }));
  content.push(brandRule());

  // ---- 6. CLIENT RESPONSIBILITIES ----
  content.push(heading1("6. CLIENT RESPONSIBILITIES"));
  content.push(p("Client shall:"));
  content.push(spacer());
  content.push(p("(a) Provide access to systems, cloud consoles (Meraki Dashboard), and personnel as reasonably required to complete the assessment;", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(b) Designate a point of contact authorized to validate inventory, approve access, make decisions on behalf of Client, and schedule the executive readout;", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(c) Review and approve deliverables (discovery memo, findings register, roadmap, executive summary) within five (5) business days of submission;", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(d) Ensure all relevant configuration backups and network documentation provided to Technijian are authorized for external sharing, and treat any configuration material returned by Technijian as sensitive;", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(e) Rotate or revoke any temporary Meraki API key issued for this engagement promptly upon conclusion of Phase 4;", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(f) Acknowledge that the preliminary review identified embedded private keys and privileged management information in historical switch backups; Client is responsible for any credential rotation, key/certificate regeneration, or incident-response activity, which is out of scope of this SOW; and", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(g) Inform internal stakeholders of the assessment scope so that configuration review activity is not mistaken for change-execution or troubleshooting activity.", { indent: { left: 360 } }));
  content.push(brandRule());

  // ---- 7. CHANGE MANAGEMENT ----
  content.push(heading1("7. CHANGE MANAGEMENT"));
  content.push(p("7.01. Any changes to the scope, schedule, or pricing of this SOW must be documented in a written Change Order signed by both Parties before work on the change begins."));
  content.push(spacer());
  content.push(p("7.02. If Client requests work outside the defined scope \u2014 including, without limitation, remediation labor, configuration changes, after-hours work, on-site visits, wireless surveys, cable certification, or deeper compliance review \u2014 Technijian shall provide a Change Order detailing the additional work, estimated hours, and cost impact."));
  content.push(spacer());
  content.push(p("7.03. Technijian shall not proceed with out-of-scope work without an approved Change Order, except in cases where delay would result in imminent risk of data loss, security breach, or system outage to Client\u2019s systems, in which case Technijian may perform emergency out-of-scope work not to exceed $2,500 (at applicable Rate Card rates) without prior approval. Technijian shall notify Client as soon as practicable and shall issue a retrospective Change Order within three (3) business days of the emergency work for Client\u2019s review and ratification."));
  content.push(brandRule());

  // ---- 8. ACCEPTANCE ----
  content.push(heading1("8. ACCEPTANCE"));
  content.push(p("8.01. Upon completion of each phase, Technijian shall notify Client in writing that the deliverables are ready for review."));
  content.push(spacer());
  content.push(p("8.02. Client shall review the deliverables and provide written acceptance or a detailed description of deficiencies within five (5) business days. Technijian\u2019s delivery notification shall include a conspicuous statement: \u201CIf you do not respond within five (5) business days, deliverables will be deemed accepted per SOW Section 8.03.\u201D"));
  content.push(spacer());
  content.push(p("8.03. If Client does not respond within the review period, the deliverables shall be deemed accepted."));
  content.push(spacer());
  content.push(p("8.04. If deficiencies are identified, Technijian shall correct them and resubmit for review. This process shall repeat until acceptance is achieved or the Parties agree on a resolution."));
  content.push(brandRule());

  // ---- 9. GOVERNING TERMS ----
  content.push(heading1("9. GOVERNING TERMS"));
  content.push(p("9.01. No Master Service Agreement is currently in effect between the Parties. The Technijian Standard Terms and Conditions (attached as Appendix A, if provided) shall govern this SOW. If Appendix A is not attached, the following shall apply as a minimum: (a) neither Party\u2019s total aggregate liability under this SOW shall exceed the total fees paid or payable under this SOW; (b) in no event shall either Party be liable for indirect, incidental, special, consequential, or punitive damages; and (c) this SOW shall be governed by the laws of the State of California, and disputes shall be resolved by binding arbitration in Orange County, California, under the AAA Commercial Arbitration Rules."));
  content.push(spacer());
  content.push(p("9.02. If the Parties subsequently execute a Master Service Agreement, the MSA shall govern this SOW on a go-forward basis and, in the event of a conflict, the MSA shall prevail unless this SOW expressly states otherwise."));
  content.push(spacer());
  content.push(p("9.03. Deliverables produced under this SOW constitute Technijian work product. Upon full payment of all amounts due, Technijian grants Client a perpetual, non-exclusive license to use the deliverables for Client\u2019s internal business purposes. Technijian retains ownership of its pre-existing methodologies, templates, and tools."));
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
  content.push(p("ARANDA TOOLING, LLC", { bold: true, color: CHARCOAL }));
  content.push(spacer());
  content.push(p("By: ___________________________________"));
  content.push(spacer());
  content.push(p("Name: _________________________________"));
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
          "Network Assessment \u2014 Aranda Tooling, LLC"
        )
      },
      {
        properties: contentSectionProps(),
        children: content
      }
    ]
  });

  const buffer = await Packer.toBuffer(doc);
  const outputPath = path.join(__dirname, "SOW-ART-001-NetworkAssessment.docx");
  fs.writeFileSync(outputPath, buffer);
  console.log("Generated:", outputPath);
}

generateSOW().catch(err => {
  console.error("Error generating SOW:", err);
  process.exit(1);
});
