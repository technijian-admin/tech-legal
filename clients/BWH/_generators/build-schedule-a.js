/**
 * Brandywine Homes (BWH) — Schedule A: Monthly Managed Services
 * Output: BWH-Schedule-A-Monthly-Services.docx
 * Reference document (NOT signed)
 */
const { Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
        ImageRun, AlignmentType, LevelFormat,
        BorderStyle, WidthType, ShadingType, PageBreak } = require('docx');
const fs = require('fs');
const path = require('path');
const helpers = require('../../../scripts/brand-helpers');

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

function bullet(text) {
  return new Paragraph({
    spacing: { after: 40 },
    indent: { left: 720, hanging: 360 },
    children: [
      new TextRun({ text: "\u2022  ", font: "Open Sans", size: 22, color: CORE_BLUE }),
      new TextRun({ text, font: "Open Sans", size: 22, color: BRAND_GREY }),
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
          "Schedule A",
          "Monthly Managed Services\nAttached to MSA-BWH",
          EFFECTIVE_DATE
        ),
      ]
    },

    // ── SCHEDULE A BODY ──
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
        colorBanner("SCHEDULE A \u2014 MONTHLY MANAGED SERVICES", CORE_BLUE, WHITE, 28),
        spacer(100),
        bodyText("Attached to Master Service Agreement MSA-BWH"),
        bodyText(`Effective Date: ${EFFECTIVE_DATE}`),
        bodyText(`This Schedule describes the Monthly Managed Services provided by Technijian, Inc. (\u201CTechnijian\u201D) to ${CLIENT_NAME} (\u201CClient\u201D) under the Master Service Agreement.`),

        // ── PART 1: ONLINE SERVICES ──
        spacer(),
        colorBanner("PART 1 \u2014 ONLINE SERVICES", DARK_CHARCOAL, WHITE, 24),
        spacer(100),

        sectionHeader("1.1 Description"),
        bodyText("Online Services include managed infrastructure, security, monitoring, and related IT services delivered on a recurring monthly basis. Services are selected from the Technijian Price List and itemized in the Service Order below."),

        spacer(100),
        sectionHeader("1.2 Service Categories"),
        bodyText("Online Services are organized into the following categories. Specific services, quantities, and pricing are detailed in the Service Order attached to this Schedule."),
        styledTable(
          ["Category", "Description"],
          [
            ["Desktop Management", "Patch management, antivirus (CrowdStrike, Huntress), DNS filtering, remote access, monitoring"],
            ["Server Management", "Patch management, image backup, antivirus (CrowdStrike, Huntress), remote access, monitoring"],
            ["Cloud Infrastructure", "Backup storage, Veeam management"],
            ["Network & Security", "Switch config backup, firewall traffic monitoring, WiFi monitoring, pen testing, storage monitoring"],
            ["Email & Compliance", "Site assessment, DMARC/DKIM, anti-spam, phishing training, Veeam 365, file sharing"],
          ]
        ),

        spacer(),
        sectionHeader("1.3 Service Order"),
        bodyText("The specific services, quantities, and monthly pricing for Client are detailed below. The Service Order may be updated by mutual written agreement."),

        // Desktop Management (32 desktops)
        spacer(100),
        bodyBoldPrefix("Desktop Management (32 desktops)", ""),
        styledTable(
          ["Service", "Code", "Unit Price", "Qty", "Monthly"],
          [
            ["Patch Management", "PMW", "$4.00", "32", "$128.00"],
            ["My Secure Internet", "SI", "$6.00", "32", "$192.00"],
            ["My Remote", "MR", "$2.00", "32", "$64.00"],
            ["My Ops \u2014 Net", "OPS-NET", "$3.25", "32", "$104.00"],
            ["AVH Protection \u2014 Desktop (Huntress)", "AVMH", "$6.00", "32", "$192.00"],
            ["AV Protection \u2014 Desktop (CrowdStrike)", "AVD", "$8.50", "32", "$272.00"],
            ["Desktop Subtotal", "", "", "", "$952.00"],
          ],
          [6]
        ),

        // Server Management (12 servers)
        spacer(100),
        bodyBoldPrefix("Server Management (12 servers)", ""),
        styledTable(
          ["Service", "Code", "Unit Price", "Qty", "Monthly"],
          [
            ["Patch Management", "PMW", "$4.00", "12", "$48.00"],
            ["My Secure Internet", "SI", "$6.00", "12", "$72.00"],
            ["My Remote", "MR", "$2.00", "12", "$24.00"],
            ["My Ops \u2014 Net", "OPS-NET", "$3.25", "12", "$39.00"],
            ["Image Backup (Veeam)", "IB", "$15.00", "12", "$180.00"],
            ["AVH Protection \u2014 Server (Huntress)", "AVHS", "$6.00", "12", "$72.00"],
            ["AV Protection \u2014 Server (CrowdStrike)", "AVS", "$10.50", "12", "$126.00"],
            ["Server Subtotal", "", "", "", "$561.00"],
          ],
          [7]
        ),

        // Cloud Infrastructure
        spacer(100),
        bodyBoldPrefix("Cloud Infrastructure", ""),
        styledTable(
          ["Service", "Code", "Unit Price", "Qty", "Monthly"],
          [
            ["Backup Storage (TB)", "TB-BSTR", "$50.00", "13", "$650.00"],
            ["Veeam One", "VONE", "$3.00", "11", "$33.00"],
            ["Cloud Subtotal", "", "", "", "$683.00"],
          ],
          [2]
        ),

        // Network & Security
        spacer(100),
        bodyBoldPrefix("Network & Security", ""),
        styledTable(
          ["Service", "Code", "Unit Price", "Qty", "Monthly"],
          [
            ["My Ops \u2014 Config (Switches)", "OPS-BKP", "$6.00", "3", "$18.00"],
            ["Real Time Pen Testing", "RTPT", "$7.00", "6", "$42.00"],
            ["My Ops \u2014 Traffic (Firewalls)", "OPS-TR", "$14.00", "1", "$14.00"],
            ["My Ops \u2014 Wifi (APs)", "OPS-WF", "$1.00", "6", "$6.00"],
            ["My Ops \u2014 Storage (Disks)", "OPS-ST", "$4.75", "2", "$9.50"],
            ["Sophos Firewall Subscription 2C-4G", "SO-2C4G", "$270.00", "1", "$270.00"],
            ["MPC Edge Appliance (16GB/8 cores/512GB)", "Edge-16M", "$100.00", "1", "$100.00"],
            ["Network Subtotal", "", "", "", "$459.50"],
          ],
          [7]
        ),

        // Email & Compliance
        spacer(100),
        bodyBoldPrefix("Email & Compliance", ""),
        styledTable(
          ["Service", "Code", "Unit Price", "Qty", "Monthly"],
          [
            ["Site Assessment", "SA", "$50.00", "1", "$50.00"],
            ["DMARC/DKIM", "DKIM", "$20.00", "1", "$20.00"],
            ["Anti-Spam Standard", "ASA", "$6.25", "83", "$518.75"],
            ["Phishing Training", "PHT", "$6.00", "85", "$510.00"],
            ["Veeam 365", "V365", "$2.50", "110", "$275.00"],
            ["My Disk", "MDU", "$16.00", "1", "$16.00"],
            ["Email Subtotal", "", "", "", "$1,389.75"],
          ],
          [6]
        ),

        // Grand Total
        spacer(100),
        styledTable(
          ["", "", "", "", ""],
          [
            ["TOTAL MONTHLY ONLINE SERVICES", "", "", "", "$4,045.25"],
          ],
          [0]
        ),

        spacer(),
        sectionHeader("1.4 Service Levels"),
        styledTable(
          ["Service Level", "Target"],
          [
            ["Infrastructure Uptime", "99.9% monthly (excluding scheduled maintenance)"],
            ["Scheduled Maintenance", "Tuesday evenings and Saturdays (with advance notice)"],
            ["Critical Incident Response", "Within 1 hour of notification"],
            ["Standard Support Response", "Within 4 business hours"],
            ["Emergency Maintenance", "As needed with reasonable notice"],
          ]
        ),

        spacer(),
        sectionHeader("1.4a Service Level Remedies"),
        numbered("(a)", "Service Credits. If Technijian fails to meet the Infrastructure Uptime target of 99.9% in any calendar month, Client shall be entitled to a service credit equal to 5% of the monthly recurring charges for the affected service for each full 0.1% below the target, up to a maximum credit of 25% of the monthly recurring charges for that service."),
        numbered("(b)", "Chronic Failure. If Technijian fails to meet the Infrastructure Uptime target for three (3) or more consecutive months, Client shall have the right to terminate the affected service without penalty upon thirty (30) days written notice."),
        numbered("(c)", "Credit Requests. To receive a service credit, Client must submit a written request within thirty (30) days of the end of the affected month. Service credits shall be applied against future invoices and shall not be paid as cash refunds."),
        numbered("(d)", "Exclusions. Service level targets and remedies do not apply during scheduled maintenance windows, force majeure events, or outages caused by Client\u2019s actions, third-party services not managed by Technijian, or factors outside Technijian\u2019s reasonable control."),
        numbered("(e)", "Sole Remedy. Service credits under this Section 1.4a are Client\u2019s sole and exclusive remedy for Technijian\u2019s failure to meet the applicable service levels."),

        spacer(),
        sectionHeader("1.5 Monitoring and Reporting"),
        bodyText("Technijian shall provide:"),
        numbered("(a)", "24/7 monitoring of Client\u2019s infrastructure included in the Service Order;"),
        numbered("(b)", "Monthly service reports summarizing uptime, incidents, and support activity; and"),
        numbered("(c)", "Quarterly service reviews with Client\u2019s designated representative."),
        numbered("(d)", "Escalation Path. Support requests shall be escalated as follows: Tier 1 (initial response) \u2014 assigned technician; Tier 2 (within 4 hours if unresolved) \u2014 senior engineer or team lead; Tier 3 (within 8 hours if unresolved) \u2014 department manager or CTO Advisory."),

        // ── SIP TRUNK (one line) ──
        spacer(),
        colorBanner("PART 2 \u2014 SIP TRUNK SERVICES", DARK_CHARCOAL, WHITE, 24),
        spacer(100),
        bodyText("SIP Trunk Services may be added via Service Order amendment."),

        // ── PART 3: VIRTUAL STAFF ──
        new Paragraph({ children: [new PageBreak()] }),
        colorBanner("PART 3 \u2014 VIRTUAL STAFF (CONTRACTED SUPPORT)", DARK_CHARCOAL, WHITE, 24),
        spacer(100),

        sectionHeader("3.1 Description"),
        bodyText("Virtual Staff services provide Client with dedicated technology support personnel on a contracted basis. This service operates on a 12-month cycle-based billing model as described below."),

        spacer(100),
        sectionHeader("3.2 Support Roles"),
        styledTable(
          ["Role", "Location", "Hours/Mo", "BWH Rate"],
          [
            ["Systems Architect", "US (IRV-AD1)", "5.00", "$170.00/hr"],
            ["USA Tech Normal", "US (IRV-TS1)", "15.26", "$106.25/hr"],
            ["India Tech Normal", "India (CHD-TS1)", "58.13", "$12.75/hr"],
            ["India Tech After Hours", "India (CHD-TS1)", "42.82", "$25.50/hr"],
          ]
        ),

        spacer(),
        sectionHeader("3.3 Cycle-Based Billing Model"),
        numbered("(a)", "Billing Cycle. Client has selected a billing cycle of 12 months (the \u201CCycle\u201D). The purpose of the Cycle is to provide Client with a structured path to eliminate any unpaid hour balance by the end of each Cycle, thereby avoiding cancellation fees."),
        numbered("(b)", "Monthly Billed Amount Calculation. The fixed monthly billing rate for each role is calculated as follows:"),
        numbered("1.", "At the start of each new Cycle, Technijian calculates the average monthly hours consumed per role during the previous Cycle, excluding the final month of that Cycle.", 1),
        numbered("2.", "This average is then adjusted to account for any unpaid hour balance carried forward from the previous Cycle, so that the new monthly billed amount is set at a level designed to bring the unpaid balance to zero by the end of the current Cycle.", 1),
        numbered("3.", "The monthly billed amount for each role equals the adjusted monthly billed hours multiplied by the applicable Contracted Rate from the Rate Card (Schedule C).", 1),
        numbered("(c)", "Running Balance. Technijian maintains a running balance for each role:"),
        numbered("1.", "At the start of each month, the running balance is adjusted by adding the actual hours used during the previous month and subtracting the monthly billed hours for that month.", 1),
        numbered("2.", "A positive running balance indicates hours consumed in excess of billed amounts (an unpaid hour balance that the Cycle is designed to resolve).", 1),
        numbered("3.", "A negative running balance indicates hours billed in excess of consumption. A negative balance does not entitle Client to a credit or refund; it simply means Client has no unpaid hour balance (the unpaid balance is zero). The underlying usage data from months producing a negative balance is used in calculating the average for the next Cycle per Section 3.3(b).", 1),
        numbered("(d)", "Cycle Reconciliation. At the end of each Cycle:"),
        numbered("1.", "The running balance for each role is reconciled.", 1),
        numbered("2.", "Any net positive balance (hours consumed but not yet billed) is carried forward into the next Cycle. The next Cycle\u2019s monthly billed amount will be recalculated per Section 3.3(b) to absorb this balance and target a zero unpaid balance by the end of the next Cycle.", 1),
        numbered("3.", "Any net negative balance (hours billed but not consumed) resets to zero. No credit or refund is issued. The actual usage data from the completed Cycle is used to calculate the monthly billed amount for the next Cycle per Section 3.3(b).", 1),
        numbered("(e)", "Cancellation. If Client terminates Virtual Staff services or this Agreement:"),
        numbered("1.", "Any positive running balance (actual hours under the current Cycle exceeding billed hours under the current Cycle) shall become immediately due and payable at the Rate Card Hourly Rate ($150.00 per hour) from Schedule C, not the Contracted Rate. The Contracted Rates set forth in Section 3.2 are provided in consideration for Client\u2019s commitment to the Cycle, and shall not apply to unpaid hours upon cancellation under any circumstance.", 1),
        numbered("2.", "Any negative running balance (billed hours exceeding actual hours) does not entitle Client to a credit, refund, or offset against the final invoice. The unpaid balance is simply zero and no further amounts are due from either Party with respect to that role.", 1),
        numbered("3.", "The Legacy Balance described in Section 12.01 of the Master Service Agreement shall be governed by the termination treatment set forth in Section 12.01(c) of the Master Service Agreement, not by this subsection (e). For avoidance of doubt, no rate other than the Rate Card Hourly Rate ($150.00 per hour) per Schedule C shall apply to either the Cycle running balance under this Section 3.3 or the Legacy Balance under Section 12.01 of the Master Service Agreement upon cancellation, and no reduced or discounted rate shall apply.", 1),
        numbered("(f)", "Minimum Contracted Hours. The monthly billed hours for each role shall not fall below fifty percent (50%) of the initial contracted hours established in the Service Order for that role (the \u201CMinimum Hours\u201D). If actual usage drops below the Minimum Hours for three (3) or more consecutive months, Technijian may adjust the monthly billed hours down to the Minimum Hours at the start of the next Cycle, but shall not reduce below the Minimum Hours without mutual written agreement. The Minimum Hours provision ensures that Technijian can maintain dedicated staffing resources and reserved capacity for Client. If Client wishes to reduce hours below the Minimum, Client may request a Service Order amendment, subject to Technijian\u2019s approval and a thirty (30) day notice period."),

        spacer(),
        sectionHeader("3.4 Weekly Service Reports"),
        bodyText("Technijian shall provide Client with weekly service reports that detail:"),
        numbered("(a)", "Each support ticket addressed during the period;"),
        numbered("(b)", "The role, resource name, and hours spent per ticket;"),
        numbered("(c)", "Whether the work was performed during normal or after-hours;"),
        numbered("(d)", "A description of the work performed; and"),
        numbered("(e)", "The current running balance for each role."),

        spacer(),
        sectionHeader("3.5 Service Level Commitments"),
        bodyText("Technijian commits to a single measurable Service Level Agreement under this Schedule: Response Time. Resolution times are not guaranteed because Client\u2019s environment may include equipment that is out of warranty, third-party software requiring vendor escalation, and other factors outside Technijian\u2019s control."),
        spacer(60),
        styledTable(
          ["Service Level", "Commitment"],
          [
            ["Response Time (all severities)", "Within four (4) business hours of ticket creation in the Client Portal"],
            ["Resolution Time", "Not guaranteed; commercially reasonable efforts only"],
            ["Infrastructure Uptime (target)", "99.9% monthly, commercially reasonable efforts (no service credit unless expressly granted under Section 3.5a)"],
            ["Scheduled Maintenance", "Tuesday evenings and Saturdays, with reasonable advance notice"],
            ["Emergency Maintenance", "As needed with reasonable notice"],
          ]
        ),
        spacer(80),
        numbered("(a)", "Response Time Definition. \u201CResponse\u201D means initial human acknowledgment of the support ticket in the Client Portal, including assignment to a technician and confirmation of receipt to Client. Response Time is measured from Client Portal ticket creation timestamp to ticket acknowledgment timestamp. Response Time applies to all support tickets regardless of severity classification. A timely deferral notice issued under Section 3.6 shall constitute a Response within the meaning of this subsection, and the deferred ticket shall be excluded from the breach calculation under Master Service Agreement Section 12.01(d) unless timely escalated under Section 3.6(f)."),
        numbered("(b)", "Resolution Not Guaranteed. The Parties acknowledge that resolution timeframes depend on factors that may include third-party vendor support timelines, equipment warranty status, software vendor escalation cycles, hardware availability, and other circumstances beyond Technijian\u2019s reasonable control. Technijian shall use commercially reasonable efforts to drive each support ticket to resolution but does not commit to any specific resolution timeframe under this Schedule."),
        numbered("(c)", "Measurement Period. Response Time compliance is measured per billing month using Client Portal ticket data. Tickets opened in a given billing month are evaluated for Response Time compliance based on the timestamps recorded in the Client Portal."),
        numbered("(d)", "Relationship to MSA Section 12.01. Failure to meet the Response Time Service Level may, if material and uncured as defined in Section 12.01(d) of the Master Service Agreement, support a termination for cause under MSA Section 2.04(a) and trigger the Legacy Balance waiver in MSA Section 12.01(c)(2). Resolution Time and Infrastructure Uptime are not bases for the Legacy Balance waiver under MSA Section 12.01(c)(2)."),

        spacer(),
        sectionHeader("3.5a Service Level Remedies"),
        numbered("(a)", "Service Credits. If Technijian fails to meet the Infrastructure Uptime target of 99.9% in any calendar month, Client shall be entitled to a service credit equal to 5% of the monthly recurring charges for the affected service for each full 0.1% below the target, up to a maximum credit of 25% of the monthly recurring charges for that service."),
        numbered("(b)", "Chronic Failure. If Technijian fails to meet the Infrastructure Uptime target for three (3) or more consecutive months, Client shall have the right to terminate the affected service without penalty upon thirty (30) days written notice."),
        numbered("(c)", "Credit Requests. To receive a service credit, Client must submit a written request within thirty (30) days of the end of the affected month. Service credits shall be applied against future invoices and shall not be paid as cash refunds."),
        numbered("(d)", "Exclusions. Service level targets and remedies do not apply during scheduled maintenance windows, force majeure events, or outages caused by Client\u2019s actions, third-party services not managed by Technijian, or factors outside Technijian\u2019s reasonable control."),
        numbered("(e)", "Sole Remedy. Service credits under this Section are Client\u2019s sole and exclusive remedy for Technijian\u2019s failure to meet the applicable service levels."),

        spacer(),
        sectionHeader("3.6 Usage Notifications and Cycle Discipline"),
        numbered("(a)", "Notifications. Technijian shall track Client\u2019s monthly Virtual Staff hour consumption against the monthly billed hours per role and shall provide notifications to Client through the Client Portal and to Client\u2019s designated point of contact when cumulative consumption in a billing month reaches: (i) 50% of monthly billed hours; (ii) 60% of monthly billed hours; (iii) 70% of monthly billed hours; and (iv) 80% of monthly billed hours."),
        numbered("(b)", "80% Threshold. Upon reaching 80% of monthly billed hours for any role in a billing month, Technijian shall notify Client that the monthly cap is approaching, and Technijian may decline to begin new non-emergency support requests under that role for the remainder of the billing month. Client may continue to submit emergency (P1 production-down) requests, which Technijian shall continue to address subject to the Response Time Service Level in Section 3.5. A written deferral notice issued by Technijian in response to a non-emergency request submitted at or above the 80% threshold shall constitute the Response under Section 3.5(a) for purposes of SLA compliance, and the deferred ticket shall be excluded from the breach calculation under MSA Section 12.01(d) unless Client timely escalates the ticket under subsection (f) below."),
        numbered("(c)", "Purpose. The notification thresholds and the 80% practice are intended to maintain cycle integrity by helping ensure Client\u2019s actual consumption stays within monthly billed hours during the term of this Schedule, so that the under-utilization paydown described in Section 3.3 and Section 12.01 of the Master Service Agreement can resolve the Legacy Balance through cycle dynamics rather than through end-of-cycle invoicing or termination."),
        numbered("(d)", "Override. Client may direct Technijian in writing to continue non-emergency work beyond 80% of monthly billed hours for a given role and billing month. Hours worked beyond 80% on Client\u2019s written direction shall be tracked and may, at Technijian\u2019s option, be billed as out-of-contract services per Schedule C if persistent overuse is observed for more than three (3) consecutive billing months."),
        numbered("(e)", "No Service Reduction. The 80% practice does not reduce the monthly billed hours for which Client is invoiced, nor does it constitute a credit, refund, or offset of any kind. The 80% practice is a queue-management mechanism to support cycle paydown and may be adjusted by mutual written agreement of the Parties at any time."),
        numbered("(f)", "Escalation. If Client in good faith believes a deferred ticket constitutes an Emergency (as defined in subsection (g) below) or otherwise should not have been deferred, Client shall escalate the ticket in writing within five (5) business days of the deferral notice, identifying the specific ticket and the basis for reclassification. Upon receipt of a timely escalation, Technijian shall reclassify the ticket and respond per the Response Time Service Level in Section 3.5. Tickets not escalated within the five (5) business day window shall be deemed properly deferred and shall not count toward the breach calculation in MSA Section 12.01(d). Improper deferrals identified through the escalation process do count toward the Section 12.01(d) calculation if Technijian fails to reclassify and respond within the four (4) business hour window after escalation."),
        numbered("(g)", "Emergency Definition. For purposes of Section 3.5 and this Section 3.6, an \u201CEmergency\u201D (also \u201CP1 production-down\u201D) means a support request involving any of the following: (i) total loss of access to a production system used by five (5) or more end users; (ii) total loss of access to email, file shares, or critical line-of-business applications affecting five (5) or more end users; (iii) a confirmed cybersecurity incident involving active compromise of Client systems or data; or (iv) physical site outage at a Client location. Severity classification is initially made by Client at the time of ticket submission and may be reclassified by Technijian upon review of the ticket details, subject to Client\u2019s escalation rights under subsection (f)."),

        spacer(),
                // ── GENERAL TERMS FOR SCHEDULE A ──
        new Paragraph({ children: [new PageBreak()] }),
        colorBanner("GENERAL TERMS FOR THIS SCHEDULE", DARK_CHARCOAL, WHITE, 24),
        spacer(100),

        sectionHeader("Payment and Collection"),
        bodyText("All payment terms, late fees, dispute procedures, and collection remedies for invoices arising under this Schedule are governed by Section 3 of the Master Service Agreement."),

        spacer(100),
        sectionHeader("Changes to Services"),
        bodyText("Either Party may request changes to the services described in this Schedule by providing thirty (30) days written notice. Changes to quantities, roles, or service levels shall be documented in an updated Service Order signed by both Parties."),

        spacer(100),
        sectionHeader("Pricing Adjustments"),
        bodyText("Pricing for services under this Schedule is subject to the Rate Card (Schedule C). Technijian may adjust rates upon sixty (60) days written notice, effective at the start of any month-to-month continuation period under MSA Section 2.02, or upon mutual written agreement during the Initial Term."),

      ]
    },
  ]
});

// ── Generate DOCX ──
const outPath = path.join(__dirname, '..', '02_MSA', 'BWH-Schedule-A-Monthly-Services.docx');
Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync(outPath, buffer);
  const sz = fs.statSync(outPath).size;
  console.log(`Created: ${outPath}  (${sz.toLocaleString()} bytes)`);
}).catch(err => {
  console.error('Error generating DOCX:', err);
  process.exit(1);
});
