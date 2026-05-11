---
name: foxit-esign
description: Use when sending PDFs for signature via Foxit eSign API. Covers text tag syntax, field placement, branded email pattern, common silent-failure traps, and the proven end-to-end pipeline (DOCX → PDF → Foxit → branded email → signed PDF return). Examples: "Send this letter for esign", "Create a Foxit envelope", "Why are my Foxit fields not showing up", "Set up signature fields in this document".
---

# Foxit eSign — Field Placement, Text Tags, Common Pitfalls

## When to use

Trigger this skill the moment a task involves:

- Sending any PDF document for signature via Foxit eSign
- Adding signature, date, text, or initial fields to a PDF
- Debugging why Foxit fields aren't appearing in the signing UI
- Building a `createfolder` API call
- Sending Technijian-branded signing-invitation or completion emails

## The 11 mistakes I made before getting this right (May 11, 2026) — DO NOT REPEAT

These cost an entire afternoon. Each one was a silent failure where Foxit accepted the request but dropped the fields. Always verify "Required Fields Left" counter in the Foxit UI shows >0 before sending to real signers.

### Coordinate-based fields (the wrong path)

1. **Coordinate-based fields silently fail on Word-generated multi-page PDFs.** Even with correct `x, y, width, height, pageNumber`, Foxit's text-tag parser drops fields placed at certain y values (especially y < ~250 from top on multi-page Word PDFs). Verified empirically: isolation test with y=400 worked, y=200 failed on the same PDF.
2. **Numeric `:width:height` is silently ignored for signfield.** The signature field rendered as a giant ~300pt-tall canvas regardless of `height: 18` or `height: 30`. Numeric dimensions are documented for `textfield` and `datefield` only.
3. **Type names matter.** It's `signfield` and `datefield` — NOT `signature` or `date`. The latter are silently dropped.
4. **Y is from TOP of the page** (per the developer guide). I burned hours assuming y-from-bottom because the reference PDF "worked" by coincidence.
5. **Y is the TOP-LEFT corner of the field**, not the bottom-left. Field extends DOWN from `y` by `height`.
6. **API account email = signer email gives author-view URL, no fields visible.** Testing with `rjain@technijian.com` (the API token owner) shows the document but no interactive boxes. Use a different email — an alias (`rjain+test@`) or external (gmail) — so Foxit issues a true signer-view URL.

### Field sizing

7. **Sig field `height < ~30` renders invisibly** in the Foxit signing UI. The signer can't see anything to fill and just clicks "Approve" → document executes empty.
8. **Overlapping fields get silently dropped.** Two fields whose y-rectangles overlap (even at different x positions) → Foxit drops one or both. Keep each field on its own visual row.
9. **Foxit signature field has a minimum canvas size.** Even when the height parameter is accepted, signature fields are forced to a minimum ~30pt to fit the signature image. Plan vertical layout around this.

### Workflow

10. **`sendNow: true` triggers Foxit's branded email.** Always use `sendNow: false` and send the invitation yourself via Graph from `rjain@technijian.com` for Technijian branding. Foxit account-level notifications must also be disabled (see `workstation_integrations.md` vault topic).
11. **Foxit's signing UI is NOT customizable on the standard tier.** Account-level branding (logo, colors in the signing portal) is enterprise-only. We brand the invitation email and the completion email; the signing portal itself is generic Foxit.

## The right path — text tags in white text

After all the coordinate-based failures, the user pointed me to the correct approach: **embed Foxit text tags in white text directly in the DOCX**. Foxit's `processTextTags: true` flag scans the rendered PDF for these tags and converts them to fields at the exact rendered positions. **No coordinate math required.**

### Authoritative text tag syntax

From the official Foxit eSign Sample PDF (`https://developersguide.foxitesign.foxit.com/uploads/FoxiteSignAPISampleDoc.pdf`):

```
${fieldType:partyNumber:required:fieldName:widthOrUnderscores:height}
```

| Field | Tag format | Notes |
|---|---|---|
| Signature | `${signfield:1:y:Emp_Sig:____________________}` | Width via underscore count INSIDE braces. Numeric `:w:h` silently ignored. |
| Date (auto-fill on signing) | `${datefield:1:y:Date_Signed:80:18}` | Auto-populates with current date when signer opens doc. Numeric `:w:h` honored. |
| Text field | `${textfield:1:y:Field_Name:90:20}` | Numeric `:w:h` honored. |
| Initial | `${initialfield:1:y:Init:______}` | Underscore-width only. |
| Checkbox | `${checkboxfield:1:y:::}` | Empty trailing slots OK. |

**Short notations:** `${s:1:______}` = signfield. `${i:1:______}` = initialfield. `${t:1:n::______}` = textfield. `${c:1:y:::}` = checkboxfield.

### Two underscore conventions (don't confuse them)

- **Underscores in `fieldName`** (`Name_of_Signer`): get converted to **spaces** in the rendered field label.
- **Underscores in the trailing slot** (after the last `:` before `}`): set the **field WIDTH** at the tag's rendered text width.

### Controlling field HEIGHT

