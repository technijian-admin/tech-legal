# Coverage

## Primary Module Segments

- `clients`
- `contract`
- `lookups`
- `list`

## Verified Entry Points

- `dbo.stp_Get_Client_List` -> list clients, no parameters
- `dbo.GET_CONTRACTS_LIST` -> list contracts, optional `UserID`, `FilterID`
- `dbo.GetAllContracts` -> broad contract read, no parameters
- `dbo.stp_Get_Contract_Report_NEW` -> contract report by `Contract_ID`
- `dbo.stp_xml_GetContractForDirectory` -> directory-linked contract lookup by `DirID`

## Common Workflows

- Active clients: run `stp_Get_Client_List`, filter `IsActive == true`
- Active clients with active contracts: join `stp_Get_Client_List` and `GET_CONTRACTS_LIST` on `ClientID == Client_ID`
- Contract report by ID: run `stp_Get_Contract_Report_NEW` with `Contract_ID`
- Directory-to-contract lookup: run `stp_xml_GetContractForDirectory` with `DirID`

## Data Caveat

Many active contract rows are location-linked and return `Client_ID = null`, so direct client joins undercount total active contract coverage. Say that explicitly when reporting “all clients with an active contract.”

## Handoffs

- Users or directory joins: `client-portal-users-directory-assets`
- Invoice or billing impact of contracts: `client-portal-invoices-billing-payments`
