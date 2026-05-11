/**
 * Generates 6 individual termination / retrenchment letters as DOCX files.
 *
 * Run from tech-legal/technijian/india/hr/restructuring-2026/:
 *   node generate-letters-docx.js
 *
 * Output: letters/ folder — one .docx per employee
 *
 * Letterhead: India (Technijian IT Services Pvt. Ltd., Panchkula)
 * Notice date: May 11, 2026 (Monday)
 * Last working day: May 31, 2026
 * Settlement: June 1, 2026
 */

const fs   = require('fs');
const path = require('path');

const docxRoot = 'C:/vscode/tech-branding/tech-branding/node_modules';
const docx = require(path.join(docxRoot, 'docx'));

const {
  Document, Packer, Paragraph, TextRun, AlignmentType,
  Table, TableRow, TableCell, WidthType, BorderStyle,
  Header, Footer, ImageRun, PageNumber, PageOrientation,
  ShadingType,
} = docx;

// ─── BRAND CONSTANTS ──────────────────────────────────────────────────────
const CORE_BLUE     = '006DB6';
const CORE_ORANGE   = 'F67D4B';
const DARK_CHARCOAL = '1A1A2E';
const BRAND_GREY    = '59595B';
const LIGHT_GREY    = 'E9ECEF';
const OFF_WHITE     = 'F8F9FA';
const WHITE         = 'FFFFFF';

const LOGO_PATH = 'C:/vscode/tech-branding/tech-branding/assets/logos/png/technijian-logo-full-color-600x125.png';
const OUT_DIR   = path.join(__dirname, 'letters');

// ─── HELPERS ──────────────────────────────────────────────────────────────
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

const HR = () => new Paragraph({
  children: [],
  border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: LIGHT_GREY } },
  spacing: { before: 60, after: 120 },
});

const blankLine = () => P([T('')], { after: 80 });

const cell = (text, opts = {}) => new TableCell({
  children: [new Paragraph({
    children: [new TextRun({ text: String(text), font: 'Calibri', size: opts.size ?? 20, bold: opts.bold ?? false, color: opts.color ?? (opts.header ? WHITE : DARK_CHARCOAL) })],
    alignment: opts.align ?? AlignmentType.LEFT,
    spacing: { before: 40, after: 40 },
  })],
  shading: opts.header ? { type: ShadingType.SOLID, color: CORE_BLUE, fill: CORE_BLUE } :
           opts.alt    ? { type: ShadingType.SOLID, color: OFF_WHITE, fill: OFF_WHITE } : undefined,
  width: opts.width ? { size: opts.width, type: WidthType.DXA } : undefined,
});

const settTable = (rows) => new Table({
  width: { size: 100, type: WidthType.PERCENTAGE },
  rows: rows.map((row, ri) => new TableRow({
    children: row.map((c) => {
      const isHeader = ri === 0;
      const isAlt    = !isHeader && ri % 2 === 0;
      return cell(c.text ?? c, { header: isHeader, alt: isAlt, bold: isHeader || (c.opts && c.opts.bold), ...c.opts });
    }),
  })),
  borders: { top: { style: BorderStyle.SINGLE, size: 4, color: LIGHT_GREY }, bottom: { style: BorderStyle.SINGLE, size: 4, color: LIGHT_GREY }, left: { style: BorderStyle.SINGLE, size: 4, color: LIGHT_GREY }, right: { style: BorderStyle.SINGLE, size: 4, color: LIGHT_GREY }, insideHorizontal: { style: BorderStyle.SINGLE, size: 2, color: LIGHT_GREY }, insideVertical: { style: BorderStyle.SINGLE, size: 2, color: LIGHT_GREY } },
});

