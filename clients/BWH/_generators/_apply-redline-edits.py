"""
Apply BWH MSA + Schedule A redline edits per Dave's 2026-04-28 acceptance.

The JS source files use \\u201C / \\u201D / \\u2014 / \\u2019 escape sequences
(6 literal ASCII bytes each) inside JS string literals, NOT the real Unicode
characters. So we preprocess each old/new fragment to convert:
    "    -> \\u201C
    "    -> \\u201D
    --   -> \\u2014  (em-dash; using two ASCII hyphens as marker in source)
    ASCII apostrophe inside JS strings stays as ' (we use a marker)
    minus -> \\u2212 (only used in math: 75% x (12 - N))

To keep the Python source readable we use ASCII placeholders and convert at
runtime. Do NOT type real curly quotes anywhere -- always use the placeholder.
"""
import sys
from pathlib import Path

GEN_DIR = Path(__file__).parent


def to_js(s: str) -> str:
    """Convert ASCII placeholders to the JS-source escape sequences the file uses.
    The file stores fancy punctuation as 6-byte ASCII escapes like \\u201C inside
    JS string literals (NOT as real Unicode characters)."""
    s = s.replace("<<LCQ>>", "\\u201C")   # left curly double quote
    s = s.replace("<<RCQ>>", "\\u201D")   # right curly double quote
    s = s.replace("<<EM>>", "\\u2014")    # em-dash
    s = s.replace("<<APOS>>", "\\u2019")  # right single quote / apostrophe
    s = s.replace("<<MINUS>>", "\\u2212") # minus sign
    s = s.replace("<<MUL>>", "\\u00D7")   # multiplication sign x
    return s


# ─────────────────────────────────────────────────────────────────────────
# build-msa-signing.js  edits
# ─────────────────────────────────────────────────────────────────────────
msa_path = GEN_DIR / "build-msa-signing.js"
with open(msa_path, "r", encoding="utf-8", newline="") as f:
    msa = f.read()

edits: list[tuple[str, str]] = []

# A. Section 2 header comment (uses U+2500 box-draw chars `──` literal)
edits.append((
    "// ── SECTION 2: TERM AND RENEWAL ──",
    "// ── SECTION 2: TERM AND TERMINATION ──"
))

# B. Section 2 numbered header
edits.append((
    'numberedSectionHeader("2", "Term and Renewal")',
    'numberedSectionHeader("2", "Term and Termination")'
))

# C. Auto-renewal info box -> No-renewal info box
old_info = (
    'infoBox(\r\n'
    '          "AUTOMATIC RENEWAL NOTICE:",\r\n'
    '          "This Agreement will automatically renew for successive twelve (12) month periods unless you cancel at least sixty (60) days before the end of the current term. You may cancel by sending written notice to Technijian at the address above or by email to contracts@technijian.com. Technijian will send a renewal reminder at least thirty (30) days before each renewal date."\r\n'
    '        ),'
)
new_info = to_js(
    'infoBox(\r\n'
    '          "TERM NOTICE <<EM>> NO AUTOMATIC RENEWAL:",\r\n'
    '          "This Agreement has a twelve (12) month Initial Term. There is no automatic renewal. Upon expiration of the Initial Term, this Agreement continues on a month-to-month basis until either Party terminates under Section 2.03 (Termination for Convenience) or Section 2.04 (Termination for Cause). Either Party may end the month-to-month continuation upon sixty (60) days written notice with no wind-down fee."\r\n'
    '        ),'
)
edits.append((old_info, new_info))

# D. §2.02 Renewal -> Continuation After Initial Term
old_202 = to_js(
    'numbered("2.02.", "Renewal. Upon expiration of the Initial Term, this Agreement shall automatically renew for successive twelve (12) month periods (each a <<LCQ>>Renewal Term<<RCQ>>), unless either Party provides written notice of non-renewal at least sixty (60) days prior to the expiration of the then-current term. Technijian shall send Client a written renewal reminder at least thirty (30) days prior to each renewal date, which shall restate the auto-renewal terms and cancellation method."),'
)
new_202 = (
    'numbered("2.02.", "Continuation After Initial Term. Upon expiration of the Initial Term, this Agreement shall continue on a month-to-month basis until terminated by either Party in accordance with Section 2.03 (Termination for Convenience) or Section 2.04 (Termination for Cause). For avoidance of doubt, no automatic renewal term shall apply, and the Initial Term shall not extend beyond twelve (12) months unless extended by mutual written agreement. Either Party may terminate the month-to-month continuation upon sixty (60) days written notice without payment of any wind-down fee under Section 2.03."),'
)
edits.append((old_202, new_202))

