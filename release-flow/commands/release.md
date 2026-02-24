---
description: Bump version, generate changelog, tag, and optionally publish a forge release
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, mcp__gitx__tag_list, mcp__gitx__tag_create, mcp__gitx__release_create, mcp__gitx__release_list, mcp__gitx__commit_list, mcp__gitx__repo_get
---

# Release — Bump, tag, and release

Calculate the next semantic version from conventional commits, update manifest files, generate a changelog with git-cliff, create a git tag, and optionally publish a forge release.

Arguments provided: $ARGUMENTS

## Prerequisites

This command requires `git-cliff` installed and on PATH. Run `/release-flow:setup` first if you haven't.

## Forge Content Formatting Rules

**CRITICAL — These rules apply to ALL text passed to MCP tools (release_create body):**

### Newlines
You MUST use actual newlines in strings passed to MCP tools, NEVER escaped `\n` characters. The API receives the string exactly as you pass it. Literal `\n` will render as visible text, not line breaks.

### Agent Signature
Every release body MUST end with the following signature on its own line:

```
[agent release]
```

This signature MUST be the LAST line. Nothing after it.

## Workflow

### Step 1: Parse Arguments

Extract flags from `$ARGUMENTS`:

| Flag | Effect |
|------|--------|
| `--major` | Force a major version bump |
| `--minor` | Force a minor version bump |
| `--patch` | Force a patch version bump |
| `--release` | Push commit + tag and create a forge release |
| `--dry-run` | Preview all actions without side effects |
| `--tag-prefix <prefix>` | Tag prefix (default: `v`) |
| `--pre <label>` | Pre-release label (`rc`, `beta`, `alpha`) |
| `--no-changelog` | Skip changelog generation |
| `--no-commit` | Skip creating the release commit (just tag) |

If multiple of `--major`, `--minor`, `--patch` are given, the highest wins (major > minor > patch).

### Step 2: Validate Working Tree

1. Run `git status --porcelain` — if there are uncommitted changes:
   - If `--dry-run`, warn but continue
   - Otherwise, stop: "You have uncommitted changes. Commit or stash them before releasing."
2. Run `git branch --show-current` to detect the current branch
3. Detect the default branch via `git remote show origin | grep 'HEAD branch'` or fall back to checking if `main` or `master` exists
4. If not on the default branch, warn: "You're on `<branch>`, not the default branch `<default>`. Release from here anyway?" — wait for confirmation unless `--dry-run`

### Step 3: Verify git-cliff is Installed

Run `git-cliff --version`.

If it fails:
```
git-cliff is not installed or not on PATH.
Run /release-flow:setup to install and configure it.
```
Stop.

### Step 4: Detect Current Version

Determine the current version using this fallback chain:

1. **git-cliff** — Run `git-cliff --bumped-version` and extract the base version (before the bump). If git-cliff reports no tags, fall through.
2. **Latest git tag** — Run `git tag --sort=-v:refname` and parse the first tag matching the tag prefix pattern (e.g., `v1.2.3`). Strip the prefix to get `1.2.3`.
3. **package.json** — Read `version` field
4. **Cargo.toml** — Read `version` under `[package]`
5. **Default** — `0.0.0` (first release)

Report: "Current version: `<version>` (detected from <source>)"

### Step 5: Preview Changes with git-cliff

Run `git-cliff --unreleased --strip header` to show what commits will be in this release.

Parse the output to report:
```
Unreleased changes since <current-version>:
  Features:     <count>
  Bug Fixes:    <count>
  Performance:  <count>
  Refactoring:  <count>
  Other:        <count>
  Total:        <count> commits

Auto-detected bump: <major/minor/patch>
```

**Bump level detection:**
- If any commit has a BREAKING CHANGE footer or a bang (!) after the type → **major**
- If any feat commits → **minor**
- Otherwise → **patch**

If an explicit `--major`, `--minor`, or `--patch` flag was provided, report: "Override: using `<level>` bump (auto-detected was `<auto-level>`)"

If there are no unreleased commits:
- If `--dry-run`, report "No unreleased changes found." and stop
- Otherwise, ask: "No unreleased changes found. Create an empty release anyway?" — stop if no

### Step 6: Calculate Next Version

Apply the bump level to the current version:

| Current | Bump | Next |
|---------|------|------|
| `1.2.3` | patch | `1.2.4` |
| `1.2.3` | minor | `1.3.0` |
| `1.2.3` | major | `2.0.0` |

If `--pre <label>` is provided, append the pre-release suffix:
- First pre-release: `1.3.0-rc.1`
- If current version already has the same pre-release label, increment: `1.3.0-rc.1` → `1.3.0-rc.2`

Construct the full tag: `<prefix><version>` (e.g., `v1.3.0`)

Report:
```
Version: <current> → <next>
Tag:     <tag>
```

If `--dry-run`, prefix every subsequent action with `[DRY RUN]` and do NOT execute any mutating operations.

### Step 7: Update Manifest Files

Detect and update version in manifest files:

**package.json + package-lock.json (Node.js):**
- If both `package.json` and `package-lock.json` exist, run: `npm version <version> --no-git-tag-version`
- If only `package.json` exists, use Edit to update the `"version"` field