// ─── INDIA HEADER ──────────────────────────────────────────────────────────
function buildHeader() {
  const logoBuf = fs.readFileSync(LOGO_PATH);
  const borderNone = { top: { style: BorderStyle.NONE, size: 0, color: WHITE }, bottom: { style: BorderStyle.NONE, size: 0, color: WHITE }, left: { style: BorderStyle.NONE, size: 0, color: WHITE }, right: { style: BorderStyle.NONE, size: 0, color: WHITE }, insideHorizontal: { style: BorderStyle.NONE, size: 0, color: WHITE }, insideVertical: { style: BorderStyle.NONE, size: 0, color: WHITE } };

  const headerTable = new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    rows: [new TableRow({ children: [
      new TableCell({ children: [new Paragraph({ children: [new ImageRun({ data: logoBuf, transformation: { width: 180, height: 38 } })] })], width: { size: 50, type: WidthType.PERCENTAGE } }),
      new TableCell({ children: [
        new Paragraph({ alignment: AlignmentType.RIGHT, children: [new TextRun({ text: 'TECHNIJIAN IT SERVICES PVT. LTD.', font: 'Calibri', size: 18, bold: true, color: DARK_CHARCOAL })] }),
        new Paragraph({ alignment: AlignmentType.RIGHT, children: [new TextRun({ text: 'Twin Tower, Plot no 7, Sector 22', font: 'Calibri', size: 15, color: BRAND_GREY })] }),
        new Paragraph({ alignment: AlignmentType.RIGHT, children: [new TextRun({ text: 'IT Park, Panchkula 134109, Haryana, India', font: 'Calibri', size: 15, color: BRAND_GREY })] }),
        new Paragraph({ alignment: AlignmentType.RIGHT, children: [new TextRun({ text: 'india@technijian.com  |  technijian.com', font: 'Calibri', size: 15, color: CORE_BLUE })] }),
      ], width: { size: 50, type: WidthType.PERCENTAGE } }),
    ]})],
    borders: borderNone,
  });

  const blueBar = new Table({ width: { size: 100, type: WidthType.PERCENTAGE }, rows: [new TableRow({ children: [new TableCell({ children: [new Paragraph({ children: [new TextRun('')] })], shading: { type: ShadingType.SOLID, color: CORE_BLUE, fill: CORE_BLUE } })], height: { value: 40, rule: 'exact' } })], borders: borderNone });
  const orangeBar = new Table({ width: { size: 100, type: WidthType.PERCENTAGE }, rows: [new TableRow({ children: [new TableCell({ children: [new Paragraph({ children: [new TextRun('')] })], shading: { type: ShadingType.SOLID, color: CORE_ORANGE, fill: CORE_ORANGE } })], height: { value: 60, rule: 'exact' } })], borders: borderNone });

  return new Header({ children: [headerTable, blueBar, orangeBar, new Paragraph({ children: [new TextRun('')], spacing: { before: 0, after: 80 } })] });
}

function buildFooter() {
  return new Footer({ children: [
    new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 60, after: 0 }, children: [new TextRun({ text: 'TECHNIJIAN IT SERVICES PVT. LTD.  |  Managed IT  -  Cybersecurity  -  Cloud  -  AI Development  -  Compliance', font: 'Calibri', size: 14, color: BRAND_GREY })] }),
    new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 20, after: 0 }, children: [new TextRun({ text: 'Twin Tower, Plot no 7, Sector 22, IT Park, Panchkula 134109  |  india@technijian.com  |  U.S. Parent: 18 Technology Dr., Ste 141, Irvine, CA 92618', font: 'Calibri', size: 13, color: BRAND_GREY })] }),
    new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 20, after: 0 }, children: [
      new TextRun({ text: 'Page ', font: 'Calibri', size: 13, color: BRAND_GREY }),
      new TextRun({ children: [PageNumber.CURRENT], font: 'Calibri', size: 13, color: BRAND_GREY }),
      new TextRun({ text: '  |  CONFIDENTIAL', font: 'Calibri', size: 13, italics: true, color: BRAND_GREY }),
    ]}),
  ]});
}

