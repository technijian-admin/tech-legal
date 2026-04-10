# Auth

## Credential Location

Default key file:
- `/mnt/c/Users/rjain/OneDrive - Technijian, Inc/Documents/VSCODE/keys/client-portal.md`

Environment-variable overrides:
- `CLIENT_PORTAL_USERNAME`
- `CLIENT_PORTAL_PASSWORD`
- `CLIENT_PORTAL_KEYS_FILE`

## Verified Live On 2026-04-10

- Token endpoint: `POST https://api-clientportal.technijian.com/api/auth/token`
- Request body:

```json
{
  "userName": "<email>",
  "password": "<password>"
}
```

- Response shape:

```json
{
  "tokenType": "Bearer",
  "expiresIn": 4298,
  "scope": "api://1cb85b95-8f51-4b69-a8a9-834c8d3ce0e1/access_as_user",
  "accessToken": "<jwt>"
}
```

- `GET /api/auth/token` returns `405 Method Not Allowed`.
- Missing credentials return `400` with `UserName and Password are required.`
- Authenticated `GET /api/system/health` returned `status = ok`.

## Helper Script Behavior

- `scripts/client_portal_api.py` caches the bearer token in `~/.cache/client-portal/token.json`.
- The script refreshes the token when it is near expiry.
- The script never prints the password.
