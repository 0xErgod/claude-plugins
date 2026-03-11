---
description: "Bulk-generate or update JSDoc/TSDoc comments across TypeScript source and test files"
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

# /ts-lang:doc — TypeScript Doc Comment Generator

Generate or update `/** */` JSDoc/TSDoc comments across `.ts` and `.tsx` files in a project.

## Arguments

```
/ts-lang:doc [<path>] [--dry-run] [--tests-only] [--force] [--jsdoc | --tsdoc]
```

| Argument | Description |
|---|---|
| `<path>` | Directory or file to process (default: current working directory) |
| `--dry-run` | Show what would be documented without making changes |
| `--tests-only` | Only document test files (`*.test.ts`, `*.spec.ts`) |
| `--force` | Overwrite existing doc comments instead of augmenting them |
| `--jsdoc` | Use JSDoc conventions (default: auto-detect) |
| `--tsdoc` | Use TSDoc conventions (default: auto-detect) |

Parse these from the `$ARGUMENTS` string. Any unrecognized flags should be ignored with a warning.

## Workflow

### Step 1: Fetch Current Doc Conventions

Query Context7 for TypeScript doc comment conventions. First resolve the library ID:

```
mcp__context7__resolve-library-id  libraryName="TypeScript documentation"
```

Then query:

```
mcp__context7__query-docs  libraryId="<resolved-id>"  query="JSDoc TSDoc documentation comments conventions"
```

If Context7 is unavailable or returns nothing useful, fall back to these built-in conventions:

**JSDoc style:**
- `/** */` block comments above the item
- `@param name - Description` for parameters
- `@returns Description` for return values
- `@throws {ErrorType} Description` for thrown errors
- `@example` with code block for usage examples
- `@see` for cross-references
- `@deprecated Reason` for deprecated items
- Do NOT use `@type`, `@typedef`, or `@callback` in TypeScript — the type system handles these

**TSDoc style (stricter):**
- Same `/** */` block comments
- `@param name - Description` (dash required)
- `@returns Description`
- `@throws Description` (no `{ErrorType}` — use inline `{@link}` instead)
- `{@link SymbolName}` for cross-references (not `@see`)
- `@example` blocks
- `@remarks` for extended discussion separate from summary
- `@beta`, `@alpha`, `@internal` for release tags

### Step 2: Detect Doc Flavor (JSDoc vs TSDoc)

Unless `--jsdoc` or `--tsdoc` is specified, auto-detect by scanning existing comments:

- Look for TSDoc markers: `{@link}`, `@remarks`, `@beta`, `@alpha`, `@internal`
- Look for JSDoc markers: `@see`, `@throws {Type}`, `@typedef`
- Check for a `tsdoc.json` or `api-extractor.json` file (indicates TSDoc)
- Default to JSDoc if unclear — it's more widely used

### Step 3: Discover Target Files

Use Glob to find TypeScript files:

- If `<path>` is provided and is a file, process only that file
- If `<path>` is provided and is a directory, glob `<path>/**/*.{ts,tsx}`
- If no `<path>`, glob `**/*.{ts,tsx}` from the working directory

Exclude paths containing `node_modules/`, `dist/`, `build/`, `.next/`, `coverage/` directories.

**If more than 20 files are found**, ask the user to confirm before proceeding. Show the count and list a few example paths.

### Step 4: Detect Project Style

Before generating any docs, analyze existing `/** */` patterns in 3-5 files (pick files that already have some doc comments):

- Do they document all parameters or only non-obvious ones?
- Do they include `@example` sections?
- Do they use `@returns` or omit it for obvious return types?
- What tone — terse or detailed?
- Do they include `@throws`?
- Do they document interfaces/types or just functions?

Use this detected style for all generated docs. If no existing docs are found, use the conventions from Step 1.

### Step 5: Process Each File

For each `.ts`/`.tsx` file, Read the file and identify items that need documentation:

