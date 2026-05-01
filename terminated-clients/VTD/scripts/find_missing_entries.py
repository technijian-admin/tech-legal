"""
VTD missing-entries diagnosis.

Per Ravi 2026-04-30: techs may submit time entries AFTER the monthly invoice is sent;
those late entries should appear in subsequent weekly time-entry spreadsheets.

This script finds, per service month, which entries in the global ticket file are:
  (a) present in the monthly attachment for that month
  (b) recovered via a weekly attachment sent after the monthly
  (c) TRULY MISSING — not in any spreadsheet sent to the client

Output: terminated-clients/VTD/exhibits/rebuild/vtd_missing_entries.xlsx
"""

from __future__ import annotations
import os, glob, email, re, tempfile
from email import policy
import pandas as pd
from datetime import datetime

VTD = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
EMAILS_DIR = os.path.join(VTD, 'emails', 'billing_history')
OUT_DIR    = os.path.join(VTD, 'exhibits', 'rebuild')
os.makedirs(OUT_DIR, exist_ok=True)


def extract_attachment_xlsx(eml_path):
    """Yield (sent_dt, attachment_filename, dataframe) for each time-entry xlsx in the eml."""
    with open(eml_path, 'rb') as f:
        msg = email.message_from_binary_file(f, policy=policy.default)
    sent_dt = email.utils.parsedate_to_datetime(msg['Date']) if msg['Date'] else None
    if sent_dt:
        sent_dt = sent_dt.replace(tzinfo=None)
    for part in msg.iter_attachments():
        n = (part.get_filename() or '').lower()
        if ('time entries' in n or 'time entry' in n) and n.endswith('.xlsx'):
            payload = part.get_payload(decode=True)
            with tempfile.NamedTemporaryFile(suffix='.xlsx', delete=False) as tmp:
                tmp.write(payload)
                p = tmp.name
            try:
                df = pd.read_excel(p, sheet_name='TimeEntries')
                df['__sent_dt']     = sent_dt
                df['__source_eml'] = os.path.basename(eml_path)
                df['__attachment'] = part.get_filename()
                yield df
            finally:
                try:
                    os.unlink(p)
                except (PermissionError, OSError):
                    pass


def gather_attachments(pattern):
    """Walk all eml files matching pattern, return concatenated time-entry rows."""
    rows = []
    for eml in sorted(glob.glob(os.path.join(EMAILS_DIR, '*', pattern))):
        for df in extract_attachment_xlsx(eml):
            rows.append(df)
    if not rows:
        return pd.DataFrame()
    out = pd.concat(rows, ignore_index=True)
    return out


def normalize(df):
    """Filter to Under Contract, normalize keys for matching."""
    if df.empty:
        return df
    df = df[df['Contract'] == 'Under Contract'].copy()
    df['Date Requested'] = pd.to_datetime(df['Date Requested'], errors='coerce')
    df['Start']          = pd.to_datetime(df['Start'], errors='coerce')
    # Match key = (Title trimmed, Start to minute precision)
    df['__title_norm'] = df['Title'].astype(str).str.strip().str.lower()
    df['__start_min']  = df['Start'].dt.floor('min')
    df['__key']        = df['__title_norm'] + '||' + df['__start_min'].astype(str)
    df['ServiceMonth'] = df['Date Requested'].dt.to_period('M').astype(str)
    df['Hours'] = df.get('Normal Qty', 0).fillna(0) + df.get('AH Qty', 0).fillna(0)
    return df


