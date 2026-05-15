---
name: send-esign
description: Use when the user wants ANY document sent for electronic signature (SOW, MSA, NDA, schedule, retrenchment letter, mutual separation agreement, proposal, change order, contract, amendment - anything signable). Routes ALL Technijian eSign sends through the single universal harness `scripts/foxit-send.py` driven by an envelope JSON config under `scripts/foxit-envelopes/`. Never creates per-document send scripts. Triggers on phrases like "send X for signature", "esign this", "send via Foxit", "get this signed", "send the SOW", "send the MSA", "send for signing", "Foxit", "DocuSign" (DocuSign is sunset 2026-04-30 - silently substitutes Foxit per `[[esign_provider_timeline]]`).
---

# Technijian Universal eSign Send Skill

Single entry point for ALL eSign sends. No per-document scripts. No hand-rolled email templates. No coordinate-based fields on Word PDFs.

## Critical context (read before doing anything)

The user has voided at least 3 envelopes (Rajat MSA 33689124, BBC SOW 33787642, PCAP SOW 33812-ish) because per-document send scripts kept getting created instead of using a universal pipeline. As of 2026-05-15, **there is exactly one Technijian Foxit sender**: `scripts/foxit-send.py`. All envelope-specific configuration lives in JSON files at `scripts/foxit-envelopes/<envelope-id>.json`.

The user's directive (2026-05-15): *"there should be just one script to send documents for signature not individual per document because you keep making the same mistake and we have to voids multiple documents which looks bad"*.

## When to invoke this skill

User said any of:
- "Send X for signature"
- "Esign this"
- "Send the SOW / MSA / NDA / proposal"
- "Get this signed"
- "Send via Foxit" or "Send via DocuSign" (silently substitute Foxit; DocuSign ended 2026-04-30)
- "Send the retrenchment letter / mutual separation agreement"
- Any variant of "I want this document signed"

## What this skill does

Delegate to the `esign-sender` subagent (`tech-legal/.claude/agents/esign-sender.md`). The subagent:

1. Locates or asks for the DOCX path
2. Reuses or drafts an envelope JSON config at `scripts/foxit-envelopes/<id>.json`
3. Runs `scripts/foxit-send.py --inspect <pdf>` to verify the PDF contains Foxit text tags (sigfield count must be >= 1)
4. Runs `scripts/foxit-send.py --config <env.json> --dry-run` to preview
5. Runs `scripts/foxit-send.py --config <env.json> --test --test-email rjain557@gmail.com` to dispatch a single test envelope
6. Pauses for the user to visually verify the test envelope in the Foxit signing UI ("Required Fields Left" >= 1)
7. Asks the user to confirm before the real send
8. Runs `scripts/foxit-send.py --config <env.json> --send`
9. Reports the folder id and the next-step `scripts/foxit-completion-email.py <id>` command

