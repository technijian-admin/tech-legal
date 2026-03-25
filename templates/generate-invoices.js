const fs = require("fs");
const path = require("path");
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  Header, Footer, AlignmentType, HeadingLevel, BorderStyle,
  WidthType, ShadingType, PageNumber, PageBreak, ImageRun
} = require("docx");

// ===== TECHNIJIAN BRAND COLORS (from Brand Guide 2026) =====
const BLUE = "006DB6";
const ORANGE = "F67D4B";
const TEAL = "1EAAC8";
const GREY = "59595B";
const CHARCOAL = "1A1A2E";
const OFF_WHITE = "F8F9FA";
const WHITE = "FFFFFF";
const LIGHT_BLUE = "E8F4FD";
const LIGHT_ORANGE = "FEF0EB";
const FONT = "Open Sans";

// Logo
let logoBuffer = null;
const logoPath = path.join(__dirname, "logo.jpg");
try { logoBuffer = fs.readFileSync(logoPath); } catch (e) { /* no logo */ }

// ===== HELPERS =====
const thinBorder = { style: BorderStyle.SINGLE, size: 1, color: "DDDDDD" };
const noBorder = { style: BorderStyle.NONE, size: 0 };
const tableBorders = { top: thinBorder, bottom: thinBorder, left: thinBorder, right: thinBorder };
const noBorders = { top: noBorder, bottom: noBorder, left: noBorder, right: noBorder };
const cellPadding = { top: 60, bottom: 60, left: 100, right: 100 };

function p(text, opts = {}) {
  const runOpts = { font: FONT, size: opts.size || 20, color: opts.color || GREY, text };
  if (opts.bold) runOpts.bold = true;
  if (opts.italics) runOpts.italics = true;
  const pOpts = { children: [new TextRun(runOpts)] };
  if (opts.alignment) pOpts.alignment = opts.alignment;
  if (opts.spacing) pOpts.spacing = opts.spacing;
  return new Paragraph(pOpts);
}

function multiRun(runs, opts = {}) {
  const children = runs.map(r => {
    const o = { font: FONT, size: r.size || 20, color: r.color || GREY, text: r.text };
    if (r.bold) o.bold = true;
    if (r.italics) o.italics = true;
    return new TextRun(o);
  });
  const pOpts = { children };
  if (opts.alignment) pOpts.alignment = opts.alignment;
  if (opts.spacing) pOpts.spacing = opts.spacing;
  return new Paragraph(pOpts);
}

function spacer(after = 120) { return p("", { spacing: { after } }); }

function cell(text, opts = {}) {
  const width = opts.width || 2000;
  const isHeader = opts.header || false;
  const runs = [{ font: FONT, size: opts.size || 18, text: text || "", color: isHeader ? WHITE : (opts.color || GREY), bold: isHeader || opts.bold || false }];
  if (opts.italics) runs[0].italics = true;
  const alignment = opts.alignment || (isHeader ? AlignmentType.CENTER : AlignmentType.LEFT);
  return new TableCell({
    borders: opts.noBorders ? noBorders : tableBorders,
    width: { size: width, type: WidthType.DXA },
    margins: opts.padding || cellPadding,
    shading: { fill: isHeader ? BLUE : (opts.fill || (opts.alt ? OFF_WHITE : WHITE)), type: ShadingType.CLEAR },
    verticalAlign: "center",
    children: [new Paragraph({ alignment, children: [new TextRun(runs[0])] })]
  });
}

function multiLineCell(lines, opts = {}) {
  const width = opts.width || 2000;
  return new TableCell({
    borders: opts.noBorders ? noBorders : tableBorders,
    width: { size: width, type: WidthType.DXA },
    margins: opts.padding || cellPadding,
    shading: { fill: opts.fill || WHITE, type: ShadingType.CLEAR },
    verticalAlign: "center",
    children: lines.map(l => new Paragraph({
      alignment: l.alignment || AlignmentType.LEFT,
      children: [new TextRun({ font: FONT, size: l.size || 18, text: l.text, color: l.color || GREY, bold: l.bold || false })]
    }))
  });
}

function makeTable(headers, rows, widths) {
  const totalWidth = widths.reduce((a, b) => a + b, 0);
  const tableRows = [
    new TableRow({ children: headers.map((h, i) => cell(h, { width: widths[i], header: true })) }),
    ...rows.map((row, ri) => new TableRow({
      children: row.map((c, ci) => {
        const text = typeof c === "string" ? c : c.text;
        const copts = typeof c === "object" ? c : {};
        return cell(text, { width: widths[ci], alt: ri % 2 === 0, ...copts });
      })
    }))
  ];
  return new Table({ width: { size: totalWidth, type: WidthType.DXA }, columnWidths: widths, rows: tableRows });
}

// ===== INVOICE HEADER / FOOTER =====
function invoiceHeader() {
  const children = [];
  if (logoBuffer) {
    children.push(new Paragraph({
      alignment: AlignmentType.LEFT,
      children: [new ImageRun({ type: "jpg", data: logoBuffer, transformation: { width: 140, height: 35 }, altText: { title: "Technijian", description: "Technijian Inc.", name: "logo" } })]
    }));
  } else {
    children.push(new Paragraph({
      children: [
        new TextRun({ text: "TECHNIJIAN", font: FONT, bold: true, size: 22, color: BLUE }),
        new TextRun({ text: "  technology as a solution", font: FONT, size: 16, color: GREY })
      ]
    }));
  }
  children.push(new Paragraph({ border: { bottom: { style: BorderStyle.SINGLE, size: 2, color: ORANGE } }, children: [] }));
  return new Header({ children });
}

function invoiceFooter() {
  // Simple footer — company info + page numbers only (terms go in body)
  return new Footer({ children: [
    new Paragraph({ border: { top: { style: BorderStyle.SINGLE, size: 1, color: BLUE } }, spacing: { before: 60 }, children: [] }),
    new Paragraph({ alignment: AlignmentType.CENTER, children: [
      new TextRun({ text: "Technijian, Inc.  |  18 Technology Dr., Ste 141, Irvine, CA 92618  |  949.379.8499", font: FONT, size: 14, color: GREY })
    ]}),
    new Paragraph({ alignment: AlignmentType.CENTER, children: [
      new TextRun({ text: "Page ", font: FONT, size: 14, color: GREY }),
      new TextRun({ children: [PageNumber.CURRENT], font: FONT, size: 14, color: GREY }),
      new TextRun({ text: " of ", font: FONT, size: 14, color: GREY }),
      new TextRun({ children: [PageNumber.TOTAL_PAGES], font: FONT, size: 14, color: GREY }),
    ]})
  ]});
}

