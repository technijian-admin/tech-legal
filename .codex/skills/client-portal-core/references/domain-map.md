# Domain Map

Use this map when a prompt is phrased as business work rather than raw module names.

| Raw Module Segment | Primary Skill | Notes |
|---|---|---|
| `dbo` | `client-portal-core` | Catchall bucket. Start in core, then hand off by business area. |
| `clients` | `client-portal-clients-contracts` | Client master lists and basic client metadata. |
| `contract` | `client-portal-clients-contracts` | Contract lists, reports, directory-linked contract lookups. |
| `lookups` | `client-portal-clients-contracts` | Shared contract and asset lookups. |
| `list` | `client-portal-clients-contracts` | Recurring type lists; often cross-linked with billing. |
| `projectproposal` | `client-portal-proposals-estimates-sales` | Proposal lists, detail, audit, validation. |
| `estimate` | `client-portal-proposals-estimates-sales` | Estimate lists, estimate detail, proposal-estimate joins. |
| `filter` | `client-portal-proposals-estimates-sales` | Proposal and dashboard filters. |
| `salesrep` | `client-portal-proposals-estimates-sales` | Sales-rep-related lookups. |
| `sales` | `client-portal-proposals-estimates-sales` | Low-volume sales routes from Swagger. |
| `pricelist` | `client-portal-proposals-estimates-sales` | Shared with billing, but owned here for quote/proposal workflows. |
| `tickets` | `client-portal-tickets-service-delivery` | Ticket detail, status, client-facing ticket views, scheduling history. |
| `attachment` | `client-portal-tickets-service-delivery` | Ticket and email attachments; often used with tickets or email. |
| `meeting` | `client-portal-tickets-service-delivery` | Meeting/task/ticket-adjacent service delivery data. |
| `recurringticketsda` | `client-portal-tickets-service-delivery` | Recurring ticket history and notes. |
| `timeentry` | `client-portal-time-entries-approvals` | Ticket time entries and time-entry detail. |
| `approveticket` | `client-portal-time-entries-approvals` | Time approval workflows. |
| `workshift` | `client-portal-time-entries-approvals` | Shift detail and workshift lookups. |
| `pod` | `client-portal-time-entries-approvals` | POD staffing and schedule context. |
| `monthly` | `client-portal-time-entries-approvals` | Monthly operational grids tied to service delivery. |
| `eom` | `client-portal-time-entries-approvals` | End-of-month approval workflows tied to labor/time. |
| `users` | `client-portal-users-directory-assets` | User list, validation, client/location user views. |
| `dir` | `client-portal-users-directory-assets` | Directory and related views. |
| `technijiandirectory` | `client-portal-users-directory-assets` | Internal Technijian directory. |
| `assets` | `client-portal-users-directory-assets` | Asset detail and monthly asset grids. |
| `location` | `client-portal-users-directory-assets` | Low-volume location routes from Swagger. |
| `sites` | `client-portal-users-directory-assets` | Low-volume site routes from Swagger. |
| `phone` | `client-portal-users-directory-assets` | Low-volume phone routes from Swagger. |
| `invoices` | `client-portal-invoices-billing-payments` | Invoice lists, previews, proposal invoices, invoice generation. |
| `internal` | `client-portal-invoices-billing-payments` | Invoice recurrence and internal billing procedures. |
| `invoice` | `client-portal-invoices-billing-payments` | Low-volume invoice routes from Swagger. |
| `cardpointe` | `client-portal-invoices-billing-payments` | Payment profiles and settlement/payment flows. |
| `quickbook` | `client-portal-invoices-billing-payments` | QuickBooks-facing billing/report data. |
| `email` | `client-portal-communications-signatures` | Email lookup/send-related procedures. |
| `digitalsignature` | `client-portal-communications-signatures` | Signature workflows and document signing status. |
| `fax` | `client-portal-communications-signatures` | Fax workflows. |
| `sms` | `client-portal-communications-signatures` | SMS workflows. |
| `teams` | `client-portal-communications-signatures` | Teams collaboration. |
| `msteam` | `client-portal-communications-signatures` | Microsoft Teams read-only endpoints. |
| `outlook` | `client-portal-communications-signatures` | Outlook integration surfaces. |
| `threecxsms` | `client-portal-communications-signatures` | 3CX SMS configuration and lookups. |
| `notify` | `client-portal-communications-signatures` | Notification-related procedures. |
| `docusign` | `client-portal-communications-signatures` | Low-volume DocuSign routes from Swagger. |
| `teamsportal` | `client-portal-communications-signatures` | Low-volume Teams Portal routes from Swagger. |
| `files` | `client-portal-communications-signatures` | Shared file surfaces used by send/sign/collab workflows. |
| `portalconfig` | `client-portal-admin-automation-security` | Role, privilege, credential, mapping, plugin configuration. |
| `automated` | `client-portal-admin-automation-security` | Automation settings and generated-process plugins. |
| `security` | `client-portal-admin-automation-security` | Security-related lists. |
| `menu` | `client-portal-admin-automation-security` | Menu/configuration lists. |
| `setting` | `client-portal-admin-automation-security` | Low-volume settings writes. |
| `cred` | `client-portal-admin-automation-security` | Credential retrieval endpoints. |
| `cache` | `client-portal-admin-automation-security` | Token/session cache routes. |
| `utilitty` | `client-portal-admin-automation-security` | Utility saves and email-log helpers. |
| `chatgpt` | `client-portal-admin-automation-security` | Prompt/config storage for ChatGPT defaults. |
| `reports` | `client-portal-reporting-analytics` | Cross-domain reports. |
| `treedata` | `client-portal-reporting-analytics` | Tree views for clients, locations, tickets, invoices, assets. |
| `excel` | `client-portal-reporting-analytics` | Report exports such as payroll slips. |
| `prtg` | `client-portal-reporting-analytics` | Monitoring/reporting data. |
| `payroll` | `client-portal-payroll-hr-ops` | Payroll, bank info, India employee flows, EOM payroll approval. |
