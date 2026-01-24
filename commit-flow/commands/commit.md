---
description: Create well-formatted conventional commits with pre-commit checks and intelligent commit splitting
allowed-tools: Bash, Read, Glob, Grep
---

# Commit Workflow

Create commits following conventional commit format with automatic pre-commit validation and intelligent commit splitting.

## Arguments

- `--no-verify`: Skip pre-commit checks
- `--amend`: Amend the previous commit (use with caution)

Arguments provided: $ARGUMENTS

## Workflow

### Step 1: Detect Project Type and Run Pre-Commit Checks

Unless `--no-verify` is specified, detect the project type and run appropriate checks.

**Detection and checks by project type:**

| Indicator | Project Type | Checks to Run |
|-----------|--------------|---------------|
| `Cargo.toml` | Rust | `cargo check && cargo test && cargo clippy` |
| `package.json` | Node.js | `npm run lint` (if exists), `npm test` (if exists), `npm run typecheck` (if exists) |
| `pyproject.toml` or `setup.py` | Python | `ruff check .` or `flake8`, `pytest` (if tests exist), `mypy .` (if configured) |
| `go.mod` | Go | `go build ./...`, `go test ./...`, `go vet ./...` |
| `pom.xml` | Java/Maven | `mvn compile`, `mvn test` |
| `build.gradle` | Java/Gradle | `./gradlew build`, `./gradlew test` |
| `Makefile` | Generic | `make check` or `make test` (if targets exist) |
| `.pre-commit-config.yaml` | Any | `pre-commit run --all-files` |

**Important:**
- Only run checks that are available/configured for the project
- If checks fail, report the failures and ask if user wants to proceed anyway or fix first
- If no recognizable project type, skip to Step 2

### Step 2: Analyze Git Status

Run `git status` to check:
- Which files are staged
- Which files are modified but unstaged
- Which files are untracked

If no files are staged, automatically stage all modified files with `git add -u`. Do NOT automatically add untracked files without asking.

### Step 3: Generate Diff and Analyze Changes

Run `git diff --cached` to see what will be committed.

Analyze the diff to identify:
1. **Distinct logical changes** - Changes that serve different purposes
2. **Different change types** - Features, fixes, refactoring, docs, tests, chores
3. **Unrelated file groups** - Changes to unrelated parts of the codebase

### Step 4: Decide on Single vs Multiple Commits

**Split commits when:**
- Changes mix different concerns (e.g., feature + unrelated fix)
- Changes touch unrelated subsystems
- Changes include both source code and documentation updates for different features
- A refactor is mixed with new functionality
- Test additions are for different features

**Keep as single commit when:**
- All changes serve one logical purpose
- Changes are tightly coupled (e.g., feature + its tests + its docs)
- Changes are small and cohesive

### Step 5: Create Commit(s)

For each commit:

1. If splitting, unstage all files first with `git reset HEAD`
2. Stage only the files for this specific commit with `git add <files>`
3. Create commit with conventional commit message

**Conventional Commit Format:**
```
<type>: <description>

<body>

[agent commit]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style/formatting (no logic change)
- `refactor`: Code restructuring (no feature/fix)
- `perf`: Performance improvement
- `test`: Adding/updating tests
- `chore`: Build, CI, dependencies, tooling
- `revert`: Reverting previous commit

**Rules:**
- First line under 72 characters
- Use present tense, imperative mood ("add" not "added")
- Body explains what and why (not how)
- NO emojis anywhere
- ALWAYS end with `[agent commit]` signature on its own line
- NO `Co-Authored-By` lines
- NO "Generated with Claude Code" text

### Step 6: Verify

After committing, run `git log -1 --stat` to show the commit that was created.

If multiple commits were made, run `git log -<n> --oneline` where n is the number of commits created.

## Example Output

**Single commit:**
```
feat: add user authentication with JWT tokens

Implement JWT-based authentication flow including login, logout,
and token refresh endpoints. Add middleware for protected routes.

[agent commit]
```

**Split commits example:**
```
# Commit 1
refactor: extract validation logic into separate module

Move input validation from controllers to dedicated validators
for better separation of concerns and reusability.

[agent commit]

# Commit 2
feat: add email validation for user registration

Add RFC 5322 compliant email validation to prevent invalid
email addresses during user signup.

[agent commit]

# Commit 3
test: add unit tests for email validation

[agent commit]
```

## Important Reminders

- NEVER use emojis in commit messages
- ALWAYS sign with `[agent commit]` as the final line
- NEVER include Co-Authored-By or Generated with Claude Code
- When splitting, explain to the user what commits you're creating before making them
- If pre-commit checks fail, always ask before proceeding
- Prefer atomic, focused commits over large mixed commits
