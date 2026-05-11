/**
 * Generates the Mutual Separation Agreement DOCX for Rajat Kumar.
 *
 * Per the India HR template at:
 *   docs/employees/India/00-Templates/07-Separation/Mutual-Separation-Agreement.md
 *
 * Replaces the original termination letter at the employee's request — Rajat
 * asked to resign instead of being terminated so he can apply to other
 * companies cleanly. Company saves no cash (same total payout as termination),
 * but obtains full mutual release of all claims.
 *
 * Run from tech-legal/technijian/Employees/India/HR/restructuring-2026/:
 *   node generate-rajat-msa-docx.js
 *
 * Output: letters/02-Rajat-Kumar-Mutual-Separation-Agreement.docx
 *
 * Letterhead: India (Technijian IT Services Pvt. Ltd., Panchkula)
 * Separation date: May 31, 2026
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
const OUT_FILE  = '02-Rajat-Kumar-Mutual-Separation-Agreement.docx';

// ─── EMPLOYEE DATA ─────────────────────────────────────────────────────────
const emp = {
  name:        'Rajat Kumar',
  designation: 'Customer Support Engineer',
  department:  'Customer Support Engineering (CSE)',
  hireDate:    'February 2, 2026',
  empNo:       'TIPL-CSE-2026-02',
  tenure:      'approximately three (3) months',
};

const settlement = {
  may:         42500,
  exGratia:    14167,
  total:       56667,
};

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
      return cell(c.text ?? c, { header: isHeader, alt: isAlt, bold: isHeader || (c.opts && c.opts.bold), ...(c.opts || {}) });
    }),
  })),
  borders: { top: { style: BorderStyle.SINGLE, size: 4, color: LIGHT_GREY }, bottom: { style: BorderStyle.SINGLE, size: 4, color: LIGHT_GREY }, left: { style: BorderStyle.SINGLE, size: 4, color: LIGHT_GREY }, right: { style: BorderStyle.SINGLE, size: 4, color: LIGHT_GREY }, insideHorizontal: { style: BorderStyle.SINGLE, size: 2, color: LIGHT_GREY }, insideVertical: { style: BorderStyle.SINGLE, size: 2, color: LIGHT_GREY } },
});

const sectionHeading = (txt) => new Paragraph({
  children: [new TextRun({ text: txt, font: 'Calibri', size: 22, bold: true, color: CORE_BLUE })],
  spacing: { before: 200, after: 80 },
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

// ─── BODY ──────────────────────────────────────────────────────────────────
function buildBody() {
  const body = [];

  // Date + ref
  body.push(P([T('Ref: MSA-SEP/2026/01', { color: BRAND_GREY, size: 18 })], { after: 40 }));
  body.push(P([T('Date: May 11, 2026', { bold: true, color: DARK_CHARCOAL })], { after: 160 }));

  // Title
  body.push(new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { before: 80, after: 200 },
    children: [new TextRun({ text: 'MUTUAL SEPARATION AGREEMENT AND RELEASE OF CLAIMS', font: 'Calibri', size: 26, bold: true, color: CORE_BLUE })],
  }));

  // Parties
  body.push(P([
    T('This Mutual Separation Agreement and Release of Claims (this '),
    T('"Agreement"', { bold: true, color: DARK_CHARCOAL }),
    T(') is made on '),
    T('May 11, 2026', { bold: true, color: DARK_CHARCOAL }),
    T(' at '),
    T('Panchkula, Haryana', { bold: true, color: DARK_CHARCOAL }),
    T(', between:'),
  ], { after: 160 }));

  body.push(P([
    T('TECHNIJIAN IT SERVICES PVT. LTD.', { bold: true, color: DARK_CHARCOAL }),
    T(', a company incorporated under the Companies Act, 2013, having its Operating Office at Plot No. 07, 1st Floor, Panchkula IT Park, Panchkula, Haryana 134109 (the '),
    T('"Company"', { bold: true, color: DARK_CHARCOAL }),
    T(', which expression shall include its successors and permitted assigns) — of the '),
    T('First Part', { bold: true, color: DARK_CHARCOAL }),
    T(';'),
  ], { after: 160 }));

  body.push(P([T('AND', { bold: true, color: DARK_CHARCOAL, size: 22 })], { align: AlignmentType.CENTER, after: 160 }));

  body.push(P([
    T('Mr. ', { bold: true, color: DARK_CHARCOAL }),
    T(emp.name, { bold: true, color: DARK_CHARCOAL }),
    T(', Employee ID '),
    T(emp.empNo, { bold: true, color: DARK_CHARCOAL }),
    T(', presently designated as '),
    T(emp.designation, { bold: true, color: DARK_CHARCOAL }),
    T(' in the '),
    T(emp.department, { bold: true, color: DARK_CHARCOAL }),
    T(' Department of the Company (the '),
    T('"Employee"', { bold: true, color: DARK_CHARCOAL }),
    T(', which expression shall include the Employee\'s heirs and legal representatives) — of the '),
    T('Second Part', { bold: true, color: DARK_CHARCOAL }),
    T('.'),
  ], { after: 200 }));

  // ── Recitals ──
  body.push(sectionHeading('RECITALS'));

  body.push(P([
    T('A.  The Employee joined the Company on '),
    T(emp.hireDate, { bold: true, color: DARK_CHARCOAL }),
    T(' as '),
    T(emp.designation, { bold: true, color: DARK_CHARCOAL }),
    T(', and has rendered '),
    T(emp.tenure, { bold: true, color: DARK_CHARCOAL }),
    T(' of continuous service as on the date of this Agreement.'),
  ], { after: 160 }));

  body.push(P([
    T('B.  The Parties have, after discussion and in good faith, mutually agreed to bring the Employee\'s employment with the Company to an amicable end on the terms and conditions set out in this Agreement, in lieu of the cost-reduction-based separation notice issued earlier on May 11, 2026.'),
  ], { after: 160 }));

  body.push(P([
    T('C.  The Parties enter into this Agreement of their own free will, without coercion, undue influence, fraud, or misrepresentation, with full knowledge of their respective rights and after having had the opportunity to consult with independent legal counsel.'),
  ], { after: 200 }));

  body.push(P([
    T('NOW, THEREFORE, in consideration of the mutual covenants set forth below, the Parties agree as follows:'),
  ], { after: 200 }));

  // ── 1. Separation Date ──
  body.push(sectionHeading('1. SEPARATION DATE'));

  body.push(P([
    T('1.01  The Employee\'s employment with the Company shall stand terminated by mutual agreement effective close of business on '),
    T('May 31, 2026', { bold: true, color: DARK_CHARCOAL }),
    T(' (the '),
    T('"Separation Date"', { bold: true, color: DARK_CHARCOAL }),
    T(').'),
  ], { after: 160 }));

  body.push(P([
    T('1.02  From the date of execution of this Agreement up to and including the Separation Date, the Employee shall be on paid leave-of-absence and shall not be required to attend the Company\'s premises or perform work.'),
  ], { after: 160 }));

  body.push(P([
    T('1.03  The Employee\'s Company email access, VPN, and physical premises access shall stand revoked with effect from '),
    T('May 11, 2026', { bold: true, color: DARK_CHARCOAL }),
    T('.'),
  ], { after: 200 }));

  // ── 2. Settlement ──
  body.push(sectionHeading('2. SEPARATION CONSIDERATION ("F&F + EX-GRATIA")'));

  body.push(P([
    T('2.01  In full and final consideration of this Agreement and the releases granted by the Employee in §4 below, the Company shall pay to the Employee the following amounts ('),
    T('"Separation Consideration"', { bold: true, color: DARK_CHARCOAL }),
    T('):'),
  ], { after: 160 }));

  body.push(settTable([
    ['Component', 'Amount (INR)', 'Notes'],
    ['(a) May 2026 Salary up to the Separation Date', `Rs. ${settlement.may.toLocaleString('en-IN')}`, 'Full month payroll'],
    ['(b) Notice period pay-in-lieu', 'Rs. 0', 'Not applicable (mutual separation, both parties waive notice)'],
    ['(c) Earned Leave (EL) encashment', 'Rs. 0', 'Balance as per payroll records; nil residual'],
    ['(d) Statutory retrenchment compensation', 'Rs. 0', 'Tenure < 1 year; not applicable'],
    ['(e) Ex-gratia / severance payment', `Rs. ${settlement.exGratia.toLocaleString('en-IN')}`, 'Voluntary payment over and above statutory dues, in consideration of releases in §4'],
    [{ text: 'TOTAL Separation Consideration (gross)', opts: { bold: true } }, { text: `Rs. ${settlement.total.toLocaleString('en-IN')}`, opts: { bold: true } }, { text: 'Payable June 1, 2026', opts: { bold: true } }],
  ]));

  body.push(blankLine());

  body.push(P([
    T('2.02  The Separation Consideration shall be paid by direct bank credit to the Employee\'s salary account on or before '),
    T('June 1, 2026', { bold: true, color: DARK_CHARCOAL }),
    T(', in accordance with Section 17(2) of the Code on Wages, 2019.'),
  ], { after: 160 }));

  body.push(P([
    T('2.03  '),
    T('Ex-gratia component (clause 2.01(e))', { bold: true, color: DARK_CHARCOAL }),
    T(' is paid voluntarily by the Company over and above any statutory entitlement. The Employee acknowledges and agrees that this component is consideration for the releases granted by the Employee in §4 below, and would not have been paid in the absence of this Agreement.'),
  ], { after: 160 }));

  body.push(P([
    T('2.04  '),
    T('Form 16', { bold: true, color: DARK_CHARCOAL }),
    T(' for the relevant financial year shall be issued by the Company on or before 15 June 2027 per Rule 31 of the Income Tax Rules, 1962. All amounts above are subject to applicable TDS deductions as per the Income-tax Act, 1961.'),
  ], { after: 200 }));

  // ── 3. Statutory ──
  body.push(sectionHeading('3. STATUTORY ENTITLEMENTS'));

  body.push(P([
    T('3.01  '),
    T('Provident Fund:', { bold: true, color: DARK_CHARCOAL }),
    T(' The Employee may withdraw or transfer the PF balance through the Universal Account Number (UAN) per the EPF Act, 1952 / Chapter III of the Code on Social Security, 2020. The Company shall not withhold any statutory dues.'),
  ], { after: 160 }));

  body.push(P([
    T('3.02  '),
    T('Gratuity:', { bold: true, color: DARK_CHARCOAL }),
    T(' No gratuity is payable as continuous service is less than five (5) years per Section 4(1) of the Payment of Gratuity Act, 1972.'),
  ], { after: 160 }));

  body.push(P([
    T('3.03  '),
    T('ESI:', { bold: true, color: DARK_CHARCOAL }),
    T(' Coverage continues for the prescribed grace period after the Separation Date per the ESI Act / Code on Social Security, Chapter IV.'),
  ], { after: 200 }));

  // ── 4. Releases ──
  body.push(sectionHeading('4. MUTUAL RELEASE OF CLAIMS'));

  body.push(P([
    T('4.01  '),
    T('Employee Release.', { bold: true, color: DARK_CHARCOAL }),
    T(' Subject to receipt of the Separation Consideration in §2 above, the Employee hereby '),
    T('fully, finally, and irrevocably releases and discharges', { bold: true, color: DARK_CHARCOAL }),
    T(' the Company, its directors, officers, employees, parent (Technijian, Inc., USA), subsidiaries, affiliates, successors, and assigns (collectively, the '),
    T('"Released Parties"', { bold: true, color: DARK_CHARCOAL }),
    T('), from any and all claims, demands, dues, complaints, suits, actions, causes of action, damages, losses, costs, and expenses (whether known or unknown, asserted or unasserted, contingent or accrued, statutory or contractual) arising out of or in any manner connected with the Employee\'s employment with the Company or the cessation thereof, including without limitation:'),
  ], { after: 160 }));

  body.push(P([T('(a) Any unpaid wages, allowances, bonus, incentive, leave encashment, gratuity, retrenchment compensation, notice pay, or any other monetary entitlement;')], { after: 80 }));
  body.push(P([T('(b) Any claim under the Code on Wages, 2019; the Industrial Relations Code, 2020; the Code on Social Security, 2020; the Code on Occupational Safety, Health & Working Conditions, 2020; the Punjab Shops and Commercial Establishments Act, 1958; the Payment of Gratuity Act, 1972; the EPF Act, 1952; the ESI Act, 1948; or any other Indian labour law;')], { after: 80 }));
  body.push(P([T('(c) Any claim of wrongful termination, constructive dismissal, retrenchment without compliance, unfair labour practice, or violation of natural justice;')], { after: 80 }));
  body.push(P([T('(d) Any claim under the Sexual Harassment Act, 2013 (POSH); provided that this release does NOT cover any then-pending POSH complaint, which shall continue per its statutory process;')], { after: 80 }));
  body.push(P([T('(e) Any claim for damages, mental anguish, loss of reputation, or compensation under the law of torts; and')], { after: 80 }));
  body.push(P([T('(f) Any other claim arising out of the employment relationship up to and including the Separation Date.')], { after: 160 }));

  body.push(P([
    T('4.02  '),
    T('Company Release.', { bold: true, color: DARK_CHARCOAL }),
    T(' Subject to the Employee\'s compliance with this Agreement and the surviving obligations in §5–§7 below, the Company hereby releases and discharges the Employee from all claims of monetary recovery arising out of the Employee\'s employment, save and except: (a) claims arising from fraud, criminal misconduct, or willful breach of fiduciary duty; (b) claims for return of Company property under §6; (c) claims for breach of confidentiality, IP assignment, or non-solicitation under §7; and (d) any tax, statutory, or regulatory liability that the Company may be required to deduct, withhold, or recover by operation of law.'),
  ], { after: 160 }));

  body.push(P([
    T('4.03  '),
    T('Acknowledgment of Adequacy.', { bold: true, color: DARK_CHARCOAL }),
    T(' The Employee acknowledges that the Separation Consideration in §2 (particularly the ex-gratia component in §2.01(e)) is '),
    T('adequate, sufficient, and acceptable', { bold: true, color: DARK_CHARCOAL }),
    T(' consideration for the releases in §4.01 and would not have been received absent this Agreement. The Employee further acknowledges having had the opportunity to consult with independent legal counsel of the Employee\'s choice prior to executing this Agreement.'),
  ], { after: 200 }));

  // ── 5. Confidentiality + non-disparagement ──
  body.push(sectionHeading('5. CONFIDENTIALITY AND NON-DISPARAGEMENT'));

  body.push(P([
    T('5.01  The Parties shall keep the existence and terms of this Agreement strictly confidential, save for disclosures: (a) to immediate family, legal counsel, and tax advisors on a need-to-know basis; (b) as required by law, regulation, or court order; or (c) for the purpose of enforcing this Agreement.'),
  ], { after: 160 }));

  body.push(P([
    T('5.02  The Employee\'s obligations under the executed Non-Disclosure Agreement, the Employee Handbook §Code of Business Ethics and Conduct, and the IT Acceptable Use Policy survive cessation in accordance with their terms.'),
  ], { after: 160 }));

  body.push(P([
    T('5.03  '),
    T('Non-Disparagement (Mutual).', { bold: true, color: DARK_CHARCOAL }),
    T(' Neither Party shall, directly or indirectly, make any statement (oral, written, or electronic, including on social media, glassdoor.in, LinkedIn, or to journalists) that disparages, defames, or impugns the reputation of the other Party.'),
  ], { after: 160 }));

  body.push(P([
    T('5.04  '),
    T('Reference Inquiries.', { bold: true, color: DARK_CHARCOAL }),
    T(' The Company shall, in response to any reference inquiry by a prospective employer, confirm only: (a) the Employee\'s dates of employment, (b) the Employee\'s last designation, and (c) that the Employee separated by mutual agreement. No further information shall be provided save with the Employee\'s written consent or as required by law.'),
  ], { after: 200 }));

  // ── 6. Return of property ──
  body.push(sectionHeading('6. RETURN OF COMPANY PROPERTY'));

  body.push(P([
    T('6.01  The Employee shall return on or before '),
    T('May 31, 2026', { bold: true, color: DARK_CHARCOAL }),
    T(' all Company property, including laptop, charger, peripherals, access cards, ID badge, security tokens, all credentials (passwords, VPN tokens, MFA secrets), and any documents containing Company or client confidential information.'),
  ], { after: 160 }));

  body.push(P([
    T('6.02  Any non-returned asset shall be valued at replacement cost and recovered from the Separation Consideration.'),
  ], { after: 200 }));

  // ── 7. Surviving obligations ──
  body.push(sectionHeading('7. SURVIVING OBLIGATIONS'));

  body.push(P([
    T('7.01  The Employee\'s post-employment obligations shall continue beyond the Separation Date, including: (a) Confidentiality and Non-Disclosure (perpetual for trade secrets; 3 years for other Confidential Information); (b) Intellectual Property Assignment (perpetual); (c) Non-Solicitation of clients and employees for twelve (12) months from the Separation Date; (d) Data Protection obligations under the DPDP Act, 2023 and IT Act, 2000.'),
  ], { after: 160 }));

  body.push(P([
    T('7.02  '),
    T('Post-Employment Non-Compete:', { bold: true, color: DARK_CHARCOAL }),
    T(' The Parties acknowledge that any post-employment non-compete restriction is void and unenforceable under §27 of the Indian Contract Act, 1872, and that the Employee is therefore at liberty, after the Separation Date, to take up other employment or carry on independent business, subject only to the surviving obligations in §7.01 above.'),
  ], { after: 200 }));

  // ── 8. No admission ──
  body.push(sectionHeading('8. NO ADMISSION'));

  body.push(P([
    T('8.01  This Agreement is made for the sole purpose of resolving the Parties\' separation amicably and is '),
    T('not, and shall not be construed as, an admission of liability, fault, wrongdoing, or breach', { bold: true, color: DARK_CHARCOAL }),
    T(' by either Party.'),
  ], { after: 200 }));

  // ── 9. Dispute resolution ──
  body.push(sectionHeading('9. DISPUTE RESOLUTION'));

  body.push(P([
    T('9.01  Disputes arising out of this Agreement shall first be resolved by good-faith negotiation. Failing amicable resolution, the dispute shall be referred to arbitration by a sole arbitrator under the Arbitration and Conciliation Act, 1996, seated at Panchkula, Haryana, conducted in English. The Courts at Panchkula, Haryana shall have exclusive jurisdiction. This Agreement shall be governed by and construed in accordance with the laws of India.'),
  ], { after: 200 }));

  // ── 10. Acknowledgment of voluntariness ──
  body.push(sectionHeading('10. ACKNOWLEDGMENT OF VOLUNTARINESS'));

  body.push(P([
    T('10.01  The Employee specifically acknowledges: (a) the Employee has read and understood every provision of this Agreement; (b) the Employee has had the opportunity to consult independent legal counsel of the Employee\'s choice; (c) the Employee is signing voluntarily, without coercion or undue influence, and in full knowledge of the rights being released; (d) the Employee believes the Separation Consideration to be fair and adequate consideration for the releases granted herein.'),
  ], { after: 200 }));

  // ── Signatures ──
  body.push(HR());
  body.push(P([
    T('IN WITNESS WHEREOF', { bold: true, color: DARK_CHARCOAL }),
    T(', the Parties have executed this Agreement on the date first written above.'),
  ], { after: 200 }));

  // Company signature block
  body.push(P([T('For TECHNIJIAN IT SERVICES PVT. LTD.', { bold: true, color: DARK_CHARCOAL })], { before: 200, after: 360 }));
  body.push(blankLine());
  body.push(P([T('_______________________________')], { after: 40 }));
  body.push(P([T('Ravi', { bold: true, color: DARK_CHARCOAL })], { after: 40 }));
  body.push(P([T('Director', { bold: true, color: DARK_CHARCOAL })], { after: 40 }));
  body.push(P([T('Technijian IT Services Pvt. Ltd.')], { after: 40 }));
  body.push(P([T('Panchkula, Haryana')], { after: 240 }));

  // Employee signature block
  body.push(HR());
  body.push(P([T('EMPLOYEE', { bold: true, color: CORE_BLUE })], { before: 100, after: 360 }));
  body.push(P([T('_______________________________')], { after: 40 }));
  body.push(P([T(emp.name, { bold: true, color: DARK_CHARCOAL })], { after: 40 }));
  body.push(P([T(`Employee No.: ${emp.empNo}`)], { after: 40 }));
  body.push(P([T('Date: ___________________________')], { after: 40 }));
  body.push(P([
    T('Place: ', { color: BRAND_GREY }),
    T('Panchkula, Haryana', { color: DARK_CHARCOAL, bold: true }),
  ], { after: 240 }));

  // Witnesses
  body.push(HR());
  body.push(P([T('WITNESSES', { bold: true, color: CORE_BLUE })], { before: 100, after: 160 }));
  body.push(settTable([
    ['', 'Witness 1', 'Witness 2'],
    ['Name', '__________________________', '__________________________'],
    ['Signature', '__________________________', '__________________________'],
    ['Date', '__________________________', '__________________________'],
  ]));

  body.push(blankLine());
  body.push(new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { before: 200 },
    children: [new TextRun({ text: '— Confidential employer communication. Not for further distribution. —', font: 'Calibri', size: 16, italics: true, color: BRAND_GREY })],
  }));

  return body;
}

// ─── GENERATE ──────────────────────────────────────────────────────────────
(async () => {
  if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR, { recursive: true });

  const doc = new Document({
    creator: 'Technijian IT Services Pvt. Ltd.',
    title: `Mutual Separation Agreement — ${emp.name}`,
    description: `Mutual Separation Agreement dated May 11, 2026`,
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

  const buf     = await Packer.toBuffer(doc);
  const outFile = path.join(OUT_DIR, OUT_FILE);
  fs.writeFileSync(outFile, buf);
  console.log(`Generated: ${OUT_FILE}  (${(buf.length / 1024).toFixed(1)} KB)`);
  console.log(`\nFile: ${outFile}`);
})();
