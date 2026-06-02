# Workflow: Test a Feature Flag (React / Vitest)

## How it works

The project uses `mockFlags` from `test-utils/vitest-launchdarkly-mock`, which mocks `useFlags` from the LD SDK at the module level. The custom `useFeatureFlags()` hook calls `useFlags()` internally, so mocking at the SDK level flows through correctly.

**All flags default to `true` in tests** (the mock returns `{}` for unknown keys, but `useFeatureFlags` maps them — effectively `undefined` which is falsy). To get a flag reliably `true` or `false`, always set it explicitly with `mockFlags`.

## Setup

At the top of your test file (or in a shared setup file), import both:

```typescript
// Adjust ../ depth to match your component's location.
import { mockFlags } from '../../../test-utils/vitest-launchdarkly-mock';
import { FEATURE_FLAGS } from '../../feature-flags/featureFlags';
```

`vitest-launchdarkly-mock` auto-mocks the LD SDK when imported — no `vi.mock(...)` call needed.

## Usage patterns

### Force a flag ON

```typescript
mockFlags({ [FEATURE_FLAGS.JIMS6100_Enable_New_Checkout]: true });
```

### Force a flag OFF

```typescript
mockFlags({ [FEATURE_FLAGS.JIMS6100_Enable_New_Checkout]: false });
```

### Test both enabled and disabled paths

```typescript
describe('<NewCheckout />', () => {
  describe('When JIMS6100_Enable_New_Checkout is enabled', () => {
    test('Then it renders the new checkout UI', async () => {
      mockFlags({ [FEATURE_FLAGS.JIMS6100_Enable_New_Checkout]: true });
      const { findByTestId } = await render(<MyComponent />);
      expect(await findByTestId('new-checkout')).toBeInTheDocument();
    });
  });

  describe('When JIMS6100_Enable_New_Checkout is disabled', () => {
    test('Then it renders the legacy checkout UI', async () => {
      mockFlags({ [FEATURE_FLAGS.JIMS6100_Enable_New_Checkout]: false });
      const { findByTestId } = await render(<MyComponent />);
      expect(await findByTestId('legacy-checkout')).toBeInTheDocument();
    });
  });
});
```

### Reset mocks between tests

Use `resetLDMocks` in `afterEach` if tests share state:

```typescript
import { mockFlags, resetLDMocks } from '../../../test-utils/vitest-launchdarkly-mock';

afterEach(() => {
  resetLDMocks();
});
```

## Notes

- Always use `FEATURE_FLAGS.JIMS####_Name` as the key — never a raw `teamy-{guid}` string.
- Use `render` from `test-utils/test-utils.tsx`, not from `@testing-library/react` directly.
