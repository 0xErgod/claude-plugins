---
description: Merge an approved PR, close the linked issue, and clean up branches
allowed-tools: Bash, Read, Grep, mcp__gitx__pr_get, mcp__gitx__pr_merge, mcp__gitx__pr_review_list, mcp__gitx__pr_files, mcp__gitx__issue_get, mcp__gitx__issue_edit, mcp__gitx__issue_comment_create, mcp__gitx__branch_delete, mcp__gitx__milestone_get, mcp__gitx__actions_run_list, mcp__gitx__label_list
---

# Merge — Close the loop

Merge an approved pull request, close the linked issue, clean up the feature branch, and update local state. This is the final step in the forge-flow cycle.

Arguments provided: $ARGUMENTS

## Prerequisites

This command requires the `gitx-mcp` MCP server configured with server name `gitx`. The first argument should be a PR number.

## Forge Content Formatting Rules

**CRITICAL — These rules apply to ALL text passed to MCP tools (issue_comment_create body):**

### Newlines
You MUST use actual newlines in strings passed to MCP tools, NEVER escaped `\n` characters. The API receives the string exactly as you pass it. Literal `\n` will render as visible text, not line breaks.

### Agent Signature
Every issue comment MUST end with `[agent comment]` on its own line. Nothing after it.

## Workflow

### Step 1: Parse Arguments

Extract the PR number from `$ARGUMENTS`. If no PR number is provided, check if the current branch has an open PR. If not:
"Usage: `/forge-flow:merge <pr-number>`"

### Step 2: Pre-Merge Checks

Call `pr_get` with the PR number. Verify ALL of the following:

1. **PR is open** — If already merged or closed, report and stop
2. **PR is mergeable** — Check `mergeable` field. If false:
   - Report: "PR #N has merge conflicts. The author needs to rebase/resolve conflicts first."
   - Stop
3. **PR is approved** — Call `pr_review_list` and check:
   - At least one review with `APPROVED` status
   - No unresolved `REQUEST_CHANGES` reviews (a newer APPROVED overrides older REQUEST_CHANGES from the same reviewer)
   - If not approved: "PR #N is not approved. Run `/forge-flow:review <N>` first or request a review."
4. **CI is green** — Call `actions_run_list`, filter for the PR's head branch:
   - If the latest run is failing, warn: "CI is failing on this branch. Merge anyway?" — wait for confirmation
   - If no CI runs exist, note: "No CI runs found. Proceeding without CI verification."

Report the pre-merge check results:
```
Pre-merge checks for PR #<N>:
  Mergeable: YES
  Approved:  YES (<reviewer> approved)
  CI:        GREEN (build #<run-id>)
  Conflicts: NONE

Proceeding with merge...
```

If ANY check fails (except CI with user confirmation), stop and report what needs to be fixed.

### Step 3: Determine Merge Strategy

Use the merge strategy from arguments, or determine automatically:

| Condition | Strategy | Rationale |
|-----------|----------|-----------|
| `--squash` flag | `squash` | User requested |
| `--rebase` flag | `rebase` | User requested |
| `--merge` flag | `merge` | User requested |
| Single commit on branch | `rebase` | Clean history, no merge commit needed |
| Multiple commits, clean history | `merge` | Preserve commit structure |
| Many small commits | `squash` | Collapse noisy history |
| No flag, unclear | `merge` | Safe default |

To determine commit count: parse the PR details or run `git log origin/<base>..origin/<head> --oneline | wc -l`.

### Step 4: Merge the PR

Call `pr_merge` with:
- `index`: PR number
- `merge_style`: Determined strategy (`merge`, `rebase`, or `squash`)
- `merge_message`: For squash/merge, use: `<PR title> (#<pr-number>)`
- `delete_branch_after_merge`: `true` (unless `--keep-branch` flag)

If merge fails:
- 405 error: "Merge blocked — check branch protection rules, required reviews, or CI status."
- Other errors: Report the error details

### Step 5: Close the Linked Issue

1. Parse the PR body for issue references (`Closes #N`, `Fixes #N`, `Resolves #N`)
2. If found and the reference uses a closing keyword:
   - The forge may auto-close the issue on merge. Check issue state with `issue_get`.
   - If not auto-closed, manually close with `issue_edit` setting `state: "closed"`
   - Remove the "in-progress" label if present (fetch current labels, filter it out, update)
3. If the PR used "Addresses #N" (non-closing):
   - Do NOT close the issue
   - Post a comment with `issue_comment_create`:
     ```markdown
     **PR merged:** #<pr-number> was merged into `<base>`.

     This PR partially addresses this issue. Remaining work may still be needed.

     [agent comment]
     ```

### Step 6: Update Milestone (if applicable)

If the linked issue had a milestone:
1. Call `milestone_get` to check current counts
2. Report: "Milestone `<name>`: <closed>/<total> issues complete (<percentage>%)"

### Step 7: Local Cleanup

1. Switch to the default branch: `git checkout <base-branch>`
2. Pull latest: `git pull origin <base-branch>`
3. Delete the local feature branch: `git branch -d <head-branch>` (use `-d` not `-D` for safety)
   - If `-d` fails (unmerged changes), warn and ask before using `-D`
4. Prune remote tracking branches: `git fetch --prune`

### Step 8: Report

```
Merged PR #<N>: "<title>"
  Strategy: <merge/squash/rebase>
  Branch: <head> → <base> (deleted)
  Issue: #<issue-number> — <closed/still open>
  Milestone: <name> — <X/Y> complete

  Local branch cleaned up. You're on `<base-branch>` with latest changes.

  Run /forge-flow:triage to find your next task.
```

## Arguments

- `<pr-number>` (required): The PR to merge
- `--squash`: Force squash merge
- `--rebase`: Force rebase merge
- `--merge`: Force merge commit (default)
- `--keep-branch`: Don't delete the feature branch after merge
- `--force`: Skip approval/CI checks (use with caution)

## Important

- NEVER merge without the user explicitly invoking this command
- Merging is a significant action — always show the pre-merge check results before proceeding
- If `--force` is used, print a clear warning: "Skipping approval and CI checks as requested."
- The local cleanup step is a convenience — if it fails, the merge itself already succeeded on the forge
- If the user is currently on the branch being deleted, switch to base first
