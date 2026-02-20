---
description: Submit current work as a PR linked to the originating issue
allowed-tools: Bash, Read, Grep, Glob, mcp__gitx__issue_get, mcp__gitx__issue_comment_create, mcp__gitx__pr_create, mcp__gitx__pr_list, mcp__gitx__label_list, mcp__gitx__commit_list, mcp__gitx__commit_compare, mcp__gitx__user_get_me, mcp__gitx__branch_list
---

# Submit — Package work as a PR

Create a pull request from the current feature branch, linking it to the originating issue with a structured description that maps implementation to requirements.

Arguments provided: $ARGUMENTS

## Prerequisites

This command requires the `gitx-mcp` MCP server configured with server name `gitx`. You should be on a feature branch with commits ahead of the base branch.

## Workflow

### Step 1: Validate Current State

1. Run `git branch --show-current` to get the current branch
2. Parse the branch name to extract issue number and type (pattern: `<type>/<number>-<slug>`)
3. If the branch doesn't match the pattern, ask: "Can't detect issue number from branch `<name>`. Which issue does this work address? (Enter issue number or 'none')"
4. If on `main`/`master`, stop: "You're on the default branch. Switch to your feature branch first."
5. Run `git status --porcelain` — if there are uncommitted changes, warn: "You have uncommitted changes. Commit or stash them before submitting."

### Step 2: Gather Context

Fetch in parallel where possible:

1. **Issue details** — `issue_get` with the extracted issue number (if any)
2. **Current user** — `user_get_me`
3. **Detect base branch** — `git remote show origin | grep 'HEAD branch'` to find the default branch
4. **Commit log** — `git log origin/<base>..HEAD --oneline` to see all commits on this branch
5. **Full diff stats** — `git diff origin/<base>..HEAD --stat` to understand scope
6. **Labels** — `label_list` to apply matching labels from the issue
7. **Existing PRs** — `pr_list` with `state: "open"` to check if a PR already exists for this branch

### Step 3: Check for Existing PR

If an open PR already exists for this branch (matching head branch name):
- Report: "PR #N already exists for this branch: `<title>`. Update it instead?"
- If user confirms, stop (they should push new commits and optionally use `pr_edit`)
- If no existing PR, proceed

### Step 4: Push Branch to Remote

1. Check if the branch has a remote tracking branch: `git rev-parse --abbrev-ref @{upstream} 2>/dev/null`
2. If not pushed yet: `git push -u origin <branch-name>`
3. If already pushed: `git push` to ensure remote is up to date

### Step 5: Build PR Description

Construct the PR body with this structure:

```markdown
## Summary

<2-4 sentence description of what this PR does and why>

## Linked Issue

<Closes/Addresses> #<issue-number>

## Requirements Checklist

Based on Issue #<N>: "<issue-title>":

- [x] <requirement 1 from issue — addressed>
- [x] <requirement 2 from issue — addressed>
- [ ] <requirement 3 from issue — NOT addressed (explain why or mark as follow-up)>

## Changes

<Brief description of the key changes, organized by area>

## Testing

<What testing was done or what tests were added>
```

**Linking keywords:**
- Use `Closes #N` if all issue requirements are addressed (the default)
- Use `Addresses #N` if this is partial work (use `--addresses` flag or if checklist has unchecked items)

**PR Title:**
- Format: `<type>: <concise description>` (matching conventional commit style)
- Derive type from the branch prefix
- Keep under 72 characters
- Example: `fix: resolve Safari login failure after OAuth redirect`

### Step 6: Create the PR

Call `pr_create` with:
- `title`: The generated PR title
- `head`: Current branch name
- `base`: Default branch (main/master)
- `body`: The generated PR body
- `labels`: Copy label IDs from the linked issue (fetch current issue labels, map to IDs via `label_list`)
- `assignees`: Current user

### Step 7: Update the Issue

Call `issue_comment_create` on the linked issue:

```markdown
**PR submitted:** #<pr-number> — `<pr-title>`

Branch `<branch-name>` → `<base-branch>`
Commits: <N> | Files changed: <M>
```

### Step 8: Report

Print the result:

```
PR #<N> created: <title>
  <forge-url>/pulls/<N>

  Branch: <head> → <base>
  Linked: Issue #<issue-number>
  Commits: <count>
  Files: <count>
  Labels: <labels>

  Next: Ask a collaborator to review, or run /forge-flow:review <N> for self-review.
```

## Arguments

- `--draft`: Create as a draft PR (not ready for review)
- `--addresses`: Use "Addresses" instead of "Closes" (for partial work)
- `--base <branch>`: Override the target base branch (default: main/master)
- `--title <title>`: Override the auto-generated PR title
- `--reviewer <username>`: Request a specific reviewer (added to assignees)

## Important

- NEVER create a PR without the user explicitly invoking this command
- If there are no commits ahead of base, stop: "No commits to submit. Make changes first."
- If push fails (e.g., no remote access), report the error and stop
- Always verify the PR was created successfully by checking the response
- The requirements checklist is key — it's what makes the review step effective. Map every requirement from the issue to a checkbox.
