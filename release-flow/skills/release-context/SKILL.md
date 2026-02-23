---
name: release-context
description: Passive release awareness — track current version, unreleased commits, and suggest releases after merges
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - mcp__gitx__tag_list
  - mcp__gitx__release_list
  - mcp__gitx__commit_list
---

# Release Context — Passive Version Awareness

You are working in a repository that uses semantic versioning and conventional commits. This skill teaches you to maintain awareness of the release state while doing regular development work.

## When This Skill Activates

Apply this skill whenever you are working in a repository. You do NOT need the user to invoke a release-flow command — this awareness is always-on.

## Version Detection

When you start working or when the user asks about releases/versions, detect the current version:

1. **Git tags** — Run `git tag --sort=-v:refname` and find the latest tag matching `v[0-9]*` (or the project's tag prefix pattern)
2. **Manifest files** — Check `package.json` or `Cargo.toml` for the `version` field
3. If no version is found, note: "No releases yet — this project hasn't been tagged."

Cache this information — do NOT re-fetch on every interaction.

## How to Use Release Context

### When Asked About Releases or Versions

If the user asks about the current version, release state, or what's changed:

1. Report the latest version and when it was tagged: `git log -1 --format=%ci <tag>`
2. Count commits since the last release: `git rev-list <tag>..HEAD --count`
3. Summarize what changed: `git log <tag>..HEAD --oneline`
4. If `git-cliff` is available, report the auto-detected next version: `git-cliff --bumped-version`

```
Current release: v1.2.3 (2024-03-15)
Commits since release: 12
  - 5 feat, 3 fix, 2 chore, 1 docs, 1 refactor
Next version (auto): 1.3.0 (minor bump due to feat commits)

Run /release-flow:release --dry-run to preview the full changelog.
```

### After Merge Operations

When you detect that a merge has just happened (e.g., after a `forge-flow:merge` command, or the user runs `git merge` or `git pull` that brings in new commits):

Gently note the release state:
```
There are N unreleased commits since v<version>. Consider `/release-flow:release --dry-run` to preview.
```

Only mention this ONCE per merge — do not repeat it.

### During General Work

- If the user asks "should we release?" or similar, provide the commit breakdown and suggest the appropriate bump level based on conventional commit types
- If you notice the commit count since last release is high (20+), you may mention it once: "Note: there are N commits since the last release."

## What NOT to Do

- Do NOT automatically run release-flow commands without the user asking
- Do NOT create tags, releases, or modify files silently
- Do NOT slow down the user's workflow with excessive version checks — detect ONCE and cache
- Do NOT announce "I'm using the release-context skill" — just use the context naturally
- Do NOT block or interrupt the user's current task to suggest releases
- Do NOT re-check version state on every interaction — only when relevant

## Graceful Degradation

- If `git-cliff` is not installed, skip git-cliff-specific checks (bumped version detection) and rely on git tags and manual commit counting. Do not warn about git-cliff missing unless the user tries to use a release-flow command.
- If no git tags exist, note "No releases yet" and move on
- If tag or commit queries fail, note it once and do not retry repeatedly
