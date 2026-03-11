---
description: "Bulk-generate or update /// and //! doc comments across Rust source files"
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

# /rust-lang:doc — Rust Doc Comment Generator

Generate or update `///` and `//!` doc comments across `.rs` files in a project.

## Arguments

```
/rust-lang:doc [<path>] [--dry-run] [--tests-only] [--force]
```

| Argument | Description |
|---|---|
| `<path>` | Directory or file to process (default: current working directory) |
| `--dry-run` | Show what would be documented without making changes |
| `--tests-only` | Only document `#[test]` and `#[cfg(test)]` items |
| `--force` | Overwrite existing doc comments instead of augmenting them |

Parse these from the `$ARGUMENTS` string. Any unrecognized flags should be ignored with a warning.

## Workflow

### Step 1: Fetch Current Doc Conventions

Query Context7 for Rust doc comment conventions. First resolve the library ID:

```
mcp__context7__resolve-library-id  libraryName="The Rust Programming Language Book"
```

Then query:

```
mcp__context7__query-docs  libraryId="<resolved-id>"  query="documentation comments rustdoc conventions /// //! examples"
```

Also try resolving the Rust standard library or Rust by Example for supplementary conventions.

If Context7 is unavailable or returns nothing useful, fall back to these built-in conventions:

- `///` for outer doc comments (items: functions, structs, enums, traits, constants, type aliases, modules from outside)
- `//!` for inner doc comments (crate-level and module-level docs at the top of `lib.rs`, `main.rs`, or `mod.rs`)
- First line: brief summary sentence (imperative mood for functions)
- Blank `///` line separates summary from details
- Use `/// # Examples` with a fenced code block — examples should compile and are tested by `cargo test --doc`
- Use `/// # Panics` to document conditions that cause a panic
- Use `/// # Errors` to document `Result::Err` variants returned
- Use `/// # Safety` for `unsafe` functions — describe invariants the caller must uphold
- Use `/// # Arguments` only when parameter purpose is non-obvious
- Link related items with `` [`OtherType`] `` intra-doc link syntax

### Step 2: Discover Target Files

Use Glob to find `.rs` files:

- If `<path>` is provided and is a file, process only that file
- If `<path>` is provided and is a directory, glob `<path>/**/*.rs`
- If no `<path>`, glob `**/*.rs` from the working directory

Exclude paths containing `target/` directories.

**If more than 20 files are found**, ask the user to confirm before proceeding. Show the count and list a few example paths.

### Step 3: Detect Project Style

Before generating any docs, analyze existing `///` and `//!` patterns in 3-5 files (pick files that already have some doc comments):

- Do they include `# Examples` sections with code blocks?
- Do they use intra-doc links (`` [`Type`] ``)?
- Do they document error variants individually or in prose?
- What tone — terse or detailed?
- Do they include `# Panics` / `# Errors` / `# Safety` sections?
- Do they use `//!` at the crate root?

Use this detected style for all generated docs. If no existing docs are found, use the conventions from Step 1.

### Step 4: Process Each File

For each `.rs` file, Read the file and identify items that need documentation:

**Items to document:**
- `//!` crate/module-level docs (for `lib.rs`, `main.rs`, `mod.rs` — only if missing)
- `pub struct` / `struct` declarations
- `pub enum` / `enum` declarations (and their variants)
- `pub trait` / `trait` declarations
- `pub fn` / `fn` declarations
- `pub const` / `const` declarations
- `pub type` / `type` alias declarations
- `impl` blocks (the `impl` line itself, if it implements a notable trait)
- `pub mod` declarations (in parent files)
- `#[test]` functions
- `unsafe fn` — these MUST get `# Safety` docs

**For each undocumented item** (or all items if `--force`):

1. Read the item's signature and body to understand its purpose
2. Generate a `///` doc comment following the detected project style
3. For `unsafe` functions, always include a `# Safety` section
4. For functions returning `Result`, include a `# Errors` section
5. For functions that can panic, include a `# Panics` section
6. Apply using Edit (place the comment directly above the item, after any attributes)

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
```rust
/// Returns the length.
pub fn len(&self) -> usize
```

Good (adds meaningful context):
```rust
/// Returns the number of elements currently stored in the buffer, not including
/// items that have been popped but not yet deallocated.
pub fn len(&self) -> usize
```

If you cannot add meaningful information beyond the name, skip the item and count it as "skipped."

### Unsafe Functions Must Have Safety Docs

```rust
/// Reconstructs a `Vec<T>` from a raw pointer, length, and capacity.
///
/// # Safety
///
/// - `ptr` must have been allocated by the same allocator that backs `Vec`.
/// - `length` must be less than or equal to `capacity`.
/// - The first `length` elements must be properly initialized values of type `T`.
pub unsafe fn from_raw_parts(ptr: *mut T, length: usize, capacity: usize) -> Vec<T>
```

### Error-Returning Functions Document Error Variants

```rust
/// Parses a configuration file at the given path.
///
/// # Errors
///
/// Returns `ConfigError::NotFound` if the file does not exist.
/// Returns `ConfigError::ParseFailed` if the file contains invalid TOML.
pub fn parse_config(path: &Path) -> Result<Config, ConfigError>
```

### Enum Variants Get Their Own Docs

```rust
/// Represents the current state of a network connection.
pub enum ConnectionState {
    /// The connection has not yet been established.
    Disconnected,
    /// A handshake is in progress with the remote peer.
    Connecting { attempt: u32 },
    /// The connection is active and ready for data transfer.
    Connected,
}
```

### Test Functions Describe Behavior

```rust
/// Verifies that pushing beyond capacity triggers a reallocation
/// and all elements remain accessible.
#[test]
fn test_push_beyond_capacity() {
```

### Never Delete Existing Docs

- If an item already has `///` comments and `--force` is not set, skip it
- If `--force` is set, replace the existing comment block but preserve manually-written sections containing information not inferrable from code
- Never remove `///` or `//!` lines without replacing them

### Include Examples When Appropriate

If the project style includes `# Examples`, generate compilable examples:

```rust
/// Splits a string on whitespace and returns the parts as a vector.
///
/// # Examples
///
/// ```
/// let parts = my_crate::split_words("hello world");
/// assert_eq!(parts, vec!["hello", "world"]);
/// ```
pub fn split_words(input: &str) -> Vec<&str>
```

Examples must be valid Rust that would pass `cargo test --doc`.

## Error Handling

- If a file cannot be read, warn and continue to the next file
- If an Edit fails, warn and continue — do not abort the entire run
- If Context7 is unavailable, proceed with built-in conventions (note once at the start)
