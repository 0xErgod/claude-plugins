---
description: Install git-cliff, detect project type, and configure cliff.toml for release automation
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
---

# Setup — Configure git-cliff for release-flow

One-time setup that checks for the git-cliff binary, detects your project type, creates a `cliff.toml` configuration, and verifies everything works.

Arguments provided: $ARGUMENTS

## Workflow

### Step 1: Check for git-cliff Binary

Run `command -v git-cliff` (or `where git-cliff` on Windows) to check if the binary is on PATH.

**If found**, report the version:
```
git-cliff found: <version>
  Path: <path>
```

**If NOT found**, guide installation:

```
git-cliff binary not found on PATH.

Install it with one of:
  cargo install git-cliff          # Rust toolchain (recommended)
  npm install -g git-cliff         # Node.js
  brew install git-cliff           # macOS (Homebrew)
  winget install orhun.git-cliff   # Windows (winget)

Or download a prebuilt binary from:
  https://github.com/orhun/git-cliff/releases
```

Ask the user: "Install now, or have you installed it elsewhere?"
- If they want to install: detect available package managers and run the appropriate install command
- If installed elsewhere: ask for the full path to the binary

After installation, verify again with `git-cliff --version`.
If still not found, stop: "Cannot find git-cliff. Ensure it's on your PATH and try again."

### Step 2: Detect Project Type

Scan the repository root for manifest files to understand the project:

| File | Project Type |
|------|--------------|
| `package.json` | Node.js / JavaScript / TypeScript |
| `Cargo.toml` | Rust / Move |
| `pyproject.toml` | Python |
| `go.mod` | Go |
| `pom.xml` | Java (Maven) |
| `build.gradle` | Java (Gradle) |
| `mix.exs` | Elixir |
| `Gemfile` | Ruby |

Use Glob to search for these files at the project root.

Report what was found:
```
Detected project type(s):
  - Node.js (package.json found)
  - Rust (Cargo.toml found)

Manifest files that will be updated during releases:
  - package.json
  - Cargo.toml
```

If no manifest files are found, note: "No known manifest files found. Releases will use git tags only (no version file updates)."

### Step 3: Create cliff.toml Configuration

Check if `cliff.toml` already exists in the project root.

**If it exists:**
```
cliff.toml already exists. Overwrite with release-flow defaults?
```
Ask the user — if no, skip to Step 4.

**If it does not exist (or user wants to overwrite)**, create `cliff.toml` with these defaults:

```toml
[changelog]
header = """
# Changelog\n
All notable changes to this project will be documented in this file.\n
"""
body = """
{% if version %}\
    ## [{{ version | trim_start_matches(pat="v") }}] - {{ timestamp | date(format="%Y-%m-%d") }}
{% else %}\
    ## [unreleased]
{% endif %}\
{% for group, commits in commits | group_by(attribute="group") %}
    ### {{ group | striptags | trim | upper_first }}
    {% for commit in commits %}
        - {% if commit.scope %}*({{ commit.scope }})* {% endif %}\
            {% if commit.breaking %}[**breaking**] {% endif %}\
            {{ commit.message | upper_first }}\
    {% endfor %}
{% endfor %}\n
"""
trim = true

[git]
conventional_commits = true
filter_unconventional = true
split_commits = false
commit_parsers = [
    { message = "^feat", group = "Features" },
    { message = "^fix", group = "Bug Fixes" },
    { message = "^perf", group = "Performance" },
    { message = "^refactor", group = "Refactoring" },
    { message = "^docs", group = "Documentation" },
    { message = "^style", group = "Styling" },
    { message = "^test", group = "Tests" },
    { message = "^chore", group = "Chores" },
    { message = "^revert", group = "Reverts" },
]
protect_breaking_commits = false
filter_commits = false
tag_pattern = "v[0-9].*"
topo_order = false
sort_commits = "oldest"
```

The `commit_parsers` match the section names from `.versionrc.json` to keep changelog formatting consistent across tools.

### Step 4: Summary

Report what was configured:

```
release-flow setup complete!

  git-cliff:    <version> (<path>)
  Project type: <type(s)>
  Config:       cliff.toml <created / already existed>
  Manifests:    <list of manifest files>

  Next steps:
    /release-flow:release --dry-run    — Preview your first release
    /release-flow:release --patch      — Create a patch release
    /release-flow:release              — Auto-detect bump level from commits

  The release-context skill will passively track your release state.
```

## Arguments

- `--force`: Overwrite cliff.toml without asking

## Important

- NEVER overwrite cliff.toml without asking unless `--force` is specified
- The cliff.toml config should match the conventional commit types used in the project — use the section names from `.versionrc.json` if present
- If git-cliff installation fails, report the error clearly and suggest alternative installation methods
- This setup is project-local — cliff.toml should be committed to the repository
