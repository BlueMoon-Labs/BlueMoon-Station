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
});
