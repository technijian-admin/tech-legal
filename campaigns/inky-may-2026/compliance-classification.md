# Compliance Classification — 44 Prospects

Industry-based mapping to the closest regulatory framework that should drive the email pitch. Frameworks confirmed against Obsidian Compliance Matrix and client notes.

## Tier 1 — Heavy Compliance (14 clients, custom templates required)

### Financial Services (4) — SEC Reg S-P, FINRA Rules, FTC Safeguards, GLBA

| Code | Client | Framework | Why |
|------|--------|-----------|-----|
| AFFG | American Fundstars Financial Group | SEC Reg S-P (2024 Amendments), FINRA 3110/4370, SEC 17a-4 | Registered Investment Adviser, Iris Liu is CCO, MSA effective 2026-05-01 with full compliance overlay |
| EAG | Ellis Advisory Group | SEC Reg S-P, FTC Safeguards | Financial advisory practice |
| VAF | Via Auto Finance | GLBA, FTC Safeguards (Dec 2022), ECOA, FCRA | Consumer auto lending — customer financial info |
| JSD | Jerry Seiner Dealerships | FTC Safeguards Rule, GLBA | Auto dealer (offers financing = GLBA financial institution) |

### Healthcare (4) — HIPAA Security Rule, HITECH, California CMIA

| Code | Client | Framework | Why |
|------|--------|-----------|-----|
| PCM | 180 Medical, Inc. | HIPAA (covered entity), CMS/Medicare, HITECH | DME supplier, billing Medicare |
| ISI | Intl Sportsmedicine Institute | HIPAA (covered entity) | Medical practice |
| RSPMD | Rosalina See-Prats, M.D. | HIPAA (covered entity), CMIA | Solo physician practice |
| SVE | Saddleback Valley Endodontic | HIPAA (covered entity), CMIA | Endodontic dental practice |

### Legal (3) — ABA Model Rule 1.1/1.6, California RPC 1.6(c), Formal Op 477R

| Code | Client | Framework | Why |
|------|--------|-----------|-----|
| CBL | Chris Bank Law | ABA / Cal RPC 1.6(c) — reasonable efforts to prevent disclosure | Law firm |
| RALF | Richard C. Alter Law Firm | Same | Law firm |
| LODC | Law Offices of David Chesley | Same | Law firm |

### Aerospace / Defense (2) — CMMC 2.0, DFARS 252.204-7012, ITAR

| Code | Client | Framework | Why |
|------|--------|-----------|-----|
| ASC | Adsys Controls, Inc | CMMC Level 2 likely, DFARS 7012, possibly ITAR | Avionics/control-systems manufacturer |
| CAM | Coast Aero Mfg | Same | Aerospace manufacturer |

### Insurance / Benefits (1) — HIPAA + GLBA + State Insurance Laws

| Code | Client | Framework | Why |
|------|--------|-----------|-----|
| ALE | Alera Group | HIPAA (health plans/broker), GLBA, state insurance regs | Employee benefits / insurance brokerage |

## Tier 2 — Light Compliance (30 clients, base prospect template)

Use the unchanged prospect template. Compliance angles exist but aren't the primary pitch driver:

- **Construction/Engineering** (4): BBC, CCC, RKEG, BBE — general cyber-hygiene, insurance requirements
- **Real Estate** (3): AOC, AAVA, RMG — consumer data handling (tenant info)
- **Hospitality** (3): AYH, FOR, TOR — PCI-DSS (card payments), guest data
- **Nonprofit / Community** (2): ONE, GRF — donor/resident data
- **Manufacturing/Distribution** (4): ANI, BRM, MGN, USFI (food: FDA FSMA)
- **Logistics / Import-Export** (2): ALG (export controls EAR), WCS
- **IT / Consulting** (4): HIT, GSD, SGC, SSCI
- **Marketing / Other** (3): LAG, TALY*, STW
- **Retail / Small Business** (3): BBTS, KCC, TCH
- **Personal** (1): R_GD
- **Non-profit Aux** (1): SAS

*TALY — "Talley & Associates" — industry unclear from portal data. If they're a CPA firm they'd move to Tier 1 (AICPA, IRS Pub 4557, SOC for Service Organizations). Worth confirming before send.

## Template Variants Needed

1. `email-prospects.md` — base template (30 recipients)
2. `email-prospects-financial.md` — SEC/FINRA/GLBA framing (4 recipients)
3. `email-prospects-healthcare.md` — HIPAA framing (4 recipients)
4. `email-prospects-legal.md` — ABA/attorney-client privilege framing (3 recipients)
5. `email-prospects-defense.md` — CMMC/DFARS framing (2 recipients)
6. `email-prospects-insurance.md` — GLBA + HIPAA dual-framework (1 recipient)

## Flags Before Send

- **TALY — RESOLVED 2026-04-24** (via talleyassoc.weebly.com): governmental-relations / association-management / MHP-conversion consulting firm. No specific compliance framework. **Stays on base template.**
- **CAM — RESOLVED 2026-04-24** (via coastaero.com): explicit customer testimonials from Boeing and Northrop Grumman. Sub-tier defense supplier with CMMC 2.0 L2 + DFARS 7012 flow-down from primes. **Stays on defense template; per-client paragraph added emphasizing supply-chain flow-down rather than direct DoD prime work.**
- **ASC — RESOLVED 2026-04-24** (via adsyscontrols.com): extensive defense client roster (NASA, USAF, DARPA, Lincoln Labs, Raytheon, Boeing, Lockheed, Northrop) plus laser / UAS / electro-optical product portfolio. Very strong ITAR + CMMC L2 posture. **Stays on defense template; per-client paragraph added emphasizing ITAR and direct DoD customer base.**
- **AFFG** — this client has the most sophisticated compliance posture of the prospect list (SOW-003 + SOW-004 Rev 1 already signed). The Inky pitch should reference SEC Reg S-P email-security requirements specifically, not generic "cyber insurance" language used in the base template.
