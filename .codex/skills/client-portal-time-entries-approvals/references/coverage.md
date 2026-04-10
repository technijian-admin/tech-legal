# Coverage

## Primary Module Segments

- `timeentry`
- `approveticket`
- `workshift`
- `pod`
- `monthly`
- `eom`

## Representative Entry Points

- `dbo.sp_TicketEntry_List`
- `dbo.ApproveTimeEntry`
- `dbo.GET_APPROVETIMEENTRY_LIST`
- `dbo.stp_xml_PODUser_Tech_Workshift_Get`
- `dbo.stp_xml_PODUser_Tech_Workshift_Get_V2`
- `dbo.stp_xml_WS_Tech_Workshift_Get`
- `dbo.stp_xml_WS_Tech_Workshift_Save` (write)

## Search Guidance

Use the prompt noun plus one of these modifiers:

- `list`
- `detail`
- `approval`
- `error`
- `schedule`
- `calendar`

## Handoffs

- Ticket context: `client-portal-tickets-service-delivery`
- Payroll and formal payroll approval: `client-portal-payroll-hr-ops`