# E. §2.03 Termination for Convenience
old_203 = to_js(
    'numbered("2.03.", "Termination for Convenience. Either Party may terminate this Agreement for any reason upon sixty (60) days written notice to the other Party. If Client terminates for convenience during the Initial Term or any Renewal Term, Client shall pay an early termination fee equal to: (a) any unrecoverable third-party costs committed by Technijian on Client<<APOS>>s behalf (including prepaid licenses, committed hosting, and contracted offshore resources); plus (b) a wind-down fee calculated as follows: 75% of the average monthly recurring fees for the three (3) months preceding the termination notice, multiplied by the number of months remaining in the current term, up to a maximum of three (3) months<<APOS>> average recurring fees. The early termination fee constitutes liquidated damages and represents a reasonable estimate of Technijian<<APOS>>s anticipated damages from early termination, including committed capacity, staffing, and unrecoverable vendor obligations, and is not a penalty. The Parties acknowledge that actual damages from early termination would be difficult or impracticable to calculate at the time of contracting."),'
)
new_203 = to_js(
    'numbered("2.03.", "Termination for Convenience. Either Party may terminate this Agreement for any reason upon sixty (60) days written notice to the other Party. If Client terminates for convenience during the Initial Term, Client shall pay an early termination fee equal to: (a) any unrecoverable third-party costs committed by Technijian on Client<<APOS>>s behalf (including prepaid licenses, committed hosting, and contracted offshore resources); plus (b) a wind-down fee calculated using the formula 75% <<MUL>> (12 <<MINUS>> N) / 12 <<MUL>> Average MRR, where N equals the number of completed months of the Initial Term as of the date the termination notice is given. By the end of Month 12 of the Initial Term the wind-down fee equals zero. <<LCQ>>Average MRR<<RCQ>> means the average of the three (3) most recent fully-billed Monthly Service Invoices for recurring services only, excluding one-time items, SOW project work, ad-hoc hourly billings, and equipment or perpetual license invoices. The early termination fee constitutes liquidated damages and represents a reasonable estimate of Technijian<<APOS>>s anticipated damages from early termination, including committed capacity, staffing, and unrecoverable vendor obligations, and is not a penalty. The Parties acknowledge that actual damages from early termination would be difficult or impracticable to calculate at the time of contracting. After expiration of the Initial Term, no wind-down fee under this Section shall apply, and Client<<APOS>>s only obligation upon termination for convenience shall be sixty (60) days written notice and payment of all undisputed amounts accrued through the effective termination date."),'
)
edits.append((old_203, new_203))

# F. §2.05(b) — 5 business day transition + escrow
old_205b = to_js(
    'numbered("(b)", "Technijian shall provide reasonable transition assistance for a period of up to thirty (30) days following termination, provided that Client has paid all amounts owed under this Agreement in full, including any accrued late fees and collection costs. If Client has any outstanding balance at the time of termination, Technijian may withhold transition assistance until payment is received, or condition transition assistance upon Client<<APOS>>s execution of a payment plan acceptable to Technijian.", 1),'
)
new_205b = to_js(
    'numbered("(b)", "Technijian shall begin transition assistance within five (5) business days of the effective termination date and shall provide reasonable transition assistance for a period of up to thirty (30) days following termination. If Client has an outstanding undisputed balance at the time of termination, Technijian may withhold transition assistance until payment is received, or condition transition assistance upon Client<<APOS>>s execution of a payment plan acceptable to Technijian. If Client disputes any portion of the outstanding balance in good faith, Client shall (i) place the disputed amount in a mutually acceptable escrow account pending resolution, and (ii) deliver to Technijian a written particularization identifying the specific invoice(s), the amount(s) in dispute, and the basis for the dispute with reasonable specificity. Technijian shall not withhold transition assistance with respect to amounts properly placed in escrow under this subsection. Resolution of escrowed amounts shall follow Section 3.05 (Disputed Invoices) and Section 8 (Dispute Resolution).", 1),'
)
edits.append((old_205b, new_205b))

# G. §2.05(d) — add Section 12 to survival list
old_205d = (
    'numbered("(d)", "The following sections shall survive termination: Section 3 (Payment), Section 4 (Confidentiality), Section 5 (Limitation of Liability), Section 6 (Indemnification), Section 7 (Intellectual Property), Section 8 (Dispute Resolution), Section 9.03 (Severability), Section 9.04 (Waiver), Section 9.05 (Assignment), Section 9.08 (Governing Law), Section 9.09 (Personnel Transition Fee), Section 10 (Data Protection), and Section 11 (Insurance, which shall remain in effect through the end of any transition assistance period under Section 2.05(b)), and any other provision that by its nature is intended to survive termination.", 1),'
)
new_205d = (
    'numbered("(d)", "The following sections shall survive termination: Section 3 (Payment), Section 4 (Confidentiality), Section 5 (Limitation of Liability), Section 6 (Indemnification), Section 7 (Intellectual Property), Section 8 (Dispute Resolution), Section 9.03 (Severability), Section 9.04 (Waiver), Section 9.05 (Assignment), Section 9.08 (Governing Law), Section 9.09 (Personnel Transition Fee), Section 10 (Data Protection), Section 11 (Insurance, which shall remain in effect through the end of any transition assistance period under Section 2.05(b)), Section 12 (Transition Provisions), and any other provision that by its nature is intended to survive termination.", 1),'
)
edits.append((old_205d, new_205d))

