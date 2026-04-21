---
name: templates
description: "Skill for the Templates area of tech-legal. 50 symbols across 2 files."
---

# Templates

50 symbols | 2 files | Cohesion: 94%

## When to Use

- Working with code in `templates/`
- Understanding how p, multiRun, heading1 work
- Modifying templates-related functionality

## Key Files

| File | Symbols |
|------|---------|
| `templates/generate-invoices.js` | p, multiRun, spacer, makeTable, msaRefBar (+22) |
| `templates/generate-docx.js` | p, multiRun, heading1, heading2, heading3 (+18) |

## Key Symbols

| Symbol | Type | File | Line |
|--------|------|------|------|
| `p` | Function | `templates/generate-docx.js` | 75 |
| `multiRun` | Function | `templates/generate-docx.js` | 88 |
| `heading1` | Function | `templates/generate-docx.js` | 101 |
| `heading2` | Function | `templates/generate-docx.js` | 102 |
| `heading3` | Function | `templates/generate-docx.js` | 103 |
| `spacer` | Function | `templates/generate-docx.js` | 104 |
| `brandRule` | Function | `templates/generate-docx.js` | 106 |
| `orangeAccentRule` | Function | `templates/generate-docx.js` | 115 |
| `coverPage` | Function | `templates/generate-docx.js` | 124 |
| `signatureBlock` | Function | `templates/generate-docx.js` | 173 |
| `brandTableCell` | Function | `templates/generate-docx.js` | 206 |
| `makeTable` | Function | `templates/generate-docx.js` | 231 |
| `makeHeader` | Function | `templates/generate-docx.js` | 252 |
| `makeFooter` | Function | `templates/generate-docx.js` | 280 |
| `coverSectionProps` | Function | `templates/generate-docx.js` | 308 |
| `contentSectionProps` | Function | `templates/generate-docx.js` | 317 |
| `generateNDA` | Function | `templates/generate-docx.js` | 330 |
| `generateMSA` | Function | `templates/generate-docx.js` | 437 |
| `generateScheduleA` | Function | `templates/generate-docx.js` | 634 |
| `generateScheduleB` | Function | `templates/generate-docx.js` | 800 |

## Execution Flows

| Flow | Type | Steps |
|------|------|-------|
| `GenerateMonthlyServiceInvoice → P` | intra_community | 3 |
| `GenerateRecurringSubscriptionInvoice → P` | intra_community | 3 |
| `GenerateWeeklyOutOfContractInvoice → P` | intra_community | 3 |
| `GenerateEquipmentInvoice → P` | intra_community | 3 |
| `GenerateWeeklyInContractInvoice → P` | intra_community | 3 |

## How to Explore

1. `gitnexus_context({name: "p"})` — see callers and callees
2. `gitnexus_query({query: "templates"})` — find related execution flows
3. Read key files listed above for implementation details
