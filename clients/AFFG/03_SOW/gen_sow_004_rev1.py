"""
Generate SOW-AFFG-004-Rev1 matching the EXACT format of SOW-AFFG-004.

Title block (page 1): deepcopied from original — logo, orange rules, date, company.
Content (page 2+):    rebuilt with exact XML matching original's typography.

Original structure (first 14 body elements):
  [0]  empty para
  [1]  logo (inline image, centered, spacing after=200)
  [2]  empty para
  [3]  orange horizontal rule (pBdr bottom F67D4B sz=2)
  [4]  "Statement of Work" (24pt bold #1A1A2E centered)
  [5]  subtitle (12pt #59595B centered)
  [6]  orange horizontal rule
  [7]  empty para
  [8]  date (11pt #59595B centered)  <-- updated to "Rev 1 – May 1, 2026"
  [9]  empty para
  [10] "Technijian, Inc." (11pt bold #1A1A2E centered)
  [11] address (10pt #59595B centered)
  [12] page break
  [13] section properties para (defines page 1 margins)
  [14] Heading1 "STATEMENT OF WORK"  <-- content starts here
"""
import copy
import shutil
from docx import Document
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

SRC  = r'c:\vscode\tech-legal\tech-legal\clients\AFFG\03_SOW\SOW-AFFG-004-Managed-Device-Migration.docx'
DEST = r'c:\vscode\tech-legal\tech-legal\clients\AFFG\03_SOW\SOW-AFFG-004-Rev1-Managed-Device-Migration.docx'

DARK  = '1A1A2E'
GREY  = '59595B'
BLUE  = '006DB6'
WHITE = 'FFFFFF'
ROW   = 'F8F9FA'
BRDR  = 'DDDDDD'
TOTAL = 'E8EFF5'
FONT  = 'Open Sans'

# ── Step 1: deepcopy title block from original ────────────────────────────────
src_doc = Document(SRC)
src_body_children = list(src_doc.element.body)
title_block = [copy.deepcopy(src_body_children[i]) for i in range(14)]

# Update date text in element [8]
date_elem = title_block[8]
for t_el in date_elem.findall('.//' + qn('w:t')):
    if t_el.text and '2026' in t_el.text:
        t_el.text = 'Rev 1 \u2013 May 1, 2026'

# ── Step 2: clone original → dest, clear body ────────────────────────────────
shutil.copy2(SRC, DEST)
doc = Document(DEST)
body = doc.element.body
final_sectPr = body.find(qn('w:sectPr'))
if final_sectPr is not None:
    final_sectPr = copy.deepcopy(final_sectPr)
for child in list(body):
    body.remove(child)

# ── Step 3: reinsert title block ──────────────────────────────────────────────
for elem in title_block:
    body.append(elem)
if final_sectPr is not None:
    body.append(final_sectPr)

# ── XML helpers ───────────────────────────────────────────────────────────────

def make_rPr(size_pt=11, bold=False, color=GREY):
    rPr = OxmlElement('w:rPr')
    fonts = OxmlElement('w:rFonts')
    for attr in ('ascii', 'hAnsi', 'cs', 'eastAsia'):
        fonts.set(qn(f'w:{attr}'), FONT)
    rPr.append(fonts)
    if bold:
        rPr.append(OxmlElement('w:b'))
        rPr.append(OxmlElement('w:bCs'))
    c = OxmlElement('w:color')
    c.set(qn('w:val'), color)
    rPr.append(c)
    sz = OxmlElement('w:sz')
    sz.set(qn('w:val'), str(int(size_pt * 2)))
    rPr.append(sz)
    szC = OxmlElement('w:szCs')
    szC.set(qn('w:val'), str(int(size_pt * 2)))
    rPr.append(szC)
    return rPr

def add_run(p_elem, text, size_pt=11, bold=False, color=GREY):
    r = OxmlElement('w:r')
    r.append(make_rPr(size_pt, bold, color))
    t = OxmlElement('w:t')
    t.set(qn('xml:space'), 'preserve')
    t.text = text
    r.append(t)
    p_elem.append(r)

