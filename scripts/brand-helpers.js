// Shared visual helpers for all Technijian DOCX build scripts
const { Paragraph, TextRun, Table, TableRow, TableCell,
        ImageRun, Header, Footer, AlignmentType,
        BorderStyle, WidthType, ShadingType, PageNumber } = require('docx');

const CORE_BLUE = "006DB6";
const CORE_ORANGE = "F67D4B";
const DARK_CHARCOAL = "1A1A2E";
const BRAND_GREY = "59595B";
const OFF_WHITE = "F8F9FA";
const WHITE = "FFFFFF";
const LIGHT_GREY = "E9ECEF";
const TEAL = "1EAAC8";

const noBorders = {
  top: { style: BorderStyle.NONE }, bottom: { style: BorderStyle.NONE },
  left: { style: BorderStyle.NONE }, right: { style: BorderStyle.NONE }
};
const thinBorder = { style: BorderStyle.SINGLE, size: 1, color: LIGHT_GREY };
const borders = { top: thinBorder, bottom: thinBorder, left: thinBorder, right: thinBorder };
const cellMargins = { top: 80, bottom: 80, left: 120, right: 120 };

// Full-width colored banner
function colorBanner(text, bgColor, textColor, fontSize) {
  return new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: [9360],
    rows: [new TableRow({
      children: [new TableCell({
        borders: noBorders, width: { size: 9360, type: WidthType.DXA },
        shading: { fill: bgColor || CORE_BLUE, type: ShadingType.CLEAR },
        margins: { top: 120, bottom: 120, left: 200, right: 200 },
        children: [new Paragraph({ alignment: AlignmentType.CENTER,
          children: [new TextRun({ text, font: "Open Sans", size: fontSize || 28, bold: true, color: textColor || WHITE })] })]
      })]
    })]
  });
}

// Thin accent bar (blue or orange)
function accentBar(color, height) {
  const h = height || 20;
  return new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: [9360],
    rows: [new TableRow({
      children: [new TableCell({
        borders: noBorders, width: { size: 9360, type: WidthType.DXA },
        shading: { fill: color || CORE_BLUE, type: ShadingType.CLEAR },
        margins: { top: h, bottom: h, left: 0, right: 0 },
        children: [new Paragraph({ children: [] })]
      })]
    })]
  });
}

// Section header with colored left bar accent
function sectionHeader(title, color) {
  return new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: [120, 9240],
    rows: [new TableRow({
      children: [
        new TableCell({ borders: noBorders, width: { size: 120, type: WidthType.DXA },
          shading: { fill: color || CORE_BLUE, type: ShadingType.CLEAR },
          children: [new Paragraph({ children: [] })] }),
        new TableCell({ borders: noBorders, width: { size: 9240, type: WidthType.DXA },
          margins: { top: 80, bottom: 80, left: 160, right: 0 },
          children: [new Paragraph({
            children: [new TextRun({ text: title, font: "Open Sans", size: 28, bold: true, color: color || CORE_BLUE })] })] }),
      ]
    })]
  });
}

// Numbered section header (for legal docs)
function numberedSectionHeader(number, title) {
  return new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: [120, 9240],
    rows: [new TableRow({
      children: [
        new TableCell({ borders: noBorders, width: { size: 120, type: WidthType.DXA },
          shading: { fill: CORE_BLUE, type: ShadingType.CLEAR },
          children: [new Paragraph({ children: [] })] }),
        new TableCell({ borders: noBorders, width: { size: 9240, type: WidthType.DXA },
          margins: { top: 80, bottom: 80, left: 160, right: 0 },
          children: [new Paragraph({
            children: [new TextRun({ text: `${number}. ${title.toUpperCase()}`, font: "Open Sans", size: 28, bold: true, color: CORE_BLUE })] })] }),
      ]
    })]
  });
}

// Body text paragraph
function bodyText(text) {
  return new Paragraph({
    spacing: { after: 120 },
    children: [new TextRun({ text, font: "Open Sans", size: 22, color: BRAND_GREY })]
  });
}

// Subsection heading
function subsectionHeading(number, title) {
  return new Paragraph({
    spacing: { before: 240, after: 100 },
    children: [new TextRun({ text: `${number} ${title}`, font: "Open Sans", size: 24, bold: true, color: DARK_CHARCOAL })]
  });
}

// Orange divider (centered)
function orangeDivider() {
  return new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: [3280, 2800, 3280],
    rows: [new TableRow({
      children: [
        new TableCell({ borders: noBorders, width: { size: 3280, type: WidthType.DXA }, children: [new Paragraph({ children: [] })] }),
        new TableCell({ borders: noBorders, width: { size: 2800, type: WidthType.DXA },
          children: [new Paragraph({ border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: CORE_ORANGE, space: 0 } }, children: [] })] }),
        new TableCell({ borders: noBorders, width: { size: 3280, type: WidthType.DXA }, children: [new Paragraph({ children: [] })] }),
      ]
    })]
  });
}

