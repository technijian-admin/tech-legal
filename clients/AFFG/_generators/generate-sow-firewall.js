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
      reference: "bullets8",
      levels: [{
        level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 720, hanging: 360 } } }
      }]
    },
    {
      reference: "bullets9",
      levels: [{
        level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 720, hanging: 360 } } }
      }]
    },
    {
      reference: "bullets10",
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
  items.push(p("March 23, 2026", { size: 22, color: GREY, alignment: AlignmentType.CENTER, spacing: { after: 200 } }));
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
    { text: "SOW-AFFG-001" }
  ]));
  content.push(multiRun([
    { text: "Effective Date: ", bold: true, color: CHARCOAL },
    { text: "March 23, 2026" }
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
  content.push(p("American Fundstars Financial Group LLC (\u201CClient\u201D)", { bold: true, color: CHARCOAL }));
  content.push(p("1 Park Plaza, Suite 210"));
  content.push(p("Irvine, California 92618"));
  content.push(multiRun([{ text: "Primary Contact: ", bold: true, color: CHARCOAL }, { text: "Iris Liu" }]));
  content.push(brandRule());

  // ---- 1. PROJECT OVERVIEW ----
  content.push(heading1("1. PROJECT OVERVIEW"));

  content.push(heading2("1.1 Project Title"));
  content.push(p("Sophos SF V-2C4 Virtual Firewall & Edge Appliance Deployment"));
  content.push(spacer());

  content.push(heading2("1.2 Project Description"));
  content.push(p("American Fundstars Financial Group LLC (\u201CAFFG\u201D) is a dually registered Investment Adviser (RIA) and Broker-Dealer regulated by the Securities and Exchange Commission (SEC) and the Financial Industry Regulatory Authority (FINRA). As a regulated financial institution handling nonpublic personal information (NPI), personally identifiable information (PII), and customer financial data, AFFG is subject to the following compliance frameworks, each of which mandates network-layer security controls:"));
  content.push(spacer());
  content.push(bullet("SEC Regulation S-P (2024 Amendments) \u2014 Privacy of Consumer Financial Information and Safeguarding Customer Information", "bullets"));
  content.push(bullet("SEC Regulation S-ID \u2014 Identity Theft Red Flag Rules", "bullets"));
  content.push(bullet("FINRA Rule 4370 \u2014 Business Continuity Plans and Emergency Contact Information", "bullets"));
  content.push(bullet("FINRA Rule 3110 \u2014 Supervision (supervisory continuity during disruptions)", "bullets"));
  content.push(bullet("FINRA Cybersecurity Guidance \u2014 Annual Regulatory and Examination Priorities", "bullets"));
  content.push(bullet("FTC Safeguards Rule (16 CFR Part 314) \u2014 Financial Institution Information Security Requirements", "bullets"));
  content.push(bullet("HIPAA Security Rule \u2014 Where AFFG handles protected health information", "bullets"));
  content.push(bullet("SOC 2 Trust Services Criteria \u2014 Service organization controls for data security", "bullets"));
  content.push(bullet("PCI-DSS 4.0 \u2014 Payment card data handling requirements", "bullets"));
  content.push(bullet("GDPR \u2014 Where applicable to EU data subjects", "bullets"));
  content.push(spacer());
  content.push(p("This SOW covers the supply, deployment, configuration, and ongoing management of a Technijian-provided Edge Appliance 16GB with VMware ESXi hypervisor hosting a Sophos SF V-2C4 Virtual Firewall to establish a compliant, enterprise-grade network security perimeter for AFFG\u2019s 15-user environment. Technijian will supply all hardware, hypervisor software, and virtual appliance licensing as a fully managed solution. This engagement directly addresses critical control requirements across all applicable compliance frameworks and closes identified gaps from AFFG\u2019s BCP Compliance Review (March 6, 2026)."));
  content.push(spacer());

  content.push(heading2("1.3 Location"));
  content.push(makeTable(
    ["Location Name", "Code", "Address", "Billable"],
    [["AFFG - Primary", "AFFG-HQ", "1 Park Plaza, Ste 210, Irvine, CA 92618", "Yes"]],
    [2340, 1560, 3900, 1560]
  ));
  content.push(brandRule());

  // ---- 2. COMPLIANCE JUSTIFICATION ----
  content.push(heading1("2. COMPLIANCE JUSTIFICATION"));
  content.push(p("As a dually registered RIA/Broker-Dealer handling customer NPI, PII, and financial data, AFFG is required by SEC, FINRA, and multiple additional regulatory frameworks to implement and maintain network security controls. The amended SEC Regulation S-P (mandatory compliance effective 2026) specifically requires covered institutions to develop, implement, and maintain written policies and procedures for detecting, responding to, and recovering from unauthorized access to customer information\u2014including technical safeguards such as network perimeter defense."));
  content.push(spacer());
  content.push(p("The deployment of a next-generation firewall with intrusion prevention, encrypted traffic inspection, and centralized logging is not optional\u2014it is a regulatory mandate. The following table maps the Sophos SF V-2C4 firewall capabilities directly to the compliance controls they satisfy:"));
  content.push(spacer());

  // Compliance mapping table
  content.push(heading2("2.1 Firewall Controls to Compliance Framework Mapping"));
  content.push(makeTable(
    ["Firewall Capability", "HIPAA", "SOC 2 (TSC)", "PCI-DSS 4.0", "GDPR"],
    [
      [
        "Intrusion Prevention (IPS)",
        "\u00A7164.312(e)(1) Transmission Security",
        "CC6.1, CC6.6 Logical & Network Access",
        "Req 1 - Network Security Controls; Req 11 - Test Security",
        "Art 32 - Security of Processing"
      ],
      [
        "TLS 1.3 Encrypted Traffic Inspection",
        "\u00A7164.312(a)(2)(iv) Encryption Mechanism",
        "CC6.1, CC6.7 Encryption Controls",
        "Req 4 - Encrypt Transmissions",
        "Art 32(1)(a) - Encryption"
      ],
      [
        "Advanced Threat Protection & Zero-Day Sandboxing",
        "\u00A7164.308(a)(5)(ii)(B) Malicious Software Protection",
        "CC6.8, CC7.1 Threat Detection",
        "Req 5 - Anti-Malware; Req 6.3 - Patching",
        "Art 32 - Security of Processing"
      ],
      [
        "Application Control (3,300+ apps)",
        "\u00A7164.312(a)(1) Access Control",
        "CC6.1 Logical Access",
        "Req 7 - Restrict Access",
        "Art 32(1)(b) - Confidentiality"
      ],
      [
        "Centralized Logging & Reporting (Sophos Central)",
        "\u00A7164.312(b) Audit Controls",
        "CC7.1, CC7.2, CC7.3 Monitoring & Detection",
        "Req 10 - Log & Monitor Access",
        "Art 32 - Security of Processing"
      ],
      [
        "VPN (IPsec & SSL) Encrypted Remote Access",
        "\u00A7164.312(e)(1) Transmission Security",
        "CC6.1, CC6.6 Secure Access",
        "Req 4 - Encrypt Transmissions; Req 8 - Identify Users",
        "Art 32(1)(a) - Encryption"
      ],
      [
        "DoS/DDoS Protection",
        "\u00A7164.308(a)(7) Contingency Plan",
        "A1.2 Recovery Objectives",
        "Req 1 - Network Security Controls",
        "Art 32(1)(c) - Availability & Resilience"
      ],
      [
        "Web Filtering & Content Control",
        "\u00A7164.308(a)(1) Risk Management",
        "CC6.1 Logical Access",
        "Req 1 - Network Segmentation",
        "Art 25 - Data Protection by Design"
      ]
    ],
    [1900, 1700, 1900, 2000, 1860]
  ));
  content.push(spacer());

  // Financial services-specific
  content.push(heading2("2.2 SEC & FINRA Requirements (AFFG-Specific)"));
  content.push(p("As a dually registered RIA/Broker-Dealer, AFFG is directly subject to the following requirements that mandate network security controls:"));
  content.push(spacer());

  content.push(bulletMulti([
    { text: "SEC Regulation S-P (2024 Amendments): ", bold: true, color: CHARCOAL },
    { text: "The amended rule (mandatory compliance 2026) requires covered institutions to implement administrative, technical, and physical safeguards to protect customer records and NPI. Technical safeguards explicitly include network perimeter defense, encryption of data in transit, and monitoring for unauthorized access. A next-generation firewall with IPS, TLS inspection, and centralized logging directly satisfies these requirements." }
  ], "bullets"));

  content.push(bulletMulti([
    { text: "SEC Regulation S-ID: ", bold: true, color: CHARCOAL },
    { text: "Identity theft red-flag detection programs require monitoring and alerting capabilities. The Sophos SF V-2C4\u2019s Advanced Threat Protection and application-level traffic analysis provide network-layer detection of anomalous activity consistent with red-flag indicators." }
  ], "bullets2"));

  content.push(bulletMulti([
    { text: "FINRA Rule 4370 (BCP Requirements): ", bold: true, color: CHARCOAL },
    { text: "Requires identification and protection of mission-critical systems. AFFG\u2019s BCP Compliance Review (March 6, 2026) identified significant gaps in network security controls. A properly configured firewall with DoS/DDoS protection, failover capabilities, and centralized logging is essential for business continuity of mission-critical trading and customer account systems." }
  ], "bullets3"));

  content.push(bulletMulti([
    { text: "FINRA Cybersecurity Guidance: ", bold: true, color: CHARCOAL },
    { text: "FINRA\u2019s annual Regulatory and Examination Priorities consistently identify network security controls\u2014firewalls, intrusion detection, and data loss prevention\u2014as core expectations for broker-dealers. The Sophos SF V-2C4 delivers all three in a single, centrally managed platform." }
  ], "bullets4"));

  content.push(bulletMulti([
    { text: "FTC Safeguards Rule (16 CFR Part 314): ", bold: true, color: CHARCOAL },
    { text: "The amended 2023 requirements mandate access controls, encryption, multi-factor authentication, monitoring, and regular testing for financial institutions. The Sophos firewall\u2019s VPN with MFA support, TLS inspection, IPS monitoring, and Sophos Central audit logging directly address these obligations." }
  ], "bullets5"));

  content.push(spacer());
  content.push(heading2("2.3 BCP Compliance Review Findings Addressed"));
  content.push(p("AFFG\u2019s BCP Compliance Review (March 6, 2026) identified 3 critical, 7 high, and 9 medium findings across SEC Reg S-P and FINRA requirements. This firewall deployment directly addresses the following identified gaps:"));
  content.push(spacer());
  content.push(makeTable(
    ["BCP Finding", "Severity", "How This Deployment Addresses It"],
    [
      ["No network perimeter defense for customer data", "CRITICAL", "Sophos SF V-2C4 provides enterprise-grade IPS, ATP, and encrypted traffic inspection at the network boundary"],
      ["No centralized logging or audit trail for network activity", "HIGH", "Sophos Central provides 30-day log retention, real-time alerting, and compliance-ready reporting"],
      ["No encrypted traffic inspection capability", "HIGH", "TLS 1.3 inspection eliminates the largest blind spot in modern network security"],
      ["No intrusion detection/prevention system", "HIGH", "IPS with continuous monitoring of all traffic including inter-VLAN and SSL/TLS decrypted scanning"],
      ["Service provider oversight gaps (network layer)", "CRITICAL", "Centralized Sophos Central management enables Technijian to provide documented oversight and 72-hour breach detection capability"]
    ],
    [2700, 1200, 5460]
  ));

  content.push(spacer());
  content.push(p("Without a properly configured next-generation firewall, AFFG cannot demonstrate compliance with SEC Reg S-P, FINRA examination expectations, or the FTC Safeguards Rule network security mandates. This deployment directly addresses Control Domain #10 (Network Security) in AFFG\u2019s compliance control mapping and remediates critical findings from the March 2026 BCP review.", { italics: true }));
  content.push(brandRule());

  // ---- 3. SCOPE OF WORK ----
  content.push(heading1("3. SCOPE OF WORK"));

  content.push(heading2("3.1 In Scope"));
  content.push(bullet("Supply and deployment of Technijian-provided Edge Appliance 16GB at Client\u2019s primary location", "bullets4"));
  content.push(bullet("Installation and configuration of VMware ESXi hypervisor on the Edge Appliance", "bullets4"));
  content.push(bullet("Deployment of Sophos SF V-2C4 Virtual Firewall as a virtual machine on ESXi", "bullets4"));
  content.push(bullet("Xstream Protection Bundle license activation and configuration", "bullets4"));
  content.push(bullet("Firewall policy creation including network segmentation, access control rules, and application filtering", "bullets4"));
  content.push(bullet("Intrusion Prevention System (IPS) tuning for AFFG\u2019s environment", "bullets4"));
  content.push(bullet("TLS 1.3 inspection configuration with pre-packaged and custom policy exceptions", "bullets4"));
  content.push(bullet("VPN configuration (IPsec and/or SSL) for secure remote access", "bullets4"));
  content.push(bullet("Web filtering and application control policy implementation", "bullets4"));
  content.push(bullet("Sophos Central cloud management platform enrollment and configuration", "bullets4"));
  content.push(bullet("Integration with existing endpoint protection (Synchronized Security heartbeat if applicable)", "bullets4"));
  content.push(bullet("30-day log retention configuration and centralized reporting setup", "bullets4"));
  content.push(bullet("Post-deployment validation and compliance documentation", "bullets4"));
  content.push(spacer());

  content.push(heading2("3.2 Out of Scope"));
  content.push(bullet("Desktop or workstation configuration changes beyond VPN client deployment", "bullets5"));
  content.push(bullet("Email security configuration (covered under separate Anti-Spam services)", "bullets5"));
  content.push(bullet("Physical network cabling or infrastructure upgrades at Client\u2019s site", "bullets5"));
  content.push(bullet("Third-party vendor coordination for ISP or circuit changes", "bullets5"));
  content.push(bullet("Endpoint security agent deployment (covered under separate SOW or managed services agreement)", "bullets5"));
  content.push(bullet("Compliance audit documentation beyond firewall-specific evidence", "bullets5"));
  content.push(spacer());

  content.push(heading2("3.3 Assumptions"));
  content.push(bullet("Technijian will supply the Edge Appliance 16GB hardware and VMware ESXi hypervisor; no existing client hypervisor infrastructure is required", "bullets6"));
  content.push(bullet("Client will designate a point of contact authorized to approve firewall policy decisions", "bullets6"));
  content.push(bullet("Existing network topology documentation will be provided or discovered during Phase 1", "bullets6"));
  content.push(bullet("Work will be performed remotely unless on-site presence is specifically required", "bullets6"));
  content.push(brandRule());

  // ---- 4. PROJECT PHASES ----
  content.push(heading1("4. PROJECT PHASES"));

  // Phase 1
  content.push(heading2("Phase 1: Discovery & Assessment"));
  content.push(heading3("4.1.1 Description"));
  content.push(p("Comprehensive assessment of AFFG\u2019s current network environment, virtual infrastructure resources, internet connectivity, existing security posture, and compliance requirements. This phase produces the network design document that governs all subsequent configuration."));
  content.push(spacer());
  content.push(heading3("4.1.2 Deliverables"));
  content.push(bullet("Network topology assessment and documentation", "bullets7"));
  content.push(bullet("Virtual infrastructure resource validation report", "bullets7"));
  content.push(bullet("Firewall policy design document (access rules, VPN, IPS, web filtering)", "bullets7"));
  content.push(bullet("Compliance control mapping worksheet (firewall controls to AFFG frameworks)", "bullets7"));
  content.push(spacer());
  content.push(heading3("4.1.3 Schedule"));
  content.push(makeTable(
    ["Role", "Resource", "Description", "Est. Hours", "Timeline"],
    [
      ["Sr. Engineer", "US", "Network discovery and topology assessment", "3", "Week 1"],
      ["Engineer", "Offshore", "Documentation and compliance control mapping", "2", "Week 1"],
      [{ text: "", bold: true }, "", { text: "Phase 1 Total", bold: true }, { text: "5", bold: true }, ""]
    ],
    [1600, 1100, 3300, 1180, 1180]
  ));
  content.push(spacer());

  // Phase 2
  content.push(heading2("Phase 2: ESXi & Firewall Deployment"));
  content.push(heading3("4.2.1 Description"));
  content.push(p("Install and configure VMware ESXi hypervisor on the Edge Appliance 16GB, deploy the Sophos SF V-2C4 virtual firewall as a VM on ESXi, activate the Xstream Protection Bundle license, and perform base configuration including network interfaces, DNS, NTP, DHCP (if applicable), and Sophos Central enrollment."));
  content.push(spacer());
  content.push(heading3("4.2.2 Deliverables"));
  content.push(bullet("VMware ESXi installed, configured, and operational on Edge Appliance 16GB", "bullets8"));
  content.push(bullet("Sophos SF V-2C4 deployed as VM on ESXi with allocated resources (2 vCPU, 4 GB RAM)", "bullets8"));
  content.push(bullet("Xstream Protection Bundle activated", "bullets8"));
  content.push(bullet("Base network configuration (virtual switches, interfaces, routing, NAT)", "bullets8"));
  content.push(bullet("Sophos Central cloud management enrolled and verified", "bullets8"));
  content.push(spacer());
  content.push(heading3("4.2.3 Schedule"));
  content.push(makeTable(
    ["Role", "Resource", "Description", "Est. Hours", "Timeline"],
    [
      ["Sr. Engineer", "US", "ESXi installation and hypervisor configuration", "2", "Week 2"],
      ["Sr. Engineer", "US", "Sophos VM deployment and network configuration", "1", "Week 2"],
      ["Engineer", "Offshore", "License activation and Sophos Central enrollment", "1", "Week 2"],
      ["Engineer", "Offshore", "Configuration documentation", "1", "Week 2"],
      [{ text: "", bold: true }, "", { text: "Phase 2 Total", bold: true }, { text: "5", bold: true }, ""]
    ],
    [1600, 1100, 3300, 1180, 1180]
  ));
  content.push(spacer());

  // Phase 3
  content.push(heading2("Phase 3: Edge Appliance Physical Installation & Network Integration"));
  content.push(heading3("4.3.1 Description"));
  content.push(p("Technijian will supply, deliver, and physically install the Edge Appliance 16GB at the Client\u2019s primary location. This Technijian-provided appliance serves as the dedicated hardware platform hosting the ESXi hypervisor and Sophos virtual firewall, providing the physical network edge that ensures all Client traffic passes through the Sophos security inspection engine."));
  content.push(spacer());
  content.push(heading3("4.3.2 Deliverables"));
  content.push(bullet("Technijian-supplied Edge Appliance 16GB physically delivered, racked, and powered on", "bullets9"));
  content.push(bullet("Physical network cabling integrated with Client\u2019s existing switch/router infrastructure", "bullets9"));
  content.push(bullet("WAN and LAN connectivity validated through ESXi virtual switches to Sophos firewall", "bullets9"));
  content.push(bullet("Traffic routing validated end-to-end through firewall inspection path", "bullets9"));
  content.push(spacer());
  content.push(heading3("4.3.3 Schedule"));
  content.push(makeTable(
    ["Role", "Resource", "Description", "Est. Hours", "Timeline"],
    [
      ["Sr. Engineer", "US", "Edge appliance delivery, rack mounting, and physical cabling", "2", "Week 2-3"],
      ["Sr. Engineer", "US", "WAN/LAN integration and end-to-end traffic path validation", "2", "Week 3"],
      [{ text: "", bold: true }, "", { text: "Phase 3 Total", bold: true }, { text: "4", bold: true }, ""]
    ],
    [1600, 1100, 3300, 1180, 1180]
  ));
  content.push(spacer());

  // Phase 4
  content.push(heading2("Phase 4: Security Policy & Compliance Configuration"));
  content.push(heading3("4.4.1 Description"));
  content.push(p("Configure all security policies aligned to AFFG\u2019s compliance requirements. This is the critical phase where regulatory control requirements are translated into firewall rules, IPS signatures, TLS inspection policies, application control rules, and web filtering policies."));
  content.push(spacer());
  content.push(heading3("4.4.2 Deliverables"));
  content.push(bullet("Firewall access control rules (ingress/egress) per compliance policy design", "bullets10"));
  content.push(bullet("Intrusion Prevention System (IPS) signatures enabled and tuned", "bullets10"));
  content.push(bullet("TLS 1.3 inspection enabled with appropriate exceptions", "bullets10"));
  content.push(bullet("Application control policies (3,300+ application signatures)", "bullets10"));
  content.push(bullet("Web filtering categories configured per acceptable use policy", "bullets10"));
  content.push(bullet("VPN configuration for secure remote access (IPsec/SSL)", "bullets10"));
  content.push(bullet("DoS/DDoS protection thresholds configured", "bullets10"));
  content.push(bullet("Xstream SD-WAN SLA policies (if applicable)", "bullets10"));
  content.push(bullet("Audit logging enabled and verified in Sophos Central (30-day retention)", "bullets10"));
  content.push(spacer());
  content.push(heading3("4.4.3 Schedule"));
  content.push(makeTable(
    ["Role", "Resource", "Description", "Est. Hours", "Timeline"],
    [
      ["Sr. Engineer", "US", "Access control rules and network segmentation", "3", "Week 3"],
      ["Sr. Engineer", "US", "IPS tuning and threat protection configuration", "2", "Week 3"],
      ["Sr. Engineer", "US", "VPN setup and remote access configuration", "1", "Week 4"],
      ["Engineer", "Offshore", "TLS inspection, app control, and web filtering", "2", "Week 3-4"],
      ["Engineer", "Offshore", "Logging, reporting, and audit trail verification", "2", "Week 4"],
      [{ text: "", bold: true }, "", { text: "Phase 4 Total", bold: true }, { text: "10", bold: true }, ""]
    ],
    [1600, 1100, 3300, 1180, 1180]
  ));
  content.push(spacer());

  // Phase 5
  content.push(heading2("Phase 5: Testing, Validation & Go-Live"));
  content.push(heading3("4.5.1 Description"));
  content.push(p("End-to-end testing of all firewall functions including traffic inspection, IPS detection, VPN connectivity, application filtering, and centralized logging. Coordinated production cutover with minimal disruption to Client operations."));
  content.push(spacer());
  content.push(heading3("4.5.2 Deliverables"));
  content.push(bullet("Functional test results for all security features"));
  content.push(bullet("VPN connectivity validation from remote locations"));
  content.push(bullet("Compliance evidence package (firewall rule export, IPS configuration, logging screenshots)"));
  content.push(bullet("Production cutover completed"));
  content.push(bullet("Post-cutover monitoring (first 48 hours)"));
  content.push(spacer());
  content.push(heading3("4.5.3 Schedule"));
  content.push(makeTable(
    ["Role", "Resource", "Description", "Est. Hours", "Timeline"],
    [
      ["Sr. Engineer", "US", "Production cutover and post-cutover monitoring", "3", "Week 5"],
      ["Sr. Engineer", "US", "End-to-end security feature testing", "1", "Week 4-5"],
      ["Engineer", "Offshore", "Functional testing and VPN validation", "2", "Week 4-5"],
      ["Engineer", "Offshore", "Compliance evidence package assembly", "2", "Week 5"],
      [{ text: "", bold: true }, "", { text: "Phase 5 Total", bold: true }, { text: "8", bold: true }, ""]
    ],
    [1600, 1100, 3300, 1180, 1180]
  ));
  content.push(brandRule());

  // ---- 5. EQUIPMENT AND SUBSCRIPTIONS ----
  content.push(heading1("5. EQUIPMENT AND SUBSCRIPTIONS"));
  content.push(p("Technijian will supply all hardware, hypervisor software, and firewall licensing required for this deployment as a fully managed solution. All pricing is sourced from the Technijian Managed Services Price List effective March 23, 2026."));
  content.push(spacer());

  content.push(heading2("5.1 Technijian-Supplied Equipment & Software"));
  content.push(makeTable(
    ["Item", "Description"],
    [
      ["Edge Appliance 16GB", "Dedicated hardware appliance (16 GB RAM) supplied by Technijian for on-premises installation at Client\u2019s primary location"],
      ["VMware ESXi", "Hypervisor installed and configured on the Edge Appliance to host virtual workloads"],
      ["Sophos SF V-2C4", "Virtual firewall appliance (2 vCPU, 4 GB RAM) deployed as a VM on ESXi with Xstream Protection Bundle"]
    ],
    [2800, 6560]
  ));
  content.push(spacer());

  content.push(heading2("5.2 Subscription Services (Annual)"));
  content.push(makeTable(
    ["Item", "Description", "Code", "License", "Annual Price"],
    [
      ["Sophos SF V-2C4", "Virtual Firewall with Xstream Protection Bundle (Up to 300 Mbps)", "SO-2C4G", "Yearly", "$350.00"],
      ["Edge Appliance 16GB", "Managed edge appliance with ESXi hypervisor", "Edge-16M", "Yearly", "$100.00"],
      [{ text: "", bold: true }, { text: "", bold: true }, "", { text: "Sub-Total:", bold: true }, { text: "$450.00", bold: true }]
    ],
    [1800, 3200, 1200, 1200, 1960]
  ));
  content.push(spacer());

  content.push(heading2("5.3 Monthly Equivalent"));
  content.push(makeTable(
    ["Item", "Annual", "Monthly Equivalent"],
    [
      ["Sophos SF V-2C4", "$350.00", "$29.17"],
      ["Edge Appliance 16GB", "$100.00", "$8.33"],
      [{ text: "Total", bold: true }, { text: "$450.00", bold: true }, { text: "$37.50", bold: true }]
    ],
    [3800, 2780, 2780]
  ));
  content.push(spacer());

  content.push(heading2("5.4 Title and Ownership"));
  content.push(p("The Edge Appliance 16GB hardware, VMware ESXi hypervisor license, and Sophos SF V-2C4 virtual appliance license are supplied by Technijian and shall remain the property of Technijian for the duration of the managed services engagement. Client is granted use of the equipment and software solely in connection with the services described in this SOW. Upon termination of the managed services engagement, Technijian shall retrieve the Edge Appliance hardware and deactivate associated licenses."));
  content.push(brandRule());

  // ---- 6. PRICING AND PAYMENT ----
  content.push(heading1("6. PRICING AND PAYMENT"));

  content.push(heading2("6.1 Rate Card"));
  content.push(makeTable(
    ["Resource Tier", "Description", "Hourly Rate"],
    [
      ["Sr. Engineer (US)", "On-shore senior technical resource \u2014 architecture, deployment, cutover, policy design", "$150.00"],
      ["Engineer (Offshore)", "Off-shore technical resource \u2014 configuration, documentation, testing, evidence assembly", "$45.00"]
    ],
    [2800, 4560, 2000]
  ));
  content.push(spacer());

  content.push(heading2("6.2 Labor Summary"));
  content.push(makeTable(
    ["Phase", "Description", "US Hrs", "Offshore Hrs", "US Cost", "Offshore Cost", "Phase Total"],
    [
      ["Phase 1", "Discovery & Assessment", "3", "2", "$450.00", "$90.00", "$540.00"],
      ["Phase 2", "ESXi & Firewall Deployment", "3", "2", "$450.00", "$90.00", "$540.00"],
      ["Phase 3", "Edge Appliance Install & Integration", "4", "0", "$600.00", "$0.00", "$600.00"],
      ["Phase 4", "Security Policy & Compliance Config", "6", "4", "$900.00", "$180.00", "$1,080.00"],
      ["Phase 5", "Testing, Validation & Go-Live", "4", "4", "$600.00", "$180.00", "$780.00"],
      [{ text: "Total", bold: true }, "", { text: "20", bold: true }, { text: "12", bold: true }, { text: "$3,000.00", bold: true }, { text: "$540.00", bold: true }, { text: "$3,540.00", bold: true }]
    ],
    [1000, 2100, 900, 1100, 1100, 1200, 960]
  ));
  content.push(spacer());

  content.push(heading2("6.3 Total Project Cost Summary"));
  content.push(makeTable(
    ["Category", "Type", "Cost"],
    [
      ["Labor \u2014 US (20 hrs @ $150/hr)", "One-Time Fixed", "$3,000.00"],
      ["Labor \u2014 Offshore (12 hrs @ $45/hr)", "One-Time Fixed", "$540.00"],
      ["Sophos SF V-2C4 (Year 1)", "Annual Subscription", "$350.00"],
      ["Edge Appliance 16GB (Year 1)", "Annual Subscription", "$100.00"],
      [{ text: "Total Year 1 Investment", bold: true }, "", { text: "$3,990.00", bold: true }],
      ["", "", ""],
      [{ text: "Annual Recurring (Year 2+)", bold: true }, { text: "Annual Subscription", bold: true }, { text: "$450.00", bold: true }]
    ],
    [4000, 2680, 2680]
  ));
  content.push(spacer());

  content.push(heading2("6.4 Payment Schedule"));
  content.push(makeTable(
    ["Milestone", "Invoiced", "Amount"],
    [
      ["Upon SOW Execution", "Before Phase 1 begins", "$1,770.00"],
      ["Completion of Phase 4", "After security policy configuration", "$1,770.00"],
      ["Annual Subscriptions", "Upon license activation", "$450.00"],
      [{ text: "Total", bold: true }, "", { text: "$3,990.00", bold: true }]
    ],
    [3200, 3080, 3080]
  ));
  content.push(spacer());

  content.push(heading2("6.5 Payment Terms"));
  content.push(p("All invoices are due and payable within thirty (30) days of the invoice date. Late payments are subject to a late fee of 1.5% per month on the unpaid balance."));
  content.push(brandRule());

  // ---- 7. CLIENT RESPONSIBILITIES ----
  content.push(heading1("7. CLIENT RESPONSIBILITIES"));
  content.push(p("Client shall:"));
  content.push(spacer());
  content.push(p("(a) Provide physical site access, power, and network connectivity for the Technijian-supplied Edge Appliance at the designated location;", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(b) Designate a point of contact authorized to approve firewall policy decisions, VPN access requests, and network changes;", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(c) Provide current network topology documentation or allow Technijian to perform discovery;", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(d) Review and approve the firewall policy design document within five (5) business days of submission;", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(e) Ensure all relevant data is backed up prior to the start of network cutover;", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(f) Inform users of planned maintenance windows and potential connectivity disruptions during deployment; and", { indent: { left: 360 } }));
  content.push(spacer());
  content.push(p("(g) Provide rack space or suitable mounting location for the Edge Appliance with adequate ventilation and power.", { indent: { left: 360 } }));
  content.push(brandRule());

  // ---- 8. CHANGE MANAGEMENT ----
  content.push(heading1("8. CHANGE MANAGEMENT"));
  content.push(p("8.01. Any changes to the scope, schedule, or pricing of this SOW must be documented in a written Change Order signed by both Parties before work on the change begins."));
  content.push(spacer());
  content.push(p("8.02. If Client requests work outside the defined scope, Technijian shall provide a Change Order detailing the additional work, estimated hours, and cost impact."));
  content.push(spacer());
  content.push(p("8.03. Technijian shall not proceed with out-of-scope work without an approved Change Order, except in cases where delay would result in harm to Client\u2019s systems, in which case Technijian shall notify Client as soon as practicable."));
  content.push(brandRule());

  // ---- 9. ACCEPTANCE ----
  content.push(heading1("9. ACCEPTANCE"));
  content.push(p("9.01. Upon completion of each phase, Technijian shall notify Client in writing that the deliverables are ready for review."));
  content.push(spacer());
  content.push(p("9.02. Client shall review the deliverables and provide written acceptance or a detailed description of deficiencies within five (5) business days."));
  content.push(spacer());
  content.push(p("9.03. If Client does not respond within the review period, the deliverables shall be deemed accepted."));
  content.push(spacer());
  content.push(p("9.04. If deficiencies are identified, Technijian shall correct them and resubmit for review. This process shall repeat until acceptance is achieved or the Parties agree on a resolution."));
  content.push(brandRule());

  // ---- 10. GOVERNING TERMS ----
  content.push(heading1("10. GOVERNING TERMS"));
  content.push(p("10.01. If a Master Service Agreement is in effect between the Parties, the terms of the MSA shall govern this SOW. In the event of a conflict between this SOW and the MSA, the MSA shall prevail unless this SOW expressly states otherwise."));
  content.push(spacer());
  content.push(p("10.02. If no MSA is in effect, the Technijian Standard Terms and Conditions (attached as Appendix A) shall govern this SOW."));
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
          "Statement of Work",
          "Sophos SF V-2C4 Virtual Firewall & Edge Appliance Deployment \u2014 American Fundstars Financial Group LLC"
        )
      },
      {
        properties: contentSectionProps(),
        children: content
      }
    ]
  });

  const buffer = await Packer.toBuffer(doc);
  const outputPath = path.join(__dirname, "..", "03_SOW", "SOW-AFFG-001-Firewall.docx");
  fs.writeFileSync(outputPath, buffer);
  console.log("Generated:", outputPath);
}

generateSOW().catch(err => {
  console.error("Error generating SOW:", err);
  process.exit(1);
});