# H. §3.07 Acceleration — split cure period
old_307 = to_js(
    'numbered("3.07.", "Acceleration. Upon the occurrence of any of the following events, all fees, charges, and amounts owing under this Agreement, all Schedules, and all SOWs shall become immediately due and payable without further notice or demand: (a) Client fails to pay any undisputed invoice within forty-five (45) days of the due date; (b) Client terminates this Agreement or any Schedule while any invoices remain unpaid; (c) Client becomes insolvent, files for bankruptcy, or has a receiver appointed for its assets; or (d) Client is the subject of a material adverse change in its financial condition that, in Technijian<<APOS>>s reasonable judgment, impairs Client<<APOS>>s ability to perform its payment obligations."),'
)
new_307 = to_js(
    'numbered("3.07.", "Acceleration. Upon the occurrence of any of the following events, all fees, charges, and amounts owing under this Agreement, all Schedules, and all SOWs shall become immediately due and payable: (a) Client fails to pay any undisputed invoice within forty-five (45) days of the due date, provided that Technijian shall first deliver written notice of the non-payment trigger and Client shall have ten (10) business days from receipt of such notice to cure the non-payment before acceleration takes effect (the <<LCQ>>Non-Payment Cure Period<<RCQ>>); during the Non-Payment Cure Period, the disputed portion of any invoice subject to a good-faith written dispute under Section 3.05 shall not count toward the forty-five (45) day non-payment threshold; (b) Client terminates this Agreement or any Schedule while any invoices remain unpaid; (c) Client becomes insolvent, files for bankruptcy, or has a receiver appointed for its assets; or (d) Client is the subject of a material adverse change in its financial condition that, in Technijian<<APOS>>s reasonable judgment, impairs Client<<APOS>>s ability to perform its payment obligations. The Non-Payment Cure Period applies only to subsection (a); the events described in subsections (b), (c), and (d) constitute objective events for which no cure period is available, and acceleration upon such events takes effect immediately upon written notice."),'
)
edits.append((old_307, new_307))

# I. Insert SECTION 12 before SIGNATURES marker
section_12_block = to_js(
    '\r\n'
    '        // ── SECTION 12: TRANSITION PROVISIONS ──\r\n'
    '        spacer(),\r\n'
    '        numberedSectionHeader("12", "Transition Provisions"),\r\n'
    '        spacer(40),\r\n'
    '        numbered("12.01.", "Legacy Balance Acknowledgment."),\r\n'
    '        numbered("(a)", "Acknowledged Balance. The Parties acknowledge an outstanding balance of one thousand seven and 30/100 contracted hours (1,007.30 hours) as of the Effective Date, representing services performed by Technijian and not yet absorbed under the prior Master Service Agreement between the Parties (the <<LCQ>>Legacy Balance<<RCQ>>). The Legacy Balance comprises: (i) India Tech Normal: 573.81 hours; (ii) India Tech After Hours: 290.23 hours; (iii) USA Tech Normal: 143.26 hours; and (iv) Systems Architect: 0.00 hours. The Legacy Balance is documented by Invoice #28148 dated April 1, 2026 and the line-item ticket-level accounting workbook BWH-Hours-Accounting-Life-of-Contract.xlsx provided to Client on April 24, 2026, and is locked at signing of this Agreement.", 1),\r\n'
    '        numbered("(b)", "Resolution Path. The Parties intend for the Legacy Balance to be absorbed through the cycle mechanics described in Schedule A, Section 3.3 over the Initial Term. Provided this Agreement remains in effect, no separate hourly invoicing of the Legacy Balance shall occur; the Legacy Balance shall be resolved through cycle dynamics under Schedule A.", 1),\r\n'
    '        numbered("(c)", "Termination Treatment.", 1),\r\n'
    '        numbered("1.", "If Client terminates this Agreement without cause under Section 2.03, or if Technijian terminates this Agreement for cause under Section 2.04(a) due to Client<<APOS>>s default, or if this Agreement is terminated under Section 2.04(b) (insolvency or bankruptcy), any unresolved portion of the Legacy Balance shall be invoiced at the Rate Card Hourly Rate ($150.00 per hour) per Schedule C and shall become immediately due and payable.", 2),\r\n'
    '        numbered("2.", "If Client terminates this Agreement for cause under Section 2.04(a) based on Technijian<<APOS>>s material uncured failure to meet the Response Time Service Level set forth in Schedule A, Section 3.5, the unresolved portion of the Legacy Balance shall be waived in full, and no invoicing of the Legacy Balance shall occur with respect to such termination.", 2),\r\n'
    '        numbered("(d)", "Definition of Material Uncured Response Time Failure. For purposes of subsection (c)(2), Technijian<<APOS>>s failure to meet the Response Time Service Level shall be deemed material and uncured if all of the following conditions are satisfied: (i) Technijian fails to acknowledge support tickets within four (4) business hours of ticket creation in the Client Portal with respect to more than twenty-five percent (25%) of support tickets opened during a billing month, measured by Client Portal ticket creation and acknowledgment timestamps; (ii) such failure occurs during three (3) consecutive billing months; (iii) Client delivers to Technijian a written notice identifying the specific tickets, billing months, and evidence of breach (the <<LCQ>>SLA Failure Notice<<RCQ>>); and (iv) Technijian fails to cure such failure within thirty (30) business days following receipt of the SLA Failure Notice. If Technijian cures the failure within the cure period, no termination right under subsection (c)(2) shall vest with respect to that SLA Failure Notice, and the Legacy Balance shall remain governed by subsection (c)(1).", 1),\r\n'
    '        numbered("(e)", "No Reduced Rate. For avoidance of doubt, the Legacy Balance shall not be invoiced at any rate other than the Rate Card Hourly Rate ($150.00 per hour) per Schedule C. The Contracted Rates set forth in Schedule A, Section 3.2 shall not apply to the invoicing of the Legacy Balance under any termination scenario, and no other reduced or discounted rate shall apply.", 1),\r\n'
    '        numbered("(f)", "Survival. This Section 12.01 shall survive termination of this Agreement.", 1),\r\n'
    '\r\n'
    '        // ── SIGNATURES ──\r\n'
)
old_sig_marker = "        // ── SIGNATURES ──\r\n"
edits.append((old_sig_marker, section_12_block))