def main():
    print('Walking monthly emails...')
    monthly = normalize(gather_attachments('*Monthly_Invoice_*.eml'))
    print(f'  Monthly attachment rows (Under Contract): {len(monthly)}')

    print('Walking weekly emails...')
    weekly = normalize(gather_attachments('*Weekly_Invoice_*.eml'))
    print(f'  Weekly attachment rows (Under Contract): {len(weekly)}')

    # Combined "sent to client" key set: monthly + weekly
    sent_keys = set(monthly['__key']) | set(weekly['__key'])
    print(f'  Total unique entries sent (monthly + weekly): {len(sent_keys)}')

    # Global ticket file (the ground truth)
    print('Loading global ticket file...')
    g = pd.read_excel(os.path.join(VTD, 'exhibits',
        'vtd_TicketTimeEntries_2023-01-01_to_2026-04-14.xlsx'))
    gc = g[(g['ContractID'] == 4915) & (g['StatusTxt'] == 'Completed')].copy()
    gc['StartDateTime'] = pd.to_datetime(gc['StartDateTime'], errors='coerce')
    gc['__title_norm']  = gc['Title'].astype(str).str.strip().str.lower()
    gc['__start_min']   = gc['StartDateTime'].dt.floor('min')
    gc['__key']         = gc['__title_norm'] + '||' + gc['__start_min'].astype(str)
    gc['ServiceMonth']  = gc['StartDateTime'].dt.to_period('M').astype(str)
    for c in ['NH_HoursWorked', 'AH_HoursWorked', 'Onsite_HoursWorked']:
        gc[c] = gc[c].fillna(0)
    gc['Hours'] = gc['NH_HoursWorked'] + gc['AH_HoursWorked'] + gc['Onsite_HoursWorked']
    print(f'  Global rows (Contract 4915 Completed): {len(gc)}')

    # Classification per global entry
    monthly_keys = set(monthly['__key'])
    weekly_keys  = set(weekly['__key'])

    def classify(k):
        if k in monthly_keys: return 'on_monthly'
        if k in weekly_keys:  return 'on_weekly_only'
        return 'truly_missing'
    gc['SendStatus'] = gc['__key'].apply(classify)

    # Per service month roll-up
    summary = gc.groupby('ServiceMonth').apply(lambda d: pd.Series({
        'Global_Hours':      d['Hours'].sum(),
        'Global_Rows':       len(d),
        'On_Monthly_Hours':  d.loc[d['SendStatus']=='on_monthly','Hours'].sum(),
        'On_Monthly_Rows':   (d['SendStatus']=='on_monthly').sum(),
        'On_WeeklyOnly_Hours': d.loc[d['SendStatus']=='on_weekly_only','Hours'].sum(),
        'On_WeeklyOnly_Rows':  (d['SendStatus']=='on_weekly_only').sum(),
        'TrulyMissing_Hours': d.loc[d['SendStatus']=='truly_missing','Hours'].sum(),
        'TrulyMissing_Rows':  (d['SendStatus']=='truly_missing').sum(),
    })).reset_index()

    # Verbose detail of truly missing
    missing = gc[gc['SendStatus']=='truly_missing'][[
        'TicketEntryID','TicketID','Title','RequestorName',
        'StartDateTime','RoleTypeTxt','AssignedName','InvoiceID',
        'NH_HoursWorked','AH_HoursWorked','Onsite_HoursWorked','Hours',
        'ServiceMonth',
    ]].sort_values(['ServiceMonth','StartDateTime'])

    # Verbose detail of weekly-only-recovered (the "we did send them, just on weeklies" answer)
    weekly_only = gc[gc['SendStatus']=='on_weekly_only'][[
        'TicketEntryID','TicketID','Title','RequestorName',
        'StartDateTime','RoleTypeTxt','AssignedName','InvoiceID',
        'Hours','ServiceMonth',
    ]].sort_values(['ServiceMonth','StartDateTime'])

    out_xlsx = os.path.join(OUT_DIR, 'vtd_missing_entries.xlsx')
    with pd.ExcelWriter(out_xlsx, engine='openpyxl') as w:
        summary.to_excel(w,    sheet_name='1_PerMonth_Summary', index=False)
        missing.to_excel(w,    sheet_name='2_TrulyMissing_Detail', index=False)
        weekly_only.to_excel(w, sheet_name='3_WeeklyOnly_Recovered', index=False)
    print(f'\nOutput: {out_xlsx}')

    print('\n=== PER-MONTH SUMMARY ===')
    print(summary.to_string(index=False))

    print('\n=== TOTALS ===')
    tot = summary[['Global_Hours','On_Monthly_Hours','On_WeeklyOnly_Hours','TrulyMissing_Hours']].sum()
    print(f'Global hrs:               {tot["Global_Hours"]:>9.2f}')
    print(f'On monthly:               {tot["On_Monthly_Hours"]:>9.2f}  ({tot["On_Monthly_Hours"]/tot["Global_Hours"]*100:.1f}%)')
    print(f'On weekly (recovered):    {tot["On_WeeklyOnly_Hours"]:>9.2f}  ({tot["On_WeeklyOnly_Hours"]/tot["Global_Hours"]*100:.1f}%)')
    print(f'Truly missing:            {tot["TrulyMissing_Hours"]:>9.2f}  ({tot["TrulyMissing_Hours"]/tot["Global_Hours"]*100:.1f}%)')


if __name__ == '__main__':
    main()
