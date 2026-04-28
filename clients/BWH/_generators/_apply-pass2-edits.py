"""
PASS-2 ONLY: Close the §3.6/§3.5 loophole + Renewal Term cleanup.
This script ONLY touches subsection text edits (idempotent on content).
It does NOT do marker-anchored inserts.

Run after _apply-redline-edits.py has already added Section 12 and §3.6(a)-(e).
"""
import sys
from pathlib import Path

GEN_DIR = Path(__file__).parent

def to_js(s: str) -> str:
    s = s.replace("<<LCQ>>", "\\u201C")
    s = s.replace("<<RCQ>>", "\\u201D")
    s = s.replace("<<EM>>", "\\u2014")
    s = s.replace("<<APOS>>", "\\u2019")
    s = s.replace("<<MINUS>>", "\\u2212")
    s = s.replace("<<MUL>>", "\\u00D7")
    return s


# ─────── MSA file ───────
msa_path = GEN_DIR / "build-msa-signing.js"
with open(msa_path, "r", encoding="utf-8", newline="") as f:
    msa = f.read()

# §12.01(d) — exclude properly-deferred tickets from breach calculation
msa_old_12_01_d = to_js(
    'numbered("(d)", "Definition of Material Uncured Response Time Failure. For purposes of subsection (c)(2), Technijian<<APOS>>s failure to meet the Response Time Service Level shall be deemed material and uncured if all of the following conditions are satisfied: (i) Technijian fails to acknowledge support tickets within four (4) business hours of ticket creation in the Client Portal with respect to more than twenty-five percent (25%) of support tickets opened during a billing month, measured by Client Portal ticket creation and acknowledgment timestamps; (ii) such failure occurs during three (3) consecutive billing months; (iii) Client delivers to Technijian a written notice identifying the specific tickets, billing months, and evidence of breach (the <<LCQ>>SLA Failure Notice<<RCQ>>); and (iv) Technijian fails to cure such failure within thirty (30) business days following receipt of the SLA Failure Notice. If Technijian cures the failure within the cure period, no termination right under subsection (c)(2) shall vest with respect to that SLA Failure Notice, and the Legacy Balance shall remain governed by subsection (c)(1).", 1),'
)
msa_new_12_01_d = to_js(
    'numbered("(d)", "Definition of Material Uncured Response Time Failure. For purposes of subsection (c)(2), Technijian<<APOS>>s failure to meet the Response Time Service Level shall be deemed material and uncured if all of the following conditions are satisfied: (i) Technijian fails to acknowledge support tickets within four (4) business hours of ticket creation in the Client Portal with respect to more than twenty-five percent (25%) of support tickets opened during a billing month, measured by Client Portal ticket creation and acknowledgment timestamps; (ii) such failure occurs during three (3) consecutive billing months; (iii) Client delivers to Technijian a written notice identifying the specific tickets, billing months, and evidence of breach (the <<LCQ>>SLA Failure Notice<<RCQ>>); and (iv) Technijian fails to cure such failure within thirty (30) business days following receipt of the SLA Failure Notice. Tickets deferred by Technijian under Schedule A, Section 3.6 (Usage Notifications and Cycle Discipline) and not timely escalated by Client under Schedule A, Section 3.6(f) shall be excluded from the calculation in clause (i) and shall not count toward the breach measurement under this subsection. If Technijian cures the failure within the cure period, no termination right under subsection (c)(2) shall vest with respect to that SLA Failure Notice, and the Legacy Balance shall remain governed by subsection (c)(1).", 1),'
)

if msa_old_12_01_d in msa:
    if msa.count(msa_old_12_01_d) == 1:
        msa = msa.replace(msa_old_12_01_d, msa_new_12_01_d, 1)
        print("OK MSA §12.01(d) — added deferred-ticket exclusion")
    else:
        print(f"FAIL MSA §12.01(d): old occurs {msa.count(msa_old_12_01_d)} times")
        sys.exit(1)
elif msa_new_12_01_d in msa:
    print("SKIP MSA §12.01(d): already applied")
else:
    print("FAIL MSA §12.01(d): neither old nor new found")
    sys.exit(1)

with open(msa_path, "w", encoding="utf-8", newline="") as f:
    f.write(msa)


# ─────── Schedule A file ───────
sched_path = GEN_DIR / "build-schedule-a.js"
with open(sched_path, "r", encoding="utf-8", newline="") as f:
    sched = f.read()

sched_edits: list[tuple[str, str, str]] = []  # (label, old, new)

# §3.5(a) — clarify Response includes deferral notice
sched_edits.append((
    "§3.5(a) Response Time Definition",
    to_js('numbered("(a)", "Response Time Definition. <<LCQ>>Response<<RCQ>> means initial human acknowledgment of the support ticket in the Client Portal, including assignment to a technician and confirmation of receipt to Client. Response Time is measured from Client Portal ticket creation timestamp to ticket acknowledgment timestamp. Response Time applies to all support tickets regardless of severity classification."),'),
    to_js('numbered("(a)", "Response Time Definition. <<LCQ>>Response<<RCQ>> means initial human acknowledgment of the support ticket in the Client Portal, including assignment to a technician and confirmation of receipt to Client. Response Time is measured from Client Portal ticket creation timestamp to ticket acknowledgment timestamp. Response Time applies to all support tickets regardless of severity classification. A timely deferral notice issued under Section 3.6 shall constitute a Response within the meaning of this subsection, and the deferred ticket shall be excluded from the breach calculation under Master Service Agreement Section 12.01(d) unless timely escalated under Section 3.6(f)."),'),
))

