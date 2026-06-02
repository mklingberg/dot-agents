# Reference: Testing Feature Flags

## How the mock works

`test-utils/vitest-launchdarkly-mock.ts` mocks the entire `launchdarkly-react-client-sdk` module at the Vitest level. Importing this file (directly or via a shared setup) replaces `useFlags` with a `vi.fn()`.

The `mockFlags` helper sets what `useFlags` returns for a given test:

```typescript
export const mockFlags = (flags: LDFlagSet) => {
  mockUseFlags.mockImplementation(() => {
    const result: LDFlagSet = {};
    Object.keys(flags).forEach((k) => {
      result[k] = flags[k];
    });
    return result;
  });
};
```

Since `useFeatureFlags()` calls `useFlags()` internally, mocking at the SDK level is sufficient — you never need to mock `useFeatureFlags` itself.

## Import pattern

```typescript
import { mockFlags, resetLDMocks } from '../../../test-utils/vitest-launchdarkly-mock';
import { FEATURE_FLAGS } from '../../feature-flags/featureFlags';
```

Adjust `../` depth based on the test file's location inside `src/`.

## Key: use `FEATURE_FLAGS` as the key, not the flag name

`mockFlags` takes an `LDFlagSet` where keys are **LaunchDarkly IDs** (`teamy-{guid}`), not the human-readable names. Use the `FEATURE_FLAGS` object to get the right key:

```typescript
// Correct
mockFlags({ [FEATURE_FLAGS.JIMS4934_Enable_Bank_Info]: true });

// Wrong — this key won't match anything
mockFlags({ JIMS4934_Enable_Bank_Info: true });
```

## Default flag state in tests

When `mockFlags` has not been called, `useFlags()` returns `{}`. The `useFeatureFlags()` hook maps every entry in `FEATURE_FLAGS` against this empty object, so all flags resolve to `undefined` (falsy). Explicitly set flags to `true` or `false` in each test to avoid relying on this implicit default.

## Resetting between tests

```typescript
import { resetLDMocks } from '../../../test-utils/vitest-launchdarkly-mock';

afterEach(() => {
  resetLDMocks();
});
```

`resetLDMocks` resets `useFlags` to return `{}` and clears all `ldClientMock` call records.

## Partial mock typing

When you only set a subset of flags, TypeScript may complain if you pass the result where `FeatureFlags` is expected. Cast with `as Partial<FeatureFlags>` where needed.
