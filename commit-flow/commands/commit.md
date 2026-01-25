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

### Step 2: Analyze Repository Commit History

Run `git log --oneline -20` to examine recent commits and understand:
- **Message style** - How are descriptions phrased? What verb tense? What level of detail?
- **Type usage** - Which conventional commit types does this repo use? Any custom conventions?
- **Scope patterns** - Does the repo use scopes like `feat(auth):`? What format?
- **Body conventions** - How detailed are commit bodies? What information is included?

**IMPORTANT:** Your commits MUST match the existing patterns in the repository to maintain continuity. If the repo uses lowercase descriptions, use lowercase. If commits are terse, be terse. Mirror the established style.

### Step 3: Analyze Git Status

Run `git status` to check:
- Which files are staged
- Which files are modified but unstaged
- Which files are untracked

If no files are staged, automatically stage all modified files with `git add -u`. Do NOT automatically add untracked files without asking.

### Step 4: Generate Diff and Analyze Changes

Run `git diff --cached` to see what will be committed.

Analyze the diff to identify:
1. **Distinct logical changes** - Changes that serve different purposes
2. **Different change types** - Features, fixes, refactoring, docs, tests, chores
3. **Unrelated file groups** - Changes to unrelated parts of the codebase

### Step 5: Actively Evaluate Commit Splitting

**DEFAULT BEHAVIOR: Look for ways to split.** Don't default to a single commit - actively analyze whether changes should be separated.

**Ask yourself these questions:**
1. Are there changes to multiple unrelated files or subsystems?
2. Could someone reviewing this say "this commit does two things"?
3. Are there formatting/style changes mixed with functional changes?
4. Are there bug fixes mixed with new features?
5. Are there refactors that could stand alone from new functionality?
6. Are there test files that test different features?
7. Are there documentation updates for different topics?

**If ANY answer is yes, split the commits.**

**Split commits when (actively look for these):**
- Changes mix different concerns (e.g., feature + unrelated fix)
- Changes touch unrelated subsystems or directories
- Changes include both source code and documentation updates for different features
- A refactor is mixed with new functionality
- Test additions are for different features
- Style/formatting changes are mixed with logic changes
- Configuration changes are unrelated to code changes
- Multiple independent bug fixes exist

**Keep as single commit ONLY when:**
- All changes serve ONE clear logical purpose
- Changes are tightly coupled (e.g., a feature + its direct tests + its direct docs)
- Changes are small AND cohesive
- Splitting would make commits less meaningful

**When splitting, tell the user:**
"I'm splitting these changes into X commits because [reason]. The commits will be: 1) ... 2) ... 3) ..."

### Step 6: Create Commit(s)

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
- Match the style/formatting of existing commits in the repo (from Step 2 analysis)
- NO emojis anywhere

**CRITICAL - Signature Format:**
The commit message MUST end with EXACTLY `[agent commit]` on its own line. Nothing else.
- NO `Co-Authored-By:` lines (NEVER, EVER)
- NO `Co-Authored By:` variations
- NO "Generated with Claude Code" text
- NO other signatures, attributions, or footers
- ONLY `[agent commit]` as the final line

**Correct format:**
```
feat: add user auth

Implement JWT authentication.

[agent commit]
```

**WRONG formats (NEVER do these):**
```
feat: add user auth

[agent commit]

Co-Authored-By: Claude <noreply@anthropic.com>
```
```
feat: add user auth

[agent commit]
Co-Authored-By: ...
```
```
feat: add user auth

Co-Authored-By: ...

[agent commit]
```

### Step 7: Verify

After committing, run `git log -1 --stat` to show the commit that was created.

If multiple commits were made, run `git log -<n> --oneline` where n is the number of commits created.

**Verify the commit message format is correct** - check that:
1. The signature is ONLY `[agent commit]` with nothing after it
2. No Co-Authored-By or other attributions snuck in
3. The message style matches the repository's existing commits

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

- **ANALYZE COMMIT HISTORY FIRST** - Always check recent commits to match the repo's style
- **ACTIVELY SPLIT COMMITS** - Default to splitting; only keep single commit if truly atomic
- NEVER use emojis in commit messages
- **SIGNATURE IS STRICTLY `[agent commit]`** - This is the ONLY signature. Nothing before, nothing after.
- **ABSOLUTELY NO Co-Authored-By** - Never add `Co-Authored-By:`, `Co-authored-by:`, or any variation. Not before the signature, not after, not anywhere.
- **NO "Generated with Claude Code"** - Never add this text
- When splitting, explain to the user what commits you're creating before making them
- If pre-commit checks fail, always ask before proceeding
- Prefer atomic, focused commits over large mixed commits
- Match the existing commit message style in the repository
