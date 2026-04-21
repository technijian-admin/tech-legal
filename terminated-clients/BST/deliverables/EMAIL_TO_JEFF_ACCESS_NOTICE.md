# Operational/Evidentiary Email to Jeff Klein — Support Access Unavailable
**Subject:** VPN Support Request — Continued Access Limitations Following Tech Heights Transition
**To:** Jeff Klein <jklein@bostongroupwaste.com>; Gagan Singh <gagan@bostongroupwaste.com>
**Cc:** Technijian Support <support@technijian.com>; Raja Mohamed <RMohamed@Technijian.com>
**From:** Ravi Jain
**Target send:** Today (send promptly — ticket #325 still open)

---

Hello Jeff and Gagan,

Thank you for opening ticket #325 regarding the VPN issue. I want to provide clear written confirmation of why Technijian is currently unable to assist with this and similar requests, so that everyone is aligned as we move toward the April 30, 2026 termination date.

**Access issues documented:**

Since on or about March 31 – April 1, 2026, Technijian's administrative access to the Boston Group environment has been progressively impaired by actions taken by Tech Heights. Specifically, our engineers have observed:

1. **ESXi host password changed** without authorization from Technijian (originally reported to you April 1, 2026).
2. **Active Directory rebuilt on a different server.** The original BST-HQ-AD-01 went offline, and a new AD infrastructure was stood up by Tech Heights on separate hardware.
3. **Default gateway changed** from 10.1.1.254 to 10.1.1.1, with the previous firewall replaced. Technijian has no credentials on the current gateway.
4. **Technijian monitoring and management agents** have been removed from BST endpoints and servers.

Without credentials to the current firewall, the current domain controllers, or the current hypervisor, Technijian cannot diagnose or remediate VPN, access, or connectivity issues on the BST environment.

**Per your April 1, 2026 email** ("your company has refused to cooperate so we are proceeding without your support"), Technijian understood Boston Group had directed that the transition proceed with Tech Heights as the active technical provider through the termination date. The subsequent credential changes are consistent with that direction.

**Our position through April 30, 2026:**

- **We remain contractually willing to provide support through the termination date** per Section 4.05 of the signed agreement, and would gladly assist with ticket #325 if we could.
- **We cannot do so without administrative access.** If Boston Group directs Tech Heights to restore Technijian's credentials (ESXi host, domain controllers, firewall/gateway, and reinstatement of our monitoring/management agents), we will resume normal support response immediately.
- **Otherwise, please direct all active support requests to Tech Heights,** since they currently hold the operational credentials. Our advice to Gagan was to contact Tech Heights for this reason; this email confirms that direction in writing.

**Reservation of rights:**

Nothing in this email waives or limits any claim Technijian may have arising from the unauthorized credential changes, agent removals, or related conduct by Tech Heights or any third party. All rights are expressly reserved.

The April 30, 2026 termination items outlined in my March 23 email — including the $15,045.00 settlement offer, invoice #28064 ($126,442.50 contract-basis cancellation fee), and April 2026 monthly invoice #27949 — remain as stated.

Please let me know if Boston Group intends to restore our access for the remaining notice period, or if ongoing support should be routed to Tech Heights.

Thank you,

Ravi Jain
CEO, Technijian, Inc.
T: 949.379.8499 x201 | C: 714.402.3164
rjain@technijian.com

---

### Internal notes (not for inclusion in email)

**Why send now, not at 4/21 with the expiration follow-up:**
- Ticket #325 is live — delay on this specific technical issue weakens the "willing to help if access restored" posture.
- Each day without a written record of the access obstruction makes the CFAA/CDAFA preservation weaker.
- Keeping this email separate from the expiration follow-up keeps the two narratives distinct: (1) "we can't provide support because Tech Heights locked us out" vs (2) "the settlement offer is about to expire."

**What this email accomplishes:**

| Purpose | How |
|---|---|
| Preserves CFAA/CDAFA evidence against Tech Heights | Enumerates four specific unauthorized changes with dates |
| Refutes § 4.05 abandonment argument | States we remain willing; blocked by BST/Tech Heights actions |
| Documents BST's own directive | Quotes Jeff's 4/1 email verbatim |
| Creates concurrent written record | Dated close to the actual technical events |
| Keeps door open for support | "We will resume immediately if access restored" |
| Reservation of rights, no threats | Neutral tone; preserves all theories |

**What this email does NOT do:**
- Does not threaten legal action against BST
- Does not name Leggett personally
- Does not repeat damages numbers in detail (references the 3/23 email by incorporation)
- Does not offer a new concession
- Does not soften the 4/30 deadline
