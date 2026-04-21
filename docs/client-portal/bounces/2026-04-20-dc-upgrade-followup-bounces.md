# Bounced Broadcast Contacts — 2026-04-20 DC Upgrade Follow-Up

**Source:** RJain@technijian.com NDRs received 2026-04-21 00:09 UTC (immediately after `send-dc-upgrade-followup.ps1` broadcast).

**Action taken 2026-04-21:**
- Canonical [bounce-register.md](../bounce-register.md) created (this per-event log is now superseded by the register for ongoing truth).
- B2I resolved: `brenna@b2insurance.com` → `keith@b2insurance.com` in both `send-*.ps1` scripts and in [B2I CONTACTS.md](../../../clients/B2I/CONTACTS.md).
- EAG, KEI, NAC, TCH have no alternate contact on file — pending user action to obtain replacements.

**Historical context — why four of these re-bounced:** The same four addresses (B2I, KEI, NAC, TCH) were identified as bouncing on the 2026-04-16 `send-dc-upgrade-notice.ps1` sweep. That sweep recorded findings only in a conversation log; they were never propagated to the BCC arrays in `send-*.ps1` or to per-client `CONTACTS.md`. Four days later the follow-up broadcast re-sent to all four and they re-bounced. The durable fix (2026-04-21) is the bounce register plus the feedback rule `feedback_post_send_ndr_sweep.md` that mandates in-engagement propagation to register + scripts + CONTACTS.md after every send.

**Pending:** EAG / KEI / NAC / TCH still need replacement contacts. Per global CLAUDE.md rule, **bounced email ≠ inactive client** — do not close these clients; just replace the contact.

## Bounced Addresses

| Client Code | Client Name | Bounced Address | NDR Reason | Severity | Next Action |
|---|---|---|---|---|---|
| B2I | B2 Insurance | brenna@b2insurance.com | 5.1.1 recipient not found in Office 365 | Permanent (mailbox removed) | Get current contact at B2 Insurance |
| EAG | Ellis Advisory | nellis@cfiemail.com | 550 5.x mailbox unavailable at postin02.mbox.net | Permanent | Get current Ellis Advisory contact |
| KEI | Kruger and Eckels | anthony@krugerandeckels.com | 550 5.x mailbox unavailable | Permanent | Get current KEI contact |
| NAC | National Auto Coverage | sammy@natautocoverage.com | 550 5.4.310 DNS domain `natautocoverage.com` does not exist | Permanent (domain dead) | Verify NAC is still operational; get new contact + possibly new domain |
| TCH | Torch Enterprises | DANIEL@TORCHENTERPRISE.COM | 5.1.1 recipient not found in Office 365 | Permanent (mailbox removed) | Get current Torch Enterprises contact |

## Notes

- **NAC's domain does not exist** — worth a separate sanity check to confirm National Auto Coverage is still an operating business before re-engaging.
- Per-client CONTACTS.md files at [tech-legal/clients/B2I/CONTACTS.md](../../../clients/B2I/CONTACTS.md), [EAG](../../../clients/EAG/CONTACTS.md), [KEI](../../../clients/KEI/CONTACTS.md), [NAC](../../../clients/NAC/CONTACTS.md), and [TCH](../../../clients/TCH/CONTACTS.md) should be updated once replacement contacts are obtained.
- Successful delivery: 62 recipients (67 original BCC list minus 5 bounces).
