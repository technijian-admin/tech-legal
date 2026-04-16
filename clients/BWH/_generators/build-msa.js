/**
 * Brandywine Homes (BWH) — Complete MSA + Schedules A/B/C Generator
 * Single DOCX: Cover + MSA (Sections 1-11) + Schedule A + Schedule B + Schedule C
 * Uses brand-helpers.js shared formatting system
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

// ── BWH Client Data ──
const CLIENT_NAME = "Brandywine Homes";
const CLIENT_SHORT = "BWH";
const EFFECTIVE_DATE = "May 1, 2026";

// ── Reusable: numbered paragraph (blue number prefix) ──
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

// ── Reusable: bold prefix + normal text ──
function bodyBoldPrefix(boldText, text) {
  return new Paragraph({
    spacing: { after: 60 },
    children: [
      new TextRun({ text: boldText, font: "Open Sans", size: 20, bold: true, color: DARK_CHARCOAL }),
      new TextRun({ text, font: "Open Sans", size: 20, color: BRAND_GREY }),
    ]
  });
}

// ── Reusable: bullet point ──
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

// ── Reusable: info/disclosure box ──
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

// ── Reusable: styled data table (blue header, alternating rows, grey borders) ──
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

// ── Reusable: spacer ──
function spacer(pts) {
  return new Paragraph({ spacing: { before: pts || 200 }, children: [] });
}

// ── Signature block with hidden DocuSign anchors ──
function sigLine(label, anchor) {
  return new Paragraph({
    spacing: { after: 40 },
    children: [
      new TextRun({ text: anchor, font: "Open Sans", size: 2, color: WHITE }),
      new TextRun({ text: label, font: "Open Sans", size: 22, color: BRAND_GREY }),
    ]
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
    // ══════════════════════════════════════════════════════════════
    //  COVER PAGE
    // ══════════════════════════════════════════════════════════════
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
          "Master Service Agreement",
          "Managed IT Services, Cybersecurity & Virtual Staff\nPrepared for Brandywine Homes",
          EFFECTIVE_DATE
        ),
      ]
    },

    // ══════════════════════════════════════════════════════════════
    //  MSA BODY (Sections 1-11)
    // ══════════════════════════════════════════════════════════════
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
        colorBanner("MASTER SERVICE AGREEMENT", CORE_BLUE, WHITE, 28),
        spacer(100),
        bodyText("Agreement Number: MSA-BWH"),
        bodyText(`Effective Date: ${EFFECTIVE_DATE}`),
        spacer(100),
        bodyText("This Master Service Agreement (\u201CAgreement\u201D) is entered into by and between:"),
        spacer(60),
        bodyBoldPrefix("Technijian, Inc. (\u201CTechnijian\u201D)", ""),
        bodyText("18 Technology Drive, Suite 141"),
        bodyText("Irvine, California 92618"),
        spacer(60),
        bodyText("and"),
        spacer(60),
        bodyBoldPrefix(`${CLIENT_NAME} (\u201CClient\u201D)`, ""),
        bodyText("2355 Main St #220"),
        bodyText("Irvine, CA 92614"),
        spacer(60),
        bodyText("(collectively, the \u201CParties\u201D)"),

        // ── RECITALS ──
        spacer(),
        sectionHeader("RECITALS"),
        bodyText("WHEREAS, Technijian provides managed IT services, cybersecurity, cloud infrastructure, telephony, and related technology solutions; and"),
        bodyText("WHEREAS, Client desires to engage Technijian to provide certain services as described in the Schedules attached hereto;"),
        bodyText("NOW, THEREFORE, for good and valuable consideration, the receipt and sufficiency of which are hereby acknowledged, the Parties agree as follows:"),

        // ── SECTION 1: SCOPE OF SERVICES ──
        spacer(),
        numberedSectionHeader("1", "Scope of Services"),
        spacer(100),
        numbered("1.01.", "Services. Technijian shall provide the services described in the Schedules attached to this Agreement, which are incorporated herein by reference:"),
        bullet("Schedule A \u2014 Monthly Managed Services (Online Services, SIP Trunk, Virtual Staff)"),
        bullet("Schedule B \u2014 Subscription and License Services"),
        bullet("Schedule C \u2014 Rate Card"),
        bodyText("Additional services may be provided through Statements of Work (\u201CSOWs\u201D) executed under this Agreement. Each SOW shall be signed by authorized representatives of both Parties and shall reference this Agreement by number. Upon execution, each SOW is incorporated into and governed by this Agreement."),
        numbered("1.02.", "Standard of Care. Technijian shall perform all services in a professional and workmanlike manner, consistent with industry standards for managed IT service providers."),
        numbered("1.03.", "Service Level Agreement. The service levels applicable to the services are set forth in Schedule A. Technijian shall use commercially reasonable efforts to meet the service levels described therein."),
        numbered("1.04.", "Client Responsibilities. Client shall:"),
        numbered("(a)", "Provide Technijian with reasonable access to Client\u2019s systems, facilities, and personnel as necessary for Technijian to perform the services;", 1),
        numbered("(b)", "Designate a primary point of contact for communications with Technijian;", 1),
        numbered("(c)", "Maintain current and accurate information regarding Client\u2019s systems and infrastructure;", 1),
        numbered("(d)", "Comply with all applicable laws and regulations in connection with its use of the services; and", 1),
        numbered("(e)", "Be solely responsible for the security and management of Client\u2019s account credentials and passwords.", 1),
        numbered("1.05.", "Independent Contractor. Technijian is an independent contractor. Nothing in this Agreement shall be construed to create a partnership, joint venture, agency, or employment relationship between the Parties."),
        numbered("1.06.", "Client Data. \u201CClient Data\u201D means any data, information, content, records, or files that belong to Client or Client\u2019s customers, employees, or agents, that are stored, processed, or transmitted using the services, including personal information as defined under the California Consumer Privacy Act."),
        numbered("1.07.", "Currency. All fees under this Agreement are stated and payable in United States Dollars (USD)."),
        numbered("1.08.", "Order of Precedence. In the event of a conflict between this Agreement and any Schedule, SOW, or Service Order, the following order of precedence shall apply (highest to lowest): (a) the applicable SOW or Service Order (but only for the specific services described therein); (b) the applicable Schedule; (c) this Master Service Agreement. A more specific provision in a lower-priority document shall not be deemed to conflict with a general provision in a higher-priority document unless it expressly states an intent to override."),
        numbered("1.09.", "Representations and Warranties. Each Party represents and warrants that: (a) it has the legal power and authority to enter into this Agreement; (b) the execution of this Agreement has been duly authorized by all necessary corporate action; (c) this Agreement constitutes a valid and binding obligation enforceable against it in accordance with its terms; and (d) its performance under this Agreement will not violate any applicable law, regulation, or existing contractual obligation."),
        numbered("1.10.", "Subcontractors. Technijian may engage subcontractors, including offshore personnel, to perform services under this Agreement, provided that: (a) Technijian shall remain fully responsible for all services performed by its subcontractors; (b) all subcontractors shall be bound by confidentiality and data protection obligations at least as protective as those in this Agreement; and (c) Technijian shall be liable for the acts and omissions of its subcontractors as if they were Technijian\u2019s own."),

        // ── SECTION 2: TERM AND RENEWAL ──
        spacer(),
        numberedSectionHeader("2", "Term and Renewal"),
        spacer(100),
        numbered("2.01.", "Initial Term. This Agreement shall commence on the Effective Date and continue for a period of twelve (12) months (the \u201CInitial Term\u201D)."),
        spacer(100),
        infoBox(
          "AUTOMATIC RENEWAL NOTICE:",
          "This Agreement will automatically renew for successive twelve (12) month periods unless you cancel at least sixty (60) days before the end of the current term. You may cancel by sending written notice to Technijian at the address above or by email to contracts@technijian.com. Technijian will send a renewal reminder at least thirty (30) days before each renewal date."
        ),
        spacer(100),
        numbered("2.02.", "Renewal. Upon expiration of the Initial Term, this Agreement shall automatically renew for successive twelve (12) month periods (each a \u201CRenewal Term\u201D), unless either Party provides written notice of non-renewal at least sixty (60) days prior to the expiration of the then-current term. Technijian shall send Client a written renewal reminder at least thirty (30) days prior to each renewal date, which shall restate the auto-renewal terms and cancellation method."),
        numbered("2.03.", "Termination for Convenience. Either Party may terminate this Agreement for any reason upon sixty (60) days written notice to the other Party. If Client terminates for convenience during the Initial Term or any Renewal Term, Client shall pay an early termination fee equal to: (a) any unrecoverable third-party costs committed by Technijian on Client\u2019s behalf (including prepaid licenses, committed hosting, and contracted offshore resources); plus (b) a wind-down fee calculated as follows: 75% of the average monthly recurring fees for the three (3) months preceding the termination notice, multiplied by the number of months remaining in the current term, up to a maximum of three (3) months\u2019 average recurring fees. The early termination fee constitutes liquidated damages and represents a reasonable estimate of Technijian\u2019s anticipated damages from early termination, including committed capacity, staffing, and unrecoverable vendor obligations, and is not a penalty. The Parties acknowledge that actual damages from early termination would be difficult or impracticable to calculate at the time of contracting."),
        numbered("2.04.", "Termination for Cause. Either Party may terminate this Agreement immediately upon written notice if the other Party:"),
        numbered("(a)", "Commits a material breach of this Agreement and fails to cure such breach within thirty (30) days after receiving written notice of the breach; or", 1),
        numbered("(b)", "Becomes insolvent, files for bankruptcy, or has a receiver appointed for its assets.", 1),
        numbered("2.05.", "Effect of Termination."),
        numbered("(a)", "Upon termination for any reason, all fees and charges for services rendered through the date of termination shall become immediately due and payable, including: (i) any remaining obligations for annual licenses and subscriptions procured on Client\u2019s behalf; (ii) for Virtual Staff services, any unpaid hour balance invoiced at the applicable Hourly Rate from the Rate Card (Schedule C) as set forth in Schedule A, Section 3.3(e); (iii) all accrued and unpaid late fees under Section 3.04; and (iv) any early termination fees as calculated under Section 2.03. Termination shall not relieve Client of any payment obligation that accrued prior to or as a result of termination.", 1),
        numbered("(b)", "Technijian shall provide reasonable transition assistance for a period of up to thirty (30) days following termination, provided that Client has paid all amounts owed under this Agreement in full, including any accrued late fees and collection costs. If Client has any outstanding balance at the time of termination, Technijian may withhold transition assistance until payment is received, or condition transition assistance upon Client\u2019s execution of a payment plan acceptable to Technijian.", 1),
        numbered("(c)", "Technijian shall return all Client Data in its possession within thirty (30) days of termination, in a commercially standard format. If Client has outstanding unpaid invoices at the time of termination, Technijian may require Client to execute a payment plan acceptable to Technijian as a condition of data return, but shall not withhold Client Data beyond sixty (60) days following termination regardless of payment status. Notwithstanding any other provision of this Agreement, Technijian shall not withhold Client Data to the extent such withholding would prevent Client from complying with applicable law, including data breach notification obligations under California Civil Code Section 1798.82, consumer rights requests under the CCPA, HIPAA obligations, or other regulatory requirements. Nothing in this subsection shall be construed to grant Technijian any ownership interest in Client Data, nor shall the return of Client Data relieve Client of any payment obligation.", 1),
        numbered("(d)", "The following sections shall survive termination: Section 3 (Payment), Section 4 (Confidentiality), Section 5 (Limitation of Liability), Section 6 (Indemnification), Section 7 (Intellectual Property), Section 8 (Dispute Resolution), Section 9.03 (Severability), Section 9.04 (Waiver), Section 9.05 (Assignment), Section 9.08 (Governing Law), Section 9.09 (Personnel Transition Fee), Section 10 (Data Protection), and Section 11 (Insurance, which shall remain in effect through the end of any transition assistance period under Section 2.05(b)), and any other provision that by its nature is intended to survive termination.", 1),

        // ── PAGE BREAK before Section 3 ──
        new Paragraph({ children: [new PageBreak()] }),

        // ── SECTION 3: PAYMENT ──
        numberedSectionHeader("3", "Payment"),
        spacer(100),
        numbered("3.01.", "Fees. Client shall pay fees for the services as set forth in the applicable Schedule, SOW, or invoice. Fees are exclusive of applicable taxes."),
        numbered("3.02.", "Invoice Types. Client may receive the following types of invoices from Technijian during the term of this Agreement. Each invoice will clearly identify its type, the applicable Schedule or SOW, and the billing period or delivery event."),
        numbered("(a)", "Monthly Service Invoice. Issued on the first business day of each month for recurring managed services under Schedule A (Online Services, infrastructure, monitoring, desktop/server management). Billed in advance for the upcoming month.", 1),
        numbered("(b)", "Monthly Recurring Subscription Invoice. Issued on the first business day of each month for subscription and license services under Schedule B (software licenses, SaaS subscriptions, SIP trunk services). Billed in advance for the upcoming month. Subscription quantities and pricing are as specified in the applicable Service Order.", 1),
        numbered("(c)", "Weekly In-Contract Invoice. Issued every Friday for Virtual Staff (contracted support) services performed under Schedule A, Part 3, during the preceding week (Monday through Friday). Each weekly in-contract invoice shall include: (i) a listing of each support ticket addressed during the period; (ii) the assigned resource, role, and hours spent per ticket; (iii) a description of the work performed per ticket; (iv) whether work was performed during normal business hours or after-hours; and (v) the current running balance for each contracted role. The weekly in-contract invoice is issued for transparency and tracking purposes; the actual billed amount is governed by the cycle-based billing model described in Schedule A, Section 3.3.", 1),
        numbered("(d)", "Weekly Out-of-Contract Invoice. Issued every Friday for labor services performed outside the scope of any active Schedule or SOW \u2014 including ad-hoc support requests, emergency work, and services performed under a SOW with hourly billing (such as CTO Advisory engagements). Each weekly out-of-contract invoice shall include: (i) a listing of each support ticket or task performed during the period; (ii) the assigned resource, role, and applicable hourly rate from the Rate Card (Schedule C); (iii) time entries with hours billed per activity (in 15-minute increments); (iv) whether work was performed during normal business hours or after-hours; and (v) the total hours and total amount for the week. Out-of-contract work is billed in arrears at the applicable rates from Schedule C.", 1),
        numbered("(e)", "Equipment and Materials Invoice. Issued upon delivery or procurement of hardware, software licenses (perpetual), or other tangible goods on Client\u2019s behalf. Each equipment invoice shall include: (i) item description, manufacturer, and model/part number; (ii) quantity and unit price; (iii) applicable sales tax; (iv) shipping and handling charges, if any; and (v) total amount due. Title to equipment shall not pass to Client until payment is received in full, as set forth in Section 3.09.", 1),
        numbered("(f)", "Project Milestone Invoice. Issued upon completion of a project milestone as defined in an applicable SOW. The milestone, deliverables, and invoiced amount are as specified in the payment schedule of the SOW. Milestone invoices are billed in arrears upon acceptance of the deliverables or deemed acceptance under the SOW\u2019s acceptance provisions.", 1),
        numbered("3.03.", "Payment Terms. All invoices are due and payable within thirty (30) days of the invoice date, unless otherwise specified in the applicable Schedule or SOW."),
        numbered("3.04.", "Late Payment. Invoices not paid within terms shall accrue a late fee of 1.5% per month (or the maximum rate permitted by law, whichever is less) on the unpaid balance, calculated as simple interest from the date payment was due until the date payment is received in full. Late fees are payable in addition to the outstanding principal amount. The Parties acknowledge that the late fee represents a reasonable estimate of Technijian\u2019s administrative costs and damages resulting from late payment, including cash-flow disruption, collection overhead, and the cost of carrying accounts receivable, and is not intended as a penalty."),
        numbered("3.05.", "Disputed Invoices."),
        numbered("(a)", "Weekly Invoices (In-Contract and Out-of-Contract). Because weekly invoices include detailed ticket descriptions and time entries, Client shall have thirty (30) days from the invoice date to review and dispute any portion of a weekly invoice. Client shall notify Technijian in writing, specifying the ticket number(s) and nature of the dispute with reasonable particularity. Undisputed tickets and time entries on the same invoice shall remain payable by the due date. Failure to provide a timely written dispute notice within the thirty (30) day period shall constitute acceptance of all tickets and time entries on the invoice.", 1),
        numbered("(b)", "All Other Invoices. For monthly service invoices, monthly recurring subscription invoices, equipment invoices, and project milestone invoices, Client shall notify Technijian in writing within fifteen (15) days of the invoice date if Client disputes any portion, specifying the nature and basis of the dispute with reasonable particularity. Client shall pay all undisputed amounts by the due date. Failure to provide a timely written dispute notice shall constitute acceptance of the invoice.", 1),
        numbered("(c)", "Resolution. The Parties shall work in good faith to resolve any invoice dispute within thirty (30) days of the dispute notice. If the dispute results in an adjustment, Technijian shall issue a credit memo or revised invoice within ten (10) business days of resolution.", 1),
        numbered("3.06.", "Suspension of Services. If Client fails to pay any undisputed invoice within thirty (30) days of the due date, Technijian may, upon ten (10) days written notice, suspend services under the Schedule or SOW associated with the unpaid invoice until payment is received in full, including all accrued late fees. If Client fails to pay any undisputed invoice within sixty (60) days of the due date, Technijian may suspend all services under this Agreement and any related Schedules or SOWs. Recurring fees for suspended services shall continue to accrue for a period not to exceed thirty (30) days following the date of suspension, after which Technijian may terminate the affected Schedule, SOW, or this Agreement upon written notice. Technijian continues to maintain infrastructure, licenses, and reserved capacity during any suspension period, which justifies the continued accrual. Suspension of services shall not relieve Client of its payment obligations."),
        numbered("3.07.", "Acceleration. Upon the occurrence of any of the following events, all fees, charges, and amounts owing under this Agreement, all Schedules, and all SOWs shall become immediately due and payable without further notice or demand: (a) Client fails to pay any undisputed invoice within forty-five (45) days of the due date; (b) Client terminates this Agreement or any Schedule while any invoices remain unpaid; (c) Client becomes insolvent, files for bankruptcy, or has a receiver appointed for its assets; or (d) Client is the subject of a material adverse change in its financial condition that, in Technijian\u2019s reasonable judgment, impairs Client\u2019s ability to perform its payment obligations."),
        numbered("3.08.", "Collection Costs and Attorney\u2019s Fees. This Section applies exclusively to the collection of fees, invoices, and other amounts owed under this Agreement and is separate from and does not apply to disputes regarding service quality, professional performance, errors and omissions, or any other non-payment claims. In any Collection Effort (as defined in Section 8.04), the prevailing Party shall be entitled to recover from the non-prevailing Party all reasonable costs of collection, including but not limited to: (a) reasonable attorney\u2019s fees and legal costs (including fees for in-house counsel at market rates); (b) collection agency fees and commissions; (c) court costs, arbitration filing fees, and administrative costs; (d) costs of investigation, skip tracing, and asset searches; and (e) all costs of appeal. This obligation applies regardless of whether a lawsuit or arbitration is commenced, and such costs shall be in addition to all other amounts owed. Pursuant to California Civil Code Section 1717, the Parties acknowledge that this attorney\u2019s fees provision is reciprocal and shall be enforced as such. For avoidance of doubt, this Section does not entitle either Party to recover attorney\u2019s fees or costs in connection with any counterclaim, cross-claim, or separate claim arising from alleged service deficiencies, professional negligence, or other non-payment matters \u2014 such claims are governed by Section 8.05."),
        numbered("3.09.", "Right of Setoff and Lien. (a) Technijian shall have the right to set off any amounts owed by Client under this Agreement against any amounts Technijian may owe to Client under this or any other agreement between the Parties. (b) Technijian shall retain a lien on all work product, deliverables, custom development, documentation, and materials (excluding Client Data as defined in Section 1.06) in its possession until all amounts owed by Client are paid in full. Technijian shall not be required to deliver, transfer, or release any work product or grant any license until all outstanding invoices, including accrued late fees and collection costs, are satisfied. (c) In the event of non-payment, Technijian may withhold transition assistance and credential transfers described in Section 2.05 until all amounts owed are paid in full, subject to the Client Data return obligations in Section 2.05(c) and the regulatory carve-outs therein."),
        numbered("3.10.", "Grant of Security Interest (UCC)."),
        numbered("(a)", "Grant. To secure the full and timely payment of all fees, charges, late fees, collection costs, and any other amounts now or hereafter owing by Client to Technijian under this Agreement, any Schedule, any SOW, or any other agreement between the Parties (collectively, the \u201CSecured Obligations\u201D), Client hereby grants to Technijian a continuing security interest in the following property of Client, whether now owned or hereafter acquired (collectively, the \u201CCollateral\u201D): (i) all equipment, hardware, and fixtures procured by Technijian on Client\u2019s behalf or used in connection with the services; (ii) all work product, deliverables, custom development, and documentation produced by Technijian under this Agreement or any SOW; (iii) all proceeds of the foregoing; and (iv) all books and records relating to the foregoing. For avoidance of doubt, the Collateral does not include Client Data (as defined in Section 1.06), Client\u2019s pre-existing intellectual property, or Client\u2019s general accounts receivable or general intangibles unrelated to the services. This security interest shall be subordinate to any prior perfected security interest held by Client\u2019s primary lender(s) of record as of the Effective Date of this Agreement.", 1),
        numbered("(b)", "Filing of UCC-1 Financing Statement. Client authorizes Technijian to file a UCC-1 Financing Statement (and any amendments, continuations, or renewals thereof) with the California Secretary of State or any other applicable filing office to perfect the security interest granted herein. Technijian may file such UCC-1 Financing Statement at any time after execution of this Agreement; provided, however, that Technijian shall provide Client with ten (10) days written notice before filing, except that no prior notice shall be required if Client is more than forty-five (45) days past due on any undisputed invoice.", 1),
        numbered("(c)", "Client Cooperation. Client shall: (i) execute and deliver any financing statements, amendments, or other documents reasonably requested by Technijian to perfect, maintain, or enforce the security interest; (ii) not grant any security interest in the Collateral that would be senior to Technijian\u2019s security interest without Technijian\u2019s prior written consent; and (iii) promptly notify Technijian of any change in Client\u2019s legal name, state of organization, or organizational identification number.", 1),
        numbered("(d)", "Remedies Upon Default. If Client fails to pay any Secured Obligation within forty-five (45) days of the due date (a \u201CPayment Default\u201D), Technijian shall have, in addition to all other rights and remedies under this Agreement and applicable law, all the rights and remedies of a secured party under the California Uniform Commercial Code (Cal. Com. Code \u00A7 9101 et seq.), including the right to take possession of Collateral that is in Technijian\u2019s physical or constructive possession and to dispose of it in a commercially reasonable manner. Technijian shall provide Client with at least fifteen (15) days prior written notice before exercising any disposition remedy. All self-help remedies shall be exercised without breach of the peace as required by Cal. Com. Code \u00A7 9609. For avoidance of doubt, nothing in this Section authorizes Technijian to access Client\u2019s computer systems, networks, or accounts to enforce the security interest; enforcement against intangible Collateral shall be conducted through lawful judicial process or notification to account debtors pursuant to Cal. Com. Code \u00A7 9607.", 1),
        numbered("(e)", "Termination and Release. Within thirty (30) days after all Secured Obligations have been paid in full and this Agreement has been terminated or expired with no further obligations outstanding, Technijian shall, at its own expense, file a UCC-3 Termination Statement to release the security interest and provide Client with written confirmation of the release. If Technijian fails to file a termination statement within such period after Client\u2019s written request (and all Secured Obligations are paid in full), Client shall be entitled to file a UCC-3 Termination Statement on its own behalf, and Technijian hereby authorizes such filing.", 1),
        numbered("3.11.", "Credit Reporting and Collections. Technijian reserves the right to report delinquent accounts to commercial credit reporting agencies and to assign delinquent accounts to third-party collection agencies, in each case after sixty (60) days of non-payment and ten (10) days written notice to Client."),
        numbered("3.12.", "Taxes. Client shall be responsible for all applicable sales, use, and other taxes arising from the services, excluding taxes based on Technijian\u2019s income."),

        // ── SECTION 4: CONFIDENTIALITY ──
        spacer(),
        numberedSectionHeader("4", "Confidentiality"),
        spacer(100),
        numbered("4.01.", "Definition. \u201CConfidential Information\u201D means any non-public information disclosed by either Party to the other in connection with this Agreement, including business, technical, and financial information. If the Parties have executed a separate Non-Disclosure Agreement, its terms are incorporated herein by reference."),
        numbered("4.02.", "Obligations. Each Party shall:"),
        numbered("(a)", "Hold the other Party\u2019s Confidential Information in confidence using at least the same degree of care it uses for its own confidential information, but not less than reasonable care;", 1),
        numbered("(b)", "Not disclose Confidential Information to third parties without prior written consent, except to employees, agents, and subcontractors who have a need to know and are bound by equivalent obligations; and", 1),
        numbered("(c)", "Not use Confidential Information for any purpose other than performing obligations under this Agreement.", 1),
        numbered("4.03.", "Exclusions. Confidential Information does not include information that is or becomes publicly available through no fault of the receiving Party, was known to the receiving Party prior to disclosure, is independently developed, or is received from a third party without restriction."),
        numbered("4.04.", "Compelled Disclosure. If required by law or court order to disclose Confidential Information, the receiving Party shall provide prompt written notice to the disclosing Party (to the extent legally permitted) and cooperate in seeking a protective order."),
        numbered("4.05.", "Duration. Confidentiality obligations shall survive termination for a period of three (3) years."),

        // ── SECTION 5: LIMITATION OF LIABILITY ──
        spacer(),
        numberedSectionHeader("5", "Limitation of Liability"),
        spacer(100),
        numbered("5.01.", "Limitation. EXCEPT AS PROVIDED IN SECTION 5.03 BELOW, NEITHER PARTY\u2019S TOTAL AGGREGATE LIABILITY UNDER THIS AGREEMENT SHALL EXCEED THE TOTAL FEES PAID OR PAYABLE BY CLIENT UNDER THIS AGREEMENT DURING THE TWELVE (12) MONTH PERIOD IMMEDIATELY PRECEDING THE EVENT GIVING RISE TO THE CLAIM (THE \u201CSTANDARD CAP\u201D)."),
        numbered("5.02.", "Exclusion of Consequential Damages. EXCEPT AS PROVIDED IN SECTION 5.03 BELOW, IN NO EVENT SHALL EITHER PARTY BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING LOSS OF PROFITS, DATA, BUSINESS OPPORTUNITY, OR GOODWILL, REGARDLESS OF WHETHER SUCH DAMAGES WERE FORESEEABLE OR WHETHER EITHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES."),
        importantCallout("EXCEPT FOR BREACHES OF CONFIDENTIALITY (SECTION 4), DATA PROTECTION (SECTION 10), INDEMNIFICATION (SECTION 6), WILLFUL MISCONDUCT, OR GROSS NEGLIGENCE, THE ENHANCED CAP SHALL BE THREE (3) TIMES THE STANDARD CAP. LIABILITY FOR WILLFUL AND INTENTIONAL MISAPPROPRIATION OF CONFIDENTIAL INFORMATION OR CLIENT DATA SHALL BE UNCAPPED."),
        numbered("5.03.", "Enhanced Cap for Certain Claims. FOR CLAIMS ARISING FROM BREACHES OF SECTION 4 (CONFIDENTIALITY), SECTION 10 (DATA PROTECTION), INDEMNIFICATION OBLIGATIONS UNDER SECTION 6, WILLFUL MISCONDUCT, OR GROSS NEGLIGENCE, THE TOTAL AGGREGATE LIABILITY OF THE RESPONSIBLE PARTY SHALL NOT EXCEED THREE (3) TIMES THE STANDARD CAP DEFINED IN SECTION 5.01 (THE \u201CENHANCED CAP\u201D). THE ENHANCED CAP SHALL NOT APPLY TO LIABILITY ARISING FROM A PARTY\u2019S WILLFUL AND INTENTIONAL MISAPPROPRIATION OF THE OTHER PARTY\u2019S CONFIDENTIAL INFORMATION OR CLIENT DATA, FOR WHICH LIABILITY SHALL BE UNCAPPED."),
        numbered("5.04.", "Data Liability. While Technijian shall use commercially reasonable efforts to protect Client Data in its possession, Client acknowledges that: (a) Client is solely responsible for maintaining backup copies of its data; (b) Technijian\u2019s liability for data loss shall be limited to using commercially reasonable efforts to restore data from available backups; and (c) Technijian shall not be liable for data loss caused by Client\u2019s actions, third-party attacks that Technijian could not have reasonably prevented through the safeguards required under Section 10.03, or events beyond Technijian\u2019s reasonable control."),

        // ── PAGE BREAK before Section 6 ──
        new Paragraph({ children: [new PageBreak()] }),

        // ── SECTION 6: INDEMNIFICATION ──
        numberedSectionHeader("6", "Indemnification"),
        spacer(100),
        numbered("6.01.", "By Technijian. Technijian shall indemnify, defend, and hold harmless Client from and against any third-party claims arising from: (a) Technijian\u2019s gross negligence or willful misconduct in performing the services; or (b) any claim that Technijian IP (as defined in Section 7.01) used in performing the services infringes such third party\u2019s United States intellectual property rights, provided the infringement does not arise from Client\u2019s modifications to the Technijian IP, Client\u2019s combination of the Technijian IP with non-Technijian materials, or Client\u2019s use of the services in a manner not authorized by this Agreement. If any Technijian IP becomes the subject of an infringement claim, Technijian may, at its option and expense: (i) procure for Client the right to continue using the affected IP; (ii) modify the affected IP to make it non-infringing while maintaining substantially equivalent functionality; or (iii) replace the affected IP with a non-infringing alternative. If none of these options are commercially practicable, either Party may terminate the affected services upon thirty (30) days\u2019 notice, and Technijian shall refund any prepaid fees for the terminated services covering the period after termination."),
        numbered("6.02.", "By Client. Client shall indemnify, defend, and hold harmless Technijian from and against any third-party claims arising from: (a) Client\u2019s use of the services in violation of applicable law; (b) Client\u2019s breach of this Agreement; or (c) any data, content, or materials provided by Client."),
        numbered("6.03.", "Procedure. The indemnified Party shall provide prompt written notice of any claim, cooperate with the indemnifying Party in the defense, and not settle any claim without the indemnifying Party\u2019s prior written consent."),

        // ── SECTION 7: INTELLECTUAL PROPERTY ──
        spacer(),
        numberedSectionHeader("7", "Intellectual Property"),
        spacer(100),
        numbered("7.01.", "Technijian IP. Technijian retains all right, title, and interest in its proprietary tools, methodologies, software, and processes used in providing the services (\u201CTechnijian IP\u201D). Client receives no rights to Technijian IP except as expressly set forth in this Agreement."),
        numbered("7.02.", "Client IP. Client retains all right, title, and interest in its data, content, and pre-existing intellectual property (\u201CClient IP\u201D)."),
        numbered("7.03.", "Custom Development. Ownership of any custom software or materials developed under a SOW shall be governed by the terms of that SOW. Unless otherwise specified, Technijian shall retain ownership of any general-purpose tools, frameworks, or methodologies developed during the engagement."),

        // ── SECTION 8: DISPUTE RESOLUTION ──
        spacer(),
        numberedSectionHeader("8", "Dispute Resolution"),
        spacer(100),
        numbered("8.01.", "Escalation. The Parties shall first attempt to resolve any dispute through good faith negotiations between their respective designated representatives for a period of thirty (30) days."),
        numbered("8.02.", "Mediation. If the dispute is not resolved through negotiation, the Parties shall submit the dispute to mediation administered by a mutually agreed-upon mediator in Orange County, California, for a period not to exceed sixty (60) days."),
        numbered("8.03.", "Arbitration. If mediation fails, any remaining dispute shall be resolved by binding arbitration administered by the American Arbitration Association under its Commercial Arbitration Rules. The arbitration shall take place in Orange County, California, before a single arbitrator. The arbitrator shall have the authority to award any remedy that would be available in a court of competent jurisdiction, including injunctive relief and specific performance. The Parties shall equally share arbitrator fees and AAA administrative costs; each Party shall bear its own attorney\u2019s fees except as provided in Sections 8.04 and 8.05. The arbitrator shall issue a reasoned written award."),
        numbered("8.04.", "Fees \u2014 Payment Collection Actions. Notwithstanding Section 8.05, in any dispute, arbitration, mediation, litigation, or other proceeding in which the primary relief sought is the collection of fees, invoices, or other amounts owed under this Agreement, any Schedule, or any SOW (a \u201CCollection Action\u201D), the prevailing Party shall be entitled to recover from the non-prevailing Party all reasonable costs and expenses incurred in connection with such Collection Action, including but not limited to: (a) attorney\u2019s fees and legal costs (including fees for in-house counsel at market rates); (b) expert witness fees; (c) arbitration and mediation filing fees, administrative costs, and arbitrator compensation; (d) court costs and filing fees; (e) costs of discovery, depositions, and document production; and (f) all costs of appeal. For purposes of this Section, a \u201CCollection Action\u201D includes any proceeding initiated to recover unpaid invoices, late fees, accelerated amounts under Section 3.07, or amounts due upon termination under Section 2.05, as well as any action to enforce a judgment or arbitration award arising from such a proceeding. The \u201Cprevailing Party\u201D means the Party that substantially obtains the relief sought, whether by settlement, judgment, or award, as determined by the arbitrator or court. This provision is in addition to and does not limit the pre-litigation collection costs recoverable under Section 3.08."),
        numbered("8.05.", "Fees \u2014 All Other Disputes. Except as expressly provided in Section 8.04 (Collection Actions) and Section 3.08 (Collection Costs), in any dispute, arbitration, mediation, litigation, or other proceeding arising out of or relating to this Agreement \u2014 including but not limited to claims relating to service quality, professional negligence, errors and omissions, breach of warranty, indemnification, data protection, or any counterclaim asserted in response to a Collection Action \u2014 each Party shall bear its own attorney\u2019s fees and costs. Neither Party shall be entitled to recover attorney\u2019s fees or costs from the other Party in connection with such non-collection disputes, regardless of which Party prevails. For avoidance of doubt, if a Collection Action under Section 8.04 and a non-collection dispute under this Section 8.05 are joined or heard in the same proceeding, the arbitrator or court shall apportion fees accordingly, awarding fees to the prevailing Party only with respect to the Collection Action claims."),
        numbered("8.06.", "Injunctive and Provisional Relief. Nothing in this Section shall prevent either Party from seeking injunctive or other equitable relief in a court of competent jurisdiction to prevent irreparable harm. Either Party may seek provisional remedies from a court of competent jurisdiction pursuant to California Code of Civil Procedure Section 1281.8 pending appointment of the arbitrator or resolution of the arbitration, without waiving the right to arbitrate."),

        // ── SECTION 9: GENERAL PROVISIONS ──
        spacer(),
        numberedSectionHeader("9", "General Provisions"),
        spacer(100),
        numbered("9.01.", "Entire Agreement. This Agreement, together with its Schedules and any SOWs, constitutes the entire agreement between the Parties and supersedes all prior agreements, whether written or oral, relating to the subject matter hereof."),
        numbered("9.02.", "Amendment. This Agreement may only be amended by a written instrument signed by both Parties. Technijian may update its Rate Card (Schedule C) upon sixty (60) days written notice to Client, effective at the start of the next Renewal Term."),
        numbered("9.03.", "Severability. If any provision is found to be invalid or unenforceable, the remaining provisions shall continue in full force and effect."),
        numbered("9.04.", "Waiver. No waiver of any provision shall be effective unless in writing and signed by the waiving Party. A waiver of any breach shall not constitute a waiver of any subsequent breach."),
        numbered("9.05.", "Assignment. Neither Party may assign this Agreement without the prior written consent of the other Party, except that either Party may assign this Agreement in connection with a merger, acquisition, or sale of substantially all of its assets."),
        numbered("9.06.", "Force Majeure."),
        numbered("(a)", "Neither Party shall be liable for delays or failures in performance caused by events beyond its reasonable control, including natural disasters, acts of government, labor disputes, pandemics, cyberattacks on critical infrastructure, or failures of major third-party infrastructure services (such as cloud platform outages) that are not attributable to the affected Party\u2019s failure to implement reasonable redundancy (\u201CForce Majeure Event\u201D).", 1),
        numbered("(b)", "The affected Party shall notify the other Party in writing within five (5) business days of becoming aware of a Force Majeure Event and shall use commercially reasonable efforts to mitigate the impact and resume performance.", 1),
        numbered("(c)", "Payment obligations are not excused by a Force Majeure Event.", 1),
        numbered("(d)", "If a Force Majeure Event prevents performance of a material portion of the services for more than ninety (90) consecutive days, either Party may terminate the affected Schedule, SOW, or this Agreement upon fifteen (15) days written notice without liability for early termination fees, and Client shall pay only for services actually rendered through the date of termination.", 1),
        numbered("9.07.", "Notices. All notices shall be in writing and delivered by email with confirmation, certified mail, or nationally recognized overnight courier to the addresses set forth above (or as updated in writing)."),
        numbered("9.08.", "Governing Law. This Agreement shall be governed by and construed in accordance with the laws of the State of California without regard to conflict of law principles."),
        numbered("9.09.", "Personnel Transition Fee. The Parties acknowledge that each invests significant resources in recruiting, training, and retaining skilled personnel. If either Party hires (whether as an employee or independent contractor) any individual who was an employee of the other Party and who was directly involved in performing or receiving services under this Agreement, and such hiring occurs during the term of this Agreement or within twelve (12) months following termination, the hiring Party shall pay the other Party a personnel transition fee equal to 25% of the hired individual\u2019s first-year annual compensation (base salary or annualized contractor fees). This fee represents a reasonable estimate of the non-hiring Party\u2019s recruiting and training costs and is not intended as a restraint on trade or employment. This Section does not restrict any individual\u2019s right to seek or obtain employment, and shall not apply to individuals who: (a) respond to general public job postings or advertisements not specifically targeted at the other Party\u2019s employees; or (b) are referred by a third-party recruiting firm without the hiring Party\u2019s direction to target the other Party\u2019s employees."),
        numbered("9.10.", "Counterparts. This Agreement may be executed in counterparts, each of which shall be deemed an original."),

        // ── SECTION 10: DATA PROTECTION ──
        spacer(),
        numberedSectionHeader("10", "Data Protection"),
        spacer(100),
        numbered("10.01.", "CCPA/CPRA Compliance. To the extent Technijian processes, stores, or has access to personal information (as defined under the California Consumer Privacy Act, as amended by the California Privacy Rights Act, Cal. Civ. Code \u00A7 1798.100 et seq., collectively \u201CCCPA\u201D) on behalf of Client, Technijian acts as a \u201Cservice provider\u201D as defined under Cal. Civ. Code \u00A7 1798.140(ag) and shall:"),
        numbered("(a)", "Process such personal information only as necessary to perform the services and in accordance with Client\u2019s documented instructions and this Agreement;", 1),
        numbered("(b)", "Not sell, share, retain, use, or disclose personal information for any purpose other than performing the services, including not using personal information for targeted advertising or cross-context behavioral advertising;", 1),
        numbered("(c)", "Not combine personal information received from Client with personal information received from other sources or collected from Technijian\u2019s own interactions with individuals, except as expressly permitted by the CCPA to perform the services;", 1),
        numbered("(d)", "Implement reasonable security measures appropriate to the nature of the personal information, consistent with the requirements of Section 10.03;", 1),
        numbered("(e)", "Cooperate with Client in responding to verifiable consumer rights requests under the CCPA (including access, deletion, correction, and opt-out requests) within ten (10) business days of Client\u2019s request;", 1),
        numbered("(f)", "Notify Client within five (5) business days if Technijian determines that it can no longer meet its obligations as a service provider under the CCPA;", 1),
        numbered("(g)", "Ensure that all subcontractors (including offshore personnel engaged under Section 1.10) who process personal information on behalf of Client are bound by written agreements containing data protection obligations at least as protective as those in this Section 10, and Technijian shall remain liable for the acts and omissions of its subcontractors with respect to personal information;", 1),
        numbered("(h)", "Permit Client, upon thirty (30) days written notice and no more than once per twelve (12) month period, to audit or inspect Technijian\u2019s data processing practices to verify compliance with this Section 10, or, at Technijian\u2019s option, provide Client with a summary of a recent independent third-party audit (such as SOC 2 Type II) covering the relevant controls; and", 1),
        numbered("(i)", "Certify that Technijian understands the restrictions in this Section 10 and will comply with them, including that Technijian shall not sell or share personal information as those terms are defined under the CCPA.", 1),
        bodyText("If the Parties require more detailed data processing terms (for example, to address GDPR, HIPAA, or industry-specific requirements), the Parties shall execute a separate Data Processing Addendum, which shall be incorporated into this Agreement by reference."),
        numbered("10.02.", "Security Incident Notification. If Technijian becomes aware of a breach of security leading to the accidental or unlawful destruction, loss, alteration, unauthorized disclosure of, or access to Client Data (\u201CSecurity Incident\u201D), Technijian shall: (a) notify Client in writing without unreasonable delay and in no event later than forty-eight (48) hours after becoming aware of the Security Incident; (b) provide Client with sufficient information to enable Client to comply with its obligations under California Civil Code \u00A7 1798.82 (data breach notification), including the categories and approximate number of records affected, the nature of the incident, and the measures taken or proposed to address it, and any other applicable data breach notification laws; (c) cooperate with Client\u2019s investigation of the Security Incident; and (d) take reasonable steps to contain and remediate the Security Incident. If Client Data includes protected health information subject to HIPAA, notification shall also comply with 45 CFR \u00A7 164.410."),
        numbered("10.03.", "Data Security. Technijian shall implement and maintain administrative, technical, and physical safeguards designed to protect Client Data from unauthorized access, use, or disclosure, consistent with industry standards for managed IT service providers. Such safeguards shall include, at a minimum: (a) encryption of Client Data in transit and at rest; (b) access controls limiting access to authorized personnel; (c) regular security assessments and vulnerability testing; and (d) employee security awareness training."),
        numbered("10.04.", "Regulatory Compliance. If Client is subject to the Health Insurance Portability and Accountability Act (\u201CHIPAA\u201D), the Payment Card Industry Data Security Standard (\u201CPCI DSS\u201D), the General Data Protection Regulation (\u201CGDPR\u201D), or other industry-specific data protection requirements, the Parties shall execute a separate addendum addressing the additional obligations applicable to the regulated data. Technijian shall cooperate with Client in implementing controls necessary to meet such requirements."),
        numbered("10.05.", "Data Return and Deletion. Subject to Section 2.05(c), upon termination of this Agreement or upon Client\u2019s written request, Technijian shall securely delete or return all Client Data in its possession within thirty (30) days, using methods consistent with NIST SP 800-88 (Guidelines for Media Sanitization) or equivalent standards, and shall certify such deletion in writing upon request. Technijian may retain copies of Client Data only to the extent required by applicable law, provided such retained data remains subject to the confidentiality and data protection obligations of this Agreement."),

        // ── SECTION 11: INSURANCE ──
        spacer(),
        numberedSectionHeader("11", "Insurance"),
        spacer(100),
        numbered("11.01.", "Required Coverage. During the term of this Agreement, Technijian shall maintain the following insurance coverage with carriers rated A- VII or better by A.M. Best: (a) Commercial General Liability insurance on an occurrence basis with limits of not less than $1,000,000 per occurrence and $2,000,000 in the aggregate; (b) Professional Liability (Errors and Omissions) insurance on a claims-made basis with limits of not less than $1,000,000 per claim and $2,000,000 in the aggregate, with a retroactive date no later than the Effective Date of this Agreement; (c) Cyber Liability insurance on a claims-made basis with limits of not less than $1,000,000 per claim, covering data breaches, network security failures, and privacy violations; and (d) Workers\u2019 Compensation insurance as required by the laws of the State of California."),
        numbered("11.02.", "Additional Requirements. (a) Client shall be named as an additional insured on Technijian\u2019s Commercial General Liability policy with respect to the services provided under this Agreement. (b) Technijian\u2019s insurance shall be primary and non-contributory with respect to any insurance maintained by Client. (c) For claims-made policies (Professional Liability and Cyber Liability), Technijian shall maintain tail coverage (extended reporting period) for a minimum of two (2) years following termination of this Agreement. (d) Technijian shall include a waiver of subrogation in favor of Client on the Commercial General Liability and Workers\u2019 Compensation policies."),
        numbered("11.03.", "Certificates of Insurance. Upon Client\u2019s written request, Technijian shall provide certificates of insurance evidencing the coverage required under this Section, including evidence of additional insured status and waiver of subrogation. Technijian shall provide Client with at least thirty (30) days\u2019 prior written notice of any material change to or cancellation of such coverage."),

        // ── SIGNATURES ──
        new Paragraph({ children: [new PageBreak()] }),
        numberedSectionHeader("", "Signatures"),
        spacer(100),
        bodyText("IN WITNESS WHEREOF, the parties have executed this Agreement as of the Effective Date."),
        spacer(),

        // Technijian signature block
        bodyBoldPrefix("TECHNIJIAN, INC.", ""),
        sigLine("By: ___________________________________", "/tSign/"),
        sigLine("Name: _________________________________", "/tName/"),
        sigLine("Title: _________________________________", "/tTitle/"),
        sigLine("Date: _________________________________", "/tDate/"),
        spacer(),

        // Client signature block
        bodyBoldPrefix(CLIENT_NAME.toUpperCase(), ""),
        sigLine("By: ___________________________________", "/cSign/"),
        sigLine("Name: _________________________________", "/cName/"),
        sigLine("Title: _________________________________", "/cTitle/"),
        sigLine("Date: _________________________________", "/cDate/"),

        spacer(),
        bodyText("Schedules:"),
        bullet("Schedule A \u2014 Monthly Managed Services"),
        bullet("Schedule B \u2014 Subscription and License Services"),
        bullet("Schedule C \u2014 Rate Card"),

        spacer(),
        ctaBanner(),
      ]
    },

    // ══════════════════════════════════════════════════════════════
    //  SCHEDULE A — MONTHLY MANAGED SERVICES
    // ══════════════════════════════════════════════════════════════
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

        // ── PART 2: SIP TRUNK SERVICES ──
        new Paragraph({ children: [new PageBreak()] }),
        colorBanner("PART 2 \u2014 SIP TRUNK SERVICES", DARK_CHARCOAL, WHITE, 24),
        spacer(100),

        sectionHeader("2.1 Description"),
        bodyText("SIP Trunk Services include voice-over-IP telephony, SIP trunking, and related telecommunications services."),

        spacer(100),
        sectionHeader("2.2 Service Components"),
        styledTable(
          ["Component", "Description"],
          [
            ["SIP Trunk", "Primary voice connectivity with failover"],
            ["Voice Package", "Bundled calling plans (domestic, long distance)"],
            ["DID Numbers", "Direct inward dialing numbers"],
            ["E911", "Emergency services routing"],
          ]
        ),

        spacer(),
        sectionHeader("2.3 Service Levels"),
        styledTable(
          ["Service Level", "Target"],
          [
            ["Voice Uptime", "99.9% monthly"],
            ["Call Quality (MOS)", "4.0 or higher"],
            ["Number Porting", "Completed within 10 business days of request"],
          ]
        ),

        spacer(),
        sectionHeader("2.4 SIP Trunk Service Level Remedies"),
        bodyText("The service level remedies set forth in Section 1.4a (Service Credits, Chronic Failure, Credit Requests, Exclusions, and Sole Remedy) shall apply equally to SIP Trunk Service Levels, with \u201CVoice Uptime\u201D substituted for \u201CInfrastructure Uptime\u201D where applicable."),
        bodyText("Note: SIP Trunk Services are not included in the current Service Order. This section is included for reference should Client elect to add SIP Trunk Services in the future."),

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
        numbered("1.", "Any positive running balance (actual hours exceeding billed hours) shall become immediately due and payable. The unpaid hours shall be invoiced at the applicable Hourly Rate from the Rate Card (Schedule C), not the Contracted Rate. This reflects the rate that would have applied had Client engaged Technijian on an ad hoc hourly basis without a Cycle commitment.", 1),
        numbered("2.", "Any negative running balance (billed hours exceeding actual hours) does not entitle Client to a credit, refund, or offset against the final invoice. The unpaid balance is simply zero and no further amounts are due from either Party with respect to that role.", 1),
        numbered("3.", "The Cycle-Based Billing Model provides Client with Contracted Rates that are lower than the standard Hourly Rates as consideration for Client\u2019s commitment to the Cycle. The application of Hourly Rates upon cancellation reflects the removal of that commitment and the corresponding rate benefit.", 1),

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
        sectionHeader("3.5 New Client Onboarding"),
        bodyText("For new Clients without a previous Cycle history, the initial Cycle billing shall be based on:"),
        numbered("(a)", "A mutually agreed-upon estimated monthly hours per role, documented in the Service Order; and"),
        numbered("(b)", "Actual usage tracking beginning immediately, with the first Cycle reconciliation occurring at the end of the initial Cycle period."),

        spacer(),
        sectionHeader("3.6 Acceptable Use"),
        bodyText("Client shall direct Virtual Staff only to perform work within the scope of the applicable role description and the services contemplated by this Agreement. Client shall not direct or request Virtual Staff to:"),
        numbered("(a)", "Perform any activity that violates applicable law, regulation, or third-party rights;"),
        numbered("(b)", "Access, process, or transmit data in violation of data protection laws or Client\u2019s own data handling policies;"),
        numbered("(c)", "Perform work for any entity other than Client without Technijian\u2019s prior written consent; or"),
        numbered("(d)", "Perform work outside the scope of the role for which they are contracted without a corresponding change to the Service Order."),
        bodyText("Technijian reserves the right to reassign or remove Virtual Staff if Client directs work that falls outside these guidelines, without affecting Client\u2019s billing obligations under Section 3.3."),

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
        bodyText("Pricing for services under this Schedule is subject to the Rate Card (Schedule C). Technijian may adjust rates upon sixty (60) days written notice, effective at the start of the next Renewal Term of the Agreement."),
      ]
    },

    // ══════════════════════════════════════════════════════════════
    //  SCHEDULE B — SUBSCRIPTION AND LICENSE SERVICES
    // ══════════════════════════════════════════════════════════════
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
      ]
    },

    // ══════════════════════════════════════════════════════════════
    //  SCHEDULE C — RATE CARD
    // ══════════════════════════════════════════════════════════════
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
        colorBanner("SCHEDULE C \u2014 RATE CARD", CORE_BLUE, WHITE, 28),
        spacer(100),
        bodyText("Attached to Master Service Agreement MSA-BWH"),
        bodyText(`Effective Date: ${EFFECTIVE_DATE}`),

        // ── SECTION 1: VIRTUAL STAFF RATES ──
        spacer(),
        colorBanner("1. VIRTUAL STAFF RATES", DARK_CHARCOAL, WHITE, 24),
        spacer(100),
        bodyText("The following rates reflect BWH contracted rates with a 15% discount from standard pricing. Virtual Staff billing operates on a 12-month billing cycle."),

        spacer(100),
        sectionHeader("1.1 United States \u2014 Based Staff"),
        styledTable(
          ["Role", "Standard Rate", "After-Hours Rate", "BWH Contracted Rate"],
          [
            ["Systems Architect", "$250/hr", "$350/hr", "$170.00/hr"],
            ["CTO Advisory", "$250/hr", "$350/hr", "$225/hr"],
            ["Developer", "$150/hr", "N/A", "$125/hr"],
            ["Tech Support", "$150/hr", "$250/hr", "$106.25/hr"],
          ]
        ),

        spacer(),
        sectionHeader("1.2 Offshore \u2014 Based Staff"),
        styledTable(
          ["Role", "Standard Rate", "After-Hours Rate", "BWH Contracted Rate"],
          [
            ["Developer", "$45/hr", "N/A", "$30/hr"],
            ["SEO Specialist", "$45/hr", "N/A", "$30/hr"],
            ["Tech Support (Normal)", "$15/hr", "$30/hr", "$12.75/hr"],
            ["Tech Support (After Hours)", "$30/hr", "N/A", "$25.50/hr"],
          ]
        ),

        spacer(),
        bodyBoldPrefix("Normal Business Hours: ", "Monday through Friday, 8:00 AM to 6:00 PM Pacific Time, excluding US federal holidays."),
        bodyBoldPrefix("After-Hours: ", "All hours outside of Normal Business Hours, including weekends and US federal holidays."),
        bodyBoldPrefix("BWH Contracted Rate: ", "The 15% discounted hourly rate applied under the BWH Master Service Agreement. These rates apply to Virtual Staff services billed through the 12-month Cycle-Based Billing Model described in Schedule A, Part 3."),
        bodyBoldPrefix("Standard Rate: ", "The standard rate for ad hoc (non-contracted) services. This rate is also applied to calculate cancellation fees on any unpaid hour balance upon termination of Virtual Staff services, as described in Schedule A, Section 3.3(e)."),
        bodyBoldPrefix("Billing Cycle: ", "Virtual Staff services are billed on a 12-month cycle. Initial cycle based on estimated monthly hours per the Service Order. Actual usage tracked from day one with reconciliation at end of each cycle period."),

        // ── SECTION 2: PROJECT RATES ──
        spacer(),
        colorBanner("2. PROJECT RATES", DARK_CHARCOAL, WHITE, 24),
        spacer(100),
        styledTable(
          ["Service", "Rate", "Minimum", "Notes"],
          [
            ["On-Site Support (US)", "$150/hr", "2-hour minimum", "No trip charges"],
            ["Remote Support (ad hoc, non-contracted)", "$150/hr", "15-min increments", "Billed in 15-minute increments"],
            ["Emergency / Critical Response", "$250/hr", "1-hour minimum", "After-hours and critical incidents"],
            ["Project Management", "$150/hr", "N/A", "For SOW-based engagements"],
          ]
        ),

        // ── SECTION 3: ONLINE SERVICES INFRASTRUCTURE ──
        new Paragraph({ children: [new PageBreak()] }),
        colorBanner("3. ONLINE SERVICES \u2014 INFRASTRUCTURE", DARK_CHARCOAL, WHITE, 24),
        spacer(100),

        sectionHeader("3.1 Cloud Infrastructure"),
        styledTable(
          ["Service", "Code", "Unit", "License", "Monthly Rate"],
          [
            ["Cloud VM \u2014 vCore", "CL-VC", "Per vCore", "M", "$6.25"],
            ["Cloud VM \u2014 Memory", "CL-GB", "Per GB", "M", "$0.63"],
            ["Cloud VM \u2014 Shared Bandwidth", "CL-SBW", "Per connection", "M", "$15.00"],
            ["Hosting \u2014 CDN", "HC", "Per domain", "M", "$30.00"],
            ["Production Storage", "TB-PSTR", "Per TB", "M", "$200.00"],
            ["Replicated Storage", "TB-RSTR", "Per TB", "M", "$100.00"],
            ["Backup Storage", "TB-BSTR", "Per TB", "M", "$50.00"],
          ]
        ),

        spacer(),
        sectionHeader("3.2 Server Management"),
        styledTable(
          ["Service", "Code", "Unit", "License", "Monthly Rate"],
          [
            ["Patch Management", "PMW", "Per server", "M", "$4.00"],
            ["Image Backup (Veeam)", "IB", "Per server", "M", "$15.00"],
            ["AV Protection \u2014 Server (CrowdStrike)", "AVS", "Per server", "M", "$10.50"],
            ["AVM Protection \u2014 Server (MalwareBytes)", "AVMS", "Per server", "M", "$16.00"],
            ["AVH Protection \u2014 Server (Huntress)", "AVHS", "Per server", "M", "$6.00"],
            ["My Secure Internet (DNS Filtering)", "SI", "Per server", "M", "$6.00"],
            ["My Remote", "MR", "Per server", "M", "$2.00"],
            ["Health Monitoring (SNMP)", "SHM", "Per device", "M", "$2.00"],
            ["Syslog Monitoring (SNMP)", "SSM", "Per device", "M", "$2.00"],
            ["My Ops \u2014 Net", "OPS-NET", "Per server", "M", "$3.25"],
            ["My Ops \u2014 Config", "OPS-BKP", "Per switch", "M", "$6.00"],
            ["My Ops \u2014 Traffic", "OPS-TR", "Per firewall", "M", "$14.00"],
            ["My Ops \u2014 Port", "OPS-PRT", "Per port", "M", "$0.25"],
            ["My Ops \u2014 Storage", "OPS-ST", "Per disk", "M", "$4.75"],
            ["My Ops \u2014 Wifi", "OPS-WF", "Per AP", "M", "$1.00"],
            ["MyAudit Server", "AMS", "Per server", "M", "$252.00"],
          ]
        ),

        spacer(),
        sectionHeader("3.3 Desktop Management"),
        styledTable(
          ["Service", "Code", "Unit", "License", "Monthly Rate"],
          [
            ["Patch Management", "PMW", "Per desktop", "M", "$4.00"],
            ["Patch Management (Mac OS)", "PMMAC", "Per desktop", "M", "$11.00"],
            ["AV Protection \u2014 Desktop (CrowdStrike)", "AVD", "Per desktop", "M", "$8.50"],
            ["AVM Protection \u2014 Desktop (MalwareBytes)", "AVMD", "Per desktop", "M", "$5.00"],
            ["AVH Protection \u2014 Desktop (Huntress)", "AVMH", "Per desktop", "M", "$6.00"],
            ["My Secure Internet (DNS Filtering)", "SI", "Per desktop", "M", "$6.00"],
            ["My Remote", "MR", "Per desktop", "M", "$2.00"],
            ["My Ops \u2014 Net", "OPS-NET", "Per desktop", "M", "$3.25"],
            ["Audit Monitoring (Base)", "AM", "Per desktop", "M", "$9.50"],
            ["Audit Monitoring (30 Day)", "AM30", "Per desktop", "M", "$12.50"],
            ["Audit Monitoring (90 Day)", "AM90", "Per desktop", "M", "$15.00"],
            ["Audit Monitoring (6 Months)", "AM6M", "Per desktop", "M", "$25.00"],
            ["Audit Monitoring (1 Year)", "AM1Y", "Per desktop", "M", "$45.00"],
          ]
        ),

        spacer(),
        sectionHeader("3.3a Advanced Audit Monitoring"),
        bodyText("Advanced audit monitoring tiers include User Activity Monitoring (UAM) and Data Loss Prevention (DLP)."),
        styledTable(
          ["Service", "Code", "Unit", "License", "Monthly Rate"],
          [
            ["Audit Monitoring UAM (Base + UAM)", "AMUAM", "Per desktop", "M", "$42.00"],
            ["Audit Monitoring UAM (30 Day)", "AMUAM30", "Per desktop", "M", "$44.90"],
            ["Audit Monitoring UAM (90 Day)", "AMUAM90", "Per desktop", "M", "$47.40"],
            ["Audit Monitoring UAM (6 Months)", "AMUAM6M", "Per desktop", "M", "$57.40"],
            ["Audit Monitoring UAM (1 Year)", "AMUAM1Y", "Per desktop", "M", "$77.40"],
            ["Audit Monitoring DLP (UAM + DLP)", "AMDLP", "Per desktop", "M", "$49.00"],
            ["Audit Monitoring DLP (30 Day)", "AMDLP30", "Per desktop", "M", "$51.90"],
            ["Audit Monitoring DLP (90 Day)", "AMDLP90", "Per desktop", "M", "$57.30"],
            ["Audit Monitoring DLP (6 Months)", "AMDLP6M", "Per desktop", "M", "$72.70"],
            ["Audit Monitoring DLP (1 Year)", "AMDLP1Y", "Per desktop", "M", "$108.10"],
          ]
        ),

        // ── SECTION 3.4: NETWORK AND SECURITY ──
        new Paragraph({ children: [new PageBreak()] }),
        sectionHeader("3.4 Network and Security"),
        styledTable(
          ["Service", "Code", "Unit", "License", "Monthly Rate"],
          [
            ["Sophos 1C-4G (Up to 100 Mbps)", "SO-1C4G", "Per appliance", "Y", "$145.00"],
            ["Sophos 2C-4G (Up to 300 Mbps)", "SO-2C4G", "Per appliance", "Y", "$350.00"],
            ["Sophos 4C-6G (Up to 500 Mbps)", "SO-4C6G", "Per appliance", "Y", "$510.00"],
            ["Sophos 6C-8G (Up to 750 Mbps)", "SO-6C8G", "Per appliance", "Y", "$855.00"],
            ["Sophos 8C-16G (Up to 1 Gbps)", "SO-8C16G", "Per appliance", "Y", "$1,330.00"],
            ["Sophos 16C-24G (Up to 1.5 Gbps)", "SO-16C24G", "Per appliance", "Y", "$2,435.00"],
            ["Sophos UC-UG (Over 1.5 Gbps)", "SO-UCG", "Per appliance", "Y", "$3,320.00"],
            ["VeloCloud SD-WAN 30M", "VC-30M", "Per appliance", "Y", "$200.00"],
            ["VeloCloud SD-WAN 50M", "VC-50M", "Per appliance", "Y", "$250.00"],
            ["VeloCloud SD-WAN 100M", "VC-100M", "Per appliance", "Y", "$310.00"],
            ["VeloCloud SD-WAN 200M", "VC-200M", "Per appliance", "Y", "$385.00"],
            ["Edge Appliance 16GB", "Edge-16M", "Per appliance", "Y", "$100.00"],
            ["Real-Time Penetration Testing", "RTPT", "Per IP", "M", "$7.00"],
            ["Vulnerability Assessment", "PT", "Per device", "M", "$1.00"],
            ["Network Assessment", "NA", "Per device", "M", "$1.00"],
          ]
        ),

        spacer(),
        sectionHeader("3.5 Email, Compliance, and Identity"),
        styledTable(
          ["Service", "Code", "Unit", "License", "Monthly Rate"],
          [
            ["E-Mail Archiving", "EA", "Per user", "M", "$4.00"],
            ["DMARC/DKIM Management", "DKIM", "Per domain", "M", "$20.00"],
            ["Site Assessment", "SA", "Per domain", "M", "$50.00"],
            ["Veeam 365 Backup", "V365", "Per user", "M", "$2.50"],
            ["Anti-Spam Basic", "ASB", "Per user", "M", "$4.25"],
            ["Anti-Spam Standard (+ Encryption)", "ASA", "Per user", "M", "$6.25"],
            ["Anti-Spam Professional", "ASP", "Per user", "M", "$10.25"],
            ["Anti-Spam GSuite", "ASG", "Per user", "M", "$6.25"],
            ["Phishing Training", "PHT", "Per user", "M", "$6.00"],
            ["SSO / 2FA Login", "SSO-2FA", "Per user", "M", "$12.00"],
            ["SSO / Desktop", "SSO-DSK", "Per user", "M", "$6.00"],
            ["Credential Manager", "CRM", "Per user", "M", "$5.00"],
          ]
        ),

        // ── SECTION 4: SIP TRUNK, HOSTING, LICENSING ──
        spacer(),
        colorBanner("4. SIP TRUNK, HOSTING, AND LICENSING SERVICES", DARK_CHARCOAL, WHITE, 24),
        spacer(100),
        styledTable(
          ["Service", "Code", "Unit", "License", "Monthly Rate"],
          [
            ["SIP Trunk", "\u2014", "Per trunk", "M", "Per Service Order"],
            ["Voice Package", "\u2014", "Per package", "M", "Per Service Order"],
            ["DID Number", "\u2014", "Per number", "M", "Per Service Order"],
            ["Hosting \u2014 Web IIS", "HIIS", "Per domain", "M", "$10.00"],
            ["Hosting \u2014 Web WordPress", "HWP", "Per domain", "M", "$10.00"],
            ["Hosting \u2014 Web Magento", "HMG", "Per domain", "M", "$10.00"],
            ["My VDI", "MYVDI", "Per user", "M", "$10.00"],
            ["MDM (iOS)", "MDMIOS", "Per device", "M", "$4.00"],
            ["My Disk (File Sharing & Backup)", "MDU", "Per user", "M", "$16.00"],
            ["Veeam VBR (Backup & Replication)", "VBR", "Per VM", "M", "$13.00"],
            ["Veeam One (Backup Management)", "VONE", "Per VM", "M", "$3.00"],
            ["365 Azure Directory P2", "MS-ADP2", "Per user", "M", "$9.00"],
            ["MSFT \u2014 RDP SAL", "MS-WRDS", "Per license", "M", "$9.20"],
            ["MSFT \u2014 SQL Std SAL", "MS-SSSE", "Per license", "M", "$18.50"],
            ["MSFT \u2014 SQL Std Core", "MS-SSSC", "Per license", "M", "$175.00"],
            ["MSFT \u2014 Sharepoint SAL", "MS-SPSE", "Per license", "M", "$4.00"],
            ["MSFT \u2014 Exchange Std SAL", "MS-ESS", "Per license", "M", "$3.50"],
            ["MSFT \u2014 Exchange Ent SAL", "MS-EESS", "Per license", "M", "$4.00"],
            ["MSFT \u2014 Std Core 2 LIC", "MS-STD", "Per license", "M", "$5.25"],
            ["Foxit PDF Business", "FX-BSPDF", "Per license", "Y", "$14.00"],
          ]
        ),

        // ── SECTION 5: TERMS ──
        new Paragraph({ children: [new PageBreak()] }),
        colorBanner("5. TERMS", DARK_CHARCOAL, WHITE, 24),
        spacer(100),

        sectionHeader("5.01 Rate Adjustments"),
        bodyText("Technijian may adjust the rates in this Schedule upon sixty (60) days written notice to Client. Adjusted rates shall take effect at the start of the next Renewal Term of the Agreement."),

        spacer(100),
        sectionHeader("5.02 Volume Discounts"),
        bodyText("Volume-based pricing may be negotiated and documented in the applicable Service Order or Subscription Order."),

        spacer(100),
        sectionHeader("5.03 Minimum Billing"),
        bodyText("Contracted Virtual Staff hours are billed per the Cycle-Based Billing Model described in Schedule A, Part 3, at the BWH Contracted Rate. Ad hoc (non-contracted) support is billed at the Standard Rate in 15-minute increments. Upon cancellation or termination, any unpaid hour balance shall be invoiced at the applicable Standard Rate as set forth in Schedule A, Section 3.3(e)."),

        spacer(100),
        sectionHeader("5.04 Relationship to Price List"),
        bodyText("Technijian maintains a separate Services Price List that provides the current catalog of available services and list prices. The Price List may be updated by Technijian from time to time and shall be made available to Client upon request. In the event of a conflict between the Price List and this Rate Card, the rates documented in this Rate Card (Schedule C) shall govern for the duration of the then-current term. Any rate change shall be subject to the sixty (60) day written notice and Renewal Term effective date requirements set forth in Section 5.01 above and MSA Section 9.02."),

        // ── SCHEDULE C SIGNATURES ──
        spacer(),
        numberedSectionHeader("", "Signatures"),
        spacer(100),
        bodyText("IN WITNESS WHEREOF, the parties have executed this Rate Card as of the Effective Date."),
        spacer(),

        bodyBoldPrefix("TECHNIJIAN, INC.", ""),
        sigLine("By: ___________________________________", "/tSign/"),
        sigLine("Name: _________________________________", "/tName/"),
        sigLine("Title: _________________________________", "/tTitle/"),
        sigLine("Date: _________________________________", "/tDate/"),
        spacer(),

        bodyBoldPrefix(CLIENT_NAME.toUpperCase(), ""),
        sigLine("By: ___________________________________", "/cSign/"),
        sigLine("Name: _________________________________", "/cName/"),
        sigLine("Title: _________________________________", "/cTitle/"),
        sigLine("Date: _________________________________", "/cDate/"),

        spacer(),
        ctaBanner(),
      ]
    },
  ]
});

// ── Generate DOCX ──
const outPath = path.join(__dirname, '..', '02_MSA', 'MSA-BWH.docx');
Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync(outPath, buffer);
  const sz = fs.statSync(outPath).size;
  console.log(`Created: ${outPath}  (${sz.toLocaleString()} bytes)`);
}).catch(err => {
  console.error('Error generating DOCX:', err);
  process.exit(1);
});