The universal harness handles:
- Loading creds from the OneDrive key vault
- DOCX -> PDF via Word COM (with content-types patch)
- Foxit createfolder with `processTextTags: True` + `sendNow: False`
- Per-party signing URL validation (Trap #12: malformed eetid URLs, poll up to 5 times)
- Sending the canonical Technijian-branded HTML invitation per party via Graph
- Including Ravi's signature block ONLY on emails to non-tech recipients

## Hard rules

1. **Never create a new `send-<client>-<doc>.py` or `.ps1`**. The pipeline is the harness; everything per-document is config.
2. **Never hand-roll the branded email HTML.** Use the canonical `build_signing_email()` in `scripts/foxit-send.py`. If extra narrative is needed, set `intro` per party in the envelope config.
3. **Multi-party MUST be sequential** (`signing_mode: "sequential"` in the envelope JSON; harness sets `signInSequence: true`). Parallel multi-party breaks the first party's post-sign redirect — verified across 3 broken client envelopes 2026-05-15 (33788227, 33788491, 33788499). Sequential is verified working on 33788882. See [[feedback_foxit_multiparty_unresolved]] (resolved).
4. **`signSuccessUrl` is mandatory** on every Foxit envelope. The harness defaults to `https://technijian.com`. Omitting it sends the signer to a broken Foxit error page immediately after they sign. See [[feedback_foxit_sign_success_url_mandatory]].
5. **`createEmbeddedSigningSession: True` is mandatory** for branded-email flows. Setting it False leaves the folder in DRAFT and requires `/folders/sendDraftFolder` — which triggers Foxit's own un-branded email (no API suppression). The proven harness keeps it True; do not change.
6. **`--inspect` then `--test` are non-negotiable.** Skipping either is what voided envelopes 33689124, 33787642, and the PCAP ones. Multi-party tests REQUIRE a 2-party test envelope (e.g. `rjain557@hotmail.com` seq 1 + `rjain557@gmail.com` seq 2) — single-party tests do NOT prove multi-party works.
7. **Confirm before every `--send`.** Even mid-session approvals don't carry forward; each send is a separate authorization (`[[feedback_confirm_before_external_send]]`).
8. **DOCX text tags must be in WHITE text in the signature block.** Use the proven npm-docx pattern from `restructuring-2026/generate-letters-docx.js`. Coordinate-based field placement on Word multi-page PDFs is broken — `[[feedback_foxit_text_tag_traps]]` Trap #3.
9. **Download returns a ZIP**, not a raw PDF. `foxit-completion-email.py` consumers must unpack `<folderName>.pdf` from the ZIP for the signed-document attachment.

10. **DOCX tag party convention: Tech=1, Client=2.** The signature-block text tags in the DOCX generator MUST use `${signfield:1:...}` for the Technijian/Ravi block and `${signfield:2:...}` for the Client block. Same for `datefield` and `textfield`. Inverting these makes Ravi sign the CLIENT box (incident: PCAP 33789128 voided 2026-05-15). Fix the DOCX generator, not the envelope config — the convention is fixed.

11. **PROOFREAD 3X before --send.** (1) PDF tag party-numbers match the Tech=1/Client=2 convention; (2) envelope config sequences/emails align with the tag party numbers; (3) signature-page text content looks right (no placeholders, correct entity names, Technijian-above-client). Surface each pass in your pre-send summary so the user can audit before authorizing.

## Failure modes the user has hit (read before sending)

| Date | Folder | Failure | Fix |
|------|--------|---------|-----|
| 2026-05-11 | various | Text tags didn't parse (coordinate fields on multi-page PDF) | Use white text tags in DOCX |
| 2026-05-12 | 33689124 | Wrong shift-allowance amount in Rajat MSA | Resend with corrected DOCX |
| 2026-05-15 | 33787642 | BBC SOW - field verification skipped, assumed broken | Always `--inspect` + `--test` before `--send` |
| 2026-05-15 | PCAP folder | Logo updated, send re-run without asking | Confirm before EVERY send |

## Memory pointers

- `[[feedback_universal_esign_send_script]]` - the one-script rule
- `[[feedback_foxit_text_tag_traps]]` - 13 documented silent-failure modes
- `[[feedback_esign_branded_email_template]]` - canonical email template lives in send-docusign.ps1, ported to foxit-send.py
- `[[feedback_confirm_before_external_send]]` - ask before every real send
- `[[feedback_preview_emails_before_send]]` - render + visual verify before send
- `[[foxit_esign_workflow]]` - full Foxit pipeline notes (createfolder + completion polling)
- `[[workstation_integrations]]` - Foxit endpoint map + account notification settings (all No)
- `[[esign_provider_timeline]]` - DocuSign ended 2026-04-30; Foxit-only from then

## Quick reference

| Action | Command |
|--------|---------|
| Inspect tags in PDF | `python scripts/foxit-send.py --inspect <pdf>` |
| Dry-run envelope    | `python scripts/foxit-send.py --config scripts/foxit-envelopes/<id>.json --dry-run` |
| Test send to gmail  | `python scripts/foxit-send.py --config <env.json> --test --test-email rjain557@gmail.com` |
| Real send to parties| `python scripts/foxit-send.py --config <env.json> --send` |
| Cancel folder       | `python scripts/foxit-cancel.py <folder_id> --reason "<why>"` |
| Completion email    | `python scripts/foxit-completion-email.py <folder_id>` |