# Apply all edits with verification (idempotent: skip if already applied)
for i, (old, new) in enumerate(edits):
    if old not in msa:
        if new in msa:
            print(f"SKIP msa edit #{i}: already applied")
            continue
        print(f"FAIL msa edit #{i}: old not found and new not found")
        sys.exit(1)
    if msa.count(old) > 1:
        print(f"FAIL msa edit #{i}: old string occurs {msa.count(old)} times")
        sys.exit(1)
    msa = msa.replace(old, new, 1)
    print(f"OK msa edit #{i}")

with open(msa_path, "w", encoding="utf-8", newline="") as f:
    f.write(msa)
print(f"Wrote {msa_path}")

# Sanity post-checks: verify expected content present
checks = [
    "Term and Termination",
    "Continuation After Initial Term",
    "TERM NOTICE",
    "Non-Payment Cure Period",
    "TRANSITION PROVISIONS",
    "Legacy Balance Acknowledgment",
    "1,007.30 hours",
    "twenty-five percent (25%)",
    "$150.00 per hour",
]
for c in checks:
    assert c in msa, f"Post-check failed: {c} not found in MSA"
print("All MSA post-checks passed.")


# ─────────────────────────────────────────────────────────────────────────
# build-schedule-a.js  edits
# ─────────────────────────────────────────────────────────────────────────
sched_path = GEN_DIR / "build-schedule-a.js"
with open(sched_path, "r", encoding="utf-8", newline="") as f:
    sched = f.read()

sched_edits: list[tuple[str, str]] = []