**Cargo.toml (Rust):**
- Use Edit to update ONLY the `version = "..."` line under the `[package]` section
- Do NOT modify version fields in `[dependencies]` or other sections
- Match the exact format: `version = "<new-version>"`

**Other manifests:**
- `pyproject.toml`: Report "Found pyproject.toml — update `version` manually or add a release hook"
- `go.mod`: Report "Go uses git tags for versioning — no file update needed"
- Any other: Report but don't auto-update

Report each file updated:
```
Updated manifests:
  - package.json → <version>
  - package-lock.json → <version> (via npm version)
  - Cargo.toml → <version>
```

### Step 8: Generate Changelog

Unless `--no-changelog` is specified:

Run `git-cliff --tag <new-tag> -o CHANGELOG.md` to generate or update the changelog.

git-cliff handles:
- Prepending the new version section
- Grouping commits by type
- Formatting according to cliff.toml

If `cliff.toml` does not exist, warn: "No cliff.toml found. Run `/release-flow:setup` first for consistent formatting. Using git-cliff defaults."

Report: "Updated CHANGELOG.md with `<new-tag>` release notes"

### Step 9: Create Release Commit

Unless `--no-commit` is specified:

1. Stage all modified files:
   - `CHANGELOG.md` (if updated)
   - `package.json`, `package-lock.json` (if updated)
   - `Cargo.toml` (if updated)
   - Any other manifest files that were updated
2. Create a commit:

```
chore(release): <version>

[agent release]
```

**CRITICAL — Commit Signature:**
- The commit message MUST end with EXACTLY `[agent release]` on its own line
- NO `Co-Authored-By:` lines (NEVER)
- NO "Generated with Claude Code" text
- NO other signatures, attributions, or footers
- ONLY `[agent release]` as the final line

Use a HEREDOC to pass the commit message to preserve formatting:
```bash
git commit -m "$(cat <<'EOF'
chore(release): <version>

[agent release]
EOF
)"
```

### Step 10: Create Git Tag

Create an annotated tag:

```bash
git tag -a <prefix><version> -m "Release <prefix><version>"
```

If the tag already exists, stop: "Tag `<tag>` already exists. Delete it first or use a different version."

### Step 11: Create Forge Release (Optional)

**Only if `--release` flag is provided.** Otherwise skip and report: "Tag created locally. Push with `git push origin <branch> --tags` when ready, or re-run with `--release` to publish."

If `--release`:

1. Push the commit and tag:
   ```bash
   git push origin <branch>
   git push origin <tag>
   ```

2. Extract the release notes for this version from the changelog. Run `git-cliff --latest --strip header` to get just the latest version's notes.

3. Call `release_create` with:
   - `tag_name`: The new tag
   - `name`: `Release <version>`
   - `body`: The release notes from git-cliff, ending with `[agent release]`
   - `prerelease`: `true` if `--pre` was used, `false` otherwise
   - `draft`: `false`

Report: "Forge release created: Release `<version>`"

### Step 12: Report Summary

Print the final report:

```
Release <version> complete!

  Version: <old> → <new>
  Tag:     <tag>

  Actions taken:
    [x] Calculated version from conventional commits
    [x] Updated package.json → <version>
    [x] Updated Cargo.toml → <version>
    [x] Generated CHANGELOG.md
    [x] Created commit: chore(release): <version>
    [x] Created tag: <tag>
    [x] Pushed to origin                        # only if --release
    [x] Created forge release                   # only if --release

  Next steps:
    git push origin <branch> --tags   # if not using --release
    npm publish                       # if Node.js project
    cargo publish                     # if Rust project
```

For `--dry-run`, use `[ ]` instead of `[x]` and prefix with:
```
[DRY RUN] No changes were made. Here's what would happen:
```

## Arguments

- `--major`: Force major version bump (breaking changes)
- `--minor`: Force minor version bump (new features)
- `--patch`: Force patch version bump (bug fixes)
- `--release`: Push to remote and create a forge release
- `--dry-run`: Preview all actions without making changes
- `--tag-prefix <prefix>`: Custom tag prefix (default: `v`)
- `--pre <label>`: Pre-release label (e.g., `rc`, `beta`, `alpha`)
- `--no-changelog`: Skip changelog generation/update
- `--no-commit`: Skip creating the release commit (tag only)

## Important

- NEVER create a release without the user explicitly invoking this command
- Dry run mode is completely side-effect free — no files modified, no commits, no tags, no pushes
- The `[agent release]` signature is MANDATORY on all commits and forge release bodies
- When updating Cargo.toml, ONLY change the version under `[package]` — never touch dependency versions
- If git-cliff is not installed, always stop and point to `/release-flow:setup`
- ALL text sent to MCP tools MUST use real newlines, NEVER escaped `\n`
- If `--release` creates a forge release, the release notes should come from git-cliff output, not be manually composed
- Pre-release versions follow semver: `1.3.0-rc.1`, `1.3.0-rc.2`, `1.3.0-beta.1`
- Match the tag prefix from the repository's existing tags if possible (detect from `tag_list` or git tags)
