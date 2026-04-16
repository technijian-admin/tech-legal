/**
 * Brandywine Homes (BWH) — Executive Summary Generator
 * MSA Migration — Managed IT Services, Cybersecurity & Virtual Staff
 * Uses brand-helpers.js shared formatting system
 * Replaces generate-summary.py
 */
const { Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
        ImageRun, AlignmentType, LevelFormat,
        BorderStyle, WidthType, ShadingType, PageBreak } = require('docx');
const fs = require('fs');
const path = require('path');
const helpers = require('../../scripts/brand-helpers');

const {
  CORE_BLUE, CORE_ORANGE, DARK_CHARCOAL, BRAND_GREY, OFF_WHITE, WHITE, LIGHT_GREY, TEAL,
  noBorders, borders, cellMargins,
  colorBanner, accentBar, sectionHeader, numberedSectionHeader,
  bodyText, subsectionHeading, orangeDivider, coverPage,
  brandedHeader, brandedFooter, importantCallout, statusTable, ctaBanner
} = helpers;

const logoPath = path.resolve(__dirname, 'technijian-logo.png');
const logoData = fs.readFileSync(logoPath);

// ── BWH Client Data ──
const CLIENT_NAME = "Brandywine Homes";
const CLIENT_SHORT = "BWH";
const EFFECTIVE_DATE = "May 1, 2026";

// ── Reusable helpers (same as build-msa.js) ──
function numbered(num, text, indent) {
  const prefix = indent ? "    ".repeat(indent) : "";
  return new Paragraph({
    spacing: { after: 60 },
    indent: indent ? { left: indent * 720 } : undefined,
    children: [
      new TextRun({ text: `${prefix}${num} `, font: "Open Sans", size: 22, bold: true, color: CORE_BLUE }),
      new TextRun({ text, font: "Open Sans", size: 22, color: BRAND_GREY }),
    ]
  });
}

function bodyBoldPrefix(boldText, text) {
  return new Paragraph({
    spacing: { after: 60 },
    children: [
      new TextRun({ text: boldText, font: "Open Sans", size: 20, bold: true, color: DARK_CHARCOAL }),
      new TextRun({ text, font: "Open Sans", size: 20, color: BRAND_GREY }),
    ]
  });
}

function bullet(text) {
  return new Paragraph({
    spacing: { after: 40 },
    indent: { left: 720, hanging: 360 },
    children: [
      new TextRun({ text: "\u2022  ", font: "Open Sans", size: 22, color: CORE_BLUE }),
      new TextRun({ text, font: "Open Sans", size: 22, color: BRAND_GREY }),
    ]
  });
}

function bulletBoldPrefix(boldText, text) {
  return new Paragraph({
    spacing: { after: 40 },
    indent: { left: 720, hanging: 360 },
    children: [
      new TextRun({ text: "\u2022  ", font: "Open Sans", size: 22, color: CORE_BLUE }),
      new TextRun({ text: boldText, font: "Open Sans", size: 20, bold: true, color: DARK_CHARCOAL }),
      new TextRun({ text, font: "Open Sans", size: 20, color: BRAND_GREY }),
    ]
  });
}

function styledTable(headers, rows, totalIndices, colWidths) {
  totalIndices = totalIndices || [];
  const defaultColWidth = Math.floor(9360 / headers.length);
  const widths = colWidths || headers.map(() => defaultColWidth);
  return new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: widths,
    rows: [
      new TableRow({
        children: headers.map((h, i) => new TableCell({
          borders, width: { size: widths[i], type: WidthType.DXA }, margins: cellMargins,
          shading: { fill: CORE_BLUE, type: ShadingType.CLEAR },
          children: [new Paragraph({
            children: [new TextRun({ text: h, font: "Open Sans", size: 20, bold: true, color: WHITE })]
          })]
        }))
      }),
      ...rows.map((row, ri) => new TableRow({
        children: row.map((val, ci) => {
          const isTotal = totalIndices.includes(ri);
          return new TableCell({
            borders, width: { size: widths[ci], type: WidthType.DXA }, margins: cellMargins,
            shading: { fill: isTotal ? OFF_WHITE : (ri % 2 === 0 ? WHITE : OFF_WHITE), type: ShadingType.CLEAR },
            children: [new Paragraph({
              children: [new TextRun({
                text: String(val), font: "Open Sans", size: 20,
                bold: isTotal, color: isTotal ? DARK_CHARCOAL : BRAND_GREY
              })]
            })]
          });
        })
      }))
    ]
  });
}

