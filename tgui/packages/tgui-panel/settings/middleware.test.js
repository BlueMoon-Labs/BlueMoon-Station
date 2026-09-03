import { applyMiddleware, combineReducers, createStore } from 'common/redux';
import { storage } from 'common/storage';

import { setClientTheme } from '../themes';
import { updateSettings } from './actions';
import { settingsMiddleware } from './middleware';
import { settingsReducer } from './reducer';

jest.mock('common/storage', () => ({
  storage: {
    get: jest.fn(),
    set: jest.fn(),
  },
}));

jest.mock('../themes', () => ({
  THEMES: ['light', 'dark', 'default'],
  setClientTheme: jest.fn(),
}));

const flushPromises = async () => {
  await Promise.resolve();
  await Promise.resolve();
};

const createSettingsStore = () => createStore(
  combineReducers({
    settings: settingsReducer,
  }),
  applyMiddleware(settingsMiddleware),
);

describe('settingsMiddleware', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    storage.get.mockResolvedValue(undefined);
    storage.set.mockResolvedValue(undefined);
    window.__windowId__ = 'browseroutput';
    global.Byond = {
      topic: jest.fn(),
    };
  });

  test('does not let late hydration override local updates', async () => {
    let resolveGet;
    storage.get.mockReturnValue(new Promise(resolve => {
      resolveGet = resolve;
    }));

    const store = createSettingsStore();
    store.dispatch(updateSettings({
      theme: 'dark',
    }));

    resolveGet({
      version: 1,
      theme: 'default',
      fontSize: 16,
    });
    await flushPromises();

    expect(store.getState().settings.theme).toBe('dark');
    expect(setClientTheme).toHaveBeenLastCalledWith('dark');
    expect(storage.set).toHaveBeenLastCalledWith(
      'panel-settings',
      expect.objectContaining({
        theme: 'dark',
      }),
    );
  });

  test('hydrates saved theme when user has not changed it yet', async () => {
    storage.get.mockResolvedValue({
      version: 1,
      theme: 'light',
    });

    const store = createSettingsStore();
    store.dispatch({
      type: 'noop',
    });
    await flushPromises();

    expect(store.getState().settings.theme).toBe('light');
    expect(setClientTheme).toHaveBeenCalledWith('light');
  });

  test('does not re-apply theme when non-theme settings change', async () => {
    const store = createSettingsStore();

    store.dispatch(updateSettings({
      theme: 'dark',
    }));
    store.dispatch(updateSettings({
      lineHeight: 1.4,
    }));
    await flushPromises();

    expect(setClientTheme).toHaveBeenCalledTimes(1);
    expect(setClientTheme).toHaveBeenCalledWith('dark');
  });

  test('sends panel/theme_set when user changes theme', async () => {
    const store = createSettingsStore();

    store.dispatch(updateSettings({
      theme: 'dark',
    }));
    await flushPromises();

    expect(global.Byond.topic).toHaveBeenCalledWith({
      tgui: 1,
      window_id: 'browseroutput',
      type: 'panel/theme_set',
      payload: JSON.stringify({
        theme: 'dark',
      }),
    });
  });

  test('does not send panel/theme_set for unchanged theme', async () => {
    const store = createSettingsStore();

    store.dispatch(updateSettings({
      theme: 'default',
    }));
    await flushPromises();

    expect(global.Byond.topic).not.toHaveBeenCalled();
  });

  test('applies incoming server theme without echoing back', async () => {
    const store = createSettingsStore();

    store.dispatch({
      type: 'panel/theme',
      payload: {
        theme: 'dark',
      },
    });
    await flushPromises();

    expect(store.getState().settings.theme).toBe('dark');
    expect(setClientTheme).toHaveBeenCalledWith('dark');
    expect(global.Byond.topic).not.toHaveBeenCalled();
  });

  test('does not let late hydration override incoming server theme', async () => {
    let resolveGet;
    storage.get.mockReturnValue(new Promise(resolve => {
      resolveGet = resolve;
    }));

    const store = createSettingsStore();
    store.dispatch({
      type: 'panel/theme',
      payload: {
        theme: 'dark',
      },
    });

    resolveGet({
      version: 1,
      theme: 'light',
    });
    await flushPromises();

    expect(store.getState().settings.theme).toBe('dark');
    expect(setClientTheme).toHaveBeenCalledTimes(1);
    expect(setClientTheme).toHaveBeenCalledWith('dark');
  });

  // ---- Global font diffing ----
  // Setting font-size / font-family on <html> and <body> invalidates
  // the entire document's computed styles. We must skip these calls
  // when the underlying value has not changed (e.g. user is typing in
  // the highlight text field, which does not touch fonts).

  describe('global font diffing', () => {
    let setPropertySpy;

    beforeEach(() => {
      setPropertySpy = jest.fn();
      Object.defineProperty(document.documentElement, 'style', {
        configurable: true,
        value: { setProperty: setPropertySpy },
      });
      Object.defineProperty(document.body, 'style', {
        configurable: true,
        value: { setProperty: setPropertySpy },
      });
    });

    test('applies font size and family on first dispatch', async () => {
      const store = createSettingsStore();
      store.dispatch(updateSettings({
        fontSize: 14,
      }));
      await flushPromises();

      // Initial dispatch of any setting applies fontSize and fontFamily once.
      const fontSizeCalls = setPropertySpy.mock.calls
        .filter(([prop]) => prop === 'font-size');
      const fontFamilyCalls = setPropertySpy.mock.calls
        .filter(([prop]) => prop === 'font-family');
      // 2 elements (html + body) × 1 setting application
      expect(fontSizeCalls).toHaveLength(2);
      expect(fontFamilyCalls).toHaveLength(2);
      expect(fontSizeCalls[0][1]).toBe('14px');
    });

    test('does not re-apply font size when an unrelated setting changes', async () => {
      const store = createSettingsStore();
      // Establish baseline (first dispatch always applies)
      store.dispatch(updateSettings({ fontSize: 14 }));
      await flushPromises();
      setPropertySpy.mockClear();

      // Simulate typing in highlight text (no font change)
      store.dispatch(updateSettings({ highlightText: 'a' }));
      store.dispatch(updateSettings({ highlightText: 'ab' }));
      store.dispatch(updateSettings({ highlightText: 'abc' }));
      await flushPromises();

      // Font setters must not run for unrelated changes
      const fontSizeCalls = setPropertySpy.mock.calls
        .filter(([prop]) => prop === 'font-size');
      const fontFamilyCalls = setPropertySpy.mock.calls
        .filter(([prop]) => prop === 'font-family');
      expect(fontSizeCalls).toHaveLength(0);
      expect(fontFamilyCalls).toHaveLength(0);
    });

    test('re-applies font size when fontSize actually changes', async () => {
      const store = createSettingsStore();
      store.dispatch(updateSettings({ fontSize: 14 }));
      await flushPromises();
      setPropertySpy.mockClear();

      store.dispatch(updateSettings({ fontSize: 16 }));
      await flushPromises();

      const fontSizeCalls = setPropertySpy.mock.calls
        .filter(([prop]) => prop === 'font-size');
      // Applied to html and body
      expect(fontSizeCalls).toHaveLength(2);
      expect(fontSizeCalls[0][1]).toBe('16px');
    });

    test('does not re-apply font when fontSize is set to its current value', async () => {
      const store = createSettingsStore();
      store.dispatch(updateSettings({ fontSize: 14 }));
      await flushPromises();
      setPropertySpy.mockClear();

      // Same value — should be a no-op for the DOM
      store.dispatch(updateSettings({ fontSize: 14 }));
      await flushPromises();

      const fontSizeCalls = setPropertySpy.mock.calls
        .filter(([prop]) => prop === 'font-size');
      expect(fontSizeCalls).toHaveLength(0);
    });
  });
});