def insert_para(elems=None):
    """Create a bare w:p and insert before final sectPr."""
    p = OxmlElement('w:p')
    if elems:
        for e in elems:
            p.append(e)
    sectPr = body.find(qn('w:sectPr'))
    if sectPr is not None:
        body.insert(list(body).index(sectPr), p)
    else:
        body.append(p)
    return p

def heading(level, text):
    p = insert_para()
    pPr = OxmlElement('w:pPr')
    pStyle = OxmlElement('w:pStyle')
    pStyle.set(qn('w:val'), f'Heading{level}')
    pPr.append(pStyle)
    p.append(pPr)
    add_run(p, text, size_pt=11, color=GREY)
    return p

def body_para(text, before=0, after=6, bold=False, size_pt=11, color=GREY):
    p = insert_para()
    pPr = OxmlElement('w:pPr')
    sp = OxmlElement('w:spacing')
    sp.set(qn('w:before'), str(int(before * 20)))
    sp.set(qn('w:after'), str(int(after * 20)))
    pPr.append(sp)
    p.append(pPr)
    add_run(p, text, size_pt=size_pt, bold=bold, color=color)
    return p

def kv_para(label, value):
    """Matches original exactly: no pPr, two runs (bold dark + grey)."""
    p = insert_para()
    add_run(p, label, size_pt=11, bold=True, color=DARK)
    add_run(p, value, size_pt=11, color=GREY)
    return p

def bullet_para(text):
    p = insert_para()
    pPr = OxmlElement('w:pPr')
    pStyle = OxmlElement('w:pStyle')
    pStyle.set(qn('w:val'), 'ListParagraph')
    pPr.append(pStyle)
    numPr = OxmlElement('w:numPr')
    ilvl = OxmlElement('w:ilvl'); ilvl.set(qn('w:val'), '0')
    numId = OxmlElement('w:numId'); numId.set(qn('w:val'), '2')
    numPr.append(ilvl); numPr.append(numId)
    pPr.append(numPr)
    sp = OxmlElement('w:spacing')
    sp.set(qn('w:before'), '40'); sp.set(qn('w:after'), '40')
    pPr.append(sp)
    p.append(pPr)
    add_run(p, text, size_pt=11, color=GREY)
    return p

def clause_para(num, text):
    p = insert_para()
    pPr = OxmlElement('w:pPr')
    sp = OxmlElement('w:spacing'); sp.set(qn('w:before'), '40'); sp.set(qn('w:after'), '40')
    pPr.append(sp); p.append(pPr)
    add_run(p, num + '  ', size_pt=11, bold=True, color=DARK)
    add_run(p, text, size_pt=11, color=GREY)
    return p

# ── Table builder ─────────────────────────────────────────────────────────────
# Ticket cols match original exactly: [1600, 4200, 1600, 960] DXA
TICKET_COLS = [1600, 4200, 1600, 960]
TICKET_HDR  = ['Ticket', 'Title', 'Assigned To', 'Est. Hours']

def make_cell(text, fill, bold, size_pt=10, width_dxa=None):
    tc = OxmlElement('w:tc')
    tcPr = OxmlElement('w:tcPr')
    if width_dxa:
        tcW = OxmlElement('w:tcW')
        tcW.set(qn('w:w'), str(width_dxa)); tcW.set(qn('w:type'), 'dxa')
        tcPr.append(tcW)
    tcB = OxmlElement('w:tcBorders')
    for side in ('top', 'left', 'bottom', 'right'):
        b = OxmlElement(f'w:{side}')
        b.set(qn('w:val'), 'single'); b.set(qn('w:color'), BRDR); b.set(qn('w:sz'), '1')
        tcB.append(b)
    tcPr.append(tcB)
    shd = OxmlElement('w:shd')
    shd.set(qn('w:val'), 'clear'); shd.set(qn('w:color'), 'auto'); shd.set(qn('w:fill'), fill)
    tcPr.append(shd)
    tcMar = OxmlElement('w:tcMar')
    for side, val in (('top','80'),('left','120'),('bottom','80'),('right','120')):
        m = OxmlElement(f'w:{side}'); m.set(qn('w:w'), val); m.set(qn('w:type'), 'dxa')
        tcMar.append(m)
    tcPr.append(tcMar)
    va = OxmlElement('w:vAlign'); va.set(qn('w:val'), 'center'); tcPr.append(va)
    tc.append(tcPr)
    p = OxmlElement('w:p')
    pPr = OxmlElement('w:pPr')
    sp = OxmlElement('w:spacing'); sp.set(qn('w:before'), '60'); sp.set(qn('w:after'), '60')
    pPr.append(sp); p.append(pPr)
    r = OxmlElement('w:r')
    r.append(make_rPr(size_pt=size_pt, bold=bold,
                      color=WHITE if fill == BLUE else GREY))
    t_el = OxmlElement('w:t')
    t_el.set(qn('xml:space'), 'preserve'); t_el.text = str(text)
    r.append(t_el); p.append(r); tc.append(p)
    return tc