function greenTable(headers, rows, totalIndices, colWidths) {
  totalIndices = totalIndices || [];
  const defaultColWidth = Math.floor(9360 / headers.length);
  const widths = colWidths || headers.map(() => defaultColWidth);
  const GREEN = "28A745";
  return new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: widths,
    rows: [
      new TableRow({
        children: headers.map((h, i) => new TableCell({
          borders, width: { size: widths[i], type: WidthType.DXA }, margins: cellMargins,
          shading: { fill: GREEN, type: ShadingType.CLEAR },
          children: [new Paragraph({
            children: [new TextRun({ text: h, font: "Open Sans", size: 20, bold: true, color: WHITE })]
          })]
        }))
      }),
      ...rows.map((row, ri) => new TableRow({
        children: row.map((val, ci) => {
          const isTotal = totalIndices.includes(ri);
          return new TableCell({
            borders, width: { size: widths[ci], type: WidthType.DXA }, margins: cellMargins,
            shading: { fill: isTotal ? OFF_WHITE : (ri % 2 === 0 ? WHITE : OFF_WHITE), type: ShadingType.CLEAR },
            children: [new Paragraph({
              children: [new TextRun({
                text: String(val), font: "Open Sans", size: 20,
                bold: isTotal, color: isTotal ? DARK_CHARCOAL : BRAND_GREY
              })]
            })]
          });
        })
      }))
    ]
  });
}

function spacer(pts) {
  return new Paragraph({ spacing: { before: pts || 200 }, children: [] });
}

// ════════════════════════════════════════════════════════════════════
//  BUILD DOCUMENT
// ════════════════════════════════════════════════════════════════════

