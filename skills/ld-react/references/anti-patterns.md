# Reference: Anti-patterns

## Don't use `useFlags()` directly

```typescript
// Bad
import { useFlags } from 'launchdarkly-react-client-sdk';
const flags = useFlags();
const enabled = flags['teamy-e8d29bb4-2c27-445e-8fa5-4e09416cfdcd'];

// Good
import { useFeatureFlags } from '../../feature-flags/featureFlags.ts';
const { JIMS4934_Enable_Bank_Info } = useFeatureFlags();
```

**Why:** Raw `useFlags()` exposes LD IDs in component code, makes refactoring harder, bypasses the centralized registry, and is not covered by the project's test mock helper.

---

## Don't inline `teamy-{guid}` strings in components

```typescript
// Bad
if (flags['teamy-e8d29bb4-2c27-445e-8fa5-4e09416cfdcd']) { ... }

// Good
const { JIMS4934_Enable_Bank_Info } = useFeatureFlags();
if (JIMS4934_Enable_Bank_Info) { ... }
```

**Why:** LD keys are opaque UUIDs. Centralizing them in `FEATURE_FLAGS` makes search-and-replace, audits, and cleanup possible.

---

## Don't use a flag before adding it to `featureFlags.ts`

```typescript
// Bad — JIMS6200_New_Feature doesn't exist in FEATURE_FLAGS yet
const { JIMS6200_New_Feature } = useFeatureFlags(); // always undefined
```

**Why:** `useFeatureFlags()` only maps entries present in `FEATURE_FLAGS`. If the key is missing, the flag value is always `undefined` (falsy) regardless of what LaunchDarkly returns.

---

## Don't mock `useFeatureFlags` directly in tests

```typescript
// Bad
vi.mock('../../feature-flags/featureFlags', () => ({
  useFeatureFlags: vi.fn().mockReturnValue({ JIMS4934_Enable_Bank_Info: true }),
}));

// Good
import { mockFlags } from '../../../test-utils/vitest-launchdarkly-mock';
import { FEATURE_FLAGS } from '../../feature-flags/featureFlags';
mockFlags({ [FEATURE_FLAGS.JIMS4934_Enable_Bank_Info]: true });
```

**Why:** The project has a dedicated `mockFlags` helper that operates at the SDK level. Mocking `useFeatureFlags` at the module level bypasses the real mapping logic and couples tests to the hook's implementation details.

---

## Don't ship behaviour changes without a flag

Any change that alters visible behaviour or affects users should be wrapped in a feature flag so it can be rolled back without a deploy.
