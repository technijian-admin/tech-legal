# QbConnectService On-Box Smoke Checklist

Run this on `10.120.254.13` after install and after the one-time authorization in [register-integrated-app.md](register-integrated-app.md).

```powershell
$base = 'https://10.120.254.13:8443'
$token = '<Auth:ApiToken>'
$h = @{ Authorization = "Bearer $token" }
```

## Environment facts to record first

| Fact | How to capture it | Value |
| --- | --- | --- |
| QuickBooks Enterprise year/version/build | `GET /api/health -> quickBooksVersion` and QuickBooks `Help -> About QuickBooks` | |
| Multi-user hosting status of the `.QBW` | QuickBooks UI and QuickBooks Database Server Manager | |
| `svc_qbsdk` account and `Log on as a service` right | `secpol.msc -> User Rights Assignment` | |
| Firewall rule for the HTTPS port | `Get-NetFirewallRule -DisplayName 'QbConnectService HTTPS'` | |
| RequestProcessor vs RequestProcessor2 ProgID, registered and 32-bit | QuickBooks SDK tooling / host inspection | |
| PII / personal-data access granted to the integrated app | QuickBooks `Integrated Applications -> Company Preferences -> Properties` | |
| `qbXmlVersionsSupported` | `GET /api/health` | |

## Checklist

- [ ] Capture the environment facts in the table above before changing anything else.

- [ ] Health check

  ```powershell
  $health = Invoke-RestMethod "$base/api/health" -Headers $h
  $health
  ```

  Good:
  `status` is `healthy`, `connectionState` is `SessionOpen`, `companyFile` matches `appsettings.json`, `quickBooksVersion` is populated, `qbXmlVersionsSupported` is non-empty, and `lastError` is `null`.
  If `status` is `down` or `degraded`, stop here and use [../README.md](../README.md). `lastError.code` is the HRESULT.

- [ ] `company_info`

  ```powershell
  $company = Invoke-RestMethod "$base/api/ops/company_info" -Headers $h -Method Post -Body '{}' -ContentType 'application/json'
  $company
  ```

  Good:
  `$company.result.status.code -eq '0'`, the company name and fiscal-year values are correct, and `edition` matches the real QuickBooks Enterprise edition string.
  Record the exact `edition` / `ProductName` wording. That is the first live re-pin data point.

- [ ] `report`

  ```powershell
  $reportBody = @{
      type = 'ProfitAndLoss'
      dateMacro = 'ThisFiscalYearToDate'
  } | ConvertTo-Json

  $report = Invoke-RestMethod "$base/api/ops/report" -Headers $h -Method Post -Body $reportBody -ContentType 'application/json'
  $report
  ```

  Good:
  `$report.result.report.columns.Count -gt 0`, `$report.result.report.rows.Count -gt 0`, and `$report.result.type -eq 'ProfitAndLoss'`.
  Eyeball the report row and column metadata against the OnScreen Reference:
  `ColDesc`, `ColTitle`, and `ColType` casing are the second live re-pin point.

- [ ] `create_customer` dry-run

  ```powershell
  $customerName = 'ZZ_SMOKE_TEST_' + (Get-Date -Format 'yyyyMMdd_HHmmss')
  $dryRunBody = @{ name = $customerName } | ConvertTo-Json

  $dryRun = Invoke-RestMethod "$base/api/ops/create_customer/dryrun" -Headers $h -Method Post -Body $dryRunBody -ContentType 'application/json'
  $dryRun
  ```

  Good:
  `$dryRun.dryRun.qbXml` contains a well-formed `CustomerAddRq`,
  `$dryRun.dryRun.summary` is populated,
  `$dryRun.dryRun.preFlight` is all green,
  and `$dryRun.dryRun.allowWrites` is `False`.
  This step must have no side effect in QuickBooks. Use the qbXML shape here as another re-pin checkpoint.

- [ ] Flip `AllowWrites` to `true`

  Edit the deployed `appsettings.json`, set `Safety:AllowWrites=true`, then restart the service or task.

  ```powershell
  Restart-Service QbConnectService
  $health = Invoke-RestMethod "$base/api/health" -Headers $h
  $health.allowWrites
  ```

  Good:
  `health.allowWrites` is now `true`.

- [ ] One real low-stakes write

  ```powershell
  $create = Invoke-RestMethod "$base/api/ops/create_customer" -Headers $h -Method Post -Body $dryRunBody -ContentType 'application/json'
  $create
  ```

  Good:
  HTTP 200, `$create.result.status.code -eq '0'`, and the first returned row contains `ListID` and `EditSequence`.
  A customer is the preferred smoke write because it is reversible and has no GL impact.
  If the name already exists from a previous run, append another timestamp or GUID and retry once with the new name.

- [ ] Confirm the new customer in QuickBooks and make it inactive

  Open QuickBooks on the host, open the Customers list, and confirm the smoke customer exists.
  Then make it inactive either in the QuickBooks UI or through raw qbXML while `AllowWrites=true`.

  ```xml
  <?xml version="1.0" encoding="utf-8"?>
  <?qbxml version="16.0"?>
  <QBXML>
    <QBXMLMsgsRq onError="stopOnError">
      <CustomerModRq>
        <CustomerMod>
          <ListID>PASTE-LISTID-FROM-STEP-6</ListID>
          <EditSequence>PASTE-EDITSEQUENCE-FROM-STEP-6</EditSequence>
          <IsActive>false</IsActive>
        </CustomerMod>
      </CustomerModRq>
    </QBXMLMsgsRq>
  </QBXML>
  ```

  If you use the raw qbXML path:

  ```powershell
  $xmlHeaders = @{
      Authorization = "Bearer $token"
      'Content-Type' = 'application/xml'
  }

  Invoke-WebRequest "$base/api/qbxml" -Headers $xmlHeaders -Method Post -Body $qbxml
  ```

- [ ] Confirm the audit row and verify the chain

  ```powershell
  Get-Content '<Audit:Path>\audit.jsonl' -Tail 3
  & 'C:\Program Files\QbConnectService\QbConnectService.exe' --verify-audit
  ```

  Good:
  the last audit line is the `create_customer` write,
  `seq` is previous plus one (or `0` if first),
  `op` is `create_customer`,
  `args.name` matches the smoke customer name,
  `responseStatusCode` is `0`,
  `prevHash` matches the previous row's `hash` or 64 zeros for genesis,
  `hash` is present,
  and `--verify-audit` prints `audit chain OK`.

- [ ] Flip `AllowWrites` back to `false`

  Edit `appsettings.json`, set `Safety:AllowWrites=false`, restart, and confirm the guard is back on.

  ```powershell
  Restart-Service QbConnectService
  $health = Invoke-RestMethod "$base/api/health" -Headers $h
  $health.allowWrites
  ```

  Good:
  `health.allowWrites` is `false` again.
