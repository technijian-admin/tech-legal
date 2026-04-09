/**
 * Brandywine Homes (BWH) — Schedule C: Rate Card
 * Output: BWH-Schedule-C-Rate-Card.docx
 * BWH CONTRACTED RATES ONLY — no full infrastructure price catalog.
 * Reference document (NOT signed)
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

const CLIENT_NAME = "Brandywine Homes";
const CLIENT_SHORT = "BWH";
const EFFECTIVE_DATE = "May 1, 2026";

// ── Reusable helpers ──
function bodyBoldPrefix(boldText, text) {
  return new Paragraph({
    spacing: { after: 60 },
    children: [
      new TextRun({ text: boldText, font: "Open Sans", size: 20, bold: true, color: DARK_CHARCOAL }),
      new TextRun({ text, font: "Open Sans", size: 20, color: BRAND_GREY }),
    ]
  });
}

function styledTable(headers, rows, totalIndices) {
  totalIndices = totalIndices || [];
  const colWidth = Math.floor(9360 / headers.length);
  return new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: headers.map(() => colWidth),
    rows: [
      new TableRow({
        children: headers.map(h => new TableCell({
          borders, width: { size: colWidth, type: WidthType.DXA }, margins: cellMargins,
          shading: { fill: CORE_BLUE, type: ShadingType.CLEAR },
          children: [new Paragraph({
            children: [new TextRun({ text: h, font: "Open Sans", size: 20, bold: true, color: WHITE })]
          })]
        }))
      }),
      ...rows.map((row, ri) => new TableRow({
        children: row.map(val => {
          const isTotal = totalIndices.includes(ri);
          return new TableCell({
            borders, width: { size: colWidth, type: WidthType.DXA }, margins: cellMargins,
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
  numbering: {
    config: [
      { reference: "alpha",
        levels: [{ level: 0, format: LevelFormat.LOWER_LETTER, text: "(%1)", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
    ]
  },
  sections: [
    // ── COVER PAGE ──
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
          "Schedule C",
          "Rate Card\nAttached to MSA-BWH",
          EFFECTIVE_DATE
        ),
      ]
    },

    // ── SCHEDULE C BODY ──
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
        colorBanner("SCHEDULE C \u2014 RATE CARD", CORE_BLUE, WHITE, 28),
        spacer(100),
        bodyText("Attached to Master Service Agreement MSA-BWH"),
        bodyText(`Effective Date: ${EFFECTIVE_DATE}`),

        // ── SECTION 1: VIRTUAL STAFF RATES ──
        spacer(),
        colorBanner("1. VIRTUAL STAFF RATES (BWH CONTRACTED)", DARK_CHARCOAL, WHITE, 24),
        spacer(100),
        bodyText("The following rates reflect BWH contracted rates. Virtual Staff billing operates on a 12-month billing cycle as described in Schedule A, Part 3."),

        spacer(100),
        sectionHeader("1.1 United States \u2014 Based Staff"),
        styledTable(
          ["Role", "Standard Rate", "BWH Contracted Rate"],
          [
            ["Systems Architect", "$250/hr", "$170.00/hr"],
            ["CTO Advisory", "$250/hr", "$225/hr"],
            ["Developer", "$150/hr", "$125/hr"],
            ["Tech Support", "$150/hr", "$106.25/hr"],
          ]
        ),

        spacer(),
        sectionHeader("1.2 Offshore \u2014 Based Staff"),
        styledTable(
          ["Role", "Standard Rate", "BWH Contracted Rate"],
          [
            ["Developer", "$45/hr", "$30/hr"],
            ["SEO Specialist", "$45/hr", "$30/hr"],
            ["Tech Support (Normal Hours)", "$15/hr", "$12.75/hr"],
            ["Tech Support (After Hours)", "$30/hr", "$25.50/hr"],
          ]
        ),

        // ── SECTION 2: PROJECT & AD HOC RATES ──
        spacer(),
        colorBanner("2. PROJECT & AD HOC RATES", DARK_CHARCOAL, WHITE, 24),
        spacer(100),
        styledTable(
          ["Service", "Rate", "Minimum", "Notes"],
          [
            ["On-Site Support (US)", "$150/hr", "2-hour minimum", "No trip charges"],
            ["Remote Support (ad hoc, non-contracted)", "$150/hr", "15-min increments", "Billed in 15-minute increments"],
            ["Emergency / Critical Response", "$250/hr", "1-hour minimum", "After-hours and critical incidents"],
            ["Project Management", "$150/hr", "N/A", "For SOW-based engagements"],
          ]
        ),

        // ── SECTION 3: RATE DEFINITIONS ──
        spacer(),
        colorBanner("3. RATE DEFINITIONS", DARK_CHARCOAL, WHITE, 24),
        spacer(100),
        bodyBoldPrefix("Normal Business Hours: ", "Monday through Friday, 8:00 AM to 6:00 PM Pacific Time, excluding US federal holidays."),
        bodyBoldPrefix("After-Hours: ", "All hours outside of Normal Business Hours, including weekends and US federal holidays."),
        bodyBoldPrefix("BWH Contracted Rate: ", "The discounted hourly rate applied under the BWH Master Service Agreement. These rates apply to Virtual Staff services billed through the 12-month Cycle-Based Billing Model described in Schedule A, Part 3."),
        bodyBoldPrefix("Standard Rate: ", "The standard rate for ad hoc (non-contracted) services. This rate is also applied to calculate cancellation fees on any unpaid hour balance upon termination of Virtual Staff services, as described in Schedule A, Section 3.3(e)."),
        bodyBoldPrefix("Billing Cycle: ", "Virtual Staff services are billed on a 12-month cycle. Initial cycle based on estimated monthly hours per the Service Order. Actual usage tracked from day one with reconciliation at end of each cycle period."),

        // ── TERMS ──
        spacer(),
        colorBanner("4. TERMS", DARK_CHARCOAL, WHITE, 24),
        spacer(100),

        sectionHeader("4.01 Rate Adjustments"),
        bodyText("Technijian may adjust the rates in this Schedule upon sixty (60) days written notice to Client. Adjusted rates shall take effect at the start of the next Renewal Term of the Agreement. Rate increases shall not exceed the greater of (a) 5% per year or (b) the annual percentage change in the Consumer Price Index for All Urban Consumers (CPI-U) for the Los Angeles-Long Beach-Anaheim metropolitan area, as published by the U.S. Bureau of Labor Statistics."),

        spacer(100),
        sectionHeader("4.02 Volume Discounts"),
        bodyText("Volume-based pricing may be negotiated and documented in the applicable Service Order or Subscription Order."),

        spacer(100),
        sectionHeader("4.03 Minimum Billing"),
        bodyText("Contracted Virtual Staff hours are billed per the Cycle-Based Billing Model described in Schedule A, Part 3, at the BWH Contracted Rate. Ad hoc (non-contracted) support is billed at the Standard Rate in 15-minute increments. Upon cancellation or termination, any unpaid hour balance shall be invoiced at the applicable Standard Rate as set forth in Schedule A, Section 3.3(e)."),

        spacer(),
        bodyText("Full Online Services infrastructure pricing available upon request via Service Order."),

      ]
    },
  ]
});

// ── Generate DOCX ──
const outPath = path.join(__dirname, 'BWH-Schedule-C-Rate-Card.docx');
Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync(outPath, buffer);
  const sz = fs.statSync(outPath).size;
  console.log(`Created: ${outPath}  (${sz.toLocaleString()} bytes)`);
}).catch(err => {
  console.error('Error generating DOCX:', err);
  process.exit(1);
});