// ===== MSA REFERENCE BAR (blue bar under title) =====
function msaRefBar(msaRef, schedule) {
  const parts = [`Governed by Master Service Agreement ${msaRef}`];
  if (schedule) parts.push(`Schedule ${schedule}`);
  return new Table({
    width: { size: 10080, type: WidthType.DXA },
    columnWidths: [10080],
    rows: [new TableRow({ children: [
      new TableCell({
        borders: noBorders,
        width: { size: 10080, type: WidthType.DXA },
        margins: { top: 60, bottom: 60, left: 200, right: 200 },
        shading: { fill: LIGHT_BLUE, type: ShadingType.CLEAR },
        children: [new Paragraph({
          alignment: AlignmentType.CENTER,
          children: [
            new TextRun({ text: parts.join("  |  "), font: FONT, size: 18, bold: true, color: BLUE })
          ]
        })]
      })
    ]})]
  });
}

// ===== PAYMENT TERMS BOX (in invoice body, not footer) =====
function paymentTermsBox(msaRef, isMSAClient) {
  const children = [];

  // Section heading
  children.push(new Paragraph({
    spacing: { before: 60 },
    children: [new TextRun({ text: "TERMS & CONDITIONS", font: FONT, size: 20, bold: true, color: WHITE })]
  }));

  if (isMSAClient) {
    children.push(new Paragraph({ spacing: { before: 80 }, children: [
      new TextRun({ text: "Governing Agreement: ", font: FONT, size: 16, bold: true, color: WHITE }),
      new TextRun({ text: `This invoice is governed by Master Service Agreement ${msaRef || "[MSA-XXXX]"} and all applicable Schedules attached thereto. In the event of any conflict between the terms stated on this invoice and the MSA, the MSA shall control.`, font: FONT, size: 16, color: LIGHT_BLUE })
    ]}));
    children.push(new Paragraph({ spacing: { before: 60 }, children: [
      new TextRun({ text: "Payment: ", font: FONT, size: 16, bold: true, color: WHITE }),
      new TextRun({ text: "Due within thirty (30) days of invoice date (MSA Section 3.03).", font: FONT, size: 16, color: LIGHT_BLUE })
    ]}));
    children.push(new Paragraph({ spacing: { before: 60 }, children: [
      new TextRun({ text: "Late Fees: ", font: FONT, size: 16, bold: true, color: WHITE }),
      new TextRun({ text: "1.5% per month on unpaid balance, compounding monthly (MSA Section 3.04).", font: FONT, size: 16, color: LIGHT_BLUE })
    ]}));
    children.push(new Paragraph({ spacing: { before: 60 }, children: [
      new TextRun({ text: "Disputes: ", font: FONT, size: 16, bold: true, color: WHITE }),
      new TextRun({ text: "Written notice within fifteen (15) days of invoice date. Failure to dispute constitutes acceptance (MSA Section 3.05).", font: FONT, size: 16, color: LIGHT_BLUE })
    ]}));
    children.push(new Paragraph({ spacing: { before: 60 }, children: [
      new TextRun({ text: "Non-Payment Remedies: ", font: FONT, size: 16, bold: true, color: WHITE }),
      new TextRun({ text: "Service suspension (MSA 3.06), acceleration of all amounts due (MSA 3.07), lien and security interest enforcement (MSA 3.09-3.10). Client liable for all collection costs and attorney's fees (MSA 3.08, 8.04).", font: FONT, size: 16, color: LIGHT_BLUE })
    ]}));
  } else {
    children.push(new Paragraph({ spacing: { before: 80 }, children: [
      new TextRun({ text: "Payment: ", font: FONT, size: 16, bold: true, color: WHITE }),
      new TextRun({ text: "Due within thirty (30) days of invoice date.", font: FONT, size: 16, color: LIGHT_BLUE })
    ]}));
    children.push(new Paragraph({ spacing: { before: 60 }, children: [
      new TextRun({ text: "Late Fees: ", font: FONT, size: 16, bold: true, color: WHITE }),
      new TextRun({ text: "1.5% per month (18% APR) on unpaid balance, or the maximum rate permitted by California law, whichever is less.", font: FONT, size: 16, color: LIGHT_BLUE })
    ]}));
    children.push(new Paragraph({ spacing: { before: 60 }, children: [
      new TextRun({ text: "Disputes: ", font: FONT, size: 16, bold: true, color: WHITE }),
      new TextRun({ text: "Written notice within fifteen (15) days of invoice date. Failure to dispute constitutes acceptance.", font: FONT, size: 16, color: LIGHT_BLUE })
    ]}));
    children.push(new Paragraph({ spacing: { before: 60 }, children: [
      new TextRun({ text: "Acceptance: ", font: FONT, size: 16, bold: true, color: WHITE }),
      new TextRun({ text: "By accepting services or making payment, Client agrees to be bound by Technijian's Standard Terms and Conditions.", font: FONT, size: 16, color: LIGHT_BLUE })
    ]}));
    children.push(new Paragraph({ spacing: { before: 60 }, children: [
      new TextRun({ text: "Collection: ", font: FONT, size: 16, bold: true, color: WHITE }),
      new TextRun({ text: "Unpaid accounts may be reported to credit agencies and referred to collections after sixty (60) days. Client liable for all collection costs and attorney's fees.", font: FONT, size: 16, color: LIGHT_BLUE })
    ]}));
    children.push(new Paragraph({ spacing: { before: 60 }, children: [
      new TextRun({ text: "Governing Law: ", font: FONT, size: 16, bold: true, color: WHITE }),
      new TextRun({ text: "State of California. Disputes resolved by binding arbitration in Orange County, CA.", font: FONT, size: 16, color: LIGHT_BLUE })
    ]}));
  }

  // Wrap in a dark charcoal box
  return new Table({
    width: { size: 10080, type: WidthType.DXA },
    columnWidths: [10080],
    rows: [new TableRow({ children: [
      new TableCell({
        borders: { top: { style: BorderStyle.SINGLE, size: 3, color: ORANGE }, bottom: { style: BorderStyle.SINGLE, size: 3, color: ORANGE }, left: noBorder, right: noBorder },
        width: { size: 10080, type: WidthType.DXA },
        margins: { top: 120, bottom: 120, left: 200, right: 200 },
        shading: { fill: CHARCOAL, type: ShadingType.CLEAR },
        children
      })
    ]})]
  });
}

function invoiceSectionProps() {
  return {
    page: {
      size: { width: 12240, height: 15840 },
      margin: { top: 1200, right: 1080, bottom: 1200, left: 1080 }
    },
    headers: { default: invoiceHeader() },
    footers: { default: invoiceFooter() }
  };
}