const doc = new Document({
  styles: {
    default: { document: { run: { font: "Open Sans", size: 22, color: BRAND_GREY } } },
    paragraphStyles: [
      { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 28, bold: true, font: "Open Sans", color: CORE_BLUE },
        paragraph: { spacing: { before: 360, after: 160 }, outlineLevel: 0 } },
    ]
  },
  sections: [
    // ══════════════════════════════════════════════════════════════
    //  PAGE 1: COVER PAGE
    // ══════════════════════════════════════════════════════════════
    {
      properties: {
        page: {
          size: { width: 12240, height: 15840 },
          margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 }
        }
      },
      children: [
        ...coverPage(
          logoData,
          "Executive Summary",
          "MSA Migration \u2014 Managed IT Services, Cybersecurity & Virtual Staff\nPrepared for Brandywine Homes",
          "May 2026"
        ),
      ]
    },

    // ══════════════════════════════════════════════════════════════
    //  PAGE 2: MIGRATION OVERVIEW
    // ══════════════════════════════════════════════════════════════
    {
      properties: {
        page: {
          size: { width: 12240, height: 15840 },
          margin: { top: 1800, right: 1440, bottom: 1440, left: 1440 }
        }
      },
      headers: { default: brandedHeader(logoData) },
      footers: { default: brandedFooter() },
      children: [
        colorBanner("MIGRATION OVERVIEW", CORE_BLUE, WHITE, 28),
        spacer(100),
        bodyText(
          `Technijian is pleased to present this proposal to migrate ${CLIENT_NAME} from the existing ` +
          "Terms & Conditions (T&C) agreement to a new Master Service Agreement (MSA). This migration " +
          "formalizes the service relationship under a comprehensive legal framework while delivering " +
          "immediate cost savings through service optimization and rate consolidation."
        ),
        spacer(60),
        bodyText(
          `As an existing Technijian client, ${CLIENT_NAME} has been receiving managed IT services, ` +
          "cybersecurity, and virtual staff support under the legacy T&C structure. The new MSA provides " +
          "enhanced protections for both parties, clearer service definitions, structured billing with " +
          "full transparency, and negotiated rates that reflect the strength of this ongoing partnership."
        ),
        spacer(100),
        sectionHeader("Key Changes in This Migration"),
        spacer(60),
        bulletBoldPrefix("Endpoint Optimization: ", "Desktop count reduced from 41 to 32 (decommissioned/consolidated endpoints)"),
        bulletBoldPrefix("Service Streamlining: ", "Network Assessment service consolidated into the existing Site Assessment coverage"),
        bulletBoldPrefix("Rate Reduction: ", "15% reduction across all Virtual Staff roles, effective immediately under the new MSA"),
        bulletBoldPrefix("Backup Storage Optimization: ", "Quota right-sized from 24 TB to 13 TB with deduplication enabled to keep storage usage down"),
        bulletBoldPrefix("Invoice Consolidation: ", "Two separate invoices (monthly + recurring) consolidated into single monthly MSA invoice"),
        bulletBoldPrefix("Veeam 365 Consolidated: ", "Veeam 365 backup consolidated to 110 users under the new MSA"),
        bulletBoldPrefix("Firewall Clarification: ", "1 Sophos Firewall (2C-4G) \u2014 confirmed single unit"),

        // ══════════════════════════════════════════════════════════════
        //  PAGE 3: CURRENT ENVIRONMENT + APRIL vs MAY
        // ══════════════════════════════════════════════════════════════
        new Paragraph({ children: [new PageBreak()] }),

        colorBanner("CURRENT ENVIRONMENT & COST COMPARISON", CORE_BLUE, WHITE, 28),
        spacer(100),
        sectionHeader("Current Environment"),
        spacer(60),
        styledTable(
          ["Category", "Details"],
          [
            ["Managed Desktops", "32 (reduced from 41)"],
            ["Managed Servers", "12"],
            ["Firewalls", "1 (Sophos 2C-4G)"],
            ["Switches", "3"],
            ["Access Points", "6"],
            ["Email Users", "83 (Anti-Spam) / 85 (Phishing Training) / 110 (Veeam 365)"],
            ["Backup Storage", "13 TB"],
            ["Cloud VMs", "11"],
            ["Disks", "2"],
            ["Static IPs", "6"],
            ["Edge Appliance", "1 (16GB / 8 cores / 512GB)"],
            ["My Disk", "1"],
          ],
          [],
          [3120, 6240]
        ),

        spacer(200),
        sectionHeader("April 2026 vs May 2026 \u2014 Cost Comparison"),
        spacer(60),
        bodyText(
          "The table below shows a side-by-side comparison of the current April 2026 combined invoices " +
          "(old T&C) versus the proposed May 2026 consolidated invoice (new MSA). All figures are monthly costs."
        ),
        spacer(60),
        bodyBoldPrefix("April (Old T&C \u2014 Combined): ", "Monthly Invoice #28148: $9,041.05 + Recurring Invoice #28116: $1,234.70 = $10,275.75"),
        spacer(60),
        greenTable(
          ["Category", "April (Combined)", "May (Proposed)", "Savings", "Change"],
          [
            ["Online Services", "$10,275.75", "$4,045.25", "", "Consolidated"],
            ["Schedule B Subscriptions", "", "$7.20", "", "Entra ID P1"],
            ["Virtual Staff", "(incl. above)", "$4,304.44", "", "15% rate reduction"],
            ["TOTAL", "$10,275.75", "$8,356.89", "$1,918.86", "18.7% savings"],
          ],
          [3],
          [1872, 1872, 1872, 1872, 1872]
        ),

        // ══════════════════════════════════════════════════════════════
        //  PAGE 4: DETAILED CHANGE BREAKDOWN
        // ══════════════════════════════════════════════════════════════
        new Paragraph({ children: [new PageBreak()] }),

        colorBanner("DETAILED CHANGE BREAKDOWN", CORE_BLUE, WHITE, 28),
        spacer(100),
        sectionHeader("What Changed \u2014 Detail"),
        spacer(60),

        numbered("1.", "Desktop Reduction (41 to 32):"),
        bodyText(
          "9 desktops decommissioned or consolidated. This reduces costs across 6 per-desktop services: " +
          "Patch Management, My Secure Internet, My Remote, My Ops-Net, AVH Protection, and AV Protection. " +
          "Savings: $267.75/mo."
        ),

        spacer(100),
        numbered("2.", "Network Assessment Consolidated:"),
        bodyText(
          "The Network Assessment service has been consolidated into the " +
          "Site Assessment already included in the service stack. " +
          "Savings: $78.00/mo."
        ),

        spacer(100),
        numbered("3.", "Virtual Staff Rate Reduction (15%):"),
        bodyText(
          "All Virtual Staff roles receive a 15% rate discount under the new MSA, recognizing the " +
          "long-term partnership."
        ),
        spacer(60),
        styledTable(
          ["Role", "Old Rate", "New Rate", "Discount"],
          [
            ["Systems Architect (US)", "$200.00/hr", "$170.00/hr", "15%"],
            ["USA Tech Normal", "$125.00/hr", "$106.25/hr", "15%"],
            ["India Tech Normal", "$15.00/hr", "$12.75/hr", "15%"],
            ["India Tech After Hours", "$30.00/hr", "$25.50/hr", "15%"],
          ],
          [],
          [3120, 2080, 2080, 2080]
        ),
        spacer(60),
        bodyText("Combined Virtual Staff savings: $759.61/mo."),

        // ══════════════════════════════════════════════════════════════
        //  PAGE 5: SERVICE DETAIL TABLES — DESKTOP + SERVER
        // ══════════════════════════════════════════════════════════════
        new Paragraph({ children: [new PageBreak()] }),

        colorBanner("SERVICE DETAIL \u2014 INFRASTRUCTURE", CORE_BLUE, WHITE, 28),
        spacer(100),
        sectionHeader("Desktop Services (32 units)"),
        spacer(60),
        styledTable(
          ["Service", "Qty", "Unit Price", "Monthly"],
          [
            ["Patch Management", "32", "$4.00", "$128.00"],
            ["My Secure Internet", "32", "$6.00", "$192.00"],
            ["My Remote", "32", "$2.00", "$64.00"],
            ["My Ops - Net", "32", "$3.25", "$104.00"],
            ["AVH Protection - Desktop", "32", "$6.00", "$192.00"],
            ["AV Protection - Desktop", "32", "$8.50", "$272.00"],
            ["SUBTOTAL \u2014 DESKTOP", "", "", "$952.00"],
          ],
          [6],
          [4000, 1200, 1800, 2360]
        ),

        spacer(200),
        sectionHeader("Server Services (12 units)"),
        spacer(60),
        styledTable(
          ["Service", "Qty", "Unit Price", "Monthly"],
          [
            ["Patch Management", "12", "$4.00", "$48.00"],
            ["My Secure Internet", "12", "$6.00", "$72.00"],
            ["My Remote", "12", "$2.00", "$24.00"],
            ["My Ops - Net", "12", "$3.25", "$39.00"],
            ["Image Backup", "12", "$15.00", "$180.00"],
            ["AVH Protection - Server", "12", "$6.00", "$72.00"],
            ["AV Protection - Server", "12", "$10.50", "$126.00"],
            ["SUBTOTAL \u2014 SERVER", "", "", "$561.00"],
          ],
          [7],
          [4000, 1200, 1800, 2360]
        ),

        // ══════════════════════════════════════════════════════════════
        //  PAGE 6: OTHER INFRASTRUCTURE + EMAIL
        // ══════════════════════════════════════════════════════════════
        new Paragraph({ children: [new PageBreak()] }),

        colorBanner("SERVICE DETAIL \u2014 CLOUD, NETWORK & EMAIL", CORE_BLUE, WHITE, 28),
        spacer(100),
        sectionHeader("Cloud Infrastructure"),
        spacer(60),
        styledTable(
          ["Service", "Qty", "Unit Price", "Monthly"],
          [
            ["Backup Storage (TB)", "13", "$50.00", "$650.00"],
            ["Veeam One", "11", "$3.00", "$33.00"],
            ["SUBTOTAL \u2014 CLOUD", "", "", "$683.00"],
          ],
          [2],
          [4000, 1200, 1800, 2360]
        ),

        spacer(200),
        sectionHeader("Network & Security"),
        spacer(60),
        styledTable(
          ["Service", "Qty", "Unit Price", "Monthly"],
          [
            ["My Ops - Config (Switches)", "3", "$6.00", "$18.00"],
            ["Real Time Pen Testing", "6", "$7.00", "$42.00"],
            ["My Ops - Traffic (Firewalls)", "1", "$14.00", "$14.00"],
            ["My Ops - Storage (Disks)", "2", "$4.75", "$9.50"],
            ["My Ops - Wifi (APs)", "6", "$1.00", "$6.00"],
            ["Sophos Firewall Subscription 2C-4G", "1", "$270.00", "$270.00"],
            ["MPC Edge Appliance (16GB/8 cores/512GB)", "1", "$100.00", "$100.00"],
            ["SUBTOTAL \u2014 NETWORK", "", "", "$459.50"],
          ],
          [7],
          [4000, 1200, 1800, 2360]
        ),

        spacer(200),
        sectionHeader("Email & User Services"),
        spacer(60),
        styledTable(
          ["Service", "Qty", "Unit Price", "Monthly"],
          [
            ["Site Assessment", "1", "$50.00", "$50.00"],
            ["DMARC/DKIM", "1", "$20.00", "$20.00"],
            ["Anti-Spam Standard", "83", "$6.25", "$518.75"],
            ["Phishing Training", "85", "$6.00", "$510.00"],
            ["Veeam 365", "110", "$2.50", "$275.00"],
            ["My Disk", "1", "$16.00", "$16.00"],
            ["SUBTOTAL \u2014 EMAIL & USERS", "", "", "$1,389.75"],
          ],
          [6],
          [4000, 1200, 1800, 2360]
        ),

        spacer(100),
        styledTable(
          ["", "Monthly"],
          [
            ["TOTAL ONLINE SERVICES", "$4,045.25"],
          ],
          [0],
          [6240, 3120]
        ),

        // ══════════════════════════════════════════════════════════════
        //  PAGE 7: VIRTUAL STAFF
        // ══════════════════════════════════════════════════════════════
        new Paragraph({ children: [new PageBreak()] }),

        colorBanner("VIRTUAL STAFF \u2014 CONTRACTED SUPPORT", CORE_BLUE, WHITE, 28),
        spacer(100),
        sectionHeader("Virtual Staff Rate Comparison"),
        spacer(60),
        bodyText(
          "All Virtual Staff roles receive a 15% rate reduction under the new MSA. " +
          "Hours remain based on current utilization. Virtual Staff services are billed on a " +
          "12-month billing cycle with weekly tracking invoices for full transparency."
        ),
        spacer(60),
        styledTable(
          ["Role", "Hours/Mo", "Old Rate", "New Rate", "Monthly"],
          [
            ["Systems Architect (US)", "5.00", "$200.00/hr", "$170.00/hr", "$850.00"],
            ["USA Tech Normal", "15.26", "$125.00/hr", "$106.25/hr", "$1,621.38"],
            ["India Tech Normal", "58.13", "$15.00/hr", "$12.75/hr", "$741.16"],
            ["India Tech After Hours", "42.82", "$30.00/hr", "$25.50/hr", "$1,091.91"],
            ["SUBTOTAL \u2014 VIRTUAL STAFF", "121.21", "", "", "$4,304.44"],
          ],
          [4],
          [2340, 1400, 1640, 1640, 2340]
        ),

        spacer(100),
        sectionHeader("Billing Model"),
        spacer(60),
        bodyBoldPrefix("12-Month Cycle-Based Billing: ",
          "Initial cycle based on estimated hours per the Service Order. Actual usage tracked from " +
          "day one with weekly in-contract invoices showing ticket-level detail. Reconciliation occurs " +
          "at the end of each 12-month cycle."
        ),
        spacer(60),
        bodyBoldPrefix("15% Discount Applied: ",
          "All Virtual Staff rates reflect a 15% discount from standard Schedule C rates, " +
          "recognizing the long-term partnership between Technijian and Brandywine Homes."
        ),

        // ══════════════════════════════════════════════════════════════
        //  PAGE 8: UNPAID HOURS RECOVERY PLAN
        // ══════════════════════════════════════════════════════════════
        new Paragraph({ children: [new PageBreak()] }),

        colorBanner("UNPAID HOURS RECOVERY PLAN", CORE_ORANGE, WHITE, 28),
        spacer(100),
        sectionHeader("Current Unpaid Balance"),
        spacer(60),
        bodyText(
          "The current under-contract period has accumulated unpaid hours (actual hours consumed " +
          "exceeding billed hours) across Virtual Staff roles. Under the new MSA, Technijian will " +
          "implement a structured recovery plan to reduce these balances over the 12-month billing cycle."
        ),
        spacer(60),
        styledTable(
          ["Role", "Unpaid Hours", "New Rate", "Value at New Rate"],
          [
            ["India Tech Normal", "573.81 hrs", "$12.75/hr", "$7,316.08"],
            ["India Tech After Hours", "290.23 hrs", "$25.50/hr", "$7,400.87"],
            ["USA Tech Normal", "143.26 hrs", "$106.25/hr", "$15,221.38"],
            ["Systems Architect (US)", "0.00 hrs", "$170.00/hr", "$0.00"],
            ["TOTAL UNPAID BALANCE", "1,007.30 hrs", "", "$29,938.33"],
          ],
          [4],
          [2800, 2000, 2000, 2560]
        ),

        spacer(100),
        sectionHeader("Recovery Strategy"),
        spacer(60),
        bodyBoldPrefix("Target: ",
          "Technijian will target utilizing approximately 20% fewer hours than billed each month. " +
          "This means actual work will be managed to stay below the monthly billed amount, allowing " +
          "the unpaid balance to decrease each month."
        ),
        spacer(60),
        bodyBoldPrefix("How It Works: ",
          "Each month, BWH is billed a fixed amount based on the 12-month cycle average. " +
          "If Technijian uses fewer hours than billed (targeting 20% under), the running balance " +
          "decreases. Weekly in-contract invoices will show the current balance so both parties " +
          "can track progress."
        ),
        spacer(60),
        bodyBoldPrefix("12-Month Cycle Rationale: ",
          "The current 12-month billing cycle is maintained specifically to provide a longer " +
          "runway for the unpaid hours to come down. A shorter cycle would require immediate " +
          "reconciliation of the balance, whereas the 12-month cycle allows gradual recovery " +
          "while maintaining consistent monthly billing for BWH."
        ),

        spacer(100),
        sectionHeader("Projected Recovery (20% Under Target)"),
        spacer(60),
        styledTable(
          ["Role", "Billed/Mo", "Target (80%)", "Monthly Paydown", "12-Mo Paydown"],
          [
            ["India Tech Normal", "58.13 hrs", "46.50 hrs", "11.63 hrs", "139.56 hrs"],
            ["India Tech After Hours", "42.82 hrs", "34.26 hrs", "8.56 hrs", "102.72 hrs"],
            ["USA Tech Normal", "15.26 hrs", "12.21 hrs", "3.05 hrs", "36.60 hrs"],
            ["TOTAL MONTHLY PAYDOWN", "116.21 hrs", "92.97 hrs", "23.24 hrs", "278.88 hrs"],
          ],
          [3],
          [2340, 1560, 1560, 1900, 2000]
        ),

        spacer(60),
        importantCallout(
          "At the 20% under-utilization target, approximately 278.88 unpaid hours will be recovered " +
          "over the 12-month cycle, reducing the balance from 1,007.30 hours to approximately 728.42 hours. " +
          "Technijian commits to transparency through weekly invoices showing the current running balance " +
          "for each role."
        ),

        // ══════════════════════════════════════════════════════════════
        //  PAGE 9: TOTAL MONTHLY INVESTMENT SUMMARY
        // ══════════════════════════════════════════════════════════════
        new Paragraph({ children: [new PageBreak()] }),

        colorBanner("TOTAL MONTHLY INVESTMENT SUMMARY", CORE_BLUE, WHITE, 28),
        spacer(100),
        sectionHeader("May 2026 \u2014 Consolidated Monthly Cost"),
        spacer(60),
        styledTable(
          ["Category", "Monthly"],
          [
            ["Online Services", "$4,045.25"],
            ["Schedule B Subscriptions", "$7.20"],
            ["Virtual Staff Support", "$4,304.44"],
            ["TOTAL MONTHLY (NEW MSA)", "$8,356.89"],
            ["", ""],
            ["Previous Combined (Old T&C)", "$10,275.75"],
            ["MONTHLY SAVINGS", "$1,918.86 (18.7%)"],
          ],
          [3, 6],
          [6240, 3120]
        ),

        spacer(200),
        importantCallout(
          "Your new consolidated monthly investment is $8,356.89 \u2014 a savings of $1,918.86 per month (18.7%) " +
          "compared to your current combined April invoices of $10,275.75. All services are now under a single " +
          "monthly MSA invoice with full transparency."
        ),

        // ══════════════════════════════════════════════════════════════
        //  PAGE 10: RATE CARD + SLA + AGREEMENT + NEXT STEPS
        // ══════════════════════════════════════════════════════════════
        new Paragraph({ children: [new PageBreak()] }),

        colorBanner("RATE CARD, SLA & NEXT STEPS", CORE_BLUE, WHITE, 28),
        spacer(100),
        sectionHeader("BWH Contracted Rate Card (15% Discount)"),
        spacer(60),

        // US Staff
        subsectionHeading("", "United States \u2014 Based Staff"),
        spacer(40),
        styledTable(
          ["Role", "Standard Rate", "After-Hours", "BWH Contracted"],
          [
            ["Systems Architect", "$250/hr", "$350/hr", "$170.00/hr"],
            ["CTO Advisory", "$250/hr", "$350/hr", "$225/hr"],
            ["Developer", "$150/hr", "N/A", "$125/hr"],
            ["Tech Support", "$150/hr", "$250/hr", "$106.25/hr"],
          ],
          [],
          [2800, 2000, 2000, 2560]
        ),

        spacer(100),
        // Offshore Staff
        subsectionHeading("", "Offshore \u2014 Based Staff"),
        spacer(40),
        styledTable(
          ["Role", "Standard Rate", "After-Hours", "BWH Contracted"],
          [
            ["Developer", "$45/hr", "N/A", "$30/hr"],
            ["SEO Specialist", "$45/hr", "N/A", "$30/hr"],
            ["Tech Support (Normal)", "$15/hr", "$30/hr", "$12.75/hr"],
            ["Tech Support (After Hrs)", "$30/hr", "N/A", "$25.50/hr"],
          ],
          [],
          [2800, 2000, 2000, 2560]
        ),

        spacer(100),
        // Project Rates
        subsectionHeading("", "Project & Ad Hoc Rates"),
        spacer(40),
        styledTable(
          ["Service", "Rate", "Minimum", "Notes"],
          [
            ["On-Site Support (US)", "$150/hr", "2-hour minimum", "No trip charges"],
            ["Remote Support (ad hoc)", "$150/hr", "15-min increments", "Non-contracted work"],
            ["Emergency / Critical", "$250/hr", "1-hour minimum", "After-hours / critical incidents"],
            ["Project Management", "$150/hr", "N/A", "For SOW-based engagements"],
          ],
          [],
          [2400, 1400, 2200, 3360]
        ),

        spacer(200),
        sectionHeader("Service Level Commitments"),
        spacer(60),
        styledTable(
          ["Service Level", "Target"],
          [
            ["Infrastructure Uptime", "99.9% for monitored services"],
            ["Critical Incident Response", "Within 1 hour of notification"],
            ["Standard Support Response", "Within 4 business hours"],
            ["Scheduled Maintenance", "Tuesday evenings and Saturdays (with advance notice)"],
            ["24/7 Monitoring", "All desktops, servers, and email security continuously monitored"],
            ["Monthly Reporting", "Service reports summarizing incidents, uptime, and support activity"],
            ["Quarterly Reviews", `Scheduled service reviews with ${CLIENT_NAME}\u2019s designated representative`],
          ],
          [],
          [3120, 6240]
        ),

        spacer(200),
        sectionHeader("Agreement Structure"),
        spacer(60),
        bulletBoldPrefix("Master Service Agreement (MSA): ",
          "Governs the overall relationship, payment terms, confidentiality, liability, and dispute " +
          "resolution for a 12-month initial term with automatic annual renewal. Replaces the existing T&C."
        ),
        bulletBoldPrefix("Schedule A \u2014 Monthly Services: ",
          "Details the managed desktop security, server management, email security, monitoring, " +
          "and virtual staff services with SLA commitments."
        ),
        bulletBoldPrefix("Schedule B \u2014 Subscription Services: ",
          `Covers any third-party software subscriptions and licenses managed by Technijian on ` +
          `${CLIENT_NAME}\u2019s behalf.`
        ),
        bulletBoldPrefix("Schedule C \u2014 Rate Card: ",
          "Establishes hourly rates for all labor, including the BWH contracted rates with 15% discount, " +
          "on-site support, emergency response, and ad hoc services."
        ),

        spacer(200),
        sectionHeader("Next Steps"),
        spacer(60),
        numbered("1.", "Review this executive summary and the attached MSA"),
        numbered("2.", "Confirm any questions with your Technijian account representative"),
        numbered("3.", "Sign the MSA, Schedule A, Schedule B, and Schedule C"),
        numbered("4.", "New rates take effect May 1, 2026"),
        numbered("5.", "Weekly tracking invoices begin immediately under the new billing structure"),

        spacer(200),
        ctaBanner(),
      ]
    }
  ]
});

// ── Write output ──
const outPath = path.join(__dirname, '..', '02_MSA', 'BWH-Executive-Summary.docx');
Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync(outPath, buffer);
  console.log('Created: ' + outPath);
}).catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