For `signfield`, height is determined by the **font size of the text tag itself** in the source DOCX, NOT by any numeric parameter. Set the tag's font size to ~10pt (DOCX `size: 20` half-points) to get a properly-sized signature field on the underscore line. Larger font = taller field. The signature canvas has a minimum height (~30pt) below which Foxit forces a larger area.

For `datefield` and `textfield`, the numeric `:width:height` IS honored.

## The proven DOCX template snippet (working as of 2026-05-11)

```javascript
// In your DOCX generator (npm 'docx' library):
const WHITE = 'FFFFFF';

// One field per line with breathing room. Print Name + Employee No
// pre-filled directly in document text (no Foxit fields needed).
body.push(P([
  T('Employee Signature:  '),
  T('${signfield:1:y:Emp_Sig:____________________}', { color: WHITE, size: 20 }),
], { before: 200, after: 220 }));

body.push(P([
  T('Date:  '),
  T('${datefield:1:y:Date_Signed:80:18}', { color: WHITE, size: 20 }),
], { after: 220 }));

body.push(P([
  T('Print Name:  ', { color: BRAND_GREY }),
  T(emp.name, { color: DARK_CHARCOAL, bold: true }),
], { after: 160 }));

body.push(P([
  T('Employee No.:  ', { color: BRAND_GREY }),
  T(emp.empNo, { color: DARK_CHARCOAL, bold: true }),
], { after: 120 }));
```

**Critical:** The text tag must be on the SAME paragraph line as the visible label (after a space or two), not on its own paragraph. Foxit places the field at the tag's exact rendered position; if the tag is alone on a line, the field will be at the leftmost margin, not next to the label.

## The createfolder payload (with text tag processing)

```python
payload = {
    "folderName": "Technijian — Letter Subject",
    "inputType": "base64",
    "base64FileString": [b64_pdf],
    "fileNames": ["letter.pdf"],
    "sendNow": False,                              # MUST be False — we send via Graph
    "createEmbeddedSigningSession": True,
    "createEmbeddedSigningSessionForAllParties": True,
    "signInSequence": False,
    "processTextTags": True,                       # CRITICAL — scans PDF for ${...} tags
    "parties": [{
        "firstName": "Recipient",
        "lastName":  "Name",
        "emailId":   "recipient@external.com",     # NOT the API account email
        "permission": "FILL_FIELDS_AND_SIGN",
        "sequence": 1, "workflowSequence": 1,
    }],
    # No 'fields' array needed when using text tags. If you mix, declare here.
}
r = requests.post(
    "https://na1.foxitesign.foxit.com/api/folders/createfolder",
    headers={"Authorization": f"Bearer {tok}", "Content-Type": "application/json"},
    json=payload,
)
```

## Test before sending to real signers

1. **Use an external email or `+alias`** for the test, NOT the API account email. The account email gives the author-view URL with no interactive fields. An alias like `rjain+test@technijian.com` or an external gmail creates a separate Foxit party with the signer-view URL.
2. **Open the signing URL and check "Required Fields Left" counter** at the top of the Foxit UI. Must show >0 before sending real envelopes. Counter=0 means Foxit dropped all your fields silently.
3. **Click the signature field** — confirm a draw-signature canvas opens. If clicking does nothing, the field is decorative and won't capture the signature.
4. **Confirm date field auto-populates** when the document opens (datefield does this natively).
5. **Pre-flight verify branded email** — the signing-invitation email must come from the Graph-sent Technijian-branded HTML, NOT a Foxit-platform email. If you see a Foxit-branded email arrive at the signer's inbox, the account-level "Send PDF with Completion Notification" setting is on — disable it at na1.foxitesign.foxit.com → My Account → Notifications.

## Reference scripts in this repo

- `technijian/Employees/India/HR/restructuring-2026/send-restructuring-foxit.py` — full production pipeline with text tags, branded Graph email, multi-document envelopes
- `technijian/Employees/India/HR/restructuring-2026/generate-letters-docx.js` — DOCX generator with embedded white text tags
- `scripts/_foxit_test_final.py` — minimal one-page test reference
- `scripts/foxit-completion-email.py` — polls for EXECUTED and sends branded completion email

## End-to-end pipeline

```
1. DOCX generator (npm 'docx') with white text tags embedded
2. Python win32com → Word COM → PDF
3. PyMuPDF stamp Ravi's pre-signed signature (if applicable)
4. Python script reads PDF, base64-encodes, POSTs to /folders/createfolder
   with processTextTags: true, sendNow: false
5. Extract folderAccessURL from response (per-party URL)
6. Send branded Technijian HTML invitation via Microsoft Graph
   (From: rjain@technijian.com, To: signer's external email)
7. Signer opens email, clicks "Review & Sign", signs in Foxit UI
8. Poll /folders/myfolder until folderStatus == "EXECUTED"
9. Download signed PDF via /folders/download?folderId=...
10. Send branded Technijian completion email via Graph with signed PDF attached
```

## See also

- Vault: [[foxit_esign_workflow]] — full workflow detail (gets updated whenever the pipeline changes)
- Vault: [[workstation_integrations]] — Foxit credentials, endpoint map, notification settings
- Vault: [[esign_provider_timeline]] — provider history (DocuSign → Foxit transition)
- Vault: [[feedback_foxit_text_tag_traps]] — every silent-failure mode I hit; consult before debugging next time