// ===== INVOICE TITLE BAR =====
function invoiceTitleBar(title) {
  // Orange background bar with white text
  return new Table({
    width: { size: 10080, type: WidthType.DXA },
    columnWidths: [10080],
    rows: [new TableRow({ children: [
      new TableCell({
        borders: noBorders,
        width: { size: 10080, type: WidthType.DXA },
        margins: { top: 100, bottom: 100, left: 200, right: 200 },
        shading: { fill: ORANGE, type: ShadingType.CLEAR },
        children: [new Paragraph({
          alignment: AlignmentType.RIGHT,
          children: [new TextRun({ text: title, font: FONT, size: 32, bold: true, color: WHITE })]
        })]
      })
    ]})]
  });
}

// ===== BILL TO / INVOICE INFO BLOCK =====
function billToBlock(billTo, invoiceInfo) {
  // Two-column layout: Bill To on left, Invoice details on right
  const leftLines = [
    { text: "Bill To:", size: 16, bold: true, color: ORANGE },
    { text: billTo.name || "[CLIENT NAME]", size: 20, bold: true, color: CHARCOAL },
    { text: billTo.company || "", size: 18, color: GREY },
    { text: billTo.address || "[CLIENT ADDRESS]", size: 18, color: GREY },
    { text: billTo.cityStateZip || "[CITY, STATE ZIP]", size: 18, color: GREY }
  ].filter(l => l.text);

  const rightData = [
    ["Invoice #:", invoiceInfo.number || "[INV-XXXX]"],
    ["Date:", invoiceInfo.date || "[DATE]"],
    ["Due:", invoiceInfo.due || "[DUE DATE]"],
    ["Page:", invoiceInfo.page || "1 of 1"]
  ];
  if (invoiceInfo.msaRef) rightData.push(["MSA:", invoiceInfo.msaRef]);
  if (invoiceInfo.schedule) rightData.push(["Schedule:", invoiceInfo.schedule]);
  if (invoiceInfo.servicePeriod) rightData.push(["Period:", invoiceInfo.servicePeriod]);
  if (invoiceInfo.datesOfService) rightData.push(["Service:", invoiceInfo.datesOfService]);

  const rightChildren = rightData.map(([label, value]) => new Paragraph({
    alignment: AlignmentType.RIGHT,
    spacing: { after: 20 },
    children: [
      new TextRun({ text: label + " ", font: FONT, size: 16, bold: true, color: CHARCOAL }),
      new TextRun({ text: value, font: FONT, size: 18, color: BLUE, bold: true })
    ]
  }));

  return new Table({
    width: { size: 10080, type: WidthType.DXA },
    columnWidths: [5040, 5040],
    rows: [new TableRow({ children: [
      new TableCell({
        borders: noBorders,
        width: { size: 5040, type: WidthType.DXA },
        margins: { top: 60, bottom: 60, left: 80, right: 80 },
        shading: { fill: LIGHT_BLUE, type: ShadingType.CLEAR },
        children: leftLines.map(l => new Paragraph({
          spacing: { after: 20 },
          children: [new TextRun({ text: l.text, font: FONT, size: l.size, color: l.color, bold: l.bold || false })]
        }))
      }),
      new TableCell({
        borders: noBorders,
        width: { size: 5040, type: WidthType.DXA },
        margins: { top: 60, bottom: 60, left: 80, right: 80 },
        shading: { fill: WHITE, type: ShadingType.CLEAR },
        children: rightChildren
      })
    ]})]
  });
}

// ===== ACCOUNT SUMMARY BAR =====
function accountSummaryBar(previousBalance, paymentsReceived, currentCharges, amountDue) {
  const items = [
    ["Previous Balance", previousBalance],
    ["Payments Received", paymentsReceived],
    ["Current Charges", currentCharges],
    ["Amount Due", amountDue]
  ];
  const colWidth = 2520;
  return new Table({
    width: { size: 10080, type: WidthType.DXA },
    columnWidths: items.map(() => colWidth),
    rows: [
      new TableRow({ children: items.map(([label], i) =>
        cell(label, { width: colWidth, header: i < 3, fill: i === 3 ? ORANGE : undefined, size: 16, bold: true })
      )}),
      new TableRow({ children: items.map(([, value], i) =>
        cell(value, { width: colWidth, fill: i === 3 ? LIGHT_ORANGE : OFF_WHITE, bold: i === 3, color: i === 3 ? CHARCOAL : GREY, alignment: AlignmentType.CENTER, size: 22 })
      )})
    ]
  });
}

// ===== TOTALS BLOCK =====
function totalsBlock(subtotal, tax, total, balanceDue) {
  const rows = [["Sub-Total:", subtotal]];
  if (tax !== undefined) rows.push([`Sales Tax (7.75%):`, tax]);
  rows.push(["Total:", total]);
  rows.push(["Balance Due:", balanceDue]);

  return new Table({
    width: { size: 4000, type: WidthType.DXA },
    columnWidths: [2400, 1600],
    rows: rows.map(([label, value], i) => {
      const isLast = i === rows.length - 1;
      return new TableRow({ children: [
        cell(label, { width: 2400, bold: true, color: CHARCOAL, alignment: AlignmentType.RIGHT, fill: isLast ? ORANGE : OFF_WHITE, size: isLast ? 20 : 18 }),
        cell(value, { width: 1600, bold: isLast, color: isLast ? WHITE : GREY, alignment: AlignmentType.RIGHT, fill: isLast ? ORANGE : WHITE, size: isLast ? 20 : 18 })
      ]});
    })
  });
}

// ===== WIRE INFO BLOCK =====
function wireInfoBlock() {
  return [
    p("Wire / ACH Information", { bold: true, size: 18, color: CHARCOAL, spacing: { before: 200, after: 60 } }),
    multiRun([{ text: "Bank: ", bold: true, size: 16, color: CHARCOAL }, { text: "Chase", size: 16 }]),
    multiRun([{ text: "Account: ", bold: true, size: 16, color: CHARCOAL }, { text: "791013375", size: 16 }]),
    multiRun([{ text: "Routing: ", bold: true, size: 16, color: CHARCOAL }, { text: "322271627", size: 16 }]),
  ];
}


