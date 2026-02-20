---
description: Configure the gitx-mcp server for forge-flow — installs at project or user level
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
---

# Setup — Configure gitx-mcp for forge-flow

One-time setup that checks for the gitx-mcp binary, configures the MCP server connection, and verifies everything works.

Arguments provided: $ARGUMENTS

## Workflow

### Step 1: Check if Already Configured

Try to determine if the gitx MCP server is already available by checking:

1. Look for a `.mcp.json` in the current project root — read it and check for a `gitx` server entry
2. Read `~/.claude/settings.json` and check for a `gitx` server in `mcpServers`

If already configured at either level, report:
```
gitx-mcp is already configured at <project/user> level.
  Server name: gitx
  Command: <command>

Run /forge-flow:triage to verify the connection works.
```
Then ask: "Reconfigure anyway?" — if no, stop.

### Step 2: Check for gitx-mcp Binary

Run `command -v gitx-mcp` (or `where gitx-mcp` on Windows) to check if the binary is on PATH.

**If NOT found**, guide installation:

```
gitx-mcp binary not found on PATH.

Install it with one of:
  cargo install gitx-mcp          # From crates.io (requires Rust 1.75+)
  cargo install --git https://github.com/0xErgod/gitx-mcp   # From source
```

Ask the user: "Install now with cargo, or have you installed it elsewhere?"
- If they want to install: run `cargo install --git https://github.com/0xErgod/gitx-mcp`
- If installed elsewhere: ask for the full path to the binary

After installation, verify again with `command -v gitx-mcp`.
If still not found, stop: "Cannot find gitx-mcp. Ensure it's on your PATH and try again."

### Step 3: Gather Forge Credentials

Check if `GITEA_URL` and `GITEA_TOKEN` are already set as environment variables:
- Run `echo $GITEA_URL` and `echo $GITEA_TOKEN` (mask the token — only check if non-empty)
- Also check `FORGEJO_REMOTE_URL` and `FORGEJO_AUTH_TOKEN` (backward-compatible aliases)

**If environment variables are set:**
```
Detected forge credentials from environment:
  GITEA_URL: https://gitea.example.com
  GITEA_TOKEN: ****<last4>

Use these? (yes / enter different credentials)
```

**If NOT set**, ask the user:
1. "What is your Gitea/Forgejo instance URL?" (e.g., `https://gitea.example.com`)
2. "What is your API token?" (explain: generate one at `<url>/user/settings/applications` with `repo` scope)

Validate the URL format (must start with http:// or https://, no trailing slash).

### Step 4: Choose Installation Level

Ask the user:

```
Where should the MCP server be configured?

  1. This project only (.mcp.json)
     Best if you use multiple Gitea/Forgejo instances across different repos.
     Config stays with the project.

  2. All projects (~/.claude/settings.json)
     Best if you use one forge for everything.
     One-time setup, works in every repo.
```

### Step 5: Determine Credential Strategy

Ask the user how to store credentials:

```
How should credentials be stored?

  1. Environment variables (recommended)
     Config references $GITEA_URL and $GITEA_TOKEN from your shell environment.
     You manage the actual values in your .bashrc/.zshrc/.env file.

  2. Inline values
     URL and token are written directly into the config file.
     Simpler, but be careful not to commit tokens to git.
```

### Step 6: Write Configuration

**MCP server config block:**

With environment variables:
```json
{
  "mcpServers": {
    "gitx": {
      "command": "<path-to-gitx-mcp>",
      "env": {
        "GITEA_URL": "${GITEA_URL}",
        "GITEA_TOKEN": "${GITEA_TOKEN}"
      }
    }
  }
}
```

With inline values:
```json
{
  "mcpServers": {
    "gitx": {
      "command": "<path-to-gitx-mcp>",
      "env": {
        "GITEA_URL": "https://gitea.example.com",
        "GITEA_TOKEN": "actual-token-value"
      }
    }
  }
}
```

Use the full path to the binary from Step 2 (resolve with `which gitx-mcp` or `where gitx-mcp`).

**If project-level (.mcp.json):**
1. Check if `.mcp.json` already exists in the project root
   - If yes, read it and merge the `gitx` server into the existing `mcpServers` object
   - If no, create a new `.mcp.json` with the config
2. Check if `.mcp.json` is in `.gitignore`
   - If using inline tokens AND `.mcp.json` is NOT in `.gitignore`, warn:
     "Your .mcp.json contains an API token. Add it to .gitignore?"
   - If user agrees, append `.mcp.json` to `.gitignore`

**If user-level (~/.claude/settings.json):**
1. Read the existing `~/.claude/settings.json`
2. Merge the `gitx` server into the `mcpServers` section (create section if missing)
3. Write the updated file, preserving all other settings

### Step 7: Verify Connection

Tell the user:
```
Configuration written. Restart Claude Code or reload the session for the MCP server to activate.

After restarting, run /forge-flow:triage to verify the connection.
```

**Note:** MCP servers are loaded at session start. The newly written config won't take effect until the next session. Do NOT attempt to call gitx MCP tools in this session if they weren't available at start.

### Step 8: Summary

```
forge-flow setup complete!

  MCP server: gitx (gitx-mcp)
  Forge URL:  <url>
  Installed:  <project-level / user-level>
  Credentials: <environment variables / inline>

  Next steps:
  1. Restart Claude Code (or start a new session)
  2. Run /forge-flow:triage to scan for work

  Available commands after setup:
    /forge-flow:triage    — What should I work on?
    /forge-flow:claim N   — Pick up issue #N
    /forge-flow:submit    — Create PR from current branch
    /forge-flow:review N  — Review PR #N against issue goals
    /forge-flow:merge N   — Merge PR #N and close the loop
```

## Arguments

- `--project`: Skip the level prompt, install at project level
- `--user`: Skip the level prompt, install at user level
- `--env`: Skip the credential strategy prompt, use environment variables
- `--inline`: Skip the credential strategy prompt, use inline values

## Important

- NEVER write tokens to files that are tracked by git without warning the user
- When merging into existing config files, preserve ALL existing content — only add/update the `gitx` server entry
- If any step fails, report clearly what went wrong and what the user can do to fix it
- The server name MUST be `gitx` — all forge-flow commands reference MCP tools as `mcp__gitx__*`
