/**
 * Brandywine Homes (BWH) — Schedule B: Subscription and License Services
 * Output: BWH-Schedule-B-Subscriptions.docx
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

function infoBox(title, text) {
  return new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: [9360],
    rows: [new TableRow({
      children: [new TableCell({
        borders,
        width: { size: 9360, type: WidthType.DXA },
        shading: { fill: OFF_WHITE, type: ShadingType.CLEAR },
        margins: { top: 120, bottom: 120, left: 200, right: 200 },
        children: [new Paragraph({
          children: [
            new TextRun({ text: title, font: "Open Sans", size: 22, bold: true, color: DARK_CHARCOAL }),
            new TextRun({ text: "\n", font: "Open Sans", size: 8 }),
            new TextRun({ text, font: "Open Sans", size: 20, color: BRAND_GREY }),
          ]
        })]
      })]
    })]
  });
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
          "Schedule B",
          "Subscription and License Services\nAttached to MSA-BWH",
          EFFECTIVE_DATE
        ),
      ]
    },

    // ── SCHEDULE B BODY ──
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
        colorBanner("SCHEDULE B \u2014 SUBSCRIPTION AND LICENSE SERVICES", CORE_BLUE, WHITE, 28),
        spacer(100),
        bodyText("Attached to Master Service Agreement MSA-BWH"),
        bodyText(`Effective Date: ${EFFECTIVE_DATE}`),
        bodyText(`This Schedule describes the Subscription and License Services provided by Technijian, Inc. (\u201CTechnijian\u201D) to ${CLIENT_NAME} (\u201CClient\u201D) under the Master Service Agreement.`),

        spacer(),
        sectionHeader("Current Subscriptions Billed Through Technijian"),
        styledTable(
          ["Service", "Code", "Unit Price", "Qty", "Monthly"],
          [
            ["Microsoft Entra ID P1", "MS-ADP1", "$7.20/user", "1", "$7.20"],
            ["TOTAL", "", "", "", "$7.20"],
          ],
          [1]
        ),

        spacer(),
        bodyText("Note: Other subscriptions (Microsoft 365, etc.) are billed directly by the vendor and are not included in Technijian invoices. If Client elects to procure additional subscriptions through Technijian, they will be added to this Schedule via an updated Service Order."),

        spacer(),
        sectionHeader("Subscription Terms"),
        numbered("(a)", "Subscriptions are billed monthly in advance per MSA Section 3.02(b)."),
        numbered("(b)", "Quantity changes require thirty (30) days written notice and take effect on the first day of the following month."),
        numbered("(c)", "Annual subscriptions procured on Client\u2019s behalf are non-refundable for the committed term."),

        spacer(),
        infoBox(
          "AUTOMATIC RENEWAL DISCLOSURE:",
          "Subscriptions procured through Technijian on Client\u2019s behalf will renew automatically at the then-current rates unless Client provides thirty (30) days written notice of cancellation prior to the renewal date. Technijian will notify Client of any rate changes at least sixty (60) days before the next renewal."
        ),

        spacer(),
        sectionHeader("Data and Access"),
        bodyText("Upon termination of any subscription service, Technijian shall cooperate with Client to ensure orderly transition of subscription data, including:"),
        numbered("(a)", "Providing Client with access to export subscription data prior to cancellation, where supported by the vendor;"),
        numbered("(b)", "Coordinating with the subscription vendor for license transfers, where applicable; and"),
        numbered("(c)", "Notifying Client of any data retention windows imposed by the vendor."),

      ]
    },
  ]
});

// ── Generate DOCX ──
const outPath = path.join(__dirname, 'BWH-Schedule-B-Subscriptions.docx');
Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync(outPath, buffer);
  const sz = fs.statSync(outPath).size;
  console.log(`Created: ${outPath}  (${sz.toLocaleString()} bytes)`);
}).catch(err => {
  console.error('Error generating DOCX:', err);
  process.exit(1);
});