// ===== SERVICE PROFILE GROUP — MATRIX STYLE (matches old invoice layout) =====
// Each group row: Location/Group | Category columns with count pairs + price | Sub-Total
function profileGroupRow(groupName, categories, groupSubtotal) {
  // categories = [{ name: "Users", count: "5", billed: "5", price: "$20.00", total: "$28.00" }, ...]
  // Build dynamic columns based on categories present
  const rows = [];
  const groupW = 1400;
  const subW = 1200;
  // Determine category columns from data (max ~6 categories to fit page)
  const catCols = categories.map(c => ({
    name: c.name,
    count: c.count,
    billed: c.billed,
    price: c.price,
    total: c.total,
  }));
  // Each category gets 2 sub-columns (count | billed) — we'll show as "count  billed" in one cell
  const catW = Math.floor((10080 - groupW - subW) / Math.max(catCols.length, 1));

  // Header row
  const headerCells = [cell("Location/Group", { width: groupW, header: true, size: 14, alignment: AlignmentType.LEFT })];
  catCols.forEach(c => headerCells.push(cell(c.name, { width: catW, header: true, size: 14 })));
  headerCells.push(cell("Sub-Total", { width: subW, header: true, size: 14 }));
  rows.push(new TableRow({ children: headerCells }));

  // Group name + count row
  const countCells = [cell(groupName, { width: groupW, bold: true, color: CHARCOAL, size: 16 })];
  catCols.forEach(c => {
    // Show count pair: "5    5" (current | billed) in one cell
    countCells.push(multiLineCell([
      { text: `${c.count}       ${c.billed}`, size: 16, color: GREY, alignment: AlignmentType.CENTER }
    ], { width: catW, fill: OFF_WHITE }));
  });
  countCells.push(cell("", { width: subW }));
  rows.push(new TableRow({ children: countCells }));

  // Price row
  const priceCells = [cell("", { width: groupW, fill: OFF_WHITE })];
  catCols.forEach(c => cell_push(priceCells, c.price, catW));
  priceCells.push(cell(groupSubtotal, { width: subW, bold: true, color: BLUE, alignment: AlignmentType.RIGHT, size: 16 }));
  rows.push(new TableRow({ children: priceCells }));

  const allWidths = [groupW, ...catCols.map(() => catW), subW];
  return new Table({
    width: { size: allWidths.reduce((a, b) => a + b, 0), type: WidthType.DXA },
    columnWidths: allWidths,
    rows
  });
}

// Helper for price cells
function cell_push(arr, price, w) {
  arr.push(cell(price, { width: w, alignment: AlignmentType.CENTER, size: 14, color: GREY, fill: OFF_WHITE }));
}

// ===== VIRTUAL STAFF MATRIX (role columns with hour pairs) =====
function virtualStaffMatrix(staffRoles, staffSubtotal) {
  // staffRoles = [{ name: "USA Tech: Normal", hours: "0.25", billed: "0.25", total: "$37.50" }, ...]
  const labelW = 1400;
  const subW = 1200;
  const roleW = Math.floor((10080 - labelW - subW) / Math.max(staffRoles.length, 1));
  const allWidths = [labelW, ...staffRoles.map(() => roleW), subW];

  const rows = [];
  // Header: "Virtual Staff" | role names... | "Sub-Total"
  const h = [cell("Virtual Staff", { width: labelW, header: true, size: 14, alignment: AlignmentType.LEFT })];
  staffRoles.forEach(r => h.push(cell(r.name, { width: roleW, header: true, size: 12 })));
  h.push(cell("", { width: subW, header: true, size: 14 }));
  rows.push(new TableRow({ children: h }));

  // Hours row: "Remote" | "hours  billed" pairs | subtotal
  const hr = [cell("Remote", { width: labelW, bold: true, color: CHARCOAL, size: 14 })];
  staffRoles.forEach(r => hr.push(multiLineCell([
    { text: `${r.hours}       ${r.billed}`, size: 14, color: GREY, alignment: AlignmentType.CENTER }
  ], { width: roleW, fill: OFF_WHITE })));
  hr.push(cell("", { width: subW }));
  rows.push(new TableRow({ children: hr }));

  // Price row
  const pr = [cell("", { width: labelW, fill: OFF_WHITE })];
  staffRoles.forEach(r => pr.push(cell(r.total, { width: roleW, alignment: AlignmentType.CENTER, size: 14, color: GREY, fill: OFF_WHITE })));
  pr.push(cell(staffSubtotal, { width: subW, bold: true, color: BLUE, alignment: AlignmentType.RIGHT, size: 16 }));
  rows.push(new TableRow({ children: pr }));

  return new Table({
    width: { size: allWidths.reduce((a, b) => a + b, 0), type: WidthType.DXA },
    columnWidths: allWidths,
    rows
  });
}

// ===== SUPPORT HISTORY — Unpaid (Bef) | Billed | Actual | Unpaid (Aft) =====
function supportHistoryTable(historyRows) {
  // historyRows = [{ role, unpaidBef, billed, actual, unpaidAft }, ...]
  return makeTable(
    ["Role", "Unpaid (Bef)", "Billed", "Actual", "Unpaid (Aft)"],
    historyRows.map(r => {
      const aftVal = parseFloat((r.unpaidAft || "0").replace(/[^0-9.\-]/g, ""));
      return [
        r.role,
        r.unpaidBef,
        r.billed,
        r.actual,
        { text: r.unpaidAft, bold: true, color: aftVal > 0 ? ORANGE : GREY }
      ];
    }),
    [2000, 1600, 1600, 1600, 1600]
  );
}

// ===== DISCLAIMER BOX (right side, next to support history) =====
function disclaimerBlock(msaRef) {
  return multiLineCell([
    { text: "Disclaimer", size: 18, bold: true, color: CHARCOAL },
    { text: "", size: 8 },
    { text: `Attached is the price list and terms and conditions that help determine the monthly invoice. Payment of this invoice means the client agrees to the price list, terms and conditions, and the Master Service Agreement ${msaRef || "[MSA-XXXX]"}.`, size: 14, color: GREY },
    { text: "", size: 8 },
    { text: "The Support History section reflects actual vs. billed hours for the current under-contract period. Any unpaid hour balance is subject to invoicing upon termination per the applicable agreement terms.", size: 14, color: GREY },
    { text: "", size: 8 },
    { text: `Per MSA Schedule A, Section 3.3(e) and Section 2.05(a)(ii).`, size: 14, color: GREY, bold: true },
  ], { width: 5040, fill: WHITE, noBorders: true, padding: { top: 60, bottom: 60, left: 120, right: 60 } });
}


