# Workstation Setup — MCP Servers and Credentials Sync

## Purpose

Claude Code's MCP server connections are configured per-workstation, not per-repo by default. This file documents what needs to be in place on every workstation so the Claude Code agent in this repo has the same toolset (Gmail, DocuSign, Foxit eSign, etc.) on every machine.

Without these in place, Claude on a fresh workstation can only read/write files and run scripts — it cannot send emails, dispatch DocuSign envelopes, or drive Foxit eSign.

## What needs to be replicated

### 1. Project-scoped MCP server config (preferred — portable via git)

Create a file at the repo root: **`c:/VSCode/tech-legal/tech-legal/.mcp.json`** containing the MCP server definitions for this repo. When this file exists in the repo, every workstation that opens it in Claude Code automatically loads the same MCP servers.

On the workstation that already has working MCP servers, copy the relevant `mcpServers` block from `~/.claude.json` into a new project-level `.mcp.json`. Example structure:

```json
{
  "mcpServers": {
    "docusign": {
      "command": "...",
      "args": ["..."],
      "env": {
        "DOCUSIGN_API_KEY": "${DOCUSIGN_API_KEY}",
        "DOCUSIGN_API_ACCOUNT_ID": "${DOCUSIGN_API_ACCOUNT_ID}"
      },
      "type": "stdio"
    },
    "foxit": {
      "command": "...",
      "args": ["..."],
      "env": {
        "FOXIT_API_KEY": "${FOXIT_API_KEY}"
      },
      "type": "stdio"
    },
    "gmail": {
      "command": "...",
      "args": ["..."],
      "type": "stdio"
    }
  }
}
```

Use `${ENV_VAR}` placeholders for secrets — the actual values come from `composio.env` (already in the repo) or the user's environment, never hard-coded into `.mcp.json`.

### 2. User-scoped MCP server config (per workstation, not portable)

If the MCP servers must remain user-scoped on the working machine, the equivalent block is in `~/.claude.json` under `mcpServers`. As of this writing, this workstation only has:

```json
"mcpServers": {
  "pencil":   { "command": "...", "args": ["--app", "desktop"], "type": "stdio" },
  "gitnexus": { "command": "cmd", "args": ["/c", "npx", "-y", "gitnexus@latest", "mcp"] }
}
```

The other workstation that has DocuSign / Foxit / Gmail working should export its `mcpServers` block from `~/.claude.json` and the new workstation should import it.

### 3. Permissions allow-list (`.claude/settings.json`)

The repo already has this file. It currently allows:

- WebFetch to `technijian.com`, `developers.docusign.com`, `www.docusign.com`, `community.docusign.com`, `github.com`, `zapier.com`
- Bash commands for `pip install`, `npm install`, `node templates/generate-docx.js`, `python -c "..."`, etc.
- Bash export of `COMPOSIO_API_KEY`

If the other workstation has additional permissions (e.g., `Bash(npx docusign...)`, `WebFetch(domain:foxit.com)`), copy those into the project's `.claude/settings.json` and commit.

### 4. Credentials and OAuth tokens

Two separate categories — handle differently:

| Item | Where it lives | Commit to repo? |
|---|---|---|
| API keys (DocuSign, Composio, Foxit) | `composio.env` at repo root | **Already tracked in repo** — note: this means keys are visible to anyone with repo access. Rotate if the repo is shared beyond intended audience. |
| Per-machine OAuth tokens (Gmail, Drive, Calendar) | `~/.claude/.credentials.json`, `~/.claude/mcp-needs-auth-cache.json` | **Never commit.** Each workstation re-runs the OAuth flow. |
| MCP needs-auth cache | `~/.claude/mcp-needs-auth-cache.json` | Never commit; regenerated automatically. |

After the MCP server config arrives on a new workstation:

- For Gmail: Claude will run `mcp__claude_ai_Gmail__authenticate`; user authorizes in the browser; Claude completes with `mcp__claude_ai_Gmail__complete_authentication`.
- For DocuSign: depends on the chosen server. If using Composio, it inherits `DOCUSIGN_API_KEY` from `composio.env`. If using a JWT-based DocuSign integration, the integrator-key/RSA-private-key files need to be on the workstation.
- For Foxit eSign: confirm whether it's an API-key model (use `composio.env`) or OAuth model (re-authorize per machine).

### 5. Required local installations

Some MCP servers are CLIs that need to be installed on the machine. Check the working workstation for:

- `npm install -g @modelcontextprotocol/server-docusign` (or whatever DocuSign MCP package is in use)
- `npm install -g @modelcontextprotocol/server-foxit` (or equivalent)
- Any Python packages needed by Composio
- Any Pencil / GitNexus binaries (already configured on this workstation)

Document these in this file once confirmed, so a fresh workstation can be brought up by reading this document alone.

## Steps to bring up a fresh workstation

1. Clone the repo: `git clone https://github.com/rjain557/tech-legal`
2. `cd tech-legal/tech-legal`
3. Open Claude Code in the repo directory.
4. **Pull the project's `.mcp.json`** (after the working workstation has committed it). Restart Claude Code.
5. **Authorize each OAuth-based MCP server** (Gmail, possibly Foxit) — Claude will guide through the auth flow.
6. **Verify** by asking Claude to list available DocuSign / Gmail / Foxit tools. They should appear in the deferred-tool list.
7. **Test** with a low-stakes action (e.g., list Gmail labels, read a DocuSign envelope status).

## Action items for the workstation that currently has these tools working

- [ ] Export the `mcpServers` section of `~/.claude.json`
- [ ] Create `c:/VSCode/tech-legal/tech-legal/.mcp.json` with the relevant server definitions, replacing hard-coded secrets with `${ENV_VAR}` placeholders
- [ ] Update this file (`docs/WORKSTATION_SETUP.md`) with the actual server names, commands, args, and any required CLI installations
- [ ] Commit `.mcp.json` and updated `WORKSTATION_SETUP.md` to `main`
- [ ] Confirm `composio.env` contains all required keys (DocuSign, Foxit, Gmail if applicable). If keys are missing for a service, document where to obtain them.

## Security note — composio.env

`composio.env` is currently tracked in this repo, which means API keys are visible to anyone with repo access (including past commits via git history). If the repo is shared with anyone outside Technijian's trusted ops team:

1. Rotate the affected API keys (Composio, DocuSign).
2. Add `composio.env` to a new `.gitignore`.
3. Run `git rm --cached composio.env` and commit.
4. Consider rewriting git history with `git filter-repo` to purge the keys from prior commits, then force-push.

If the repo is private to Technijian internal use, this is lower priority but still worth addressing as part of routine credential hygiene.
