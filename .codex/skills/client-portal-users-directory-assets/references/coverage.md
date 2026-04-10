# Coverage

## Primary Module Segments

- `users`
- `dir`
- `technijiandirectory`
- `assets`
- `location`
- `sites`
- `phone`

## Representative Read-First Procedures

- `dbo.stp_Get_User_List`
- `dbo.GET_Directory_Filters`
- `dbo.stp_Get_Client_Location_Users`
- `dbo.stp_Get_Client_Users`
- `dbo.stp_Get_Location_Users`
- `dbo.sp_Validate_User`
- `dbo.stp_Get_Asset_Details`
- `dbo.stp_str_Usr_Email_Get`

## Sensitive Data Warning

`stp_Get_User_List` returns columns that can include password or token-like values. Do not echo those back unless the user explicitly needs them and it is safe to do so.

## Handoffs

- Client or contract joins: `client-portal-clients-contracts`
- Communications lookups: `client-portal-communications-signatures`