// =====================================================================
// INVOICE TYPE 1: MONTHLY SERVICE INVOICE
// =====================================================================
function generateMonthlyServiceInvoice() {
  const children = [];

  children.push(invoiceTitleBar("MONTHLY SERVICE INVOICE"));
  children.push(spacer(80));
  children.push(msaRefBar("[MSA-XXXX]", "A — Monthly Managed Services"));
  children.push(spacer(120));

  children.push(billToBlock(
    { name: "[CLIENT NAME]", address: "[CLIENT ADDRESS]", cityStateZip: "[CITY, STATE ZIP]" },
    { number: "[INV-XXXX]", date: "[DATE]", due: "[DUE DATE]", msaRef: "[MSA-XXXX]", schedule: "A" }
  ));
  children.push(spacer(150));

  // ========== SERVICE PROFILE GROUPS (matrix style) ==========
  // Group 1: ICML/Root — Users + Storages
  children.push(profileGroupRow("ICML / Root", [
    { name: "Users",    count: "5",  billed: "5",  price: "$20.00", total: "$28.00" },
    { name: "Storages", count: "56.00", billed: "55.00", price: "$28.00", total: "" },
  ], "$48.00"));
  children.push(spacer(80));

  // Group 2: ICML/ActiveMailboxes
  children.push(profileGroupRow("ICML / ActiveMailboxes", [
    { name: "Users", count: "2", billed: "2", price: "$8.50", total: "" },
  ], "$8.50"));
  children.push(spacer(150));

  // ========== SIP TRUNK ==========
  children.push(new Table({
    width: { size: 10080, type: WidthType.DXA },
    columnWidths: [1400, 7480, 1200],
    rows: [
      new TableRow({ children: [
        cell("SIP Trunk", { width: 1400, header: true, size: 14, alignment: AlignmentType.LEFT }),
        cell("", { width: 7480, header: true }),
        cell("Sub-Total", { width: 1200, header: true, size: 14 }),
      ]}),
      new TableRow({ children: [
        cell("", { width: 1400 }),
        cell("", { width: 7480 }),
        cell("", { width: 1200 }),
      ]})
    ]
  }));
  children.push(spacer(150));

  // ========== VIRTUAL STAFF (matrix style) ==========
  children.push(virtualStaffMatrix([
    { name: "USA Tech: Normal", hours: "0.25", billed: "0.25", total: "$37.50" },
    { name: "India Tech: AH",  hours: "0.73", billed: "0.5",  total: "$32.85" },
    { name: "India Tech: Normal", hours: "1.0", billed: "1.0", total: "$30.00" },
  ], "$100.35"));
  children.push(spacer(200));

  // ========== TOTALS ==========
  children.push(totalsBlock("$156.85", undefined, "$156.85", "$156.85"));
  children.push(spacer(300));

  // ========== BOTTOM SECTION: Support History (left) + Disclaimer (right) ==========
  // Two-column layout using a table
  const historyData = [
    { role: "India Tech: Normal",   unpaidBef: "0.00", billed: "1.00", actual: "1.00", unpaidAft: "0.00" },
    { role: "India Tech: After Hours", unpaidBef: "4.55", billed: "0.73", actual: "0.50", unpaidAft: "4.32" },
    { role: "India Dev: Normal",    unpaidBef: "0.00", billed: "0.25", actual: "0.25", unpaidAft: "0.00" },
    { role: "USA Tech: Normal",     unpaidBef: "4.55", billed: "0.73", actual: "0.50", unpaidAft: "4.32" },
    { role: "USA Dev: Normal",      unpaidBef: "0.00", billed: "0.25", actual: "0.25", unpaidAft: "0.00" },
    { role: "USA CTO: Normal",      unpaidBef: "0.00", billed: "0.25", actual: "0.25", unpaidAft: "0.00" },
  ];

  const historyTable = supportHistoryTable(historyData);

  // Wrap support history + disclaimer side by side
  children.push(new Table({
    width: { size: 10080, type: WidthType.DXA },
    columnWidths: [5040, 5040],
    rows: [new TableRow({ children: [
      new TableCell({
        borders: noBorders,
        width: { size: 5040, type: WidthType.DXA },
        margins: { top: 0, bottom: 0, left: 0, right: 80 },
        children: [
          historyTable,
          spacer(60),
          p("*Unpaid hours represent the difference between actual hours worked and hours billed during the current under-contract period. Upon termination of this Agreement, all unpaid hours documented through ticketing shall be invoiced at the applicable hourly rate per the Rate Card and are due before the agreement is terminated, per the Client Monthly Service Agreement and Master Service Agreement Section 2.05(a).", { italics: true, size: 12, color: GREY }),
        ]
      }),
      disclaimerBlock("[MSA-XXXX]")
    ]})]
  }));

  children.push(spacer(200));

  // Terms & Conditions
  children.push(paymentTermsBox("[MSA-XXXX]", true));

  return children;
}


// =====================================================================
// INVOICE TYPE 2: RECURRING SUBSCRIPTION INVOICE
// =====================================================================
function generateRecurringSubscriptionInvoice() {
  const children = [];

  children.push(invoiceTitleBar("RECURRING SUBSCRIPTION INVOICE"));
  children.push(spacer(80));
  children.push(msaRefBar("[MSA-XXXX]", "B — Subscription & License Services"));
  children.push(spacer(200));

  children.push(billToBlock(
    { name: "[CLIENT NAME]", address: "[CLIENT ADDRESS]", cityStateZip: "[CITY, STATE ZIP]" },
    { number: "[INV-XXXX]", date: "[DATE]", due: "[DUE DATE]", msaRef: "[MSA-XXXX]", schedule: "B" }
  ));
  children.push(spacer(200));

  // Software Subscriptions
  children.push(p("Software Subscriptions & Licenses", { bold: true, size: 20, color: BLUE, spacing: { after: 100 } }));
  children.push(makeTable(
    ["Item", "Description", "Billing", "Qty", "Unit Price", "Sub-Total"],
    [
      ["5.4.2 M365", "Microsoft 365 Business Standard", "Monthly", "69.00", "$15.00", "$1,035.00"],
      ["5.4.2 M365", "365 Business Basic", "Monthly", "78.00", "$7.20", "$561.60"],
      ["5.4.2 M365", "Power BI Pro", "Monthly", "18.00", "$16.80", "$302.40"],
      ["5.4.2 M365", "Microsoft Entra ID P1", "Monthly", "1.00", "$7.20", "$7.20"],
      ["5.4.2 M365", "Copilot", "Annual", "1.00", "$360.00", "$360.00"],
    ],
    [1200, 2800, 1000, 800, 1000, 1200]
  ));
  children.push(spacer(100));

  // SSL Certificates
  children.push(p("SSL Certificates", { bold: true, size: 20, color: BLUE, spacing: { after: 100 } }));
  children.push(makeTable(
    ["Type", "Domain / Description", "Billing", "Qty", "Unit Price", "Sub-Total"],
    [
      ["UCC Multi-Domain", "UCC SSL 1 Year Multiple Domains", "Annual", "1.00", "$134.99", "$134.99"],
      ["Standard SSL", "Standard SSL - 1 Year", "Annual", "2.00", "$67.99", "$135.98"],
      ["Wildcard SSL", "SSL Wildcard - 1 Year", "Annual", "1.00", "$234.99", "$234.99"],
    ],
    [1200, 2800, 1000, 800, 1000, 1200]
  ));
  children.push(spacer(100));

  // Domain Registrations
  children.push(p("Domain Registrations", { bold: true, size: 20, color: BLUE, spacing: { after: 100 } }));
  children.push(makeTable(
    ["Service", "Domain", "Billing", "Qty", "Unit Price", "Sub-Total"],
    [
      ["Domain Reg.", "oxplive.com", "Annual", "1.00", "$35.25", "$35.25"],
      ["Domain Reg.", "orthoxbiologics.com", "Annual", "1.00", "$35.25", "$35.25"],
    ],
    [1200, 2800, 1000, 800, 1000, 1200]
  ));
  children.push(spacer(60));
  children.push(p("Annual subscriptions auto-renew per MSA Schedule B, Section 5.03 unless Client provides 30 days' written notice prior to renewal date.", { italics: true, size: 14, color: GREY, spacing: { after: 100 } }));

  children.push(spacer(100));
  children.push(totalsBlock("$4,683.55", "$0.00", "$4,683.55", "$4,683.55"));
  children.push(spacer(200));
  children.push(...wireInfoBlock());

  // Terms & Conditions
  children.push(spacer(300));
  children.push(paymentTermsBox("[MSA-XXXX]", true));

  return children;
}


