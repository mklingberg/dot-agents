# Workflow: Remove a Feature Flag (React)

Use this when a flag is fully rolled out to PROD and the old code path can be deleted.

## Steps

### 1. Confirm full rollout

Before touching any code, verify the flag is 100% enabled in PROD:

```
mcp__LaunchDarkly__get-flag-status-across-environments
  projectKey: "after-purchase"
  featureFlagKey: "teamy-{guid}"
```

Do not proceed until the flag is confirmed on in PROD.

### 2. Find all usages in the codebase

```bash
grep -r "JIMS####_Description" ~/Dev/walley-my-walley-frontend/src --include="*.ts" --include="*.tsx"
```

List every file that imports or uses this flag.

### 3. Inline the enabled-path code

For each usage:
- Remove the flag variable from the `useFeatureFlags()` destructure.
- Keep the **enabled** code path, delete the **disabled** code path.
- Remove any flag-conditional wrappers (ternaries, `&&`, `if` blocks).

Example before:
```tsx
const { JIMS6100_Enable_New_Checkout } = useFeatureFlags();
return JIMS6100_Enable_New_Checkout ? <NewCheckout /> : <LegacyCheckout />;
```

Example after:
```tsx
return <NewCheckout />;
```

### 4. Remove from `featureFlags.ts`

File: `~/Dev/walley-my-walley-frontend/src/feature-flags/featureFlags.ts`

Delete the line:
```typescript
JIMS####_Description: 'teamy-{guid}',
```

### 5. Remove test mocks for this flag

Search for test files referencing this flag:
```bash
grep -r "JIMS####_Description" ~/Dev/walley-my-walley-frontend/src --include="*.test.tsx" --include="*.test.ts"
```

Remove `mockFlags` calls that set this flag, and any test cases that only exist to test the disabled path.

### 6. Run tests

```bash
cd ~/Dev/walley-my-walley-frontend && npm run test-pr
```

Fix any failures before proceeding.

### 7. Delete the flag in LaunchDarkly via MCP

```
mcp__LaunchDarkly__delete-feature-flag
  projectKey: "after-purchase"
  featureFlagKey: "teamy-{guid}"
```

This is irreversible — confirm the flag key before executing.