# A. §3.3(e)(1) — Replace cancellation language with $150 always + reference to Section 12 of MSA
old_e1 = to_js(
    'numbered("(e)", "Cancellation. If Client terminates Virtual Staff services or this Agreement:"),\r\n'
    '        numbered("1.", "Any positive running balance (actual hours exceeding billed hours) shall become immediately due and payable. The unpaid hours shall be invoiced at the applicable Hourly Rate from the Rate Card (Schedule C), not the Contracted Rate. This reflects the rate that would have applied had Client engaged Technijian on an ad hoc hourly basis without a Cycle commitment.", 1),\r\n'
    '        numbered("2.", "Any negative running balance (billed hours exceeding actual hours) does not entitle Client to a credit, refund, or offset against the final invoice. The unpaid balance is simply zero and no further amounts are due from either Party with respect to that role.", 1),\r\n'
    '        numbered("3.", "The Cycle-Based Billing Model provides Client with Contracted Rates that are lower than the standard Hourly Rates as consideration for Client<<APOS>>s commitment to the Cycle. The application of Hourly Rates upon cancellation reflects the removal of that commitment and the corresponding rate benefit.", 1),'
)
new_e1 = to_js(
    'numbered("(e)", "Cancellation. If Client terminates Virtual Staff services or this Agreement:"),\r\n'
    '        numbered("1.", "Any positive running balance (actual hours under the current Cycle exceeding billed hours under the current Cycle) shall become immediately due and payable at the Rate Card Hourly Rate ($150.00 per hour) from Schedule C, not the Contracted Rate. The Contracted Rates set forth in Section 3.2 are provided in consideration for Client<<APOS>>s commitment to the Cycle, and shall not apply to unpaid hours upon cancellation under any circumstance.", 1),\r\n'
    '        numbered("2.", "Any negative running balance (billed hours exceeding actual hours) does not entitle Client to a credit, refund, or offset against the final invoice. The unpaid balance is simply zero and no further amounts are due from either Party with respect to that role.", 1),\r\n'
    '        numbered("3.", "The Legacy Balance described in Section 12.01 of the Master Service Agreement shall be governed by the termination treatment set forth in Section 12.01(c) of the Master Service Agreement, not by this subsection (e). For avoidance of doubt, no rate other than the Rate Card Hourly Rate ($150.00 per hour) per Schedule C shall apply to either the Cycle running balance under this Section 3.3 or the Legacy Balance under Section 12.01 of the Master Service Agreement upon cancellation, and no reduced or discounted rate shall apply.", 1),'
)
sched_edits.append((old_e1, new_e1))

# B. Replace §3.5 Service Levels table with response-time-only commitment
old_35 = (
    'sectionHeader("3.5 Service Levels"),\r\n'
    '        styledTable(\r\n'
    '          ["Service Level", "Target"],\r\n'
    '          [\r\n'
    '            ["Infrastructure Uptime", "99.9% monthly (excluding scheduled maintenance)"],\r\n'
    '            ["Scheduled Maintenance", "Tuesday evenings and Saturdays (with advance notice)"],\r\n'
    '            ["Critical Incident Response", "Within 1 hour of notification"],\r\n'
    '            ["Standard Support Response", "Within 4 business hours"],\r\n'
    '            ["Emergency Maintenance", "As needed with reasonable notice"],\r\n'
    '          ]\r\n'
    '        ),'
)
new_35 = to_js(
    'sectionHeader("3.5 Service Level Commitments"),\r\n'
    '        bodyText("Technijian commits to a single measurable Service Level Agreement under this Schedule: Response Time. Resolution times are not guaranteed because Client<<APOS>>s environment may include equipment that is out of warranty, third-party software requiring vendor escalation, and other factors outside Technijian<<APOS>>s control."),\r\n'
    '        spacer(60),\r\n'
    '        styledTable(\r\n'
    '          ["Service Level", "Commitment"],\r\n'
    '          [\r\n'
    '            ["Response Time (all severities)", "Within four (4) business hours of ticket creation in the Client Portal"],\r\n'
    '            ["Resolution Time", "Not guaranteed; commercially reasonable efforts only"],\r\n'
    '            ["Infrastructure Uptime (target)", "99.9% monthly, commercially reasonable efforts (no service credit unless expressly granted under Section 3.5a)"],\r\n'
    '            ["Scheduled Maintenance", "Tuesday evenings and Saturdays, with reasonable advance notice"],\r\n'
    '            ["Emergency Maintenance", "As needed with reasonable notice"],\r\n'
    '          ]\r\n'
    '        ),\r\n'
    '        spacer(80),\r\n'
    '        numbered("(a)", "Response Time Definition. <<LCQ>>Response<<RCQ>> means initial human acknowledgment of the support ticket in the Client Portal, including assignment to a technician and confirmation of receipt to Client. Response Time is measured from Client Portal ticket creation timestamp to ticket acknowledgment timestamp. Response Time applies to all support tickets regardless of severity classification."),\r\n'
    '        numbered("(b)", "Resolution Not Guaranteed. The Parties acknowledge that resolution timeframes depend on factors that may include third-party vendor support timelines, equipment warranty status, software vendor escalation cycles, hardware availability, and other circumstances beyond Technijian<<APOS>>s reasonable control. Technijian shall use commercially reasonable efforts to drive each support ticket to resolution but does not commit to any specific resolution timeframe under this Schedule."),\r\n'
    '        numbered("(c)", "Measurement Period. Response Time compliance is measured per billing month using Client Portal ticket data. Tickets opened in a given billing month are evaluated for Response Time compliance based on the timestamps recorded in the Client Portal."),\r\n'
    '        numbered("(d)", "Relationship to MSA Section 12.01. Failure to meet the Response Time Service Level may, if material and uncured as defined in Section 12.01(d) of the Master Service Agreement, support a termination for cause under MSA Section 2.04(a) and trigger the Legacy Balance waiver in MSA Section 12.01(c)(2). Resolution Time and Infrastructure Uptime are not bases for the Legacy Balance waiver under MSA Section 12.01(c)(2)."),'
)
sched_edits.append((old_35, new_35))

