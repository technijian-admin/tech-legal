/**
 * Generates the Workforce Reduction Memo as a Technijian IT Services Pvt. Ltd. branded DOCX.
 *
 * Run from tech-legal/technijian/india/hr/restructuring-2026/:
 *   node generate-memo-docx.js
 *
 * Output: workforce-reduction-memo.docx (in current folder)
 *
 * Letterhead: India (Technijian IT Services Pvt. Ltd., Panchkula)
 * Voice: U.S. English. 6-person cut. Notice date: May 11, 2026.
 */

const fs = require('fs');
const path = require('path');

const docxRoot = 'C:/vscode/tech-branding/tech-branding/node_modules';
const docx = require(path.join(docxRoot, 'docx'));

const {
  Document, Packer, Paragraph, TextRun, AlignmentType,
  Table, TableRow, TableCell, WidthType, BorderStyle,
  Header, Footer, ImageRun, PageNumber, PageOrientation,
  ShadingType,
} = docx;

// ─── BRAND CONSTANTS ────────────────────────────────────────────────────
const CORE_BLUE   = '006DB6';
const CORE_ORANGE = 'F67D4B';
const DARK_CHARCOAL = '1A1A2E';
const BRAND_GREY  = '59595B';
const LIGHT_GREY  = 'E9ECEF';
const OFF_WHITE   = 'F8F9FA';
const WHITE       = 'FFFFFF';

const LOGO_PATH = 'C:/vscode/tech-branding/tech-branding/assets/logos/png/technijian-logo-full-color-600x125.png';

// ─── HELPERS ────────────────────────────────────────────────────────────
const T = (text, opts = {}) => new TextRun({
  text,
  font: 'Calibri',
  size: opts.size ?? 22,
  color: opts.color ?? BRAND_GREY,
  bold: opts.bold ?? false,
  italics: opts.italic ?? false,
});

const P = (children, opts = {}) => new Paragraph({
  children: Array.isArray(children) ? children : [children],
  spacing: { before: opts.before ?? 0, after: opts.after ?? 120 },
  alignment: opts.align ?? AlignmentType.LEFT,
});

const H1 = (text) => new Paragraph({
  children: [new TextRun({ text, font: 'Calibri', size: 36, bold: true, color: CORE_BLUE })],
  spacing: { before: 360, after: 180 },
});

const H3 = (text) => new Paragraph({
  children: [new TextRun({ text, font: 'Calibri', size: 24, bold: true, color: CORE_BLUE })],
  spacing: { before: 200, after: 100 },
});

const cell = (text, opts = {}) => new TableCell({
  children: [new Paragraph({
    children: [new TextRun({
      text: String(text),
      font: 'Calibri',
      size: opts.size ?? 18,
      bold: opts.bold ?? false,
      color: opts.color ?? (opts.header ? WHITE : DARK_CHARCOAL),
    })],
    alignment: opts.align ?? AlignmentType.LEFT,
    spacing: { before: 40, after: 40 },
  })],
  shading: opts.header ? { type: ShadingType.SOLID, color: CORE_BLUE, fill: CORE_BLUE } :
           opts.alt    ? { type: ShadingType.SOLID, color: OFF_WHITE,  fill: OFF_WHITE  } : undefined,
});

const table = (rows, columnWidths) => new Table({
  width: { size: 100, type: WidthType.PERCENTAGE },
  columnWidths,
  rows: rows.map((row, ri) => new TableRow({
    children: row.map((c) => {
      const isHeader = ri === 0;
      const isAlt    = !isHeader && ri % 2 === 0;
      return cell(c.text ?? c, { header: isHeader, alt: isAlt, bold: isHeader, ...c.opts });
    }),
  })),
  borders: {
    top:              { style: BorderStyle.SINGLE, size: 4, color: LIGHT_GREY },
    bottom:           { style: BorderStyle.SINGLE, size: 4, color: LIGHT_GREY },
    left:             { style: BorderStyle.SINGLE, size: 4, color: LIGHT_GREY },
    right:            { style: BorderStyle.SINGLE, size: 4, color: LIGHT_GREY },
    insideHorizontal: { style: BorderStyle.SINGLE, size: 2, color: LIGHT_GREY },
    insideVertical:   { style: BorderStyle.SINGLE, size: 2, color: LIGHT_GREY },
  },
});

