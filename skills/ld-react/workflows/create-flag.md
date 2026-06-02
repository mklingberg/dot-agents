# Workflow: Create a Feature Flag (React)

## Steps

### 1. Get inputs from user
Ask for:
- Jira ticket number (e.g. `JIMS6100`)
- Short PascalCase description (e.g. `Enable_New_Checkout`)

### 2. Generate a GUID for the LaunchDarkly key

```bash
uuidgen | tr '[:upper:]' '[:lower:]'
```

This produces the `{guid}` used in `teamy-{guid}`.

### 3. Add the entry to `featureFlags.ts`

File: `~/Dev/walley-my-walley-frontend/src/feature-flags/featureFlags.ts`

Add a new line inside the `FEATURE_FLAGS` object:

```typescript
export const FEATURE_FLAGS = {
  // ...existing flags...
  JIMS####_Description: 'teamy-{guid}',
};
```

The `getLDProviderConfig()` function automatically sets all `FEATURE_FLAGS` values to `false` as defaults — no extra step needed.

### 4. Create the flag in LaunchDarkly via MCP

```
mcp__LaunchDarkly__create-feature-flag
  projectKey: "after-purchase"
  name: "JIMS####_Description"
  key: "teamy-{guid}"
  kind: "boolean"
  temporary: true
  defaultVariation: 1   (index of false/off variation — confirm off is default)
```

Verify the flag was created:
```
mcp__LaunchDarkly__get-feature-flag
  projectKey: "after-purchase"
  featureFlagKey: "teamy-{guid}"
```

### 5. Rollout reminder

Remind the user to enable the flag environment by environment:
1. CI (dev/test)
2. UAT
3. PROD

The flag starts off everywhere until explicitly enabled in LaunchDarkly.