// ─── EMPLOYEE DATA ──────────────────────────────────────────────────────────
const employees = [
  {
    filename: '01-Devesh-Bhattacharya-Termination.docx',
    name:         'Devesh Bhattacharya',
    designation:  'Customer Support Engineer',
    department:   'Customer Support Engineering (CSE)',
    hireDate:     'April 1, 2026',
    empNo:        'TIPL-CSE-2026-01',
    pathway:      'probation',
    settlement: [
      ['Component', 'Amount (INR)', 'Notes'],
      ['May 2026 Salary (pro-rata through May 31, 2026)', 'Rs. 50,000', 'Full month; access revoked May 11'],
      ['Notice pay-in-lieu', 'Rs. 0', 'No notice required during probation period'],
      ['Retrenchment compensation', 'Rs. 0', 'Tenure < 1 year; not applicable'],
      ['Earned Leave (EL) encashment', 'Rs. 0', 'No EL accrued during probation'],
      [{ text: 'Total Full and Final Settlement', opts: { bold: true } }, { text: 'Rs. 50,000', opts: { bold: true } }, { text: 'Payable June 1, 2026', opts: { bold: true } }],
    ],
    body: null,
  },
  // Rajat Kumar — see generate-rajat-msa-docx.js (resigned via Mutual Separation Agreement)
  {
    filename: '03-Aditya-Saraf-Termination.docx',
    name:         'Aditya Saraf',
    designation:  'Customer Support Engineer Lead',
    department:   'Customer Support Engineering (CSE)',
    hireDate:     'January 10, 2026',
    empNo:        'TIPL-CSE-2026-03',
    pathway:      'non-worker',
    settlement: [
      ['Component', 'Amount (INR)', 'Notes'],
      ['May 2026 Salary', 'Rs. 70,000', 'Full month payroll'],
      ['Notice pay-in-lieu (10 days)', 'Rs. 23,333', '10 days x Rs.70,000/30'],
      ['Retrenchment compensation', 'Rs. 0', 'Supervisory / non-worker classification; not applicable'],
      ['Earned Leave (EL) encashment', 'Rs. 0', 'Balance as per payroll records'],
      [{ text: 'Total Full and Final Settlement', opts: { bold: true } }, { text: 'Rs. 93,333', opts: { bold: true } }, { text: 'Payable June 1, 2026', opts: { bold: true } }],
    ],
    body: null,
  },
  {
    filename: '04-Suresh-Kumar-Sharma-Termination.docx',
    name:         'Suresh Kumar Sharma',
    designation:  'Customer Support Engineer',
    department:   'Customer Support Engineering (CSE)',
    hireDate:     'June 9, 2025',
    empNo:        'TIPL-CSE-2025-04',
    pathway:      'post-probation',
    elBurnNote:   'Your accrued Earned Leave (EL) balance as of April 2026 payroll is 49.13 hours (approximately 6.14 working days). This balance, together with any May 2026 accrual, will be fully utilized as paid leave during the notice period (May 11 to May 31, 2026). A pre-filled leave application is provided to you with this notice for signature. Upon full utilization of your EL balance during the notice period, no separate EL encashment will be payable.',
    settlement: [
      ['Component', 'Amount (INR)', 'Notes'],
      ['May 2026 Salary', 'Rs. 40,000', 'Full month payroll'],
      ['Notice pay-in-lieu (10 days shortfall)', 'Rs. 13,333', '10 days x Rs.40,000 / 30'],
      ['Retrenchment compensation', 'Rs. 0', 'Tenure < 1 year; not applicable'],
      ['Earned Leave (EL) encashment', 'Rs. 0', 'Fully utilized during notice period (49.13 hrs per April 2026 payslip)'],
      [{ text: 'Total Full and Final Settlement', opts: { bold: true } }, { text: 'Rs. 53,333', opts: { bold: true } }, { text: 'Payable June 1, 2026', opts: { bold: true } }],
    ],
    body: null,
  },
  {
    filename: '05-Yogesh-Kumar-Retrenchment.docx',
    name:         'Yogesh Kumar',
    designation:  'Customer Support Engineer',
    department:   'Customer Support Engineering (CSE)',
    hireDate:     'June 1, 2022',
    empNo:        'TIPL-CSE-2022-05',
    pathway:      'retrenchment',
    elBurnNote:   'Your accrued Earned Leave (EL) balance as of April 2026 payroll is 17.61 hours (approximately 2.20 working days). This balance, together with any May 2026 accrual, will be fully utilized as paid leave during the notice period (May 11 to May 31, 2026). A pre-filled leave application is provided to you with this notice for signature. Upon full utilization of your EL balance during the notice period, no separate EL encashment will be payable.',
    settlement: [
      ['Component', 'Amount (INR)', 'Notes'],
      ['May 2026 Salary', 'Rs. 47,589', 'Full month payroll'],
      ['Notice pay-in-lieu (10 days shortfall)', 'Rs. 15,863', '10 days x Rs.47,589 / 30'],
      ['Retrenchment compensation (IR Code 2020 §70)', 'Rs. 48,686', '15 days x 4 years x Basic Rs.24,343 / 30 (per IR Code §2(zh): wages = Basic + DA only)'],
      ['Earned Leave (EL) encashment', 'Rs. 0', 'Fully utilized during notice period (17.61 hrs per April 2026 payslip)'],
      [{ text: 'Total Cash to Employee (payable June 1, 2026)', opts: { bold: true } }, { text: 'Rs. 1,12,138', opts: { bold: true } }, { text: 'Net amount to bank account', opts: { bold: true } }],
      ['Re-skilling Fund deposit (IR Code §83) - PAID TO STATE, NOT TO EMPLOYEE', 'Rs. 12,171', 'Company expense: paid directly to Haryana Re-skilling Fund (15 days x Basic Rs.24,343 / 30)'],
    ],
    body: null,
  },
  {
    filename: '06-Rahul-Uniyal-Retrenchment.docx',
    name:         'Rahul Uniyal',
    designation:  'Customer Support Engineer',
    department:   'Customer Support Engineering (CSE)',
    hireDate:     'May 10, 2022',
    empNo:        'TIPL-CSE-2022-06',
    pathway:      'retrenchment',
    elBurnNote:   'Your accrued Earned Leave (EL) balance as of April 2026 payroll is 89.16 hours (approximately 11.15 working days). This balance, together with any May 2026 accrual, will be fully utilized as paid leave during the notice period (May 11 to May 31, 2026). A pre-filled leave application is provided to you with this notice for signature. Upon full utilization of your EL balance during the notice period, no separate EL encashment will be payable.',
    settlement: [
      ['Component', 'Amount (INR)', 'Notes'],
      ['May 2026 Salary', 'Rs. 38,585', 'Full month payroll'],
      ['Notice pay-in-lieu (10 days shortfall)', 'Rs. 12,862', '10 days x Rs.38,585 / 30'],
      ['Retrenchment compensation (IR Code 2020 §70)', 'Rs. 39,370', '15 days x 4 years x Basic Rs.19,685 / 30 (per IR Code §2(zh): wages = Basic + DA only)'],
      ['Earned Leave (EL) encashment', 'Rs. 0', 'Fully utilized during notice period (89.16 hrs per April 2026 payslip)'],
      [{ text: 'Total Cash to Employee (payable June 1, 2026)', opts: { bold: true } }, { text: 'Rs. 90,817', opts: { bold: true } }, { text: 'Net amount to bank account', opts: { bold: true } }],
      ['Re-skilling Fund deposit (IR Code §83) - PAID TO STATE, NOT TO EMPLOYEE', 'Rs. 9,843', 'Company expense: paid directly to Haryana Re-skilling Fund (15 days x Basic Rs.19,685 / 30)'],
    ],
    body: null,
  },
];

