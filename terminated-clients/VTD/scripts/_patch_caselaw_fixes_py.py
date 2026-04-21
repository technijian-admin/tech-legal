"""Patch the VTD-Ed case-law draft with the 3 remaining citation fixes.
Reads the current draft body from disk (saved by the _working HTML grab),
makes the replacements with clean UTF-8, then emits the patched HTML so the
PowerShell wrapper can PATCH it back to Graph.
"""
import sys, pathlib

src = pathlib.Path(r'C:\VSCode\tech-legal\tech-legal\terminated-clients\VTD\_working_caselaw_draft.html')
dst = pathlib.Path(r'C:\VSCode\tech-legal\tech-legal\terminated-clients\VTD\_working_caselaw_draft_patched.html')

html = src.read_text(encoding='utf-8')

edits = []

# Fix 1b: Iyere recommended use — replace only if the "Belongs in §" line still has old language
old_1b = 'Belongs in §&nbsp;17 alongside <i>Fabian</i> and <i>Ruiz</i>. Caveat: <i>Iyere</i> concerned a physical signature and the court distinguished electronic ones, so cite for the burden framework, not as direct e-sig authority.'
new_1b = 'Recommended use: cite in §&nbsp;17 only by ANALOGY, for the proposition that if even under the stricter handwritten-signature framework a bare failure-to-recall is insufficient, the same principle supports the proponent in the e-sig context governed by <i>Ruiz</i> and <i>Fabian</i>. Do NOT frame <i>Iyere</i> as a direct e-sig authentication holding.'

if old_1b in html:
    html = html.replace(old_1b, new_1b)
    edits.append('Fix 1b Iyere recommended use: applied')
else:
    edits.append('Fix 1b Iyere recommended use: anchor MISSED')

# Fix 2: Hohenshelt add 18 Cal.5th 310
old_2 = '<i>Hohenshelt v. Superior Court</i> (2025) \u2014 CCP §§&nbsp;1281.97/1281.98 fee-payment deadlines;'
new_2 = '<i>Hohenshelt v. Superior Court</i> (2025) 18 Cal.5th 310 \u2014 CCP §§&nbsp;1281.97/1281.98 fee-payment deadlines;'

if old_2 in html:
    html = html.replace(old_2, new_2)
    edits.append('Fix 2 Hohenshelt cite: applied')
else:
    edits.append('Fix 2 Hohenshelt cite: anchor MISSED')

# Fix 3: NECF add docket and filing date
old_3 = '<i>New England Country Foods, LLC v. Vanlaw Food Products</i> (2025) \u2014 §&nbsp;1668 limits contractual limitations of liability for willful injury;'
new_3 = '<i>New England Country Foods, LLC v. Vanlaw Food Products</i> (Cal. Apr. 24, 2025, S282968) \u2014 §&nbsp;1668 limits contractual limitations of liability for willful injury;'

if old_3 in html:
    html = html.replace(old_3, new_3)
    edits.append('Fix 3 NECF cite: applied')
else:
    edits.append('Fix 3 NECF cite: anchor MISSED')

dst.write_text(html, encoding='utf-8')

for e in edits:
    print(e)
print(f'\nPatched HTML written to: {dst}')
