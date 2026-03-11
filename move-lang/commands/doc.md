---
description: "Bulk-generate or update /// doc comments across Move source and test files"
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Edit
  - Write
  - mcp__context7__resolve-library-id
  - mcp__context7__query-docs
---

# /move-lang:doc — Move Doc Comment Generator

Generate or update `///` doc comments across `.move` files in a project.

## Arguments

```
/move-lang:doc [<path>] [--dry-run] [--tests-only] [--force]
```

| Argument | Description |
|---|---|
| `<path>` | Directory or file to process (default: current working directory) |
| `--dry-run` | Show what would be documented without making changes |
| `--tests-only` | Only document `#[test]` and `#[test_only]` functions |
| `--force` | Overwrite existing doc comments instead of augmenting them |

Parse these from the `$ARGUMENTS` string. Any unrecognized flags should be ignored with a warning.

## Workflow

### Step 1: Fetch Current Doc Conventions

Query Context7 for the latest Move doc comment conventions:

```
mcp__context7__query-docs  libraryId="/websites/move-book"  query="doc comments documentation conventions /// style"
```

If Context7 is unavailable or returns nothing useful, fall back to these built-in conventions:

- `///` for item-level docs (modules, structs, functions, constants)
- `//!` for inner module-level docs (rarely used in Move — prefer `///` before `module`)
- First line: brief summary sentence
- Blank `///` line separates summary from details
- Use `/// # Aborts` section for abort conditions
- Use `/// # Type Parameters` for generic explanations
- Use `/// # Arguments` or `/// # Parameters` for function parameters (only when non-obvious)
- Use `/// # Returns` only when the return value is non-obvious

### Step 2: Discover Target Files

Use Glob to find `.move` files:

- If `<path>` is provided and is a file, process only that file
- If `<path>` is provided and is a directory, glob `<path>/**/*.move`
- If no `<path>`, glob `**/*.move` from the working directory

Exclude paths containing `build/` or `.build/` directories.

**If more than 20 files are found**, ask the user to confirm before proceeding. Show the count and list a few example paths.

### Step 3: Detect Project Style

Before generating any docs, analyze existing `///` patterns in 3-5 files (pick files that already have some doc comments):

- What heading style do they use? (`# Aborts` vs `Aborts:` vs inline)
- Do they document parameters individually or in prose?
- Do they include examples?
- What tone — terse or detailed?
- Do they use `@param`/`@return` tags (non-standard but some projects use them)?

Use this detected style for all generated docs. If no existing docs are found, use the conventions from Step 1.

### Step 4: Process Each File

For each `.move` file, Read the file and identify items that need documentation:

**Items to document:**
- `module` declarations
- `public struct` / `struct` declarations
- `public fun` / `public(package) fun` / `fun` declarations
- `const` declarations (especially error codes like `const ENotOwner: u64 = 1;`)
- `#[test]` / `#[test_only]` functions (describe what behavior is being tested)
- `public enum` / `enum` declarations

**For each undocumented item** (or all items if `--force`):

1. Read the item's signature and body to understand its purpose
2. Generate a `///` doc comment following the detected project style
3. Apply using Edit (place the comment directly above the item, after any attributes like `#[test]`)

**If `--dry-run`**: instead of editing, collect and display what would be added.

**If `--tests-only`**: skip non-test items.

### Step 5: Report Summary

After processing, report:

```
Doc comment generation complete:
  Files scanned:    <N>
  Items documented: <N> (new)
  Items updated:    <N> (augmented existing)
  Items skipped:    <N> (already documented / trivial)
```

If `--dry-run`, prefix with "Dry run — no changes made:"

## Doc Comment Quality Rules

### Never Generate Trivial Docs

Bad (restates the name):
```move
/// Gets the balance
public fun get_balance(account: &Account): u64
```

Good (adds meaningful context):
```move
/// Returns the spendable balance for the account, excluding any locked or staked amounts.
public fun get_balance(account: &Account): u64
```

If you cannot add meaningful information beyond the name, skip the item and count it as "skipped."

### Error Constants Get Clear Docs

Error constants are especially important to document:

```move
/// The caller is not the owner of the object.
/// Used in access-control checks for admin-only operations.
const ENotOwner: u64 = 1;
```

### Test Functions Describe Behavior

```move
/// Verifies that transferring more than the available balance aborts with `EInsufficientBalance`.
#[test]
fun test_transfer_insufficient_balance()
```

### Never Delete Existing Docs

- If an item already has `///` comments and `--force` is not set, skip it
- If `--force` is set, replace the existing comment block but preserve any manually-written sections that contain information not inferrable from the code (use judgment)
- Never remove `///` lines without replacing them

### Struct Field Docs

When documenting structs, also document non-obvious fields:

```move
/// A liquidity pool for a trading pair.
public struct Pool<phantom CoinA, phantom CoinB> has key {
    id: UID,
    /// Reserve of coin A held in the pool.
    reserve_a: Balance<CoinA>,
    /// Reserve of coin B held in the pool.
    reserve_b: Balance<CoinB>,
    /// Accumulated protocol fees, in basis points of each swap.
    fee_bps: u64,
}
```

## Error Handling

- If a file cannot be read, warn and continue to the next file
- If an Edit fails, warn and continue — do not abort the entire run
- If Context7 is unavailable, proceed with built-in conventions (note once at the start)
