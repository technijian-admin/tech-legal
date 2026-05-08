# Signed Letters Folder

When you sign the 6 termination/retrenchment letters, drop the scanned signed PDFs in this folder using the **same filenames** as the unsigned versions in `../pdf/`:

```
01-Devesh-Bhattacharya-Termination.pdf
02-Rajat-Kumar-Termination.pdf
03-Aditya-Saraf-Termination.pdf
04-Suresh-Kumar-Sharma-Termination.pdf
05-Yogesh-Kumar-Retrenchment.pdf
06-Rahul-Uniyal-Retrenchment.pdf
```

After dropping signed versions here, re-run either send script:

- `..\..\send-india-restructuring.ps1` — refreshes the leads draft (Ajay/Gurdeep)
- `..\..\send-directors-briefing.ps1` — refreshes the directors draft

Both scripts auto-detect signed versions and use them in preference to the unsigned originals. The script output will tell you `[SIGNED]` vs `[unsigned]` for each letter.

Leave applications stay unsigned — the employees sign them on Monday.