// ─── HEADER & FOOTER (INDIA BRANDING) ───────────────────────────────────
function buildHeader() {
  const logoBuf = fs.readFileSync(LOGO_PATH);

  const headerTable = new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    rows: [new TableRow({
      children: [
        new TableCell({
          children: [new Paragraph({
            children: [new ImageRun({ data: logoBuf, transformation: { width: 180, height: 38 } })],
          })],
          width: { size: 50, type: WidthType.PERCENTAGE },
        }),
        new TableCell({
          children: [
            new Paragraph({ alignment: AlignmentType.RIGHT, children: [new TextRun({ text: 'TECHNIJIAN IT SERVICES PVT. LTD.', font: 'Calibri', size: 18, bold: true, color: DARK_CHARCOAL })] }),
            new Paragraph({ alignment: AlignmentType.RIGHT, children: [new TextRun({ text: 'Twin Tower, Plot no 7, Sector 22', font: 'Calibri', size: 16, color: BRAND_GREY })] }),
            new Paragraph({ alignment: AlignmentType.RIGHT, children: [new TextRun({ text: 'IT Park, Panchkula 134109, Haryana, India', font: 'Calibri', size: 16, color: BRAND_GREY })] }),
            new Paragraph({ alignment: AlignmentType.RIGHT, children: [new TextRun({ text: 'india@technijian.com  |  technijian.com', font: 'Calibri', size: 16, color: CORE_BLUE })] }),
          ],
          width: { size: 50, type: WidthType.PERCENTAGE },
        }),
      ],
    })],
    borders: { top: { style: BorderStyle.NONE, size: 0, color: WHITE }, bottom: { style: BorderStyle.NONE, size: 0, color: WHITE }, left: { style: BorderStyle.NONE, size: 0, color: WHITE }, right: { style: BorderStyle.NONE, size: 0, color: WHITE }, insideHorizontal: { style: BorderStyle.NONE, size: 0, color: WHITE }, insideVertical: { style: BorderStyle.NONE, size: 0, color: WHITE } },
  });

  const blueBar = new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    rows: [new TableRow({ children: [new TableCell({ children: [new Paragraph({ children: [new TextRun({ text: '' })] })], shading: { type: ShadingType.SOLID, color: CORE_BLUE, fill: CORE_BLUE } })], height: { value: 40, rule: 'exact' } })],
    borders: { top: { style: BorderStyle.NONE, size: 0, color: WHITE }, bottom: { style: BorderStyle.NONE, size: 0, color: WHITE }, left: { style: BorderStyle.NONE, size: 0, color: WHITE }, right: { style: BorderStyle.NONE, size: 0, color: WHITE }, insideHorizontal: { style: BorderStyle.NONE, size: 0, color: WHITE }, insideVertical: { style: BorderStyle.NONE, size: 0, color: WHITE } },
  });

  const orangeBar = new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    rows: [new TableRow({ children: [new TableCell({ children: [new Paragraph({ children: [new TextRun({ text: '' })] })], shading: { type: ShadingType.SOLID, color: CORE_ORANGE, fill: CORE_ORANGE } })], height: { value: 80, rule: 'exact' } })],
    borders: { top: { style: BorderStyle.NONE, size: 0, color: WHITE }, bottom: { style: BorderStyle.NONE, size: 0, color: WHITE }, left: { style: BorderStyle.NONE, size: 0, color: WHITE }, right: { style: BorderStyle.NONE, size: 0, color: WHITE }, insideHorizontal: { style: BorderStyle.NONE, size: 0, color: WHITE }, insideVertical: { style: BorderStyle.NONE, size: 0, color: WHITE } },
  });

  return new Header({
    children: [headerTable, blueBar, orangeBar, new Paragraph({ children: [new TextRun({ text: '' })], spacing: { before: 0, after: 80 } })],
  });
}

function buildFooter() {
  return new Footer({
    children: [
      new Paragraph({
        alignment: AlignmentType.CENTER,
        spacing: { before: 60, after: 0 },
        children: [
          new TextRun({ text: 'TECHNIJIAN IT SERVICES PVT. LTD.', font: 'Calibri', size: 16, bold: true, color: DARK_CHARCOAL }),
          new TextRun({ text: '  |  Managed IT  -  Cybersecurity  -  Cloud  -  AI Development  -  Compliance', font: 'Calibri', size: 16, color: BRAND_GREY }),
        ],
      }),
      new Paragraph({
        alignment: AlignmentType.CENTER,
        spacing: { before: 30, after: 0 },
        children: [new TextRun({ text: 'Twin Tower, Plot no 7, Sector 22, IT Park, Panchkula 134109, Haryana, India  |  india@technijian.com', font: 'Calibri', size: 14, color: BRAND_GREY })],
      }),
      new Paragraph({
        alignment: AlignmentType.CENTER,
        spacing: { before: 20, after: 0 },
        children: [new TextRun({ text: 'U.S. Parent: Technijian  |  18 Technology Dr., Ste 141, Irvine, CA 92618  |  949.379.8500', font: 'Calibri', size: 14, color: BRAND_GREY })],
      }),
      new Paragraph({
        alignment: AlignmentType.CENTER,
        spacing: { before: 20, after: 0 },
        children: [
          new TextRun({ text: 'Page ', font: 'Calibri', size: 14, color: BRAND_GREY }),
          new TextRun({ children: [PageNumber.CURRENT], font: 'Calibri', size: 14, color: BRAND_GREY }),
          new TextRun({ text: ' of ', font: 'Calibri', size: 14, color: BRAND_GREY }),
          new TextRun({ children: [PageNumber.TOTAL_PAGES], font: 'Calibri', size: 14, color: BRAND_GREY }),
          new TextRun({ text: '  |  CONFIDENTIAL', font: 'Calibri', size: 14, color: BRAND_GREY, italics: true }),
        ],
      }),
    ],
  });
}

