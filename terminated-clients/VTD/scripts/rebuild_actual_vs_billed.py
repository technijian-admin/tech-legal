"""
VTD actual-vs-billed rebuild — sourced from the canonical email pipeline.

Per Ravi 2026-04-30:
- Build BILLED hours from the invoice register (only canonical invoices, voids excluded).
- Build ACTUAL hours from time-entry xlsx attachments on the monthly emails sent to
  Erica Garcia at vintagedesigninc.com.
- Diagnose any discrepancies against the global ticket spreadsheet.

Scope filter:
- VTD has ZERO formal proposals. Only Contract 4915 (monthly service) is in scope.
- Contract 4942 (onboarding fixed-price) and OOC weekly invoices are out of scope.
- Voided / zero-total invoices are excluded.
- Post-termination invoices (after 2025-07-31) are flagged.

Output: ../exhibits/rebuild/vtd_actual_vs_billed_REBUILT.xlsx
        ../exhibits/rebuild/vtd_methodology.md
        ../exhibits/rebuild/vtd_void_register.md
"""

from __future__ import annotations
import os, sys, glob, email, re, json
from email import policy
from datetime import datetime
from dateutil.relativedelta import relativedelta
import pandas as pd
import tempfile

VTD = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
EXHIBITS = os.path.join(VTD, 'exhibits')
EMAILS_DIR = os.path.join(VTD, 'emails', 'billing_history')
OUT_DIR = os.path.join(EXHIBITS, 'rebuild')
os.makedirs(OUT_DIR, exist_ok=True)

INVOICE_REG = os.path.join(EXHIBITS, 'vtd_InvoiceDetails_2023-01-01_to_2026-04-14.xlsx')
GLOBAL_TIX  = os.path.join(EXHIBITS, 'vtd_TicketTimeEntries_2023-01-01_to_2026-04-14.xlsx')

TERMINATION = datetime(2025, 7, 31)


# -- 1. BILLED HOURS FROM INVOICE REGISTER -----------------------------------

def build_billed():
    df = pd.read_excel(INVOICE_REG)
    df['InvoiceDate'] = pd.to_datetime(df['InvoiceDate'])
    monthly = df[df['InvoiceType'] == 'Monthly'].copy()

    # Identify canonical vs voided invoices: void = all line items zero or InvoiceTotal == 0
    headers = monthly.drop_duplicates(subset='InvoiceID')[
        ['InvoiceID', 'InvoiceDate', 'InvoiceTotal']
    ].copy()
    voided = headers[headers['InvoiceTotal'] == 0]['InvoiceID'].tolist()
    canonical = headers[headers['InvoiceTotal'] > 0]

    # Service month = invoice_date + 1 month (Ravi 2026-04-30: net-30 advance billing —
    # "invoice dated June 1st is the billed hours for July since we have net 30").
    # Each monthly email contains: an invoice billing forward 30 days (next service month) +
    # a time-entry xlsx reporting the previous 30 days (prior service month).
    canonical['ServiceMonth'] = canonical['InvoiceDate'].apply(
        lambda d: (d + relativedelta(months=1)).replace(day=1)
    )
    canonical['PostTermination'] = canonical['ServiceMonth'] > TERMINATION

    # Quantity per service month per category
    cats = {
        'OffShore_Support.R':    'CHD_Normal_Qty',
        'OffShore_Support.R.AF': 'CHD_AfterHours_Qty',
        'Tech_Support.R':        'IRV_Normal_Qty',
    }
    rows = []
    for _, inv in canonical.iterrows():
        lines = monthly[monthly['InvoiceID'] == inv['InvoiceID']]
        out = {
            'ServiceMonth':   inv['ServiceMonth'],
            'InvoiceID':      inv['InvoiceID'],
            'InvoiceDate':    inv['InvoiceDate'],
            'InvoiceTotal':   inv['InvoiceTotal'],
            'PostTermination': inv['PostTermination'],
        }
        for item, col in cats.items():
            qty = lines[lines['Item'] == item]['Qty'].sum()
            out[col] = qty
        rows.append(out)

    billed = pd.DataFrame(rows).sort_values('ServiceMonth').reset_index(drop=True)
    return billed, voided


