# Query Recipes

These are seed workflows, not the only valid paths.

## Active Clients

1. Execute `dbo.stp_Get_Client_List`.
2. Filter `IsActive == true`.
3. Return `ClientID`, `ClientCode`, `ClientName`.

## Contract List

1. Execute `dbo.GET_CONTRACTS_LIST` with default body or explicit `UserID` / `FilterID`.
2. Filter `Is_Active_Contract == "true"` or `Active == "true"` depending on the use case.
3. Keep `Contract_ID`, `Contract_Name`, `Client_ID`, `Location_name`, `ClientName`, `From_Date`, `To_Date`.

## Active Clients With Active Contracts

1. Execute `dbo.stp_Get_Client_List`.
2. Execute `dbo.GET_CONTRACTS_LIST`.
3. Keep only client rows where `IsActive == true`.
4. Keep only contract rows where `Is_Active_Contract == "true"` or `Active == "true"`.
5. Join on `ClientID == Client_ID`.
6. Return unique clients with `ClientID`, `ClientCode`, `ClientName`.

Caveat:
- Many active contract rows are location-linked and come back with `Client_ID = null`, so a direct join undercounts total active contract coverage.
- When completeness matters, follow up with contract-directory procedures such as `dbo.stp_xml_GetContractForDirectory` and a directory/location lookup from the users-directory-assets domain.

The helper script bakes in this recipe:

```bash
python3 scripts/client_portal_api.py recipe active-client-contracts --limit 50
```

## Users For A Client Or Location

1. Start in the users-directory-assets skill.
2. Search for `client users`, `location users`, or `directory users`.
3. Read the guide entry before execution because many user procedures expose sensitive fields.
4. Redact password, token, and credential columns unless the user explicitly needs them.

## Ticket Time Entries

1. Execute `dbo.sp_TicketEntry_List`.
2. Pass `TicketID` when known.
3. If the result is empty, verify ticket ID and check whether time entries live in a different workflow or date slice.