// =====================================================================
// INVOICE TYPE 3: WEEKLY IN-CONTRACT SERVICE INVOICE
// =====================================================================
function generateWeeklyInContractInvoice() {
  const children = [];

  children.push(invoiceTitleBar("WEEKLY SERVICE INVOICE"));
  children.push(spacer(80));
  children.push(msaRefBar("[MSA-XXXX]", "A — Virtual Staff (Contracted Support)"));
  children.push(spacer(200));

  children.push(billToBlock(
    { name: "[CLIENT NAME]", address: "[CLIENT ADDRESS]", cityStateZip: "[CITY, STATE ZIP]" },
    { number: "[INV-XXXX]", date: "[DATE]", due: "[DUE DATE]", msaRef: "[MSA-XXXX]", schedule: "A — Virtual Staff", datesOfService: "[START] - [END]" }
  ));
  children.push(spacer(200));

  // Hours Summary
  children.push(p("Contracted Hours Summary", { bold: true, size: 20, color: BLUE, spacing: { after: 100 } }));
  children.push(makeTable(
    ["Role / POD", "Type", "Hours", "Rate", "Status", "Amount"],
    [
      ["CHD-TS1 Support", "Remote (N)", "1.25", "$15.00/hr", "Under Contract", "$0.00"],
      ["CHD-TS1 Support", "Remote (AH)", "1.00", "$30.00/hr", "Under Contract", "$0.00"],
    ],
    [1800, 1400, 900, 1200, 1500, 1200]
  ));
  children.push(spacer(100));

  // Running Balance Snapshot
  children.push(p("Cycle Running Balance (Snapshot)", { bold: true, size: 18, color: CHARCOAL, spacing: { after: 80 } }));
  children.push(makeTable(
    ["Role", "Cycle Billed Hrs/Mo", "Actual This Week", "Running Balance"],
    [
      ["CHD-TS1 Support (N)", "98.00", "1.25 hrs", "+0.00 hrs"],
      ["CHD-TS1 Support (AH)", "66.00", "1.00 hrs", "+0.00 hrs"],
    ],
    [2800, 2000, 2000, 2000]
  ));
  children.push(p("* Positive balance = hours consumed exceeding billed amount, payable upon cycle reconciliation or termination per MSA Schedule A, Section 3.3(e).", { italics: true, size: 14, color: GREY, spacing: { before: 40, after: 100 } }));
  children.push(spacer(100));

  // Ticket Details
  children.push(p("Ticket Details", { bold: true, size: 20, color: BLUE, spacing: { after: 100 } }));
  children.push(makeTable(
    ["Date", "Ticket Title", "Resource", "Role", "Hours", "Notes"],
    [
      ["[DATE]", "[Ticket title]", "[Resource Name]", "CHD-TS1 (N)", "0.75", "[Work description]"],
      ["[DATE]", "[Ticket title]", "[Resource Name]", "CHD-TS1 (AH)", "1.00", "[Work description]"],
    ],
    [1100, 2200, 1400, 1200, 800, 2600]
  ));
  children.push(spacer(200));

  // Totals
  children.push(totalsBlock("$0.00", undefined, "$0.00", "$0.00"));
  children.push(spacer(60));
  children.push(p("This is a transparency report for contracted hours. No additional payment is due. Monthly billing is per the cycle-based model in MSA Schedule A, Section 3.3.", { italics: true, size: 14, color: GREY }));

  // Terms & Conditions
  children.push(spacer(300));
  children.push(paymentTermsBox("[MSA-XXXX]", true));

  return children;
}


// =====================================================================
// INVOICE TYPE 4: WEEKLY OUT-OF-CONTRACT SERVICE INVOICE
// =====================================================================
function generateWeeklyOutOfContractInvoice() {
  const children = [];

  children.push(invoiceTitleBar("WEEKLY SERVICE INVOICE — BILLABLE"));
  children.push(spacer(80));
  children.push(msaRefBar("[MSA-XXXX]", "C — Rate Card"));
  children.push(spacer(200));

  children.push(billToBlock(
    { name: "[CLIENT NAME]", address: "[CLIENT ADDRESS]", cityStateZip: "[CITY, STATE ZIP]" },
    { number: "[INV-XXXX]", date: "[DATE]", due: "[DUE DATE]", msaRef: "[MSA-XXXX]", schedule: "C — Rate Card", datesOfService: "[START] - [END]" }
  ));
  children.push(spacer(200));

  // Out of Contract Notice
  children.push(new Table({
    width: { size: 10080, type: WidthType.DXA },
    columnWidths: [10080],
    rows: [new TableRow({ children: [
      new TableCell({
        borders: { top: { style: BorderStyle.SINGLE, size: 2, color: ORANGE }, bottom: { style: BorderStyle.SINGLE, size: 2, color: ORANGE }, left: noBorder, right: noBorder },
        width: { size: 10080, type: WidthType.DXA },
        margins: { top: 80, bottom: 80, left: 200, right: 200 },
        shading: { fill: LIGHT_ORANGE, type: ShadingType.CLEAR },
        children: [new Paragraph({
          alignment: AlignmentType.CENTER,
          children: [new TextRun({ text: "OUT OF CONTRACT — BILLABLE HOURS", font: FONT, size: 20, bold: true, color: ORANGE })]
        }), new Paragraph({
          alignment: AlignmentType.CENTER,
          children: [new TextRun({ text: "These hours are outside contracted scope and billed at Rate Card (Schedule C) rates.", font: FONT, size: 16, color: GREY })]
        })]
      })
    ]})]
  }));
  children.push(spacer(200));

  // Billable Line Items
  children.push(p("Billable Services", { bold: true, size: 20, color: BLUE, spacing: { after: 100 } }));
  children.push(makeTable(
    ["Date", "Role / POD", "Type", "Hours", "Rate", "Sub-Total"],
    [
      ["[DATE]", "IRV-TS1 — Tech Support", "Onsite (N)", "2.00", "$150.00/hr", "$300.00"],
      ["[DATE]", "IRV-AD1 — CTO", "Onsite (AH)", "1.50", "$400.00/hr", "$600.00"],
    ],
    [1100, 2400, 1200, 900, 1400, 1400]
  ));
  children.push(spacer(100));

  // Ticket Details
  children.push(p("Ticket Details", { bold: true, size: 20, color: BLUE, spacing: { after: 100 } }));
  children.push(makeTable(
    ["Date", "Ticket Title", "Resource", "Role", "Hours", "Notes"],
    [
      ["[DATE]", "[Ticket title]", "[Resource Name]", "IRV-TS1 (N)", "2.00", "[Work description]"],
      ["[DATE]", "[Ticket title]", "[Resource Name]", "IRV-AD1 (AH)", "1.50", "[Work description]"],
    ],
    [1100, 2200, 1400, 1200, 800, 2600]
  ));
  children.push(spacer(200));

  children.push(totalsBlock("$900.00", undefined, "$900.00", "$900.00"));
  children.push(spacer(200));
  children.push(...wireInfoBlock());

  // Terms & Conditions
  children.push(spacer(300));
  children.push(paymentTermsBox("[MSA-XXXX]", true));

  return children;
}