# -- 2. ACTUAL HOURS FROM EMAIL TIME-ENTRY ATTACHMENTS -----------------------

def build_actual():
    """Combine Under-Contract time-entry rows from monthly AND weekly attachments,
    dedupe by (Title, Start, Resource) key, then aggregate per work month.

    Per Ravi 2026-04-30: late tech submissions appear on subsequent weekly attachments
    after the monthly was sent. Both must be included to capture full Under-Contract hours.
    OOC weekly attachments are excluded (separate scope).
    """
    patterns = ['*Monthly_Invoice_*.eml', '*Weekly_Invoice_*.eml']  # NOT Out_of_Contract
    all_te = []
    for pat in patterns:
        for eml_path in sorted(glob.glob(os.path.join(EMAILS_DIR, '*', pat))):
            with open(eml_path, 'rb') as f:
                msg = email.message_from_binary_file(f, policy=policy.default)
            subj = msg['Subject'] or ''
            mre = re.search(r'Invoice (\d+)', subj)
            portal_id = int(mre.group(1)) if mre else None
            sent_dt = email.utils.parsedate_to_datetime(msg['Date']) if msg['Date'] else None
            for part in msg.iter_attachments():
                name = (part.get_filename() or '').lower()
                if ('time entries' in name or 'time entry' in name) and name.endswith('.xlsx'):
                    with tempfile.NamedTemporaryFile(suffix='.xlsx', delete=False) as tmp:
                        tmp.write(part.get_payload(decode=True))
                        tmp_path = tmp.name
                    try:
                        te = pd.read_excel(tmp_path, sheet_name='TimeEntries')
                        te = te[te['Contract'] == 'Under Contract']
                        if te.empty:
                            continue
                        te['Date Requested'] = pd.to_datetime(te['Date Requested'], errors='coerce')
                        te['Start']          = pd.to_datetime(te['Start'], errors='coerce')
                        te['__key'] = (
                            te['Title'].astype(str).str.strip().str.lower()
                            + '||' + te['Start'].dt.floor('min').astype(str)
                            + '||' + te.get('Resource', pd.Series([''] * len(te))).astype(str)
                        )
                        te['__src_eml']   = os.path.basename(eml_path)
                        te['__sent']      = sent_dt.replace(tzinfo=None) if sent_dt else None
                        te['__portal_id'] = portal_id
                        te['__src_type']  = 'Monthly' if 'Monthly' in pat else 'Weekly'
                        all_te.append(te)
                    finally:
                        try: os.unlink(tmp_path)
                        except (PermissionError, OSError): pass

    if not all_te:
        return pd.DataFrame()
    combined = pd.concat(all_te, ignore_index=True)
    combined = combined.drop_duplicates(subset='__key', keep='first')
    combined['ServiceMonth'] = combined['Date Requested'].dt.to_period('M').dt.to_timestamp()

    rows = []
    for sm, grp in combined.groupby('ServiceMonth'):
        chd = grp[grp['POD'] == 'CHD-TS1']
        irv = grp[grp['POD'] == 'IRV-TS1']
        # Pull the Portal ID for this service month from the Monthly source if present
        monthly_portal = grp.loc[grp['__src_type'] == 'Monthly', '__portal_id'].dropna()
        portal_id = int(monthly_portal.iloc[0]) if len(monthly_portal) else None
        rows.append({
            'ServiceMonth':           sm,
            'CHD_Normal_Actual':      chd['Normal Qty'].fillna(0).sum(),
            'CHD_AfterHours_Actual':  chd['AH Qty'].fillna(0).sum(),
            'IRV_Normal_Actual':      irv['Normal Qty'].fillna(0).sum(),
            'IRV_AfterHours_Actual':  irv['AH Qty'].fillna(0).sum(),
            'TicketCount':            len(grp),
            'TicketCount_Monthly':    (grp['__src_type'] == 'Monthly').sum(),
            'TicketCount_WeeklyOnly': (grp['__src_type'] == 'Weekly').sum(),
            'PortalInvoiceID':        portal_id,
            'EmailSent':              grp['__sent'].max(),
            'EmlPath':                grp['__src_eml'].iloc[0],
        })
    return pd.DataFrame(rows).sort_values('ServiceMonth').reset_index(drop=True)


