---
name: forge-context
description: Passive forge awareness — automatically detect issue context from branch names and keep issue requirements in mind while working
allowed-tools:
  - Bash
  - Read
  - Grep
  - mcp__gitx__issue_get
  - mcp__gitx__issue_comment_list
  - mcp__gitx__pr_list
  - mcp__gitx__label_list
---

# Forge Context — Passive Issue Awareness

You are working in a repository connected to a Gitea/Forgejo forge via the `gitx` MCP server. This skill teaches you to maintain awareness of the issue/PR context while doing regular development work.

## When This Skill Activates

Apply this skill whenever you are working in a repository and the `gitx` MCP server is available. You do NOT need the user to invoke a forge-flow command — this awareness is always-on.

## Branch-to-Issue Detection

When you start working or notice the current branch, check if it follows the forge-flow naming convention:

**Pattern:** `<type>/<issue-number>-<slug>`

Examples:
- `fix/31-login-fails-on-safari` → Issue #31
- `feat/15-user-dashboard` → Issue #15
- `chore/8-update-deps` → Issue #8

If the branch matches, silently fetch the issue details with `issue_get` to understand the requirements you're working toward. You do NOT need to announce this — just keep the context in mind.

## How to Use Issue Context

When you have issue context, let it guide your work:

### During Implementation
- **Scope check:** If you're about to make changes unrelated to the issue, pause and mention it: "This change is outside the scope of Issue #N. Should I proceed or create a separate issue?"
- **Requirement coverage:** As you implement, mentally track which issue requirements you've addressed. If the user asks "are we done?", reference the issue requirements.
- **Design decisions:** When choosing between approaches, prefer the one that best satisfies the issue requirements. Mention the tradeoff: "Issue #N asks for X, so I'll use approach A which better addresses that."

### During Commits
- When creating commit messages (especially with `/commit`), include the issue reference when relevant:
  - `fix: resolve Safari login crash (#31)`
  - `feat: add CSV export endpoint (#28)`
- Don't force issue references into every commit — only when the commit directly addresses the issue.

### Proactive Awareness
- **Stale work detection:** If you notice the branch has been around for a while (many days since first commit) or has diverged significantly from main, mention it: "This branch has diverged N commits from main. Consider rebasing."
- **New issue comments:** If you fetch issue context and notice recent comments you haven't seen, summarize them: "Note: there are new comments on Issue #N since work started."
- **Blocked state:** If you determine that the current work is blocked (missing dependency, unclear requirement, waiting on another PR), suggest: "This might be a good time to update Issue #N with a status comment."

## What NOT to Do

- Do NOT automatically run forge-flow commands without the user asking
- Do NOT post comments to issues unless explicitly asked or running a forge-flow command
- Do NOT modify issue state (assignees, labels, status) silently
- Do NOT slow down the user's workflow with excessive forge queries — fetch issue context ONCE when you first detect the branch, not on every interaction
- Do NOT announce "I'm using the forge-context skill" — just use the context naturally

## Graceful Degradation

- If the `gitx` MCP server is not available, skip all forge-related behavior silently
- If the branch doesn't match the naming pattern, don't try to guess an issue
- If `issue_get` fails (404, auth error), note it once and move on — don't retry repeatedly
