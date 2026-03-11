---
name: rust-doc-style
description: "Passive doc comment conventions — automatically include /// and //! doc comments when writing or generating Rust code"
allowed-tools:
  - mcp__context7__resolve-library-id
  - mcp__context7__query-docs
  - Read
  - Grep
  - Glob
---

# Rust Doc Style — Passive Doc Comment Conventions

When writing or generating Rust code, always include appropriate `///` and `//!` doc comments as part of the code — not as a separate step.

## When This Skill Activates

Apply this skill whenever you are:

- **Writing new Rust code** — functions, structs, enums, traits, constants, type aliases, modules
- **Generating Rust code** from user descriptions or specifications
- **Adding new public items** to existing `.rs` files
- **Refactoring Rust code** that results in new public API surface

Do NOT activate when:

- Only reading or reviewing existing code (no writes)
- Making trivial changes (renaming, formatting, fixing typos)
- The user explicitly says "no docs" or "skip comments"

## Doc Comment Conventions

### Crate / Module Level (`//!`)

```rust
//! A high-performance concurrent hash map with lock-free reads.
//!
//! This crate provides [`ConcurrentMap`], which supports concurrent reads
//! without locking while serializing writes through a sharded lock scheme.
```

- Use `//!` at the top of `lib.rs`, `main.rs`, or `mod.rs`
- First line: one-sentence summary
- Optional: expanded description with key types linked via `` [`Type`] ``

### Structs

```rust
/// A ring buffer with fixed capacity that overwrites the oldest entries when full.
///
/// Elements are stored contiguously and accessed by index relative to the current head.
pub struct RingBuffer<T> {
    /// The backing storage. Length equals the buffer's capacity.
    buf: Vec<T>,
    /// Index of the next write position, wrapping at capacity.
    head: usize,
    /// Number of elements currently stored (at most `capacity`).
    len: usize,
}
```

- Document the struct itself with a summary
- Document fields that are not self-explanatory
- Skip fields whose purpose is obvious from name + type

### Enums

```rust
/// An error returned when a database query fails.
#[derive(Debug, thiserror::Error)]
pub enum QueryError {
    /// The connection to the database was lost during the query.
    #[error("connection lost")]
    ConnectionLost,
    /// The query timed out after the configured deadline.
    #[error("query timed out after {0:?}")]
    Timeout(Duration),
}
```

- Document the enum and each variant
- Variants should explain when/why that variant occurs

### Functions

```rust
/// Merges two sorted slices into a new sorted vector.
///
/// Both input slices must already be sorted in ascending order. The result
/// contains all elements from both slices, also in ascending order.
///
/// # Panics
///
/// Panics if the total number of elements exceeds `usize::MAX`.
pub fn merge_sorted<T: Ord>(a: &[T], b: &[T]) -> Vec<T>
```

- First line: imperative mood summary
- `# Safety` — **mandatory** for `unsafe fn`; describe invariants the caller must uphold
- `# Panics` — document panic conditions
- `# Errors` — document `Result::Err` variants
- `# Examples` — include when the project style does; examples must compile
- Only document parameters when names + types are insufficient

### Traits

```rust
/// A type that can be serialized to a compact binary representation.
///
/// Implementors must ensure that [`encode`](Self::encode) and [`decode`](Self::decode)
/// are inverses: `decode(encode(x)) == x` for all valid `x`.
pub trait BinaryCodec: Sized {
    /// Encodes `self` into the given byte buffer, returning the number of bytes written.
    fn encode(&self, buf: &mut Vec<u8>) -> usize;
    /// Decodes an instance from the byte slice, returning the value and the number of bytes consumed.
    fn decode(buf: &[u8]) -> Result<(Self, usize), DecodeError>;
}
```

- Document the trait's contract and invariants
- Document each method

### Constants

```rust
/// Maximum number of retries before a request is considered permanently failed.
pub const MAX_RETRIES: u32 = 5;
```

- Explain what the value controls and its implications
- Skip truly obvious constants

### Test Functions

```rust
/// Verifies that concurrent inserts from multiple threads produce
/// the correct final count without data races.
#[test]
fn test_concurrent_inserts() {
```

- Describe the behavior being tested, not the implementation
- Pattern: "Verifies that [condition/action] [expected outcome]"

## Adapting to Project Style

Before generating docs for a new project, detect the existing style:

1. Use Grep to find files with `///` comments: `Grep pattern="^\\s*///" glob="**/*.rs" output_mode="files_with_matches" head_limit=5`
2. Read 2-3 of those files to observe patterns
3. Match the detected style for: `# Examples` usage, intra-doc link style, level of detail, tone, section ordering

**Cache the detected style** for the rest of the session — do not re-scan on every interaction.

If no existing docs are found, use the conventions above as defaults.

## When to Query Context7

Only query Context7 for doc conventions if:

- You are unsure about a Rust-specific documentation pattern (e.g., how to document associated types, GATs, or `unsafe` trait implementations)
- The project uses an unfamiliar `rustdoc` feature you want to verify

First resolve the library:

```
mcp__context7__resolve-library-id  libraryName="The Rust Programming Language Book"
```

Then query with a specific question.

Do NOT query Context7:

- On every interaction — once per session is sufficient
- For general documentation advice unrelated to Rust
- For rustdoc syntax you already know

## How to Apply

- **Include doc comments inline** as you write code — do not generate code first and then add docs as a second pass
- **Match the surrounding file's style** — if the file uses terse one-line docs, do the same; if it uses detailed multi-section docs, match that
- **Use Edit to add docs** to existing undocumented items only when the user is working on that specific code
- **Do not proactively scan and document** an entire file — that's the job of `/rust-lang:doc`
- **Always include `# Safety`** on any `unsafe fn` you write — this is non-negotiable

## What NOT to Do

- Do NOT generate trivial docs that restate the item name (`/// Creates a new Foo` on `Foo::new()` when it's obvious)
- Do NOT announce "I'm adding doc comments" — just include them naturally
- Do NOT add docs to code you are not otherwise modifying
- Do NOT override or remove existing doc comments
- Do NOT add `//!` docs to files other than `lib.rs`, `main.rs`, or `mod.rs` unless the project already does
- Do NOT document private items unless the project style does so
- Do NOT write examples that won't compile — if unsure, omit the `# Examples` section

## Graceful Degradation

- If Context7 is unavailable, use the built-in conventions above — they are sufficient for most projects
- If no existing `.rs` files have doc comments, use the default style without announcing a fallback
- If the project has inconsistent doc styles across files, pick the most common pattern
