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
        level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 720, hanging: 360 } } }
      }]
    },
    {
      reference: "bullets2",
      levels: [{
        level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 720, hanging: 360 } } }
      }]
    },
    {
      reference: "bullets3",
      levels: [{
        level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 720, hanging: 360 } } }
      }]
    },
    {
      reference: "bullets4",
      levels: [{
        level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 720, hanging: 360 } } }
      }]
    },
    {
      reference: "bullets5",
      levels: [{
        level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 720, hanging: 360 } } }
      }]
    },
    {
      reference: "bullets6",
      levels: [{
        level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 720, hanging: 360 } } }
      }]
    },
    {
      reference: "bullets7",
      levels: [{
        level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 720, hanging: 360 } } }
      }]
    },
    {
      reference: "letters",
      levels: [{
        level: 0, format: LevelFormat.LOWER_LETTER, text: "(%1)", alignment: AlignmentType.LEFT,
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
  items.push(p("March 31, 2026", { size: 22, color: GREY, alignment: AlignmentType.CENTER, spacing: { after: 200 } }));
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
  content.push(heading1("ADDENDUM \u2014 STATEMENT OF WORK"));
  content.push(multiRun([
    { text: "SOW Number: ", bold: true, color: CHARCOAL },
    { text: "SOW-AFFG-002" }
  ]));
  content.push(multiRun([
    { text: "Parent SOW: ", bold: true, color: CHARCOAL },
    { text: "SOW-AFFG-001 (Sophos SF V-2C4 Virtual Firewall & Edge Appliance Deployment)" }
  ]));
  content.push(multiRun([
    { text: "Effective Date: ", bold: true, color: CHARCOAL },
    { text: "March 31, 2026" }
  ]));
  content.push(spacer());
  content.push(p("This Addendum Statement of Work (\u201CSOW\u201D) is entered into by and between:"));
  content.push(spacer());
  content.push(p("Technijian, Inc. (\u201CTechnijian\u201D)", { bold: true, color: CHARCOAL }));
  content.push(p("18 Technology Drive, Suite 141"));
  content.push(p("Irvine, California 92618"));
  content.push(spacer());
  content.push(p("and"));
  content.push(spacer());
  content.push(p("American Fundstars Financial Group LLC (\u201CClient\u201D)", { bold: true, color: CHARCOAL }));
  content.push(p("1 Park Plaza, Suite 210"));
  content.push(p("Irvine, California 92618"));
  content.push(multiRun([{ text: "Primary Contact: ", bold: true, color: CHARCOAL }, { text: "Iris Liu" }]));
  content.push(brandRule());

  // ---- 1. BACKGROUND & PURPOSE ----
  content.push(heading1("1. BACKGROUND & PURPOSE"));
  content.push(spacer());
  content.push(p("During the discovery phase of SOW-AFFG-001 (Sophos SF V-2C4 Virtual Firewall & Edge Appliance Deployment), it was identified that the existing router at Client\u2019s primary location also functions as the sole wireless access point (Wi-Fi). Upon deployment of the Sophos firewall, the router\u2019s Wi-Fi functionality must be disabled to ensure all traffic is properly routed through the Sophos security inspection engine and to eliminate unmonitored wireless ingress/egress points."));
  content.push(spacer());
  content.push(p("Disabling the router\u2019s built-in Wi-Fi without providing a replacement access point would leave Client without wireless network connectivity. This addendum provides for the procurement and deployment of a dedicated, enterprise-grade wireless access point to restore Wi-Fi service under the security umbrella of the new Sophos firewall."));
  content.push(spacer());
  content.push(p("This SOW presents three access point options for Client selection, each evaluated against AFFG\u2019s regulatory compliance requirements."));
  content.push(brandRule());

  // ---- 2. COMPLIANCE CONTEXT ----
  content.push(heading1("2. COMPLIANCE REQUIREMENTS FOR WIRELESS"));
  content.push(spacer());
  content.push(p("As established in SOW-AFFG-001, AFFG is subject to SEC, FINRA, FTC, HIPAA, SOC 2, PCI-DSS 4.0, and GDPR compliance frameworks. Each imposes specific requirements on wireless network infrastructure:"));
  content.push(spacer());

  content.push(heading2("2.1 Wireless-Specific Compliance Controls"));
  content.push(spacer());
  content.push(makeTable(
    ["Framework", "Wireless Requirement", "Control"],
    [
      ["SEC Reg S-P (2024)", "Encrypted wireless transmission of NPI/PII", "WPA3-Enterprise or WPA3-SAE minimum"],
      ["FINRA Rule 4370", "Wireless infrastructure in BCP documentation", "Managed AP with monitoring and alerting"],
      ["FINRA Rule 3110", "Supervisory control over wireless access", "Centralized management with audit logging"],
      ["FTC Safeguards", "Encryption of customer information in transit", "WPA3 with AES-256; rogue AP detection"],
      ["HIPAA \u00A7164.312(e)", "Transmission security for ePHI", "WPA3-Enterprise; network segmentation via VLAN"],
      ["SOC 2 CC6.1", "Logical access controls for wireless networks", "802.1X authentication; RBAC; session logging"],
      ["PCI-DSS 4.0 \u00A711.2", "Wireless analyzer scans / rogue AP detection", "Built-in WIDS/WIPS or Sophos Central integration"],
      ["PCI-DSS 4.0 \u00A72.3", "Wireless encryption standards", "WPA3 mandatory; WPA2-TKIP prohibited"],
      ["GDPR Art. 32", "Appropriate technical measures for data in transit", "WPA3; AP management access restricted and logged"]
    ],
    [1800, 3300, 4260]
  ));
  content.push(spacer());

  content.push(heading2("2.2 Critical Compliance Capabilities"));
  content.push(spacer());
  content.push(bullet("WPA3-Enterprise or WPA3-SAE encryption (mandatory across all frameworks)", "bullets"));
  content.push(bullet("Centralized cloud management with audit logging (FINRA 3110, SOC 2)", "bullets"));
  content.push(bullet("WIDS/WIPS rogue access point detection (PCI-DSS 4.0 \u00A711.2)", "bullets"));
  content.push(bullet("VLAN support for network segmentation (HIPAA, PCI-DSS)", "bullets"));
  content.push(bullet("802.1X / RADIUS authentication support (SOC 2 CC6.1)", "bullets"));
  content.push(bullet("Encrypted management interface with role-based access (GDPR Art. 32)", "bullets"));
  content.push(bullet("Firmware update management and vulnerability patching (all frameworks)", "bullets"));
  content.push(brandRule());

  // ---- 3. ACCESS POINT OPTIONS ----
  content.push(heading1("3. ACCESS POINT OPTIONS"));
  content.push(spacer());
  content.push(p("Technijian presents three access point options for Client consideration. Each has been evaluated for technical capability, compliance coverage, integration with the Sophos firewall deployed under SOW-AFFG-001, and total cost of ownership."));
  content.push(spacer());

  // --- Option A: Sophos AP6 420 ---
  content.push(heading2("Option A: Sophos AP6 420 (RECOMMENDED)"));
  content.push(spacer());
  content.push(makeTable(
    ["Specification", "Details"],
    [
      ["Model / SKU", "AP6 420 (AP420U00ZZPCNP)"],
      ["Wi-Fi Standard", "Wi-Fi 6 (802.11ax)"],
      ["Bands", "Dual-Band (2.4 GHz + 5 GHz)"],
      ["MIMO", "2x2:2"],
      ["Max Supported Devices", "Up to 100 concurrent clients"],
      ["PoE Requirement", "802.3af/at (standard PoE) \u2014 ~15W"],
      ["Management", "Sophos Central (cloud) \u2014 same console as Sophos firewall"],
      ["MSRP (Hardware)", "$260.00"],
      ["Annual Support License", "$13.00/year (optional \u2014 advance RMA + firmware updates)"],
      ["Mandatory Subscription", "None \u2014 AP functions without paid subscription"]
    ],
    [3200, 6160]
  ));
  content.push(spacer());

  content.push(heading3("Compliance Assessment \u2014 Sophos AP6 420"));
  content.push(spacer());
  content.push(makeTable(
    ["Compliance Control", "Status", "Notes"],
    [
      ["WPA3-Enterprise / WPA3-SAE", "PASS", "Full WPA3 support"],
      ["Centralized Management + Audit Logging", "PASS", "Sophos Central \u2014 unified with firewall management"],
      ["WIDS/WIPS Rogue AP Detection", "PASS", "Built-in via Sophos Central Wireless"],
      ["VLAN / Network Segmentation", "PASS", "Full VLAN tagging and multiple SSID support"],
      ["802.1X / RADIUS", "PASS", "Enterprise authentication supported"],
      ["Encrypted Management Interface", "PASS", "TLS-encrypted Sophos Central; RBAC"],
      ["Firmware Management", "PASS", "Centralized firmware deployment via Sophos Central"],
      ["Synchronized Security (Sophos Heartbeat)", "PASS", "Native integration \u2014 AP shares health status with firewall"],
      [{ text: "Overall Compliance Score", bold: true }, { text: "8/8 PASS", bold: true }, { text: "Full compliance \u2014 best Sophos ecosystem integration", bold: true }]
    ],
    [3200, 1200, 4960]
  ));
  content.push(spacer());

  content.push(p("Recommendation Rationale:", { bold: true, color: CHARCOAL }));
  content.push(bullet("Native Sophos ecosystem integration \u2014 the AP6 420 is managed from the same Sophos Central console as the SF V-2C4 firewall deployed under SOW-AFFG-001", "bullets2"));
  content.push(bullet("Synchronized Security (Heartbeat) \u2014 the AP shares endpoint health status with the firewall, enabling automatic isolation of compromised wireless clients", "bullets2"));
  content.push(bullet("Unified compliance reporting \u2014 wireless logs, firewall logs, and security events in a single pane of glass for auditors", "bullets2"));
  content.push(bullet("Lowest total cost of ownership \u2014 no mandatory subscription; optional $13/year support", "bullets2"));
  content.push(bullet("Single-vendor accountability \u2014 simplifies incident response and audit evidence collection", "bullets2"));
  content.push(spacer());

  // --- Option B: Cisco Meraki CW9176I ---
  content.push(heading2("Option B: Cisco Meraki CW9176I"));
  content.push(spacer());
  content.push(makeTable(
    ["Specification", "Details"],
    [
      ["Model / SKU", "CW9176I-RTG"],
      ["Wi-Fi Standard", "Wi-Fi 7 (802.11be)"],
      ["Bands", "Tri-Band (2.4 GHz + 5 GHz + 6 GHz)"],
      ["MIMO", "4x4:4"],
      ["Max Supported Devices", "500+ concurrent clients"],
      ["PoE Requirement", "802.3bt (PoE++) required \u2014 ~35W"],
      ["Management", "Meraki Cloud Dashboard (separate platform from Sophos Central)"],
      ["MSRP (Hardware)", "$2,507.00"],
      ["Annual License (Mandatory)", "$150.00/year (Enterprise License \u2014 AP will not function without it)"],
      ["Year 1 Total", "$2,657.00"]
    ],
    [3200, 6160]
  ));
  content.push(spacer());

  content.push(heading3("Compliance Assessment \u2014 Cisco Meraki CW9176I"));
  content.push(spacer());
  content.push(makeTable(
    ["Compliance Control", "Status", "Notes"],
    [
      ["WPA3-Enterprise / WPA3-SAE", "PASS", "Full WPA3 support including 6 GHz band"],
      ["Centralized Management + Audit Logging", "PASS", "Meraki Cloud Dashboard \u2014 separate console from Sophos"],
      ["WIDS/WIPS Rogue AP Detection", "PASS", "Built-in Air Marshal \u2014 industry-leading WIDS/WIPS"],
      ["VLAN / Network Segmentation", "PASS", "Full VLAN and Group Policy support"],
      ["802.1X / RADIUS", "PASS", "Enterprise authentication with Meraki RADIUS proxy"],
      ["Encrypted Management Interface", "PASS", "TLS-encrypted cloud dashboard; RBAC; SAML SSO"],
      ["Firmware Management", "PASS", "Automatic firmware updates via Meraki cloud"],
      ["Synchronized Security (Sophos Heartbeat)", "FAIL", "No Sophos integration \u2014 separate security ecosystem"],
      [{ text: "Overall Compliance Score", bold: true }, { text: "7/8 PASS", bold: true }, { text: "Strong standalone compliance \u2014 no Sophos integration", bold: true }]
    ],
    [3200, 1200, 4960]
  ));
  content.push(spacer());

  content.push(p("Considerations:", { bold: true, color: CHARCOAL }));
  content.push(bullet("Enterprise-class hardware significantly oversized for a 15-user, <50 device environment", "bullets3"));
  content.push(bullet("Mandatory annual license ($150/year) \u2014 AP ceases to function entirely if the license lapses, creating a business continuity risk (FINRA Rule 4370)", "bullets3"));
  content.push(bullet("Requires PoE++ (802.3bt) \u2014 existing PoE switches may not support the higher power draw; may require a PoE injector or switch upgrade (additional cost)", "bullets3"));
  content.push(bullet("Separate management console from Sophos firewall \u2014 auditors must collect evidence from two platforms instead of one", "bullets3"));
  content.push(bullet("No Sophos Synchronized Security (Heartbeat) \u2014 cannot automatically isolate compromised wireless clients at the firewall level", "bullets3"));
  content.push(spacer());

  // --- Option C: Ubiquiti UniFi U7 Pro ---
  content.push(heading2("Option C: Ubiquiti UniFi U7 Pro"));
  content.push(spacer());
  content.push(makeTable(
    ["Specification", "Details"],
    [
      ["Model / SKU", "U7-Pro (U7-PRO-US)"],
      ["Wi-Fi Standard", "Wi-Fi 7 (802.11be)"],
      ["Bands", "Tri-Band (2.4 GHz + 5 GHz + 6 GHz)"],
      ["MIMO", "2x2:2 per band"],
      ["Max Supported Devices", "300+ concurrent clients"],
      ["PoE Requirement", "802.3at (PoE+) \u2014 ~18W"],
      ["Management", "UniFi Controller (self-hosted or UniFi Cloud Gateway)"],
      ["MSRP (Hardware)", "$189.00"],
      ["Annual Subscription", "None \u2014 no recurring license fees"],
      ["Year 1 Total", "$189.00"]
    ],
    [3200, 6160]
  ));
  content.push(spacer());

  content.push(heading3("Compliance Assessment \u2014 Ubiquiti UniFi U7 Pro"));
  content.push(spacer());
  content.push(makeTable(
    ["Compliance Control", "Status", "Notes"],
    [
      ["WPA3-Enterprise / WPA3-SAE", "PASS", "Full WPA3 support"],
      ["Centralized Management + Audit Logging", "PARTIAL", "UniFi Controller provides management but audit logging is limited compared to enterprise platforms; no SOC 2 attestation for UniFi cloud"],
      ["WIDS/WIPS Rogue AP Detection", "PARTIAL", "Basic RF scanning available; no dedicated WIDS/WIPS comparable to Meraki Air Marshal or Sophos Central"],
      ["VLAN / Network Segmentation", "PASS", "Full VLAN and multiple SSID support"],
      ["802.1X / RADIUS", "PASS", "Enterprise authentication supported"],
      ["Encrypted Management Interface", "PARTIAL", "Self-hosted controller requires customer-managed TLS; cloud option lacks enterprise RBAC depth"],
      ["Firmware Management", "PASS", "Centralized via UniFi Controller"],
      ["Synchronized Security (Sophos Heartbeat)", "FAIL", "No Sophos integration \u2014 separate ecosystem"],
      [{ text: "Overall Compliance Score", bold: true }, { text: "5/8 PASS", bold: true }, { text: "Gaps in audit logging, WIDS/WIPS, and management security", bold: true }]
    ],
    [3200, 1200, 4960]
  ));
  content.push(spacer());

  content.push(p("Considerations:", { bold: true, color: CHARCOAL }));
  content.push(bullet("Lowest hardware cost but compliance gaps may require additional compensating controls, increasing real-world cost", "bullets4"));
  content.push(bullet("Limited audit logging \u2014 FINRA 3110 and SOC 2 CC6.1 require demonstrable supervisory controls with audit trails; UniFi\u2019s logging may not satisfy auditor scrutiny", "bullets4"));
  content.push(bullet("WIDS/WIPS capability is basic \u2014 PCI-DSS 4.0 \u00A711.2 requires wireless analyzer scans; may require supplemental quarterly scanning", "bullets4"));
  content.push(bullet("Self-hosted controller requires additional infrastructure management, patching, and backup \u2014 increases operational burden", "bullets4"));
  content.push(bullet("No Sophos Synchronized Security (Heartbeat) \u2014 same limitation as Meraki", "bullets4"));
  content.push(bullet("Consumer/prosumer brand perception may raise questions during SEC or FINRA examinations", "bullets4"));
  content.push(brandRule());

  // ---- 4. COMPARISON SUMMARY ----
  content.push(heading1("4. COMPARISON SUMMARY"));
  content.push(spacer());

  content.push(heading2("4.1 Technical Comparison"));
  content.push(spacer());
  content.push(makeTable(
    ["Feature", "Sophos AP6 420", "Meraki CW9176I", "UniFi U7 Pro"],
    [
      ["Wi-Fi Standard", "Wi-Fi 6", "Wi-Fi 7", "Wi-Fi 7"],
      ["Bands", "Dual-Band", "Tri-Band", "Tri-Band"],
      ["MIMO", "2x2", "4x4", "2x2"],
      ["PoE", "af/at (15W)", "bt PoE++ (35W)", "at PoE+ (18W)"],
      ["Sophos Integration", "Native (Heartbeat)", "None", "None"],
      ["Rogue AP Detection", "Full WIDS/WIPS", "Full (Air Marshal)", "Basic"],
      ["Audit Logging", "Enterprise-grade", "Enterprise-grade", "Limited"],
      ["Compliance Score", "8/8", "7/8", "5/8"]
    ],
    [2400, 2280, 2280, 2400]
  ));
  content.push(spacer());

  content.push(heading2("4.2 Cost Comparison"));
  content.push(spacer());
  content.push(makeTable(
    ["Cost Item", "Sophos AP6 420", "Meraki CW9176I", "UniFi U7 Pro"],
    [
      ["Hardware (MSRP)", "$260.00", "$2,507.00", "$189.00"],
      ["Annual License/Support", "$13.00 (optional)", "$150.00 (mandatory)", "$0.00"],
      ["Year 1 Total", "$260.00 \u2013 $273.00", "$2,657.00", "$189.00"],
      ["3-Year TCO", "$286.00 \u2013 $299.00", "$2,807.00 \u2013 $2,957.00", "$189.00"],
      [{ text: "Mandatory License?", bold: true }, { text: "No", bold: true }, { text: "Yes \u2014 AP stops working", bold: true }, { text: "No", bold: true }]
    ],
    [2400, 2280, 2280, 2400]
  ));
  content.push(brandRule());

  // ---- 5. TECHNIJIAN RECOMMENDATION ----
  content.push(heading1("5. TECHNIJIAN RECOMMENDATION"));
  content.push(spacer());
  content.push(p("Technijian recommends Option A: Sophos AP6 420 for the following reasons:", { bold: true, color: CHARCOAL }));
  content.push(spacer());
  content.push(bullet("Full 8/8 compliance score \u2014 the only option that passes all regulatory control requirements without compensating controls", "bullets5"));
  content.push(bullet("Native Sophos ecosystem integration \u2014 managed from the same Sophos Central console as the firewall, providing unified security visibility and audit evidence", "bullets5"));
  content.push(bullet("Synchronized Security (Heartbeat) \u2014 the AP communicates with the Sophos firewall in real-time; if a wireless client is compromised, the firewall can automatically isolate it from the network", "bullets5"));
  content.push(bullet("Lowest total cost of ownership \u2014 $260 hardware with no mandatory subscription vs. $2,657 Year 1 for Meraki", "bullets5"));
  content.push(bullet("Right-sized for the environment \u2014 supports up to 100 clients, appropriate for AFFG\u2019s 15-user / <50 device environment without over-provisioning", "bullets5"));
  content.push(bullet("Single-vendor security stack \u2014 firewall + AP + endpoint protection all under Sophos Central reduces audit complexity and incident response time", "bullets5"));
  content.push(brandRule());

  // ---- 6. SCOPE OF WORK ----
  content.push(heading1("6. SCOPE OF WORK"));
  content.push(spacer());
  content.push(p("Upon Client selection of an access point option, Technijian shall perform the following:"));
  content.push(spacer());

  content.push(heading2("6.1 In Scope"));
  content.push(bullet("Procurement of the selected access point at the MSRP price listed above", "bullets6"));
  content.push(bullet("Disable Wi-Fi on existing router to eliminate unmonitored wireless traffic", "bullets6"));
  content.push(bullet("Physical installation of the access point at Client\u2019s primary location", "bullets6"));
  content.push(bullet("Configuration of WPA3-Enterprise or WPA3-SAE encryption", "bullets6"));
  content.push(bullet("VLAN configuration for wireless network segmentation (guest vs. corporate SSIDs)", "bullets6"));
  content.push(bullet("802.1X / RADIUS configuration (if Client has or deploys a RADIUS server)", "bullets6"));
  content.push(bullet("Integration with Sophos firewall \u2014 wireless traffic routed through Sophos inspection engine", "bullets6"));
  content.push(bullet("Sophos Central enrollment and Synchronized Security configuration (Option A only)", "bullets6"));
  content.push(bullet("WIDS/WIPS rogue AP detection configuration", "bullets6"));
  content.push(bullet("Post-deployment validation and wireless coverage testing", "bullets6"));
  content.push(bullet("Compliance evidence documentation for wireless controls", "bullets6"));
  content.push(spacer());

  content.push(heading2("6.2 Out of Scope"));
  content.push(bullet("RADIUS server deployment (covered under separate SOW if needed)", "bullets7"));
  content.push(bullet("Additional access points for extended coverage areas", "bullets7"));
  content.push(bullet("PoE switch upgrades (if required for Meraki option \u2014 quoted separately)", "bullets7"));
  content.push(bullet("Wireless site survey or heat mapping", "bullets7"));
  content.push(spacer());

  content.push(heading2("6.3 Schedule"));
  content.push(spacer());
  content.push(makeTable(
    ["Role", "Resource", "Description", "Est. Hours", "Timeline"],
    [
      ["Sr. Engineer", "US", "Router Wi-Fi disable, AP physical install, and network integration", "2", "During SOW-001 Phase 3"],
      ["Sr. Engineer", "US", "WPA3, VLAN, 802.1X, and security policy configuration", "1", "During SOW-001 Phase 4"],
      ["Engineer", "Offshore", "Sophos Central enrollment, WIDS/WIPS config, and compliance documentation", "1", "During SOW-001 Phase 4"],
      [{ text: "", bold: true }, "", { text: "Total", bold: true }, { text: "4", bold: true }, ""]
    ],
    [1600, 1100, 3300, 1180, 1180]
  ));
  content.push(brandRule());

  // ---- 7. PRICING ----
  content.push(heading1("7. PRICING AND PAYMENT"));
  content.push(spacer());

  content.push(heading2("7.1 Rate Card"));
  content.push(makeTable(
    ["Resource Tier", "Description", "Hourly Rate"],
    [
      ["Sr. Engineer (US)", "On-shore senior technical resource \u2014 installation, configuration, integration", "$150.00"],
      ["Engineer (Offshore)", "Off-shore technical resource \u2014 enrollment, documentation, compliance evidence", "$45.00"]
    ],
    [2800, 4560, 2000]
  ));
  content.push(spacer());

  content.push(heading2("7.2 Labor Cost"));
  content.push(makeTable(
    ["Resource", "Hours", "Rate", "Cost"],
    [
      ["Sr. Engineer (US)", "3", "$150.00", "$450.00"],
      ["Engineer (Offshore)", "1", "$45.00", "$45.00"],
      [{ text: "Labor Subtotal", bold: true }, "", "", { text: "$495.00", bold: true }]
    ],
    [2800, 1400, 2480, 2680]
  ));
  content.push(spacer());

  content.push(heading2("7.3 Equipment Cost (Client Selects One)"));
  content.push(makeTable(
    ["Option", "Access Point", "MSRP Price", "Annual License", "Year 1 Total"],
    [
      ["Option A (Recommended)", "Sophos AP6 420", "$260.00", "$13.00 (optional)", "$260.00 \u2013 $273.00"],
      ["Option B", "Cisco Meraki CW9176I", "$2,507.00", "$150.00 (mandatory)", "$2,657.00"],
      ["Option C", "Ubiquiti UniFi U7 Pro", "$189.00", "$0.00", "$189.00"]
    ],
    [2000, 2000, 1680, 1880, 1800]
  ));
  content.push(spacer());

  content.push(heading2("7.4 Total Investment Summary"));
  content.push(spacer());
  content.push(makeTable(
    ["Cost Component", "Option A (Sophos)", "Option B (Meraki)", "Option C (Ubiquiti)"],
    [
      ["Labor", "$495.00", "$495.00", "$495.00"],
      ["Hardware (MSRP)", "$260.00", "$2,507.00", "$189.00"],
      ["Annual License (Year 1)", "$13.00 (optional)", "$150.00", "$0.00"],
      [{ text: "Total Investment", bold: true }, { text: "$755.00 \u2013 $768.00", bold: true }, { text: "$3,152.00", bold: true }, { text: "$684.00", bold: true }]
    ],
    [2400, 2280, 2280, 2400]
  ));
  content.push(spacer());

  content.push(heading2("7.5 Pricing Disclaimer"));
  content.push(p("All equipment prices listed in this SOW are based on Manufacturer\u2019s Suggested Retail Price (MSRP) as of March 31, 2026. Technijian is currently collecting final distributor and vendor quotes. The actual invoiced equipment price may be adjusted downward once final quotes are received. Technijian shall notify Client of any price adjustment prior to invoicing. In no event shall the equipment price exceed the MSRP listed herein.", { italics: true }));
  content.push(spacer());

  content.push(heading2("7.6 Payment Terms"));
  content.push(p("Equipment cost is due upon SOW execution. Labor is invoiced upon completion. All invoices are due and payable within thirty (30) days of the invoice date."));
  content.push(brandRule());

  // ---- 8. CLIENT SELECTION ----
  content.push(heading1("8. CLIENT SELECTION"));
  content.push(spacer());
  content.push(p("Client selects the following access point option (check one):"));
  content.push(spacer());
  content.push(p("\u25A1  Option A: Sophos AP6 420 \u2014 $260.00 (Recommended)", { bold: true, color: CHARCOAL }));
  content.push(spacer());
  content.push(p("\u25A1  Option B: Cisco Meraki CW9176I \u2014 $2,507.00 + $150.00/year license", { bold: true, color: CHARCOAL }));
  content.push(spacer());
  content.push(p("\u25A1  Option C: Ubiquiti UniFi U7 Pro \u2014 $189.00", { bold: true, color: CHARCOAL }));
  content.push(brandRule());

  // ---- 9. GOVERNING TERMS ----
  content.push(heading1("9. GOVERNING TERMS"));
  content.push(p("9.01. This Addendum SOW is governed by the same terms and conditions as SOW-AFFG-001. All provisions of SOW-AFFG-001 regarding change management, acceptance, liability, and governing law apply to this addendum."));
  content.push(spacer());
  content.push(p("9.02. Work under this addendum will be performed concurrently with SOW-AFFG-001 Phases 3 and 4 to minimize disruption and avoid duplicate site visits."));
  content.push(brandRule());

  // ---- SIGNATURES ----
  content.push(heading1("SIGNATURES"));
  content.push(spacer());
  content.push(p("TECHNIJIAN, INC.", { bold: true, color: CHARCOAL }));
  content.push(spacer());
  content.push(p("By: ___________________________________"));
  content.push(spacer());
  content.push(p("Name: _________________________________"));
  content.push(spacer());
  content.push(p("Title: _________________________________"));
  content.push(spacer());
  content.push(p("Date: _________________________________"));
  content.push(spacer());
  content.push(spacer());
  content.push(p("AMERICAN FUNDSTARS FINANCIAL GROUP LLC", { bold: true, color: CHARCOAL }));
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
          "Addendum \u2014 Statement of Work",
          "Wireless Access Point Deployment \u2014 American Fundstars Financial Group LLC"
        )
      },
      {
        properties: contentSectionProps(),
        children: content
      }
    ]
  });

  const buffer = await Packer.toBuffer(doc);
  const outputPath = path.join(__dirname, "..", "03_SOW", "SOW-AFFG-002-WirelessAP.docx");
  fs.writeFileSync(outputPath, buffer);
  console.log("Generated:", outputPath);
}

generateSOW().catch(err => {
  console.error("Error generating SOW:", err);
  process.exit(1);
});
