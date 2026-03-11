---
name: ts-doc-style
description: "Passive doc comment conventions — automatically include JSDoc/TSDoc comments when writing or generating TypeScript code"
allowed-tools:
  - mcp__context7__resolve-library-id
  - mcp__context7__query-docs
  - Read
  - Grep
  - Glob
---

# TypeScript Doc Style — Passive Doc Comment Conventions

When writing or generating TypeScript code, always include appropriate `/** */` doc comments as part of the code — not as a separate step.

## When This Skill Activates

Apply this skill whenever you are:

- **Writing new TypeScript code** — functions, classes, interfaces, types, enums, constants, React components
- **Generating TypeScript code** from user descriptions or specifications
- **Adding new exported items** to existing `.ts` / `.tsx` files
- **Refactoring TypeScript code** that results in new public API surface

Do NOT activate when:

- Only reading or reviewing existing code (no writes)
- Making trivial changes (renaming, formatting, fixing typos)
- The user explicitly says "no docs" or "skip comments"
- Writing internal implementation details with self-explanatory signatures

## Doc Flavor Detection

TypeScript projects use either JSDoc or TSDoc conventions. Detect once per session:

1. Check for `tsdoc.json` or `api-extractor.json` — if present, use TSDoc
2. Scan a few existing `/** */` comments for TSDoc markers (`{@link}`, `@remarks`, `@beta`) vs JSDoc markers (`@see`, `@throws {Type}`)
3. Default to JSDoc if unclear

**Cache the detected flavor** for the rest of the session.

## Doc Comment Conventions

### Functions

```typescript
/**
 * Debounces a function so it only fires after `delay` ms of inactivity.
 *
 * Returns a new function that delays invoking `fn` until after `delay`
 * milliseconds have elapsed since the last invocation.
 *
 * @param fn - The function to debounce.
 * @param delay - Milliseconds to wait after the last call.
 * @returns A debounced version of `fn` with a `.cancel()` method.
 */
export function debounce<T extends (...args: any[]) => void>(
  fn: T,
  delay: number,
): DebouncedFunction<T>
```

- First line: concise summary (what it does, not how)
- `@param` for non-obvious parameters — skip when name + type are self-explanatory
- `@returns` only when the return value needs explanation beyond the type
- `@throws` for thrown errors (with `{ErrorType}` for JSDoc, without for TSDoc)

### Interfaces and Types

```typescript
/**
 * Configuration for the application's database connection pool.
 */
export interface PoolConfig {
  /** PostgreSQL connection string (e.g., `"postgresql://user:pass@host/db"`). */
  connectionString: string;
  /** Maximum number of connections in the pool. Defaults to `10`. */
  maxConnections?: number;
  /**
   * Time in milliseconds to wait for a connection before throwing.
   * Set to `0` to disable the timeout.
   */
  acquireTimeout?: number;
}
```

- Document the interface/type with a summary
- Document members that are not self-explanatory from name + type
- Include defaults, units, format examples where helpful
- Skip members where name + type tell the full story

### Classes

```typescript
/**
 * Manages WebSocket connections with automatic reconnection and message buffering.
 *
 * Messages sent while disconnected are buffered and flushed upon reconnection.
 */
export class WebSocketManager {
  /**
   * Creates a new WebSocket manager.
   *
   * @param url - The WebSocket server URL.
   * @param options - Reconnection and buffering configuration.
   */
  constructor(url: string, options?: WebSocketOptions) {}

  /**
   * Sends a message to the server, buffering it if currently disconnected.
   *
   * @param message - The payload to send, serialized as JSON.
   * @throws {ConnectionError} If the buffer is full and `options.dropOnOverflow` is false.
   */
  send(message: unknown): void {}
}
```

- Document the class, constructor, and public methods
- Skip private methods unless the project style documents them
- Include `@throws` for methods that throw

### Enums

