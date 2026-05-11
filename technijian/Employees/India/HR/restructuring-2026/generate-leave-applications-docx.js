/**
 * Generates 3 one-page Earned Leave applications as DOCX files for the
 * EL-burn employees (Yogesh Kumar, Rahul Uniyal, Suresh Kumar Sharma).
 *
 * Each form is the employee's leave application for May 11 - May 31, 2026.
 * Employees sign on Monday May 11 when their termination/retrenchment letter
 * is handed over.
 *
 * Run from tech-legal/technijian/india/hr/restructuring-2026/:
 *   node generate-leave-applications-docx.js
 *
 * Output: leave-applications/ folder -- one .docx per employee
 *
 * Letterhead: India (Technijian IT Services Pvt. Ltd., Panchkula)
 */

const fs   = require('fs');
const path = require('path');

const docxRoot = 'C:/vscode/tech-branding/tech-branding/node_modules';
const docx = require(path.join(docxRoot, 'docx'));

const {
  Document, Packer, Paragraph, TextRun, AlignmentType,
  Table, TableRow, TableCell, WidthType, BorderStyle,
  Header, Footer, ImageRun, PageNumber,
  ShadingType,
} = docx;

// Brand constants (match termination-letter generator)
const CORE_BLUE     = '006DB6';
const CORE_ORANGE   = 'F67D4B';
const DARK_CHARCOAL = '1A1A2E';
const BRAND_GREY    = '59595B';
const LIGHT_GREY    = 'E9ECEF';
const WHITE         = 'FFFFFF';

const LOGO_PATH = 'C:/vscode/tech-branding/tech-branding/assets/logos/png/technijian-logo-full-color-600x125.png';
const OUT_DIR   = path.join(__dirname, 'leave-applications');

if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR, { recursive: true });

const T = (text, opts = {}) => new TextRun({
  text,
  font: 'Calibri',
  size: opts.size ?? 22,
  color: opts.color ?? BRAND_GREY,
  bold: opts.bold ?? false,
  italics: opts.italic ?? false,
  underline: opts.underline ? {} : undefined,
});

const P = (children, opts = {}) => new Paragraph({
  children: Array.isArray(children) ? children : [children],
  spacing: { before: opts.before ?? 0, after: opts.after ?? 160 },
  alignment: opts.align ?? AlignmentType.LEFT,
});

const blankLine = () => P([T('')], { after: 80 });

function buildHeader() {
  const logoBuf = fs.readFileSync(LOGO_PATH);
  const borderNone = {
    top:    { style: BorderStyle.NONE, size: 0, color: WHITE },
    bottom: { style: BorderStyle.NONE, size: 0, color: WHITE },
    left:   { style: BorderStyle.NONE, size: 0, color: WHITE },
    right:  { style: BorderStyle.NONE, size: 0, color: WHITE },
    insideHorizontal: { style: BorderStyle.NONE, size: 0, color: WHITE },
    insideVertical:   { style: BorderStyle.NONE, size: 0, color: WHITE },
  };

  const headerTable = new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    rows: [new TableRow({ children: [
      new TableCell({
        children: [new Paragraph({ children: [new ImageRun({ data: logoBuf, transformation: { width: 180, height: 38 } })] })],
        width: { size: 50, type: WidthType.PERCENTAGE },
      }),
      new TableCell({
        children: [
          new Paragraph({ alignment: AlignmentType.RIGHT, children: [new TextRun({ text: 'TECHNIJIAN IT SERVICES PVT. LTD.', font: 'Calibri', size: 18, bold: true, color: DARK_CHARCOAL })] }),
          new Paragraph({ alignment: AlignmentType.RIGHT, children: [new TextRun({ text: 'Twin Tower, Plot no 7, Sector 22', font: 'Calibri', size: 15, color: BRAND_GREY })] }),
          new Paragraph({ alignment: AlignmentType.RIGHT, children: [new TextRun({ text: 'IT Park, Panchkula 134109, Haryana, India', font: 'Calibri', size: 15, color: BRAND_GREY })] }),
          new Paragraph({ alignment: AlignmentType.RIGHT, children: [new TextRun({ text: 'india@technijian.com  |  technijian.com', font: 'Calibri', size: 15, color: CORE_BLUE })] }),
        ],
        width: { size: 50, type: WidthType.PERCENTAGE },
      }),
    ]})],
    borders: borderNone,
  });

  const blueBar = new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    rows: [new TableRow({ children: [new TableCell({ children: [new Paragraph({ children: [new TextRun('')] })], shading: { type: ShadingType.SOLID, color: CORE_BLUE, fill: CORE_BLUE } })], height: { value: 40, rule: 'exact' } })],
    borders: borderNone,
  });
  const orangeBar = new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    rows: [new TableRow({ children: [new TableCell({ children: [new Paragraph({ children: [new TextRun('')] })], shading: { type: ShadingType.SOLID, color: CORE_ORANGE, fill: CORE_ORANGE } })], height: { value: 60, rule: 'exact' } })],
    borders: borderNone,
  });

  return new Header({ children: [
    headerTable, blueBar, orangeBar,
    new Paragraph({ children: [new TextRun('')], spacing: { before: 0, after: 80 } }),
  ]});
}

