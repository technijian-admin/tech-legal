# Coverage

## Primary Module Segments

- `payroll`

## Representative Read-First Procedures

- `Reporting.stp_xml_IndiaPayrollSlip_Get`
- `Payroll.stp_xml_IndiaExecEmailData_Get`
- `Payroll.stp_xml_BankInfo_Get`
- `Payroll.stp_xml_IndiaEmp_DropDown_Get`
- `dbo.stp_EOMApproval_Check`
- `dbo.stp_str_IndiaPayrollApproval_Check`

## Sensitive Data Warning

Payroll endpoints can expose employee, bank, and approval data. Minimize output and redact fields that are not directly needed.

## Handoffs

- Time or technician labor context: `client-portal-time-entries-approvals`
- Pure reporting rollups: `client-portal-reporting-analytics`