# -- 3. RECONCILIATION + AVERAGING VALIDATION --------------------------------

def reconcile(billed, actual):
    merged = billed.merge(actual, on='ServiceMonth', how='outer').sort_values('ServiceMonth')
    # Diff columns
    for cat in ['CHD_Normal', 'CHD_AfterHours', 'IRV_Normal']:
        merged[f'{cat}_Diff'] = (
            merged[f'{cat}_Actual'] - merged[f'{cat}_Qty']
        )
    return merged


def period_totals(merged):
    # Periods per the signed Client Monthly Service Agreement (12-month under-contract)
    periods = [
        ('P1 (May 2023 - Apr 2024)', datetime(2023,5,1), datetime(2024,4,1)),
        ('P2 (May 2024 - Apr 2025)', datetime(2024,5,1), datetime(2025,4,1)),
        ('P3 (May 2025 - Jul 2025, terminated)', datetime(2025,5,1), datetime(2025,7,1)),
    ]
    rows = []
    for label, start, end in periods:
        slc = merged[(merged['ServiceMonth'] >= start) & (merged['ServiceMonth'] <= end)]
        months = len(slc)
        for cat, qcol, acol in [
            ('OffShore Normal', 'CHD_Normal_Qty', 'CHD_Normal_Actual'),
            ('OffShore AH',     'CHD_AfterHours_Qty', 'CHD_AfterHours_Actual'),
            ('Tech Support',    'IRV_Normal_Qty', 'IRV_Normal_Actual'),
        ]:
            billed = slc[qcol].sum()
            actual = slc[acol].sum()
            rows.append({
                'Period':        label,
                'Category':      cat,
                'Months':        months,
                'Total Billed':  billed,
                'Total Actual':  actual,
                'Avg Billed/mo': billed / months if months else 0,
                'Avg Actual/mo': actual / months if months else 0,
                'Delta (Actual-Billed)': actual - billed,
            })
    return pd.DataFrame(rows)


def averaging_validation(merged):
    # Per MSA ¶¶ 3-4: P2 billed monthly Qty should ≈ P1 actual monthly avg
    # P3 billed monthly Qty should ≈ P2 actual monthly avg
    rows = []
    cats = [
        ('OffShore Normal', 'CHD_Normal_Qty', 'CHD_Normal_Actual'),
        ('OffShore AH',     'CHD_AfterHours_Qty', 'CHD_AfterHours_Actual'),
        ('Tech Support',    'IRV_Normal_Qty', 'IRV_Normal_Actual'),
    ]
    boundaries = [
        ('P1->P2', datetime(2023,5,1), datetime(2024,4,1), datetime(2024,5,1), datetime(2025,4,1)),
        ('P2->P3', datetime(2024,5,1), datetime(2025,4,1), datetime(2025,5,1), datetime(2025,7,1)),
    ]
    for label, p_start, p_end, n_start, n_end in boundaries:
        prev = merged[(merged['ServiceMonth'] >= p_start) & (merged['ServiceMonth'] <= p_end)]
        nxt  = merged[(merged['ServiceMonth'] >= n_start) & (merged['ServiceMonth'] <= n_end)]
        for cat, qcol, acol in cats:
            prev_actual_avg  = prev[acol].sum() / 12  # MSA averaging divides by 12
            next_billed_avg  = nxt[qcol].mean() if len(nxt) else 0
            rows.append({
                'Boundary':         label,
                'Category':         cat,
                'Prior Actual Avg (÷12)': round(prev_actual_avg, 2),
                'Next Billed Monthly':    round(next_billed_avg, 2),
                'Delta':            round(next_billed_avg - prev_actual_avg, 2),
                'Tied?':            'YES' if abs(next_billed_avg - prev_actual_avg) < 0.5 else 'NO',
            })
    return pd.DataFrame(rows)