def add_table(headers, rows, col_dxa):
    tbl = OxmlElement('w:tbl')
    tblPr = OxmlElement('w:tblPr')
    tblW = OxmlElement('w:tblW')
    tblW.set(qn('w:w'), str(sum(col_dxa))); tblW.set(qn('w:type'), 'dxa')
    tblPr.append(tblW)
    tbl.append(tblPr)
    tblGrid = OxmlElement('w:tblGrid')
    for w in col_dxa:
        gc = OxmlElement('w:gridCol'); gc.set(qn('w:w'), str(w)); tblGrid.append(gc)
    tbl.append(tblGrid)
    # header row
    hdr_tr = OxmlElement('w:tr')
    for i, h in enumerate(headers):
        hdr_tr.append(make_cell(h, BLUE, bold=True, width_dxa=col_dxa[i]))
    tbl.append(hdr_tr)
    # data rows
    for row_data in rows:
        is_total = (str(row_data[0]) == '' and 'Total' in str(row_data[1])) \
                   or str(row_data[0]) in ('TOTAL', 'Total', 'Subtotal')
        fill = TOTAL if is_total else ROW
        tr = OxmlElement('w:tr')
        for i, val in enumerate(row_data):
            tr.append(make_cell(val, fill, bold=is_total, width_dxa=col_dxa[i]))
        tbl.append(tr)
    sectPr = body.find(qn('w:sectPr'))
    if sectPr is not None:
        body.insert(list(body).index(sectPr), tbl)
    else:
        body.append(tbl)
    insert_para()  # spacing after table

# ── CONTENT ───────────────────────────────────────────────────────────────────

heading(1, 'STATEMENT OF WORK')

for label, value in [
    ('SOW Number: ', 'SOW-AFFG-004 Rev 1'),
    ('Title: ', 'VDI-to-Managed-Device Migration'),
    ('Effective Date: ', 'May 1, 2026'),
    ('Supersedes: ', 'SOW-AFFG-004 (original, April 2026)'),
    ('Parent Agreement: ', 'MSA-AFFG-2026'),
    ('Primary Contact: ', 'Iris Liu  |  iris.liu@americanfundstars.com  |  949-439-2392'),
    ('Source: ', 'AFFG Managed Device Strategy (REF: AFFG-MDS-2026-04-Rev1, April 2026)'),
    ('Regulatory Scope: ', 'SEC Reg S-P (2024), FINRA 3110, FINRA 4370, SEC 17a-4, NIST SP 800-53 Rev 5'),
]:
    kv_para(label, value)

insert_para()

body_para(
    'This Statement of Work (\u201cSOW\u201d) is entered into by and between Technijian, Inc. (\u201cTechnijian\u201d), '
    '18 Technology Drive, Suite 141, Irvine, California 92618 and American Fundstars Financial Group LLC '
    '(\u201cClient\u201d or \u201cAFFG\u201d), 1 Park Plaza, Suite 210, Irvine, California 92618. '
    'Primary Contact: Iris Liu.'
)
body_para(
    'Supersedes: SOW-AFFG-003 (IT Compliance & VDI Implementation). Upon completion of this SOW, the Horizon '
    'VDI infrastructure deployed under SOW-AFFG-003 Phase 1 will be decommissioned. All compliance controls '
    'previously enforced via VDI are migrated to managed endpoints with CloudBrink ZTNA. The monthly recurring '
    'charges in Schedule A of MSA-AFFG-2026 will be amended per Section 8 of this SOW.'
)
body_para(
    'Revision Notes (Rev 1): (1) BYOD MAM-only replaces company phone MDM enrollment; '
    '(2) device fleet corrected to 4 Mac Mini (Apple ABM) + 6 Windows laptops; '
    '(3) SSO/2FA Gateway product removed \u2014 Azure Entra ID SSO used instead; '
    '(4) CloudBrink ZTNA replaces Cisco Umbrella; '
    '(5) custodian portal access controlled via office WAN IP whitelist + CloudBrink egress IP for remote laptop access.'
)