# C. Add §3.6 Usage Notifications and Cycle Discipline immediately after §3.5a Sole Remedy block,
#    by inserting before the GENERAL TERMS FOR SCHEDULE A page break.
old_general_marker = (
    '        // ── GENERAL TERMS FOR SCHEDULE A ──\r\n'
)
section_36_block = to_js(
    '        spacer(),\r\n'
    '        sectionHeader("3.6 Usage Notifications and Cycle Discipline"),\r\n'
    '        numbered("(a)", "Notifications. Technijian shall track Client<<APOS>>s monthly Virtual Staff hour consumption against the monthly billed hours per role and shall provide notifications to Client through the Client Portal and to Client<<APOS>>s designated point of contact when cumulative consumption in a billing month reaches: (i) 50% of monthly billed hours; (ii) 60% of monthly billed hours; (iii) 70% of monthly billed hours; and (iv) 80% of monthly billed hours."),\r\n'
    '        numbered("(b)", "80% Threshold. Upon reaching 80% of monthly billed hours for any role in a billing month, Technijian shall notify Client that the monthly cap is approaching, and Technijian may decline to begin new non-emergency support requests under that role for the remainder of the billing month. Client may continue to submit emergency (P1 production-down) requests, which Technijian shall continue to address subject to the Response Time Service Level in Section 3.5."),\r\n'
    '        numbered("(c)", "Purpose. The notification thresholds and the 80% practice are intended to maintain cycle integrity by helping ensure Client<<APOS>>s actual consumption stays within monthly billed hours during the term of this Schedule, so that the under-utilization paydown described in Section 3.3 and Section 12.01 of the Master Service Agreement can resolve the Legacy Balance through cycle dynamics rather than through end-of-cycle invoicing or termination."),\r\n'
    '        numbered("(d)", "Override. Client may direct Technijian in writing to continue non-emergency work beyond 80% of monthly billed hours for a given role and billing month. Hours worked beyond 80% on Client<<APOS>>s written direction shall be tracked and may, at Technijian<<APOS>>s option, be billed as out-of-contract services per Schedule C if persistent overuse is observed for more than three (3) consecutive billing months."),\r\n'
    '        numbered("(e)", "No Service Reduction. The 80% practice does not reduce the monthly billed hours for which Client is invoiced, nor does it constitute a credit, refund, or offset of any kind. The 80% practice is a queue-management mechanism to support cycle paydown and may be adjusted by mutual written agreement of the Parties at any time."),\r\n'
    '\r\n'
    '        // ── GENERAL TERMS FOR SCHEDULE A ──\r\n'
)
sched_edits.append((old_general_marker, section_36_block))

# Apply Schedule A edits with verification (idempotent)
for i, (old, new) in enumerate(sched_edits):
    if old not in sched:
        if new in sched:
            print(f"SKIP sched edit #{i}: already applied")
            continue
        print(f"FAIL sched edit #{i}: old not found and new not found")
        sys.exit(1)
    if sched.count(old) > 1:
        print(f"FAIL sched edit #{i}: old occurs {sched.count(old)} times")
        sys.exit(1)
    sched = sched.replace(old, new, 1)
    print(f"OK sched edit #{i}")

with open(sched_path, "w", encoding="utf-8", newline="") as f:
    f.write(sched)
print(f"Wrote {sched_path}")

sched_checks = [
    "Service Level Commitments",
    "Within four (4) business hours",
    "Resolution Time",
    "Not guaranteed",
    "3.6 Usage Notifications",
    "80% Threshold",
    "Section 12.01",
    "$150.00 per hour",
]
for c in sched_checks:
    assert c in sched, f"Post-check failed: {c} not found in Schedule A"
print("All Schedule A post-checks passed.")


# ─────────────────────────────────────────────────────────────────────────
# SECOND PASS — close the §3.6/§3.5 loophole + Renewal Term cleanup
# ─────────────────────────────────────────────────────────────────────────
print()
print("=== Second pass: loophole closures + Renewal Term cleanup ===")

# Re-read the now-modified files
with open(msa_path, "r", encoding="utf-8", newline="") as f:
    msa = f.read()
with open(sched_path, "r", encoding="utf-8", newline="") as f:
    sched = f.read()

pass2_msa: list[tuple[str, str]] = []
pass2_sched: list[tuple[str, str]] = []

