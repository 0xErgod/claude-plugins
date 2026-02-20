---
description: Scan issues, PRs, commits, CI, and notifications to recommend what to work on next
allowed-tools: Bash, Read, Grep, Glob, mcp__gitx__user_get_me, mcp__gitx__issue_list, mcp__gitx__issue_get, mcp__gitx__pr_list, mcp__gitx__pr_get, mcp__gitx__notification_list, mcp__gitx__milestone_list, mcp__gitx__milestone_get, mcp__gitx__commit_list, mcp__gitx__branch_list, mcp__gitx__label_list, mcp__gitx__actions_run_list
---

# Triage — "What should I work on?"

Scan the full repository state across the forge and local git to produce a prioritized, actionable work recommendation.

Arguments provided: $ARGUMENTS

## Prerequisites

This command requires the `gitx-mcp` MCP server configured with server name `gitx`. If MCP tools are not available, inform the user and stop.

## Workflow

### Step 1: Establish Identity and Repo Context

1. Call `user_get_me` to identify the authenticated user
2. Read the auto-detected repo context (owner/repo) — all subsequent MCP calls can omit owner/repo params
3. Run `git branch --show-current` locally to know the current branch
4. Run `git log --oneline -10` locally to understand recent local momentum

### Step 2: Gather Forge State (parallel where possible)

Fetch all of the following. Use pagination if needed (default limit 20 is fine for triage).

| Data Source | MCP Tool | Parameters |
|-------------|----------|------------|
| Open issues | `issue_list` | `state: "open"` |
| Open PRs | `pr_list` | `state: "open"` |
| Notifications | `notification_list` | `status: "unread"` |
| Milestones | `milestone_list` | `state: "open"` |
| Labels | `label_list` | (for decoding priority/type labels) |
| Branches | `branch_list` | (for cross-referencing with issues) |
| CI runs | `actions_run_list` | `limit: 5` |
| Recent commits | `commit_list` | `limit: 10` |

### Step 3: Cross-Reference and Classify

For each open item, determine its **category** and **urgency**:

**Categories (in priority order):**

1. **CI_BROKEN** — Recent CI run failed on the default branch. Fixing builds unblocks everyone.
2. **REVIEW_REQUESTED** — Open PRs assigned to you or requesting your review. Quick wins that unblock others.
3. **NOTIFICATION** — Unread mentions, assignments, or review requests. Someone is waiting on you.
4. **STALE_PR** — Open PRs with no activity for 3+ days. Might need a nudge or review.
5. **P1_BUG** — Issues labeled as bugs with high-priority/P1/critical labels, especially with milestone deadlines.
6. **MILESTONE_DUE** — Issues in milestones with approaching due dates (within 7 days).
7. **ASSIGNED_TO_YOU** — Issues assigned to the current user but not yet started (no branch exists).
8. **UNCLAIMED_BUG** — Unassigned bug issues.
9. **UNCLAIMED_FEAT** — Unassigned feature issues.
10. **ORPHANED_BRANCH** — Local or remote branches matching `type/number-*` pattern with no corresponding open PR.
11. **LOW_PRIORITY** — Everything else.

**Cross-reference logic:**
- Match branches to issues by extracting issue numbers from branch names (pattern: `<type>/<number>-<slug>`)
- Match PRs to issues by checking PR body for `Closes #N`, `Fixes #N`, `Addresses #N` references
- Identify issues that already have branches or PRs (mark as "in progress")
- Identify branches that have no PR yet (potential stale work)

### Step 4: Rank and Present

Present findings as a ranked table, grouped by category:

```
Forge Triage for <owner>/<repo>
Authenticated as: <username>
Current branch: <branch>

NEEDS ATTENTION:
  1. [CI_BROKEN]    Build #42 failed on main — "test suite: 3 failures"
  2. [REVIEW]       PR #23 "Add rate limiting" — assigned to you, CI green, 2d old
  3. [NOTIFICATION] Issue #31 — you were mentioned 4h ago

READY TO WORK:
  4. [P1 BUG]       Issue #31 "Login fails on Safari" — milestone v3.1 (due Thu), unclaimed
  5. [MILESTONE]    Issue #28 "Export to CSV" — milestone v3.1 (due Thu), assigned to you, no branch
  6. [BUG]          Issue #44 "Broken pagination" — unclaimed

BACKLOG:
  7. [FEAT]         Issue #15 "User dashboard" — unclaimed
  8. [FEAT]         Issue #22 "Dark mode" — unclaimed

STALE:
  9. [STALE PR]     PR #19 "Fix memory leak" — no activity for 8d
 10. [ORPHAN]       Branch fix/7-cors-headers — no PR, 12d old
```

### Step 5: Recommend Next Action

Based on the ranking, suggest a specific next action:

- If CI is broken: "Build is red on main. Recommend investigating build #42 first."
- If PRs need review: "PR #23 is waiting for your review. Quick `/forge-flow:review 23` would unblock the author."
- If assigned work exists: "You're assigned to Issue #28 but haven't started. Run `/forge-flow:claim 28` to begin."
- If urgent bugs exist: "P1 bug #31 is unclaimed with a Thursday deadline. Consider `/forge-flow:claim 31`."
- If nothing urgent: "Backlog is clear. Issue #15 is the highest-value unclaimed feature."

Always end with a concrete command suggestion the user can act on.

## Arguments

- `--all`: Include closed issues/PRs in the scan (shows full picture)
- `--mine`: Only show items assigned to or involving the current user
- `--milestone <name>`: Filter to a specific milestone

## Important

- Do NOT make any changes — triage is read-only
- If any MCP call fails (e.g., 401 unauthorized), report the error clearly and suggest checking GITEA_URL/GITEA_TOKEN configuration
- If the repo has many issues (100+), paginate and summarize rather than listing everything
- Keep the output scannable — use the table format, not verbose paragraphs
