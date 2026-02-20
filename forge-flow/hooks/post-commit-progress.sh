#!/usr/bin/env bash
#
# forge-flow: post-commit progress breadcrumbs
#
# Posts a brief progress comment to the linked Gitea/Forgejo issue after each commit.
# This creates a traceable trail of work visible to collaborators.
#
# Hook type: PostToolUse (Bash) — triggers after git commit commands
#
# Configuration:
#   Add to your .claude/settings.json or project settings:
#
#   "hooks": {
#     "PostToolUse": [
#       {
#         "matcher": "Bash",
#         "hook": "./forge-flow/hooks/post-commit-progress.sh"
#       }
#     ]
#   }
#
# Environment variables required:
#   GITEA_URL   — Base URL of the Gitea/Forgejo instance (e.g., https://gitea.example.com)
#   GITEA_TOKEN — API token with issue write scope
#
# The hook only activates when:
#   1. The last Bash command was a git commit
#   2. The current branch follows forge-flow naming: <type>/<number>-<slug>
#   3. GITEA_URL and GITEA_TOKEN are set
#

# Only proceed if the tool input looks like a git commit
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"
if ! echo "$TOOL_INPUT" | grep -qE 'git\s+commit'; then
  exit 0
fi

# Check required env vars
if [ -z "$GITEA_URL" ] || [ -z "$GITEA_TOKEN" ]; then
  exit 0
fi

# Get current branch
BRANCH=$(git branch --show-current 2>/dev/null)
if [ -z "$BRANCH" ]; then
  exit 0
fi

# Extract issue number from branch name (pattern: type/number-slug)
ISSUE_NUMBER=$(echo "$BRANCH" | grep -oP '^\w+/\K\d+' 2>/dev/null)
if [ -z "$ISSUE_NUMBER" ]; then
  exit 0
fi

# Get the last commit message (first line only)
COMMIT_MSG=$(git log -1 --pretty=format:'%s' 2>/dev/null)
if [ -z "$COMMIT_MSG" ]; then
  exit 0
fi

# Detect repo owner/name from git remote
REMOTE_URL=$(git remote get-url origin 2>/dev/null)
if [ -z "$REMOTE_URL" ]; then
  exit 0
fi

# Parse owner/repo from remote URL (handles both HTTPS and SSH)
OWNER_REPO=$(echo "$REMOTE_URL" | sed -E 's#.*[:/]([^/]+/[^/]+?)(\.git)?$#\1#')
OWNER=$(echo "$OWNER_REPO" | cut -d'/' -f1)
REPO=$(echo "$OWNER_REPO" | cut -d'/' -f2)

if [ -z "$OWNER" ] || [ -z "$REPO" ]; then
  exit 0
fi

# Get short SHA
SHORT_SHA=$(git log -1 --pretty=format:'%h' 2>/dev/null)

# Post progress comment to the issue
COMMENT_BODY="**Progress:** \`${SHORT_SHA}\` — ${COMMIT_MSG}"

curl -s -X POST \
  "${GITEA_URL}/api/v1/repos/${OWNER}/${REPO}/issues/${ISSUE_NUMBER}/comments" \
  -H "Authorization: token ${GITEA_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"body\": \"${COMMENT_BODY}\"}" \
  > /dev/null 2>&1

# Output feedback to Claude (shown as hook feedback)
echo "Posted progress to Issue #${ISSUE_NUMBER}: ${COMMIT_MSG}"
