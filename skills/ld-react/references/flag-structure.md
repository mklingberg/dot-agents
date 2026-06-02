# Reference: Flag Structure

## File location

`~/Dev/walley-my-walley-frontend/src/feature-flags/featureFlags.ts`

## `FEATURE_FLAGS` object

A plain TypeScript object mapping human-readable flag names to LaunchDarkly flag IDs:

```typescript
export const FEATURE_FLAGS = {
  JIMS4934_Enable_Bank_Info: 'teamy-e8d29bb4-2c27-445e-8fa5-4e09416cfdcd',
  JIMS5829_Can_Extend_Due_Date: 'teamy-019a72f9-cab5-737f-bb6b-41dc54cb3bc2',
  // ...
};
```

### Key naming convention

`JIMS####_PascalCase_Description`

- Prefix: Jira ticket number (e.g. `JIMS4934`)
- Body: PascalCase description (e.g. `Enable_Bank_Info`)

### LaunchDarkly key format

`teamy-{guid}`

- Always lowercase
- UUID generated with `uuidgen | tr '[:upper:]' '[:lower:]'`
- Example: `teamy-e8d29bb4-2c27-445e-8fa5-4e09416cfdcd`

## `useFeatureFlags()` hook

```typescript
export function useFeatureFlags() {
  const flags = useFlags();
  return Object.fromEntries(
    Object.entries(FEATURE_FLAGS).map(([name, id]) => [name, flags[id]])
  );
}
```

**What it does:**
1. Calls `useFlags()` from `launchdarkly-react-client-sdk` to get raw flag values keyed by LD ID.
2. Remaps them to human-readable names using `FEATURE_FLAGS`.
3. Returns an object you can destructure by flag name.

This is why you can write `const { JIMS4934_Enable_Bank_Info } = useFeatureFlags()` instead of dealing with `teamy-e8d29bb4-...` strings in components.

## `FeatureFlags` type

```typescript
export type FeatureFlags = ReturnType<typeof useFeatureFlags>;
```

Use this type when you need to pass flags as props or store them in state.
