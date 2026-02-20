---
description: Claim an issue — assign it, create a feature branch, and set up working context
allowed-tools: Bash, Read, Grep, Glob, mcp__gitx__issue_get, mcp__gitx__issue_edit, mcp__gitx__issue_comment_create, mcp__gitx__label_list, mcp__gitx__label_create, mcp__gitx__user_get_me, mcp__gitx__branch_list
---

# Claim — Pick up an issue and start working

Assign an issue to yourself, create a properly named feature branch, and set up the working context so you can immediately start implementing.

Arguments provided: $ARGUMENTS

## Prerequisites

This command requires the `gitx-mcp` MCP server configured with server name `gitx`. The first argument should be an issue number.

## Forge Content Formatting Rules

**CRITICAL — These rules apply to ALL text passed to MCP tools (issue_comment_create body):**

### Newlines
You MUST use actual newlines in strings passed to MCP tools, NEVER escaped `\n` characters. The API receives the string exactly as you pass it. Literal `\n` will render as visible text, not line breaks.

### Agent Signature
Every issue comment MUST end with `[agent comment]` on its own line. Nothing after it.

## Workflow

### Step 1: Parse Arguments

Extract the issue number from `$ARGUMENTS`. If no issue number is provided, tell the user:
"Usage: `/forge-flow:claim <issue-number>`. Run `/forge-flow:triage` first to see available issues."

### Step 2: Fetch Issue Details

1. Call `user_get_me` to get the current username
2. Call `issue_get` with the provided issue number
3. Verify the issue exists and is open. If closed, warn: "Issue #N is already closed. Reopen it first or pick another."
4. Check if the issue is already assigned to someone else. If so, warn: "Issue #N is assigned to <user>. Claim anyway?" and wait for confirmation.

### Step 3: Determine Branch Name

Construct the branch name from the issue:

**Pattern:** `<type>/<issue-number>-<slug>`

**Type mapping from labels:**
- Labels containing "bug", "fix", "defect" → `fix`
- Labels containing "feature", "enhancement", "feat" → `feat`
- Labels containing "docs", "documentation" → `docs`
- Labels containing "refactor" → `refactor`
- Labels containing "perf", "performance" → `perf`
- Labels containing "test" → `test`
- Labels containing "chore", "maintenance" → `chore`
- No matching label → `feat` (default)

**Slug:** Derive from the issue title:
- Lowercase
- Replace spaces and special characters with hyphens
- Truncate to 40 characters max
- Remove trailing hyphens

**Examples:**
- Issue #31 "Login fails on Safari" (labeled "bug") → `fix/31-login-fails-on-safari`
- Issue #15 "User dashboard" (labeled "feature") → `feat/15-user-dashboard`
- Issue #28 "Export to CSV" (no label) → `feat/28-export-to-csv`

### Step 4: Ensure "in-progress" Label Exists

1. Call `label_list` to check if an "in-progress" label exists
2. If not found, create it with `label_create`:
   - name: `in-progress`
   - color: `#0052cc` (blue)
   - description: `Work is actively being done on this issue`

### Step 5: Update Issue on Forge

1. Call `issue_edit` to:
   - Add the current user to assignees (preserve existing assignees — fetch current list from issue_get, append self)
   - Add the "in-progress" label (preserve existing labels — fetch current IDs, append in-progress ID)
2. Call `issue_comment_create` to post:

```markdown
**Work started** on branch `<branch-name>`

Claimed by @<username> via forge-flow.

[agent comment]
```

### Step 6: Create Branch and Checkout

1. Ensure working tree is clean: run `git status --porcelain`. If dirty, warn: "You have uncommitted changes. Stash or commit them first?"
2. Fetch latest: `git fetch origin`
3. Create and checkout the branch from the default branch:
   ```
   git checkout -b <branch-name> origin/main
   ```
   (Use `origin/master` if that's the default branch — check with `git remote show origin | grep 'HEAD branch'`)

### Step 7: Present Working Context

Print a summary the user can act on immediately:

```
Claimed Issue #<N>: "<title>"
Branch: <branch-name>
Assigned to: <username>

Requirements:
<issue body, formatted as bullet points if possible>

Labels: <label1>, <label2>
Milestone: <milestone name> (due <date>) — or "None"
```

If the issue body is long (>30 lines), summarize the key requirements and note "Full issue body available on the forge."

## Arguments

- `<issue-number>` (required): The issue to claim
- `--branch <name>`: Override the auto-generated branch name
- `--no-assign`: Don't assign the issue (useful if you just want the branch)

## Important

- NEVER claim an issue without the user explicitly invoking this command
- If `git checkout -b` fails because the branch already exists, ask: "Branch `<name>` already exists. Switch to it instead?"
- If the user is already on a feature branch, warn: "You're currently on `<branch>`. Switch to the new branch?"
- Preserve existing assignees and labels when editing — `issue_edit` replaces them, so always merge with current values