**Items to document:**
- `export function` / `function` declarations
- `export class` declarations (and their public methods, constructor, properties)
- `export interface` declarations (and their members)
- `export type` declarations (non-trivial ones — skip simple aliases)
- `export const` / `export let` declarations (especially configuration objects, constants)
- `export enum` declarations (and their members)
- `export default` items
- Test functions (`describe`, `it`, `test` blocks) — only the top-level `describe` needs a doc comment
- React components (`export function Component()` or `export const Component = ()`)

**For each undocumented item** (or all items if `--force`):

1. Read the item's signature and body to understand its purpose
2. Generate a `/** */` doc comment following the detected project style
3. For functions: include `@param` for non-obvious parameters, `@returns` for non-obvious returns, `@throws` for thrown errors
4. For React components: describe what the component renders and its key props
5. Apply using Edit (place the comment directly above the item, after any decorators)

**If `--dry-run`**: instead of editing, collect and display what would be added.

**If `--tests-only`**: only process test files.

### Step 6: Report Summary

After processing, report:

```
Doc comment generation complete:
  Files scanned:    <N>
  Items documented: <N> (new)
  Items updated:    <N> (augmented existing)
  Items skipped:    <N> (already documented / trivial)
  Doc flavor:       JSDoc | TSDoc (auto-detected | specified)
```

If `--dry-run`, prefix with "Dry run — no changes made:"

## Doc Comment Quality Rules

### Never Generate Trivial Docs

Bad (restates the name):
```typescript
/** Gets the user name. */
function getUserName(user: User): string
```

Good (adds meaningful context):
```typescript
/**
 * Returns the display name for a user, falling back to their email
 * prefix if no display name is set.
 */
function getUserName(user: User): string
```

If you cannot add meaningful information beyond the name, skip the item and count it as "skipped."

### Interfaces and Types Get Clear Docs

```typescript
/**
 * Options for configuring the retry behavior of API calls.
 */
export interface RetryOptions {
  /** Maximum number of retry attempts before giving up. */
  maxRetries: number;
  /**
   * Base delay in milliseconds between retries. Actual delay uses
   * exponential backoff: `baseDelay * 2^attempt`.
   */
  baseDelay: number;
  /** HTTP status codes that should trigger a retry. Defaults to `[429, 500, 502, 503]`. */
  retryableStatuses?: number[];
}
```

### React Components Document Props and Behavior

```typescript
/**
 * Renders a paginated data table with sortable columns and row selection.
 *
 * Supports server-side pagination via the `onPageChange` callback, or
 * client-side pagination when all data is provided upfront.
 *
 * @param props.data - The rows to display on the current page.
 * @param props.columns - Column definitions including header, accessor, and sort config.
 * @param props.onPageChange - Called when the user navigates to a different page.
 */
export function DataTable<T>({ data, columns, onPageChange }: DataTableProps<T>)
```

### Test Suites Describe Behavior

```typescript
/**
 * Tests the authentication flow including login, token refresh,
 * and session expiration handling.
 */
describe("AuthService", () => {
```

Only document the top-level `describe` — individual `it`/`test` blocks have descriptive strings already.

### Never Delete Existing Docs

- If an item already has `/** */` comments and `--force` is not set, skip it
- If `--force` is set, replace the existing comment block but preserve manually-written information
- Never remove `/** */` blocks without replacing them

### Overloaded Functions

Document each overload signature separately:

```typescript
/**
 * Formats a date as a localized string.
 * @param date - The date to format.
 * @param locale - BCP 47 language tag (e.g., `"en-US"`).
 */
export function formatDate(date: Date, locale: string): string;
/**
 * Formats a Unix timestamp as a localized string.
 * @param timestamp - Milliseconds since epoch.
 * @param locale - BCP 47 language tag.
 */
export function formatDate(timestamp: number, locale: string): string;
```

## Error Handling

- If a file cannot be read, warn and continue to the next file
- If an Edit fails, warn and continue — do not abort the entire run
- If Context7 is unavailable, proceed with built-in conventions (note once at the start)