// =====================================================================
// INVOICE TYPE 5: EQUIPMENT / PRODUCT INVOICE
// =====================================================================
function generateEquipmentInvoice() {
  const children = [];

  children.push(invoiceTitleBar("INVOICE"));
  children.push(spacer(80));
  children.push(msaRefBar("[MSA-XXXX]", null));
  children.push(spacer(200));

  children.push(billToBlock(
    { name: "[CLIENT NAME]", company: "[COMPANY]", address: "[CLIENT ADDRESS]", cityStateZip: "[CITY, STATE ZIP]" },
    { number: "[INV-XXXX]", date: "[DATE]", due: "[DUE DATE]", msaRef: "[MSA-XXXX]" }
  ));
  children.push(spacer(200));

  // 20 Line Items to test multipage flow
  children.push(p("Products & Equipment", { bold: true, size: 20, color: BLUE, spacing: { after: 100 } }));
  children.push(makeTable(
    ["Item", "Description", "Qty", "Unit Price", "Tax", "Sub-Total"],
    [
      ["Laptop",        "Dell Pro 14 Laptop",                          "3.00",  "$1,178.67", "X", "$3,536.01"],
      ["Laptop",        "Dell Latitude 5550 Laptop",                   "2.00",  "$1,342.00", "X", "$2,684.00"],
      ["Monitor",       "INNOCN 27\" 4K USB-C Monitor",                "6.00",  "$237.49",   "X", "$1,424.94"],
      ["Monitor",       "Dell P2723QE 27\" 4K USB-C Hub Monitor",      "2.00",  "$389.99",   "X", "$779.98"],
      ["Accessories",   "Dell Pro Thunderbolt 4 Smart Dock SD25TB4",   "5.00",  "$307.83",   "X", "$1,539.15"],
      ["Accessories",   "Dell USB-C Mobile Adapter DA310",             "3.00",  "$69.99",    "X", "$209.97"],
      ["Accessories",   "Logitech MX Master 3S Mouse",                "5.00",  "$99.99",    "X", "$499.95"],
      ["Accessories",   "Logitech MX Keys S Keyboard",                "5.00",  "$109.99",   "X", "$549.95"],
      ["Accessories",   "Dell Pro Slim Briefcase 15",                  "5.00",  "$39.99",    "X", "$199.95"],
      ["Headset",       "Jabra Evolve2 75 UC Wireless Headset",        "3.00",  "$299.00",   "X", "$897.00"],
      ["Webcam",        "Logitech Brio 4K Ultra HD Webcam",            "2.00",  "$169.99",   "X", "$339.98"],
      ["UPS",           "APC Back-UPS Pro 1500VA",                     "2.00",  "$249.99",   "X", "$499.98"],
      ["Network",       "Ubiquiti UniFi U6 Pro Access Point",          "4.00",  "$149.00",   "X", "$596.00"],
      ["Network",       "Ubiquiti USW-Pro-24-PoE Switch",              "1.00",  "$699.00",   "X", "$699.00"],
      ["Storage",       "Samsung 870 EVO 1TB SSD (upgrade)",           "3.00",  "$89.99",    "X", "$269.97"],
      ["Memory",        "Crucial 32GB DDR5 Kit (upgrade)",             "2.00",  "$124.99",   "X", "$249.98"],
      ["Software",      "Microsoft Office 2024 LTSC Standard",         "5.00",  "$249.99",   "",  "$1,249.95"],
      ["CED - 15 to 34","E-Recycling Fee — Laptops",                  "5.00",  "$7.00",     "",  "$35.00"],
      ["CED - 15 to 34","E-Recycling Fee — Monitors",                 "8.00",  "$7.00",     "",  "$56.00"],
      ["Shipping",      "Freight & Handling",                           "1.00",  "$185.00",   "",  "$185.00"],
    ],
    [1000, 3000, 800, 1200, 600, 1200]
  ));
  children.push(spacer(60));
  children.push(p("Title to equipment remains with Technijian until paid in full per MSA Section 3.09. Items marked \"X\" in the Tax column are subject to applicable sales tax.", { italics: true, size: 14, color: GREY }));
  children.push(spacer(100));

  // Totals
  children.push(totalsBlock("$16,500.76", "$1,148.46", "$17,649.22", "$17,649.22"));
  children.push(spacer(200));
  children.push(...wireInfoBlock());

  // Terms & Conditions
  children.push(spacer(300));
  children.push(paymentTermsBox("[MSA-XXXX]", true));

  // Product detail pages
  children.push(new Paragraph({ children: [new PageBreak()] }));
  children.push(invoiceTitleBar("PRODUCT SPECIFICATIONS"));
  children.push(spacer(200));

  // Spec 1 — Dell Pro 14
  children.push(p("Dell Pro 14 Laptop (Qty: 3)", { bold: true, size: 22, color: CHARCOAL, spacing: { after: 80 } }));
  [
    "Intel Core 7 150U (10 Core, Up to 5.40GHz, 12MB Cache, 15W)",
    "512GB PCIe M.2 NVMe Gen 4 Class 25 QLC Solid State Drive",
    "16GB (1X16GB) Up to 5600MT/s DDR5 SoDIMM Non-ECC",
    "Intel Integrated Graphics",
    "Windows 11 Pro",
    "14 inch FHD+ (1920 x 1200) Anti-Glare 300-nits 45% NTSC Non-Touch Display",
    "US English Single Pointing Backlit Copilot key Keyboard",
    "Intel Wi-Fi 6E 2x2 AX211 Wireless Card",
    "FHD IR Camera and Microphone",
    "3-Cell, 55 WHr Lithium Ion Battery (Express Charge Capable)"
  ].forEach(s => children.push(p("  •  " + s, { size: 16, color: GREY, spacing: { after: 40 } })));
  children.push(spacer(200));

  // Spec 2 — Dell Latitude 5550
  children.push(p("Dell Latitude 5550 Laptop (Qty: 2)", { bold: true, size: 22, color: CHARCOAL, spacing: { after: 80 } }));
  [
    "Intel Core Ultra 7 155U vPro (12 Core, Up to 4.80GHz, 12MB Cache)",
    "512GB PCIe M.2 NVMe Gen 4 Class 40 SSD",
    "16GB (2X8GB) DDR5 5600MT/s Non-ECC",
    "Intel Integrated Graphics",
    "Windows 11 Pro",
    "15.6 inch FHD (1920 x 1080) Anti-Glare 250-nits Non-Touch IPS Display",
    "Intel Wi-Fi 6E AX211 2x2 + Bluetooth 5.3",
    "FHD IR Camera with Microphone, Privacy Shutter",
    "4-Cell, 54 WHr Lithium Ion Battery (Express Charge Capable)",
    "3 Year ProSupport Plus with Next Business Day Onsite"
  ].forEach(s => children.push(p("  •  " + s, { size: 16, color: GREY, spacing: { after: 40 } })));
  children.push(spacer(200));

  // Spec 3 — Monitors
  children.push(p("INNOCN 27\" 4K USB-C Monitor (Qty: 6)", { bold: true, size: 22, color: CHARCOAL, spacing: { after: 80 } }));
  [
    "27 inch IPS 4K UHD (3840 x 2160) Display",
    "USB-C PD 96W — single cable power + video for laptops",
    "HDR400 / 99% sRGB / 350 nits brightness",
    "Height Adjustable Stand, Pivot, Tilt, Swivel",
    "2x HDMI 2.0, 1x DisplayPort 1.4, 1x USB-C, 2x USB-A downstream",
    "VESA 100x100mm Mount Compatible"
  ].forEach(s => children.push(p("  •  " + s, { size: 16, color: GREY, spacing: { after: 40 } })));
  children.push(spacer(200));

  // Spec 4 — Dell Monitors
  children.push(p("Dell P2723QE 27\" 4K USB-C Hub Monitor (Qty: 2)", { bold: true, size: 22, color: CHARCOAL, spacing: { after: 80 } }));
  [
    "27 inch IPS 4K UHD (3840 x 2160) Display",
    "USB-C PD 90W Hub with RJ45 Ethernet pass-through",
    "99% sRGB / 350 nits / Anti-Glare 3H Coating",
    "Height Adjustable Stand, Pivot, Tilt, Swivel",
    "1x USB-C upstream, 1x HDMI, 1x DP 1.4, 4x USB-A, 1x RJ45",
    "VESA 100x100mm Mount Compatible",
    "Dell 3 Year Advanced Exchange Service"
  ].forEach(s => children.push(p("  •  " + s, { size: 16, color: GREY, spacing: { after: 40 } })));
  children.push(spacer(200));

  // Spec 5 — Network
  children.push(p("Ubiquiti UniFi U6 Pro Access Point (Qty: 4)", { bold: true, size: 22, color: CHARCOAL, spacing: { after: 80 } }));
  [
    "WiFi 6 (802.11ax) Dual-Band — 2.4 GHz / 5 GHz",
    "5 GHz: 4x4 MU-MIMO, up to 4.8 Gbps throughput",
    "2.4 GHz: 2x2 MIMO, up to 573 Mbps throughput",
    "PoE powered (802.3at PoE+), no separate power adapter needed",
    "300+ concurrent client capacity",
    "Managed via UniFi Network Controller",
    "Ceiling/Wall mountable with included hardware"
  ].forEach(s => children.push(p("  •  " + s, { size: 16, color: GREY, spacing: { after: 40 } })));
  children.push(spacer(200));

  // Spec 6 — Switch
  children.push(p("Ubiquiti USW-Pro-24-PoE Switch (Qty: 1)", { bold: true, size: 22, color: CHARCOAL, spacing: { after: 80 } }));
  [
    "24x Gigabit RJ45 ports with 802.3at/af PoE+ (400W total PoE budget)",
    "2x 10G SFP+ uplink ports",
    "Layer 3 switching with inter-VLAN routing",
    "Managed via UniFi Network Controller",
    "1.3 inch touchscreen for status/management",
    "Rack-mountable 1U form factor"
  ].forEach(s => children.push(p("  •  " + s, { size: 16, color: GREY, spacing: { after: 40 } })));

  return children;
}


