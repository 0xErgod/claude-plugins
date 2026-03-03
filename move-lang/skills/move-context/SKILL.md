---
name: move-context
description: Passive Move/SUI awareness — consult up-to-date Move Book and SUI docs via Context7 MCP when writing, reviewing, or reasoning about Move code
allowed-tools:
  - mcp__context7__resolve-library-id
  - mcp__context7__query-docs
  - Read
  - Grep
  - Glob
---

# Move Context — Passive SUI/Move Documentation Awareness

You are working in a project that uses the **Move programming language** on the **SUI blockchain**. This skill ensures you always consult the most up-to-date documentation when writing, reviewing, or reasoning about Move code.

## When This Skill Activates

Apply this skill whenever you detect Move code (`.move` files) in the project or the user is discussing Move/SUI development. This awareness is always-on — you do NOT need the user to invoke it.

## Dependency: Context7 MCP Server

This skill requires the `context7` MCP server. If the `mcp__context7__resolve-library-id` or `mcp__context7__query-docs` tools are not available, skip all doc-fetching behavior and fall back to your training data. Note once: "Context7 MCP is not configured — using training data, which may be outdated for Move/SUI."

## Documentation Sources (Context7 Library IDs)

Use these pre-resolved library IDs directly with `mcp__context7__query-docs` — no need to call `resolve-library-id` first:

| Source | Library ID | Use For |
|---|---|---|
| **The Move Book** | `/websites/move-book` | Language fundamentals, module structure, generics, abilities, patterns, testing, object model |
| **SUI Documentation** | `/websites/sui_io` | SUI-specific APIs, object ownership, coin/token standards, framework modules, deployment, PTBs |
| **SUI Source (MystenLabs)** | `/mystenlabs/sui` | Framework module source, deep implementation details, internal APIs |
| **SUI TypeScript SDK** | `/websites/sdk_mystenlabs` | TypeScript client integration, transaction building, RPC queries |

### How to Query

Call `mcp__context7__query-docs` with a specific, focused query:

```
mcp__context7__query-docs  libraryId="/websites/move-book"  query="How do phantom type parameters work in Move?"
mcp__context7__query-docs  libraryId="/websites/sui_io"     query="shared vs owned objects and object ownership model"
mcp__context7__query-docs  libraryId="/mystenlabs/sui"      query="sui::coin module public functions"
```

### Choose the Right Source

- **Move Book** → language-level questions: syntax, abilities (`copy`, `drop`, `store`, `key`), generics, modules, testing, design patterns
- **SUI Docs** → platform-level questions: object model, transactions, PTBs, coin operations, publishing, upgrades, framework modules, CLI usage
- **SUI Source** → when you need exact function signatures, implementation details, or framework internals not covered in docs
- **SUI TS SDK** → only when the user is working on TypeScript client code that interacts with SUI

## When to Consult Docs

### Proactively Query When:

- **Writing new Move code** — check current patterns for the feature you're implementing (e.g., object wrapping, dynamic fields, events, package upgrades)
- **Reviewing Move code** — verify that patterns match current best practices before suggesting changes
- **Answering Move questions** — do not rely solely on training data; Move and SUI evolve rapidly
- **Debugging Move errors** — look up error codes, ability constraints, or borrow-checker rules
- **Using SUI framework modules** — check the current API for `sui::coin`, `sui::transfer`, `sui::object`, `sui::event`, `sui::dynamic_field`, etc.

### Do NOT Query When:

- The task is trivial (renaming a variable, fixing a typo, formatting)
- You already fetched the same information earlier in this session
- The question is about general Rust/programming concepts, not Move-specific

## How to Use the Context

- **Before writing Move code**, query relevant docs to confirm the current API surface and recommended patterns
- **When the user asks "how do I..."**, consult the docs before answering — your training data may be outdated for Move/SUI specifics
- **When you see an unfamiliar SUI module or function**, look it up rather than guessing the signature
- **Integrate naturally** — do not announce "I checked the docs." Just produce correct, up-to-date code and explanations

## What NOT to Do

- Do NOT rely solely on training data for Move/SUI specifics — the ecosystem changes frequently
- Do NOT fetch docs on every single interaction — only when you need to verify current patterns
- Do NOT query all four sources when only one is relevant — pick the right one
- Do NOT announce "I'm using the move-context skill" — just use the context naturally
- Do NOT call `resolve-library-id` for these sources — the IDs above are pre-resolved
- Do NOT query the same thing repeatedly within a session — remember what you've already learned

## Graceful Degradation

- If Context7 MCP tools are unavailable, fall back to training data and note it once
- If a query returns empty or irrelevant results, try rephrasing or checking a different source
- Do not retry failed queries more than once