# ── Section 1 ─────────────────────────────────────────────────────────────────
heading(1, '1. PROJECT OVERVIEW')
body_para(
    'Technijian will deliver a 6-phase implementation that migrates AFFG from the Technijian Horizon VDI '
    'environment (deployed under SOW-AFFG-003) to a managed-device model using 4 Mac Mini desktops and '
    '6 Windows laptops enrolled in Microsoft Intune, with CloudBrink Zero Trust Network Access (ZTNA) '
    'replacing both the VDI egress IP whitelist and Cisco Umbrella. Mobile access is handled via BYOD with '
    'Intune MAM-only (Outlook App). This migration maintains the identical SEC/FINRA compliance posture '
    'established under SOW-AFFG-003 while eliminating VDI hosting costs and improving user experience.'
)
heading(2, '1.1 Objectives')
for obj in [
    'Enroll 4 Mac Mini (Apple Business Manager) and 6 Windows laptops (Autopilot) in Microsoft Intune with full endpoint security stack',
    'Deploy CloudBrink ZTNA to replace VDI egress IP and Cisco Umbrella; whitelist CloudBrink egress IP at Schwab Advisor Services and IBKR',
    'Configure Entra ID Conditional Access: named location policy (office WAN IP) + Intune-compliant device requirement for M365',
    'Configure BYOD Intune MAM (Outlook App) for employee personal mobile devices \u2014 no MDM enrollment required',
    'Migrate MyAudit UAM+DLP and Credential Manager from VDI to all 10 managed endpoints',
    'Execute controlled VDI-to-managed-device migration with 2-week parallel operation window',
    'Decommission Horizon VDI infrastructure and amend Schedule A for monthly savings',
]:
    bullet_para(obj)

heading(2, '1.2 Exclusions')
for exc in [
    'CloudBrink per-user subscription licensing (procured directly by AFFG)',
    'Hardware procurement (AFFG provides Mac Mini desktops and Windows laptops)',
    'Microsoft 365 license costs (AFFG procures directly \u2014 E3 or E5 required)',
    'Technijian My Archive (AFFG operates own email-archiving platform)',
    'Company-owned mobile phones and MDM enrollment thereof (BYOD model adopted)',
]:
    bullet_para(exc)

# ── Section 2 ─────────────────────────────────────────────────────────────────
heading(1, '2. IMPLEMENTATION SCOPE')

heading(2, 'Phase 1: Endpoint Foundation (Weeks 1\u20134)')
body_para('7 tickets  |  24 hours')
body_para(
    'Configure Intune Autopilot (Windows) and Apple Business Manager (Mac). Set compliance policies and '
    'device configuration profiles. Enroll and image all 10 endpoints. Deploy full security stack '
    '(CrowdStrike, Huntress, CloudBrink agent, DNS, Patch Mgmt, ScreenConnect), MyAudit UAM+DLP, and '
    'Credential Manager on all managed endpoints.'
)
heading(3, 'Phase 1 Tickets')
add_table(TICKET_HDR, [
    ('AFFG-004-001', 'Intune Autopilot Configuration & Enrollment Profiles (Windows)', 'CHD-TS1', '3'),
    ('AFFG-004-002', 'Apple Business Manager (ABM) MDM Configuration (Mac Mini)', 'CHD-TS1', '3'),
    ('AFFG-004-003', 'Intune Device Compliance & Configuration Policies', 'CHD-TS1', '2'),
    ('AFFG-004-004', 'Windows Laptop Autopilot Enrollment & Imaging \u2013 6 Devices', 'CHD-TS1', '4'),
    ('AFFG-004-005', 'Mac Mini ABM Enrollment & Imaging \u2013 4 Devices', 'CHD-TS1', '4'),
    ('AFFG-004-006', 'Endpoint Security Stack Deployment \u2013 All 10 Endpoints', 'CHD-TS1', '4'),
    ('AFFG-004-007', 'MyAudit UAM+DLP & Credential Manager Deployment \u2013 All 10 Endpoints', 'CHD-TS1', '4'),
    ('', 'Phase Total', '', '24'),
], TICKET_COLS)