// ===== MAIN: Generate all 5 invoice templates =====
async function main() {
  const outputDir = __dirname;

  const invoiceTypes = [
    { name: "INV-Template-Monthly-Service", gen: generateMonthlyServiceInvoice, msa: true, msaRef: "[MSA-XXXX]" },
    { name: "INV-Template-Recurring-Subscription", gen: generateRecurringSubscriptionInvoice, msa: true, msaRef: "[MSA-XXXX]" },
    { name: "INV-Template-Weekly-InContract", gen: generateWeeklyInContractInvoice, msa: true, msaRef: "[MSA-XXXX]" },
    { name: "INV-Template-Weekly-OutOfContract", gen: generateWeeklyOutOfContractInvoice, msa: true, msaRef: "[MSA-XXXX]" },
    { name: "INV-Template-Equipment", gen: generateEquipmentInvoice, msa: true, msaRef: "[MSA-XXXX]" },
  ];

  for (const inv of invoiceTypes) {
    const doc = new Document({
      styles: {
        default: { document: { run: { font: FONT, size: 20, color: GREY } } }
      },
      sections: [{
        properties: invoiceSectionProps(),
        children: inv.gen()
      }]
    });

    const buffer = await Packer.toBuffer(doc);
    const outPath = path.join(outputDir, `${inv.name}.docx`);
    fs.writeFileSync(outPath, buffer);
    console.log(`Generated: ${outPath}`);
  }

  console.log("\nAll 5 invoice templates generated successfully.");
}

main().catch(err => { console.error(err); process.exit(1); });