# -- 4. WRITE OUTPUT ---------------------------------------------------------

def write_output(billed, actual, merged, periods, validation, voided):
    out_xlsx = os.path.join(OUT_DIR, 'vtd_actual_vs_billed_REBUILT.xlsx')
    with pd.ExcelWriter(out_xlsx, engine='openpyxl') as w:
        merged_view = merged[[
            'ServiceMonth', 'InvoiceID', 'InvoiceDate', 'PortalInvoiceID', 'PostTermination',
            'CHD_Normal_Qty', 'CHD_Normal_Actual', 'CHD_Normal_Diff',
            'CHD_AfterHours_Qty', 'CHD_AfterHours_Actual', 'CHD_AfterHours_Diff',
            'IRV_Normal_Qty', 'IRV_Normal_Actual', 'IRV_Normal_Diff',
            'TicketCount', 'EmailSent', 'InvoiceTotal',
        ]].copy()
        merged_view.to_excel(w, sheet_name='1_Monthly_Reconciliation', index=False)
        periods.to_excel(w, sheet_name='2_Period_Totals', index=False)
        validation.to_excel(w, sheet_name='3_Averaging_Validation', index=False)
        billed.to_excel(w, sheet_name='4_Canonical_Billed_Source', index=False)
        actual.to_excel(w, sheet_name='5_Email_Actual_Source', index=False)

        void_df = pd.DataFrame({'VoidedInvoiceID': voided})
        void_df.to_excel(w, sheet_name='6_Voided_Register_IDs', index=False)
    return out_xlsx


