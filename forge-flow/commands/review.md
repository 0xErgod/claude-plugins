---
description: Review a PR against its linked issue requirements — approve, request changes, or comment
allowed-tools: Bash, Read, Grep, Glob, mcp__gitx__pr_get, mcp__gitx__pr_diff, mcp__gitx__pr_files, mcp__gitx__pr_review_list, mcp__gitx__pr_review_create, mcp__gitx__issue_get, mcp__gitx__issue_comment_list, mcp__gitx__label_list, mcp__gitx__actions_run_list, mcp__gitx__actions_run_get, mcp__gitx__commit_list, mcp__gitx__user_get_me
---

# Review — Evaluate a PR against issue goals

Review a pull request by examining its diff against the linked issue's requirements. This is the negotiation step — does the proposed solution actually achieve what the issue asked for?

Arguments provided: $ARGUMENTS

## Prerequisites

This command requires the `gitx-mcp` MCP server configured with server name `gitx`. The first argument should be a PR number.

## Forge Content Formatting Rules

**CRITICAL — These rules apply to ALL text passed to MCP tools (pr_review_create body):**

### Newlines
You MUST use actual newlines in strings passed to MCP tools, NEVER escaped `\n` characters. The API receives the string exactly as you pass it. Literal `\n` will render as visible text, not line breaks.

### Agent Signature
Every review body MUST end with `[agent review]` on its own line. Nothing after it.

## Workflow

### Step 1: Parse Arguments

Extract the PR number from `$ARGUMENTS`. If no PR number is provided, check if the user is on a branch that has an open PR. If not, tell the user:
"Usage: `/forge-flow:review <pr-number>`. Run `/forge-flow:triage` to see PRs needing review."

### Step 2: Gather PR Context (parallel where possible)

1. **PR details** — `pr_get` with the PR number. Extract:
   - Title, body, state, head/base branches
   - Mergeable status
   - Author
   - Labels, assignees
2. **PR diff** — `pr_diff` to get the full unified diff
3. **Changed files** — `pr_files` for the file list with diff stats
4. **Existing reviews** — `pr_review_list` to see prior feedback
5. **Current user** — `user_get_me` to avoid self-review warnings where appropriate
6. **CI status** — `actions_run_list` (limit 5), filter for runs on the PR's head branch

### Step 3: Identify Linked Issue

Parse the PR body for issue references:
- Look for patterns: `Closes #N`, `Fixes #N`, `Addresses #N`, `Resolves #N`, `Refs #N`, `Related to #N`
- Also check the branch name for `<type>/<number>-<slug>` pattern

If a linked issue is found:
1. Call `issue_get` to fetch the full issue details
2. Call `issue_comment_list` to understand any discussion context
3. Extract the issue's requirements (from body, title, and comment discussion)

If NO linked issue is found:
- Note this in the review: "This PR has no linked issue. Review is based on the PR description and diff alone."
- Proceed with the review using only the PR body as the requirements source

### Step 4: Analyze the Diff

Read the full diff carefully. For each changed file, understand:

1. **What changed** — additions, modifications, deletions
2. **Why it changed** — infer purpose from context, commit messages, and issue requirements
3. **Quality signals:**
   - Are there obvious bugs, edge cases, or error handling gaps?
   - Are there security concerns (injection, auth bypass, sensitive data exposure)?
   - Are there performance concerns (N+1 queries, unbounded loops, memory leaks)?
   - Is the code consistent with the surrounding codebase style?
   - Are there missing tests for new functionality?

If the diff is very large (>500 lines), focus on:
- New files first (they contain the core new logic)
- Modified files (behavioral changes)
- Deleted files last (usually cleanup)

### Step 5: Requirements Gap Analysis

This is the core of the review. For each requirement from the linked issue:

| Requirement | Status | Evidence |
|-------------|--------|----------|
| <requirement from issue> | MET / PARTIALLY MET / NOT MET | <file:line or explanation> |

**Status definitions:**
- **MET** — The diff clearly addresses this requirement with implementation evidence
- **PARTIALLY MET** — Some aspects addressed, but gaps remain (specify what's missing)
- **NOT MET** — No evidence in the diff that this requirement was addressed
- **OUT OF SCOPE** — The requirement exists but was explicitly deferred (check PR body for "Addresses" vs "Closes")

### Step 6: Check CI Status

From the workflow runs:
- Is the latest run on this branch passing?
- If failing, what's failing? (Use `actions_run_get` for details if needed)
- Note CI status in the review

### Step 7: Determine Verdict

**APPROVED** — when ALL of:
- All issue requirements are MET (or explicitly marked as follow-up with "Addresses")
- No obvious bugs, security issues, or critical quality problems
- CI is green (or CI failures are unrelated to the PR changes)

**REQUEST_CHANGES** — when ANY of:
- Issue requirements are NOT MET without explanation
- Bugs, security issues, or critical quality problems found
- CI is red due to changes in this PR
- The implementation contradicts the issue's stated goals

**COMMENT** — when:
- Requirements are met but you have suggestions for improvement
- You need clarification on an approach before approving
- The review is informational (self-review, second opinion)

### Step 8: Submit the Review

Call `pr_review_create` with:
- `index`: PR number
- `event`: `APPROVED`, `REQUEST_CHANGES`, or `COMMENT`
- `body`: Structured review (see format below)

**Review body format:**

```markdown
## Review: <PR title>

### Verdict: <APPROVED / CHANGES REQUESTED / COMMENT>

### Issue Requirements (#<N>: "<title>")

| # | Requirement | Status | Evidence |
|---|-------------|--------|----------|
| 1 | <req> | MET | `src/auth.ts:42` — JWT validation added |
| 2 | <req> | NOT MET | No rate limiting found in diff |

### Code Quality

<observations about code quality, bugs, or improvements — or "No issues found">

### CI Status

<green/red — details if red>

### Summary

<1-3 sentences: overall assessment and what to do next>

[agent review]
```

### Step 9: Report Locally

Print a concise summary:

```
Review submitted for PR #<N>: <verdict>

  Requirements: <X/Y met>
  CI: <green/red>
  Quality: <clean / N issues noted>

  <If REQUEST_CHANGES: "Author needs to address: <brief list>">
  <If APPROVED: "Ready for /forge-flow:merge <N>">
```

## Arguments

- `<pr-number>` (required): The PR to review
- `--quick`: Skip deep diff analysis, focus only on requirements checklist
- `--strict`: Require ALL requirements MET for approval (no partial/Addresses)

## Important

- This is a structured, goal-oriented review — not a line-by-line code review nitpick session
- The linked issue is the SOURCE OF TRUTH for what this PR should accomplish
- If no issue is linked, the review quality is inherently lower — flag this
- Be fair: if a PR explicitly says "Addresses" (not "Closes"), unmet requirements are acceptable IF they're acknowledged
- Never fabricate evidence — if you can't find where a requirement is met in the diff, say so
- Read the FULL diff before forming an opinion, not just file names
- ALL text sent to MCP tools MUST use real newlines, NEVER escaped `\n`
- ALWAYS end review bodies with `[agent review]` as the final line