```typescript
/** The current status of an order in the fulfillment pipeline. */
export enum OrderStatus {
  /** Order received but not yet processed. */
  Pending = "pending",
  /** Order has been picked and packed for shipment. */
  Shipped = "shipped",
  /** Order was delivered to the customer. */
  Delivered = "delivered",
  /** Order was cancelled before shipment. */
  Cancelled = "cancelled",
}
```

- Document the enum and each member

### React Components

```typescript
/**
 * A searchable dropdown that fetches options asynchronously as the user types.
 *
 * Renders a text input with a dropdown list. Options are fetched via `onSearch`
 * after the user stops typing for 300ms.
 *
 * @param props.onSearch - Called with the search query; should return matching options.
 * @param props.onSelect - Called when the user picks an option from the dropdown.
 * @param props.placeholder - Placeholder text shown when the input is empty.
 */
export function AsyncSelect<T>({ onSearch, onSelect, placeholder }: AsyncSelectProps<T>)
```

- Describe what the component renders and its key interactive behavior
- Document non-obvious props; skip standard ones (`className`, `style`, `children`)

### Constants and Configuration

```typescript
/** Default timeout in milliseconds for all HTTP requests made by the API client. */
export const DEFAULT_TIMEOUT = 30_000;

/**
 * Rate limit tiers mapping plan names to requests-per-minute.
 * Used by the rate limiter middleware to enforce per-user limits.
 */
export const RATE_LIMITS: Record<Plan, number> = {
  free: 60,
  pro: 600,
  enterprise: 6000,
};
```

- Explain what the value controls
- Include units where applicable

### Test Files

```typescript
/**
 * Tests the payment processing flow including charge creation,
 * refunds, and webhook signature verification.
 */
describe("PaymentService", () => {
```

- Only document the top-level `describe` block
- Individual `it`/`test` blocks already have descriptive strings

## Adapting to Project Style

Before generating docs for a new project, detect the existing style:

1. Use Grep to find files with doc comments: `Grep pattern="^\\s*/\\*\\*" glob="**/*.{ts,tsx}" output_mode="files_with_matches" head_limit=5`
2. Read 2-3 of those files to observe patterns
3. Match the detected style for: parameter documentation, `@returns` usage, level of detail, tone

**Cache the detected style** for the rest of the session — do not re-scan on every interaction.

If no existing docs are found, use the conventions above as defaults.

## When to Query Context7

Only query Context7 for doc conventions if:

- You are unsure about a TSDoc-specific tag or convention
- The project uses a documentation tool (TypeDoc, API Extractor) with specific requirements you want to verify

Do NOT query Context7:

- On every interaction — once per session is sufficient
- For standard JSDoc tags you already know
- For general documentation advice unrelated to TypeScript

## How to Apply

- **Include doc comments inline** as you write code — do not generate code first and then add docs as a second pass
- **Match the surrounding file's style** — if the file uses terse single-line `/** summary */`, do the same; if it uses multi-line with `@param` tags, match that
- **Use Edit to add docs** to existing undocumented items only when the user is working on that specific code
- **Do not proactively scan and document** an entire file — that's the job of `/ts-lang:doc`
- **Respect the detected flavor** — do not mix JSDoc and TSDoc conventions in the same project

## What NOT to Do

- Do NOT generate trivial docs that restate the name (`/** The user service */` on `class UserService`)
- Do NOT announce "I'm adding doc comments" — just include them naturally
- Do NOT add docs to code you are not otherwise modifying
- Do NOT override or remove existing doc comments
- Do NOT use `@type`, `@typedef`, or `@callback` in TypeScript — the type system handles these
- Do NOT document every single prop — skip `className`, `style`, `children`, and other standard React props
- Do NOT use `@param` when the parameter name and type make the purpose obvious (e.g., `@param id - The id` is useless)

## Graceful Degradation

- If Context7 is unavailable, use the built-in conventions above — they are sufficient for most projects
- If no existing `.ts`/`.tsx` files have doc comments, use the default style without announcing a fallback
- If the project mixes JSDoc and TSDoc, pick the more common one and stay consistent