def write_methodology():
    path = os.path.join(OUT_DIR, 'vtd_methodology.md')
    content = """# VTD Actual-vs-Billed Rebuild — Methodology

Generated by: `scripts/rebuild_actual_vs_billed.py`
Generated at: """ + datetime.now().strftime('%Y-%m-%d %H:%M') + """

## Sources of truth (in order of authority)

1. **Monthly emails sent from `billing@technijian.com` to `ericagarcia@vintagedesigninc.com`** — what the client legally received. Each email carries a PDF invoice + a `Monthly Time Entries.xlsx` attachment.
2. **Invoice register** (`exhibits/vtd_InvoiceDetails_2023-01-01_to_2026-04-14.xlsx`) — final-state invoice data after voids/replacements. Used to identify canonical invoices and exclude voids.
3. **Global ticket spreadsheet** (`exhibits/vtd_TicketTimeEntries_2023-01-01_to_2026-04-14.xlsx`) — internal ground truth for diagnosing discrepancies. NOT used for client-facing numbers.

When the canonical email pipeline disagrees with the internal system, the **email pipeline wins** for any client-facing or arbitration-facing number. The internal system data is for diagnosis only.

## Scope filter

| Layer | In scope | Out of scope |
|---|---|---|
| Contract | **Contract 4915** (Client Monthly Service Agreement, signed 2023-05-04). Time-entry rows where column A `Contract == 'Under Contract'` only. | Contract 4942 (onboarding, fixed-price); OOC weekly invoices |
| Proposals | None — VTD has zero formal proposals | (VG / Vintage Group's Proposal 6831 / Contract 5477 / 5192 are NOT VTD data) |
| Period | May 2023 – July 2025 | Anything `ServiceMonth > 2025-07-31` (flagged `PostTermination=True`) |
| Invoices | Register entries where `InvoiceType='Monthly'` AND `InvoiceTotal > 0` | Voided / zero-total invoices (sheet 6 of output xlsx) |

## Definitions

- **Service month**: the calendar month the support work covers.
- **Billed quantity**: from invoice register; `Qty` column for one of three Item codes:
  - `OffShore_Support.R` → CHD-TS1 normal hours billed
  - `OffShore_Support.R.AF` → CHD-TS1 after-hours billed
  - `Tech_Support.R` → IRV-TS1 normal hours billed
- **Actual quantity**: from time-entry xlsx attached to monthly email; aggregate `Normal Qty` (col H) and `AH Qty` (col J), grouped by `POD` (col N: CHD-TS1 vs IRV-TS1), filtered to `Contract == 'Under Contract'`.

## Convention: invoice timing

Per signed Agreement Other Terms ¶ 2 (advance billing on net-30):
- Invoice dated `M-1` covers service month `M` (advance billing).
- Time-entry xlsx attached to the email sent at start of month `M+1` reports actual hours for service month `M` (in arrears).

The rebuild aligns both billed and actual to **service month** so each row is one calendar month of work.

## June 2023 duplicate (Jodie's question)

Two invoices appear in the register for June 2023:
- **#36128** — InvoiceTotal = `$0.00`, all line item Qty = 0. **Void marker.**
- **#36372** — InvoiceTotal = `$7,551.50`, full quantities. **Canonical.**

The two emails Jodie identified (#4255 issued 2023-05-09 and #4442 issued 2023-06-02) are Portal invoice IDs that don't directly cross-reference the register IDs. The **canonical June 2023 invoice is whichever was non-zero in the register** — that's #36372 (or its Portal-ID equivalent in the email file, identifiable by matching InvoiceDate + service quantities).

## August 2025 invoice #26205 (Jodie's question)

Portal invoice #26205 is in the email pipeline but **not in the register** — meaning it was voided in the billing system after the email was sent. Should be excluded from any document production to opposing counsel.

## Averaging math validation

Per MSA ¶¶ 3-4, the new monthly billed quantity for cycle N should equal the average of cycle N-1's actual hours, divided by 12. Sheet 3 of the output xlsx tests this: for each P→P+1 boundary, prior-period actual ÷ 12 vs next-period billed monthly average. Tied = exact match within 0.5 hours.

## Output structure

`exhibits/rebuild/vtd_actual_vs_billed_REBUILT.xlsx`:

| Sheet | Purpose |
|---|---|
| 1_Monthly_Reconciliation | Per-month actual vs billed for all 3 categories + diff |
| 2_Period_Totals | P1 / P2 / P3 totals + monthly averages |
| 3_Averaging_Validation | P1→P2 and P2→P3 averaging math check |
| 4_Canonical_Billed_Source | Raw billed quantities from register |
| 5_Email_Actual_Source | Raw actual quantities from email attachments |
| 6_Voided_Register_IDs | Invoice IDs marked as voided in the register |
"""
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    return path


def main():
    print('=== VTD Rebuild ===')
    print('Loading invoice register...')
    billed, voided = build_billed()
    print(f'  Canonical monthly invoices: {len(billed)}')
    print(f'  Voided register IDs: {voided}')

    print('Walking monthly emails...')
    actual = build_actual()
    print(f'  Service months with email-sourced actuals: {len(actual)}')

    print('Reconciling...')
    merged = reconcile(billed, actual)

    print('Computing period totals...')
    periods = period_totals(merged)

    print('Validating averaging mechanism...')
    validation = averaging_validation(merged)

    print('Writing outputs...')
    xlsx = write_output(billed, actual, merged, periods, validation, voided)
    md   = write_methodology()
    print(f'  -> {xlsx}')
    print(f'  -> {md}')

    print('\n=== PERIOD TOTALS PREVIEW ===')
    print(periods.to_string(index=False))
    print('\n=== AVERAGING VALIDATION PREVIEW ===')
    print(validation.to_string(index=False))


if __name__ == '__main__':
    main()
