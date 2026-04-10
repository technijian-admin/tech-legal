# Coverage

## Primary Module Segments

- `invoices`
- `internal`
- `invoice`
- `cardpointe`
- `quickbook`

## Representative Read-First Procedures

- `dbo.Get_Clients_Invoices`
- `dbo.Get_Monthly_Invoice`
- `dbo.Get_Weekly_Invoice`
- `dbo.Get_Weekly_Invoice_Preview`
- `dbo.Get_Weekly_Proposal_Invoice`
- `Automated.stp_bool_InvoiceGeneration_Check`
- `Automated.stp_xml_InvoiceGeneration_List_Get`

## Write-Sensitive Examples

- `dbo.stp_Create_Contract_Invoice`
- `dbo.stp_Create_Invoices_Installment`
- `dbo.stp_Create_Partial_Contract_Invoice`
- `dbo.stp_Create_Proposal_FixRate_Contract_Invoice`

## Handoffs

- Contract context: `client-portal-clients-contracts`
- Proposal and estimate context: `client-portal-proposals-estimates-sales`