// Cover page builder
function coverPage(logoData, title, subtitle, dateText) {
  return [
    accentBar(CORE_BLUE),
    new Paragraph({ spacing: { before: 1800 }, children: [] }),
    new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 300 },
      children: [new ImageRun({ type: "png", data: logoData, transformation: { width: 280, height: 58 },
        altText: { title: "Technijian", description: "Logo", name: "logo" } })] }),
    orangeDivider(),
    new Paragraph({ spacing: { before: 400 }, alignment: AlignmentType.CENTER,
      children: [new TextRun({ text: title, font: "Open Sans", size: 52, bold: true, color: DARK_CHARCOAL })] }),
    new Paragraph({ spacing: { before: 200 }, alignment: AlignmentType.CENTER,
      children: [new TextRun({ text: subtitle, font: "Open Sans", size: 26, color: BRAND_GREY })] }),
    new Paragraph({ spacing: { before: 100 }, alignment: AlignmentType.CENTER,
      children: [new TextRun({ text: dateText || "[Date]", font: "Open Sans", size: 22, color: BRAND_GREY })] }),
    new Paragraph({ spacing: { before: 1200 }, children: [] }),
    accentBar(CORE_ORANGE),
    new Paragraph({ spacing: { before: 120 }, alignment: AlignmentType.CENTER,
      children: [new TextRun({ text: "CONFIDENTIAL \u2014 For authorized use only", font: "Open Sans", size: 18, italics: true, color: BRAND_GREY })] }),
  ];
}

// Standard branded header
function brandedHeader(logoData) {
  return new Header({
    children: [new Paragraph({
      spacing: { after: 60 },
      border: { bottom: { style: BorderStyle.SINGLE, size: 2, color: CORE_BLUE, space: 6 } },
      children: [new ImageRun({ type: "png", data: logoData, transformation: { width: 140, height: 29 },
        altText: { title: "Technijian", description: "Logo", name: "logo" } })]
    })]
  });
}

// Standard branded footer
function brandedFooter() {
  return new Footer({
    children: [new Paragraph({
      alignment: AlignmentType.CENTER,
      border: { top: { style: BorderStyle.SINGLE, size: 1, color: LIGHT_GREY, space: 6 } },
      children: [
        new TextRun({ text: "Technijian | 18 Technology Dr., Ste 141, Irvine, CA 92618 | 949.379.8500  \u2022  Page ", font: "Open Sans", size: 16, color: BRAND_GREY }),
        new TextRun({ children: [PageNumber.CURRENT], font: "Open Sans", size: 16, color: BRAND_GREY }),
      ]
    })]
  });
}

// Important clause callout box (orange border)
function importantCallout(text) {
  return new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: [9360],
    rows: [new TableRow({
      children: [new TableCell({
        borders: { top: { style: BorderStyle.SINGLE, size: 2, color: CORE_ORANGE }, bottom: { style: BorderStyle.SINGLE, size: 2, color: CORE_ORANGE },
          left: { style: BorderStyle.SINGLE, size: 6, color: CORE_ORANGE }, right: { style: BorderStyle.SINGLE, size: 2, color: CORE_ORANGE } },
        width: { size: 9360, type: WidthType.DXA },
        shading: { fill: "FEF3EE", type: ShadingType.CLEAR },
        margins: { top: 120, bottom: 120, left: 200, right: 200 },
        children: [new Paragraph({ children: [new TextRun({ text, font: "Open Sans", size: 20, color: DARK_CHARCOAL })] })]
      })]
    })]
  });
}

// Status/severity table row
function statusTable(headers, rows) {
  return new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: headers.map(() => Math.floor(9360 / headers.length)),
    rows: [
      new TableRow({
        children: headers.map(h => new TableCell({
          borders, width: { size: Math.floor(9360 / headers.length), type: WidthType.DXA }, margins: cellMargins,
          shading: { fill: CORE_BLUE, type: ShadingType.CLEAR },
          children: [new Paragraph({ children: [new TextRun({ text: h, bold: true, color: WHITE, font: "Open Sans", size: 20 })] })]
        }))
      }),
      ...rows.map((row, i) => new TableRow({
        children: row.map((cell, j) => {
          const isStatus = j === row.length - 1 || (headers[j] && headers[j].toLowerCase().includes('status'));
          let textColor = BRAND_GREY;
          let bold = false;
          if (isStatus && typeof cell === 'string') {
            const lower = cell.toLowerCase();
            if (lower.includes('critical') || lower.includes('fail') || lower.includes('high risk')) { textColor = "CC0000"; bold = true; }
            else if (lower.includes('high') || lower.includes('partial')) { textColor = CORE_ORANGE; bold = true; }
            else if (lower.includes('medium')) { textColor = TEAL; bold = true; }
            else if (lower.includes('pass') || lower.includes('compliant') || lower.includes('complete')) { textColor = "28A745"; bold = true; }
          }
          return new TableCell({
            borders, width: { size: Math.floor(9360 / headers.length), type: WidthType.DXA }, margins: cellMargins,
            shading: { fill: i % 2 === 0 ? WHITE : OFF_WHITE, type: ShadingType.CLEAR },
            children: [new Paragraph({ children: [new TextRun({ text: cell, font: "Open Sans", size: 20, color: textColor, bold })] })]
          });
        })
      }))
    ]
  });
}

// CTA banner
function ctaBanner() {
  return colorBanner("Questions? Contact us at 949.379.8500 or rjain@technijian.com", CORE_BLUE, WHITE, 22);
}

module.exports = {
  CORE_BLUE, CORE_ORANGE, DARK_CHARCOAL, BRAND_GREY, OFF_WHITE, WHITE, LIGHT_GREY, TEAL,
  noBorders, borders, cellMargins,
  colorBanner, accentBar, sectionHeader, numberedSectionHeader,
  bodyText, subsectionHeading, orangeDivider, coverPage,
  brandedHeader, brandedFooter, importantCallout, statusTable, ctaBanner
};