heading(2, 'Phase 2: Access Control (Weeks 3\u20136)')
body_para('5 tickets  |  16 hours')
body_para(
    'Configure Entra ID Conditional Access (named location policy for office WAN IP, Intune-compliant device '
    'requirement, legacy auth block, MFA enforcement). Deploy CloudBrink ZTNA (tenant, connector, agent on '
    'all 10 endpoints, per-app micro-segmentation). Whitelist CloudBrink egress IP at Schwab Advisor Services '
    'and IBKR, replacing the former VDI egress IP. Cisco Umbrella decommissioned.'
)
heading(3, 'Phase 2 Tickets')
add_table(TICKET_HDR, [
    ('AFFG-004-008', 'Conditional Access Policy Suite (Named Location + Compliant Device + MFA)', 'IRV-TS1', '4'),
    ('AFFG-004-009', 'CloudBrink ZTNA Tenant & Connector Setup', 'IRV-TS1', '3'),
    ('AFFG-004-010', 'CloudBrink Agent Deployment \u2013 All 10 Managed Endpoints', 'CHD-TS1', '3'),
    ('AFFG-004-011', 'CloudBrink Access Policies & Micro-Segmentation', 'CHD-TS1', '3'),
    ('AFFG-004-012', 'Schwab & IBKR Access Migration (VDI Egress IP \u2192 CloudBrink Egress IP)', 'IRV-TS1', '3'),
    ('', 'Phase Total', '', '16'),
], TICKET_COLS)

heading(2, 'Phase 3: Mobile BYOD \u2013 MAM Configuration (Weeks 5\u20137)')
body_para('2 tickets  |  4 hours')
body_para(
    'Configure Intune App Protection (MAM) policies for BYOD personal devices. No MDM enrollment required. '
    'Employees install the Outlook App from their personal app store; MAM policies containerize corporate '
    'data, enforce app PIN, and enable selective corporate data wipe without touching personal content. '
    'Full M365 browser access from mobile is restricted to Intune-compliant managed devices via Conditional Access.'
)
heading(3, 'Phase 3 Tickets')
add_table(TICKET_HDR, [
    ('AFFG-004-013', 'Intune MAM Policy Configuration \u2013 BYOD Outlook App (iOS & Android)', 'CHD-TS1', '2'),
    ('AFFG-004-014', 'MAM Policy Testing & Employee BYOD Enrollment Guide', 'CHD-TS1', '2'),
    ('', 'Phase Total', '', '4'),
], TICKET_COLS)

heading(2, 'Phase 4: Migration & Cutover (Weeks 7\u201312)')
body_para('4 tickets  |  17 hours')
body_para(
    'Migrate user data from VDI to managed endpoints (Windows profile migration + Mac local profile setup). '
    'User training on managed-device workflow and CloudBrink ZTNA for remote access. 2-week parallel '
    'operation window. VDI decommission and cleanup.'
)
heading(3, 'Phase 4 Tickets')
add_table(TICKET_HDR, [
    ('AFFG-004-015', 'VDI-to-Managed-Device Data Migration (Windows + Mac)', 'CHD-TS1', '6'),
    ('AFFG-004-016', 'User Training \u2013 Managed Device & CloudBrink Remote Access Workflow', 'CHD-TS1', '4'),
    ('AFFG-004-017', 'Parallel Operation Window (VDI + Managed Devices)', 'IRV-TS1', '4'),
    ('AFFG-004-018', 'VDI Decommission & Cleanup', 'IRV-TS1', '3'),
    ('', 'Phase Total', '', '17'),
], TICKET_COLS)

