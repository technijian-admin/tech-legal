---
name: generators
description: "Skill for the _generators area of tech-legal. 424 symbols across 26 files."
---

# _generators

424 symbols | 26 files | Cohesion: 95%

## When to Use

- Working with code in `clients/`
- Understanding how set_cell_shading, remove_borders, set_grey_borders work
- Modifying _generators-related functionality

## Key Files

| File | Symbols |
|------|---------|
| `clients/BWH/_generators/generate-msa.py` | set_cell_shading, set_grey_borders, BrandedDoc, run, section_header (+23) |
| `clients/AFFG/_generators/generate-all.py` | set_cell_shading, remove_borders, set_grey_borders, BrandedDoc, run (+21) |
| `clients/OKL/_generators/generate-dell-quotes.py` | shade, fix_table_layout, keep_rows_together, light_borders, no_borders (+19) |
| `clients/AAVA/_generators/generate-msa.py` | set_cell_shading, remove_borders, set_grey_borders, BrandedDoc, run (+19) |
| `clients/AFFG/_generators/generate-sow-managed-device.js` | p, multiRun, heading1, heading2, heading3 (+17) |
| `clients/OKL/_generators/generate-all.py` | set_cell_shading, remove_borders, set_grey_borders, BrandedDoc, run (+16) |
| `clients/AMP/_generators/generate-all.py` | set_cell_shading, remove_borders, set_grey_borders, BrandedDoc, run (+16) |
| `clients/AFFG/_generators/generate-sow-managed-device.vdi-draft.js` | multiRun, brandRule, bulletMulti, brandTableCell, makeTable (+16) |
| `clients/OKL/_generators/generate-docs.js` | p, multiRun, heading1, heading2, spacer (+15) |
| `clients/CPM/_generators/generate-msa.py` | BrandedDoc, run, section_header, body, body_bold (+15) |

## Entry Points

Start here when exploring this area:

- **`set_cell_shading`** (Function) — `clients/AFFG/_generators/generate-all.py:70`
- **`remove_borders`** (Function) — `clients/AFFG/_generators/generate-all.py:75`
- **`set_grey_borders`** (Function) — `clients/AFFG/_generators/generate-all.py:90`
- **`run`** (Function) — `clients/AFFG/_generators/generate-all.py:123`
- **`accent_bar`** (Function) — `clients/AFFG/_generators/generate-all.py:133`

## Key Symbols

| Symbol | Type | File | Line |
|--------|------|------|------|
| `BrandedDoc` | Class | `clients/AFFG/_generators/generate-all.py` | 108 |
| `BrandedDoc` | Class | `clients/BWH/_generators/generate-msa.py` | 67 |
| `BrandedDoc` | Class | `clients/AAVA/_generators/generate-msa.py` | 70 |
| `BrandedDoc` | Class | `clients/OKL/_generators/generate-all.py` | 63 |
| `BrandedDoc` | Class | `clients/AMP/_generators/generate-all.py` | 63 |
| `BrandedDoc` | Class | `clients/OKL/_generators/generate-schedules.py` | 64 |
| `BrandedDoc` | Class | `clients/CPM/_generators/generate-msa.py` | 51 |
| `BrandedDoc` | Class | `clients/CCC/_generators/generate-msa.py` | 52 |
| `set_cell_shading` | Function | `clients/AFFG/_generators/generate-all.py` | 70 |
| `remove_borders` | Function | `clients/AFFG/_generators/generate-all.py` | 75 |
| `set_grey_borders` | Function | `clients/AFFG/_generators/generate-all.py` | 90 |
| `run` | Function | `clients/AFFG/_generators/generate-all.py` | 123 |
| `accent_bar` | Function | `clients/AFFG/_generators/generate-all.py` | 133 |
| `cover_page` | Function | `clients/AFFG/_generators/generate-all.py` | 147 |
| `section_header` | Function | `clients/AFFG/_generators/generate-all.py` | 192 |
| `part_header` | Function | `clients/AFFG/_generators/generate-all.py` | 209 |
| `styled_table` | Function | `clients/AFFG/_generators/generate-all.py` | 221 |
| `body` | Function | `clients/AFFG/_generators/generate-all.py` | 244 |
| `body_bold` | Function | `clients/AFFG/_generators/generate-all.py` | 250 |
| `bullet` | Function | `clients/AFFG/_generators/generate-all.py` | 257 |

## Execution Flows

| Flow | Type | Steps |
|------|------|-------|
| `Build_msa → Set_cell_shading` | cross_community | 4 |
| `Build_msa → Remove_borders` | cross_community | 4 |
| `Build_msa → Set_cell_shading` | cross_community | 4 |
| `Build_msa → Remove_borders` | cross_community | 4 |
| `Build_sow → Set_cell_shading` | intra_community | 4 |
| `Build_sow → Remove_borders` | intra_community | 4 |
| `Build_msa → Set_cell_shading` | intra_community | 4 |
| `Build_msa → Remove_borders` | intra_community | 4 |
| `Build_sow_compliance → Set_cell_shading` | intra_community | 4 |
| `Build_sow_compliance → Remove_borders` | intra_community | 4 |

## How to Explore

1. `gitnexus_context({name: "set_cell_shading"})` — see callers and callees
2. `gitnexus_query({query: "_generators"})` — find related execution flows
3. Read key files listed above for implementation details
