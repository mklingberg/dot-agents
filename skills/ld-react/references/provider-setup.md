# Reference: Provider Setup

## Config file

`~/Dev/walley-my-walley-frontend/src/scripts/launch-darkly-config.ts`

## `getLDProviderConfig()`

Returns an `AsyncProviderConfig` used by `asyncWithLDProvider()` in `main-render.tsx`.

Key behaviours:

**1. All flags default to `false`**

```typescript
const setDefaultValueToFlags = Object.fromEntries(
  Object.values(FEATURE_FLAGS).map((value) => [value, false])
);
```

Every flag ID in `FEATURE_FLAGS` is pre-seeded to `false`. This means new flags are always off on deploy — there is no risk of unintentional enablement.

**2. Context from backend**

```typescript
export function getLdContext(): LDContext {
  return window.WALLEY?.LD_CONTEXT ?? getDefaultContext();
}
```

The backend sets `window.WALLEY.LD_CONTEXT` when serving the SPA. This context is used to target flags to specific users/tenants.

**3. SessionStorage fallback**

If `window.WALLEY.LD_CONTEXT` is not available (e.g. demo site, dev environment), the context is read from `sessionStorage` via `getStoredLdContext()`. If that also fails, a default context is used.

**4. `useCamelCaseFlagKeys: false`**

```typescript
reactOptions: {
  useCamelCaseFlagKeys: false,
}
```

Flag keys are used as-is (`teamy-{guid}`). This is why the remapping in `useFeatureFlags()` is necessary — the SDK won't auto-convert to camelCase.

## Provider wrapping

The provider wraps the entire app in the per-market entry points (e.g. `src/scripts/main-render.tsx`) using `asyncWithLDProvider(getLDProviderConfig())`.