heading(2, 'Phase 5: Monitoring & Validation (Weeks 11\u201314)')
body_para('4 tickets  |  13 hours')
body_para(
    'Expand monitoring to full device fleet and CloudBrink. Configure MAM compliance reporting. '
    'End-to-end security validation. Post-migration compliance gap assessment confirming equivalent regulatory posture.'
)
heading(3, 'Phase 5 Tickets')
add_table(TICKET_HDR, [
    ('AFFG-004-019', 'Monitoring Expansion \u2013 Device Fleet & CloudBrink', 'CHD-TS1', '3'),
    ('AFFG-004-020', 'MAM Compliance Reporting Configuration', 'CHD-TS1', '2'),
    ('AFFG-004-021', 'End-to-End Security Validation', 'IRV-TS1', '4'),
    ('AFFG-004-022', 'Post-Migration Compliance Gap Assessment', 'IRV-TS1', '4'),
    ('', 'Phase Total', '', '13'),
], TICKET_COLS)

heading(2, 'Phase 6: Documentation Update (Weeks 13\u201316)')
body_para('2 tickets  |  9 hours')
body_para('Update all SOW-003 compliance documents for managed-device architecture. Draft Schedule A amendment.')
heading(3, 'Phase 6 Tickets')
add_table(TICKET_HDR, [
    ('AFFG-004-023', 'Update Compliance Documentation Suite', 'CHD-TS1', '6'),
    ('AFFG-004-024', 'Schedule A Amendment \u2013 Remove VDI / Add Managed Device Services', 'IRV-TS1', '3'),
    ('', 'Phase Total', '', '9'),
], TICKET_COLS)

# ── Section 3 ─────────────────────────────────────────────────────────────────
heading(1, '3. CONTROL-TO-CITATION MAP')
body_para('The following table maps each design component to its control objective and regulatory citations:')
add_table(
    ['Design Component', 'Control Objective', 'Citation(s)'],
    [
        ('Intune-managed endpoints (4 Mac Mini + 6 Windows laptops)',
         'All 10 users on company-owned, encrypted, policy-enforced devices',
         'Reg S-P 248.30(a)(1)-(3); FINRA 3110(a)'),
        ('CloudBrink ZTNA (replaces Cisco Umbrella + VDI egress IP)',
         'Zero-trust access; device posture verified per session; DNS filtering and ZTNA egress',
         'Reg S-P 248.30(a)(3); NIST AC-17, SC-7'),
        ('Office WAN IP + CloudBrink egress whitelist at Schwab & IBKR',
         'Only office or CloudBrink-tunneled devices reach custodian portals \u2014 MFA alone does not restrict device origin',
         'Reg S-P 248.30(a)(3); NIST AC-3, SC-7'),
        ('Entra Conditional Access (Named Location + Compliant Device)',
         'M365 restricted to office WAN IP or Intune-compliant device; legacy auth blocked',
         'Reg S-P 248.30(a)(3); NIST AC-3, IA-2(1)'),
        ('Intune MAM \u2013 BYOD Outlook App',
         'Corporate email containerized on personal device; selective corporate wipe on separation',
         'Reg S-P 248.30(a)(1)-(3); NIST AC-19, MP-6'),
        ('Technijian MyAudit UAM+DLP',
         'Block USB, local download, print, clipboard, screen capture on all managed endpoints',
         'Reg S-P 248.30(a)(3); NIST AC-19, MP-7'),
        ('Technijian Veeam Backup for M365',
         'Immutable, non-rewriteable backup of full M365 tenant',
         'SEC Rule 17a-4(b),(f); FINRA 4511'),
        ('Technijian monthly assessment',
         'Detect drift; attested evidence of ongoing control operation',
         'FINRA 3110(c); FINRA 3120'),
    ],
    [2100, 2900, 2360]
)

# ── Section 4 ─────────────────────────────────────────────────────────────────
heading(1, '4. DELIVERABLES')
for d in [
    '10 Intune-managed company endpoints (4 Mac Mini via ABM, 6 Windows laptops via Autopilot) with full security stack',
    'CloudBrink ZTNA deployed with per-application micro-segmented access and device posture enforcement',
    'Schwab and IBKR migrated from VDI egress IP to CloudBrink egress IP whitelist',
    'Entra Conditional Access: M365 restricted to office WAN IP or Intune-compliant device; legacy auth blocked',
    'MyAudit UAM+DLP and Credential Manager on all 10 managed endpoints (replaces VDI-based deployment)',
    'Intune MAM policies for BYOD personal mobile devices (Outlook App, iOS and Android)',
    'Updated compliance documentation suite reflecting managed-device architecture',
    'Schedule A amendment reflecting monthly cost reduction',
    'Post-migration compliance gap assessment confirming equivalent regulatory posture',
]:
    bullet_para(d)

