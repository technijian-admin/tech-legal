# Coverage

## Primary Module Segments

- `projectproposal`
- `estimate`
- `filter`
- `salesrep`
- `sales`
- `pricelist`

## Representative Read-First Procedures

- `dbo.GET_PROPOSALS_LIST`
- `dbo.GET_PROJECT_PROPOSAL`
- `dbo.GET_PROPOSALS_LIST_VERSIONS`
- `dbo.stp_Get_Audit_Project_Proposal`
- `dbo.Get_Estimate_List`
- `dbo.Get_Estimate_Verion_List`
- `dbo.stp_Get_Estimate`
- `dbo.stp_xml_DDL_Org_Loc_Prop_Est_Get`

## Search Guidance

If a proposal or estimate path is not obvious, search using the exact nouns from the prompt plus one of these modifiers:

- `list`
- `report`
- `audit`
- `version`
- `detail`
- `sign`
- `validate`

## Handoffs

- Contract conversion or contract-side proposal links: `client-portal-clients-contracts`
- Proposal invoices or billing: `client-portal-invoices-billing-payments`
