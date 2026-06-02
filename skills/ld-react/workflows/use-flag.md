# Workflow: Use a Feature Flag in a Component (React)

## Steps

### 1. Import the hook

```typescript
import { useFeatureFlags } from '../../feature-flags/featureFlags.ts';
```

Adjust the relative path depth based on the component's location inside `src/`.

### 2. Destructure the flag

```typescript
const { JIMS####_Description } = useFeatureFlags();
```

Prefer destructuring over `const flags = useFeatureFlags()` — it's more explicit about which flags the component depends on.

### 3. Use in JSX / logic

**Pattern A — Conditional render:**
```tsx
const { JIMS6100_Enable_New_Checkout } = useFeatureFlags();

return (
  <div>
    {JIMS6100_Enable_New_Checkout && <NewCheckout />}
  </div>
);
```

**Pattern B — Hook dependency / early return:**
```tsx
const { JIMS4396_Kill_Switch_My_Walley } = useFeatureFlags();

if (JIMS4396_Kill_Switch_My_Walley) {
  return <MaintenancePage />;
}
```

**Pattern C — GraphQL variable:**
```tsx
const { JIMS4934_Enable_Bank_Info } = useFeatureFlags();

const { data } = useQuery(MY_QUERY, {
  variables: { includeBankInfo: JIMS4934_Enable_Bank_Info },
});
```

**Pattern D — Multiple flags (keep destructuring):**
```tsx
const {
  JIMS4934_Enable_Bank_Info,
  JIMS4963_Enable_Language_Selection,
} = useFeatureFlags();
```

## Notes

- Never pass raw flag IDs (`teamy-{guid}`) into components — always go through `FEATURE_FLAGS` and `useFeatureFlags()`.
- The flag must already be in `featureFlags.ts`. If not, run the `create-flag` workflow first.