// ─── LETTER BODY BUILDER ────────────────────────────────────────────────────
function buildLetterBody(emp) {
  const isProbation    = emp.pathway === 'probation';
  const isNonWorker    = emp.pathway === 'non-worker';
  const isRetrenchment = emp.pathway === 'retrenchment';
  const isPostProb     = emp.pathway === 'post-probation';

  let subjectLine, openingPara, terminationPara, noticePara;

  if (isProbation) {
    subjectLine = 'Termination of Employment — Probation Period';
    openingPara = [
      T('Dear '), T(emp.name, { bold: true, color: DARK_CHARCOAL }), T(','),
    ];
    terminationPara = [
      T('We regret to inform you that your employment with Technijian IT Services Pvt. Ltd. is being terminated with effect from '),
      T('May 31, 2026', { bold: true, color: DARK_CHARCOAL }),
      T('. As you are currently serving your probationary period (commenced '), T(emp.hireDate, { bold: true, color: DARK_CHARCOAL }),
      T('), this termination is made pursuant to the probationary terms of your offer letter and the Company\'s Employee Handbook (§Appointments).'),
    ];
    noticePara = [
      T('As your employment is within the probationary period, no separate notice period or retrenchment compensation is applicable. Your last working day will be '),
      T('May 31, 2026', { bold: true, color: DARK_CHARCOAL }),
      T('. Your full May 2026 salary will be paid as part of your full and final settlement.'),
    ];
  } else if (isNonWorker) {
    subjectLine = 'Termination of Employment — Cost Reduction';
    openingPara = [
      T('Dear '), T(emp.name, { bold: true, color: DARK_CHARCOAL }), T(','),
    ];
    terminationPara = [
      T('We regret to inform you that your employment with Technijian IT Services Pvt. Ltd. is being terminated with effect from '),
      T('May 31, 2026', { bold: true, color: DARK_CHARCOAL }),
      T(', effective today for purposes of your release and system access.'),
    ];
    noticePara = [
      T('Given the supervisory / managerial nature of your role and the operational requirements of the Company, you are being released from active duties with immediate effect today, May 11, 2026. In lieu of the notice period not served, you will receive '),
      T('10 days\' pay-in-lieu of notice', { bold: true, color: DARK_CHARCOAL }),
      T(' in addition to your full May 2026 salary. Your full and final settlement will be disbursed on June 1, 2026.'),
    ];
  } else if (isRetrenchment) {
    subjectLine = 'Notice of Retrenchment — IR Code 2020 §70';
    openingPara = [
      T('Dear '), T(emp.name, { bold: true, color: DARK_CHARCOAL }), T(','),
    ];
    terminationPara = [
      T('We regret to inform you that your employment with Technijian IT Services Pvt. Ltd. is being retrenched under '),
      T('Section 70 of the Industrial Relations Code, 2020', { bold: true, color: DARK_CHARCOAL }),
      T(', with your last working day being '),
      T('May 31, 2026', { bold: true, color: DARK_CHARCOAL }),
      T('.'),
    ];
    noticePara = [
      T('Notice of retrenchment is being issued today, May 11, 2026, providing 20 days of actual notice (May 11 through May 31, 2026). As the statutory notice period is 30 days, '),
      T('10 days\' wages in lieu of notice', { bold: true, color: DARK_CHARCOAL }),
      T(' will be included in your full and final settlement. You are placed on paid leave-of-absence effective today; your system access and client credentials have been revoked. All statutory entitlements, including retrenchment compensation under §70 and any Earned Leave balance, will be paid on June 1, 2026.'),
    ];
  } else {
    subjectLine = 'Termination of Employment — Cost Reduction';
    openingPara = [
      T('Dear '), T(emp.name, { bold: true, color: DARK_CHARCOAL }), T(','),
    ];
    terminationPara = [
      T('We regret to inform you that your employment with Technijian IT Services Pvt. Ltd. is being terminated with effect from '),
      T('May 31, 2026', { bold: true, color: DARK_CHARCOAL }),
      T('.'),
    ];
    noticePara = [
      T('Notice of termination is being issued today, May 11, 2026, providing 20 days of actual notice (May 11 through May 31, 2026). As the statutory notice period is 30 days, '),
      T('10 days\' wages in lieu of notice', { bold: true, color: DARK_CHARCOAL }),
      T(' will be included in your full and final settlement. Your full and final settlement will be disbursed on June 1, 2026.'),
    ];
  }

  const body = [];

  // ── Date + addressee block ──
  body.push(P([T('May 11, 2026', { bold: true, color: DARK_CHARCOAL })], { after: 160 }));

  body.push(settTable([
    [{ text: 'To' }, { text: emp.name, opts: { bold: true } }],
    [{ text: 'Employee No.' }, { text: emp.empNo }],
    [{ text: 'Designation' }, { text: emp.designation }],
    [{ text: 'Department' }, { text: emp.department }],
    [{ text: 'Date of Joining' }, { text: emp.hireDate }],
  ]));

  body.push(blankLine());

  // ── Subject ──
  body.push(P([
    T('Subject: ', { bold: true, color: DARK_CHARCOAL }),
    T(subjectLine, { bold: true, color: CORE_BLUE, underline: true }),
  ], { after: 200 }));

  // ── Opening + termination ──
  body.push(P(openingPara, { after: 200 }));

  // ── Business reason (all pathways) ──
  body.push(P([
    T('As you are aware, Technijian IT Services Pvt. Ltd. experienced a '),
    T('severe malware attack in September 2024', { bold: true, color: DARK_CHARCOAL }),
    T(' that disrupted operations and eroded client confidence, resulting in the '),
    T('loss of four major client accounts', { bold: true, color: DARK_CHARCOAL }),
    T(' in Q4 2024 and Q1 2025. The consequent and sustained revenue reduction has made it necessary for the Company to restructure its workforce in order to ensure the long-term viability of its India operations. This decision is being taken on the ground of '),
    T('bona fide cost reduction and redundancy', { bold: true, color: DARK_CHARCOAL }),
    T(', and not on account of any personal conduct on your part.'),
  ], { after: 200 }));

  body.push(P(terminationPara, { after: 200 }));
  body.push(P(noticePara, { after: 200 }));

  // ── EL burn instruction (if applicable) ──
  if (emp.elBurnNote) {
    body.push(new Paragraph({
      children: [new TextRun({ text: 'Earned Leave During Notice Period:', font: 'Calibri', size: 22, bold: true, color: CORE_BLUE })],
      spacing: { before: 100, after: 80 },
    }));
    body.push(P([T(emp.elBurnNote)], { after: 200 }));
  }

  // ── Retrenchment compliance (§70 only) ──
  if (isRetrenchment) {
    body.push(new Paragraph({
      children: [new TextRun({ text: 'Statutory Compliance:', font: 'Calibri', size: 22, bold: true, color: CORE_BLUE })],
      spacing: { before: 100, after: 80 },
    }));
    body.push(P([
      T('This retrenchment is carried out in compliance with the Industrial Relations Code, 2020. The selection follows the last-in-first-out (LIFO) seniority order within the Customer Support Engineering department as required by §71. The required notification under §70(c) is being filed with the appropriate Government authority concurrent with the issuance of this notice. The Company\'s establishment size is below the §77 prior-permission threshold; no prior Government permission is required. The Re-skilling Fund contribution under §83 will be deposited with the Haryana state authority.'),
    ], { after: 200 }));
  }

  // ── Settlement table ──
  body.push(new Paragraph({
    children: [new TextRun({ text: 'Full and Final Settlement:', font: 'Calibri', size: 22, bold: true, color: CORE_BLUE })],
    spacing: { before: 100, after: 80 },
  }));
  body.push(settTable(emp.settlement));
  body.push(blankLine());
  body.push(P([
    T('All amounts are subject to applicable TDS deductions as per the Income-tax Act, 1961. The net amount after TDS will be transferred to your registered bank account on or before June 1, 2026. Your Form 16 will be issued within 30 days of the end of the financial year.'),
  ], { before: 80, after: 200 }));

  // ── IT / Access revocation ──
  body.push(new Paragraph({
    children: [new TextRun({ text: 'System Access and Company Assets:', font: 'Calibri', size: 22, bold: true, color: CORE_BLUE })],
    spacing: { before: 100, after: 80 },
  }));
  body.push(P([
    T('Effective '),
    T('May 11, 2026', { bold: true, color: DARK_CHARCOAL }),
    T(', your access to all Technijian systems, client environments, VPN, remote monitoring tools, and any client-specific portals has been revoked. You are required to return all Company property — including any equipment, access cards, tokens, and documents — to the team lead at the Panchkula office on or before May 31, 2026. Retention or unauthorized use of Company property or client data after the effective date of termination may result in legal action.'),
  ], { after: 200 }));

  // ── Confidentiality ──
  body.push(new Paragraph({
    children: [new TextRun({ text: 'Confidentiality and Non-Disclosure:', font: 'Calibri', size: 22, bold: true, color: CORE_BLUE })],
    spacing: { before: 100, after: 80 },
  }));
  body.push(P([
    T('Your confidentiality and non-disclosure obligations under your offer letter and the Company\'s Employee Handbook continue to apply after the termination of your employment. You must not disclose, use, or reproduce any proprietary information, client data, or trade secrets of Technijian IT Services Pvt. Ltd. or its clients, for any purpose after your last working day.'),
  ], { after: 200 }));

  // ── EPF / ESIC ──
  body.push(new Paragraph({
    children: [new TextRun({ text: 'EPF and ESIC:', font: 'Calibri', size: 22, bold: true, color: CORE_BLUE })],
    spacing: { before: 100, after: 80 },
  }));
  body.push(P([
    T('The Company will process your EPF UAN transfer / withdrawal and ESIC exit formalities within 15 days of your last working date. Please ensure your UAN is linked to your Aadhaar and your bank account details on the EPFO portal are current. Contact the undersigned directly if you require any assistance with the process.'),
  ], { after: 200 }));

  // ── Closing ──
  body.push(HR());
  body.push(P([
    T('We acknowledge the contributions you have made to Technijian IT Services Pvt. Ltd. during your tenure and regret the circumstances that have led to this decision. We wish you the very best in your future endeavors and will provide a relieving letter and service certificate upon request.'),
  ], { before: 120, after: 200 }));

  body.push(P([T('Yours sincerely,')], { before: 200, after: 160 }));
  body.push(blankLine());
  body.push(blankLine());
  body.push(blankLine());

  body.push(P([T('_______________________________')], { after: 40 }));
  body.push(P([T('Ravi', { bold: true, color: DARK_CHARCOAL })], { after: 40 }));
  body.push(P([T('Director', { bold: true, color: DARK_CHARCOAL })], { after: 40 }));
  body.push(P([T('Technijian IT Services Pvt. Ltd.')], { after: 40 }));
  body.push(P([T('Panchkula, Haryana')], { after: 200 }));

  body.push(HR());
  body.push(new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { before: 100 },
    children: [new TextRun({ text: '— Confidential employer communication. Not for further distribution. —', font: 'Calibri', size: 16, italics: true, color: BRAND_GREY })],
  }));

  // ── Acknowledgement strip ──
  body.push(P([T('')], { before: 360 }));
  body.push(new Paragraph({
    children: [new TextRun({ text: 'EMPLOYEE ACKNOWLEDGEMENT', font: 'Calibri', size: 22, bold: true, color: CORE_BLUE })],
    spacing: { before: 240, after: 120 },
  }));
  body.push(P([
    T('I, '), T(emp.name, { bold: true, color: DARK_CHARCOAL }),
    T(', acknowledge receipt of this termination / retrenchment notice dated May 11, 2026. I understand the terms, the last working day of May 31, 2026, and the settlement amounts stated above.'),
  ], { after: 200 }));

  // Foxit text tags embedded as white text inside the underscore placeholders.
  // processTextTags: true in createfolder API will scan the PDF and convert
  // these tags to interactive fields at their exact rendered positions.
  // Tag format: ${type:party:required:name:width:height}
  // Foxit text tags: signfield uses underscores INSIDE braces for width;
  // height is derived from the text tag's font size. datefield supports
  // explicit numeric w:h. Tags rendered in white (invisible) at 10pt to
  // constrain signature field height. One field per line with breathing room.
  body.push(P([
    T('Employee Signature:  '),
    T('${signfield:1:y:Emp_Sig:____________________}', { color: WHITE, size: 20 }),
  ], { before: 200, after: 220 }));
  body.push(P([
    T('Date:  '),
    T('${datefield:1:y:Date_Signed:80:18}', { color: WHITE, size: 20 }),
  ], { after: 220 }));
  body.push(P([
    T('Print Name:  ', { color: BRAND_GREY }),
    T(emp.name, { color: DARK_CHARCOAL, bold: true }),
  ], { after: 160 }));
  body.push(P([
    T('Employee No.:  ', { color: BRAND_GREY }),
    T(emp.empNo, { color: DARK_CHARCOAL, bold: true }),
  ], { after: 120 }));

  return body;
}

// ─── GENERATE ALL LETTERS ──────────────────────────────────────────────────
(async () => {
  if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR, { recursive: true });

  for (const emp of employees) {
    const doc = new Document({
      creator: 'Technijian IT Services Pvt. Ltd.',
      title: `Termination Letter — ${emp.name}`,
      description: `Employment termination notice dated May 11, 2026`,
      styles: { default: { document: { run: { font: 'Calibri', size: 22 } } } },
      sections: [{
        properties: {
          page: {
            size: { width: 12240, height: 15840, orientation: PageOrientation.PORTRAIT },
            margin: { top: 2880, right: 1440, bottom: 1800, left: 1440 },
          },
        },
        headers: { default: buildHeader() },
        footers: { default: buildFooter() },
        children: buildLetterBody(emp),
      }],
    });

    const buf     = await Packer.toBuffer(doc);
    const outFile = path.join(OUT_DIR, emp.filename);
    fs.writeFileSync(outFile, buf);
    console.log(`Generated: ${emp.filename}  (${(buf.length / 1024).toFixed(1)} KB)`);
  }

  console.log('\nAll 6 letters generated in:', OUT_DIR);
})();
