#!/usr/bin/env bash
#
# forge-flow: pre-push branch hygiene check
#
# Validates branch naming conventions and issue linkage before pushing.
# Outputs warnings to Claude if the branch doesn't follow forge-flow patterns.
#
# Hook type: PreToolUse (Bash) — triggers before git push commands
#
# Configuration:
#   Add to your .claude/settings.json or project settings:
#
#   "hooks": {
#     "PreToolUse": [
#       {
#         "matcher": "Bash",
#         "hook": "./forge-flow/hooks/pre-push-check.sh"
#       }
#     ]
#   }
#
# Environment variables required:
#   GITEA_URL   — Base URL of the Gitea/Forgejo instance
#   GITEA_TOKEN — API token with issue read scope
#
# The hook only activates when the Bash command contains "git push".
#

# Only proceed if the tool input looks like a git push
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"
if ! echo "$TOOL_INPUT" | grep -qE 'git\s+push'; then
  exit 0
fi

WARNINGS=""

# Get current branch
BRANCH=$(git branch --show-current 2>/dev/null)
if [ -z "$BRANCH" ]; then
  exit 0
fi

# Skip checks for default branches
if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
  exit 0
fi

# Check branch naming convention: <type>/<number>-<slug>
VALID_TYPES="feat|fix|docs|style|refactor|perf|test|chore|revert"
if ! echo "$BRANCH" | grep -qP "^(${VALID_TYPES})/\d+-"; then
  WARNINGS="${WARNINGS}Branch '${BRANCH}' does not follow forge-flow naming convention (<type>/<issue-number>-<slug>).\n"
  WARNINGS="${WARNINGS}Expected patterns: feat/15-user-dashboard, fix/31-login-bug, chore/8-update-deps\n"
  WARNINGS="${WARNINGS}This branch won't be linked to an issue in the forge.\n"
fi

# Extract issue number if present
ISSUE_NUMBER=$(echo "$BRANCH" | grep -oP '^\w+/\K\d+' 2>/dev/null)

# If we have an issue number and Gitea credentials, verify the issue exists and is open
if [ -n "$ISSUE_NUMBER" ] && [ -n "$GITEA_URL" ] && [ -n "$GITEA_TOKEN" ]; then
  # Detect repo owner/name from git remote
  REMOTE_URL=$(git remote get-url origin 2>/dev/null)
  if [ -n "$REMOTE_URL" ]; then
    OWNER_REPO=$(echo "$REMOTE_URL" | sed -E 's#.*[:/]([^/]+/[^/]+?)(\.git)?$#\1#')
    OWNER=$(echo "$OWNER_REPO" | cut -d'/' -f1)
    REPO=$(echo "$OWNER_REPO" | cut -d'/' -f2)

    if [ -n "$OWNER" ] && [ -n "$REPO" ]; then
      # Check issue state
      ISSUE_RESPONSE=$(curl -s \
        "${GITEA_URL}/api/v1/repos/${OWNER}/${REPO}/issues/${ISSUE_NUMBER}" \
        -H "Authorization: token ${GITEA_TOKEN}" \
        -H "Content-Type: application/json" \
        2>/dev/null)

      if echo "$ISSUE_RESPONSE" | grep -q '"state":"closed"'; then
        WARNINGS="${WARNINGS}Issue #${ISSUE_NUMBER} is CLOSED. You may be pushing to a stale branch.\n"
      fi

      # Check if issue is assigned to someone else
      CURRENT_USER=$(curl -s \
        "${GITEA_URL}/api/v1/user" \
        -H "Authorization: token ${GITEA_TOKEN}" \
        2>/dev/null | grep -oP '"login":"\K[^"]+' | head -1)

      if [ -n "$CURRENT_USER" ]; then
        ASSIGNEE=$(echo "$ISSUE_RESPONSE" | grep -oP '"login":"\K[^"]+' | head -1)
        if [ -n "$ASSIGNEE" ] && [ "$ASSIGNEE" != "$CURRENT_USER" ]; then
          WARNINGS="${WARNINGS}Issue #${ISSUE_NUMBER} is assigned to '${ASSIGNEE}', not you (${CURRENT_USER}).\n"
        fi
      fi
    fi
  fi
fi

# Output warnings (these are shown to Claude as hook feedback)
if [ -n "$WARNINGS" ]; then
  echo "forge-flow pre-push warnings:"
  echo -e "$WARNINGS"
  echo "Push will proceed. These are warnings, not blockers."
fi

# Always allow the push (exit 0) — these are advisory warnings
exit 0