# ── Section 5 ─────────────────────────────────────────────────────────────────
heading(1, '5. PRICING AND PAYMENT')
heading(2, '5.1 Labor Summary')
add_table(
    ['Role', 'Rate', 'Hours', 'Labor'],
    [
        ('US Tech Support (IRV-TS1)', '$150/hr', '24', '$3,600.00'),
        ('India Tech Support (CHD-TS1)', '$45/hr', '59', '$2,655.00'),
        ('TOTAL', '', '83 hrs', '$6,255.00'),
    ],
    [4000, 1400, 1200, 1760]
)

heading(2, '5.2 Payment Schedule')
add_table(
    ['Milestone', 'Trigger', 'Amount'],
    [
        ('50% upon SOW execution', 'SOW signed by both parties', '$3,127.50'),
        ('25% upon Phase 4 completion', 'VDI decommissioned', '$1,563.75'),
        ('25% upon Phase 6 delivery', 'Documentation + Schedule A amendment accepted', '$1,563.75'),
        ('Total', '', '$6,255.00'),
    ],
    [3000, 4200, 1160]
)

heading(2, '5.3 Payment Terms')
body_para(
    'All invoices are due and payable within thirty (30) days of the invoice date. '
    'Late payments are subject to a late fee of 1.5% per month on the unpaid balance.'
)

# ── Section 6 ─────────────────────────────────────────────────────────────────
heading(1, '6. ASSUMPTIONS')
for a in [
    'AFFG has procured 4 Mac Mini desktops and 6 Windows 11 Pro/Enterprise laptops suitable for Intune enrollment',
    'AFFG enrolls Mac Minis in Apple Business Manager (ABM) prior to Phase 1; Technijian will assist with ABM setup',
    'AFFG has procured CloudBrink ZTNA per-user subscription licenses for all 10 users',
    "AFFG\u2019s M365 tenant remains licensed at E3 or E5 (Intune, Conditional Access, and DLP included)",
    'AFFG employees use personal mobile devices (BYOD) for Outlook App only; no company phones are procured',
    'AFFG provides the office WAN static IP address to Technijian prior to Phase 2 commencement',
    'Schwab Advisor Services and IBKR approve transition from VDI egress IP to CloudBrink egress IP within standard timelines',
    'The 7 VDI agents are available for managed-device migration and training during Weeks 7\u201310',
    'All MyAudit UAM+DLP and Credential Manager licenses are transferred from VDI to managed endpoints at no additional cost',
]:
    bullet_para(a)

# ── Section 7 ─────────────────────────────────────────────────────────────────
heading(1, '7. EXCLUSIONS')
for e in [
    'CloudBrink per-user subscription licensing (AFFG-procured)',
    'Hardware procurement (Mac Mini desktops and Windows laptops)',
    'Microsoft 365 license costs (AFFG procures directly)',
    'Technijian My Archive (AFFG operates own archiving)',
    'Company-owned mobile phones and MDM enrollment thereof',
    'Remediation beyond defined scope; issues requiring additional work will be scoped as a separate Change Order',
]:
    bullet_para(e)

