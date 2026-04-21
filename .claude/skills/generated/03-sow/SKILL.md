---
name: 03-sow
description: "Skill for the 03_SOW area of tech-legal. 11 symbols across 1 files."
---

# 03_SOW

11 symbols | 1 files | Cohesion: 100%

## When to Use

- Working with code in `clients/`
- Understanding how make_rPr, add_run, insert_para work
- Modifying 03_sow-related functionality

## Key Files

| File | Symbols |
|------|---------|
| `clients/AFFG/03_SOW/gen_sow_004_rev1.py` | make_rPr, add_run, insert_para, heading, body_para (+6) |

## Entry Points

Start here when exploring this area:

- **`make_rPr`** (Function) — `clients/AFFG/03_SOW/gen_sow_004_rev1.py:70`
- **`add_run`** (Function) — `clients/AFFG/03_SOW/gen_sow_004_rev1.py:90`
- **`insert_para`** (Function) — `clients/AFFG/03_SOW/gen_sow_004_rev1.py:99`
- **`heading`** (Function) — `clients/AFFG/03_SOW/gen_sow_004_rev1.py:112`
- **`body_para`** (Function) — `clients/AFFG/03_SOW/gen_sow_004_rev1.py:122`

## Key Symbols

| Symbol | Type | File | Line |
|--------|------|------|------|
| `make_rPr` | Function | `clients/AFFG/03_SOW/gen_sow_004_rev1.py` | 70 |
| `add_run` | Function | `clients/AFFG/03_SOW/gen_sow_004_rev1.py` | 90 |
| `insert_para` | Function | `clients/AFFG/03_SOW/gen_sow_004_rev1.py` | 99 |
| `heading` | Function | `clients/AFFG/03_SOW/gen_sow_004_rev1.py` | 112 |
| `body_para` | Function | `clients/AFFG/03_SOW/gen_sow_004_rev1.py` | 122 |
| `body_para_with_anchor` | Function | `clients/AFFG/03_SOW/gen_sow_004_rev1.py` | 133 |
| `kv_para` | Function | `clients/AFFG/03_SOW/gen_sow_004_rev1.py` | 149 |
| `bullet_para` | Function | `clients/AFFG/03_SOW/gen_sow_004_rev1.py` | 156 |
| `clause_para` | Function | `clients/AFFG/03_SOW/gen_sow_004_rev1.py` | 174 |
| `make_cell` | Function | `clients/AFFG/03_SOW/gen_sow_004_rev1.py` | 188 |
| `add_table` | Function | `clients/AFFG/03_SOW/gen_sow_004_rev1.py` | 223 |

## How to Explore

1. `gitnexus_context({name: "make_rPr"})` — see callers and callees
2. `gitnexus_query({query: "03_sow"})` — find related execution flows
3. Read key files listed above for implementation details
