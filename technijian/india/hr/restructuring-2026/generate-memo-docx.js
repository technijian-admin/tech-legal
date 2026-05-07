/**
 * Generates the Workforce Reduction Memo as a Technijian (USA) branded DOCX.
 *
 * Run from tech-legal/technijian/india/hr/restructuring-2026/:
 *   node generate-memo-docx.js
 *
 * Output: workforce-reduction-memo.docx (in current folder)
 *
 * Brand reference: tech-branding/skills/technijian-letterhead/SKILL.md
 * Logo path: c:/vscode/tech-branding/tech-branding/assets/logos/png/technijian-logo-full-color-600x125.png
 *
 * Voice: U.S. English. Sender: Technijian (Irvine, CA). Subject: India operations restructuring.
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
const CORE_BLUE = '006DB6';
const CORE_ORANGE = 'F67D4B';
const DARK_CHARCOAL = '1A1A2E';
const BRAND_GREY = '59595B';
const LIGHT_GREY = 'E9ECEF';
const OFF_WHITE = 'F8F9FA';
const WHITE = 'FFFFFF';

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
           opts.alt ? { type: ShadingType.SOLID, color: OFF_WHITE, fill: OFF_WHITE } : undefined,
});

const table = (rows, columnWidths) => new Table({
  width: { size: 100, type: WidthType.PERCENTAGE },
  columnWidths,
  rows: rows.map((row, ri) => new TableRow({
    children: row.map((c) => {
      const isHeader = ri === 0;
      const isAlt = !isHeader && ri % 2 === 0;
      return cell(c.text ?? c, { header: isHeader, alt: isAlt, bold: isHeader, ...c.opts });
    }),
  })),
  borders: {
    top: { style: BorderStyle.SINGLE, size: 4, color: LIGHT_GREY },
    bottom: { style: BorderStyle.SINGLE, size: 4, color: LIGHT_GREY },
    left: { style: BorderStyle.SINGLE, size: 4, color: LIGHT_GREY },
    right: { style: BorderStyle.SINGLE, size: 4, color: LIGHT_GREY },
    insideHorizontal: { style: BorderStyle.SINGLE, size: 2, color: LIGHT_GREY },
    insideVertical: { style: BorderStyle.SINGLE, size: 2, color: LIGHT_GREY },
  },
});

// ─── HEADER & FOOTER (US BRANDING) ──────────────────────────────────────
function buildHeader() {
  const logoBuf = fs.readFileSync(LOGO_PATH);

  const headerTable = new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    rows: [
      new TableRow({
        children: [
          new TableCell({
            children: [
              new Paragraph({
                children: [new ImageRun({ data: logoBuf, transformation: { width: 180, height: 38 } })],
              }),
            ],
            width: { size: 50, type: WidthType.PERCENTAGE },
          }),
          new TableCell({
            children: [
              new Paragraph({
                alignment: AlignmentType.RIGHT,
                children: [new TextRun({ text: 'TECHNIJIAN', font: 'Calibri', size: 18, bold: true, color: DARK_CHARCOAL })],
              }),
              new Paragraph({
                alignment: AlignmentType.RIGHT,
                children: [new TextRun({ text: '18 Technology Dr., Ste 141', font: 'Calibri', size: 16, color: BRAND_GREY })],
              }),
              new Paragraph({
                alignment: AlignmentType.RIGHT,
                children: [new TextRun({ text: 'Irvine, CA 92618', font: 'Calibri', size: 16, color: BRAND_GREY })],
              }),
              new Paragraph({
                alignment: AlignmentType.RIGHT,
                children: [new TextRun({ text: '949.379.8500  |  technijian.com', font: 'Calibri', size: 16, color: CORE_BLUE })],
              }),
            ],
            width: { size: 50, type: WidthType.PERCENTAGE },
          }),
        ],
      }),
    ],
    borders: {
      top: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
      bottom: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
      left: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
      right: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
      insideHorizontal: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
      insideVertical: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
    },
  });

  const blueBar = new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    rows: [new TableRow({
      children: [new TableCell({
        children: [new Paragraph({ children: [new TextRun({ text: '' })] })],
        shading: { type: ShadingType.SOLID, color: CORE_BLUE, fill: CORE_BLUE },
      })],
      height: { value: 40, rule: 'exact' },
    })],
    borders: {
      top: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
      bottom: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
      left: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
      right: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
      insideHorizontal: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
      insideVertical: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
    },
  });

  const orangeBar = new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    rows: [new TableRow({
      children: [new TableCell({
        children: [new Paragraph({ children: [new TextRun({ text: '' })] })],
        shading: { type: ShadingType.SOLID, color: CORE_ORANGE, fill: CORE_ORANGE },
      })],
      height: { value: 80, rule: 'exact' },
    })],
    borders: {
      top: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
      bottom: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
      left: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
      right: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
      insideHorizontal: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
      insideVertical: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
    },
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
          new TextRun({ text: 'TECHNIJIAN', font: 'Calibri', size: 16, bold: true, color: DARK_CHARCOAL }),
          new TextRun({ text: '  |  Managed IT  -  Cybersecurity  -  Cloud  -  AI Development  -  Compliance', font: 'Calibri', size: 16, color: BRAND_GREY }),
        ],
      }),
      new Paragraph({
        alignment: AlignmentType.CENTER,
        spacing: { before: 30, after: 0 },
        children: [new TextRun({
          text: 'Technijian  |  18 Technology Dr., Ste 141, Irvine, CA 92618  |  949.379.8500',
          font: 'Calibri', size: 14, color: BRAND_GREY,
        })],
      }),
      new Paragraph({
        alignment: AlignmentType.CENTER,
        spacing: { before: 20, after: 0 },
        children: [new TextRun({
          text: 'info@technijian.com  |  technijian.com',
          font: 'Calibri', size: 14, color: BRAND_GREY,
        })],
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

// ─── MEMO BODY (U.S. ENGLISH) ───────────────────────────────────────────
function buildBody() {
  const body = [];

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
    [{ text: 'Date', opts: { bold: true } }, { text: 'May 6, 2026' }],
    [{ text: 'To', opts: { bold: true } }, { text: 'Board of Directors, Technijian' }],
    [{ text: 'From', opts: { bold: true } }, { text: 'Office of the CEO' }],
    [{ text: 'Subject', opts: { bold: true } }, { text: 'Authorization for retrenchment of 7 India employees on cost-reduction grounds' }],
    [{ text: 'Status', opts: { bold: true } }, { text: 'DRAFT — pre-counsel review and pre-Board approval' }],
    [{ text: 'Confidentiality', opts: { bold: true } }, { text: 'Strictly confidential — do not distribute beyond Board and named addressees' }],
  ], [2000, 7000]));

  body.push(P([T('')], { after: 200 }));

  // 1. EXECUTIVE SUMMARY
  body.push(H1('1. Executive Summary'));
  body.push(P([T('Technijian\'s India operations have been operationally and financially impaired by the '),
               T('September 2024 malware attack', { bold: true, color: DARK_CHARCOAL }),
               T(' and the '),
               T('subsequent loss of four major client accounts', { bold: true, color: DARK_CHARCOAL }),
               T('. Revenue capacity at the Panchkula office is materially below the level required to support its current 43-person headcount. To restore operating viability, leadership recommends a '),
               T('headcount reduction of 7 employees', { bold: true, color: DARK_CHARCOAL }),
               T(' in a single, lawful, well-documented restructuring action effective '),
               T('May 31, 2026', { bold: true, color: DARK_CHARCOAL }),
               T('.')]));

  body.push(P([T('Headline numbers:', { bold: true, color: DARK_CHARCOAL })], { before: 120 }));

  body.push(table([
    [{ text: 'Metric' }, { text: 'Value (INR)' }, { text: 'Value (USD @ ₹84)' }],
    [{ text: 'One-time restructuring cost (statutory minimum + leave optimization)' }, { text: '₹9,71,852', opts: { bold: true } }, { text: '$11,569', opts: { bold: true } }],
    [{ text: 'Recurring monthly savings starting June 2026' }, { text: '₹3,47,174 / month' }, { text: '$4,133 / month' }],
    [{ text: 'Annualized recurring savings' }, { text: '₹41,66,088 / year', opts: { bold: true } }, { text: '$49,596 / year', opts: { bold: true } }],
    [{ text: 'Payback period' }, { text: '2.80 months', opts: { bold: true } }, { text: '—' }],
    [{ text: '5-year cumulative net benefit' }, { text: '₹2,06,50,588', opts: { bold: true } }, { text: '$245,840', opts: { bold: true } }],
  ]));

  body.push(P([T('The restructuring is grounded in established Indian labor law (IR Code 2020 §§70–71, Code on Wages 2019, Punjab S&E Act 1958, Code on Social Security 2020) and Supreme Court precedent affirming cost-reduction as a valid retrenchment ground. Procedural, statutory, and documentary safeguards are built into the implementation plan.')], { before: 200 }));

  body.push(P([T('Board decisions requested:', { bold: true, color: DARK_CHARCOAL })], { before: 120 }));
  body.push(P([T('1. Approval of the 7-person retrenchment.')], { after: 60 }));
  body.push(P([T('2. Authorization of the ₹9.72 lakh disbursement on June 1, 2026.')], { after: 60 }));
  body.push(P([T('3. Authorization for HR and external counsel to issue notices on May 9, 2026.')], { after: 60 }));
  body.push(P([T('4. Ratification of the business-case rationale and §71 LIFO-departure justification.')], { after: 200 }));

  // 2. BUSINESS CONTEXT
  body.push(H1('2. Business Context'));
  body.push(H3('2.1  The triggering events'));
  body.push(P([T('• '), T('September 2024:', { bold: true, color: DARK_CHARCOAL }), T(' Malware attack on Technijian systems disrupted operations, eroded client confidence, and incurred direct remediation costs.')]));
  body.push(P([T('• '), T('Q4 2024 – Q1 2025:', { bold: true, color: DARK_CHARCOAL }), T(' Four major client accounts terminated their engagements citing service disruption and confidence concerns.')]));
  body.push(P([T('• '), T('Through FY 2025-26:', { bold: true, color: DARK_CHARCOAL }), T(' Combined effect produced sustained revenue compression. Margin compression made the existing India headcount cost structure unsustainable at projected revenue.')]));

  body.push(H3('2.2  The financial necessity'));
  body.push(P([T('The 7 employees identified for retrenchment together represent approximately ₹3.47 lakh per month / ₹41.66 lakh per year in direct payroll cost. After accounting for ancillary costs (employer EPF, group health insurance, allocated facilities, IT licenses, equipment depreciation), the realistic monthly burn associated with these positions is closer to ₹4.0–4.2 lakh / ~$4,800–5,000.')]));
  body.push(P([T('Restoring the cost structure to a level supportable by post-attack revenue requires a step change in headcount; incremental measures (raise freezes, vendor renegotiation, allowance trims) are insufficient on their own.')]));

  body.push(H3('2.3  Why retrenchment vs. salary reduction'));
  body.push(P([T('A 21-day notice salary-reduction route (IR Code 2020 §40) was evaluated and rejected. Reasons: constructive-dismissal jurisprudence makes the path expensive and unpredictable; adverse selection retains the lowest-performing staff while losing higher performers; damages morale and triggers attrition cascades on the surviving team; EL encashment liability is not avoided; total expected cost equals or exceeds clean retrenchment.')]));

  // 3. SELECTION METHODOLOGY
  body.push(H1('3. Selection Methodology'));
  body.push(H3('3.1  Selection criteria'));
  body.push(P([T('The 7 employees were identified using the following hierarchical criteria, applied in order:')]));
  body.push(P([T('1. '), T('Business necessity', { bold: true, color: DARK_CHARCOAL }), T(' — positions whose roles and scope can be eliminated given the reduced client base.')], { after: 60 }));
  body.push(P([T('2. '), T('Recency of hire (LIFO)', { bold: true, color: DARK_CHARCOAL }), T(' — newer hires whose retrenchment compensation exposure is lower.')], { after: 60 }));
  body.push(P([T('3. '), T('Performance evidence', { bold: true, color: DARK_CHARCOAL }), T(' — documented underperformance per April 2026 mid-year reviews where available.')], { after: 60 }));
  body.push(P([T('4. '), T('Operational impact', { bold: true, color: DARK_CHARCOAL }), T(' — minimizing disruption to remaining client deliverables.')]));

  body.push(H3('3.2  The 7 selected positions'));
  body.push(table([
    [{ text: '#' }, { text: 'Employee' }, { text: 'Department' }, { text: 'Hired' }, { text: 'Tenure' }, { text: 'Selection rationale' }],
    [{ text: '1' }, { text: 'Devesh Bhattacharya' }, { text: 'CSE' }, { text: 'Apr 1, 2026' }, { text: '5 wk' }, { text: 'Most recent CSE hire; in probation' }],
    [{ text: '2' }, { text: 'Rajat Kumar' }, { text: 'CSE' }, { text: 'Feb 2, 2026' }, { text: '3 mo' }, { text: 'Recent CSE hire; just past probation' }],
    [{ text: '3' }, { text: 'Deepak Bhardwaj' }, { text: 'CSE' }, { text: 'Jan 15, 2026' }, { text: '3.5 mo' }, { text: 'Recent CSE hire' }],
    [{ text: '4' }, { text: 'Aditya Saraf' }, { text: 'CSE' }, { text: 'Jan 10, 2026' }, { text: '4 mo' }, { text: 'Recent Lead hire; supervisory role redundant at reduced scale' }],
    [{ text: '5' }, { text: 'Yogesh Kumar' }, { text: 'CSE' }, { text: 'Jun 1, 2022' }, { text: '4 yr' }, { text: 'Mid-year review 3.07/5; cross-reviewer concurrence' }],
    [{ text: '6' }, { text: 'Rahul Uniyal' }, { text: 'CSE' }, { text: 'May 10, 2022' }, { text: '4 yr' }, { text: 'Mid-year review 3.07/5; cross-reviewer concurrence' }],
    [{ text: '7' }, { text: 'Saroj Kumari' }, { text: 'DMA' }, { text: 'Sep 9, 2024' }, { text: '1 yr 8 mo' }, { text: 'DMA function consolidation; specific role eliminated; junior DMA staff retained at lower cost' }],
  ]));

  body.push(H3('3.3  §71 LIFO-departure justification — Saroj Kumari'));
  body.push(P([T('Statutory provision: ', { bold: true, color: DARK_CHARCOAL }), T('IR Code 2020 §71 requires retrenchment in reverse order of seniority within a category, unless the employer records a specific business reason for departure.')]));
  body.push(P([T('Departure rationale (memorialized in a separate signed document):', { bold: true, color: DARK_CHARCOAL })]));
  body.push(new Paragraph({
    spacing: { before: 60, after: 120 },
    alignment: AlignmentType.LEFT,
    indent: { left: 360 },
    children: [new TextRun({
      text: '"The DMA function is being consolidated. Saroj Kumari\'s specific role focused on full-funnel digital marketing campaigns for the four lost clients; that workstream no longer exists. The two junior DMAs (Mohit Pandey, Vaishali Rathor) perform technical-execution and content-publishing tasks at significantly lower cost (~₹25-27K/mo vs ₹60.5K/mo) and are needed for ongoing surviving client work. Substitution is not feasible: the junior staff cannot perform the strategic-campaign work, and the strategic role is not justified at reduced revenue."',
      font: 'Calibri', size: 20, color: DARK_CHARCOAL, italics: true,
    })],
  }));
  body.push(P([T('This pattern is supported by tribunal jurisprudence: '), T('Workmen of Western India Match Co. v. Industrial Tribunal', { italic: true }), T(' (SC 1973), '), T('Parry & Co. v. P.C. Pal', { italic: true }), T(' (SC 1970).')]));

  body.push(H3('3.4  Removed from the cut list'));
  body.push(P([T('Navjit Kaur', { bold: true, color: DARK_CHARCOAL }), T(' (CSE Junior, hired Feb 27, 2023) was initially considered but removed. She is currently working remotely following a six-month maternity leave. While the protected statutory window has lapsed, terminating a recently-returned-from-maternity employee creates discrimination-claim exposure that materially exceeds the modest cost saving (~₹22.9K/month).')]));

  // 4. LEGAL FRAMEWORK
  body.push(H1('4. Legal Framework'));
  body.push(H3('4.1  The four 2020 Indian Labor Codes (in force November 21, 2025)'));
  body.push(P([T('• Industrial Relations Code, 2020 — controls retrenchment, lay-off, notice, compensation')], { after: 60 }));
  body.push(P([T('• Code on Wages, 2019 — controls wage payments, final settlement timing')], { after: 60 }));
  body.push(P([T('• Code on Social Security, 2020 — EPF, ESI, gratuity, maternity (none of the 7 cross 5-year gratuity vest)')], { after: 60 }));
  body.push(P([T('• Occupational Safety, Health and Working Conditions Code, 2020 — informs welfare obligations on the surviving establishment')]));

  body.push(H3('4.2  Specific statutory bases'));
  body.push(table([
    [{ text: 'Provision' }, { text: 'What it requires' }, { text: 'Compliance plan' }],
    [{ text: 'IR Code §70 — retrenchment of workers ≥1 year' }, { text: '1 month notice (or pay-in-lieu); retrenchment compensation = 15 days × completed years; Government notification' }, { text: 'Notice May 6, 2026; 25 days served + 5 days pay-in-lieu = 30 days; full compensation budgeted' }],
    [{ text: 'IR Code §71 — last-in-first-out within category' }, { text: 'Cut newer hires first unless documented business reason' }, { text: 'Compliant for 6 of 7; §71 departure for Saroj documented' }],
    [{ text: 'IR Code §83 — Re-skilling Fund' }, { text: '15 days\' wages per retrenched worker to state Fund' }, { text: '₹73,338 deposit budgeted' }],
    [{ text: 'IR Code §78 — Govt-permission threshold' }, { text: '≥300 workers triggers prior permission' }, { text: 'Headcount 43; NOT triggered' }],
    [{ text: 'Code on Wages §17(2)' }, { text: 'All dues paid within 2 working days of cessation' }, { text: 'Disbursement June 1, 2026' }],
    [{ text: 'Punjab S&E Act §§ 28-30 (Haryana)' }, { text: 'EL encashment at last-drawn wages' }, { text: 'EL balances per April 2026 payroll fully provided' }],
    [{ text: 'Social Security Code Ch V — Gratuity' }, { text: '5-year vesting' }, { text: 'None of the 7 has crossed; not owed' }],
    [{ text: 'Social Security Code Ch VI — Maternity' }, { text: 'No dismissal during pregnancy/maternity' }, { text: 'Saroj cleared: not pregnant, not on maternity' }],
    [{ text: 'POSH Act 2013' }, { text: 'No retaliation termination' }, { text: 'IC chair clearance for all 7 before notice' }],
    [{ text: 'DPDP Act 2023' }, { text: 'Erase non-essential data after retention period' }, { text: 'Built into HR offboarding SOP' }],
    [{ text: 'Income-tax Act §10(10AA)' }, { text: '₹25 lakh lifetime EL exemption' }, { text: 'None at cap; full benefit available' }],
    [{ text: 'Income-tax Act §10(10B)' }, { text: 'Partial exemption on retrenchment compensation' }, { text: 'TDS at applicable slab' }],
  ]));

  body.push(H3('4.3  Applicable Indian Supreme Court precedents'));
  body.push(table([
    [{ text: 'Case' }, { text: 'Holding' }],
    [{ text: 'Workmen of Sudder Office v. Management (SC 1971)' }, { text: 'Economic necessity / cost-reduction is a valid retrenchment ground' }],
    [{ text: 'Parry & Co. v. P.C. Pal (SC 1970)' }, { text: 'Bona fide business decisions on closure / restructuring receive judicial deference' }],
    [{ text: 'Hindustan Lever v. Ram Mohan Ray (SC 1973)' }, { text: 'Cost-reduction and efficiency-driven restructuring are legitimate grounds' }],
    [{ text: 'Workmen of Western India Match Co. (SC 1973)' }, { text: 'Downsizing for documented financial reasons is sustainable; §71 departure permitted' }],
    [{ text: 'Aureliano Fernandes v. State of Goa (SC 2023)' }, { text: 'POSH compliance integrity; pre-clearance check recommended' }],
  ]));

  // 5. FINANCIAL ANALYSIS
  body.push(H1('5. Financial Analysis'));
  body.push(H3('5.1  One-time restructuring cost'));
  body.push(P([T('Statutory minimum, no ex-gratia, with leave-burn optimization for Yogesh, Rahul, and Saroj.')]));
  body.push(table([
    [{ text: '#' }, { text: 'Employee' }, { text: 'May salary' }, { text: 'Notice top-up' }, { text: 'Retrench comp' }, { text: 'EL encashment' }, { text: 'Cash to employee' }, { text: 'Re-skilling Fund' }],
    [{ text: '1' }, { text: 'Devesh Bhattacharya' }, { text: '50,000' }, { text: '0' }, { text: '0' }, { text: '0' }, { text: '50,000' }, { text: '0' }],
    [{ text: '2' }, { text: 'Rajat Kumar' }, { text: '42,500' }, { text: '7,083' }, { text: '0' }, { text: '0' }, { text: '49,583' }, { text: '0' }],
    [{ text: '3' }, { text: 'Deepak Bhardwaj' }, { text: '38,000' }, { text: '6,333' }, { text: '0' }, { text: '0' }, { text: '44,333' }, { text: '0' }],
    [{ text: '4' }, { text: 'Aditya Saraf' }, { text: '70,000' }, { text: '11,667' }, { text: '0' }, { text: '0' }, { text: '81,667' }, { text: '0' }],
    [{ text: '5' }, { text: 'Yogesh Kumar' }, { text: '47,589' }, { text: '7,931' }, { text: '95,178' }, { text: '0' }, { text: '1,50,698' }, { text: '23,795' }],
    [{ text: '6' }, { text: 'Rahul Uniyal' }, { text: '38,585' }, { text: '6,431' }, { text: '77,170' }, { text: '1,15,178' }, { text: '2,37,364' }, { text: '19,293' }],
    [{ text: '7' }, { text: 'Saroj Kumari' }, { text: '60,500' }, { text: '10,083' }, { text: '60,500' }, { text: '1,53,786' }, { text: '2,84,869' }, { text: '30,250' }],
    [{ text: '', opts: { bold: true } }, { text: 'Subtotals', opts: { bold: true } }, { text: '3,47,174', opts: { bold: true } }, { text: '49,528', opts: { bold: true } }, { text: '2,32,848', opts: { bold: true } }, { text: '2,68,964', opts: { bold: true } }, { text: '8,98,514', opts: { bold: true } }, { text: '73,338', opts: { bold: true } }],
  ]));

  body.push(P([T('All-in one-time cost: ', { bold: true, color: DARK_CHARCOAL }),
               T('₹9,71,852 (~$11,569 USD)', { bold: true, color: CORE_BLUE })], { before: 120, after: 120 }));

  body.push(H3('5.2  Recurring savings'));
  body.push(table([
    [{ text: 'Period' }, { text: 'INR' }, { text: 'USD (@ ₹84)' }],
    [{ text: 'Per month (direct salary)' }, { text: '3,47,174' }, { text: '$4,133' }],
    [{ text: 'Per year (direct salary)' }, { text: '41,66,088' }, { text: '$49,596' }],
    [{ text: 'Per year (incl. EPF, insurance, facilities)' }, { text: '~48–50 lakh' }, { text: '~$57,000–$60,000' }],
  ]));

  body.push(H3('5.3  Return on the restructuring'));
  body.push(table([
    [{ text: 'Metric' }, { text: 'Value' }],
    [{ text: 'Payback period' }, { text: '2.80 months' }],
    [{ text: 'Cost recouped by' }, { text: '~Late August 2026' }],
    [{ text: 'Year-1 net benefit' }, { text: '₹31,94,236 (~$38,027)' }],
    [{ text: 'Year-2+ pure benefit' }, { text: '₹41,66,088 / year (~$49,596 / year)' }],
    [{ text: '5-year cumulative net benefit', opts: { bold: true } }, { text: '₹2,06,50,588 (~$245,840)', opts: { bold: true } }],
  ]));

  // 6. RISK ASSESSMENT
  body.push(H1('6. Risk Assessment'));
  body.push(table([
    [{ text: 'Employee' }, { text: 'Risk tier' }, { text: 'Drivers' }, { text: 'Mitigations' }],
    [{ text: 'Devesh Bhattacharya' }, { text: 'Lowest' }, { text: 'In probation' }, { text: 'Standard relieving letter; pro-rata wages' }],
    [{ text: 'Rajat Kumar' }, { text: 'Low' }, { text: 'Just past probation; <1 yr' }, { text: '1-month notice or pay-in-lieu' }],
    [{ text: 'Deepak Bhardwaj' }, { text: 'Low' }, { text: 'Past probation; <1 yr' }, { text: '1-month notice or pay-in-lieu' }],
    [{ text: 'Aditya Saraf' }, { text: 'Low' }, { text: 'Lead at ₹70K = likely non-worker; <1 yr' }, { text: 'Contractual exit' }],
    [{ text: 'Yogesh Kumar' }, { text: 'Medium' }, { text: '4-yr tenure; §70 retrench comp due' }, { text: 'Frame as redundancy; full statutory comp' }],
    [{ text: 'Rahul Uniyal' }, { text: 'Medium' }, { text: '4-yr tenure; large EL balance' }, { text: 'Same as Yogesh' }],
    [{ text: 'Saroj Kumari' }, { text: 'Medium-High' }, { text: 'Female; 2-yr tenure; §71 LIFO departure required' }, { text: 'Documented LIFO memo; counsel-vetted letter; pregnancy/POSH cleared' }],
  ]));

  body.push(P([T('Aggregate risk rating: Medium overall. ', { bold: true, color: DARK_CHARCOAL }),
               T('Driven primarily by Saroj\'s profile. Mitigations bring residual risk to manageable levels. Expected aggregate risk-adjusted cost of claims: ₹1.0–1.8 lakh. Even at the upper bound, total program cost remains far below alternative restructuring approaches.')], { before: 200 }));

  // 7. IMPLEMENTATION
  body.push(H1('7. Implementation Plan'));
  body.push(H3('7.1  Timeline'));
  body.push(table([
    [{ text: 'Date' }, { text: 'Action' }],
    [{ text: 'May 6, 2026 (today)' }, { text: 'Draft business-case + LIFO memos. Pre-clearance checks initiated. Counsel engaged.' }],
    [{ text: 'May 7-8, 2026' }, { text: 'Counsel reviews letters. Directors sign business-case memo. Pre-clearance closed.' }],
    [{ text: 'May 9, 2026 (Friday)' }, { text: 'Decision day. Notice handed to all 7. Aditya effective same day with pay-in-lieu (surrender access). Yogesh, Rahul, Saroj on paid leave-of-absence from May 9. Devesh, Rajat, Deepak continue working.' }],
    [{ text: 'May 31, 2026 (Sunday)' }, { text: 'Last working day for the 6 still on payroll.' }],
    [{ text: 'June 1, 2026 (Monday)' }, { text: 'Final settlement paid. Form 16. EPF UAN exit. ESIC closure. Re-skilling Fund deposit.' }],
    [{ text: 'June 15, 2026' }, { text: 'EPF ECR for May filed.' }],
    [{ text: 'June 30, 2026' }, { text: 'All compliance filings closed.' }],
  ]));

  body.push(H3('7.2  Pre-clearance checklist (before May 9, 2026)'));
  body.push(table([
    [{ text: 'Check' }, { text: 'Owner' }, { text: 'Status' }],
    [{ text: 'Restructuring / business-case memo signed' }, { text: 'Directors' }, { text: 'Pending Board approval' }],
    [{ text: '§71 LIFO-departure memo — Saroj' }, { text: 'CHRO + Head of DMA' }, { text: 'To draft' }],
    [{ text: 'External counsel review of all 7 letters' }, { text: 'India counsel' }, { text: 'Engage now' }],
    [{ text: 'POSH / GRC complaint clearance — all 7' }, { text: 'IC chair' }, { text: 'To confirm' }],
    [{ text: 'Pregnancy / maternity check — Saroj' }, { text: 'HR' }, { text: 'To confirm' }],
    [{ text: 'Rajat probation-end date' }, { text: 'HR' }, { text: 'To confirm' }],
    [{ text: 'Outstanding loans / advances' }, { text: 'Payroll' }, { text: '✓ Confirmed: none' }],
    [{ text: 'Treasury liquidity for ₹9.7L on June 1, 2026' }, { text: 'CFO' }, { text: 'To confirm' }],
    [{ text: 'Re-skilling Fund deposit procedure' }, { text: 'Compliance' }, { text: 'To confirm' }],
  ]));

  // 8. APPROVALS
  body.push(H1('8. Approvals Requested from the Board'));
  body.push(table([
    [{ text: '#' }, { text: 'Item' }, { text: 'Decision' }],
    [{ text: '1' }, { text: 'Authorization of the 7-person retrenchment as detailed in §3' }, { text: 'Approve / Decline' }],
    [{ text: '2' }, { text: 'Authorization of the ₹9,71,852 disbursement (one-time)' }, { text: 'Approve / Decline' }],
    [{ text: '3' }, { text: 'Authorization for HR + counsel to issue notices on May 9, 2026' }, { text: 'Approve / Decline' }],
    [{ text: '4' }, { text: 'Ratification of business-case rationale (§2)' }, { text: 'Approve / Decline' }],
    [{ text: '5' }, { text: 'Ratification of §71 LIFO-departure justification for Saroj Kumari (§3.3)' }, { text: 'Approve / Decline' }],
    [{ text: '6' }, { text: 'Authorization for the CEO to issue all-employee communication' }, { text: 'Approve / Decline' }],
  ]));

  // 9. SIGN-OFFS — 3 DIRECTORS
  body.push(H1('9. Director Sign-offs'));
  body.push(P([T('By signing below, the undersigned Directors of Technijian acknowledge review of this Memorandum and authorize the proposed workforce reduction of 7 India-based employees, the associated ₹9,71,852 (~$11,569) one-time disbursement on June 1, 2026, and the implementation timeline set out in §7.')], { after: 240 }));

  body.push(table([
    [{ text: 'Director', opts: { bold: true } }, { text: 'Signature', opts: { bold: true } }, { text: 'Date', opts: { bold: true } }],
    [{ text: 'Ravi Jain', opts: { bold: true } }, { text: '_______________________________' }, { text: '_______________' }],
    [{ text: 'Chandra Jain', opts: { bold: true } }, { text: '_______________________________' }, { text: '_______________' }],
    [{ text: 'Daya Krishan Sharma', opts: { bold: true } }, { text: '_______________________________' }, { text: '_______________' }],
  ]));

  body.push(P([T('')], { before: 240 }));
  body.push(new Paragraph({
    alignment: AlignmentType.CENTER,
    children: [new TextRun({
      text: 'This document is privileged and confidential. Prepared in contemplation of internal restructuring; may attract attorney-client privilege upon counsel review. Distribution is restricted to the Board, named approvers, and external counsel.',
      font: 'Calibri', size: 16, italics: true, color: BRAND_GREY,
    })],
  }));
  body.push(new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { before: 100 },
    children: [new TextRun({
      text: '— END OF MEMORANDUM —',
      font: 'Calibri', size: 18, bold: true, color: CORE_BLUE,
    })],
  }));

  return body;
}

// ─── BUILD AND SAVE ─────────────────────────────────────────────────────
const doc = new Document({
  creator: 'Technijian',
  title: 'Workforce Reduction Plan — India Operations',
  description: 'Board-Level Decision Memorandum, May 6, 2026',
  styles: {
    default: { document: { run: { font: 'Calibri', size: 22 } } },
  },
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
