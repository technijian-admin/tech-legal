# API Surface

Verified live against Swagger and catalog on `2026-04-10`.

## High-Level Facts

- Base URL: `https://api-clientportal.technijian.com`
- Swagger UI: `https://api-clientportal.technijian.com/swagger/index.html`
- OpenAPI JSON: `https://api-clientportal.technijian.com/swagger/v1/swagger.json`
- Swagger path count observed live: `998`
- Database aliases observed live: `client-portal`, `teams`, `client-portal-teams`
- `catalog/guide` count observed live: `100`
- `catalog/objects` count observed live: `990`

## Module Guide Snapshot

| Segment | Module | Business Area | Endpoints | Read | Write |
|---|---|---|---:|---:|---:|
| `dbo` | `dbo` | XML Contract Organization | 162 | 129 | 33 |
| `tickets` | `Tickets` | Tickets | 102 | 64 | 38 |
| `dir` | `Dir` | Directory | 101 | 66 | 35 |
| `invoices` | `Invoices` | Invoices | 82 | 55 | 27 |
| `lookups` | `Lookups` | XML Contracts Asset | 55 | 40 | 15 |
| `users` | `Users` | Users | 43 | 30 | 13 |
| `payroll` | `Payroll` | Payroll | 37 | 17 | 20 |
| `contract` | `Contract` | Contract | 36 | 28 | 8 |
| `projectproposal` | `ProjectProposal` | Project Proposal | 33 | 26 | 7 |
| `timeentry` | `TimeEntry` | Time Entry | 30 | 13 | 17 |
| `portalconfig` | `PortalConfig` | Portal Config | 26 | 13 | 13 |
| `internal` | `Internal` | XML Invoice Recur | 24 | 7 | 17 |
| `meeting` | `Meeting` | Meeting | 22 | 17 | 5 |
| `treedata` | `TreeData` | Tree Data | 18 | 14 | 4 |
| `reports` | `Reports` | Reports | 17 | 17 | 0 |
| `pod` | `POD` | POD | 15 | 11 | 4 |
| `email` | `Email` | Email | 14 | 6 | 8 |
| `digitalsignature` | `DigitalSignature` | Digital Signature | 12 | 2 | 10 |
| `filter` | `Filter` | XML Proposal | 12 | 9 | 3 |
| `estimate` | `Estimate` | Estimate | 11 | 9 | 2 |
| `approveticket` | `ApproveTicket` | Approve Ticket | 9 | 4 | 5 |
| `cardpointe` | `CardPointe` | Card Pointe | 9 | 3 | 6 |
| `teams` | `Teams` | Teams | 9 | 5 | 4 |
| `eom` | `EOM` | EOM | 7 | 2 | 5 |
| `msteam` | `MSTeam` | MS Team | 7 | 7 | 0 |
| `attachment` | `Attachment` | Attachment | 6 | 6 | 0 |
| `automated` | `Automated` | Automated | 6 | 4 | 2 |
| `excel` | `Excel` | Excel | 6 | 6 | 0 |
| `fax` | `Fax` | Fax | 6 | 3 | 3 |
| `prtg` | `PRTG` | PRTG | 6 | 6 | 0 |
| `assets` | `Assets` | Assets | 5 | 3 | 2 |
| `salesrep` | `SalesRep` | Sales Rep | 5 | 4 | 1 |
| `workshift` | `Workshift` | Workshift | 5 | 4 | 1 |
| `monthly` | `Monthly` | Monthly | 4 | 2 | 2 |
| `sms` | `SMS` | SMS | 4 | 3 | 1 |
| `technijiandirectory` | `TechnijianDirectory` | Technijian Directory | 4 | 3 | 1 |
| `list` | `List` | XML Recurring Type | 3 | 3 | 0 |
| `menu` | `Menu` | Menu | 3 | 3 | 0 |
| `security` | `Security` | Security | 3 | 3 | 0 |
| `chatgpt` | `ChatGPT` | Chat GPT | 2 | 1 | 1 |
| `clients` | `Clients` | Clients | 2 | 2 | 0 |
| `cred` | `Cred` | Cred | 2 | 2 | 0 |
| `notify` | `Notify` | Notify | 2 | 2 | 0 |
| `outlook` | `Outlook` | Outlook | 2 | 2 | 0 |
| `pricelist` | `PriceList` | Price | 2 | 1 | 1 |
| `quickbook` | `Quickbook` | Quickbook | 2 | 2 | 0 |
| `recurringticketsda` | `RecurringTicketsDA` | Recurring Tickets DA | 2 | 1 | 1 |
| `setting` | `Setting` | Setting | 2 | 0 | 2 |
| `threecxsms` | `ThreeCXSMS` | Three CXSMS | 2 | 2 | 0 |
| `utilitty` | `Utilitty` | Utilitty | 2 | 0 | 2 |

## Extra Raw Swagger Module Segments

The raw path inventory also exposed low-volume segments that did not show up in the `catalog/modules/guide` snapshot:

- `cache`
- `docusign`
- `files`
- `invoice`
- `location`
- `phone`
- `sales`
- `sites`
- `teamsportal`

Treat these as valid coverage areas and map them using [domain-map.md](domain-map.md).
