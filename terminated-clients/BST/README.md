# BST — Boston Group Waste — Termination File

**Client contact:** Jeff Klein — jklein@bostongroupwaste.com
**Termination effective:** 2026-04-30 (end of month, per user)
**New provider:** Tech Heights (Rich Leggett — rleggett@techheights.com)
**Outside counsel referenced in thread:** Ed Susolik / Callahan (es@callahan-law.com)

## Folder contents

- `_pull_jeff_emails.ps1` — script that pulled this folder's emails via Graph app-only auth
- `emails_index.csv` — manifest of all 109 messages (sort by `ReceivedOrSent`)
- `emails/` — 109 message bodies as `.html` (or `.txt`) with metadata header
- `attachments/` — 22 file attachments (invoices, signed MSA, actual-vs-billable spreadsheet, scans)

## Key thread: "Service Cancellation"

The core termination discussion runs under the subject **"Service Cancellation"** across 30+ reply messages between 2026-03-17 and 2026-04-10. Participants:

- Jeff Klein (BST)
- Ravi Jain (Technijian)
- Rich Leggett (Tech Heights — incoming provider)
- Raja Mohamed (Technijian)
- Ed Susolik (Callahan Law)

## Key attachments already downloaded

- `Boston_Group-Monthly_Service-signed.pdf` — signed MSA (two copies, 03-19 and 03-24)
- `bst_actualvsbillable.csv` — hours spreadsheet (matches CDC-style reconciliation pattern)
- Invoices: `Boston+Group-27890`, `27949`, `28064` (Service Cancellation), `28112`, `28143`
- `BP-70C36_20260317_112415.pdf` — 3 copies (scanned document, likely signed notice)

## Next steps (suggested)

1. Read the earliest `2026-03-17_1826_Service Cancellation.html` to see what Jeff originally sent
2. Read `bst_actualvsbillable.csv` and `Boston_Group-Monthly_Service-signed.pdf` for the reconciliation methodology (same pattern as CDC)
3. Apply the same cancellation-fee logic the user worked through with ChatGPT for CDC (overage hours × $150/hr, March at no cost, etc.)

## How to re-run this pull

```powershell
cd c:\vscode\tech-legal\tech-legal\terminated-clients\BST
powershell -ExecutionPolicy Bypass -File .\_pull_jeff_emails.ps1
```

Credentials read from `C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md`.
