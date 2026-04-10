# Coverage

## Primary Module Segments

- `portalconfig`
- `automated`
- `security`
- `menu`
- `setting`
- `cred`
- `cache`
- `utilitty`
- `chatgpt`

## Representative Read-First Procedures

- `dbo.sp_Role_List`
- `dbo.stp_GetAll_Privileges`
- `dbo.stp_GetAllUserRolePrivilege`
- `dbo.stp_Get_Default_List_By_Group_ID`
- `dbo.stp_Get_PRTG_Device_Sensor_Mapping`
- `dbo.stp_Get_QBMapping`
- `dbo.stp_xml_Docusign_Cred_Get`
- `dbo.stp_xml_EmailProcessPlugin_Get`

## Sensitive Data Warning

Many portal-config and cred endpoints return secrets, API keys, or mapping data that should be summarized rather than copied verbatim.

## Handoffs

- Messaging or signature workflows: `client-portal-communications-signatures`
- Billing-side QuickBooks context: `client-portal-invoices-billing-payments`
