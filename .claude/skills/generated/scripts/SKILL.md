---
name: scripts
description: "Skill for the Scripts area of tech-legal. 31 symbols across 7 files."
---

# Scripts

31 symbols | 7 files | Cohesion: 75%

## When to Use

- Working with code in `terminated-clients/`
- Understanding how setup_document, add_heading, add_horizontal_rule work
- Modifying scripts-related functionality

## Key Files

| File | Symbols |
|------|---------|
| `terminated-clients/VTD/scripts/_generate_docx.py` | setup_document, add_heading, add_horizontal_rule, build_case_law_memo, add_letterhead (+7) |
| `terminated-clients/BST/scripts/_generate_docx.py` | add_inline, parse_table_rows, render_table, convert |
| `scripts/brand-helpers.js` | colorBanner, ctaBanner, orangeDivider, coverPage |
| `scripts/create-client-folders.py` | main, user_info, find_active_users |
| `scripts/add-contract-details.py` | fmt_date, fmt_currency, main |
| `scripts/add-contract-details-v2.py` | fmt_date, fmt_currency, main |
| `scripts/send-foxit-affg-002.js` | httpsRequest, main |

## Entry Points

Start here when exploring this area:

- **`setup_document`** (Function) — `terminated-clients/VTD/scripts/_generate_docx.py:19`
- **`add_heading`** (Function) — `terminated-clients/VTD/scripts/_generate_docx.py:75`
- **`add_horizontal_rule`** (Function) — `terminated-clients/VTD/scripts/_generate_docx.py:112`
- **`build_case_law_memo`** (Function) — `terminated-clients/VTD/scripts/_generate_docx.py:711`
- **`add_letterhead`** (Function) — `terminated-clients/VTD/scripts/_generate_docx.py:35`

## Key Symbols

| Symbol | Type | File | Line |
|--------|------|------|------|
| `setup_document` | Function | `terminated-clients/VTD/scripts/_generate_docx.py` | 19 |
| `add_heading` | Function | `terminated-clients/VTD/scripts/_generate_docx.py` | 75 |
| `add_horizontal_rule` | Function | `terminated-clients/VTD/scripts/_generate_docx.py` | 112 |
| `build_case_law_memo` | Function | `terminated-clients/VTD/scripts/_generate_docx.py` | 711 |
| `add_letterhead` | Function | `terminated-clients/VTD/scripts/_generate_docx.py` | 35 |
| `add_paragraph` | Function | `terminated-clients/VTD/scripts/_generate_docx.py` | 94 |
| `add_table` | Function | `terminated-clients/VTD/scripts/_generate_docx.py` | 124 |
| `build_scenario_analysis` | Function | `terminated-clients/VTD/scripts/_generate_docx.py` | 494 |
| `add_footer` | Function | `terminated-clients/VTD/scripts/_generate_docx.py` | 64 |
| `add_field_line` | Function | `terminated-clients/VTD/scripts/_generate_docx.py` | 104 |
| `add_privileged_callout` | Function | `terminated-clients/VTD/scripts/_generate_docx.py` | 148 |
| `build_settlement_memo` | Function | `terminated-clients/VTD/scripts/_generate_docx.py` | 164 |
| `add_inline` | Function | `terminated-clients/BST/scripts/_generate_docx.py` | 21 |
| `parse_table_rows` | Function | `terminated-clients/BST/scripts/_generate_docx.py` | 42 |
| `render_table` | Function | `terminated-clients/BST/scripts/_generate_docx.py` | 55 |
| `convert` | Function | `terminated-clients/BST/scripts/_generate_docx.py` | 73 |
| `main` | Function | `scripts/create-client-folders.py` | 14 |
| `user_info` | Function | `scripts/create-client-folders.py` | 33 |
| `find_active_users` | Function | `scripts/create-client-folders.py` | 47 |
| `fmt_date` | Function | `scripts/add-contract-details.py` | 12 |

## How to Explore

1. `gitnexus_context({name: "setup_document"})` — see callers and callees
2. `gitnexus_query({query: "scripts"})` — find related execution flows
3. Read key files listed above for implementation details