# MSA edit J: §12.01(d) — exclude deferred-and-not-escalated tickets from breach calc
msa_old_12_01_d = to_js(
    'numbered("(d)", "Definition of Material Uncured Response Time Failure. For purposes of subsection (c)(2), Technijian<<APOS>>s failure to meet the Response Time Service Level shall be deemed material and uncured if all of the following conditions are satisfied: (i) Technijian fails to acknowledge support tickets within four (4) business hours of ticket creation in the Client Portal with respect to more than twenty-five percent (25%) of support tickets opened during a billing month, measured by Client Portal ticket creation and acknowledgment timestamps; (ii) such failure occurs during three (3) consecutive billing months; (iii) Client delivers to Technijian a written notice identifying the specific tickets, billing months, and evidence of breach (the <<LCQ>>SLA Failure Notice<<RCQ>>); and (iv) Technijian fails to cure such failure within thirty (30) business days following receipt of the SLA Failure Notice. If Technijian cures the failure within the cure period, no termination right under subsection (c)(2) shall vest with respect to that SLA Failure Notice, and the Legacy Balance shall remain governed by subsection (c)(1).", 1),'
)
msa_new_12_01_d = to_js(
    'numbered("(d)", "Definition of Material Uncured Response Time Failure. For purposes of subsection (c)(2), Technijian<<APOS>>s failure to meet the Response Time Service Level shall be deemed material and uncured if all of the following conditions are satisfied: (i) Technijian fails to acknowledge support tickets within four (4) business hours of ticket creation in the Client Portal with respect to more than twenty-five percent (25%) of support tickets opened during a billing month, measured by Client Portal ticket creation and acknowledgment timestamps; (ii) such failure occurs during three (3) consecutive billing months; (iii) Client delivers to Technijian a written notice identifying the specific tickets, billing months, and evidence of breach (the <<LCQ>>SLA Failure Notice<<RCQ>>); and (iv) Technijian fails to cure such failure within thirty (30) business days following receipt of the SLA Failure Notice. Tickets deferred by Technijian under Schedule A, Section 3.6 (Usage Notifications and Cycle Discipline) and not timely escalated by Client under Schedule A, Section 3.6(f) shall be excluded from the calculation in clause (i) and shall not count toward the breach measurement under this subsection. If Technijian cures the failure within the cure period, no termination right under subsection (c)(2) shall vest with respect to that SLA Failure Notice, and the Legacy Balance shall remain governed by subsection (c)(1).", 1),'
)
pass2_msa.append((msa_old_12_01_d, msa_new_12_01_d))

# Schedule A edit K: §3.5(a) — clarify Response includes deferral notice
sched_old_35a = to_js(
    'numbered("(a)", "Response Time Definition. <<LCQ>>Response<<RCQ>> means initial human acknowledgment of the support ticket in the Client Portal, including assignment to a technician and confirmation of receipt to Client. Response Time is measured from Client Portal ticket creation timestamp to ticket acknowledgment timestamp. Response Time applies to all support tickets regardless of severity classification."),'
)
sched_new_35a = to_js(
    'numbered("(a)", "Response Time Definition. <<LCQ>>Response<<RCQ>> means initial human acknowledgment of the support ticket in the Client Portal, including assignment to a technician and confirmation of receipt to Client. Response Time is measured from Client Portal ticket creation timestamp to ticket acknowledgment timestamp. Response Time applies to all support tickets regardless of severity classification. A timely deferral notice issued under Section 3.6 shall constitute a Response within the meaning of this subsection, and the deferred ticket shall be excluded from the breach calculation under Master Service Agreement Section 12.01(d) unless timely escalated under Section 3.6(f)."),'
)
pass2_sched.append((sched_old_35a, sched_new_35a))

# Schedule A edit L: §3.6(b) — clarify deferral notice is the Response
sched_old_36b = to_js(
    'numbered("(b)", "80% Threshold. Upon reaching 80% of monthly billed hours for any role in a billing month, Technijian shall notify Client that the monthly cap is approaching, and Technijian may decline to begin new non-emergency support requests under that role for the remainder of the billing month. Client may continue to submit emergency (P1 production-down) requests, which Technijian shall continue to address subject to the Response Time Service Level in Section 3.5."),'
)
sched_new_36b = to_js(
    'numbered("(b)", "80% Threshold. Upon reaching 80% of monthly billed hours for any role in a billing month, Technijian shall notify Client that the monthly cap is approaching, and Technijian may decline to begin new non-emergency support requests under that role for the remainder of the billing month. Client may continue to submit emergency (P1 production-down) requests, which Technijian shall continue to address subject to the Response Time Service Level in Section 3.5. A written deferral notice issued by Technijian in response to a non-emergency request submitted at or above the 80% threshold shall constitute the Response under Section 3.5(a) for purposes of SLA compliance, and the deferred ticket shall be excluded from the breach calculation under MSA Section 12.01(d) unless Client timely escalates the ticket under subsection (f) below."),'
)
pass2_sched.append((sched_old_36b, sched_new_36b))