function buildFooter() {
  return new Footer({ children: [
    new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 60, after: 0 }, children: [new TextRun({ text: 'TECHNIJIAN IT SERVICES PVT. LTD.', font: 'Calibri', size: 14, color: BRAND_GREY })] }),
    new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 20, after: 0 }, children: [new TextRun({ text: 'Twin Tower, Plot no 7, Sector 22, IT Park, Panchkula 134109  |  india@technijian.com', font: 'Calibri', size: 13, color: BRAND_GREY })] }),
    new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 20, after: 0 }, children: [
      new TextRun({ text: 'Page ', font: 'Calibri', size: 13, color: BRAND_GREY }),
      new TextRun({ children: [PageNumber.CURRENT], font: 'Calibri', size: 13, color: BRAND_GREY }),
      new TextRun({ text: '  |  CONFIDENTIAL', font: 'Calibri', size: 13, italics: true, color: BRAND_GREY }),
    ]}),
  ]});
}

const employees = [
  {
    filename:    '01-Yogesh-Kumar-Leave-Application.docx',
    name:        'Yogesh Kumar',
    designation: 'Customer Support Engineer',
    department:  'Customer Support Engineering (CSE)',
    empNo:       'TIPL-CSE-2022-05',
    hours:       17.61,
    daysApprox:  '2.20',
  },
  {
    filename:    '02-Rahul-Uniyal-Leave-Application.docx',
    name:        'Rahul Uniyal',
    designation: 'Customer Support Engineer',
    department:  'Customer Support Engineering (CSE)',
    empNo:       'TIPL-CSE-2022-06',
    hours:       89.16,
    daysApprox:  '11.15',
  },
  {
    filename:    '03-Suresh-Kumar-Sharma-Leave-Application.docx',
    name:        'Suresh Kumar Sharma',
    designation: 'Customer Support Engineer',
    department:  'Customer Support Engineering (CSE)',
    empNo:       'TIPL-CSE-2025-04',
    hours:       49.13,
    daysApprox:  '6.14',
  },
];

