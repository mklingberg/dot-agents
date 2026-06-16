# React / TypeScript / Apollo Client review reference

Loaded when the diff contains `.ts`/`.tsx` or a `package.json` with React/Apollo.
Apply on top of the universal pillars in SKILL.md. Stack-specific defects only —
generic correctness/security/perf live in the universal pillars.

---

## TypeScript

- **No `any` past the API edge.** External boundaries (fetch, GraphQL responses, `JSON.parse`) parse with Zod (or equivalent) into typed shapes. Internal code never sees `any`.
- **No `as` casts to silence the compiler.** Cast only when narrowing a known runtime invariant; comment why. `as unknown as T` is a smell.
- **`unknown` over `any`** for genuinely unknown values; force narrowing.
- **Discriminated unions** for state machines (`{ status: 'loading' } | { status: 'error', error } | { status: 'ok', data }`). No optional-everything blobs.
- **`readonly` arrays / `as const`** for fixed data; prevents accidental mutation.
- **No non-null assertions (`!`)** in product code unless the invariant is enforced one line above.
- **Strict mode on.** `strict`, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes` ideally enabled — flag if disabled without reason.

## React — hooks

- **Stale closures in `useEffect` / `useCallback` / `useMemo`.** Every referenced value must be in deps, or the dep must be a ref. The `react-hooks/exhaustive-deps` lint rule should not be disabled per-line without justification.
- **Effects that should be event handlers.** If logic runs in response to a user action, put it in the handler — not an effect keyed off state. Effects synchronize with external systems; they are not a generic "do this when X changes" hook.
- **Derived state.** If a `useState` is computed from props or other state, derive it inline or with `useMemo`. Don't store derived state and sync it via `useEffect`.
- **Refs vs state.** Mutable values that don't drive rendering → `useRef`. Don't `useState` something you never render.
- **Custom hooks** named `use*` and obey hook rules. Pure logic helpers should be regular functions.
- **`useMemo` / `useCallback` only when profiled or required for referential stability** (deps of another hook, props to memoized child). Reflexive memoization is noise and can hurt perf.
- **`useLayoutEffect`** only for synchronous DOM measurements. Otherwise `useEffect`.

## React — rendering & components

- **`key` on lists** must be stable and unique per item. Index keys only when the list is append-only and never reordered.
- **Conditional hooks / hooks in loops** — never. Will break.
- **Component size.** > 200 lines or > 5 hooks → split. Co-locate state with where it's used.
- **Prop drilling > 2 levels** → context, composition, or state colocation.
- **Server vs client components (Next.js App Router).** `'use client'` boundary minimized — pushed as deep as possible. Server components must not import client-only APIs (browser globals, `useState`, event handlers). Server data fetched server-side, not refetched on client.
- **Suspense + Error boundaries** — every async boundary has both, scoped tightly to the loading region. Don't wrap the whole app in one suspense.
- **Forms** controlled or uncontrolled, not both. Library (`react-hook-form`) preferred over hand-rolled for non-trivial forms.

## Accessibility

- **Semantic elements** before ARIA. `<button>`, `<a href>`, `<label htmlFor>`, `<nav>`, `<main>`. ARIA only when no semantic element fits.
- **Interactive elements** keyboard-reachable: focusable, visible focus ring, Enter/Space activation.
- **Labels** on every form input (`<label htmlFor>` or `aria-label`). Placeholders are not labels.
- **Color contrast** ≥ 4.5:1 for body text (WCAG AA). Flag pure-color state indicators.
- **Images** have `alt`. Decorative → `alt=""`.
- **Live regions** (`aria-live`) for async UI updates that screen readers need to announce.

## Apollo Client

- **Codegen-typed operations.** All `useQuery` / `useMutation` typed via codegen (`@graphql-codegen/typescript-operations` or `typed-document-node`). No hand-written response types. No `useQuery<any>`.
- **Named operations.** Every query/mutation/subscription has a name (`query GetUser { ... }`). Anonymous operations break Apollo devtools, persisted queries, and cache identity.
- **Fragment colocation.** Components define their own fragments; parent queries compose them. No god-queries selecting every field.
- **Cache normalization.**
  - Every type with an `id` (or stable key) listed in `typePolicies.<Type>.keyFields` if non-default.
  - Paginated fields have an explicit `merge` function (or use `relayStylePagination` / `offsetLimitPagination`). Default merge throws on incoming arrays.
  - `read`/`merge` written carefully — they run on every cache read.
- **`fetchPolicy` chosen deliberately.** Default `cache-first`. Use `cache-and-network` for stale-while-revalidate UX, `network-only` for freshness-critical data, `no-cache` for one-shot data not worth caching. Never default to `network-only`.
- **`nextFetchPolicy`** set when initial fetch should be `network-only` but subsequent reads `cache-first`.
- **Mutations update the cache.** Order of preference: (1) return updated entity from server with same `id`/`__typename` (auto-merge), (2) `cache.modify` / `writeFragment` in `update`, (3) `refetchQueries` only when surgical updates are infeasible. Reflexive `refetchQueries: ['everything']` is a smell.
- **Optimistic responses** include `__typename` and `id`. Without them the cache writes a phantom object.
- **Error handling.** Distinguish `error.networkError` (transport failed) from `error.graphQLErrors` (server returned `errors`). `errorPolicy: 'all'` when partial data is meaningful. Surface user-facing errors via the typed error union, not raw `error.message`.
- **`@defer` / `@stream`** behind a feature flag — server support and client cache behavior must be verified.
- **Subscriptions** clean up on unmount (`useSubscription` does this; manual `subscribe` calls must `unsubscribe`). Reconnect strategy defined.
- **Avoid request waterfalls.** Independent queries fire in parallel — do not chain `useQuery` calls gated on each other's data unless data dependency is real.
- **Don't over-fetch.** Select only fields rendered. If a fragment selects 20 fields and the component renders 3, trim it.
- **Persisted queries / trusted documents** in production — flag absence on user-facing apps.

## Bundle & runtime perf

- **Code splitting** via `React.lazy` + `Suspense` for routes and heavyweight components.
- **Tree-shake-friendly imports.** `import { x } from 'lib'` not `import * as lib from 'lib'`. Watch out for libraries (lodash, date-fns) — use scoped imports.
- **Image optimization** — `next/image` or equivalent; explicit `width`/`height` to prevent CLS.
- **No giant inline objects/arrays in JSX** for memoized children — they break referential equality.

## Testing

- **React Testing Library** queries by role/label/text — not by `data-testid` unless nothing else fits, and never by class name.
- **`userEvent`** over `fireEvent` for interactions.
- **MSW** (or Apollo `MockedProvider`) for network. No real fetch in tests.
- **Async assertions** via `findBy*` / `waitFor`, not `setTimeout`.
- **Test behavior, not implementation.** No assertions on internal state, hook call counts, or rendered HTML structure beyond what the user sees.

## Common smells (always flag)

- `useEffect(() => { setX(deriveFromProps(props.y)) }, [props.y])` — derive inline.
- `JSON.parse(JSON.stringify(x))` — use structuredClone.
- `await Promise.all(items.map(async i => await fetch(...)))` inside a render path — should be a query/mutation, batched, or moved server-side.
- `dangerouslySetInnerHTML` without sanitization.
- `window` / `document` referenced outside `useEffect` or a client guard in SSR contexts.
- `console.log` left in shipping code.