// ─── MEMO BODY ──────────────────────────────────────────────────────────
function buildBody() {
  const body = [];

  // ── TITLE BLOCK ──
  body.push(new Paragraph({
    spacing: { before: 0, after: 120 },
    alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: 'WORKFORCE REDUCTION PLAN — INDIA OPERATIONS', font: 'Calibri', size: 32, bold: true, color: CORE_BLUE })],
  }));
  body.push(new Paragraph({
    spacing: { before: 0, after: 240 },
    alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: 'Board-Level Decision Memorandum', font: 'Calibri', size: 22, italics: true, color: DARK_CHARCOAL })],
  }));

  body.push(table([
    [{ text: 'Date',            opts: { bold: true } }, { text: 'May 8, 2026' }],
    [{ text: 'To',              opts: { bold: true } }, { text: 'Board of Directors, Technijian IT Services Pvt. Ltd.' }],
    [{ text: 'From',            opts: { bold: true } }, { text: 'Office of the CEO' }],
    [{ text: 'Subject',         opts: { bold: true } }, { text: 'Authorization for retrenchment of 6 India employees on cost-reduction grounds' }],
    [{ text: 'Status',          opts: { bold: true } }, { text: 'DRAFT — pre-counsel review and pre-Board approval' }],
    [{ text: 'Confidentiality', opts: { bold: true } }, { text: 'Strictly confidential — do not distribute beyond Board and named addressees' }],
  ], [2000, 7000]));

  body.push(P([T('')], { after: 200 }));

  // ── 1. EXECUTIVE SUMMARY ──
  body.push(H1('1. Executive Summary'));
  body.push(P([
    T('Technijian IT Services Pvt. Ltd. has been operationally and financially impaired by the '),
    T('September 2024 malware attack', { bold: true, color: DARK_CHARCOAL }),
    T(' and the '),
    T('subsequent loss of four major client accounts', { bold: true, color: DARK_CHARCOAL }),
    T('. Revenue capacity at the Panchkula office is materially below the level required to support its current 22-person active workforce (per April 2026 payroll register). To restore operating viability, leadership recommends a '),
    T('headcount reduction of 6 employees', { bold: true, color: DARK_CHARCOAL }),
    T(' (a 27% workforce reduction concentrated in the Customer Support Engineering department) effective '),
    T('May 31, 2026', { bold: true, color: DARK_CHARCOAL }),
    T(', with notice issued on May 11, 2026.'),
  ]));

  body.push(P([T('Headline numbers:', { bold: true, color: DARK_CHARCOAL })], { before: 120 }));

  body.push(table([
    [{ text: 'Metric' }, { text: 'Value (INR)' }, { text: 'Value (USD @ Rs.84)' }],
    [{ text: 'One-time restructuring cost (statutory minimum on Basic+DA per IR Code §2(zh) + leave optimization)' }, { text: 'Rs.5,52,441', opts: { bold: true } }, { text: '$6,577', opts: { bold: true } }],
    [{ text: 'Recurring monthly savings starting June 2026' }, { text: 'Rs.2,88,674 / month' }, { text: '$3,437 / month' }],
    [{ text: 'Annualized recurring savings' }, { text: 'Rs.34,64,088 / year', opts: { bold: true } }, { text: '$41,239 / year', opts: { bold: true } }],
    [{ text: 'Payback period' }, { text: '~1.91 months', opts: { bold: true } }, { text: '—' }],
    [{ text: '5-year cumulative net benefit' }, { text: 'Rs.1,67,67,999', opts: { bold: true } }, { text: '$199,619', opts: { bold: true } }],
  ], [4500, 2500, 2000]));

  body.push(P([T('The restructuring is grounded in established Indian labor law (IR Code 2020 §§70–71, Code on Wages 2019, Punjab S&E Act 1958, Code on Social Security 2020) and Supreme Court precedent affirming cost-reduction as a valid retrenchment ground.')], { before: 200 }));

  body.push(P([T('Board decisions requested:', { bold: true, color: DARK_CHARCOAL })], { before: 120 }));
  body.push(P([T('1. Approval of the 6-person retrenchment.')], { after: 60 }));
  body.push(P([T('2. Authorization of the Rs.5.52 lakh disbursement on June 1, 2026.')], { after: 60 }));
  body.push(P([T('3. Authorization for the Director to issue notices on May 11, 2026.')], { after: 60 }));
  body.push(P([T('4. Ratification of the business-case rationale for cost-reduction retrenchment.')], { after: 200 }));

  // ── 2. BUSINESS CONTEXT ──
  body.push(H1('2. Business Context'));
  body.push(H3('2.1  The triggering events'));
  body.push(P([T('• '), T('September 2024:', { bold: true, color: DARK_CHARCOAL }), T(' Malware attack on Technijian systems disrupted operations, eroded client confidence, and incurred direct remediation costs.')]));
  body.push(P([T('• '), T('Q4 2024 – Q1 2025:', { bold: true, color: DARK_CHARCOAL }), T(' Four major client accounts terminated their engagements citing service disruption and confidence concerns.')]));
  body.push(P([T('• '), T('Through FY 2025-26:', { bold: true, color: DARK_CHARCOAL }), T(' Combined effect produced sustained revenue compression that made the existing India headcount cost structure unsustainable at projected revenue.')]));

  body.push(H3('2.2  The financial necessity'));
  body.push(P([T('The 6 employees identified for retrenchment together represent approximately Rs.2.89 lakh per month / Rs.34.64 lakh per year in direct payroll cost. After accounting for ancillary costs (employer EPF, group health insurance, allocated facilities, IT licenses, equipment depreciation), the realistic monthly burn is closer to Rs.3.3–3.4 lakh / ~$3,900–4,000.')]));
  body.push(P([T('Restoring the cost structure to a level supportable by post-attack revenue requires a step change in headcount; incremental measures (raise freezes, vendor renegotiation, allowance trims) are insufficient on their own.')]));

  body.push(H3('2.3  Why retrenchment vs. salary reduction'));
  body.push(P([T('A 21-day notice salary-reduction route (IR Code 2020 §40) was evaluated and rejected. Reasons: constructive-dismissal jurisprudence makes the path expensive and unpredictable; adverse selection retains the lowest-performing staff while losing higher performers; damages morale and triggers attrition cascades on the surviving team; EL encashment liability is not avoided; total expected cost equals or exceeds clean retrenchment.')]));

  // ── 3. SELECTION METHODOLOGY ──
  body.push(H1('3. Selection Methodology'));
  body.push(H3('3.1  Selection criteria'));
  body.push(P([T('The 6 employees were identified using the following hierarchical criteria, applied in order:')]));
  body.push(P([T('1. '), T('Business necessity', { bold: true, color: DARK_CHARCOAL }), T(' — positions whose roles and scope can be eliminated given the reduced client base.')], { after: 60 }));
  body.push(P([T('2. '), T('Recency of hire (LIFO)', { bold: true, color: DARK_CHARCOAL }), T(' — newer hires whose retrenchment compensation exposure is lower.')], { after: 60 }));
  body.push(P([T('3. '), T('Performance evidence', { bold: true, color: DARK_CHARCOAL }), T(' — documented underperformance per April 2026 mid-year reviews where available.')], { after: 60 }));
  body.push(P([T('4. '), T('Operational impact', { bold: true, color: DARK_CHARCOAL }), T(' — minimizing disruption to remaining client deliverables.')]));

  body.push(H3('3.2  The 6 selected positions'));
  body.push(table([
    [{ text: '#' }, { text: 'Employee' }, { text: 'Department' }, { text: 'Hired' }, { text: 'Tenure' }, { text: 'Selection rationale' }],
    [{ text: '1' }, { text: 'Devesh Bhattacharya' }, { text: 'CSE' }, { text: 'Apr 1, 2026' },  { text: '5 wk' },     { text: 'Most recent CSE hire; in probation; no notice required' }],
    [{ text: '2' }, { text: 'Rajat Kumar' },          { text: 'CSE' }, { text: 'Feb 2, 2026' },  { text: '3 mo' },    { text: 'Recent CSE hire; just past probation' }],
    [{ text: '3' }, { text: 'Aditya Saraf' },          { text: 'CSE' }, { text: 'Jan 10, 2026' }, { text: '4 mo' },    { text: 'CSE Lead; supervisory role redundant at reduced scale; non-worker' }],
    [{ text: '4' }, { text: 'Suresh Kumar Sharma' },   { text: 'CSE' }, { text: 'Jun 9, 2025' },  { text: '~11 mo' },  { text: 'CSE; past probation; within LIFO seniority order' }],
    [{ text: '5' }, { text: 'Yogesh Kumar' },          { text: 'CSE' }, { text: 'Jun 1, 2022' },  { text: '4 yr' },    { text: 'Mid-year review 3.07/5; cross-reviewer concurrence; confirmed workman' }],
    [{ text: '6' }, { text: 'Rahul Uniyal' },          { text: 'CSE' }, { text: 'May 10, 2022' }, { text: '4 yr' },    { text: 'Mid-year review 3.07/5; cross-reviewer concurrence; confirmed workman' }],
  ], [300, 1800, 800, 1200, 700, 4200]));

  body.push(H3('3.3  LIFO compliance — no departure required'));
  body.push(P([T('All 6 selected employees are in the '), T('CSE department', { bold: true, color: DARK_CHARCOAL }), T('. The selection follows strict reverse order of seniority within the category. No §71 LIFO departure memo is required. This eliminates a significant litigation exposure compared to cross-department cuts.')]));

  body.push(H3('3.4  Employees considered and removed from cut list'));
  body.push(P([T('Navjit Kaur', { bold: true, color: DARK_CHARCOAL }), T(' (CSE Junior, hired Feb 27, 2023): recently returned from six-month maternity leave, now working 100% remotely. Terminating a recently-returned-from-maternity employee creates discrimination-claim exposure that materially exceeds the modest cost saving (~Rs.22.9K/month).')]));

  // ── 4. LEGAL FRAMEWORK ──
  body.push(H1('4. Legal Framework'));
  body.push(H3('4.1  The four 2020 Indian Labor Codes (in force November 21, 2025)'));
  body.push(P([T('• Industrial Relations Code, 2020 — controls retrenchment, lay-off, notice, compensation')], { after: 60 }));
  body.push(P([T('• Code on Wages, 2019 — controls wage payments, final settlement timing')], { after: 60 }));
  body.push(P([T('• Code on Social Security, 2020 — EPF, ESI, gratuity, maternity (none of the 6 cross 5-year gratuity vest)')], { after: 60 }));
  body.push(P([T('• Occupational Safety, Health and Working Conditions Code, 2020 — welfare obligations on surviving establishment')]));

  body.push(H3('4.2  Specific statutory bases'));
  body.push(table([
    [{ text: 'Provision' }, { text: 'What it requires' }, { text: 'Compliance plan' }],
    [{ text: 'IR Code §70 — retrenchment of workers >=1 year' }, { text: '1 month notice (or pay-in-lieu); retrenchment comp = 15 days x completed years; Government notification' }, { text: 'Notice May 11, 2026; 20 days served + 10 days pay-in-lieu = 30 days; full compensation budgeted for Yogesh and Rahul' }],
    [{ text: 'IR Code §71 — last-in-first-out within category' }, { text: 'Cut newer hires first unless documented business reason' }, { text: 'Fully compliant — all 6 in CSE, in LIFO order. No departure required.' }],
    [{ text: 'IR Code §83 — Re-skilling Fund' }, { text: '15 days wages per retrenched worker to state Fund (Basic+DA basis per §2(zh))' }, { text: 'Rs.22,014 deposit budgeted (Yogesh + Rahul only; others < 1 yr)' }],
    [{ text: 'IR Code §78 — Govt-permission threshold' }, { text: '>=300 workers triggers prior permission' }, { text: 'Active workforce 22; NOT triggered' }],
    [{ text: 'Code on Wages §17(2)' }, { text: 'All dues paid within 2 working days of cessation' }, { text: 'Disbursement June 1, 2026' }],
    [{ text: 'Punjab S&E Act §§28-30 (Haryana)' }, { text: 'EL encashment at last-drawn wages' }, { text: 'EL balances per April 2026 payroll; leave-burn strategy applied' }],
    [{ text: 'Social Security Code Ch V — Gratuity' }, { text: '5-year vesting' }, { text: 'None of the 6 has crossed 5 years; not owed' }],
    [{ text: 'Social Security Code Ch VI — Maternity' }, { text: 'No dismissal during pregnancy/maternity' }, { text: 'None of the 6 are pregnant or on maternity leave (confirmed)' }],
    [{ text: 'POSH Act 2013' }, { text: 'No retaliation termination' }, { text: 'IC chair clearance for all 6 before notice' }],
    [{ text: 'DPDP Act 2023' }, { text: 'Erase non-essential data after retention period' }, { text: 'Built into HR offboarding SOP' }],
    [{ text: 'Income-tax Act §10(10AA)' }, { text: 'Rs.25 lakh lifetime EL exemption' }, { text: 'None at cap; full benefit available' }],
    [{ text: 'Income-tax Act §10(10B)' }, { text: 'Partial exemption on retrenchment compensation' }, { text: 'TDS at applicable slab' }],
  ], [2800, 3000, 3200]));

  body.push(H3('4.3  Applicable Indian Supreme Court precedents'));
  body.push(table([
    [{ text: 'Case' }, { text: 'Holding' }],
    [{ text: 'Workmen of Sudder Office v. Management (SC 1971)' },           { text: 'Economic necessity / cost-reduction is a valid retrenchment ground' }],
    [{ text: 'Parry & Co. v. P.C. Pal (SC 1970)' },                         { text: 'Bona fide business decisions on closure / restructuring receive judicial deference' }],
    [{ text: 'Hindustan Lever v. Ram Mohan Ray (SC 1973)' },                 { text: 'Cost-reduction and efficiency-driven restructuring are legitimate grounds' }],
    [{ text: 'Workmen of Western India Match Co. (SC 1973)' },               { text: 'Downsizing for documented financial reasons is sustainable' }],
    [{ text: 'Aureliano Fernandes v. State of Goa (SC 2023)' },              { text: 'POSH compliance integrity; pre-clearance check recommended' }],
  ], [4500, 4500]));

  // ── 5. FINANCIAL ANALYSIS ──
  body.push(H1('5. Financial Analysis'));
  body.push(H3('5.1  One-time restructuring cost'));
  body.push(P([T('Statutory minimum, no ex-gratia, with leave-burn optimization for Yogesh, Rahul, and Suresh. Notice issued May 11; 20 days served + 10 days pay-in-lieu.')]));
  body.push(table([
    [{ text: '#' }, { text: 'Employee' }, { text: 'May salary' }, { text: 'Notice top-up' }, { text: 'Retrench comp' }, { text: 'EL encashment' }, { text: 'Cash to employee' }, { text: 'Re-skilling Fund' }],
    [{ text: '1' }, { text: 'Devesh Bhattacharya' },   { text: '50,000' },  { text: '0' },      { text: '0' },       { text: '0' },          { text: '50,000' },   { text: '0' }],
    [{ text: '2' }, { text: 'Rajat Kumar' },            { text: '42,500' },  { text: '14,167' }, { text: '0' },       { text: '0' },          { text: '56,667' },   { text: '0' }],
    [{ text: '3' }, { text: 'Aditya Saraf' },           { text: '70,000' },  { text: '23,333' }, { text: '0' },       { text: '0' },          { text: '93,333' },   { text: '0' }],
    [{ text: '4' }, { text: 'Suresh Kumar Sharma' },    { text: '40,000' },  { text: '13,333' }, { text: '0' },       { text: '21,777' },      { text: '75,110' },   { text: '0' }],
    [{ text: '5' }, { text: 'Yogesh Kumar' },           { text: '47,589' },  { text: '15,863' }, { text: '48,686' },  { text: '0 (burned)' },  { text: '1,12,138' }, { text: '12,171' }],
    [{ text: '6' }, { text: 'Rahul Uniyal' },           { text: '38,585' },  { text: '12,862' }, { text: '39,370' },  { text: '52,362' },      { text: '1,43,179' }, { text: '9,843' }],
    [{ text: '',   opts: { bold: true } }, { text: 'Subtotals', opts: { bold: true } }, { text: '2,88,674', opts: { bold: true } }, { text: '79,558', opts: { bold: true } }, { text: '88,056', opts: { bold: true } }, { text: '74,139', opts: { bold: true } }, { text: '5,30,427', opts: { bold: true } }, { text: '22,014', opts: { bold: true } }],
  ], [300, 1800, 900, 900, 900, 1000, 1100, 1100]));

  body.push(P([
    T('All-in one-time cost: ', { bold: true, color: DARK_CHARCOAL }),
    T('Rs.5,52,441 (~$6,577 USD)', { bold: true, color: CORE_BLUE }),
    T('  — calculated on Basic+DA per IR Code §2(zh) wages definition; payroll has no DA component, so wages = Basic only', { italics: true }),
  ], { before: 120, after: 120 }));

  body.push(H3('5.2  Recurring savings'));
  body.push(table([
    [{ text: 'Period' }, { text: 'INR' }, { text: 'USD (@ Rs.84)' }],
    [{ text: 'Per month (direct salary)' },                  { text: '2,88,674' },     { text: '$3,437' }],
    [{ text: 'Per year (direct salary)' },                   { text: '34,64,088' },    { text: '$41,239' }],
    [{ text: 'Per year (incl. EPF, insurance, facilities)' }, { text: '~39–40 lakh' }, { text: '~$46,000–$47,600' }],
  ], [4000, 3000, 2000]));

  body.push(H3('5.3  Return on the restructuring'));
  body.push(table([
    [{ text: 'Metric' }, { text: 'Value' }],
    [{ text: 'Payback period' },                           { text: '~1.91 months' }],
    [{ text: 'Cost recouped by' },                         { text: 'Early July 2026' }],
    [{ text: 'Year-1 net benefit' },                       { text: 'Rs.29,11,647 (~$34,663)' }],
    [{ text: 'Year-2+ pure benefit' },                     { text: 'Rs.34,64,088 / year (~$41,239 / year)' }],
    [{ text: '5-year cumulative net benefit', opts: { bold: true } }, { text: 'Rs.1,67,67,999 (~$199,619)', opts: { bold: true } }],
  ], [4500, 4500]));

  // ── 6. RISK ASSESSMENT ──
  body.push(H1('6. Risk Assessment'));
  body.push(table([
    [{ text: 'Employee' }, { text: 'Risk tier' }, { text: 'Drivers' }, { text: 'Mitigations' }],
    [{ text: 'Devesh Bhattacharya' }, { text: 'Lowest' }, { text: 'In probation' },                           { text: 'Standard relieving letter; pro-rata wages' }],
    [{ text: 'Rajat Kumar' },         { text: 'Low' },    { text: 'Just past probation; <1 yr' },             { text: '10-day pay-in-lieu' }],
    [{ text: 'Aditya Saraf' },        { text: 'Low' },    { text: 'Lead at Rs.70K = likely non-worker; <1 yr' }, { text: 'Contractual exit; 10-day pay-in-lieu' }],
    [{ text: 'Suresh Kumar Sharma' }, { text: 'Low' },    { text: 'Past probation; <1 yr; no retrench comp'}, { text: '10-day pay-in-lieu; EL encashment confirmed' }],
    [{ text: 'Yogesh Kumar' },        { text: 'Medium' }, { text: '4-yr tenure; §70 retrench comp due' },     { text: 'Full statutory comp; cost-reduction framing; LIFO compliant' }],
    [{ text: 'Rahul Uniyal' },        { text: 'Medium' }, { text: '4-yr tenure; large EL balance' },          { text: 'Same as Yogesh; leave-burn reduces EL' }],
  ], [2000, 1200, 2500, 3300]));

  body.push(P([
    T('Aggregate risk rating: ', { bold: true, color: DARK_CHARCOAL }),
    T('Low-Medium overall. ', { bold: true, color: DARK_CHARCOAL }),
    T('All cuts within one department (CSE), following LIFO order. No female employees on cut list. No LIFO departure required. Zero discrimination exposure. Expected aggregate risk-adjusted cost of claims: Rs.50,000–1,00,000.'),
  ], { before: 200 }));

  // ── 7. IMPLEMENTATION ──
  body.push(H1('7. Implementation Plan'));
  body.push(H3('7.1  Timeline'));
  body.push(table([
    [{ text: 'Date' }, { text: 'Action' }],
    [{ text: 'May 8-10, 2026' },          { text: 'Counsel reviews letters. Directors sign decision memo. Pre-clearance items closed. IT access-revocation list prepared.' }],
    [{ text: 'May 11, 2026 (Monday)' },   { text: 'Decision day. Notices delivered to all 6 simultaneously. Aditya: immediate release with pay-in-lieu + access revoked. Yogesh, Rahul, Suresh: on paid leave-of-absence + access revoked + sign leave applications. Devesh, Rajat: continue working.' }],
    [{ text: 'May 31, 2026 (Sunday)' },   { text: 'Last working day for Devesh and Rajat.' }],
    [{ text: 'June 1, 2026 (Monday)' },   { text: 'Final settlement paid to all 6. Form 16. EPF UAN exit. ESIC closure. Re-skilling Fund deposit (Rs.22,014 to Haryana state).' }],
    [{ text: 'June 15, 2026' },            { text: 'EPF ECR for May filed.' }],
    [{ text: 'June 30, 2026' },            { text: 'All compliance filings closed.' }],
  ], [2000, 7000]));

  body.push(H3('7.2  Pre-clearance checklist (before May 11, 2026)'));
  body.push(table([
    [{ text: 'Check' }, { text: 'Owner' }, { text: 'Status' }],
    [{ text: 'Board decision memo signed by 3 directors' },        { text: 'Directors' },    { text: 'Pending Board approval' }],
    [{ text: 'External counsel review of all 6 letters' },         { text: 'India counsel' }, { text: 'Engage now' }],
    [{ text: 'POSH / GRC complaint clearance — all 6' },           { text: 'IC chair' },      { text: 'To confirm' }],
    [{ text: 'Rajat Kumar probation-end date verification' },       { text: 'HR' },            { text: 'To confirm' }],
    [{ text: 'Outstanding loans / advances' },                      { text: 'Payroll' },       { text: 'Confirmed: none' }],
    [{ text: 'Treasury liquidity for Rs.7.62L on June 1, 2026' },  { text: 'CFO' },           { text: 'To confirm' }],
    [{ text: 'Re-skilling Fund deposit procedure (Haryana)' },      { text: 'Compliance' },    { text: 'To confirm' }],
    [{ text: 'IT access revocation list ready (all 6)' },          { text: 'IT' },            { text: 'To confirm' }],
  ], [4500, 2000, 2500]));

  body.push(H3('7.3  System access and client safety'));
  body.push(P([T('All 6 employees must have client system credentials and remote-access revoked simultaneously with letter delivery on May 11, 2026. This includes: VPN access, client RMM/monitoring tools, remote desktop sessions, shared mailboxes, and any client-specific portals. The IT team should stage the revocation list in advance and execute it at the same moment as the physical letter delivery to prevent any gap.')]));

  // ── 8. APPROVALS ──
  body.push(H1('8. Approvals Requested from the Board'));
  body.push(table([
    [{ text: '#' }, { text: 'Item' }, { text: 'Decision' }],
    [{ text: '1' }, { text: 'Authorization of the 6-person retrenchment as detailed in §3' },      { text: 'Approve / Decline' }],
    [{ text: '2' }, { text: 'Authorization of the Rs.7,62,375 disbursement (one-time)' },          { text: 'Approve / Decline' }],
    [{ text: '3' }, { text: 'Authorization for HR + counsel to issue notices on May 11, 2026' },   { text: 'Approve / Decline' }],
    [{ text: '4' }, { text: 'Ratification of business-case rationale (§2)' },                      { text: 'Approve / Decline' }],
    [{ text: '5' }, { text: 'Authorization for the CEO to issue all-employee communication' },     { text: 'Approve / Decline' }],
  ], [500, 7000, 1500]));

  // ── 9. DIRECTOR SIGN-OFFS ──
  body.push(H1('9. Director Sign-offs'));
  body.push(P([T('By signing below, the undersigned Directors of Technijian IT Services Pvt. Ltd. acknowledge review of this Memorandum and authorize the proposed workforce reduction of 6 India-based employees, the associated Rs.7,62,375 (~$9,076) one-time disbursement on June 1, 2026, and the implementation timeline set out in §7.')], { after: 240 }));

  body.push(table([
    [{ text: 'Director', opts: { bold: true } }, { text: 'Signature', opts: { bold: true } }, { text: 'Date', opts: { bold: true } }],
    [{ text: 'Ravi Jain',            opts: { bold: true } }, { text: '_______________________________' }, { text: '_______________' }],
    [{ text: 'Chandra Jain',         opts: { bold: true } }, { text: '_______________________________' }, { text: '_______________' }],
    [{ text: 'Daya Krishan Sharma',  opts: { bold: true } }, { text: '_______________________________' }, { text: '_______________' }],
  ], [3000, 5000, 1000]));

  body.push(P([T('')], { before: 240 }));
  body.push(new Paragraph({
    alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: 'This document is privileged and confidential. Prepared in contemplation of internal restructuring; may attract attorney-client privilege upon counsel review. Distribution is restricted to the Board, named approvers, and external counsel.', font: 'Calibri', size: 16, italics: true, color: BRAND_GREY })],
  }));
  body.push(new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { before: 100 },
    children: [new TextRun({ text: '— END OF MEMORANDUM —', font: 'Calibri', size: 18, bold: true, color: CORE_BLUE })],
  }));

  return body;
}

// ─── BUILD AND SAVE ─────────────────────────────────────────────────────
const doc = new Document({
  creator: 'Technijian IT Services Pvt. Ltd.',
  title: 'Workforce Reduction Plan — India Operations',
  description: 'Board-Level Decision Memorandum, May 8, 2026',
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
    children: buildBody(),
  }],
});

const outPath = path.join(__dirname, 'workforce-reduction-memo.docx');
Packer.toBuffer(doc).then((buf) => {
  fs.writeFileSync(outPath, buf);
  console.log('Generated:', outPath);
  console.log('Size:', (buf.length / 1024).toFixed(1), 'KB');
});
