# Writing Tests

## Overview

tgui uses **Jest 30** with **jsdom** for unit testing. Tests cover utility
functions, Redux reducers, component logic, and UI rendering.

## Getting started

Create a file ending in `.test.ts`, `.test.js`, `.spec.ts`, or `.spec.js`
(usually with the same filename as the file you're testing), and write a
test case:

```js
test('something', () => {
  expect('a').toBe('a');
});
```

To run all tests:

```
bin/tgui --test
```

You can read more about Jest here: https://jestjs.io/docs/getting-started

## Test structure

Tests use the `describe` / `test` / `expect` pattern:

```js
import { capitalize } from './string';

describe('capitalize', () => {
  test('capitalizes first letter', () => {
    expect(capitalize('hello')).toBe('Hello');
  });

  test('handles empty string', () => {
    expect(capitalize('')).toBe('');
  });
});
```

- **`describe`** groups related tests together.
- **`test`** (or `it`) defines a single test case.
- **`expect`** makes assertions about values.

## What to test

### Utility functions (`packages/common/`)

Pure functions are the easiest to test. See existing examples:

- `string.spec.js` — string manipulation (`capitalize`, `createSearch`,
  `buildQueryString`, etc.)
- `math.spec.ts` — math helpers (`clamp`, `round`, `scale`, etc.)
- `collections.spec.ts` — collection utilities (`BooleanLike`, `map`,
  `filter`, etc.)
- `vector.spec.js` — vector math (`vecAdd`, `vecNormalize`, etc.)
- `color.spec.js` — color manipulation
- `fp.spec.js` — functional programming helpers
- `keycodes.spec.js` — keyboard constant validation
- `storage.spec.js` — storage backend logic
- `timer.spec.js` — debounce/throttle helpers
- `events.spec.js` — event emitter
- `redux.spec.js` — Redux store and combineReducers

### Redux reducers (`packages/tgui-panel/`)

Reducers are pure functions — pass state + action, assert the result:

```js
import { chatReducer, initialState } from './reducer';
import { addChatPage } from './actions';

describe('chatReducer', () => {
  test('adds a new page', () => {
    const state = chatReducer(initialState, addChatPage());
    expect(state.pages.length).toBe(initialState.pages.length + 1);
  });
});
```

See existing examples in `packages/tgui-panel/`:
- `chat/reducer.test.js`, `chat/model.test.js`, `chat/selectors.test.js`
- `chat/renderer.test.js` — chat rendering pipeline
- `chat/replaceInTextNode.test.js` — text node replacement
- `ping/reducer.test.js`, `ping/actions.test.js`
- `settings/middleware.test.js`, `settings/reducer.test.js`
- `audio/reducer.test.js`
- `emotes/reducer.test.js`
- `game/reducer.test.js`
- `telemetry.test.js`

### Component logic (`packages/tgui/`)

You can test component helper functions (unit conversion, class name
computation, formatting) without rendering:

```js
import { computeBoxClassName, unit } from './Box';

describe('unit', () => {
  test('converts number to rem', () => {
    expect(unit(2)).toBe('2rem');
  });

  test('passes through percentage string', () => {
    expect(unit('50%')).toBe('50%');
  });
});
```

See existing examples:
- `components/Box.test.ts` — Box unit conversion and class computation
- `format.spec.js` — value formatting helpers
- `constants.spec.js` — color and constant definitions
- `drag.test.js` — window drag/resize logic

## Tips

- Keep test descriptions concise and descriptive.
- Test edge cases: empty input, zero, negative numbers, `undefined`/`null`.
- For reducers, always start from `initialState` to ensure isolation.
- One assertion per test when practical — makes failures easier to diagnose.