# §3.6(b) — clarify deferral notice is the Response
sched_edits.append((
    "§3.6(b) 80% Threshold",
    to_js('numbered("(b)", "80% Threshold. Upon reaching 80% of monthly billed hours for any role in a billing month, Technijian shall notify Client that the monthly cap is approaching, and Technijian may decline to begin new non-emergency support requests under that role for the remainder of the billing month. Client may continue to submit emergency (P1 production-down) requests, which Technijian shall continue to address subject to the Response Time Service Level in Section 3.5."),'),
    to_js('numbered("(b)", "80% Threshold. Upon reaching 80% of monthly billed hours for any role in a billing month, Technijian shall notify Client that the monthly cap is approaching, and Technijian may decline to begin new non-emergency support requests under that role for the remainder of the billing month. Client may continue to submit emergency (P1 production-down) requests, which Technijian shall continue to address subject to the Response Time Service Level in Section 3.5. A written deferral notice issued by Technijian in response to a non-emergency request submitted at or above the 80% threshold shall constitute the Response under Section 3.5(a) for purposes of SLA compliance, and the deferred ticket shall be excluded from the breach calculation under MSA Section 12.01(d) unless Client timely escalates the ticket under subsection (f) below."),'),
))

# §3.6(e) — append (f) Escalation and (g) Emergency Definition AFTER (e)
sched_edits.append((
    "§3.6(e) -> append (f) and (g)",
    to_js('numbered("(e)", "No Service Reduction. The 80% practice does not reduce the monthly billed hours for which Client is invoiced, nor does it constitute a credit, refund, or offset of any kind. The 80% practice is a queue-management mechanism to support cycle paydown and may be adjusted by mutual written agreement of the Parties at any time."),'),
    to_js(
        'numbered("(e)", "No Service Reduction. The 80% practice does not reduce the monthly billed hours for which Client is invoiced, nor does it constitute a credit, refund, or offset of any kind. The 80% practice is a queue-management mechanism to support cycle paydown and may be adjusted by mutual written agreement of the Parties at any time."),\r\n'
        '        numbered("(f)", "Escalation. If Client in good faith believes a deferred ticket constitutes an Emergency (as defined in subsection (g) below) or otherwise should not have been deferred, Client shall escalate the ticket in writing within five (5) business days of the deferral notice, identifying the specific ticket and the basis for reclassification. Upon receipt of a timely escalation, Technijian shall reclassify the ticket and respond per the Response Time Service Level in Section 3.5. Tickets not escalated within the five (5) business day window shall be deemed properly deferred and shall not count toward the breach calculation in MSA Section 12.01(d). Improper deferrals identified through the escalation process do count toward the Section 12.01(d) calculation if Technijian fails to reclassify and respond within the four (4) business hour window after escalation."),\r\n'
        '        numbered("(g)", "Emergency Definition. For purposes of Section 3.5 and this Section 3.6, an <<LCQ>>Emergency<<RCQ>> (also <<LCQ>>P1 production-down<<RCQ>>) means a support request involving any of the following: (i) total loss of access to a production system used by five (5) or more end users; (ii) total loss of access to email, file shares, or critical line-of-business applications affecting five (5) or more end users; (iii) a confirmed cybersecurity incident involving active compromise of Client systems or data; or (iv) physical site outage at a Client location. Severity classification is initially made by Client at the time of ticket submission and may be reclassified by Technijian upon review of the ticket details, subject to Client<<APOS>>s escalation rights under subsection (f)."),'
    ),
))

# Pricing Adjustments — replace "Renewal Term" reference (no renewal exists anymore)
sched_edits.append((
    "Pricing Adjustments — Renewal Term cleanup",
    'bodyText("Pricing for services under this Schedule is subject to the Rate Card (Schedule C). Technijian may adjust rates upon sixty (60) days written notice, effective at the start of the next Renewal Term of the Agreement."),',
    'bodyText("Pricing for services under this Schedule is subject to the Rate Card (Schedule C). Technijian may adjust rates upon sixty (60) days written notice, effective at the start of any month-to-month continuation period under MSA Section 2.02, or upon mutual written agreement during the Initial Term."),',
))

for label, old, new in sched_edits:
    if old in sched:
        if sched.count(old) > 1:
            print(f"FAIL {label}: old occurs {sched.count(old)} times")
            sys.exit(1)
        sched = sched.replace(old, new, 1)
        print(f"OK {label}")
    elif new in sched:
        print(f"SKIP {label}: already applied")
    else:
        print(f"FAIL {label}: neither old nor new found")
        sys.exit(1)

with open(sched_path, "w", encoding="utf-8", newline="") as f:
    f.write(sched)

# Final post-checks
final_msa = [
    "Tickets deferred by Technijian under Schedule A, Section 3.6",
    "shall be excluded from the calculation in clause (i)",
]
for c in final_msa:
    assert c in msa, f"MSA pass2 check failed: {c}"

final_sched = [
    "deferral notice issued under Section 3.6 shall constitute a Response",
    "written deferral notice issued by Technijian",
    "Escalation. If Client in good faith believes",
    "Emergency Definition",
    "month-to-month continuation period under MSA Section 2.02",
]
for c in final_sched:
    assert c in sched, f"Schedule A pass2 check failed: {c}"

print("\nAll pass-2 post-checks passed.")
