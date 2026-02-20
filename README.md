# cc-plugins

A plugin marketplace for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — Anthropic's official CLI for Claude.

## Setup

Install the marketplace as a plugin source in Claude Code:

```bash
claude plugins add /path/to/claude-plugins
```

Or add the GitHub repo directly:

```bash
claude plugins add https://github.com/0xErgod/claude-plugins
```

After installation, all plugins in the marketplace are available in your Claude Code sessions. Commands appear as `/plugin-name:command`, and skills activate automatically when relevant.

## Plugins

### commit-flow

Language-agnostic commit workflow with conventional commits, pre-commit checks, and intelligent commit splitting.

**Commands:**

| Command | Description |
|---------|-------------|
| `/commit-flow:commit` | Create well-formatted conventional commits with automatic pre-commit validation |

**What it does:**
- Detects project type (Rust, Node, Python, Go, Java, etc.) and runs appropriate pre-commit checks
- Analyzes your repository's commit history to match existing style
- Actively evaluates whether staged changes should be split into multiple atomic commits
- Formats commits using conventional commit syntax (`feat:`, `fix:`, `chore:`, etc.)
- Signs commits with `[agent commit]` for traceability

---

### forge-flow

Issue-driven collaborative development for Gitea/Forgejo forges. Connects Claude Code to your forge via the [gitx-mcp](https://github.com/0xErgod/gitx-mcp) server so the agent can discover, claim, implement, submit, review, and merge work through issues and PRs.

**Requires:** [gitx-mcp](https://github.com/0xErgod/gitx-mcp) MCP server with access to a Gitea or Forgejo instance.

**Commands:**

| Command | Description |
|---------|-------------|
| `/forge-flow:setup` | One-time setup — installs and configures the gitx-mcp server (project or user level) |
| `/forge-flow:triage` | Scan issues, PRs, CI, and notifications to recommend what to work on next |
| `/forge-flow:claim <N>` | Claim issue #N — assign it, create a feature branch, set up working context |
| `/forge-flow:submit` | Create a PR from the current branch, linked to the originating issue |
| `/forge-flow:review <N>` | Review PR #N against its linked issue's requirements — approve or request changes |
| `/forge-flow:merge <N>` | Merge PR #N, close the linked issue, clean up branches |

**Skill:**

| Skill | Description |
|-------|-------------|
| `forge-context` | Passive issue awareness — auto-detects issue context from branch names and guides implementation decisions |

**Hooks:**

| Hook | Trigger | Description |
|------|---------|-------------|
| `post-commit-progress` | After `git commit` | Posts a progress breadcrumb comment to the linked issue |
| `pre-push-check` | Before `git push` | Warns if branch naming is off or the linked issue is closed/reassigned |

**Workflow:**

```
  setup ──→ triage ──→ claim ──→ [implement] ──→ submit ──→ review ──→ merge
               ^                                                         |
               └─────────────────────────────────────────────────────────┘
```

**Quick start:**

```bash
# 1. Configure the MCP server
/forge-flow:setup

# 2. Restart Claude Code, then scan for work
/forge-flow:triage

# 3. Pick up an issue
/forge-flow:claim 31

# 4. ... implement the fix ...

# 5. Submit as PR
/forge-flow:submit

# 6. Review and merge
/forge-flow:review 42
/forge-flow:merge 42
```

## Structure

```
claude-plugins/
├── .claude-plugin/
│   └── marketplace.json        # Plugin registry
├── commit-flow/
│   ├── .claude-plugin/
│   │   └── plugin.json         # Plugin metadata
│   └── commands/
│       └── commit.md           # /commit-flow:commit
├── forge-flow/
│   ├── .claude-plugin/
│   │   └── plugin.json         # Plugin metadata
│   ├── commands/
│   │   ├── setup.md            # /forge-flow:setup
│   │   ├── triage.md           # /forge-flow:triage
│   │   ├── claim.md            # /forge-flow:claim
│   │   ├── submit.md           # /forge-flow:submit
│   │   ├── review.md           # /forge-flow:review
│   │   └── merge.md            # /forge-flow:merge
│   ├── skills/
│   │   └── forge-context/
│   │       └── SKILL.md        # Passive forge awareness
│   └── hooks/
│       ├── post-commit-progress.sh
│       └── pre-push-check.sh
└── CHANGELOG.md
```

## License

MIT