# ── Section 8 ─────────────────────────────────────────────────────────────────
heading(1, '8. MONTHLY COST IMPACT')
heading(2, '8.1 Current vs. Proposed Monthly Recurring')
body_para('Current Monthly (SOW-003 implemented, VDI model) = $5,770.45/mo')
add_table(
    ['Category', 'Current Monthly', 'Proposed Monthly', 'Change'],
    [
        ('Horizon VDI Workstations (7 agents)', '$2,433.20', '$0.00', '\u2212$2,433.20'),
        ('Physical Desktop Security \u2013 10 endpoints (excl. Umbrella @ $22.50/device)', '$238.50', '$225.00', '\u2212$13.50'),
        ('CloudBrink ZTNA \u2013 10 endpoints @ $8.00 (replaces Cisco Umbrella @ $4.00)', '$0.00', '$80.00', '+$80.00'),
        ('Managed Endpoint Add-Ons \u2013 10 endpoints (see 8.2)', '$0.00', '$1,131.00', '+$1,131.00'),
        ('All-User Services (31 M365 users)', '$441.75', '$441.75', '$0.00'),
        ('Domain / Site / IP Services', '$162.00', '$162.00', '$0.00'),
        ('Production Storage (VDI profiles)', '$400.00', '$0.00', '\u2212$400.00'),
        ('Backup Storage (V365 / SEC 17a-4)', '$100.00', '$100.00', '$0.00'),
        ('Virtual Staff Support (unchanged)', '$1,995.00', '$1,995.00', '$0.00'),
        ('TOTAL MONTHLY', '$5,770.45', '$4,134.75', '\u2212$1,635.70'),
    ],
    [3800, 1440, 1440, 1680]
)

heading(2, '8.2 Managed Endpoint Add-Ons Detail (NEW \u2013 10 endpoints)')
add_table(
    ['Service', 'Code', 'Qty', 'Unit Price', 'Monthly'],
    [
        ('MyAudit UAM+DLP / 1-Year', 'AMDLP1Y', '10', '$108.10', '$1,081.00'),
        ('Credential Manager', 'CRM', '10', '$5.00', '$50.00'),
        ('Subtotal', '', '', '', '$1,131.00'),
    ],
    [3200, 1200, 640, 1440, 1880]
)
body_para(
    'Note: SSO/2FA Gateway product removed \u2014 Azure Entra ID SSO (included in M365 E3) provides identity '
    'federation and MFA natively. CloudBrink subscription is AFFG-procured. Cisco Umbrella removed from '
    'security stack; CloudBrink ZTNA provides DNS filtering, zero-trust egress, and replaces the VDI egress IP.'
)

# ── Sections 9\u201311 ─────────────────────────────────────────────────────────────
heading(1, '9. CHANGE MANAGEMENT')
for num, text in [
    ('9.01.', 'Any changes to the scope, schedule, or pricing of this SOW must be documented in a written Change Order signed by both Parties before work on the change begins.'),
    ('9.02.', 'If Client requests work outside the defined scope, Technijian shall provide a Change Order detailing the additional work, estimated hours, and cost impact.'),
    ('9.03.', "Technijian shall not proceed with out-of-scope work without an approved Change Order, except in cases where delay would result in harm to Client\u2019s systems."),
]:
    clause_para(num, text)

heading(1, '10. ACCEPTANCE')
for num, text in [
    ('10.01.', 'Upon completion of each phase, Technijian shall notify Client in writing that the deliverables are ready for review.'),
    ('10.02.', 'Client shall review the deliverables and provide written acceptance or a detailed description of deficiencies within five (5) business days.'),
    ('10.03.', 'If Client does not respond within the review period, the deliverables shall be deemed accepted.'),
    ('10.04.', 'If deficiencies are identified, Technijian shall correct them and resubmit for review. This process shall repeat until acceptance is achieved.'),
]:
    clause_para(num, text)

heading(1, '11. GOVERNING TERMS')
clause_para('11.01.', 'This SOW is governed by the Master Service Agreement MSA-AFFG-2026 between the Parties. '
    'In the event of a conflict between this SOW and the MSA, the MSA shall prevail unless this SOW expressly states otherwise.')

# ── Signatures ────────────────────────────────────────────────────────────────
heading(1, 'SIGNATURES')
body_para('TECHNIJIAN, INC.', bold=True, color=DARK, before=6, after=0)
for line in ['By: ___________________________________',
             'Name: _________________________________',
             'Title: _________________________________',
             'Date: _________________________________']:
    body_para(line, before=12, after=0)

insert_para()
body_para('AMERICAN FUNDSTARS FINANCIAL GROUP LLC', bold=True, color=DARK, before=6, after=0)
for line in ['By: ___________________________________',
             'Name: _________________________________',
             'Title: _________________________________',
             'Date: _________________________________']:
    body_para(line, before=12, after=0)

# ── Save ──────────────────────────────────────────────────────────────────────
doc.save(DEST)
print('Saved:', DEST)