function buildBody(emp) {
  const para = (txt, opts = {}) => P([T(txt, { size: opts.size ?? 22, color: opts.color ?? DARK_CHARCOAL, bold: opts.bold ?? false })], { after: opts.after ?? 200 });

  const fieldRow = (label, value, valueBold = false) => new Paragraph({
    children: [
      new TextRun({ text: label, font: 'Calibri', size: 22, color: BRAND_GREY }),
      new TextRun({ text: value, font: 'Calibri', size: 22, color: DARK_CHARCOAL, bold: valueBold }),
    ],
    spacing: { before: 0, after: 120 },
  });

  return [
    // Title
    P([T('APPLICATION FOR EARNED LEAVE', { size: 28, bold: true, color: CORE_BLUE })], { align: AlignmentType.CENTER, after: 280 }),

    // Date
    fieldRow('Date: ', 'May 11, 2026', true),
    blankLine(),

    // To block
    para('To,', { after: 0 }),
    para('The Director', { after: 0 }),
    para('Technijian IT Services Pvt. Ltd.', { after: 0 }),
    para('Twin Tower, Plot no 7, Sector 22', { after: 0 }),
    para('IT Park, Panchkula 134109, Haryana', { after: 200 }),

    // Subject
    P([
      new TextRun({ text: 'Subject: ', font: 'Calibri', size: 22, bold: true, color: DARK_CHARCOAL }),
      new TextRun({ text: `Application for Earned Leave (May 11 - May 31, 2026) - Full Accrued Balance`, font: 'Calibri', size: 22, bold: true, color: DARK_CHARCOAL }),
    ], { after: 240 }),

    // Salutation
    para('Dear Sir / Madam,'),

    // Body sentence
    new Paragraph({
      children: [
        new TextRun({ text: 'I, ', font: 'Calibri', size: 22, color: DARK_CHARCOAL }),
        new TextRun({ text: emp.name, font: 'Calibri', size: 22, color: DARK_CHARCOAL, bold: true }),
        new TextRun({ text: ', Employee No. ', font: 'Calibri', size: 22, color: DARK_CHARCOAL }),
        new TextRun({ text: emp.empNo, font: 'Calibri', size: 22, color: DARK_CHARCOAL, bold: true }),
        new TextRun({ text: `, working as ${emp.designation} in the ${emp.department}, hereby apply to utilize my entire accrued Earned Leave (EL) balance of `, font: 'Calibri', size: 22, color: DARK_CHARCOAL }),
        new TextRun({ text: `${emp.hours.toFixed(2)} hours (approximately ${emp.daysApprox} working days)`, font: 'Calibri', size: 22, color: DARK_CHARCOAL, bold: true }),
        new TextRun({ text: ', together with any May 2026 accrual, as paid leave during the notice period (May 11 - May 31, 2026).', font: 'Calibri', size: 22, color: DARK_CHARCOAL }),
      ],
      spacing: { before: 0, after: 240 },
    }),

    // Details block (compact)
    fieldRow('Leave period: ', 'From May 11, 2026 through May 31, 2026', true),
    fieldRow('Accrued balance (April 2026 payroll): ', `${emp.hours.toFixed(2)} hours (~${emp.daysApprox} days)`, true),
    fieldRow('Type of leave: ', 'Earned Leave (EL) - full accrued balance, paid during notice', false),

    P([T('Kindly approve this leave application. I will return any company equipment in my possession on or before May 31, 2026 as instructed.')], { after: 120, before: 120 }),

    P([T('Thanking you,')], { after: 100 }),
    P([T('Yours sincerely,')], { after: 360 }),

    // Employee signature line
    P([T('________________________________________', { color: DARK_CHARCOAL, size: 22 })], { after: 40 }),
    P([T(emp.name, { color: DARK_CHARCOAL, size: 22, bold: true })], { after: 0 }),
    P([T(`${emp.designation}  |  Employee No. ${emp.empNo}  |  Date: ____________________`, { color: BRAND_GREY, size: 18 })], { after: 160 }),

    // ── Director approval block (Ravi's signature stamped above the line) ──
    new Paragraph({
      children: [],
      border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: LIGHT_GREY } },
      spacing: { before: 40, after: 80 },
    }),
    P([T('APPROVED BY DIRECTOR', { color: CORE_BLUE, size: 20, bold: true })], { after: 80 }),

    // Spacer for stamped signature (~40pt tall, needs ~600 EMU of clearance)
    P([T('')], { after: 600 }),

    P([T('________________________________________', { color: DARK_CHARCOAL, size: 22 })], { after: 40 }),
    P([T('Ravi  |  Director  |  Technijian IT Services Pvt. Ltd.  |  May 11, 2026', { color: DARK_CHARCOAL, size: 18, bold: true })], { after: 160 }),

    // ── Handover and witness block (single line, compact) ──
    new Paragraph({
      children: [],
      border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: LIGHT_GREY } },
      spacing: { before: 40, after: 80 },
    }),
    P([T('DELIVERED IN PERSON  -  May 11, 2026', { color: CORE_BLUE, size: 18, bold: true })], { after: 80 }),

    // Side-by-side handover + witness, tight spacing
    new Table({
      width: { size: 100, type: WidthType.PERCENTAGE },
      rows: [new TableRow({ children: [
        new TableCell({
          children: [
            new Paragraph({ children: [new TextRun({ text: 'Handed over by:', font: 'Calibri', size: 18, color: BRAND_GREY })], spacing: { after: 240 } }),
            new Paragraph({ children: [new TextRun({ text: '_________________________', font: 'Calibri', size: 20, color: DARK_CHARCOAL })], spacing: { after: 20 } }),
            new Paragraph({ children: [new TextRun({ text: 'Ajay Bhardwaj  -  Team Lead', font: 'Calibri', size: 18, bold: true, color: DARK_CHARCOAL })], spacing: { after: 0 } }),
            new Paragraph({ children: [new TextRun({ text: 'Time: ___________', font: 'Calibri', size: 18, color: BRAND_GREY })], spacing: { after: 0 } }),
          ],
          width: { size: 50, type: WidthType.PERCENTAGE },
        }),
        new TableCell({
          children: [
            new Paragraph({ children: [new TextRun({ text: 'Witnessed by:', font: 'Calibri', size: 18, color: BRAND_GREY })], spacing: { after: 240 } }),
            new Paragraph({ children: [new TextRun({ text: '_________________________', font: 'Calibri', size: 20, color: DARK_CHARCOAL })], spacing: { after: 20 } }),
            new Paragraph({ children: [new TextRun({ text: 'Gurdeep Kumar  -  Team Lead', font: 'Calibri', size: 18, bold: true, color: DARK_CHARCOAL })], spacing: { after: 0 } }),
            new Paragraph({ children: [new TextRun({ text: 'Time: ___________', font: 'Calibri', size: 18, color: BRAND_GREY })], spacing: { after: 0 } }),
          ],
          width: { size: 50, type: WidthType.PERCENTAGE },
        }),
      ]})],
      borders: {
        top: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
        bottom: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
        left: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
        right: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
        insideHorizontal: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
        insideVertical: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
      },
    }),
  ];
}

async function generate(emp) {
  const doc = new Document({
    creator: 'Technijian IT Services Pvt. Ltd.',
    title:   `Leave Application - ${emp.name}`,
    styles:  { default: { document: { run: { font: 'Calibri', size: 22 } } } },
    sections: [{
      headers: { default: buildHeader() },
      footers: { default: buildFooter() },
      properties: { page: { margin: { top: 1080, bottom: 720, left: 720, right: 720 } } },
      children: buildBody(emp),
    }],
  });

  const outPath = path.join(OUT_DIR, emp.filename);
  const buf = await Packer.toBuffer(doc);
  fs.writeFileSync(outPath, buf);
  console.log(`  [+] ${emp.filename}  (${(buf.length / 1024).toFixed(1)} KB)`);
}

(async () => {
  console.log('Generating leave applications...');
  for (const emp of employees) {
    await generate(emp);
  }
  console.log(`\nDone. ${employees.length} leave applications written to ${OUT_DIR}`);
})();