# Schedule A edit M: insert §3.6(f) Escalation and §3.6(g) Emergency Definition
#   before the GENERAL TERMS marker, immediately after current (e).
sched_old_general = (
    '        // ── GENERAL TERMS FOR SCHEDULE A ──\r\n'
)
sched_36fg_block = to_js(
    '        numbered("(f)", "Escalation. If Client in good faith believes a deferred ticket constitutes an Emergency (as defined in subsection (g) below) or otherwise should not have been deferred, Client shall escalate the ticket in writing within five (5) business days of the deferral notice, identifying the specific ticket and the basis for reclassification. Upon receipt of a timely escalation, Technijian shall reclassify the ticket and respond per the Response Time Service Level in Section 3.5. Tickets not escalated within the five (5) business day window shall be deemed properly deferred and shall not count toward the breach calculation in MSA Section 12.01(d). Improper deferrals identified through the escalation process do count toward the Section 12.01(d) calculation if Technijian fails to reclassify and respond within the four (4) business hour window after escalation."),\r\n'
    '        numbered("(g)", "Emergency Definition. For purposes of Section 3.5 and this Section 3.6, an <<LCQ>>Emergency<<RCQ>> (also <<LCQ>>P1 production-down<<RCQ>>) means a support request involving any of the following: (i) total loss of access to a production system used by five (5) or more end users; (ii) total loss of access to email, file shares, or critical line-of-business applications affecting five (5) or more end users; (iii) a confirmed cybersecurity incident involving active compromise of Client systems or data; or (iv) physical site outage at a Client location. Severity classification is initially made by Client at the time of ticket submission and may be reclassified by Technijian upon review of the ticket details, subject to Client<<APOS>>s escalation rights under subsection (f)."),\r\n'
    '\r\n'
    '        // ── GENERAL TERMS FOR SCHEDULE A ──\r\n'
)
pass2_sched.append((sched_old_general, sched_36fg_block))

# Schedule A edit N: Pricing Adjustments — remove "Renewal Term" reference
sched_old_pricing = (
    'bodyText("Pricing for services under this Schedule is subject to the Rate Card (Schedule C). Technijian may adjust rates upon sixty (60) days written notice, effective at the start of the next Renewal Term of the Agreement."),'
)
sched_new_pricing = (
    'bodyText("Pricing for services under this Schedule is subject to the Rate Card (Schedule C). Technijian may adjust rates upon sixty (60) days written notice, effective at the start of any month-to-month continuation period under MSA Section 2.02, or upon mutual written agreement during the Initial Term."),'
)
pass2_sched.append((sched_old_pricing, sched_new_pricing))

# Apply pass-2 MSA edits
for i, (old, new) in enumerate(pass2_msa):
    if old not in msa:
        if new in msa:
            print(f"SKIP pass2 msa edit #{i}: already applied")
            continue
        print(f"FAIL pass2 msa edit #{i}: old not found and new not found")
        sys.exit(1)
    if msa.count(old) > 1:
        print(f"FAIL pass2 msa edit #{i}: old occurs {msa.count(old)} times")
        sys.exit(1)
    msa = msa.replace(old, new, 1)
    print(f"OK pass2 msa edit #{i}")

with open(msa_path, "w", encoding="utf-8", newline="") as f:
    f.write(msa)

# Apply pass-2 Schedule A edits
for i, (old, new) in enumerate(pass2_sched):
    if old not in sched:
        if new in sched:
            print(f"SKIP pass2 sched edit #{i}: already applied")
            continue
        print(f"FAIL pass2 sched edit #{i}: old not found and new not found")
        sys.exit(1)
    if sched.count(old) > 1:
        print(f"FAIL pass2 sched edit #{i}: old occurs {sched.count(old)} times")
        sys.exit(1)
    sched = sched.replace(old, new, 1)
    print(f"OK pass2 sched edit #{i}")

with open(sched_path, "w", encoding="utf-8", newline="") as f:
    f.write(sched)

# Final post-checks
final_checks_msa = [
    "Tickets deferred by Technijian under Schedule A, Section 3.6",
    "shall be excluded from the calculation in clause (i)",
]
for c in final_checks_msa:
    assert c in msa, f"MSA pass2 check failed: {c}"

final_checks_sched = [
    "deferral notice issued under Section 3.6 shall constitute a Response",
    "written deferral notice issued by Technijian",
    "Escalation. If Client in good faith believes",
    "Emergency Definition",
    "month-to-month continuation period under MSA Section 2.02",
]
for c in final_checks_sched:
    assert c in sched, f"Schedule A pass2 check failed: {c}"

print("All pass-2 post-checks passed.")
