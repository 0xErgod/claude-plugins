---
name: move-doc-style
description: "Passive doc comment conventions — automatically include /// doc comments when writing or generating Move code"
allowed-tools:
  - mcp__context7__resolve-library-id
  - mcp__context7__query-docs
  - Read
  - Grep
  - Glob
---

# Move Doc Style — Passive Doc Comment Conventions

When writing or generating Move code, always include appropriate `///` doc comments as part of the code — not as a separate step.

## When This Skill Activates

Apply this skill whenever you are:

- **Writing new Move code** — functions, structs, modules, constants, enums
- **Generating Move code** from user descriptions or specifications
- **Adding new items** to existing `.move` files
- **Refactoring Move code** that results in new public API surface

Do NOT activate when:

- Only reading or reviewing existing code (no writes)
- Making trivial changes (renaming, formatting, fixing typos)
- The user explicitly says "no docs" or "skip comments"

## Doc Comment Conventions

### Module-Level

```move
/// A decentralized exchange module implementing constant-product AMM.
///
/// Supports creating pools, adding/removing liquidity, and swapping coins
/// with configurable fee tiers.
module dex::pool {
```

- First line: one-sentence summary of the module's purpose
- Optional: expanded description after a blank `///` line
- Place before the `module` keyword

### Struct / Enum

```move
/// Configuration for a lending market, controlling interest rates and collateral factors.
public struct MarketConfig has store {
    /// Annual base interest rate in basis points (1 = 0.01%).
    base_rate_bps: u64,
    /// Maximum loan-to-value ratio, as a percentage (e.g., 75 = 75%).
    max_ltv: u64,
}
```

- Document the struct itself with a summary
- Document fields that are not self-explanatory (skip `id: UID`)
- Include units or encoding where applicable (basis points, percentages, timestamps)

### Functions

```move
/// Deposits `amount` of `CoinType` into the user's account and mints corresponding share tokens.
///
/// # Aborts
///
/// * `EMarketPaused` — the market is temporarily paused by governance.
/// * `EZeroAmount` — `amount` is zero.
public fun deposit<CoinType>(account: &mut Account, coin: Coin<CoinType>, clock: &Clock) {
```

- First line: what the function does (imperative mood)
- `# Aborts` section listing abort conditions (if any)
- `# Type Parameters` if generics are non-obvious
- Only document parameters when their purpose isn't clear from name + type
- Skip `# Returns` if the return type is self-explanatory

### Constants

```move
/// The caller does not have admin privileges for this operation.
const ENotAdmin: u64 = 1;

/// Maximum number of active markets allowed per protocol instance.
const MAX_MARKETS: u64 = 128;
```

- Error constants (`E` prefix) are high priority — always document
- Numeric configuration constants: explain what the value controls
- Skip truly obvious constants

### Test Functions

```move
/// Verifies that withdrawing the full balance leaves the account empty and succeeds.
#[test]
fun test_full_withdrawal() {
```

- Describe the behavior being tested, not the implementation
- Pattern: "Verifies that [condition/action] [expected outcome]"

## Adapting to Project Style

Before generating docs for a new project, detect the existing style:

1. Use Grep to find files with `///` comments: `Grep pattern="^\\s*///" glob="**/*.move" output_mode="files_with_matches" head_limit=5`
2. Read 2-3 of those files to observe patterns
3. Match the detected style for: heading format, parameter documentation style, level of detail, tone

**Cache the detected style** for the rest of the session — do not re-scan on every interaction.

If no existing docs are found, use the conventions above as defaults.

## When to Query Context7

Only query Context7 for doc conventions if:

- You are unsure about a Move-specific documentation pattern (e.g., how to document phantom types, abilities, or object ownership)
- The project uses an unfamiliar convention you want to verify

Query: `mcp__context7__query-docs libraryId="/websites/move-book" query="doc comments documentation style"`

Do NOT query Context7:

- On every interaction — once per session is sufficient
- If the `move-context` skill already fetched relevant doc information in this session
- For general documentation advice unrelated to Move

## How to Apply

- **Include doc comments inline** as you write code — do not generate code first and then add docs as a second pass
- **Match the surrounding file's style** — if the file uses terse one-line docs, do the same; if it uses detailed multi-line docs, match that
- **Use Edit to add docs** to existing undocumented items only when the user is working on that specific code
- **Do not proactively scan and document** an entire file — that's the job of `/move-lang:doc`

## What NOT to Do

- Do NOT generate trivial docs that restate the item name (`/// The foo function` on `fun foo()`)
- Do NOT announce "I'm adding doc comments" — just include them naturally
- Do NOT add docs to code you are not otherwise modifying
- Do NOT override or remove existing doc comments
- Do NOT add `//!` inner docs unless the project already uses them
- Do NOT document every single field — skip `id: UID` and other framework-standard fields
- Do NOT add parameter docs when names and types are self-explanatory

## Interaction with move-context

- If `move-context` has already queried Context7 in this session, reuse that knowledge rather than re-querying
- `move-context` provides language awareness; this skill provides documentation conventions — they complement each other
- If `move-context` is not active, this skill still functions independently using its built-in conventions

## Graceful Degradation

- If Context7 is unavailable, use the built-in conventions above — they are sufficient for most projects
- If no existing `.move` files have doc comments, use the default style without announcing a fallback
- If the project has inconsistent doc styles across files, pick the most common pattern
