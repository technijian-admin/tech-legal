# Coverage

## Primary Module Segments

- `reports`
- `treedata`
- `excel`
- `prtg`
- `dbo` (read-mostly report and dashboard catchalls)

## Representative Read-First Procedures

- `dbo.stp_TreeView`
- `dbo.stp_Get_Contract_Report_NEW`
- `dbo.stp_Get_Asset_Details`
- `dbo.stp_xml_InvWeekly_Org_Clt_Inv_Weekly_Report_Get`
- `Reporting.stp_xml_IndiaPayrollSlip_Get`

## Usage Pattern

- Search first
- Read the guide entry
- Execute with the guide template
- Join multiple result sets in-memory when the report spans clients, contracts, invoices, users, or time entries

## Handoffs

- Domain-specific cleanup of results should go back to the owning skill from `client-portal-core/references/domain-map.md`
